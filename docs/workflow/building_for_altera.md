# Development Workflow for Altera

Development using **Quartus Prime Lite** — Altera platform.

**Prerequisite:** Read [`quartus_install.md`](quartus_install.md) to install Quartus.

---

## 1. Create Project

1. Open **Quartus Prime Lite**
2. `File` → `New Project Wizard`
   ![alt text](img/image2.png)
3. Configure:
   - **Project Name:** `blink`
   - **Project Directory:** ex. `C:\fpga\max_ii\blink\` or `/home/user/fpga/max_ii/blink/`
   - **Add Files to Project:** (leave blank for now)
   ![alt text](img/image3.png)
   ![alt text](img/image4.png)
   ![alt text](img/image5.png)
4. Click **Next**
5. Select MAX II device:
   - **Family:** MAX II
   - **Device:** EPM570T100C5 (or other compatible MAX II)
   ![alt text](img/image6.png)
6. Click **Finish**
   ![alt text](img/image7.png)


---

## 2. Create Verilog File

1. `File` → `New`
2. Select **Verilog HDL File**
3. Save as `top.v`
   ![alt text](img/image8.png)
4. Write your Verilog module.
![alt text](img/image11.png)
5. Adding external files: `File` → `Project` → `Add Files...`
6. Select `file.v` and click **Apply** and ok:

![alt text](img/image9.png)
![alt text](img/image10.png)
![alt text](img/image13.png)
---

## 3. Synthesis

1. `Processing` → `Start Compilation`
2. Wait for compilation complete

![alt text](img/image14.png)
Success: No critical errors in **Messages** tab.

---

## 4. Physical Constraints (`.qsf`)

1. `Assignments` → `Pins`
![alt text](img/image15.png)
2. Configure pins:

| Port Name | Pin # | IO Type |
|-----------|-------|---------|
| clk | (check board) | LVCMOS |
| led | (check board) | LVCMOS |

![alt text](img/image16.png)

> **Note:** Pins depend on specific MAX II board. Check board documentation.

3. Save project (Ctrl+S) and re-compile
![alt text](img/image17.png)

---

## 5. Place & Route

Already done during compilation (step 3)

---

## 7. Programming

1. Connect board via **USB Blaster**
2. `Tools` → `Programmer`
![alt text](img/image18.png)
3. Click **Hardware Setup** and select USB Blaster port
![alt text](img/image19.png)
4. Click **Start** to program
![alt text](img/image20.png)

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
