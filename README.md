# Documentação Técnica: Calculadora Modular em Assembly x86_64 (Linux)

## 1. Visão Geral do Sistema e Arquitetura

Este documento descreve a arquitetura e a implementação de uma calculadora interativa operada via interface de linha de comando (CLI), desenvolvida inteiramente em **Assembly x86_64** para sistemas operacionais baseados em **Linux**.

O sistema destaca-se por uma abordagem puramente nativa: **não é utilizada a biblioteca padrão do C (`libc`)**. Toda a interação com os periféricos de entrada e saída (teclado e tela) e a finalização do processo ocorrem por intermédio de chamadas diretas ao kernel do Linux (*syscalls*).

### Aderência à System V AMD64 ABI

O projeto segue rigorosamente a convenção de chamadas **System V AMD64 ABI**, padrão para sistemas Unix/Linux. Os argumentos para as funções são passados através de registradores específicos antes de qualquer utilização da pilha (*stack*). Abaixo encontra-se a tabela de referência dos registradores utilizados no projeto:

| Registrador | Propósito na Convenção System V AMD64 ABI | Utilização no Projeto |
| --- | --- | --- |
| **`rdi`** | 1º Argumento da função | Passagem de ponteiros de strings ou inteiros a processar. |
| **`rsi`** | 2º Argumento da função | Endereço secundário / Ponteiro de buffer em *syscalls*. |
| **`rdx`** | 3º Argumento da função | Controle de tamanho de buffers / Armazenamento do resto da divisão. |
| **`rax`** | Valor de retorno / Identificador da *Syscall* | Retorno de funções (`atoi`, `readline`) e seleção de operação do kernel. |

---

## 2. Estrutura de Diretórios e Organização do Projeto

O código encontra-se organizado de forma modular, separando a lógica de apresentação e controle das rotinas utilitárias de baixo nível.

```text
calculadora/
├── Makefile                # Gestão de compilação automatizada
└── src/                    # Código-fonte do sistema
    ├── main.asm            # Módulo principal (Controle, Menu e Operações)
    └── lib/       
        └── utils.asm       # Biblioteca estática de I/O e conversão de dados

```

---

## 3. Automação do Fluxo de Compilação (`Makefile`)

O arquivo `Makefile` gerencia o ciclo de vida do software através do montador `nasm` e do ligador (*linker*) `ld`.

```makefile
ASM      := nasm
ASMFLAGS := -f elf64
LD       := ld
LDFLAGS  := -m elf_x86_64
TARGET   := calc

SRCS := src/main.asm src/lib/utils.asm
OBJS := $(patsubst src/%.asm, build/%.o, $(SRCS))

.PHONY: all clean

all: $(TARGET)

$(TARGET): $(OBJS)
	$(LD) $(LDFLAGS) -o $@ $^

build/%.o: src/%.asm
	@mkdir -p $(dir $@)
	$(ASM) $(ASMFLAGS) -o $@ $<

clean:
	rm -rf build $(TARGET)

```

### Análise do Fluxo do `Makefile`:

* **`ASMFLAGS := -f elf64`**: Instrui o `nasm` a gerar arquivos objeto no formato *Executable and Linkable Format* de 64 bits, nativo do Linux.
* **`LDFLAGS := -m elf_x86_64`**: Garante que o utilitário `ld` realize a linkagem em conformidade com a arquitetura x86_64.
* **Função `patsubst**`: Mapeia dinamicamente os arquivos fontes localizados em `src/` para o diretório intermediário `build/`, convertendo as extensões `.asm` para `.o`.
* **`@mkdir -p $(dir $@)`**: Executa a criação automatizada dos subdiretórios dentro de `build/` (neste caso, `build/lib/`) antes do passo de montagem, prevenindo erros de diretório inexistente.

---

## 4. Dissecação da Biblioteca de Utilitários (`src/lib/utils.asm`)

Este arquivo concentra as operações críticas de manipulação de memória, aritmética de conversão e interface direta com o Kernel.

### Declarações Globais e Seção de Dados Voláteis (`.bss`)

```assembly
global print_cstr, atoi_simple, print_int, get_number_from_user

section .bss
    outbuf  resb 32     ; Buffer estático para conversão de inteiros
    inbuf   resb 128    ; Buffer estático para leitura do teclado

```

* **`global`**: Expõe os rótulos de forma pública para que o linker resolva as referências cruzadas vindas do `main.o`.
* **`outbuf resb 32`**: Reserva 32 bytes não inicializados. Um inteiro de 64 bits possui no máximo 20 dígitos decimais; este espaço comporta com folga o número, o sinal negativo, o caractere de nova linha (`\n`) e atua como salvaguarda contra corrupção de memória.

### 4.1. Função `print_cstr` (Impressão de String)

* **Objetivo**: Calcular dinamicamente o tamanho de uma string terminada em nulo (`\0`) e enviá-la para a tela.
* **Mecânica Interna**:
1. O ponteiro original em `rdi` é preservado em `rsi` (exigência da *syscall* `sys_write`).
2. `xor al, al` limpa o registrador `al` para buscar pelo valor `0` (fim da string).
3. `mov rcx, -1` define o contador de repetições para o valor máximo (`0xFFFFFFFFFFFFFFFF`).
4. **A instrução `repne scasb**`: Varre a memória a partir de `rdi`. A cada iteração, compara o byte atual com `al`, incrementa `rdi` e decrementa `rcx`. O loop cessa ao detectar o `\0`.
5. `not rcx` combinado com `dec rcx` converte o valor negativo de `rcx` no comprimento exato da string.
6. Realiza-se um teste de segurança (`test rcx, rcx`). Se a string for vazia, efetua o salto para `.ret`, poupando os ciclos de processamento de uma chamada de sistema.
7. Aciona a chamada ao sistema: `rax = 1` (`sys_write`), `rdi = 1` (`stdout`), com o tamanho contido em `rdx`.



### 4.2. Função `atoi_simple` (ASCII para Inteiro)

* **Objetivo**: Processar uma cadeia de caracteres ASCII e consolidá-la num valor numérico puro de 64 bits.
* **Mecânica Interna**:
* **Preservação de Estado**: `push rbx` protege o registrador `rbx` (característica *callee-saved*). `rbx` armazenará a flag de sinal (1 para negativo, 0 para positivo).
* **`.skip_spaces`**: Salta caracteres de espaço (`32`) e tabulação (`9`), avançando o índice em `r8`.
* **`.sign`**: Avalia se há ocorrência de `-` ou `+`. Caso encontre `-`, incrementa `rbx`.
* **`.loop` (Motor de Conversão Otimizado)**:
1. `movzx rdx, byte [rdi + r8]` lê o caractere expandindo-o com zeros.
2. `sub dl, '0'` converte o caractere ASCII no seu valor numérico correspondente.
3. `cmp dl, 9 / ja .done` valida o limite. Qualquer caractere fora do intervalo numérico quebra o loop.
4. **Otimização Matemática com `lea**`: Em vez de invocar a custosa instrução de multiplicação `mul/imul`, o código executa saltos de endereço de memória simulando aritmética:

$$rax = rax \times 5$$


$$rax = (rax \times 5) \times 2 + rdx = rax \times 10 + rdx$$



Esta substituição reduz drasticamente a latência de *clock* por iteração.


* **Finalização**: Se a flag em `rbx` estiver ativa, a instrução `neg rax` aplica o complemento de dois para tornar o número negativo.



### 4.3. Função `print_int` (Inteiro para ASCII e Impressão)

* **Objetivo**: Efetuar o processo inverso do `atoi`: extrair os dígitos de um valor binário e exibi-los graficamente.
* **Mecânica Interna**:
* **Caso do Zero**: Se `test rax, rax` resultar em zero, injeta diretamente `'0'` e `\n` no buffer, saltando todo o algoritmo de divisão.
* **Sinal**: Valores negativos são positivados temporariamente via `neg rax`, ativando a flag em `rbx`.
* **`.conv` (Extração)**: Divide sucessivamente o número por 10 (`div rbp`). O resto em `rdx` recebe a adição de `'0'` para regressar ao formato ASCII e é depositado em `outbuf`.
* **`.reverse` (Inversão *In-Place*)**: Visto que a divisão extrai o dígito menos significativo primeiro, a string fica invertida na memória (ex: `143` resulta em `"341"`). O código implementa o padrão de "dois ponteiros" (`rbx` no início, `rdx` no fim), trocando os bytes simetricamente até se cruzarem no centro.
* Termina gravando o caractere de nova linha (`10`) e invocando a *syscall* de escrita.



### 4.4. Função `readline` (Leitura Segura do Teclado)

* **Objetivo**: Capturar caracteres enviados pelo usuário através do terminal com blindagem contra estouros.
* **Mecânica Interna**:
* Carrega o endereço com `lea r12, [rel inbuf]`. O prefixo `rel` força o endereçamento relativo ao ponteiro de instrução (*RIP-relative*), requisito vital em binários modernos configurados para PIE (*Position Independent Executable*).
* O loop lê **byte a byte** através da *syscall* `sys_read` (`rax = 0`, `rdi = 0`).
* A verificação `cmp r8, 127` interrompe a leitura ao atingir o limite seguro, garantindo que o buffer de 128 bytes nunca transborde (*Buffer Overflow Prevention*).
* O loop encerra ao interceptar uma quebra de linha (`10`) ou EOF (`rax <= 0`), inserindo no final o byte nulo `0`.



### 4.5. Função `get_number_from_user`

* **Objetivo**: Orquestrar a interface de entrada de dados unindo as primitivas anteriores.
* **Fluxo**: Salva o ponteiro do prompt em `r13`, imprime a mensagem via `print_cstr`, suspende a execução aguardando o input com `readline` e despacha o resultado capturado para o `atoi_simple`. O inteiro final é devolvido no registrador `rax`.

---

## 5. Dissecação do Módulo de Controle (`src/main.asm`)

Este arquivo atua como o *front-end* interativo da calculadora, gerenciando a máquina de estados do menu e a lógica aritmética.

### Seções de Dados e Linkagem Externa

```assembly
extern print_cstr, print_int, get_number_from_user

section .data
    menu_msg    db "=== Calculadora Assembly ===", 10, 0
    ; ...

```

A diretiva `extern` sinaliza ao montador que as implementações dessas rotinas estão em outro arquivo objeto. As constantes na seção `.data` possuem a terminação em `0`, garantindo compatibilidade estrita com a função `print_cstr`.

### 5.1. Rotina `read_menu` (Limpeza de Linha e I/O Robusto)

Resolve o problema clássico do caractere de quebra de linha (`\n`) que fica pendente no buffer do teclado.

* **Fase de Captura (`.get`)**: Lê 1 byte. Se for `10` (`\n`), ele ignora e repete a leitura. O caractere efetivo da opção é isolado em `r12b`.
* **Fase de *Flush* (`.flush`)**: Aciona um loop secundário que continua lendo (e descartando) dados da entrada padrão até encontrar o `10`. Isso limpa o buffer, prevenindo que sujeiras digitadas quebrem a leitura do próximo *prompt*.

### 5.2. Loop Principal (`_start`) e Tabela de Despacho

Após renderizar os menus visuais, a aplicação avalia a entrada do usuário `al`:

```assembly
    cmp  al, '0'
    je   .exit
    cmp  al, '1'
    je   .op_soma
    ; ... (restantes comparações)
    jmp  .loop

```

Funciona como uma estrutura `switch-case`. Se o usuário fornecer uma opção inexistente, a execução "cai" (*fall-through*) para o `jmp .loop`, limpando a tela logicamente e redesenhando o menu do zero.

### 5.3. A Macro de Otimização `%macro read_ab 0`

```assembly
%macro read_ab 0
    lea  rdi, [rel prompt1]
    call get_number_from_user
    mov  r14, rax
    lea  rdi, [rel prompt2]
    call get_number_from_user
    mov  r15, rax
%endmacro

```

* **Design DRY (*Don't Repeat Yourself*)**: Diferente de uma função padrão que causa saltos e usa a pilha (*overhead*), o pré-processador do NASM injeta este bloco de código *inline* em tempo de compilação em todas as chamadas.
* **Registradores de Segurança**: Os operandos são alocados em `r14` (A) e `r15` (B). Como são *callee-saved*, não há risco de seus valores serem corrompidos acidentalmente pelas *syscalls* subsequentes.

### 5.4. Operações Matemáticas e Controle de Exceções

O estado da CPU é validado logo após cada cálculo através do registrador `RFLAGS`.

#### A. Soma, Subtração e Multiplicação

Utilizam `add`, `sub` e `imul` (aritmética com sinal).

```assembly
    add  rax, r15
    jo   .overflow

```

* **Controle de *Overflow***: A instrução `jo` (*Jump on Overflow*) avalia se o cálculo estourou o limite representável em 64 bits com sinal ($[-2^{63}, 2^{63}-1]$). Se a flag ligar, o programa aborta o fluxo principal e imprime um alerta, mantendo a integridade matemática da resposta.

#### B. Divisão e Módulo (Arquitetura de 128 bits)

A instrução `idiv` possui exigências peculiares de pipeline:

```assembly
    test r15, r15
    jz   .divzero
    mov  rax, r14
    cqo
    idiv r15

```

1. **Proteção contra *Crash***: `test r15, r15` e `jz .divzero` interceptam divisores nulos, bloqueando exceções de hardware nativas (*Floating Point Exception* / *Core Dumped*).
2. **Extensão de Sinal (`cqo`)**: A instrução `idiv` consome um registrador virtual de 128 bits concatenado em `rdx:rax`. O comando `cqo` copia o bit de sinal de `rax` preenchendo todos os 64 bits de `rdx`. Omitir o `cqo` causaria resultados caóticos caso houvesse lixo de memória em `rdx`.
3. **Distribuição**: A CPU aloca automaticamente o Quociente em `rax` (usado em `.op_div`) e o Resto em `rdx` (usado em `.op_mod`).

#### C. Potenciação (`.op_pow`)

Implementa um laço iterativo de multiplicações sucessivas.

* **Casos Especiais**:
* Expoentes menores que zero (`jl .neg_exp`) são rejeitados (a calculadora opera com inteiros).
* Expoente igual a zero (`jz .pow_zero_exp`) ignora a lógica e imprime diretamente `1` ($x^0 = 1$).


* O `jo .overflow` é mantido rigorosamente dentro do loop iterativo `imul rax, r14` para abortar imediatamente caso a expansão exponencial atinja o limite durante o processamento.

---

## 6. Fluxo de Execução (Cenário Prático)

Rastreamento de uma operação de **Módulo (Resto)** dos números **14** e **3**:

1. **`_start`**: Imprime o menu e chama `read_menu`.
2. **`read_menu`**: Usuário digita `5` e pressiona `[ENTER]`. Captura o `5`, limpa o `\n` do buffer e retorna.
3. **Despacho**: `cmp al, '5'` é verdadeiro. Salta para `.op_mod`.
4. **`read_ab`**:
* Solicita e lê o primeiro valor (`14`). Armazena em `r14`.
* Solicita e lê o segundo valor (`3`). Armazena em `r15`.


5. **Cálculo em `.op_mod**`:
* Verifica se `r15` é zero. Não é.
* Move `14` para `rax`. Aplica `cqo` (zera `rdx` pois é positivo).
* Executa `idiv r15`.
* A CPU divide 14 por 3. Resultando em Quociente=4 (`rax`) e Resto=2 (`rdx`).


6. **Finalização**: Move o resto de `rdx` para `rdi`. Invoca `print_int`.
7. **`print_int`**: Converte o valor numérico `2` em ASCII, anexa `\n` e executa `sys_write` para exibir o resultado. O programa salta de volta a `.loop`.

---

## 7. Considerações de Segurança e Robustez

1. **Proteção do Contexto da Pilha**: A ABI é rigidamente preservada. Registradores vitais (`rbx`, `r12`, `r13`, `r14`, `r15`) são guardados e repostos via `push/pop` nos escopos das funções, impedindo falhas em cascata de variáveis de estado.
2. **Controle de Interface Interativa**: O expurgo do buffer de teclado (*flush* no menu) e as proteções explícitas de tamanho (`cmp r8, 127` no readline) imunizam o software contra entradas superdimensionadas ou ruídos nos *prompts*.
3. **Resiliência Numérica**: Validações proativas para divisão por zero e interceptação sistemática da flag de *overflow* blindam o fluxo de controle contra interrupções de hardware, garantindo que o software permaneça responsivo frente a dados imprevistos ou fora da escala.

## 8. Manual do Usuário: Compilação e Execução

Esta seção detalha os passos necessários para configurar o ambiente, compilar o código-fonte e operar a calculadora no terminal.

### 8.1. Pré-requisitos do Sistema

Como este projeto utiliza *syscalls* nativas do kernel Linux e a arquitetura x86_64, você precisará de um ambiente Linux. Se estiver no Windows, recomenda-se fortemente o uso do **WSL** (Windows Subsystem for Linux).

Certifique-se de ter as seguintes ferramentas instaladas no seu sistema:

* **NASM** (Netwide Assembler): Para montar o código.
* **Make**: Para ler o `Makefile` e automatizar a compilação.
* **Binutils** (inclui o `ld`): Para a linkagem do executável.

Em distribuições baseadas em Debian/Ubuntu, você pode instalar tudo com um único comando:

```bash
sudo apt update && sudo apt install nasm make binutils

```

### 8.2. Estruturação dos Arquivos

Antes de compilar, garanta que os seus arquivos estão organizados exatamente conforme a árvore abaixo. O `Makefile` depende dessa estrutura para encontrar o código-fonte:

```text
seu_diretorio/
├── Makefile
└── src/
    ├── main.asm
    └── lib/
        └── utils.asm

```

### 8.3. Compilando o Projeto

Abra o terminal, navegue até a raiz do projeto (onde o `Makefile` está localizado) e execute o comando:

```bash
make

```

**O que acontece por baixo dos panos?**

1. O Make criará automaticamente uma pasta chamada `build/`.
2. O NASM compilará `utils.asm` e `main.asm` em arquivos objeto (`.o`).
3. O ligador (`ld`) unirá esses arquivos e gerará um executável binário final chamado **`calc`** na raiz do seu projeto.

### 8.4. Executando a Calculadora

Com o binário compilado, inicie a calculadora executando:

```bash
./calc

```

### 8.5. Passo a Passo de Uso (Exemplo Interativo)

Ao executar o comando acima, a interface será desenhada no seu terminal. Veja um exemplo prático de como realizar uma **Potenciação** (calculando $2^{10}$):

**1. O Menu Principal será exibido:**

```text
=== Calculadora Assembly ===
1) Soma
2) Subtracao
3) Multiplicacao
4) Divisao
5) Resto
6) Potenciacao
0) Sair
Escolha: 

```

**2. Digite a opção desejada e pressione `[ENTER]`:**
Neste caso, digite `6` (Potenciação). O sistema limpará qualquer caractere extra digitado por engano e pedirá os parâmetros.

**3. Inserindo os valores:**
O sistema solicitará a Base. Digite `2` e pressione `[ENTER]`.

```text
Base: 2

```

Em seguida, solicitará o Expoente. Digite `10` e pressione `[ENTER]`.

```text
Expoente: 10

```

**4. Resultado:**
O programa calculará o resultado, imprimirá na tela e, em seguida, exibirá o menu novamente para uma nova operação.

```text
1024
=== Calculadora Assembly ===
1) Soma
...

```

### 8.6. Tratamento de Erros e Limitações

Durante o uso, o sistema o protegerá contra operações matemáticas inválidas. Experimente os seguintes cenários para ver os tratamentos de erro em ação:

* **Divisão por zero:** Escolha a opção `4` (Divisao), insira um número qualquer e depois insira `0`. O sistema exibirá `Erro: divisao por zero` e retornará ao menu.
* **Expoente Negativo:** Na opção `6` (Potenciacao), tente usar um expoente como `-2`. O sistema exibirá `Erro: expoente negativo`.
* **Limites Numéricos (Overflow):** Se você tentar multiplicar ou somar números que ultrapassem o limite de 64 bits com sinal (valores acima de $9.223.372.036.854.775.807$), o sistema exibirá `Erro: overflow` e cancelará a operação para evitar resultados corrompidos.

### 8.7. Limpeza do Ambiente (Clean)

Se você desejar apagar o executável gerado e a pasta de arquivos temporários (`build/`) para empacotar o projeto ou recompilar do zero, basta rodar:

```bash
make clean

```

Isso manterá o seu repositório limpo, deixando apenas o código-fonte original e o `Makefile`.
