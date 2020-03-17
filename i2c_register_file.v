/* Here we are designing a register bank or a register filw, which is widely used in a digital elctronics 
to randmolmy access data as in case of MIPS32. it has a register file of 32 x 32 register, i.e. 32 reg of 32 bit each,
i.e. an address line of 5 bits. It can do two read and one write operation in a single clock cycle.
*/

module i2c_register_file( 
			read1,
			read2,
			sr1,
			sr2,
			dr,
			write,
			en,
			clk,
			reset	);

parameter word_size = 8;	//32-bits or 4 bytes
parameter address_line = 8;

output [word_size-1:0] read1,read2;
input [address_line-1:0]sr1,sr2,dr;
input [word_size-1:0]write;
input en,clk,reset;
integer k;
reg [word_size-1:0] regfile[0:word_size-1];

assign read1 = regfile[sr1];
assign read2 = regfile[sr2];

always @ (posedge clk)
begin
	if (reset) begin
		for (k=0;k<255;k=k+1)begin
			regfile[k] <= 0;
		end
		end
		else begin
			if (en)
				regfile[dr] <= write;
		end			
end 
endmodule 
/*
module register_file_test();
wire [31:0]read1,read2;
reg [4:0]sr1,sr2,dr;
reg [31:0]write;
reg en,clk,reset;
integer k;

register_file register_file_1( 
				read1,
				read2,
				sr1,
				sr2,
				dr,
				write,
				en,
				clk,
				reset	);


initial
begin
	clk = 0;
	#1 reset = 1; en = 0;
	#5 reset = 0;
end

always 
	#5 clk = ~clk;
initial
begin
	#7
	for (k=0;k<31;k=k+1)begin
		dr = k; write = 10 * k; en = 1;
		#10 en = 0; 
	end
	
	#20 
	for (k=0;k<31;k=k+1)begin
		sr1=k;sr2=k+1;
		#5;
		
	end	
 
end
initial
	$monitor("reg[%2d] = %d,reg[%2d] = %d",sr1,read1,sr2,read2);
endmodule       	
*/

