/*
	File: fn_building_change_objects.sqf
	Author:  Savage Game Design
	Public: No
	
	Description:
		Updates the list of objects associated with a building
	
	Parameter(s):
		_newObjects - New objects to assign to the building [ARRAY]
	
	Returns:
		None
	
	Example(s):
		[_building, [_object1]] call para_s_fnc_building_change_objects
*/
params ["_building", ["_newObjects", [], [[]]]];

_building setVariable ["para_g_objects", _newObjects, true];

{
	private _object = _x;
	if (isNull _object) then {continue};

	_object setVariable ["para_g_building", _building, true];

	if !(_object getVariable ["para_s_building_deleted_eh_registered", false]) then {
		_object setVariable ["para_s_building_deleted_eh_registered", true, true];
		_object addEventHandler ["Deleted", {
			params ["_object"];
			if (isNull _object) exitWith {};

			private _building = _object getVariable ["para_g_building", objNull];
			if (isNull _building) exitWith {};
			if (_building getVariable ["para_s_building_deleting", false]) exitWith {};
			if !(_object in (_building getVariable ["para_g_objects", []])) exitWith {};

			[_building] call para_s_fnc_building_delete;
		}];
	};

	//Use this remoteExec, so we can have several JIP'd remoteExecs on the same object.
	[[_object], "para_c_fnc_buildable_overlay_init", 0, _object] call para_s_fnc_remoteExec_jip_obj_stacked;
} forEach _newObjects;

[_building, "onBuildingObjectsChanged", [_building, _newObjects]] call para_g_fnc_building_fire_feature_event;