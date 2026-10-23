
// alu.v - ALU module

module alu #(parameter WIDTH = 32) (
    input       [WIDTH-1:0] a, b,       // operands
    input       [3:0] alu_ctrl,         // ALU control
    output reg  [WIDTH-1:0] alu_out,    // ALU output
    output      zero                    // zero flag
);

// reverse the bit order of a word 
function [WIDTH-1:0] rev(input [WIDTH-1:0] x);
    integer k;
    begin
        for (k = 0; k < WIDTH; k = k + 1) rev[k] = x[WIDTH-1-k];
    end
endfunction

// comparisons
wire lt_u = (a < b);                                  // unsigned
wire lt_s = (a[WIDTH-1] != b[WIDTH-1]) ? a[WIDTH-1] : lt_u;   // signs differ: negative one is smaller
 																				// same sign: unsigned compare is correct

wire                    is_left  = (alu_ctrl == 4'b0111);
wire                    is_sra   = (alu_ctrl == 4'b1001);
wire [4:0]              shamt    = b[4:0];
wire [WIDTH-1:0]        shift_in = is_left ? rev(a) : a;
wire signed [WIDTH:0]   shift_ext = {is_sra & a[WIDTH-1], shift_in};
wire signed [WIDTH:0]   shift_res = shift_ext >>> shamt;
wire [WIDTH-1:0]        shift_out = is_left ? rev(shift_res[WIDTH-1:0]) : shift_res[WIDTH-1:0];


always @(*) begin
    case (alu_ctrl)
        4'b0000:  alu_out = a + b;       // ADD
        4'b0001:  alu_out = a + ~b + 1;  // SUB
        4'b0010:  alu_out = a & b;       // AND
        4'b0011:  alu_out = a | b;       // OR
		  4'b0100:  alu_out = a ^ b;       // XOR
        4'b0101:  alu_out = {{(WIDTH-1){1'b0}}, lt_s};	//SLT
		  4'b0110:  alu_out = {{(WIDTH-1){1'b0}}, lt_u};   // SLTU
        4'b0111,                 // SLL
        4'b1000,  					// SRL
        4'b1001:  alu_out = shift_out;      // SRA
        default: alu_out = {WIDTH{1'b0}};
    endcase
end

assign zero = (alu_out == 0) ? 1'b1 : 1'b0;

endmodule

