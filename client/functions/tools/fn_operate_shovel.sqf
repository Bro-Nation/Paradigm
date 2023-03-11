/*
    File: fn_operate_shovel.sqf
    Author:  Savage Game Design // John The GI / DJ Dijksterhuis
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
private _currentTeam = player getVariable ["vn_mf_db_player_group", "MikeForce"];

// player should have been validated as a whitelist member when joining the group
// so no need to check whitelist again here

if !(_currentTeam in ["MikeForce", "GreenHornets", "ACAV", "SpikeTeam"]) then
{
    // 0.4 ==> 3x shovel hits to build up a structure
    ["building_on_hit", [_building, 0.4]] call para_c_fnc_call_on_server;
} 
else 
{
    // 0.2 ==> 5x shovel hits to build up a structure (the default vanilla Mike Force setting)
    ["building_on_hit", [_building, 0.2]] call para_c_fnc_call_on_server;
};

// without this the above function may get called about 7 times (see fn_operate_hammer.sqf)
false