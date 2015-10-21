# Assembly Compiler and Flags
ASMC=nasm
ASMFLAGS= -f bin -o

# Truncate Flags
TFLAGS= -s 1440k

# ISO Flags
ISOFLAGS= -o iso/bootloader.iso -b

# QEMU Flags
QALLFLAGS= -full-screen
QFLOPFLAGS= -fda bootloader.bin
QHDDFLAGS= -hda bootloader.bin
QCOMFLAGS= -serial file:log/qCOM1.log
QMEMFLAGS= -m 8G
QUSBFLAGS= -usb 

binary: boot1.asm boot2.asm
	$(ASMC) boot1.asm $(ASMFLAGS) b1.bin
	$(ASMC) boot2.asm $(ASMFLAGS) b2.bin
	cat b1.bin b2.bin > bootloader.bin
	
iso: binary	
	truncate bootloader.bin $(TFLAGS)
	mkisofs $(ISOFLAGS) bootloader.bin ./
	
qemu: clean binary
	qemu-system-x86_64 $(QFLOPFLAGS) $(QCOMFLAGS) $(QALLFLAGS)

qemu-hdd: clean binary
	qemu-system-x86_64 $(QHDDFLAGS) $(QCOMFLAGS) $(QALLFLAGS)
	
bochs: clean iso
	bochs
	
clean:
	mkdir -p iso
	mkdir -p log
	rm -f *.bin
	rm -f iso/*.iso