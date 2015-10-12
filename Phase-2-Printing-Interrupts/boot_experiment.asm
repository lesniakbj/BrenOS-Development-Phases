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

jmp bootloader_start		; Safely jump ourselves away from any stored
				; data in the data segement.
;==================================================
; 		DATA SEGEMENT
;==================================================
; OEM Parameter Block
oemName 	db "BrenOS  "	; Must be 8 Bytes long, thus padded with spaces
bytesPerSector:	dw 512
sectorsPerClus: db 1
reservedSectrs: db 1
numberOfFATs:	db 2
rootEntries:	db 224
totalSectors:	dw 2880
media:		db 0xF0
sectorsPerFAT:	dw 9
sectorsPerTrk:	dw 18
headsPerCyln:	dw 2
hiddenSectors:	dd 0
totalSectBig:	dd 0
driveNum:	db 0
unused:		db 0
extBootSig:	db 0x29
serialNum:	dd 0xa0a1a2a3
volLabel:	db "BOS FLOPPY "
fileSystem:	db "FAT12   "

; Bootloader Static Messages / Data
newline db 0x0A, 0x0D, 0
warmupmsg db "Press any key to continue booting...", 0x0A, 0x0D, 0
bootmsg db "Continuing with loading...",0x0A, 0x0D, 0
stackmsg db "Stack Segement (SS) set to: ", 0
stkptmsg db "Stack Pointer (SP) setup to: ", 0
lowmemmsg db "Detecting Low Memory: ", 0
memerrmsg db "Error in Low Memory Detection", 0x0A, 0x0D, 0

; Bootloader datq output swap space
hex_16_out: db '0x0000', 0
;==================================================
;		CODE SEGMENT
;=================================================
bootloader_start:
	xor ax, ax			; 0 out eax to clear junk
	mov ds, ax			; Set the current data segment offset to 0
	mov es, ax			; Do the same with es segement register

	call clear_screen	; Clear the screen before we try to print
						; any strings to the screen
	mov si, warmupmsg
	call write_string
	call wait_for_input

	mov si, bootmsg	
	call write_string

	; Ok, now it's time to setup a stack for our stage01 bootloader
	; to use. This will be used for function calls, and getting ready
	; for our stage02 bootloader. 
	mov ax, 0x07C0		; Set up 4K of stack space after this bootloader
						; code. Start with where this code is loaded
						; from. 
	add ax, 32			; 32 Paragrahs to skip past bootloader, and
						; point SS to the memory segment directly
						; passed our bootloader
	mov ss, ax			; Point our SS to the segment directly after
						; the bootloader
	mov sp, 4096		; Move our stack pointer to SS:4096, giving us
						; 4K of stack space to work with. 

	mov si, stackmsg
	call write_string
	mov ax, ss			; Move SS into AX for printing
	mov dx, ax
	call print_hex
	
	mov si, stkptmsg
	call write_string
	;mov ax, sp
	;mov dx, ax
	;call print_hex
	;mov si, newline
	;call write_string
						
	mov si, lowmemmsg
	call write_string

	xor ax, ax			; Clear AX beforehand
	call detect_low_mem	; After calling this routine, we will get
						; the value of memory returned in ax
				
	mov dx, ax			; To print hex, we need to put the value we
						; want to print in DX
	call print_hex
	
	; Now that we have detected our Low Memory, we want to do some
	; setup so that we can read our 2nd stage bootloader from
	; the rest of the drive. 
	; call reset_disk

	jmp loop		; Jump control over all of our functions, 
				; to an endless loop so we do not exec
				; junk

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

detect_low_mem:
	clc			; Clear the carry flag, it gets set if there
				; is an error in the operation.
	int 0x12		; BIOS call to get the low memory map
	jc .mem_error
	ret

.mem_error:
	mov si, memerrmsg
	call write_string
	ret

print_hex:
	;pusha			; Once stack is setup, push regs before
				; calling so state can be restored

	mov cx, 4		; Start the counter. AX contains 4 "characters"
				; and thus our counter is 4.  4 bits per char.
				; Control continues to hex_to_char_loop
.hex_to_char_loop:
	dec cx			; Pre decrement our counter

	mov ax, dx		; Copy DX to BX so we can mask it
	shr dx, 4		; Shift it 4 bits to the right, so we are 
				; dealing witha  value such:
				; 0xF29A  -->  0x00F2
	and ax, 0x0F		; Get the last 4 bits, one character

	mov bx, hex_16_out	; Set BX to our output memory address
	add bx, 2		; Skip the '0x' char in the string
	add bx, cx		; Add the counter to the address so
				; we can address the correct byte in the string

	cmp ax, 0xA		; Check to see if this is a letter or number
	jl .set_letter		; If its a number, set the value immediately
				; otherwise there is some preprocessing
	add byte [bx], 7	; If its a letter, add 7 to offset to ASCII
				; values

	jl .set_letter

.set_letter:
	add byte [bx], al	; Add the value of the byte to the char at bx

	cmp cx, 0		; Check the counter to see if we are done
	je .print_hex_done	; If we are done, head on out of here
	jmp .hex_to_char_loop	; Otherwise, leads head back to the printing
				; loop so we can print the value

.print_hex_done:
	mov si, hex_16_out	; Now that we are done converting to char,
				; lets print that out
	call write_string
	ret

reset_disk:
	mov ah, 0x00		; Move 0 into AH, the function we want to call
				; 0 = reset floppy function
	mov dl, 0x00		; dl = drive number, 0 the current drive
	int 0x13		; Call BIOS reset function
	jc reset_disk		; If the carry was set there was an error
				; resetting the disk, try again.

loop:
	jmp loop		; Infinite loop when this is called, nothing
				; else to do.
	;cli			; Clear all of the interrupts that were 
				; generated
	;hlt			; Halt any system execution

times 510 - ($ - $$) db 0	; Compiler macro ($ and $$) that
				; fills all the intermediate space with
				; 0 bytes.

dw 0xAA55			; Finally, put the bootsector signature
				; at the end of the file.
