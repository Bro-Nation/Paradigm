["CuratorExitUI", {
	params ["_curator"];

	diag_log format["[ZEUS] Curator has exited the menu: %1 (%2)", name _curator, getPlayerUID _curator];
}] call CBA_fnc_addEventHandler;