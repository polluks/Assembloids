'
' Assembloids - A CVBasic puzzle game port of Quartet (MSX)
' Original concept by Ilkke & bitsofbas (MSXdev 2018)
'

    DEFINE CHAR PLETTER 0, 253, image_char
    DEFINE COLOR PLETTER 0, 253, image_color

    ' Set up timer bar tiles (solid block patterns)
    FOR #i = 0 TO 7
        VPOKE $0008 + #i, 255
        VPOKE $0010 + #i, 255
    NEXT #i
    ' Solid blocks show the foreground color: green / red
    VPOKE $2001, $31
    VPOKE $2002, $81

    DIM g(15)
    DIM f(15)

    ' Piece value -> tile map (4 faces x 4 quadrants)
    ' Face 0 (red):   tiles 169,170 / 209,210
    ' Face 1 (white): tiles 174,175 / 214,215
    ' Face 2 (blue):  tiles 185,186 / 225,226
    ' Face 3 (green): tiles 190,191 / 230,231
    f(0) = 169: f(1) = 170: f(2) = 209: f(3) = 210
    f(4) = 174: f(5) = 175: f(6) = 214: f(7) = 215
    f(8) = 185: f(9) = 186: f(10) = 225: f(11) = 226
    f(12) = 190: f(13) = 191: f(14) = 230: f(15) = 231

    title_t = 0
    help_t = 0
    px = 0
    py = 0
    stage = 0
    pulse = 0
    timer = 0
    timer_max = 0
    complete = 0

    #score = 0
    #hiscore = 0
    lives = 3

restart:
    SCREEN DISABLE
    FOR #i = 0 TO 767
        VPOKE $1800 + #i, 0
    NEXT #i
    SCREEN ENABLE
    title_t = 0

title_loop:
    GOSUB draw_title
    WHILE 1
        WAIT
        title_t = title_t + 1
        IF title_t > 120 THEN title_t = 0
        IF CONT1.BUTTON OR CONT1.BUTTON2 THEN GOTO begin_game
        IF CONT1.KEY < 15 THEN GOTO help_loop
    WEND

help_loop:
    GOSUB draw_help
    WHILE 1
        WAIT
        help_t = help_t + 1
        IF help_t > 120 THEN help_t = 0
        IF CONT1.BUTTON OR CONT1.BUTTON2 OR CONT1.KEY < 15 THEN GOTO restart
    WEND

begin_game:
    #score = 0
    lives = 3
    stage = 1

next_stage:
    GOSUB setup_stage

main_loop:
    WHILE 1
        WAIT
        GOSUB handle_input
        GOSUB update_timer
        GOSUB draw_board
        IF lives = 0 THEN GOTO game_over
        IF complete >= 4 THEN
            stage = stage + 1
            GOTO next_stage
        END IF
    WEND

setup_stage: PROCEDURE
    SCREEN DISABLE
    FOR #i = 0 TO 767
        VPOKE $1800 + #i, 0
    NEXT #i
    complete = 0
    ' 4 faces x 4 quadrants = 16 cells = full grid
    FOR #i = 0 TO 15
        g(#i) = #i
    NEXT #i
    ' Shuffle all individual pieces (16 values, mapped to face tiles via f())
    FOR #i = 0 TO 15
        #r = #i + RANDOM(16 - #i)
        #t = g(#i)
        g(#i) = g(#r)
        g(#r) = #t
    NEXT #i
    px = 1
    py = 1
    IF stage = 1 THEN timer_max = 200 ELSE timer_max = 166
    timer = timer_max
    SCREEN ENABLE
    END

handle_input: PROCEDURE
    pulse = pulse + 1
    IF pulse > 30 THEN pulse = 0
    IF CONT1.LEFT AND px > 0 THEN
        #idx = py * 4 + px
        #idx2 = py * 4 + px - 1
        IF g(#idx2) = 255 THEN
            lives = lives - 1
            SOUND 6, 3, 10
            SOUND 8, 10, 10
            IF lives > 0 THEN
                timer = timer_max
                GOSUB shuffle_board
            END IF
        ELSE
            #t = g(#idx)
            g(#idx) = g(#idx2)
            g(#idx2) = #t
            px = px - 1
            SOUND 7, 250, 4
            SOUND 8, 10, 4
            GOSUB check_faces
        END IF
    END IF
    IF CONT1.RIGHT AND px < 3 THEN
        #idx = py * 4 + px
        #idx2 = py * 4 + px + 1
        IF g(#idx2) = 255 THEN
            lives = lives - 1
            SOUND 6, 3, 10
            SOUND 8, 10, 10
            IF lives > 0 THEN
                timer = timer_max
                GOSUB shuffle_board
            END IF
        ELSE
            #t = g(#idx)
            g(#idx) = g(#idx2)
            g(#idx2) = #t
            px = px + 1
            SOUND 7, 250, 4
            SOUND 8, 10, 4
            GOSUB check_faces
        END IF
    END IF
    IF CONT1.UP AND py > 0 THEN
        #idx = py * 4 + px
        #idx2 = (py - 1) * 4 + px
        IF g(#idx2) = 255 THEN
            lives = lives - 1
            SOUND 6, 3, 10
            SOUND 8, 10, 10
            IF lives > 0 THEN
                timer = timer_max
                GOSUB shuffle_board
            END IF
        ELSE
            #t = g(#idx)
            g(#idx) = g(#idx2)
            g(#idx2) = #t
            py = py - 1
            SOUND 7, 250, 4
            SOUND 8, 10, 4
            GOSUB check_faces
        END IF
    END IF
    IF CONT1.DOWN AND py < 3 THEN
        #idx = py * 4 + px
        #idx2 = (py + 1) * 4 + px
        IF g(#idx2) = 255 THEN
            lives = lives - 1
            SOUND 6, 3, 10
            SOUND 8, 10, 10
            IF lives > 0 THEN
                timer = timer_max
                GOSUB shuffle_board
            END IF
        ELSE
            #t = g(#idx)
            g(#idx) = g(#idx2)
            g(#idx2) = #t
            py = py + 1
            SOUND 7, 250, 4
            SOUND 8, 10, 4
            GOSUB check_faces
        END IF
    END IF
    END

check_faces: PROCEDURE
    #bonus = 1
    FOR #fy = 0 TO 1
        FOR #fx = 0 TO 1
            #i0 = #fy * 8 + #fx * 2
            #i1 = #i0 + 1
            #i2 = #i0 + 4
            #i3 = #i2 + 1
            #a0 = g(#i0)
            IF #a0 <> 255 THEN
                #face = #a0 / 4
                #c0 = #a0 = #face * 4
                #c1 = g(#i1) = #face * 4 + 1
                #c2 = g(#i2) = #face * 4 + 2
                #c3 = g(#i3) = #face * 4 + 3
                #count = #c0 + #c1 + #c2 + #c3
                IF #count = 4 THEN
                    g(#i0) = 255
                    g(#i1) = 255
                    g(#i2) = 255
                    g(#i3) = 255
                    complete = complete + 1
                    #score = #score + 20
                    SOUND 7, 248, 2
                    SOUND 6, 8, 4
                    SOUND 8, 12, 4
                ELSE
                    #score = #score + #count * 5
                    #bonus = 0
                END IF
            END IF
        NEXT #fx
    NEXT #fy
    IF complete = 4 AND #bonus THEN
        lives = lives + 1
        #score = #score + 50
    END IF
    END

update_timer: PROCEDURE
    timer = timer - 1
    IF timer <= 0 THEN
        lives = lives - 1
        SOUND 6, 3, 10
        SOUND 8, 10, 10
        IF lives > 0 THEN
            timer = timer_max
            GOSUB shuffle_board
        END IF
    END IF
    END

shuffle_board: PROCEDURE
    FOR #i = 0 TO 59
        #a = RANDOM(16)
        #b = RANDOM(16)
        IF g(#a) <> 255 AND g(#b) <> 255 THEN
            #t = g(#a)
            g(#a) = g(#b)
            g(#b) = #t
        END IF
    NEXT #i
    GOSUB mark_faces
    END

mark_faces: PROCEDURE
    FOR #fy = 0 TO 1
        FOR #fx = 0 TO 1
            #i0 = #fy * 8 + #fx * 2
            #i1 = #i0 + 1
            #i2 = #i0 + 4
            #i3 = #i2 + 1
            #a0 = g(#i0)
            IF #a0 <> 255 THEN
                #face = #a0 / 4
                IF #a0 = #face * 4 AND g(#i1) = #face * 4 + 1 AND g(#i2) = #face * 4 + 2 AND g(#i3) = #face * 4 + 3 THEN
                    g(#i0) = 255
                    g(#i1) = 255
                    g(#i2) = 255
                    g(#i3) = 255
                    complete = complete + 1
                END IF
            END IF
        NEXT #fx
    NEXT #fy
    END

draw_board: PROCEDURE
    ' Board offset: centered on screen
    ' Draw board background first (tile 154 = cyan background)
    FOR #row = 0 TO 3
        FOR #col = 0 TO 3
            #addr = $1800 + (8 + #row) * 32 + (12 + #col)
            VPOKE #addr, 154
        NEXT #col
    NEXT #row
    ' Draw face pieces via lookup table
    FOR #row = 0 TO 3
        FOR #col = 0 TO 3
            #idx = #row * 4 + #col
            #val = g(#idx)
            IF #val <> 255 THEN
                #addr = $1800 + (8 + #row) * 32 + (12 + #col)
                VPOKE #addr, f(#val)
            END IF
        NEXT #col
    NEXT #row
    ' Draw cursor highlight (overlay tile 155 on current cell)
    #addr = $1800 + (8 + py) * 32 + (12 + px)
    IF pulse > 15 THEN
        VPOKE #addr, 155
    END IF
    ' Timer bar (row 0): tile 1 = green, tile 2 = red
    FOR #i = 0 TO 31
        #t = 2
        IF #i < timer * 32 / timer_max THEN #t = 1
        VPOKE $1800 + #i, #t
    NEXT #i
    ' Lives in upper right (row 1)
    FOR #i = 0 TO lives - 1
        VPOKE $1800 + 63 - #i, 155
    NEXT #i
    ' HUD (row 23)
    PRINT AT 736,"SCORE:",<6>#score
    PRINT AT 748,"STAGE:",stage
    END

draw_title: PROCEDURE
    ' Row 1: title
    PRINT AT 32,"   ASSEMBLOIDS"
    ' Rows 4-5: four faces
    ' Face 0 (red, tiles 169,170 / 209,210) at cols 2-3
    VPOKE $1800 + 130, 169
    VPOKE $1800 + 131, 170
    VPOKE $1800 + 162, 209
    VPOKE $1800 + 163, 210
    ' Face 1 (white, tiles 174,175 / 214,215) at cols 8-9
    VPOKE $1800 + 136, 174
    VPOKE $1800 + 137, 175
    VPOKE $1800 + 168, 214
    VPOKE $1800 + 169, 215
    ' Face 2 (blue, tiles 185,186 / 225,226) at cols 14-15
    VPOKE $1800 + 142, 185
    VPOKE $1800 + 143, 186
    VPOKE $1800 + 174, 225
    VPOKE $1800 + 175, 226
    ' Face 3 (green, tiles 190,191 / 230,231) at cols 20-21
    VPOKE $1800 + 148, 190
    VPOKE $1800 + 149, 191
    VPOKE $1800 + 180, 230
    VPOKE $1800 + 181, 231
    ' Row 8: hiscore in lower right
    PRINT AT 268,"HISCORE:",<7>#hiscore
    ' Row 10: press fire
    IF title_t < 60 THEN
        PRINT AT 320," PRESS FIRE"
    ELSE
        PRINT AT 320,"            "
    END IF
    END

draw_help: PROCEDURE
    SCREEN DISABLE
    FOR #i = 0 TO 767
        VPOKE $1800 + #i, 0
    NEXT #i
    SCREEN ENABLE
    ' Row 1: heading
    PRINT AT 42," HOW TO PLAY"
    ' Rows 3-4: four faces (red, white, blue, green)
    VPOKE $1800 + 98, 169:    VPOKE $1800 + 99, 170
    VPOKE $1800 + 130, 209:   VPOKE $1800 + 131, 210
    VPOKE $1800 + 104, 174:   VPOKE $1800 + 105, 175
    VPOKE $1800 + 136, 214:   VPOKE $1800 + 137, 215
    VPOKE $1800 + 110, 185:   VPOKE $1800 + 111, 186
    VPOKE $1800 + 142, 225:   VPOKE $1800 + 143, 226
    VPOKE $1800 + 116, 190:   VPOKE $1800 + 117, 191
    VPOKE $1800 + 148, 230:   VPOKE $1800 + 149, 231
    ' Row 6-7: objective
    PRINT AT 192,"ASSEMBLE THE FITTING PIECES"
    PRINT AT 224,"TOGETHER TO MAKE FOUR FACES"
    ' Rows 9-10: move rule
    PRINT AT 288,"MOVE THE CENTRE PIECE TO AN"
    PRINT AT 320,"ADJACENT EMPTY TILE"
    ' Row 12: controls
    PRINT AT 384,"USE THE CURSOR KEYS OR JOYSTICK"
    ' Rows 14-16: lose-a-life warning
    PRINT AT 448,"IF THE TIMER RUNS OUT, OR"
    PRINT AT 480,"YOU MOVE ONTO AN EMPTY TILE,"
    PRINT AT 512,"YOU LOSE A LIFE!"
    ' Row 19: blinking return prompt
    IF help_t < 60 THEN
        PRINT AT 608," PRESS FIRE"
    ELSE
        PRINT AT 608,"            "
    END IF
    END

game_over:
    IF #score > #hiscore THEN #hiscore = #score
    SCREEN DISABLE
    FOR #i = 0 TO 767
        VPOKE $1800 + #i, 0
    NEXT #i
    SCREEN ENABLE
    PRINT AT 264,"GAME OVER"
    PRINT AT 296,"SCORE:",<7>#score
    PRINT AT 328,"HISCORE:",<7>#hiscore
    FOR #c = 1 TO 200
        WAIT
    NEXT #c
    GOTO restart

' ============================================================
' BMP Tile Data (Pletter-compressed from Assembloids.bmp)
' ============================================================
image_char:
    DATA BYTE $3a,$00,$ab,$e3,$00,$20,$92,$00
    DATA BYTE $00,$01,$50,$00,$d2,$0f,$06,$54
    DATA BYTE $f8,$01,$0b,$11,$78,$08,$a0,$70
    DATA BYTE $28,$f0,$17,$c0,$c8,$00,$10,$20
    DATA BYTE $40,$98,$18,$00,$40,$a0,$81,$01
    DATA BYTE $a8,$90,$68,$00,$60,$69,$0d,$27
    DATA BYTE $91,$15,$00,$20,$10,$57,$17,$03
    DATA BYTE $00,$03,$13,$a8,$70,$20,$70,$a8
    DATA BYTE $45,$50,$f8,$50,$e6,$5c,$cd,$2c
    DATA BYTE $fc,$64,$6d,$60,$02,$08,$c4,$2d
    DATA BYTE $80,$06,$70,$02,$88,$98,$a8,$c8
    DATA BYTE $88,$70,$2e,$ab,$23,$00,$32,$23
    DATA BYTE $0f,$18,$60,$80,$43,$07,$30,$08
    DATA BYTE $00,$17,$30,$50,$90,$90,$f8,$10
    DATA BYTE $82,$5f,$f8,$80,$f0,$08,$00,$49
    DATA BYTE $f0,$0f,$40,$08,$88,$57,$17,$0f
    DATA BYTE $3f,$57,$30,$27,$0c,$73,$02,$07
    DATA BYTE $78,$36,$39,$5c,$bc,$06,$07,$bb
    DATA BYTE $62,$65,$8a,$9f,$00,$53,$b0,$01
    DATA BYTE $76,$04,$02,$0d,$01,$02,$04,$08
    DATA BYTE $38,$67,$ef,$e3,$7f,$98,$80,$12
    DATA BYTE $7f,$50,$40,$f8,$02,$67,$00,$5c
    DATA BYTE $62,$02,$17,$80,$00,$b9,$57,$0f
    DATA BYTE $88,$d5,$0f,$7f,$77,$3c,$02,$f8
    DATA BYTE $07,$73,$80,$1f,$b8,$ae,$77,$1c
    DATA BYTE $36,$a3,$37,$f5,$96,$00,$70,$5f
    DATA BYTE $68,$00,$17,$90,$09,$a0,$c0,$a0
    DATA BYTE $90,$17,$80,$d4,$00,$37,$0f,$d8
    DATA BYTE $38,$a8,$a8,$27,$88,$c8,$4c,$c8
    DATA BYTE $6f,$98,$2f,$ed,$57,$bc,$5f,$4f
    DATA BYTE $cc,$00,$d8,$7b,$0f,$b1,$37,$5f
    DATA BYTE $70,$c6,$ff,$3d,$c4,$00,$79,$67
    DATA BYTE $2f,$d5,$05,$96,$a4,$0f,$50,$d8
    DATA BYTE $cb,$4f,$0d,$8e,$ba,$0f,$e2,$82
    DATA BYTE $2f,$d1,$d7,$8e,$6f,$78,$60,$00
    DATA BYTE $47,$78,$f0,$11,$fd,$ee,$39,$67
    DATA BYTE $30,$00,$f0,$c6,$e7,$e5,$f5,$67
    DATA BYTE $27,$1d,$84,$0b,$68,$98,$8a,$d6
    DATA BYTE $d7,$1c,$de,$ef,$56,$0f,$41,$14
    DATA BYTE $96,$3f,$cd,$6d,$17,$d4,$a9,$fb
    DATA BYTE $64,$8f,$48,$32,$40,$e0,$f1,$ee
    DATA BYTE $1f,$f1,$5b,$70,$53,$2f,$53,$79
    DATA BYTE $60,$60,$ff,$00,$18,$d0,$ff,$a5
    DATA BYTE $17,$81,$e0,$87,$c7,$74,$15,$17
    DATA BYTE $00,$d0,$66,$a8,$00,$1d,$07,$b0
    DATA BYTE $c8,$2f,$dd,$4f,$27,$68,$00,$6f
    DATA BYTE $80,$ee,$4f,$50,$8c,$07,$b8,$c0
    DATA BYTE $78,$ea,$7f,$6d,$ef,$b6,$c6,$f4
    DATA BYTE $c8,$ed,$1e,$8e,$87,$80,$74,$0f
    DATA BYTE $c7,$4e,$50,$36,$07,$50,$d3,$3a
    DATA BYTE $1e,$8f,$30,$d3,$c5,$80,$f8,$0a
    DATA BYTE $85,$20,$05,$02,$5e,$18,$3f,$2b
    DATA BYTE $bf,$c0,$03,$36,$b0,$c0,$0e,$27
    DATA BYTE $40,$a8,$10,$7d,$62,$70,$58,$70
    DATA BYTE $3f,$d7,$5f,$86,$00,$0f,$1d,$1f
    DATA BYTE $12,$01,$03,$3f,$00,$01,$00,$13
    DATA BYTE $ff,$fc,$fe,$07,$ff,$82,$00,$7f
    DATA BYTE $f0,$f0,$fe,$00,$11,$fc,$fc,$f9
    DATA BYTE $07,$ff,$fe,$47,$01,$10,$c0,$e0
    DATA BYTE $56,$00,$d4,$ac,$40,$17,$d0,$01
    DATA BYTE $01,$fd,$b9,$2c,$00,$ff,$e4,$00
    DATA BYTE $49,$02,$d1,$00,$00,$e5,$0f,$a8
    DATA BYTE $34,$a0,$01,$fe,$3e,$00,$0e,$1e
    DATA BYTE $3e,$7e,$1f,$6f,$74,$78,$68,$ee
    DATA BYTE $00,$00,$34,$be,$f8,$00,$1a,$30
    DATA BYTE $3c,$7e,$0c,$00,$30,$f0,$de,$00
    DATA BYTE $08,$df,$df,$00,$f4,$7f,$f0,$f8
    DATA BYTE $0f,$e0,$d8,$b8,$78,$e0,$3f,$02
    DATA BYTE $06,$0b,$05,$00,$09,$05,$0b,$06
    DATA BYTE $15,$2b,$50,$a8,$43,$ff,$b1,$2f
    DATA BYTE $40,$6c,$13,$13,$ec,$fe,$e0,$07
    DATA BYTE $21,$21,$df,$a0,$08,$50,$2b,$56
    DATA BYTE $fe,$0c,$d0,$00,$34,$80,$40,$01
    DATA BYTE $d7,$f9,$bf,$70,$7f,$00,$00,$1c
    DATA BYTE $1c,$e0,$6e,$01,$00,$cc,$cc,$00
    DATA BYTE $3f,$9f,$80,$80,$0f,$1f,$1f,$0f
    DATA BYTE $04,$f3,$e7,$07,$07,$c2,$b0,$b6
    DATA BYTE $c0,$fc,$2d,$17,$05,$d6,$00,$10
    DATA BYTE $aa,$24,$be,$3f,$5f,$01,$3e,$1c
    DATA BYTE $5e,$3e,$01,$b0,$75,$82,$a0,$00
    DATA BYTE $e7,$e7,$02,$e1,$09,$fe,$9e,$9e
    DATA BYTE $dc,$0e,$17,$c0,$34,$f0,$e8,$01
    DATA BYTE $fe,$3f,$60,$70,$00,$72,$73,$b3
    DATA BYTE $00,$b1,$01,$78,$fc,$30,$30,$48
    DATA BYTE $86,$40,$86,$88,$7c,$00,$14,$50
    DATA BYTE $2b,$c5,$e0,$fc,$f8,$0b,$01,$a2
    DATA BYTE $52,$f2,$2f,$41,$17,$87,$86,$38
    DATA BYTE $a1,$00,$34,$34,$fc,$3f,$7e,$87
    DATA BYTE $bd,$28,$28,$19,$17,$65,$0c,$a6
    DATA BYTE $86,$07,$ce,$ec,$ef,$cf,$1f,$12
    DATA BYTE $d2,$f3,$cf,$70,$e0,$b2,$a0,$e5
    DATA BYTE $17,$96,$17,$8e,$0a,$50,$6b,$d7
    DATA BYTE $f9,$bf,$57,$1c,$e9,$19,$6e,$07
    DATA BYTE $78,$ca,$69,$f8,$c1,$00,$3f,$1f
    DATA BYTE $80,$c0,$c2,$7b,$f1,$e3,$07,$c9
    DATA BYTE $63,$17,$01,$03,$b2,$17,$fe,$ed
    DATA BYTE $00,$52,$bf,$ff,$ff,$ff,$ff,$c0

image_color:
    DATA BYTE $3b,$f1,$ae,$be,$36,$00,$61,$00
    DATA BYTE $38,$91,$96,$00,$61,$64,$0c,$94
    DATA BYTE $a9,$a9,$91,$00,$67,$61,$07,$56
    DATA BYTE $10,$0f,$14,$db,$1f,$1a,$26,$f1
    DATA BYTE $91,$b3,$41,$e1,$41,$00,$41,$fe
    DATA BYTE $e4,$a7,$00,$c6,$0f,$f4,$fe,$df
    DATA BYTE $00,$7d,$0f,$07,$fc,$3d,$41,$f0
    DATA BYTE $00,$71,$74,$a1,$00,$05,$f1,$d1
    DATA BYTE $f7,$91,$00,$45,$41,$a9,$f7,$07
    DATA BYTE $df,$17,$7f,$27,$3c,$3f,$c1,$00
    DATA BYTE $04,$a2,$a2,$c2,$c2,$c1,$02,$a2
    DATA BYTE $0c,$a1,$a1,$21,$21,$07,$3e,$a4
    DATA BYTE $a2,$07,$ec,$17,$1e,$fb,$28,$5f
    DATA BYTE $e7,$bf,$96,$98,$41,$1c,$c5,$07
    DATA BYTE $64,$8d,$e3,$3b,$0f,$00,$7a,$07
    DATA BYTE $1f,$be,$17,$27,$fe,$3f,$78,$d1
    DATA BYTE $97,$98,$fd,$fe,$04,$ed,$36,$ed
    DATA BYTE $e1,$00,$9e,$07,$fe,$5f,$0f,$1f
    DATA BYTE $7e,$07,$c9,$bf,$91,$41,$8b,$32
    DATA BYTE $e4,$07,$2a,$be,$53,$00,$63,$91
    DATA BYTE $07,$e1,$9e,$07,$f1,$7b,$17,$8e
    DATA BYTE $bf,$63,$15,$a0,$cc,$9a,$5d,$f4
    DATA BYTE $64,$a4,$10,$b8,$cf,$bb,$df,$07
    DATA BYTE $7d,$17,$27,$bb,$e6,$ff,$61,$fb
    DATA BYTE $0a,$be,$fc,$ca,$7e,$07,$fb,$21
    DATA BYTE $ef,$27,$ef,$3f,$ff,$ff,$ff,$fc
