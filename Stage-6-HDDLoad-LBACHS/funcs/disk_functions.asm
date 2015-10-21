;=======================;
;	PRIMARY FUNCTIONS	;
;=======================;
lba_to_chs:
	mov [lbaAddress], ax

.start:
	; Divide dx:ax by sectorsPerTrack and add 1
	; Sector = (LBA % (Sectors per Track)) + 1,
	; then save it.
	; Temp = LBA / (Sectors per Track)
	xor dx, dx
	div word [sectorsPerTrack]
	inc dl
	mov byte [absoluteSector], dl
	
	; Head = Temp % (Number of Heads)
	; Cylinder = Temp / (Number of Heads)
	xor dx, dx
	div word [numberOfHeads]
	mov byte [absoluteHead], dl
	mov byte [absoluteCylnider], al
	
	ret 

reset_disk:
	mov ah, 0x00			; Move 0 into AH, the function we want to call
							; 0 = reset floppy function
	mov dl, [diskNumber]	; dl = drive number
	int 0x13				; Call BIOS reset function
	jc reset_disk			; If the carry was set there was an error
							; resetting the disk, try again.
	ret
	
read_hard_drive:
	mov si, diskPacket
	mov ah, 0x42
	mov dl, [diskNumber]
	int 0x13
	
	; The carry flag will be set if there is any 
	; error during the transfer. AH should be
    ; set to 0 on success.
	jc .disk_read_error
	ret
	
.disk_read_error:
	mov si, READ_ERROR_HDD
	call write_string
	jmp $	
	
read_floppy:
	mov ah, 0x02	; Read Sector Function
	
	mov al, 1		; Number of Sectors to Read
	; mov dl, 0x80	; Use the 1st (C:) Drive. HDD.
	mov ch, 0		; Use the 1st Cylinder/Track
	mov dh, 0		; Use the 1st Read/Write Head
	mov cl, 2		; Read the 2nd Sector
	
	; Where to buffer the disk read to...
	; ES:BX
	mov bx, 0
	mov es, bx		; ES -> 0
	mov bx, 0x7E00	; BX -> 0x7E00 = 0x0000:0x7E00
	
	int 0x13
	
	jc .disk_read_error
	ret 

.disk_read_error:
	mov si, READ_ERROR
	call write_string
	jmp $
	

get_drive_geometry:
	xor ax, ax
	mov ah, 0x08
	mov dl, [diskNumber]
	int 0x13
	
	; DH = Number of Heads
	; The value returned in DH is the 
	; "Number of Heads" -1
	mov [numberOfHeads], dh
	add dh, 1
	
	; CL and 0x3F = Sectors per Track
	and cl, 0x3F
	mov [sectorsPerTrack], cl
	
	ret
	
get_address_extensions:
	clc
	
	; Check to see if the 
	; extensions are supported. 
	mov ah, 0x41
	mov bx, 0x55AA
	mov dl, 0x80
	int 0x13
	
	; Carry will be set by the int
	; if they are NOT supported
	ret