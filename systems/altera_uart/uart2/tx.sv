module tx (clk,rst,enable,data,done,tx,tick,nbits);	//Define my module as tx

input clk, rst, enable,tick;	//Define 1 bit inputs
input [3:0]nbits;		//Define 4 bits inputs
input [7:0]data;		//Define 8 bit inputs

output tx;V
output done;

//Variabels used for state machine...
parameter  IDLE = 1'b0, WRITE = 1'b1;	//We have 2 states for the State Machine state 0 and 1 (WRITE adn IDLE)
reg  State, Next;			//Create some registers for the states
reg  done = 1'b0;			//Variable used to notify when the transmission process is done
reg  tx;				//We register the input value
reg write_enable = 1'b0;		//Variable used to activate or deactivate the transmission process			
reg start_bit = 1'b1;			//Variable used to notify if the START bit was made or not yet
reg stop_bit = 1'b0;			//Variable used to notify if the STOP bit was made or not yet
reg [4:0] Bit = 5'b00000;		//Variable used for the bit by bit write loop (in this case 8 bits so 8 loops)
reg [3:0] counter = 4'b0000;		//Counter variable used to count the tick pulses up to 16
reg [7:0] in_data=8'b00000000;		//Register where we store tha data that arrived with the data input and has to be sent
reg [1:0] R_edge;			//Variable used to avoid debounce of the write enable pin
wire D_edge;				//Wire used to connect the D_edge

///////////////////////////////STATE MACHINE////////////////////////////////
always @ (posedge clk or negedge rst)			//It is good to always have a reset always
    begin
        if (!rst)	
            State <= IDLE;				//If reset pin is low, we get to the initial state which is IDLE
        else 		
            State <= Next;				//If not we go to the next state
    end

////////////////////////////////////////////////////////////////////////////
////////////////////////////Next step decision//////////////////////////////
////////////////////////////////////////////////////////////////////////////
/* This is easy as well.  Each time "State or D_edge or data or done" will 
change their value we decide which is the next step. 
 - If D_edge was detected, so the enable was enabeled, we start the write process
 - Obviously, if the done is high, then we get back to IDLE and wait for next enable to be activated */
always @ (State or D_edge or data or done) 
    begin
        case(State)	
            IDLE:	
                if(D_edge)		
                    Next = WRITE;		//If we are into IDLE and D_edge gets activated, we start the WRITE process
                else			
                    Next = IDLE;
            WRITE:	
                if(done)		
                    Next = IDLE;  		//If we are into WRITE and done gets high, we get back to IDLE and wait
                else			
                    Next = WRITE;
            default 			
                Next = IDLE;
        endcase
    end

////////////////////////////////////////////////////////////////////////////
///////////////////////////ENABLE WRITE OR NOT//////////////////////////////
////////////////////////////////////////////////////////////////////////////
always @ (State)
    begin
        case (State)
            WRITE: begin
                write_enable <= 1'b1;	//If we are in the WRITE state, we enable the write process
            end
            
            IDLE: begin
                write_enable <= 1'b0;	//If we are in the IDLE state, we disable the write process
            end
        endcase
    end

////////////////////////////////////////////////////////////////////////////
///////////////////////Write the data out on tx pin/////////////////////////
////////////////////////////////////////////////////////////////////////////
/*Finally, each time we detect a tick pulse, if the write_enable is enabeled,
we start counting ticks. First we set the tx pin to LOW and that indicates a start bit.
Then each 16 ticks, we set the tx output to a value acording to the "in_data" value which
is the data to eb sent. We do that by shifting the "in_data" using this lines: 
	in_data <= {1'b0,in_data[7:1]};
	tx <= in_data[0]; */

always @ (posedge tick)
    begin
        if (!write_enable)				//if write_enable is not activated, then we reset all varaibles for enxt loop
            begin
                done = 1'b0;
                start_bit <=1'b1;
                stop_bit <= 1'b0;
            end

        if (write_enable)				//if write_enable is activated, then we start counting and changing the tx output
            begin
                counter <= counter+1;				//Increase the counter by one each positive edge of the tick input
            
            if(start_bit & !stop_bit)			//We set the tx to LOW (start bit) and pass the data input to the in:data register
                begin
                    tx <=1'b0;					//Create start bit  (low pulse)
                    in_data <= data;				//Pass the data to eb sent to the in_data register so we could use it
                end		

            if ((counter == 4'b1111) & (start_bit) )	//If counter reaches 16 (4'b1111), then we create the first bit and set "start_bit" to low
                begin		
                    start_bit <= 1'b0;
                    in_data <= {1'b0,in_data[7:1]};
                    tx <= in_data[0];
                end

            if ((counter == 4'b1111) & (!start_bit) &  (Bit < nbits-1))	//If we reach 16 once again, we make a loop for the next 7 bits (nbits-1)
                begin		
                    in_data <= {1'b0,in_data[7:1]};
                    Bit <=Bit+1;
                    tx <= in_data[0];
                    start_bit <= 1'b0;
                    counter <= 4'b0000;
                end	

            if ((counter == 4'b1111) & (Bit == nbits-1) & (!stop_bit))	//We finish, so we set tx to HIGH (Stop bit)
                begin
                    tx <= 1'b1;	
                    counter <= 4'b0000;	
                    stop_bit <=1'b1;
                end

            if ((counter == 4'b1111) & (Bit == nbits-1) & (stop_bit) )	//If stop bit was enabeled, than we reset the values and wait for enxt write process
                begin
                    Bit <= 4'b0000;
                    done <= 1'b1;
                    counter <= 4'b0000;
                    //start_bit <=1'b1;
                end
        end
    end

////////////////////////////////////////////////////////////////////////////
////////////////////////////Input enable detect/////////////////////////////
////////////////////////////////////////////////////////////////////////////
/*Here we detect if there was a reset or if the enable was activated.
If "enable" was actiavted than we start the write process and we will send
the data that is on the "data" input so make sure that in the 
moment you activate "enable" the data" has the values you want to send . */
always @ (posedge clk or negedge rst)
    begin
        if(!rst)
            begin
                R_edge <= 2'b00;
            end
        else
            begin
                R_edge <={R_edge[0], enable};
            end
    end

assign D_edge = !R_edge[1] & R_edge[0];

endmodule