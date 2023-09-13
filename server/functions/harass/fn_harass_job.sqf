/*
    File: fn_ai_job.sqf
    Author:  Savage Game Design
    Public: No
    
    Description:
        Scheduler job for managing the harassment subsystem.
    
    Parameter(s):
        None
    
    Returns:
		None
    
    Example(s):
		["harass_manager", para_s_fnc_harass_job, [], 15] call para_g_fnc_scheduler_add_job;
*/


/*
disabled by @dijksterhuis in favour of v2 patch scripts
(stops pursuit AI being assigned to attack bases)

//Create harass squads for the players in the field, if possible
call para_s_fnc_harass_create_squads;
*/

call para_s_fnc_harass_create_squads_v2;
