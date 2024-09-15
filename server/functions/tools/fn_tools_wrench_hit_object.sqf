/*
    File: fn_tools_wrench_hit_object.sqf
    Author: @dijksterhuis
    Public: Yes
    
    Description:
        Executes "Wrench" behaviour server side
        to ensure clients can't use setDamage
    
    Parameter(s):
        _hitObject object to be analysed
    
    Returns:
        None
    
    Example(s):
        [_thingToWhack, player] remoteExec ["para_s_fnc_tools_wrench_hit_object", 2];
*/

params ["_hitObject", "_player"];

// beyond repair
if ((damage _hitObject) >= 1)) exitWith {nil};

// not a vehicle
if !((_hitObject isKindOf "Air") || (_hitObject isKindOf "LandVehicle")) exitWith {nil};

// player doesn't have a toolkit
if !(("vn_b_item_toolkit" in (items _player)) || ("ToolKit" in (items _player))) exitWith {nil};

_newDmg = ((damage _hitObject) - 0.05);
_hitObject setDamage _newDmg;
