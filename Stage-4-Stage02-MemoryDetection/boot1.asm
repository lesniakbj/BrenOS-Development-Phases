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
	; Incase it was filled with junk
	cld	

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
	
	; DL contains the drive number,
	; which is conviently where we
	; put the parameter for the 
	; write_hex(dl) function.
	call write_hex

	call reset_disk
	call read_from_disk
	jmp 0x0000:0x7E00

%include "funcs/output_functions.asm"

; Note: These can't be included due to the
; fact that they use variables defined here.
; Thus, they are are simply included as 
; functions here.
; %include "funcs/disk_functions.asm"

reset_disk:
	pusha
	
	mov ah, 0				; Reset disk function
	mov dl, [diskNumber]	; This will only be run if on Floppy
	int 0x13
	jc .reset_disk
	
	popa
	ret
	
read_from_disk:
	pusha
	; Read Sector Function
	mov ah, 0x02
	
	; Setup the function defining where
	; we are reading from...
	mov al, 1				; Number of Sectors to Read
	mov dl, [driveNumber]	; Use the 1st (C:) Drive. HDD.
	mov ch, 1				; Use the 1st Cylinder/Track
	mov dh, 0				; Use the 1st Read/Write Head
	mov cl, 2				; Read the 2nd Sector
	
	; Where to buffer the disk read to...
	; ES:BX -> 0x0000:0x7E00
	mov bx, 0x0000
	mov es, bx
	mov bx, 0x7E00
	
	int 0x13
	
	jc .disk_read_error
	
	popa
	ret 

.disk_read_error:
	mov si, READ_ERROR
	call write_string
	jmp $

;===================;
;	BOOT-1 DATA
;===================;
; String Data
READ_ERROR: db "Error reading disk!", 0
	
; Other Data
diskNumber	db 0
	
TIMES 510 - ($ - $$) db 0 
dw 0xAA55