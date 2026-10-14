-- simple example design how to build a bidirectional interface wit the Efinity SW.
-- if rw = '1' th ebidi bus enables th eoutput driver.
-- if set = '1' cnt(7:0) will be set from the external bidi I/O value, cnt (31:8) will be set to 0
-- signal bidi : INOUT must be divide in a bidi_IN signal and an bidi_OUT signal as well the coresponding OutputEnable signal bidi_OE
-- signal names are case sensitive !!
-- Author: Harald Werner
-- Version: 1.0
-- Date: 1.09.2023

LIBRARY IEEE;
USE IEEE.std_logic_1164.all;
USE IEEE.std_logic_signed.all;
use ieee.numeric_std.all;

Entity BiDi is
port (	clkpll :  in std_logic;
		set : in std_logic;
		rw : in std_logic;         -- '1' read '0' write
		lock_pll : in std_logic;
		bidi_IN : in std_logic_vector ( 7 downto 0);
		bidi_OUT : out std_logic_vector ( 7 downto 0);
		bidi_OE : out std_logic_vector ( 7 downto 0));
end BiDi;

Architecture rtl of BiDi is
signal cnt : std_logic_vector (31 downto 0)  := (others =>'0');

begin
-- simle design as in example for an bidirectional bus usage !
Bidi_control_process:process(clkpll)
						Begin	
							if clkpll'event and clkpll = '1' then
								if lock_pll = '1' then
									if rw= '0' then
										bidi_OE <= (others =>'0');
										if (set = '1' )  then	
												cnt(7 downto 0) <= bidi_IN;
												cnt(31 downto 8) <= (others=>'0');
										else
											cnt <= cnt +1;
										end if;
									elsif  rw= '1' then
										bidi_OE <= (others =>'1');	
												cnt <= cnt +1;
									end if;	
									bidi_OUT <= cnt(15 downto 8);
								end if;
							end if;
						end process;
						
end rtl;

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
