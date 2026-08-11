# Exercícios, Simulação e Verificação

## 📚 Série 1: Conceitos Fundamentais

### Exercício 1.1 - Função de Ativação

**Questão:** Para um perceptron com w₀ = 2, w₁ = -1, e threshold = 1:

a) Calcule a saída para entrada (1, 1):
```
Soma = 1 × 2 + 1 × (-1) = ?
y = (Soma ≥ 1) ? 1 : 0 = ?
```

b) Calcule a saída para entrada (0, 0):
```
Soma = 0 × 2 + 0 × (-1) = ?
y = (Soma ≥ 1) ? 1 : 0 = ?
```

c) Calcule a saída para entrada (1, 0):
```
Soma = 1 × 2 + 0 × (-1) = ?
y = (Soma ≥ 1) ? 1 : 0 = ?
```

**Respostas:**
```
a) Soma = 1, y = 1
b) Soma = 0, y = 0
c) Soma = 2, y = 1
```

---

### Exercício 1.2 - Cálculo de Erro

**Questão:** Para cada entrada abaixo, sabendo que y_esperada = 1 e y_predita é calculada com w₀ = 1, w₁ = 1, threshold = 1:

| Entrada | Soma | y_pred | Erro |
|---------|------|--------|------|
| (0, 0)  | 0    | ?      | ?    |
| (0, 1)  | 1    | ?      | ?    |
| (1, 0)  | 1    | ?      | ?    |
| (1, 1)  | 2    | ?      | ?    |

**Respostas:**
```
| Entrada | Soma | y_pred | Erro |
|---------|------|--------|------|
| (0, 0)  | 0    | 0      | 1    |
| (0, 1)  | 1    | 1      | 0    |
| (1, 0)  | 1    | 1      | 0    |
| (1, 1)  | 2    | 1      | 0    |
```

---

### Exercício 1.3 - Atualização de Pesos

**Questão:** Usando a regra de Hebb: `w_novo = w_antigo + erro × entrada`

Dado: w₀ = 0, w₁ = 0, entrada = (1, 0), erro = 1

Calcule os novos pesos:
```
w₀_novo = 0 + 1 × 1 = ?
w₁_novo = 0 + 1 × 0 = ?
```

**Respostas:**
```
w₀_novo = 1
w₁_novo = 0
```

---

## 📊 Série 2: Treinamento da Porta OR

### Exercício 2.1 - Simulação Manual da Época 1

**Dados:**
```
Amostra 0: x = (0,0), y_esperada = 0
Amostra 1: x = (0,1), y_esperada = 1
Amostra 2: x = (1,0), y_esperada = 1
Amostra 3: x = (1,1), y_esperada = 1

Threshold = 1
Pesos iniciais: w₀ = 0, w₁ = 0
```

**Planilha para preencher (Época 1):**

| Amostra | x₀ | x₁ | Soma | y_pred | y_esp | Erro | w₀_novo | w₁_novo |
|---------|----|----|------|--------|-------|------|---------|---------|
| 0       | 0  | 0  | ?    | ?      | 0     | ?    | ?       | ?       |
| 1       | 0  | 1  | ?    | ?      | 1     | ?    | ?       | ?       |
| 2       | 1  | 0  | ?    | ?      | 1     | ?    | ?       | ?       |
| 3       | 1  | 1  | ?    | ?      | 1     | ?    | ?       | ?       |

**Respostas - Época 1:**

| Amostra | x₀ | x₁ | Soma | y_pred | y_esp | Erro | w₀_novo | w₁_novo |
|---------|----|----|------|--------|-------|------|---------|---------|
| 0       | 0  | 0  | 0    | 0      | 0     | 0    | 0       | 0       |
| 1       | 0  | 1  | 0    | 0      | 1     | 1    | 0       | 1       |
| 2       | 1  | 0  | 0    | 0      | 1     | 1    | 1       | 1       |
| 3       | 1  | 1  | 2    | 1      | 1     | 0    | 1       | 1       |

Pesos após Época 1: **w₀ = 1, w₁ = 1**

### Exercício 2.2 - Simulação Manual da Época 2

Usar w₀ = 1, w₁ = 1 como entrada:

| Amostra | x₀ | x₁ | Soma | y_pred | y_esp | Erro | w₀_novo | w₁_novo |
|---------|----|----|------|--------|-------|------|---------|---------|
| 0       | 0  | 0  | ?    | ?      | 0     | ?    | ?       | ?       |
| 1       | 0  | 1  | ?    | ?      | 1     | ?    | ?       | ?       |
| 2       | 1  | 0  | ?    | ?      | 1     | ?    | ?       | ?       |
| 3       | 1  | 1  | ?    | ?      | 1     | ?    | ?       | ?       |

**Respostas - Época 2:**

| Amostra | x₀ | x₁ | Soma | y_pred | y_esp | Erro | w₀_novo | w₁_novo |
|---------|----|----|------|--------|-------|------|---------|---------|
| 0       | 0  | 0  | 0    | 0      | 0     | 0    | 1       | 1       |
| 1       | 0  | 1  | 1    | 1      | 1     | 0    | 1       | 1       |
| 2       | 1  | 0  | 1    | 1      | 1     | 0    | 1       | 1       |
| 3       | 1  | 1  | 2    | 1      | 1     | 0    | 1       | 1       |

Pesos após Época 2: **w₀ = 1, w₁ = 1** (convergência! ✅)

---

## 💻 Série 3: Simulação com iverilog

### Exercício 3.1 - Compilação e Simulação Básica

**Tarefa:** Execute a simulação do projeto

**Passo 1: Compilar**
```bash
cd /home/anderson/github_projects/embedded_systems/hdl/tang_nano_1k/pj_perceptron/legado

iverilog -o sim_top tb_top.v top.v control.v datapath.v
```

**Passo 2: Executar**
```bash
vvp sim_top > sim.log
```

**Passo 3: Visualizar com GTKWave**
```bash
gtkwave sim.vcd &
```

**O que você deve ver:**
- Clock oscilando entre 0 e 1
- Máquina de estados transitando entre INICIAR → AGUARDAR → PROPAGACAO → RETRO
- LEDs mudando conforme pesos são atualizados

---

### Exercício 3.2 - Análise de Waveforms

**Tarefa:** Abra o arquivo `sim.vcd` no GTKWave e:

1. Encontre a transição de estado **INICIAR → AGUARDAR**
   - O que acontece com os sinais de controle?
   - Como `registrador_erro` é resetado?

2. Encontre a transição **AGUARDAR → PROPAGACAO**
   - Qual sinal indica a disponibilidade de época?
   - Como o índice de amostra é controlado?

3. Observe o cálculo **PROPAGACAO**
   - Acompanhe `contador_amostra` (qual amostra está sendo processada)
   - Veja `erro_calculado` sendo calculado
   - Observe `registrador_erro` capturando o valor

4. Observe a atualização **RETRO**
   - Como `peso_w0` e `peso_w1` mudam?
   - Qual é a relação com `registrador_erro`?

---

### Exercício 3.3 - Adição de Sinais de Debug

**Tarefa:** Modifique `tb_top.v` para monitorar sinais internos

```verilog
// Adicionar ao testbench:
initial begin
    $monitor("T=%0t | Estado=%b | contador_amostra=%d | peso_w0=%d | peso_w1=%d | LED=%b",
             $time, 
             dut.control_instance.estado_atual,
             dut.datapath_instance.contador_amostra,
             dut.datapath_instance.peso_w0,
             dut.datapath_instance.peso_w1,
             dut.led);
end
```

**O que fazer:**
1. Adicione este monitor ao seu testbench
2. Re-compile: `iverilog -o sim_top tb_top.v top.v control.v datapath.v`
3. Execute: `vvp sim_top`
4. Veja a saída com os valores dos pesos mudando

---

## 🔍 Série 4: Verificação e Debugging

### Exercício 4.1 - Checklist de Verificação

**Compilação:**
- [ ] Não há erros de sintaxe em `top.v`, `control.v`, `datapath.v`
- [ ] Não há warnings de portos não utilizados
- [ ] Não há warnings de sinais não inicializados

**Simulação:**
- [ ] Testbench compila sem erros
- [ ] Simulação executa sem crashing
- [ ] Arquivo VCD é gerado
- [ ] GTKWave abre o VCD sem problemas

**Funcionalidade:**
- [ ] Clock está oscilando
- [ ] FSM transiciona corretamente entre estados
- [ ] `contador_amostra` incrementa 0 → 1 → 2 → 3 → 0
- [ ] `contador_época` incrementa 0 → 1 → 2 → ... → 10
- [ ] Pesos (`peso_w0`, `peso_w1`) mudam durante treinamento
- [ ] LEDs exibem os valores dos pesos

---

### Exercício 4.2 - Debugging Prático

Se a simulação não funcionar, siga este checklist:

**Erro: "Module `top' not found!"**
- Verifique que `top.v` está no mesmo diretório
- Verifique que você está incluindo `top.v` no comando iverilog:
  ```bash
  iverilog -o sim_top tb_top.v top.v control.v datapath.v
                          ↑ não esqueça!
  ```

**Erro: "Module `control' not found!"**
- Verifique que `control.v` existe
- Verifique que está listado no comando iverilog

**Erro: "Undefined signal 'clk' in module..."**
- Verifique que o testbench instancia `top` com portos corretos
- Verifique que `clk` está definido como `reg` no testbench

**A simulação roda mas os pesos não mudam:**
1. Verifique se a FSM está transitando corretamente
   - Use `$monitor` para exibir `estado_atual`
2. Verifique se `load_indice_amostra` e `clr_indice_amostra` estão corretos
3. Verifique se `update_pesos` está sendo assertado no estado RETRO
4. Verifique a lógica de cálculo de erro em `datapath.v`

**Os LEDs não mudam:**
- Verifique se `peso_w0` e `peso_w1` estão sendo lidos corretamente de `datapath.v`
- Verifique a conexão em `top.v`:
  ```verilog
  assign led = {peso_w1[2:0], peso_w0[2:0]};
  ```

---

## 📊 Série 5: Análise de Síntese

### Exercício 5.1 - Interpretação de Resultados

**Resultado real de síntese para Tang Nano 1K:**

```
Device Utilisation:
    VCC:           1/    1   100%
    SLICE:       405/ 1152    35%
    IOB:           8/   48    16%
    MUX2_LUT5:   109/  576    18%
    MUX2_LUT6:    52/  288    18%
    MUX2_LUT7:    26/  144    18%
    MUX2_LUT8:     1/  136     0%
    GND:           1/    1   100%
    RAMW:          0/   72     0%
    GSR:           1/    1   100%
    OSCZ:          0/    1     0%
    rPLL:          0/    1     0%
```

**Questões:**

1. Qual é o percentual total de LUTs utilizados?
   ```
   Total LUTs = (109 + 52 + 26 + 1) / (576 + 288 + 144 + 136) × 100
               = 188 / 1144 = ?%
   ```

2. Qual é o percentual de SLICE?
   ```
   SLICE = 405 / 1152 = ?%
   ```

3. Há espaço disponível para adicionar mais lógica?
   ```
   Espaço restante = 1152 - 405 = ? SLICEs livres
   Porcentagem livre = ? %
   ```

4. Qual é o recurso mais limitado (maior percentual de utilização)?

**Respostas:**
```
1. 188 / 1144 = 16.4% de LUTs usados
2. 405 / 1152 = 35% de SLICE usados
3. 747 SLICEs livres = 65% de espaço disponível
4. VCC e GND (100%), mas esses são fixos
   De recursos reais: SLICE com 35%
```

---

### Exercício 5.2 - Timing Analysis

**Resultado real:**

```
Max frequency for clock 'clk_IBUF_I_O': 91.52 MHz (PASS at 27.00 MHz)
Max frequency for clock 'clk_util': 106.96 MHz (PASS at 27.00 MHz)
```

**Questões:**

1. Qual é a margem de frequência para `clk_IBUF_I_O`?
   ```
   Margem = 91.52 MHz - 27.00 MHz = ? MHz
   Fator de segurança = 91.52 / 27.00 = ?x
   ```

2. Qual é a margem para `clk_util`?
   ```
   Margem = ? MHz
   Fator de segurança = ? x
   ```

3. Se você quiser aumentar a frequência de operação:
   ```
   Qual é a máxima frequência segura que você poderia usar?
   (Considere deixar 20% de margem)
   ```

**Respostas:**
```
1. Margem = 64.52 MHz, Fator = 3.4x
2. Margem = 79.96 MHz, Fator = 4.0x
3. Com 20% de margem: min(91.52 × 0.8, 106.96 × 0.8) = 73.2 MHz máximo
```

---

## 🎯 Série 6: Desafios e Extensões

### Desafio 6.1 - Treinar Função AND

**Tarefa:** Modifique o projeto para treinar a função AND em vez de OR

**Dados da função AND:**
```
| x₀ | x₁ | y |
|----|----|---|
| 0  | 0  | 0 |
| 0  | 1  | 0 |
| 1  | 0  | 0 |
| 1  | 1  | 1 |
```

**O que mudar em `datapath.v`:**
```verilog
// Procure por:
reg saida_esperada[3:0];

// E mude para:
reg saida_esperada[3:0] = 4'b1000;  // Apenas amostra 3 tem saída 1
```

**Teste:**
1. Compile com: `make all`
2. Simule e verifique que os pesos convergem
3. Qual é a diferença nos pesos finais comparado com OR?

---

### Desafio 6.2 - Adicionar Taxa de Aprendizado

**Tarefa:** Implemente uma taxa de aprendizado (learning rate) para acelerar convergência

**Modificação em `datapath.v`:**
```verilog
// Ao invés de:
peso_w0 <= peso_w0 + (registrador_erro * entrada_amostra[0]);

// Use (com learning rate de 2x):
peso_w0 <= peso_w0 + 2 * (registrador_erro * entrada_amostra[0]);
```

**Teste:**
1. Verifique se converge mais rápido
2. Que acontece se learning rate for muito alto?
3. Implemente como parâmetro: `parameter LEARNING_RATE = 1;`

---

### Desafio 6.3 - Aumentar Número de Épocas

**Tarefa:** Mude de 10 para 20 épocas de treinamento

**Modificação em `top.v`:**
```verilog
// Procure por:
.max_epoch(4'd10),

// Mude para:
.max_epoch(5'd20),     // Note: 5 bits para 20 (4 bits só vai até 15)
```

**Teste:**
1. Verifique se a síntese ainda passa
2. Qual é o novo percentual de utilização de SLICE?
3. Há ainda espaço para mais épocas?

---

### Desafio 6.4 - Implementar Testbench Automatizado

**Tarefa:** Crie um testbench que verifica automaticamente se o treinamento convergiu

**Pseudocódigo:**
```verilog
// Após N épocas, verificar se:
// 1. Para amostra (0,0): predição = 0
// 2. Para amostra (0,1): predição = 1
// 3. Para amostra (1,0): predição = 1
// 4. Para amostra (1,1): predição = 1

// Usar assertions:
if (teste_convergencia_passed) begin
    $display("✅ TREINAMENTO CONVERGIU COM SUCESSO!");
end else begin
    $display("❌ TREINAMENTO NÃO CONVERGIU!");
end
```
