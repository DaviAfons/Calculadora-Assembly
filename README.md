Aqui está o `README.md` atualizado, refletindo as novas operações (Resto, Potenciação), a refatoração (com `get_number_from_user`) e o tratamento de erros (Overflow, Expoente Negativo).

-----

# 🧮 Calculadora em Assembly (x86-64)

Uma **calculadora simples de console** escrita em **Assembly NASM (x86-64)** para **Linux**.

Este projeto é um **exercício de estudo** para demonstrar os fundamentos da programação em Assembly, incluindo:

  - Interação com o kernel (syscalls)
  - Manipulação de strings
  - Conversão de tipos numéricos
  - Estruturação de um projeto em múltiplos arquivos
  - Modularização e reutilização de código
  - Tratamento de erros (Divisão por zero, Overflow)

-----

## 🚀 Como Rodar

Este projeto foi desenvolvido e testado em um ambiente **Linux (Ubuntu)** e depende das ferramentas de build `make`, `nasm` e `ld`.

### 🧰 1. Pré-requisitos

Instale as ferramentas necessárias:

```bash
sudo apt update
sudo apt install make nasm binutils
```

### ⚙️ 2. Compilação

Com as ferramentas instaladas, basta usar o `Makefile` para compilar o projeto.
No diretório raiz do projeto, execute:

```bash
make
```

O comando irá:

  * Montar os arquivos `.asm` em `.o`
  * Lincar (`ld`) os objetos em um executável final chamado `calc`

### ▶️ 3. Execução

Após a compilação, execute:

```bash
./calc
```

Você verá o menu principal da calculadora.

-----

## 📁 Estrutura do Projeto

```
.
├── Makefile            # Orquestra a compilação
└── src/
    ├── main.asm        # Ponto de entrada, menu e lógica das operações
    └── lib/
        └── utils.asm   # Funções de biblioteca (E/S, conversões)
```

Arquivos adicionais após a compilação:

```
calc        # Executável final
main.o      # Objeto de main.asm
utils.o     # Objeto de utils.asm
```

-----

## 🧩 Lógica e Estrutura do Programa

O programa foi dividido em dois módulos principais e um Makefile, com o objetivo de tornar o código mais organizado e legível.

-----

### 1️⃣ `src/main.asm` — O Cérebro da Aplicação

Este arquivo contém o ponto de entrada (`_start`), o menu e a lógica das operações.

#### Estrutura principal

  * **Seção `.data`** — mensagens e textos constantes (menu, prompts, mensagens de erro).
  * **Seção `.bss`** — reserva de memória (`inbuf`) para leitura da opção do menu.
  * **Seção `.text`** — código executável.

#### Loop principal (`main_loop`)

1.  Mostra o menu no console (`print_cstr`).
2.  Lê a opção do usuário (`read_sys`).
3.  Compara o caractere digitado (`cmp` e `je`) e salta para a operação correspondente.
4.  Após o cálculo, retorna ao menu.

#### Tratamento de Erros

O programa agora inclui verificação de erros para:

  * **Divisão por Zero:** (em `idiv`)
  * **Overflow Aritmético:** (usando `jo` após `add`, `sub`, `imul`)
  * **Expoente Negativo:** (na operação de potenciação)

#### Operações disponíveis

| Opção | Operação | Instrução | Observação |
| --- | --- | --- | --- |
| 1 | Soma | `add` | Soma dois inteiros |
| 2 | Subtração | `sub` | Subtrai o segundo do primeiro |
| 3 | Multiplicação | `imul` | Multiplica dois inteiros |
| 4 | Divisão | `idiv` | Divide. Tratamento de erro se divisor for zero |
| **5** | **Resto (Modulus)** | `idiv` | Retorna o resto (de `rdx`). Tratamento de erro se divisor for zero |
| **6** | **Potenciação** | `imul` (em loop) | `Base ^ Expoente`. Tratamento de erro se expoente for negativo |
| 0 | Sair | syscall `exit(0)` | Encerra o programa |

Cada bloco `.opX` agora usa a função `get_number_from_user` para obter os operandos antes de executar a lógica.

-----

### 2️⃣ `src/lib/utils.asm` — Biblioteca de Funções Auxiliares

Este arquivo implementa as funções básicas usadas por `main.asm`.
As funções são exportadas com `global` e importadas com `extern`.

| Função | Descrição |
| --- | --- |
| `read_sys` | Wrapper para syscall `read(0, buffer, len)` — lê entrada do usuário |
| `write_sys` | Wrapper para syscall `write(fd, buffer, len)` — escreve no terminal |
| `print_cstr` | Imprime uma string terminada em `0` (estilo C) |
| `atoi_simple` | Converte string em número inteiro (suporta negativos) |
| `print_int` | Converte um inteiro para string e imprime no terminal |
| **`get_number_from_user`** | **Combina `print_cstr`, `read_sys` e `atoi_simple` para pedir e retornar um número.** |

#### 🔍 Detalhes das principais funções:

  * **`print_cstr`**
    Calcula o tamanho da string até o byte nulo (`0`) e a imprime via syscall `write`.

  * **`atoi_simple`**
    Ignora espaços, detecta sinal `-` ou `+`, e converte dígitos ASCII para inteiro (multiplicando o acumulador por 10).

  * **`print_int`**
    Divide o valor por 10 repetidamente, armazena os dígitos (resto) em um buffer e depois os inverte para a ordem correta antes de imprimir.

-----

### 3️⃣ `Makefile` — O Construtor Automático

O `Makefile` automatiza a compilação e o link:

#### Regras típicas:

```makefile
all: calc

calc: main.o utils.o
    ld main.o utils.o -o calc

main.o: src/main.asm
    nasm -f elf64 -g src/main.asm -o main.o

utils.o: src/lib/utils.asm
    nasm -f elf64 -g src/lib/utils.asm -o utils.o

clean:
    rm -f *.o calc
```

  * **`make`** — compila e gera o executável `calc`.
  * **`make clean`** — remove binários e objetos antigos.

-----

## 💻 Exemplo de Execução

```text
Calculadora Assembly
1) Soma
2) Subtracao
3) Multiplicacao
4) Divisao
5) Resto
6) Potenciacao
0) Sair
Escolha uma opcao: 6
Digite a base: 5
Digite o expoente: 3
125

Calculadora Assembly
1) Soma
2) Subtracao
3) Multiplicacao
4) Divisao
5) Resto
6) Potenciacao
0) Sair
Escolha uma opcao: 5
Digite o primeiro inteiro: 10
Digite o segundo inteiro: 3
1

Calculadora Assembly
1) Soma
2) Subtracao
3) Multiplicacao
4) Divisao
5) Resto
6) Potenciacao
0) Sair
Escolha uma opcao: 4
Digite o primeiro inteiro: 9
Digite o segundo inteiro: 0
Erro: divisao por zero
```

-----

## 🧠 Conceitos Envolvidos

  * Syscalls Linux (`read`, `write`, `exit`)
  * Manipulação de buffers e strings
  * Conversão ASCII ↔ Inteiro
  * Estruturação modular em Assembly
  * Convenção de chamadas System V AMD64 (uso de registradores)
  * Controle de fluxo (`cmp`, `jmp`, `je`, `jne`, `loop`)
  * Tratamento de Flags (Overflow Flag - `OF`)

-----

## 👨‍💻 Autor

**Davi Afonso**
