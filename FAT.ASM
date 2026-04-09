;      Ez egy olyan progi lesz ami kiirja a FAT16 -on az
;      allokacios lancokat.
;                          keszitette : Visegradi Istvan
;
;      Feladat: 17
stak    segment         para    stack   'stack'
	db 100h dup (?)
stak    ends

dat     segment         para    public  'data'
uzen1   db      'Ezen a drive-on nem FAT16 van!',13,10,'$'
hiba    db      'Hiba! Nem tudtam olvasni a drive-r¢l!',13,10,'$'
konyv	db	'Ez egy alkonyvt r!',13,10,'$'
ente	db	13,10,13,10,'$'
	db 1000h dup (?)
dat     ends


cod     segment         para    public  'code'
	assume  cs:cod, ds:dat, es:nothing, ss:stak

;----------------------Eljarasok------------------------------------
irfile  proc    near
	mov dx,0520h            ; string kezdete
	mov ah,09h
	int 21h
	ret
irfile  endp

korrig  proc    near
	add al,30h              ; szamok korrekcioja
	cmp al,3ah              ; szam vagy karakter(a..f)?
	jnae ittjo
	add al,07h              ; karakter tovebbi korrekcio
ittjo:  mov si,0530h
	add si,cx
	mov [ds:si],al          ; kiirja a helyere a korrigaltat
	ret
korrig  endp

irlanc  proc    near
	xor cx,cx
	mov bx,[ds:0506h]       ; aktualis lanc beolvasasa
	mov al,bh               ; felso byte attoltese
	and al,11110000b        ; felso 4 bit megtartasa
	shr al,4                ; felso 4 bit -> also 4 bitre tolasa
	call korrig
	inc cx                  ; kovetkezo helyre kell majd irni
	mov al,bh               ; felso byte attoltese
	and al,0fh              ; also 4 bit megtartasa
	call korrig
	inc cx                  ; kovetkezo helyre kell majd irni
	mov al,bl               ; also byte attoltese
	and al,11110000b        ; felso 4 bit megtartasa
	shr al,4                ; felso 4 bit -> also 4 bitre tolasa
	call korrig
	inc cx                  ; kovetkezo helyre kell majd irni
	mov al,bl               ; also byte atoltese
	and al,0fh              ; also 4 bit megtartasa
	call korrig
	mov dx,0530h            ; itt kezdodik a string
	mov ah,09h              ; string kiirato DOS rutin
	int 21h
	ret
irlanc  endp


;-----------------------Eljarasok---Vege----------------------------

; BOOT sector beolvasasa 500h-ra
start:  mov ax,seg dat          ; az adatszegmens beallitasa
	mov ds,ax
	mov ah,19h
	int 21h                 ; al-be aktualis drive
	mov dx,0                ; 0. sectort
	mov cx,1                ; 1 db sectort
	mov bx,0500h            ; ds:0500-ra
	int 25h
	pop dx                  ; rajtahagyott word levetele
	jnc masfat

	mov ah,19h
	int 21h                 ; al-be aktualis drive

	xor dx,dx
	mov bx,0550h            ; szektor beolvaso tarolo kezdete
	mov [ds:0550h],dx       ; 0.szektor a FAT16-ban
	mov [ds:0552h],dx       ; 0.szektor a FAT16-ban
	mov cx,01h
	mov [ds:0554h],cx	; 1. db szektort olvasson
	mov [ds:0556h],0500h    ; cel offszetje
	mov [ds:0558h],ds       ; cel szegmense
	mov cx,1111111111111111b
	int 25h
	pop dx
	jnc masfat
	mov dx,offset hiba      ; uzenet offset-je
	mov ah,09h              ; uzenet kiiratasa
	int 21h
	jmp seged2              ; ugras a vegere segeden keresztul

; FAT16 az aktualis drive?
masfat: mov [ds:0511h],al       ; aktualis drive kiirasa taroloba
	mov ah,[ds:053ah]       ; milyen FAT?
	sub ah,36h              ; FAT1'6'->36h
	jz root
	mov dx,offset uzen1     ; uzenet offsetje
	mov ah,09h              ; uzenet kiiratasa
	int 21h
	jmp seged2              ; ugras a vegere segeden keresztul

;Root elejenek kiszamitasa
root:   mov ax,[ds:0516h]       ; FAT merete
	xor bx,bx
	mov bl,[ds:0510h]       ; FAT-ek szama
	mul bx
	add ax,[ds:050eh]       ; Foglalt sectorok a FAT elott
	mov [ds:0500h],ax

;Adatok inicializalasa
	xor ax,ax
	mov [ds:0502h],ax       ; 0. Root sector lesz betoltve
	mov [ds:0504h],ax       ; 0. FAT sector lesz betoltve
	mov [ds:0508h],al       ; 0. File lesz beolvasva

;Hany lanc van egy sectorban?
	mov ax,[ds:050bh]       ; Byte/sector
	shr ax,1                ; /2
	mov [ds:0509h],ax

;Hanyadik bit 1-es a lanc/sectorban?
	xor cx,cx
	mov dx,1
eltol:  test dx,ax              ; Ez az a bit?
	jnz megvan
	inc cx
	shl dx,1                ; Eltol 1-vel balra
	jmp eltol
megvan: mov [ds:050dh],cl       ; Hanyadik bit 1-es kiir

;Hany file bejegyzes van egy sectorban
	mov ax,[ds:050bh]       ; Byte/sector
	mov bl,20h              ; Ekkora egy file bejegyzes
	div bl
	mov [ds:0515h],al       ; Kiir helyere a file/sectort

; Betolt 0.Root sector
	mov ah,19h
	int 21h                 ; al-be aktualis drive
	mov [ds:0511h],al
	mov bx,0550h            ; szektor beolvaso tarolo kezdete
	mov dx,[ds:0500h]       ;
	mov [ds:0550h],dx       ; root szektor a FAT16-ban
	xor dx,dx
	mov [ds:0552h],dx
	mov cx,01h
	mov [ds:0554h],cx	; 1. db szektort olvasson
	mov [ds:0556h],0600h    ; cel offszetje
	mov [ds:0558h],ds       ; cel szegmense
	mov cx,1111111111111111b
	int 25h
	pop dx

; Betolt 0.FAT sectort a FAT0-rol
	mov al,[ds:0511h]       ; aktualis drive
	mov bx,0550h            ; szektor beolvaso tarolo kezdete
	mov dx,[ds:050eh]       ;
	mov [ds:0550h],dx	; fat0 1. szektor
	mov cx,01h
	mov [ds:0554h],cx	; 1. db szektort olvasson
	mov cx,0600h            ; Root betoltott sektoranak kezdete
	add cx,[ds:050bh]       ; Ekkora 1 sector
	mov [ds:0556h],cx       ; cel offszetje
	mov cx,1111111111111111b
	int 25h
	pop dx

; Kiiratando szoveg helyenek inicializalasa
	mov dx,2eh
	mov [ds:0528h],dx	; '.' A filenev es a kiterjesztes elvalasztoja
	mov dx,0dh
	mov [ds:052ch],dx
	mov dx,20h
	mov [ds:0534h],dx
	mov dx,0ah
	mov [ds:052dh],dx
	mov dx,24h
	mov [ds:052eh],dx	; '$' A string vege jel a filenev kiirashoz
	mov [ds:0535h],dx	; '$' A string vege jel a lanc kiirashoz

; Kovetkezo filenev atrakasa a kiiro helyre
filrak:	mov cx,08h              ; 8 karakter masolasa
	mov si,0600h            ; 600-as a sektor kezdete
	mov al,[ds:0508h]       ; melyik az aktualis file
	mov bl,20h              ; ekkora egy file bejegyzes
	mul bl
	add si,ax               ; Itt kezdodik a filenev
	mov di,0520h            ; Ide masolja
	mov bx,000bh		; file attributum
	add bx,si
	mov al,[ds:bx]          ; aktualis file attributuma
	mov [ds:0513h],al	; mentese az attributumoknak
	and al,08h		; volume cimke
	jnz  seged6

hoho:   mov bx,si
	add bx,cx
	dec bx
	mov al,[ds:bx]
	mov bx,di
	add bx,cx
	dec bx
	mov [ds:bx],al
	dec cx
	jnz hoho
	mov cx,03h              ; 3 karakter masolasa
	mov si,0608h            ; itt kezdodik a file kiterjesztes
	mov al,[ds:0508h]       ; melyik az aktualis file
	mov bl,20h              ; ekkora egy file bejegyzes
	mul bl
	add si,ax               ; Itt kezdodik az aktualis file kiterjesztese
	mov di,0529h            ; Ide masolja
haha:   mov bx,si
	add bx,cx
	dec bx
	mov al,[ds:bx]
	mov bx,di
	add bx,cx
	dec bx
	mov [ds:bx],al
	dec cx
	jnz haha

; Filenev vizsgalata
	mov al,[ds:0520h]       ; File 1.kar
	cmp al,11100101b        ; Torolt file (e5)
	jz seged6
	cmp al,00h              ; Nincs tobb file
	jz seged2
	mov bx,0ffh
las:	mov cx,1111111111111111b
lassit:	dec cx
	jnz lassit
	dec bx
	jnz las
	mov dx,offset ente
	mov ah,09h
	int 21h
	call irfile             ; Kiir filenev

	mov al,[ds:0513h]
	and al,10h		; alkonyvtar
	jz lan
	mov dx,offset konyv
	mov ah,09h
	int 21h


; Aktualis lanc elrakasa
lan:	mov al,[ds:0508h]       ; Aktualis file
	mov bl,20h
	mul bl                  ; pozicionalas
	add ax,061ah            ; lanc bejegyzes helye
	mov bx,ax
	mov ax,[ds:bx]          ; lanc bejegyzes beolvas
	mov [ds:0506h],ax       ; lanc bejegyzes elrak
	jmp mejsec
seged6: jmp seged5

; Aktualis lanc melyik sectorban(FAT) van bejegyezve?
mejsec: mov ax,[ds:0506h]       ; aktualis lanc betoltese
	mov ch,00h
	mov cl,[ds:050dh]       ; mennyit kell shiftelni
	inc cx                  ; a dec cx flag allitasa miatt
shift:  dec cx                  ; csokkenti a shiftek szamat
	jz keszen               ; nincs tobb?
	shr ax,1                ; shift 1-et jobbra
	jmp shift
seged5: jmp kovfile
seged:  jmp filrak              ; seged a tul nagy ugras miatt
seged2: jmp vege                ; seged a tul nagy ugras miatt
; Bent van-e ez a szektor?
keszen: cmp ax,[ds:0504h]       ; ez az aktualis sector(FAT)?
	jz bentva
	mov [ds:0504h],ax       ; ez lesz az aktualis sector(FAT)
	mov dx,[ds:050eh]       ; foglalt sectorok a FAT elott
	add dx,ax               ; ezt a sectort kell betolteni
	mov al,[ds:0511h]       ; aktualis drive
	mov bx,0550h            ; szektor beolvaso tarolo kezdete
	mov [ds:0550h],dx       ; fat0 ezen szektorat kell betolteni
	mov cx,01h
	mov [ds:0554h],cx	; 1. db szektort olvasson
	mov cx,0600h            ; Root betoltott szektoranak kezdete
	add cx,[ds:050bh]       ; Ekkora 1 sector
	mov [ds:0556h],cx       ; cel offszetje
	mov cx,1111111111111111b
	int 25h
	pop dx
bentva: call irlanc

; Aktualis lanc betoltese a sectorbol(FAT)
	mov bx,[ds:0506h]       ; aktualis lanc
	mov ax,[ds:0504h]       ; aktualis sector(FAT)
	mov cx,[ds:0509h]       ; lanc/sector
	mul cx                  ; (akt. sec.)*(lanc/sec.)
	sub bx,ax               ; akt. lanc - (akt. sec.)*(lanc/sec.)
	shl bx,1                ; *2 (2 byte 1 lanc bejegyzes)
	mov dx,0600h            ; root kezdete
	add dx,[ds:050bh]       ; (byte/sec) aktualis sector(FAT) kezdete
	add bx,dx               ; sector(FAT)-ban a lanc pozicioja
	mov ax,[ds:bx]          ; kovetkezo lanc
	mov [ds:0506h],ax       ; kiir aktualis lancnak
	sub ax,1111111111110000b
	jc mejsec

; Kovetkezo file beolvasasa
kovfile: mov bl,[ds:0508h]      ; aktualis file
	inc bl
	mov [ds:0508h],bl
	cmp bl,[ds:0515h]       ; hany file bejegyzes egy sectorba
	jnz seged               ; nem az utolso volt
	mov ax,[ds:0502h]       ; hanyadik root sector van bent
	inc ax
	mov [ds:0502h],ax       ; kiir aktualis root sectornak
	mov cl,0h
	mov [ds:0508h],cl       ; 0. lesz az aktualis file
	mov bx,0550h            ; szektor beolvaso tarolo kezdete
	mov dx,[ds:0500h]       ; root eleje
	add dx,ax
	mov [ds:0550h],dx       ; root szektor a FAT16-ban
	mov al,[ds:0511h]       ; C drive
	mov cx,01h
	mov [ds:0554h],cx	 ; 1 db szektort olvasson
	mov [ds:0556h],0600h    ; cel offszetje
	mov cx,1111111111111111b
	int 25h
	pop dx
	jmp seged

vege:   mov ah,01001100b        ; kilepes 4ch
	int 21h

cod     ends
	end     start
