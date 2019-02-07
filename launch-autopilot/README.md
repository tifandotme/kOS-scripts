## Launch Autopilot
This kOS script will automate your launch with a [gravity turn](https://wiki.kerbalspaceprogram.com/wiki/Gravity_turn) maneuver in mind until your vessel in a parking circular orbit. Staging, throttling, pitchover will be handled automaticaly by the script.

Before runnning the program, make sure that your rocket meet these following criteria in order to achieve the best possible ascent profile:
1. Have an atleast 1.4 of TWR.
2. Aerodynamically stable.
3. Structurally stable.

>The last part is especially important, because sometimes the rocket can go back and forth when the heading system is set. So I highly recommend to enable rigid attachment and/or autostrut for your parts.

Run the program alongside it's 2 parameter: `run launch(a, b)`. Where **a** is your target altitude (in km) and **b** is your desired orbit inclination.
