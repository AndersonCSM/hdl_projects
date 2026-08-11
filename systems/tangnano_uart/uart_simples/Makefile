# ============================================================================
# Makefile: UART Echo TestBench e Síntese
# Descrição: Compila e roda simulação do UART Echo, e sintetiza para a FPGA
# ============================================================================

# Compilador e simulador
IVERILOG = iverilog
VVP = vvp

# Ferramentas de Síntese
YOSYS = yosys
NEXTPNR = nextpnr-gowin
GOWIN_PACK = gowin_pack
OPENFPGALOADER = openFPGALoader

# Configurações da Placa (Tang Nano 20K)
BOARD = tangnano20k
DEVICE = GW2AR-LV18QN88C8/I7
FAMILY = GW2AR-18
CST_FILE = uart3.cst
JSON_FILE = uart.json
PNR_FILE = uart_pnr.json
FS_FILE = uart.fs

# Diretórios
SIM_DIR = ./

# Arquivos
VERILOG_FILES = top.sv baud_rate_generator.sv uart_rx.sv uart_tx.sv tb_top.sv
SYNTH_FILES = top.sv baud_rate_generator.sv uart_rx.sv uart_tx.sv
TB_FILE = tb_top
EXECUTABLE = $(SIM_DIR)/sim
LOG_FILE = simulation_log.txt

# Flags do compilador
IVERILOG_FLAGS = -g2009 -o $(EXECUTABLE)

# ============================================================================
# REGRAS PRINCIPAIS
# ============================================================================

.PHONY: all run_test clean view_log help build flash

# Compilar e rodar teste (regra padrão)
all: run_test

# Compilar e executar a simulação
run_test: compile
	@echo "=========================================="
	@echo "  Executando simulação..."
	@echo "=========================================="
	$(VVP) $(EXECUTABLE) -n 2>&1 | tee $(LOG_FILE)
	@echo ""
	@echo "Teste concluído! Verifique o arquivo: $(LOG_FILE)"
	@echo ""

# Compilar o testbench
compile: $(VERILOG_FILES)
	@echo "=========================================="
	@echo "  Compilando testbench..."
	@echo "=========================================="
	$(IVERILOG) $(IVERILOG_FLAGS) $^
	@echo "Compilação concluída!"
	@echo ""

# ============================================================================
# REGRAS DE SÍNTESE E GRAVAÇÃO (HARDWARE)
# ============================================================================

# Compilar para a FPGA (Síntese + PNR + Bitstream)
build: $(FS_FILE)

$(FS_FILE): $(SYNTH_FILES) $(CST_FILE)
	@echo "=========================================="
	@echo "  1. Sintetizando com Yosys..."
	@echo "=========================================="
	$(YOSYS) -p "read_verilog -sv $(SYNTH_FILES); synth_gowin -json $(JSON_FILE)"
	@echo ""
	@echo "=========================================="
	@echo "  2. Place and Route com NextPNR..."
	@echo "=========================================="
	$(NEXTPNR) --json $(JSON_FILE) --write $(PNR_FILE) --device $(DEVICE) --cst $(CST_FILE)
	@echo ""
	@echo "=========================================="
	@echo "  3. Gerando Bitstream com Gowin Pack..."
	@echo "=========================================="
	$(GOWIN_PACK) -d $(FAMILY) -o $(FS_FILE) $(PNR_FILE)
	@echo "Build concluído! Arquivo gerado: $(FS_FILE)"
	@echo ""

# Gravar na placa
flash: $(FS_FILE)
	@echo "=========================================="
	@echo "  Gravando na Tang Nano 20K..."
	@echo "=========================================="
	$(OPENFPGALOADER) -b $(BOARD) $(FS_FILE)
	@echo "Gravação concluída!"
	@echo ""

# ============================================================================
# REGRAS DE LIMPEZA E UTILIDADE
# ============================================================================

# Visualizar o arquivo de log
view_log: $(LOG_FILE)
	@echo "=========================================="
	@echo "  Conteúdo do arquivo de log:"
	@echo "=========================================="
	@cat $(LOG_FILE)

# Visualizar apenas o resumo (últimas linhas)
view_summary: $(LOG_FILE)
	@echo "=========================================="
	@echo "  Resumo do teste:"
	@echo "=========================================="
	@tail -20 $(LOG_FILE)

# Limpar arquivos de compilação e síntese temporários
clean:
	@echo "Limpando arquivos temporários..."
	rm -f $(EXECUTABLE)
	rm -f $(LOG_FILE)
	rm -f $(JSON_FILE) $(PNR_FILE)
	@echo "Limpeza concluída!"

# Limpar tudo (incluindo logs e bitstream)
clean_all: clean
	@echo "Removendo todos os arquivos gerados..."
	rm -f $(FS_FILE)

# Mostrar ajuda
help:
	@echo "=========================================="
	@echo "  UART Echo - Makefile Help"
	@echo "=========================================="
	@echo ""
	@echo "Targets disponíveis:"
	@echo ""
	@echo "  make build       - Sintetiza o projeto e gera o bitstream (.fs)"
	@echo "  make flash       - Grava o bitstream gerado na placa FPGA"
	@echo "  make run_test    - Compila e roda a simulação do testbench"
	@echo "  make compile     - Apenas compila o testbench"
	@echo "  make view_log    - Exibe o arquivo de log completo"
	@echo "  make view_summary- Exibe apenas o resumo do teste"
	@echo "  make clean       - Remove arquivos de compilação"
	@echo "  make clean_all   - Remove tudo (compilação + logs + bitstream)"
	@echo "  make help        - Mostra esta mensagem"
	@echo ""
	@echo "Uso típico:"
	@echo "  make build && make flash   # Gerar bitstream e gravar na placa"
	@echo "  make run_test              # Rodar simulação"
	@echo ""

# Sempre executar estas regras (mesmo que o arquivo exista)
.PHONY: all run_test compile clean clean_all view_log view_summary help build flash
