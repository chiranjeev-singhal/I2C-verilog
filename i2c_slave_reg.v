/*
	I2C register file slave

	SLAVE 1 = unique address-1101_000
	
*/

module i2c_slave_reg (  sda_slave,
			scl_slave,
			read_slave_1,
			addrs_slave_1,
			sr_slave_1,
			write_slave_1,
			reset_slave,
			en_slave);

parameter word_size = 8; 			//8-bits or 1 byte
parameter addrs_line = 8;			//since we are modelling only 8 registers per slave so we need 3 address lines to access those 8 registers
parameter unique_addr = 7;			//7bits slave unique address

output [word_size-1:0] read_slave_1;		//slave output to read the data stored by master
input sda_slave;				//Serial data in port
input scl_slave;				//slave clock driver
input  [unique_addr-1:0] addrs_slave_1;		//8bit slave address
input  [addrs_line-1:0] sr_slave_1;		//8bit slave internal register address from 0000_0000-1111_1111
input  [word_size-1:0] write_slave_1;		//8bit data to be written in above recevied address
input en_slave,reset_slave;			//to enable and reset slave control signals

reg [7:0] temp_write_slave_1;			//temp reg to store written data
reg [6:0] temp_addrs_slave_1;			//temp reg to store slave unique address
reg [7:0] temp_sr_slave_1;			//temp reg to register address for data to be written inside the slave memory
reg [word_size-1:0] slave1[0:word_size-1]; 	//SLAVE1 memory with 8 registers of 8 bits each

reg [0:3] slave_state,slave_next;		//4bit state variable to access different states

integer k;					//integer to reset/initialize the slave memory to 0
integer slave_delay;				//counts the number of bits received

parameter slave_start=4'b0000;			//slave start state on reset
parameter slave_address_received=4'b0001;	//8bits unique address reception
parameter slave_address_ack=4'b0010;		//unique address acknowledgment signal
parameter slave_register_received=4'b0011;	//8bits register address reception
parameter slave_register_ack=4'b0100;		//register address acknowledgment
parameter slave_data_received=4'b0101;		//8bits data reception
parameter slave_data_ack=4'b0110;		//data acknowledgment
parameter slave_stop=4'b0111;	 		//slave stop state

assign read_slave_1 = slave1[temp_sr_slave_1];	//read/access data stored in the slave memory

always @ (posedge scl_slave or reset_slave)
	if (reset_slave) 
	begin
		for (k=0;k<8;k=k+1) 
		begin
			slave1[k]<=0;
		end		
		slave_state<=slave_start;
		slave_delay<=0;
	end
	else begin 
		slave_state<=slave_next;
		slave_delay<=slave_delay+1;	
	end
always @ (slave_state or slave_delay)
begin
	case (slave_state)
		slave_start: begin
			#286 slave_next=slave_address_received;
			slave_delay=0;
		end

		slave_address_received: begin
			if (slave_delay==8) begin
				slave_next=slave_register_received;
				slave_delay=0;
			end
			else begin
				slave_next=slave_address_received;
				
				temp_addrs_slave_1[6] <= sda_slave;
				temp_addrs_slave_1[5] <= temp_addrs_slave_1[6];
				temp_addrs_slave_1[4] <= temp_addrs_slave_1[5];
				temp_addrs_slave_1[3] <= temp_addrs_slave_1[4];
				temp_addrs_slave_1[2] <= temp_addrs_slave_1[3];
				temp_addrs_slave_1[1] <= temp_addrs_slave_1[2];
				temp_addrs_slave_1[0] <= temp_addrs_slave_1[1];
				
			end
		
		end

		slave_address_ack: begin
			slave_next = slave_register_received;
		end
		
		slave_register_received: begin
			if (slave_delay==10) begin
				slave_next=slave_data_received;
				slave_delay=0;
			end
			else begin
				temp_sr_slave_1[7] <= sda_slave;
				temp_sr_slave_1[6] <= temp_sr_slave_1[7];
				temp_sr_slave_1[5] <= temp_sr_slave_1[6];
				temp_sr_slave_1[4] <= temp_sr_slave_1[5];
				temp_sr_slave_1[3] <= temp_sr_slave_1[4];
				temp_sr_slave_1[2] <= temp_sr_slave_1[3];
				temp_sr_slave_1[1] <= temp_sr_slave_1[2];
				temp_sr_slave_1[0] <= temp_sr_slave_1[1];
				
				slave_next=slave_register_received;
				
			end
		
		end

		slave_register_ack: begin
				slave_next = slave_data_received;
				slave_delay=0;
		end
		
		slave_data_received: begin
			if (slave_delay==9) begin
				slave_next=slave_data_ack;
				slave_delay=0;
				slave1[temp_sr_slave_1]=temp_write_slave_1;	
			end
			else begin
				slave_next=slave_data_received;
				temp_write_slave_1[7] <= sda_slave;
				temp_write_slave_1[6] <= temp_write_slave_1[7];
				temp_write_slave_1[5] <= temp_write_slave_1[6];
				temp_write_slave_1[4] <= temp_write_slave_1[5];
				temp_write_slave_1[3] <= temp_write_slave_1[4];
				temp_write_slave_1[2] <= temp_write_slave_1[3];
				temp_write_slave_1[1] <= temp_write_slave_1[2];
				temp_write_slave_1[0] <= temp_write_slave_1[1];
				
			end
			end
		slave_data_ack: begin
			if (slave_delay==1) begin
				slave_next = slave_stop;
				slave_delay=0;
			end
			else 
				slave_next=slave_data_ack; 
			end

		slave_stop: begin
			
			if (scl_slave==1)
				slave_next = slave_start;
			else
				slave_next=slave_stop;
			end
		endcase
end
endmodule 