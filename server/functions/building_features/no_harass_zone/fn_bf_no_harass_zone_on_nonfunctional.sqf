/*
	File: fn_bf_no_harass_zone_on_nonfunctional.sqf
	Author: Tylervip
	Public: No

	Description:
		Cleans up the no-harass marker when the building stops being functional.

	Parameter(s):
		_building - Building that stopped being functional [OBJECT]

	Returns:
		Nothing
*/
params ["_building"];

[_building] call para_s_fnc_bf_no_harass_zone_cleanup;
