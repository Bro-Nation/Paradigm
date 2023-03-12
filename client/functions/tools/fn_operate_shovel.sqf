/*
    File: fn_operate_shovel.sqf
    Author:  Savage Game Design
    Modified: "DJ" Dijksterhuis
    Public: Yes
    
    Description:
        Executes "Shovel" behaviour for building.
    
    Parameter(s):
        _hitObject object to be built
    
    Returns:
        None
    
    Example(s):
        [_thingToWhack] call para_c_fnc_operate_shovel
*/

params ["_hitObject"];
// systemchat "SHOVEL";

private _building = _hitObject getVariable ["para_g_building", objNull];

// default build rate  5x shovel hits
private _buildRate = 0.2;

// does the boolean rate modifier trait exists on the player's team 
// if so, grant them a buffed build rate of 3x shovel hits
// (defined in mike-force/mission/config/subconfigs/teams.hpp)

if (player getUnitTrait "increasedBuildRate") then {_buildRate = 0.4};

["building_on_hit", [_building, _buildRate]] call para_c_fnc_call_on_server;
    
false