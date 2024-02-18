.segment "HEADER"
.byte "NES"
.byte $1a
.byte $02 ; 2 * 16KB PRG ROM
.byte $01 ; 1 * 8KB CHR ROM
.byte %00000001 ; mapper and mirroring
.byte $00
.byte $00
.byte $00
.byte $00
.byte $00, $00, $00, $00, $00 ; filler bytes
.segment "ZEROPAGE" ; LSB 0 - FF
temp: .res 1
temp2: .res 1
temp3: .res 1
temp4: .res 1
temp5: .res 1
temp6: .res 1
temp7: .res 1
temp8: .res 1
; Byte declaration: _x = 20
_x: .res 1
; Byte declaration: _y = 20
_y: .res 1
; Sprite declaration: sp0
sp0: .res 1
; Sprite declaration: sp1
sp1: .res 1
; Sprite declaration: sp2
sp2: .res 1
; Sprite declaration: sp3
sp3: .res 1
; Sprite declaration: sp4
sp4: .res 1
; Sprite declaration: sp5
sp5: .res 1
; Sprite declaration: sp6
sp6: .res 1
; Sprite declaration: sp7
sp7: .res 1

.segment "STARTUP"
Reset:
    SEI ; Disables all interrupts
    CLD ; disable decimal mode

    ; Disable sound IRQ
    LDX #$40
    STX $4017

    ; Initialize the stack register
    LDX #$FF
    TXS

    INX ; #$FF + 1 => #$00

    ; Zero out the PPU registers
    STX $2000
    STX $2001

    STX $4010

:
    BIT $2002
    BPL :-

    TXA

CLEARMEM:
    STA $0000, X ; $0000 => $00FF
    STA $0100, X ; $0100 => $01FF
    STA $0300, X
    STA $0400, X
    STA $0500, X
    STA $0600, X
    STA $0700, X
    LDA #$FF
    STA $0200, X ; $0200 => $02FF
    LDA #$00
    INX
    BNE CLEARMEM
; wait for vblank
:
    BIT $2002
    BPL :-

    LDA #$02
    STA $4014
    NOP

    ; $3F00
    LDA #$3F
    STA $2006
    LDA #$00
    STA $2006

    LDX #$00

LoadPalettes:
    LDA PaletteData, X
    STA $2007 ; $3F00, $3F01, $3F02 => $3F1F
    INX
    CPX #$20
    BNE LoadPalettes    

    JMP SkipLoadSprite

    LDX #$00
LoadSprites:
    LDA SpriteData, X
    STA $0200, X
    INX
    CPX #$20
    BNE LoadSprites    
SkipLoadSprite:

; Clear the nametables- this isn't necessary in most emulators unless
; you turn on random memory power-on mode, but on real hardware
; not doing this means that the background / nametable will have
; random garbage on screen. This clears out nametables starting at
; $2000 and continuing on to $2400 (which is fine because we have
; vertical mirroring on. If we used horizontal, we'd have to do
; this for $2000 and $2800)
    LDX #$00
    LDY #$00
    LDA $2002
    LDA #$20
    STA $2006
    LDA #$00
    STA $2006
ClearNametable:
    STA $2007
    INX
    BNE ClearNametable
    INY
    CPY #$08
    BNE ClearNametable
    
; Enable interrupts
    CLI

    LDA #%10010000 ; enable NMI change background to use second chr set of tiles ($1000)
    STA $2000
    ; Enabling sprites and background for left-most 8 pixels
    ; Enable sprites and background
    LDA #%00011110
    STA $2001

    ; init stack of available sprites
    ldx #64
    ldy #0
InitSpritesStack:
    dex
    tya
    sta $0300, X
    iny
    iny
    iny
    iny
    txa
    bne InitSpritesStack
    lda #63 ;#$3f
    ldx #64 ;#$40
    sta $0300, X




Start:
; initialization of _x with 20
LDA #20
STA _x
; initialization of _y with 20
LDA #20
STA _y
    LDA _x
    PHA
    LDA _y
    PHA
    LDA #0
    PHA
    JSR CreateSprite
    PLA
    STA sp0
    LDA _x
    PHA
    LDA #8
    PHA
    JSR add
    PLA
    PHA
    LDA _y
    PHA
    LDA #1
    PHA
    JSR CreateSprite
    PLA
    STA sp1
    LDA _x
    PHA
    LDA _y
    PHA
    LDA #8
    PHA
    JSR add
    PLA
    PHA
    LDA #2
    PHA
    JSR CreateSprite
    PLA
    STA sp2
    LDA _x
    PHA
    LDA #8
    PHA
    JSR add
    PLA
    PHA
    LDA _y
    PHA
    LDA #8
    PHA
    JSR add
    PLA
    PHA
    LDA #3
    PHA
    JSR CreateSprite
    PLA
    STA sp3
    LDA _x
    PHA
    LDA _y
    PHA
    LDA #8
    PHA
    JSR add
    PLA
    PHA
    LDA #8
    PHA
    JSR add
    PLA
    PHA
    LDA #4
    PHA
    JSR CreateSprite
    PLA
    STA sp4
    LDA _x
    PHA
    LDA #8
    PHA
    JSR add
    PLA
    PHA
    LDA _y
    PHA
    LDA #8
    PHA
    JSR add
    PLA
    PHA
    LDA #8
    PHA
    JSR add
    PLA
    PHA
    LDA #5
    PHA
    JSR CreateSprite
    PLA
    STA sp5
    LDA _x
    PHA
    LDA _y
    PHA
    LDA #8
    PHA
    JSR add
    PLA
    PHA
    LDA #8
    PHA
    JSR add
    PLA
    PHA
    LDA #8
    PHA
    JSR add
    PLA
    PHA
    LDA #6
    PHA
    JSR CreateSprite
    PLA
    STA sp6
    LDA _x
    PHA
    LDA #8
    PHA
    JSR add
    PLA
    PHA
    LDA _y
    PHA
    LDA #8
    PHA
    JSR add
    PLA
    PHA
    LDA #8
    PHA
    JSR add
    PLA
    PHA
    LDA #8
    PHA
    JSR add
    PLA
    PHA
    LDA #7
    PHA
    JSR CreateSprite
    PLA
    STA sp7


Loop:
    JMP Loop

NMI:

    LDY #3
    LDX sp0
    STX temp
    LDX #$02
    STX temp2
    LDA (temp), Y
    PHA
    LDA #1
    PHA
    JSR add
    PLA
    LDY #3
    LDX sp0
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
    LDY #3
    LDX sp1
    STX temp
    LDX #$02
    STX temp2
    LDA (temp), Y
    PHA
    LDA #2
    PHA
    JSR add
    PLA
    LDY #3
    LDX sp1
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
    LDY #3
    LDX sp2
    STX temp
    LDX #$02
    STX temp2
    LDA (temp), Y
    PHA
    LDA #3
    PHA
    JSR add
    PLA
    LDY #3
    LDX sp2
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
    LDY #3
    LDX sp3
    STX temp
    LDX #$02
    STX temp2
    LDA (temp), Y
    PHA
    LDA #4
    PHA
    JSR add
    PLA
    LDY #3
    LDX sp3
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
    LDY #3
    LDX sp4
    STX temp
    LDX #$02
    STX temp2
    LDA (temp), Y
    PHA
    LDA #5
    PHA
    JSR add
    PLA
    LDY #3
    LDX sp4
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
    LDY #3
    LDX sp5
    STX temp
    LDX #$02
    STX temp2
    LDA (temp), Y
    PHA
    LDA #6
    PHA
    JSR add
    PLA
    LDY #3
    LDX sp5
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
    LDA #0
    CMP #$00
    BEQ ENDIF0
    LDY #3
    LDX sp6
    STX temp
    LDX #$02
    STX temp2
    LDA (temp), Y
    PHA
    LDA #7
    PHA
    JSR add
    PLA
    LDY #3
    LDX sp6
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
ENDIF0:
    LDA #1
    CMP #$00
    BEQ ENDIF1
    LDY #3
    LDX sp7
    STX temp
    LDX #$02
    STX temp2
    LDA (temp), Y
    PHA
    LDA #8
    PHA
    JSR add
    PLA
    LDY #3
    LDX sp7
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
ENDIF1:

    LDA #$02 ; copy sprite data from $0200 => PPU memory for display
    STA $4014

    RTI

add:
    pla
    tax
    pla
    tay
    pla
    sta temp
    pla
    clc
    adc temp
    pha
    tya
    pha
    txa
    pha
    rts

CreateSprite:
    ; TODO pop next available sprite from the stack
    ; read the stack pointer value at #$0340 (#64)
    ; read the value itself which should be the index of a sprite
    ; dec stack pointer
    ; TODO if it is zero then return -1 or may be somehow show an error (but for now do nothing)
    ; push sprite index the the ordinary stack to return as a value
    ; ... profit!

    ;save return address to temp and temp2
    pla
    sta temp
    pla
    sta temp2
    ;save arguments to temp3,temp4,temp5
    pla
    sta temp3
    pla
    sta temp4
    pla
    sta temp5
    ;dec sprite stack pointer and return sprite index
    ldx #$40 ; (64)
    lda $0300, X
    dec $0300, X
    tax
    lda $0300, X
    pha

    ;now we need to initialize the sprite values
    
    sta temp6 ;we should have in A - the address of a sprite
    ldx #$02
    stx temp7
    ; now we can address the sprite with offset Y
    ldy #0 ; y value of a sprite
    lda temp4 ; load second argument (y)
    sta (temp6), Y ; set it
    
    ldy #1 ;  tile value of a sprite
    lda temp3 ; load third argument (tile)
    sta (temp6), Y

    ldy #2 ; properties of a sprite default is $00
    lda #$00
    sta (temp6), Y

    ldy #3 ; x value of a sprite
    lda temp5 ; load first argument (x)
    sta (temp6), Y

    lda temp2
    pha
    lda temp
    pha
    rts

DeleteSprite:
    ; TODO push sprite to the stack and make it invisible?
    rts

PaletteData:
    .byte $22,$29,$1A,$0F,$22,$36,$17,$0f,$22,$30,$21,$0f,$22,$27,$17,$0F  ;background palette data
    .byte $22,$16,$27,$18,$22,$1A,$30,$27,$22,$16,$30,$27,$22,$0F,$36,$17  ;sprite palette data

SpriteData:
    .byte $08, $00, $00, $08
    .byte $08, $01, $00, $10
    .byte $10, $02, $00, $08
    .byte $10, $03, $00, $10
    .byte $18, $04, $00, $08
    .byte $18, $05, $00, $10
    .byte $20, $06, $00, $08
    .byte $20, $07, $00, $10

.segment "VECTORS"
    .word NMI
    .word Reset
    ; 
.segment "CHARS"
    .incbin "defaultchar.chr"