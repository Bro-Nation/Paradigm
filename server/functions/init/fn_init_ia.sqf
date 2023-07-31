private _queryResult = ["SELECT user_id FROM ia", 2, true] call para_s_fnc_db_query;

private _result = [];
{
	private _uid = _x select 0;
	_result pushBack _uid;
} forEach _queryResult;

diag_log format["[+] IA UIDs: %1", _result];
missionNamespace setVariable ["iaUIDs", _result];
publicVariable "iaUIDs";