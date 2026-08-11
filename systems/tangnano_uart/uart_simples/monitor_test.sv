`default_nettype none
`timescale 1ns/1ps

module monitor_test;

    localparam CLK_FREQ = 27_000_000;
    localparam BAUD_RATE = 115200;
    localparam CLK_PERIOD = 1000.0 / (CLK_FREQ / 1_000_000);
    localparam DIVISOR = CLK_FREQ / BAUD_RATE;
    localparam BIT_PERIOD = DIVISOR * CLK_PERIOD;

    reg clk;
    reg rst;
    wire uart_rx, uart_tx;
    reg rx_bit;

    top dut (
        .clk(clk),
        .btn1(rst),
        .uart_rx(uart_rx),
        .uart_tx(uart_tx)
    );

    assign uart_rx = rx_bit;

    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end

    initial begin
        // Init
        rx_bit = 1'b1;
        rst = 1'b0;
        #(1000);
        rst = 1'b1;
        #(100 * CLK_PERIOD);

        // Send 'A' (0x41)
        $display("[%t] Starting transmission of 0x41", $time);
        wait(dut.tick == 1'b1);
        
        rx_bit = 1'b0;
        repeat(DIVISOR) @(posedge clk);
        
        // Data bits
        rx_bit = 1'b1; // bit 0 of 0x41 = 1
        repeat(DIVISOR) @(posedge clk);
        rx_bit = 1'b0; // bit 1
        repeat(DIVISOR) @(posedge clk);
        rx_bit = 1'b1; // bit 2
        repeat(DIVISOR) @(posedge clk);
        rx_bit = 1'b0; // bit 3
        repeat(DIVISOR) @(posedge clk);
        rx_bit = 1'b1; // bit 4
        repeat(DIVISOR) @(posedge clk);
        rx_bit = 1'b0; // bit 5
        repeat(DIVISOR) @(posedge clk);
        rx_bit = 1'b0; // bit 6
        repeat(DIVISOR) @(posedge clk);
        rx_bit = 1'b0; // bit 7
        repeat(DIVISOR) @(posedge clk);
        
        // Stop bit
        rx_bit = 1'b1;
        repeat(DIVISOR) @(posedge clk);

        $display("[%t] Transmission done", $time);

        // Monitor
        repeat(2000) begin
            @(posedge clk);
            if (dut.rx_done) begin
                $display("[%t] RX_DONE detected! rx_data=0x%02X", $time, dut.rx_data);
            end
            if (dut.tx_send_latch) begin
                $display("[%t] TX_SEND_LATCH is high", $time);
            end
        end

        $finish;
    end

endmodule
