/*
    File: fn_behaviour_is_valid_target.sqf
    Author:  Savage Game Design
    Public: No
    
    Description:
        Reports if a target is valid for a squad to engage
    
    Parameter(s):
		_group - Group to check target validity against [GROUP]
		_target - Target object [OBJECT]
    
    Returns:
        Function reached the end [BOOL]
    
    Example(s):
        [_group, assignedTarget leader _group] call para_g_fnc_behaviour_is_valid_target
*/

params ["_group", "_target"];

// NOTE: @dijksterhuis: this is the inverse of how SGD does it.
// I find AND statements easier to debug rather than negating a
// bunch of OR statements

if (
    !(isNull _target)
    && {
        (alive _target)
    && {
        !(vehicle _target isKindOf "air")
    && {
        !(leader _group distance2D _target > 1500)
    && {
        // not incap or is incap but has rolled over
        !([_target] call para_g_fnc_unit_is_incapacitated)
        || ([_target] call para_g_fnc_unit_is_incapacitated_and_rolled)
    }
    }
    }
    }
) exitWith {true};

false;