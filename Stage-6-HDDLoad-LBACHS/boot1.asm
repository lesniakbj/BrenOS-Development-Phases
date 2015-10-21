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
bpbOemIdentifier		db 'BrenOS  '
bpbBytesPerSector		dw 512
bpbSectorsPerCluster	db 1
bpbReservedSectors		dw 1
bpbNumberOfFATs			db 1
bpbRootEntries			dw 224
bpbTotalNumberSectors	dw 0
bpbMediaDescriptor		db 0xF8
bpbSectorsPerFAT		dw 0
bpbSectorsPerTrack		dw 0
bpbNumberOfHeads		dw 0
bpbHiddenSectors		dd 0
bpbLargeMediaFields		dd 0

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
	cmp byte [diskNumber], 0x81
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

.hdd_boot:
	; Since we are booting from a hard
	; drive, we are going to need to know
	; a few things about the drive geometry. 
	; We will ask BIOS for that information.
	call get_drive_geometry
	
	; Now we will see if we can use the extensions
	; to load our data from HDD, otherwise we are
	; stuck using CHS addressing.
	call get_address_extensions
	jc .chs_addressing_mode
	
	mov si, HDD_BOOT_MSG
	call write_string
	
	xor si, si
	xor di, di
	jmp 0x0000:stage02_load
	
.chs_addressing_mode:
	mov si, HDD_BOOT_CHS_MSG
	call write_string
	
	xor si, si
	xor di, di
	jmp 0x0000:stage02_load
	
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
BOOT_MSG			db 'Loading stage 2 loader from floppy...', 0x0A, 0x0D, 0
HDD_BOOT_MSG		db 'Loading stage 2 loader from HDD...', 0x0A, 0x0D, 0
HDD_BOOT_CHS_MSG	db 'Loading stage 2 loader from HDD using CHS...', 0x0A, 0x0D, 0
READ_ERROR			db 'Error reading from Disk!', 0x0A, 0x0D, 0

; Other Data
diskNumber		db 0
numberOfHeads	dw 0
sectorsPerTrack dw 0

lbaAddress			dw 0
absoluteSector		db 0
absoluteHead		db 0
absoluteCylnider	db 0

; LBA Addressing Packet
diskPacket:
	; Size of the packet
	sizeOfPacket	db 0x10
	; Always 0
	alwaysZero		db 0x00
	; # of sectors to retrieve
	sectorsToGet	dw 0
	; Where to put them (offset:segment)
	transferBuff	dd 0
	startLBA		dd 0
	extraBitLBA		dd 0
	
; Error Checking Data
readSegment	dw 0
readOffset	dw 0
	
TIMES 510 - ($ - $$) db 0 
dw 0xAA55

; Here we create a label to jump to
; when Stage02 loads.
stage02_load: