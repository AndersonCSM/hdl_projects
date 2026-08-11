# Altera MAX II Development Workflow

Development using **Quartus Prime Lite** — Altera platform.

**Prerequisite:** Read [`quartus_install.md`](quartus_install.md) to install Quartus.

---

## 1. Create Project

1. Open **Quartus Prime Lite**
2. `File` → `New Project Wizard`
3. Configure:
   - **Project Name:** `blink`
   - **Project Directory:** ex. `C:\fpga\max_ii\blink\` or `/home/user/fpga/max_ii/blink/`
   - **Add Files to Project:** (leave blank for now)
4. Click **Next**
5. Select MAX II device:
   - **Family:** MAX II
   - **Device:** EPM570T100C5 (or other compatible MAX II)
6. Click **Finish**

---

## 2. Create Verilog File

1. `File` → `New`
2. Select **Verilog HDL File**
3. Save as `top.v`
4. Write your Verilog module.
5. `File` → `Project` → `Add Files...`
6. Select `top.v` and click **Add**

---

## 3. Synthesis

1. `Processing` → `Start Compilation`
2. Wait for compilation complete

Success: No critical errors in **Messages** tab.

---

## 4. Physical Constraints (`.qsf`)

1. `Assignments` → `Pins`
2. Configure pins:

| Port Name | Pin # | IO Type |
|-----------|-------|---------|
| sys_clk | (check board) | LVCMOS |
| sys_rst_n | (check board) | LVCMOS |
| led[0] | (check board) | LVCMOS |
| led[1] | (check board) | LVCMOS |
| led[2] | (check board) | LVCMOS |

> **Note:** Pins depend on specific MAX II board. Check board documentation.

3. Save project (Ctrl+S)

---

## 5. Place & Route

Already done during compilation (step 3).

---

## 6. Generate Programming File

1. `File` → `Convert Programming Files`
2. Configure:
   - **Programming File Type:** SRAM Object File (`.svf`)
   - **Output File Name:** `blink.svf`
3. Click **Convert**

---

## 7. Programming

1. Connect board via **USB Blaster**
2. `Tools` → `Programmer`
3. Click **Hardware Setup** and select USB Blaster port
4. Click **Start** to program

---

## Troubleshooting (Quartus)

### USB Blaster not appearing

```
Solution: Check drivers (quartus_install.md, Windows section)
        Reconnect USB cable
        jtagconfig (list devices)
```

### Compilation errors

```
Solution: Check pin names
        Confirm correct MAX II device
        Review Verilog code
```
