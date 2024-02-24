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
; Byte declaration: speed = 1
speed: .res 1
; Byte declaration: vSpeed = 128
vSpeed: .res 1
; Byte declaration: g = 1
g: .res 1
; Byte declaration: jumpSpeed = 125
jumpSpeed: .res 1
; Byte declaration: test = 0
test: .res 1
; Byte declaration: grounded = 0
grounded: .res 1
; Sprite declaration: cursorSprite
cursorSprite: .res 1
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
; initialization of speed with 1
LDA #1
STA speed
; initialization of vSpeed with 128
LDA #128
STA vSpeed
; initialization of g with 1
LDA #1
STA g
; initialization of jumpSpeed with 125
LDA #125
STA jumpSpeed
; initialization of test with 0
LDA #0
STA test
; initialization of grounded with 0
LDA #0
STA grounded
; initialization of counter with 0
LDA #0
STA counter
    LDA _x
    PHA
    LDA #100
    PHA
    JSR add
    PLA
    PHA
    LDA _y
    PHA
    LDA #165
    PHA
    JSR add
    PLA
    PHA
    LDA #10
    PHA
    LDA #3
    PHA
    JSR CreateSprite
    PLA
    STA box1
    LDA _x
    PHA
    LDA #100
    PHA
    JSR add
    PLA
    PHA
    LDA #8
    PHA
    JSR add
    PLA
    PHA
    LDA _y
    PHA
    LDA #165
    PHA
    JSR add
    PLA
    PHA
    LDA #11
    PHA
    LDA #3
    PHA
    JSR CreateSprite
    PLA
    STA box2
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
    LDA _x
    PHA
    LDA #140
    PHA
    JSR add
    PLA
    PHA
    LDA #165
    PHA
    LDA #26
    PHA
    LDA #3
    PHA
    JSR CreateSprite
    PLA
    STA box3
    LDA _x
    PHA
    LDA #140
    PHA
    JSR add
    PLA
    PHA
    LDA #8
    PHA
    JSR add
    PLA
    PHA
    LDA #165
    PHA
    LDA #27
    PHA
    LDA #3
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
    LDA vSpeed
    PHA
    LDA #254
    PHA
    JSR greaterThan
    PLA
    CMP #$00
    BNE SKIP_TO_ELSE1
    JMP ENDIF1
SKIP_TO_ELSE1:
    LDA #254
    STA vSpeed
    JMP ENDIF1
ENDIF1:
    LDA vSpeed
    PHA
    LDA #128
    PHA
    JSR greaterThan
    PLA
    CMP #$00
    BNE SKIP_TO_ELSE2
    JMP ENDIF2
SKIP_TO_ELSE2:
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
    JMP ENDIF2
ENDIF2:
    LDA vSpeed
    PHA
    LDA #128
    PHA
    JSR lowerThan
    PLA
    CMP #$00
    BNE SKIP_TO_ELSE3
    JMP ENDIF3
SKIP_TO_ELSE3:
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
    JMP ENDIF3
ENDIF3:
    LDA #0
    STA grounded
    LDA _y
    PHA
    LDA #200
    PHA
    JSR greaterThan
    PLA
    CMP #$00
    BNE SKIP_TO_ELSE4
    JMP ENDIF4
SKIP_TO_ELSE4:
    LDA #200
    STA _y
    LDA #128
    STA vSpeed
    LDA #1
    STA grounded
    JMP ENDIF4
ENDIF4:
    LDA vSpeed
    PHA
    LDA #128
    PHA
    JSR greaterThan
    PLA
    CMP #$00
    BNE SKIP_TO_ELSE5
    JMP ENDIF5
SKIP_TO_ELSE5:
    LDY #0
    LDX hero5
    STX temp
    LDX #$02
    STX temp2
    LDA (temp), Y
    PHA
    LDY #0
    LDX box1
    STX temp
    LDX #$02
    STX temp2
    LDA (temp), Y
    PHA
    JSR lowerThan
    PLA
    CMP #$00
    BNE SKIP_TO_ELSE6
    JMP ENDIF6
SKIP_TO_ELSE6:
    LDY #0
    LDX hero5
    STX temp
    LDX #$02
    STX temp2
    LDA (temp), Y
    PHA
    LDA #8
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
    BNE SKIP_TO_ELSE7
    JMP ENDIF7
SKIP_TO_ELSE7:
    LDA _x
    PHA
    LDA #8
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
    BNE SKIP_TO_ELSE8
    JMP ENDIF8
SKIP_TO_ELSE8:
    LDY #3
    LDX box2
    STX temp
    LDX #$02
    STX temp2
    LDA (temp), Y
    PHA
    LDA _x
    PHA
    JSR greaterThan
    PLA
    CMP #$00
    BNE SKIP_TO_ELSE9
    JMP ENDIF9
SKIP_TO_ELSE9:
    LDY #0
    LDX box1
    STX temp
    LDX #$02
    STX temp2
    LDA (temp), Y
    PHA
    LDA #24
    PHA
    JSR subtract
    PLA
    STA _y
    LDA #128
    STA vSpeed
    LDA #1
    STA grounded
    JMP ENDIF9
ENDIF9:
    JMP ENDIF8
ENDIF8:
    JMP ENDIF7
ENDIF7:
    JMP ENDIF6
ENDIF6:
    LDY #0
    LDX hero5
    STX temp
    LDX #$02
    STX temp2
    LDA (temp), Y
    PHA
    LDY #0
    LDX box3
    STX temp
    LDX #$02
    STX temp2
    LDA (temp), Y
    PHA
    JSR lowerThan
    PLA
    CMP #$00
    BNE SKIP_TO_ELSE10
    JMP ENDIF10
SKIP_TO_ELSE10:
    LDY #0
    LDX hero5
    STX temp
    LDX #$02
    STX temp2
    LDA (temp), Y
    PHA
    LDA #8
    PHA
    JSR add
    PLA
    PHA
    LDY #0
    LDX box3
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
    LDA _x
    PHA
    LDA #8
    PHA
    JSR add
    PLA
    PHA
    LDY #3
    LDX box3
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
    LDY #3
    LDX box4
    STX temp
    LDX #$02
    STX temp2
    LDA (temp), Y
    PHA
    LDA _x
    PHA
    JSR greaterThan
    PLA
    CMP #$00
    BNE SKIP_TO_ELSE13
    JMP ENDIF13
SKIP_TO_ELSE13:
    LDY #0
    LDX box3
    STX temp
    LDX #$02
    STX temp2
    LDA (temp), Y
    PHA
    LDA #24
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
    JMP ENDIF5
ENDIF5:
    LDA pad1 ; Загрузка состояния кнопок для Player1
    AND #BTN_RIGHT ; Маскирование для проверки кнопки
    BEQ NotPressed14 ; Если кнопка не нажата, переходим к метке NotPressed14
    LDA #$01 ; Если кнопка нажата, загружаем 1
    JMP EndCheck14 ; Переходим к концу проверки
NotPressed14:
    LDA #$00 ; Загружаем 0, так как кнопка не нажата
EndCheck14:
    CMP #$00
    BNE SKIP_TO_ELSE15
    JMP ENDIF15
SKIP_TO_ELSE15:
    LDA _x
    PHA
    LDA speed
    PHA
    JSR add
    PLA
    STA _x
    JMP ENDIF15
ENDIF15:
    LDA pad1 ; Загрузка состояния кнопок для Player1
    AND #BTN_LEFT ; Маскирование для проверки кнопки
    BEQ NotPressed16 ; Если кнопка не нажата, переходим к метке NotPressed16
    LDA #$01 ; Если кнопка нажата, загружаем 1
    JMP EndCheck16 ; Переходим к концу проверки
NotPressed16:
    LDA #$00 ; Загружаем 0, так как кнопка не нажата
EndCheck16:
    CMP #$00
    BNE SKIP_TO_ELSE17
    JMP ENDIF17
SKIP_TO_ELSE17:
    LDA _x
    PHA
    LDA speed
    PHA
    JSR subtract
    PLA
    STA _x
    JMP ENDIF17
ENDIF17:
    LDA pad1 ; Загрузка состояния кнопок для Player1
    AND #BTN_A ; Маскирование для проверки кнопки
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
    LDA grounded
    CMP #$00
    BNE SKIP_TO_ELSE20
    JMP ENDIF20
SKIP_TO_ELSE20:
    LDA jumpSpeed
    STA vSpeed
    LDA #0
    STA counter
    JMP ENDIF20
ENDIF20:
    JMP ENDIF19
ENDIF19:
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
    pla         ; Извлекаем верхнее значение из стека в A
    tax         ; Сохраняем извлеченное значение в X
    pla         ; Извлекаем следующее значение из стека в A
    tay         ; Сохраняем это значение в Y

    ; Теперь, когда значения сохранены в X и Y, выполняем сравнение двух других значений
    pla         ; Извлекаем первое значение для сравнения (второе число)
    sta temp    ; Сохраняем его во временной переменной
    pla         ; Извлекаем второе значение для сравнения (первое число)
    cmp temp    ; Сравниваем его с первым значением, сохраненным в temp

    bcs @isGreater ; Если первое число больше или равно второго, переходим к метке isGreater
    lda #$00     ; Загружаем 0 в A, первое число не больше второго
    jmp @done    ; Переходим к завершению функции

@isGreater:
    lda #$01     ; Загружаем 1 в A, первое число больше второго

@done:
    pha          ; Сохраняем результат сравнения (0 или 1) обратно в стек

    ; Восстанавливаем значения, которые были сохранены в X и Y
    tya          ; Перемещаем значение из Y обратно в A
    pha          ; Сохраняем его обратно в стек
    txa          ; Перемещаем значение из X обратно в A
    pha          ; Сохраняем его обратно в стек

    rts          ; Возвращаемся из подпрограммы



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

PaletteData:
    .byte $3c,$27,$07,$20,$3c,$0c,$1c,$07,$3c,$0d,$20,$0f,$3c,$07,$37,$27  ;background palette data
    .byte $3c,$27,$07,$20,$3c,$0c,$1c,$07,$3c,$0d,$20,$0f,$3c,$07,$37,$27  ;sprite palette data

.segment "VECTORS"
    .word NMI
    .word Reset
    ; 
.segment "CHARS"
    .incbin "defaultchar.chr"