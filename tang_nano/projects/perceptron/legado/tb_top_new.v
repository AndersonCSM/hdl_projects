// ════════════════════════════════════════════════════════════════════════════════
// TESTBENCH: tb_top.v
// 
// Objetivo: Simular e debugar o projeto Perceptron Tang Nano 1K
// 
// Funcionalidades:
//   • Gera clock de 27 MHz
//   • Gera reset (botão)
//   • Monitora sinais internos (estado FSM, pesos, contadores)
//   • Gera arquivo VCD para visualização em GTKWave
//   • Assertions básicas para verificação
//   • Análise de convergência do treinamento
//
// Como usar:
//   1. Compilar:  iverilog -o sim tb_top.v top.v control.v datapath.v
//   2. Simular:   vvp sim > sim.log
//   3. Visualizar: gtkwave sim.vcd &
//
// ════════════════════════════════════════════════════════════════════════════════

`timescale 1ns/1ps

module tb_top;
    // ────────────────────────────────────────────────────────────────
    // SINAIS DO TESTBENCH
    // ────────────────────────────────────────────────────────────────
    
    // Sinais de entrada (registradores para poder controlar)
    reg clk_tb;          // Clock de 27 MHz
    reg btn1_tb;         // Botão de reset
    
    // Sinais de saída (fios para capturar)
    wire [5:0] led_tb;   // 6 LEDs
    
    // Sinais internos para debug (acessando via hierarquia)
    wire reset_ativo_alto;
    wire clk_util;
    wire estado_atual;
    wire [3:0] contador_amostra;
    wire [3:0] contador_epoca;
    wire signed [7:0] peso_w0;
    wire signed [7:0] peso_w1;
    wire epoch_disponivel;
    wire amostra_disponivel;
    wire signed [8:0] soma_ponderada;
    wire saida_predita;
    wire signed [1:0] erro_calculado;
    
    // Variáveis de teste
    integer ciclo_simulacao = 0;
    integer ciclo_anterior_clk_util = 0;
    
    // ────────────────────────────────────────────────────────────────
    // INSTANCIAÇÃO DO MÓDULO PRINCIPAL (DUT - Device Under Test)
    // ────────────────────────────────────────────────────────────────
    
    top dut (
        .clk(clk_tb),
        .btn1(btn1_tb),
        .led(led_tb)
    );
    
    // Acesso aos sinais internos via hierarquia
    assign reset_ativo_alto = dut.reset_ativo_alto;
    assign clk_util = dut.clk_util;
    
    // Sinais do control.v
    assign estado_atual = dut.control_instance.estado_atual;
    
    // Sinais do datapath.v
    assign contador_amostra = dut.datapath_instance.contador_amostra;
    assign contador_epoca = dut.datapath_instance.contador_epoca;
    assign peso_w0 = dut.datapath_instance.peso_w0;
    assign peso_w1 = dut.datapath_instance.peso_w1;
    assign epoch_disponivel = dut.datapath_instance.epoch_disponivel;
    assign amostra_disponivel = dut.datapath_instance.amostra_disponivel;
    assign soma_ponderada = dut.datapath_instance.soma_ponderada;
    assign saida_predita = dut.datapath_instance.saida_predita;
    assign erro_calculado = dut.datapath_instance.erro_calculado;
    
    // ────────────────────────────────────────────────────────────────
    // GERADOR DE CLOCK (27 MHz)
    // ────────────────────────────────────────────────────────────────
    // Período: 1 / 27MHz ≈ 37.04 ns
    // Meio período: 18.52 ns
    
    initial begin
        clk_tb = 1'b0;
        // Oscilação contínua a cada 18.52 ns
        forever #18.52 clk_tb = ~clk_tb;
    end
    
    // ────────────────────────────────────────────────────────────────
    // INICIALIZAÇÃO E CONTROLE DO TESTBENCH
    // ────────────────────────────────────────────────────────────────
    
    initial begin
        // Dump de variáveis para arquivo VCD (GTKWave)
        $dumpfile("sim.vcd");
        $dumpvars(0, tb_top);
        
        $display("════════════════════════════════════════════════════════════");
        $display("  SIMULAÇÃO: Perceptron Tang Nano 1K");
        $display("  Data: %0t", $time);
        $display("════════════════════════════════════════════════════════════");
        $display("");
        
        // ────────────────────────────────────────────────────────────
        // FASE 1: RESET (botão pressionado)
        // ────────────────────────────────────────────────────────────
        
        btn1_tb = 1'b0;  // Botão pressionado (ativo baixo)
        $display("[%0d ns] FASE 1: RESET", $time);
        $display("  → Botão pressionado (btn1 = 0)");
        $display("  → Reset ativo (reset = 1)");
        
        // Manter reset por 200 ns
        #200;
        
        // ────────────────────────────────────────────────────────────
        // FASE 2: SOLTAR RESET (botão solto)
        // ────────────────────────────────────────────────────────────
        
        btn1_tb = 1'b1;  // Botão solto (inativo alto)
        $display("[%0d ns] FASE 2: INICIAR SIMULAÇÃO", $time);
        $display("  → Botão solto (btn1 = 1)");
        $display("  → Reset inativo (reset = 0)");
        $display("  → Aguardando clock reduzido (~1 Hz)...");
        $display("");
        
        // ────────────────────────────────────────────────────────────
        // FASE 3: MONITORAMENTO DURANTE SIMULAÇÃO
        // ────────────────────────────────────────────────────────────
        
        // Simular por tempo suficiente para ver treinamento
        // 27M ciclos de clock ≈ 1 segundo de tempo real simulado
        // Para ver ~3 épocas: 27M × 3 + margem = ~81M ciclos
        // Em simulação: 81M × 37ns ≈ 3 segundos
        
        #100_000_000_000;  // Simula ~100 segundos (múltiplas épocas)
        
        $display("");
        $display("════════════════════════════════════════════════════════════");
        $display("  SIMULAÇÃO FINALIZADA");
        $display("════════════════════════════════════════════════════════════");
        $display("  Arquivo VCD gerado: sim.vcd");
        $display("  Para visualizar: gtkwave sim.vcd &");
        $display("════════════════════════════════════════════════════════════");
        
        $finish;
    end
    
    // ────────────────────────────────────────────────────────────────
    // MONITOR: Exibir sinais a cada ciclo do clock reduzido
    // ────────────────────────────────────────────────────────────────
    // NOTA: Quando o treinamento termina (epoch_disponivel=0), a máquina
    // permanece em AGUARDAR. Neste estado, os valores X (don't care) para
    // pesos e soma são comportamentos esperados pois não há atualização
    // dos pesos. Este é um estado de repouso/idle após convergência.
    // ────────────────────────────────────────────────────────────────
    
    always @(posedge clk_util) begin
        if (reset_ativo_alto) begin
            // Durante reset, não monitorar
            if (ciclo_anterior_clk_util == 0) begin
                $display("[RESET] Estado: INICIAR (limpando tudo...)");
            end
        end else begin
            // Após reset, exibir estado do treinamento
            ciclo_anterior_clk_util = ciclo_anterior_clk_util + 1;
            
            // Mapeamento dos estados
            case (estado_atual)
                2'b00: $display("[%0d ns] [Ciclo %0d] INICIAR     | Época: %0d | Amostra: %0d | w0: %3d | w1: %3d | LED: %b",
                               $time, ciclo_anterior_clk_util, contador_epoca, contador_amostra, 
                               peso_w0, peso_w1, led_tb);
                2'b01: $display("[%0d ns] [Ciclo %0d] AGUARDAR    | Época: %0d | Amostra: %0d | w0: %3d | w1: %3d | LED: %b",
                               $time, ciclo_anterior_clk_util, contador_epoca, contador_amostra,
                               peso_w0, peso_w1, led_tb);
                2'b10: $display("[%0d ns] [Ciclo %0d] PROPAGACAO | Época: %0d | Amostra: %0d | w0: %3d | w1: %3d | LED: %b | Soma: %0d | Erro: %0d",
                               $time, ciclo_anterior_clk_util, contador_epoca, contador_amostra,
                               peso_w0, peso_w1, led_tb, soma_ponderada, erro_calculado);
                2'b11: $display("[%0d ns] [Ciclo %0d] RETRO       | Época: %0d | Amostra: %0d | w0: %3d | w1: %3d | LED: %b | Atualizado!",
                               $time, ciclo_anterior_clk_util, contador_epoca, contador_amostra,
                               peso_w0, peso_w1, led_tb);
                default: $display("[%0d ns] [Ciclo %0d] ESTADO INVÁLIDO = %b", $time, ciclo_anterior_clk_util, estado_atual);
            endcase
        end
    end
    
    // ────────────────────────────────────────────────────────────────
    // MONITOR: Detectar transições de estado (DEBUG)
    // ────────────────────────────────────────────────────────────────
    
    reg [1:0] estado_anterior = 2'b00;
    
    always @(estado_atual) begin
        if (estado_anterior != estado_atual) begin
            case ({estado_anterior, estado_atual})
                4'b0001: $display("  ✓ TRANSIÇÃO: INICIAR → AGUARDAR");
                4'b0110: $display("  ✓ TRANSIÇÃO: AGUARDAR → PROPAGACAO");
                4'b1011: $display("  ✓ TRANSIÇÃO: PROPAGACAO → RETRO");
                4'b1110: $display("  ✓ TRANSIÇÃO: RETRO → PROPAGACAO");
                4'b1101: $display("  ✓ TRANSIÇÃO: RETRO → AGUARDAR");
                4'b0101: $display("  ✓ TRANSIÇÃO: AGUARDAR → AGUARDAR (TREINAMENTO CONCLUÍDO - IDLE)");
                default: $display("  ✗ TRANSIÇÃO INESPERADA: %b → %b", estado_anterior, estado_atual);
            endcase
            estado_anterior = estado_atual;
        end
    end
    
    // ────────────────────────────────────────────────────────────────
    // ASSERTIONS: Verificações de sanidade
    // ────────────────────────────────────────────────────────────────
    
    always @(posedge clk_util) begin
        if (!reset_ativo_alto) begin
            // Verificação 1: Contadores não devem ultrapassar máximo
            if (contador_amostra > 4'd4) begin
                $display("  ✗ ERRO: contador_amostra = %0d (máximo = 4)", contador_amostra);
            end
            
            if (contador_epoca > 4'd10) begin
                $display("  ✗ ERRO: contador_epoca = %0d (máximo = 10)", contador_epoca);
            end
            
            // Verificação 2: Pesos não devem ser valores muito extremos
            // (Indicaria lógica quebrada)
            if (peso_w0 > 50 || peso_w0 < -50) begin
                $display("  ⚠ AVISO: peso_w0 = %0d (fora do esperado)", peso_w0);
            end
            
            if (peso_w1 > 50 || peso_w1 < -50) begin
                $display("  ⚠ AVISO: peso_w1 = %0d (fora do esperado)", peso_w1);
            end
        end
    end
    
    // ────────────────────────────────────────────────────────────────
    // ANÁLISE: Detectar convergência do treinamento
    // ────────────────────────────────────────────────────────────────
    
    reg [7:0] peso_w0_anterior = 8'd0;
    reg [7:0] peso_w1_anterior = 8'd0;
    integer ciclos_sem_mudanca_w0 = 0;
    integer ciclos_sem_mudanca_w1 = 0;
    
    always @(posedge clk_util) begin
        if (!reset_ativo_alto) begin
            // Verificar se pesos mudaram
            if (peso_w0 == peso_w0_anterior) begin
                ciclos_sem_mudanca_w0 = ciclos_sem_mudanca_w0 + 1;
            end else begin
                ciclos_sem_mudanca_w0 = 0;
                peso_w0_anterior = peso_w0;
            end
            
            if (peso_w1 == peso_w1_anterior) begin
                ciclos_sem_mudanca_w1 = ciclos_sem_mudanca_w1 + 1;
            end else begin
                ciclos_sem_mudanca_w1 = 0;
                peso_w1_anterior = peso_w1;
            end
            
            // Se ambos os pesos não mudaram por múltiplas épocas, pode ter convergido
            if (ciclos_sem_mudanca_w0 > 10 && ciclos_sem_mudanca_w1 > 10) begin
                $display("  ✓ CONVERGÊNCIA DETECTADA: Pesos estáveis há %0d ciclos!", ciclos_sem_mudanca_w0);
                $display("    Pesos finais: w0 = %0d, w1 = %0d", peso_w0, peso_w1);
            end
        end
    end

    // ────────────────────────────────────────────────────────────────
    // DIAGNÓSTICO: Detectar término do treinamento (estado IDLE)
    // ────────────────────────────────────────────────────────────────
    
    integer contador_ciclos_idle = 0;
    reg treinamento_terminado = 1'b0;
    
    always @(posedge clk_util) begin
        if (!reset_ativo_alto) begin
            // Se está em AGUARDAR e epoch_disponivel = 0, está em IDLE
            if (estado_atual == 2'b01 && !epoch_disponivel) begin
                contador_ciclos_idle = contador_ciclos_idle + 1;
                
                // Primeira vez que entra em IDLE
                if (!treinamento_terminado) begin
                    treinamento_terminado = 1'b1;
                    $display("");
                    $display("════════════════════════════════════════════════════════════");
                    $display("  ✓ TREINAMENTO CONCLUÍDO!");
                    $display("════════════════════════════════════════════════════════════");
                    $display("  Estado: AGUARDAR (IDLE)");
                    $display("  Pesos Finais: w0 = %0d, w1 = %0d", peso_w0, peso_w1);
                    $display("  Épocas Executadas: %0d", contador_epoca);
                    $display("  Observação: Valores X (don't care) para soma/pred/erro");
                    $display("              são esperados neste estado de repouso.");
                    $display("════════════════════════════════════════════════════════════");
                    $display("");
                end
            end else begin
                contador_ciclos_idle = 0;
                treinamento_terminado = 1'b0;
            end
        end
    end

endmodule
// ════════════════════════════════════════════════════════════════════════════════
