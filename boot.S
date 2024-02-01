.option norvc
.include "macro.S"
.include "vm.S"
.include "uart.S"
.include "pci.S"
.include "hex.S"
.include "vga.S"
.section .data

hello: .ascii "Hello, RISC-V!\n\0"
iamhart: .ascii "I am hart \0"
newline: .ascii "\n\0"
tablespace: .ascii  "    \0"
supervisor_mode: .ascii "Enter Supervisor Mode\n\0"
mmode_trap_warning: .ascii "M Mode Trap cause: \0"
smode_trap_warning: .ascii "S Mode Trap cause: \0"
twisset: .ascii "TW bit is set!\0"
mpp_mmode: .ascii  "MPP Mode: Machine \0"
mpp_smode: .ascii  "MPP Mode: Supervisor \0"
interrupts_status: .ascii  "Interrupts:\0"
hextable: .ascii  "0123456789ABCDEF"
data_section_address: .ascii "Data: \0"
write_uart_address: .ascii "Uart: \0"

walkingpagetables: .ascii "Walking Page Tables...\0"
endwalkingpagetables: .ascii "Walking Page Tables Complete\0"
pcidevices: .ascii "PCI Devices1\0"
pcivendorid: .ascii "Vendor1\0"
pcideviceid: .ascii "Device\0"
tableheader: .ascii "--------------------------------\0"

setup_qemu_pci_bridge: .ascii "Identified QEMU PCI Bridge\0"
setup_qemu_vga: .ascii "Setting Up QEMU VGA...\0"

_hartlock:
	.skip 8,0

_scratchpad:
	.skip 1024,0

.align 12
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
	call _print_misa

	# set machine mode trap vector
	la t0, _machine_trap
	csrw mtvec, t0
	
	# set supervisor mode trap vector
	la t0, _supervisor_trap
	csrw stvec, t0

	# configure Physical Memory Protection to give supervisor mode
  	# access to all of physical memory.
	li t0, 0x3FFFFFFF
	csrw pmpaddr0, t0
	li t0, 0xF
	csrw pmpcfg0, t0

	# jump to supervisor mode
	csrr t0, mstatus
	# MPP mask
	li t1, 3
	slli t1, t1, 11
	not t1, t1
	and t0, t0, t1
	# Set MPP to Supervisor
	li t1, 1
	slli t1, t1, 11
	or t0, t0, t1
	csrw mstatus, t0

	# # delegate all interrupts and exceptions to supervisor mode.
	# li t0, 0xffff
	# csrw medeleg, t0
	# csrw mideleg, t0
	# csrr t0, sie
	# # external
	# li t1, 1
	# slli t1, t1, 9
	# or t0, t0, t1
	# # timer
	# li t1, 1
	# slli t1, t1, 5
	# or t0, t0, t1
	# # software
	# li t1, 1
	# slli t1, t1, 1
	# or t0, t0, t1
	# csrw sie, t0

	call _setup_satp

	# print out supervisor string address
	la a0, _data_start
	call _print_hex

	# Identity Map Data
	la a0, _data_start
	la a1, _data_start
	li a2, 0x07
	call _map_to_virtual

	# Identity Map Data (F)
	la a0, _stacks
	la a1, _stacks
	li a2, 0x0F
	call _map_to_virtual

	# Identity Map the Uart Ports
	li a0, 0x10000000
	li a1, 0x10000000
	li a2, 0x0F
	call _map_to_virtual

	# Identity Map the Uart Functions  (F)
	la a0, _write_uart
	la a1, _write_uart
	li a2, 0x0F
	call _map_to_virtual

	# Virtual Map the Example Page (F)
	la a0, _example_page
	la a1, _example_page
	li a2, 0x0F
	call _map_to_virtual

	la a0, walkingpagetables
	call _write_newline

	# Print out All Page Tables
	la a0, _page_table_start
	li a1, 2
	call _walk_page_tables

	la a0, endwalkingpagetables
	call _write_newline

	call _setup_pci

	# set mepc to example page
	la t0, _example_page
	csrw mepc, t0
	mret

    wfi # wait for interrupt

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

_supervisor_trap:
	la a0, smode_trap_warning
	call _write_uart

	csrr t0, scause
	addi t0, t0, 0x30
	la a0, _scratchpad
	sb t0, 0(a0)
	call _write_newline

	wfi

_machine_trap:
	la a0, mmode_trap_warning
	call _write_uart

	csrr a0, mcause
	call _print_hex
	wfi

_print_misa:
	push ra
	csrr t0, misa
	# number of extensions
	li t1, 26
	li t2, 0
_print_misa_extension_start:
	andi t3, t0, 1
	beqz t3, _print_misa_extension_inc

	addi t3, t2, 0x41
	la a0, _scratchpad
	# store ASCII extension value
	sb t3, 0(a0)
	push t0
	push t1
	push t2
	call _write_uart
	pop t2
	pop t1
	pop t0

_print_misa_extension_inc:
	srai t0, t0, 1
	addi t2, t2, 1
	bne t1, t2, _print_misa_extension_start

	la a0, newline
	call _write_uart

	pop ra
	ret

_wait:
	wfi

# a0: 64 bit value, print in hex
_print_hex:
	push ra
	# 64 bit value
	li a1, 60

_print_hex_loop:
	sra a2, a0, a1	# print from left to right
	andi t1, a2, 0x0F	
	# load hextable and add the offset
	la t2, hextable
	push a0
	push a1
	add a0, t1, t2
	call _write_uart_char
	pop a1
	pop a0
	addi a1, a1, -4
	bgez a1, _print_hex_loop

	la a0, newline
	call _write_uart
	pop ra
	ret

# a0 = pages to alloc
_kalloc:
	la a1, _heap_counter
	ld t0, 0(a1)

	addi t0, t0, 1
	sd t0, 0(a1)

	la t1, _heap_end
	li t2, 4096
	mul t2, t0, t2
	sub a0, t1, t2
	ret

.align 12
_example_page:
	la a0, supervisor_mode
	call _write_uart
	la a0, _page_table_start
	ld a0, 0(a0)
	wfi
	.skip 4096

.align 12 # next data or instruction align to 2^12
_page_table_start:
# Sv39 page tables contain 2^9 Page Table Entries
	.skip 4096	# skip (allocate) 4096 byte memory space
