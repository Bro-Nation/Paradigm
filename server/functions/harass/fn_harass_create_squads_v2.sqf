/*
	File: fn_harass_create_squads_v2.sqf
	Author:  Savage Game Design
	Modified: "DJ" Dijksterhuis
	Public: No

	Description:
		This function should not be called outside of the AI subsystem.
		Maintains the dynamic harass squads that attack players in the field.
		Sets a 'harass level' on players, to mark how harassed they are right now. '1' is the target.
		Less than 1 is under-harassed, more than 1 is over-harassed.

	Parameter(s): none

	Returns: nothing

	Example(s):
		// runs logic once
		call para_s_fnc_harass_create_squads_v2;
*/
{
	private _side = _x;
	private _enemySides = [west, east, independent, civilian] select {_x getFriend _side < 0.6};
	private _friendlyPlayers = playableUnits select {side group _x == _side};
	private _enemyUnits = allUnits select {alive _x && (side group _x in _enemySides)};
	private _harassTraitSet = false;

	//Figure out if harassTraitSet is True
	(getAllUnitTraits player) apply {if("harrassable" in _x) exitWith {_harassTraitSet = true}};

	//Figure out which players can be harassed
	private _harassablePlayers = _friendlyPlayers select {
		private _player = _x;
		alive _player
		//!(Player is in a vehicle and travelling over 29 km/h) - Don't harass moving vehicles.
		&& !(vehicle _player != _player && (canMove vehicle _player))
		//Player is on a combat side.
		&& side group _player in [west, east, independent]
		//Player has harrass flag set as true
		&& (_player getUnitTrait "harassable")
	};

	_harassablePlayers = [_harassablePlayers] call para_interop_fnc_harass_filter_target_players;

	//Initialise the harassment variables for all players - we'll be using them later.
	{
		private _enemiesInArea = (_enemyUnits inAreaArray [getPos _x, 200, 200]);
		private _friendlyPlayersInArea = (_harassablePlayers inAreaArray [getPos _x, 200, 200]);

		_x setVariable ["harass_level", 0];
		//Only records harassable players. This avoids us messing around with people in aircraft, etc.
		_x setVariable ["harass_nearbyFriendlyPlayers", _friendlyPlayersInArea];
		_x setVariable ["harass_nearbyEnemies", _enemiesInArea];
	} forEach _friendlyPlayers;

	//Calculate the current harassment level for each player.
	//Factor in nearby allies, nearby enemies, and enemies currently on their way to them (where possible).
	private _aiPerChallengeLevel = [1, 1] call para_g_fnc_ai_scale_to_player_count;
	{
		//Apply a value that decreases over time, if they've had harass squads recently sent.
		//Avoids saturating a player with harass squads, since we don't count squads that are more than X m away,
		//It's theoretically possible there's an entire attack on its way
		//If harass delay is too short, we risk spamming the players with AI.

		private _enemyRatioComponent =
			(count (_x getVariable "harass_nearbyEnemies") /  count (_x getVariable "harass_nearbyFriendlyPlayers"))
			/ _aiPerChallengeLevel;

		_x setVariable ["harass_level", _enemyRatioComponent];
	} forEach _harassablePlayers;

	// Keep occupied FOBs harassed
	private _playersHarrassedBaseAttacks = [_harassablePlayers] call para_s_fnc_harass_attack_base;

	// Find players that aren't
	// - harassed enough by tracker teams
	// - being harrased by base attacks

	private _friendlyPlayersToHarass = _harassablePlayers select {_x getVariable "harass_level" < 1};
	private _playersToPursueHarrass = _friendlyPlayersToHarass - _playersHarrassedBaseAttacks;

	private _playersHarrassedPursuits = [_playersToPursueHarrass] call para_s_fnc_harass_pursuit;

} forEach [west, east, independent];

