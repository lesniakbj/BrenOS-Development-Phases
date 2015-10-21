;=======================;
;	PRIMARY FUNCTIONS	;
;=======================;
read_sector:
	jmp [readFunction]

;---------------------------------------;
; read_sector_hdd(sector, dest*, length);
;		EAX - Sector to Read			;
;		ES:BX - Destination				;
;		CX - Length						;
;---------------------------------------;
read_sector_hdd:
	; Push all registers full width, because
	; the read function may trash the upper
	; halves
	a32 pusha
	
	; Setup the diskLBAPacket Structure
	mov dl, [diskNumber]
	add eax, [diskPartitionLBA]
	mov [startLBA], eax
	mov [transferOffset], bx
	mov [transferSeg], es
	mov [sectorsToGet], cx
	
	; Call the int so we can read the struct,
	; in turn reading the sectors we want from
	; the drive. 
	mov ah, 0x42
	mov si, diskLBAPacket
	int 0x13
	
	a32 popa
	ret

;---------------------------------------;
; read_sector_fd(sector, dest*, length)	;
;		EAX - Sector to Read			;
;		ES:BX - Destination				;
;		CX - Length						;
;---------------------------------------;
read_sector_fd:
	a32 pusha
	
.read_next_sector:
	call read_single_sector_fd
	
	; Lets move to the next sector
	; to read from.
	add bx, 512
	inc eax
	
	; Loop will decrement CX on every
	; iteration so we do not need to do that.
	loop .read_next_sector
	
.done:
	a32 popa
	ret
	
read_single_sector_fd:
	a32 pusha
	
	; FD's need CHS values instead of
	; LBA. Lets do the conversion.
	call get_chs_values
	
.read_sector:
	call reset_drive
	mov dl, [diskNumber]
	; Read/# of Sectors combined
	mov ax, 0x0201
	int 0x13
	
	jc .read_sector
	
	a32 popa
	ret
	
;---------------------------------------;
; get_chs_values(sector, dest*, length)	;
;		EAX - Sector to Read			;
;		ES:BX - Destination				;
;		CX - Length						;
;---------------------------------------;
get_chs_values:
   xor edx, edx                     ;Zero out edx
   div word [bpbSectorsPerTrack]
   mov cl, dl                     
   inc cl
   xor edx, edx
   div word [bpbNumberOfHeads]
   mov dh, dl                     ;Mov dl into dh (dh=head)
   mov ch, al                     ;Mov cylinder into ch
   shl ah, 6
   or  cl, ah
   ret
   
reset_drive:
	pusha
	
.retry:
	mov ax, 0
	mov dl, [diskNumber]
	int 0x13
	
	jc .retry
	
	popa
	ret
	
;=======================;
;		DISK DATA		;
;=======================;
; DISK READ FUNCTION
readFunction		dd 0

; DISK INFORMATION
diskNumber			db 0
diskPartitionLBA	dd 0
bootPartition		db 0xFF
systemMemory		dd 0

; LBA ADDRESSING PACKET
diskLBAPacket:	
	sizeOfPacket		db 0x10	; Size of the packet	
	alwaysZero			db 0x00	; Always 0	
	sectorsToGet		dw 0	; # of sectors to retrieve
	transferOffset		dw 0	; Where to put them (segment:offset)
	transferSeg			dw 0	; ... cont ...
	startLBA			dd 0	; Linear address to start from
	extraBitLBA			dd 0