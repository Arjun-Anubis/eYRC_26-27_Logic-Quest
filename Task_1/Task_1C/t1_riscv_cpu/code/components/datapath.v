
// datapath.v
module datapath (
    input         clk, reset,
    input [1:0]   ResultSrc,
    input         PCSrc, ALUSrc,
    input         RegWrite,
    input [2:0]   ImmSrc,
    input [3:0]   ALUControl,
    output        Zero,
    output [31:0] PC,
    input  [31:0] Instr,
    output [31:0] Mem_WrAddr, Mem_WrData,
    input  [31:0] ReadData,
    output [31:0] Result,	
	 input			Jalr,
	 output 			Lt, Ltu
);

wire [31:0] PCNext, PCPlus4, PCTarget, AuiPC, lAuiPC, PCJalr;
wire [31:0] ImmExt, SrcA, SrcB, WriteData, ALUResult;

// next PC logic
mux2 #(32)     pcmux(PCPlus4, PCTarget, PCSrc, PCJalr);
assign PCNext = Jalr? {ALUResult[31:1], 1'b0} : PCJalr;

reset_ff #(32) pcreg(clk, reset, PCNext, PC);
adder          pcadd4(PC, 32'd4, PCPlus4);
adder          pcaddbranch(PC, ImmExt, PCTarget);

// register file logic
reg_file       rf (clk, RegWrite, Instr[19:15], Instr[24:20], Instr[11:7], Result, SrcA, WriteData);
imm_extend     ext (Instr[31:7], ImmSrc, ImmExt);

// ALU logic
mux2 #(32)     srcbmux(WriteData, ImmExt, ALUSrc, SrcB);
alu            alu (SrcA, SrcB, ALUControl, ALUResult, Zero);

//Branching comparisons
assign Lt  = ($signed(SrcA) < $signed(SrcB));
assign Ltu = (SrcA < SrcB);

adder #(32) auipcadder({Instr[31:12], 12'b0}, PC, AuiPC);
mux2 #(32) lauipcmux(AuiPC, {Instr[31:12], 12'b0}, Instr[5], lAuiPC);

// load formatter: pick the byte / half-word out of the word read from memory
// and extend it (LB, LH sign-extend; LBU, LHU zero-extend; LW passes through)
reg  [7:0]  lbyte;
reg  [15:0] lhalf;
reg  [31:0] LoadData;
 
always @(*) begin
    case (ALUResult[1:0])
        2'd0:    lbyte = ReadData[7:0];
        2'd1:    lbyte = ReadData[15:8];
        2'd2:    lbyte = ReadData[23:16];
        default: lbyte = ReadData[31:24];
    endcase
    lhalf = ALUResult[1] ? ReadData[31:16] : ReadData[15:0];
    case (Instr[14:12])
        3'b000:  LoadData = {{24{lbyte[7]}}, lbyte};     // LB
        3'b001:  LoadData = {{16{lhalf[15]}}, lhalf};    // LH
        3'b100:  LoadData = {24'b0, lbyte};              // LBU
        3'b101:  LoadData = {16'b0, lhalf};              // LHU
        default: LoadData = ReadData;                    // LW
    endcase
end


//Result Source
mux4 #(32)     resultmux(ALUResult, LoadData, PCPlus4, lAuiPC, ResultSrc, Result);

assign Mem_WrData = WriteData;
assign Mem_WrAddr = ALUResult;

endmodule

