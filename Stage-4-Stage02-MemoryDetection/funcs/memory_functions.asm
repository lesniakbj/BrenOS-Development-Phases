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
	
	
; Use the INT 0x15, eax= 0xE820 BIOS function to get a memory map
detect_memory_map:
	ret
	
;=======================;
;		   DATA			;
;=======================;
memMapEntry db 0 