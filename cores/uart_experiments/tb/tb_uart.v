`timescale 1ns/1ps

module tb_uart();

// ============================================================================
// Parâmetros e Sinais
// ============================================================================
parameter CLK_PERIOD = 37;          // 27 MHz -> ~37 ns
parameter BAUD_RATE = 115200;
parameter CLK_FREQ = 27_000_000;
parameter BAUD_TICKS_PER_BIT = 16;  // Oversampling 16x (padrão UART)

// Cálculo do divisor real usado pelo baud_generate interno do DUT
localparam DIVISOR = (CLK_FREQ + BAUD_RATE*8) / (BAUD_RATE*16);
// Total de ciclos de clock por bit UART
localparam CLK_CYCLES_PER_BIT = DIVISOR * BAUD_TICKS_PER_BIT;

// Sinais do DUT
reg clk_i;
reg rst_i;
reg uart_rx_drive;   // Sinal de entrada dirigido pelo testbench (quando não em loopback)
wire uart_rx_i;      // Sinal real de entrada do DUT
reg [7:0] tx_data_i;
reg tx_send_i;
wire uart_tx_o;
wire tx_ready_o;
wire [7:0] rx_data_o;
wire rx_valid_o;

// Controle de loopback
reg loopback_en;
assign uart_rx_i = loopback_en ? uart_tx_o : uart_rx_drive;

// Sinais auxiliares
integer errors = 0;
integer test_id = 0;
integer log_file;

// Gerador de baud tick externo (para verificação no TC-02)
reg baud_tick;

// Instanciação do DUT (UART completa)
uart #(
    .BAUD_RATE(BAUD_RATE),
    .CLK_FREQ(CLK_FREQ)
) dut_uart (
    .clk_i(clk_i),
    .rst_i(rst_i),
    .uart_rx_i(uart_rx_i),
    .uart_tx_o(uart_tx_o),
    .tx_data_i(tx_data_i),
    .tx_send_i(tx_send_i),
    .tx_ready_o(tx_ready_o),
    .rx_data_o(rx_data_o),
    .rx_valid_o(rx_valid_o)
);

// ============================================================================
// Geração de Clock e Reset
// ============================================================================
initial clk_i = 1'b0;
always #(CLK_PERIOD/2) clk_i = ~clk_i;

// Reset inicial
initial begin
    rst_i = 1'b0;
    uart_rx_drive = 1'b1;  // Linha em repouso
    tx_data_i = 8'h00;
    tx_send_i = 1'b0;
    loopback_en = 1'b0;
    baud_tick = 1'b0;
    #200;
    rst_i = 1'b1;
end

// ============================================================================
// Gerador de Baud Tick externo (para monitoramento no TC-02)
// ============================================================================
reg [15:0] baud_counter = 16'd0;
always @(posedge clk_i or negedge rst_i) begin
    if (!rst_i) begin
        baud_counter <= 16'd0;
        baud_tick <= 1'b0;
    end else begin
        if (baud_counter >= DIVISOR - 1) begin
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

// Verifica um valor esperado contra o real (até 32 bits)
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

// Envia um byte pelo transmissor UART usando tx_send_i e aguarda conclusão
task send_tx_byte;
    input [7:0] data;
begin
    wait(tx_ready_o == 1'b1);
    @(posedge clk_i);
    tx_data_i = data;
    tx_send_i = 1'b1;
    @(posedge clk_i);
    tx_send_i = 1'b0;
    wait(tx_ready_o == 1'b1);
end
endtask

// Recebe um byte serialmente pela entrada uart_rx_drive (gera frame UART)
// Usa ciclos de clock para garantir alinhamento com o DUT independente da fase do baud_tick
task receive_rx_byte;
    input [7:0] data;
    integer i;
begin
    // Garante linha em idle por 1 bit time
    uart_rx_drive = 1'b1;
    repeat(CLK_CYCLES_PER_BIT) @(posedge clk_i);
    // Start bit
    uart_rx_drive = 1'b0;
    repeat(CLK_CYCLES_PER_BIT) @(posedge clk_i);
    // Data bits (LSB primeiro)
    for (i = 0; i < 8; i = i + 1) begin
        uart_rx_drive = data[i];
        repeat(CLK_CYCLES_PER_BIT) @(posedge clk_i);
    end
    // Stop bit
    uart_rx_drive = 1'b1;
    repeat(CLK_CYCLES_PER_BIT) @(posedge clk_i);
end
endtask

// Aguarda rx_valid_o com timeout
task wait_rx_valid;
    input integer timeout_cycles;
    output reg success;
    integer count;
begin
    success = 0;
    count = 0;
    while (!rx_valid_o && count < timeout_cycles) begin
        @(posedge clk_i);
        count = count + 1;
    end
    if (rx_valid_o) begin
        success = 1;
    end else begin
        log_message($sformatf("[ERRO] Timeout aguardando rx_valid_o (tempo %0t)", $time));
        errors = errors + 1;
    end
end
endtask

// ============================================================================
// Casos de Teste (TC-XX)
// ============================================================================

initial begin
    // Abrir arquivo de log
    log_file = $fopen("../sim/uart_test_results.txt", "w");
    if (log_file == 0) begin
        $display("ERRO: Não foi possível criar o arquivo de log em ../sim/");
        $finish;
    end

    #200;
    log_message("=============================================");
    log_message(" Testes da UART (tx + rx integrados)");
    log_message("=============================================");

    // TC-01: Estado inicial após reset
    test_id = 1;
    log_message($sformatf("\nTC-%0d: Estado inicial após reset", test_id));
    apply_reset(5);
    check_value(1, tx_ready_o, "tx_ready_o = 1 após reset");
    check_value(1, uart_tx_o, "uart_tx_o = 1 (repouso) após reset");
    check_value(0, rx_valid_o, "rx_valid_o = 0 após reset");
    check_value(0, rx_data_o, "rx_data_o = 0 após reset");

    // TC-02: Transmissão de um byte (0xA5) e verificação do frame serial
    test_id = 2;
    log_message($sformatf("\nTC-%0d: Transmissão do byte 0xA5", test_id));
    apply_reset(3);
    fork
        begin
            send_tx_byte(8'hA5);
        end
        begin
            @(negedge uart_tx_o);
            repeat(BAUD_TICKS_PER_BIT) @(posedge baud_tick);
            if (uart_tx_o !== 1'b0) begin
                log_message($sformatf("[ERRO] Start bit: esperado 0, obtido %b (tempo %0t)", uart_tx_o, $time));
                errors = errors + 1;
            end else begin
                log_message($sformatf("[OK]   Start bit (tempo %0t)", $time));
            end

            begin
                integer i;
                reg expected_bit;
                reg [7:0] expected_byte;
                expected_byte = 8'hA5;
                for (i = 0; i < 8; i = i + 1) begin
                    repeat(BAUD_TICKS_PER_BIT) @(posedge baud_tick);
                    expected_bit = expected_byte[i];
                    if (uart_tx_o !== expected_bit) begin
                        log_message($sformatf("[ERRO] Bit de dados[%0d]: esperado %b, obtido %b (tempo %0t)", i, expected_bit, uart_tx_o, $time));
                        errors = errors + 1;
                    end else begin
                        log_message($sformatf("[OK]   Bit de dados[%0d] (tempo %0t)", i, $time));
                    end
                end
            end

            repeat(BAUD_TICKS_PER_BIT) @(posedge baud_tick);
            if (uart_tx_o !== 1'b1) begin
                log_message($sformatf("[ERRO] Stop bit: esperado 1, obtido %b (tempo %0t)", uart_tx_o, $time));
                errors = errors + 1;
            end else begin
                log_message($sformatf("[OK]   Stop bit (tempo %0t)", $time));
            end
        end
    join
    log_message("[INFO] Transmissão do byte 0xA5 concluída");

    // TC-03: Recepção de um byte (0x5A) e verificação dos dados
    test_id = 3;
    log_message($sformatf("\nTC-%0d: Recepção do byte 0x5A", test_id));
    apply_reset(3);
    fork
        begin
            receive_rx_byte(8'h5A);
        end
        begin
            reg check_ok;
            wait_rx_valid(10000, check_ok);
            if (check_ok) begin
                check_value(8'h5A, rx_data_o, "Byte recebido");
            end
        end
    join

    // TC-04: Loopback externo TX->RX (atribuição contínua)
    test_id = 4;
    log_message($sformatf("\nTC-%0d: Loopback externo TX->RX (assign)", test_id));
    apply_reset(3);

    loopback_en = 1'b1;   // ativa loopback

    send_tx_byte(8'hAA);

    begin
        reg check_ok;
        wait_rx_valid(10000, check_ok);
        if (check_ok)
            check_value(8'hAA, rx_data_o, "Byte loopback recebido");
    end

    loopback_en = 1'b0;   // desativa loopback, retorna ao drive normal
    uart_rx_drive = 1'b1; // linha em repouso

    // TC-05: Reset durante transmissão
    test_id = 5;
    log_message($sformatf("\nTC-%0d: Reset durante transmissão", test_id));
    apply_reset(3);
    fork
        begin
            send_tx_byte(8'h55);
        end
        begin
            repeat(10) @(posedge baud_tick);
            rst_i = 1'b0;
            repeat(2) @(posedge clk_i);
            rst_i = 1'b1;
        end
    join
    #100;
    check_value(1, tx_ready_o, "tx_ready_o = 1 após reset durante TX");

    // TC-06: Transmissões consecutivas (back-to-back)
    test_id = 6;
    log_message($sformatf("\nTC-%0d: Transmissões consecutivas", test_id));
    apply_reset(3);
    send_tx_byte(8'h11);
    send_tx_byte(8'h22);
    send_tx_byte(8'h33);
    log_message("[OK] Três transmissões consecutivas realizadas");

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
    $dumpfile("../sim/uart_tb.vcd");
    $dumpvars(0, tb_uart);
end

endmodule