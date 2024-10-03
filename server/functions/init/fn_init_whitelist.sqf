private _teams = (missionConfigFile >> "gamemode" >> "teams") call BIS_fnc_getCfgSubClasses;

{
	private _name = _x;
	private _isDefaultTeam = _name in ["MikeForce", "ACAV", "GreenHornets", "SpikeTeam"];
	if(!_isDefaultTeam) then {

		private _query = format ["SELECT SteamID FROM users WHERE %1 >= 1", _name];
		private _queryResult = [_query, 2, true] call para_s_fnc_db_query;

		private _result = [];
		{
			private _uid = _x select 0;
			_result pushBack _uid;
		} forEach _queryResult;

		missionNamespace setVariable [format ["whitelist_%1", _name], _result];
		publicVariable format ["whitelist_%1", _name];
	};
} forEach _teams;