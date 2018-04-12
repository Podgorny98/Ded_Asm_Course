%macro read_write 4
    mov rax, %1         ;; sys_call num
    mov rdi, %2         ;; 1st arg (fd)
    mov rsi, %3         ;; 2nd arg (buf pointer)
    mov rdx, %4         ;; 3 arg (bytes count)
    syscall
    cmp rax, -1         ;; check return value
    je rd_wr_error
%endmacro

%macro print_result 0
    ;; calculate num length
    mov rax, rcx                                    ;; nums_qt is in rcx
    mov rdx, 8
    mul rdx
    mov rcx, rax                                    ;; rcx = nums_qt * 8
    read_write SYS_WRITE, STD_OUT, rsp, rcx         ;; print result
    read_write SYS_WRITE, STD_OUT, NEW_LINE, 1      ;; print \n
%endmacro

%macro push_nums 2
    mov rax, [INPUT_CHAR]
    xor rcx, rcx        ;; rcx is nums counter

%%shift_loop:
    mov rbx, %1         ;; %1 - AND_BITS argument
    and rbx, rax        ;; checking bits in rbx
    cmp rbx, 9          ;; for hexadecimal
    jg %%more_than_nine
    add rbx, '0'        ;; current num code
    jmp %%push_loop

%%more_than_nine:
    add rbx, 'A' - 10   ;; current num code

%%push_loop:
    push rbx
    shr rax, %2         ;; %2 - SHIFT argument
    inc rcx
    cmp rax, 0
    jne %%shift_loop
%endmacro

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

section .text
    global _start

_start:
    ;; get char
    read_write SYS_READ, STD_IN, INPUT_CHAR, 1

    ;; to binary
    push_nums BIN_AND_BITS, BIN_SHIFT
    print_result

    ;; to octadecimal
    push_nums OCT_AND_BITS, OCT_SHIFT
    push '0'        ;; octadecimal notation
    inc rcx         ;; for '0'
    print_result

    ;; to hexadecimal
    push_nums HEX_AND_BITS, HEX_SHIFT
    push 'x'        ;; hexadecimal notation
    push '0'
    add rcx, 2      ;; for 'x' and '0'
    print_result

    ;; to decimal
    mov rax, [INPUT_CHAR]
    xor rcx, rcx    ;; rcx is counter
dec_loop:
    mov rdx, 0      ;; numerator is in rdx : rax
    mov rbx, 10
    div rbx         ;; rax = rax / 10
    add rdx, '0'    ;; remainder is in rdx
    push rdx
    inc rcx
    cmp rax, 0
    jne dec_loop
    print_result

exit:
    mov rax, SYS_EXIT
    mov rdi, EXIT_CODE
    syscall

rd_wr_error:
    mov rax, SYS_WRITE
    mov rdi, STD_OUT
    mov rsi, ERROR_MSG
    mov rdx, 16
    syscall
    jmp exit
