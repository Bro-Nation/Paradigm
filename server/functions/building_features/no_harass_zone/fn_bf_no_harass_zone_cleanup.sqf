/*
	File: fn_bf_no_harass_zone_cleanup.sqf
	Author: Tylervip
	Public: No

	Description:
		Deletes the building's no-harass marker and removes it from the shared list.

	Parameter(s):
		_building - Building that owns the marker [OBJECT]

	Returns:
		Nothing
*/
params ["_building"];

private _markerName = _building getVariable ["para_s_no_harass_marker", ""];
if (_markerName isEqualTo "") exitWith {};

deleteMarker _markerName;

if !(isNil "vn_mf_markers_no_harass") then {
	vn_mf_markers_no_harass = vn_mf_markers_no_harass - [_markerName];
	publicVariable "vn_mf_markers_no_harass";
};

if !(isNil "vn_mf_markers_fsb") then {
	vn_mf_markers_fsb = vn_mf_markers_fsb - [_markerName];
	publicVariable "vn_mf_markers_fsb";
};

_building setVariable ["para_s_no_harass_marker", nil, true];
