/*
	File: fn_bf_soundranging_tower_on_functional.sqf
	Author: Tylervip
	Public: No

	Description:
		Registers a sound-ranging tower when the building becomes functional.
			The tower marker is tagged for West visibility only.

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

// Global marker persists until the building is removed (see tower_on_deleted)
private _markerName = format ["vn_mf_sr_tower_%1", netId _building];
if (markerType _markerName isEqualTo "") then {
	private _tower = (_building getVariable ["para_g_objects", []]) param [0, _building];
	createMarker [_markerName, getPosATL _tower];
	_markerName setMarkerType "loc_Transmitter";
	_markerName setMarkerColor "ColorOrange";
	_markerName setMarkerText "";
	missionNamespace setVariable [format ["vn_mf_sr_tower_side_%1", _markerName], west];
	publicVariable (format ["vn_mf_sr_tower_side_%1", _markerName]);
};

diag_log format ["[Sound Ranging] Registered tower %1", _building];
