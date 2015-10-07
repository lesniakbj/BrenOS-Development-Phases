; The following lines of code are interpreted by the
; compiler, and are not a part of the output binary.
; The directives are specifed below in comments.

[BITS 16]			; When loaded by the operating system, we are
				; loaded into 16 bit mode. Thus, the kernel
				; bootloader needs to be 16 bits.

[ORG 0x7C00]			; We get loaded into memory at location 0x7C00
				; by BIOS

start:
	xor eax, eax		; 0 out eax to clear junk
	mov eax, 0xBEAD0501	; This is a signature for BrenOS
	
	; Here we are going to try and call a BIOS interrupt to 
	; print some characters to the screen.
	; I need to setup some registers to do this correctly:
	; ah = function to call when interrupt handler is called,
	; al = Character, bl = Color
	mov ah, 0x0E
	mov al, 'H'
	int 0x10
	
	jmp .loop
.loop:
	jmp .loop		; Infinite loop when this is called, nothing
				; else to do.	
	;cli			; Clear all of the interrupts that were generated
	;hlt			; Halt any system execution

times 510 - ($ - $$) db 0	; Compiler macro that
				; fills all the intermediate space with 
				; 0 bytes.

dw 0xAA55			; Finally, put the bootsector signature
				; at the end of the file.
