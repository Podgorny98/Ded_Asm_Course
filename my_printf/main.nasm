;;locals @@
;;===============================================================
section .data
    PRINTF_FORMAT_STR db "Printf %c, %s, %d, %o, %x and %b, please. okay, and %c %s %x %d %%", 0xa, 0
    LOVE db "love", 0
    BIN_ARG equ 255
    HEX_ARG equ 0xEDA
    OCT_ARG equ 0o777
    DEC_ARG equ 123456
    CHAR_ARG equ 'z'
    STRING_ARG db "Tralala_Tralala", 0
    SYS_WRITE equ 1
    SYS_EXIT equ 60
    EXIT_CODE equ 0
    ERROR_EXIT_CODE equ 1
    STD_OUT equ 1
    NEW_LINE db 0xa         ;; '\n'
    BIN_SHIFT equ 1
    OCT_SHIFT equ 3
    HEX_SHIFT equ 4
    BIN_AND_BITS equ 1
    OCT_AND_BITS equ 07
    HEX_AND_BITS equ 0xF
    ERROR_MSG db "Write error", 0xa
    ERROR_MSG_LEN equ $ - ERROR_MSG
    WRONG_ARG_MSG db "Invalid character after %", 0xa
    WRONG_ARG_MSG_LEN equ $ - WRONG_ARG_MSG
;;===============================================================
section .bss
;;===============================================================
%macro write_to_stdout 2
    mov rax, SYS_WRITE      ;; write syscall
    mov rdi, STD_OUT        ;; 1st arg (fd)
    mov rsi, %1             ;; 2nd arg (buf pointer)
    mov rdx, %2             ;; 3 arg (bytes count)
    syscall
    cmp rax, 0              ;; check return value
    jle wr_error
%endmacro
;;===============================================================
%macro print_result 0
    ;; calculate result length
    mov rax, r8                         ;; r8 = characters quantity
    mov rdx, 8                          ;; 8 byte word
    mul rdx
    mov r8, rax                         ;; r8 = r8 * 8 - bytes quantity
    write_to_stdout rsp, r8             ;; print result
%endmacro
;===============================================================
section .text
    global _start
_start:
    call main
    jmp exit
;;===============================================================
main:
    push rbp
    mov rbp, rsp

    push 100
    push 3802
    push LOVE
    push 'I'
    push BIN_ARG
    push HEX_ARG
    push OCT_ARG
    push DEC_ARG
    push STRING_ARG
    push CHAR_ARG
    push PRINTF_FORMAT_STR

    call MyPrintf

    mov rsp, rbp
    pop rbp
    ret
;;===============================================================
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;  MyPrintf                                                ;;
;;  Exit:                                                   ;;
;;  Destr: rax, rbx, rcx, rdx, rdi, rsi, r8, r9, r10, r11b  ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
MyPrintf:
    push rbp
    mov rbp, rsp

    mov r9, [rbp + 16]          ;; r9 -> printf format string (and first byte)
    mov r10, 16                 ;; [rbp + r10] = current argument

??main_printf_cycle:
    mov r11b, [r9]              ;; r11b = current byte
    test r11b, r11b             ;; is it end of format string
    jz ??end_of_printf
    cmp r11b, '%'               ;; is it %
    je ??printf_arg
    push r11
    write_to_stdout rsp, 1      ;; printf current byte
    pop r11                     ;; stack balance
    inc r9                      ;; r9 -> next byte
    jmp ??main_printf_cycle

??printf_arg:
    inc r9                      ;; r9 -> next byte after %
    add r10, 8                  ;; [rbp + r10] = current argument
    mov r11b, [r9]              ;; r11b = current byte
    inc r9                      ;; r9 -> next byte
    cmp r11b, 'd'
    je ??dec_arg
    cmp r11b, 's'
    je ??str_arg
    cmp r11b, 'c'
    je ??char_arg
    cmp r11b, 'x'
    je ??hex_arg
    cmp r11b, 'o'
    je ??oct_arg
    cmp r11b, 'b'
    je ??bin_arg                ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    write_to_stdout WRONG_ARG_MSG, WRONG_ARG_MSG_LEN
    jmp exit

??dec_arg:
    mov rax, [rbp + r10]
    push rax
    call DecFunc
    mov rsp, rsi
    print_result                ;; printf %d
    mov rsp, rbp                ;; stack balance
    jmp ??main_printf_cycle

??str_arg:
    mov rdi, [rbp + r10]        ;; rdi -> current %s argument   ;;
    xor rax, rax                ;; find \0 in str               ;;
    xor rcx, rcx                ;; rcx = 0                      ;;
    not rcx                     ;; rcx = -1                     ;;;;;;;;;;;;
    cld                         ;; from left to right           ;; strlen ;;
    repne scasb                 ;; rcx = -strlen -2             ;;;;;;;;;;;;
    not rcx                     ;; rcx = strlen + 1             ;;
    dec rcx                     ;; rcx = strlen                 ;;

    write_to_stdout [rbp + r10], rcx    ;; printf %s
    jmp ??main_printf_cycle

??char_arg:
    mov rbx, rbp
    add rbx, r10                ;; rbx -> %c argument
    write_to_stdout rbx, 1      ;; printf %c
    jmp ??main_printf_cycle

??hex_arg:
    mov rax, [rbp + r10]
    push HEX_AND_BITS
    push HEX_SHIFT
    push rax
    call BinOctHexFunc
    mov rsp, rsi                ;; rsp -> top of string
    push 'x'                    ;; hexadecimal notation
    push '0'
    add r8, 2                   ;; r8 = characters counter
    print_result                ;; printf %x
    mov rsp, rbp                ;; stack balance
    jmp ??main_printf_cycle

??oct_arg:
    mov rax, [rbp + r10]
    push OCT_AND_BITS
    push OCT_SHIFT
    push rax
    call BinOctHexFunc
    mov rsp, rsi
    push '0'
    inc r8
    print_result                ;; printf %o
    mov rsp, rbp
    jmp ??main_printf_cycle

??bin_arg:
    mov rax, [rbp + r10]
    push BIN_AND_BITS
    push BIN_SHIFT
    push rax
    call BinOctHexFunc
    mov rsp, rsi
    print_result                ;; printf %b
    mov rsp, rbp
    jmp ??main_printf_cycle

??end_of_printf:
    mov rsp, rbp
    pop rbp
    ret
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;  DecFunc - push numbers in decimal notation of number in rax to stack    ;;
;;  Exit:   r8 = nums quantity; rsi -> top of numbers in stack              ;;
;;  Destr:  rax, rbx, rdx, rsi, r8                                          ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
DecFunc:
    push rbp
    mov rbp, rsp

    mov rax, [rbp + 16]         ;; rax = number to convert in necessary notation
    xor r8, r8                  ;; r8 is digits counter

??dec_loop:
    mov rdx, 0                  ;; numerator is in rdx : rax
    mov rbx, 10
    div rbx                     ;; rax = rax / 10
    add rdx, '0'                ;; rdx = rax % 10 + '0'
    push rdx
    inc r8                      ;; digits counter ++
    cmp rax, 0                  ;; check end of rax
    jne ??dec_loop

    mov rsi, rsp                ;; return rsi which point at top of string
    mov rsp, rbp
    pop rbp
    ret
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;  BinOctHexFunc - push numbers in bin, oct and hex notation of number in rax to stack     ;;
;;  Exit:   r8 = nums quantity; rsi -> top of numbers in stack                              ;;
;;  Destr:  rax, rbx, cl, rsi, r8                                                           ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
BinOctHexFunc:
    push rbp
    mov rbp, rsp

    mov rax, [rbp + 16]         ;; rax = number to convert in necessary notation
    xor r8, r8                  ;; r8 is digits counter
    mov cl, [rbp + 24]          ;; shift bits

??shift_loop:
    mov rbx, [rbp + 32]         ;; AND bits
    and rbx, rax                ;; checking bits in rbx
    cmp rbx, 9                  ;; for hexadecimal
    jg ??more_than_nine
    add rbx, '0'                ;; current digit code
    jmp ??push_loop

??more_than_nine:
    add rbx, 'A' - 10           ;; current digit code

??push_loop:
    push rbx
    shr rax, cl                 ;; rax = rax >> AND bits
    inc r8                      ;; digits counter ++
    cmp rax, 0                  ;; check end of rax
    jne ??shift_loop

;jmp exit
    mov rsi, rsp                ;; return rsi which point at top of string
    mov rsp, rbp
    pop rbp
    ret
;;===============================================================


;;===============================================================
exit:
    mov rax, SYS_EXIT
    mov rdi, EXIT_CODE
    syscall

wr_error:
    mov rax, SYS_WRITE
    mov rdi, STD_OUT
    mov rsi, ERROR_MSG
    mov rdx, ERROR_MSG_LEN
    syscall
    mov rax, SYS_EXIT
    mov rdi, ERROR_EXIT_CODE
    syscall
