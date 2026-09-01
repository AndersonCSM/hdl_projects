`timescale 1ns/1ps

module tb_tx();

// ============================================================================
// Parâmetros e Sinais
// ============================================================================
parameter CLK_PERIOD = 20;          // Clock de 50 MHz -> 20 ns
parameter BAUD_TICKS_PER_BIT = 16;  // Oversampling 16x (padrão UART)

// Sinais do DUT
reg clk_i;
reg rst_i;
reg enable_tx;
reg baud_tick;
reg [7:0] data_i;
wire uart_tx_o;
wire tx_valid;

// Sinais auxiliares
integer errors = 0;
integer test_id = 0;
integer log_file;  // Arquivo de log

// Instanciação do transmissor (DUT)
tx dut_tx (
    .clk_i(clk_i),
    .rst_i(rst_i),
    .enable_tx(enable_tx),
    .baud_tick(baud_tick),
    .data_i(data_i),
    .uart_tx_o(uart_tx_o),
    .tx_valid(tx_valid)
);

// ============================================================================
// Geração de Clock e Reset
// ============================================================================
initial clk_i = 1'b0;
always #(CLK_PERIOD/2) clk_i = ~clk_i;

// Reset inicial
initial begin
    rst_i = 1'b0;
    enable_tx = 1'b0;
    data_i = 8'h00;
    baud_tick = 1'b0;
    #100;
    rst_i = 1'b1;
end

// ============================================================================
// Gerador de Baud Tick (simula baud_generate)
// ============================================================================
reg [15:0] baud_counter = 16'd0;

always @(posedge clk_i or negedge rst_i) begin
    if (!rst_i) begin
        baud_counter <= 16'd0;
        baud_tick <= 1'b0;
    end else begin
        if (baud_counter == BAUD_TICKS_PER_BIT - 1) begin
            baud_counter <= 16'd0;
            baud_tick <= 1'b1;
        end else begin
            baud_counter <= baud_counter + 1'b1;
            baud_tick <= 1'b0;
        end
    end
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
    input [7:0] expected;
    input [7:0] actual;
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

// Envia um byte: aplica enable_tx por 1 ciclo e aguarda conclusão
task send_byte;
    input [7:0] data;
begin
    wait(tx_valid == 1'b1);  // Aguarda IDLE
    @(posedge clk_i);
    data_i = data;
    enable_tx = 1'b1;
    @(posedge clk_i);
    enable_tx = 1'b0;
    wait(tx_valid == 1'b0);  // Confirma início da transmissão
    wait(tx_valid == 1'b1);  // Aguarda retorno a IDLE (fim)
end
endtask

// Verifica a sequência completa na saída (start + 8 bits + stop)
// Deve ser chamada logo após enable_tx ter sido pulsado.
// Esta tarefa é bloqueante e não tem timeout; use a versão com timeout quando apropriado.
task check_tx_sequence;
    input [7:0] expected_data;
    input integer ticks_per_bit;
    integer i;
    reg expected_bit;
begin
    // Detecta borda de descida (início do start bit)
    @(negedge uart_tx_o);
    log_message($sformatf("[DEBUG] Início da transmissão detectado em %0t", $time));
    
    // Start bit: deve permanecer 0 por ticks_per_bit ciclos de baud
    repeat(ticks_per_bit) @(posedge baud_tick);
    check_value(1'b0, uart_tx_o, "Start bit");
    
    // Bits de dados (LSB primeiro)
    for (i = 0; i < 8; i = i + 1) begin
        repeat(ticks_per_bit) @(posedge baud_tick);
        expected_bit = expected_data[i];
        check_value(expected_bit, uart_tx_o, $sformatf("Bit de dados[%0d]", i));
    end
    
    // Stop bit
    repeat(ticks_per_bit) @(posedge baud_tick);
    check_value(1'b1, uart_tx_o, "Stop bit");
end
endtask

// Tarefa com timeout para verificar a sequência, com cancelamento adequado
// Retorna 1 se a verificação completou com sucesso, 0 se ocorreu timeout.
task check_tx_sequence_timeout;
    input [7:0] expected_data;
    input integer ticks_per_bit;
    input integer timeout_cycles;   // timeout em ciclos de clock
    output reg success;
    reg timeout_occurred;
begin
    success = 0;
    timeout_occurred = 0;
    
    fork : verify_block
        begin
            // Thread de verificação
            check_tx_sequence(expected_data, ticks_per_bit);
            // Se chegou aqui sem timeout, sucesso
            success = 1;
            disable timeout_block;  // Cancela a thread de timeout
        end
        begin : timeout_block
            // Thread de timeout
            repeat(timeout_cycles) @(posedge clk_i);
            timeout_occurred = 1;
            log_message($sformatf("[ERRO] Timeout na verificação da sequência (tempo %0t)", $time));
            errors = errors + 1;
            disable verify_block;  // Cancela a thread de verificação
        end
    join_any
    
    // Se o timeout ocorreu, a thread de verificação foi desabilitada,
    // então success permanece 0.
    // Nota: não há necessidade de aguardar tx_valid aqui, pois a verificação já terminou ou falhou.
end
endtask

// ============================================================================
// Casos de Teste (TC-XX)
// ============================================================================

initial begin
    // Abrir arquivo de log (caminho relativo à pasta tb, um nível acima para sim)
    log_file = $fopen("../sim/uart_tx_test_results.txt", "w");
    if (log_file == 0) begin
        $display("ERRO: Não foi possível criar o arquivo de log em ../sim/");
        $finish;
    end

    // Aguarda estabilização do reset
    #100;
    log_message("=============================================");
    log_message(" Testes do Transmissor UART (tx)");
    log_message("=============================================");
    
    // TC-01: Estado inicial após reset
    test_id = 1;
    log_message($sformatf("\nTC-%0d: Estado inicial após reset", test_id));
    apply_reset(5);
    check_value(1'b1, uart_tx_o, "Linha em repouso após reset");
    check_value(1'b1, tx_valid, "tx_valid em IDLE após reset");
    
    // TC-02: Transmissão de um byte com verificação bit a bit (com timeout)
    test_id = 2;
    log_message($sformatf("\nTC-%0d: Transmissão do byte 0xA5 (verificação detalhada)", test_id));
    apply_reset(3);
    // Prepara dados e dispara enable
    data_i = 8'hA5;
    enable_tx = 1'b1;
    @(posedge clk_i);
    enable_tx = 1'b0;
    
    // Chama a tarefa com timeout (por exemplo, 10000 ciclos de clock é mais que suficiente)
    begin
        reg check_ok;
        check_tx_sequence_timeout(8'hA5, BAUD_TICKS_PER_BIT, 10000, check_ok);
        if (check_ok)
            log_message("[INFO] Transmissão do byte 0xA5 concluída com sucesso");
        else
            log_message("[INFO] Transmissão do byte 0xA5 falhou (timeout)");
    end
    
    // TC-03: Loop por todos os valores de dados (envio simples)
    test_id = 3;
    log_message($sformatf("\nTC-%0d: Envio de todos os 256 valores", test_id));
    for (int val = 0; val < 256; val++) begin
        apply_reset(2);
        send_byte(val[7:0]);
        // Verifica apenas se retornou a IDLE corretamente
        if (tx_valid !== 1'b1) begin
            log_message($sformatf("[ERRO] tx_valid não retornou a 1 para valor %h", val));
            errors = errors + 1;
        end
    end
    log_message("[OK] Loop de 256 valores concluído");
    
    // TC-04: Transmissões consecutivas (back-to-back)
    test_id = 4;
    log_message($sformatf("\nTC-%0d: Transmissões consecutivas (back-to-back)", test_id));
    apply_reset(3);
    send_byte(8'h55);
    send_byte(8'hAA);
    log_message("[OK] Duas transmissões consecutivas realizadas");
    
    // TC-05: enable_tx mantido alto por vários ciclos
    test_id = 5;
    log_message($sformatf("\nTC-%0d: enable_tx mantido alto", test_id));
    apply_reset(3);
    data_i = 8'h0F;
    enable_tx = 1'b1;
    repeat(50) @(posedge clk_i);
    enable_tx = 1'b0;
    wait(tx_valid == 1'b1);
    log_message("[OK] Transmissão com enable_tx alto por vários ciclos");
    
    // TC-06: Reset durante a transmissão
    test_id = 6;
    log_message($sformatf("\nTC-%0d: Reset durante a transmissão", test_id));
    apply_reset(3);
    data_i = 8'h33;
    enable_tx = 1'b1;
    @(posedge clk_i);
    enable_tx = 1'b0;
    // Aguarda alguns ticks de baud para entrar no meio da transmissão
    repeat(20) @(posedge baud_tick);
    // Aplica reset
    rst_i = 1'b0;
    @(posedge clk_i);
    check_value(1'b1, uart_tx_o, "Linha após reset durante transmissão");
    check_value(1'b1, tx_valid, "tx_valid após reset durante transmissão");
    rst_i = 1'b1;
    
    // TC-07: Mudança de data_i durante a transmissão (com verificação e timeout)
    test_id = 7;
    log_message($sformatf("\nTC-%0d: Mudança de data_i durante a transmissão", test_id));
    apply_reset(3);
    data_i = 8'h33;
    enable_tx = 1'b1;
    @(posedge clk_i);
    enable_tx = 1'b0;

    fork
        begin : verify_thread
            reg check_ok;
            check_tx_sequence_timeout(8'h33, BAUD_TICKS_PER_BIT, 10000, check_ok);
            if (check_ok)
                log_message("[OK] Transmissão não foi afetada pela mudança de data_i");
            else
                log_message("[ERRO] Falha na verificação da sequência para TC-07");
        end
        begin : change_data_thread
            repeat(2) @(posedge clk_i);
            data_i = 8'hCC;
        end
    join
    
    // TC-08: Fase do baud_tick no início da transmissão
    test_id = 8;
    log_message($sformatf("\nTC-%0d: Fase do baud_tick no início", test_id));
    apply_reset(3);
    // Inicia transmissão logo após um baud_tick
    @(posedge baud_tick);
    data_i = 8'h5A;
    enable_tx = 1'b1;
    @(posedge clk_i);
    enable_tx = 1'b0;
    wait(tx_valid == 1'b1);
    log_message("[OK] Transmissão iniciada logo após baud_tick");
    
    // TC-09: Fase do baud_tick no meio do período
    test_id = 9;
    log_message($sformatf("\nTC-%0d: Fase do baud_tick no meio do período", test_id));
    apply_reset(3);
    // Aguarda metade do período (8 ciclos) e inicia
    repeat(8) @(posedge clk_i);
    data_i = 8'h5A;
    enable_tx = 1'b1;
    @(posedge clk_i);
    enable_tx = 1'b0;
    wait(tx_valid == 1'b1);
    log_message("[OK] Transmissão iniciada no meio do período de baud_tick");
    
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
    $dumpfile("../sim/uart_tx_tb.vcd");
    $dumpvars(0, tb_tx);
end

endmodule