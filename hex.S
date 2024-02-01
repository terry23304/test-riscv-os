# a0: 64 bit value, print in hex
# a1: address of 16 byte block of memory for return value
_format_hex:
	push ra
    mv t5, a1
	# 64 bit value
	li a1, 60

_format_hex_loop:
	sra a2, a0, a1	# print from left to right
	andi t1, a2, 0x0F	
	la t2, hextable

	# get ASCII value of Hex Digit
	add t6, t2, t1
	lb t6, 0(t6)

	# Store the ASCII HEX value into t5
	sb t6, 0(t5)
	addi t5, t5, 1

	addi a1, a1, -4
	bgez a1, _format_hex_loop
	pop ra
	ret