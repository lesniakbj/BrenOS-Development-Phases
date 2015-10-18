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
;=======================;
;		   DATA			;
;=======================;
preserveEBX		dd 0	; Need to preserve
mem_map_entries	dd 0