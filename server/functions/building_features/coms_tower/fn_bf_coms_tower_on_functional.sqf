/*
    File: fn_bf_coms_tower_on_functional.sqf
    Author: Legend
    Public: No

    Description:
        Called when the DAC Cong coms tower becomes functional.
        Sends a single mission notification and clears destroyed flag.

    Parameter(s):
        _building - Building object [OBJECT]

    Returns:
        Nothing
*/

params ["_building"];

missionNamespace setVariable ["vn_mf_coms_tower_built_in_ao", true, true];
missionNamespace setVariable ["vn_mf_coms_tower_destroyed_in_ao", false, true];

// Only send notification once per AO
if !(missionNamespace getVariable ["vn_mf_coms_tower_notified_in_ao", false]) then {
	missionNamespace setVariable ["vn_mf_coms_tower_notified_in_ao", true, true];
	["ComsTowerBuilt"] remoteExec ["para_c_fnc_show_notification", 0];
};
