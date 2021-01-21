# Labs for ECE222
## Lab 1 - Completed
### Notes on Completion
The LEDs switch on and off based on the least significant 8 bits stored at their memory address. To switch all of the LEDs on, the memory address must store 2^8-1,or 255 in decimal. This can be achieved by adding 255, then subtracting it or performing an XOR operation between the current value at the memory and 255.
For example: 11111 XOR 11111 = 00000; 00000 XOR 11111 = 00000.
Performing this operation halfway through each cycle (every 500ms, or @0.5Hz) will create a full period of flashing LEDs at 1Hz.
### Relevant Code Changed
In the lab 1 assembly file, `delay` and `change_leds` labels were created. 
`delay` has a counter that should take ~0.5s to complete on speed 10 in emulsiV.
'change_leds' performs an XOR operation with the value at X3 and 255. X3 is then loaded into the base memory address stored at X15. `change_leds` then jumps to the first line in the loop where the counter is reset to continue this loop infinitely.
## Lab 2
## Lab 3
