/*
    File: fn_bf_coms_tower_can_place_building.sqf
    Author: Legend
    Public: Yes

    Description:
        Checks if a coms tower can be placed in the active AO.
        Allows only one paradigm-built coms tower (including in-progress states) per AO.

    Parameter(s):
        _buildingConfig - Building config [CONFIG]
        _object - Main building object being placed [OBJECT]

    Returns:
        [_canPlace, _message] [ARRAY]
*/

params ["_buildingConfig", "_object"];

if !(markerExists "activeZoneCircle") exitWith {[true, ""]};

if (missionNamespace getVariable ["vn_mf_coms_tower_destroyed_in_ao", false]) exitWith {
    [false, localize "STR_vn_mf_buildingMenu_condition_comsTowerNotDestroyedInAO"]
};

private _center = markerPos "activeZoneCircle";
private _radius = selectMax ((getMarkerSize "activeZoneCircle") apply {abs _x});

private _existingTowers = (nearestObjects [
    _center,
    ["Land_vn_ttowersmall_2_f", "vn_ttowersmall_2_f_part0", "vn_ttowersmall_2_f_part1"],
    _radius,
    true
]) select {
    !isNull (_x getVariable ["para_g_building", objNull])
};

if (_existingTowers isNotEqualTo []) exitWith {
    [false, localize "STR_vn_mf_buildingMenu_condition_noComsTowerInAO"]
};

[true, ""]
