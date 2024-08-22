private _serverNumber = 0;	

for "_i" from 1 to 5 do 
{ 
	if ([str(_i), serverName] call BIS_fnc_inString) then
	{
		_serverNumber = _i;

		uiNamespace setVariable ["serverNumber", _i];
	};
};

private _query = format ["SELECT user_id FROM curators WHERE server_number = %1", _serverNumber];
private _queryResult = [_query, 2, true] call para_s_fnc_db_query;

private _result = [];
{
	private _uid = _x select 0;
	_result pushBack _uid;
} forEach _queryResult;

diag_log format["[+] Curator UIDs: %1", _result];
missionNamespace setVariable ["curatorUIDs", _result];
publicVariable "curatorUIDs";
