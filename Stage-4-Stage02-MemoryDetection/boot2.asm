[BITS 16]
[ORG 0x7E00]

boot2_start:
	; Ok, we made it. Lets clear the 
	; screen before we continue on...
	call clear_sceen
	
	; .. now that the screen is clear
	; lets set the screen mode we want
	; to use for now (80:25:8x8)
	call set_screen_mode
	
	; FUNC TEST
	mov al, 'H'
	mov cx, 1
	call write_char
	call write_color_row
	
	; Now we should write what we are 
	; are doing, for record keeping.
	; mov si, LOW_MEM_DET_MSG
	; call write_string
	
	; Lets now detect the total amount
	; of low memory.
	; call detect_low_memory
	
	; Now that we have the low memory in
	; AX, lets put it in DX so we can
	; write it to the screen.
	; mov dx, ax
	; call write_hex
	
	jmp $


%include 'funcs/screen_functions.asm'
%include 'funcs/memory_functions.asm'
%include 'funcs/output_functions.asm'


LOW_MEM_DET_MSG db 'Detecting Low Memory (KB): ', 0 

; NOTE:
; ======================
; Some emulators and disk drives will
; not read a sector unless it is fully 
; padded out, thus we need to pad this
; sector or it will not be read. This is
; true of all sectors we read in some 
; emulators. Thus, the last sector of every
; code segment must be padded.
TIMES 512 db 0