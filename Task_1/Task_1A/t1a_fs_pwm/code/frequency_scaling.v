// Logic Quest Bot : Task 1A : Frequency Scaling
/*
Instructions
-------------------
Students are not allowed to make any changes in the Module declaration.
This file is used to design a module which will scale down the 50MHz Clock Frequency to clk_5MHz

Recommended Quartus Version : 20.1
The submitted project file must be 20.1 compatible as the evaluation will be done on Quartus Prime Lite 20.1.

Warning: The error due to compatibility will not be entertained.
-------------------
*/

//Frequency Scaling
//Inputs : clk_50MHz
//Output : 5MHz


module frequency_scaling (
    input clk_50MHz,
    input reset_n,
    output reg clk_5MHz
);

//////////////////DO NOT MAKE ANY CHANGES ABOVE THIS LINE //////////////////

	reg [2:0] counter;
	
	initial begin
		counter = 0;
		clk_5MHz = 0;
	end
	
	always @(posedge clk_50MHz or negedge reset_n) 
		if (!reset_n) begin
			clk_5MHz <= 0;
			counter <= 4;
		end
			
		else
			if (counter == 4) begin
				counter <= 0;
				clk_5MHz <= ~clk_5MHz;
			end 
			else
				counter <= counter + 1;



//////////////////DO NOT MAKE ANY CHANGES BELOW THIS LINE //////////////////

endmodule

