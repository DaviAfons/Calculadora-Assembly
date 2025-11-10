# 🧮 Calculadora em Assembly (x86-64)

Uma **calculadora simples de console** escrita em **Assembly NASM (x86-64)** para **Linux**.

Este projeto é um **exercício de estudo** para demonstrar os fundamentos da programação em Assembly, incluindo:
- Interação com o kernel (syscalls)
- Manipulação de strings
- Conversão de tipos numéricos
- Estruturação de um projeto em múltiplos arquivos
- Modularização e reutilização de código

---

## 🚀 Como Rodar

Este projeto foi desenvolvido e testado em um ambiente **Linux (Ubuntu)** e depende das ferramentas de build `make`, `nasm` e `ld`.

### 🧰 1. Pré-requisitos

Instale as ferramentas necessárias:
```bash
sudo apt update
sudo apt install make nasm binutils
````

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

---

## 📁 Estrutura do Projeto

```
.
├── Makefile             # Orquestra a compilação
└── src/
    ├── main.asm         # Ponto de entrada, menu e lógica das operações
    └── lib/
        └── utils.asm    # Funções de biblioteca (E/S, conversões)
```

Arquivos adicionais após a compilação:

```
calc       # Executável final
main.o     # Objeto de main.asm
utils.o    # Objeto de utils.asm
```

---

## 🧩 Lógica e Estrutura do Programa

O programa foi dividido em dois módulos principais e um Makefile, com o objetivo de tornar o código mais organizado e legível.

---

### 1️⃣ `src/main.asm` — O Cérebro da Aplicação

Este arquivo contém o ponto de entrada (`_start`), o menu e a lógica das operações.

#### Estrutura principal

* **Seção `.data`** — mensagens e textos constantes (menu, prompts, mensagens de erro).
* **Seção `.bss`** — reserva de memória (`inbuf`) para leitura da entrada.
* **Seção `.text`** — código executável.

#### Loop principal (`main_loop`)

1. Mostra o menu no console (`print_cstr`).
2. Lê a opção do usuário (`read_sys`).
3. Compara o caractere digitado (`cmp` e `je`) e salta para a operação correspondente.
4. Após o cálculo, retorna ao menu.

#### Operações disponíveis

| Opção | Operação      | Instrução         | Observação                                        |
| ----- | ------------- | ----------------- | ------------------------------------------------- |
| 1     | Soma          | `add`             | Soma dois inteiros                                |
| 2     | Subtração     | `sub`             | Subtrai o segundo do primeiro                     |
| 3     | Multiplicação | `imul`            | Multiplica dois inteiros                          |
| 4     | Divisão       | `idiv`            | Divide com tratamento de erro se divisor for zero |
| 0     | Sair          | syscall `exit(0)` | Encerra o programa                                |

Cada bloco `.opX`:

1. Pede o primeiro número (`prompt1`).
2. Lê e converte para inteiro (`read_sys` + `atoi_simple`).
3. Pede o segundo número (`prompt2`) e faz o mesmo.
4. Executa a operação aritmética.
5. Imprime o resultado (`print_int`).
6. Retorna ao `main_loop`.

---

### 2️⃣ `src/lib/utils.asm` — Biblioteca de Funções Auxiliares

Este arquivo implementa as funções básicas usadas por `main.asm`.
As funções são exportadas com `global` e importadas com `extern`.

| Função        | Descrição                                                           |
| ------------- | ------------------------------------------------------------------- |
| `read_sys`    | Wrapper para syscall `read(0, buffer, len)` — lê entrada do usuário |
| `write_sys`   | Wrapper para syscall `write(fd, buffer, len)` — escreve no terminal |
| `print_cstr`  | Imprime uma string terminada em `0` (estilo C)                      |
| `atoi_simple` | Converte string em número inteiro (suporta negativos)               |
| `print_int`   | Converte um inteiro para string e imprime no terminal               |

#### 🔍 Detalhes das principais funções:

* **`print_cstr`**
  Calcula o tamanho da string até o byte nulo (`0`) e a imprime via syscall `write`.

* **`atoi_simple`**

  * Ignora espaços em branco.
  * Detecta sinal `-` ou `+`.
  * Converte caractere por caractere de ASCII para número (`'0'` a `'9'`).
  * Multiplica o acumulador por 10 a cada novo dígito para formar o número completo.

* **`print_int`**

  * Divide o valor por 10 repetidamente para extrair os dígitos (restos da divisão).
  * Armazena-os no buffer `outbuf` em ordem inversa.
  * Inverte o conteúdo para a ordem correta antes de imprimir.
  * Adiciona `'\n'` ao final.

---

### 3️⃣ `Makefile` — O Construtor Automático

O `Makefile` automatiza a compilação e o link:

#### Regras típicas:

```makefile
all: calc

calc: main.o utils.o
	ld main.o utils.o -o calc

main.o: src/main.asm
	nasm -f elf64 src/main.asm -o main.o

utils.o: src/lib/utils.asm
	nasm -f elf64 src/lib/utils.asm -o utils.o

clean:
	rm -f *.o calc
```

* **`make`** — compila e gera o executável `calc`.
* **`make clean`** — remove binários e objetos antigos.

---

## 💻 Exemplo de Execução

```text
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

---

## 🧠 Conceitos Envolvidos

* Syscalls Linux (`read`, `write`, `exit`)
* Manipulação de buffers e strings
* Conversão ASCII ↔ Inteiro
* Estruturação modular em Assembly
* Convenção de chamadas System V AMD64 (uso de registradores)
* Controle de fluxo (`cmp`, `jmp`, `je`, `jne`, etc.)

---

## 👨‍💻 Autor

**Davi Afonso**
