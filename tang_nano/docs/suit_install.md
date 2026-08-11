# Tang Nano Toolchain — Complete Installation Guide

Installation and configuration guide for the `oss-cad-suite` toolchain for FPGA development with Tang Nano boards on Linux and Windows.

**Platforms:** Tang Nano 1K, 9K, 20K and variants  
**Toolchain:** `oss-cad-suite` (Yosys, nextpnr, openFPGALoader)  
**Support:** Linux (Ubuntu 20.04+, Debian, Fedora, etc.) and Windows

---

## Index

- [Overview](#overview)
- [Pre-requisites](#pre-requisites)
- [Installing oss-cad-suite (Linux)](#installing-oss-cad-suite-linux)
- [Configuring Environment Variables (Linux)](#configuring-environment-variables-linux)
- [Installing OpenFPGALoader (Linux)](#installing-openfpgaloader-linux)
- [USB/Driver Configuration (Linux)](#usbdriver-configuration-linux)
- [Verifying Installation](#verifying-installation)
- [Windows Installation](#windows-installation)
- [VS Code Development Extensions](#vs-code-development-extensions)
- [Troubleshooting Windows: JTAG and Zadig](#troubleshooting-windows-jtag-and-zadig)

---

## Overview

To work with **Tang Nano** using open-source tools, you need:

| Tool | Function |
|------------|--------|
| **oss-cad-suite** | Synthesis, Place & Route, Bitstream Generation (Yosys + nextpnr) |
| **openFPGALoader** | FPGA programmer via USB/JTAG |
| **USB Drivers** | Communication with the FPGA board |

### Recommended Layout

```bash
/home/tools/
  oss-cad-suite/        # Global installation (shared)
    bin/
    lib/
    share/

hdl/
  tang_nano_1k/
    blink/              # Projects
    teste/
  tang_nano_20k/
```

---

## Pre-requisites

- **Linux:** Ubuntu 20.04 LTS or later (recommended)
- **Disk space:** ≥ 5 GB
- **Internet access:** For downloading toolchains
- **Root/sudo access:** For global installation

### System Dependencies

#### Ubuntu/Debian

```bash
sudo apt update
sudo apt install -y \
    build-essential \
    git \
    cmake \
    pkg-config \
    libusb-1.0-0-dev \
    libusb-1.0-0 \
    python3 \
    python3-pip \
    python3-dev \
    libftdi1-dev \
    libftdi-dev \
    libmpsse-dev
```

#### Fedora/RHEL

```bash
sudo dnf install -y \
    gcc \
    g++ \
    git \
    cmake \
    pkg-config \
    libusbx-devel \
    python3 \
    python3-devel \
    libftdi-devel
```

---

## Installing oss-cad-suite (Linux)

### Option A: Global Installation (Recommended)

Install in `/home/tools/` to share between projects.

```bash
# Create directory
sudo mkdir -p /home/tools
cd /home/tools

# Determine version (replace VERSION with the latest tag)
# Check: https://github.com/YosysHQ/oss-cad-suite-build/releases

# Download (Linux x64)
VERSION="2024-01-01"  # Example: adjust to the latest version
wget https://github.com/YosysHQ/oss-cad-suite-build/releases/download/${VERSION}/oss-cad-suite-linux-x64-${VERSION}.tgz

# Extract
sudo tar xzf oss-cad-suite-linux-x64-${VERSION}.tgz

# Remove archive
sudo rm oss-cad-suite-linux-x64-${VERSION}.tgz

# Verify installation
ls -la /home/tools/oss-cad-suite/bin/
```

### Option B: Local Installation (Project Specific)

If you prefer to install only for a specific project:

```bash
cd hdl/tang_nano_1k

# Download and extract
wget https://github.com/YosysHQ/oss-cad-suite-build/releases/download/VERSION/oss-cad-suite-linux-x64.tgz
tar xzf oss-cad-suite-linux-x64.tgz
rm oss-cad-suite-linux-x64.tgz

# Use local path instead of global
```

---

## Configuring Environment Variables (Linux)

### 1. Edit `~/.bashrc`

```bash
nano ~/.bashrc
# or
vim ~/.bashrc
```

### 2. Add to End of File

```bash
# === oss-cad-suite (FPGA Tang Nano) ===
export FPGA_TOOLS="/home/tools/oss-cad-suite"
export PATH="${FPGA_TOOLS}/bin:$PATH"
export LD_LIBRARY_PATH="${FPGA_TOOLS}/lib:$LD_LIBRARY_PATH"
```

### 3. Reload Configuration

```bash
source ~/.bashrc
```

### 4. Verify

```bash
yosys --version
nextpnr-gowin --version
openFPGALoader --version
```

---

## Installing OpenFPGALoader (Linux)

**openFPGALoader** is the programmer utility used to flash bitstreams into the FPGA.

### Option A: Via Package Manager (If Available)

```bash
sudo apt install openfpgaloader
```

### Option B: Compile from Source (Recommended)

```bash
# Clone repository
git clone https://github.com/trabucayre/openFPGALoader.git
cd openFPGALoader

# Create build directory
mkdir build && cd build

# Configure CMake
cmake -DCMAKE_BUILD_TYPE=Release ..

# Compile (use all cores)
make -j$(nproc)

# Install globally
sudo make install

# Or install locally
mkdir -p ~/.local/bin
cp openFPGALoader ~/.local/bin/
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

### Verification

```bash
openFPGALoader --version
```

---

## USB/Driver Configuration (Linux)

### 1. Connect Tang Nano

Connect the board via the USB-C cable.

### 2. Create udev Rules

```bash
sudo tee /etc/udev/rules.d/99-fpga.rules > /dev/null << 'EOF'
# Anlogic FPGA (Tang Nano, etc.)
SUBSYSTEMS=="usb", ATTRS{idVendor}=="0403", ATTRS{idProduct}=="6010", MODE="0666"

# Other Gowin/FTDI devices
SUBSYSTEM=="usb", ATTRS{idVendor}=="0403", ATTRS{idProduct}=="6001", MODE="0666"
SUBSYSTEM=="usb", ATTRS{idVendor}=="0403", ATTRS{idProduct}=="6014", MODE="0666"
EOF
```

### 3. Reload Rules

```bash
sudo udevadm control --reload-rules
sudo udevadm trigger
```

### 4. Add User to Group (Optional, to avoid sudo)

```bash
sudo usermod -a -G dialout $USER
sudo usermod -a -G plugdev $USER

# Login again to apply
exit
# Reconnect or run:
# newgrp dialout
```

---

## Verifying Installation

### Complete Checklist

```bash
# 1. Verify Yosys
yosys -version

# Expected output:
# Yosys 0.26+...

# 2. Verify nextpnr
nextpnr-gowin --version

# 3. Verify openFPGALoader
openFPGALoader --version

# 4. Connect Tang Nano and detect
openFPGALoader --detect

# Expected output:
# found 1 device
#   idcode 0x100681b
#   manufacturer Gowin
#   family GW1NZ
#   model  GW1NZ-1
```

---

## Windows Installation

The OSS CAD Suite is also distributed as a pre-compiled binary for Windows.

### Step 1: Download and Run Installer
1. Access the official GitHub repository: [YosysHQ/oss-cad-suite-build/releases](https://github.com/YosysHQ/oss-cad-suite-build/releases).
2. In the **Releases** tab, locate the latest version. Windows updates are rolled out slower; currently, the latest Windows update is from 2026-06-03.
3. In the **Assets** section, download the `.exe` file corresponding to Windows 64-bit (e.g., `oss-cad-suite-windows-x64-YYYYMMDD.exe`).
4. Run the installer. We recommend extracting it to a directory in the system root to avoid issues with spaces in the path (e.g., `C:\oss-cad-suite`).
5. Wait for the file extraction to complete.

### Step 2: PATH Configuration (Environment Variables)
To use the tools from any terminal or VS Code extension:
1. Press the Windows key, type **Edit the system environment variables** (or equivalent in your OS language), and press Enter.
2. Click the **Environment Variables...** button.
3. In the **System variables** section, locate the **Path** variable and click Edit.
4. Add the exact path to the `bin` folder of your installation (e.g., `C:\oss-cad-suite\bin`).
5. Click OK to save all changes.

Open a new terminal and run `yosys --version` and `openFPGALoader --version` to validate the installation.

---

## VS Code Development Extensions

To streamline development, it is highly recommended to use **Visual Studio Code** with the following extensions:

### 1. HDL/Verilog
Extension for syntax support, formatting, and linting of Verilog and SystemVerilog.
- **Installation:** Search for `mshr-h.VerilogHDL` in the VS Code extensions tab.

### 2. Lushay Code
Extension to automate compilation and programming for Tang Nano boards using the `oss-cad-suite`.
- **Installation:** Search for `Lushay Code` in the VS Code extensions tab.

**Configuring the Lushay Code Extension:**
1. In VS Code, open settings (`Ctrl + ,`) and search for `Lushay Code`.
2. Configure the executable path for the OSS CAD Suite (if necessary, in case the PATH variable does not resolve automatically).
3. Set your default target board under "FPGA Board" (e.g., `tangnano1k`, `tangnano9k`).
4. When opening `.v` or `.cst` files, the extension will provide interface buttons ("Build" and "Program") to execute synthesis and programming with a single click. On Windows, it will detect the tools configured in your `Path` variable.

---

## Troubleshooting Windows: JTAG and Zadig

A frequent issue on Windows is a communication failure between `openFPGALoader` and the Tang Nano board due to the generic USB driver installed by the operating system.

**Resolution via Zadig:**
To allow programming via JTAG, you will need to install the WinUSB driver on the correct interface.

1. Download the [Zadig](https://zadig.akeo.ie/) application and run it as an administrator.
2. Connect the Tang Nano board to the USB port.
3. In Zadig, go to the **Options** menu and check **List All Devices**.
4. In the main dropdown menu, select the JTAG programmer interface.
   **Critical Warning:** Be extremely careful during this step to select the correct device (usually named `JTAG Debugger (Interface 0)` or similar, with the USB ID `0403 6010`). Changing the driver for other peripherals (like your mouse or keyboard) will cause them to stop working.
5. In the target driver selection box, choose **WinUSB**.
6. Click the **Replace Driver** (or **Install Driver**) button.
7. Wait for the process to finish and test the communication again by running `openFPGALoader --detect` in the terminal.
