# Tang Nano 20K UART Echo Project Makefile
# Device: GW2AR-LV18 (Gowin GW2A family)
# Toolchain: oss-cad-suite (Yosys + nextpnr-gowin + gowin_pack)

# oss-cad-suite paths
TOOLS_DIR := /home/anderson/tools/oss-cad-suite
YOSYS := $(TOOLS_DIR)/bin/yosys
NEXTPNR := $(TOOLS_DIR)/bin/nextpnr-himbaechel
GOWIN_PACK := $(TOOLS_DIR)/bin/gowin_pack

PROJECT := uart
TOP_MODULE := top
FAMILY := GW2A
DEVICE := GW2AR-LV18C

# Source files
VERILOG_FILES := top.sv tx.sv rx.sv baud_generate.sv
CST_FILE := uart.cst

# Build targets
.PHONY: all synth pnr pack bitstream clean help

all: bitstream

help:
	@echo "Available targets:"
	@echo "  make synth     - Run synthesis only"
	@echo "  make pnr       - Run place & route"
	@echo "  make pack      - Generate bitstream"
	@echo "  make bitstream - Build everything (default)"
	@echo "  make clean     - Remove build artifacts"

# Synthesis
synth: $(PROJECT).json

$(PROJECT).json: $(VERILOG_FILES)
	@echo "=== Synthesis with Yosys ==="
	$(YOSYS) -p "read_verilog $(VERILOG_FILES); synth_gowin -json $(PROJECT).json"

# Place & Route
pnr: $(PROJECT)_pnr.json

$(PROJECT)_pnr.json: $(PROJECT).json
	@echo "=== Place & Route with NextPnR ==="
	$(NEXTPNR) --device $(DEVICE) --vopt family=$(FAMILY) --json $(PROJECT).json --write $(PROJECT)_pnr.json

# Pack (Bitstream generation)
pack: $(PROJECT).fs

$(PROJECT).fs: $(PROJECT)_pnr.json
	@echo "=== Generate Bitstream ==="
	$(GOWIN_PACK) -d $(FAMILY) -o $(PROJECT).fs $(PROJECT)_pnr.json

# Full bitstream build
bitstream: pack
	@echo "=== UART Echo Build Complete! ==="
	@ls -lh $(PROJECT).fs

# Clean build artifacts
clean:
	@echo "=== Cleaning build files ==="
	rm -f $(PROJECT).json $(PROJECT)_pnr.json $(PROJECT).fs
	rm -rf build/ *.rpt

.PRECIOUS: $(PROJECT).json $(PROJECT)_pnr.json

# Program FPGA
program: $(FILE).fs
	@echo "=== Programming FPGA ==="
	$(TOOLS_DIR)/bin/openFPGALoader -b $(FPGA_BOARD) $(FILE).fs

# Clean build artifacts
clean:
	rm -f $(FILE).json $(FILE)_pnr.json $(FILE).fs

.PHONY: all synth pnr pack bitstream clean program
