
-- This is an hierarchical example design in VHDL which shows th eimplementation of differnet VHDL Blocks including IP catalog files.
-- The functions are how to design Bidirctional I/Os with Efinix as well how to debug in te Efinity SW
-- the counter part is assigned to a Ti60 eval Board which can be used to debug the design
-- the Bidi signals are just assigned to random I/Os, means with this I/O assignment it is not assigned to useful I7Os on the T20 Board.
-- signal bidi : INOUT must be divide in a bidi_IN signal and an bidi_OUT signal as well the coresponding OutputEnable signal bidi_OE
-- be careful because all signal names in VHDL and the interface Deisgner are case sensitive !
-- Author: Harald Werner
-- Version: 1.0
-- Date: 1.09.2023
LIBRARY IEEE;
USE IEEE.std_logic_1164.all;
USE IEEE.std_logic_signed.all;
use ieee.numeric_std.all;

Entity Tutorial_top is
port (	
-- from/to the PLL . Generated clock is clkpll. The PLL input clock will be assigned in interface Designer    
		clkpll :  in std_logic;             -- generated clock signal from the Pll (75MHz)
		resetn_pll :  out std_logic;        -- low active
		lock_pll :  in std_logic;           -- hign active. High if PLL is has a lock
-- counter I/Os
		resetn : in std_logic;               -- low active
		stopn : in std_logic;                -- low active
		Led : out std_logic_vector ( 5 downto 0);
-- bidi example  I/Os!  
		set : in std_logic;                 -- high avctive
		rw : in std_logic;                  -- '1' read '0' write
		bidi_IN : in std_logic_vector ( 7 downto 0);
		bidi_OUT : out std_logic_vector ( 7 downto 0);
		bidi_OE : out std_logic_vector ( 7 downto 0)); -- high avctive
ATTRIBUTE syn_peri_port : INTEGER;
ATTRIBUTE syn_peri_port OF clkpll : SIGNAL IS 0;
ATTRIBUTE syn_peri_port OF resetn_pll : SIGNAL IS 0;
ATTRIBUTE syn_peri_port OF lock_pll : SIGNAL IS 0;
ATTRIBUTE syn_peri_port OF resetn : SIGNAL IS 0;
ATTRIBUTE syn_peri_port OF stopn : SIGNAL IS 0;
ATTRIBUTE syn_peri_port OF Led : SIGNAL IS 0;
ATTRIBUTE syn_peri_port OF set : SIGNAL IS 0;
ATTRIBUTE syn_peri_port OF rw : SIGNAL IS 0;
ATTRIBUTE syn_peri_port OF bidi_IN : SIGNAL IS 0;
ATTRIBUTE syn_peri_port OF bidi_OUT : SIGNAL IS 0;
ATTRIBUTE syn_peri_port OF bidi_OE : SIGNAL IS 0;
end Tutorial_top;

Architecture vers1 of Tutorial_top is
-- component declaration of Fifo
COMPONENT Fifo is
PORT (
	prog_full_o : out std_logic;
	full_o : out std_logic;
	empty_o : out std_logic;
	clk_i : in std_logic;
	wr_en_i : in std_logic;
	rd_en_i : in std_logic;
	wdata : in std_logic_vector(5 downto 0);
	datacount_o : out std_logic_vector(8 downto 0);
	rst_busy : out std_logic;
	rdata : out std_logic_vector(5 downto 0);
	a_rst_i : in std_logic);
END COMPONENT;

signal dataouti :  std_logic_vector ( 5 downto 0);
signal empty_o,full_o, a_rst_i, wr_en_i,rd_en_i : std_logic;

Begin

resetn_pll <= resetn;  -- conect PLL reset with systen resetn

-- Bidirectional example with direct instantiation
BiDi_inst :  entity work.Bidi(rtl)
				port map( clkpll =>clkpll,	
						set =>set,	
						rw =>rw,
						lock_pll=>lock_pll,						
						bidi_IN =>bidi_IN,	
						bidi_OUT=>bidi_OUT,	
						bidi_OE =>bidi_OE);
						
-- counter instantiation with direct instantiation
counter_inst :  entity work.counter(rtl)
				port map( clk 		=>clkpll,	
						resetn 		=>resetn,								
						stopn 		=>stopn,								
						Dataout 	=>dataouti); 

-- IP core Fifo section with Fifo control with component decalration and instantiation
a_rst_i <= not resetn;
Fifo_control_process: process(clkpll)
						Begin
								if clkpll'event and clkpll = '1' then
									if lock_pll = '1' then
										if empty_o = '0' then	
											rd_en_i <= '1';    -- set read enable to 1 if empty flag goes inactive
										else	
											rd_en_i <= '0';
										end if;
										if full_o = '1' then	
											wr_en_i <= '0'; -- set write enable inactive if Fifo is Full !!
										else	
											wr_en_i <= '1';
										end if;
									end if;
								end if;
						end process;
                        
-- Fifo instantiation
Fifo_inst : Fifo
			PORT MAP (
					prog_full_o => open,
					full_o => full_o,
					empty_o => empty_o,
					clk_i => clkpll,
					wr_en_i => wr_en_i,
					rd_en_i => rd_en_i,
					wdata => dataouti,
					datacount_o => open,
					rst_busy => open,
					rdata => Led,
					a_rst_i => a_rst_i);						
end;

--------------------------------------------------------------------------------
-- Copyright (C) 2013-2024 Efinix Inc. All rights reserved.              
--
-- This   document  contains  proprietary information  which   is        
-- protected by  copyright. All rights  are reserved.  This notice       
-- refers to original work by Efinix, Inc. which may be derivitive       
-- of other work distributed under license of the authors.  In the       
-- case of derivative work, nothing in this notice overrides the         
-- original author's license agreement.  Where applicable, the           
-- original license agreement is included in it's original               
-- unmodified form immediately below this header.                        
--                                                                       
-- WARRANTY DISCLAIMER.                                                  
--     THE  DESIGN, CODE, OR INFORMATION ARE PROVIDED “AS IS” AND        
--     EFINIX MAKES NO WARRANTIES, EXPRESS OR IMPLIED WITH               
--     RESPECT THERETO, AND EXPRESSLY DISCLAIMS ANY IMPLIED WARRANTIES,  
--     INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF          
--     MERCHANTABILITY, NON-INFRINGEMENT AND FITNESS FOR A PARTICULAR    
--     PURPOSE.  SOME STATES DO NOT ALLOW EXCLUSIONS OF AN IMPLIED       
--     WARRANTY, SO THIS DISCLAIMER MAY NOT APPLY TO LICENSEE.           
--                                                                       
-- LIMITATION OF LIABILITY.                                              
--     NOTWITHSTANDING ANYTHING TO THE CONTRARY, EXCEPT FOR BODILY       
--     INJURY, EFINIX SHALL NOT BE LIABLE WITH RESPECT TO ANY SUBJECT    
--     MATTER OF THIS AGREEMENT UNDER TORT, CONTRACT, STRICT LIABILITY   
--     OR ANY OTHER LEGAL OR EQUITABLE THEORY (I) FOR ANY INDIRECT,      
--     SPECIAL, INCIDENTAL, EXEMPLARY OR CONSEQUENTIAL DAMAGES OF ANY    
--     CHARACTER INCLUDING, WITHOUT LIMITATION, DAMAGES FOR LOSS OF      
--     GOODWILL, DATA OR PROFIT, WORK STOPPAGE, OR COMPUTER FAILURE OR   
--     MALFUNCTION, OR IN ANY EVENT (II) FOR ANY AMOUNT IN EXCESS, IN    
--     THE AGGREGATE, OF THE FEE PAID BY LICENSEE TO EFINIX HEREUNDER    
--     (OR, IF THE FEE HAS BEEN WAIVED, $100), EVEN IF EFINIX SHALL HAVE 
--     BEEN INFORMED OF THE POSSIBILITY OF SUCH DAMAGES.  SOME STATES DO 
--     NOT ALLOW THE EXCLUSION OR LIMITATION OF INCIDENTAL OR            
--     CONSEQUENTIAL DAMAGES, SO THIS LIMITATION AND EXCLUSION MAY NOT   
--     APPLY TO LICENSEE.                                                
--
--------------------------------------------------------------------------------
