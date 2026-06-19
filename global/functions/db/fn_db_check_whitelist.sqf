/*
    File: fn_check_whitelist.sqf
    Author: Cerebral
    
    Description:
        Checks whitelist to see if player can join team.
    
    Parameter(s):
		_player - Player to change to the team of [UNIT]
		_team - Name of the team to change to [STRING]
    
    Returns:
	   	Team join successful [BOOLEAN]
    
    Example(s):
		[_myPlayer, "ACAV"] call para_g_fnc_db_check_whitelist
*/

params ["_player", "_team"];

private _result = false;
private _defaultTeams = ["MikeForce", "GreenHornets", "ACAV", "SpikeTeam"];
private _playerUID = getPlayerUID _player;

if (_team isEqualTo "Instructors") then
{
	private _inWhitelist = false;
	{
		if ((_x find "whitelist_") isEqualTo 0) then {
			private _teamName = _x select [10];
			if !(_teamName in (_defaultTeams + ["Instructors"])) then {
				private _whitelist = missionNamespace getVariable [_x, []];
				if (_playerUID in _whitelist) exitWith {
					_inWhitelist = true;
				};
			};
		};
	} forEach allVariables missionNamespace;

	_result = _inWhitelist;
}
else
{
	if !(_team in _defaultTeams) then
	{
		private _whitelist = missionNamespace getVariable [format ["whitelist_%1", _team], []];
		private _inWhitelist = _playerUID in _whitelist;

		if (_inWhitelist) then {
			_result = true;
		} else {
			_result = false;
		};
	} else {
		_result = true;
	};
};

_result