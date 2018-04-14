; ====> READ ME <====
; comments are there only to make understanding the code easier
; there's a version without most of them (apart from symbol signatures) 
; in the same folder ("mul_no_comments.asm") 

                section         .text

                global          _start
_start:
                ; move stack pointer to make space for 2 128-qword numbers
                sub             rsp, 2 * 128 * 8
                ; move address of first number to rdi
                lea             rdi, [rsp + 128 * 8]
                ; move length of first number to rcx
                mov             rcx, 128
                ; read first number
                call            read_long
                ; move address of second number to rdi
                mov             rdi, rsp
                ; read second number
                call            read_long
                ; move address from rdi to rsi (required due to pecularities of sbb)
                mov             rsi, rdi
                ; move address of second argument to rdi
                lea             rdi, [rsp + 128 * 8]
                ; calculate result
                call            sub_long_long

                ; write result to stdout
                call            write_long

                ; write line break to stdout
                mov             al, 0x0a
                call            write_char

                ; exit
                jmp             exit

; subtracts two long numbers
;    rdi -- address of minuend (long number)
;    rsi -- address of subtrahend (long number)
;    rcx -- length of long numbers in qwords
; result:
;    difference is written to rdi
sub_long_long:
                ; store current data in registers
                push            rdi
                push            rsi
                push            rcx

                ; clear CF
                clc

.loop:
                ; move current qword of subtrahend to rax
                mov             rax, [rsi]
                ; subtract current qword in subtrahend from
                ; value in rax (== current qword in minuend) with borrow
                sbb             [rdi], rax
                ; move rsi to the next qword in minuend
                add             rsi, 8
                ; move rdi to the next qword in subtrahend
                add             rdi, 8
                ; decrement the length (and loop counter) in rcx
                dec             rcx
                jnz             .loop

                ; restore data in registers
                pop             rcx
                pop             rsi
                pop             rdi
                ret


; adds two long numbers
;    rdi -- address of summand #1 (long number)
;    rsi -- address of summand #2 (long number)
;    rcx -- length of long numbers in qwords
; result:
;    sum is written to rdi
add_long_long:
                ; store current data in registers
                push            rdi
                push            rsi
                push            rcx

                ; clear CF
                clc
.loop:
                ; move next qword from the number #2 to rax
                mov             rax, [rsi]
                ; move rsi to next qword in number #2
                lea             rsi, [rsi + 8]
                ; add rax (aka current qword in number #2) to
                ; current qword in number #1 with carry
                adc             [rdi], rax
                ; move rdi to next qword in number #1
                lea             rdi, [rdi + 8]
                ; decrement length (and loop counter) in rcx
                dec             rcx
                jnz             .loop

                ; restore data in registers
                pop             rcx
                pop             rsi
                pop             rdi
                ret

; adds 64-bit number to long number
;    rdi -- address of summand #1 (long number)
;    rax -- summand #2 (64-bit unsigned)
;    rcx -- length of long number in qwords
; result:
;    sum is written to rdi
add_long_short:
                ; store current data in registers
                push            rdi
                push            rcx
                push            rdx

                ; set rdx to 0
                xor             rdx,rdx
.loop:
                ; add rax to current qword in the long number
                ; (first iteration - actual number, afterwards
                ; -- CF if present)
                add             [rdi], rax
                ; set rdx to CF (by adding 0 with carry)
                adc             rdx, 0
                ; set rax to rdx (== CF)
                mov             rax, rdx
                ; set rdx to 0
                xor             rdx, rdx
                ; move rdi to next qword in the long number
                add             rdi, 8
                ; decrement length (and looop counter) in rcx
                dec             rcx
                jnz             .loop

                ; restore data in registers
                pop             rdx
                pop             rcx
                pop             rdi
                ret

; multiplies long number by a short
;    rdi -- address of multiplier #1 (long number)
;    rbx -- multiplier #2 (64-bit unsigned)
;    rcx -- length of long number in qwords
; result:
;    product is written to rdi
mul_long_short:
                ; store current data in registers
                push            rax
                push            rdi
                push            rcx

                ; set rsi to 0
                xor             rsi, rsi
.loop:
                ; move current qword in the long number to rax
                mov             rax, [rdi]
                ; multiply rax (== current qword in the long number) by rbx
                mul             rbx
                ; add rsi (carry from previous multiplication) to rax
                add             rax, rsi
                ; add CF to rdx (by adding 0 with carry)
                adc             rdx, 0
                ; move current result in rax to current qword in the long number
                mov             [rdi], rax
                ; move rdi to next qword in the long number
                add             rdi, 8
                ; write the high part of product to rsi
                mov             rsi, rdx
                ; decrement length (and loop counter) in rcx
                dec             rcx
                jnz             .loop

                ; restore data in registers
                pop             rcx
                pop             rdi
                pop             rax
                ret

; divides long number by a short
;    rdi -- address of dividend (long number)
;    rbx -- divisor (64-bit unsigned)
;    rcx -- length of long number in qwords
; result:
;    quotient is written to rdi
;    rdx -- remainder
div_long_short:
                ; store current data in registers
                push            rdi
                push            rax
                push            rcx

                ; move rdi to the first qword in the long number
                lea             rdi, [rdi + 8 * rcx - 8]
                ; set rdx (aka remainder) to 0
                xor             rdx, rdx

.loop:
                ; set rax to current qword in the long number
                mov             rax, [rdi]
                ; divide rax (== current qword) by rbx
                div             rbx
                ; move the divided value of current qword back at rdi
                mov             [rdi], rax
                ; move to the previous qword in the long number
                sub             rdi, 8
                ; decrement length (and loop counter) in rcx
                dec             rcx
                jnz             .loop

                ; restore data in registers
                pop             rcx
                pop             rax
                pop             rdi
                ret

; assigns a zero to long number
;    rdi -- argument (long number)
;    rcx -- length of long number in qwords
set_zero:
                ; store current data in registers
                push            rax
                push            rdi
                push            rcx

                ; set rax to 0
                xor             rax, rax
                ; [while rcx > 0 decrement rcx] rep
                ; [store qword (8 bytes) rax value (== 0) at address rdi and increase 
                ; rdi by qword (8 bytes)] stosq
                rep stosq

                ; restore data in registers
                pop             rcx
                pop             rdi
                pop             rax
                ret

; checks if a long number is a zero
;    rdi -- argument (long number)
;    rcx -- length of long number in qwords
; result:
;    ZF=1 if zero
is_zero:
                ; store current data in registers
                push            rax
                push            rdi
                push            rcx

                ; set rax to 0
                xor             rax, rax
                ; [while rcx > 0 decrement rcx] rep
                ; [compare qword (8 bytes) rax value (== 0) with qword (8 bytes)
                ; at address rdi and set flags if required] scasq
                rep scasq

                ; restore data in registers
                pop             rcx
                pop             rdi
                pop             rax
                ret

; read long number from stdin
;    rdi -- location for output (long number)
;    rcx -- length of long number in qwords
read_long:
                ; store current data in registers
                push            rcx
                push            rdi

                ; set the current long number at address rdi with length rcx to zero
                call            set_zero
.loop:
                ; read a character from the number
                call            read_char
                ; set flags for rax
                or              rax, rax
                ; exit if rax < 0 (SF == 1, error has occured when reading)
                js              exit
                ; compare rax with EOL
                cmp             rax, 0x0a
                ; if rax reached EOL, finish reading
                je              .done
                ; compare rax with '0'
                cmp             rax, '0'
                ; if rax is less than '0', print an error message
                jb              .invalid_char
                ; compare rax with '9'
                cmp             rax, '9'
                ; if rax is more than '9', print an error message
                ja              .invalid_char

                ; change rax from char code to respective digit
                sub             rax, '0'
                ; set rbx to 10
                mov             rbx, 10
                ; multiply current long number by 10
                call            mul_long_short
                ; add current digit to the long number
                call            add_long_short
                jmp             .loop

.done:
                ; restore data in registers
                pop             rdi
                pop             rcx
                ret

.invalid_char:
                ; print error message
                mov             rsi, invalid_char_msg
                mov             rdx, invalid_char_msg_size
                call            print_string
                ; print the invalid char
                call            write_char
                ; set al to line break
                mov             al, 0x0a
                ; print line break
                call            write_char

.skip_loop:
                ; read a char from stdin
                call            read_char
                ; set flags for rax
                or              rax, rax
                ; if rax < 0 (SF == 1, error has occured when reading)
                js              exit
                ; compare rax with EOL
                cmp             rax, 0x0a
                ; if rax reached EOL, finish reading
                je              exit
                jmp             .skip_loop

; write long number to stdout
;    rdi -- argument (long number)
;    rcx -- length of long number in qwords
write_long:
                ; store current data in registers
                push            rax
                push            rcx

                ; set rax to 20 (maximum length of the 64-bit number)
                mov             rax, 20
                ; multiply rax by rcx (aka number length) to get maximum length of 
                ; the long number in chars
                mul             rcx
                ; store rsp value in rbp
                mov             rbp, rsp
                ; make space for string representation of the long number
                sub             rsp, rax
                ; set rsi to the end of space for the long number
                mov             rsi, rbp

.loop:
                ; set rbx to 10
                mov             rbx, 10
                ; divide current long number by rbx value (== 10)
                call            div_long_short
                ; change the remainder in rdx from digit value to char
                add             rdx, '0'
                ; decrement rsi
                dec             rsi
                ; write the char at the end of rdx to memory at rsi
                mov             [rsi], dl
                ; check if the remaining long number is zero
                call            is_zero
                jnz             .loop

                ; set rdx to rbp
                mov             rdx, rbp
                ; set rdx to size of string at rsi (by subtracting rsi from rdx)
                sub             rdx, rsi
                ; print the long number
                call            print_string

                ; restore rsp and data in registers
                mov             rsp, rbp
                pop             rcx
                pop             rax
                ret

; read one char from stdin
; result:
;    rax == -1 if error occurs
;    rax \in [0; 255] if OK
read_char:
                ; store current data in registers
                push            rcx
                push            rdi

                ; make space for one char
                sub             rsp, 1
                ; move syscall number to rax
                ; syscall 0 == sys_read
                xor             rax, rax
                ; move file descriptor number to rdi
                ; rdi == 0 => stdin
                xor             rdi, rdi
                ; move string address to rsi
                mov             rsi, rsp
                ; move string size to rdx
                mov             rdx, 1
                ; read char
                syscall

                ; check if one char was read
                cmp             rax, 1
                ; exit with rax == -1 if condition is not met
                jne             .error
                ; set rax to 0
                xor             rax, rax
                ; move byte at rsp to al
                mov             al, [rsp]
                ; restore rsp
                add             rsp, 1

                ; restore data in registers
                pop             rdi
                pop             rcx
                ret
.error:
                ; set rax to -1
                mov             rax, -1
                ; restore rsp
                add             rsp, 1
                ; restore data in registers
                pop             rdi
                pop             rcx
                ret

; write one char to stdout, errors are ignored
;    al -- char
write_char:
                ; make space for one char
                sub             rsp, 1
                ; move char in al to memory at rsp
                mov             [rsp], al

                ; move syscall number to rax
                ; syscall 1 == sys_write
                mov             rax, 1
                ; move file descriptor number to rdi
                ; rdi == 1 => stdout
                mov             rdi, 1
                ; set string address (which is now in rsp) to rsi
                mov             rsi, rsp
                ; set string size to 1
                mov             rdx, 1
                ; write al to stdout
                syscall
                ; restore rsp
                add             rsp, 1
                ret

; program exit point
exit:
                ; move syscall number to rax
                ; syscall 60 == sys_exit
                mov             rax, 60
                ; set rdi to 0
                ; rdi == 0 => program executed without errors
                xor             rdi, rdi
                ; exit
                syscall

; print string to stdout
;    rsi -- string
;    rdx -- size
print_string:
                ; store current data in registers
                push            rax

                ; move syscall number to rax
                ; syscall 1 == sys_write
                mov             rax, 1
                ; move file descriptor number to rdi
                ; rdi == 1 => stdout
                mov             rdi, 1
                ; print string at rsi with size rdx
                syscall

                ; restore data in registers
                pop             rax
                ret

; prints a sample message
print_debug:
                push            rsi
                push            rdx
                push            rax

                mov             rsi, debug_msg
                mov             rdx, debug_msg_size
                call            print_string
                mov             al, 0x0a
                call            write_char

                pop             rax
                pop             rdx
                pop             rsi
                ret

; messages data
                section         .rodata
debug_msg:                      db      "its ok there"
debug_msg_size:                 equ     $ - debug_msg
; set symbol invalid_char_msg to byte sequence "Invalid character: "
invalid_char_msg:               db      "Invalid character: "
; set symbol invalid_char_msg_size to size of invalid_char_msg
invalid_char_msg_size:          equ     $ - invalid_char_msg
; how it works:
; ...][Invalid character: ][<number>][...   <---- memory
;     .                    $
;     ^msg                 ^msg_size
; (current address) $ - (address of) msg == size of "Invalid character: "
 