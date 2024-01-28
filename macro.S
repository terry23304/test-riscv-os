.macro push reg
	sd \reg, 0(sp)
	li t6, 8
	add sp, sp, t6
.endm

# And to pop it off again...
.macro pop reg
	li t6, -8
	add sp, sp, t6
	ld \reg, 0(sp)
.endm
