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
	
	mov dl, 0x0A
	call write_hex_nl_8_serial
	
	; These are some tests of the COMs...
	; I am working on sending Hexideciamal
	; characters, so I can debug the registers,
	; rather than relying on reading the file's
	; hex.
	; mov ax, 0xE801
	; int 0x15
	
	; mov [axOut], ax
	; mov [bxOut], bx
	; mov [cxOut], cx
	; mov [dxOut], dx
	
	; mov dx, COM_1_PORT
	; mov ax, [axOut]
	; shr ax, 8
	; and ax, 0x00FF
	; out dx, al
	
	; mov dx, COM_1_PORT
	; mov ax, [axOut]
	; and ax, 0x00FF
	; out dx, al
	
	call write_newline
	call write_newline
	call write_color_row
	
	jmp $

%include 'funcs/screen_functions.asm'
%include 'funcs/memory_functions.asm'
%include 'funcs/output_functions.asm'

;===========================;
;		COM FUNCTIONS		;
;===========================;
%macro	SERIAL_FIFO_COMMAND_PORT 1 
	mov dx, %1 
	add dx, 2
%endmacro
%macro SERIAL_LINE_COMMAND_PORT 1
	mov dx, %1
	add dx, 3
%endmacro
%macro	SERIAL_MODEM_COMMAND_PORT 1
	mov dx, %1
	add dx, 4
%endmacro
%macro	SERIAL_LINE_STATUS_PORT 1
	mov dx, %1
	add dx, 5
%endmacro

configure_com_port_1:
	push dx
	push bx
	
	mov dx, COM_1_PORT
	mov bx, 4
	
	call configure_com_baud_rate
	call configure_com_line_bits
	call configure_com_buffer
	call configure_com_modem
	
	pop bx
	pop dx
	ret
;-----------------------;
; dx - com port to 		;
; send the baud rate	;
; data to.				;
;						;
; bx - divisor			;
;-----------------------;
configure_com_baud_rate:
	push dx
	push bx
	push ax
	
	; First, we must tell the serial com that we
	; are going to be sending the highest 8 bits
	; followed by the lowest 8 for all coms.
	SERIAL_LINE_COMMAND_PORT dx
	mov al, SERIAL_LINE_ENABLE_DLAB	
	out dx, al
	
	; Now we need to send the speed that we want
	; to communicate with the device with. Really,
	; we send a divisor for the normal com clock
	; of 115200Hz. First we send the top half of
	; the divisor...
	
	; Set the port we are writing to.
	mov dx, SERIAL_DATA_PORT(dx)
	; Move the divisor into CX
	mov ax, bx
	; Send the high byte of CX
	shr ax, 8
	and ax, 0x00FF
	out dx, al
	
	; ... and onto the bottom.
	mov dx, SERIAL_DATA_PORT(dx)
	mov ax, bx
	and ax, 0x00FF
	out dx, al
	
	
	pop ax
	pop bx
	pop dx
	ret

;-----------------------;
; dx - com port to 		;
; send the line bits	;
; data to.				;
;-----------------------;
configure_com_line_bits:
	push dx
	push ax
	
	; Here we send the desired, and standard, configuration
	; bits. This resolves to the 8 bits that mean we are 
	; sending a data length of 8 bits, no parity bits, and
	; no stop bits. 
	SERIAL_LINE_COMMAND_PORT dx
	mov al, 0x03
	out dx, al
	
	pop ax
	pop dx
	ret
	
;-----------------------;
; dx - com port to 		;
; send the buffer info	;
; data to.				;
;-----------------------;
configure_com_buffer:
	push dx
	push ax
	
	; Like the line bits, we need to send a special value
	; so that the com device communicates in the way that
	; we want it to. This: Enables FIFO queing, clears
	; both send and recieve queues, and sets the queue
	; size to 14 bytes. 
	SERIAL_FIFO_COMMAND_PORT dx
	mov al, 0xC7
	out dx, al
	
	pop ax
	pop dx
	ret

;-----------------------;
; dx - com port to 		;
; send the modem info	;
; data to.				;
;-----------------------;
configure_com_modem:
	push dx
	push ax
	
	; We now want to tell the com device to use
	; Ready to Transmit (RTS) and Data Terminal
	; Ready (DTR), and keep interrupts off asm
	; we are not using coms for input.
	SERIAL_MODEM_COMMAND_PORT dx
	mov al, 0x03
	out dx, al
	
	pop ax
	pop dx
	ret
	
;-----------------------;
; dx - com to check info;
; on.					;
;						;
; Returns, [queueStatus];
;-----------------------;
check_com_transmit_queue_empty:
	push dx
	push bx
	push ax
	
	; Now we want to check to see if the line
	; is empty and ready to be used. 0x20 checks
	; to see if the 5th bit is set. Or... test..
	SERIAL_LINE_STATUS_PORT dx
	in al, dx
	and ax, 0x0020
	
	mov [queueStatus], ax
	
	pop ax
	pop bx
	pop dx
	ret
	
; SI is the source index for the data
; we are going to write

; IN PROGRESS
write_string_serial:
	push ax
	push bx
	push dx
	push si
	
.write_loop:
	; Load the character at SI to AL
	lodsb
	cmp al, 0
	je .write_end
	
; Serial OUT loop...
.check_status_loop:
	; Our charcter is stored in AX, we
	; don't want to trash it. 
	push ax
	call check_com_transmit_queue_empty
	mov bx, [queueStatus]
	cmp bx, 0
	pop ax
	je .check_status_loop
		
	; Line is ready, write the data...	
	mov dx, COM_1_PORT
	out dx, al

	jmp .write_loop

.write_end:
	pop si
	pop dx
	pop bx
	pop ax
	ret
	
write_hex_nl_8_serial:
	push bx
	push si
	
	mov bx, dx
	shr bx, 4
	and bx, 0x0F
	add bx, HEX_CHARS
	mov bl, [bx]
	mov [HEX_OUT_NL_8], bl
	
	mov bx, dx
	and bx, 0x0F
	add bx, HEX_CHARS
	mov bl, [bx]
	mov [HEX_OUT_NL_8 + 1], bl
	
	mov si, HEX_OUT_NL_8
	call write_string_serial
	
	pop si
	pop bx
	ret
	
;===============================;
;		BOOT 2 - DATA			;
;===============================;
; Output test data:
axOut	db 0
bxOut	db 0
cxOut	db 0
dxOut	db 0

; Working Data - COM
queueStatus			dw 0

; COM Test Messages
TELL_TEST_MSG		db ' Testing Serial COMs...', 0
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