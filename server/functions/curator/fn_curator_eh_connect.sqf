["CuratorConnect", {
	params ["_curator"];

	private _curators = missionNamespace getVariable ["curatorsOnline", []];

	if (_curator in _curators) exitWith {};

	_curators pushBack _curator;
	missionNamespace setVariable ["curatorsOnline", _curators];
	publicVariable "curatorsOnline";

	diag_log format["[ZEUS] Curator connected: %1", _curator];
}] call CBA_fnc_addEventHandler;