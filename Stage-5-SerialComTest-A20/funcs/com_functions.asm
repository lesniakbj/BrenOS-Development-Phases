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
	
write_hex_8_serial:
	push bx
	push si
	
	mov bx, dx
	shr bx, 4
	and bx, 0x0F
	add bx, HEX_CHARS
	mov bl, [bx]
	mov [HEX_OUT_8], bl
	
	mov bx, dx
	and bx, 0x0F
	add bx, HEX_CHARS
	mov bl, [bx]
	mov [HEX_OUT_8 + 1], bl
	
	mov si, HEX_OUT_8
	call write_string_serial
	
	pop si
	pop bx
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

serial_write_test:
	push ax
	push dx

	; Extended memory between 1M and 16M, 
	; in KB (max 3C00h = 15MB)
	mov ax, [axOut]
	shr ax, 8
	and ax, 0x00FF
	mov dl, al
	call write_hex_8_serial

	mov ax, [axOut]
	and ax, 0x00FF
	mov dl, al
	call write_hex_nl_8_serial
	
	mov ax, [cxOut]
	shr ax, 8
	and ax, 0x00FF
	mov dl, al
	call write_hex_8_serial

	mov ax, [cxOut]
	and ax, 0x00FF
	mov dl, al
	call write_hex_nl_8_serial
	
	; Extended memory above 16M, in 
	; 64K blocks
	mov ax, [bxOut]
	shr ax, 8
	and ax, 0x00FF
	mov dl, al
	call write_hex_8_serial

	mov ax, [bxOut]
	and ax, 0x00FF
	mov dl, al
	call write_hex_nl_8_serial
	
	mov ax, [dxOut]
	shr ax, 8
	and ax, 0x00FF
	mov dl, al
	call write_hex_8_serial

	mov ax, [dxOut]
	and ax, 0x00FF
	mov dl, al
	call write_hex_nl_8_serial
	
	pop dx
	pop ax
	ret
	
; Output test data:
axOut			dw 0
bxOut			dw 0
cxOut			dw 0
dxOut			dw 0

; Working Data - COM
queueStatus		dw 0