/*
    File: fn_helper_rExec_notification.sqf
    Author: 'DJ' Disjkterhuis
    Public: No

    Description:
        remoteExec paradigm notification pop up. via unscheduled (default) or scheduled execution.

        Unscheduled -- order of execution vs other code does not matter (95% of notification cases).
        Scheduled -- order of execution matters.

    Parameter(s):
		_title - STRING: title on the pop up defined in the stringtable
		_msg - STRING: Message body to add to the pop up notification. DO NOT ARRAY-IFY. 
		_entities - Object/Array: Who to send the notification to.
		_scheduled - Boolean (default false), how to do the remote exec.

    Returns: nothing (triggers notification in entities' UI)

    Example(s):
    	// unscheduled
    	["AdminLog", "Someone is being a naughty boy.", player] call para_c_fnc_helper_rExec_notification;
    	["AdminLog", "Someone is being a naughty boy.", player, false] call para_c_fnc_helper_rExec_notification;
    	// scheduled
    	["AdminLog", "Someone is being a naughty boy.", player, true] call para_c_fnc_helper_rExec_notification;
*/

params ["_entities", "_title", ["_msg", []], ["scheduled", false]];

private _args = objNull;

// _msg is not array or is zero length array -- no message.
if !((isArray _msg) && {(count _msg) == 0}) then {_args = [_title]} else {args = [_title, [_msg]]};

if (scheduled) then {
	_args remoteExec ["para_c_fnc_show_notification", _entities];
} else {
	_args remoteExecCall ["para_c_fnc_show_notification", _entities];
}
