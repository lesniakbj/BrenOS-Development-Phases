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
	
	; Add some color to the screen, see 
	; if we can turn this into a msg
	; screen.
	call write_color_row
	call write_newline
	call write_newline
	
	; Tell the user that we are now
	; detecting memory in their system.
	mov si, MEM_DET_MSG
	call write_string
	call write_newline
	mov si, DIVIDER_MSG
	call write_string
	call write_newline
	call write_newline
	
	; Now we should write what we are 
	; are doing, for record keeping.
	mov si, LOW_MEM_DET_MSG
	call write_string
	
	; Lets now detect the total amount
	; of low memory.
	call detect_low_memory
	
	; Now that we have the low memory in
	; AX, lets put it in DX so we can
	; write it to the screen.
	mov dx, ax
	call write_hex
	
	; And back to this, add some 
	call write_newline
	call write_newline
	
	; Now that we did some screen bookkeeping,
	; its time to detect the system memory map
	; and put it into a buffer for us to use.
	; Inputs: es:di -> destination buffer for 24 byte entries
	; Outputs: bp = entry count, trashes all registers except esi
	mov di, memoryMapBuffer
	pusha
	call detect_memory_map
	popa
	; mov [memMapEntryCount], bp
	
	call write_newline
	call write_newline
	call write_color_row
	
	; Bochs error check:
	mov ax, memMapEntryCount
	; mov bx, [memMapEntryCount]
	
	jmp $


%include 'funcs/screen_functions.asm'
%include 'funcs/memory_functions.asm'
%include 'funcs/output_functions.asm'

;===============================;
;		BOOT 2 - DATA			;
;===============================;
MEM_DET_MSG		db ' Detecting Memory Map', 0
LOW_MEM_DET_MSG db ' Detecting Low Memory (KB): ', 0
DIVIDER_MSG		db ' =================================', 0

; Buffer & count for memory map structure
memMapEntryCount	db 0
memoryMapBuffer		resb 0

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