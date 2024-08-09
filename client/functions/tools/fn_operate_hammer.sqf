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

private _building = _hitObject getVariable ["para_g_building", objNull];

// default build rate 5x hammer hits to tear down to 0%
private _buildRate = 0.2;

// does the boolean rate modifier trait exists on the player's team
// if so, grant them a buffed teardown rate of 3x hammer hits to fully destroy
// (defined in mike-force/mission/config/subconfigs/teams.hpp)

if (player getUnitTrait "increasedBuildRate") then {_buildRate = 0.5};

["building_on_hit", [_building, -_buildRate]] call para_c_fnc_call_on_server;

/*
DO NOT DELETE ME!

IMPORTANT: @dijksterhuis: this `false` is 100% necessary to ensure we
return some boolean value to the scripted event handler code in fn_tool_controller_init.sqf!

without this we get a really nasty recursion bug where using the hammer will cause the
building to repeatedly decrease in build state after one hit (because the scripted event
handler keeps failing because of no return value!)
*/
false