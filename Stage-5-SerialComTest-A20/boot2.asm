[BITS 16]
[ORG 0x7E00]

jmp boot2_start

%define COM_1_PORT						0x03F8
%define SERIAL_LINE_ENABLE_DLAB         0x80
%define SERIAL_DATA_PORT(base)			(base)

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
	
	;===========================;
	; 	MEM FUNCS IN STAGE-4	;
	;===========================;	
	
	; Time to start some communication with
	; external COM ports. We use these not
	; because we want to communicate with 
	; legacy devices, rather, we use these
	; for LOGGING!!! :D
	call configure_com_port_1
	
	mov si, TELL_TEST_MSG
	call write_string
	
	mov si, COM_TEST_MSG
	call write_string_serial
	
	; These are some tests of the COMs...
	; I am working on sending Hexideciamal
	; characters, so I can debug the registers,
	; rather than relying on reading the file's
	; hex.
	mov ax, 0xE801
	int 0x15
	
	; Lets test the routine out and verify that 
	; everything is working correctly. 
	mov [axOut], ax
	mov [bxOut], bx
	mov [cxOut], cx
	mov [dxOut], dx
	call serial_write_test
	
	; Now.. onto the A20 line. We used BIOS to 
	; determine how much memory we have, but without
	; enabling the A20 line, we cannot address more
	; than 1MB due to the behavior of real mode 
	; adderssing and compatibility reasons. 
	mov si, A20_TEST_MSG
	call write_string
	; First, lets check to see if the A20 line is
	; already enabled. 
	mov byte [A20Enabled], 0
	call check_A20_enabled
	; jc .A20_enabled
	
	;		OR
	cmp byte [A20Enabled], 1
	je .A20_enabled
	
	
	call write_newline
	call write_newline
	call write_color_row
	
	jmp $

.A20_enabled:
	mov si, A20_ENABLED
	call write_string
	
	call write_newline
	call write_newline
	call write_color_row
	
	jmp $

%include 'funcs/screen_functions.asm'
%include 'funcs/memory_functions.asm'
%include 'funcs/output_functions.asm'
%include 'funcs/com_functions.asm'
	
;===============================;
;		BOOT 2 - DATA			;
;===============================;
; COM Test Messages
TELL_TEST_MSG		db ' Testing Serial COMs...', 0x0A, 0x0D, 0
COM_TEST_MSG		db 'Test this string!', 0x0A, 0x0D, 0

; Memory Messages
MEM_DET_MSG			db ' Detecting Memory Map', 0
LOW_MEM_DET_MSG 	db ' Detecting Low Memory (KB): ', 0
DIVIDER_MSG			db ' =================================', 0
HIGH_MEM_MSG 		db ' Detecting High Memory: ', 0
BYTES_DET_MSG		db ' Bytes Stored (0x): ', 0
HIGHMEMERR_MSG		db ' Error Using INT 0x15, AX 0xE820!', 0

; COM/Serial Port Messages
CONF_SERIAL_MSG		db ' Configuring Serial Ports', 0
SEND_BYTE_MSG		db ' Sending Byte: ', 0

; A20 Messages
A20_TEST_MSG		db ' Testing the A20 Line...', 0x0A, 0x0D, 0
A20_ENABLED			db ' A20 Line is Enabled!', 0


; Buffer for memory map structure
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