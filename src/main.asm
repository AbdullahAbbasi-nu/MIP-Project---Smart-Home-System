; =============================================================================
; Project: Smart Environmental Control System
; =============================================================================

.include "m32def.inc"

.equ RS = 0
.equ RW = 4
.equ E  = 1

.def temp        = r16
.def lcd_data    = r17
.def temp_val    = r18
.def ldr_val     = r19
.def fan_speed   = r20
.def quot        = r21
.def rem         = r22
.def divisor     = r23
.def delay_temp  = r24       
.def delay_temp2 = r25       
.def last_temp = r26
.def last_ldr  = r27

.cseg
.org 0x000
    rjmp RESET
.org 0x002
    rjmp EXT_INT0

RESET:
    ldi temp, low(RAMEND)
    out SPL, temp
    ldi temp, high(RAMEND)
    out SPH, temp

    ldi temp, 0x00
    out DDRA, temp
    ldi temp, 0xFF
    out PORTA, temp

    ldi temp, 0xFF
    out DDRB, temp
    ldi temp, 0x00
    out PORTB, temp

    ldi temp, 0xFF
    out DDRC, temp
    ldi temp, 0x00
    out PORTC, temp

    ldi temp, (1<<DDD4)|(1<<DDD3)|(1<<DDD1)|(1<<DDD0) 
    out DDRD, temp
    ldi temp, 0x00
    out PORTD, temp

    rcall ADC_Init
    rcall LCD_Init
    rcall Timer0_PWM_Init
    rcall INT0_Init

    sei

MAIN_LOOP:
    rcall Read_LDR
    mov ldr_val, temp

	cpi ldr_val, 39
	brlo LDR_THREE_ON

	cpi ldr_val, 87
	brlo LDR_TWO_ON

	cpi ldr_val, 129
	brlo LDR_ONE_ON
	
	rjmp LDR_ALL_OFF

LDR_THREE_ON: sbi PORTB, 5 sbi PORTB, 6 sbi PORTB, 7 rjmp LDR_DONE
LDR_TWO_ON:   sbi PORTB, 5 sbi PORTB, 6 cbi PORTB, 7 rjmp LDR_DONE
LDR_ONE_ON:   sbi PORTB, 5 cbi PORTB, 6 cbi PORTB, 7 rjmp LDR_DONE
LDR_ALL_OFF:  cbi PORTB, 5 cbi PORTB, 6 cbi PORTB, 7
LDR_DONE:

    cp ldr_val, last_ldr
    breq Skip_LCD_Light
    mov last_ldr, ldr_val
    rcall Update_LCD_Light
Skip_LCD_Light:

    rcall Read_Temp
    mov temp_val, temp
    rcall Control_Fan

    cp temp_val, last_temp
    breq Skip_LCD_Temp
    mov last_temp, temp_val
    rcall Update_LCD_Temp
Skip_LCD_Temp:

    rjmp MAIN_LOOP

ADC_Init:
    ldi temp, (1<<REFS0)|(1<<ADLAR)  ; selcting AVCC as Vref and making ADC Output left-justified
    out ADMUX, temp
    ldi temp, (1<<ADEN)|(1<<ADPS2)|(1<<ADPS1)|(1<<ADPS0) ; ADC Enabled and 128 prescalar selected
    out ADCSRA, temp
    ret

Read_LDR:
    in  temp, ADMUX
    andi temp, 0xE0
    out ADMUX, temp
    sbi ADCSRA, ADSC
WaitLDR:
    sbic ADCSRA, ADSC ;waiting for the ADC to perform the conversion bc lm35 is connexted adc1
    rjmp WaitLDR
    in  temp, ADCH
    ret

Read_Temp:
    in  temp, ADMUX
    andi temp, 0xE0
    ori  temp, 0x01 ;selecting ADC1 as single ended input
    out ADMUX, temp
    sbi  ADCSRA, ADSC
WaitTemp:
    sbic ADCSRA, ADSC
    rjmp WaitTemp
    in   temp, ADCH
    lsl  temp
    ret

Timer0_PWM_Init:
    ldi temp, (1<<WGM00)|(1<<WGM01)|(1<<COM01)|(1<<CS01)
    out TCCR0, temp
    clr temp
    out OCR0, temp
    ret

Control_Fan:
    mov temp, temp_val
    cpi temp, 25
    brlo FAN_OFF
    cpi temp, 30
    brlo FAN_25
    cpi temp, 35
    brlo FAN_50
    cpi temp, 40
    brlo FAN_75
    ldi fan_speed, 0xFF
    rjmp FAN_SET

FAN_OFF:
    ldi fan_speed, 0x00
    out OCR0, fan_speed
    cbi PORTB, 0
    cbi PORTB, 1
    ret

FAN_25:
    ldi fan_speed, 64
    rjmp FAN_SET

FAN_50:
    ldi fan_speed, 128
    rjmp FAN_SET

FAN_75:
    ldi fan_speed, 192
    rjmp FAN_SET

FAN_SET:
    out OCR0, fan_speed
    sbi PORTB, 0
    cbi PORTB, 1
    ret

INT0_Init:
    ldi temp, (1<<ISC01)
    out MCUCR, temp
    ldi temp, (1<<INT0)
    out GICR, temp
    ret

EXT_INT0:
    push r24
    push r25
    push r30
    push r31

    sbi PORTD, 3
    ldi r16, 0x01
    rcall LCD_Command  
    ldi r16, 0x80
    rcall LCD_Command

    ldi r16, 'C'
    rcall LCDData
    ldi r16, 'R'
    rcall LCDData
    ldi r16, 'I'
    rcall LCDData
    ldi r16, 'T'
    rcall LCDData
    ldi r16, 'I'
    rcall LCDData
    ldi r16, 'C'
    rcall LCDData
    ldi r16, 'A'
    rcall LCDData
    ldi r16, 'L'
    rcall LCDData
    ldi r16, ' '
    rcall LCDData
    ldi r16, 'A'
    rcall LCDData
    ldi r16, 'L'
    rcall LCDData
    ldi r16, 'E'
    rcall LCDData
    ldi r16, 'R'
    rcall LCDData
    ldi r16, 'T'
    rcall LCDData
    ldi r16, '!'
    rcall LCDData

    pop r31
    pop r30
    pop r25
    pop r24
    reti

LCD_Init:
    sbi DDRD, RS
    sbi DDRD, RW
    sbi DDRD, E

    ldi r16, 0xFF
    out DDRC, r16

    rcall Delay_20ms

    ldi r16, 0x38
    rcall LCD_Command_Init 
    ldi r16, 0x0C
    rcall LCD_Command_Init
    ldi r16, 0x01
    rcall LCD_Command
    ldi r16, 0x06
    rcall LCD_Command_Init
    ret

LCD_Command:
    out PORTC, r16
    cbi PORTD, RS
    cbi PORTD, RW
    sbi PORTD, E
    rcall Delay_us_pulse
    cbi PORTD, E
    cpi r16, 0x01
    breq Command_2ms_delay
    cpi r16, 0x02
    breq Command_2ms_delay
    rcall Delay_100us
    ret

Command_2ms_delay:
    rcall Delay_2ms
    ret

LCD_Command_Init:
    out PORTC, r16
    cbi PORTD, RS
    cbi PORTD, RW
    sbi PORTD, E
    rcall Delay_us_pulse
    cbi PORTD, E
    rcall Delay_100us
    ret

LCDData:
    out PORTC, r16
    sbi PORTD, RS
    cbi PORTD, RW
    sbi PORTD, E
    rcall Delay_us_pulse
    cbi PORTD, E
    rcall Delay_100us
    ret

Update_LCD_Temp:
    ldi r16, 0xC0
    rcall LCD_Command

    sbic PORTB,0
    rjmp FanIsOn
    ldi r16,'F'
    rcall LCDData
    ldi r16,'A'
    rcall LCDData
    ldi r16,'N'
    rcall LCDData
    ldi r16,':'
    rcall LCDData
    ldi r16,'O'
    rcall LCDData
    ldi r16,'F'
    rcall LCDData
    ldi r16,'F'
    rcall LCDData
    rjmp PrintTempLabel

FanIsOn:
    ldi r16,'F'
    rcall LCDData
    ldi r16,'A'
    rcall LCDData
    ldi r16,'N'
    rcall LCDData
    ldi r16,':'
    rcall LCDData
    ldi r16,'O'
    rcall LCDData
    ldi r16,'N'
    rcall LCDData
    ldi r16,' '
    rcall LCDData

PrintTempLabel:
    ldi r16,' '
    rcall LCDData
    ldi r16,'T'
    rcall LCDData
    ldi r16,'e'
    rcall LCDData
    ldi r16,'m'
    rcall LCDData
    ldi r16,'p'
    rcall LCDData
    ldi r16,':'
    rcall LCDData

    mov temp,temp_val
    rcall Convert_and_Display
    ldi r16,'C'
    rcall LCDData
    ret

Update_LCD_Light:
    ldi r16, 0x80
    rcall LCD_Command
    ldi r16, 'L'
    rcall LCDData
    ldi r16, 'D'
    rcall LCDData
    ldi r16, 'R'
    rcall LCDData
    ldi r16, ':'
    rcall LCDData
    ldi r16, ' '
    rcall LCDData

    mov temp, ldr_val
    rcall Convert_LDR_Percentage

    ldi r16, '%'
    rcall LCDData
    ldi r16, ' '
    rcall LCDData
    ldi r16, ' '
    rcall LCDData
    ldi r16, ' '
    rcall LCDData
    ret

div8u:
    push     r24
    clr      r23
    ldi      r24, 8
div8u_loop:
    lsl      r21
    rol      r23
    cp       r23, r22
    brlo     div8u_skip
    sub      r23, r22
    ori      r21, 0x01
div8u_skip:
    dec      r24
    brne     div8u_loop
    mov      r22, r23
    pop      r24
    ret

Convert_and_Display:
    mov      r21, temp
    ldi      r22, 10
    rcall    div8u
    ori      r21, '0'
    mov      r16, r21
    rcall    LCDData
    ori      r22, '0'
    mov      r16, r22
    rcall    LCDData
    ret

Delay_us_pulse:
    nop
    nop
    nop
    ret

Delay_100us:
    push delay_temp
    ldi delay_temp, 60
Delay_100us_loop:
    call Delay_us_pulse
    dec delay_temp
    brne Delay_100us_loop
    pop delay_temp
    ret

Delay_2ms:
    push delay_temp
    ldi delay_temp, 20
Delay_2ms_loop:
    call Delay_100us
    dec delay_temp
    brne Delay_2ms_loop
    pop delay_temp
    ret

Delay_20ms:
    push delay_temp
    ldi delay_temp, 10
Delay_20ms_loop:
    call Delay_2ms
    dec delay_temp
    brne Delay_20ms_loop
    pop delay_temp
    ret

Convert_LDR_Percentage:
    cpi     temp, 170        
    brlo    val_ok
    ldi     temp, 170
val_ok:
    mov     r21, temp        
    ldi     r22, 151         
    mul     r21, r22
    mov     temp, r1
    cpi     temp, 2
    brlo    ForceZero
    rjmp    DisplayLDR
ForceZero:
    ldi     temp, 0
DisplayLDR:
    rcall   Display_3digit
    ret

Display_3digit:
    mov     r21, temp
    ldi     r22, 100
    rcall    div8u
    ori     r21, '0'
    mov     r16, r21
    rcall LCDData
    mov     temp, r22
    mov     r21, temp
    ldi     r22, 10
    rcall    div8u
    ori     r21, '0'
    mov     r16, r21
    rcall LCDData
    ori     r22, '0'
    mov     r16, r22
    rcall LCDData
    ret
