# pulsecounter
Power meters send a light pulse every kwh. Counting the number of pulses per day and you know your power usage.
This could be done with the adc and a ldr+resistor but I had a "Light Detection Module" with a digital output on some threshold value.

## Wiring
I hooked up the digital output to GPIO2.

## Code
I keep a seperate file "config.lua" with the api key and wifi settings so I don't have to worry about accidentally uploading them.
You should remove that line or do something similar.

