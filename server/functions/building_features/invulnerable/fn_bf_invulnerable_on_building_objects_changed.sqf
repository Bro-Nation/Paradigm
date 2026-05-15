/*
    File: fn_bf_invulnerable_on_building_objects_changed.sqf
    Author:  Savage Game Design
    Public: No

    Description:
        Persists no-damage on all objects belonging to a building.

    Parameter(s):
        _building - Building whose objects have changed [NAMESPACE]
        _newObjects - New objects attached to the building [ARRAY]

    Returns:
        None

    Example(s):
        See building features config
*/

params ["_building", "_newObjects"];

{
	[_x, false] call para_s_fnc_allow_damage_persistent;
} forEach _newObjects;