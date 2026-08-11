# Tang Nano Development Workflow

This document outlines two development workflows for the Gowin Tang Nano boards (1K, 9K, 20K):
1. **Gowin IDE (Windows):** Official GUI toolchain.
2. **oss-cad-suite (Cross-Platform):** Open-source toolchain (Yosys, nextpnr, openFPGALoader).

---

## Index

- [Part 1: Gowin IDE (Windows)](#part-1-gowin-ide-windows)
  - [1. Installation](#1-installation)
  - [2. Create Project](#2-create-project)
  - [3. Create Verilog File and Synthesis](#3-create-verilog-file-and-synthesis)
  - [4. Constraints and Programming](#4-constraints-and-programming)
- [Part 2: Open Source Toolchain (Cross-Platform)](#part-2-open-source-toolchain-cross-platform)
  - [Option A: Workflow via VS Code & Lushay Code (Recommended)](#option-a-workflow-via-vs-code--lushay-code-recommended)
  - [Option B: Workflow via Makefile (CLI)](#option-b-workflow-via-makefile-cli)

---

## Part 1: Gowin IDE (Windows)

### 1. Installation

1. Download **Gowin FPGA Designer (Education)** from [Gowin's Website](https://www.gowinsemi.com/en/support/download_eda/).
2. Run the installer as Administrator. It will also install the **Gowin Programmer** and USB FTDI drivers.
3. Open Gowin FPGA Designer. If it opens without errors, installation is successful.

**Warning:** The installation and project paths must contain only letters, numbers, and underscores. Avoid spaces, special characters, and accents.

### 2. Create Project

1. Open **Gowin FPGA Designer**
2. `File` → `New` → **FPGA Design Project** → OK
3. Configure Project Name and Path.
4. Select device (e.g., Series: GW1NZ, Device: GW1NZ-1, Package: QN48, Speed: C6/I5).
5. Click **Finish**.

### 3. Create Verilog File and Synthesis

1. `File` → `New` → **Verilog File** → Save as `top.v`.
2. Write your HDL code.
3. In the **Process** panel, double-click **Synthesize**.
4. Check for success in the terminal output.

### 4. Constraints and Programming

1. Use the **Floorplanner** to map your Verilog ports to the physical pins of your board (generates `.cst` file).
2. Double-click **Place & Route** in the Process panel.
3. Double-click **Program Device**. Ensure the cable is detected as `USB Debugger A`.
4. Run SRAM Program or Flash Program with your `.fs` bitstream file.

---

## Part 2: Open Source Toolchain (Cross-Platform)

**Prerequisite:** Install `oss-cad-suite` and the Lushay Code extension as detailed in [`suit_install.md`](suit_install.md).

### Option A: Workflow via VS Code & Lushay Code (Recommended)

This workflow utilizes the Lushay Code extension to automate project creation, synthesis, and programming.

#### 1. Create a Project Folder
Create an empty directory for your new project and open it in Visual Studio Code.

#### 2. Initialize the Project
- Click on the Lushay Code extension icon or open the Command Palette (`Ctrl+Shift+P`) to create a new project.
- **2.1.** Write the project name when prompted.

#### 3. Default Project Files
The extension generates a basic structure, including:
- `top.v`: The main Verilog module (Top-Level) where you will write your hardware logic.
- `top.cst`: The Physical Constraints file where you map the top-level Verilog ports (inputs/outputs) to the actual physical pins on the FPGA board.

#### 4. Basic Constraints (`tang.cst`)
Depending on your board version, use the following base templates for the system clock:

**Tang Nano 1K:**
```cst
IO_LOC "clk" 52;
IO_PORT "clk" IO_TYPE=LVCMOS33 PULL_MODE=UP;
```

**Tang Nano 9K:**
```cst
IO_LOC "clk" 52;
IO_PORT "clk" IO_TYPE=LVCMOS33 PULL_MODE=UP;
```

**Tang Nano 20K:**
```cst
IO_LOC "clk" 4;
IO_PORT "clk" IO_TYPE=LVCMOS33 PULL_MODE=UP;
```

#### 5. Project Configuration (JSON)
The extension relies on a JSON configuration file (e.g., `project.lushay.json`). Depending on your board version, structure your JSON as follows (using `blink` as the project name):

**Tang Nano 1K:**
```json
{
    "name": "blink",
    "project_name": "blink",
    "top_module": "top",
    "device": "GW1NZ-LV1QN48C6/I5",
    "board": "tangnano1k",
    "includedFiles": ["blink.v"],
    "constraintFiles": ["blink.cst"]
}
```

**Tang Nano 9K:**
```json
{
    "name": "blink",
    "project_name": "blink",
    "top_module": "top",
    "device": "GW1NR-LV9QN88PC6/I5",
    "board": "tangnano9k",
    "includedFiles": ["blink.v"],
    "constraintFiles": ["blink.cst"]
}
```

**Tang Nano 20K:**
```json
{
    "name": "blink",
    "project_name": "blink",
    "top_module": "top",
    "device": "GW2AR-LV18",
    "board": "tangnano20k",
    "includedFiles": ["blink.v"],
    "constraintFiles": ["blink.cst"]
}
```

#### 6. Toolchain Execution
With a source file active, click on the Lushay Code toolchain menu. You will find the following options:
- **Compile:** Runs the toolchain to synthesize the design and generate the bitstream (`.fs`).
- **Run:** Uses openFPGALoader to program the previously generated bitstream to the board.
- **Compile and Run:** Performs the complete pipeline sequentially: synthesis, bitstream generation, and immediate FPGA programming.

---

### Option B: Workflow via Makefile (CLI)

### 1. Project Structure

Create your project folder and add a `Makefile` to automate the build process:

```
your_project/
├── Makefile
├── src/
│   └── top.v
└── constraints/
    └── pins.cst
```

### 2. Complete Makefile

```makefile
# Gowin FPGA Build System

PROJECT := top
DEVICE := GW1NZ-1
FAMILY := GW1N
FPGA_BOARD := tangnano1k

VERILOG_FILES := src/top.v
CST_FILE := constraints/pins.cst

JSON_SYNTH := build/$(PROJECT).json
JSON_PNR := build/$(PROJECT)_pnr.json
BITSTREAM := build/$(PROJECT).fs

.PHONY: all synth pnr pack program clean

all: pack

synth: $(JSON_SYNTH)
$(JSON_SYNTH): $(VERILOG_FILES)
	mkdir -p build
	yosys -p "read_verilog $(VERILOG_FILES); synth_gowin -json $(JSON_SYNTH)"

pnr: $(JSON_PNR)
$(JSON_PNR): $(JSON_SYNTH) $(CST_FILE)
	nextpnr-gowin --device $(DEVICE) --cst $(CST_FILE) --json $(JSON_SYNTH) --write $(JSON_PNR)

pack: $(BITSTREAM)
$(BITSTREAM): $(JSON_PNR)
	gowin_pack -d $(DEVICE) -o $(BITSTREAM) $(JSON_PNR)

program: $(BITSTREAM)
	openFPGALoader -b $(FPGA_BOARD) $(BITSTREAM)

clean:
	rm -rf build/
```

### 3. Development Flow

1. **Synthesis:** `make synth` (Uses Yosys to convert HDL to netlist).
2. **Place and Route:** `make pnr` (Uses nextpnr to place logic elements and route connections).
3. **Bitstream Generation:** `make pack` (Uses Apicula / gowin_pack to generate `.fs` file).
4. **Programming:** `make program` (Uses openFPGALoader to flash the board).

Check [`suit_install.md`](suit_install.md) for troubleshooting USB permissions and toolchain paths if commands fail.
