[BITS 16]
[ORG 0x7E00]

boot2_start:
	pop ax
	
	cmp ax, 0x00
	je .boot_fd_msg
	
	mov si, BOOT2_MSG
	call write_string
	
	jmp $
	
.boot_fd_msg:
	mov si, BOOT2_FD_MSG
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
;===============================;
;		BOOT 2 - DATA			;
;===============================;
; String Data
BOOT2_MSG		db 'We loaded from HDD!', 0x0A, 0x0D, 0
BOOT2_FD_MSG	db 'We loaded from FD!', 0x0A, 0x0D, 0
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