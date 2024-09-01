/*
	File: fn_ai_obj_get_valid_player_units.sqf
	Author: @dijksterhuis
	Public: No

	Description:
		Get all players we will consider valid units for the AI objective system.

	Parameter(s): none

	Returns: nothing

	Example(s):
		[] call para_s_fnc_ai_obj_get_valid_player_units;
*/

allUnits
	select {isPlayer _x}
	select {!(_x isKindOf "HeadlessClient_F")}
	select {!(vehicle _x isKindOf "Plane")}
	select {(speed vehicle _x < 200)}
	select {!(side _x == east)}
;