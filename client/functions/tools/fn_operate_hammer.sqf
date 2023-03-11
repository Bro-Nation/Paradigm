/*
    File: fn_operate_hammer.sqf
    Author:  Savage Game Design
    Modified: DJ Dijksterhuis
    Public: Yes
    
    Description:
        Executes "Hammer" behaviour for building.
        
        NOTE: Vanilla Mike Force resource depletion rate is -0.5.
    
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
private _currentTeam = player getVariable ["vn_mf_db_player_group", "MikeForce"];

// player should have been validated as a whitelist member when joining the group
// so no need to check whitelist again here

if (_currentTeam in ["MikeForce", "GreenHornets", "ACAV", "SpikeTeam"]) then
{
    // 0.2 ==> 5x hammer hits to destroy a structure
    ["building_on_hit", [_building, -0.2]] call para_c_fnc_call_on_server;
} 
else 
{
    // 0.4 ==> 3x hammer hits to destroy a structure
    ["building_on_hit", [_building, -0.4]] call para_c_fnc_call_on_server;
};

// without this the above function may get called about 7 times
false