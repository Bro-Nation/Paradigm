/*
	File: fn_ai_job.sqf
	Author:  Savage Game Design
	Public: No

	Description:
		Scheduler job for managing the AI.

		stuff. initial rework

	Parameter(s): none

	Returns: nothing

	Example(s): none
*/


////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////
// Server-only public variable overrides
// should be defined in the system init, but need to be switched if changing between different
// implementations live on the server

para_s_ai_obj_activation_radius = 600;
para_s_ai_obj_priority_radii = [200,300,400,500,para_s_ai_obj_activation_radius];
para_s_ai_obj_reinforce_block_direct_spawn_range = 600;
para_s_ai_obj_reinforce_reallocate_range = 600;
para_s_ai_obj_hard_ai_limit = para_s_ai_obj_config getOrDefault ["hardAiLimit", 80];
para_s_ai_obj_pursuitRadius = 300;
para_s_ai_obj_maxPursuitDistance = 1200;

// added
para_s_ai_obj_tracked_players = [];

private _debug = true;

private _fnc_get_players = {
	// allUnits select {isPlayer _x && {!(_x isKindOf "HeadlessClient_F")} && !(vehicle _x isKindOf "Plane") && (speed vehicle _x < 200) && !(side _x == east)}
	allUnits select {!(_x isKindOf "HeadlessClient_F") && !(vehicle _x isKindOf "Plane") && (speed vehicle _x < 200) && !(side _x == east)}
};

private _fnc_get_ai_count = {
	count (allUnits select {(side group _x == east) && (_x getVariable ["paradigm_managed", false])})
};


/*
this function is a very hacky estimation of a periodic convolutio between a monotonically
increasing linear function and a postive only step function.

It is hacky, but it avoids having to write an FFT implementation or dealing with integrals in convolutions.

We end up with something like this -- as palyers increase, so does amount of AI, with extra AI added at certain points.

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
// "Tick" objectives.
// run periodic code, such as updating its position.

_debug && {diag_log "AI Obj: Objective ticking."};

para_s_ai_obj_objectives apply {[_x] call (_x getVariable ["onTick", {}])};

_debug && {diag_log "AI Obj: Objective activation."};

// Determine active objectives
private _activeObjectives = para_s_ai_obj_objectives select {
	private _obj = _x;
	_allPlayers findIf {(_x distance2D _obj) < para_s_ai_obj_activation_radius} > -1
};

private _allPlayersInRange = _allPlayers select {
	private _player = _x;
	_activeObjectives findIf {_x distance2D _player < para_s_ai_obj_activation_radius} > -1;
};

para_s_ai_obj_tracked_players = _allPlayersInRange;

//Figure out which objectives have just been activated, and which have been de-activated.
//Risk of bouncing here - if players wander in and out of objective radius. Need to put a buffer in to minimise it.
private _newlyActiveObjectives = _activeObjectives - para_s_ai_obj_active_objectives;
private _deactivatedObjectives = para_s_ai_obj_active_objectives - _activeObjectives;
para_s_ai_obj_active_objectives = _activeObjectives;

_debug && {
	diag_log format ["AI Obj: Objectives to activate: %1", _newlyActiveObjectives apply {_x getVariable "id"}];
	diag_log format ["AI Obj: Objectives to deactivate: %1", _deactivatedObjectives apply {_x getVariable "id"}];
	diag_log format ["AI Obj: Objectives currently active: %1", _activeObjectives apply {_x getVariable "id"}];
};

_debug && {diag_log "AI Obj: Old objectives deactivating."};

//Deactivate objectives
_deactivatedObjectives apply {
	[_x] call (_x getVariable ["onDeactivation", {}]);
	private _assignedGroups = _x getVariable "assignedGroups";
	[_assignedGroups, _x] call para_s_fnc_ai_obj_unassign_from_objective;
	_freeGroupLeaders append (_assignedGroups apply {leader _x});
};

_debug && {diag_log "AI Obj: New objectives activating."};

//Activate new objectives
_newlyActiveObjectives apply {[_x] call (_x getVariable ["onActivation", {}])};

_debug && {
	diag_log format [
		"AI Obj: Current Headroom Stats: PoolSize=%1 UnitCount=%2 HardLimit=%3",
		call _fnc_get_pool_size,
		call _fnc_get_ai_count,
		para_s_ai_obj_hard_ai_limit
	];
};

private _globalPoolSize = call _fnc_get_pool_size;

/*
@dijksterhuis

HACK: pursuit objectives distance to player is ALWAYS within
the minimum `para_s_ai_obj_priority_radii` radius, so pursuit
objectives always end up highest priority.

instead of Mike Force sites being occupied by AI, or Mike Force
base attacks being an onslaught, we end up with a bunch of tracker
teams starving the AO of any defenses.

so force tracker team objectives to be priority 1 instead of 0
--> release tracker teams from player groups when all other
objectives are higher priority

with default configurations, this should mean when players are
within 300m of a site (minimum default value for
`para_s_ai_obj_priority_radii`), tracker teams should will back
off and give players some breathing room, before they encounter
a site and have to attack it. additionally, this gives the AI
tasked with defending the site time to move into the site to
defend it.

at the start of a mike force AO/Zone, this should mean AI will
start off by tracking palyers on the edge of the zone, then
reinforcing sites when players get closer.

TODO: attack objectives, similar to pursuit objectives, are always
highest priority.

for us to gain some room for other AI objective types (example:
defending an officer etc that spike tema need to go out and kill)
we can also set the attack types to priority 1 by default.

but i'm leaving this as is for now to test the pursuit changes
independently.

currently, if anyone steps out of the FOB during an attack then
they might get a bit bored due to tracker teams being deprioritised
versus attack objectives, but that's a consequence for the player
for going off-piste and lone-wolfing.
*/

_debug && {diag_log "AI Obj: Prioristing objectives."};

private _objectivesWithPriority = para_s_ai_obj_active_objectives apply {
	private _obj = _x;
	private _priority = -1;
	// TODO: We can ignore -1 priorities from findIf later...

	if ((_obj getVariable "type") == "pursue") then {_priority = 1} else {
		_priority = para_s_ai_obj_priority_radii findIf {
			private _radius = _x;
			_allPlayersInRange findIf {_x distance2D _obj < _radius} > -1
		};
		if (_priority isEqualTo -1) then {_priority = 9999};
	};

	_obj setVariable ["priority", _priority];
	[_priority, _obj]
};

//Sort by priority
_objectivesWithPriority sort true;

//Filter out the objective objects
private _objectivesPrioritisedHighestFirst = _objectivesWithPriority apply {_x # 1};

_debug && {diag_log "AI Obj: Determining ideal objective unit counts."};

//Calculate the numbers we need to make informed decisions about each zone.
_objectivesPrioritisedHighestFirst apply {
	private _obj = _x;

	private _playerCount = _obj getVariable ["scaling_player_count_override", 0];
	if (_playerCount == 0) then
	{
		_playerCount = count (_allPlayersInRange inAreaArray [getPos _obj, para_s_ai_obj_activation_radius, para_s_ai_obj_activation_radius]);
	};

	_obj setVariable ["nearby_player_count", _playerCount];

	private _desiredUnitCount = _obj getVariable ["fixed_unit_count", 0];
	if (_desiredUnitCount == 0) then {
		private _priority = _obj getVariable "priority";

		//LOD multiplier - distant objectives need fewer units, as they're less likely to be targeted.
		//This is a terrible way of calculating the LOD multiplier, but it's hacky and works for now.
		//Priorities can start at 0, so we need to add 1.

		// TODO: @dijksterhuis: This needs to be worked on.
		//		Annoyingly, multivariate ranking is a fairly hard problem to solve.
		// 		This really should be something like ratio of players to objectives?

		private _LODMultiplier = 1 / (_priority + 1);
		private _scalingFactor = (_obj getVariable "scaling_factor") * _LODMultiplier;
		_desiredUnitCount = [_playerCount, _scalingFactor] call para_g_fnc_ai_scale_to_player_count;

		/*diag_log format [
			"AI Obj %1: Players: %2, Scaling Factor: %3, LOD Multiplier: %4",
			_obj getVariable "id",
			_playerCount,
			_scalingFactor,
			_LODMultiplier
		];*/
	};

	_obj setVariable ["desired_unit_count", _desiredUnitCount];

	private _totalAliveUnits = 0;
	(_obj getVariable "assignedGroups") apply {_totalAliveUnits = _totalAliveUnits + ({alive _x} count units _x)};
	_obj setVariable ["total_alive_units", _totalAliveUnits];
};

//First, work backwards down the priority list, de-allocating groups from over-staffed objectives.
//These free groups can then be re-allocated where needed, starting with high priority objectives.
private _objectivesPrioritisedLowestFirst = +_objectivesPrioritisedHighestFirst;
reverse _objectivesPrioritisedLowestFirst;

////////////////////////////////////////////////////////////////////////////////////////////////
// SCALE-IN GLOBAL AI COUNT.
// end the lowest priority objectives until we've purged enough AI units
// we **HAVE TO** remove these. we're exceeding our global pool.
// make sure we delete the groups and units immediately.

_debug && {
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
	uiSleep 0.001;

	_debug && {
		diag_log format [
			"AI Obj: Scaling-in global excess AI: objId=%1 pool=%2 ai=%3 excess=%4 purged=%5",
			_obj getVariable "id",
			_globalPoolSize,
			call _fnc_get_ai_count,
			((call _fnc_get_ai_count) - _globalPoolSize) max 0,
			_purged
		];
	};
};

_debug && {
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
// SCALE-IN AI OBJECTIVE GROUPS.
// find groups that are overallocated for their specific objective.
// these units can be reallocated somewhere else, so do not purge them

//TODO: @dijksterhuis: this does not deallocate groups based on changed priorities?
// 		we can end up with an objective on the other side of the zone filled with AI
//		and no nearby players.

//Amount of "flex" in the number of allocated units, before we decide to remove some.
// @dijksterhuis changed to 10% of objective total
private _assignedUnitFlex = 1.1;

// who has stuff
// who needs stuff

// private _has = _objectivesPrioritisedLowestFirst apply {
// 	[_obj, _obj getVariable "total_alive_units"]
// };

// private _needs = _objectivesPrioritisedLowestFirst apply {
// 	[_obj, _obj getVariable "total_alive_units"]
// };

// unassign based on average of poll count / active objectives?

// if we were to go through and allocate everything from sctach, how would that look?
// ratio out of ai assignment per priority band
// then deallocate.
// then allocate

// normalised scores!


// _objectivesPrioritisedHighestFirst apply {};

_debug && {
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

	if (_totalAliveUnits > _deallocateThreshold && count _assignedGroups > 1) then
	{
		//This is a dumb algorithm. We remove groups until we don't need to remove any more.
		private _difference = _totalAliveUnits - _deallocateThreshold;
		_assignedGroups apply {
			//If we've deallocated enough units, stop deallocating.
			if (_difference <= 0) exitWith {};
			[_x, _obj] call para_s_fnc_ai_obj_unassign_from_objective;
			_freeGroupLeaders pushBack leader _x;
			_difference = _difference - count units _x;
			/*diag_log format [
				"AI Obj %1: Deallocating %2 units from group %3. Desired: %4, has %5",
				_obj getVariable "id",
				count units _x,
				_x,
				_desiredUnitCount,
				_totalAliveUnits
			];*/

			_debug && {
				diag_log format [
					"AI Obj: Freeing local excess AI: obj=%1 pool=%2 ai=%3: Deallocating: unitDealloc=%4 desiredAlloc=%5 alive=%6",
					_obj getVariable "id",
					_globalPoolSize,
					call _fnc_get_ai_count,
					count units _x,
					_desiredUnitCount,
					_totalAliveUnits
				];
			};
		};
	};
};

_debug && {
	diag_log format [
		"AI Obj: Freed local excess AI: objs=%1 pool=%2 ai=%3",
		count _objectivesPrioritisedLowestFirst,
		_globalPoolSize,
		call _fnc_get_ai_count
	];
};

////////////////////////////////////////////////////////////////////////////////////////////////
// SCALE-OUT GLOBAL AI COUNT VIA AI OBJECTIVE GROUPS

_debug && {
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

	private _availableReinforcements = [_obj, _allPlayersInRange] call para_s_fnc_ai_obj_available_reinforcements; 

	private _totalAliveUnits = _obj getVariable "total_alive_units";
	private _squadSize = _obj getVariable "squad_size";

	//Don't need to do anything if we have enough units. Let's roughly define that as 50% dead for now.
	if (_totalAliveUnits >= _desiredUnitCount * 0.5) then {
		_debug && {
			diag_log format [
				"AI Obj: Reallocating/Creating AI: obj=%1 pool=%2 ai=%3: obj has enough AI: alive=%4 thresh=%5",
				_obj getVariable "id",
				_globalPoolSize,
				call _fnc_get_ai_count,
				_totalAliveUnits,
				_totalAliveUnits >= _desiredUnitCount * 0.5
			];
		};
		continue;
	};

	////////////////////////////////////////////////////////////////////////////////////////////////
	// RETARGET EXISTING GROUPS WITHIN RANGE

	private _reinforcementsNeeded = _desiredUnitCount - _totalAliveUnits;

	private _reusableGroups = _freeGroupLeaders inAreaArray [getPos _obj, para_s_ai_obj_reinforce_reallocate_range, para_s_ai_obj_reinforce_reallocate_range] apply {group _x};
	private _reusedGroups = [];

	if (_reinforcementsNeeded > 0) then {
		_reusableGroups apply {
			if (count units _x <= (_reinforcementsNeeded * _assignedUnitFlex)) then
			{
				_reusedGroups pushBack _x;
				[_x, _obj] call para_s_fnc_ai_obj_assign_to_objective;
				_reinforcementsNeeded = _reinforcementsNeeded - count units _x;

				_debug && {
					diag_log format [
						"AI Obj %1: Reinforcing with %2 units from group %3",
						_obj getVariable "id",
						count units _x,
						_x
					];
				};
			};
		};
	};

	_freeGroupLeaders = _freeGroupLeaders - (_reusedGroups apply {leader _x});

	_debug && {
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

	_debug && {
		diag_log format [
			"AI Obj: Reallocating/Creating AI: objs=%1 pool=%2 ai=%3: Create new AI?: need=%4 availRein=%5 availGlobal=%6",
			_obj getVariable "id",
			_globalPoolSize,
			call _fnc_get_ai_count,
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

	//No reinforcements needed at all - great, let's exit.
	if (_unitsToSendCount > 1) exitWith {
		_debug && {
			diag_log format [
				"AI Obj: Reallocating/Creating AI: objs=%1 pool=%2 ai=%3: Created new AI: need=%4  availRein=%5 availGlobal=%6 send=%7",
				_obj getVariable "id",
				_globalPoolSize,
				call _fnc_get_ai_count,
				call _fnc_get_ai_count,
				_reinforcementsNeeded,
				_availableReinforcements,
				_unitsRemainingInGlobalPool,
				_unitsToSendCount
			];
		};

		[_obj, _unitsToSendCount] call para_s_fnc_ai_obj_reinforce;
	};
};

// Finish any objectives that haven't got any AI left.
para_s_ai_obj_objectives select {
	_x getVariable ["reinforcements_remaining", 0] <= 0
} apply {
	[_x] call para_s_fnc_ai_obj_finish_objective;

	_debug && {
		diag_log format [
			"AI Obj: Finishing objectives: obj=%1",
			_obj getVariable "id"
		];
	};

	_x
};

_debug && {
	diag_log format [
		"AI Obj: Removing free groups: groupsRemove=%1 managedGroups=%2",
		count _freeGroupLeaders,
		count para_s_ai_obj_managedGroups
	];
};

//Add any unused groups to cleanup.
//Be wary of lingering AI squads being pinned in place by a single guy.
//Want to avoid the situation where one unit can stop 100 AI from being cleaned up
private _groupsToRemove = _freeGroupLeaders apply {

	private _group = group _x;
	_group deleteGroupWhenEmpty true;
	[units _group] call para_s_fnc_cleanup_add_items;
	units _group apply { deleteVehicle _x };

	_group
};

para_s_ai_obj_managedGroups = para_s_ai_obj_managedGroups - _groupsToRemove;

_debug && {
	diag_log format [
		"AI Obj: Removed free groups: groupsRemove=%1 managedGroups=%2",
		count _freeGroupLeaders,
		count para_s_ai_obj_managedGroups
	];
};

_debug && {
	diag_log format [
		"AI Obj: Final stats: PoolSize=%1 UnitCount=%2 HardLimit=%3 currentUnitCount=%4 Objectives=%5",
		_globalPoolSize,
		(call _fnc_get_ai_count),
		para_s_ai_obj_hard_ai_limit,
		(call _fnc_get_ai_count),
		count para_s_ai_obj_objectives
	];
};
