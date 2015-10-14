[ORG 0x7C00]

mov bp, 0xFFFF
mov sp, bp

call read_from_disk

mov si, BOOT2_SAMEFILE_MSG
call print_string

jmp $

%include "funcs/output_functions.asm"

read_from_disk:
	mov ah, 0x02	; Read Sector Function
	
	mov al, 1		; Number of Sectors to Read
	mov ch, 0		; Use the 1st Cylinder/Track
	mov dh, 0		; Use the 1st Read/Write Head
	mov cl, 2		; Read the 2nd Sector
	
	; Where to buffer the disk read to...
	; ES:BX
	mov bx, 0
	mov es, bx		; ES -> 0
	mov bx, 0x7E00	; BX -> 0x7E00 = 0x0000:0x7E00
	
	int 0x13
	
	jc .disk_read_error
	ret 

.disk_read_error:
	mov si, READ_ERROR
	call write_string
	jmp $
	
;===================;
;	BOOT-1 DATA
;===================;
READ_ERROR: db "Error reading disk!", 0
	
TIMES 510 - ($ - $$) db 0 
dw 0xAA55

BOOT2_SAMEFILE_MSG:	db "Has this been read from disk yet?!?", 0

; NOTE:
; ======================
; Some emulators and disk drives will
; not read a sector unless it is fully 
; padded out, thus we need to pad this
; sector or it will not be read. This is
; true of all sectors we read in some 
; emulators. Thus, the last sector of every
; code segment must be padded.
TIMES 512 - ($ - $$) db 0