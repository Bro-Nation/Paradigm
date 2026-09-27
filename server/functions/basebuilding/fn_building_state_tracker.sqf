/*
	File: fn_building_state_tracker.sqf
	Author:  Savage Game Design
	Public: No

	Description:
		Building state tracking

	Parameter(s): none

	Returns: nothing

	Example(s):
		call para_s_fnc_building_state_tracker;
*/

private _lastRan = missionNamespace getVariable [
	"para_l_building_state_tracker_last_ran",
	time
];

para_l_building_state_tracker_last_ran = time;

private _timeDifference = time - _lastRan;

// remove any deleted objects
para_l_buildings = para_l_buildings - [objNull];

{
	private _building = _x;
	//We can "safely" "select 0" here, as it's invalid for an object to ever have an empty array here.
	private _objects = _building getVariable ["para_g_objects", []] - [objNull];
	//If somehow we've no longer got any objects, building is invalid, delete it.
	if (_objects isEqualTo []) then {
		[_building] call para_s_fnc_building_delete;
	} else {

		if ([_building] call para_g_fnc_building_is_decaying) then {
			private _endsAt = _building getVariable ["para_g_decay_ends_at", -1];
			if (_endsAt < 0) then {
				private _duration = missionNamespace getVariable ["para_g_building_decay_duration", 5 * 60];
				_endsAt = serverTime + _duration;
				_building setVariable ["para_g_decay_started_at", serverTime, true];
				_building setVariable ["para_g_decay_ends_at", _endsAt, true];
			};

			if (serverTime >= _endsAt) then {
				[_building] call para_s_fnc_building_delete;
			};
		}
		else
		{
			// Do supply consumption
			private _config = [_building] call para_g_fnc_get_building_config;
			private _supplyConsumptionRate = getNumber(_config >> "supply_consumption");
			[_building, _timeDifference * _supplyConsumptionRate, true] call para_s_fnc_building_consume_supplies;
		};

		[_building, "onBuildingTick", [_building, _timeDifference]] call para_g_fnc_building_fire_feature_event;
	};
} forEach para_l_buildings;

//Save buildings
[] call para_s_fnc_basebuilding_save;
