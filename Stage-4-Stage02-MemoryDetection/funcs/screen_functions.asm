clear_sceen:
	mov ah, 0
	int 0x10
	
	ret
	
set_screen_mode:
	; Lets set 80x25 mode...
	mov al, 0x03
	int 0x10
	
	; Now lets load an 8x8 font.
	xor bx, bx
	mov ah, 0x11
	mov al, 0x12
	int 0x10
	
	ret