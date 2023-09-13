/*
	File: fn_harass_pursuit.sqf
	Author: "DJ" Dijksterhuis
	Public: No

	Description:
		This function should not be called outside of the AI subsystem.
		Assigns pursuit AI (a.k.a. tracker teams to players) based on various conditions.

	Parameter(s):
		- harrassablePlayers: Array of players that could have pursuit / tracker team AI assigned to them

	Returns: Players with pursuit / tracker team AI objectives assigned to them, or to friendly players near them

	Example(s):
		[allPlayers] call para_s_fnc_harass_pursuit;
*/

params ["_harassablePlayers"];

private _lastPlayersToHarassLength = -1;

// @dijksterhuis: creating a new array here to avoid mutation of the original
// (I'm not 100% certain on how Arma variable namespace works)

private  _friendlyPlayersToHarass = +_harassablePlayers;

private _playersActivePursuitHarrassment = [];

//Start sending harass squads at players, updating the harassment values as we do.
//Abort if nothing was removed from the array, as a failsafe.

while {!(_friendlyPlayersToHarass isEqualTo []) && count _friendlyPlayersToHarass != _lastPlayersToHarassLength} do {

	_lastPlayersToHarassLength = count _friendlyPlayersToHarass;
	private _target = selectRandom _friendlyPlayersToHarass;

	private _nearbyPlayers = _target getVariable "harass_nearbyFriendlyPlayers";
	private _totalHarassment = 0;
	private _totalChallengeRating = 0;
	private _totalFrequencyMultiplier = 0;
	private _totalTimeSinceLastHarass = 0;

	{
		_totalHarassment = _totalHarassment + (_x getVariable "harass_level");
		private _difficulty = (_x call para_s_fnc_harass_calculate_difficulty);
		_totalChallengeRating = _totalChallengeRating + (_difficulty select 0);
		_totalFrequencyMultiplier = _totalFrequencyMultiplier + (_difficulty select 1);
		_totalTimeSinceLastHarass = _totalTimeSinceLastHarass + (serverTime - (_x getVariable ["harass_lastSent", 0]));
	} forEach _nearbyPlayers;

	private _averageHarassment = _totalHarassment / count _nearbyPlayers;
	private _averageChallengeRating = _totalChallengeRating / count _nearbyPlayers;
	private _averageFrequencyMultiplier = _totalFrequencyMultiplier / count _nearbyPlayers;
	private _averageTimeSinceLastHarass = _totalTimeSinceLastHarass / count _nearbyPlayers;
	/*["Group: %1", _nearbyPlayers apply {name _x}] call BIS_fnc_logFormat;
	["Average harassment: %1", _averageHarassment] call BIS_fnc_logFormat;
	["Average Challenge Rating: %1", _averageChallengeRating] call BIS_fnc_logFormat;
	["Average Frequency Multiplier: %1", _averageFrequencyMultiplier] call BIS_fnc_logFormat;
	["Average Time Since Last Harass: %1", _averageTimeSinceLastHarass] call BIS_fnc_logFormat;*/

	//Check whether it's been long enough, and we can send them.
	//Force a minimum delay, to avoid spamming players with AI.
	private _sufficientTimeHasPassed = _averageTimeSinceLastHarass > ((para_s_harassDelay * _averageFrequencyMultiplier) max para_s_harassMinDelay);

	//Don't need to update their harassment values, as we're just going to delete from the harass list.

	//Makes sure we have the minimum harassment to make it worthwhile to send a squad.
	private _challengeDifference = _averageChallengeRating - _averageHarassment;
	if (_sufficientTimeHasPassed && _averageHarassment <= 0.5) then {
		//Harassment is between 0 and 1, where 1 is 'optimally harassed'. Use it to set the difficulty parameter here.
		//["Requesting pursuit with %1 unit scaling", [count _nearbyPlayers, _challengeDifference]] call BIS_fnc_logFormat;
		private _enemySide = [_side, getPos _target] call para_interop_fnc_harass_get_enemy_side;
		[_nearbyPlayers, _challengeDifference, 1, _enemySide] call para_s_fnc_ai_obj_request_pursuit;

		private _time = serverTime;
		{
			_x setVariable ["harass_lastSent", _time];
			_x setVariable ["harass_lastHarassChallengeRating", _averageChallengeRating];
		} forEach _nearbyPlayers;
	};

	// push back flattened entries of players we've assigned pursuit AI to
	_nearbyPlayers apply {_playersActivePursuitHarrassment pushBack _x};

	_friendlyPlayersToHarass = _friendlyPlayersToHarass - _nearbyPlayers;
};

_playersActivePursuitHarrassment
