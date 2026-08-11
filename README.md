# HDL Projects

Welcome to the **HDL Projects** repository! This central repository contains HDL designs, examples, and comprehensive documentation for working with Field Programmable Gate Arrays (FPGAs), ASICs chips and Complex Programmable Logic Devices (CPLDs).

## Supported Hardware

- **Gowin Tang Nano (1K & 20K)**
- **Altera MAX II**

## Repository Structure

- **`cores/`**: Reusable hardware blocks (IPs) that are platform-agnostic (e.g., clock dividers, UART controllers);
- **`systems/`**: Complete embedded projects (Top-levels) targeted for specific FPGA boards (e.g., Altera MAX II, Tang Nano);
- **`docs/`**: Comprehensive guides, installation tutorials, and workflow steps. **Start here** if you are setting up your environment;
- **`scripts/`**: Automation scripts (e.g., environment setup).

## Moved Projects
The educational processor implementations have been moved to their own dedicated repositories:
- **[MIPS Processor](https://github.com/AndersonCSM/mips_processor)**
- **[RISC-V Processor](https://github.com/AndersonCSM/riscv_processor)**

## Installation Guides

Choose the guide that matches your OS and target FPGA:

- **Tang Nano (Open Source / Linux):** [`docs/suit_install.md`](docs/suit_install.md)
- **Quartus Prime Lite (Windows/Linux):** [`docs/quartus_install.md`](docs/quartus_install.md)

## Workflows and Step-by-Step

Once installed, follow these guides to run your first project:

- **Tang Nano:** [`docs/tangnano_workflow.md`](docs/tangnano_workflow.md) (Gowin IDE and Open-source Toolchain)
- **Altera MAX II:** [`docs/altera_workflow.md`](docs/altera_workflow.md) (Quartus Prime Lite)

---

## External Links

### Primary Tools
- [oss-cad-suite](https://github.com/YosysHQ/oss-cad-suite-build)
- [OpenFPGALoader](https://github.com/trabucayre/openFPGALoader)
- [Yosys](https://yosyshq.net/)
- [nextpnr](https://github.com/YosysHQ/nextpnr)

### Hardware
- [Tang Nano 1K/20K](https://sipeed.com/tang-nano-1k)
- [Altera MAX II](https://www.intel.com/content/www/us/en/products/details/fpga/max/ii.html)
