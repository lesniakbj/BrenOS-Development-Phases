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
	
detect_high_memory:
	
	ret
	
HIGH_MEM_STRUCT:
	resb 