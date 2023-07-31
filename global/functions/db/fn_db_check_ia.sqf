/*
    File: fn_check_ia.sqf
    Author: Cerebral
    
    Description:
        Checks if player is ia.
    
    Parameter(s):
		_player - Player to check [UNIT]
    
    Returns:
	   	Is curator == true [BOOLEAN]
    
    Example(s):
		[_myPlayer] call para_g_fnc_db_check_ia
*/

params ["_player"];

private _curators = missionNamespace getVariable ["iaUIDs", []];
private _playerIsCurator = _curators findIf { _x == getPlayerUID _player} > -1;

_playerIsCurator