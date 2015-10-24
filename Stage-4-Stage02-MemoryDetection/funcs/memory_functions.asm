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
;		EBX = 0
;		EAX = E820
;		ES:DI = Buffer [mMapBuffer]
;		ECX = 20
;		EDX = SMAP (0x534D4150)
detect_memory_map_e820:
	xor ebx, ebx
	mov eax, 0xE820
	mov ecx, 24
	mov edx, 0x534D4150
	mov di, mMapBuffer	
	
	int 0x15
	
	jc .error_exit
	
	cmp ebx, 0
	je .error_exit
	
	mov [es:di + 20], dword 1
	mov word [mMapEntries], 1
	mov byte [mMapBytesPerEntry], ecx
	
.e820_loop:
	add di, [mMapEntrySize]
	mov eax, 0xE820
	mov edx, 0x534D4150
	mov ecx, 20
	
	int 0x15
	
	cmp ebx, 0
	je .loop_end
	
	jc .loop_end_carry
	
	mov word [mMapEntries], 1
	jmp .e820_loop

.loop_end:
	mov [es:di + 20], dword 1
	inc word [mMapEntries], 1
	ret
	
.loop_end_carry:
	ret
	
.error_exit:
	mov si, ERR_MSG
	call write_string
	stc
	ret
;=======================;
;		   DATA			;
;=======================;
ERR_MSG db 'Error E820!', 0

mMapEntries			dd 0
mMapBytesPerEntry	db 0
mMapEntrySize		db 24

mMapStruct:
	baseAddress		dq 0
	lengthOfRegion	dq 0
	regionType		dd 0
	extAttributes	dd 0