_format_scratch:
	.skip 32

# Enumerate and setup PCI devices
_setup_pci:
	push ra
	# Dump PCI devices
	la a0, pcidevices
	call _write_newline

	# Print Table headers
	la a0, pcivendorid
	call _write_uart
	la a0, tablespace
	call _write_uart
	la a0, tablespace
	call _write_uart
	la a0, tablespace
	call _write_uart
	la a0, tablespace
	call _write_uart
	la a0, pcideviceid
	call _write_newline
	la a0, tableheader
	call _write_newline

	li t0, 0
_iterate_pci:
	li a0, 0x30000000
	add a0, a0, t0
	ld a0, 0(a0)
	# a0: first 8 bytes of PCI header

	# vendor id into t2
	li t1, 0xFFFF
	and t2, a0, t1

	# device id into t3
	srli t3, a0, 16
	and t3, t3, t1

	li t4, 0xFFFF
	beq t2, t4, _iterate_pci_continue
	push t0
	push t2
	push t3
	mv a0, t2
	la a1, _format_scratch
	call _format_hex
	la a0, _format_scratch
	call _write_uart

	la a0, tablespace
	call _write_uart

	pop t3
	mv a0, t3
	push t3
	la a1, _format_scratch
	call _format_hex
	la a0, _format_scratch
	call _write_newline

	pop t3
	pop t2
	pop t0

	la a0, _pci_registry
	li a1, 0
_iterate_table:
	lw a3, 0(a0)
	mv a4, t2
	slli a4, a4, 16
	or a4, a4, t3
	bne a3, a4, _iterate_table_continue
	addi a4, a0, 4
	push a0
	push a1
	push t0
	push t2
	push t3
	li a0, 0x30000000
	add a0, t0, a0
	jalr ra, a4
	pop t3
	pop t2
	pop t0
	pop a1
	pop a0

_iterate_table_continue:
	addi a1, a1, 1
	addi a0, a0, 8
	li a2, 2
	bne a1, a2, _iterate_table

_iterate_pci_continue:
	li t1, 4096
	add t0, t0, t1
	li t1, 0x10000000
	bne t0, t1, _iterate_pci
	pop ra

	la a0, setup_qemu_pci_bridge
	call _write_newline
	ret

# Device Driver Configuration Table
# Table Vendors -> Table Devices -> Function
_pci_registry:
	# PCI Device Bridge
	.byte 0x08, 0x00, 0x36, 0x1B
	j _setup_qemu_pci_bridge
	# QEMU VGA Identifier
	.byte  0x11, 0x11, 0x34, 0x12
	j _setup_qemu_vga

_setup_qemu_pci_bridge:
	push ra
	la a0, setup_qemu_pci_bridge
	call _write_newline
	pop ra
	ret
