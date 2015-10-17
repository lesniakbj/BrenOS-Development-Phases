[BITS 16]
[ORG 0x7E00]

boot2_start:
	; Ok, we made it. Lets clear the 
	; screen and set our sceen mode
	; before we continue on...
	call clear_sceen
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
	call write_newline
	call write_newline
	
	; TEST: This mem should be 0'ed
	mov si, memoryMapBuffer
	mov cx, 32
	mov ax, 8
	call write_memory_range_contents_16

	; Now that we did some screen bookkeeping,
	; its time to detect the system memory map
	; and put it into a buffer for us to use.
	; Check the carry flag, as it will be set
	; if there is an error. 
	call fill_memory_info_buffer
	
	; TEST THAT BUFFER FILLED
	mov si, memoryMapBuffer
	mov cx, 32
	mov ax, 8
	call write_memory_range_contents_16
	
	
	; Test of the memory range print
	; function. Lets see if we can print
	; our Stage01 boot code, or at least
	; the first 16 bytes of it. 
	; CX = Number of Bytes to Read
	; AX = Entries per Row (to Display)
	; ES:SI -> Buffer to read from
	mov si, 0x7C00
	mov cx, 32
	mov ax, 8
	call write_memory_range_contents_16
	
	
	call write_color_row
	
	; Bochs error check:
	mov ax, memMapEntryCount
	mov bx, [memMapEntryCount]
	 
	jmp $
	
fill_memory_info_buffer:
	; ES:DI -> Buffer Location
	mov di, memoryMapBuffer
	call detect_memory_map
	jc memory_detect_error
	mov [memMapEntryCount], bp
	
	ret
	
.memory_detect_error:
	mov si, HIGHMEMERR_MSG
	call write_string
	jmp .hlt
	
.hlt:
	cli
	hlt
	jmp .hlt

%include 'funcs/screen_functions.asm'
%include 'funcs/memory_functions.asm'
%include 'funcs/output_functions.asm'

;===============================;
;		BOOT 2 - DATA			;
;===============================;
MEM_DET_MSG		db ' Detecting Memory Map', 0
LOW_MEM_DET_MSG db ' Detecting Low Memory (KB): ', 0
DIVIDER_MSG		db ' =================================', 0
HIGHMEMERR_MSG	db ' Error Using INT 0x15, AX 0xE820!', 0

; Buffer & count for memory map structure
memMapEntryCount	db 0
memoryMapBuffer		resb 128

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