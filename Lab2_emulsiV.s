##################################################
## Name:    Lab2_Solution.s  					##
## Purpose:	Counting & Cylon LED ~5Hz Freq 	##
## Author:	Eric Praetzel	 					##
##################################################

    .text
    .global __reset

__reset:
	jal InitialSetup 	# Perform any initial setup required for the LEDs, buttons and print welcome message

#  Global Variables 

#	x0 holds the value 0 and the name 'zero' can be used instead
# 	x1 holds the Return Address (ra) for subroutine calls and should not be used within a subroutine unless saved to the stack
# 	x2 holds the Stack Pointer (sp) and should not be used as a general register
# 	x14 = 0xD0000000 the base address for all General-purpose I/O devices to configure Direction, Interrupts and more
#	x15 = 0xD0000010 the base address for General-purpose I/O _DATA_

# To write to the LEDs: byte write with offsetup of zero using x15. ie 0(x15)

# To read the switches byte read with an offset of 1: 1(x15) and the buttons are at offset 2 bytes. ie  lb x6, 2(x15)

# the ABI register names (zero, ra, sp, gp, tp, t0, t1, t2 ...) can be used - but they ARE NOT displayed in the simulator 
# The simulator displays all registers with their base names of: x0, x1, x2 ... 

# choose which program and run, comment out the other line, code the program, run make to build it, load it into the simulator and run it

	jal simple_counter		# jump to the simple_counter program

	#jal cylon_eye			# jump to the cylon Eye program


################################################################################
# Displaying on all eight LEDs a counter output
#
# write the counter value (held in x3) to the lowest 4 LEDs (lowest 4 bits)
# read the slide switches and write them to the upper 4 LEDs
#

simple_counter:		# A simple counter that starts at zero and displays  the count as a binary number on the 4 right most LEDs

	add x3, zero, zero 	# a clear-as-mud way to load zero into a x3 - other math & logic instruction could be used
	
display_count:
	#jal Timing_Loop		# delay for 0.2 seconds
	lb x6, 1(x15)       # read the switch inputs at address 0xd000 0011 (register x15 + 1)
# do some bit manipulation magic combinging the upper 4 bits of x6 (switches) and the lower four bits of x3 (counter) 
# into x5 which gets written to the eight LEDs
	#srli x9, x6, 24 #shifts x6 to look like 0x000000F0	
	andi x9, x6, 0x000000F0 #masking operation
	
	andi x8, x3, 0x0000000F #masking operation
	
# This is done with masking & merging - a mask (AND) operation zeros bits you don't want and an merge (OR) operation combines things
	or x5, x9, x8 #combines x3 and x5

	sb x5, 0(x15)		# write out the value to the LEDs

# increment the x3 counter
	addi x3, x3, 1
# one line of code to keep going back, to and display, delay, merge and count
	jal display_count


###########################################################################
#
# Cylon Eye pattern
#
# Suggested registers for various functions:
# x3 is the direction the LED is moving, 0 = moving left, 1 = moving right
# x5 is the 8-bits written to the LED, only a single 1 should be in the entire byte
#
# LED Pattern for the eight LEDS
#  0 0 0 0 0 0 0 1
#  0 0 0 0 0 0 1 0
#  0 0 0 0 0 1 0 0
#  0 0 0 0 1 0 0 0
#  0 0 0 1 0 0 0 0
#  0 0 1 0 0 0 0 0
#  0 1 0 0 0 0 0 0
#  1 0 0 0 0 0 0 0
#  0 1 0 0 0 0 0 0
#  0 0 1 0 0 0 0 0
#  0 0 0 1 0 0 0 0
#  0 0 0 0 1 0 0 0
#  0 0 0 0 0 1 0 0
#  0 0 0 0 0 0 1 0
#  0 0 0 0 0 0 0 1
#  0 0 0 0 0 0 1 0 
#  .....

cylon_eye:
	addi x5, zero, 1 	# set x5 to 1 so that the Cylon eye begins on the right
	add x3, zero, zero 	# direction - is the LED pattern shifting left (0) or right (1)?
	addi x8, zero, 0x80 # last value in hex for the cylon eye to display

next_out:
	sb x5, 0(x15)		# store the byte into address 0xD000 0000 where the 8 LEDs are

	jal Timing_Loop		# delay for 0.2 seconds

# Code to do the Cylon Eye

# Lots of magic here involving testing the direction and checking if an end has been hit and if not shifting

# You will need to use the shift instructions: slli  slri for Shift Logical Left Immediate and Shift Logical Right Immediate

# some sample labels for one way to do this

	beq x3, x0, left #checks if currently shifting left or right

right: #if left hasn't been triggered, enter this tag
	srli x5, x5, 1 #increment the cylon eye rightwards
	beq x5, x3, at_right_end #checks condition for being at edge of cylon eye
	jal zero, next_out #reset loop

left: 
	slli x5, x5, 1
	beq x5, x8, at_left_end #checks condition for being at edge of cylon eye
	jal zero, next_out #reset loop
	
at_right_end:
	add x3, zero, zero # if at either end then change direction
	jal zero, next_out#reset loop
	
at_left_end:
	addi x3, zero, 1 # if at either end then change direction
	jal zero, next_out#reset loop



####################################################################################################
#
# A simple timing loop that delays for ~0.2 seconds (5Hz counting speed)
#
####################################################################################################
Timing_Loop:
	addi sp, sp, -4			# push x4 to the stack to preserve their values
	sw x4, 0(sp)

	li x4, 50000			# value of necessary to give ~0.2 second delay
delay:
	addi x4, x4, -1			# decrement the counter
#	bxx .....	# compares the counter with zero to see if done, if not keep decrementing

	lw x4, 0(sp)
	addi sp, sp, 4			# pop x6, x7 from the stack
	jr ra



####################################################################################################
#
# Anything below here should not be modified but used as examples and basic functions to build upon
#
####################################################################################################
#
# Code to perform any setup required
#
# x15 holds the based address for the I/O at 0xD000 0010
#
InitialSetup:	

	la sp, __stack_pointer		# assign the default stack pointer address (register x2)

	addi sp, sp, -4             # push the return address to the stack
	sw ra, 0(sp)				# because we're calling another subroutine and need to preserve it

    la x5, BootMessage
	jal PrintToScreen		 #Print out a bootup message

# Setup all 8 wires to output by writing a 0x00  , 0xff turns pins into inputs
	li x15, 0xD0000000
	li t1, 0x00
	sb t1, (x15)		# setup all pins to LEDs as output
	li t1, 0xff
	sb t1, 1(x15)	# Setup all pins to switches as inputs

	li x15, 0xD0000010		# S1 points to the base I/O address, offset 0 = LEDS, offset 1 = switches

	lw ra, 0(sp)
	addi sp, sp, 4             # pop the return address to the stack

	jr ra		# return to sender


###########################################################################
# Print a message to the Text Window of the emulator
#
# The message to be printed is pointed to by x5 (t0) and must be NULL terminated
#
# exit with x5 incremented to point to the NULL at the end of the string

PrintToScreen:
	addi sp, sp, -8             # push x6, x7 to the stack to preserve their values
	sw x7, 4(sp)
	sw x6, 0(sp)

    li x6, 0xC0000000		# This is the address of the small text window in the lower right
loop:
    lbu x7, (x5)			# Read a byte from the string
    beq x7, zero, done		# Exit if we have read the NULL (0x00) character
    sb x7, (x6)				# Write the character (byte) to the Text Window
    addi x5, x5, 1			# Incrememt the point to the next character
	beq zero, zero, loop
done:
	lw x6, 0(sp)
	lw x7, 4(sp)
	addi sp, sp, 8             # pop x6, x7 from the stack
	jr ra



##############################################################################################
# Now the data section of the program where strings can be stored and memory reserved for use
#
# Note .asciz adds a null termination at the end of a string while .ascii does not
#
# ASCII characters like \n (new line) and \r (carriage return) may be used in strings

    .data

BootMessage:
    .asciz "Lab 1 \n Counter and Cylon Eye at 5Hz\n"

DebuggingMessage:
    .asciz "What Happened?\n"

################################################################################
# This section below automatically enables the LED and Switch I/O  in the emulator
################################################################################

    .section gpio_config, "a"

leds: .byte 3, 3, 3, 3, 3, 3, 3, 3
sws:  .byte 2, 2, 2, 2, 2, 2, 2, 2
btns:  .byte 1, 1, 1, 1, 1, 1, 1, 1 
