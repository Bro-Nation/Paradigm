/*
	File: fn_bf_no_harass_zone_on_deleted.sqf
	Author: Tylervip
	Public: No

	Description:
		Cleans up the no-harass marker when the building is deleted.

	Parameter(s):
		_building - Building that was deleted [OBJECT]

	Returns:
		Nothing
*/
params ["_building"];

[_building] call para_s_fnc_bf_no_harass_zone_cleanup;
