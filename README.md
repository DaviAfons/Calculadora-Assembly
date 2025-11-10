# 🧮 Calculadora em Assembly (x86-64)

Este projeto implementa uma **calculadora interativa** escrita em **Assembly NASM (x86-64)** para sistemas **Linux**, com suporte a **operações básicas** de aritmética — soma, subtração, multiplicação e divisão — utilizando **entradas do teclado** e **saídas no terminal** via chamadas de sistema (syscalls).

---

## 📁 Estrutura do Projeto

```
src/
├── main.asm           # Programa principal (menu e lógica da calculadora)
└── lib/
    └── utils.asm      # Biblioteca com funções auxiliares (E/S e conversão)
calc                   # Executável final
main.o                 # Objeto do main.asm
utils.o                # Objeto do utils.asm
makefile               # Script de compilação automática
```

---

## ⚙️ Funcionalidades

* Exibe um **menu interativo** com as opções:

  ```
  Calculadora Assembly
  1) Soma
  2) Subtração
  3) Multiplicação
  4) Divisão
  0) Sair
  ```

* Solicita dois números inteiros do usuário.

* Executa a operação escolhida.

* Exibe o resultado no terminal.

* Trata **divisão por zero**, exibindo mensagem de erro.

* Retorna ao menu após cada operação.

---

## 🧩 Principais Funções

### 📘 `main.asm`

Arquivo principal responsável por:

* Mostrar o menu e ler a opção do usuário.
* Chamar as rotinas da biblioteca (`utils.asm`).
* Executar as operações matemáticas.
* Controlar o fluxo do programa (loop principal e saída).

### ⚙️ `utils.asm`

Biblioteca com funções auxiliares reutilizáveis:

| Função        | Descrição                                                                   |
| ------------- | --------------------------------------------------------------------------- |
| `read_sys`    | Lê entrada do teclado (`sys_read`)                                          |
| `write_sys`   | Escreve texto no terminal (`sys_write`)                                     |
| `print_cstr`  | Imprime uma string terminada em `0`                                         |
| `atoi_simple` | Converte uma string em número inteiro (sem sinal e com suporte a negativos) |
| `print_int`   | Converte um número inteiro para string e imprime                            |

---

## 🧠 Conceitos Envolvidos

* **Manipulação de syscalls** (`read`, `write`, `exit`).
* **Conversão entre texto e número** (ASCII ↔ inteiro).
* **Estruturas de controle** (loops, comparações e saltos).
* **Seções de dados, texto e BSS** (`.data`, `.text`, `.bss`).
* **Passagem de parâmetros via registradores** conforme a ABI System V AMD64.

---

## 🛠️ Compilação e Execução

### 🔧 Pré-requisitos

* Linux (qualquer distribuição compatível com ELF 64 bits)
* [NASM](https://www.nasm.us/) assembler
* [ld](https://man7.org/linux/man-pages/man1/ld.1.html) (linker padrão)

### 💻 Compilar manualmente

```bash
nasm -f elf64 src/lib/utils.asm -o utils.o
nasm -f elf64 src/main.asm -o main.o
ld main.o utils.o -o calc
```

### ▶️ Executar

```bash
./calc
```

---

## 📄 Exemplo de Execução

```
Calculadora Assembly
1) Soma
2) Subtracao
3) Multiplicacao
4) Divisao
0) Sair
Escolha uma opcao: 1
Digite o primeiro inteiro: 5
Digite o segundo inteiro: 7
12

Calculadora Assembly
1) Soma
2) Subtracao
3) Multiplicacao
4) Divisao
0) Sair
Escolha uma opcao: 4
Digite o primeiro inteiro: 9
Digite o segundo inteiro: 0
Erro: divisao por zero
```


## 👨‍💻 Autor

**Davi Afonso**
