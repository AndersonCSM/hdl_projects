`timescale 1ns/1ps

module tb_rx();

parameter CLK_PERIOD = 20;
parameter BAUD_TICKS_PER_BIT = 16;

reg clk_i;
reg rst_i;
reg enable_rx;
reg baud_tick;
reg uart_rx_i;
wire [7:0] data_o;
wire rx_valid;

integer errors = 0;
integer test_id = 0;
integer log_file;

rx dut_rx (
    .clk_i(clk_i),
    .rst_i(rst_i),
    .enable_rx(enable_rx),
    .baud_tick(baud_tick),
    .uart_rx_i(uart_rx_i),
    .data_o(data_o),
    .rx_valid(rx_valid)
);

initial clk_i = 1'b0;
always #(CLK_PERIOD/2) clk_i = ~clk_i;

initial begin
    rst_i = 1'b0;
    enable_rx = 1'b0;
    uart_rx_i = 1'b1;
    baud_tick = 1'b0;
    #100;
    rst_i = 1'b1;
end

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

task send_byte_to_rx;
    input [7:0] data;
    integer i;
begin
    uart_rx_i = 1'b1;
    repeat(BAUD_TICKS_PER_BIT) @(posedge baud_tick);
    uart_rx_i = 1'b0;
    repeat(BAUD_TICKS_PER_BIT) @(posedge baud_tick);
    for (i = 0; i < 8; i = i + 1) begin
        uart_rx_i = data[i];
        repeat(BAUD_TICKS_PER_BIT) @(posedge baud_tick);
    end
    uart_rx_i = 1'b1;
    repeat(BAUD_TICKS_PER_BIT) @(posedge baud_tick);
end
endtask

task wait_rx_valid;
    input integer timeout_cycles;
    output reg success;
    integer count;
begin
    success = 0;
    count = 0;
    while (!rx_valid && count < timeout_cycles) begin
        @(posedge clk_i);
        count = count + 1;
    end
    if (rx_valid) begin
        success = 1;
    end else begin
        log_message($sformatf("[ERRO] Timeout aguardando rx_valid (tempo %0t)", $time));
        errors = errors + 1;
    end
end
endtask

task send_and_check;
    input [7:0] data;
    reg check_ok;
begin
    fork
        begin
            send_byte_to_rx(data);
        end
        begin
            wait_rx_valid(10000, check_ok);
        end
    join
    if (check_ok) begin
        if (data_o !== data) begin
            log_message($sformatf("[ERRO] Valor %h recebido incorretamente como %h", data, data_o));
            errors = errors + 1;
        end
    end else begin
        log_message($sformatf("[ERRO] Timeout para valor %h", data));
        errors = errors + 1;
    end
end
endtask

initial begin
    log_file = $fopen("../sim/rx_test_results.txt", "w");
    if (log_file == 0) begin
        $display("ERRO: Não foi possível criar o arquivo de log em ../sim/");
        $finish;
    end

    #100;
    log_message("=============================================");
    log_message(" Testes do Receptor UART (rx)");
    log_message("=============================================");

    // TC-01
    test_id = 1;
    log_message($sformatf("\nTC-%0d: Estado inicial após reset", test_id));
    apply_reset(5);
    check_value(8'h00, data_o, "data_o inicial após reset");
    check_value(1'b0, rx_valid, "rx_valid em IDLE após reset");

    // TC-02
    test_id = 2;
    log_message($sformatf("\nTC-%0d: Recepção do byte 0xA5", test_id));
    apply_reset(3);
    enable_rx = 1'b1;
    fork
        begin
            send_byte_to_rx(8'hA5);
        end
        begin
            reg check_ok;
            wait_rx_valid(10000, check_ok);
            if (check_ok) begin
                check_value(8'hA5, data_o, "Valor recebido");
                log_message("[INFO] Byte 0xA5 recebido com sucesso");
            end else begin
                log_message("[ERRO] Não recebeu byte 0xA5");
            end
        end
    join

    // TC-03
    test_id = 3;
    log_message($sformatf("\nTC-%0d: Recepção de todos os 256 valores", test_id));
    for (int val = 0; val < 256; val++) begin
        apply_reset(2);
        enable_rx = 1'b1;
        send_and_check(val[7:0]);
    end
    log_message("[OK] Loop de 256 valores concluído");

    // TC-04
    test_id = 4;
    log_message($sformatf("\nTC-%0d: Recepções consecutivas (back-to-back)", test_id));
    apply_reset(3);
    enable_rx = 1'b1;
    send_and_check(8'h55);
    send_and_check(8'hAA);
    log_message("[OK] Duas recepções consecutivas realizadas");

    // TC-05
    test_id = 5;
    log_message($sformatf("\nTC-%0d: enable_rx = 0 (não deve receber)", test_id));
    apply_reset(3);
    enable_rx = 1'b0;
    send_byte_to_rx(8'h33);
    #100000;
    check_value(1'b0, rx_valid, "rx_valid permanece 0 com enable_rx=0");
    check_value(8'h00, data_o, "data_o permanece 0 com enable_rx=0");

    // TC-06
    test_id = 6;
    log_message($sformatf("\nTC-%0d: Reset durante a recepção", test_id));
    apply_reset(3);
    enable_rx = 1'b1;
    fork
        begin
            send_byte_to_rx(8'hC3);
        end
        begin
            repeat(5) @(posedge baud_tick);
            rst_i = 1'b0;
            repeat(2) @(posedge clk_i);
            rst_i = 1'b1;
        end
    join
    #100;
    check_value(1'b0, rx_valid, "rx_valid após reset durante recepção");
    // check_value(8'h00, data_o, "data_o após reset durante recepção");

    // TC-07
    test_id = 7;
    log_message($sformatf("\nTC-%0d: Glitch de curta duração no sinal", test_id));
    apply_reset(3);
    enable_rx = 1'b1;
    uart_rx_i = 1'b0;
    repeat(2) @(posedge clk_i);
    uart_rx_i = 1'b1;
    #100000;
    check_value(1'b0, rx_valid, "rx_valid não deve ser ativado por glitch");
    check_value(8'h00, data_o, "data_o permanece 0 após glitch");

    // TC-08
    test_id = 8;
    log_message($sformatf("\nTC-%0d: Fase do baud_tick no início", test_id));
    apply_reset(3);
    enable_rx = 1'b1;
    @(posedge baud_tick);
    fork
        begin
            send_byte_to_rx(8'h5A);
        end
        begin
            reg check_ok;
            wait_rx_valid(10000, check_ok);
            if (check_ok)
                check_value(8'h5A, data_o, "Byte recebido com fase alinhada");
        end
    join

    // TC-09
    test_id = 9;
    log_message($sformatf("\nTC-%0d: Fase do baud_tick no meio do período", test_id));
    apply_reset(3);
    enable_rx = 1'b1;
    repeat(8) @(posedge clk_i);
    fork
        begin
            send_byte_to_rx(8'hA5);
        end
        begin
            reg check_ok;
            wait_rx_valid(10000, check_ok);
            if (check_ok)
                check_value(8'hA5, data_o, "Byte recebido com fase defasada");
        end
    join

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
    $dumpfile("../sim/rx_tb.vcd");
    $dumpvars(0, tb_rx);
end

endmodule