/*
    File: fn_operate_hammer.sqf
    Author:  Savage Game Design
    Modified: DJ Dijksterhuis
    Public: Yes
    
    Description:
        Executes "Hammer" behaviour for building.
    
    Parameter(s):
        _hitObject object to be deconstructed
    
    Returns:
        None
    
    Example(s):
        [_thingToWhack] call para_c_fnc_operate_hammer
*/


params ["_hitObject"];
// systemchat "HAMMER";

private _building = _hitObject getVariable ["para_g_building", objNull];
if (isNull _building) exitWith { false };

// default build rate 5x hammer hits to tear down to 0%
private _buildRate = 0.2;

// does the boolean rate modifier trait exists on the player's team
// if so, grant them a buffed teardown rate of 1x hammer hit to fully destroy
// (defined in mike-force/mission/config/subconfigs/teams.hpp)

if (player getUnitTrait "increasedBuildRate") then {_buildRate = 1};

private _hasTrait = player getUnitTrait "increasedBuildRate";
["building_on_hit", [_building, -_buildRate, _hasTrait]] call para_c_fnc_call_on_server;

false

