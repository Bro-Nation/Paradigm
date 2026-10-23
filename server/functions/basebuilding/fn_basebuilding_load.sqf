/*
    File: fn_basebuilding_load.sqf
    Author:  Savage Game Design
    Public: Yes

    Description:
		Loads all bases and buildings saved

    Parameter(s):
	 	None

    Returns:
		None

    Example(s):
		[] call para_s_fnc_basebuilding_load;
*/

(["GET", "basebuilding", [[], []]] call para_s_fnc_profile_db) params ["","_basebuildingData"];

_basebuildingData params ["_bases", "_buildings"];

//Restore bases first, to prevent us accidentally doubling bases when spawning saved HQ buildings.
//That, or HQ buildings need to know how to restore bases.

_bases apply {[_x] call para_s_fnc_base_deserialize};
_buildings apply {[_x] call para_s_fnc_building_deserialize};

{
	private _base = _x;
	private _validBaseBuildings = para_l_buildings select {
		!isNull _x &&
		{(_x getVariable ["para_g_base", objNull]) isEqualTo _base} &&
		{_x getVariable ["para_g_building_constructed", false]}
	};

	if (_validBaseBuildings isEqualTo []) then {
		[_base] call para_s_fnc_base_delete;
	};
} forEach (+para_g_bases);
