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
	xor ecx, ecx
	
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
	jc .error_exit
	
	; Save ebx as it needs to be preserved,
	; along with cl, which contains the number
	; of bytes now stored at ES:DI
	mov [preserveEBX], ebx

	ret
	
.error_exit:
	stc
	ret
	
; To check if the A20 line is enabled, we
; will compare a known value (boot01 magic
; value) to the equivalent wrap around address.
; If they are equal, the A20 is disabled.

; We will use FS/GS as our Extra Segement.
check_A20_enabled:
	push bx
	push cx
	push fs
	push gs
	
	; Clear the carry flag, we will be returning
	; the carry flag if the A20 line is already
	; enabled. 
	clc
	; Setup a segment:offset pair...
	; for 0000:7DFE to get the bootsector byte.
	xor bx, bx
	mov fs, bx
	mov bx, 0x7DFE
	
	; Clear CX, then move the word at
	; 0000:7DFE (55AA) into cx. Push cx
	; so we can use it again. 
	xor cx, cx
	mov cx, word [fs:bx]
	push cx
	
	; Setup a segment:offset pair...
	; for FFFF:7DFE to check if this byte
	; is the same as the inital byte. 
	mov bx, 0xFFFF
	mov gs, bx
	mov bx, 0x7E0E	
	
	; Again, clear CX, then move the word
	; at FFFF:7E0E into CX. Copy that from 
	; CX into BX, then pop CX back to the 
	; pushed value from before. 
	xor cx, cx
	mov cx, word [gs:bx]
	mov bx, cx
	pop cx
	
	cmp bx, cx
	je .A20_disabled_sanity_check

	stc
	mov byte [A20Enabled], 1	
	pop gs
	pop fs
	pop cx
	pop bx
	ret
	
.A20_disabled_sanity_check:
	xor bx, bx
	mov fs, bx
	mov bx, 0x7DFE
	
	mov word [fs:bx], 0xBE05
	mov bx, 0xFFFF
	mov gs, bx
	mov bx, 0x7E0E
	cmp word [gs:bx], 0xBE05
	jne .A20_enabled

	mov byte [A20Enabled], 0	
	pop gs
	pop fs
	pop cx
	pop bx
	ret
	
.A20_enabled:
	stc
	mov byte [A20Enabled], 1
	pop gs
	pop fs
	pop cx
	pop bx
	ret
	
; This is the quickest and easiest way
; to enable the A20 line... simple... easy...
; And, only do the write if necissary
enable_A20_fast:
	; Read from system control port A
	in al, 0x92
	; Test the 2nd bit of byte we just read,
	; 0 - A20 Disabled, 1 - Enabled
	test al, 2
	jnz .A20_enabled
	
	; Set the A20 bit...
	or al, 2
	
	; Note:
	; "Since bit 0 sometimes is write-only, 
	; and writing a 1 there causes a reset, 
	; ..." ... don't write a 1 to bit 0. 
	and al, 0xFE
	
	; ... now enable the A20 Line
	out 0x92, al
	
	ret

.A20_enabled:
	ret
	
;=======================;
;		   DATA			;
;=======================;
preserveEBX			dd 0	; Need to preserve
mem_map_entries		dd 0

; Working Data - A20
A20Enabled			db 0

; Working Data - E820
mMapBytesPerEntry	db 0

memoryMapStruct:
	baseAddress		dq 0
	lengthOfRegion	dq 0
	regionType		dd 0
	extAttributes	dd 0