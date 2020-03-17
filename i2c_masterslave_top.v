/* I2C - MASTER SLAVE  

*/

module i2c_masterslave_top();

wire sda;
wire scl;
reg clk_50;
reg reset;
reg state_reset;

i2c_master i2c_master_m1(sda,scl,clk_50,reset,state_reset);

//i2c_slave i2c_slave_s1(sda,scl,clk_50,reset,state_reset);

initial
begin
	clk_50=0;
	reset=0;
	//mode=1;

	#5 reset =1;
	#2 reset = 0;

	#35 state_reset = 1;
	#3 state_reset =0;
	#1 state_reset =1;
	
	//#7248
	
	//mode =0;
	//#5 reset =1;
	//#2 reset = 0;

	//#35 state_reset = 1;
	//#3 state_reset =0;
	//#1 state_reset =1;
	
	
end

always 
	#5 clk_50=~clk_50;
endmodule 