module i2c_slave_top();

wire sda;
wire scl;
reg clk_50;
reg reset;
reg state_reset;

i2c_slave i2c_slave(sda,scl,clk_50,reset,state_reset);	

initial
begin
	clk_50=0;
	reset=0;
	
	#5 reset =1;
	#2 reset = 0;

	#35 state_reset = 1;
	#3 state_reset =0;
	#1 state_reset =1;
	
end
always 
	#5 clk_50=~clk_50;
initial
	$monitor($time, " STATE[%d] SDA[%d]  SCL[%d]",i2c_slave.state,sda,scl);

endmodule 


