/*
	File: fn_bf_soundranging_radio_on_functional.sqf
	Author: Tylervip
	Public: No

	Description:
		Enables the sound-ranging action when a radio building becomes functional.

	Parameter(s):
		_building - Building that became functional [OBJECT]

	Returns:
		Nothing
*/
params [["_building", objNull, [objNull]]];

if (!isServer) exitWith {};
if (isNull _building) exitWith {
	diag_log "[Sound Ranging] Cannot enable a radio action for a null building";
};

private _radio = (_building getVariable ["para_g_objects", []]) param [0, objNull];
if (isNull _radio || {typeOf _radio isNotEqualTo "vn_b_prop_vrc12"}) exitWith {
	diag_log format ["[Sound Ranging] Functional radio building has no VRC-12 object: %1", _building];
};

[[_radio], "vn_mf_fnc_soundranging_add_radio_action", 0, _radio] call para_s_fnc_remoteExec_jip_obj_stacked;
