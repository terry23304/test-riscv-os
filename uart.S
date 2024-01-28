.align 12
# Write the string to UART followed by a newline
# a0: address of a string to print
_write_newline:
    push ra
	call _write_uart
	la a0, newline
	call _write_uart
	pop ra
	ret

# Ensure that UART accept 8 bit value
_init_uart:
    # disable interrupts on uart
    li t1, 0x10000001
    sb x0, 0(t1)
    # write out to uart line control register
    li t1, 0x10000003
    li t2, 0x03 # set input to 8 bits data
    ret

_write_uart_char:
	push ra
	li t1, 0x10000000
	lb t2, 0(a0)
	sb t2, 0(t1)
	pop ra
	ret

.align 12
# Write a string to UART
# a0: pointer to the string
_write_uart:
	push ra
_write_uart_loop:
	li t1, 0x10000005
	beqz t1, _write_uart_loop
	li t1, 0x10000000
	lb t2, 0(a0)
	beqz t2, _write_uart_done
	sb t2, 0(t1)
	addi a0, a0, 1
	j _write_uart_loop
_write_uart_done:
	pop ra
    ret
