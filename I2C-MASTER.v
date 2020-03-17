/* I2C - Single Master Mode.
   Features:-
	1. Bidirectional ports
	2. 7-bit Slave addressable
	3. 8-bit Register Access 
	4. 8-bit Data transfer
	5. 1-bit Slave acknowledgment signal
	6. Start and Stop conditions 
*/


module i2c_master (sda,
		scl,
		clk_50,
		reset,
		state_reset);

//Input-Output Ports
inout sda;				//Bidirectionl Serial Data out port
output reg scl;				//Serial Clock out port
input clk_50;				//FPGA CLK-50MHz
input reset;				//Reset to generate slow clock
input state_reset;			//Reset to begin state transistions
//input mode;
//Internal Counters 
integer count;				//Counter for slow clock - 20KHz
integer bitcounter;			//Counter for number of bits
integer delay;
//Internal Registers
reg sda_en;				//Enable signal for Bidir Serial Data out line (read=1/write=0)
reg sda_in;				//Master input	
reg sda_slave_in;			//Slave output for ACK
//reg sda_out;
//wire sda_temp;
reg clk_200=0;				//200KHz clock initialization
reg [3:0] state,next;			//4-bit internal states
reg ack_bit;				//1-bit ACK signal
reg [7:0] slave_address=8'b1101000_0;	//7-bit slave_address[MSB:LSB-1] and 1-bit (read/write=1/0) [LSB]
reg [7:0] data=8'b1111_0000;		//8-bit data
reg [7:0] register_address=8'b1000_0000;	//8-bit register_address
//reg [7:0] register_address=$random;
//reg [7:0] register_address;
//reg [7:0] data;
parameter idle=4'b0000;
parameter start=4'b0001;
parameter slave_addrs=4'b0010;
parameter sending_addrs=4'b0011;
parameter ack_addrs=4'b0100;
parameter reg_nos=4'b0101;
parameter sending_reg_no=4'b0110;
parameter ack_reg_data=4'b0111;
parameter datas=4'b1000;
parameter sending_data=4'b1001;
parameter ack_data=4'b1010;
parameter stop=4'b1011;

//bidir SDA assignment
assign sda=(sda_en==1'b0)?sda_in : 1'bz;				//To drive the SDA as input		
//assign sda_temp=(sda_en==1'b0)?1'bz:sda_slave_in;			//To read from the SDA 
assign sda=(sda_en==1'b0)?1'bz:sda_slave_in;				//To read from the SDA 

//200KHz clock generation
always @ (posedge clk_50)
begin
	if (reset) begin
		count<=0;
		clk_200<=0;
		delay<=0;			

	end
	else if (count>2)begin
		clk_200<=~clk_200;
		count<=0;
	end
	else	
		count<=count+1;
end

//STATE transistions
always @ (posedge clk_200 or negedge state_reset)
begin
	if (!state_reset)
		state<=idle;
	else begin
		state<=next;
		delay<=delay+1;end	
end

//STATE behaviour
always @(state or delay)
begin
	case (state)
		idle:begin
			scl=#1 1'b1;
			sda_en=#1 1'b0;
			sda_in=1'b1;
			next=start;
		end	
		start:begin
			scl=#1 1'b1;
			sda_en= #1 1'b0;
			if (delay==2) begin
			sda_in= 1'b0;
			next=start;
			end
			else if (delay==3)begin
			scl=1'b0;
			bitcounter=8;
			delay=0;
			next=slave_addrs;
			end
			else begin
			next=start;end
		end
		slave_addrs: begin
			scl=#1 1'b0;
			if (delay==3)begin
			sda_in= slave_address[7];
			delay=0;
			next=sending_addrs;
			end
			else next=slave_addrs;
	
		end
		sending_addrs:begin
			scl=#1 1'b1;
			if (bitcounter-1>=0)begin
				slave_address=slave_address<<1;
				bitcounter=bitcounter-1;
				next=slave_addrs;
			end
			else begin
				bitcounter<=8;
				next=ack_addrs;
			end
			end
		ack_addrs:begin
			scl=#1 1'b0;
			sda_en= 1'b1;
			//sda_out= 1'b0;
			sda_slave_in=1'b0;
			//sda_en=1'b0;
			//sda_in=sda_temp;
			bitcounter=8;
			next=reg_nos;	
		
		end	
		reg_nos: begin
			scl=#1 1'b0;
			sda_en=#1 1'b0;
			if (delay==3)begin
			//register_address = $random;
			sda_in= register_address[7];
			delay=0;
			next=sending_reg_no;
			end
			else
			next=reg_nos;

		end
		sending_reg_no:begin
			scl=#1 1'b1;
			if (bitcounter-1>=0)begin
				register_address=register_address<<1;
				bitcounter=bitcounter-1;
				next=reg_nos;

			end
			else begin
				bitcounter<=8;
				next=ack_reg_data;

			end

		end
		ack_reg_data:begin
			scl=#1 1'b0;
			sda_en=#1  1'b1;
			//sda_out=#1 1'b0;
			sda_slave_in=1'b0;
			bitcounter=8;
			next=datas;
		end
		datas:begin
			ack_bit=#1 1'b0;
			scl=#1 1'b0;
			sda_en=#1 1'b0;
			if (delay==3)begin
			//data = $random;
			sda_in=data[7];
			delay=0;
			next=sending_data;
			end
			else
			next=datas;
		

		end
		sending_data:begin
			scl=#1 1'b1;
			if (bitcounter-1>=0)begin
				data=data<<1;
				bitcounter=bitcounter-1;
				next=datas;

			end
			else begin
				bitcounter<=8;
				next=ack_data;
		
			end
		end
		ack_data:begin
			scl=#1 1'b0;
			sda_en=#1  1'b1;
			//sda_out=#1 1'b0;
			sda_slave_in=1'b0;
			delay=0;
			next=stop;
		end
		stop: begin
			if (delay==2)begin
			scl=1'b1;
			sda_en=#1 1'b0;
			next=stop;
			end
			else if (delay==3)begin
			sda_in=1'b1;
			delay=0;
			//next = idle;
			end
			else next = stop;
		end	
	endcase
end
endmodule 