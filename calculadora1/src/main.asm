extern read_sys, print_cstr, atoi_simple, print_int

section .data
    menu_msg     db "Calculadora Assembly", 10, 0
    menu_opts    db "1) Soma",10, "2) Subtracao",10, "3) Multiplicacao",10, "4) Divisao",10, "0) Sair",10, 0
    choose_msg   db "Escolha uma opcao: ", 0
    prompt1      db "Digite o primeiro inteiro: ", 0
    prompt2      db "Digite o segundo inteiro: ", 0
    err_div_zero db "Erro: divisao por zero", 10, 0

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
    call read_sys         ; <-- Chama a função da biblioteca
    
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
    jmp main_loop

.op0: ; --- Opção 0: Sair ---
    mov rax, 60
    xor rdi, rdi
    syscall

.op1: ; --- Opção 1: Soma ---
    lea rdi, [rel prompt1]
    call print_cstr
    mov rdi, 0
    lea rsi, [rel inbuf]
    mov rdx, 64
    call read_sys
    lea rdi, [rel inbuf]
    call atoi_simple      ; <-- Chama a função da biblioteca
    mov rbx, rax

    lea rdi, [rel prompt2]
    call print_cstr
    mov rdi, 0
    lea rsi, [rel inbuf]
    mov rdx, 64
    call read_sys
    lea rdi, [rel inbuf]
    call atoi_simple
    
    add rax, rbx
    mov rdi, rax
    call print_int        ; <-- Chama a função da biblioteca
    jmp main_loop

.op2: ; --- Opção 2: Subtração ---
    lea rdi, [rel prompt1]
    call print_cstr
    mov rdi, 0
    lea rsi, [rel inbuf]
    mov rdx, 64
    call read_sys
    lea rdi, [rel inbuf]
    call atoi_simple
    mov rbx, rax

    lea rdi, [rel prompt2]
    call print_cstr
    mov rdi, 0
    lea rsi, [rel inbuf]
    mov rdx, 64
    call read_sys
    lea rdi, [rel inbuf]
    call atoi_simple
    mov rcx, rax
    
    mov rax, rbx
    sub rax, rcx
    mov rdi, rax
    call print_int
    jmp main_loop

.op3: ; --- Opção 3: Multiplicação ---
    lea rdi, [rel prompt1]
    call print_cstr
    mov rdi, 0
    lea rsi, [rel inbuf]
    mov rdx, 64
    call read_sys
    lea rdi, [rel inbuf]
    call atoi_simple
    mov rbx, rax

    lea rdi, [rel prompt2]
    call print_cstr
    mov rdi, 0
    lea rsi, [rel inbuf]
    mov rdx, 64
    call read_sys
    lea rdi, [rel inbuf]
    call atoi_simple
    
    imul rax, rbx
    mov rdi, rax
    call print_int
    jmp main_loop

.op4: ; --- Opção 4: Divisão ---
    lea rdi, [rel prompt1]
    call print_cstr
    mov rdi, 0
    lea rsi, [rel inbuf]
    mov rdx, 64
    call read_sys
    lea rdi, [rel inbuf]
    call atoi_simple
    mov rbx, rax

    lea rdi, [rel prompt2]
    call print_cstr
    mov rdi, 0
    lea rsi, [rel inbuf]
    mov rdx, 64
    call read_sys
    lea rdi, [rel inbuf]
    call atoi_simple
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