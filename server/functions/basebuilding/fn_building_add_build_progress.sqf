/*
    File: fn_building_add_build_progress.sqf
    Author:  Savage Game Design
    Public: Yes
    
    Description:
		Adds to the build progress of a building
    
    Parameter(s):
        _building - Building to set the build progress on [OBJECT]
        _delta - Build progress change between 0 and 1 [NUMBER]
        _updateObjects - Whether or not to update the objects to reflect the new build progress [BOOLEAN]
    
    Returns:
        None
    
    Example(s):
        [_building, 1] call para_s_fnc_building_add_build_progress
*/

params ["_building", "_delta", ["_updateObjects", true]];

private _fnc_debug_message = {
	// player hosted server debug messages only
	// (this is called server side so should only run when executed locally)
	if (hasInterface) then {
		_this spawn {
			diag_log format [
				"Building hit: delta=%1 old=%2 new=%3 state=%4",
				_this # 0,
				_this # 1,
				_this # 2,
				_this # 3
			];
			hint format [
				"Building hit: delta=%1 old=%2 new=%3 state=%4",
				_this # 0,
				_this # 1,
				_this # 2,
				_this # 3
			];
			sleep 15;
			hintSilent "";
		};
	};
};

private _old = _building getVariable ["para_g_build_progress", 0];
private _new = _old + _delta;
_building setVariable ["para_g_build_progress", _new min 1 max 0, true];

// Building has been built.
if (_new >= 1 && _old < 1) exitWith
{
	[_building, _updateObjects] call para_s_fnc_building_on_constructed;
	[_delta, _old, _new, "constructed"] call _fnc_debug_message;
};

// Building has been dismantled from a built state.
if (_new < 1 && _old >= 1) exitWith
{
	[_building, _updateObjects] call para_s_fnc_building_on_deconstructed;
	[_delta, _old, _new, "deconstructed"] call _fnc_debug_message;
};

// Negative build state means we've hammered it out of life -- delete it
if (_new < 0 && _old > 0) exitWith
{
	[_building] call para_s_fnc_building_delete;
	[_delta, _old, _new, "deleted"] call _fnc_debug_message;
};

// Animate the building changes if not any of the above changes
private _animState = linearConversion [0,1,_new,0.6,1,true];
{
	private _phase = _x animationSourcePhase "hide_supply_source";
	if !(_phase isEqualTo _animState) then
	{
		_x animateSource ["hide_supply_source",_animState];
	};
} forEach (_building getVariable ["para_g_objects", []]);

[_delta, _old, _new, "animated"] call _fnc_debug_message;
