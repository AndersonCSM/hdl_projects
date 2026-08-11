// ════════════════════════════════════════════════════════════════════════════════
// TESTBENCH SIMPLIFICADO: tb_top_simple.v
// 
// Versão reduzida focando em sinais IMPORTANTES para debug
// Remove sinais desnecessários e adiciona $display mais claros
//
// Como usar:
//   iverilog -o sim_simple tb_top_simple.v top.v control.v datapath.v
//   vvp sim_simple > sim_simple.log
//
// ════════════════════════════════════════════════════════════════════════════════

`timescale 1ns/1ps

module tb_top_simple;
    // ────────────────────────────────────────────────────────────────
    // SINAIS
    // ────────────────────────────────────────────────────────────────
    
    reg clk_tb;
    reg btn1_tb;
    wire [5:0] led_tb;
    
    // Acesso aos sinais internos
    wire clk_util;
    wire [1:0] estado_atual;
    wire [3:0] contador_amostra;
    wire [3:0] contador_epoca;
    wire signed [7:0] peso_w0;
    wire signed [7:0] peso_w1;
    wire epoch_disponivel;
    wire amostra_disponivel;
    wire [8:0] soma_ponderada;
    wire saida_predita;
    wire signed [1:0] erro_calculado;
    wire reset_ativo_alto;
    
    // ────────────────────────────────────────────────────────────────
    // INSTANCIAÇÃO
    // ────────────────────────────────────────────────────────────────
    
    top dut (
        .clk(clk_tb),
        .btn1(btn1_tb),
        .led(led_tb)
    );
    
    // Acesso aos sinais
    assign clk_util = dut.clk_util;
    assign reset_ativo_alto = dut.reset_ativo_alto;
    assign estado_atual = dut.control_instance.estado_atual;
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
    // CLOCK GENERATOR (27 MHz)
    // ────────────────────────────────────────────────────────────────
    
    initial begin
        clk_tb = 1'b0;
        forever #18.52 clk_tb = ~clk_tb;
    end
    
    // ────────────────────────────────────────────────────────────────
    // TESTE PRINCIPAL
    // ────────────────────────────────────────────────────────────────
    
    initial begin
        // Gerar arquivo VCD LIMPO (apenas sinais importantes)
        $dumpfile("sim_simple.vcd");
        $dumpvars(0, clk_tb, btn1_tb, led_tb, clk_util, reset_ativo_alto, 
                  estado_atual, contador_amostra, contador_epoca, 
                  peso_w0, peso_w1, epoch_disponivel, amostra_disponivel,
                  soma_ponderada, saida_predita, erro_calculado);
        
        // FASE 1: RESET
        btn1_tb = 1'b0;
        #200;
        
        // FASE 2: LIBERAR
        btn1_tb = 1'b1;
        #200;
        
        // FASE 3: EXECUTAR (100 segundos = ~100 épocas)
        #100_000_000_000;  
        
        $display("");
        $display("════════════════════════════════════════════════════════");
        $display("  SIMULAÇÃO FINALIZADA");
        $display("════════════════════════════════════════════════════════");
        
        $finish;
    end
    
    // ────────────────────────────────────────────────────────────────
    // MONITORAMENTO A CADA CICLO DE CLK_UTIL
    // ────────────────────────────────────────────────────────────────
    
    reg [1:0] estado_anterior = 2'b00;
    integer ciclo = 0;
    
    always @(posedge clk_util) begin
        if (!reset_ativo_alto) begin
            ciclo = ciclo + 1;
            
            // Mapeamento de estados
            case (estado_atual)
                2'b00: $display("[%6d] INICIAR     | E:%0d A:%0d | w0:%3d w1:%3d | soma:%5d pred:%d erro:%0d", 
                               ciclo, contador_epoca, contador_amostra, peso_w0, peso_w1,
                               soma_ponderada, saida_predita, erro_calculado);
                2'b01: $display("[%6d] AGUARDAR    | E:%0d A:%0d | w0:%3d w1:%3d | EPDSP:%b APDSP:%b", 
                               ciclo, contador_epoca, contador_amostra, peso_w0, peso_w1,
                               epoch_disponivel, amostra_disponivel);
                2'b10: $display("[%6d] PROPAGACAO | E:%0d A:%0d | w0:%3d w1:%3d | soma:%5d pred:%d erro:%0d", 
                               ciclo, contador_epoca, contador_amostra, peso_w0, peso_w1,
                               soma_ponderada, saida_predita, erro_calculado);
                2'b11: $display("[%6d] RETRO      | E:%0d A:%0d | w0:%3d w1:%3d | ATUALIZADO", 
                               ciclo, contador_epoca, contador_amostra, peso_w0, peso_w1);
            endcase
            
            // Detectar transições
            if (estado_anterior != estado_atual) begin
                case ({estado_anterior, estado_atual})
                    4'b0001: $display("           >>> INICIAR → AGUARDAR");
                    4'b0110: $display("           >>> AGUARDAR → PROPAGACAO");
                    4'b1011: $display("           >>> PROPAGACAO → RETRO");
                    4'b1110: $display("           >>> RETRO → PROPAGACAO");
                    4'b1101: $display("           >>> RETRO → AGUARDAR");
                    default: $display("           >>> TRANSIÇÃO: %b → %b", estado_anterior, estado_atual);
                endcase
                estado_anterior = estado_atual;
            end
        end
    end

endmodule
