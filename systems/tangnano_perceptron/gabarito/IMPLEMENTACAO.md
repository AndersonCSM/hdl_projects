# Implementação do Perceptron - Resumo Executivo

## 📋 Visão Geral

Foi implementado um **Perceptron Single Layer** em Verilog para a placa **Tang Nano 1K**, com arquitetura modular composta por 3 módulos principais:

1. **top.v** - Interface principal com botões/leds
2. **control.v** - Máquina de Estados Finita (FSM)
3. **datapath.v** - Núcleo do Perceptron (cálculos)

---

## 🏗️ Arquitetura do Sistema

```
┌─────────────────────────────────────────────────────────┐
│                      TOP (Interface)                     │
│   btn1=Reset | btn2=Start/Train |  led[5:0]=W0/W1      │
└──────────────┬──────────────────────┬────────────────────┘
               │                      │
        ┌──────▼──────┐        ┌──────▼──────┐
        │  CONTROL    │        │  DATAPATH   │
        │  (FSM)      │◄──────►│(Perceptron) │
        │             │        │             │
        │ 4 States:   │        │ • W0, W1    │
        │ • Start     │        │ • N (count) │
        │ • Wait      │        │ • EP (epoch)│
        │ • Forward   │        │ • Treino    │
        │ • Backprop  │        │ • Dados OR  │
        └─────────────┘        └─────────────┘
```

---

## 🧠 Algoritmo do Perceptron

### Dados de Treinamento (Porta OR)
```
Entrada (x0, x1) │ Saída (y)
──────────────────┼─────────
    (0, 0)        │   0
    (0, 1)        │   1
    (1, 0)        │   1
    (1, 1)        │   1
```

### Funcionamento

1. **Forward Pass** (Propagação Direta):
   - soma = x0*w0 + x1*w1
   - y_pred = (soma >= LIMIAR) ? 1 : 0
   - erro = y_target - y_pred

2. **Aprendizado** (se erro ≠ 0):
   - w0 ← w0 + erro × x0
   - w1 ← w1 + erro × x1

3. **Épocas**:
   - Repete para todos os 4 padrões
   - Repete para até 15 épocas (até convergência)

---

## 📊 Módulos Implementados

### 1. **datapath.v** - Perceptron

#### Registradores Principais:
```verilog
reg signed [7:0] w0, w1;      // Pesos (8 bits com sinal)
reg [3:0] N, EP;             // Contadores de padrão e época
reg [1:0] x [3:0];           // Dados de entrada (4 amostras)
reg [0:0] y_target [3:0];    // Dados esperados
reg signed [15:0] soma;      // Soma ponderada
reg signed [1:0] erro;       // Erro calculado
```

#### Sinais de Controle (entrada):
- `load_w0, load_w1`: Carregar novos pesos
- `clear_w0, clear_w1`: Zerar pesos individuais
- `clrw`: Reset global dos pesos
- `load_epoch, clear_epoch`: Incrementar/zerar época
- `load_n, clear_n`: Incrementar/zerar padrão
- `calcular`: Habilitar forward pass
- `lerp`: Ativar aprendizado

#### Sinais de Status (saída):
- `epoch_menor`: Se época < MAX (ainda pode treinar)
- `n_maior`: Se padrão > 3 (terminou todos)
- `y_pred`: Saída do perceptron
- `w0, w1`: Pesos atuais

### 2. **control.v** - FSM (Máquina de Estados)

#### Estados:

| Estado | Descrição | Ação | Próximo |
|--------|-----------|------|---------|
| **Start** | Inicializar | Limpar pesos, épocas, padrões | Wait |
| **Wait** | Aguardar | Espera btn2 pressionado | Forward |
| **Forward** | Calcular | Calcula predição e erro | Backprop |
| **Backprop** | Atualizar | Atualiza pesos e contadores | Forward ou Wait |

#### Sequência de Execução:
```
[Start] → (clrw=1) → [Wait] 
    ↓ (btn2=1)
[Forward] → (calcular=1, lerp=1)
    ↓
[Backprop] → (load_n=1)
    ↓
┌─ Se N > 3:
│  ├─ clear_n=1 (reseta padrões)
│  ├─ load_epoch=1 (próxima época)
│  ├─ Se EP >= MAX: → [Wait]
│  └─ Senão: → [Forward]
└─ Senão: → [Forward]
```

### 3. **top.v** - Interface

#### Funcionalidade:
- **Clock Divider**: Reduz 27MHz para ~1Hz
- **Conversão Reset**: btn1 (ativo baixo) → rst (ativo alto)
- **Interconnects**: Liga control + datapath
- **LEDs**: Mostra 3 bits de w0 + 3 bits de w1

#### Pinagem:
```
Entrada:
  clk (27MHz)
  btn1 = Reset (ativo baixo)
  btn2 = Start Treino (ativo baixo)

Saída:
  led[2:0] = w0[2:0]
  led[5:3] = w1[2:0]
```

---

## 🔧 Características Técnicas

### Largura de Bits:
- Entradas: 1 bit (0 ou 1)
- Pesos: 8 bits com sinal (signed)
- Soma intermediária: 16 bits (para não overflow)
- Erro: 2 bits com sinal
- Épocas: 4 bits (0-15)
- Padrões: 4 bits (0-3)

### Parâmetros:
```verilog
parameter signed LIMIAR = 32'd1;      // Threshold
parameter MAX_EPOCH = 4'd15;          // Máximo de épocas
```

### Frequência de Operação:
- Clock original: 27 MHz
- Clock aplicado: ~1 Hz (após divisor)
- Período: ~1 segundo

---

## ✨ Melhorias Implementadas

1. ✅ **Inicialização correta**: Dados de treino carregados no `initial`
2. ✅ **Contadores sincronizados**: N e EP funcionam adequadamente
3. ✅ **Status signals**: Permitem FSM tomar decisões corretas
4. ✅ **Aprendizado Hebbiano**: w ← w + erro × entrada
5. ✅ **Épocas**: Suporta múltiplas rodadas de treinamento
6. ✅ **Modularidade**: Fácil integração e teste

---

## 🧪 Teste Esperado

### Sequência de Operação:

1. **Reset (btn1)**: Limpa tudo
2. **Start (btn2)**: Inicia treinamento
3. **FSM executa**:
   - Calcula predição para amostra 1
   - Atualiza pesos se houver erro
   - Passa para amostra 2
   - ... amostra 3, 4
   - Incrementa época e volta para amostra 1
4. **LEDs mostram**: Valores de w0 e w1 durante treinamento

### Convergência Esperada (Porta OR):
- **w0**: ~1 (ou próximo)
- **w1**: ~1 (ou próximo)
- **Padrão**: LED pisca mostrando w0[2:0] e w1[2:0]

---

## 📝 Exemplo de Síntese

Para compilar e programar a FPGA:

```bash
cd /path/to/perceptron/gabarito/
make all           # Síntese + Place&Route
make loadram       # Programar a placa
```

---

## 🔍 Validação

✅ **Sem erros de sintaxe Verilog**
✅ **Módulos compilam corretamente**
✅ **Sinais bem definidos**
✅ **FSM implementada com 4 estados**
✅ **Algoritmo perceptron correto**
✅ **Dados de treino (OR) carregados**

---

## 📚 Referências

- **Diagrama de Arquitetura**: Veja `image.png`
- **Prova/Especificações**: Veja `Prova___sistemas_3-1.pdf`
- **Estratégias de Teste**: Veja `TESTING.md`
- **Instruções BUILD**: Veja `Makefile`

---

**Projeto Concluído!** 🎉

O Perceptron está pronto para ser sintetizado e programado na placa Tang Nano 1K.
