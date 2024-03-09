BTN_RIGHT   = %00000001
BTN_LEFT    = %00000010
BTN_DOWN    = %00000100
BTN_UP      = %00001000
BTN_START   = %00010000
BTN_SELECT  = %00100000
BTN_B       = %01000000
BTN_A       = %10000000
CONTROLLER1 = $4016
CONTROLLER2 = $4017
PPUDATA = $2007

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
pad1: .res 1
pad2: .res 1
; Byte declaration: _x = 20
_x: .res 1
; Byte declaration: _y = 20
_y: .res 1
; Byte declaration: ex = 50
ex: .res 1
; Byte declaration: ey = 20
ey: .res 1
; Byte declaration: speed = 1
speed: .res 1
; Byte declaration: vSpeed = 128
vSpeed: .res 1
; Byte declaration: eVSpeed = 128
eVSpeed: .res 1
; Byte declaration: g = 1
g: .res 1
; Byte declaration: jumpSpeed = 125
jumpSpeed: .res 1
; Byte declaration: grounded = 0
grounded: .res 1
; Byte declaration: eGrounded = 0
eGrounded: .res 1
; Byte declaration: flipped = 0
flipped: .res 1
; Byte declaration: eFlipped = 0
eFlipped: .res 1
; Byte declaration: playerHeight = 24
playerHeight: .res 1
; Byte declaration: playerWidth = 16
playerWidth: .res 1
; Byte declaration: boxHeight = 4
boxHeight: .res 1
; Byte declaration: boxWidth = 64
boxWidth: .res 1
; Byte declaration: groundLevel = 198
groundLevel: .res 1
; Sprite declaration: hero1
hero1: .res 1
; Sprite declaration: hero2
hero2: .res 1
; Sprite declaration: hero3
hero3: .res 1
; Sprite declaration: hero4
hero4: .res 1
; Sprite declaration: hero5
hero5: .res 1
; Sprite declaration: hero6
hero6: .res 1
; Sprite declaration: enemy1
enemy1: .res 1
; Sprite declaration: enemy2
enemy2: .res 1
; Sprite declaration: enemy3
enemy3: .res 1
; Sprite declaration: enemy4
enemy4: .res 1
; Sprite declaration: enemy5
enemy5: .res 1
; Sprite declaration: enemy6
enemy6: .res 1
; Sprite declaration: box1
box1: .res 1
; Sprite declaration: box2
box2: .res 1
; Sprite declaration: box3
box3: .res 1
; Sprite declaration: box4
box4: .res 1
; Byte declaration: counter = 0
counter: .res 1
; Byte declaration: animCounter = 0
animCounter: .res 1
; Byte declaration: animFrame = 0
animFrame: .res 1
; Byte declaration: eyesState = 0
eyesState: .res 1
; Byte declaration: eCounter = 0
eCounter: .res 1
; Byte declaration: eAnimCounter = 0
eAnimCounter: .res 1
; Byte declaration: eAnimFrame = 0
eAnimFrame: .res 1
; Byte declaration: eEyesState = 0
eEyesState: .res 1
; Byte declaration: moving = 0
moving: .res 1
; Byte declaration: eMoving = 0
eMoving: .res 1
; Byte declaration: eDirectionCounter = 0
eDirectionCounter: .res 1
; Byte declaration: eJumpCounter = 0
eJumpCounter: .res 1
; Byte declaration: eRandomSeed = 1
eRandomSeed: .res 1
; Byte declaration: eDirectionInterval = 0
eDirectionInterval: .res 1
; Byte declaration: i = 0
i: .res 1

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

; test load namatable
    lda #$20       ; High byte of $2000
    sta $2006
    lda #$00       ; Low byte of $2000
    sta $2006


    ldx #<nametablescreentest_rleca65
    ldy #>nametablescreentest_rleca65
    jsr decodeRLE

    
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
; initialization of ex with 50
LDA #50
STA ex
; initialization of ey with 20
LDA #20
STA ey
; initialization of speed with 1
LDA #1
STA speed
; initialization of vSpeed with 128
LDA #128
STA vSpeed
; initialization of eVSpeed with 128
LDA #128
STA eVSpeed
; initialization of g with 1
LDA #1
STA g
; initialization of jumpSpeed with 125
LDA #125
STA jumpSpeed
; initialization of grounded with 0
LDA #0
STA grounded
; initialization of eGrounded with 0
LDA #0
STA eGrounded
; initialization of flipped with 0
LDA #0
STA flipped
; initialization of eFlipped with 0
LDA #0
STA eFlipped
; initialization of playerHeight with 24
LDA #24
STA playerHeight
; initialization of playerWidth with 16
LDA #16
STA playerWidth
; initialization of boxHeight with 4
LDA #4
STA boxHeight
; initialization of boxWidth with 64
LDA #64
STA boxWidth
; initialization of groundLevel with 198
LDA #198
STA groundLevel
; initialization of counter with 0
LDA #0
STA counter
; initialization of animCounter with 0
LDA #0
STA animCounter
; initialization of animFrame with 0
LDA #0
STA animFrame
; initialization of eyesState with 0
LDA #0
STA eyesState
; initialization of eCounter with 0
LDA #0
STA eCounter
; initialization of eAnimCounter with 0
LDA #0
STA eAnimCounter
; initialization of eAnimFrame with 0
LDA #0
STA eAnimFrame
; initialization of eEyesState with 0
LDA #0
STA eEyesState
; initialization of moving with 0
LDA #0
STA moving
; initialization of eMoving with 0
LDA #0
STA eMoving
; initialization of eDirectionCounter with 0
LDA #0
STA eDirectionCounter
; initialization of eJumpCounter with 0
LDA #0
STA eJumpCounter
; initialization of eRandomSeed with 1
LDA #1
STA eRandomSeed
; initialization of eDirectionInterval with 0
LDA #0
STA eDirectionInterval
; initialization of i with 0
LDA #0
STA i
    LDA _x
    PHA
    LDA _y
    PHA
    LDA #88
    PHA
    LDA #0
    PHA
    JSR CreateSprite
    PLA
    STA hero1
    LDA _x
    PHA
    LDA #8
    PHA
    JSR add
    PLA
    PHA
    LDA _y
    PHA
    LDA #89
    PHA
    LDA #0
    PHA
    JSR CreateSprite
    PLA
    STA hero2
    LDA _x
    PHA
    LDA _y
    PHA
    LDA #8
    PHA
    JSR add
    PLA
    PHA
    LDA #104
    PHA
    LDA #0
    PHA
    JSR CreateSprite
    PLA
    STA hero3
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
    LDA #105
    PHA
    LDA #0
    PHA
    JSR CreateSprite
    PLA
    STA hero4
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
    LDA #120
    PHA
    LDA #1
    PHA
    JSR CreateSprite
    PLA
    STA hero5
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
    LDA #121
    PHA
    LDA #1
    PHA
    JSR CreateSprite
    PLA
    STA hero6
    LDA ex
    PHA
    LDA ey
    PHA
    LDA #88
    PHA
    LDA #2
    PHA
    JSR CreateSprite
    PLA
    STA enemy1
    LDA ex
    PHA
    LDA #8
    PHA
    JSR add
    PLA
    PHA
    LDA ey
    PHA
    LDA #89
    PHA
    LDA #2
    PHA
    JSR CreateSprite
    PLA
    STA enemy2
    LDA ex
    PHA
    LDA ey
    PHA
    LDA #8
    PHA
    JSR add
    PLA
    PHA
    LDA #104
    PHA
    LDA #2
    PHA
    JSR CreateSprite
    PLA
    STA enemy3
    LDA ex
    PHA
    LDA #8
    PHA
    JSR add
    PLA
    PHA
    LDA ey
    PHA
    LDA #8
    PHA
    JSR add
    PLA
    PHA
    LDA #105
    PHA
    LDA #2
    PHA
    JSR CreateSprite
    PLA
    STA enemy4
    LDA ex
    PHA
    LDA ey
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
    LDA #120
    PHA
    LDA #3
    PHA
    JSR CreateSprite
    PLA
    STA enemy5
    LDA ex
    PHA
    LDA #8
    PHA
    JSR add
    PLA
    PHA
    LDA ey
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
    LDA #121
    PHA
    LDA #3
    PHA
    JSR CreateSprite
    PLA
    STA enemy6
    LDA #100
    PHA
    LDA #172
    PHA
    LDA #20
    PHA
    JSR add
    PLA
    PHA
    LDA #52
    PHA
    LDA #4
    PHA
    JSR CreateSprite
    PLA
    STA box1
    LDA #108
    PHA
    LDA #172
    PHA
    LDA #20
    PHA
    JSR add
    PLA
    PHA
    LDA #53
    PHA
    LDA #4
    PHA
    JSR CreateSprite
    PLA
    STA box2
    LDA #100
    PHA
    LDA #180
    PHA
    LDA #20
    PHA
    JSR add
    PLA
    PHA
    LDA #52
    PHA
    LDA #4
    PHA
    JSR CreateSprite
    PLA
    STA box3
    LDA #108
    PHA
    LDA #180
    PHA
    LDA #20
    PHA
    JSR add
    PLA
    PHA
    LDA #53
    PHA
    LDA #4
    PHA
    JSR CreateSprite
    PLA
    STA box4


Loop:
    JMP Loop

NMI:
    LDA #$02 ; copy sprite data from $0200 => PPU memory for display
    STA $4014
    JSR ReadControllers




    LDA counter
    PHA
    LDA #1
    PHA
    JSR add
    PLA
    STA counter
    LDA eCounter
    PHA
    LDA #1
    PHA
    JSR add
    PLA
    STA eCounter
    LDA counter
    PHA
    LDA #7
    PHA
    JSR equal
    PLA
    CMP #$00
    BNE SKIP_TO_ELSE0
    JMP ENDIF0
SKIP_TO_ELSE0:
    LDA #0
    STA counter
    LDA vSpeed
    PHA
    LDA g
    PHA
    JSR add
    PLA
    STA vSpeed
    JMP ENDIF0
ENDIF0:
    LDA eCounter
    PHA
    LDA #7
    PHA
    JSR equal
    PLA
    CMP #$00
    BNE SKIP_TO_ELSE1
    JMP ENDIF1
SKIP_TO_ELSE1:
    LDA #0
    STA eCounter
    LDA eVSpeed
    PHA
    LDA g
    PHA
    JSR add
    PLA
    STA eVSpeed
    JMP ENDIF1
ENDIF1:
    LDA vSpeed
    PHA
    LDA #254
    PHA
    JSR greaterThan
    PLA
    CMP #$00
    BNE SKIP_TO_ELSE2
    JMP ENDIF2
SKIP_TO_ELSE2:
    LDA #254
    STA vSpeed
    JMP ENDIF2
ENDIF2:
    LDA eVSpeed
    PHA
    LDA #254
    PHA
    JSR greaterThan
    PLA
    CMP #$00
    BNE SKIP_TO_ELSE3
    JMP ENDIF3
SKIP_TO_ELSE3:
    LDA #254
    STA eVSpeed
    JMP ENDIF3
ENDIF3:
    LDA vSpeed
    PHA
    LDA #128
    PHA
    JSR greaterThan
    PLA
    CMP #$00
    BNE SKIP_TO_ELSE4
    JMP ENDIF4
SKIP_TO_ELSE4:
    LDA vSpeed
    PHA
    LDA #128
    PHA
    JSR subtract
    PLA
    PHA
    LDA _y
    PHA
    JSR add
    PLA
    STA _y
    JMP ENDIF4
ENDIF4:
    LDA vSpeed
    PHA
    LDA #128
    PHA
    JSR lowerThan
    PLA
    CMP #$00
    BNE SKIP_TO_ELSE5
    JMP ENDIF5
SKIP_TO_ELSE5:
    LDA vSpeed
    PHA
    LDA _y
    PHA
    JSR add
    PLA
    PHA
    LDA #128
    PHA
    JSR subtract
    PLA
    STA _y
    JMP ENDIF5
ENDIF5:
    LDA eVSpeed
    PHA
    LDA #128
    PHA
    JSR greaterThan
    PLA
    CMP #$00
    BNE SKIP_TO_ELSE6
    JMP ENDIF6
SKIP_TO_ELSE6:
    LDA eVSpeed
    PHA
    LDA #128
    PHA
    JSR subtract
    PLA
    PHA
    LDA ey
    PHA
    JSR add
    PLA
    STA ey
    JMP ENDIF6
ENDIF6:
    LDA eVSpeed
    PHA
    LDA #128
    PHA
    JSR lowerThan
    PLA
    CMP #$00
    BNE SKIP_TO_ELSE7
    JMP ENDIF7
SKIP_TO_ELSE7:
    LDA eVSpeed
    PHA
    LDA ey
    PHA
    JSR add
    PLA
    PHA
    LDA #128
    PHA
    JSR subtract
    PLA
    STA ey
    JMP ENDIF7
ENDIF7:
    LDA #0
    STA grounded
    LDA #0
    STA eGrounded
    LDA _y
    PHA
    LDA groundLevel
    PHA
    JSR greaterThan
    PLA
    CMP #$00
    BNE SKIP_TO_ELSE8
    JMP ENDIF8
SKIP_TO_ELSE8:
    LDA groundLevel
    STA _y
    LDA #128
    STA vSpeed
    LDA #1
    STA grounded
    JMP ENDIF8
ENDIF8:
    LDA ey
    PHA
    LDA groundLevel
    PHA
    JSR greaterThan
    PLA
    CMP #$00
    BNE SKIP_TO_ELSE9
    JMP ENDIF9
SKIP_TO_ELSE9:
    LDA groundLevel
    STA ey
    LDA #128
    STA eVSpeed
    LDA #1
    STA eGrounded
    JMP ENDIF9
ENDIF9:
    LDY #0
    LDX box1
    STX temp
    LDX #$02
    STX temp2
    LDA (temp), Y
    PHA
    LDA boxHeight
    PHA
    JSR add
    PLA
    PHA
    LDA playerHeight
    PHA
    JSR subtract
    PLA
    PHA
    LDA _y
    PHA
    JSR greaterThan
    PLA
    CMP #$00
    BNE SKIP_TO_ELSE10
    JMP ENDIF10
SKIP_TO_ELSE10:
    LDA #10
    LDY #0
    LDX box2
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
    LDA #10
    LDY #3
    LDX box2
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
    LDA _y
    PHA
    LDA playerHeight
    PHA
    JSR add
    PLA
    PHA
    LDY #0
    LDX box1
    STX temp
    LDX #$02
    STX temp2
    LDA (temp), Y
    PHA
    JSR greaterThan
    PLA
    CMP #$00
    BNE SKIP_TO_ELSE11
    JMP ENDIF11
SKIP_TO_ELSE11:
    LDA #20
    LDY #0
    LDX box2
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
    LDA #20
    LDY #3
    LDX box2
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
    LDA _x
    PHA
    LDA playerWidth
    PHA
    JSR add
    PLA
    PHA
    LDY #3
    LDX box1
    STX temp
    LDX #$02
    STX temp2
    LDA (temp), Y
    PHA
    JSR greaterThan
    PLA
    CMP #$00
    BNE SKIP_TO_ELSE12
    JMP ENDIF12
SKIP_TO_ELSE12:
    LDA #30
    LDY #0
    LDX box2
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
    LDA #10
    LDY #3
    LDX box2
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
    LDY #3
    LDX box1
    STX temp
    LDX #$02
    STX temp2
    LDA (temp), Y
    PHA
    LDA boxWidth
    PHA
    JSR add
    PLA
    PHA
    LDA _x
    PHA
    JSR greaterThan
    PLA
    CMP #$00
    BNE SKIP_TO_ELSE13
    JMP ENDIF13
SKIP_TO_ELSE13:
    LDA #40
    LDY #0
    LDX box2
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
    LDA #20
    LDY #3
    LDX box2
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
    LDY #0
    LDX box1
    STX temp
    LDX #$02
    STX temp2
    LDA (temp), Y
    PHA
    LDA playerHeight
    PHA
    JSR subtract
    PLA
    STA _y
    LDA #128
    STA vSpeed
    LDA #1
    STA grounded
    JMP ENDIF13
ENDIF13:
    JMP ENDIF12
ENDIF12:
    JMP ENDIF11
ENDIF11:
    JMP ENDIF10
ENDIF10:
    LDY #0
    LDX box1
    STX temp
    LDX #$02
    STX temp2
    LDA (temp), Y
    PHA
    LDA boxHeight
    PHA
    JSR add
    PLA
    PHA
    LDA playerHeight
    PHA
    JSR subtract
    PLA
    PHA
    LDA ey
    PHA
    JSR greaterThan
    PLA
    CMP #$00
    BNE SKIP_TO_ELSE14
    JMP ENDIF14
SKIP_TO_ELSE14:
    LDA ey
    PHA
    LDA playerHeight
    PHA
    JSR add
    PLA
    PHA
    LDY #0
    LDX box1
    STX temp
    LDX #$02
    STX temp2
    LDA (temp), Y
    PHA
    JSR greaterThan
    PLA
    CMP #$00
    BNE SKIP_TO_ELSE15
    JMP ENDIF15
SKIP_TO_ELSE15:
    LDA ex
    PHA
    LDA playerWidth
    PHA
    JSR add
    PLA
    PHA
    LDY #3
    LDX box1
    STX temp
    LDX #$02
    STX temp2
    LDA (temp), Y
    PHA
    JSR greaterThan
    PLA
    CMP #$00
    BNE SKIP_TO_ELSE16
    JMP ENDIF16
SKIP_TO_ELSE16:
    LDY #3
    LDX box1
    STX temp
    LDX #$02
    STX temp2
    LDA (temp), Y
    PHA
    LDA boxWidth
    PHA
    JSR add
    PLA
    PHA
    LDA ex
    PHA
    JSR greaterThan
    PLA
    CMP #$00
    BNE SKIP_TO_ELSE17
    JMP ENDIF17
SKIP_TO_ELSE17:
    LDY #0
    LDX box1
    STX temp
    LDX #$02
    STX temp2
    LDA (temp), Y
    PHA
    LDA playerHeight
    PHA
    JSR subtract
    PLA
    STA ey
    LDA #128
    STA eVSpeed
    LDA #1
    STA eGrounded
    JMP ENDIF17
ENDIF17:
    JMP ENDIF16
ENDIF16:
    JMP ENDIF15
ENDIF15:
    JMP ENDIF14
ENDIF14:
    LDA #0
    STA moving
    LDA #1
    STA eMoving
    LDA pad1 ; Загрузка состояния кнопок для Player1
    AND #BTN_RIGHT ; Маскирование для проверки кнопки
    BEQ NotPressed18 ; Если кнопка не нажата, переходим к метке NotPressed18
    LDA #$01 ; Если кнопка нажата, загружаем 1
    JMP EndCheck18 ; Переходим к концу проверки
NotPressed18:
    LDA #$00 ; Загружаем 0, так как кнопка не нажата
EndCheck18:
    CMP #$00
    BNE SKIP_TO_ELSE19
    JMP ENDIF19
SKIP_TO_ELSE19:
    LDA #1
    STA flipped
    LDA #1
    STA moving
    LDA _x
    PHA
    LDA speed
    PHA
    JSR add
    PLA
    STA _x
    LDA grounded
    CMP #$00
    BNE SKIP_TO_ELSE20
    JMP ENDIF20
SKIP_TO_ELSE20:
    LDA eyesState
    CMP #$00
    BNE SKIP_TO_ELSE21
    JMP ELSE21
SKIP_TO_ELSE21:
    LDA #89
    LDY #1
    LDX hero1
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
    LDA #64
    LDY #2
    LDX hero1
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
    LDA #88
    LDY #1
    LDX hero2
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
    LDA #64
    LDY #2
    LDX hero2
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
    JMP ENDIF21
ELSE21:
    LDA #91
    LDY #1
    LDX hero1
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
    LDA #64
    LDY #2
    LDX hero1
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
    LDA #90
    LDY #1
    LDX hero2
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
    LDA #64
    LDY #2
    LDX hero2
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
ENDIF21:
    LDA animCounter
    PHA
    LDA #1
    PHA
    JSR add
    PLA
    STA animCounter
    LDA animCounter
    PHA
    LDA #10
    PHA
    JSR equal
    PLA
    CMP #$00
    BNE SKIP_TO_ELSE22
    JMP ENDIF22
SKIP_TO_ELSE22:
    LDA #0
    STA animCounter
    LDA animFrame
    PHA
    LDA #1
    PHA
    JSR add
    PLA
    STA animFrame
    LDA animFrame
    PHA
    LDA #4
    PHA
    JSR equal
    PLA
    CMP #$00
    BNE SKIP_TO_ELSE23
    JMP ENDIF23
SKIP_TO_ELSE23:
    LDA #0
    STA animFrame
    LDA #1
    PHA
    LDA eyesState
    PHA
    JSR subtract
    PLA
    STA eyesState
    JMP ENDIF23
ENDIF23:
    LDA animFrame
    PHA
    LDA #0
    PHA
    JSR equal
    PLA
    CMP #$00
    BNE SKIP_TO_ELSE24
    JMP ENDIF24
SKIP_TO_ELSE24:
    LDA #105
    LDY #1
    LDX hero3
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
    LDA #64
    LDY #2
    LDX hero3
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
    LDA #104
    LDY #1
    LDX hero4
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
    LDA #64
    LDY #2
    LDX hero4
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
    LDA #121
    LDY #1
    LDX hero5
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
    LDA #65
    LDY #2
    LDX hero5
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
    LDA #120
    LDY #1
    LDX hero6
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
    LDA #65
    LDY #2
    LDX hero6
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
    JMP ENDIF24
ENDIF24:
    LDA animFrame
    PHA
    LDA #1
    PHA
    JSR equal
    PLA
    CMP #$00
    BNE SKIP_TO_ELSE25
    JMP ENDIF25
SKIP_TO_ELSE25:
    LDA #107
    LDY #1
    LDX hero3
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
    LDA #64
    LDY #2
    LDX hero3
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
    LDA #106
    LDY #1
    LDX hero4
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
    LDA #64
    LDY #2
    LDX hero4
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
    LDA #123
    LDY #1
    LDX hero5
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
    LDA #65
    LDY #2
    LDX hero5
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
    LDA #122
    LDY #1
    LDX hero6
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
    LDA #65
    LDY #2
    LDX hero6
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
    JMP ENDIF25
ENDIF25:
    LDA animFrame
    PHA
    LDA #2
    PHA
    JSR equal
    PLA
    CMP #$00
    BNE SKIP_TO_ELSE26
    JMP ENDIF26
SKIP_TO_ELSE26:
    LDA #109
    LDY #1
    LDX hero3
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
    LDA #64
    LDY #2
    LDX hero3
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
    LDA #108
    LDY #1
    LDX hero4
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
    LDA #64
    LDY #2
    LDX hero4
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
    LDA #125
    LDY #1
    LDX hero5
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
    LDA #65
    LDY #2
    LDX hero5
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
    LDA #124
    LDY #1
    LDX hero6
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
    LDA #65
    LDY #2
    LDX hero6
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
    JMP ENDIF26
ENDIF26:
    LDA animFrame
    PHA
    LDA #3
    PHA
    JSR equal
    PLA
    CMP #$00
    BNE SKIP_TO_ELSE27
    JMP ENDIF27
SKIP_TO_ELSE27:
    LDA #107
    LDY #1
    LDX hero3
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
    LDA #64
    LDY #2
    LDX hero3
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
    LDA #106
    LDY #1
    LDX hero4
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
    LDA #64
    LDY #2
    LDX hero4
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
    LDA #123
    LDY #1
    LDX hero5
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
    LDA #65
    LDY #2
    LDX hero5
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
    LDA #122
    LDY #1
    LDX hero6
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
    LDA #65
    LDY #2
    LDX hero6
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
    JMP ENDIF27
ENDIF27:
    JMP ENDIF22
ENDIF22:
    JMP ENDIF20
ENDIF20:
    JMP ENDIF19
ENDIF19:
    LDA pad1 ; Загрузка состояния кнопок для Player1
    AND #BTN_LEFT ; Маскирование для проверки кнопки
    BEQ NotPressed28 ; Если кнопка не нажата, переходим к метке NotPressed28
    LDA #$01 ; Если кнопка нажата, загружаем 1
    JMP EndCheck28 ; Переходим к концу проверки
NotPressed28:
    LDA #$00 ; Загружаем 0, так как кнопка не нажата
EndCheck28:
    CMP #$00
    BNE SKIP_TO_ELSE29
    JMP ENDIF29
SKIP_TO_ELSE29:
    LDA #0
    STA flipped
    LDA #1
    STA moving
    LDA _x
    PHA
    LDA speed
    PHA
    JSR subtract
    PLA
    STA _x
    LDA grounded
    CMP #$00
    BNE SKIP_TO_ELSE30
    JMP ENDIF30
SKIP_TO_ELSE30:
    LDA eyesState
    CMP #$00
    BNE SKIP_TO_ELSE31
    JMP ELSE31
SKIP_TO_ELSE31:
    LDA #88
    LDY #1
    LDX hero1
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
    LDA #0
    LDY #2
    LDX hero1
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
    LDA #89
    LDY #1
    LDX hero2
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
    LDA #0
    LDY #2
    LDX hero2
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
    JMP ENDIF31
ELSE31:
    LDA #90
    LDY #1
    LDX hero1
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
    LDA #0
    LDY #2
    LDX hero1
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
    LDA #91
    LDY #1
    LDX hero2
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
    LDA #0
    LDY #2
    LDX hero2
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
ENDIF31:
    LDA animCounter
    PHA
    LDA #1
    PHA
    JSR add
    PLA
    STA animCounter
    LDA animCounter
    PHA
    LDA #10
    PHA
    JSR equal
    PLA
    CMP #$00
    BNE SKIP_TO_ELSE32
    JMP ENDIF32
SKIP_TO_ELSE32:
    LDA #0
    STA animCounter
    LDA animFrame
    PHA
    LDA #1
    PHA
    JSR add
    PLA
    STA animFrame
    LDA animFrame
    PHA
    LDA #4
    PHA
    JSR equal
    PLA
    CMP #$00
    BNE SKIP_TO_ELSE33
    JMP ENDIF33
SKIP_TO_ELSE33:
    LDA #0
    STA animFrame
    LDA #1
    PHA
    LDA eyesState
    PHA
    JSR subtract
    PLA
    STA eyesState
    JMP ENDIF33
ENDIF33:
    LDA animFrame
    PHA
    LDA #0
    PHA
    JSR equal
    PLA
    CMP #$00
    BNE SKIP_TO_ELSE34
    JMP ENDIF34
SKIP_TO_ELSE34:
    LDA #104
    LDY #1
    LDX hero3
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
    LDA #0
    LDY #2
    LDX hero3
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
    LDA #105
    LDY #1
    LDX hero4
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
    LDA #0
    LDY #2
    LDX hero4
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
    LDA #120
    LDY #1
    LDX hero5
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
    LDA #1
    LDY #2
    LDX hero5
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
    LDA #121
    LDY #1
    LDX hero6
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
    LDA #1
    LDY #2
    LDX hero6
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
    JMP ENDIF34
ENDIF34:
    LDA animFrame
    PHA
    LDA #1
    PHA
    JSR equal
    PLA
    CMP #$00
    BNE SKIP_TO_ELSE35
    JMP ENDIF35
SKIP_TO_ELSE35:
    LDA #106
    LDY #1
    LDX hero3
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
    LDA #0
    LDY #2
    LDX hero3
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
    LDA #107
    LDY #1
    LDX hero4
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
    LDA #0
    LDY #2
    LDX hero4
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
    LDA #122
    LDY #1
    LDX hero5
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
    LDA #1
    LDY #2
    LDX hero5
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
    LDA #123
    LDY #1
    LDX hero6
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
    LDA #1
    LDY #2
    LDX hero6
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
    JMP ENDIF35
ENDIF35:
    LDA animFrame
    PHA
    LDA #2
    PHA
    JSR equal
    PLA
    CMP #$00
    BNE SKIP_TO_ELSE36
    JMP ENDIF36
SKIP_TO_ELSE36:
    LDA #108
    LDY #1
    LDX hero3
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
    LDA #0
    LDY #2
    LDX hero3
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
    LDA #109
    LDY #1
    LDX hero4
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
    LDA #0
    LDY #2
    LDX hero4
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
    LDA #124
    LDY #1
    LDX hero5
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
    LDA #1
    LDY #2
    LDX hero5
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
    LDA #125
    LDY #1
    LDX hero6
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
    LDA #1
    LDY #2
    LDX hero6
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
    JMP ENDIF36
ENDIF36:
    LDA animFrame
    PHA
    LDA #3
    PHA
    JSR equal
    PLA
    CMP #$00
    BNE SKIP_TO_ELSE37
    JMP ENDIF37
SKIP_TO_ELSE37:
    LDA #106
    LDY #1
    LDX hero3
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
    LDA #0
    LDY #2
    LDX hero3
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
    LDA #107
    LDY #1
    LDX hero4
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
    LDA #0
    LDY #2
    LDX hero4
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
    LDA #122
    LDY #1
    LDX hero5
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
    LDA #1
    LDY #2
    LDX hero5
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
    LDA #123
    LDY #1
    LDX hero6
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
    LDA #1
    LDY #2
    LDX hero6
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
    JMP ENDIF37
ENDIF37:
    JMP ENDIF32
ENDIF32:
    JMP ENDIF30
ENDIF30:
    JMP ENDIF29
ENDIF29:
    LDA eDirectionCounter
    PHA
    LDA #1
    PHA
    JSR add
    PLA
    STA eDirectionCounter
    LDA eDirectionCounter
    PHA
    LDA eDirectionInterval
    PHA
    JSR subtract
    PLA
    PHA
    LDA #0
    PHA
    JSR greaterThan
    PLA
    CMP #$00
    BNE SKIP_TO_ELSE38
    JMP ENDIF38
SKIP_TO_ELSE38:
    LDA #0
    STA eDirectionCounter
    LDA #1
    PHA
    LDA eFlipped
    PHA
    JSR subtract
    PLA
    STA eFlipped
    LDA eRandomSeed
    PHA
    LDA #13
    PHA
    JSR add
    PLA
    STA eRandomSeed
    LDA eRandomSeed
    PHA
    LDA #13
    PHA
    JSR lowerThan
    PLA
    CMP #$00
    BNE SKIP_TO_ELSE39
    JMP ENDIF39
SKIP_TO_ELSE39:
    LDA eRandomSeed
    PHA
    LDA #7
    PHA
    JSR add
    PLA
    STA eRandomSeed
    JMP ENDIF39
ENDIF39:
    LDA eRandomSeed
    STA eDirectionInterval
    LDA eDirectionInterval
    PHA
    LDA #50
    PHA
    JSR lowerThan
    PLA
    CMP #$00
    BNE SKIP_TO_ELSE40
    JMP ELSE40
SKIP_TO_ELSE40:
    LDA eDirectionInterval
    PHA
    LDA #50
    PHA
    JSR add
    PLA
    STA eDirectionInterval
    JMP ENDIF40
ELSE40:
    LDA eDirectionInterval
    PHA
    LDA #177
    PHA
    JSR greaterThan
    PLA
    CMP #$00
    BNE SKIP_TO_ELSE41
    JMP ENDIF41
SKIP_TO_ELSE41:
    LDA eDirectionInterval
    PHA
    LDA #128
    PHA
    JSR subtract
    PLA
    STA eDirectionInterval
    JMP ENDIF41
ENDIF41:
ENDIF40:
    JMP ENDIF38
ENDIF38:
    LDA eJumpCounter
    PHA
    LDA #1
    PHA
    JSR add
    PLA
    STA eJumpCounter
    LDA eJumpCounter
    PHA
    LDA #150
    PHA
    JSR equal
    PLA
    CMP #$00
    BNE SKIP_TO_ELSE42
    JMP ENDIF42
SKIP_TO_ELSE42:
    LDA #0
    STA eJumpCounter
    LDA eGrounded
    CMP #$00
    BNE SKIP_TO_ELSE43
    JMP ENDIF43
SKIP_TO_ELSE43:
    LDA jumpSpeed
    STA eVSpeed
    LDA #0
    STA eCounter
    JMP ENDIF43
ENDIF43:
    JMP ENDIF42
ENDIF42:
    LDA eFlipped
    CMP #$00
    BNE SKIP_TO_ELSE44
    JMP ELSE44
SKIP_TO_ELSE44:
    LDA ex
    PHA
    LDA speed
    PHA
    JSR add
    PLA
    STA ex
    JMP ENDIF44
ELSE44:
    LDA ex
    PHA
    LDA speed
    PHA
    JSR subtract
    PLA
    STA ex
ENDIF44:
    LDA eGrounded
    CMP #$00
    BNE SKIP_TO_ELSE45
    JMP ENDIF45
SKIP_TO_ELSE45:
    LDA eFlipped
    CMP #$00
    BNE SKIP_TO_ELSE46
    JMP ELSE46
SKIP_TO_ELSE46:
    LDA eEyesState
    CMP #$00
    BNE SKIP_TO_ELSE47
    JMP ELSE47
SKIP_TO_ELSE47:
    LDA #89
    LDY #1
    LDX enemy1
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
    LDA #66
    LDY #2
    LDX enemy1
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
    LDA #88
    LDY #1
    LDX enemy2
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
    LDA #66
    LDY #2
    LDX enemy2
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
    JMP ENDIF47
ELSE47:
    LDA #91
    LDY #1
    LDX enemy1
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
    LDA #66
    LDY #2
    LDX enemy1
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
    LDA #90
    LDY #1
    LDX enemy2
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
    LDA #66
    LDY #2
    LDX enemy2
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
ENDIF47:
    LDA eAnimCounter
    PHA
    LDA #1
    PHA
    JSR add
    PLA
    STA eAnimCounter
    LDA eAnimCounter
    PHA
    LDA #10
    PHA
    JSR equal
    PLA
    CMP #$00
    BNE SKIP_TO_ELSE48
    JMP ENDIF48
SKIP_TO_ELSE48:
    LDA #0
    STA eAnimCounter
    LDA eAnimFrame
    PHA
    LDA #1
    PHA
    JSR add
    PLA
    STA eAnimFrame
    LDA eAnimFrame
    PHA
    LDA #4
    PHA
    JSR equal
    PLA
    CMP #$00
    BNE SKIP_TO_ELSE49
    JMP ENDIF49
SKIP_TO_ELSE49:
    LDA #0
    STA eAnimFrame
    LDA #1
    PHA
    LDA eEyesState
    PHA
    JSR subtract
    PLA
    STA eEyesState
    JMP ENDIF49
ENDIF49:
    LDA eAnimFrame
    PHA
    LDA #0
    PHA
    JSR equal
    PLA
    CMP #$00
    BNE SKIP_TO_ELSE50
    JMP ENDIF50
SKIP_TO_ELSE50:
    LDA #105
    LDY #1
    LDX enemy3
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
    LDA #66
    LDY #2
    LDX enemy3
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
    LDA #104
    LDY #1
    LDX enemy4
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
    LDA #66
    LDY #2
    LDX enemy4
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
    LDA #121
    LDY #1
    LDX enemy5
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
    LDA #67
    LDY #2
    LDX enemy5
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
    LDA #120
    LDY #1
    LDX enemy6
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
    LDA #67
    LDY #2
    LDX enemy6
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
    JMP ENDIF50
ENDIF50:
    LDA eAnimFrame
    PHA
    LDA #1
    PHA
    JSR equal
    PLA
    CMP #$00
    BNE SKIP_TO_ELSE51
    JMP ENDIF51
SKIP_TO_ELSE51:
    LDA #107
    LDY #1
    LDX enemy3
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
    LDA #66
    LDY #2
    LDX enemy3
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
    LDA #106
    LDY #1
    LDX enemy4
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
    LDA #66
    LDY #2
    LDX enemy4
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
    LDA #123
    LDY #1
    LDX enemy5
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
    LDA #67
    LDY #2
    LDX enemy5
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
    LDA #122
    LDY #1
    LDX enemy6
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
    LDA #67
    LDY #2
    LDX enemy6
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
    JMP ENDIF51
ENDIF51:
    LDA eAnimFrame
    PHA
    LDA #2
    PHA
    JSR equal
    PLA
    CMP #$00
    BNE SKIP_TO_ELSE52
    JMP ENDIF52
SKIP_TO_ELSE52:
    LDA #109
    LDY #1
    LDX enemy3
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
    LDA #66
    LDY #2
    LDX enemy3
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
    LDA #108
    LDY #1
    LDX enemy4
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
    LDA #66
    LDY #2
    LDX enemy4
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
    LDA #125
    LDY #1
    LDX enemy5
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
    LDA #67
    LDY #2
    LDX enemy5
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
    LDA #124
    LDY #1
    LDX enemy6
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
    LDA #67
    LDY #2
    LDX enemy6
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
    JMP ENDIF52
ENDIF52:
    LDA eAnimFrame
    PHA
    LDA #3
    PHA
    JSR equal
    PLA
    CMP #$00
    BNE SKIP_TO_ELSE53
    JMP ENDIF53
SKIP_TO_ELSE53:
    LDA #107
    LDY #1
    LDX enemy3
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
    LDA #66
    LDY #2
    LDX enemy3
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
    LDA #106
    LDY #1
    LDX enemy4
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
    LDA #66
    LDY #2
    LDX enemy4
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
    LDA #123
    LDY #1
    LDX enemy5
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
    LDA #67
    LDY #2
    LDX enemy5
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
    LDA #122
    LDY #1
    LDX enemy6
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
    LDA #67
    LDY #2
    LDX enemy6
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
    JMP ENDIF53
ENDIF53:
    JMP ENDIF48
ENDIF48:
    JMP ENDIF46
ELSE46:
    LDA eEyesState
    CMP #$00
    BNE SKIP_TO_ELSE54
    JMP ELSE54
SKIP_TO_ELSE54:
    LDA #88
    LDY #1
    LDX enemy1
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
    LDA #2
    LDY #2
    LDX enemy1
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
    LDA #89
    LDY #1
    LDX enemy2
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
    LDA #2
    LDY #2
    LDX enemy2
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
    JMP ENDIF54
ELSE54:
    LDA #90
    LDY #1
    LDX enemy1
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
    LDA #2
    LDY #2
    LDX enemy1
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
    LDA #91
    LDY #1
    LDX enemy2
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
    LDA #2
    LDY #2
    LDX enemy2
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
ENDIF54:
    LDA eAnimCounter
    PHA
    LDA #1
    PHA
    JSR add
    PLA
    STA eAnimCounter
    LDA eAnimCounter
    PHA
    LDA #10
    PHA
    JSR equal
    PLA
    CMP #$00
    BNE SKIP_TO_ELSE55
    JMP ENDIF55
SKIP_TO_ELSE55:
    LDA #0
    STA eAnimCounter
    LDA eAnimFrame
    PHA
    LDA #1
    PHA
    JSR add
    PLA
    STA eAnimFrame
    LDA eAnimFrame
    PHA
    LDA #4
    PHA
    JSR equal
    PLA
    CMP #$00
    BNE SKIP_TO_ELSE56
    JMP ENDIF56
SKIP_TO_ELSE56:
    LDA #0
    STA eAnimFrame
    LDA #1
    PHA
    LDA eEyesState
    PHA
    JSR subtract
    PLA
    STA eEyesState
    JMP ENDIF56
ENDIF56:
    LDA eAnimFrame
    PHA
    LDA #0
    PHA
    JSR equal
    PLA
    CMP #$00
    BNE SKIP_TO_ELSE57
    JMP ENDIF57
SKIP_TO_ELSE57:
    LDA #104
    LDY #1
    LDX enemy3
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
    LDA #2
    LDY #2
    LDX enemy3
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
    LDA #105
    LDY #1
    LDX enemy4
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
    LDA #2
    LDY #2
    LDX enemy4
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
    LDA #120
    LDY #1
    LDX enemy5
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
    LDA #3
    LDY #2
    LDX enemy5
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
    LDA #121
    LDY #1
    LDX enemy6
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
    LDA #3
    LDY #2
    LDX enemy6
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
    JMP ENDIF57
ENDIF57:
    LDA eAnimFrame
    PHA
    LDA #1
    PHA
    JSR equal
    PLA
    CMP #$00
    BNE SKIP_TO_ELSE58
    JMP ENDIF58
SKIP_TO_ELSE58:
    LDA #106
    LDY #1
    LDX enemy3
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
    LDA #2
    LDY #2
    LDX enemy3
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
    LDA #107
    LDY #1
    LDX enemy4
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
    LDA #2
    LDY #2
    LDX enemy4
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
    LDA #122
    LDY #1
    LDX enemy5
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
    LDA #3
    LDY #2
    LDX enemy5
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
    LDA #123
    LDY #1
    LDX enemy6
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
    LDA #3
    LDY #2
    LDX enemy6
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
    JMP ENDIF58
ENDIF58:
    LDA eAnimFrame
    PHA
    LDA #2
    PHA
    JSR equal
    PLA
    CMP #$00
    BNE SKIP_TO_ELSE59
    JMP ENDIF59
SKIP_TO_ELSE59:
    LDA #108
    LDY #1
    LDX enemy3
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
    LDA #2
    LDY #2
    LDX enemy3
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
    LDA #109
    LDY #1
    LDX enemy4
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
    LDA #2
    LDY #2
    LDX enemy4
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
    LDA #124
    LDY #1
    LDX enemy5
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
    LDA #3
    LDY #2
    LDX enemy5
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
    LDA #125
    LDY #1
    LDX enemy6
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
    LDA #3
    LDY #2
    LDX enemy6
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
    JMP ENDIF59
ENDIF59:
    LDA eAnimFrame
    PHA
    LDA #3
    PHA
    JSR equal
    PLA
    CMP #$00
    BNE SKIP_TO_ELSE60
    JMP ENDIF60
SKIP_TO_ELSE60:
    LDA #106
    LDY #1
    LDX enemy3
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
    LDA #2
    LDY #2
    LDX enemy3
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
    LDA #107
    LDY #1
    LDX enemy4
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
    LDA #2
    LDY #2
    LDX enemy4
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
    LDA #122
    LDY #1
    LDX enemy5
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
    LDA #3
    LDY #2
    LDX enemy5
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
    LDA #123
    LDY #1
    LDX enemy6
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
    LDA #3
    LDY #2
    LDX enemy6
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
    JMP ENDIF60
ENDIF60:
    JMP ENDIF55
ENDIF55:
ENDIF46:
    JMP ENDIF45
ENDIF45:
    LDA grounded
    CMP #$00
    BNE SKIP_TO_ELSE61
    JMP ELSE61
SKIP_TO_ELSE61:
    LDA #1
    PHA
    LDA moving
    PHA
    JSR subtract
    PLA
    CMP #$00
    BNE SKIP_TO_ELSE62
    JMP ENDIF62
SKIP_TO_ELSE62:
    LDA flipped
    CMP #$00
    BNE SKIP_TO_ELSE63
    JMP ELSE63
SKIP_TO_ELSE63:
    LDA #89
    LDY #1
    LDX hero1
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
    LDA #64
    LDY #2
    LDX hero1
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
    LDA #88
    LDY #1
    LDX hero2
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
    LDA #64
    LDY #2
    LDX hero2
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
    LDA #93
    LDY #1
    LDX hero3
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
    LDA #64
    LDY #2
    LDX hero3
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
    LDA #92
    LDY #1
    LDX hero4
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
    LDA #64
    LDY #2
    LDX hero4
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
    LDA #117
    LDY #1
    LDX hero5
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
    LDA #65
    LDY #2
    LDX hero5
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
    LDA #116
    LDY #1
    LDX hero6
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
    LDA #65
    LDY #2
    LDX hero6
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
    JMP ENDIF63
ELSE63:
    LDA #88
    LDY #1
    LDX hero1
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
    LDA #0
    LDY #2
    LDX hero1
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
    LDA #89
    LDY #1
    LDX hero2
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
    LDA #0
    LDY #2
    LDX hero2
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
    LDA #92
    LDY #1
    LDX hero3
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
    LDA #0
    LDY #2
    LDX hero3
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
    LDA #93
    LDY #1
    LDX hero4
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
    LDA #0
    LDY #2
    LDX hero4
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
    LDA #116
    LDY #1
    LDX hero5
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
    LDA #1
    LDY #2
    LDX hero5
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
    LDA #117
    LDY #1
    LDX hero6
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
    LDA #1
    LDY #2
    LDX hero6
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
ENDIF63:
    JMP ENDIF62
ENDIF62:
    JMP ENDIF61
ELSE61:
    LDA flipped
    CMP #$00
    BNE SKIP_TO_ELSE64
    JMP ELSE64
SKIP_TO_ELSE64:
    LDA #87
    LDY #1
    LDX hero1
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
    LDA #64
    LDY #2
    LDX hero1
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
    LDA #86
    LDY #1
    LDX hero2
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
    LDA #64
    LDY #2
    LDX hero2
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
    LDA #103
    LDY #1
    LDX hero3
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
    LDA #64
    LDY #2
    LDX hero3
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
    LDA #102
    LDY #1
    LDX hero4
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
    LDA #64
    LDY #2
    LDX hero4
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
    LDA #119
    LDY #1
    LDX hero5
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
    LDA #65
    LDY #2
    LDX hero5
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
    LDA #118
    LDY #1
    LDX hero6
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
    LDA #65
    LDY #2
    LDX hero6
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
    JMP ENDIF64
ELSE64:
    LDA #86
    LDY #1
    LDX hero1
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
    LDA #0
    LDY #2
    LDX hero1
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
    LDA #87
    LDY #1
    LDX hero2
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
    LDA #0
    LDY #2
    LDX hero2
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
    LDA #102
    LDY #1
    LDX hero3
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
    LDA #0
    LDY #2
    LDX hero3
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
    LDA #103
    LDY #1
    LDX hero4
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
    LDA #0
    LDY #2
    LDX hero4
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
    LDA #118
    LDY #1
    LDX hero5
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
    LDA #1
    LDY #2
    LDX hero5
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
    LDA #119
    LDY #1
    LDX hero6
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
    LDA #1
    LDY #2
    LDX hero6
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
ENDIF64:
ENDIF61:
    LDA eGrounded
    CMP #$00
    BNE SKIP_TO_ELSE65
    JMP ELSE65
SKIP_TO_ELSE65:
    LDA #1
    PHA
    LDA eMoving
    PHA
    JSR subtract
    PLA
    CMP #$00
    BNE SKIP_TO_ELSE66
    JMP ENDIF66
SKIP_TO_ELSE66:
    LDA eFlipped
    CMP #$00
    BNE SKIP_TO_ELSE67
    JMP ELSE67
SKIP_TO_ELSE67:
    LDA #89
    LDY #1
    LDX enemy1
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
    LDA #66
    LDY #2
    LDX enemy1
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
    LDA #88
    LDY #1
    LDX enemy2
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
    LDA #66
    LDY #2
    LDX enemy2
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
    LDA #93
    LDY #1
    LDX enemy3
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
    LDA #66
    LDY #2
    LDX enemy3
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
    LDA #92
    LDY #1
    LDX enemy4
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
    LDA #66
    LDY #2
    LDX enemy4
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
    LDA #117
    LDY #1
    LDX enemy5
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
    LDA #67
    LDY #2
    LDX enemy5
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
    LDA #116
    LDY #1
    LDX enemy6
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
    LDA #67
    LDY #2
    LDX enemy6
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
    JMP ENDIF67
ELSE67:
    LDA #88
    LDY #1
    LDX enemy1
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
    LDA #2
    LDY #2
    LDX enemy1
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
    LDA #89
    LDY #1
    LDX enemy2
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
    LDA #2
    LDY #2
    LDX enemy2
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
    LDA #92
    LDY #1
    LDX enemy3
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
    LDA #2
    LDY #2
    LDX enemy3
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
    LDA #93
    LDY #1
    LDX enemy4
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
    LDA #2
    LDY #2
    LDX enemy4
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
    LDA #116
    LDY #1
    LDX enemy5
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
    LDA #3
    LDY #2
    LDX enemy5
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
    LDA #117
    LDY #1
    LDX enemy6
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
    LDA #3
    LDY #2
    LDX enemy6
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
ENDIF67:
    JMP ENDIF66
ENDIF66:
    JMP ENDIF65
ELSE65:
    LDA eFlipped
    CMP #$00
    BNE SKIP_TO_ELSE68
    JMP ELSE68
SKIP_TO_ELSE68:
    LDA #87
    LDY #1
    LDX enemy1
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
    LDA #66
    LDY #2
    LDX enemy1
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
    LDA #86
    LDY #1
    LDX enemy2
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
    LDA #66
    LDY #2
    LDX enemy2
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
    LDA #103
    LDY #1
    LDX enemy3
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
    LDA #66
    LDY #2
    LDX enemy3
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
    LDA #102
    LDY #1
    LDX enemy4
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
    LDA #66
    LDY #2
    LDX enemy4
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
    LDA #119
    LDY #1
    LDX enemy5
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
    LDA #67
    LDY #2
    LDX enemy5
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
    LDA #118
    LDY #1
    LDX enemy6
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
    LDA #67
    LDY #2
    LDX enemy6
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
    JMP ENDIF68
ELSE68:
    LDA #86
    LDY #1
    LDX enemy1
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
    LDA #2
    LDY #2
    LDX enemy1
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
    LDA #87
    LDY #1
    LDX enemy2
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
    LDA #2
    LDY #2
    LDX enemy2
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
    LDA #102
    LDY #1
    LDX enemy3
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
    LDA #2
    LDY #2
    LDX enemy3
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
    LDA #103
    LDY #1
    LDX enemy4
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
    LDA #2
    LDY #2
    LDX enemy4
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
    LDA #118
    LDY #1
    LDX enemy5
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
    LDA #3
    LDY #2
    LDX enemy5
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
    LDA #119
    LDY #1
    LDX enemy6
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
    LDA #3
    LDY #2
    LDX enemy6
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
ENDIF68:
ENDIF65:
    LDA _x
    PHA
    LDA #0
    PHA
    JSR lowerThan
    PLA
    CMP #$00
    BNE SKIP_TO_ELSE69
    JMP ENDIF69
SKIP_TO_ELSE69:
    LDA #0
    STA _x
    JMP ENDIF69
ENDIF69:
    LDA _x
    PHA
    LDA #240
    PHA
    JSR greaterThan
    PLA
    CMP #$00
    BNE SKIP_TO_ELSE70
    JMP ENDIF70
SKIP_TO_ELSE70:
    LDA #0
    STA _x
    JMP ENDIF70
ENDIF70:
    LDA pad1 ; Загрузка состояния кнопок для Player1
    AND #BTN_A ; Маскирование для проверки кнопки
    BEQ NotPressed71 ; Если кнопка не нажата, переходим к метке NotPressed71
    LDA #$01 ; Если кнопка нажата, загружаем 1
    JMP EndCheck71 ; Переходим к концу проверки
NotPressed71:
    LDA #$00 ; Загружаем 0, так как кнопка не нажата
EndCheck71:
    CMP #$00
    BNE SKIP_TO_ELSE72
    JMP ENDIF72
SKIP_TO_ELSE72:
    LDA grounded
    CMP #$00
    BNE SKIP_TO_ELSE73
    JMP ENDIF73
SKIP_TO_ELSE73:
    LDA jumpSpeed
    STA vSpeed
    LDA #0
    STA counter
    JMP ENDIF73
ENDIF73:
    JMP ENDIF72
ENDIF72:
    LDA pad1 ; Загрузка состояния кнопок для Player1
    AND #BTN_SELECT ; Маскирование для проверки кнопки
    BEQ NotPressed74 ; Если кнопка не нажата, переходим к метке NotPressed74
    LDA #$01 ; Если кнопка нажата, загружаем 1
    JMP EndCheck74 ; Переходим к концу проверки
NotPressed74:
    LDA #$00 ; Загружаем 0, так как кнопка не нажата
EndCheck74:
    CMP #$00
    BNE SKIP_TO_ELSE75
    JMP ELSE75
SKIP_TO_ELSE75:
    LDA #5
    STA i
WHILE_START_76:
    LDA i
    PHA
    LDA #1
    PHA
    JSR greaterThan
    PLA
    CMP #$00
    BEQ WHILE_END_76
    LDA i
    PHA
    LDA #1
    PHA
    JSR subtract
    PLA
    STA i
    LDY #3
    LDX box4
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
    LDX box4
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
    JMP WHILE_START_76
WHILE_END_76:
    JMP ENDIF75
ELSE75:
    LDY #3
    LDX box4
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
    LDX box4
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
ENDIF75:
    LDA _x
    LDY #3
    LDX hero1
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
    LDA _y
    LDY #0
    LDX hero1
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
    LDA _x
    PHA
    LDA #8
    PHA
    JSR add
    PLA
    LDY #3
    LDX hero2
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
    LDA _y
    LDY #0
    LDX hero2
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
    LDA _x
    LDY #3
    LDX hero3
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
    LDA _y
    PHA
    LDA #8
    PHA
    JSR add
    PLA
    LDY #0
    LDX hero3
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
    LDA _x
    PHA
    LDA #8
    PHA
    JSR add
    PLA
    LDY #3
    LDX hero4
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
    LDA _y
    PHA
    LDA #8
    PHA
    JSR add
    PLA
    LDY #0
    LDX hero4
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
    LDA _x
    LDY #3
    LDX hero5
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
    LDA _y
    PHA
    LDA #16
    PHA
    JSR add
    PLA
    LDY #0
    LDX hero5
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
    LDA _x
    PHA
    LDA #8
    PHA
    JSR add
    PLA
    LDY #3
    LDX hero6
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
    LDA _y
    PHA
    LDA #16
    PHA
    JSR add
    PLA
    LDY #0
    LDX hero6
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
    LDA ex
    LDY #3
    LDX enemy1
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
    LDA ey
    LDY #0
    LDX enemy1
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
    LDA ex
    PHA
    LDA #8
    PHA
    JSR add
    PLA
    LDY #3
    LDX enemy2
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
    LDA ey
    LDY #0
    LDX enemy2
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
    LDA ex
    LDY #3
    LDX enemy3
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
    LDA ey
    PHA
    LDA #8
    PHA
    JSR add
    PLA
    LDY #0
    LDX enemy3
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
    LDA ex
    PHA
    LDA #8
    PHA
    JSR add
    PLA
    LDY #3
    LDX enemy4
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
    LDA ey
    PHA
    LDA #8
    PHA
    JSR add
    PLA
    LDY #0
    LDX enemy4
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
    LDA ex
    LDY #3
    LDX enemy5
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
    LDA ey
    PHA
    LDA #16
    PHA
    JSR add
    PLA
    LDY #0
    LDX enemy5
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
    LDA ex
    PHA
    LDA #8
    PHA
    JSR add
    PLA
    LDY #3
    LDX enemy6
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y
    LDA ey
    PHA
    LDA #16
    PHA
    JSR add
    PLA
    LDY #0
    LDX enemy6
    STX temp
    LDX #$02
    STX temp2
    STA (temp), Y



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

subtract:
    pla         ; Извлекаем верхнее значение из стека в A
    tax         ; Перемещаем из A в X
    pla         ; Извлекаем следующее значение из стека в A
    tay         ; Перемещаем из A в Y
    pla         ; Извлекаем значение, которое будет вычитаемым, в A
    sta temp    ; Сохраняем вычитаемое во временной переменной
    pla         ; Извлекаем уменьшаемое из стека в A
    sec         ; Устанавливаем флаг carry для корректного вычитания
    sbc temp    ; Выполняем вычитание с borrow из temp
    pha         ; Сохраняем результат обратно в стек
    tya         ; Перемещаем Y обратно в A
    pha         ; Сохраняем второе извлеченное значение обратно в стек
    txa         ; Перемещаем X обратно в A
    pha         ; Сохраняем первое извлеченное значение обратно в стек
    rts         ; Возвращаемся из подпрограммы

equal:
    pla         ; Извлекаем верхнее значение из стека в A
    tax         ; Сохраняем извлеченное значение в X
    pla         ; Извлекаем следующее значение из стека в A
    tay         ; Сохраняем это значение в Y

    ; Теперь, когда значения сохранены в X и Y, выполняем сравнение двух других значений
    pla         ; Извлекаем первое значение для сравнения
    sta temp    ; Сохраняем его во временной переменной
    pla         ; Извлекаем второе значение для сравнения
    cmp temp    ; Сравниваем его с первым значением, сохраненным в temp

    beq @isEqual ; Если значения равны, переходим к метке isEqual
    lda #$00    ; Загружаем 0 в A, значения не равны
    jmp @done   ; Переходим к завершению функции

@isEqual:
    lda #$01    ; Загружаем 1 в A, значения равны

@done:
    pha         ; Сохраняем результат сравнения (0 или 1) обратно в стек

    ; Восстанавливаем значения, которые были сохранены в X и Y
    tya         ; Перемещаем значение из Y обратно в A
    pha         ; Сохраняем его обратно в стек
    txa         ; Перемещаем значение из X обратно в A
    pha         ; Сохраняем его обратно в стек

    rts         ; Возвращаемся из подпрограммы

lowerThan:
    pla         ; Извлекаем верхнее значение из стека в A
    tax         ; Сохраняем извлеченное значение в X
    pla         ; Извлекаем следующее значение из стека в A
    tay         ; Сохраняем это значение в Y

    ; Теперь, когда значения сохранены в X и Y, выполняем сравнение двух других значений
    pla         ; Извлекаем первое значение для сравнения (второе число)
    sta temp    ; Сохраняем его во временной переменной
    pla         ; Извлекаем второе значение для сравнения (первое число)
    cmp temp    ; Сравниваем его с первым значением, сохраненным в temp

    bcc @isLower ; Если первое число меньше второго, переходим к метке isLower
    lda #$00    ; Загружаем 0 в A, первое число не меньше второго
    jmp @done   ; Переходим к завершению функции

@isLower:
    lda #$01    ; Загружаем 1 в A, первое число меньше второго

@done:
    pha         ; Сохраняем результат сравнения (0 или 1) обратно в стек

    ; Восстанавливаем значения, которые были сохранены в X и Y
    tya         ; Перемещаем значение из Y обратно в A
    pha         ; Сохраняем его обратно в стек
    txa         ; Перемещаем значение из X обратно в A
    pha         ; Сохраняем его обратно в стек

    rts         ; Возвращаемся из подпрограммы

greaterThan:
    pla ; Извлекаем верхнее значение из стека в A
    tax ; Сохраняем извлеченное значение в X
    pla ; Извлекаем следующее значение из стека в A
    tay ; Сохраняем это значение в Y

    ; Теперь, когда значения сохранены в X и Y, выполняем сравнение двух других значений
    pla ; Извлекаем первое значение для сравнения (второе число)
    sta temp ; Сохраняем его во временной переменной
    pla ; Извлекаем второе значение для сравнения (первое число)
    cmp temp ; Сравниваем его с первым значением, сохраненным в temp
    beq @isNotGreater ; Если числа равны, переходим к метке isNotGreater
    bcs @isGreater ; Если первое число больше второго, переходим к метке isGreater

@isNotGreater:
    lda #$00 ; Загружаем 0 в A, первое число не больше второго
    jmp @done ; Переходим к завершению функции

@isGreater:
    lda #$01 ; Загружаем 1 в A, первое число больше второго

@done:
    pha ; Сохраняем результат сравнения (0 или 1) обратно в стек

    ; Восстанавливаем значения, которые были сохранены в X и Y
    tya ; Перемещаем значение из Y обратно в A
    pha ; Сохраняем его обратно в стек
    txa ; Перемещаем значение из X обратно в A
    pha ; Сохраняем его обратно в стек

    rts ; Возвращаемся из подпрограммы



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
    sta temp8 ;flip and pallete data (attribute)
    pla
    sta temp3 ;tile
    pla
    sta temp4 ;y
    pla
    sta temp5 ;x
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
    lda temp8; load fourth argument (attribute)
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

ReadControllers:
    ; write a "1", then a "0", to CONTROLLER1 ($4016)
    ; in order to lock in button states
    LDA #$01
    STA $4016
    LDA #$00
    STA $4016

    ; initialize pad1 to 00000001
    LDA #%0000001
    STA pad1
    
GetButtonStates:
    LDA CONTROLLER1       ; Get the next button state
    LSR A                 ; Shift the accumulator right one bit,
                          ; dropping the button state from bit 0
                          ; into the carry flag
    ROL pad1              ; Shift everything in pad1 left one bit,
                          ; moving the carry flag into bit 0
                          ; (because rotation) and bit 7
                          ; of pad1 into the carry flag
    BCC GetButtonStates   ; If the carry flag is still 0,
                          ; continue the loop. If the "1"
                          ; that we started with drops into
                          ; the carry flag, we are done.

    rts

.proc decodeRLE
    stx temp
    sty temp2
    ldy #0
    jsr doRLEbyte
    sta temp3
L1:
    jsr doRLEbyte
    cmp temp3
    beq L2
    sta PPUDATA
    sta temp4
    bne L1
L2:
    jsr doRLEbyte
    cmp #0
    beq L4
    tax
    lda temp4
L3:
    sta PPUDATA
    dex
    bne L3
    beq L1
L4:
    rts
.endproc

.proc doRLEbyte
    lda (temp),y
    inc temp
    bne L1
    inc temp2
L1:
    rts
.endproc

PaletteData:
    .byte $3c,$20,$26,$0d,$3c,$0c,$1c,$07,$3c,$0d,$20,$0f,$3c,$07,$37,$27  ;background palette data
    .byte $3c,$36,$07,$20,$3c,$1c,$2c,$07,$3c,$17,$0d,$2c,$3c,$2a,$1a,$0a  ;sprite palette data

.include "../nestemplates/mygraphics/nametablescreentest_rleca65.s"

.segment "VECTORS"
    .word NMI
    .word Reset
    ; 
.segment "CHARS"
    .incbin "defaultchar.chr"