// WIP script that shows geo longitude of target vessel's AN and DN

clearscreen.

local orbitLANminRA is 0.

until false {
	if target:orbit:lan < body:rotationangle {
		set orbitLANminRA to ((target:orbit:lan-body:rotationangle)+360).
	} else {
		set orbitLANminRA to (target:orbit:lan-body:rotationangle).
	}
	print "loAN:  " + (longitude+180) at(0,0).
	print "loDN:  " + (longitude+360) at(0,1).
	print "target:" + (orbitLANminRA) at (0,2).

	wait 0.
}

//{
//  PARAMETER isAscending, planet, targetLAN, launchAzimuth, shipLat, shipLong.
//
//  LOCAL eta IS -1.
//    LOCAL rel_lng IS ARCSIN(TAN(shipLat)/TAN(launchAzimuth)).
//    IF NOT isAscending { SET rel_lng TO 180 - rel_lng. }
//    LOCAL g_lan IS mAngle(targetLAN + rel_lng - planet:ROTATIONANGLE).
//    LOCAL node_angle IS mAngle(g_lan - shipLong).
//   SET eta TO (node_angle / 360) * planet:ROTATIONPERIOD.
//  }
//}

//The target orbit's Longitude of the Ascending Node (LAN) tells you where the orbit crosses the equator, but in terms of the solar prime vector, not local geographic longitude.

//You can use the body's ROTATIONANGLE to convert from one reference frame to another. I get a geographic longitude by subtracting the rotation angle from the orbit's LAN.

//Once you have a geographic longitude, you can compare it to your ship's longitude and calculate how long it will take to rotate around that angle. That gives you a launch ETA.

//Improvements that can be made include (1) working out the ETA to the descending node as well and picking whichever node comes first, (2) calculating the required adjustment(s) if you're not launching from the equator and (3) finding out if it is worth launching earlier (and if so how much by) on the grounds that it takes several minutes to reach orbital velocity.