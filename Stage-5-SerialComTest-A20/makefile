ASMC=nasm
ASMFLAGS= -f bin -o

binary: boot1.asm boot2.asm
	$(ASMC) boot1.asm $(ASMFLAGS) b1.bin
	$(ASMC) boot2.asm $(ASMFLAGS) b2.bin
	cat b1.bin b2.bin > bootloader.bin
	
iso: binary	
	truncate bootloader.bin -s 1440k
	mkisofs -o iso/bootloader.iso -b bootloader.bin ./
	
qemu: clean binary
	qemu-system-x86_64 -fda bootloader.bin -serial file:log/qCOM1.log

bochs: clean iso
	bochs
	
clean:
	mkdir -p iso
	mkdir -p log
	rm *.bin
	rm iso/*.iso