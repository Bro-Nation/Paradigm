/*
	File: fn_cleanup_register_player.sqf
	Author:  Savage Game Design
	Public: No

	Description:
		Registers a player to the cleanup system, allowing the system to clean up various things, such as placed equipment.
	
	Parameter(s):
		_player

	Returns: nothing

	Example(s):
		_player call para_s_fnc_cleanup_register_player
*/

params ["_player"];

if (para_s_cleanup_clean_placed_gear) then {

	_player addEventHandler [ "Put", {
		params[ "_unit", "_container" ];
		
		if( typeOf _container isEqualTo "GroundWeaponHolder" ) then {
			[_container, false, para_s_cleanup_placed_gear_cleanup_time] call para_s_fnc_cleanup_add_items;
		};
	}];

	// disassembled weapons left alone for 30 minutes are probably abandoned in an old AO.
	_player addEventHandler [
		"WeaponDisassembled",
		{
			params ["_unit", "_primaryBag", "_secondaryBag"];

			[_primaryBag, true, 30 * 60] call para_s_fnc_cleanup_add_items;
			[_secondaryBag, true, 30 * 60] call para_s_fnc_cleanup_add_items;
		};
	];
};
