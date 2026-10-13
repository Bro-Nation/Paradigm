/*
	File: fn_bf_soundranging_tower_on_functional.sqf
	Author: Tylervip
	Public: No

	Description:
		Registers a sound-ranging tower when the building becomes functional.

	Parameter(s):
		_building - Building that became functional [OBJECT]

	Returns:
		Nothing
*/
params [["_building", objNull, [objNull]]];

if (!isServer) exitWith {};
if (isNull _building) exitWith {
	diag_log "[Sound Ranging] Cannot register a null tower";
};

if ((_building getVariable ["para_g_buildclass", ""]) isNotEqualTo "Land_vn_mobileradar_01_radar_f") exitWith {
	diag_log format ["[Sound Ranging] Refusing to register unexpected buildable %1", _building getVariable ["para_g_buildclass", ""]];
};

private _towers = missionNamespace getVariable ["vn_mf_soundranging_towers", []];
_towers pushBackUnique _building;
missionNamespace setVariable ["vn_mf_soundranging_towers", _towers];

diag_log format ["[Sound Ranging] Registered tower %1", _building];
