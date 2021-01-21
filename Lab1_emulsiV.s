##################################################
## Name:    Lab1_emulsiV.s  					##
## Purpose:	Flashing LED with ~1Hz Frequenc		##
## Author:	Eric Praetzel	 					##
##################################################

#Note that there are some discrepancies between venus and emulsiv:
# 1) venus uses .globl (as is correct according to standard) not .global like emulsiv
# 2) venus uses .asciiz not .asciz like emulsiv (which is correct according to standard)
# 3) venus does not use .section, emulsiv does
# 4) venus does not like dropping the offset, e.g.  sb x7,(x6) instead of sb x7,0(x6) is flagged with error

    .text
    .global __reset

__reset:
	jal InitialSetup	# setup pointer for I/O and print welcome message, all LEDs are off 

# Global variables
# x2 is the Stack Pointer (SP) but will not be used for this Lab
# x15 now points to the I/O at 0xD0000010

# The code below turns the lights off, delays, will turn the lights on, and delay again
# This is the long flowchart that should be made to work and then improved via the short flowchart

next_out:		# "next_out" is a label that is a place in memory
# perform a time delay by running the addi instruction 20,000 times
	li x5, 25000		# find the value that gives 1Hz flashing when Speed is 10 in the emulator

delay:
	addi x5, x5, -1		# decrement the counter
    bne x5, x0, delay	# compare and test to see if we're done - if not loop back and decrement again

change_led:
	addi x4, x4, 1      #counter to estimate timing
	xori x3, x3, 255    #switches 8 bits from 0 --> 1 or 1 --> 0
	sw x3, (x15)		# write the value to the LED register in memory
    jal zero, next_out	# repeat the process forever by jumping back to next_out


###########################################################################
#
# Code to perform any setup required
#
# Do not edit any code below this comment
#
# when done x15 holds the based address for the I/O 0xD000 0010
#
InitialSetup:

    la sp, __stack_pointer      # assign the default stack pointer address (register x2)

    addi sp, sp, -4             # push the return address to the stack
    sw ra, 0(sp)                # because we're calling another subroutine and need to preserve it

    la x5, WelcomeMessage
    jal PrintToScreen        #Print out a bootup message

# Setup all 8 wires to output by writing a 0x00  , 0xff turns pins into inputs
    li x15, 0xD0000000
    li t1, 0x00
    sb t1, (x15)        # setup all pins to LEDs as output
    li t1, 0xff
    sb t1, 1(x15)   # Setup all pins to switches as inputs

    li x15, 0xD0000010      # S1 points to the base I/O address, offset 0 = LEDS, offset 1 = switches

    lw ra, 0(sp)
    addi sp, sp, 4             # pop the return address to the stack

    jr ra       # return to sender

# Print a message to the Text Window of the emulator
#
# The message to be printed is pointed to by t0 (x5) and must be NULL terminated
#
# exit with x5 incremented to point to the NULL at the end of the string

PrintToScreen:
    addi sp, sp, -8             # push x6, x7 to the stack to preserve their values
    sw x7, 4(sp)
    sw x6, 0(sp)

    li x6, 0xC0000000       # This is the address of the small text window in the lower right
loop:
    lbu x7, (x5)            # Read a byte from the string
    beq x7, zero, done      # Exit if we have read the NULL (0x00) character
    sb x7, (x6)             # Write the character (byte) to the Text Window
    addi x5, x5, 1          # Incrememt the point to the next character in the string
    beq zero, zero, loop
done:

    lw x6, 0(sp)
    lw x7, 4(sp)
    addi sp, sp, 8             # pop x6, x7 from the stack
    jr ra


    .data

WelcomeMessage:
    .asciz "Hello"		# enter any text you like; the asciz directive NULL terminates the string

# This section below automatically enables the LED and Switch I/O in the simulator
    .section gpio_config, "a"

leds: .byte 3, 3, 3, 3, 3, 3, 3, 3
sws:  .byte 2, 2, 2, 2, 2, 2, 2, 2

