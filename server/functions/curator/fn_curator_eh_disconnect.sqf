["CuratorDisconnect", {
	params ["_unit", "_id", "_uid", "_name"];

	private _curators = missionNamespace getVariable ["curatorsOnline", []];

	if (_unit in _curators) exitWith {};

	_curators deleteAt ( _curators find _unit );
	missionNamespace setVariable ["curatorsOnline", _curators];
	publicVariable "curatorsOnline";

	diag_log format["[ZEUS] Curator disconnected: %1", _name];
}] call CBA_fnc_addEventHandler;