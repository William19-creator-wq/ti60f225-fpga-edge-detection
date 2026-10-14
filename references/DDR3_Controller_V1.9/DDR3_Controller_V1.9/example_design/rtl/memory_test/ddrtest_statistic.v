//***************************************************************/
//   ______   _   _   _                  _            _
//  |  ____| | | (_) | |                | |          | |
//  | |__    | |  _  | |_    ___   ___  | |_    ___  | | __
//  |  __|   | | | | | __|  / _ \ / __| | __|  / _ \ | |/ /
//  | |____  | | | | | |_  |  __/ \__ \ | |_  |  __/ |   <  
//  |______| |_| |_|  \__|  \___| |___/  \__|  \___| |_|\_\
//
// Moudel Name    : ddrtest_statistic.v
// Version        : 1.5
// Date Created   : 2023-09-20 10:44:26
// Last Modified  : 2023-09-20 15:23:19
// Abstract       : ---
//
//Copyright (c) 2020-2023 Elitestek,Inc. All Rights Reserved.
//
//***************************************************************/
//Modification History
//1.initial
//***************************************************************/

`timescale 1ns / 1ns

module ddrtest_statistic
# (
  	parameter   DDR_CLK_PERIOD  = 32'd800_000_000 ,
  	parameter   AXI_CLK_PERIOD  = 32'd100_000_000 ,
  	parameter   DDR_DATA_WIDTH  = 32              ,
  	parameter   AXI_DATA_WIDTH  = 256             
  )
( 
  //System Signal
  input           SysClk    , //(O)System Clock
  input           Reset_N   , //(I)System Reset (Low Active)
  //DDR Controner Operate Statistics Control & Result
  input           TestBusy  , //(I)Test Busy State  
  input           TestErr   , //(I)Test Read Data Error
  input           StatiClr  , //(I)Staistics Couter Clear
  output  [23:0]  TestTime  , //(O)Test Time      
  output  [23:0]  ErrCnt    , //(O)Test Error Counter   
  output  [47:0]  OpTotCyc  , //(O)Total Operate Cycle Counter
  output  [47:0]  OpActCyc  , //(O)Actual Operate Cycle Counter
  output  [ 9:0]  OpEffic   , //(O)Operate Efficiency
  output  [ 9:0]  RdOpEffic , //(O)Read Operate Efficiency
  output  [ 9:0]  WrOpEffic , //(O)Write Operate Efficiency
  output  [15:0]  BandWidth , //(O)BandWidth
  output  [9:0]   WrPeriMin , //Write Minimum Period For One Burst
  output  [9:0]   WrPeriAvg , //Write Average Period For One Burst
  output  [9:0]   WrPeriMax , //Write maximum Period For One Burst
  output  [9:0]   RdPeriMin , //Read Minimum Period For One Burst
  output  [9:0]   RdPeriAvg , //Read Average Period For One Burst
  output  [9:0]   RdPeriMax , //Read maximum Period For One Burst
  output          TimeOut   , //(O)TimeOut
  //DDR Controner AXI4 Signal
  input           avalid    , //(I)[Addres] Address Valid
  input           aready    , //(I)[Addres] Address Ready
  input           atype     , //(I)[Addres] Operate Type 0=Read, 1=Write
  input           wlast     , //(I)[Write]  Data Last
  input           wvalid    , //(I)[Write]  Data Valid
  input           wready    , //(I)[Write]  Data Ready
  input           rlast     , //(I)[Read]   Data Last
  input           rvalid    , //(I)[Read]   Data Valid
  input           rready      //(I)[Read]   Data Ready
);

 	//Define  Parameter
	/////////////////////////////////////////////////////////
	parameter		TCo_C   		= 1;    
	
	localparam [80:0] CalcEfficCoaf_C = ( AXI_CLK_PERIOD  * AXI_DATA_WIDTH  * {64'h0,17'h1_f4_00}) 
	                                  / ( DDR_CLK_PERIOD  * DDR_DATA_WIDTH );
	
	localparam [16:0] EFFICIENCY_COAF = CalcEfficCoaf_C[18:2]; 
	
	localparam [16:0] BANDWIDTH_COAF  = (AXI_DATA_WIDTH == 256) ? 17'h1_0c_70 : 17'h0_86_38;
	                                                
	/////////////////////////////////////////////////////////

//Encryption begin
`pragma protect begin_protected
`pragma protect version=1
`pragma protect encrypt_agent="ipecrypt"
`pragma protect encrypt_agent_info="http://ipencrypter.com Version: 20.0.8"
`pragma protect author="author-a"
`pragma protect author_info="author-a-details"

`pragma protect key_keyowner="Efinix Inc."
`pragma protect key_keyname="EFX_K01"
`pragma protect key_method="rsa"
`pragma protect encoding=(enctype="base64", line_length=64, bytes=256)
`pragma protect key_block
g9ZFl88mS0apdYuO3ydXkpE+jom9flMD1gvjRFf+jGRJpsl8QSeNeiknK451+/z+
eXakn79T2LHoHvSZ8u8rYBRhXiY9WuypfgAFSoSSIR0ML3FtgYHQP9l/CeNLRHER
3HDuaMEueWOT4+8l06R6Hyd5NJ3CCO7twDu9z88okVu6qxHbJnEfPhoHMRJi5a76
tIY4a+A66uf820j2xde3GAIrtlDuB897kxw0JGMqeYaKF7SR1cbR/jekjzzWiFNk
0eCb1ZZsHH5qF1qQ7sovt6dbI/4bhYS+3CWn2jVrY+1bf18LT8wECCgyHk3c5Zcg
7+HJ6L1DtA2U7sE04eWtMw==
`pragma protect key_keyowner="Mentor Graphics Corporation"
`pragma protect key_keyname="MGC-VERIF-SIM-RSA-1"
`pragma protect key_method="rsa"
`pragma protect encoding=(enctype="base64", line_length=64, bytes=128)
`pragma protect key_block
ERhyHVZSg2YPV0vY3eDzCeWqSUZTIpcanPMWlQww//6sCFd2z5qaD39ha77qc6rf
YGk8mr7nQHouikR7uMYcWCaViiX+XImwFndptpVTQ1yI7tm+DIM1/9rc9RUjTT4P
+rLF7ABSy5NqLOVY1ACPdyeqivFZLbrfMZ89+dUBSkI=
`pragma protect data_method="aes256-cbc"
`pragma protect encoding=(enctype="base64", line_length=64, bytes=22704)
`pragma protect data_block
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
`pragma protect end_protected
endmodule

////////////////// DdrTestStat /////////////////////////////

