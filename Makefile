CC = gcc
CXX = g++
AS = nasm
CFLAGS = -std=gnu99 -ffreestanding -O2 -Wall -Wextra -m32 -fno-pie -fno-stack-protector
CXXFLAGS = -ffreestanding -O2 -Wall -Wextra -fno-exceptions -fno-rtti -m32 -fno-pie -fno-stack-protector
LDFLAGS = -ffreestanding -O2 -nostdlib -m32 -Wl,-m,elf_i386 -no-pie -Wl,--build-id=none

SRC_DIR = src
BUILD_DIR = build
ISO_DIR = iso

OBJS = $(BUILD_DIR)/boot.o $(BUILD_DIR)/kernel.o $(BUILD_DIR)/gdt_flush.o $(BUILD_DIR)/gdt.o $(BUILD_DIR)/idt_flush.o $(BUILD_DIR)/idt.o $(BUILD_DIR)/interrupt.o $(BUILD_DIR)/isr.o $(BUILD_DIR)/pic.o $(BUILD_DIR)/keyboard.o $(BUILD_DIR)/graphics.o $(BUILD_DIR)/font.o $(BUILD_DIR)/gui.o $(BUILD_DIR)/mouse.o $(BUILD_DIR)/vfs.o $(BUILD_DIR)/apps.o $(BUILD_DIR)/login.o $(BUILD_DIR)/desktop.o $(BUILD_DIR)/memory.o
BIN = $(BUILD_DIR)/lolos.bin
ISO = lolos.iso

all: $(ISO)

$(ISO): $(BIN)
	mkdir -p $(ISO_DIR)/boot/grub
	cp $(BIN) $(ISO_DIR)/boot/
	@printf 'set timeout=0\nset default=0\nmenuentry "LoLOS" {\n    set gfxpayload=1024x768x32\n    multiboot /boot/lolos.bin\n    boot\n}\n' > $(ISO_DIR)/boot/grub/grub.cfg
	grub-mkrescue -o $(ISO) $(ISO_DIR) 2>&1

$(BIN): $(OBJS) $(SRC_DIR)/linker.ld
	$(CC) -T $(SRC_DIR)/linker.ld -o $@ $(LDFLAGS) $(BUILD_DIR)/boot.o $(filter-out $(BUILD_DIR)/boot.o,$(OBJS))

$(BUILD_DIR)/boot.o: $(SRC_DIR)/boot.s
	mkdir -p $(BUILD_DIR)
	$(AS) -f elf32 $< -o $@

$(BUILD_DIR)/kernel.o: $(SRC_DIR)/kernel.c
	mkdir -p $(BUILD_DIR)
	$(CC) -c $< -o $@ $(CFLAGS)

$(BUILD_DIR)/gdt_flush.o: $(SRC_DIR)/gdt_flush.s
	mkdir -p $(BUILD_DIR)
	$(AS) -f elf32 $< -o $@

$(BUILD_DIR)/gdt.o: $(SRC_DIR)/gdt.c
	mkdir -p $(BUILD_DIR)
	$(CC) -c $< -o $@ $(CFLAGS)

$(BUILD_DIR)/idt_flush.o: $(SRC_DIR)/idt_flush.s
	mkdir -p $(BUILD_DIR)
	$(AS) -f elf32 $< -o $@

$(BUILD_DIR)/idt.o: $(SRC_DIR)/idt.c
	mkdir -p $(BUILD_DIR)
	$(CC) -c $< -o $@ $(CFLAGS)

$(BUILD_DIR)/interrupt.o: $(SRC_DIR)/interrupt.s
	mkdir -p $(BUILD_DIR)
	$(AS) -f elf32 $< -o $@

$(BUILD_DIR)/isr.o: $(SRC_DIR)/isr.c
	mkdir -p $(BUILD_DIR)
	$(CC) -c $< -o $@ $(CFLAGS)

$(BUILD_DIR)/pic.o: $(SRC_DIR)/pic.c
	mkdir -p $(BUILD_DIR)
	$(CC) -c $< -o $@ $(CFLAGS)

$(BUILD_DIR)/keyboard.o: $(SRC_DIR)/keyboard.c
	mkdir -p $(BUILD_DIR)
	$(CC) -c $< -o $@ $(CFLAGS)

$(BUILD_DIR)/graphics.o: $(SRC_DIR)/graphics.c
	mkdir -p $(BUILD_DIR)
	$(CC) -c $< -o $@ $(CFLAGS)

$(BUILD_DIR)/font.o: $(SRC_DIR)/font.c
	mkdir -p $(BUILD_DIR)
	$(CC) -c $< -o $@ $(CFLAGS)

$(BUILD_DIR)/gui.o: $(SRC_DIR)/gui.c
	mkdir -p $(BUILD_DIR)
	$(CC) -c $< -o $@ $(CFLAGS)

$(BUILD_DIR)/mouse.o: $(SRC_DIR)/mouse.c
	mkdir -p $(BUILD_DIR)
	$(CC) -c $< -o $@ $(CFLAGS)

$(BUILD_DIR)/vfs.o: $(SRC_DIR)/vfs.c
	mkdir -p $(BUILD_DIR)
	$(CC) -c $< -o $@ $(CFLAGS)

$(BUILD_DIR)/apps.o: $(SRC_DIR)/apps.c
	mkdir -p $(BUILD_DIR)
	$(CC) -c $< -o $@ $(CFLAGS)

$(BUILD_DIR)/login.o: $(SRC_DIR)/login.c
	mkdir -p $(BUILD_DIR)
	$(CC) -c $< -o $@ $(CFLAGS)

$(BUILD_DIR)/desktop.o: $(SRC_DIR)/desktop.c
	mkdir -p $(BUILD_DIR)
	$(CC) -c $< -o $@ $(CFLAGS)

$(BUILD_DIR)/memory.o: $(SRC_DIR)/memory.c
	mkdir -p $(BUILD_DIR)
	$(CC) -c $< -o $@ $(CFLAGS)

clean:
	rm -rf $(BUILD_DIR) $(ISO_DIR) $(ISO)

run: $(ISO)
	qemu-system-i386 -cdrom $(ISO) -vga std -serial stdio
