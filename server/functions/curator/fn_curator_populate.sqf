/*
	File: fn_curator_populate.sqf
	Author: @Cerebral
	Modified By: @dijksterhuis
	Public: No

	Description:
		Populate the list of curators from the backend database table
		of player steam IDs.

		Because of recent changes to server naming conventions, and
		because that the backend database column containing the player's
		permission flag for servers has not been migrated over to match
		the new server naming scheme, we have to do a bit of a hacky case
		match statement.

		TL;DR

		- MF1 --> DB whitelist 1
		- MF1 Overflow --> DB whitelist 2
		- MF2 --> DB whitelist 5
		- MF3 --> DB whitelist 3

		You can confirm this by running /lookup-curators command with BN
		discord's brobot and checking the server number at the top of the
		embed that is returned (thanks to Numbnuts for spotting this).

	Parameter(s): none

	Returns: nothing

	Example(s):
		call para_s_fnc_curator_populate;
*/

private _serverNumber = 0;	

for "_i" from 1 to 5 do 
{ 
	switch (true) do {
		case (_i isEqualTo 1) : {
			if ("Overflow" in serverName) then {
				_serverNumber = 2;
			} else {
				_serverNumber = 1;
			};
		};
		case (_i isEqualTo 2) : { _serverNumber = 5 };
		case (_i isEqualTo 3) : { _serverNumber = 3 };
		default {};
	};

	uiNamespace setVariable ["serverNumber", _serverNumber];
};

// running on dedicated server -- there's probably a database around here
// somewhere
if (isDedicated) exitWith {
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
};

// running on a player hosted server -- likely devs doing development
if (!isDedicated && isServer && !(isNull player)) exitWith {
	diag_log format["[+] Curator UIDs: %1", [getPlayerUID player]];
	missionNamespace setVariable ["curatorUIDs", [getPlayerUID player]];
	publicVariable "curatorUIDs";
};