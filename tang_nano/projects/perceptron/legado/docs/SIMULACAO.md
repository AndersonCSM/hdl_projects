# Guia de Simulação e Debug

## 📋 Índice

1. [Pré-requisitos](#pré-requisitos)
2. [Compilação e Simulação](#compilação-e-simulação)
3. [Análise com GTKWave](#análise-com-gtkwave)
4. [Debugging Prático](#debugging-prático)
5. [Troubleshooting](#troubleshooting)

---

## Pré-requisitos

### Instalação de Ferramentas

**Ubuntu/Debian:**
```bash
sudo apt-get install iverilog gtkwave
```

**macOS:**
```bash
brew install icarus-verilog gtkwave
```

**Windows:**
- Use WSL (Windows Subsystem for Linux) com instruções Linux, ou
- Download de http://bleyer.org/icarus/ e http://gtkwave.sourceforge.net/

### Verificar Instalação

```bash
# Verificar iverilog
iverilog -version

# Verificar gtkwave
gtkwave --version
```

---

## Compilação e Simulação

### Usando o Makefile (Recomendado)

#### Opção 1: Simulação Completa (Compile → Run → View)

```bash
# Compilar, simular e abrir GTKWave tudo de uma vez
make sim
```

**O que acontece:**
1. Compila `tb_top.v`, `top.v`, `control.v`, `datapath.v` com iverilog
2. Executa a simulação gerando arquivo `sim.vcd`
3. Abre `sim.vcd` automaticamente no GTKWave

#### Opção 2: Etapas Separadas

**Apenas compilar:**
```bash
make sim-compile
```
Gera: `sim_top` (executável)

**Apenas simular:**
```bash
make sim-run
```
Gera: `sim.vcd` (arquivo de waveform)
Gera: `sim.log` (log de saída)

**Apenas visualizar:**
```bash
make sim-view
```
Abre o GTKWave com o arquivo `sim.vcd`

#### Opção 3: Limpar

```bash
# Remover arquivos de simulação
make sim-clean
```

---

### Usando Comandos Manuais (sem Makefile)

Se preferir executar manualmente:

#### Passo 1: Compilar

```bash
iverilog -o sim_top tb_top.v top.v control.v datapath.v
```

**Saída esperada:**
- Nenhuma mensagem = compilação bem-sucedida ✓
- Mensagens de erro = verifique [Troubleshooting](#troubleshooting)

#### Passo 2: Executar Simulação

```bash
vvp sim_top > sim.log
```

**Arquivos gerados:**
- `sim.vcd` - Arquivo de waveform (para visualização)
- `sim.log` - Log de saída e mensagens de debug

**Tempo esperado:** ~30-60 segundos (depende do computador)

#### Passo 3: Visualizar com GTKWave

```bash
gtkwave sim.vcd &
```

---

## Análise com GTKWave

### Interface do GTKWave

```
┌─────────────────────────────────────────────────────────┐
│ GTKWave - sim.vcd                                      │
├──────────────┬──────────────────────────────────────────┤
│ Hierarquia   │ Sinais                                   │
│ (esquerda)   │ (centro)                                 │
│              │                                          │
│ ✓ tb_top     │ Gráfico de waveforms                     │
│   ✓ clk_tb   │ (mostra sinais vs. tempo)                │
│   ✓ btn1_tb  │                                          │
│   ✓ led_tb   │                                          │
│   ✓ dut      │ ┌─────────────────────────────────────┐ │
│     ✓ top    │ │ clk  ─┬─┐─┬─┐─┬─┐─┬─┐─┬─┐         │ │
│     ✓ control│ │      │ │ │ │ │ │ │ │ │ │           │ │
│     ✓ datapath│ │ led  ├─┴─┴─┴─┴─┴─┴─┴─┴─┤           │ │
│              │ │      └─────────────────────┘           │ │
│ Zoom: ⊕ ⊖   │ │                                        │ │
│              │ │ 0ns         100ns       200ns         │ │
│              └──────────────────────────────────────────┘
│                                                         │
└─────────────────────────────────────────────────────────┘
```

### Navegação Básica

#### Seleção de Sinais

1. **Expandir hierarquia** (esquerda):
   - Clique em `▶` para expandir módulos
   - Exemplo: Click em `▶ dut` para ver `top`, `control`, `datapath`

2. **Adicionar sinais ao gráfico**:
   - Click duplo em um sinal na hierarquia
   - Ou arraste para a área de waveform (centro)

3. **Sinais importantes para monitorar**:
   ```
   tb_top.clk_tb          - Clock de 27 MHz
   tb_top.btn1_tb         - Botão de reset
   tb_top.led_tb[5:0]     - 6 LEDs (saída)
   tb_top.dut.clk_util    - Clock reduzido (~1 Hz)
   tb_top.dut.reset_ativo_alto - Sinal de reset
   tb_top.estado_atual    - Estado da FSM (2 bits)
   tb_top.contador_amostra - Índice da amostra (0-3)
   tb_top.contador_epoca  - Número da época
   tb_top.peso_w0         - Peso w0
   tb_top.peso_w1         - Peso w1
   tb_top.soma_ponderada  - Soma dos pesos
   tb_top.saida_predita   - Saída do perceptron
   tb_top.erro_calculado  - Erro calculado
   ```

#### Zoom e Navegação

| Ação | Como Fazer |
|------|-----------|
| Zoom In | Botão `⊕` ou `Ctrl+Scroll`
| Zoom Out | Botão `⊖` ou `Scroll`
| Zoom em seleção | `Z` (selecione com mouse)
| Voltar zoom | `Alt+Z`
| Fit all | `Alt+A`
| Scroll esquerda | Seta esquerda ou botão esquerdo do mouse
| Scroll direita | Seta direita

#### Cursor e Medições

1. **Primary cursor** (cursor principal):
   - Click em um ponto do gráfico
   - Mostra tempo e valores dos sinais

2. **Secondary cursor**:
   - Ctrl+Click em outro ponto
   - Mostra diferença de tempo entre cursores

3. **Medir período de clock**:
   - Click na primeira subida de `clk_tb`
   - Ctrl+Click na próxima subida
   - Delta mostrado na parte inferior

---

## Debugging Prático

### Cenário 1: Verificar Clock Reduzido

**Objetivo:** Confirmar que o divisor de clock está funcionando

**Passos:**

1. Abra GTKWave: `make sim-view`
2. Adicione sinais:
   - `clk_tb` (clock original 27 MHz)
   - `clk_util` (clock reduzido)
3. Zoom out até ver múltiplos períodos
4. Observe:
   - `clk_tb` oscila rapidamente (período ≈ 37 ns)
   - `clk_util` oscila lentamente (período ≈ 1 segundo)

**Esperado:**
```
clk_tb   : ─┬─┐─┬─┐─┬─┐─┬─┐─┬─┐─┬─┐─┬─┐─┬─┐─ (rápido)
           └─┘ └─┘ └─┘ └─┘ └─┘ └─┘ └─┘ └─┘

clk_util : ─────────────┐─────────────────┐─ (lento)
                        └─────────────────┘
```

### Cenário 2: Verificar Estados da FSM

**Objetivo:** Confirmar transições de estado

**Passos:**

1. Adicione `estado_atual` (2 bits) ao gráfico
2. Zoom em `clk_util` para ver uma época completa
3. Observe sequência de estados:

```
Valores de estado_atual:
  2'b00 = INICIAR
  2'b01 = AGUARDAR
  2'b10 = PROPAGACAO
  2'b11 = RETRO
```

**Esperado para cada época:**
```
INICIAR (00) → AGUARDAR (01) → PROPAGACAO (10) → RETRO (11) 
                    ↑ volta aqui após processar 4 amostras
```

### Cenário 3: Monitorar Pesos Durante Treinamento

**Objetivo:** Ver como pesos mudam durante treinamento

**Passos:**

1. Adicione:
   - `contador_amostra` (qual amostra)
   - `contador_epoca` (qual época)
   - `peso_w0` (peso w0 assinado)
   - `peso_w1` (peso w1 assinado)

2. Zoom em `clk_util` para ver múltiplas épocas (zoom bem out)
3. Observe mudanças:
   - Pesos devem mudar durante RETRO
   - Pesos devem convergir (parar de mudar após ~2 épocas)

**Esperado:**
```
Época 0: w0=0,   w1=0
Época 1: w0=1,   w1=1    (mudou!)
Época 2: w0=1,   w1=1    (convergiu)
Época 3: w0=1,   w1=1    (sem mudança)
```

### Cenário 4: Analisar Erro e Atualização

**Objetivo:** Entender cálculo de erro e atualização de pesos

**Passos:**

1. Adicione:
   - `contador_amostra`
   - `soma_ponderada` (assinado, 9 bits)
   - `saida_predita` (1 bit)
   - `erro_calculado` (assinado, 2 bits)
   - `peso_w0`, `peso_w1` (8 bits assinados)

2. Zoom em `clk_util` até ver um ciclo completo (PROPAGACAO → RETRO)

3. Analise manualmente:
   - **PROPAGACAO**: Calcula `soma = x0*w0 + x1*w1`
   - **PROPAGACAO**: Calcula `erro = y_esperada - y_predita`
   - **RETRO**: Atualiza `w0 += erro * x0`, `w1 += erro * x1`

**Exemplo:**
```
Amostra 1, Época 1:
  entrada = (0, 1), y_esperada = 1
  peso_w0 = 0, peso_w1 = 0
  
  PROPAGACAO:
    soma = 0*0 + 1*0 = 0
    y_predita = (0 >= 1) ? 1 : 0 = 0
    erro = 1 - 0 = 1
  
  RETRO:
    w0 = 0 + (1 * 0) = 0
    w1 = 0 + (1 * 1) = 1  ← mudou!
```

### Cenário 5: Verificar Saídas dos LEDs

**Objetivo:** Confirmar mapeamento correto dos LEDs

**Passos:**

1. Adicione:
   - `led_tb[5:0]` (mostrar como números hexadecimais)
   - `peso_w0[2:0]`
   - `peso_w1[2:0]`

2. Zoom em múltiplas épocas

3. Verifique correspondência:
```
LED = {peso_w1[2:0], peso_w0[2:0]}

Exemplo:
  peso_w0 = 0001 → peso_w0[2:0] = 001
  peso_w1 = 0001 → peso_w1[2:0] = 001
  LED = {001, 001} = 001001 = 0x09
```

---

## Troubleshooting

### Erro: "iverilog: command not found"

**Causa:** iverilog não instalado ou não no PATH

**Solução:**
```bash
# Reinstalar
sudo apt-get install iverilog

# Ou verificar instalação
which iverilog
```

---

### Erro: "Module `top' not found!"

**Causa:** `top.v` não incluído na compilação

**Solução:**
```bash
# Verificar que top.v existe
ls -la top.v

# Verificar comando
iverilog -o sim_top tb_top.v top.v control.v datapath.v
                             ↑ não esqueça!
```

---

### Erro: "Undefined signal in module tb_top"

**Causa:** Assinatura incorreta em tb_top.v ou módulo não instanciado corretamente

**Solução:**
```bash
# Verifique assinatura de top.v
head -30 top.v

# Compare com instanciação em tb_top.v
grep -A 5 "top dut" tb_top.v

# Deve haver correspondência de portos
```

---

### GTKWave Vazio (sem sinais)

**Causa:** VCD não gerado ou corrompido

**Solução:**
```bash
# Verificar arquivo VCD
file sim.vcd

# Recriar VCD
make sim-clean
make sim-run

# Se ainda vazio, verificar log
tail -50 sim.log
```

---

### Simulação Muito Lenta

**Causa:** Simulando por muito tempo (27M ciclos de clock = lento!)

**Solução:**

Opção 1: Reduzir tempo de simulação em `tb_top.v`
```verilog
// Linha ~165 em tb_top.v
#3_000_000_000;  // 3 segundos - MUITO LONGO
// Mude para:
#500_000_000;    // 0.5 segundos
```

Opção 2: Aumentar velocidade do clock (diminuir período)
```verilog
// Linha ~118
#18.52 clk_tb = ~clk_tb;  // 27 MHz
// Mude para:
#1.85 clk_tb = ~clk_tb;   // 270 MHz (10x mais rápido)
```

---

### Pesos não mudam durante simulação

**Possível causa 1:** FSM não está em RETRO quando esperado

**Debug:**
```bash
# Ver log de estado
grep "RETRO\|Transição" sim.log
```

**Possível causa 2:** Sinais de controle não conectados

**Debug:**
```
1. Abra GTKWave
2. Procure por:
   - load_indice_amostra
   - update_pesos
   - load_erro
3. Eles devem mudar durante simulação
```

---

### Erros de compilação estranhos

**Solução geral:**

```bash
# Limpar tudo
make sim-clean

# Recompilar do zero
make sim-compile

# Ver mensagens de erro completas
iverilog -o sim_top tb_top.v top.v control.v datapath.v 2>&1 | head -20
```

---

## Dicas de Debug

### Adicionar $display para Output Customizado

Edite `tb_top.v` e adicione em qualquer bloco `always`:

```verilog
always @(posedge clk_util) begin
    if (!reset_ativo_alto) begin
        $display("[T=%0d] w0=%d, w1=%d, erro=%0d", 
                 $time, peso_w0, peso_w1, erro_calculado);
    end
end
```

Recompile e execute:
```bash
make sim-clean sim-run
```

### Usar $monitor para Output Automático

```verilog
initial begin
    $monitor("[%0t ns] Amostra=%d, Época=%d, w0=%d, w1=%d",
             $time, contador_amostra, contador_epoca, peso_w0, peso_w1);
end
```

---

## Resumo de Comandos Rápidos

```bash
# Simular tudo em um comando
make sim

# Ou etapa por etapa
make sim-compile
make sim-run
make sim-view

# Limpar
make sim-clean

# Ver ajuda
make help
```

---

**Bom debug! 🐛🔍**
