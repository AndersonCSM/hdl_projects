`timescale 1ns/1ps

module tb_fifo();

// ============================================================================
// Parâmetros e Sinais
// ============================================================================
parameter CLK_PERIOD = 20;          // Clock de 50 MHz -> 20 ns
parameter DATA_WIDTH = 8;
parameter ADDR_WIDTH = 4;
parameter DEPTH = 1 << ADDR_WIDTH;  // 16 posições

// Sinais do DUT
reg clk_i;
reg rst_i;
reg wr_en_i;
reg [DATA_WIDTH-1:0] data_in_i;
reg rd_en_i;
wire [DATA_WIDTH-1:0] data_out_o;
wire full_o;
wire empty_o;
wire [ADDR_WIDTH:0] count_o;

// Sinais auxiliares
integer errors = 0;
integer test_id = 0;
integer log_file;

// Instanciação do DUT
fifo #(
    .DATA_WIDTH(DATA_WIDTH),
    .ADDR_WIDTH(ADDR_WIDTH)
) dut_fifo (
    .clk_i(clk_i),
    .rst_i(rst_i),
    .wr_en_i(wr_en_i),
    .data_in_i(data_in_i),
    .full_o(full_o),
    .rd_en_i(rd_en_i),
    .data_out_o(data_out_o),
    .empty_o(empty_o),
    .count_o(count_o)
);

// ============================================================================
// Geração de Clock e Reset
// ============================================================================
initial clk_i = 1'b0;
always #(CLK_PERIOD/2) clk_i = ~clk_i;

// Reset inicial
initial begin
    rst_i = 1'b0;
    wr_en_i = 1'b0;
    data_in_i = 8'h00;
    rd_en_i = 1'b0;
    #100;
    rst_i = 1'b1;
end

// ============================================================================
// Tarefas de Suporte
// ============================================================================

// Tarefa para imprimir no console e no arquivo
task log_message;
    input string msg;
    begin
        $display("%s", msg);
        $fdisplay(log_file, "%s", msg);
    end
endtask

// Aplica reset por uma duração especificada em ciclos de clock
task apply_reset;
    input integer duration;
begin
    rst_i = 1'b0;
    repeat(duration) @(posedge clk_i);
    rst_i = 1'b1;
end
endtask

// Verifica um valor esperado contra o real e atualiza contador de erros
task check_value;
    input [31:0] expected;
    input [31:0] actual;
    input string description;
begin
    if (expected !== actual) begin
        log_message($sformatf("[ERRO] %s: esperado %h, obtido %h (tempo %0t)", description, expected, actual, $time));
        errors = errors + 1;
    end else begin
        log_message($sformatf("[OK]   %s (tempo %0t)", description, $time));
    end
end
endtask

// Escreve um dado na FIFO (push) e aguarda um ciclo de clock
task push;
    input [DATA_WIDTH-1:0] data;
begin
    wr_en_i = 1'b1;
    data_in_i = data;
    @(posedge clk_i);
    wr_en_i = 1'b0;
    @(posedge clk_i);  // aguarda um ciclo para estabilizar
end
endtask

// Lê um dado da FIFO (pop) e retorna o valor lido
task pop;
    output [DATA_WIDTH-1:0] data_out;
begin
    rd_en_i = 1'b1;
    @(posedge clk_i);
    rd_en_i = 1'b0;
    data_out = data_out_o;  // captura após o ciclo de leitura
    @(posedge clk_i);      // aguarda próximo ciclo para estabilizar flags
end
endtask

// ============================================================================
// Casos de Teste (TC-XX)
// ============================================================================

initial begin
    // Abrir arquivo de log
    log_file = $fopen("../sim/fifo_test_results.txt", "w");
    if (log_file == 0) begin
        $display("ERRO: Não foi possível criar o arquivo de log em ../sim/");
        $finish;
    end

    // Aguarda estabilização do reset
    #100;
    log_message("=============================================");
    log_message(" Testes da FIFO");
    log_message("=============================================");

    // TC-01: Estado inicial após reset
    test_id = 1;
    log_message($sformatf("\nTC-%0d: Estado inicial após reset", test_id));
    apply_reset(5);
    check_value(1'b1, empty_o, "empty_o em 1 após reset");
    check_value(1'b0, full_o, "full_o em 0 após reset");
    check_value(0, count_o, "count_o = 0 após reset");
    check_value(0, data_out_o, "data_out_o = 0 após reset");

    // TC-02: Escrita e leitura de um único dado
    test_id = 2;
    log_message($sformatf("\nTC-%0d: Escrita e leitura de um único dado", test_id));
    apply_reset(3);
    push(8'hA5);
    check_value(1, count_o, "count_o = 1 após push");
    check_value(1'b0, empty_o, "empty_o = 0 após push");
    begin
        reg [7:0] read_data;
        pop(read_data);
        check_value(8'hA5, read_data, "Dado lido corresponde ao escrito");
        check_value(0, count_o, "count_o = 0 após pop");
        check_value(1'b1, empty_o, "empty_o = 1 após pop");
    end

    // TC-03: Encher a FIFO completamente
    test_id = 3;
    log_message($sformatf("\nTC-%0d: Encher a FIFO completamente", test_id));
    apply_reset(3);
    for (int i = 0; i < DEPTH; i++) begin
        push(i[7:0]);
    end
    check_value(DEPTH, count_o, "count_o = 16 após encher");
    check_value(1'b1, full_o, "full_o = 1 quando cheia");
    check_value(1'b0, empty_o, "empty_o = 0 quando cheia");

    // TC-04: Esvaziar a FIFO completamente e verificar ordem
    test_id = 4;
    log_message($sformatf("\nTC-%0d: Esvaziar a FIFO e verificar ordem dos dados", test_id));
    for (int i = 0; i < DEPTH; i++) begin
        reg [7:0] read_data;
        pop(read_data);
        check_value(i[7:0], read_data, $sformatf("Dado %0d lido na ordem correta", i));
    end
    check_value(0, count_o, "count_o = 0 após esvaziar");
    check_value(1'b1, empty_o, "empty_o = 1 após esvaziar");
    check_value(1'b0, full_o, "full_o = 0 após esvaziar");

    // TC-05: Operações intercaladas (escrever, ler, escrever, ler)
    test_id = 5;
    log_message($sformatf("\nTC-%0d: Operações intercaladas", test_id));
    apply_reset(3);
    push(8'h11);
    push(8'h22);
    push(8'h33);
    begin
        reg [7:0] d;
        pop(d);
        check_value(8'h11, d, "Primeiro pop = 0x11");
    end
    push(8'h44);
    begin
        reg [7:0] d;
        pop(d);
        check_value(8'h22, d, "Segundo pop = 0x22");
        pop(d);
        check_value(8'h33, d, "Terceiro pop = 0x33");
        pop(d);
        check_value(8'h44, d, "Quarto pop = 0x44");
    end
    check_value(0, count_o, "FIFO vazia após operações intercaladas");
    check_value(1'b1, empty_o, "empty_o = 1 após esvaziar");

    // TC-06: Reset durante operação
    test_id = 6;
    log_message($sformatf("\nTC-%0d: Reset durante operação", test_id));
    apply_reset(3);
    push(8'hAA);
    push(8'hBB);
    // Aplica reset no meio
    rst_i = 1'b0;
    repeat(2) @(posedge clk_i);
    rst_i = 1'b1;
    check_value(0, count_o, "count_o = 0 após reset durante escrita");
    check_value(1'b1, empty_o, "empty_o = 1 após reset");
    check_value(1'b0, full_o, "full_o = 0 após reset");

    // TC-07: Escrita quando cheia (não deve alterar dados)
    test_id = 7;
    log_message($sformatf("\nTC-%0d: Escrita quando cheia", test_id));
    apply_reset(3);
    // Enche a FIFO
    for (int i = 0; i < DEPTH; i++) begin
        push(i[7:0]);
    end
    // Tenta escrever quando cheia
    wr_en_i = 1'b1;
    data_in_i = 8'hFF;
    @(posedge clk_i);
    wr_en_i = 1'b0;
    // Verifica que a FIFO não aceitou escrita (full permanece 1, count não aumentou)
    check_value(DEPTH, count_o, "count_o permanece 16 após tentativa de escrita com full");
    check_value(1'b1, full_o, "full_o permanece 1");
    // Esvazia e verifica que o último dado ainda é o 15
    for (int i = 0; i < DEPTH; i++) begin
        reg [7:0] d;
        pop(d);
        if (i == DEPTH-1)
            check_value(8'h0F, d, "Último dado é 0x0F (não sobrescrito)");
    end

    // TC-08: Leitura quando vazia (não deve alterar saída)
    test_id = 8;
    log_message($sformatf("\nTC-%0d: Leitura quando vazia", test_id));
    apply_reset(3);
    // FIFO vazia, tenta ler
    rd_en_i = 1'b1;
    @(posedge clk_i);
    rd_en_i = 1'b0;
    check_value(0, count_o, "count_o permanece 0");
    check_value(1'b1, empty_o, "empty_o permanece 1");
    check_value(0, data_out_o, "data_out_o permanece 0 (ou último valor)");

    // Resumo final
    log_message("\n=============================================");
    if (errors == 0)
        log_message("TODOS OS TESTES PASSARAM!");
    else
        log_message($sformatf("FALHAS: %0d erros encontrados", errors));
    log_message("=============================================");

    $fclose(log_file);
    $finish;
end

// ============================================================================
// Geração de VCD para visualização de ondas
// ============================================================================
initial begin
    $dumpfile("../sim/fifo_tb.vcd");
    $dumpvars(0, tb_fifo);
end

endmodule