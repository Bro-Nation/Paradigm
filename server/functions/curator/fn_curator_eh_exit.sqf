["CuratorExitUI", {
	params ["_curator"];

	private _curators = missionNamespace getVariable ["curatorsInUI", []];
	if (!(_curator in _curators)) exitWith {};

	_curators deleteAt ( _curators find _curator );
	missionNamespace setVariable ["curatorsInUI", _curators];
	publicVariable "curatorsInUI";

	diag_log format["[ZEUS] Curator has exited the menu: %1 (%2)", name _curator, getPlayerUID _curator];
}] call CBA_fnc_addEventHandler;