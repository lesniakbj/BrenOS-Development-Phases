[ORG 0x0000:0x7E00]

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