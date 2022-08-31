/*
    File: fn_operate_hammer.sqf
    Author:  Savage Game Design
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
["building_on_hit", [_building, -0.5]] call para_c_fnc_call_on_server;
false; //without this the above function gets called about 7 times
// systemChat "WRENCH";