# Development Workflow for Altera

Development using **Quartus Prime Lite** — Altera platform.

**Prerequisite:** Read [`quartus_install.md`](quartus_install.md) to install Quartus.

---

## 1. Create Project

1. Open **Quartus Prime Lite**
2. `File` → `New Project Wizard`
   ![alt text](img/quartus_new_project_wizard.png)
3. Configure:
   - **Project Name:** `blink`
   - **Project Directory:** ex. `C:\fpga\max_ii\blink\` or `/home/user/fpga/max_ii/blink/`
   - **Add Files to Project:** (leave blank for now)
   ![alt text](img/quartus_project_settings_1.png)
   ![alt text](img/quartus_project_settings_2.png)
   
4. Click **Next**
5. Select MAX II device:
   - **Family:** MAX II
   - **Device:** EPM570T100C5 (or other compatible MAX II)
   ![alt text](img/quartus_project_settings_3.png)
   ![alt text](img/quartus_device_selection.png)
6. Click **Finish**
   ![alt text](img/quartus_project_finish.png)


---

## 2. Create Verilog File

1. `File` → `New`
2. Select **Verilog HDL File**
3. Save as `top.v`
   ![alt text](img/quartus_new_verilog_file.png)
4. Write your Verilog module.
![alt text](img/quartus_write_verilog.png)
5. Adding external files: `File` → `Project` → `Add Files...`
6. Select `file.v` and click **Apply** and ok:

![alt text](img/quartus_add_files_1.png)
![alt text](img/quartus_add_files_2.png)
![alt text](img/quartus_add_files_3.png)
---

## 3. Synthesis

1. `Processing` → `Start Compilation`
2. Wait for compilation complete

![alt text](img/quartus_compilation_success.png)
Success: No critical errors in **Messages** tab.

---

## 4. Physical Constraints (`.qsf`)

1. `Assignments` → `Pins`
![alt text](img/quartus_pin_planner_open.png)
2. Configure pins:

| Port Name | Pin # | IO Type |
|-----------|-------|---------|
| clk | (check board) | LVCMOS |
| led | (check board) | LVCMOS |

![alt text](img/quartus_pin_assignments.png)

> **Note:** Pins depend on specific MAX II board. Check the original schematics of your board or example pinout files (`.qsf`) to properly identify which pin the `clk` and `leds` are connected to.

3. Save project (Ctrl+S) and re-compile

![alt text](img/quartus_recompile.png)


## 5. Place & Route

Already done during compilation (step 3)

## 6. Programming

1. Connect board via **USB Blaster**
2. `Tools` → `Programmer`
![alt text](img/quartus_programmer_open.png)
3. Click **Hardware Setup** and select USB Blaster port
![alt text](img/quartus_hardware_setup.png)
4. Click **Start** to program
![alt text](img/quartus_programming_start.png)

### Programming via CLI (openFPGALoader)

If you prefer to program the board via terminal using `openFPGALoader`, the Quartus Programmer will first need to generate an `.svf` file.
1. In the Programmer, go to **File** → **Create/Update** → **Create JAM, SVF, or ISC File...**
2. Save as `.svf` format.
3. In the terminal: `openFPGALoader -c usb-blaster project.svf`
*(Or convert directly via terminal with: `quartus_cpf -c output_files/top.pof output_files/top.svf`)*

---

## Troubleshooting (Quartus)

### USB Blaster not appearing

```
Solution: 
- Check drivers on Windows (Zadig issue)
- On Linux, check if udev rules are properly configured (see [quartus_install.md](../toolchain_setup/quartus_install.md))
- Reconnect USB cable
- jtagconfig (list devices)
```

### Compilation errors

```
Solution: 
- Check pin names in Pin Planner
- Confirm correct MAX II device model is selected
- Review Verilog code syntax and logic
```
