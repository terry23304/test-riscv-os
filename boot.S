.option norvc
.section .data

hello: .ascii "Hello, RISC-V!\n\0"
iamhart: .ascii "I am hart \0"
newline: .ascii "\n\0"
interrupts_status: .ascii  "Interrupt Enabled: "

_hartlock:
	.skip 8,0

_scratchpad:
	.skip 1024,0

_stacks:
	.skip 8192,0

.section .text.init
.globl _entry

_entry:
    # hardware theard 0 init, others sleep
    csrr t0, mhartid
    # setup stack for hart 0 ~ 3
	la t1, _stacks
	li t2, 1024
	mul t3, t2, t0
	add sp, t3, t1

	bnez t0, _announce

    # setup uart and print hello message
    call _init_uart
    la a0, hello
    call _write_uart
	call _print_MIE_bit

    j _announce
    wfi # wait for interrupt

.macro push
	sd ra, 0(sp)
	addi sp, sp, 8
.endm

.macro pop
	addi sp, sp, -8
	ld ra, 0(sp)
.endm

_print_MIE_bit:
	push
	csrr t0, mstatus
	# MIE bit is 3rd bit
	andi t0, t2, 8
	la a0, interrupts_status
	call _write_uart

	srai t2, t2, 3
	addi t1, t2, 0x30
	la a0, _scratchpad
	# store ASCII Hart ID into scratchpad
	sb t1, 0(a0)
	call _write_newline

	pop
	ret

_write_newline:
    push
	call _write_uart
	la a0, newline
	call _write_uart
	pop
	ret

_init_uart:
    # disable interrupts on uart
    li t1, 0x10000001
    sb x0, 0(t1)
    # write out to uart line control register
    li t1, 0x10000003
    li t2, 0x03 # set input to 8 bits data
    ret

_write_uart:
	push
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
	pop
    ret

_announce:
	la t0, _hartlock
	lw t0, 0(t0)
	csrr t1, mhartid
	bne t0, t1, _announce

	la a0, iamhart
	call _write_uart

	# add 0x30 to HART ID to get ASCII number
	csrr t1, mhartid
	li t2, 0x30
	add t1, t2, t1
	la a0, _scratchpad
	# store ASCII Hart ID into scratchpad
	sb t1, 0(a0)
	call _write_newline

	# increment the HART lock
	csrr t0, mhartid
	addi t1, t0, 1
	la t2, _hartlock
	sw t1, 0(t2)

	j _wait

_wait:
	wfi
