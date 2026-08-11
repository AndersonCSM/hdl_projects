module display7(
    input data[7:0],
    input logic clk,

    output logic leds[7:0],
);

always_ff (posedge clk) begin :
    if data == 8'b0000_0000; // 0
        leds assign <= 8'b1111110;

    else if data == 8'b0000_0001; // 1
        leds assign <= 8'b0110000;

    else if data == 8'b0000_0010; // 2
        leds assign <= 8'b1101101;

    else if data == 8'b0000_0011; // 3
        leds assign <= 8'b1111001;

    else if data == 8'b0000_0100; // 4
        leds assign <= 8'b0110011;

    else if data == 8'b0000_0101; // 5
        leds assign <= 8'b1011011;

    else if data == 8'b0000_0110; // 6
        leds assign <= 8'b1011111;

    else if data == 8'b0000_0111; // 7
        leds assign <= 8'b1110000;

    else if data == 8'b0000_1000; // 8
        leds assign <= 8'b1111111;

    else if data == 8'b0000_1001; // 9
        leds assign <= 8'b1111011;

    else: // default
        leds assign <= 8'b1111110;
end

endmodule