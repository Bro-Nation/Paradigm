/*
	File: fn_buildingMenu_indexBuildings.sqf
	Author:  Savage Game Design
	Public: No

	Description:
		Indexes all buildings available in the gamemode and proccess them.

	Parameter(s): none

	Returns:
		List of buildings [ARRAY]

	Example(s): none
*/

private _config = missionConfigFile >> "gamemode" >> "buildables";
private _buildables = "true" configClasses _config;
private _playerSide = side player;
private _isMilitaryPolice = player getVariable ["vn_mf_db_player_group", "MikeForce"] isEqualTo "MilitaryPolice";

private _nvaBuildables = _buildables select { 
	private _categories = getArray (_x >> "categories");
	"nv" in _categories
};

private _mpBuildables = _buildables select {
	private _categories = (getArray (_x >> "categories")) apply {toLower _x};
	"mp" in _categories
};

if (_playerSide == east) then {
	_buildables = _nvaBuildables;
} else {
	_buildables = _buildables - _nvaBuildables;
};

if !(_isMilitaryPolice) then {
	_buildables = _buildables - _mpBuildables;
};

private _name = "";
private _localizedName = "";
private _return = [];
private _processed = _buildables apply {
	_name = getText (_x >> "name");
	if (_name isEqualTo "") then {
		_localizedName = getText (configFile >> "CfgVehicles" >> (configName _x) >> "displayname");
	} else {
		_localizedName = _name call para_c_fnc_localize;
	};

	_return = [
		_x,
		(getArray (_x >> "categories")) apply { toLower _x },
		_localizedName,
		[getText (configFile >> "CfgVehicles" >> (configName _x) >> "editorPreview"), (getText (_x >> "picture"))] select !((getText (_x >> "picture")) isEqualTo ""),
		configName _x,
		"true" configClasses (_x >> "features") apply {configName _x}
	];
	_return
};
_processed