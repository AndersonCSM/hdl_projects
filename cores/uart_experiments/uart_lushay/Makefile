# Tang Nano 20K UART Lushay - Makefile
# Device: GW2AR-LV18C (Gowin GW2A family)
# Toolchain: oss-cad-suite (Yosys + nextpnr-gowin + gowin_pack)

# oss-cad-suite paths
TOOLS_DIR := /home/anderson/tools/oss-cad-suite
YOSYS := $(TOOLS_DIR)/bin/yosys
NEXTPNR := $(TOOLS_DIR)/bin/nextpnr-himbaechel
GOWIN_PACK := $(TOOLS_DIR)/bin/gowin_pack

PROJECT := uart
TOP_MODULE := uart
FAMILY := GW2A
DEVICE := GW2AR-LV18C

# Source files
VERILOG_FILES := uart.v
CST_FILE := uart2.cst

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
	@echo "=== Pack with Gowin_pack ==="
	$(GOWIN_PACK) -d $(DEVICE) -o $(PROJECT).fs $(PROJECT)_pnr.json

bitstream: $(PROJECT).fs
	@echo "=== Build complete: $(PROJECT).fs ==="

# Clean build artifacts
clean:
	@echo "=== Cleaning build artifacts ==="
	rm -f $(PROJECT).json $(PROJECT)_pnr.json $(PROJECT).fs
	@echo "Clean complete"
