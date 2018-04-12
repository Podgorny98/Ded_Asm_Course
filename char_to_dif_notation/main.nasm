%macro read_write 4
    mov rax, %1         ;; sys_call num
    mov rdi, %2         ;; 1st arg (fd)
    mov rsi, %3         ;; 2nd arg (buf pointer)
    mov rdx, %4         ;; 3 arg (bytes count)
    syscall
    cmp rax, 0         ;; check return value
    jle rd_wr_error
%endmacro
;;===============================================================
%macro print_result 0
    ;; calculate result length
    mov rax, r8                                     ;; r8 = nums quantity
    mov rdx, 8                                      ;; 8 byte word
    mul rdx
    mov r8, rax                                     ;; r8 = r8 * 8
    read_write SYS_WRITE, STD_OUT, rsp, r8          ;; print result
    read_write SYS_WRITE, STD_OUT, NEW_LINE, 1      ;; print \n
%endmacro
;;===============================================================
section .data
    SYS_READ equ 0
    SYS_WRITE equ 1
    SYS_EXIT equ 60
    EXIT_CODE equ 0
    STD_IN equ 0
    STD_OUT equ 1
    NEW_LINE db 0xa         ;; '\n'
    BIN_SHIFT equ 1
    OCT_SHIFT equ 3
    HEX_SHIFT equ 4
    BIN_AND_BITS equ 1
    OCT_AND_BITS equ 07
    HEX_AND_BITS equ 0xF
    ERROR_MSG db "Read\Write error"
    ERROR_MSG_LEN equ 16
section .bss
    INPUT_CHAR resb 1
;;===============================================================
section .text
    global _start
_start:
    call main
    jmp exit

main:
    push rbp
    mov rbp, rsp

    ;; get char
 ;   read_write SYS_READ, STD_IN, INPUT_CHAR, 1

    ;; to binary
    push BIN_AND_BITS
    push BIN_SHIFT
    call BinOctHexFunc
    mov rsp, rsi
    print_result
    mov rsp, rbp            ;; balance stack

    ;; to octadecimal
    push OCT_AND_BITS
    push OCT_SHIFT
    call BinOctHexFunc
    mov rsp, rsi
    push '0'                ;; octadecimal notation
    inc r8                  ;; for '0'
    print_result
    mov rsp, rbp            ;; balance stack

    ;; to hexadecimal
    push HEX_AND_BITS
    push HEX_SHIFT
    call BinOctHexFunc
    mov rsp, rsi
    push 'x'                ;; hexadecimal notation
    push '0'
    add r8, 2               ;; for 'x' and '0'
    print_result
    mov rsp, rbp            ;; balance stack

    ;; to decimal
    call DecFunc
    mov rsp, rsi
    print_result
    mov rsp, rbp            ;; balance stack

    mov rsp, rbp            ;; return
    pop rbp
    ret
;;===============================================================
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;  BinOctHexFunc - push numbers in bin, oct and hex notation of numper in rax to stack     ;;
;;  Exit:   r8 = nums quantity; rsi -> top of numbers in stack                              ;;
;;  Destr:  rax, rbx, cl, rsi, r8                                                           ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
BinOctHexFunc:
    push rbp
    mov rbp, rsp

    ;mov rax, [INPUT_CHAR]
    mov rax, 999
    xor r8, r8                  ;; r8 is nums counter
    mov cl, [rbp + 16]          ;; shift bits
 ;   mov cl, 1

??shift_loop:
    mov rbx, [rbp + 24]         ;; AND bits
  ; mov rbx, 1
    and rbx, rax                ;; checking bits in rbx
    cmp rbx, 9                  ;; for hexadecimal
    jg ??more_than_nine
    add rbx, '0'                ;; current num code
    jmp ??push_loop

??more_than_nine:
    add rbx, 'A' - 10           ;; current num code

??push_loop:
    push rbx
 ;   read_write SYS_WRITE, STD_OUT, rsp, 8
 ;   jmp exit
    shr rax, cl
    inc r8
    cmp rax, 0                  ;; check end of rax
    jne ??shift_loop

    mov rsi, rsp                ;; return rsi
    mov rsp, rbp
    pop rbp
    ret
;;===============================================================
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;  DecFunc - push numbers in decimal notation of numper in rax to stack    ;;
;;  Exit:   r8 = nums quantity; rsi -> top of numbers in stack              ;;
;;  Destr:  rax, rbx, rdx, rsi, r8                                          ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
DecFunc:
    push rbp
    mov rbp, rsp

    mov rax, [INPUT_CHAR]
    xor r8, r8          ;; r8 is counter
??dec_loop:
    mov rdx, 0          ;; numerator is in rdx : rax
    mov rbx, 10
    div rbx             ;; rax = rax / 10
    add rdx, '0'        ;; remainder is in rdx
    push rdx
    inc r8
    cmp rax, 0
    jne ??dec_loop

    mov rsi, rsp        ;; return rsi
    mov rsp, rbp
    pop rbp
    ret
;;===============================================================
exit:
    mov rax, SYS_EXIT
    mov rdi, EXIT_CODE
    syscall

rd_wr_error:
    mov rax, SYS_WRITE
    mov rdi, STD_OUT
    mov rsi, ERROR_MSG
    mov rdx, 16     ;; msg len
    syscall
    jmp exit
