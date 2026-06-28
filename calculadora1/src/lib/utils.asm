global print_cstr, atoi_simple, print_int, get_number_from_user

section .bss
    outbuf  resb 32     ; max 20 dígitos + sinal + newline para int64
    inbuf   resb 128

section .text

; ─── print_cstr(rdi = ptr null-terminated) ────────────────────────────────────
; Calcula strlen via repne scasb e emite sys_write(stdout).
print_cstr:
    mov  rsi, rdi
    xor  al, al
    mov  rcx, -1
    repne scasb         ; rcx = -(len+2) após encontrar '\0'
    not  rcx
    dec  rcx            ; rcx = strlen
    test rcx, rcx
    jz   .ret
    mov  rdx, rcx
    mov  rax, 1
    mov  rdi, 1
    syscall
.ret:
    ret

; ─── atoi_simple(rdi = ptr string) → rax = int64 ─────────────────────────────
; Pula espaços/tabs, aceita sinal '+'/'-', converte dígitos decimais.
atoi_simple:
    push rbx
    xor  rbx, rbx       ; flag: 1 = negativo
    xor  r8, r8         ; índice na string

.skip_spaces:
    mov  al, [rdi + r8]
    cmp  al, ' '
    je   .next_s
    cmp  al, 9          ; tab
    jne  .sign
.next_s:
    inc  r8
    jmp  .skip_spaces

.sign:
    cmp  al, '-'
    jne  .chk_plus
    inc  rbx
    inc  r8
    jmp  .digits
.chk_plus:
    cmp  al, '+'
    jne  .digits
    inc  r8

.digits:
    xor  rax, rax
.loop:
    movzx rdx, byte [rdi + r8]
    sub  dl, '0'
    cmp  dl, 9              ; unsigned: termina se fora de '0'..'9'
    ja   .done
    lea  rax, [rax*4 + rax] ; rax *= 5
    lea  rax, [rax*2 + rdx] ; rax = rax*10 + digit
    inc  r8
    jmp  .loop

.done:
    test rbx, rbx
    jz   .ret
    neg  rax
.ret:
    pop  rbx
    ret

; ─── print_int(rdi = int64) ───────────────────────────────────────────────────
; Converte para decimal em outbuf (estático, não reentrante) e imprime.
print_int:
    push rbx
    push rbp

    mov  rax, rdi
    lea  rsi, [rel outbuf]
    xor  r8, r8         ; contador de dígitos (r8 ≠ rcx/r11, sobrevive syscall)

    test rax, rax
    jnz  .not_zero
    mov  byte [rsi],   '0'
    mov  byte [rsi+1], 10   ; '\n'
    mov  rdx, 2
    jmp  .emit

.not_zero:
    xor  rbx, rbx       ; flag de sinal
    jns  .positive
    neg  rax
    inc  rbx

.positive:
    mov  rbp, 10        ; divisor (callee-saved → sobrevive ao loop)
.conv:
    xor  rdx, rdx
    div  rbp
    add  dl, '0'
    mov  [rsi + r8], dl
    inc  r8
    test rax, rax
    jnz  .conv

    test rbx, rbx
    jz   .reverse
    mov  byte [rsi + r8], '-'
    inc  r8

.reverse:
    ; inverte outbuf[0..r8-1] in-place
    xor  rbx, rbx
    lea  rdx, [r8 - 1]
.rev:
    cmp  rbx, rdx
    jge  .rev_done
    mov  al,  [rsi + rbx]
    mov  bpl, [rsi + rdx]
    mov  [rsi + rbx], bpl
    mov  [rsi + rdx], al
    inc  rbx
    dec  rdx
    jmp  .rev

.rev_done:
    mov  byte [rsi + r8], 10    ; '\n'
    inc  r8
    mov  rdx, r8

.emit:
    mov  rax, 1
    mov  rdi, 1
    syscall

    pop  rbp
    pop  rbx
    ret

; ─── readline → lê uma linha de stdin em inbuf, null-terminated ───────────────
; Lê byte a byte até '\n' ou EOF. Usa r8 como índice (sobrevive syscall).
readline:
    push rbx
    push r12
    lea  r12, [rel inbuf]   ; base do buffer (r12 callee-saved)
    xor  r8, r8             ; índice
.rd_loop:
    cmp  r8, 127
    jge  .rd_done
    lea  rsi, [r12 + r8]
    xor  rdi, rdi           ; stdin
    mov  rdx, 1
    xor  rax, rax
    syscall                 ; rcx e r11 são destruídos aqui — r8/r12 preservados pois são callee-saved
    test rax, rax           ; 0 = EOF
    jle  .rd_done
    mov  bl, [r12 + r8]     ; bl = byte lido
    cmp  bl, 10             ; '\n'
    je   .rd_done
    inc  r8
    jmp  .rd_loop
.rd_done:
    mov  byte [r12 + r8], 0 ; null-termina
    pop  r12
    pop  rbx
    ret

; ─── get_number_from_user(rdi = ptr prompt) → rax = int64 ────────────────────
get_number_from_user:
    push r13
    mov  r13, rdi           ; preserva prompt (r13 callee-saved)
    mov  rdi, r13
    call print_cstr
    call readline
    lea  rdi, [rel inbuf]
    call atoi_simple        ; resultado em rax
    pop  r13
    ret
