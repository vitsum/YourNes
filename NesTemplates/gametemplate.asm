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
{0}
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



{1}

Loop:
    JMP Loop

NMI:
    LDA #$02 ; copy sprite data from $0200 => PPU memory for display
    STA $4014
    JSR ReadControllers




{2}


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