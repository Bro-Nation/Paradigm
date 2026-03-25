private _teams = (missionConfigFile >> "gamemode" >> "teams") call BIS_fnc_getCfgSubClasses;

// Load arma_team_name → whitelist_slot mapping from units table
private _mappingQuery = "SELECT arma_team_name, whitelist_slot FROM units WHERE arma_team_name IS NOT NULL AND whitelist_slot IS NOT NULL";
private _mappingResult = [_mappingQuery, 2, true] call para_s_fnc_db_query;

// Build hashmap: arma_team_name → slot number
private _teamSlotMap = createHashMap;
{
	private _teamName = _x select 0;
	private _slot = _x select 1;
	_teamSlotMap set [_teamName, _slot];
} forEach _mappingResult;

{
	private _name = _x;
	private _isDefaultTeam = _name in ["MikeForce", "ACAV", "GreenHornets", "SpikeTeam"];
	if(!_isDefaultTeam) then {

		private _slot = _teamSlotMap getOrDefault [_name, -1];
		if (_slot > 0) then {
			private _query = format ["SELECT m.steam_id FROM member_whitelist mw JOIN members m ON m.user_id = mw.user_id WHERE mw.team_%1 = 1 AND m.steam_id IS NOT NULL", _slot];
			private _queryResult = [_query, 2, true] call para_s_fnc_db_query;

			private _result = [];
			{
				private _uid = _x select 0;
				_result pushBack _uid;
			} forEach _queryResult;

			missionNamespace setVariable [format ["whitelist_%1", _name], _result];
			publicVariable format ["whitelist_%1", _name];
		} else {
			// No slot mapped for this team — empty whitelist
			missionNamespace setVariable [format ["whitelist_%1", _name], []];
			publicVariable format ["whitelist_%1", _name];
		};
	};
} forEach _teams;
