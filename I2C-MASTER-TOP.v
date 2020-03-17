/* TEST BENCH for I2C MASTER
*/

module i2c_master_top();
wire sda;
wire scl;
reg clk_50;
reg reset;
reg state_reset;



i2c_master i2c_master(sda,scl,clk_50,reset,state_reset);	
//assign sda =(sda_en==1'b0)? 1'bz:sda_slave_in;

initial
begin
	clk_50=0;
	reset=0;
	
	#5 reset =1;
	#2 reset = 0;

	#35 state_reset = 1;
	#3 state_reset =0;
	#1 state_reset =1;
	//#2559
	//#1601 i2c_master.sda_in=1;
	

end
always 
	#5 clk_50=~clk_50;
initial
	$monitor($time, " STATE[%d] SDA[%d]  SCL[%d]",i2c_master.state,sda,scl);

endmodule 