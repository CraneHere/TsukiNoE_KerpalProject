//////////CONSTANTS//////////
set startTurnHeight to 15000.
set earthApoapsisHeight to 75000.
set munBreakingHeight to 80000.
/////////////////////////////

PRINT "The ship mass " + SHIP:mass.

declare function sign {
	declare parameter number.
	
	if MAX(0, number) = 0 {
		return -1.
	} else {
		return 1.
	}
}

lock angleToTheMun to VANG((body("Mun"):position-body("Kerbin"):position), (ship:position-body("Kerbin"):position)).

set kuniverse:timewarp:warp to 5.

WAIT UNTIL ABS(angleToTheMun - 180) <= 1.

set kuniverse:timewarp:warp to 0.

Lock Angle to 90.

lock steering to heading(90, Angle).

stage.

WHEN MAXTHRUST = 0 THEN {
	PRINT "The ship mass " + SHIP:mass.
    PRINT "Staging".
    STAGE.
	lock THROTTLE to 1.0.
}

WHEN SHIP:ALTITUDE >= 50000 THEN {
	AG1 ON.
}

WHEN SHIP:ALTITUDE > startTurnHeight THEN {
	PRINT "The ship mass " + SHIP:mass.
	Lock Angle to COS((SHIP:APOAPSIS - startTurnHeight) / (earthApoapsisHeight - startTurnHeight) * 90) * 90.
	lock steering to heading(90, Angle).
}

WAIT UNTIL SHIP:ALTITUDE > startTurnHeight.

WHEN SHIP:APOAPSIS >= earthApoapsisHeight THEN {
	PRINT "The ship mass " + SHIP:mass.
	lock steering to heading (90, 0).
	lock THROTTLE to 0.
}

WAIT UNTIL SHIP:APOAPSIS >= earthApoapsisHeight.

RCS ON.

WAIT UNTIL ETA:APOAPSIS <= 20.

UNTIL FALSE {
	set V1 to ship:velocity:orbit.
	set V2 to VXCL(SHIP:UP:vector, V1):NORMALIZED*sqrt(ship:body:Mu/(ship:body:radius+ship:altitude)).
	set vDelta to V2 - V1.
	
	lock steering to vDelta.
	if VANG(ship:facing:forevector, vDelta) < 1 {
		set maxAcceleration to SHIP:AVAILABLETHRUST / SHIP:MASS.
		lock THROTTLE to min(max(vDelta:MAG/(maxAcceleration*5), 0.0001), 1).
	} else {
		lock THROTTLE to 0.
	}
	
	if vDelta:MAG < 1 {
		BREAK.
	}
}

lock steering to heading (90, 0).
RCS OFF.
lock THROTTLE to 0.

UNTIL FALSE {
	CLEARSCREEN.
	set A1 to (2*body("Kerbin"):radius + body("Mun"):altitude + ship:altitude)/2.
	set A2 to body("Kerbin"):radius + body("Mun"):altitude.
	set Alpha to 180 * (1 - (A1/A2)^(3/2)).
	
	set vecM to body("Mun"):position - body("Kerbin"):position.
	set vecS to ship:position - body("Kerbin"):position.
	set currentMunAngle to VANG(vecM, vecS) * sign((vecM - vecS)*ship:velocity:orbit).
	
	set deltaAngle to currentMunAngle - Alpha.
	PRINT "deltaAngle= " + deltaAngle.
	if deltaAngle > 5 and deltaAngle < 6 {
		PRINT "Let's fly to the Mun!".
		BREAK.
	}
	
	WAIT 0.1.
}

WHEN MAXTHRUST = 0 THEN {
	stage.
	if (body("Mun"):ALTITUDE-ORBIT:APOAPSIS > 2000) {
		return true.
	} else {
		return false.
	}
}

RCS ON.
WAIT 20.
RCS OFF.

set THROTTLE to 1.0.

WHEN ORBIT:APOAPSIS/body("Mun"):ALTITUDE > 0.9 THEN {
	set THROTTLE to 0.05.
}

UNTIL body("Mun"):ALTITUDE-ORBIT:APOAPSIS <= 2000 {
	CLEARSCREEN.
	set temp to body("Mun"):ALTITUDE-ORBIT:APOAPSIS.
	PRINT "deltaHeight = " + temp.
	PRINT "Mun Alt = " + body("Mun"):ALTITUDE.
	PRINT "Apo = " + ORBIT:APOAPSIS.
	WAIT 1.
}

CLEARSCREEN.
PRINT "Transfer orbit to the Mun is finished.".

set THROTTLE to 0.

WAIT UNTIL (body("Mun"):position - ship:position):MAG - body("Mun"):radius <= munBreakingHeight.

PRINT "We are near the Mun!".

set kuniverse:timewarp:warp to 0.

lock THROTTLE to 1.0.
lock steering to -ship:velocity:orbit.

WAIT UNTIL SHIP:VELOCITY:ORBIT:MAG <= 100.

lock THROTTLE to 0.

WAIT 3.

STAGE.

WAIT 3.

RCS ON.

lock gravVector to (body("Mun"):position - ship:position):Normalized * body("Mun"):Mu/(body("Mun"):position - ship:position):MAG^2.

lock breakHorizontalVelocityVector to VXCL(gravVector, -ship:velocity:orbit).

lock steering to breakHorizontalVelocityVector.

WAIT 10.

UNTIL FALSE {
	if VANG(ship:facing:forevector, breakHorizontalVelocityVector) < 1 {
		set maxAcceleration to SHIP:AVAILABLETHRUST / SHIP:MASS.
		lock THROTTLE to min(max(breakHorizontalVelocityVector:MAG/(maxAcceleration*5), 0.0001), 1).
	} else {
		lock THROTTLE to 0.
	}
	
	if breakHorizontalVelocityVector:MAG < 1 {
		BREAK.
	}
}

lock THROTTLE to 0.

lock steering to -gravVector.

UNTIL FALSE {
	set maxAcceleration to SHIP:AVAILABLETHRUST / SHIP:MASS.
	set breakingDistance to SHIP:VELOCITY:ORBIT:MAG^2 / (2*(maxAcceleration-gravVector:MAG)).
	if ALT:RADAR / breakingDistance < 1.05 {
		BREAK.
	}
}

RCS OFF.

lock THROTTLE to 1.0.

WAIT UNTIL ship:velocity:orbit:mag <= 11.

lock THROTTLE to 0.

lock maxAcceleration to SHIP:AVAILABLETHRUST / SHIP:MASS.

UNTIL FALSE {
	set breakingDistance to SHIP:VELOCITY:SURFACE:MAG^2 / (2*(maxAcceleration-gravVector:MAG)*0.1).
	if ALT:RADAR / breakingDistance < 0.99 {
		BREAK.
	}
}

lock steering to -ship:velocity:surface.

lock THROTTLE to SHIP:MASS * ((maxAcceleration-gravVector:MAG)*0.1 + gravVector:MAG) / (COS(VANG(ship:velocity:surface, gravVector)) * SHIP:AVAILABLETHRUST).

WAIT UNTIL ship:velocity:surface:mag <= 1 or ALT:RADAR < 5.

lock THROTTLE to 0.

PRINT "stop".

WAIT 1.

STAGE.

WAIT 1.

BRAKES ON.

WAIT UNTIL SHIP:ANGULARVEL:MAG < 0.1.

PRINT "The rover is stable.".

AG2 ON. //antenna

WAIT UNTIL FALSE.
