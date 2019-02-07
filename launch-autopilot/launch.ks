// launch autopilot that performs a pure/proper gravity turn maneuver.

@LAZYGLOBAL OFF.

// MAIN

// launch parameters
parameter targetAltitude.     // desired altitude of the ciruclar orbit (km)
parameter targetIncl.         // desired inclination of the orbit (degrees)
parameter initialPitch is 4.  // pitch angle at initial pitchover maneuver
parameter switchV is 80.      // the velocity which rocket would switch from vertical ascent to pitchover maneuver

// convert target altitude back to meters.
set targetAltitude to targetAltitude*1000.

// set initial values
set STEERINGMANAGER:PITCHTS to 3.
set STEERINGMANAGER:YAWTS to 3.
set STEERINGMANAGER:ROLLTS to 3.
set terminal:width to 44.
set terminal:height to 22.
local runMode is 1.
local throt to 0.
local steer to HEADING(SHIP:HEADING, 90).
local state is "na".
local maxQ is 0.
local isMaxQ is false.         // flag for checking whether we've reached MaxQ
local isLock is false.         // another flag when we've reached the given Time to Apoapsis "lock"
local isMaxTWR is false.

// the terminal will actually gives us an error and terminate the program if we're trying to
// calculate the launch azimuth of 0 degree. So to work around that, we're going to predefine the value instead.
if targetIncl = 0 {
	global launchAzimuth is 90.
} else {
	global launchAzimuth is getLaunchAzimuth(targetIncl).
}

// set rocket's initial conditions
SAS off.
RCS off.
gear off.
lights off.
lock throttle to throt.
lock steering to steer.

countdown2(3).
clearscreen.

// auto staging
when SHIP:MAXTHRUST = 0 OR isFlameout() then {
	set throt to 0.
	wait 1.
	HUDTEXT("Staging",
		5,      // delaySeconds
		2,      // style
		20,     // size
		white,  // color
		false). // doEcho
	stage.
	set throt to 1.

	return true.
}

until runMode = 0 {
	// launch's information
	local line is 0.
	print "Target orbit:" at (0, line).
	set line to line + 1.
	print "- " + targetAltitude/1000 + "km" at (0, line).
	set line to line + 1.
	print "- " + targetIncl + "° inclination" at (0, line).
	set line to line + 1.
	print "- " + round(launchAzimuth, 4) + "° calculated azimuth" at (0, line).

	set line to line + 2.
	print "Status:        " + state + " (" + runMode + ")        " at (0, line).
	set line to line + 1.
	print "Pitch Angle:   " + round(90-vang(SHIP:UP:VECTOR,SHIP:FACING:VECTOR)) + "°   " at (0, line).
	set line to line + 1.
	print "Altitude:      " + round(ALT:RADAR/1000,1) + "km   " at (0, line).
	set line to line + 1.
	print "Apoapsis:      " + round(OBT:APOAPSIS/1000, 1) + "km (" + round(ETA:APOAPSIS, 1) + "s)    " at (0, line).
	set line to line + 1.
	print "TWR:           " + round(getTWR(), 3) + "   " at (0, line).
	set line to line + 1.
	print "Surface Vel:   " + round(OBT:VELOCITY:SURFACE:MAG) + "m/s   " at (0, line). 
	//set line to line + 1.
	//print "Dyn Pressure:  " + round(SHIP:Q * constant:AtmToKPa, 1) + "kPa   " at (0, line).

	// runmodes
	// rocket is ascending vertically until it reached the switch velocity (see parameter switchV)
	if runMode = 1 {
		set state to "Vertical Ascent".


		// lock throttle to a steady TWR.
		set throt to getThrottleByTWR(1.4).

		// rocket starts roll to match the  launch azimuth heading.
		if SHIP:VELOCITY:SURFACE:MAG > switchV/2 {
			set steer to HEADING(launchAzimuth, 90).
		}
		// switch to next runmode
		if SHIP:VELOCITY:SURFACE:MAG > switchV {
			set runMode to 2.
		}
	}
	// roket is performing the pitchover maneuver by a certain degrees set by the parameter: initialPitch
	if runMode = 2 {
		set state to "Initial Pitch Over".
		set steer to HEADING(launchAzimuth, 90 - initialPitch).

		if vang(SHIP:SRFPROGRADE:VECTOR, SHIP:FACING:VECTOR) <= 0.125 OR 
				SHIP:VELOCITY:SURFACE:MAG > switchV*1.50 {
			set runMode to 3.
		}
	}
	// rocket is performing the gravity turn maneuver
	if runMode = 3 {
		set state to "Gravity Turn".
		set steer to HEADING(launchAzimuth, 90 - vang(SHIP:UP:VECTOR,SHIP:SRFPROGRADE:VECTOR)).

		// continously check our dynamic pressure to determine whether max Q is reached 
		if maxQ < SHIP:Q {
			set maxQ to SHIP:Q.
		} else if NOT(isMaxQ) {      // assumes that max Q is reached when dynamic pressure starts to go down
			HUDTEXT("Vessel has reached Max-Q. Throttling down.",
				5,      // delaySeconds
				2,      // style
				20,     // size
				white,  // color
				false). // doEcho

			// adjust throttle when reaching max q
			set throt to getThrottleByTWR(1.4).

			// sets a flag, so that we only have to execute codes inside the curly brackets once.
			set isMaxQ to true.
		}

		local pitchAngle is 90-vang(SHIP:UP:VECTOR,SHIP:FACING:VECTOR).
		if pitchAngle > 7 {
			// when our ETA to apoapsis has reached to given time, we will keep adjusting our throttle to keep our ETA "locked".
			if ETA:APOAPSIS > 50 {
				if NOT(isLock) {
					HUDTEXT("Locking Time to Apoapsis",
						5,      // delaySeconds
						2,      // style
						20,     // size
						white,  // color
						false). // doEcho
					set isLock to true.
				}

				local temp is ETA:APOAPSIS. 
				wait 0.
				if temp > ETA:APOAPSIS { // throttle up if ETA is declining
					set throt to throt + 0.05.
				} else {                 // throttle down if ETA is increasing
					set throt to throt - 0.05.
				}
			// before our ETA to apoapsis is reaching to given time, sets our maximum TWR.
			} else {
				if getTWR() > 1.7 {
					if NOT(isMaxTWR) {
						HUDTEXT("Vessel has reached maximum TWR",
							5,      // delaySeconds
							2,      // style
							20,     // size
							white,  // color
							false). // doEcho
						set isMaxTWR to true.
					}
					set throt to getThrottleByTWR(1.7).
				//} else if NOT(isMaxQ){
				//	set throt to 1.
				}
			}
		// when pitch angle is below 5 degrees. sets throttle to maximum.
		// because at this time, ETA is usually wanting to increase even when our throttle is extremely low.
		} else {
			set throt to 1.
		}

		// switch to next runmode
		if OBT:APOAPSIS > targetAltitude {
			set throt to 0.
			set runMode to 4.
		}
	}
	// finalization, apoapsis has reached the target altitude
	if runMode = 4 {
		clearscreen.

		local line is 0.
		print "- Target apoapsis reached" at (0, line). set line to line + 1.

		// 1. creating maneuver node
		print "- Creating circularization maneuver node" at (0, line). set line to line + 1.
		global isNodeCreated is false.       // createNode() will switch this flag when node is created.
		createNode().

		wait until isNodeCreated.
		print "- Maneuver node is created" at (0, line). set line to line + 1.

		// 2. warping
		wait until ALT:RADAR > 70000.
		print "- Warping to T-40 before burn time" at (0, line). set line to line + 1.
		local burnDuration is getBurnDuration(circNode).
		KUNIVERSE:TIMEWARP:WARPTO(TIME:SECONDS + circNode:ETA-(burnDuration/2)-40).

		// set steering to node's burn vector
		//wait until circNode:ETA-(burnDuration/2) <= (burnDuration/2)+20.
		//print "- Pointing vessel to node's burn vector." at at (0, line). set line to line + 1.
		set steer to circNode:BURNVECTOR.

		// 3. executing maneuver
		wait until circNode:ETA <= (burnDuration/2).
		print "- Executing maneuver" at (0, line). set line to line + 1.

		// set initial values
		local initialBurnVector is circNode:BURNVECTOR.
		local maxAcc is 0.
		local isDone is false.
		until isDone {
			set maxAcc to SHIP:AVAILABLETHRUST/SHIP:MASS.
			set throt to min(circNode:DELTAV:MAG/maxAcc, 1).

			set steer to circNode:BURNVECTOR.

			if circNode:DELTAV:MAG < 0.1 {
				set throt to 0.
				set isDone to true.
			}
			if vdot(initialBurnVector, circNode:BURNVECTOR) < 0 {
				set throt to 0. 
			}
			wait 0.
		}

		// unlock steering and throttle
		unlock all.

		// flight report
		clearscreen.
		print "Orbit Info:".
		print "- Apoapsis:       " + round(OBT:APOAPSIS) + "m.".
		PRINT "- Periapsis:      " + round(OBT:PERIAPSIS) + "m. ".
		print "- Inclination:    " + round(OBT:INCLINATION, 4) + "°".
		
		// end program
		set runMode to 0.
	}

	// wait until one physics tick, to give time for our variables to update.
	wait 0.
}

// ======================================================================================================== //

// FUNCTIONS

local function countdown {
	// simple launch countdown
	parameter waitTime. // how long the countdown will run (in seconds)

	clearscreen.
	local text is "Program will initiate in " + waitTime + " seconds".
	print text.

	local i is 0.
	until false {
		print "." at (i+text:length+1 , 0).
		set i to i+2.

		wait 1.

		if i = waitTime*2 {
			break.
		}
	}
}

local function countdown2 {
	// simple launch countdown, just in different style than the previous one.
	parameter waitTime. // how long the countdown will run (in seconds)

	clearscreen.
	local text is "Launching in T-".
	print text.

	until waitTime < 0 {
		print waitTime at (text:length , 0).
		set waitTime to waitTime-1.

		if waitTime >= 0 {
			wait 1.
		}
	}
}

local function getLaunchAzimuth {
	// this function return the launch azimuth of the desired orbit inclination
	// reference: https://www.orbiterwiki.org/wiki/Launch_Azimuth

	parameter i. // desired orbit inclination

	local isAscending is true.
	if i < 0 {
		set isAscending to false.

		set i to abs(i).
	}

	// calculate inertial azimuth
	local phi to abs(SHIP:GEOPOSITION:LAT). // latitude of the launch site (predefined before ship launch, see above of mainline code)
	local betaI is arcsin(cos(i)/cos(phi)). // launch azimuth in inertial space

	// Vorbit (orbital velocity at target orbit)
	local mu is KERBIN:MU. // kerbin's gravitational parameter or use KERBIN:MU
	local r is KERBIN:RADIUS + targetAltitude. // distance from target orbit to the center of Kerbin.
	local Vorbit is sqrt(mu/r). // 

	// Veqrot (rotation speed at Kerbin equator)
	local Req is KERBIN:RADIUS. // equatorial radius of Kerbin
	local Trot is KERBIN:ROTATIONPERIOD. // siderail rotation period
	local Veqrot is (2 * CONSTANT:PI * Req) / Trot.

	local Vrotx is Vorbit * sin(betaI) - Veqrot * cos(phi).
	local Vroty is Vorbit * cos(betaI).

	// calculate launch azimuth
	local betaRot is arctan(Vrotx/Vroty).
	set betaRot to mod(betaRot+360, 360).

	if isAscending {
		return betaRot.
	} else {
		if betaRot <= 90 {
			return 180 - betaRot.
		} else if betaRot >= 270 {
			return 540 - betaRot.
		}
	}
}

local function isFlameout {
	// this function checks if an engine is flamed out / run out of fuel

	local numOut is 0.
	local engList is 0.
	list engines in engList.
	for eng in engList {
		if eng:FLAMEOUT {
			set numOut to numOut + 1.
		}
		//local resList is eng:PARENT:RESOURCES.
		//or res in resList {
		//	if (res:amount < 10) {
		//		set priorTWR to getTWR().
		//	}
		//	wait 0.
		//}
	}

	if numOut > 0 {
		return true.
	} else {
		return false.
	}
}

local function getTWR {
	// this function return vessel's current thrust-to-weight ratio
	// reference: https://wiki.kerbalspaceprogram.com/wiki/Cheat_sheet

	// TWR = T / m*g
	// where:
	// T = thrust of all active engine (kN)
	// m = total mass of the craft (t)
	// g = acceleration due to gravity (m/s2)

	local p is SHIP:BODY:ATM:ALTITUDEPRESSURE(ALT:RADAR).

	local t is SHIP:AVAILABLETHRUSTAT(p) * throttle.
	local m is SHIP:MASS.
	local g is SHIP:BODY:MU / SHIP:BODY:POSITION:MAG^2.

	return t / (m*g).
}

local function getThrottleByTWR {
	// this function return a floating point between 0.0 to 1.0 of throttle required to achieve a desired TWR.

	parameter desiredTWR.

	local p is SHIP:BODY:ATM:ALTITUDEPRESSURE(ALT:RADAR).

	local m is SHIP:MASS.
	local g is SHIP:BODY:MU / SHIP:BODY:POSITION:MAG^2.
	local t is SHIP:AVAILABLETHRUSTAT(p).
	
	return (desiredTWR * (m * g)) / t.
}

local function createNode {
	// this function creates a circularization node that meant to increase the periapsis to match with the apoapsis

	// adds node to flight path at apoapsis
	global circNode to node(TIME:SECONDS+ETA:APOAPSIS, 0, 0, 0).
	add circNode.

	// add prograde and normal deltav until orbit is circular
	until circNode:ORBIT:INCLINATION > targetIncl AND circNode:ORBIT:PERIAPSIS > targetAltitude{
		if circNode:ORBIT:INCLINATION < targetIncl {
			set circNode:NORMAL TO circNode:NORMAL + 0.5.
		}
		//wait 0.
		if circNode:ORBIT:PERIAPSIS < targetAltitude {
			set circNode:PROGRADE to circNode:PROGRADE + 0.5. 
		}
	}

	set isNodeCreated to true.
}

local function getBurnDuration {
	// this function return the burn duration of maneuver node.
	// reference: https://en.wikipedia.org/wiki/Tsiolkovsky_rocket_equation

	parameter maneuverNode.

	// calculate the total Isp if there's multiple engines.
	local x is 0.
	local y is 0.
	local engList is 0.
	list engines in engList.
	for eng in engList {
		// only calculate on active engines.
		if eng:IGNITION {
			set x to x + eng:AVAILABLETHRUSTAT(0).           // total sums of engines thrust
			set y to y + eng:AVAILABLETHRUSTAT(0)/eng:VISP.  // total sums of engines thrust divided by their vacuum isp
		}
	}
	local IspAvg is x/y.

	local m0 is SHIP:MASS.                                                         // initial total mass before node execution
	local m1 is m0 * constant:e^(-maneuverNode:DELTAV:MAG / (constant:g0*IspAvg)). // final total mass after node execution
	local fuelFlow is x / (constant:g0 * IspAvg).                                  // fuel flow of all active engines.

	local burnDuration is (m0 - m1) / fuelFlow.

	return burnDuration.
}
