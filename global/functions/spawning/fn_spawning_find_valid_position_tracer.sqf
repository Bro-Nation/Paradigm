/*
	File: fn_spawning_find_valid_position_tracer.sqf
	Author:  Savage Game Design
	Modified: @dijksterhuis
	Public: Yes
	
	Description:
		Calculates a valid location to spawn at
		Works by firing a 'tracer' from some distance away from a specific direction,
		which stops when it gets near to the target pos, or gets too close to a blocking unit.

		@dijksterhuis:

		A "valid" location is defined is either:

		- no playable units within 200m of the current point on the line
		- no playable units can see the point on the line (blocked by trees etc.)

		We've modified this to include a check which marks points where the terrain
		surface is water (rivers, sea etc.) as invalid.

		example line projection

		x---x---x---x---x---x---x---x---x---x---x---o---o---o---x---I--------
	
		- 'x' marks are valid terrain positions (not surface water) and there
		are no playable units nearby that might see the AI spawning in

		- 'o' marks are not valid terrain positions (surface water) so we skip them

		- The 'I' mark is where the search stops because it has detected playeable
		units nearby.

		The AI will then spawn in on the PREVIOUS valid position, i.e. the preceeding 'x'


	Parameter(s):
		_tracerEndPos - End position [Position]
		_blockingUnits - Units that prevent spawning near them [Array, defaults to <playableUnits>]
		_attackDir - Attack direction [Number, defaults to <random 360>]
		_minDistance - Minimum spawn distance [Number, defaults to 0]
	
	Returns: nothing

	Example(s): none
*/


params ["_tracerEndPos", ["_blockingUnits", playableUnits], ["_attackDir", random 360], ["_minDistance", 0]];

//How far around each unit blocking happens for.
//Soft block is when visibility checks begin
private _softBlockRadius = 600;
//Hard block is never spawn within this radius
private _hardBlockRadius = 200;

//Adjust the tracer to end _minDistance away.
_tracerEndPos = _tracerEndPos getPos [_minDistance, _attackDir + 180];
private _tracerStart = _tracerEndPos getPos [1500, _attackDir + 180];
private _lastValidTracerPosition = _tracerStart;
private _tracerPosition = _tracerStart;

//The valid position to spawn at
private _finalPosition = _tracerStart;
//Unit that caused the tracer to stop.
private _stoppedOnTarget = objNull;

if (!isNil "debugAttackTracer" && isNil "tracerMarkers") then {
	tracerMarkers = [];
};

private _index = 0;
while {true} do {
	_index = _index + 1;

	// find the next point on the line
	private _stepSize = ((_tracerPosition distance2D _tracerEndPos) / 10) max 100;
	private _newTracerPosition = _tracerPosition getPos [_stepSize, _attackDir];

	// determine if the point on the line is valid according to the terrain
	if (surfaceIsWater _newTracerPosition) then {

		// invalid terrain, ignore this spawn position to mitigate AI spawning in water
		_lastValidTracerPosition = _lastValidTracerPosition;
		private _debugMarkerColour = "ColorBlue";

	} else {

		// valid terrain, update the last known good spawn position
		_lastValidTracerPosition = _tracerPosition;
		private _debugMarkerColour = "ColorPink";

	};

	//Places debug markers on the map when tracers are fired.
	if (!isNil "debugAttackTracer") then {
		private _mark = createMarker ["Tracer" + str diag_tickTime + str _index, _newTracerPosition];
		_mark setMarkerType "mil_dot";
		_mark setMarkerColor _debugMarkerColour;
		tracerMarkers pushBack _mark;
	};


	// now we inspect the point based on player distributions.
	_tracerPosition = _newTracerPosition;

	private _positionIsValid = true;
	private _unitsNearNewPosition = _blockingUnits inAreaArray [_tracerPosition, _softBlockRadius, _softBlockRadius, 0, false];

	// players are nearby
	if !(_unitsNearNewPosition isEqualTo []) then {

		//Check if any units are within the hard block radius - squads should *never* spawn in this radius
		private _hardBlockUnits = _blockingUnits inAreaArray [_tracerPosition, _hardBlockRadius, _hardBlockRadius, 0, false];
		if !(_hardBlockUnits isEqualTo []) exitWith {
			_positionIsValid = false;
			_stoppedOnTarget = _hardBlockUnits select 0;
		};

		//Check if any units are within the soft block radius - do not spawn squads if players can see them spawn in.
		private _unitWithVisibilityIndex = _unitsNearNewPosition findIf {lineIntersectsSurfaces [eyePos _x, AGLtoASL _tracerPosition, _x] isEqualTo []};
		if (_unitWithVisibilityIndex > -1) then { 
			_positionIsValid = false; 
			_stoppedOnTarget = _unitsNearNewPosition select _unitWithVisibilityIndex;
		};
	};

	//If we find a unit, we exit and set the last valid position + which target stopped us.
	if (!_positionIsValid) exitWith {
		if (_tracerPosition isEqualTo _tracerStart) then {
			_finalPosition = [];
		} else {
			_finalPosition = _lastValidTracerPosition;
		};
	};

	// @dijksterhuis: If we are very close to the end of the projected line
	// then we need to start spawning in AI at the last known good position.
	// this means AI spawn one line step further away from the objective,
	// but this is necessary to avoid AI units spawning at water positions
	// when setting _finalPosition = _tracerPosition
	if (_tracerPosition distance2D _tracerEndPos < _stepSize) exitWith {
		_finalPosition = _lastValidTracerPosition;
	};
};

if (!isNil "debugAttackTracer") then {
	private _mark = createMarker ["TracerFinal" + str time, _finalPosition];
	_mark setMarkerType "mil_dot";
	_mark setMarkerColor "ColorRed";
	tracerMarkers pushBack _mark;
};

[_finalPosition, _stoppedOnTarget]