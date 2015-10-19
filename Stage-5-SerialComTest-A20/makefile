binary: boot1.asm boot2.asm
	nasm boot1.asm -f bin -o b1.bin
	nasm boot2.asm -f bin -o b2.bin
	cat b1.bin b2.bin > bootloader.bin

clean:
	rm *.bin
	rm iso/*.iso
	rm log/*.log