["CuratorEnterUI", {
	params ["_curator"];

	private _curators = missionNamespace getVariable ["curatorsInUI", []];
	if ((_curator in _curators)) exitWith {};

	_curators pushBack _curator;
	missionNamespace setVariable ["curatorsInUI", _curators];

	diag_log format["[ZEUS] Curator has entered the menu: %1 (%2)", name _curator, getPlayerUID _curator];
}] call CBA_fnc_addEventHandler;