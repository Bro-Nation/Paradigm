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

deleteMarker format ["vn_mf_sr_tower_%1", netId _building];
[_building] call para_s_fnc_bf_soundranging_tower_on_nonfunctional;
