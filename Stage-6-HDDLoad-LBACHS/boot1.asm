; NOTE:
;	This file follows the BPB format of
;	the FAT12 specification, listed at
;	http://wiki.osdev.org/FAT#BPB_.28BIOS_Parameter_Block.29
[BITS 16]
[ORG 0x7C00]

; Cononicalize CS:IP to 0x0000:0x7C00
; 	Note: Some BIOS' start us at 
;	0x07C0:0x0000. We fix that.
jmp short boot1_start
nop

;====================================;
;		BIOS PARAMETER BLOCK		 ;
;====================================;
bpbOemIdentifier		db 'BrenOS  '
bpbBytesPerSector		dw 512
bpbSectorsPerCluster	db 1
bpbReservedSectors		dw 1
bpbNumberOfFATs			db 1
bpbRootEntries			dw 224
bpbTotalNumberSectors	dw 0
bpbMediaDescriptor		db 0xF8
bpbSectorsPerFAT		dw 0
bpbSectorsPerTrack		dw 0
bpbNumberOfHeads		dw 0
bpbHiddenSectors		dd 0
bpbLargeMediaFields		dd 0

;====================================;
;  FAT12 EXTENDED BOOT RECORD (EBPB) ;
;====================================;
driveNumber			db 0x00
reservedField		db 0x00
signatureFAT12		db 0x29
volumeID			dd 0
volumeLabel			db 'BrenOS Sys '
fileSystemID		db 'FAT     '


; ... whew! Now that we defined all the
; things "necissary" to define our FAT
; bootable device, time to start our boot1
; code.

boot1_start:
	; Setup the segments
	cli
	xor ax, ax
	mov ds, ax
	mov es, ax
	
	; Time for the stack
	mov ss, ax
	mov sp, 0x7C00
	sti
	
	; Save the disk that we are
	; booted from.
	mov [diskNumber], dl
	mov [driveNumber], dl
	
	; Test to see if the HDD bit is set
	test dl, 0x80
	jnz boot_hdd
	
	; Ok, we are using a floppy dive, lets
	; save that so it can be used. 
	mov dword [readFunction], read_sector_fd
	jmp boot_hdd.no_mbr_found
	
; We're booting off of a HDD, so we need to find
; the MBR to figure out our partition.
boot_hdd:
	mov dword [readFunction], read_sector_hdd
	
	; Read the MBR: 
	;	Sector 0
	;	To Address 0x0000:0x1000 -> So we can put
	;								our code elsewhere. 
	;	Read 1 sector
	mov eax, 0
	mov es, ax
	mov bx, 0x1000
	mov cx, 1
	call read_sector
	
	xor ecx, ecx
	; Offset to the MBR table
	mov eax, 0x1000 + 446

; Time to determine the boot partition + LBA 
; offset. 
.check_next_sector:
	; If we find a 0 byte, 
	; then we have not found our boot
	; partition. If it's not 0, we have
	; not.
	cmp byte [eax], 0
	jne .found_boot_partition
	
	; We are going to search 4, 16 byte 
	; blocks for the MBR.
	inc cx
	cmp cx, 4
	je .no_mbr_found
	
	add eax, 16
	jmp .check_next_sector

; Now that we found the partition, lets 
; save the partition number and the LBA
; offset. 	
.found_boot_partition:
	; The partition booted from will be
	; in cl once we find it. 
	mov [bootPartition], cl
	
	; Lets grab the LBA of the disk
	; partition.
	mov ebx, [eax + 8]
	mov [diskPartitionLBA], ebx
	jmp .no_mbr_found

; Either way we need to load our 2nd stage, 
; so lets do that. 	
.no_mbr_found:
	mov eax, 1
	mov bx, 0x7E00
	mov cx, 4
	call read_sector
	
	mov ax, [diskNumber]
	push ax
	jmp 0x0000:stage02_load
	
	
%include "funcs/disk_functions.asm"

write_string:
	push ax
	push si

	
.string_loop:
	lodsb
	cmp al, 0
	je .string_end
		
	mov ah, 0x0E
	int 0x10
	jmp .string_loop
	
.string_end:
	pop si
	pop ax
	ret
	
;========================;
;		BOOT-1 DATA		 ;
;========================;
; String Data
BOOT_MSG			db 'Loading stage 2 from floppy...', 0x0A, 0x0D, 0
HDD_BOOT_MSG		db 'Loading stage 2 from HDD...', 0x0A, 0x0D, 0
HDD_BOOT_CHS_MSG	db 'Loading stage 2 from HDD-CHS...', 0x0A, 0x0D, 0
READ_ERROR			db 'Err read from Disk!', 0x0A, 0x0D, 0
READ_ERROR_HDD		db 'Err read from HDD!', 0x0A, 0x0D, 0
	
; Error Checking Data
readSegment			dw 0
readOffset			dw 0
	
TIMES 510 - ($ - $$) db 0 
dw 0xAA55

; Here we create a label to jump to
; when Stage02 loads.
stage02_load: