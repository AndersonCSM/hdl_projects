module top (
    input  logic clk,   // clock da sua placa (ex: 50 MHz)
    output logic led
);

    logic [24:0] cnt;
    always_ff @(posedge clk) begin
        if (cnt == 25_000_000-1) begin
            cnt <= 0;
            led <= ~led;
        end else begin
            cnt <= cnt + 1;
        end
    end
endmodule