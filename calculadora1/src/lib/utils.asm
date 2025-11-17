global write_sys, read_sys, print_cstr, atoi_simple, print_int, get_number_from_user 

section .bss
outbuf       resb 128
inbuf_util   resb 128  

section .text

write_sys:
    mov rax, 1
    syscall
    ret

read_sys:
    mov rax, 0
    syscall
    ret

print_cstr:
    push rsi
    push rdx
    mov rsi, rdi
    xor rcx, rcx
.find_nl:
    mov al, [rsi + rcx]
    cmp al, 0
    je .found_len
    inc rcx
    jmp .find_nl
.found_len:
    mov rdx, rcx
    mov rax, 1
    mov rdi, 1
    mov rsi, rsi
    syscall
    pop rdx
    pop rsi
    ret

atoi_simple:
    push rbp
    mov rbp, rsp
    push rbx
    push rcx
    push rdx
    mov rcx, 0
    mov rax, 0
    mov rbx, 1
.skip_spaces:
    mov bl, [rdi + rcx]
    cmp bl, ' '
    je .inc_i
    cmp bl, 9
    je .inc_i
    jmp .parse_sign
.inc_i:
    inc rcx
    jmp .skip_spaces
.parse_sign:
    mov bl, [rdi + rcx]
    cmp bl, '-'
    jne .check_plus
    mov rbx, -1
    inc rcx
    jmp .parse_digits
.check_plus:
    cmp bl, '+'
    jne .parse_digits
    inc rcx
.parse_digits:
    mov bl, [rdi + rcx]
    cmp bl, 0
    je .atoi_done
    cmp bl, '0'
    jb .atoi_done
    cmp bl, '9'
    ja .atoi_done
    
    mov rdx, rax
    shl rax, 3
    lea rax, [rax + rdx*2]
    
    movzx rdx, bl
    sub rdx, '0'
    add rax, rdx
    inc rcx
    jmp .parse_digits
.atoi_done:
    cmp rbx, -1
    jne .ret_ok
    neg rax
.ret_ok:
    pop rdx
    pop rcx
    pop rbx
    pop rbp
    ret

print_int:
    push rbp
    mov rbp, rsp
    push rbx
    push rcx
    push rdx
    push rsi
    push rdi
    push r8

    mov rax, rdi
    mov rsi, outbuf   
    xor rcx, rcx

    cmp rax, 0
    jne .not_zero
    mov byte [rsi], '0'
    inc rcx
    jmp .print_done_conv

.not_zero:
    xor rbx, rbx
    cmp rax, 0
    jge .positive
    neg rax
    mov rbx, 1
.positive:

.conv_loop:
    xor rdx, rdx
    mov r8, 10
    div r8
    add dl, '0'
    mov [outbuf + rcx], dl
    inc rcx
    cmp rax, 0
    jne .conv_loop

    cmp rbx, 1
    jne .print_done_conv
    mov byte [outbuf + rcx], '-'
    inc rcx

.print_done_conv:
    xor rbx, rbx
    mov rdx, rcx
    dec rdx

.rev_loop:
    cmp rbx, rdx
    jge .rev_done

    mov al, [outbuf + rbx]
    mov r8b, [outbuf + rdx]
    mov [outbuf + rbx], r8b
    mov [outbuf + rdx], al

    inc rbx
    dec rdx
    jmp .rev_loop

.rev_done:
    mov byte [outbuf + rcx], 10
    inc rcx

    mov rdx, rcx
    mov rax, 1
    mov rdi, 1
    mov rsi, outbuf
    syscall

    pop r8
    pop rdi
    pop rsi
    pop rdx
    pop rcx
    pop rbx
    pop rbp
    ret

    get_number_from_user:
    push rbp
    mov rbp, rsp
    push rbx
    push rcx
    push rdx
    push rsi
    push r12

    mov r12, rdi         
    mov rdi, r12       
    call print_cstr     
    mov rdi, 0          
    lea rsi, [rel inbuf_util] 
    mov rdx, 64         
    call read_sys       

    lea rdi, [rel inbuf_util] 
    call atoi_simple     
    pop r12
    pop rsi
    pop rdx
    pop rcx
    pop rbx
    pop rbp
    ret