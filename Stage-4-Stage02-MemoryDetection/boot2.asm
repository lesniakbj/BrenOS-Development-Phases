[ORG 0x7E00]

mov ax, 0xBE01
cli
hlt

;===================;
;	BOOT-2 DATA
;===================;
BOOT2_2FILE_MSG:	db "Has this been read from disk yet?!?", 0

; NOTE:
; ======================
; Some emulators and disk drives will
; not read a sector unless it is fully 
; padded out, thus we need to pad this
; sector or it will not be read. This is
; true of all sectors we read in some 
; emulators. Thus, the last sector of every
; code segment must be padded.
TIMES 512 db 0x00