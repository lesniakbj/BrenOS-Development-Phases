;=======================;
;	PRIMARY FUNCTIONS	;
;=======================;
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
	
;-------------------;
; Func:				;
;	write_char()	;
; Params:			;
;	al = Char		;
;	cx = # of Times	;
;-------------------;
write_char:
	mov ah, 0x09
	mov bh, 0
	
	int 0x10
	
	ret
	

;=======================;
;	 HELPER FUNCTIONS	;
;=======================;
write_newline:
	push si
	
	mov si, NEWLINE
	call write_string

	pop si
	ret
	
write_space:
	push si
	
	mov si, SPACE
	call write_string

	pop si
	ret
	
write_color_row:
	push ax
	push cx
	push bx
	
	mov al, ' '
	mov cx, [SCREEN_WIDTH]
	mov bl, [LINE_COLOR]
	call write_char
	
	pop bx
	pop cx
	pop ax
	ret
	
;-------------------;
; FS:SI -> Start	;
; 		   of range	;
;					;
; CX -> Count of 	;
;		bytes to 	;
;		display		;
;					;
; AX -> Number of   ;
;		bytes per   ;
;		row.		;
;-------------------;
write_memory_range_contents_16:
	mov [bytesPerRow], ax
	mov [locationOfMem], si
	
.start:
	dec ax
	dec cx
	
	call write_space
	
	mov dx, [si]
	call write_hex
	
	cmp cx, 0
	je .end
	
	cmp ax, 0
	je .newline
	
	; Add 2 to SI before we jump
	; back to the start, because
	; we are printing 16 bit (2
	; byte) values.
	add si, 2
	jmp .start
	
.newline:
	mov si, " | "
	call write_string
	
	mov dx, [locationOfMem]
	call write_hex
	
	call write_newline
	
	mov ax, [bytesPerRow]
	mov [locationOfMem], si
	jmp .start
	
	
.end:
	call write_newline
	ret

;==============================;
;		FUNCTIONS DATA		   ;
;==============================;
; Working data
bytesPerRow		dw 0
locationOfMem	dw 0

; Output and Consts.
HEX_CHARS 		db '0123456789ABCDEF'
HEX_OUT 		db '0x????', 0
SPACE			db ' ', 0
NEWLINE			db 0x0A, 0x0D, 0
LINE_COLOR		db 0x70
TEXT_COLOR		db 0x04
SCREEN_WIDTH	dw 80