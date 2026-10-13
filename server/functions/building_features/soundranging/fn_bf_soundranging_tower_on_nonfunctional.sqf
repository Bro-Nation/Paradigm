/*
	File: fn_bf_soundranging_tower_on_nonfunctional.sqf
	Author: Tylervip
	Public: No

	Description:
		Unregisters a sound-ranging tower when the building stops being functional.

	Parameter(s):
		_building - Building that stopped being functional [OBJECT]

	Returns:
		Nothing
*/
params [["_building", objNull, [objNull]]];

if (!isServer) exitWith {};
if (isNull _building) exitWith {
	diag_log "[Sound Ranging] Cannot unregister a null tower";
};

private _towers = missionNamespace getVariable ["vn_mf_soundranging_towers", []];
_towers = _towers select {
	!isNull _x && {!(_x isEqualTo _building)}
};
missionNamespace setVariable ["vn_mf_soundranging_towers", _towers];
