/*----------------------- PREP OPTIMIZED DESIGN REPORT -------------------
-- FILE NAME             : register.v
-- DESIGN NAME           : REGISTER FILE R4000
-- DESIGN DESCRIPTION    : MIPS R4000 Processor
-- LANGUAGE              : Verilog
-- SYNTHESIS PRODUCT/REV : Synplify Lite 2.1c
-- SYNTHESIS VENDOR      : Synplicity, Inc.
-- SIMULATION PRODUCT/REV: SILOS III V95.1
-- SIMULATION VENDOR     : SIMUCAD, Inc
-- APR PRODUCT/REV       : QuickLogic QuickWorks 5.04
-- AUTHOR NAME           : Joel Naumann, Amarpreet Chawla, Micheal Povlin
-- AUTHOR COMPANY        : IDT, Stratacom, QuickLogic
-- AUTHOR EMAIL          : jcn@strata.com, povlin@idtinc.com, amar@qlogic.com
-- COMMENTS              :
-- DATE                  : 7/21/94
------------------------------------------------------------------------*/
/*********************************************************************
*
*               Module Name:    register.v
*               Purpose:        Register File for R4000
*               Copyright:      Michael Povlin, Amarpreet S. Chawla
*                               Joel Naumann
*
* Please feel free to distribute as long as the header is attached.  
*        
*********************************************************************/

`define	WORD_LENGTH	3

module mRegister(
/* Input */		
		Clk,
		Reset,
		Read1RegSel,
		Read2RegSel,
		WriteRegSel,

		WriteRegData,
		WriteReg,
/* Output */
		Reg1Data,
		Reg2Data);

parameter pBuswidth = 1; // dummy width

input	Reset;
input	Clk;
input [1:0]	Read1RegSel;	
input [1:0]	Read2RegSel;
input [1:0]	WriteRegSel;

input [pBuswidth-1:0]	WriteRegData;
input	        WriteReg;

output [pBuswidth-1:0]	Reg1Data;
output [pBuswidth-1:0]	Reg2Data;

/* External register definitions */

reg	[pBuswidth-1:0]	Reg1Data;
reg	[pBuswidth-1:0]	Reg2Data;	

/* Internal register definitions */

reg	[pBuswidth-1:0]	register0;
reg	[pBuswidth-1:0]	register1;
reg	[pBuswidth-1:0]	register2;
reg	[pBuswidth-1:0]	register3;

/* Write register control */

always @ (posedge Clk)
   begin
	   if (Reset) begin
              register0 =  32'b0;
              register1 =  32'b0;
              register2 =  32'b0;
              register3 =  32'b0;
              end
           else if (WriteReg)		begin
              case (WriteRegSel)
                2'b00:	register0 =  WriteRegData;
                2'b01:	register1 =  WriteRegData;
                2'b10:	register2 =  WriteRegData;
                2'b11:	register3 =  WriteRegData;
                endcase
              end
    end

/* Read register select */

always @ (Read1RegSel 	or
          register0	or
          register1	or
          register2	or
          register3)
	begin
	        case (Read1RegSel) 
                  2'b00:	Reg1Data = register0;
                  2'b01:	Reg1Data = register1;
                  2'b10:	Reg1Data = register2;
                  2'b11:	Reg1Data = register3;
		endcase
	end


always @ (Read2RegSel 	or
	  register0     or
          register1     or
          register2     or
          register3)
	begin
                case (Read2RegSel)
                  2'b00:	Reg2Data = register0;
                  2'b01:	Reg2Data = register1;
                  2'b10:	Reg2Data = register2;
                  2'b11:	Reg2Data = register3;
                endcase
        end
endmodule
