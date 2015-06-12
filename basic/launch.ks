// My first launcher.

SET in_orbit to FALSE.
SET done_staging to TRUE.
SET launched to FALSE.
SET abort to FALSE.
//SET g TO KERBIN:MU / KERBIN:RADIUS^2.
LOCK accvec TO SHIP:SENSORS:ACC - SHIP:SENSORS:GRAV.
LOCK gforce TO accvec:MAG / SHIP:SENSORS:GRAV:MAG.

function adjust_throttle {
    parameter x.

    set throttle_value to x.

    LOCK THROTTLE TO throttle_value.
    WAIT 2. // give throttle time to adjust.
}

function emergency_abort {
    TOGGLE ABORT.
    PRINT "ABORT ABORT ABORT.".
    LOCK STEERING TO HEADING(90,45). // east, 45 degrees pitch.
    WAIT 5.
    LOCK STEERING TO SRFRETROGRADE.
    WAIT UNTIL SHIP:ALTITUDE < 1000.
    PRINT "Deploying parachutes.".
    TOGGLE AG9.
    LOCK STEERING TO UP.
}

function staging_sequence {
    SET done_staging to FALSE.
    PRINT "No liquidfuel.  Attempting to stage.".
    STAGE.
    WAIT 2.
    SET done_staging to TRUE.
    SET launched to TRUE.
    WAIT UNTIL STAGE:LIQUIDFUEL <= 0.01 OR abort.
    IF ABORT {
        emergency_abort().
    } ELSE IF NOT in_orbit {
        staging_sequence().
    }
}

WHEN SHIP:ALTITUDE > 7000 THEN {
    PRINT "Starting turn.  Aiming to 70 degree pitch.".
    LOCK STEERING TO HEADING(90,70). // east, 70 degrees pitch.
}
WHEN SHIP:ALTITUDE > 14000 THEN {
    PRINT "Starting turn.  Aiming to 45 degree pitch.".
    LOCK STEERING TO HEADING(90,45). // east, 45 degrees pitch.
}
WHEN SHIP:ALTITUDE > 40000 THEN {
    PRINT "Starting flat part.  Aiming to horizon.".
    LOCK STEERING TO HEADING(90,0). // east, horizontal.
}
WHEN SHIP:APOAPSIS > 90000 THEN {
    PRINT "Engines disengaged. Coasting to Apoapsis.".
    adjust_throttle(0.0).
}
WHEN SHIP:ALTITUDE > 85000 THEN {
    PRINT "Engines engaged. Circularizing orbit.".
    adjust_throttle(1.0).
}
WHEN SHIP:PERIAPSIS > 85000 THEN {
    PRINT "Engines disengaged. Orbit Circularized.".
    adjust_throttle(0.0).
    SET in_orbit to TRUE.
}
WHEN done_staging AND launched AND gforce < 1.0 THEN {
    PRINT "G-FORCE: " + gforce.
    //SET abort TO TRUE.
}
WHEN TRUE THEN {
    PRINT "G-FORCE: " + gforce.
    PRESERVE.
}

SET countdown TO 1.
PRINT "Counting Down:".
UNTIL countdown = 0 {
    PRINT "..." + countdown.
    SET countdown TO countdown -1.
    WAIT 1.
}

PRINT "Main throttle up.  2 seconds to stabalize it.".
adjust_throttle(1.0).   // 1.0 is the max, 0.0 is idle.
LOCK STEERING TO UP.
staging_sequence().
WAIT UNTIL in_orbit. // pause here until ship is in orbit.

// NOTE that it is vital to not just let the script end right away
// here.  Once a kOS script just ends, it releases all the controls
// back to manual piloting so that you can fly the ship by hand again.
// If the program just ended here, then that would cause the throttle
// to turn back off again right away and nothing would happen.
