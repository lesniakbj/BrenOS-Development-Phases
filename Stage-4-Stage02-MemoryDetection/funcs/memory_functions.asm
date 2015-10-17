;=======================;
;	PRIMARY FUNCTIONS	;
;=======================;
detect_low_memory:
	clc
	int 0x12
	; jc .error 
	; ToDo: Pass the error
	; to a memory location 
	; for handling
	ret
	
	
; The calling function will set the buffer
; location for the memory map.
detect_memory_map:
	xor ebx, ebx
	
	; Move the magic number into edx
	; before the BIOS call. 
	mov edx, 0x534D4150
	; Set the function call here
	mov eax, 0xE820
	mov ecx, 24
	; ... and BIOS call
	int 0x15
	
	; After the int call, eax should
	; contain the magic number, and
	; the carry flag will be clear if
	; there is no error. 
	cmp eax, 0x534D4150
	je .error_exit
	jc .error_exit
	
	; Save ebx as it needs to be preserved,
	; along with cl, which contains the number
	; of bytes now stored at ES:DI
	mov [memCallOneEBX], ebx
	mov [memCallOneCL], cl
	
	ret

.error_exit:
	mov si, memError
	call write_string
	stc
	ret
	
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
;=======================;
;		   DATA			;
;=======================;
memError		db 'MEM ERROR!', 0
memCallOneEBX	dd 0	; Need to preserve
memCallOneCL	db 0	; Number of bytes in call 1
memMapEntry 	db 0 