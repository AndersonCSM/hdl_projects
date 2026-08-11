module tx (
    input logic clk,
    input logic rst,
    input logic start,

    output logic [7:0] data,
    output reg rs232,
    output logic done
);

reg [7:0] r_data;
reg state;

reg [12:0] baud_cnt;

reg bit_flag;
reg [3:0] bit_cnt

/*baud_cnt*/
always@ (posedge clk or negedge rst) begin
    if (! rst)
        baud_cnt <= 'd0;
    else if(state)begin
        if (baud_cnt == 'd30)
            baud_cnt <= 'd0;
        else
            baud_cnt <= baud_cnt + 1'b1;
        end
    else
        baud_cnt <= 'd0;
end

/*rs232*/
always@ (posedge clk or negedge rst) begin
    if (! rst)
        rs232 <= 1'b1;
    else if(state)begin
        if(bit_flag) begin
            case(bit_cnt)
                4'd0:rs232 <= 1'b0;
                4'd1:rs232 <= r_data[0];
                4'd2:rs232 <= r_data[1];
                4'd3:rs232 <= r_data[2];
                4'd4:rs232 <= r_data[3];
                4'd5:rs232 <= r_data[4];
                4'd6:rs232 <= r_data[5];
                4'd7:rs232 <= r_data[6];
                4'd8:rs232 <= r_data[7];
                4'd9:rs232 <= 1'b1;
                default:rs232 <= 1'b1;
            endcase
        end
    end
 else
    rs232 <= 1'b1;
end

endmodule