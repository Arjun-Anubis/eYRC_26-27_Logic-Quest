
// controller.v - controller for RISC-V CPU

module controller (
    input [6:0]  op,
    input [2:0]  funct3,
    input        funct7b5,
    input        Zero,
    output       [1:0] ResultSrc,
    output       MemWrite,
    output       PCSrc, ALUSrc,
    output       RegWrite, Jump, 
    output [2:0] ImmSrc,
    output [3:0] ALUControl,
	 output Jalr,
	 input			Lt, Ltu
);

wire [1:0] ALUOp;
wire       Branch;

main_decoder    md (op, ResultSrc, MemWrite, Branch,
                    ALUSrc, RegWrite, Jump, ImmSrc, ALUOp);

alu_decoder     ad (op[5], funct3, funct7b5, ALUOp, ALUControl);

//Branching conditions
reg 		BranchTaken;
always @(*) begin
    case (funct3)
        3'b000:  BranchTaken = Zero;     // beq
        3'b001:  BranchTaken = ~Zero;    // bne
        3'b100:  BranchTaken = Lt;       // blt
        3'b101:  BranchTaken = ~Lt;      // bge
        3'b110:  BranchTaken = Ltu;      // bltu
        3'b111:  BranchTaken = ~Ltu;     // bgeu
        default: BranchTaken = 1'b0;
    endcase
end

// for jump and branch
assign PCSrc = (Branch & BranchTaken) | Jump;
assign Jalr = (op == 7'b1100111);	//Edit

endmodule

