BOARD=tangnano1k
FAMILY=GW1NZ-1
DEVICE=GW1NZ-LV1QN48C6/I5

all:	$(FILE).fs

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

clean:
	rm *.json *.fs
