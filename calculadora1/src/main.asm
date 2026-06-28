extern print_cstr, print_int, get_number_from_user

section .data
    menu_msg    db "=== Calculadora Assembly ===", 10, 0
    menu_opts   db "1) Soma", 10,
                db "2) Subtracao", 10,
                db "3) Multiplicacao", 10,
                db "4) Divisao", 10,
                db "5) Resto", 10,
                db "6) Potenciacao", 10,
                db "0) Sair", 10, 0
    choose_msg  db "Escolha: ", 0
    prompt1     db "Primeiro numero: ", 0
    prompt2     db "Segundo numero: ", 0
    prompt_base db "Base: ", 0
    prompt_exp  db "Expoente: ", 0
    err_divzero db "Erro: divisao por zero", 10, 0
    err_overflow db "Erro: overflow", 10, 0
    err_neg_exp db "Erro: expoente negativo", 10, 0

section .bss
    opbuf   resb 4

section .text
global _start

; Lê um char não-newline do stdin e descarta o restante da linha.
; Retorna o char em al (0 = EOF).
read_menu:
    push r12
    xor  r12, r12
.get:
    xor  rdi, rdi
    lea  rsi, [rel opbuf]
    mov  rdx, 1
    xor  rax, rax
    syscall
    test rax, rax
    jle  .done
    mov  r12b, [opbuf]
    cmp  r12b, 10
    je   .get
.flush:
    xor  rdi, rdi
    lea  rsi, [rel opbuf]
    mov  rdx, 1
    xor  rax, rax
    syscall
    test rax, rax
    jle  .done
    cmp  byte [opbuf], 10
    jne  .flush
.done:
    mov  al, r12b
    pop  r12
    ret

_start:
.loop:
    lea  rdi, [rel menu_msg]
    call print_cstr
    lea  rdi, [rel menu_opts]
    call print_cstr
    lea  rdi, [rel choose_msg]
    call print_cstr
    call read_menu

    cmp  al, '0'
    je   .exit
    cmp  al, '1'
    je   .op_soma
    cmp  al, '2'
    je   .op_sub
    cmp  al, '3'
    je   .op_mul
    cmp  al, '4'
    je   .op_div
    cmp  al, '5'
    je   .op_mod
    cmp  al, '6'
    je   .op_pow
    jmp  .loop

.exit:
    mov  rax, 60
    xor  rdi, rdi
    syscall

; ── Lê dois operandos e guarda em r14 (A) e r15 (B) ──────────────────────────
; Macro inline — usado por soma, sub, mul, div, mod.
%macro read_ab 0
    lea  rdi, [rel prompt1]
    call get_number_from_user
    mov  r14, rax
    lea  rdi, [rel prompt2]
    call get_number_from_user
    mov  r15, rax
%endmacro

.op_soma:
    read_ab
    mov  rax, r14
    add  rax, r15
    jo   .overflow
    mov  rdi, rax
    call print_int
    jmp  .loop

.op_sub:
    read_ab
    mov  rax, r14
    sub  rax, r15
    jo   .overflow
    mov  rdi, rax
    call print_int
    jmp  .loop

.op_mul:
    read_ab
    mov  rax, r14
    imul rax, r15
    jo   .overflow
    mov  rdi, rax
    call print_int
    jmp  .loop

.op_div:
    read_ab
    test r15, r15
    jz   .divzero
    mov  rax, r14
    cqo
    idiv r15
    mov  rdi, rax
    call print_int
    jmp  .loop

.op_mod:
    read_ab
    test r15, r15
    jz   .divzero
    mov  rax, r14
    cqo
    idiv r15
    mov  rdi, rdx           ; rdx = resto da divisão
    call print_int
    jmp  .loop

.op_pow:
    lea  rdi, [rel prompt_base]
    call get_number_from_user
    mov  r14, rax           ; r14 = base

    lea  rdi, [rel prompt_exp]
    call get_number_from_user
    mov  r15, rax           ; r15 = expoente

    test r15, r15
    jl   .neg_exp
    jz   .pow_zero_exp      ; base^0 = 1

    mov  rax, 1
    mov  r13, r15           ; contador
.pow_loop:
    imul rax, r14
    jo   .overflow
    dec  r13
    jnz  .pow_loop

    mov  rdi, rax
    call print_int
    jmp  .loop

.pow_zero_exp:
    mov  rdi, 1
    call print_int
    jmp  .loop

; ── Tratamento de erros ───────────────────────────────────────────────────────
.divzero:
    lea  rdi, [rel err_divzero]
    call print_cstr
    jmp  .loop

.overflow:
    lea  rdi, [rel err_overflow]
    call print_cstr
    jmp  .loop

.neg_exp:
    lea  rdi, [rel err_neg_exp]
    call print_cstr
    jmp  .loop
