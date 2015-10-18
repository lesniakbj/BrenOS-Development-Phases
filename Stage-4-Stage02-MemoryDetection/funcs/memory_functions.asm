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
	; Add a valid entry as
	; there most likely won'the
	; be one.
	mov [di + 20], dword 1		
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
	
	; Time to reset edx as it will sometimes get 
	; trashed...
	mov edx, 0x534D4150
	; On success, eax should have been set...
	cmp eax, edx
	jne .error_exit
	
	; If = 0, then the list is only 1 entry long
	test ebx, ebx
	je .error_exit
	
	jmp .check_entry
	
.loop:
	; Time to make the call again...
	mov eax, 0xE820
	mov [di + 20], dword 1
	mov ecx, 24
	
	jc .loop_failure
	mov edx, 0x534D4150
	
.check_entry:
	; Skip 0 length entries
	jcxz .skip_empty
	
	; Was the first entry <= a 20 byte entry...?
	cmp cl, 20
	jbe .no_extension
	
	; If its a 24 byte entry, is the ignore bit
	; set...?
	test byte [di + 20], 1
	je .skip_empty
	
.skip_empty:
	; If ebx = 0, then we are done getting the memory
	; list. 
	test ebx, ebx
	jne .loop

.no_extension:
	; Check for a 0 length region
	mov ecx, [di + 8]
	or ecx, [di + 12]
	jz .skip_empty
	
	; Ok, we now inc the entry count, and
	; incrememnt where we store the next entry.
	inc bp
	add di, 24

.loop_failure:
	mov [mem_map_entries], bp
	clc
	ret
	
.error_exit:
	stc
	ret
;=======================;
;		   DATA			;
;=======================;
preserveEBX		dd 0	; Need to preserve
mem_map_entries	dd 0