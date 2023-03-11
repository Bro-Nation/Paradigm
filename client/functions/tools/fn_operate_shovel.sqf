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

if !(_currentTeam in ["MikeForce", "GreenHornets", "ACAV", "SpikeTeam"]) then
{
	["building_on_hit", [_building, 0.4]] call para_c_fnc_call_on_server;
} 
else 
{
    ["building_on_hit", [_building, 0.2]] call para_c_fnc_call_on_server;
};

false