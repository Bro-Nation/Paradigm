/*
    File: fn_ai_obj_request_pursuit.sqf
    Author:  Savage Game Design
    Public: No
    
    Description:
		Requests the AI subsystem send units to pursue and engage a target.
    
    Parameter(s):
		_target - Array of Targets to pursue ARRAY[OBJECT]
		_scalingFactor - How hard this objective should be, used to multiply unit quantities [NUMBER]
		_reinforcementsFactor - How many reinforcements should be available. 
		_side - Side to create pursuers on [SIDE]
    
    Returns:
		None
    
    Example(s):
		[[player], 1, 1, east] call para_s_fnc_ai_obj_request_pursuit;
*/

params ["_targets", "_scalingFactor", ["_reinforcementsFactor", 1], ["_side", east]];

/*
	Set up the objective
*/
private _objective = ["pursue", getPos (_targets select 0)] call para_s_fnc_ai_obj_create_objective;
_objective setVariable ["scaling_player_count_override", count _targets];
_objective setVariable ["scaling_factor", _scalingFactor];
_objective setVariable ["reinforcements_factor", _reinforcementsFactor];
_objective setVariable ["squad_size", 4];
_objective setVariable ["squad_type", "PATROL"];
_objective setVariable ["enabled_spawn_types", ["FOOT"]];

_objective setVariable ["onAssignScript", {
	params ["_objective", "_group"];

	["AI: Pursuit: Squad beginning pursuit %1m from target", getPos leader _group distance2D (_objective getVariable "targets" select 0)] call BIS_fnc_logFormat;

	//Set the group's orders.
	_group setVariable ["orders", ["pursue", _objective getVariable "targets" select 0], true];
}];

_objective setVariable ["targets", _targets];

_objective setVariable ["onTick", {
	params ["_objective"];
	private _lastTargetPos = getPos _objective;

	/*
	Filter out targets (players) that are not
	- within specified radius of previous tracker team objective position
	- alive
	- outside blocked / no_harrass area markers (i.e. hanging around at the main base)
	*/
	private _targets = [
		(_objective getVariable "targets")
			inAreaArray [_lastTargetPos, para_s_ai_obj_pursuitRadius, para_s_ai_obj_pursuitRadius]
				select {alive _x}
	] call para_interop_fnc_harass_filter_target_players;

	//If we've lost the target, complete the pursuit.
	if (_targets isEqualTo []) exitWith {
		//No nearby players, finish the objective
		["AI: Pursuit: Objective [%1] lost target, completing objective", _objective getVariable "id"] call BIS_fnc_logFormat;
		//This WILL delete the objective
		[_objective] call para_s_fnc_ai_obj_finish_objective;
	};

	/*
	***************************************************************
	try to focus on a target that's not incapacitated with vn_revive.
	want to avoid AI standing around targets that are incapacitated
	while other targets nearby are active.

	***************************************************************
	NOTE: players who are incap but rolled over are counted as targets.
	they can shoot the AI -- so they are targets.
	***************************************************************
	*/
	private _targetIdx = _targets
		findIf {
			!([_x] call para_g_fnc_unit_is_incapacitated)
			|| ([_x] call para_g_fnc_unit_is_incapacitated_and_rolled)
		};

	/*
	***************************************************************
	everyone is incapacitated and has not rolled over, change the AI
	behaviour while no viable targets exist

	select all the current 'pursuit' groups to switch to something else.
	then update orders for each group to start patrolling or setting
	up ambushes around the area
	***************************************************************
	*/
	if (_targetIdx == -1) exitWith {

		private _targetsRaw = _objective getVariable "targets";

		/*
		***************************************************************
		conditional update depending on the first time we switch orders.

		means all the groups for this objective will always switch over
		to the same behaviour (ambush or patrol) because we really only
		set this the first time this code executes on this objective.
		***************************************************************
		*/

		private _modifiedOrders = _objective getVariable [
			"ordersModified",
			selectRandom [
				["ambush", getPos (_targetsRaw select 0)],
				["patrol", getPos (_targetsRaw select 0), 20 + (random 60)]
			]
		];
		_objective setVariable ["ordersModified", _modifiedOrders];


		/*
		***************************************************************
		get any group in this objective that hasn't had their orders
		switched yet

		this should safely pick up new groups as they're added and
		switch their orders
		***************************************************************
		force the group to come out of base arma combat behaviour.
		makes the group reliably switch behaviour to patrol/ambush.

		> Applying combat mode blue, clears the attack target
		> commands from AI subgroups
		> https://community.bistudio.com/wiki/setCombatMode

		otherwise they hang around on the player without ever patrolling,
		or they cling to the player after the first time a player tried
		to roll over and run away (when only setting WHITE).

		the AI will often run onto a newly incapped player first, but
		this is the best i can do.

		then finally apply the new orders, which the group can now pick
		up because we fully reset the combat mode.

		***************************************************************
		TODO: The fact the behaviour is being altered in objective
		code is really unclean as it doesn't properly separate the
		code functionality.

		I do not like it when the separation of concerns principle is
		not followed.
		***************************************************************
		*/

		(_objective getVariable "assignedGroups")
			select {
				((_x getVariable "orders") select 0) isEqualTo "pursue";
			}
			apply {
				if (combatMode _x != "WHITE") then {
					_x setCombatMode "BLUE";
					// group will now always switch to new orders now
					_x setCombatMode "WHITE";
				};

				_x setVariable [
					"orders",
					(_objective getVariable "ordersModified"),
					true
				];

			}
		;
	};

	// pursuit objective -- AI objective target pos is first non-incap target player
	private _target = _targets select _targetIdx;

	// Update objective position to be on the target, so it stays active.
	_objective setPos getPos _target;

	// Unassign groups that are too far away from the objective.
	private _groupsToUnassign = (_objective getVariable "assignedGroups")
		select {leader _x distance2D _target > para_s_ai_obj_maxPursuitDistance};
	[_groupsToUnassign, _objective] call para_s_fnc_ai_obj_unassign_from_objective;

	/*
	***************************************************************
	Update squad targets

	NOTE: When all targets were previously incap, and one is not incap now,
	this line switches all the AI pursuit groups out of 'patrol' and back into
	'pursue' mode
	***************************************************************
	*/
	(_objective getVariable "assignedGroups")
		apply {_x setVariable ["orders", ["pursue", _target], true]};
}];

_objective

