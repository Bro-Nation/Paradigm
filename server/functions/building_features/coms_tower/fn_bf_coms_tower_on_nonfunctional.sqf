/*
    File: fn_bf_coms_tower_on_nonfunctional.sqf
    Author: Legend
    Public: No

    Description:
        Called when the DAC Cong coms tower becomes nonfunctional.
        Nonfunctional includes states like manual deconstruction or supply decay,
        which must not be treated as "destroyed".

    Parameter(s):
        _building - Building object [OBJECT]

    Returns:
        Nothing
*/

params ["_building"];

missionNamespace setVariable ["vn_mf_coms_tower_built_in_ao", false, true];
// Preserve any explicit destroyed lock set by destruction workflows.
// Nonfunctional can be triggered by decay/deconstruction (should not force
// destroyed=true), but it must not clear a previously set destroyed=true.
private _destroyedInAO = missionNamespace getVariable ["vn_mf_coms_tower_destroyed_in_ao", false];
missionNamespace setVariable ["vn_mf_coms_tower_destroyed_in_ao", _destroyedInAO, true];
