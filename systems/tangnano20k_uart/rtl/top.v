module top #(
    parameter CLK_FREQ = 27_000_000,
    parameter BAUD_RATE = 115200,
    parameter ENABLE_TX = 1'b1,
    parameter ENABLE_RX = 1'b1,
    parameter LOOPBACK   = 1'b0,
    parameter FIFO_DATA_WIDTH = 8,
    parameter FIFO_ADDR_WIDTH = 4
)(
    input  wire       clk_i,
    input  wire       rst_i,
    input  wire       uart_rx_i,
    output wire       uart_tx_o,
    input  wire [7:0] tx_data_i,
    input  wire       tx_send_i,
    output wire       tx_ready_o,
    output wire [7:0] rx_data_o,
    output wire       rx_valid_o,
    input  wire       rx_rd_en_i,
    output wire       tx_full_o,
    output wire       rx_full_o
);

    // Sinais internos
    wire baud_tick;
    wire uart_tx_sig;
    wire [7:0] uart_rx_data;
    wire uart_rx_valid;

    // FIFO de Transmissão
    wire [7:0] tx_fifo_out;
    wire tx_fifo_empty;
    wire tx_fifo_full;
    reg  tx_rd_en;

    // FIFO de Recepção
    wire rx_fifo_empty;
    wire rx_fifo_full;
    reg  rx_rd_en;

    // Controladora de transmissão
    reg tx_send_pulse = 0;
    reg tx_state = TX_IDLE;
    localparam TX_IDLE = 1'b0, TX_SEND = 1'b1;

    // Multiplexação do loopback
    wire rx_input = LOOPBACK ? uart_tx_sig : uart_rx_i;

    // Instância da UART
    uart #(
        .BAUD_RATE(BAUD_RATE),
        .CLK_FREQ(CLK_FREQ),
        .ENABLE_RX(ENABLE_RX),
        .ENABLE_TX(ENABLE_TX)
    ) uart_inst (
        .clk_i(clk_i),
        .rst_i(rst_i),
        .uart_rx_i(rx_input),
        .uart_tx_o(uart_tx_sig),
        .tx_data_i(tx_fifo_out),
        .tx_send_i(tx_send_pulse),
        .tx_ready_o(tx_ready_o),
        .rx_data_o(uart_rx_data),
        .rx_valid_o(uart_rx_valid)
    );

    // FIFO de Transmissão
    fifo #(
        .DATA_WIDTH(FIFO_DATA_WIDTH),
        .ADDR_WIDTH(FIFO_ADDR_WIDTH)
    ) tx_fifo (
        .clk_i(clk_i),
        .rst_i(rst_i),
        .wr_en_i(tx_send_i & ENABLE_TX),
        .data_in_i(tx_data_i),
        .full_o(tx_fifo_full),
        .rd_en_i(tx_rd_en),
        .data_out_o(tx_fifo_out),
        .empty_o(tx_fifo_empty),
        .count_o()
    );

    // =========================================================
    // CORREÇÃO BLINDADA: Detector de borda para o rx_valid
    // =========================================================
    reg rx_valid_d;
    always @(posedge clk_i or negedge rst_i) begin
        if (!rst_i) rx_valid_d <= 1'b0;
        else rx_valid_d <= uart_rx_valid;
    end
    
    // O pulso de gravação (safe_rx_wr_en) só será '1' no exato ciclo de clock 
    // em que o uart_rx_valid for de 0 para 1.
    wire safe_rx_wr_en = uart_rx_valid & ~rx_valid_d & ENABLE_RX;

    // FIFO de Recepção
    fifo #(
        .DATA_WIDTH(FIFO_DATA_WIDTH),
        .ADDR_WIDTH(FIFO_ADDR_WIDTH)
    ) rx_fifo (
        .clk_i(clk_i),
        .rst_i(rst_i),
        .wr_en_i(safe_rx_wr_en),  // Usa o pulso blindado em vez do original
        .data_in_i(uart_rx_data),
        .full_o(rx_fifo_full),
        .rd_en_i(rx_rd_en),
        .data_out_o(rx_data_o),
        .empty_o(rx_fifo_empty),
        .count_o()
    );

    // Lógica de leitura da FIFO RX
    assign rx_valid_o = !rx_fifo_empty;
    always @(*) begin
        rx_rd_en = rx_rd_en_i & !rx_fifo_empty;
    end

    // Atribuições de saída
    assign uart_tx_o = ENABLE_TX ? uart_tx_sig : 1'b1;
    assign tx_full_o = tx_fifo_full;
    assign rx_full_o = rx_fifo_full;

    // Controladora de transmissão (FSM)
    always @(posedge clk_i or negedge rst_i) begin
        if (!rst_i) begin
            tx_state <= TX_IDLE;
            tx_rd_en <= 1'b0;
            tx_send_pulse <= 1'b0;
        end else begin
            tx_send_pulse <= 1'b0;
            tx_rd_en <= 1'b0;
            case (tx_state)
                TX_IDLE: begin
                    if (!tx_fifo_empty && tx_ready_o && ENABLE_TX) begin
                        tx_rd_en <= 1'b1;
                        tx_state <= TX_SEND;
                    end
                end
                TX_SEND: begin
                    if (tx_ready_o) begin
                        tx_send_pulse <= 1'b1;
                        tx_state <= TX_IDLE;
                    end
                end
            endcase
        end
    end

endmodule