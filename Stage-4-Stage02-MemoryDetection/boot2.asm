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
	call write_hex_16
	call write_newline
	call write_newline
	call write_newline
	call write_newline
	
	mov si, HIGH_MEM_MSG
	call write_string
	call write_newline
	call write_newline
	mov si, BYTES_DET_MSG
	call write_string
	; TEST: This mem should be 0'ed
	; mov si, memoryMapBuffer
	; mov cx, 12
	; mov ax, 6
	; call write_memory_range_contents_16

	; Now that we did some screen bookkeeping,
	; its time to detect the system memory map
	; and put it into a buffer for us to use.
	; Check the carry flag, as it will be set
	; if there is an error. 
	call fill_memory_info_buffer
	
	mov dx, [mMapBytesPerEntry]
	call write_hex_8
	call write_newline
	call write_newline
	call write_newline
	call write_newline
	
	; Test of the memory range print
	; function. Lets see if we can print
	; our Stage01 boot code, or at least
	; the first 16 bytes of it. 
	; CX = Number of Words to Read
	; AX = Entries per Row (to Display)
	; ES:SI -> Buffer to read from
	mov si, memoryMapBuffer
	mov cx, 10						; After 1 call, the buffer fills with 20-24 bytes.
									; Typically 20, so we will use that.
	mov ax, 5
	call write_memory_range_16
	call write_newline
	call write_newline
	
	; mov si, memoryMapBuffer
	; mov cx, 20
	; mov ax, 10
	; call write_memory_range_8
	
	; Fun Experiment: Read the entire
	; bootsector1 code and addresses.
	; mov si, 0x7C00
	; mov cx, 256
	; mov ax, 8
	; call write_memory_range_16
	
	; mov si, 0x7C00
	; mov cx, 512
	; mov ax, 16
	; call write_memory_range_8
	
	call write_color_row
	
	; Bochs error check:
	xor eax, eax
	mov ax, mMapBytesPerEntry
	mov bx, [mMapBytesPerEntry]
	 
	jmp $
	
fill_memory_info_buffer:
	; ES:DI -> Buffer Location
	mov di, memoryMapBuffer
	call detect_memory_map
	jc .memory_detect_error
	mov [mMapBytesPerEntry], cl
	
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
MEM_DET_MSG			db ' Detecting Memory Map', 0
LOW_MEM_DET_MSG 	db ' Detecting Low Memory (KB): ', 0
DIVIDER_MSG			db ' =================================', 0
HIGH_MEM_MSG 		db ' Detecting High Memory: ', 0
BYTES_DET_MSG		db ' Bytes Stored (0x): ', 0
HIGHMEMERR_MSG		db ' Error Using INT 0x15, AX 0xE820!', 0

; Buffer & count for memory map structure
mMapBytesPerEntry	db 0

memoryMapStruct:
	baseAddress		dq 0
	lengthOfRegion	dq 0
	regionType		dd 0
	extAttributes	dd 0

memoryMapBuffer:

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