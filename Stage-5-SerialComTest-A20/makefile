ASMC=nasm
ASMFLAGS= -f bin -o

binary: boot1.asm boot2.asm
	$(ASMC) boot1.asm $(ASMFLAGS) b1.bin
	$(ASMC) boot2.asm $(ASMFLAGS) b2.bin
	cat b1.bin b2.bin > bootloader.bin
	
iso: binary	
	truncate bootloader.bin -s 1440k
	mkisofs -o iso/bootloader.iso -b bootloader.bin ./

clean:
	rm *.bin
	rm iso/*.iso
	rm log/*.log