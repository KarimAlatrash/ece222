##################################################
## Name:    Lab4_emulsiV.s  					##
## Purpose: Interrupts                          ##
## Author:	Eric Praetzel	 					##
##################################################

    .text
    .global __reset

__reset:		# The reset program must start at address 0 in memory
    j start

###########################################################################
# The interrupt routine must start at the 4th byte in memory with emulsiV
#
# When an interrupt has happend - the processor will jump to this routine
#
# Interrupt routines should not modify any registers without saving them
# To aid in this x6 and x7 are pushed and poped to make them available
#
# exit with x11 holding the new random number that is between 1 and 255
###########################################################################
#
__irq:
	addi sp, sp, -8             # push x6, x7 to the stack
	sw x7, 4(sp)
	sw x6, 0(sp)

    sb x0, 10(x14)		#	Clear all event flags on the buttons - the rev (Rising Edge eVent) and fev (Falling Edge eVent) registers by writing in zero to each bit
    sb x0, 14(x14)

#	The random number in x11 and needs to be limited to 8-bits, if not already done so, and copied into x12 for the count-down
	add x12, x0, x11

	lw x6, 0(sp)
	lw x7, 4(sp)
	addi sp, sp, 8             # pop x6, x7 from the stack
    mret		# return from interrupt

################################################################################
#  Global Variables 

# Important registers in this program
#
#	x12 is a global variable holding the number being counted down
#	x11 is a global variable holding the last generated random number

#   x0 holds the value 0 and the name 'zero' can be used instead
#   x1 holds the Return Address (ra) for subroutine calls and should not be used within a subroutine unless saved to the stack
#   x2 holds the Stack Pointer (sp) and should not be used as a general register
#   x14 = 0xD0000000 the base address for all General-purpose I/O devices to configure Direction, Interrupts and more
#   x15 = 0xD0000010 the base address for General-purpose I/O _DATA_

# To write to the LEDs: byte write with offsetup of zero using x15. ie 0(x15)

# To read the switches byte read with an offset of 1: 1(x15) and the buttons are at offset 2 bytes. ie  lb x6, 2(x15)

# the ABI register names (zero, ra, sp, gp, tp, t0, t1, t2 ...) can be used - but they ARE NOT displayed in the simulator 
# The simulator displays all registers with their base names of: x0, x1, x2 ... 
################################################################################

start:
	jal InitialSetup		# configure the I/O and print a welcome message - THIS NEEDS TO BE RUN BEFORE ANYTHING ELSE

# Enable interrupts for the push buttons
	li x4, 0x01			# There are eight bits and each bit enables interrupts for one button
	sb x4, 6(x14)		# Write the enable pattern to the ien register. ie sb x4, 4(x14) would enable interrupts for LEDs

	add x12, zero, zero 	# initialize x12 to 0 so that the LEDs start flashing at the start

# Count down the number in x12 to 0 by decrementing once every second
# When x12 is 0, flash the LEDs on and off at ~10Hz
	jal loop_showing_number

flash_loop:
	li x10, 100 #delays for .1s
	jal DELAY
	xor x5, x5, 0xff #switches 8 bits of temp displayed in LEDS
	sb x5, 0(x15)
	beq x12, x0, flash_loop #loops if x12 is still equal --> IRQ not run yet

loop_showing_number:
	jal RANDOM_NUM			# call the random number generator function - returns in x10 (a0)

# put the random # into x11 for the ISR to use, possibly mask it to only 8 bits at this point
	andi x11, x10, 0xff
	sb x12, 0(x15)			# write x12 out to the LEDs to show the number being counted down

# while x12 = 0 flash on and off at ~10 Hz
add x5, x0, x12
beq x12, x0, flash_loop #runs flash loop if x12=0



keep_counting_down:			# If x12 > 0 then count down, delay, and loop back
	addi x12, x12, -1		# decrement countdown number in x12

	li x10, 1000		
	jal DELAY				# delay 1 second

	jal loop_showing_number	# rinse and repeat by going back to the start to display the current number ...



####################################################################################################
#    DO NOT EDIT CODE BELOW THIS POINT !!
####################################################################################################
#
################################################################################
#
# Code to to the initial setup when the program is first run
#
################################################################################
InitialSetup:	

	la sp, __stack_pointer	# assign the default stack pointer address

	addi sp, sp, -4             # push the return address to the stack
	sw ra, 0(sp)				# because we're calling another subroutine and need to preserve it

    la x5, BootMessage
	jal PrintToScreen		 #Print out a bootup message

# Setup all 8 wires to output by writing a 0x00  , 0xff turns pins into inputs
	li x14, 0xD0000000
	sb x0, (x14)		# setup all pins to LEDs as output by writing out 0x00
	li t1, 0xff
	sb t1, 1(x14)	# Setup all pins to switches as inputs
	sb t1, 2(x14)	# Setup all pins to buttons as inputs

	li x15, 0xD0000010		# S1 points to the base I/O address, offset 0 = LEDS, offset 1 = switches

	lw ra, 0(sp)
	addi sp, sp, 4             # pop the return address to the stack

	jr ra		# return to sender

################################################################################
# Print a message to the Text Window
#
# The message to be printed is pointed to by t0 (x5) and must be NULL terminated
#
# exits with x5 incremented to the NULL at the end of the string
################################################################################

PrintToScreen:
	addi sp, sp, -8             # push x6, x7 to the stack
	sw x7, 4(sp)
	sw x6, 0(sp)

    li x6, 0xC0000000
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

################################################################################
# Print a number to the Text Window on a new line
#
# The 32-bit (word) number to be printed is in x5
#
# ASCII characters 0 to 9 are 0x30 to 0x39, A is 0x41, B is 0x42 ....

# printing is left to right so we must start with the most signif. nibble - print the lowest 20 bits only
################################################################################

PrintNumberToScreen:
	addi sp, sp, -16	# push registers to the stack to preserve their values
	sw x7, 12(sp)
	sw x4, 8(sp)
	sw x6, 4(sp)
	sw x8, 0(sp)

	li x4, 8			# x4 counts down from 5 to 0, one for each charcter printed
    li x8, 0xC0000000	# Point to the Text Window I/O port with x8

PrintNextNumber:
	li x6, 0xf0000000		# Mask data to only keep the 5th nibble
	and x7, x5, x6		# prepare to print only the _most_ signif. nibble 0-9 or A-F
	srli x7, x7, 28		# shift the upper nibble down to the bottom for comparison and printing
	li x6, 9			# BLTU (Branch if less) BLEU (branch if less or equal) unsigned 
	bleu x7, x6, WasNumber
	addi x7, x7, 7		# Add 7 as the letters start 7 higher than the numbers
WasNumber:
	addi x7, x7, 0x30	# Add the base offset of 0x30 for ASCII character 0 as we display ASCII
    sb x7, (x8)			# Write the character (byte) to the Text Window

	slli x5, x5, 4				# shift off one nibble, 4 bits just displayed, and loop back to display what is left
	addi x4, x4, -1		# Decrement character counter and test if we're done
    bne x4, zero, PrintNextNumber		# Exit if we have printed all characters

NumberDone:
	sw x7, 12(sp)
	sw x4, 8(sp)
	sw x6, 4(sp)
	sw x8, 0(sp)
	addi sp, sp, 16		# pop x4, x6 from the stack

	jr ra

###########################################################################
# Input x10 (a0) set the time delay to a0 * 100uS
#
# If x10 = 0 then the time delay will be huge (2^32 * 100uS)
#
# returns with x10 = 0
#
# This is an intentionally BADLY DESIGNED timing loop - do not copy it
#     for Lab 1 or you have been naughty!!!
# 
################################################################################
DELAY:
	addi sp, sp, -8             # push x6, x7 to the stack to preserve their values
	sw x7, 0(sp)
	sw x6, 4(sp)

	outer_loop:
		li x6, 10						# 100,000 = 1 sec, so 100uS = 10 loops
		addi x7, zero, 0				# set x7 = 0 for counting up
		delay_loop:
			addi x7, x7, 1				# decrement the delay counter
			bgeu x6, x7, delay_loop	# compares the delay counter with the max, if not equal it returns to the delay_loop
		addi x10, x10, -1					# decrement number of delays counter
		bne x10, zero, outer_loop		# compares the number of delays counter with the max, if not equal it returns to the outer_loop

	sw x6, 4(sp)
	lw x7, 0(sp)
	addi sp, sp, 8             # pop x6, x7 from the stack
	jr ra



################################################################################
# Generate a random number between 1 and 0xffff
#
# Return a0 (x10) with the random number
#
# saves, uses and restores registers gp, t0, t1, t2 (x3, x5, x6, x7)
#
################################################################################

RANDOM_NUM:
	addi sp, sp, -16			# push t0,t1,t2 to the stack to preserve their values
	sw t0, 0(sp)
	sw t1, 4(sp)
	sw t2, 8(sp)
	sw gp, 12(sp)

	la gp, SEED					# load the last random number

	lw t0, 0(gp)				# load the seed or the last previously generated number from the data memory to t0
	li t1, 0x8000
	and t2, t0, t1				# mask bit 16 from the seed
	li t1, 0x2000
	and t1, t0, t1				# mask bit 14 from the seed
	slli t1, t1, 2				# allign bit 14 to be at the position of bit 16
	xor t2, t2, t1				# xor bit 14 with bit 16
	li t1, 0x1000		
	and t1, t0, t1				# mask bit 13 from the seed
	slli t1, t1, 3				# allign bit 13 to be at the position of bit 16
	xor t2, t2, t1				# xor bit 13 with bit 14 and bit 16
	li t1, 0x400
	and t1, t0, t1				# mask bit 11 from the seed
	slli t1, t1, 5				# allign bit 14 to be at the position of bit 16
	xor t2, t2, t1				# xor bit 11 with bit 13, bit 14 and bit 16
	srli t2, t2, 15				# shift the xoe result to the right to be the LSB
	slli t0, t0, 1				# shift the seed to the left by 1
	or t0, t0, t2				# add the XOR result to the shifted seed 
	li t1, 0xFFFF				
	and t0, t0, t1				# clean the upper 16 bits to stay 0
	sw t0, 0(gp)				# store the generated number to the data memory to be the new seed
	mv a0, t0					# copy t0 to a0 as a0 is always the return value of any function

	lw gp, 12(sp)
	lw t2, 8(sp)
	lw t1, 4(sp)
	lw t0, 0(sp)
	addi sp, sp, 16				# pop t0,t1,t2 from the stack
	
	jr ra


# Data for the program
#
    .data
BootMessage:
    .asciz "Lab 4 : Interrupts\nDownhill run to the finish.\n"
StartMessage:
    .asciz "GeT READY\n"
FinishMessage:
    .asciz "Done!\n"
NumberHeader:
    .asciz "\nDelay: 0x"
SEED:
	.word 0x1234				# Put any non zero seed for the Random Number Generator - this must be writable memory

# This section below automatically enables the LED and Switch I/O  in the emulator
#
    .section gpio_config, "a"

leds: .byte 3, 3, 3, 3, 3, 3, 3, 3
sws:  .byte 2, 2, 2, 2, 2, 2, 2, 2
btns:  .byte 1, 1, 1, 1, 1, 1, 1, 1 

