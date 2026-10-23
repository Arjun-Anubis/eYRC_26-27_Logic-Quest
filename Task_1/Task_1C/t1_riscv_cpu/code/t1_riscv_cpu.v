// t1_riscv_cpu.v - Top Module to test riscv_cpu

module t1_riscv_cpu (
    input         clk, reset,
    input         Ext_MemWrite,
    input  [31:0] Ext_WriteData, Ext_DataAdr,
    output        MemWrite,
    output [31:0] WriteData, DataAdr, ReadData,
    output [31:0] PC, Result
);

wire [31:0] Instr;
wire [31:0] DataAdr_rv32, WriteData_rv32;
wire        MemWrite_rv32;

// instantiate processor and memories
riscv_cpu rvcpu    (clk, reset, PC, Instr,
                    MemWrite_rv32, DataAdr_rv32,
                    WriteData_rv32, ReadData, Result);
instr_mem instrmem (PC, Instr);
// read-modify-write for SB / SH (data_mem.v stays word-only and untouched).
// ReadData is the old word at DataAdr; WriteData stays the raw rs2 value.
wire        is_store = (Instr[6:0] == 7'b0100011) && !reset;   // ignore external writes
wire  [1:0] boff     = DataAdr[1:0];
reg  [31:0] MemWData;
 
always @(*) begin
    MemWData = WriteData;                          // SW and external writes pass through
    if (is_store) begin
        case (Instr[13:12])                        // funct3[1:0]: 00 SB, 01 SH, 10 SW
            2'b00: case (boff)                     // SB
                2'd0:    MemWData = {ReadData[31:8],  WriteData[7:0]};
                2'd1:    MemWData = {ReadData[31:16], WriteData[7:0], ReadData[7:0]};
                2'd2:    MemWData = {ReadData[31:24], WriteData[7:0], ReadData[15:0]};
                default: MemWData = {WriteData[7:0],  ReadData[23:0]};
            endcase
            2'b01: MemWData = boff[1] ? {WriteData[15:0], ReadData[15:0]}   // SH
                                      : {ReadData[31:16], WriteData[15:0]};
            default: ;
        endcase
    end
end
 

data_mem  datamem  (clk, MemWrite, DataAdr, MemWData, ReadData);

assign MemWrite  = (Ext_MemWrite && reset) ? 1 : MemWrite_rv32;
assign WriteData = (Ext_MemWrite && reset) ? Ext_WriteData : WriteData_rv32;
assign DataAdr   = reset ? Ext_DataAdr : DataAdr_rv32;

endmodule

