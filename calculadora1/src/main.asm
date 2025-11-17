extern read_sys, print_cstr, atoi_simple, print_int, get_number_from_user

section .data
    menu_msg     db "Calculadora Assembly", 10, 0
    menu_opts    db "1) Soma",10, "2) Subtracao",10, "3) Multiplicacao",10, "4) Divisao",10, "5) Resto",10, "6) Potenciacao",10, "0) Sair",10, 0
    choose_msg   db "Escolha uma opcao: ", 0
    prompt1      db "Digite o primeiro inteiro: ", 0
    prompt2      db "Digite o segundo inteiro: ", 0
    prompt_base  db "Digite a base: ", 0
    prompt_exp   db "Digite o expoente: ", 0
    err_div_zero db "Erro: divisao por zero", 10, 0
    err_overflow db "Erro: Resultado muito grande (Overflow)", 10, 0
    err_neg_exp  db "Erro: Expoente nao pode ser negativo", 10, 0

section .bss
inbuf   resb 128

section .text
global _start

_start:
main_loop:
    lea rdi, [rel menu_msg]
    call print_cstr
    lea rdi, [rel menu_opts]
    call print_cstr
    lea rdi, [rel choose_msg]
    call print_cstr
    
   mov rdi, 0
    lea rsi, [rel inbuf]
    mov rdx, 8
    call read_sys
    
    mov al, [inbuf]
    cmp al, '0'
    je .op0
    cmp al, '1'
    je .op1
    cmp al, '2'
    je .op2
    cmp al, '3'
    je .op3
    cmp al, '4'
    je .op4
    cmp al, '5'
    je .op5
    cmp al, '6'
    je .op6
    jmp main_loop

.op0:
    mov rax, 60
    xor rdi, rdi
    syscall

.op1:
    lea rdi, [rel prompt1]
    call get_number_from_user
    mov rbx, rax

    lea rdi, [rel prompt2]
    call get_number_from_user
    
    add rax, rbx
    jo .op_error_overflow
    mov rdi, rax
    call print_int
    jmp main_loop

.op2:
    lea rdi, [rel prompt1]
    call get_number_from_user
    mov rbx, rax

    lea rdi, [rel prompt2]
    call get_number_from_user
    mov rcx, rax
    
    mov rax, rbx
    sub rax, rcx
    jo .op_error_overflow
    mov rdi, rax
    call print_int
    jmp main_loop
    
.op3:
    lea rdi, [rel prompt1]
    call get_number_from_user
    mov rbx, rax

    lea rdi, [rel prompt2]
    call get_number_from_user
    mov rcx, rax
    
    imul rax, rbx
    jo .op_error_overflow
    mov rdi, rax
    call print_int
    jmp main_loop

.op4:
    lea rdi, [rel prompt1]
    call get_number_from_user
    mov rbx, rax

    lea rdi, [rel prompt2]
    call get_number_from_user
    mov rcx, rax

    cmp rcx, 0
    jne .do_div
    lea rdi, [rel err_div_zero]
    call print_cstr
    jmp main_loop

.do_div:
    mov rax, rbx
    cqo
    idiv rcx
    mov rdi, rax
    call print_int
    jmp main_loop

.op5:
    lea rdi, [rel prompt1]
    call get_number_from_user
    mov rbx, rax

    lea rdi, [rel prompt2]
    call get_number_from_user
    mov rcx, rax

    cmp rcx, 0
    jne .do_mod
    lea rdi, [rel err_div_zero]
    call print_cstr
    jmp main_loop

.do_mod:
    mov rax, rbx
    cqo
    idiv rcx
    mov rdi, rdx
    call print_int
    jmp main_loop

.op_error_overflow:
    lea rdi, [rel err_overflow]
    call print_cstr
    jmp main_loop

.op6:
    lea rdi, [rel prompt_base]
    call get_number_from_user
    mov rbx, rax

    lea rdi, [rel prompt_exp]
    call get_number_from_user
    mov rcx, rax

    cmp rcx, 0
    jl .pow_error_negative

    cmp rcx, 0
    je .pow_is_one

    mov rax, 1
    
.pow_loop:
    imul rax, rbx
    jo .op_error_overflow
    loop .pow_loop

    mov rdi, rax
    call print_int
    jmp main_loop

.pow_is_one:
    mov rax, 1
    mov rdi, rax
    call print_int
    jmp main_loop

.pow_error_negative:
    lea rdi, [rel err_neg_exp]
    call print_cstr
    jmp main_loop