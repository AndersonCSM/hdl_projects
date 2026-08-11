# Quartus Prime Lite — Installation

Guide to installing Quartus Prime Lite for development with Altera MAX II boards.

**Platform:** Quartus Prime lite  
**Recommended Version:** 20.1  
**Support:** Linux and Windows  
**Programming:** USB Blaster

---

## Index

1. [Overview](#overview)
2. [Linux Installation](#linux-installation)
3. [Windows Installation](#windows-installation)
4. [USB Blaster Configuration](#usb-blaster-configuration)
5. [MAX II Programming](#max-ii-programming)
6. [Troubleshooting](#troubleshooting)

---

## Visão Geral

**Quartus Prime Lite** é a IDE da Intel (Altera) para desenvolvimento em placas MAX II.

| Característica | Valor |
|---|---|
| **Licença** | Gratuita (Lite) |
| **Download** | [intel.com/quartus](https://www.intel.com/content/www/us/en/software/programmable/quartus-prime/overview.html) |
| **Programador** | USB Blaster |
| **Versão Mínima** | 20.1 |

---

## Instalação no Linux

### 1. Download

Acesse: https://www.intel.com/content/www/us/en/software/programmable/quartus-prime/download.html

Escolha:
- **Operacional System:** Linux
- **Version:** 20.1 (ou mais recente)
- **File:** `Quartus-lite-20.1.0.711-linux.tar.gz`

### 2. Extrair e Instalar

```bash
# Extrair
tar -xzf Quartus-lite-20.1.0.711-linux.tar.gz

# Navegar
cd quartus

# Executar instalador
./setup.sh
```

O instalador abrirá uma interface gráfica. Siga as instruções padrão.

### 3. Configurar Variáveis de Ambiente

Editar `~/.bashrc`:

```bash
nano ~/.bashrc
```

Adicionar ao final:

```bash
# Quartus Prime 20.1 (Linux)
export QUARTUS_ROOTDIR="$HOME/intelFPGA_lite/20.1/quartus"
export PATH="$QUARTUS_ROOTDIR/bin:$PATH"
export LD_LIBRARY_PATH="$QUARTUS_ROOTDIR/linux64:$LD_LIBRARY_PATH"
```

Recarregar:

```bash
source ~/.bashrc
```

### 4. Verificar Instalação

```bash
quartus --version
jtagconfig
```

---

## Instalação no Windows

### 1. Download

Acesse: https://www.intel.com/content/www/us/en/software/programmable/quartus-prime/download.html

Escolha:
- **Operating System:** Windows
- **Version:** 20.1 (ou mais recente)
- **File:** `QuartusSetup-20.1.0.711.exe` ou similar

### 2. Executar Instalador

1. Clique com botão direito no arquivo `.exe`
2. Selecione **Executar como Administrador**
3. Aceite os termos de licença
4. Siga o wizard padrão de instalação

O instalador pode levar 30-60 minutos.

### 3. Adicionar ao PATH (Opcional)

Abra **PowerShell como Administrador** e execute:

```powershell
$quartus_path = "C:\intelFPGA_lite\20.1\quartus\bin"
[Environment]::SetEnvironmentVariable("Path", "$env:Path;$quartus_path", "User")
```

Reinicie o PowerShell para aplicar.

### 4. Verificar Instalação

```powershell
quartus --version
jtagconfig
```

---

## Configuração USB Blaster

O USB Blaster é o programador para conectar-se à placa MAX II.

### Linux: Regras udev

```bash
sudo tee /etc/udev/rules.d/51-altera-usb-blaster.rules > /dev/null << 'EOF'
# Altera USB-Blaster
SUBSYSTEM=="usb", ATTRS{idVendor}=="09fb", ATTRS{idProduct}=="6001", MODE="0666"
SUBSYSTEM=="usb", ATTRS{idVendor}=="09fb", ATTRS{idProduct}=="6002", MODE="0666"
SUBSYSTEM=="usb", ATTRS{idVendor}=="09fb", ATTRS{idProduct}=="6003", MODE="0666"
SUBSYSTEM=="usb", ATTRS{idVendor}=="09fb", ATTRS{idProduct}=="6010", MODE="0666"
SUBSYSTEM=="usb", ATTRS{idVendor}=="09fb", ATTRS{idProduct}=="6810", MODE="0666"
EOF

# Recarregar regras
sudo udevadm control --reload-rules
sudo udevadm trigger

# Adicionar usuário ao grupo dialout
sudo usermod -a -G dialout $USER

# Fazer logout e login para aplicar
```

### Windows: Drivers

O instalador do Quartus já instala os drivers USB Blaster automaticamente.

#### Verificação Inicial

1. Conecte a placa MAX II via USB Blaster
2. Abra **Gerenciador de Dispositivos** (Win+X → Gerenciador de Dispositivos)
3. Procure por "Altera" ou "USB Blaster"
4. Se os drivers estiverem instalados, aparecerá normalmente
5. Se houver **ponto de exclamação**, instale drivers manualmente (veja abaixo)

#### Instalação Manual dos Drivers

Se os drivers não foram instalados automaticamente, instale manualmente:

##### Passo 1: Localizar a Pasta de Drivers

```
C:\intelFPGA_lite\20.1\quartus\drivers\
```

ou, se instalou em outro local:

```
C:\Program Files\Intel\Quartus Prime\[versão]\drivers\
```

##### Passo 2: Conectar o USB Blaster

1. Conecte a placa MAX II ao computador via **USB Blaster**
2. Aguarde o Windows tentar detectar o dispositivo (pode falhar inicialmente)

##### Passo 3: Abrir Gerenciador de Dispositivos

1. Pressione **Win+X** e selecione **Gerenciador de Dispositivos**
2. Localize o USB Blaster (pode estar em "Portas COM e LPT" ou "Dispositivos Desconhecidos" com ponto de exclamação)
3. Clique com botão direito e selecione **Atualizar driver**

##### Passo 4: Instalar Driver Manualmente

Escolha a opção **"Procurar driver no meu computador"**:

```
C:\intelFPGA_lite\20.1\quartus\drivers\usb-blaster\
```

Se essa pasta não existir, tente:

```
C:\intelFPGA_lite\20.1\quartus\drivers\
```

##### Passo 5: Verificar Instalação

Após a instalação:
1. Abra **PowerShell como Administrador**
2. Execute:
   ```powershell
   jtagconfig
   ```

Saída esperada (sem erros):
```
1) USB-Blaster on ??
  02E600DD     EPCS16  (1x16)
  02E600DD     MAX II Device
```

**Atenção**: o diretório é a pasta 'usb-blaster', não x64 ou x32.

Para mais informações segue link da [documentação oficial](https://www.intel.com.br/content/www/br/pt/support/programmable/support-resources/download/dri-usb-blaster-vista.html).

#### Alternativa: Script de Instalação (Adcanced)

Se tiver acesso ao script de instalação:

```powershell
# Navegar até a pasta de drivers
cd "C:\intelFPGA_lite\20.1\quartus\drivers\usb-blaster\"

# Executar instalador (se existir)
.\install.bat
# ou
.\setup.exe
```

---

## Programação de MAX II

### Encontrar Dispositivos

```bash
# Linux
jtagconfig

# Windows (PowerShell)
jtagconfig
```

Saída esperada:
```
1) USB-Blaster on ??
  02E600DD     EPCS16  (1x16)
  02E600DD     MAX II Device
```

### Programar

Gere o arquivo `.svf` no Quartus, então programe:

```bash
# Linux
cd hdl/max_ii/blink
quartus_pgm -c "1" -m JTAG -o "P;top.svf"

# Windows (PowerShell)
cd hdl\max_ii\blink
quartus_pgm -c "1" -m JTAG -o "P;top.svf"
```

### Quick Diagnostics

```bash
# Listar dispositivos
jtagconfig

# Listar programadores conhecidos
quartus_pgm -l

# Verificar USB
lsusb | grep Altera        # Linux
# ou no Windows:
Get-PnpDevice -Class USB   # PowerShell
```

---

## Troubleshooting

### "Command not found: quartus"

**Solução:**
```bash
# 1. Verificar instalação
ls -la ~/intelFPGA_lite/20.1/quartus/bin/

# 2. Verificar ~/.bashrc
cat ~/.bashrc | grep QUARTUS_ROOTDIR

# 3. Recarregar
source ~/.bashrc

# 4. Testar
quartus --version
```

### USB Blaster não detectado

**Verificações:**
```bash
# Linux
lsusb | grep Altera

# Se não aparecer:
sudo udevadm control --reload-rules
sudo udevadm trigger

# Reconectar placa e testar
jtagconfig
```

### Permissões insuficientes

```bash
# Executar com sudo
sudo quartus_pgm -c "1" -m JTAG -o "P;top.svf"

# Ou adicionar usuário ao grupo
sudo usermod -a -G dialout $USER
```

---

## Referências

- **Intel Quartus:** https://www.intel.com/quartus
- **MAX II Documentation:** https://www.intel.com/content/www/us/en/software/programmable/quartus-prime/support.html
- **USB Blaster:** https://www.intel.com/content/dam/altera-www/global/en_US/pdfs/literature/ug/ug_usb_blaster.pdf
