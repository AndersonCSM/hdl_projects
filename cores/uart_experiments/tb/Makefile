VERILOG = iverilog
VVP = vvp

SIM_DIR = ../sim
TB_DIR = .
RTL_DIR = ../rtl

FLAGS = -Wall -g2012 -I$(TB_DIR) -I$(RTL_DIR)

TESTS = tb_baud_generate tb_fifo tb_uart tb_rx tb_tx tb_top tb_fpga_top

DESIGN_MAP = \
    tb_baud_generate=baud_generate \
    tb_fifo=fifo \
    tb_uart=uart \
    tb_rx=rx \
    tb_tx=tx \
    tb_top=uart_top \
	tb_fpga_top=fpga_top

get_design = $(word 2,$(subst =, ,$(filter $1=%,$(DESIGN_MAP))))

all: $(TESTS)

$(SIM_DIR):
	mkdir -p $(SIM_DIR)

$(TESTS): | $(SIM_DIR)
	@echo "--------------------------------------------------"
	@echo " Compilando e Rodando: $@"
	@echo "--------------------------------------------------"
	@if [ "$@" = "tb_top" ]; then \
		$(VERILOG) $(FLAGS) -o $(SIM_DIR)/$@.vvp $(TB_DIR)/$@.v $(RTL_DIR)/uart_top.v $(RTL_DIR)/uart.v $(RTL_DIR)/tx.v $(RTL_DIR)/rx.v $(RTL_DIR)/baud_generate.v $(RTL_DIR)/fifo.v; \
	elif [ "$@" = "tb_uart" ]; then \
		$(VERILOG) $(FLAGS) -o $(SIM_DIR)/$@.vvp $(TB_DIR)/$@.v $(RTL_DIR)/uart.v $(RTL_DIR)/tx.v $(RTL_DIR)/rx.v $(RTL_DIR)/baud_generate.v; \
	elif [ "$@" = "tb_fpga_top" ]; then \
		$(VERILOG) $(FLAGS) -o $(SIM_DIR)/$@.vvp $(TB_DIR)/$@.v $(RTL_DIR)/fpga_top.v $(RTL_DIR)/uart_top.v $(RTL_DIR)/uart.v $(RTL_DIR)/tx.v $(RTL_DIR)/rx.v $(RTL_DIR)/baud_generate.v $(RTL_DIR)/fifo.v; \
	else \
		$(VERILOG) $(FLAGS) -o $(SIM_DIR)/$@.vvp $(TB_DIR)/$@.v $(RTL_DIR)/$(call get_design,$@).v; \
	fi
	$(VVP) $(SIM_DIR)/$@.vvp
	@echo "--------------------------------------------------"

clean:
	rm -rf $(SIM_DIR)

.PHONY: all clean $(TESTS)