; NOTE:
;	This file follows the BPB format of
;	the FAT12 specification, listed at
;	http://wiki.osdev.org/FAT#BPB_.28BIOS_Parameter_Block.29
[BITS 16]
[ORG 0x7C00]

; Cononicalize CS:IP to 0x0000:0x7C00
; 	Note: Some BIOS' start us at 
;	0x07C0:0x0000. We fix that.
jmp 0x0000:boot1_start
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
	
	; DL contains the drive number,
	; which is conviently where we
	; put the parameter for the 
	; write_hex(dl) function.
	; call write_hex
	call reset_disk
	call read_from_disk
	
	mov si, READ_TO
	call write_string
	mov dx, [readSegment]
	call write_hex
	mov si, OFFSET_CHAR
	call write_string
	mov dx, [readOffset]
	call write_hex
	mov si, NEW_LINE
	call write_string
	
	mov si, CNTRL_MSG
	call write_string
	mov si, NEW_LINE
	call write_string
	
	jmp stage02_load
	cli
	hlt
	
; Note: These can't be included due to the
; fact that they use variables defined here.
; Thus, they are are simply included as 
; functions here.
; %include "funcs/disk_functions.asm"
; %include "funcs/output_functions.asm"

reset_disk:
	mov ah, 0				; Reset disk function
	mov dl, [diskNumber]	; This will only be run if on Floppy
	int 0x13
	jc reset_disk
	
	ret
	
read_from_disk:
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
	mov bx, 0
	mov es, bx
	mov bx, stage02_load
	
	; ERROR CHECKING [soon]...	
	mov [readSegment], es
	mov [readOffset], bx
	
	int 0x13
	
	jc .disk_read_error
	ret 

.disk_read_error:
	mov si, READ_ERROR
	call write_string
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

	
write_hex:
	push bx
	push si
	
	mov bx, dx
	shr bx, 12
	and bx, 0x0F
	add bx, HEX_CHARS
	mov bl, [bx]
	mov [HEX_OUT + 2], bl
	
	mov bx, dx
	shr bx, 8
	and bx, 0x0F
	add bx, HEX_CHARS
	mov bl, [bx]
	mov [HEX_OUT + 3], bl
	
	mov bx, dx
	shr bx, 4
	and bx, 0x0F
	add bx, HEX_CHARS
	mov bl, [bx]
	mov [HEX_OUT + 4], bl
	
	mov bx, dx
	and bx, 0x0F
	add bx, HEX_CHARS
	mov bl, [bx]
	mov [HEX_OUT + 5], bl
	
	mov si, HEX_OUT
	call write_string
	
	pop si
	pop bx
	ret

;===================;
;	BOOT-1 DATA
;===================;
; String Data
READ_ERROR 	db 'Error reading disk!', 0
CNTRL_MSG	db 'Handing off control...', 0
READ_TO		db 'Reading sector to: ', 0
OFFSET_CHAR	db ':', 0
NEW_LINE	db 0x0A, 0x0D, 0

; Other Data
HEX_CHARS	db '0123456789ABCDEF', 0
HEX_OUT 	db '0x???? ', 0
diskNumber	db 0

; Error Checking DATA
readSegment	dw 0
readOffset	dw 0
	
TIMES 510 - ($ - $$) db 0 
dw 0xAA55

; Here we create a label to jump to
; when Stage02 loads.
stage02_load:

mov si, TEST_STRING
call write_string

mov ax, 0xBE01
cli
hlt

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

TEST_STRING db 'Are we loaded correctly?!'

; NOTE:
; ======================
; Some emulators and disk drives will
; not read a sector unless it is fully 
; padded out, thus we need to pad this
; sector or it will not be read. This is
; true of all sectors we read in some 
; emulators. Thus, the last sector of every
; code segment must be padded.
TIMES 512 db 0