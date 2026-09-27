/*
    File: fn_building_delete.sqf
    Author:  Savage Game Design
    Public: No

    Description:
        Deletes a building, specified by either the object or the building namespace.

    Parameter(s):
        _building - building to delete

    Returns:
        Function reached the end [BOOL]

    Example(s):
		[cursorObject] call para_s_fnc_building_delete
*/

//This file's "teardown" should be a mirror of placedbuilding, since this is essentially a destructor.

params ["_building"];

//Dismantle the building, don't bother updating the objects as they'll be deleted.
//This handles calling NonFunctional, as non-built buildings are non-functional.
//NonFunctional MUST BE CALLED.
[_building, -1, false] call para_s_fnc_building_add_build_progress;

[_building, "onBuildingDestroyed", [_building]] call para_g_fnc_building_fire_feature_event;

//Remove building from para_l_buildings
para_l_buildings = para_l_buildings - [_building];

//Disconnect from supply source.
[_building] call para_s_fnc_building_disconnect_supply_source;

private _base = _building getVariable ["para_g_base", objNull];
if !(_base isEqualTo objNull) then {
	[_building] call para_s_fnc_building_disconnect_base;
	private _buildableConfig = [_building] call para_g_fnc_get_building_config;
	private _isBaseStarter = isClass (_buildableConfig >> "features" >> "base_starter");
	if (_isBaseStarter) then {
		private _remainingStarters = (_base getVariable ["para_g_buildings", []]) select {
			if (isNull _x) exitWith {false};
			if !(_x getVariable ["para_g_building_constructed", false]) exitWith {false};
			private _cfg = [_x] call para_g_fnc_get_building_config;
			isClass (_cfg >> "features" >> "base_starter")
		};
		if (_remainingStarters isEqualTo []) then {
			[_base] call para_s_fnc_base_delete;
		};
	};
};

{
	deleteVehicle _x;
} forEach (_building getVariable ["para_g_objects", []]);

[_building] call para_g_fnc_delete_namespace;
