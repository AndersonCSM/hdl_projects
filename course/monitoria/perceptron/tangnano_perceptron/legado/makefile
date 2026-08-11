BOARD=tangnano1k
FAMILY=GW1NZ-1
DEVICE=GW1NZ-LV1QN48C6/I5
FILE=top

# ═══════════════════════════════════════════════════════════════════════════════
# ALVOS PRINCIPAIS
# ═══════════════════════════════════════════════════════════════════════════════

.PHONY: all sim sim-compile sim-run sim-view sim-clean sim-all help

all:	$(FILE).fs

# Help - mostrar alvos disponíveis
help:
	@echo "╔════════════════════════════════════════════════════════════════════╗"
	@echo "║              Makefile: Perceptron Tang Nano 1K                    ║"
	@echo "╚════════════════════════════════════════════════════════════════════╝"
	@echo ""
	@echo "ALVOS DE SÍNTESE (para FPGA):"
	@echo "  make all         - Síntese completa (json → pnr → fs)"
	@echo "  make synth       - Apenas síntese (Yosys)"
	@echo "  make pnr         - Apenas place & route (nextpnr)"
	@echo "  make bitstream   - Apenas geração de bitstream"
	@echo "  make loadram     - Programar placa via USB"
	@echo "  make clean       - Remover arquivos de síntese"
	@echo ""
	@echo "ALVOS DE SIMULAÇÃO (com iverilog/GTKWave):"
	@echo "  make sim         - Simular tudo (compile → run → view)"
	@echo "  make sim-compile - Compilar testbench com iverilog"
	@echo "  make sim-run     - Executar simulação (gera sim.vcd)"
	@echo "  make sim-view    - Abrir GTKWave com waveform"
	@echo "  make sim-clean   - Remover arquivos de simulação"
	@echo ""
	@echo "EXEMPLOS:"
	@echo "  make all         # Compilar tudo para FPGA"
	@echo "  make sim         # Simular e visualizar"
	@echo "  make sim-compile # Apenas compilar"
	@echo "  make sim-run     # Apenas simular"
	@echo ""

# Synthesis
$(FILE).json: $(FILE).v control.v datapath.v
	yosys -p "read_verilog $(FILE).v control.v datapath.v; synth_gowin -top $(FILE) -json $(FILE).json"

# Place and Route
$(FILE)_pnr.json: $(FILE).json
	nextpnr-gowin --json $(FILE).json --write $(FILE)_pnr.json --freq 27 --device ${DEVICE} --family ${FAMILY} --cst ${BOARD}.cst

# Generate Bitstream
$(FILE).fs: $(FILE)_pnr.json
	gowin_pack -d ${FAMILY} -o $(FILE).fs $(FILE)_pnr.json

# Program Board
loadram: $(FILE).fs
	sudo openFPGALoader -b ${BOARD} $(FILE).fs -m

# ═══════════════════════════════════════════════════════════════════════════════
# ALVOS DE SÍNTESE (resumo)
# ═══════════════════════════════════════════════════════════════════════════════

.PHONY: synth pnr bitstream

synth: $(FILE).json
	@echo "✓ Síntese concluída: $(FILE).json"

pnr: $(FILE)_pnr.json
	@echo "✓ Place & Route concluído: $(FILE)_pnr.json"

bitstream: $(FILE).fs
	@echo "✓ Bitstream gerado: $(FILE).fs"

# ═══════════════════════════════════════════════════════════════════════════════
# ALVOS DE SIMULAÇÃO (iverilog + GTKWave)
# ═══════════════════════════════════════════════════════════════════════════════

SIM_SRCS = tb_top.v top.v control.v datapath.v
SIM_EXEC = sim_top
SIM_VCD = sim.vcd
SIM_LOG = sim.log

# Alvo padrão de simulação: compile → run → view
sim: sim-compile sim-run sim-view
	@echo ""
	@echo "╔════════════════════════════════════════════════════════════════════╗"
	@echo "║  SIMULAÇÃO CONCLUÍDA                                             ║"
	@echo "╚════════════════════════════════════════════════════════════════════╝"

# Compilar testbench
sim-compile: $(SIM_EXEC)
	@echo "✓ Compilação concluída: $(SIM_EXEC)"

$(SIM_EXEC): $(SIM_SRCS)
	@echo "Compilando com iverilog..."
	iverilog -o $(SIM_EXEC) $(SIM_SRCS)

# Executar simulação
sim-run: $(SIM_EXEC) $(SIM_VCD)
	@echo "✓ Simulação concluída: $(SIM_VCD)"
	@echo "  Log em: $(SIM_LOG)"

$(SIM_VCD): $(SIM_EXEC)
	@echo "Executando simulação (timeout: 5 min)..."
	@timeout 300 vvp $(SIM_EXEC) > $(SIM_LOG) 2>&1 || true
	@echo "  Últimas 20 linhas do log:"
	@tail -20 $(SIM_LOG)

# Abrir GTKWave
sim-view: $(SIM_VCD)
	@if [ -f $(SIM_VCD) ]; then \
		echo "Abrindo GTKWave..."; \
		gtkwave $(SIM_VCD) & \
	else \
		echo "✗ Erro: $(SIM_VCD) não encontrado"; \
		echo "  Execute 'make sim-run' primeiro"; \
	fi

# Limpeza de simulação
sim-clean:
	@echo "Limpando arquivos de simulação..."
	@rm -f $(SIM_EXEC) $(SIM_VCD) $(SIM_LOG) *.vvp
	@echo "✓ Limpeza concluída"

# ═══════════════════════════════════════════════════════════════════════════════
# ALVOS DE SIMULAÇÃO SIMPLIFICADA (testbench reduzido)
# ═══════════════════════════════════════════════════════════════════════════════

.PHONY: sim-simple sim-simple-compile sim-simple-run sim-simple-clean

SIM_SIMPLE_EXEC = sim_simple
SIM_SIMPLE_VCD = sim_simple.vcd
SIM_SIMPLE_LOG = sim_simple.log

# Compilar testbench simplificado
sim-simple-compile:
	@echo "Compilando testbench simplificado..."
	iverilog -o $(SIM_SIMPLE_EXEC) tb_top_simple.v top.v control.v datapath.v

# Executar testbench simplificado
sim-simple-run: sim-simple-compile
	@echo "Executando simulação simplificada..."
	@timeout 300 vvp $(SIM_SIMPLE_EXEC) > $(SIM_SIMPLE_LOG) 2>&1 || true
	@echo "✓ Simulação concluída: $(SIM_SIMPLE_LOG)"
	@echo ""
	@echo "Saída da simulação (últimas 30 linhas):"
	@tail -30 $(SIM_SIMPLE_LOG)

# Limpeza de simulação simplificada
sim-simple-clean:
	@echo "Limpando simulação simplificada..."
	@rm -f $(SIM_SIMPLE_EXEC) $(SIM_SIMPLE_VCD) $(SIM_SIMPLE_LOG)
	@echo "✓ Limpeza concluída"

clean:
	rm *.json *.fs
