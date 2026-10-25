
// branching_unit.v - logic for branching in execute stage

module branching_unit (
    input [2:0] funct3,
    input       Zero, Lt, Ltu,
    output reg  Branch
);

initial begin
    Branch = 1'b0;
end

always @(*) begin
    case (funct3)
        3'b000:  Branch = Zero;     // beq
        3'b001:  Branch = ~Zero;    // bne
        3'b100:  Branch = Lt;       // blt
        3'b101:  Branch = ~Lt;      // bge
        3'b110:  Branch = Ltu;      // bltu
        3'b111:  Branch = ~Ltu;     // bgeu
        default: Branch = 1'b0;
    endcase
end

endmodule