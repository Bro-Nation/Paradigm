/*
    File: fn_bf_coms_tower_on_placed.sqf
    Author: Legend
    Public: No

    Description:
        Called when the DAC Cong coms tower is first placed.
        Locks additional tower placement for the current AO.

    Parameter(s):
        _building - Building object [OBJECT]

    Returns:
        Nothing
*/

params ["_building"];

missionNamespace setVariable ["vn_mf_coms_tower_built_in_ao", true, true];
missionNamespace setVariable ["vn_mf_coms_tower_destroyed_in_ao", false, true];
