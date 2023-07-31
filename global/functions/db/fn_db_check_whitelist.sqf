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

private _result = true;
if !(_team in ["MikeForce", "GreenHornets", "ACAV", "SpikeTeam"]) then
{
	private _playerUID = getPlayerUID _player;
	private _whitelist = missionNamespace getVariable [format ["whitelist_%1", _team], []];
	private _inWhitelist = _playerUID in _whitelist;

	if (!(_inWhitelist)) then {
		_result = false;
	};
};

_result