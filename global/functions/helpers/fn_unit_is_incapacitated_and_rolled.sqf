/*
	File: fn_unit_is_incapacitated_and_rolled.sqf
	Author: @dijksterhuis
	
	Description:
		Returns whether the unit is in the incapacitated state
	
	Parameter(s):
		_unit - Unit to check against [OBJECT]
	
	Returns: boolean
	
	Example(s):
		[_unit] call para_g_fnc_unit_is_incapacitated_and_rolled;
*/

params ["_unit"];
private _isIncap = [_unit] call para_g_fnc_unit_is_incapacitated;

(_isIncap && (_unit getVariable ["vn_revive_incapacitated_mobile", false]));
