TARGET = kernel.elf
SRC = boot.S
OBJ = boot.o
LDS = kernel.ld

CC = riscv64-unknown-elf-as
LD = riscv64-unknown-elf-ld

QEMU = qemu-system-riscv64
QEMU_FLAGS = -machine virt -cpu rv64 -smp 4 -m 128M -nographic -serial mon:stdio -bios none

all: $(TARGET)

$(TARGET): $(OBJ)
	$(LD) -T $(LDS) $< -o $@

$(OBJ): $(SRC)
	$(CC) $< -o $@

run: all
	$(QEMU) $(QEMU_FLAGS) -kernel $(TARGET)

clean:
	rm -f $(OBJ) $(TARGET)

.PHONY: all run clean
