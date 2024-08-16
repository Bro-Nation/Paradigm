/*
	File: fn_curator_update_objects.sqf
	Author: 'DJ' Dijksterhuis
	Public: No

	Description:
		Updates the objects curators can edit in the mission.

	Parameter(s):
		_tickDelay - How often to update curators with objects in seconds, default 5 seconds [Number]

	Returns:
		Nothing

	Example(s):
		[5] call para_s_fnc_curator_update_objects;
*/

params [["_tickDelay", 5]];

[
	"curators_update_objects", 
	{if (count allCurators > 0) then {allCurators apply { _x addCuratorEditableObjects [vehicles + allUnits]}}},
	[],
	_tickDelay
] call para_g_fnc_scheduler_add_job;
