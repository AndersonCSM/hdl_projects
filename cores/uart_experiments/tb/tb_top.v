`timescale 1ns/1ps

module tb_top();

// Parâmetros
parameter CLK_PERIOD = 37;
parameter BAUD_RATE = 115200;
parameter CLK_FREQ = 27_000_000;
parameter BAUD_TICKS_PER_BIT = 16;
localparam DIVISOR = (CLK_FREQ + BAUD_RATE*8) / (BAUD_RATE*16);
localparam CLK_CYCLES_PER_BIT = DIVISOR * BAUD_TICKS_PER_BIT;

parameter FIFO_DATA_WIDTH = 8;
parameter FIFO_ADDR_WIDTH = 4;
localparam FIFO_DEPTH = 1 << FIFO_ADDR_WIDTH;

// Sinais do DUT principal
reg clk_i;
reg rst_i;
reg uart_rx_i;
wire uart_tx_o;
reg [7:0] tx_data_i;
reg tx_send_i;
wire tx_ready_o;
wire tx_full_o;
wire [7:0] rx_data_o;
wire rx_valid_o;
reg rx_rd_en_i;
wire rx_full_o;

// Sinais do DUT com loopback
wire uart_tx_lb_o;
reg [7:0] tx_data_lb;
reg tx_send_lb;
wire tx_ready_lb;
wire tx_full_lb;
wire [7:0] rx_data_lb;
wire rx_valid_lb;
reg rx_rd_en_lb;
wire rx_full_lb;

integer errors = 0;
integer test_id = 0;
integer log_file;

// Instância do DUT principal (sem loopback)
uart_top #(
    .CLK_FREQ(CLK_FREQ),
    .BAUD_RATE(BAUD_RATE),
    .ENABLE_TX(1'b1),
    .ENABLE_RX(1'b1),
    .LOOPBACK(1'b0),
    .FIFO_DATA_WIDTH(FIFO_DATA_WIDTH),
    .FIFO_ADDR_WIDTH(FIFO_ADDR_WIDTH)
) dut_top (
    .clk_i(clk_i),
    .rst_i(rst_i),
    .uart_rx_i(uart_rx_i),
    .uart_tx_o(uart_tx_o),
    .tx_data_i(tx_data_i),
    .tx_send_i(tx_send_i),
    .tx_ready_o(tx_ready_o),
    .tx_full_o(tx_full_o),
    .rx_data_o(rx_data_o),
    .rx_valid_o(rx_valid_o),
    .rx_rd_en_i(rx_rd_en_i),
    .rx_full_o(rx_full_o)
);

// Instância do DUT com loopback
uart_top #(
    .CLK_FREQ(CLK_FREQ),
    .BAUD_RATE(BAUD_RATE),
    .ENABLE_TX(1'b1),
    .ENABLE_RX(1'b1),
    .LOOPBACK(1'b1),
    .FIFO_DATA_WIDTH(FIFO_DATA_WIDTH),
    .FIFO_ADDR_WIDTH(FIFO_ADDR_WIDTH)
) dut_top_lb (
    .clk_i(clk_i),
    .rst_i(rst_i),
    .uart_rx_i(1'b1),
    .uart_tx_o(uart_tx_lb_o),
    .tx_data_i(tx_data_lb),
    .tx_send_i(tx_send_lb),
    .tx_ready_o(tx_ready_lb),
    .tx_full_o(tx_full_lb),
    .rx_data_o(rx_data_lb),
    .rx_valid_o(rx_valid_lb),
    .rx_rd_en_i(rx_rd_en_lb),
    .rx_full_o(rx_full_lb)
);

// Geração de clock e reset
initial clk_i = 1'b0;
always #(CLK_PERIOD/2) clk_i = ~clk_i;

initial begin
    rst_i = 1'b0;
    uart_rx_i = 1'b1;
    tx_data_i = 8'h00;
    tx_send_i = 1'b0;
    rx_rd_en_i = 1'b0;
    tx_data_lb = 8'h00;
    tx_send_lb = 1'b0;
    rx_rd_en_lb = 1'b0;
    #200;
    rst_i = 1'b1;
end

// Tarefas de suporte
task log_message;
    input string msg;
    begin
        $display("%s", msg);
        $fdisplay(log_file, "%s", msg);
    end
endtask

task apply_reset;
    input integer duration;
begin
    rst_i = 1'b0;
    repeat(duration) @(posedge clk_i);
    rst_i = 1'b1;
end
endtask

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

task hw_send_byte;
    input [7:0] data;
begin
    wait(tx_full_o == 1'b0);
    @(posedge clk_i);
    tx_data_i = data;
    tx_send_i = 1'b1;
    @(posedge clk_i);
    tx_send_i = 1'b0;
end
endtask

task hw_send_byte_lb;
    input [7:0] data;
begin
    wait(tx_full_lb == 1'b0);
    @(posedge clk_i);
    tx_data_lb = data;
    tx_send_lb = 1'b1;
    @(posedge clk_i);
    tx_send_lb = 1'b0;
end
endtask

task send_serial_byte;
    input [7:0] data;
    integer i;
begin
    uart_rx_i = 1'b0;
    repeat(CLK_CYCLES_PER_BIT) @(posedge clk_i);
    for (i = 0; i < 8; i = i + 1) begin
        uart_rx_i = data[i];
        repeat(CLK_CYCLES_PER_BIT) @(posedge clk_i);
    end
    uart_rx_i = 1'b1;
    repeat(CLK_CYCLES_PER_BIT) @(posedge clk_i);
end
endtask

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

task wait_rx_valid_lb;
    input integer timeout_cycles;
    output reg success;
    integer count;
begin
    success = 0;
    count = 0;
    while (!rx_valid_lb && count < timeout_cycles) begin
        @(posedge clk_i);
        count = count + 1;
    end
    if (rx_valid_lb) begin
        success = 1;
    end else begin
        log_message($sformatf("[ERRO] Timeout aguardando rx_valid_lb (tempo %0t)", $time));
        errors = errors + 1;
    end
end
endtask

task hw_read_byte;
    output [7:0] data;
begin
    rx_rd_en_i = 1'b1;
    @(posedge clk_i);
    #1;
    data = rx_data_o;
    rx_rd_en_i = 1'b0;
end
endtask

task hw_read_byte_lb;
    output [7:0] data;
begin
    rx_rd_en_lb = 1'b1;
    @(posedge clk_i);
    #1;
    data = rx_data_lb;
    rx_rd_en_lb = 1'b0;
end
endtask

// Casos de teste
initial begin
    log_file = $fopen("../sim/top_test_results.txt", "w");
    if (log_file == 0) begin
        $display("ERRO: Não foi possível criar o arquivo de log em ../sim/");
        $finish;
    end

    #200;
    log_message("=============================================");
    log_message(" Testes do Módulo uart_top (UART + FIFOs)");
    log_message("=============================================");

    // TC-01: Estado inicial
    test_id = 1;
    log_message($sformatf("\nTC-%0d: Estado inicial após reset", test_id));
    apply_reset(5);
    check_value(1, tx_ready_o, "tx_ready_o = 1 após reset");
    check_value(0, rx_valid_o, "rx_valid_o = 0 (FIFO RX vazia)");
    check_value(0, rx_data_o, "rx_data_o = 0 após reset");
    check_value(1, uart_tx_o, "uart_tx_o = 1 (repouso) após reset");
    check_value(0, tx_full_o, "tx_full_o = 0 (FIFO TX vazia)");
    check_value(0, rx_full_o, "rx_full_o = 0 (FIFO RX vazia)");

    // TC-02: Transmissão de um byte (0xA5)
    test_id = 2;
    log_message($sformatf("\nTC-%0d: Transmissão de um byte via FIFO TX", test_id));
    apply_reset(3);
    hw_send_byte(8'hA5);
    wait(tx_ready_o == 1'b1);
    log_message("[INFO] Transmissão do byte 0xA5 concluída");

    // TC-03: Recepção de um byte (0x5A)
    test_id = 3;
    log_message($sformatf("\nTC-%0d: Recepção de um byte via FIFO RX", test_id));
    apply_reset(3);
    fork
        begin
            send_serial_byte(8'h5A);
        end
        begin
            reg check_ok;
            wait_rx_valid(10000, check_ok);
            if (check_ok) begin
                reg [7:0] read_data;
                hw_read_byte(read_data);
                check_value(8'h5A, read_data, "Byte recebido na FIFO RX");
            end
        end
    join

    // TC-04: Loopback interno de um byte (0xAA)
    test_id = 4;
    log_message($sformatf("\nTC-%0d: Loopback interno (um byte)", test_id));
    apply_reset(3);
    hw_send_byte_lb(8'hAA);
    begin
        reg check_ok;
        wait_rx_valid_lb(10000, check_ok);
        if (check_ok) begin
            reg [7:0] read_data;
            hw_read_byte_lb(read_data);
            check_value(8'hAA, read_data, "Byte ecoado no loopback");
        end
    end

    // TC-05: Transmissão de múltiplos bytes
    test_id = 5;
    log_message($sformatf("\nTC-%0d: Transmissão de múltiplos bytes (3 bytes)", test_id));
    apply_reset(3);
    hw_send_byte(8'h11);
    hw_send_byte(8'h22);
    hw_send_byte(8'h33);
    wait(tx_ready_o == 1'b1);
    log_message("[OK] Transmissão de múltiplos bytes concluída");

    // TC-06: Recebimento de múltiplos bytes (3 bytes) – sequencial
    test_id = 6;
    log_message($sformatf("\nTC-%0d: Recebimento de múltiplos bytes (3 bytes)", test_id));
    apply_reset(3);
    for (int i = 0; i < 3; i++) begin
        send_serial_byte(8'h41 + i);
        begin
            reg check_ok;
            wait_rx_valid(10000, check_ok);
            if (check_ok) begin
                reg [7:0] d;
                hw_read_byte(d);
                check_value(8'h41 + i, d, $sformatf("Byte %0d recebido", i+1));
            end
        end
    end
    log_message("[OK] Recebimento de múltiplos bytes concluído");

    // TC-07: Loopback interno de múltiplos bytes (3 bytes) – sequencial
    test_id = 7;
    log_message($sformatf("\nTC-%0d: Loopback interno de múltiplos bytes (3 bytes)", test_id));
    apply_reset(3);
    for (int i = 0; i < 3; i++) begin
        hw_send_byte_lb(8'h71 + i);
        begin
            reg check_ok;
            wait_rx_valid_lb(10000, check_ok);
            if (check_ok) begin
                reg [7:0] d;
                hw_read_byte_lb(d);
                check_value(8'h71 + i, d, $sformatf("Byte %0d ecoado", i+1));
            end
        end
    end
    log_message("[OK] Loopback de múltiplos bytes concluído");

    // TC-08: tx_full_o permanece baixo durante envio normal
    test_id = 8;
    log_message($sformatf("\nTC-%0d: tx_full_o permanece baixo durante envio", test_id));
    apply_reset(3);
    for (int i = 0; i < 10; i++) begin
        hw_send_byte(i[7:0]);
        if (tx_full_o !== 1'b0) begin
            log_message($sformatf("[ERRO] tx_full_o foi 1 durante envio normal (tempo %0t)", $time));
            errors = errors + 1;
        end
    end
    wait(tx_ready_o == 1'b1);
    check_value(0, tx_full_o, "tx_full_o = 0 após transmissões");

    // TC-09: Enchimento da FIFO RX
    test_id = 9;
    log_message($sformatf("\nTC-%0d: Enchimento da FIFO RX e rx_full_o", test_id));
    apply_reset(3);
    fork
        begin
            for (int i = 0; i < FIFO_DEPTH; i++) begin
                send_serial_byte(i[7:0]);
            end
        end
        begin
            wait(rx_full_o == 1'b1);
            check_value(1, rx_full_o, "rx_full_o = 1 quando FIFO RX cheia");
            for (int i = 0; i < FIFO_DEPTH; i++) begin
                reg [7:0] d;
                hw_read_byte(d);
            end
            check_value(0, rx_full_o, "rx_full_o = 0 após esvaziar FIFO RX");
        end
    join

    // TC-10: Reset durante operação
    test_id = 10;
    log_message($sformatf("\nTC-%0d: Reset durante operação", test_id));
    apply_reset(3);
    hw_send_byte(8'h33);
    rst_i = 1'b0;
    repeat(2) @(posedge clk_i);
    rst_i = 1'b1;
    #100;
    check_value(1, tx_ready_o, "tx_ready_o = 1 após reset");
    check_value(0, rx_valid_o, "rx_valid_o = 0 após reset");
    check_value(0, tx_full_o, "tx_full_o = 0 após reset");
    check_value(0, rx_full_o, "rx_full_o = 0 após reset");

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

initial begin
    $dumpfile("../sim/top_tb.vcd");
    $dumpvars(0, tb_top);
end

endmodule