/*
	File: fn_bf_no_harass_zone_on_functional.sqf
	Author: Tylervip
	Public: No

	Description:
		Creates a hidden no-harass marker and applies the Black Horse flag texture
		when the building becomes functional.

	Parameter(s):
		_building - Building that became functional [OBJECT]

	Returns:
		Nothing
*/
params ["_building"];

if !((_building getVariable ["para_s_no_harass_marker", ""]) isEqualTo "") exitWith {};

private _objects = _building getVariable ["para_g_objects", []];
private _flag = _objects param [0, objNull];
if (isNull _flag) exitWith {};

_flag setFlagAnimationPhase 1;
//I give up TODO figure out how to set flag texture on the server
//_flag setFlagTexture "custom\billboards\Blackhorse_bb.paa";


private _cfg = [_building] call para_g_fnc_get_building_config;
private _radius = getNumber (_cfg >> "features" >> "no_harass_zone" >> "radius");
if (_radius <= 0) then {
	_radius = 50;
};

private _id = _building getVariable ["para_s_building_id", round random 99999];
private _markerName = format ["FSB_bh_%1", _id];

createMarker [_markerName, getPosATL _flag];
_markerName setMarkerShape "ELLIPSE";
_markerName setMarkerSize [_radius, _radius];
_markerName setMarkerBrush "Solid";
_markerName setMarkerColor "ColorGreen";
_markerName setMarkerAlpha 0;

_building setVariable ["para_s_no_harass_marker", _markerName, true];

if (isNil "vn_mf_markers_no_harass") then {
	vn_mf_markers_no_harass = [];
};
if (isNil "vn_mf_markers_fsb") then {
	vn_mf_markers_fsb = [];
};

vn_mf_markers_no_harass pushBackUnique _markerName;
publicVariable "vn_mf_markers_no_harass";

vn_mf_markers_fsb pushBackUnique _markerName;
publicVariable "vn_mf_markers_fsb";
