/*
    File: fn_operate_hammer.sqf
    Author:  Savage Game Design
    Modified: DJ Dijksterhuis
    Modified: Tylervip
    Public: Yes
    
    Description:
        Executes "Hammer" behaviour for building.
            Determine build rate based on whether the building is enemy-controlled
            about 5 hammer hits to tear down an friendly building
            about 20 hammer hits to tear down an enemy building
            increased build rate, 1 hammer hit to tear down a friendly building.
            increased build rate, 10 hammer hits to tear down an enemy building.
    
    Parameter(s):
        _hitObject object to be deconstructed
    
    Returns:
        None
    
    Example(s):
        [_thingToWhack] call para_c_fnc_operate_hammer
*/


params ["_hitObject"];

private _building = _hitObject getVariable ["para_g_building", objNull];
if (isNull _building) exitWith { false };

private _buildingSide = _building getVariable ["para_g_building_side", sideUnknown];
private _playerSide = side group player;
private _isEnemy = (_buildingSide != _playerSide && _buildingSide != sideUnknown);

private _buildRate = if (_isEnemy) then {0.05} else {0.2};

if (player getUnitTrait "increasedBuildRate") then {
	_buildRate = if (_isEnemy) then {0.1} else {1};
};

private _hasTrait = player getUnitTrait "increasedBuildRate";
["building_on_hit", [_building, -_buildRate, _hasTrait]] call para_c_fnc_call_on_server;

false

