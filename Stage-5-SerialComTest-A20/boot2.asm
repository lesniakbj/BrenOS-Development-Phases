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
	
	;===========================;
	; 	MEM FUNCS IN STAGE-4	;
	;===========================;
	
	; Time to start some communication with
	; external COM ports. We use these not
	; because we want to communicate with 
	; legacy devices, rather, we use these
	; for LOGGING!!! :D
	call configure_com_port_1
	
	out COM_1_PORT, 0x0A
	
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
%define COM_1_PORT						0x03F8
%define SERIAL_DATA_PORT(base)					(base)
%define SERIAL_FIFO_COMMAND_PORT(base)  (base + 2)
%define SERIAL_LINE_COMMAND_PORT(base)  (base + 3)
%define SERIAL_MODEM_COMMAND_PORT(base) (base + 4)
%define SERIAL_LINE_STATUS_PORT(base)   (base + 5)

%define SERIAL_LINE_ENABLE_DLAB         0x80

configure_com_port_1:
	push ax
	push bx
	
	mov ax, COM_1_PORT
	mov bx, 4
	
	call configure_com_baud_rate
	call configure_com_line_bits
	call configure_com_buffer
	call configure_com_modem
	
	pop bx
	pop ax
	ret
;-----------------------;
; ax - com port to 		;
; send the baud rate	;
; data to.				;
;						;
; bx - divisor			;
;-----------------------;
configure_com_baud_rate:
	push ax
	push bx
	push cx
	push dx
	
	; First, we must tell the serial com that we
	; are going to be sending the highest 8 bits
	; followed by the lowest 8 for all coms.
	mov dx, SERIAL_LINE_COMMAND_PORT(ax)
	mov cl, SERIAL_LINE_ENABLE_DLAB	
	out dx, cl
	
	; Now we need to send the speed that we want
	; to communicate with the device with. Really,
	; we send a divisor for the normal com clock
	; of 115200Hz. First we send the top half of
	; the divisor...
	
	; Set the port we are writing to.
	mov dx, SERIAL_DATA_PORT(ax)
	; Move the divisor into CX
	mov cx, bx
	; Send the high byte of CX
	shr cx, 8
	and cx, 0x00FF
	out dx, cl
	
	; ... and onto the bottom.
	mov dx, SERIAL_DATA_PORT(ax)
	mov cx, bx
	and cx, 0x00FF
	out dx, cl
	
	
	pop dx
	pop cx
	pop bx
	pop ax
	ret

;-----------------------;
; ax - com port to 		;
; send the line bits	;
; data to.				;
;-----------------------;
configure_com_line_bits:
	push ax
	push dx
	
	; Here we send the desired, and standard, configuration
	; bits. This resolves to the 8 bits that mean we are 
	; sending a data length of 8 bits, no parity bits, and
	; no stop bits. 
	mov dx, SERIAL_LINE_COMMAND_PORT(ax)
	out dx, 0x03
	
	pop dx
	pop ax
	ret
	
;-----------------------;
; ax - com port to 		;
; send the buffer info	;
; data to.				;
;-----------------------;
configure_com_buffer:
	push ax
	push dx
	
	; Like the line bits, we need to send a special value
	; so that the com device communicates in the way that
	; we want it to. This: Enables FIFO queing, clears
	; both send and recieve queues, and sets the queue
	; size to 14 bytes. 
	mov dx, SERIAL_FIFO_COMMAND_PORT(ax)
	out dx, 0xC7
	
	pop dx
	pop ax
	ret

;-----------------------;
; ax - com port to 		;
; send the modem info	;
; data to.				;
;-----------------------;
configure_com_modem:
	push ax
	push dx
	
	; We now want to tell the com device to use
	; Ready to Transmit (RTS) and Data Terminal
	; Ready (DTR), and keep interrupts off asm
	; we are not using coms for input.
	mov dx, SERIAL_MODEM_COMMAND_PORT(ax)
	out dx, 0x03
	
	pop dx
	pop ax
	ret
	
;-----------------------;
; ax - com to check info;
; on.					;
;						;
; Returns, [queueStatus];
;-----------------------;
check_com_transmit_queue_empty:
	push ax
	push bx
	push dx
	
	; Now we want to check to see if the line
	; is empty and ready to be used. 0x20 checks
	; to see if the 5th bit is set. Or... test..
	mov dx, SERIAL_LINE_STATUS_PORT(ax)
	in bl, dx
	and bx, 0x0020
	
	mov [queueStatus], bx
	
	pop dx
	pop bx
	pop ax
	ret
;===============================;
;		BOOT 2 - DATA			;
;===============================;
; Working Data - COM
queueStatus			dw 0

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