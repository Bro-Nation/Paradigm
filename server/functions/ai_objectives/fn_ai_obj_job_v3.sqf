/*
	File: fn_ai_job.sqf
	Author:  Savage Game Design
	Public: No

	Description:
		Scheduler job for managing the AI.

		@dijksterhuis -- AI count binning based on percentage of valid players in range

	Parameter(s): none

	Returns: nothing

	Example(s): none
*/

////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////
// Server-only public variable overrides
// should be defined in the system init, but need to be switched if changing between different
// implementations live on the server

// para_s_ai_obj_activation_radius = 1000;
// para_s_ai_obj_priority_radii = [300,400,500,700,para_s_ai_obj_activation_radius];
para_s_ai_obj_reinforce_block_direct_spawn_range = 600;
para_s_ai_obj_reinforce_reallocate_range = 600;
para_s_ai_obj_hard_ai_limit = para_s_ai_obj_config getOrDefault ["hardAiLimit", 80];
para_s_ai_obj_pursuitRadius = 300;
para_s_ai_obj_maxPursuitDistance = 1200;

// non default
para_s_ai_obj_activation_radius = 600;
para_s_ai_obj_tracked_players = [];

////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////
// Local Functions

/*
Get the base list of all players that we care about.
*/
private _fnc_get_players = {
	// allUnits select {isPlayer _x && {!(_x isKindOf "HeadlessClient_F")} && !(vehicle _x isKindOf "Plane") && (speed vehicle _x < 200) && !(side _x == east)}
	allUnits select {!(_x isKindOf "HeadlessClient_F") && !(vehicle _x isKindOf "Plane") && (speed vehicle _x < 200) && !(side _x == east)}
};

/*
Filter to players who are within range of an active objective.
*/
private _fnc_get_players_in_range_of_obj = {
	private _players = (call _fnc_get_players) select {
		private _player = _x;
		para_s_ai_obj_active_objectives findIf {_x distance2D _player < (_x getVariable ["activation_radius", para_s_ai_obj_activation_radius])} > -1;
	};

	_players;
};


/*
Get the current count of paradigm managed AI. Non-paradigm AI (Zeus / AA sites in BN Mike Force) are ignored.
*/
private _fnc_get_ai_count = {
	count (allUnits select {(side group _x == east) && (_x getVariable ["paradigm_managed", false])})
};

/*
Get the current of the globally available AI pool. Dynamically updates based on player counts and locations.

this function is a very hacky estimation of a periodic convolution between a monotonically
increasing linear function and a postive only step function.

It is hacky, but it avoids having to write an FFT implementation or dealing with integrals in convolutions.

We end up with something like this:
- as players increase, so does amount of AI (linear monotonic).
- at certain points, the AI count jumps up when we get another player joining.

AI count
|
|										x
|									x
|								x
|							|
|							|
|							x
|						x
|					x
|				|
|				|
|				x
|			x
|		x
|	x
x---------------------------------------------
					players
*/
private _fnc_get_pool_size = {
	private _alpha = 0.3;
	private _beta = 1.2;

	private _playerCount = count (call _fnc_get_players);

	private _aiPoolSize = floor (
		(_playerCount * para_g_enemiesPerPlayer) + (_playerCount * _alpha * (_playerCount mod _beta))
	);

	// clip the pool size for safety.
	_aiPoolSize min para_s_ai_obj_hard_ai_limit

};


/*
Tick objectives so they run any periodic code.
*/
private _fnc_obj_tick = {
	para_s_ai_obj_debug && {diag_log format ["AI Obj: Ticking %1 existing objectives.", count para_s_ai_obj_objectives]};
	para_s_ai_obj_objectives apply {[_x] call (_x getVariable ["onTick", {}])};
};

/*
Work out which objectives are currently active by looking for players within the objective's activation raidus.
*/
private _fnc_get_objs_active = {
	params ["_players"];
	private _objs = para_s_ai_obj_objectives select {
		private _obj = _x;
		(call _fnc_get_players) findIf {(_x distance2D _obj) < (_obj getVariable ["activation_radius", para_s_ai_obj_activation_radius])} > -1
	};

	_objs
};

/*
Activate objecvites that have been added recently
*/
private _fnc_obj_activate = {
	params ["_activeObjectives"];

	private _newlyActiveObjectives = _activeObjectives - para_s_ai_obj_active_objectives;

	para_s_ai_obj_debug && {diag_log format ["AI Obj: Activating objectives: %1", _newlyActiveObjectives apply {_x getVariable "id"}]};

	_newlyActiveObjectives apply {[_x] call (_x getVariable ["onActivation", {}])};

	para_s_ai_obj_debug && {diag_log "AI Obj: Deactivating objectives."};

};

/*
Deactivate objectives that are no longer important
*/
private _fnc_obj_deactivate = {
	params ["_activeObjectives"];

	private _deactivatedObjectives = para_s_ai_obj_active_objectives - _activeObjectives;

	para_s_ai_obj_debug && {diag_log format ["AI Obj: Deactivating objectives: %1", _deactivatedObjectives apply {_x getVariable "id"}]};

	_deactivatedObjectives apply {
		[_x] call (_x getVariable ["onDeactivation", {}]);
		private _assignedGroups = _x getVariable "assignedGroups";
		[_assignedGroups, _x] call para_s_fnc_ai_obj_unassign_from_objective;
		_freeGroupLeaders append (_assignedGroups apply {leader _x});

		para_s_ai_obj_debug && {
			private _markerName = format ["para_s_ai_obj_debug_heatmap_%1", _x getVariable "id"];
			if (_markerName in allMapMarkers) then {deleteMarker _markerName};
		};
	};
	para_s_ai_obj_debug && {diag_log "AI Obj: Deactivated objectives."};
};

/*
Activate/Deactivate objectives
*/
private _fnc_obj_init_deinit = {
	params ["_activeObjectives"];

	para_s_ai_obj_debug && {diag_log "AI Obj: Init/Deinit active objectives."};

	para_s_ai_obj_debug && {
		diag_log format [
			"AI Obj: Objectives currently active: %1",
			count _activeObjectives
		];
	};

	[_activeObjectives] call _fnc_obj_deactivate;
	[_activeObjectives] call _fnc_obj_activate;

	para_s_ai_obj_active_objectives = _activeObjectives;
	para_s_ai_obj_active_objectives
};

/*
No more AI left, out of reinforcements etc.
*/
private _fnc_obj_finish = {
	para_s_ai_obj_objectives select {
		_x getVariable ["reinforcements_remaining", 0] <= 0
	} apply {
		[_x] call para_s_fnc_ai_obj_finish_objective;

		para_s_ai_obj_debug && {
			diag_log format [
				"AI Obj: Finishing objectives: obj=%1",
				_x getVariable "id"
			];
		};

		_x
	};
};

/*
Safely remove all unecessary AI groups and units.
*/
private _fnc_purge_groups = {
	params ["_groupLeaders"];

	para_s_ai_obj_debug && {
		diag_log format [
			"AI Obj: Removing free groups: groupsRemove=%1 managedGroups=%2",
			count _groupLeaders,
			count para_s_ai_obj_managedGroups
		];
	};

	//Add any unused groups to cleanup.
	//Be wary of lingering AI squads being pinned in place by a single guy.
	//Want to avoid the situation where one unit can stop 100 AI from being cleaned up
	private _groupsToRemove = _groupLeaders apply {

		private _group = group _x;
		_group deleteGroupWhenEmpty true;
		[units _group] call para_s_fnc_cleanup_add_items;
		units _group apply { deleteVehicle _x };

		_group
	};

	para_s_ai_obj_managedGroups = para_s_ai_obj_managedGroups - _groupsToRemove;

	para_s_ai_obj_debug && {
		diag_log format [
			"AI Obj: Removed free groups: groupsRemove=%1 managedGroups=%2",
			count _groupLeaders,
			count para_s_ai_obj_managedGroups
		];
	};
};


////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////
// Setup

/*
@dijksterhuis BN changes
- [TWEAK] Not in vehicle travelling over 200 km/h (down from SGD upstream 300 km/h)
- [ADD] Not dac cong (assumption that side east == dac cong)
*/
// private _allPlayers = allUnits select {isPlayer _x && {!(_x isKindOf "HeadlessClient_F")} && !(vehicle _x isKindOf "Plane") && (speed vehicle _x < 200) && !(side _x == east)};
private _allPlayers = allUnits select {!(_x isKindOf "HeadlessClient_F") && !(vehicle _x isKindOf "Plane") && (speed vehicle _x < 200) && !(side _x == east)};

//Groups of AI that are no longer in use by the system.
//We can reuse these for other objectives later.
//Or tidy them up, if we don't need to reuse them.
//Initially - populate it with groups the system owns, that have no objective.
private _freeGroupLeaders = para_s_ai_obj_managedGroups select {isNull (_x getVariable ["objective", objNull])} apply {leader _x};

////////////////////////
// OBJECTIVE HANDLING //
////////////////////////
//Prune finished objectives
para_s_ai_obj_objectives = para_s_ai_obj_objectives select {!isNull _x};

////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////
// "Tick" objectives.
// run periodic code, such as updating its position.
call _fnc_obj_tick;

////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////
// Init/Deinit new/old objectives
private _activeObjectives = [_allPlayers] call _fnc_get_objs_active;
[_activeObjectives] call _fnc_obj_init_deinit;

////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////
// Get player counts within range of our objectives. Used to calculate global pool of AI.
// This implementation reduces the amount of AI we spawn on a point, but it should be more
// efficient than tracking all players in the server and assuming those players are nearby.
// -- 30 players back at base with 30 players in zone ==> 60 players in the old version
// -- 30 players back at base with 30 players in zone ==> 30 players in this version

para_s_ai_obj_debug && {diag_log "AI Obj: Finding valid players near enough to active objectives."};
para_s_ai_obj_tracked_players = call _fnc_get_players_in_range_of_obj;

para_s_ai_obj_debug && {
	diag_log format [
		"AI Obj: Current Headroom Stats: PoolSize=%1 UnitCount=%2 HardLimit=%3",
		call _fnc_get_pool_size,
		call _fnc_get_ai_count,
		para_s_ai_obj_hard_ai_limit
	];
};

////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////
// PRIORITISATION
// Prioritise objectives based on valid players near to an objective.
// This creates a normalised score (between 0 and 1) based on player count within an objective's
// activation radius -- default is para_s_ai_obj_activation_radius, but can be configured.
//
// The vanilla Mike Force implementation did this by binning objectives by radius of nearest
// player, and then allocating AI based on the total number of players within the activation
// radius, attempting to load balance the assignment of AI based on how close players are to an
// actual objective. 
//
// TODO: This is the important bit and I haven't explained why integer ranks are worse than
// real normalised vlaues
// The prioritisation was non-normalised interger values starting from 1. Which is usually
// problematic when we want things to "flow" more (?!).
//
// This version finds the total count of valid players within the objective's activation
// radius, then normalises by total of counts of players within any activation radius.
// IMPROTANT: we don't normalise by player count, but by the total times a player has been
// counted in an activation raidus -- this is what gives us the normalised score.
//
// TODO: We could add a second score for distance to nearest player, normalising by the
// activation radius. I would need to work out the best way to combine the two scores (simple
// addition or multiplication...?).
//

para_s_ai_obj_debug && {diag_log "AI Obj: Getting global pool size."};
private _globalPoolSize = call _fnc_get_pool_size;
para_s_ai_obj_debug && {
	diag_log format [
		"AI Obj: Initial job stats: players=%1 pool=%2 alive=%3 limit=%4 objs=%5",
		count para_s_ai_obj_tracked_players,
		_globalPoolSize,
		(call _fnc_get_ai_count),
		para_s_ai_obj_hard_ai_limit,
		count para_s_ai_obj_objectives
	]
};


para_s_ai_obj_debug && {diag_log "AI Obj: Getting per objective player counts."};
private _objectivesWithNearbyPlayerCounts = para_s_ai_obj_active_objectives apply {

	private _obj = _x;

	private _playerCount = _obj getVariable ["scaling_player_count_override", 0];
	if (_playerCount == 0) then
	{
		_playerCount = count (
			para_s_ai_obj_tracked_players inAreaArray [
				getPos _obj,
				para_s_ai_obj_activation_radius,
				para_s_ai_obj_activation_radius
			]
		);
	};

	_obj setVariable ["nearby_player_count", _playerCount];

	[_playerCount, _obj]
};

private _normalisationSum = 0;
_objectivesWithNearbyPlayerCounts apply {_normalisationSum = _normalisationSum + (_x select 0)};
private _normalisationSum = _normalisationSum max 1;  // avoid divide by zero

para_s_ai_obj_debug && {diag_log "AI Obj: Getting normalised player count score for objectives."};

private _objectivesWithNormalisedPlayerShare = _objectivesWithNearbyPlayerCounts apply {

	private _obj = _x select 1;
	private _playerCount = _x select 0;

	private _desiredUnitCount = _obj getVariable ["fixed_unit_count", 0];

	// if using fixed_unit_count then we don't *need* this, but it's useful to have in case
	// some new objective type wants to kill itself when there % players are nearby etc.
	private _normalisedPlayerShare = (_playerCount / _normalisationSum);
	_obj setVariable ["normalised_player_share", _normalisedPlayerShare];

	if (_desiredUnitCount == 0) then {
		// we cannot divide by total player count because
		// each objective will have counted the same player twice
		//
		// dividing by total times all players were counted returns
		// a normalised percentage of "nearby players" over an entire area.
		//
		// TODO: Heatmap Debug map markers.
		//
		// NOTE: a player being counted for multiple objectives is fine
		// they contribute to how active each of those objectives needs to be.
		// in truth, players determine how active an AREA needs to be.
		_desiredUnitCount = floor (_globalPoolSize * _normalisedPlayerShare);

		para_s_ai_obj_debug && {
			private _markerName = format ["para_s_ai_obj_debug_heatmap_%1", _obj getVariable "id"];

			if !(_markerName in allMapMarkers) then {deleteMarker _markerName};

			private _markerText = format ["OBJ: %1 SCORE: %2", _obj getVariable "id", _normalisedPlayerShare];
			private _marker = createMarkerLocal [_markerName, getPos _obj];
			_marker setMarkerAlphaLocal _normalisedPlayerShare;
			_marker setMarkerColorLocal "ColorBlue";
			_marker setMarkerShapeLocal "ELLIPSE";
			_marker setMarkerTextLocal _markerText;
			_marker setMarkerSize [
				_obj getVariable ["activation_radius", para_s_ai_obj_activation_radius],
				_obj getVariable ["activation_radius", para_s_ai_obj_activation_radius]
			];
			[_marker, "debug", _markerText] call para_c_fnc_zone_marker_add;
		};
	};

	_obj setVariable ["desired_unit_count", _desiredUnitCount];

	private _totalAliveUnits = 0;
	(_obj getVariable "assignedGroups") apply {_totalAliveUnits = _totalAliveUnits + ({alive _x} count units _x)};
	_obj setVariable ["total_alive_units", _totalAliveUnits];

	para_s_ai_obj_debug && {
		diag_log format [
			"AI Obj: %1: Updated player distribution score: share=%2 desired=%3 alive=%4",
			_obj getVariable "id",
			_normalisedPlayerShare,
			_desiredUnitCount,
			_totalAliveUnits
		];
	};


	[_normalisedPlayerShare, _obj]

};

// we have a 0-1 range, with 1 being the most important / highest priority

// lowest first --> low priotiry is things we can get rid of
_objectivesWithNormalisedPlayerShare sort true;
private _objectivesPrioritisedLowestFirst = +_objectivesWithNormalisedPlayerShare apply {_x select 1};

// highest first --> high priority is things we need to add to
private _objectivesPrioritisedHighestFirst = +_objectivesPrioritisedLowestFirst;
reverse _objectivesPrioritisedHighestFirst;

// diag_log format ["OBJS LOW: %1" , _objectivesPrioritisedLowestFirst];
// diag_log format ["OBJS HIGH: %1" , _objectivesPrioritisedHighestFirst];

para_s_ai_obj_debug && {diag_log "AI Obj: Determining ideal objective unit counts."};

////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////
// SCALE-IN GLOBAL AI COUNT.
// end the lowest priority objectives until we've purged enough AI units
// we **HAVE TO** remove these. we're exceeding our global pool.
// make sure we delete the groups and units immediately.

para_s_ai_obj_debug && {
	diag_log format [
		"AI Obj: Scaling-in global excess AI: objs=%1 pool=%2 ai=%3 excess=%4",
		count _objectivesPrioritisedLowestFirst,
		_globalPoolSize,
		call _fnc_get_ai_count,
		((call _fnc_get_ai_count) - _globalPoolSize) max 0
	];
};

private _purged = 0;
private _objectiveIdx = 0;

// overallocated, need to remove
// use a while to break out as early as possible
while {
	((call _fnc_get_ai_count) - _globalPoolSize) max 0 > 0
	&& {_objectiveIdx < (count _objectivesPrioritisedLowestFirst)}
} do {

	private _obj = _objectivesPrioritisedLowestFirst select _objectiveIdx;

	private _groupsToRemove = _obj getVariable ["assignedGroups", []] apply {
		[_x, _obj] call para_s_fnc_ai_obj_unassign_from_objective;
		private _grpLeader = leader _x;
		private _grp = group _grpLeader;
		_grp deleteGroupWhenEmpty true;
		units _grp apply {deleteVehicle _x};

		_purged = _purged + (count units _grp);

		_grp
	};

	para_s_ai_obj_managedGroups = para_s_ai_obj_managedGroups - _groupsToRemove;

	_objectiveIdx = _objectiveIdx + 1;

	para_s_ai_obj_debug && {
		diag_log format [
			"AI Obj: Scaling-in global excess AI: objId=%1 pool=%2 ai=%3 excess=%4 purged=%5",
			_obj getVariable "id",
			_globalPoolSize,
			call _fnc_get_ai_count,
			((call _fnc_get_ai_count) - _globalPoolSize) max 0,
			_purged
		];
	};

	uiSleep 0.001;
};

para_s_ai_obj_debug && {
	diag_log format [
		"AI Obj: Scaling-in global excess AI: objs=%1 pool=%2 ai=%3 excess=%4 purged=%5",
		count _objectivesPrioritisedLowestFirst,
		_globalPoolSize,
		call _fnc_get_ai_count,
		((call _fnc_get_ai_count) - _globalPoolSize) max 0,
		_purged
	];
};

////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////
// SCALE-IN AI OBJECTIVE GROUPS.
// find groups that are overallocated for their specific objective.
// these units might be directed to another nearby objective by pathing there.
// so do not purge them yet.

// TODO: 	@dijksterhuis: this does not deallocate groups based on changed priorities?
// 			we can end up with an objective on the other side of the zone filled with AI
//			and no nearby players.

// Amount of "flex" in the number of allocated units, before we decide to remove some.
// @dijksterhuis changed to 10% of objective total
private _assignedUnitFlex = 1.1;

para_s_ai_obj_debug && {
	diag_log format [
		"AI Obj: Freeing local excess AI: objs=%1 pool=%2 ai=%3",
		count _objectivesPrioritisedLowestFirst,
		_globalPoolSize,
		call _fnc_get_ai_count
	];
};

_objectivesPrioritisedLowestFirst apply {
	private _obj = _x;
	private _desiredUnitCount = _obj getVariable "desired_unit_count";
	private _totalAliveUnits = _obj getVariable "total_alive_units";
	private _assignedGroups = _obj getVariable ["assignedGroups", []];
	private _deallocateThreshold = _desiredUnitCount * _assignedUnitFlex;

	if (count _assignedGroups > 1 && {_totalAliveUnits > _deallocateThreshold}) then
	{
		private _grpIdx = 0;
		private _difference = _totalAliveUnits - _deallocateThreshold;

		// remove groups until we don't need to remove any more.
		while {_grpIdx < (count _assignedGroups) && {_difference <= 0}} do {

			private _grp = _assignedGroups select 0;

			[_grp, _obj] call para_s_fnc_ai_obj_unassign_from_objective;
			_freeGroupLeaders pushBack leader _grp;
			_difference = _difference - count units _grp;

			para_s_ai_obj_debug && {
				diag_log format [
					"AI Obj: Freeing local excess AI: obj=%1 pool=%2 ai=%3: Deallocating: unitDealloc=%4 desiredAlloc=%5 alive=%6",
					_obj getVariable "id",
					_globalPoolSize,
					call _fnc_get_ai_count,
					count units _grp,
					_desiredUnitCount,
					_totalAliveUnits
				];
			};

			_grpIdx = _grpIdx + 1;
			uiSleep 0.001;
		};
	};
};

para_s_ai_obj_debug && {
	diag_log format [
		"AI Obj: Freed local excess AI: objs=%1 pool=%2 ai=%3",
		count _objectivesPrioritisedLowestFirst,
		_globalPoolSize,
		call _fnc_get_ai_count
	];
};

////////////////////////////////////////////////////////////////////////////////////////////////
// SCALE-OUT GLOBAL AI COUNT VIA AI OBJECTIVE GROUPS

para_s_ai_obj_debug && {
	diag_log format [
		"AI Obj: Reallocating/Creating AI: objs=%1 pool=%2 ai=%3",
		count _objectivesPrioritisedLowestFirst,
		_globalPoolSize,
		call _fnc_get_ai_count
	];
};


//Now we go in order of highest priority, and allocate units where needed.
_objectivesPrioritisedHighestFirst apply {
	private _obj = _x;
	private _desiredUnitCount = _obj getVariable "desired_unit_count";

	private _availableReinforcements = [_obj, para_s_ai_obj_tracked_players] call para_s_fnc_ai_obj_available_reinforcements; 

	private _totalAliveUnits = _obj getVariable "total_alive_units";
	private _squadSize = _obj getVariable "squad_size";

	para_s_ai_obj_debug && {
		diag_log format [
			"AI Obj: Reallocating/Creating AI: obj=%1 pool=%2 ai=%3: init: alive=%4 availabeReinf=%5 desiredCount=%6",
			_obj getVariable "id",
			_globalPoolSize,
			call _fnc_get_ai_count,
			_totalAliveUnits,
			_availableReinforcements,
			_desiredUnitCount
		];
	};

	//Don't need to do anything if we have enough units. Let's roughly define that as 50% dead for now.
	if (_totalAliveUnits >= ceil (_desiredUnitCount * 0.5)) then {
		para_s_ai_obj_debug && {
			diag_log format [
				"AI Obj: Reallocating/Creating AI: obj=%1 pool=%2 ai=%3: obj has enough AI: alive=%4 thresh=%5 availabeReinf=%6 desiredCount=%7",
				_obj getVariable "id",
				_globalPoolSize,
				call _fnc_get_ai_count,
				_totalAliveUnits,
				ceil (_desiredUnitCount * 0.5),
				_availableReinforcements,
				_desiredUnitCount
			];
		};
		continue
	};

	////////////////////////////////////////////////////////////////////////////////////////////////
	// RETARGET EXISTING GROUPS WITHIN RANGE

	private _reinforcementsNeeded = _desiredUnitCount - _totalAliveUnits;

	private _reusableGroups = _freeGroupLeaders inAreaArray [getPos _obj, para_s_ai_obj_reinforce_reallocate_range, para_s_ai_obj_reinforce_reallocate_range] apply {group _x};
	private _reusedGroups = [];

	private _grpIdx = 0;

	while {_grpIdx < (count _reusableGroups) && {_reinforcementsNeeded > 0}} do {

		private _grp = _reusableGroups select 0;

		_reusedGroups pushBack _grp;

		[_grp, _obj] call para_s_fnc_ai_obj_assign_to_objective;
		_reinforcementsNeeded = _reinforcementsNeeded - count units _grp;

		para_s_ai_obj_debug && {
			diag_log format [
				"AI Obj %1: Reinforcing with %2 units from group %3",
				_obj getVariable "id",
				count units _grp,
				_grp
			];
		};

		_reusableGroups deleteAt 0;
		_grpIdx = _grpIdx +1;
		uiSleep 0.001;
	};

	_freeGroupLeaders = _freeGroupLeaders - (_reusedGroups apply {leader _x});

	para_s_ai_obj_debug && {
		diag_log format [
			"AI Obj: Reallocating/Creating AI: objs=%1 pool=%2 ai=%3: reallocated free AI: groupsAlloc=%4 groupsFree=%5",
			_obj getVariable "id",
			_globalPoolSize,
			call _fnc_get_ai_count,
			(call _fnc_get_ai_count),
			count _reusedGroups,
			count _freeGroupLeaders
		];
	};

	////////////////////////////////////////////////////////////////////////////////////////////////
	// SPAWN NEW AI GROUPS

	private _unitsRemainingInGlobalPool = _globalPoolSize - (call _fnc_get_ai_count);

	para_s_ai_obj_debug && {
		diag_log format [
			"AI Obj: Reallocating/Creating AI: objs=%1 pool=%2 ai=%3: Create new AI?: need=%4 availRein=%5 availGlobal=%6",
			_obj getVariable "id",
			_globalPoolSize,
			call _fnc_get_ai_count,
			_reinforcementsNeeded,
			_availableReinforcements,
			_unitsRemainingInGlobalPool
		];
	};

	//Still need more men - let's get some fresh ones.
	private _unitsToSendCount =
		_reinforcementsNeeded
		min
		_availableReinforcements
		min
		_unitsRemainingInGlobalPool
		max 0;

	// add reinforcements
	(_unitsToSendCount > 0) && {
		para_s_ai_obj_debug && {
			diag_log format [
				"AI Obj: Reallocating/Creating AI: objs=%1 pool=%2 ai=%3: Created new AI: need=%4 availRein=%5 availGlobal=%6 send=%7",
				_obj getVariable "id",
				_globalPoolSize,
				call _fnc_get_ai_count,
				_reinforcementsNeeded,
				_availableReinforcements,
				_unitsRemainingInGlobalPool,
				_unitsToSendCount
			];
		};

		[_obj, _unitsToSendCount, para_s_ai_obj_tracked_players] call para_s_fnc_ai_obj_reinforce;
	};
};


////////////////////////////////////////////////////////////////////////////////////////////////
// CLEAN UP

// finish objectives if possible
call _fnc_obj_finish;

//Add any unused groups to cleanup.
//Be wary of lingering AI squads being pinned in place by a single guy.
//Want to avoid the situation where one unit can stop 100 AI from being cleaned up
[_freeGroupLeaders] call _fnc_purge_groups;

para_s_ai_obj_debug && {
	diag_log format [
		"AI Obj: Final stats: PoolSize=%1 UnitCount=%2 HardLimit=%3 currentUnitCount=%4 Objectives=%5",
		_globalPoolSize,
		(call _fnc_get_ai_count),
		para_s_ai_obj_hard_ai_limit,
		(call _fnc_get_ai_count),
		count para_s_ai_obj_objectives
	];
};
