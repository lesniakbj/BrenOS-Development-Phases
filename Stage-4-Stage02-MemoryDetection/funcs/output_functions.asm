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
	mov bl, [TEXT_COLOR]
	int 0x10
	jmp .string_loop
	
.string_end:
	pop si
	pop ax
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

;=======================;
;	 HELPER FUNCTIONS	;
;=======================;
write_newline:
	mov si, NEWLINE
	call write_string
	ret
	
write_color_row:
	push ax
	push cx
	
	mov al, ' '
	mov cx, [SCREEN_WIDTH]
	mov bl, [LINE_COLOR]
	call write_char
	
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
; DX -> Number of   ;
;		bytes per   ;
;		row.		;
;-------------------;
write_memory_range_contents:
	mov [bytesPerRow], dx
	
.start:
	dec cx
	dec dx
	
	mov dx, [si]
	call write_hex
	
	push si
	mov si, SPACE
	call write_string
	pop si
	
	cmp cx, 0
	je .end
	
	cmp dx, 0
	call .new_row
	
	inc si
	jmp write_memory_range_contents

	
.new_row:
	push si
	call write_newline
	pop si
	
	mov dx, [bytesPerRow]
	ret
	
.end:
	push si
	call write_newline
	pop si
	ret

;==============================;
;		FUNCTIONS DATA		   ;
;==============================;
; Working data
bytesPerRow		db 0

; Output and Consts.
HEX_CHARS 		db '0123456789ABCDEF'
HEX_OUT 		db '0x????', 0
SPACE			db ' '
NEWLINE			db 0x0A, 0x0D, 0
LINE_COLOR		db 0x70
TEXT_COLOR		db 0x04
SCREEN_WIDTH	dw 80