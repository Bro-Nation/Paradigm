/*
    File: fn_is_valid_axe_target.sqf
    Author:  Savage Game Design
    Public: Yes

    Description:
        Given a melee target, determine if the axe is appropriate to deal with it.

    Parameter(s):
        None

    Returns:
        Bool - true if valid axe target, false otherwise

    Example(s):
        [_target] call para_g_fnc_is_valid_axe_target
*/

params ["_target"];

// Hard exception for christmas trees (no grinch allowed)
if (_target isKindOf "Land_vn_t_piceaabiesnativitatis_2s") exitWith {
    systemChat "You've been put on the naughty list";
    diag_log "AXE DEBUG: Naughty list tree hit";
    false;
};

private _info = getModelInfo _target;
private _path = _info select 1;
private _valid = [
    "\bush\",
    "\tree\",
    "\crop\",
    "\crops\",
    "\shrub\",
    "\treeparts\",
    "vegetation_f_vietnam\burned\",
    "vn_plants_pmc\misc\",
    "vegetation_f_vietnam\dried\"
];

_valid findIf { _x in _path } > -1
