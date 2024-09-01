/*
    File: fn_ai_obj_available_reinforcements.sqf
    Author:  Savage Game Design
    Public: No
    
    Description:
        Returns the reinforcements available at an objective.
    
    Parameter(s):
        _objective - Objective to query about available reinforcements [OBJECT]
    
    Returns:
        Number of available reinforcements [Number]
    
    Example(s):
        [_myObjective] call para_s_fnc_ai_obj_available_reinforcements
*/

params ["_objective"];

if (isNull _objective) exitWith { 0 };

private _spawnedUnitCount = _objective getVariable ["spawnedUnitsCount", 0];

0 max (
    ([_objective] call para_s_fnc_ai_obj_objective_reinforcements_full_strength_unit_quantity) * (_objective getVariable "reinforcements_remaining") - _spawnedUnitCount
)
