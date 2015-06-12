// My first launcher.

SET in_orbit to FALSE.
SET done_staging to TRUE.
SET launched to FALSE.
SET emergency to FALSE.
SET coasting to FALSE.
SET circularize to FALSE.
//SET g TO KERBIN:MU / KERBIN:RADIUS^2.
LOCK accvec TO SHIP:SENSORS:ACC - SHIP:SENSORS:GRAV.
LOCK gforce TO accvec:MAG / SHIP:SENSORS:GRAV:MAG.
LOCK pitch TO 90 - vectorangle(UP:FOREVECTOR, FACING:FOREVECTOR).

function adjust_throttle {
    parameter x.

    SET throttle_value TO x.

    LOCK THROTTLE TO throttle_value.
    WAIT 2. // give throttle time to adjust.

    IF throttle_value > 0 {
        SET coasting TO FALSE.
    }
}

function emergency_abort {
    TOGGLE ABORT.
    PRINT "ABORT ABORT ABORT.".
    LOCK STEERING TO HEADING(90,45). // east, 45 degrees pitch.
    WAIT 5.
    adjust_throttle(0).
    LOCK STEERING TO SRFRETROGRADE.
    WAIT UNTIL SHIP:ALTITUDE < 1000.
    PRINT "Deploying parachutes.".
    TOGGLE AG9.
    LOCK STEERING TO UP.
}

function staging_sequence {
    SET done_staging to FALSE.
    PRINT "All systems nominal. Staging.".
    STAGE.
    WAIT 2.
    SET done_staging to TRUE.
    SET launched to TRUE.
    PRINT "FUEL: " + STAGE:LIQUIDFUEL.
    WAIT UNTIL STAGE:LIQUIDFUEL <= 0.01 OR emergency OR circularize.
    IF emergency {
        emergency_abort().
    } ELSE IF circularize {
        adjust_throttle(1).
        PRINT "Engines engaged. Circularizing orbit.".
        SET circularize TO FALSE.
        WAIT UNTIL STAGE:LIQUIDFUEL <= 0.01 OR emergency.
        IF emergency {
            emergency_abort().
        } ELSE IF NOT in_orbit {
            PRINT "Stage fuel empty.".
            staging_sequence().
        }
    } ELSE IF NOT in_orbit {
        PRINT "Stage fuel empty.".
        staging_sequence().
    }
}

WHEN SHIP:ALTITUDE > 2500 AND NOT emergency THEN {
    PRINT "Starting turn.  Aiming to 70 degree pitch.".
    LOCK STEERING TO HEADING(90,70). // east, 70 degrees pitch.
}
WHEN SHIP:ALTITUDE > 7000 AND NOT emergency THEN {
    PRINT "Starting turn.  Aiming to 45 degree pitch.".
    LOCK STEERING TO HEADING(90,45). // east, 45 degrees pitch.
}
WHEN SHIP:ALTITUDE > 40000 AND NOT emergency THEN {
    PRINT "Starting turn.  Aiming to 10 degree pitch.".
    LOCK STEERING TO HEADING(90,10). // east, 10 degrees pitch.
}
WHEN SHIP:ALTITUDE > 50000 AND NOT emergency THEN {
    PRINT "Starting flat part.  Aiming towards horizon.".
    LOCK STEERING TO HEADING(90,00). // east, 0 degrees pitch.
}
WHEN SHIP:APOAPSIS > 90000 AND NOT emergency THEN {
    PRINT "Engines disengaged. Coasting to Apoapsis.".
    SET coasting TO TRUE.
}
WHEN SHIP:ALTITUDE > 85000 AND NOT emergency THEN {
    SET circularize TO TRUE.
}
WHEN SHIP:PERIAPSIS > 85000 AND NOT emergency THEN {
    PRINT "Engines disengaged. Orbit Circularized.".
    SET in_orbit to TRUE.
    adjust_throttle(0).
}
WHEN done_staging AND launched AND NOT coasting AND (gforce < 1.0 OR pitch < -5) THEN {
    PRINT "G-FORCE: " + gforce.
    PRINT "PITCH: " + pitch.
    SET emergency TO TRUE.
}
WHEN coasting AND NOT emergency THEN {
    adjust_throttle(0).
}
WHEN STAGE:LIQUIDFUEL < 100 THEN {
    PRINT "FUEL: " + STAGE:LIQUIDFUEL.
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
