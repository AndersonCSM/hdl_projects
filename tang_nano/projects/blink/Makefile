# Tang Nano 20K Blink Project Makefile
# Device: GW2AR-LV18 (Gowin GW2A family)
# Toolchain: oss-cad-suite (Yosys + nextpnr-gowin + gowin_pack)

# oss-cad-suite paths
TOOLS_DIR := /home/anderson/tools/oss-cad-suite
YOSYS := $(TOOLS_DIR)/bin/yosys
NEXTPNR := $(TOOLS_DIR)/bin/nextpnr-himbaechel
GOWIN_PACK := $(TOOLS_DIR)/bin/gowin_pack

FILE := blink_20k
TOP_MODULE := top
FAMILY := GW2A-18C
DEVICE := GW2A-18C
FPGA_BOARD := tangnano20k

# Source files
VERILOG_FILES := blink.v
CST_FILE := blink.cst

# Build targets
.PHONY: all synth pnr pack bitstream clean

all: bitstream

# Synthesis
synth: $(FILE).json

$(FILE).json: $(VERILOG_FILES) $(CST_FILE)
	@echo "=== Synthesis with Yosys ==="
	$(YOSYS) -p "read_verilog $(VERILOG_FILES); synth_gowin -json $(FILE).json"

# Place & Route
pnr: $(FILE)_pnr.json

$(FILE)_pnr.json: $(FILE).json $(CST_FILE)
	@echo "=== Place & Route with NextPnR (himbaechel) ==="
	$(NEXTPNR) --device $(DEVICE) --vopt family=$(FAMILY) --json $(FILE).json --write $(FILE)_pnr.json

# Pack (Bitstream generation)
pack: $(FILE).fs

$(FILE).fs: $(FILE)_pnr.json
	@echo "=== Generate Bitstream ==="
	$(GOWIN_PACK) -d $(FAMILY) -o $(FILE).fs $(FILE)_pnr.json

# Full bitstream build
bitstream: pack
	@echo "=== Build Complete! ==="
	@ls -lh $(FILE).fs

# Program FPGA
program: $(FILE).fs
	@echo "=== Programming FPGA ==="
	$(TOOLS_DIR)/bin/openFPGALoader -b $(FPGA_BOARD) $(FILE).fs

# Clean build artifacts
clean:
	rm -f $(FILE).json $(FILE)_pnr.json $(FILE).fs

.PHONY: all synth pnr pack bitstream clean program
