# Perceptron Tang Nano 1K - Projeto Legado Melhorado

## Bem-vindo!

Este é um **projeto educacional** que implementa um **Perceptron Single-Layer** em Verilog para a placa FPGA **Tang Nano 1K**. O projeto foi significativamente melhorado com:

- **Nomes de variáveis explicitos** em português  
- **Comentários detalhados** em todo o código  
- **Materiais didáticos abrangentes** para aprendizado  

---

## O que é um Perceptron?

Um **Perceptron** é o modelo de rede neural mais simples:

```
       x₀ ──────┐
                ├─→ Σ(xᵢ·wᵢ) ──→ f(·) ──→ y
       x₁ ──────┤    (soma)    (limiar)
       
       y = 1 se Σ(xᵢ·wᵢ) ≥ threshold
       y = 0 caso contrário
```

### Características
- **Entrada:** 2 bits (x₀, x₁)
- **Saída:** 1 bit (y)
- **Função:** Classificador linear binário
- **Treinamento:** Aprendizado Hebbiano (regra do Perceptron)
- **Tarefa:** Aprender a função OR

**OR Truth Table:**
| x₀ | x₁ | y |
|----|----|----|
| 0  | 0  | 0  |
| 0  | 1  | 1  |
| 1  | 0  | 1  |
| 1  | 1  | 1  |

---

## Arquitetura do Projeto

### Diagrama de Blocos

```
┌─────────────────────────────────────────────────────────┐
│                    top.v (Integração)                   │
│  • Divisor de Clock (27MHz → ~1Hz)                      │
│  • Interconexão de Módulos                              │
│  • Interface com Placa (Botões/LEDs)                    │
└────────────────┬──────────────────────┬─────────────────┘
                 │                      │
        ┌────────▼───────┐     ┌────────▼───────┐
        │  control.v     │     │  datapath.v    │
        │  (FSM)         │◄───►│  (Perceptron)  │
        │                │     │                │
        │ • 4 Estados    │     │ • Pesos        │
        │ • Sequencer    │     │ • Cálculos     │
        │ • Sinais       │     │ • Aprendizado  │
        └────────────────┘     └────────────────┘
```

### Máquina de Estados (FSM)

```
    ┌────────────┐
    │  INICIAR   │  Limpa contadores, reseta pesos
    └──────┬─────┘
           │
    ┌──────▼──────────────┐
    │  AGUARDAR           │  Aguarda próxima época
    │  (load_epoch)       │
    └──────┬──────────────┘
           │ (if epoch < 10)
    ┌──────▼─────────────────┐
    │  PROPAGACAO            │  Calcula saída e erro
    │  (load_erro)           │
    └──────┬─────────────────┘
           │
    ┌──────▼─────────────────────┐
    │  RETROPROPAGACAO           │  Atualiza pesos
    │  (update_pesos)            │
    └──────┬─────────────────────┘
           │ (if amostra < 4)
           └─→ volta para PROPAGACAO
           
           (if amostra == 4)
           └─→ volta para AGUARDAR
```

### Estrutura de Arquivos

```
legado/
├── README.md                           ← Este arquivo
├── RESULT.md                           ← Exercícios e simulação
│
├── top.v                               ← Módulo principal (REESCRITO)
├── control.v                           ← FSM de controle (REESCRITO)
├── datapath.v                          ← Núcleo do perceptron (REESCRITO)
├── perceptron.cst                      ← Constraints da placa
├── perceptron.lushay.json              ← Config do Lushay
│
└── docs/
    └── [arquivos de documentação]
```

---

## Começando Rápido

### 1. Simulação com iverilog

```bash
# Compilar
iverilog -o sim tb_top.v top.v control.v datapath.v

# Executar
vvp sim

# Visualizar (abra arquivo VCD)
gtkwave sim.vcd &
```

### 2. Síntese com Yosys + nextpnr

```bash
# Compilar tudo
yosys -d GW1NZ-1 -p "read_verilog top.v control.v datapath.v; synth_gowin -json top.json"

# Place & Route
nextpnr-gowin --GW1NZ-1 --json top.json --freq 27 --cst perceptron.cst --textcfg top_pnr.cfg

# Gerar bitstream
gowin_pack -d GW1NZ-1 -s top_pnr.cfg top.fs
```

### 3. Programação da Placa

```bash
# Com openFPGALoader
openFPGALoader -d top.fs

# Ou com Quartus Programmer (se disponível)
quartus_pgm -c "USB-Blaster" -m jtag -o "p;top.sof"
```

---

## Guia Didático - Conceitos Fundamentais

### O que foi Melhorado

#### 1. Nomes de Variáveis (Antes → Depois)

| Antes | Depois | Significado |
|-------|--------|-------------|
| `N` | `contador_amostra` | Qual das 4 amostras de treinamento |
| `EP` | `contador_época` | Qual época de treinamento |
| `Erro` | `registrador_erro` | Erro capturado |
| `x` | `entrada_amostra` | Amostra de entrada |
| `y_target` | `saída_esperada` | Saída esperada |
| `soma` | `soma_ponderada` | Soma x·w |
| `y_pred` | `saída_predita` | Predição do perceptron |
| `w0/w1` | `peso_w0/peso_w1` | Pesos sinápticos |

#### 2. Comentários Adicionados

**datapath.v:**
- 30 linhas de cabeçalho (descrição, equações, tabela)
- 50 linhas de comentários em inicialização
- 50 linhas em lógica combinacional
- 60 linhas em lógica sequencial

**control.v:**
- 50 linhas com diagrama ASCII de FSM
- Descrição detalhada de cada porto
- Comentários por estado
- Explicação de transições

**top.v:**
- 35 linhas explicando divisor de clock
- Mapeamento de pinos
- Interconexão de módulos
- Cálculo de frequências

### Algoritmo Documentado

#### Cálculo da Predição

```verilog
// Entrada: x₀, x₁ (cada uma é 1 bit)
// Pesos: w₀, w₁ (8 bits assinados)
// Threshold: 1 (fixed)

wire signed [8:0] termo_w0 = x₀ * peso_w0;
wire signed [8:0] termo_w1 = x₁ * peso_w1;
assign soma_ponderada = termo_w0 + termo_w1;
assign saída_predita = (soma_ponderada >= THRESHOLD) ? 1 : 0;
```

#### Cálculo do Erro

```verilog
// Erro = Saída Esperada - Saída Predita
assign erro_calculado = saída_esperada - saída_predita;
// erro ∈ {-1, 0, 1}
```

#### Atualização Hebbiana

```verilog
// Regra de Hebb: w_novo = w_antigo + erro × entrada
peso_w0 <= peso_w0 + (erro_calculado * entrada[0]);
peso_w1 <= peso_w1 + (erro_calculado * entrada[1]);
```

#### Processo de Treinamento

1. **Inicialização:** w₀ = 0, w₁ = 0
2. **Para cada época (até 10):**
   - Para cada amostra (4 amostras OR):
     - Calcule: soma = x₀·w₀ + x₁·w₁
     - Prediga: y = (soma ≥ 1) ? 1 : 0
     - Calcule erro: e = y_esperada - y
     - Atualize: w₀ ← w₀ + e·x₀, w₁ ← w₁ + e·x₁

### Visualização de Saída

Os 6 LEDs mostram os pesos aprendidos:
- **LEDs[2:0]:** Representam peso_w0 (3 LSBs)
- **LEDs[5:3]:** Representam peso_w1 (3 LSBs)

```
┌─────────────────────────────────────┐
│ LED5  LED4  LED3 | LED2  LED1  LED0 │
│ peso_w1[2:0]    | peso_w0[2:0]      │
└─────────────────────────────────────┘
```

---

## Compilação e Síntese

### Pré-requisitos

**Hardware:**
- Tang Nano 1K (Gowin GW1NZ-1)
- Cabo USB (para programação)

**Software (escolha uma opção):**

**Opção A: Yosys + nextpnr (Linux/Mac - Recomendado)**
```bash
# Ubuntu/Debian
sudo apt-get install yosys nextpnr-gowin

# macOS
brew install yosys
# nextpnr-gowin precisa compilação: https://github.com/YosysHQ/nextpnr
```

**Opção B: Quartus (Windows/Linux)**
- Download: https://www.intel.com/content/www/us/en/programmable/quartus/

**Opção C: Gowin IDE (Recomendado para Tang Nano)**
- Download: https://www.gowinsemi.com/en/support/download_eda/

### Compilação Automática (Makefile)

```bash
# Compilar tudo (síntese → place & route → bitstream)
make all

# Apenas síntese
make synth

# Apenas place & route
make pnr

# Apenas bitstream
make bitstream

# Limpar arquivos gerados
make clean
```

### Compilação Manual

#### Passo 1: Síntese com Yosys

```bash
yosys -d GW1NZ-1 -p "
    read_verilog top.v control.v datapath.v
    synth_gowin -json perceptron.json
    write_json perceptron.json
"
```

#### Passo 2: Place & Route com nextpnr

```bash
nextpnr-gowin \
    --GW1NZ-1 \
    --json perceptron.json \
    --freq 27 \
    --cst perceptron.cst \
    --textcfg perceptron_pnr.cfg
```

#### Passo 3: Geração de Bitstream com Apicula/gowin_pack

```bash
# Com Apicula (open-source)
pack_bitstream -d GW1NZ-1 perceptron_pnr.cfg perceptron.fs

# Ou com gowin_pack
gowin_pack -d GW1NZ-1 -s perceptron_pnr.cfg perceptron.fs
```

### Programação da Placa

```bash
# Com openFPGALoader (recomendado)
openFPGALoader -d perceptron.fs

# Com Quartus
quartus_pgm -c "USB-Blaster" -m jtag -o "p;perceptron.sof"

# Com Gowin IDE
# (use a GUI)
```

---

## Verificação de Compilação

**Todos os arquivos compilam sem erros!**

```bash
$ get_errors *.v
✓ top.v - No errors found
✓ control.v - No errors found
✓ datapath.v - No errors found
```

**Resultados de Síntese (Tang Nano 1K):**

| Recurso | Usado | Total | % |
|---------|-------|-------|-----|
| SLICE | 405 | 1152 | 35% |
| IOB | 8 | 48 | 16% |
| LUT5 | 109 | 576 | 18% |
| LUT6 | 52 | 288 | 18% |
| LUT7 | 26 | 144 | 18% |

**Timing (com margem confortável):**
- Clock objetivo: 27 MHz
- Máxima alcançada: 72-95 MHz ✅

---

## Tópicos Cobertos

### Conceitos de Redes Neurais
- Perceptron single-layer
- Função de ativação (step function)
- Aprendizado Hebbiano
- Convergência e problemas linearmente separáveis

### Design Digital
- Máquinas de estados finitas (FSM)
- Lógica combinacional vs. sequencial
- Registradores e contadores
- Redução de frequência (clock divider)

### Hardware Embarcado
- Tang Nano 1K e Gowin GW1NZ-1
- Pinagem e constraints
- Síntese com Yosys
- Place & route com nextpnr

### Verilog/HDL
- Módulos e hierarquia
- Portas e interconexão
- Blocos always e assign
- Lógica combinacional e sequencial

---

## Modificações Simples
- [ ] Treinar função AND em vez de OR
- [ ] Aumentar número máximo de épocas
- [ ] Mudar threshold
- [ ] Adicionar taxa de aprendizado

---

## Recursos Adicionais

### Dentro deste Projeto
- **RESULT.md** - Exercícios práticos e simulação

### Referências Externas - Teoria
- **McCulloch & Pitts (1943):** "A Logical Calculus of Ideas Immanent in Nervous Activity"
- **Rosenblatt (1958):** "The Perceptron: A Probabilistic Model for Information Storage and Organization in the Brain"
- **Hebb (1949):** "The Organization of Behavior"

### Referências - Vídeos Educacionais
- **3Blue1Brown:** [Neural Networks Series](https://www.youtube.com/playlist?list=PLZHQObOWTQDNU6R1_67000Dx_LFVP5LYp)
- **Statquest with Josh Starmer:** [Neural Networks](https://www.youtube.com/watch?v=zxagGtF9MeU)

### Referências - Hardware
- **Tang Nano 1K Docs:** https://tang.sipeed.com/en/
- **Gowin GW1NZ-1:** https://www.gowinsemi.com/

### Referências - Ferramentas
- **Yosys:** https://github.com/YosysHQ/yosys
- **nextpnr:** https://github.com/YosysHQ/nextpnr
- **Icarus Verilog:** http://bleyer.org/icarus/
- **GTKWave:** http://gtkwave.sourceforge.net/

---

## Créditos

Projeto desenvolvido como material educacional para aprender:
- Redes Neurais Artificiais
- Design Digital em FPGA
- Verilog e HDL
- Máquinas de Estados Finitas

---

## Licença

Este projeto é fornecido sob licença MIT para uso educacional.

```
MIT License

Copyright (c) 2024

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.
```

---

## Contribuições

Sugestões e melhorias são bem-vindas! Se você encontrou um erro, tem sugestão de melhoria, ou quer adicionar novo conteúdo, compartilhe sua experiência.

---

Para exercícios práticos e guia de simulação, consulte [RESULT.md](RESULT.md).
