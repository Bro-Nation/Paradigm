/*
    File: fn_building_on_hit.sqf
    Author:  Savage Game Design
    Public: No
    
    Description:
        No description added yet.
    
    Parameter(s):
        _localVariable - Description [DATATYPE, defaults to DEFAULTVALUE]
    
    Returns:
        Function reached the end [BOOL]
    
    Example(s):
        [parameter] call vn_fnc_myFunction
*/

params ["_building", "_step", ["_hasTrait", false]];

if (isNull _building || _building getVariable ["para_s_building_id", objNull] isEqualType objNull) exitWith {
	diag_log format ["WARNING: Paradigm: Building on hit called without a valid building by %1", _player];
};

[_building, _step, true, _hasTrait] call para_s_fnc_building_add_build_progress;