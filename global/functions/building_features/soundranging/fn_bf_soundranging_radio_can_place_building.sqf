/*
	File: fn_bf_soundranging_radio_can_place_building.sqf
	Author: Tylervip
	Public: Yes

	Description:
		Restricts Recon Radio placement to an active Fire Support Base area.

	Parameter(s):
		_buildingConfig - Building config [CONFIG]
		_object - Radio placement preview object [OBJECT]

	Returns:
		[_canPlace, _message] [ARRAY]
*/
params ["_buildingConfig", "_object"];

if (isNull _object) exitWith {
	[false, localize "STR_vn_mf_buildingMenu_condition_inFSB"]
};

private _fsbMarkers = missionNamespace getVariable ["vn_mf_markers_fsb", []];
private _fsbIndex = _fsbMarkers findIf {
	(((_x find "fsb_") isEqualTo 0) || {(_x find "FSB_bh_") isEqualTo 0} || {(_x find "no_harass_bh_") isEqualTo 0}) && {_object inArea _x}
};

if (_fsbIndex < 0) exitWith {
	[false, localize "STR_vn_mf_buildingMenu_condition_inFSB"]
};

[true, ""]
