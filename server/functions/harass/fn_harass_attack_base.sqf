/*
	File: fn_harass_create_squads.sqf
	Author: "DJ" dijksterhuis
	Public: No

	Description:
		This function should not be called outside of the AI subsystem.
		Assigns attack AI objectives over time to bases that are occupied by players.
		These attack objectives are never "freed" -- meaning the attack difficulty will scale over time.
		These palyers should not be assigned tracker team AI (pursuit objectives).

	Parameter(s):
		- _harrassablePlayers: array of players that are valid targets for harrsment

	Returns: List of all players that can be harrassed.

	Example(s):
		[allPlayers] call para_s_fnc_harass_create_squads;
*/

params ["_harrassablePlayers"];

private _playersActiveBaseHarrassment = para_g_bases apply {

	private _marker = _x getVariable "para_g_base_marker";
	private _players = _harassablePlayers inAreaArray _marker;
	private _lastAttack = _x getVariable ["harass_lastSent", 0];

	if (count _players > 0 && _lastAttack <= (serverTime - 10 * 60)) then {
		private _attackIntensity = 1;
		switch (missionNamespace getVariable ["para_s_time_of_day", "Day"]) do {
			case "Dawn": {_attackIntensity = 1};
			case "Day": {_attackIntensity = .75};
			case "Dusk": {_attackIntensity = 1.25};
			case "Night": {_attackIntensity = 1.5};
		};
		[getMarkerPos _marker, _attackIntensity, 1] call para_s_fnc_ai_obj_request_attack;
	};
	_x setVariable ["harass_lastSent", serverTime];
};

_playersActiveBaseHarrassment
