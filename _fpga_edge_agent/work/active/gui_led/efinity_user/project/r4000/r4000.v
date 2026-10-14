/*----------------------- PREP OPTIMIZED DESIGN REPORT -------------------
-- FILE NAME               : r4000.v
-- DESIGN NAME             : R4000
-- DESIGN DESCRIPTION      : MIPS R4000 Processor
-- LANGUAGE                : Verilog
-- SYNTHESIS PRODUCT/REV   : Synplify Lite 2.1c
-- SYNTHESIS VENDOR        : Synplicity, Inc.
-- SIMULATION PRODUCT/REV  : SILOS III V95.1
-- SIMULATION VENDOR       : SIMUCAD, Inc
-- APR PRODUCT/REV         : SpDE 5.04
-- APR VENDOR              : QuickLogic, Corp.
-- DEVICE PART NUMBER      : QL24x32B-2
-- DEVICE DESCRIPTION      : FPGA, 768 logic cells, 180 IO cells
-- DEVICE VENDOR           : QuickLogic, Corp.
-- PARAMETER FREQUENCY     : Fmax = 8 MHz
-- UTILIZATION %           : 97 % (744 of 768 cells)
-- APPROX DESIGN GATE COUNT: 8000
-- TOTAL PINCOUNT          : 132 (130 I/O's, 2 Clocks)
-- AUTHOR NAME             : Joel Naumann, Amarpreet Chawla, Micheal Povlin
-- AUTHOR COMPANY          : IDT, Stratacom, QuickLogic
-- AUTHOR EMAIL            : jcn@strata.com,povlin@idtinc.com, amar@qlogic.com
-- COMMENTS                :
-- DATE                    : 7/21/94
------------------------------------------------------------------------*/
/************************************************************************
The following design describes a MIPS R4000 processor core in Verilog. 
The R4000 is a 64 bit RISC processor that uses the MIPS-III instruction set
architecture (ISA). It is fully upward compatible and differs from the
ISA-I/II used by the 32 bit R3000 processor mainly by offering a 64 bit
address mode and adding instructions that perform operations on 64 bit
operands. Due to the ability of the R4000 to execute MIPS-I instructions and
thus behave like a 32 bit processors this design only implements MIPS-I
instructions to reduce the complexity. This makes "this" implementation of the
R4000 a 32 bit processor. Out of the MIPS-I  ISA eleven of the core
instructions were chosen so that each instruction class was represented and
meaningful computations can be performed. The following instructions were
implemented:

	- Memory-reference instructions:   LOAD WORD, STORE WORD
	- Arithmetic-logical instructions: ADD, SUB, AND, OR, XOR, SLL, SRL
	- Jump and Branch instructions:    BEQ, J

All instructions are coded following the MIPS instruction set architecture
(ISA).The design was written in a way that additional instructions can be
easily implemented as needed.

Because of the complexity of this high performance 64 bit processor, we
made some simplifications necessary to implement it in an FPGA.
The RTL description of the pin and functionally compatible IDT R4600 
consists of 88000 lines of Verilog code! Only a subset of the R4000 instruction
set was implemented, no pipelining was used, no primary caches were 
implemented and the number of registers was reduced.

For further information about the MIPS architecture please request
information from one of the following MIPS processor manufacturers:

Integrated Device Technology, Inc.
NEC Electronic, Inc.
LSI Logic Corporation
Toshiba Corporation
Siemens Components, Inc.

An excellent description of the MIPS architecture can also be found in:
Computer Organization & Design. The Hardware/Software Interface. David A.
Patterson, John L. Hennessy, Morgan Kaufmann Publishers, Inc., San Francisco,
California. ISBN 1-55860-281-X
**************************************************************************/

/*********************************************************************
*
*               Module Name:    mR4000
*               Purpose:        Top module for R4000
*                               includes file cntrl.v, alu.v & register.v
*               Copyright:      Michael Povlin, Amarpreet S. Chawla
*                               Joel Naumann
*               Sub modules:    register.v, cntrl.v, alu.v
*
* Please feel free to distribute as long as the header is attached.  
*        
*********************************************************************/

`include "cntrl.v"
`include "alu.v"
`include "register.v"

/*******************************************************************
processor is scalable by changing BUS to 32 to implement 32 bit
version or to 64 to implement 64 bit version 
********************************************************************/ 
`define BUS 32 

module mR4000(
/* Input */
	Clk,
	Reset,
	MemData,
/* Output */
	ReadAdd,
	WriteAdd,
	WriteData,
	MemWrite,
	MemRead);

parameter pBuswidth = `BUS;

input                            Clk;
input                            Reset;
input  [pBuswidth-1:0]           MemData;

output [pBuswidth-1:0]           ReadAdd;
output [pBuswidth-1:0]           WriteAdd;
output [pBuswidth-1:0]           WriteData;
output                           MemWrite;
output                           MemRead;

/* External register definitions */

reg    [pBuswidth-1:0]           ReadAdd;
wire   [pBuswidth-1:0]           WriteAdd;


/* Internal register definitions */

reg    [pBuswidth-1:0]           PC;            // Program counter
reg    [pBuswidth-1:0]           Instruction;   // Instruction register
reg    [pBuswidth-1:0]           TargetReg;     // Target Register

/* Control module wires */

wire             PCWrite;
wire             PCWriteCond;
wire             IorD;
wire             MemRead;
wire             MemWrite;
wire             IRWrite;                       // Instruction register write
wire             MemToReg;
wire   [1:0]     PCSource;
wire             TargetWrite;
wire   [1:0]     ALUOp;
wire   [1:0]     ALUSelB;
wire             ALUSelA;
wire             RegWrite;
wire             RegDst;
wire   [pBuswidth-1:0]  ReadData1;
wire   [pBuswidth-1:0]  ReadData2;

/* Internal wires for register module */

wire   [1:0]     Read1RegSel;
wire   [1:0]     Read2RegSel;
reg    [1:0]     WriteRegSel;
reg    [pBuswidth-1:0]    WriteRegData;


wire                      Zero;
wire   [pBuswidth-1:0]    ALU_result;

/*internal reg for selecting pc*/

wire      pc_set;

/* Logic begins */

assign
   Read1RegSel = Instruction[22:21],     // Utilize only the 2 LSB's
   Read2RegSel = Instruction[17:16];     // Utilize only the 2 LSB's

always @ (RegDst or Instruction)
   if (RegDst)
      WriteRegSel = Instruction[12:11];
   else
      WriteRegSel = Instruction[17:16];


always @ (MemToReg or MemData or ALU_result)
   if (MemToReg)
      WriteRegData = MemData;
   else
      WriteRegData = ALU_result;

/**************************/
/*  REG_IR                */
/*  Instruction register  */
/**************************/

always @ (posedge Clk)
      if (IRWrite)
         Instruction =  MemData;

/**************************/
/* logic for pc_set       */
/**************************/

assign pc_set = (PCWriteCond & Zero) | PCWrite;

/*************************/
/* PC generation         */
/*************************/

always @ (posedge Clk or posedge Reset)
   begin
      if (Reset)
         PC =  0;
      else if (pc_set) begin
         case (PCSource)
            2'b00: PC = ALU_result;
            2'b01: PC = TargetReg; 
            2'b10: PC = {2'b00,PC[31:28],Instruction[25:0]};
        endcase
      end
   end

/************************/
/*   Target Register    */
/************************/

always @ (posedge Clk)
      if (TargetWrite)
         TargetReg = ALU_result;

/************************/
/*Start of control logic*/
/************************/

/* Memory read operation (Instruction or Data) */

always @ (IorD or PC or ALU_result)
   if (IorD)
      ReadAdd = ALU_result;
   else
      ReadAdd = PC;

assign WriteAdd  = ALU_result;
assign WriteData = ReadData2;

/************************************************************/
/*	Module instantiations                               */
/************************************************************/

mCntrl cntrl (
/* Input */
	Instruction[31:26],
	Clk,
	Reset,
/* Output */
	PCWrite,
	PCWriteCond,
	IorD,
	MemRead,
	MemWrite,
	IRWrite,
	MemToReg,
	PCSource,
	TargetWrite,
	ALUOp,
	ALUSelA,
	ALUSelB,
	RegWrite,
	RegDst);

mAlu alu (

/* Input */
	PC,
	ReadData1,
	ReadData2,
	Instruction[15:0],
	ALUSelA,
	ALUSelB,
	ALUOp,

/* Output */
	Zero,
	ALU_result);

defparam alu.pBuswidth = `BUS;

mRegister register (

/* Input */
	Clk,
	Reset,
	Read1RegSel,
	Read2RegSel,
	WriteRegSel,
	WriteRegData,
	RegWrite,
/* Output */
	ReadData1,
	ReadData2);

defparam register.pBuswidth = `BUS;

endmodule

