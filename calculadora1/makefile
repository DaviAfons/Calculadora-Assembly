# Define o nome do assembler (NASM) e do linker (LD)
ASM = nasm
LDFLAGS = -m elf_x86_64
ASFLAGS = -f elf64 -g

# Nome do executável final
TARGET = calc

# Define os arquivos de objeto (compilados)
OBJS = main.o utils.o

# "all" é o alvo padrão: compila e linka o projeto
all: $(TARGET)

# Alvo para linkar o executável final
$(TARGET): $(OBJS)
	ld $(LDFLAGS) -o $(TARGET) $(OBJS)

# Regra para compilar main.asm em main.o
main.o: src/main.asm
	$(ASM) $(ASFLAGS) -o main.o src/main.asm

# Regra para compilar utils.asm em utils.o
utils.o: src/lib/utils.asm
	$(ASM) $(ASFLAGS) -o utils.o src/lib/utils.asm

# Alvo "clean" para limpar os arquivos compilados
clean:
	rm -f $(TARGET) $(OBJS)