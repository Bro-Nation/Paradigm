/*
	Logs a formatted string to the Arma 3 diagnostic log.
	Parameters:
		_string: String - The string to log.
		_params: Array - Optional parameters to format the string.
*/

["CuratorLog", {
	params ["_curator", "_string", "_params"];

	private _curators = missionNamespace getVariable ["curatorsOnline", []];

	if (!(_curator in _curators)) exitWith {};

	if (typeName _params != "ARRAY") then {
		_params = [];
	};

	diag_log format ["[ZEUS] %1(%2) %3", name _curator, getPlayerUID _curator, format [_string, _params]];
}] call CBA_fnc_addEventHandler;