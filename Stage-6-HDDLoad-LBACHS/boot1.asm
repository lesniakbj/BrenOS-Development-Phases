; NOTE:
;	This file follows the BPB format of
;	the FAT12 specification, listed at
;	http://wiki.osdev.org/FAT#BPB_.28BIOS_Parameter_Block.29
[BITS 16]
[ORG 0x7C00]

; Cononicalize CS:IP to 0x0000:0x7C00
; 	Note: Some BIOS' start us at 
;	0x07C0:0x0000. We fix that.
jmp short boot1_start
nop

;====================================;
;		BIOS PARAMETER BLOCK		 ;
;====================================;
oemIdentifier		db 'BrenOS  '
bytesPerSector		dw 512
sectorsPerCluster	db 1
reservedSectors		dw 1
numberOfFATs		db 1
rootEntries			dw 224
totalNumberSectors	dw 0
mediaDescriptor		db 0xF8
sectorsPerFAT		dw 0
sectorsPerTrack		dw 0
numberOfHeads		dw 0
hiddenSectors		dd 0
largeMediaFields	dd 0

;====================================;
;  FAT12 EXTENDED BOOT RECORD (EBPB) ;
;====================================;
driveNumber			db 0x00
reservedField		db 0x00
signatureFAT12		db 0x29
volumeID			dd 0
volumeLabel			db 'BrenOS Sys '
fileSystemID		db 'FAT     '


; ... whew! Now that we defined all the
; things "necissary" to define our FAT
; bootable device, time to start our boot1
; code.

boot1_start:
	; Setup the segments
	cli
	xor ax, ax
	mov ds, ax
	mov es, ax
	
	; Time for the stack
	mov ss, ax
	mov sp, 0x7C00
	sti
	
	; Save the disk that we are
	; booted from.
	mov [diskNumber], dl
	
	cmp byte [diskNumber], 0x80
	je .hdd_boot
	; If we are booting from a floppy
	; drive we will do the following
	; functions:
	call reset_disk
	call read_floppy
	
	mov si, BOOT_MSG
	call write_string
	
	xor si, si
	xor di, di
	jmp 0x0000:stage02_load
	jmp $

.hdd_boot:
	mov si, HDD_BOOT_MSG
	call write_string
	
	xor si, si
	xor di, di
	jmp 0x0000:stage02_load
	jmp $
write_string:
	push ax
	push si

	
.string_loop:
	lodsb
	cmp al, 0
	je .string_end
		
	mov ah, 0x0E
	int 0x10
	jmp .string_loop
	
.string_end:
	pop si
	pop ax
	ret
	
%include "funcs/disk_functions.asm"

;========================;
;		BOOT-1 DATA		 ;
;========================;
; String Data
BOOT_MSG		db 'Loading stage 2 loader from floppy...', 0x0A, 0x0D, 0
HDD_BOOT_MSG	db 'Loading stage 2 loader from HDD...', 0x0A, 0x0D, 0
READ_ERROR		db 'Error reading from Disk!', 0x0A, 0x0D, 0

; Other Data
diskNumber	db 0

; Error Checking Data
readSegment	dw 0
readOffset	dw 0
	
TIMES 510 - ($ - $$) db 0 
dw 0xAA55

; Here we create a label to jump to
; when Stage02 loads.
stage02_load: