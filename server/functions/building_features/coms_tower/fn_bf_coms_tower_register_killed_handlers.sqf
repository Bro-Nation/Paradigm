/*
    File: fn_bf_coms_tower_register_killed_handlers.sqf
    Author: Legend
    Public: No

    Description:
        Registers a server-authoritative Killed event handler on current
        Comms Tower physical objects. This tracks genuine physical destruction
        without treating nonfunctional/deconstruction as destroyed.

    Parameter(s):
        _building - Logical Paradigm building namespace [OBJECT]
        _objects - Current physical objects for this building [ARRAY], optional

    Returns:
        Nothing
*/

params ["_building", ["_objects", []]];

if (isNull _building) exitWith {};

private _buildableConfig = [_building] call para_g_fnc_get_building_config;
if !(isClass (_buildableConfig >> "features" >> "coms_tower")) exitWith {};

if !(_objects isEqualType []) then {
    _objects = [];
};
if (_objects isEqualTo []) then {
    _objects = _building getVariable ["para_g_objects", []];
};

{
    private _towerObject = _x;
    if (isNull _towerObject) then {
        continue;
    };

    if (_towerObject getVariable ["vn_mf_coms_tower_killed_eh_registered", false]) then {
        continue;
    };

    _towerObject setVariable ["vn_mf_coms_tower_killed_eh_registered", true];

    _towerObject addEventHandler ["Killed", {
        params ["_killedTowerObject"];

        if (isNull _killedTowerObject) exitWith {};

        private _killedBuilding = _killedTowerObject getVariable ["para_g_building", objNull];
        if (isNull _killedBuilding) exitWith {};

        if !(_killedBuilding getVariable ["para_g_building_constructed", false]) exitWith {};

        private _killedConfig = [_killedBuilding] call para_g_fnc_get_building_config;
        if !(isClass (_killedConfig >> "features" >> "coms_tower")) exitWith {};

        private _currentObjects = _killedBuilding getVariable ["para_g_objects", []];
        if !(_currentObjects isEqualType []) then {
            _currentObjects = [];
        };
        if !(_killedTowerObject in _currentObjects) exitWith {};

        if !(missionNamespace getVariable ["vn_mf_coms_tower_destroyed_in_ao", false]) then {
            missionNamespace setVariable ["vn_mf_coms_tower_destroyed_in_ao", true, true];
        };

        if (missionNamespace getVariable ["vn_mf_coms_tower_built_in_ao", false]) then {
            missionNamespace setVariable ["vn_mf_coms_tower_built_in_ao", false, true];
        };
    }];
} forEach _objects;
