module baud_generate(
    input logic clk,
    input logic rst,
    input logic baud_rate,

    output logic tick_rate
)

reg [15:0] contador_baud <= 16'b0;

/*contador para o baud_rate*/
// tick = clock / (16 * baud_rate)
// tick = 50Mhz / (16 * 115200) = 27
// A cada tick do baud_rate um bit é transmitido
//
always@ (posedge clk or negedge rst) begin
    if (! rst)
        contador_baud <= 'd0;
    else if(tick)
            contador_baud <= 16'b1;
        else:
            contador_baud <= contador_baud + 1'b1;


end

assign tick_rate = (baud_rate = contador_baud);

endmodule