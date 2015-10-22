;=======================;
;	PRIMARY FUNCTIONS	;
;=======================;
get_drive_parameters:
	pusha

	popa
	ret
	
.disk_error:
	popa
	ret

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
;		EAX - Sector to Read 			;
;		ES:BX - Destination				;
;		CX - Length						;
;---------------------------------------;



; THIS IMPLEMENTATION "WORKS" - RIP OUT
; EVERYTHING IF WE HAVE TO AND HARDCODE
; THE SECTORS WE NEED TO READ.
read_sector_fd:
	; Read Sector Function
	mov ah, 0x02
	
	; Setup the function defining where
	; we are reading from...
	mov al, 8				; Number of Sectors to Read
	mov dl, [diskNumber]	; Use the 1st (C:) Drive. HDD.
	mov ch, 0				; Use the 1st Cylinder/Track
	mov dh, 0				; Use the 1st Read/Write Head
	mov cl, 2				; Read the 2nd Sector
	int 0x13
	
	jc .disk_read_error
	ret 

.disk_read_error:
	mov si, READ_ERROR
	call write_string
	jmp $
	
read_sector:
	jmp [readFunction]
	
;=======================;
;		DISK DATA		;
;=======================;
; DISK READ FUNCTION
readFunction		dd 0

; DISK PARAMETERS
numberOfDrives		db 0
numberOfHeads		db 0
numberOfSectors		db 0
numberOfCylinders	dw 0
bytesPerSector		dw 512

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