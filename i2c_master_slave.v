/* I2C - Master/Slave
*/

module i2c_master_slave (sda,
			scl,
			clk_50,
			reset,
			state_reset,
			mode);

inout sda;
output reg scl;
input clk_50;
input reset;
input state_reset;
input mode;

//Internal Counters 
integer count;						//Counter for slow clock - 20KHz
integer bitcounter;					//Counter for number of bits
integer delay;						//For start/stop condition

//MODE
//reg mode;						//Master/Slave (mode=1)

//Internal Registers
reg sda_en;						//Enable signal for Bidir Serial Data out line (read=1/write=0)
reg sda_in;						//input port for the bidir SDA---master data out
reg sda_out;						//slave input

//reg sda_out;						//output port for the bidir SDA
//reg sda_temp;						//Temporary register to store the value of sda_out
	
reg clk_200=0;						//200KHz clock initialization
reg [3:0] state,next;					//4-bit internal states
//reg ack_bit;						//1-bit ACK signal
reg [7:0] slave_address=8'b1101000_0;			//7-bit slave_address[MSB:LSB-1] and 1-bit (read/write=1/0) [LSB]
reg [7:0] slave_address_read=8'b1101000_1;		//7-bit slave_address_read[MSB:LSB-1] and 1-bit (read/write=1/0)
reg [7:0] data=8'b11110000;				//8-bit data
reg [7:0] register_address=8'b00111000;			//8-bit register_address

//STATE PARAMETERS
parameter idle=4'b0000;
parameter start=4'b0001;
parameter slave_addrs=4'b0010;
parameter sending_addrs=4'b0011;
parameter ack_addrs=4'b0100;
parameter reg_nos=4'b0101;
parameter sending_reg_no=4'b0110;
parameter ack_reg_data=4'b0111;
parameter start_repeat=4'b1000;
parameter slave_addrs_repeat=4'b1001;
parameter sending_slave_repeat=4'b1010;
parameter ack_addrs_repeat=4'b1011;
parameter datas=4'b1100;
parameter sending_data=4'b1101;
parameter ack_data=4'b1110;
parameter stop=4'b1111;

//bidir SDA assignment 
assign sda=(sda_en==1'b0) ? sda_in : 1'bz;				//To drive the SDA as output with master sending data and slave reading	
assign sda=(sda_en==1'b0) ? 1'bz:sda_out;				//To read from the SDA as input with slave sending data and master receving 

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
		delay<=delay+1;
	end	
end



//MASTER MODEL
always @(state or delay & mode==1 )
begin
	case (state)
		idle:begin
			scl= 1'b1;
			sda_en= 1'b0;
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
			if (delay==2)begin
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
			sda_out= 1'b0;
			bitcounter=8;
			next=reg_nos;	
		
		end	
		reg_nos: begin
			scl=#1 1'b0;
			sda_en=#1 1'b0;
			if (delay==3)begin
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
			sda_out=#1 1'b0;
			bitcounter=8;
			next=datas;
		end
		datas:begin
			//ack_bit=#1 1'b0;
			scl=#1 1'b0;
			sda_en=#1 1'b0;
			if (delay==3)begin
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
			sda_out=#1 1'b0;
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
			next = idle;
			end
			else next = stop;
		end	
	endcase
end

//SLAVE MODEL
/*
always @(state or delay & mode==0)
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
			else if (delay==3) begin
			scl=1'b0;
			bitcounter=8;
			delay=0;
			next=slave_addrs; 
			end		
			else next=start;
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
			sda_en=#1  1'b1;
			sda_in= 1'b0;
			bitcounter=8;
			next=reg_nos;	
		
		end	
		reg_nos: begin
			scl=#1 1'b0;
			sda_en=#1 1'b0;
			if (delay==3)begin
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
			sda_in=#1 1'b0;
			bitcounter=8;
			delay=0;	
			next=start_repeat;
		end
		start_repeat:begin
			scl=#1 1'b1;
			sda_en= 1'b0;
			sda_in= 1'b1;
			if (delay==2)begin
			sda_in= 1'b0;
			next=start_repeat;end
			else if (delay==3) begin
			scl=1'b0;
			bitcounter=8;
			delay=0;
			next=slave_addrs_repeat;end
			else next=start_repeat;
		end
		slave_addrs_repeat:begin
			scl=#1 1'b0;
			if (delay==3)begin
			sda_in= slave_address[7];
			delay=0;
			next=sending_slave_repeat;
			end
			else next=slave_addrs_repeat;
		end
		sending_slave_repeat:begin
			scl=#1 1'b1;
			if (bitcounter-1>=0)begin
				slave_address_read=slave_address_read<<1;
				bitcounter=bitcounter-1;
				next=slave_addrs_repeat;
			end
			else begin
				bitcounter<=8;
				next=ack_addrs_repeat;
			end
			end
		ack_addrs_repeat:begin
			scl=#1 1'b0;
			sda_en=#1  1'b1;
			sda_in=#1 1'b0;
			bitcounter=8;
			delay=0;
			next=datas;
		end
		datas:begin
			//ack_bit=#1 1'b0;
			scl=#1 1'b0;
			sda_en=#1 1'b0;
			if (delay==3)begin
			sda_in= data[7];
			delay=0;
			next=sending_data;end
			else next = datas;
		

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
			sda_in=#1 1'b0;
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
			next = idle;
			end
			else next = stop;

		end	
	endcase	
end*/
endmodule 