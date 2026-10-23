/*
	File: fn_bf_soundranging_tower_on_deleted.sqf
	Author: Tylervip
	Public: No

	Description:
		Unregisters a sound-ranging tower when the building is deleted.

	Parameter(s):
		_building - Building that was deleted [OBJECT]

	Returns:
		Nothing
*/
params [["_building", objNull, [objNull]]];

if (!isServer) exitWith {};

private _markerName = format ["vn_mf_sr_tower_%1", netId _building];
deleteMarker _markerName;
missionNamespace setVariable [format ["vn_mf_sr_tower_side_%1", _markerName], nil];
publicVariable (format ["vn_mf_sr_tower_side_%1", _markerName]);
[_building] call para_s_fnc_bf_soundranging_tower_on_nonfunctional;
