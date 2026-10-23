private _result = [];

if (isDedicated) then {
	private _serverIP = mf_server_ip;
	private _serverPort = mf_server_port;

	private _slotQuery = format [
		"SELECT m.slot FROM curation_server_mapping m JOIN battlemetrics_servers bs ON bs.id = m.server_id WHERE bs.ip_address = '%1' AND bs.port = %2 LIMIT 1",
		_serverIP, _serverPort
	];
	private _slotResult = [_slotQuery, 2, true] call para_s_fnc_db_query;

	if (count _slotResult > 0) then {
		private _slot = (_slotResult select 0) select 0;
		private _query = format ["SELECT CAST(steam_id AS CHAR) FROM curation_whitelist WHERE server_%1 = 1", _slot];
		private _queryResult = [_query, 2, true] call para_s_fnc_db_query;

		{
			_result pushBack (_x select 0);
		} forEach _queryResult;
	} else {
		diag_log format ["[!] WARNING: No curation slot mapped for server %1:%2", _serverIP, _serverPort];
	};
} else {
	if (hasInterface && {!isNull player} && {isPlayer player}) then {
		private _uid = getPlayerUID player;
		if (_uid isNotEqualTo "") then {
			_result = [_uid];
			diag_log format ["[CURATOR] Local/dev mode -- auto-whitelisting %1", name player];
		} else {
			diag_log "[CURATOR] WARNING: Local player UID is unavailable.";
		};
	} else {
		diag_log "[CURATOR] WARNING: Local player is unavailable; curator whitelist is empty.";
	};
};

diag_log format ["[+] Curator UIDs: %1", _result];
missionNamespace setVariable ["curatorUIDs", _result, true];
