;==================================================
; The following lines of code are interpreted by the
; compiler, and are not a part of the output binary.
; The directives are specifed below in comments.
;==================================================
[BITS 16]			; When loaded by the operating system, we are
				; loaded into 16 bit mode. Thus, the kernel
				; bootloader needs to be 16 bits.

[ORG 0x7C00]			; We get loaded into memory at location 0x7C00
				; by BIOS

jmp start			; Safely jump ourselves away from any stored
				; data in the data segement.
;==================================================
; 		DATA SEGEMENT
;==================================================
newline db 10, 13
warmupmsg db "Press any key to continue booting...", newline, 0
bootmsg db "Hello BIOS! Thanks!", 0
;==================================================
;		CODE SEGMENT
;=================================================
start:
	xor ax, ax		; 0 out eax to clear junk
	mov ds, ax		; Set the current data segment offset to 0
	mov es, ax		; Do the same with es segement register

	call clear_screen	; Clear the screen before we try to print
				; any strings to the screen

	mov si, warmupmsg
	call write_string
	call wait_for_input


	mov si, bootmsg		; Move the stack data pointer to point to
				; our bootmsg and call the print routines
	call write_string

	jmp loop

clear_screen:
	mov ah, 0
	int 0x10
	ret

wait_for_input:
	xor ax, ax
	int 0x16
	ret

write_string:
	lodsb			; Load the string buffer at ds:si
	or al, al		; or the current character to ...
	jz .write_string_end	; If it is 0 (null terminator) jump to the
				; end print function. Else continue.
	call write_character	; Write the character that is in the buffer
	jmp write_string	; Do this until the buffer end is reached

.write_string_end:
	ret

write_character:
	mov bl, 0x04		; Don't make any register assumptions, always
				; set to wanted color here.
	mov ah, 0x0E
	int 0x10
	ret

loop:
	jmp loop		; Infinite loop when this is called, nothing
				; else to do.
	;cli			; Clear all of the interrupts that were generated
	;hlt			; Halt any system execution

times 510 - ($ - $$) db 0	; Compiler macro ($ and $$) that
				; fills all the intermediate space with
				; 0 bytes.

dw 0xAA55			; Finally, put the bootsector signature
				; at the end of the file.
