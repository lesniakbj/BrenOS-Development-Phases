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
	
	
write_hex_8:
	push bx
	push si
	
	mov bx, dx
	shr bx, 4
	and bx, 0x0F
	add bx, HEX_CHARS
	mov bl, [bx]
	mov [HEX_OUT_8], bl
	
	mov bx, dx
	and bx, 0x0F
	add bx, HEX_CHARS
	mov bl, [bx]
	mov [HEX_OUT_8 + 1], bl
	
	mov si, HEX_OUT_8
	call write_string
	
	pop si
	pop bx
	ret

	
write_hex_16:
	push bx
	push si
	
	mov bx, dx
	shr bx, 12
	and bx, 0x0F
	add bx, HEX_CHARS
	mov bl, [bx]
	mov [HEX_OUT_16], bl
	
	mov bx, dx
	shr bx, 8
	and bx, 0x0F
	add bx, HEX_CHARS
	mov bl, [bx]
	mov [HEX_OUT_16 + 1], bl
	
	mov bx, dx
	shr bx, 4
	and bx, 0x0F
	add bx, HEX_CHARS
	mov bl, [bx]
	mov [HEX_OUT_16 + 2], bl
	
	mov bx, dx
	and bx, 0x0F
	add bx, HEX_CHARS
	mov bl, [bx]
	mov [HEX_OUT_16 + 3], bl
	
	mov si, HEX_OUT_16
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

	
write_memory_range_8:
	push ax
	push cx
	push dx
	push si
	
	mov [bytesPerRow8], ax
	mov [initialLocMem8], si
	mov byte [offsetLoc8], 0
	
.start:
	dec ax
	dec cx
	
	call write_space
	
	mov dl, [si]
	call write_hex_8
	; Add 1 to SI before we jump
	; back to the start, because
	; we are printing 8 bit (1
	; byte) values.	
	add si, 1
	
	cmp cx, 0
	je .end
	
	cmp ax, 0
	je .newline
	
	
	jmp .start

.newline:
	; call .print_addresses
	call write_newline
	
	mov ax, [bytesPerRow8]
	mov [initialLocMem8], si
	add [offsetLoc8], ax
	
	jmp .start
	
.end:
	; call .print_addresses
	call write_newline
	call write_newline
	call write_newline
	
	pop si
	pop dx
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
write_memory_range_16:
	push ax
	push cx
	push dx
	push si
	
	; Setup some scratch work variables
	; for us that we will need to use.
	mov [bytesPerRow16], ax
	mov [initialLocMem16], si
	mov word [offsetLoc16], 0
	
.start:
	; We're starting an interation of the
	; print loop, so decrement both the
	; number of bytes to print and the number
	; drawn on that row. 
	dec ax
	dec cx
	
	; Start off by padding the table with some
	; space.
	call write_space
	
	; To write the value at si (our memory buffer)
	; we need to move the data into dx. Then print
	; it.
	mov dx, [si]
	call write_hex_16
	
	; Add 2 to SI before we jump back to the 
	; start, because we are printing 16 bit (2
	; byte) values.	
	add si, 1
	
	; Have we finished displaying all the words...?
	cmp cx, 0
	je .end
	
	; Have we finished all the words on this line...?
	cmp ax, 0
	je .newline
	
	; ... nope, lets print another character from the 
	; buffer.
	jmp .start
	
.newline:
	call .print_addresses
	call write_newline
	
	mov ax, [bytesPerRow16]
	mov [initialLocMem16], si
	
	push ax
	shl ax, 1
	add [offsetLoc16], ax
	pop ax
	
	jmp .start
	
	
.end:
	call .print_addresses
	call write_newline
	call write_newline
	call write_newline
	
	pop si
	pop dx
	pop cx
	pop ax
	ret

.print_addresses:
	; We want to print something
	; like this at the end of 
	; every line:
	;	<relative> : <absolute>
	
	; This part does the absolute
	; section of the address.
	push si
	push dx
	
	call write_space
	
	mov si, PIPE_STRING
	call write_string
	call write_space
	
	mov dx, [offsetLoc16]
	call write_hex_16
	
	mov si, COLON_STRING
	call write_string
	
	mov dx, [initialLocMem16]
	call write_hex_16
	
	pop dx
	pop si
	ret

;==============================;
;		FUNCTIONS DATA		   ;
;==============================;
; NOTE: I can probably just use
; the same scratch data for each
; function?
; Working Data - Print Hex 8
bytesPerRow8	db 0
initialLocMem8	db 0
offsetLoc8		db 0

; Working data - Print Hex 16
bytesPerRow16	dw 0
initialLocMem16	dw 0
offsetLoc16		dw 0

; Output and Consts.
HEX_CHARS 		db '0123456789ABCDEF'
HEX_OUT_8 		db '??', 0
HEX_OUT_16 		db '????', 0
SPACE			db ' ', 0
PIPE_STRING		db '|', 0
COLON_STRING	db ':', 0
NEWLINE			db 0x0A, 0x0D, 0
LINE_COLOR		db 0x70
TEXT_COLOR		db 0x04
SCREEN_WIDTH	dw 80