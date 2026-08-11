module rx (
    input logic clk,
    input logic rst,
    input logic rs232,
    
    output logic [7:0] data,
    output logic done
);

always@ (posedge clk or negedge rst) begin
    if (! rst) begin
        rs232_t <= 1'b1;
        rs232_t1 <= 1'b1;
        rs232_t2 <= 1'b1;
        end
    else begin
        rs232_t <= rs232;
        rs232_t1 <= rs232_t;
        rs232_t2 <= rs232_t1;
        end
    end

/*data*/
always@ (posedge clk or negedge rst) begin
    if (! rst)
        data <= 'd0;
    else if(state)begin
        if(bit_flag) begin
            case(bit_cnt)
                4'd1: data [0] <= rs232_t2;
                4'd2: data[1] <= rs232_t2;
                4'd3: data[2] <= rs232_t2;
                4'd4: data[3] <= rs232_t2;
                4'd5: data[4] <= rs232_t2;
                4'd6: data[5] <= rs232_t2;
                4'd7: data[6] <= rs232_t2;
                4'd8: data[7] <= rs232_t2;
                default:data <= data;
            endcase
            end
        end
    else
        data <= data;
end

endmodule