"""

Copyright (C) 2022 Efinix Inc. All rights reserved.

No portion of this code may be reused, modified or
distributed in any way without the expressed written
consent of Efinix Inc.

Created on Feb 17, 2025

@author: Dragon Lai


Last Modified on 13 Mar , 2025
Last Modified on 30 May, 2025

Fixed the invaild abort the case of mixed write mode in SDP and SP, -- 30 May , 2025
"""

import argparse
import os.path
import shutil
import fileinput
import re
import subprocess
import sys
import time
import os
import json
import math
from pathlib import Path
from typing import Dict, List
#from pyrsistent import pmap, freeze
#from pyrsistent.typing import PMap, PVector
from typing import Mapping, Sequence  
from enum import Enum

def parse_var(s):
        """
        Parse a key, value pair, separated by '='
        That's the reverse of ShellArgs.

        On the command line (argparse) a declaration will typically look like:
                foo=hello
        or
                foo="hello world"
        """
        items = s.split('=')
        key = items[0].strip() # we remove blanks around keys, as is logical
        if len(items) > 1:
                        # rejoin the rest:
                        value = '='.join(items[1:])
        return (key, value)

def parse_parameters(params: List[str]) -> Dict[str, str]:
        """
        Parse the key-value pairs and return A dictionary
        """
        d = {}
        for item in params:
                        key, value = parse_var(item)
                        d[key] = value
        return d

def remove_comment(InString):
    
    result = False 

    outString = InString

    #find comment sytnax '//'
    Index_start = InString.find('//')
  
  
    #find end of line \n after //  
    if (Index_start != -1  ):
        Index_end = InString.find('\n',Index_start)
        
        if (Index_end == -1):
            Index_end = len(InString)
       
        if (Index_start == 0 ):
            outString = InString[Index_end:] 
        else:
            outString = InString[:Index_start] + InString[Index_end:]
       
        result = True
        
    return result, outString
        
def remove_comments(InString):

    result = True
    TempString = InString
    
    while(result):
        result, OutString = remove_comment(TempString)
        TempString = OutString
        
    return OutString

class BRAM_TYPE(Enum):
    EFX_RAM_5K   = 0
    EFX_DPRAM_5K = 1
    EFX_RAM10    = 2
    EFX_DPRAM10  = 3

class COMPATIBLE(Enum):
    LARGE = 0
    SMALL = 1

class FEATURE(Enum):
    ADDRW = 0
    DATAW = 1
    WENW  = 2
    BRAM_TYPE = 3   
    COMPATIBLE= 4

#Address Width, Data Width , Number of wen, BRAM_TYPE, COMPATIBLE
EFX_RAM10_feature_table =[
[9 ,20,2,BRAM_TYPE.EFX_RAM10.value,COMPATIBLE.LARGE.value],    
[9 ,16,2,BRAM_TYPE.EFX_RAM10.value,COMPATIBLE.SMALL.value],
[10,10,1,BRAM_TYPE.EFX_RAM10.value,COMPATIBLE.LARGE.value],
[10,8 ,1,BRAM_TYPE.EFX_RAM10.value,COMPATIBLE.SMALL.value],
[11,5 ,1,BRAM_TYPE.EFX_RAM10.value,COMPATIBLE.LARGE.value],
[11,4 ,1,BRAM_TYPE.EFX_RAM10.value,COMPATIBLE.SMALL.value],
[12,2 ,1,BRAM_TYPE.EFX_RAM10.value,COMPATIBLE.SMALL.value],
[13,1 ,1,BRAM_TYPE.EFX_RAM10.value,COMPATIBLE.SMALL.value]
]

#Address Width, Data Width , Number of wen, BRAM_TYPE, COMPATIBLE
EFX_RAM10_MWM_feature_table =[   
[9 ,16,2,BRAM_TYPE.EFX_RAM10.value,COMPATIBLE.SMALL.value],
[10,8 ,1,BRAM_TYPE.EFX_RAM10.value,COMPATIBLE.SMALL.value],
[11,4 ,1,BRAM_TYPE.EFX_RAM10.value,COMPATIBLE.SMALL.value],
[12,2 ,1,BRAM_TYPE.EFX_RAM10.value,COMPATIBLE.SMALL.value],
[13,1 ,1,BRAM_TYPE.EFX_RAM10.value,COMPATIBLE.SMALL.value]
]

#Address Width, Data Width , Number of wen, BRAM_TYPE, COMPATIBLE
EFX_DPRAM10_feature_table =[
[10,10,1,BRAM_TYPE.EFX_DPRAM10.value,COMPATIBLE.LARGE.value],
[11,5 ,1,BRAM_TYPE.EFX_DPRAM10.value,COMPATIBLE.LARGE.value],
[10,8 ,1,BRAM_TYPE.EFX_DPRAM10.value,COMPATIBLE.SMALL.value],
[11,4 ,1,BRAM_TYPE.EFX_DPRAM10.value,COMPATIBLE.SMALL.value],
[12,2 ,1,BRAM_TYPE.EFX_DPRAM10.value,COMPATIBLE.SMALL.value],
[13,1 ,1,BRAM_TYPE.EFX_DPRAM10.value,COMPATIBLE.SMALL.value]
]

#Table for MixedDataWIdth
#Address Width, Data Width , Number of wen, BRAM_TYPE, COMPATIBLE
EFX_DPRAM10_MWM_feature_table =[
[10,8 ,1,BRAM_TYPE.EFX_DPRAM10.value,COMPATIBLE.SMALL.value],
[11,4 ,1,BRAM_TYPE.EFX_DPRAM10.value,COMPATIBLE.SMALL.value],
[12,2 ,1,BRAM_TYPE.EFX_DPRAM10.value,COMPATIBLE.SMALL.value],
[13,1 ,1,BRAM_TYPE.EFX_DPRAM10.value,COMPATIBLE.SMALL.value]
]

#Address Width, Data Width , Number of wen, BRAM_TYPE, COMPATIBLE
EFX_RAM_5K_feature_table =[
[8 ,20,2,BRAM_TYPE.EFX_RAM_5K.value,COMPATIBLE.LARGE.value],    
[9 ,10,1,BRAM_TYPE.EFX_RAM_5K.value,COMPATIBLE.LARGE.value],
[10,5 ,1,BRAM_TYPE.EFX_RAM_5K.value,COMPATIBLE.LARGE.value],
[8 ,16,2,BRAM_TYPE.EFX_RAM_5K.value,COMPATIBLE.SMALL.value],
[9 ,8 ,1,BRAM_TYPE.EFX_RAM_5K.value,COMPATIBLE.SMALL.value],
[10,4 ,1,BRAM_TYPE.EFX_RAM_5K.value,COMPATIBLE.SMALL.value],
[11,2 ,1,BRAM_TYPE.EFX_RAM_5K.value,COMPATIBLE.SMALL.value],
[12,1 ,1,BRAM_TYPE.EFX_RAM_5K.value,COMPATIBLE.SMALL.value]
]

#Address Width, Data Width , Number of wen, BRAM_TYPE, COMPATIBLE
EFX_RAM_5K_MWM_feature_table =[
[8 ,16,2,BRAM_TYPE.EFX_RAM_5K.value,COMPATIBLE.SMALL.value],
[9 ,8 ,1,BRAM_TYPE.EFX_RAM_5K.value,COMPATIBLE.SMALL.value],
[10,4 ,1,BRAM_TYPE.EFX_RAM_5K.value,COMPATIBLE.SMALL.value],
[11,2 ,1,BRAM_TYPE.EFX_RAM_5K.value,COMPATIBLE.SMALL.value],
[12,1 ,1,BRAM_TYPE.EFX_RAM_5K.value,COMPATIBLE.SMALL.value]
]

#Address Width, Data Width , Number of wen, BRAM_TYPE, COMPATIBLE
EFX_DPRAM_5K_feature_table =[
[9 ,10,1,BRAM_TYPE.EFX_DPRAM_5K.value,COMPATIBLE.LARGE.value],
[10,5 ,1,BRAM_TYPE.EFX_DPRAM_5K.value,COMPATIBLE.LARGE.value],
[9 ,8 ,1,BRAM_TYPE.EFX_DPRAM_5K.value,COMPATIBLE.SMALL.value],
[10,4 ,1,BRAM_TYPE.EFX_DPRAM_5K.value,COMPATIBLE.SMALL.value],
[11,2 ,1,BRAM_TYPE.EFX_DPRAM_5K.value,COMPATIBLE.SMALL.value],
[12,1 ,1,BRAM_TYPE.EFX_DPRAM_5K.value,COMPATIBLE.SMALL.value]
]


#Address Width, Data Width , Number of wen, BRAM_TYPE, COMPATIBLE
EFX_DPRAM_5K_MWM_feature_table =[
[9 ,8 ,1,BRAM_TYPE.EFX_DPRAM_5K.value,COMPATIBLE.SMALL.value],
[10,4 ,1,BRAM_TYPE.EFX_DPRAM_5K.value,COMPATIBLE.SMALL.value],
[11,2 ,1,BRAM_TYPE.EFX_DPRAM_5K.value,COMPATIBLE.SMALL.value],
[12,1 ,1,BRAM_TYPE.EFX_DPRAM_5K.value,COMPATIBLE.SMALL.value]
]

#Index of Mode Write (A), Index of Mode Read (B), Number of bram in column/row    
bram_decompose_table =[
[0 ,0, 5, 0, 0],
[0 ,0, 1, 0, 0],
]

#Index of Y of bram_decompose_table, 
#Index of X of bram_decompose_table, 
#Port A Data MSB, 
#Port A Data LSB,
#Port A Data Repart, 
#PORT A rdata MUX,
#PORT A WEN Selecion,
#PORT A BYTEEN, 
#Port B Data MSB, 
#PORT B Data LSB, 
#Port A Data Repart, 
#PORT B rdata MUX, 
#PORT B BYTEEN,
#PORT B WEN Selecion,
bram_mapping_table = list()

#Port Address Selection MSB,
#Port Address Selection LSB,
#DATA MSB,
#DATA LSB, 
rMux_mapping_table_A = list()

#Port Address Selection MSB,
#Port Address Selection LSB,
#WEN Range MSB,
#WEN Ragne LSB, 
wen_sel_mapping_table_A = list()

#Port Address Selection MSB,
#Port Address Selection LSB,
#DATA MSB,
#DATA LSB, 
rMux_mapping_table_B = list()

#Port Address Selection MSB,
#Port Address Selection LSB,
#WEN Range MSB,
#WEN Ragne LSB, 
wen_sel_mapping_table_B = list()



#Data Bit Index for Mixed Width Mode
data_mapping_table_A = list()

#Data Bit Index for Mixed Width Mode 
data_mapping_table_B = list()

#Address Bit Index for Mixed Width Mode 
address_mapping_table_A = list()

#Address Bit Index for Mixed Width Mode 
address_mapping_table_B = list()

#mem_table for include hex file
mem_table = list()
addr_table = list()

bram_decompose_mode = 1 # 1: LOOP ROW FIRST", 0: LOOP COLUMN FIRST" 
in_addr_width_a = 10
in_data_width_a = 10
in_addr_width_b = 10
in_data_width_b = 10

#byteen mapping 
# byteen index, Write Enable (WE) mode for primitive (e.g. for we[0] or we[1], 1 for wen 0, 2 for wen 1
bram_decompose_byteen_table = list()
byteen_width = 1
byteen_width_A = 1
byteen_width_B = 1

byteen_enable = 0
group_data_width = 8
group_data_width_A = 8
group_data_width_B = 8


group_columns = 1
FAMILY = 1
actual_size = 0
actual_size_A = 0
actual_size_B = 0

bram_we_mapping_table =[0,1,2,3]



	
#def generate_zero_memFile(loc_gen):
#	
#	memFile = open(loc_gen+"/init_hex.mem",'w')
#	for f in range (1<<in_addr_width_a):
		
	
def create_feature_file():
    f = open("bram_feature.vh", "w")
    y = 0
   
    line = ""   
    
    line += 'function integer bram_feature_table;\n'
    line += 'input integer index;//Mode type \n'
    line += 'input integer type; //Address_width, data_width, en_width, reserved \n'
    line += 'case (index)\n'
    f.write (line)
    for row in bram_feature_table:
       
        line = ""   
        x = 0
        
        line += str(y )
        line += ': bram_feature_table='
        
        for feature in row:
            line += '(type==' + str(x) + ')?' + str(feature) + ':'
            x = x + 1
        
        line += '0;\n'
        f.write (line)
        y = y +1
    

    line =  ""   
    line += "   endcase\n"
    line += "endfunction  \n"
    f.write (line)
    f.close()


def create_memory_initial_file(loc_gen):
    f = open(loc_gen+"/bram_ini.vh", "w")
   
    line  = '\n'
    line += 'function [255:0] bram_ini_table;\n'
    line += 'input integer index;//Mode type \n'
    line += 'input integer val_; //Port A index, Port B Index, Number of Items in Loop, Port A Start, Port B Start, reserved \n'
    line += 'case (index)\n'
    f.write (line)
    y = 0
    for row in bram_mapping_table:
       
        line = ""   
        x = 0
        
        line += '%4s: bram_ini_table=\n' %(y)
        
        
        stringline ="256'h"
        for hexChar in range(0,32):
           #stringline +=  '%02x' % (y)
           stringline +=  '%02x' % (0)
        
        
        for x in range(0,  40):
            #line += '(type==' + str(x) + ')?' + str(feature) + ':'
            line += '(val_==%2s)?' % (x)
            
            line += stringline
           #line += "256'h0000000000000000000000000000000000000000000000000000000000000000"
            
            line += ":\n"
            x = x + 1
        line += '0;\n'
        f.write (line)
        
        
        
        y = y +1
    
    
    line =  ""   
    line += "   endcase\n"
    line += "endfunction  \n"
    f.write (line)
    
    
    
    
    f.close()


    
def create_decompose_file(loc_gen):
    f = open(loc_gen+"/bram_decompose.vh", "w")
    y = 0
   
    line = ""   
    #line += 'localparam FAMILY       = '  + str(FAMILY) + '; //0:Trion,  1:Titanium\n'
    #line += 'localparam ADDR_WIDTH_A = '  + str(in_addr_width_a) + ';\n'
    #line += 'localparam DATA_WIDTH_A = '  + str(in_data_width_a) + ';\n'
    #line += 'localparam ADDR_WIDTH_B = '  + str(in_addr_width_b) + ';\n'
    #line += 'localparam DATA_WIDTH_B = '  + str(in_data_width_b) + ';\n'
    line += 'localparam TOTAL_SIZE_A = '  + str(actual_size_A) + ';\n'
    line += 'localparam TOTAL_SIZE_B = '  + str(actual_size_B) + ';\n'    
    #line += 'localparam BYTEEN_WIDTH = '  + str(byteen_width) + ';\n'
    #line += 'localparam BYTEEN_WIDTH_A = '  + str(byteen_width_A) + ';\n'
    #line += 'localparam BYTEEN_WIDTH_B = '  + str(byteen_width_B) + ';\n'
    #line += 'localparam GROUP_DATA_WIDTH = ' + str(group_data_width) + ';\n'
    #line += 'localparam GROUP_DATA_WIDTH_A = ' + str(group_data_width_A) + ';\n'
    #line += 'localparam GROUP_DATA_WIDTH_B = ' + str(group_data_width_B) + ';\n'

    line += 'localparam GROUP_COLUMNS       = ' + str(group_columns) + ';\n'
    #line += 'parameter DECOMPOSE_WRITE_MODE = "' + str(args.write_mode) + '";\n'
    
    line += 'localparam bram_table_size = '  + str(len(bram_decompose_table)) + ';\n'
    line += 'localparam bram_table_loop_mode = '  + str(bram_decompose_mode)  + ';\n'
    
    line += 'localparam bram_mapping_size = '  + str(len(bram_mapping_table))  + ';\n'
    line += 'localparam rMux_mapping_A_size = '  + str(len(rMux_mapping_table_A))  + ';\n'
    line += 'localparam rMux_mapping_B_size = '  + str(len(rMux_mapping_table_B))  + ';\n'
    line += 'localparam wen_sel_mapping_A_size = '  + str(len(wen_sel_mapping_table_A))  + ';\n'
    line += 'localparam wen_sel_mapping_B_size = '  + str(len(wen_sel_mapping_table_B))  + ';\n'
    
    
    line += 'localparam data_mapping_table_A_size = '  + str(len(data_mapping_table_A))  + ';\n'
    line += 'localparam data_mapping_table_B_size = '  + str(len(data_mapping_table_B))  + ';\n'
    line += 'localparam address_mapping_table_A_size = '  + str(len(address_mapping_table_A))  + ';\n'
    line += 'localparam address_mapping_table_B_size = '  + str(len(address_mapping_table_B))  + ';\n'
    f.write (line)
   
   
    y = 0
   
    line = '\n\n' 
    
    line += 'function integer bram_feature_table;\n'
    line += 'input integer index;//Mode type \n'
    line += 'input integer val_; //Address_width, data_width, en_width, reserved \n'
    line += 'case (index)\n'
    f.write (line)
    for row in bram_feature_table:
       
        line = ""   
        x = 0
        
        line += str(y )
        line += ': bram_feature_table='
        
        for feature in row:
            line += '(val_==' + str(x) + ')?' + str(feature) + ':'
            x = x + 1
        
        line += '0;\n'
        f.write (line)
        y = y +1
    

    line =  ""   
    line += "   endcase\n"
    line += "endfunction  \n"
    f.write (line)   
   
    
    line = '\n\n'
    y = 0
    line += 'function integer bram_decompose_table;\n'
    line += 'input integer index;//Mode type \n'
    line += 'input integer val_; //Port A index, Port B Index, Number of Items in Loop, Port A Start, Port B Start, reserved \n'
    line += 'case (index)\n'
    f.write (line)
    for row in bram_decompose_table:
       
        line = ""   
        x = 0
        
        line += '%4s: bram_decompose_table=' %(y)
        
        for feature in row:
            #line += '(type==' + str(x) + ')?' + str(feature) + ':'
            line += '(val_==%1s)?%4s:' % (x,feature)
            x = x + 1
        line += '0;\n'
        f.write (line)
        y = y +1
    
    
    line =  ""   
    line += "   endcase\n"
    line += "endfunction  \n"
    f.write (line)

    #line = ""   
    #line += '\n\n'
    #y = 0
    #line += 'function integer bram_decompose_byteen_table;\n'
    #line += 'input integer index;//Mode type \n'
    #line += 'input integer type; //Port A index, Port B Index, Number of Items in Loop, Port A Start, Port B Start, reserved \n'
    #line += 'case (index)\n'
    #f.write (line)
    #
    #
    #for row in bram_decompose_byteen_table:
    #   
    #    line = ""   
    #    x = 0
    #    
    #    line += str(y )
    #    line += ': bram_decompose_byteen_table='
    #    
    #    for feature in row:
    #        line += '(type==' + str(x) + ')?' + str(feature) + ':'
    #        x = x + 1
    #    line += '0;\n'
    #    f.write (line)
    #    y = y +1
    #
    #line =  ""   
    #line += "   endcase\n"
    #line += "endfunction  \n"    
    #f.write (line)
    
    
    line = ""   
    line += '\n\n'
    y = 0
    line += 'function integer bram_mapping_table;\n'
    line += 'input integer index;//Mode type \n'
    line += 'input integer val_;'
    line += '//            '
    line += 'Y,              '
    line += 'X,              '
    line += 'DataA [MSB],    '
    line += 'DataA [LSB],    '
    line += 'DataA Repeat,   '
    line += 'Read MuxA,      '    
    line += 'Wen0 SelA,      '    
    line += 'Wen1 SelA,      '    
    line += 'Byteen A,       '
    line += 'DataB [MSB],    '
    line += 'DataB [LSB],    '
    line += 'DataB Repeat,   '
    line += 'Read MuxB,      '    
    line += 'Wen0 SelB,      '    
    line += 'Wen1 SelB,      '    
    line += 'Byteen B,       '
    line += 'Addr Width A    '
    line += 'Data Width A    '
    line += 'Addr Width B    '
    line += 'Data Width B    '
    
    line += '\n'
    
    line += 'case (index)\n'
    f.write (line)
    
    
    for row in bram_mapping_table:
       
        line = ""   
        x = 0
        
        line += '%4s: bram_mapping_table=' % (y)
        
        for feature in row:
            line += '(val_==%2s)?%4s:' % (x,feature)
        #    line += '(val_==' + str(x) + ')?' + str(feature) + ':'
        
        
            x = x + 1
        line += '0;\n'
        f.write (line)
        y = y +1
    
    line =  ""   
    line += "   endcase\n"
    line += "endfunction  \n"    
    f.write (line)
    
    
    line = ""   
    line += '\n\n'
    y = 0
    line += 'function integer rMux_mapping_table_A;\n'
    line += 'input integer index;//Mode type \n'
    line += 'input integer val_;'
    line += '//            '
    line += 'PortA Addr MSB, '
    line += 'PortA Addr LSB, '
    line += 'DataA[MSB],     '
    line += 'DataA[LSB],     '
    line += 'MuxSelA[MSB],   '
    line += 'MuxSelA[LSB],   '
    line += 'Bypass,         '
    line += '\n'
    f.write (line)
    
    if len(rMux_mapping_table_A) != 0:
        line = 'case (index)\n'
        f.write (line)
        
        for row in rMux_mapping_table_A:
        
            line = ""   
            x = 0
            
            line += '%4s: rMux_mapping_table_A=' % (y)
            
            for feature in row:
                line += '(val_==%2s)?%4s:' % (x,feature)
            #    line += '(val_==' + str(x) + ')?' + str(feature) + ':'
            
            
                x = x + 1
            line += '0;\n'
            f.write (line)
            y = y +1
        
        line =  ""   
        line = "   endcase\n"
        f.write (line)
    else:
        line = "rMux_mapping_table_A = 0; \n"
        f.write (line)
        
    line = "endfunction  \n"    
    f.write (line)
    
 
    line = ""   
    line += '\n\n'
    y = 0
    line += 'function integer rMux_mapping_table_B;\n'
    line += 'input integer index;//Mode type \n'
    line += 'input integer val_;'
    line += '//            '
    line += 'PortB Addr MSB, '
    line += 'PortB Addr LSB, '
    line += 'DataB[MSB],     '
    line += 'DataB[LSB],     '
    line += 'MuxSelB[MSB],   '
    line += 'MuxSelB[LSB],   '
    line += 'Bypass,         '
    line += '\n'
    f.write (line)
    
    
    if len(rMux_mapping_table_B) != 0:
        line = 'case (index)\n'
        f.write (line)
        
        for row in rMux_mapping_table_B:
        
            line = ""   
            x = 0
            
            line += '%4s: rMux_mapping_table_B=' % (y)
            
            for feature in row:
                line += '(val_==%2s)?%4s:' % (x,feature)
            #    line += '(val_==' + str(x) + ')?' + str(feature) + ':'
            
            
                x = x + 1
            line += '0;\n'
            f.write (line)
            y = y +1
        
        line = ""   
        line = "   endcase\n"
        f.write (line)
    else:
        line = "rMux_mapping_table_B = 0; \n"
        f.write (line)
    
    line = "endfunction  \n"    
    f.write (line)
    
     
    line = ""   
    line += '\n\n'
    y = 0
    line += 'function integer wen_sel_mapping_table_A;\n'
    line += 'input integer index;//Mode type \n'
    line += 'input integer val_;'
    line += '//              '
    line += 'PortA Addr MSB,   '
    line += 'PortA Addr LSB,   '
    line += 'WenSelA[MSB],     '
    line += 'WenSelA[LSB],     '
    line += 'Bypass,         '
    line += '\n'
    f.write (line)
    
    
    if len(wen_sel_mapping_table_A) != 0:
        line = 'case (index)\n'
        f.write (line)
        for row in wen_sel_mapping_table_A:
        
            line = ""   
            x = 0
            
            line += '%4s: wen_sel_mapping_table_A=' % (y)
            
            for feature in row:
                line += '(val_==%2s)?%4s:' % (x,feature)
            #    line += '(val_==' + str(x) + ')?' + str(feature) + ':'
            
            
                x = x + 1
            line += '0;\n'
            f.write (line)
            y = y +1
        
        line =  ""   
        line = "   endcase\n"
        f.write (line)
    else:
        line = "wen_sel_mapping_table_A = 0; \n"
        f.write (line)

    
    line = "endfunction  \n"    
    f.write (line)
    
    line = ""   
    line += '\n\n'
    y = 0
    line += 'function integer wen_sel_mapping_table_B;\n'
    line += 'input integer index;//Mode type \n'
    line += 'input integer val_;'
    line += '//            '
    line += 'PortB Addr MSB, '
    line += 'PortB Addr LSB, '
    line += 'WenSelB[MSB],   '
    line += 'WenSelB[LSB],   '
    line += 'Bypass,         '
    line += '\n'
    f.write (line)
    
    if len(wen_sel_mapping_table_B) !=0:
    
        line = 'case (index)\n'
        f.write (line)
        for row in wen_sel_mapping_table_B:
        
            line = ""   
            x = 0
            
            line += '%4s: wen_sel_mapping_table_B=' % (y)
            
            for feature in row:
                line += '(val_==%2s)?%4s:' % (x,feature)
            #    line += '(val_==' + str(x) + ')?' + str(feature) + ':'
            
            
                x = x + 1
            line += '0;\n'
            f.write (line)
            y = y +1
        
        line =  ""   
        line = "   endcase\n"
        f.write (line)
    else:
        line = "wen_sel_mapping_table_B = 0; \n"
        f.write (line)
    
    
    line = "endfunction  \n"    
    f.write (line)
    
    
    
    line = ""   
    line += '\n\n'
    y = 0
    line += 'function integer data_mapping_table_A;\n'
    line += 'input integer index;// \n'
    f.write (line)
    
    if len(data_mapping_table_A) !=0:
    
        line = 'case (index)\n'
        f.write (line)
        for row in data_mapping_table_A:
        
            line = ""   
            
            line += '%4s: data_mapping_table_A= %4s;\n' % (y,row)

            f.write (line)
            y = y +1
        
        line =  ""   
        line = "   endcase\n"
        f.write (line)
    else:
        line = "data_mapping_table_A = 0; \n"
        f.write (line)
    
    
    line = "endfunction  \n"    
    f.write (line)
    
    
    line = ""   
    line += '\n\n'
    y = 0
    line += 'function integer data_mapping_table_B;\n'
    line += 'input integer index;// \n'
    f.write (line)
    
    if len(data_mapping_table_B) !=0:
    
        line = 'case (index)\n'
        f.write (line)
        for row in data_mapping_table_B:
        
            line = ""   
      
            line += '%4s: data_mapping_table_B= %4s;\n' % (y,row)
            
            f.write (line)
            y = y +1
        
        line =  ""   
        line = "   endcase\n"
        f.write (line)
    else:
        line = "data_mapping_table_B = 0; \n"
        f.write (line)
    
    
    line = "endfunction  \n"    
    f.write (line)
    
    
    
    line = ""   
    line += '\n\n'
    y = 0
    line += 'function integer address_mapping_table_A;\n'
    line += 'input integer index;// \n'
    f.write (line)
    
    if len(address_mapping_table_A) !=0:
    
        line = 'case (index)\n'
        f.write (line)
        for row in address_mapping_table_A:
        
            line = ""   
            
            line += '%4s: address_mapping_table_A= %4s;\n' % (y,row)

            f.write (line)
            y = y +1
        
        line =  ""   
        line = "   endcase\n"
        f.write (line)
    else:
        line = "address_mapping_table_A = 0; \n"
        f.write (line)
    
    
    line = "endfunction  \n"    
    f.write (line)
    
    
    line = ""   
    line += '\n\n'
    y = 0
    line += 'function integer address_mapping_table_B;\n'
    line += 'input integer index;// \n'
    f.write (line)
    
    if len(address_mapping_table_B) !=0:
    
        line = 'case (index)\n'
        f.write (line)
        for row in address_mapping_table_B:
        
            line = ""   
            
            line += '%4s: address_mapping_table_B= %4s;\n' % (y,row)
          
            f.write (line)
            y = y +1
        
        line =  ""   
        line = "   endcase\n"
        f.write (line)
    else:
        line = "address_mapping_table_B = 0; \n"
        f.write (line)
    
    
    line = "endfunction  \n"    
    f.write (line)
    
    
    
    f.close()

def create_decompose_column__(address_width, data_width, size, decompose_mode):
    
    #flag_find = true;
    index = 0 
    
    Find_success = False
    
    Max_addrw  = 0
    Max_dataw  = 0
    min_dataw  = 0
    rows       = 0
    
    #result = "Input Address:"+ str(address_width) +" data:" + str(data_width)
    #print (result)
    
    #Find Max Address Width 
    for feature in bram_feature_table:
        if feature[FEATURE.COMPATIBLE.value] == COMPATIBLE.LARGE.value or decompose_mode == 'speed':
            if Max_addrw < feature[FEATURE.ADDRW.value]:
                Max_addrw = feature[FEATURE.ADDRW.value]
            if address_width <= Max_addrw:
                break
                
   # result = "Max Address:"+ str(Max_addrw)
   # print (result)
             
    
   #Find Max Data Width 
   # for feature in bram_feature_table:
   #     if feature[FEATURE.COMPATIBLE.value] == COMPATIBLE.LARGE.value:
   #         if Max_dataw < feature[FEATURE.DATAW.value]:
   #             Max_dataw = feature[FEATURE.DATAW.value]
 
   # result = "Max Data:"+ str(Max_dataw)
   # print (result)
  
 
    #Find Max Data Width
    index = 0
    for feature in bram_feature_table:
    
        min_dataw = feature[FEATURE.DATAW.value]
        
        if feature[FEATURE.ADDRW.value] >= address_width:
            break
        
        if feature[FEATURE.ADDRW.value] >= Max_addrw:
            
        #    result = "Min Data:"+ str(min_dataw)
        #    print (result)
        
            if min_dataw <= data_width:
                break   
            
            
            
            min_dataw =  feature[FEATURE.DATAW.value]
                
        index += 1
            
  #  result = "Min Data:"+ str(min_dataw)
  #  print (result)
  #  result = "Index:"+ str(index)
  #  print (result)
    
    primitive_dataw = bram_feature_table[index][FEATURE.DATAW.value]
    primitive_addrw = bram_feature_table[index][FEATURE.ADDRW.value]
    
    
    total_address = pow(2,address_width)  
    total_primitive_address = pow(2,primitive_addrw)
    
    if size != 0:
        if size <= total_address:
            total_address = size
        
    rows = int(total_address/total_primitive_address)
        
    if total_address % total_primitive_address :
        rows += 1

    
    
    return index, rows, primitive_addrw, primitive_dataw

def create_decompose_column(address_width, data_width, size):
    
    #flag_find = true;
    index = 0 
    
    Find_success = False
    
    Max_addrw  = 0
    Max_dataw  = 0
    min_dataw  = 0
    rows       = 0
    
    #result = "Input Address:"+ str(address_width) +" data:" + str(data_width)
    #print (result)
    
    #Find Max Address Width 
    for feature in bram_feature_table:
        if feature[FEATURE.COMPATIBLE.value] == COMPATIBLE.LARGE.value:
            if Max_addrw < feature[FEATURE.ADDRW.value]:
                Max_addrw = feature[FEATURE.ADDRW.value]
            if address_width <= Max_addrw:
                break
                
   # result = "Max Address:"+ str(Max_addrw)
   # print (result)
             
    
   #Find Max Data Width 
   # for feature in bram_feature_table:
   #     if feature[FEATURE.COMPATIBLE.value] == COMPATIBLE.LARGE.value:
   #         if Max_dataw < feature[FEATURE.DATAW.value]:
   #             Max_dataw = feature[FEATURE.DATAW.value]
 
   # result = "Max Data:"+ str(Max_dataw)
   # print (result)
  
 
    #Find Max Data Width
    index = 0
    for feature in bram_feature_table:
    
        min_dataw = feature[FEATURE.DATAW.value]
        
        if feature[FEATURE.ADDRW.value] >= address_width:
            break
        
        if feature[FEATURE.ADDRW.value] >= Max_addrw:
            
        #    result = "Min Data:"+ str(min_dataw)
        #    print (result)
        
            if min_dataw <= data_width:
                break   
            
            
            
            min_dataw =  feature[FEATURE.DATAW.value]
                
        index += 1
            
  #  result = "Min Data:"+ str(min_dataw)
  #  print (result)
  #  result = "Index:"+ str(index)
  #  print (result)
    
    primitive_dataw = bram_feature_table[index][FEATURE.DATAW.value]
    primitive_addrw = bram_feature_table[index][FEATURE.ADDRW.value]
    
    
    total_address = pow(2,address_width)  
    total_primitive_address = pow(2,primitive_addrw)
    
    if size != 0:
        if size <= total_address:
            total_address = size
        
    rows = int(total_address/total_primitive_address)
        
    if total_address % total_primitive_address :
        rows += 1

    
    
    return index, rows, primitive_addrw, primitive_dataw



def create_decompose_row(data_width, size, group_data_width):
    
    #flag_find = true;
    index = 0 
    
    Find_success = False
    
    Max_addrw  = 0
    Max_dataw  = 0
    min_dataw  = 0
    columns    = 0
    
    #result = "Input Address:"+ str(address_width) +" data:" + str(data_width)
    #print (result)
    
    address_width = math.log2(size)
    
    #Find Max Address Width 
    for feature in bram_feature_table:
        if Max_addrw < feature[FEATURE.ADDRW.value]:
            Max_addrw = feature[FEATURE.ADDRW.value]
        if address_width <= Max_addrw:
            break
                
   # result = "Max Address:"+ str(Max_addrw)
   # print (result)
             
    
   #Find Max Data Width 
   # for feature in bram_feature_table:
   #     if feature[FEATURE.COMPATIBLE.value] == COMPATIBLE.LARGE.value:
   #         if Max_dataw < feature[FEATURE.DATAW.value]:
   #             Max_dataw = feature[FEATURE.DATAW.value]
 
   # result = "Max Data:"+ str(Max_dataw)
   # print (result)
  
 
    #Find Max Data Width
    index = 0
    for feature in bram_feature_table:
    
        min_dataw = feature[FEATURE.DATAW.value]
        
        if feature[FEATURE.ADDRW.value] >= address_width:
            break
        
        if feature[FEATURE.ADDRW.value] >= Max_addrw:
            
        #    result = "Min Data:"+ str(min_dataw)
        #    print (result)
        
            if min_dataw <= data_width:
                break   
           
        #    min_dataw =  feature[FEATURE.DATAW.value]
                
        index += 1
            
  #  result = "Min Data:"+ str(min_dataw)
  #  print (result)
  #  result = "Index:"+ str(index)
  #  print (result)
    
    primitive_dataw = bram_feature_table[index][FEATURE.DATAW.value]
    primitive_addrw = bram_feature_table[index][FEATURE.ADDRW.value]
    
    if group_data_width == 0:
        columns = int(data_width/primitive_dataw)
        
        if data_width % primitive_dataw:
            columns += 1
    else: 
        sub_columns  = int(group_data_width/primitive_dataw)
          
        if group_data_width % primitive_dataw:
            sub_columns += 1 
            
        columns = (int(data_width/group_data_width)) * sub_columns
        
        sub_columns_remain = (data_width % group_data_width)
        
        columns += int(sub_columns_remain/primitive_dataw)
       
        if sub_columns_remain % primitive_dataw:
            columns += 1
    
    return index, columns, primitive_addrw, primitive_dataw



def create_decompose_table(address_width, data_width, size, decompose_mode):
    
    total_width = 0
    total_bram  = 0
    column      = 0
    while True:
    
        index, rows, column_addrw, column_dataw = create_decompose_column(address_width, (data_width-total_width), size, decompose_mode)
    
        total_width += column_dataw
        total_bram  += rows
        
        result = "Column " + str(column) + ") Primitive index: " + str(index) + " addr"+ str(column_addrw) + " data: " + str(column_dataw) + " number of rows:" +str(rows)
        print (result)
        
        if total_width >= data_width:
            break
            
        column += 1
    
    result = "Total Bram used in:" + str(total_bram)
    print (result)
    
    
def create_decompose_table_scan_col(address_width_A, data_width_A, size, group_data_width, address_width_B, data_width_B):
    
   
    total_width = 0
    total_bram  = 0
    column      = 0
    global bram_decompose_mode
    global in_addr_width_a
    global in_data_width_a
    global in_addr_width_b
    global in_data_width_b 
    global byteen_width
    global byteen_enable
    global group_columns
    global bram_decompose_table      
    global bram_decompose_byteen_table
    global bram_mapping_table
    global rMux_mapping_table_A
    global rMux_mapping_table_B
    global wen_sel_mapping_table_A
    global wen_sel_mapping_table_B
    global actual_size_A
    global actual_size_B
   
   
    bram_decompose_byteen_table = list()
    
    total_address = pow(2,address_width_A)  
   
    if size != 0:
        if size <= total_address:
            total_address = size
            
    actual_size_A = total_address 
    actual_size_B = total_address 
    
    
    
    group_data_count = 0;
    group_data_ptr   = 0;
    for x in range(0, data_width_A):
        bram_data_row = [group_data_ptr,1]
        bram_decompose_byteen_table.append(bram_data_row)
        
        group_data_count += 1
        if(group_data_count == group_data_width):
            group_data_ptr += 1
            group_data_count = 0  
 
    if group_data_width != 0:
        byteen_enable = 1
        byteen_width =  group_data_ptr
        if ( ( data_width_A % group_data_width ) != 0):
            byteen_width += 1
        result = "byteen width: " + str(byteen_width) + " Group Data Width: " + str(group_data_width)
        print (result)
   
    bram_decompose_mode = 0 # 1: LOOP ROW FIRST", 0: LOOP COLUMN FIRST" 
    
    in_addr_width_a = address_width_A
    in_data_width_a = data_width_A
    in_addr_width_b = address_width_A
    in_data_width_b = data_width_A    
    
    byteen_index = 0;
    wen_index = 0;
    
    bram_decompose_table = list()
    rMux_mapping_table_A = list()
    rMux_mapping_table_B = list()
    wen_sel_mapping_table_A = list()
    wen_sel_mapping_table_B = list()    
        
    wenSelIndex = 0    
    

    data_start = 0    
 
    Flg_row_detected = False
 
    while True:
        
        if group_data_width == 0 :
    
            index, rows, column_addrw, column_dataw = create_decompose_column(address_width_A, (data_width_A-total_width), size)
        
            bram_column = [index,index, rows, 0,0] 
            bram_decompose_table.append(bram_column)
            
            data_start = total_width
            data_end = data_start + column_dataw
            if data_end > data_width_A:
                data_end = data_width_A
            data_end -= 1
            
            
            nBits = data_end - data_start +1 
            interval = 0
            Repeat = 0
            
            wenSel_Start = wenSelIndex
            
            
            for x in range(0,  rows):
                bram_map = [x,column,data_end,data_start,Repeat,x,wenSelIndex,wenSelIndex,byteen_index,data_end,data_start,Repeat,x,wenSelIndex,wenSelIndex,byteen_index,  column_addrw, column_dataw,  column_addrw, column_dataw]
                    
                bram_mapping_table.append(bram_map)
                wenSelIndex += 1
            
            Bypassed = 0
            if( address_width_A > column_addrw  ) | (Flg_row_detected == True) :
                Flg_row_detected = True 
                if (address_width_A <= column_addrw):
                    Bypassed = 1
            
                rMuxA = [address_width_A-1,column_addrw, data_end,data_start, rows-1, 0 , Bypassed]
                rMux_mapping_table_A.append(rMuxA)
                
                rMuxB = [address_width_A-1,column_addrw, data_end,data_start, rows-1, 0 , Bypassed]
                rMux_mapping_table_B.append(rMuxB)
                
                WenSelA = [address_width_A-1,column_addrw, wenSelIndex-1,wenSel_Start , Bypassed]
                wen_sel_mapping_table_A.append(WenSelA)
                
                WenSelB = [address_width_A-1,column_addrw, wenSelIndex-1,wenSel_Start , Bypassed]
                wen_sel_mapping_table_B.append(WenSelB)
            
            
            
            total_width += column_dataw
            total_bram  += rows
            result = "Column " + str(column) + ") Primitive index: " + str(index) + " addr"+ str(column_addrw) + " data: " + str(column_dataw) + " number of rows:" +str(rows)
            print (result)
            
            if total_width >= data_width_A:
                break
                
            column += 1    
        else :
            
            total_group_data_width = 0;
                              
           
            while True:
            
                index, rows, column_addrw, column_dataw = create_decompose_column(address_width_A, (group_data_width-total_group_data_width), size)
            
                bram_column = [index,index, rows, 0,0] 
                bram_decompose_table.append(bram_column)
                
                data_start = total_width + total_group_data_width
                data_end = data_start + column_dataw
                
                if (total_group_data_width+column_dataw) > group_data_width:
                    data_end =  total_width + group_data_width
                
                if data_end > data_width_A:
                    data_end = data_width_A
                data_end -= 1
                
                nBits = data_end - data_start +1 
                interval = 0
                Repeat = 0
                
                wenSel_Start = wenSelIndex
                
                for x in range(0,  rows):
                    bram_map = [x,column,data_end,data_start,Repeat,x,wenSelIndex,wenSelIndex,byteen_index,data_end,data_start,Repeat,x,wenSelIndex,wenSelIndex,byteen_index,   column_addrw, column_dataw,  column_addrw, column_dataw]
                    
                    bram_mapping_table.append(bram_map)
                    wenSelIndex += 1
                    
                Bypassed = 0
                if( address_width_A > column_addrw  ) | (Flg_row_detected == True) :
                    Flg_row_detected = True 
                    if (address_width_A <= column_addrw):
                        Bypassed = 1
                        
                    rMuxA = [address_width_A-1,column_addrw, data_end,data_start, rows-1, 0 , Bypassed]
                    rMux_mapping_table_A.append(rMuxA)
                    
                    rMuxB = [address_width_A-1,column_addrw, data_end,data_start, rows-1, 0 , Bypassed]
                    rMux_mapping_table_B.append(rMuxB)
                    
                    WenSelA = [address_width_A-1,column_addrw, wenSelIndex-1,wenSel_Start , Bypassed]
                    wen_sel_mapping_table_A.append(WenSelA)
                    
                    WenSelB = [address_width_A-1,column_addrw, wenSelIndex-1,wenSel_Start , Bypassed]
                    wen_sel_mapping_table_B.append(WenSelB)
               
                result = "Column " + str(column) + ") Primitive index: " + str(index) + " addr"+ str(column_addrw) + " data: " + str(column_dataw) + " number of rows:" +str(rows)
                print (result)
                             
                                           
                column += 1 
                
                total_group_data_width += column_dataw
                total_bram  += rows
                if total_group_data_width >= group_data_width:
                    byteen_index += 1
                    total_group_data_width = group_data_width
                    break
               
                if (total_width + total_group_data_width ) >= data_width_A:
                    byteen_index += 1
                    break
                    
                  
                    
            total_width += total_group_data_width         
            
            if total_width >= data_width_A:
                break
            
        
        
        
    
    result = "Total BRam used :" + str(total_bram)
    print (result)    
    

def check_row_mwm(address_width_A, data_width_A, size_A, group_data_width, address_width_B, data_width_B):
    
    if(data_width_B != 0) | (address_width_B!=0):
        if (data_width_B != 0):    
        
            temp_address_width_B = int(0)
            
            if (data_width_A > data_width_B):
                if (data_width_A % data_width_B) != 0:
                    #print("In Mixed Width Mode, Don't support remainder that Data Width A divided by Data Width of B.")
                    print("In Mixed Width Mode, please apply the equation : data_width_A = data_width_b x (2 power of n). ")             
                    return False, 0, 0, 0, 0, 0, 0, 0 
                    
                temp_data_width_B = data_width_A    
                while (True ):
                    temp_data_width_B /= 2
                    if (temp_data_width_B <=  data_width_B):
                        break; 
                    
                if  temp_data_width_B !=  data_width_B:
                    print("In Mixed Width Mode, please apply the equation : data_width_A = data_width_b x (2 power of n). ")
                    return False, 0, 0, 0, 0, 0, 0, 0 
                    
                extend_addr =  (data_width_A / data_width_B) 
                
                temp_address_width_B = address_width_A + math.log2(extend_addr)
            
            elif (data_width_B > data_width_A):
                if (data_width_B % data_width_A) != 0:
                    #print("In Mixed Width Mode, Don't support remainder that Data Width B divided by Data Width of A.")
                    print("In Mixed Width Mode, please apply the equation : data_width_B = data_width_A x (2 power of n). ")
                    return False, 0, 0, 0, 0, 0, 0, 0 
                
                print(data_width_B, data_width_A)                
                temp_data_width_A = data_width_B    
                while (True ):
                    temp_data_width_A /= 2
                    if (temp_data_width_A <=  data_width_A):
                        break; 
                    
                if  temp_data_width_A !=  data_width_A:
                    print(temp_data_width_A, data_width_A)
                    print("In Mixed Width Mode, please apply the equation : data_width_B = data_width_A x (2 power of n). ")
                    return False, 0, 0, 0, 0, 0, 0, 0 
                    
                extend_addr =  (data_width_B / data_width_A) 
                
                temp_address_width_B = address_width_A - math.log2(extend_addr)    
            else: 
                temp_address_width_B = address_width_A
                
            if address_width_B != 0:
                if address_width_B < temp_address_width_B:
                   print("In Mixed Width Mode, the address_width_B is lesser than expected address_width. ")
                   return False, 0, 0, 0, 0, 0, 0, 0
            else:
                address_width_B = temp_address_width_B
 
        if (address_width_B != 0): 
            if address_width_B > address_width_A:
                if (data_width_B == 0):
                    addr_diff = address_width_B - address_width_A
                    temp_data_width_B = data_width_A
                    
                    for i in range (0,addr_diff):
                        temp_data_width_B /= 2
                    
                    if temp_data_width_B <= 0:
                       print("In Mixed Width Mode, please apply the equation : data_width_A = data_width_b X ( ( address_width_B - address_width_A  ) power of 2). ")
                       return False, 0, 0, 0, 0, 0, 0, 0 
                       
                    data_width_B = temp_data_width_B
                    
            if address_width_A > address_width_B:
                if (data_width_B == 0):
                    addr_diff = address_width_A - address_width_B
                    temp_data_width_B = data_width_A
                    
                    for i in range (0,addr_diff):
                        temp_data_width_B *= 2
                       
                    data_width_B = temp_data_width_B        
    
        size_B = 0
        if size_A != 0:
            if data_width_A !=  data_width_B:       
                #find Max Bram Address of Port A
                max_primitive_addressA = 0
                for row in bram_decompose_table:
                    primitive_data = bram_feature_table[row[0]][FEATURE.DATAW.value]
                    primitive_addr = bram_feature_table[row[0]][FEATURE.ADDRW.value]
                    if max_primitive_addressA < primitive_addr:
                        max_primitive_addressA = primitive_addr
            
                if (size_A % pow(2, max_primitive_addressA )) != 0: 
                    Rows = (size_A / pow(2, max_primitive_addressA ))+1
                    size_A = Rows * pow(2, max_primitive_addressA )        
            
        
            if data_width_A < data_width_B:
                size_B = size_A / ( data_width_B/data_width_A)    
            elif data_width_A > data_width_B:
                size_B = size_A * ( data_width_A/data_width_B)
            else:
                size_B = size_A
        
        
    return True, int(address_width_A), int (data_width_A), int(size_A), int(group_data_width), int(address_width_B), int(data_width_B), int(size_B) 
    
    

        
#For Current Data Width < Target Data Width    
def find_mixed_width_row(index, targetRatio ):
    
    primitive_dataw = bram_feature_table[index][FEATURE.DATAW.value]
    compatible =  bram_feature_table[index][FEATURE.COMPATIBLE.value]
    TargetDataWidth = int(primitive_dataw*targetRatio)
    
    #print (TargetDataWidth, primitive_dataw, targetRatio)
    
    MaxDataWidth = primitive_dataw
    
    Index = 0
    MaxIndex = Index
    TargetIndex = Index
    
    result = False
    for feature in bram_feature_table:
        if feature[FEATURE.COMPATIBLE.value]  == compatible:
            if MaxDataWidth <= feature[FEATURE.DATAW.value]:
                MaxDataWidth = feature[FEATURE.DATAW.value]
                MaxIndex = Index
            if TargetDataWidth == feature[FEATURE.DATAW.value]:
                result = True
                TargetIndex = Index
                break
                
        Index += 1
    
    if result == False : 
        TargetIndex = MaxIndex
        TargetDataWidth = MaxDataWidth
    
    TargetAddressWidth = bram_feature_table[TargetIndex][FEATURE.ADDRW.value]
    
    return result, TargetIndex, TargetDataWidth, TargetAddressWidth
#Dragon 20250212
#For Current Data Width > Target Data Width    
def find_mixed_width_row_scaleDown(index, targetRatio ):
    
    primitive_dataw = bram_feature_table[index][FEATURE.DATAW.value]
    compatible =  bram_feature_table[index][FEATURE.COMPATIBLE.value]
    TargetDataWidth = int(primitive_dataw/targetRatio)
    
    #print (TargetDataWidth, primitive_dataw, targetRatio)
    
    MinDataWidth = primitive_dataw
    
    Index = 0
    MinIndex = Index
    TargetIndex = Index
    
    result = False
    for feature in bram_feature_table:
        if feature[FEATURE.COMPATIBLE.value]  == compatible:
            if MinDataWidth >= feature[FEATURE.DATAW.value]:
                MinDataWidth = feature[FEATURE.DATAW.value]
                MinIndex = Index
            if TargetDataWidth == feature[FEATURE.DATAW.value]:
                result = True
                TargetIndex = Index
                break
                
        Index += 1
    
    if result == False : 
        TargetIndex = MinIndex
        TargetDataWidth = MinDataWidth
    
    TargetAddressWidth = bram_feature_table[TargetIndex][FEATURE.ADDRW.value]
    
    return result, TargetIndex, TargetDataWidth, TargetAddressWidth

    

def create_decompose_table_scan_row(scan_index, address_width_A, data_width_A, size_A, group_data_width_A,  address_width_B, data_width_B, size_B, group_data_width_B): 
   
    total_width = 0
    total_bram  = 0
    row      = 0
    mixed_row =0
    global bram_decompose_mode
    global in_addr_width_a
    global in_data_width_a
    global in_addr_width_b
    global in_data_width_b   
    global byteen_width
    global byteen_width_A
    global byteen_width_B
    
    global byteen_enable
    global group_columns
    global bram_decompose_table  
    global bram_decompose_byteen_table
    global bram_mapping_table
    global rMux_mapping_table_A
    global rMux_mapping_table_B
    global wen_sel_mapping_table_A
    global wen_sel_mapping_table_B
    global actual_size_A
    global actual_size_B
    
   
    
    actual_size_A = pow(2,address_width_A)  
    if size_A != 0:
        if size_A <= actual_size_A:
            actual_size_A = size_A

    actual_size_B = pow(2,address_width_B)  
    if size_B != 0:
        if size_B <= actual_size_B:
            actual_size_B = size_B
    
    
    if data_width_A <= data_width_B:
        address_width    = address_width_A 
        data_width       = data_width_A 
        size             = size_A 
        group_data_width = group_data_width_A
        if data_width_A == data_width_B:
            if group_data_width_A > group_data_width_B:
                group_data_width = group_data_width_B
            
    else:
        address_width    = address_width_B 
        data_width       = data_width_B 
        size             = size_B 
        group_data_width = group_data_width_B
    
 
    
    mixed_total_width    = 0
    extend_row_index     = 0
    extend_data_width    = 0
    
    max_extend_row_index  = 0
    
    
       
    bram_decompose_byteen_table = list()
    group_columns = 1
    group_data_count = 0;
    group_data_ptr   = 0;
    for x in range(0, data_width):
        bram_data_row = [group_data_ptr,1]
        bram_decompose_byteen_table.append(bram_data_row)
        
        group_data_count += 1
        if(group_data_count == group_data_width):
            group_data_ptr += 1
            group_data_count = 0      
    
    if group_data_width != 0:
        byteen_width =  group_data_ptr
        byteen_enable = 1
        if ( ( data_width % group_data_width ) != 0):
            byteen_width += 1
        result = "byteen width: " + str(byteen_width) + " Group Data Width: " + str(group_data_width)
        byteen_width_A = byteen_width
        byteen_width_B = byteen_width
        print (result)

    
    bram_decompose_mode = 1 # 1: LOOP ROW FIRST", 0: LOOP COLUMN FIRST"
   
    
    total_address = pow(2,address_width)  
   
    if size != 0:
        if size <= total_address:
            total_address = size
    
    in_addr_width_a = address_width_A
    in_data_width_a = data_width_A
    in_addr_width_b = address_width_B
    in_data_width_b = data_width_B    
   
    bram_decompose_table = list()
    bram_mapping_table   = list()
    
    bram_mapping_table_index = 0
    
    if group_data_width == 0:
        group_data_width = data_width
        
    
    Max_addrw  = 0
    Min_addrw  = 1000
    mwm_ratio  = 1
       
    #Find Max Address Width 
    for feature in bram_feature_table:
        if Max_addrw < feature[FEATURE.ADDRW.value]:
            Max_addrw = feature[FEATURE.ADDRW.value]
    #Find Min Address Width 
    for feature in bram_feature_table:
        if Min_addrw > feature[FEATURE.ADDRW.value]:
            Min_addrw = feature[FEATURE.ADDRW.value]
   
   
   
    #pre check the address of decompose_row
    temp_address_width_A = address_width_A
    temp_address_width_B = address_width_B
    
    temp_total_address = total_address
    
    
    
    if(data_width_A != data_width_B): 
        if(data_width_A > data_width_B):
            mwm_ratio = data_width_A/data_width_B
            extend_mwm_addr = int(math.log2(mwm_ratio));
            temp_address_width_B = Min_addrw + extend_mwm_addr
            temp_address_width_A = Min_addrw  
            
            temp_total_address =   pow(2, Min_addrw + extend_mwm_addr) 
        
        if(data_width_A < data_width_B):
            mwm_ratio = data_width_B/data_width_A
            extend_mwm_addr = int(math.log2(mwm_ratio)); 
            temp_address_width_A = Min_addrw + extend_mwm_addr
            temp_address_width_B = Min_addrw  
                  
            temp_total_address =   pow(2, Min_addrw + extend_mwm_addr) 
    
    
    if(temp_address_width_A > address_width_A ):
        address_width_A = temp_address_width_A
    
    if(temp_address_width_B > address_width_B ):
        address_width_B = temp_address_width_B    
 
    if (temp_total_address > total_address):
        total_address = temp_total_address     

    
    print (temp_total_address, address_width_A, address_width_B)
            
    while True:

        index, columns, column_addrw, column_dataw = create_decompose_row(data_width, total_address,group_data_width)
              
#        if(data_width_A != data_width_B):
#            
#            temp_total_address = total_address
#           
#      
#            limit = 0
#            while(True):
#            
#                print (limit, Max_addrw,Min_addrw, column_addrw, temp_total_address, address_width_B, address_width_A)
#                
#                if(column_addrw == Max_addrw):
#                    break
#                    
#                if(data_width_A > data_width_B):
#                    mwm_ratio = data_width_A/data_width_B
#                    extend_mwm_addr = int(math.log2(mwm_ratio)); 
#
#                    print ("A>B",column_addrw, (address_width_B+extend_mwm_addr), address_width_A, address_width_B, mwm_ratio, extend_mwm_addr, "Data",column_dataw,"Group", group_data_width )
#                    if (column_addrw < (Min_addrw+extend_mwm_addr)) :
#                    	
#                        temp_total_address *= 2
#                        index, columns, column_addrw, column_dataw = create_decompose_row(data_width, temp_total_address,group_data_width)
#                    else: 
#                        break
#                        
#                if (data_width_A < data_width_B):        
#                    mwm_ratio = data_width_B/data_width_A
#                    extend_mwm_addr = int(math.log2(mwm_ratio)); 
#
#                    print ("B>A",column_addrw, (address_width_A+extend_mwm_addr), address_width_A, address_width_B, mwm_ratio, extend_mwm_addr, "Group", group_data_width )
#                    if(column_addrw < (Min_addrw+extend_mwm_addr)) :    
#                        temp_total_address *= 2
#                        index, columns, column_addrw, column_dataw = create_decompose_row(data_width, temp_total_address,group_data_width)
#                    else: 
#                        break
#
#                        
#                limit += 1
#                
#                if limit > 10:
#                    return 
       
       
        index_A = index
        index_B = index
        column_addr_A = column_addrw
        column_data_A = column_dataw
        
        column_addr_B = column_addrw
        column_data_B = column_dataw
        
       
        if(data_width_A != data_width_B):
            if data_width_A > data_width_B:
                mixedResult, mixedIndex, MixedDataWidth, MixedAddressWidth = find_mixed_width_row( index, int(data_width_A/data_width_B) )
                index_A = mixedIndex                    
                index_B = index
                
                column_addr_A = MixedAddressWidth
                column_data_A = MixedDataWidth
                
                
            elif data_width_A < data_width_B:                    
                mixedResult, mixedIndex, MixedDataWidth, MixedAddressWidth = find_mixed_width_row(index, int(data_width_B/data_width_A))
                index_A = index                    
                index_B = mixedIndex 
        
                column_addr_B = MixedAddressWidth
                column_data_B = MixedDataWidth
                
        
        
        bram_row = [index_A,index_B, columns,0,0] 
        bram_decompose_table.append(bram_row)
    
        total_address -= pow(2,column_addrw)
    
    
        total_width += column_dataw
        total_bram  += columns
        
        result = "row " + str(row) + ") Primitive index A: " + str(index_A) + " addrA "+ str(column_addr_A) + " dataA: " + str(column_data_A) + " index B: " + str(index_B) + " addrB "+ str(column_addr_B) + " dataB: " + str(column_data_B) +  " number of columns:" +str(columns)
        print (result)
   
       
        # Basic Mapping A
        
        #for x in range(0,  columns):
        #    
        #    data_start = byteen_index*group_data_width +  total_group_width
        #    data_end = data_start + column_dataw
        #    if data_end > data_width:
        #        data_end = data_width
        #    if data_end > ((byteen_index+1)*group_data_width):
        #        data_end = ((byteen_index+1)*group_data_width)
        #
        #    data_end -= 1
        #    nBits = data_end - data_start +1 
        #    interval = 0
        #    
        #    
        #    bram_map = [row,x,data_start,nBits,interval,row,row,row,byteen_index,data_start,nBits,interval,row,row,row,byteen_index]
        #
        #    if group_data_width != 0:
        #        total_group_width += column_dataw
        #        if total_group_width >=  group_data_width :
        #            total_group_width = 0
        #            byteen_index += 1
        #
        #    bram_mapping_table.append(bram_map)

        # Basic Mapping for Scan First
        
        # Mapping A
        data_start = 0
        byteen_index = 0
        total_group_width = 0
        
        for x in range(0,  columns):
            
            data_start = byteen_index*group_data_width +  total_group_width
            data_end = data_start + column_dataw
            if data_end > data_width:
                data_end = data_width
            if data_end > ((byteen_index+1)*group_data_width):
                data_end = ((byteen_index+1)*group_data_width)
        
            data_end -= 1
            Repeat = 0
            
            
            bram_map = [row,x,data_end,data_start,Repeat,row,row,row,byteen_index,data_end,data_start,Repeat,row,row,row,byteen_index, column_addr_A, column_data_A, column_addr_B, column_data_B]
        
            if group_data_width != 0:
                total_group_width += column_dataw
                if total_group_width >=  group_data_width :
                    total_group_width = 0
                    byteen_index += 1
        
            bram_mapping_table.append(bram_map)
        
        
        
        

        # Mapping A
        if data_width_A > data_width_B:
        
            if group_data_width_A == 0:
                group_data_width_A = data_width_A
                
        
            data_start = 0
            byteen_index = 0
            total_group_width = 0
            temp_data_width_A = 0
            
            for x in range(0,  columns):
                
                Repeat = int(column_data_A / column_data_B)
                
                bram_map_A = bram_mapping_table[bram_mapping_table_index + x] 
                              
                bram_map_A[2] += extend_row_index*extend_data_width
                bram_map_A[3] += extend_row_index*extend_data_width
                bram_map_A[4] = Repeat
                bram_map_A[5] = mixed_row
                bram_map_A[6] = mixed_row
                bram_map_A[7] = mixed_row
                bram_map_A[8] = byteen_index
            
               # print (bram_map_A)
            
                if group_data_width_A != 0:
                    total_group_width += column_data_A
                    if total_group_width >=  group_data_width_A :
                        total_group_width = 0
                        byteen_index += 1
                

                temp_data_width_A  += column_data_A                

                
            
                
            mixed_total_width +=  temp_data_width_A
            if mixed_total_width >= data_width_A:
                mixed_total_width = 0
                extend_row_index  = 0
                mixed_row += 1
            else: 
                extend_row_index += 1
                extend_data_width = temp_data_width_A
            
            
            if max_extend_row_index < extend_row_index:
                max_extend_row_index = extend_row_index

            
            #print (extend_row_index)    
            
            
        # Mapping B
        if data_width_A < data_width_B:
        
            if group_data_width_B == 0:
                group_data_width_B = data_width_B
                
        
            data_start = 0
            byteen_index = 0
            total_group_width = 0
            temp_data_width_B = 0
            
            for x in range(0,  columns):
                
                Repeat = int(column_data_B / column_data_A)
                
                bram_map_B = bram_mapping_table[bram_mapping_table_index + x] 
                        
                bram_map_B[9]  += extend_row_index*extend_data_width                
                bram_map_B[10] += extend_row_index*extend_data_width
                bram_map_B[11] = Repeat
                bram_map_B[12] = mixed_row
                bram_map_B[13] = mixed_row
                bram_map_B[14] = mixed_row
                bram_map_B[15] = byteen_index
            
               # print (bram_map_A)
            
                if group_data_width_B != 0:
                    total_group_width += column_data_B
                    if total_group_width >=  group_data_width_B :
                        total_group_width = 0
                        byteen_index += 1
                

                temp_data_width_B  += column_data_B
                
            mixed_total_width +=  temp_data_width_B
            if mixed_total_width >= data_width_B:
                mixed_total_width = 0
                extend_row_index  = 0
                mixed_row += 1
            else: 
                extend_row_index += 1
                extend_data_width = temp_data_width_B

            
            if max_extend_row_index < extend_row_index:
                max_extend_row_index = extend_row_index
            
            #print (extend_row_index)    

        
        if total_address <= 0:
            break
        
        bram_mapping_table_index += columns
        
        row += 1
    
    #find Max Bram Address of Port A
    max_primitive_addressA = 0
    
    for row in bram_decompose_table:
        primitive_data = bram_feature_table[row[0]][FEATURE.DATAW.value]
        primitive_addr = bram_feature_table[row[0]][FEATURE.ADDRW.value]
        if max_primitive_addressA < primitive_addr:
            max_primitive_addressA = primitive_addr
    
    max_primitive_addressB = 0

    for row in bram_decompose_table:
        primitive_data = bram_feature_table[row[1]][FEATURE.DATAW.value]
        primitive_addr = bram_feature_table[row[1]][FEATURE.ADDRW.value]
        if max_primitive_addressB < primitive_addr:
            max_primitive_addressB = primitive_addr
    
    max_rMux_index_A = 0;
    max_rMux_index_B = 0;
    for row in bram_mapping_table:
        if row[5] > max_rMux_index_A:
            max_rMux_index_A = row[5];
        if row[12] > max_rMux_index_B:
            max_rMux_index_B = row[12];


    max_WenSel_index_A = 0;
    max_WenSel_index_B = 0;
    for row in bram_mapping_table:
        if row[6] > max_WenSel_index_A:
            max_WenSel_index_A = row[6];
        if row[13] > max_WenSel_index_B:
            max_WenSel_index_B = row[13];

    

 
    rMux_mapping_table_A = list()
    rMux_mapping_table_B = list()
    
    wen_sel_mapping_table_A = list()
    wen_sel_mapping_table_B = list()
    
    
    if (len(bram_decompose_table) > 1   ):
    
        if (address_width_A> max_primitive_addressA):
            rMuxA = [address_width_A-1,max_primitive_addressA, data_width_A-1,0, max_rMux_index_A, 0 , 0]
            rMux_mapping_table_A.append(rMuxA)
        
            WenSelA = [address_width_A-1,max_primitive_addressA, max_WenSel_index_A,0 , 0]
            wen_sel_mapping_table_A.append(WenSelA)
            
            if max_extend_row_index != 0: 
           
                if data_width_A < data_width_B:
                    
                    mixed_addr_width  = int(max_primitive_addressA -max_primitive_addressB )
                    
                    extend_addr = int(math.log2(max_extend_row_index+1))
                    
                    for index in range(0,mixed_addr_width):
                        row = index
                        address_mapping_table_A.append(row)
                    
                    for index in range(0,extend_addr):
                        row = index + max_primitive_addressA
                        address_mapping_table_A.append(row)
                        
                    for index in range(mixed_addr_width,max_primitive_addressA):
                        row = index
                        address_mapping_table_A.append(row)
                        
                    for index in range(max_primitive_addressA+extend_addr,address_width_A):
                        row = index
                        address_mapping_table_A.append(row)
                        
       
        if (address_width_B> max_primitive_addressB):
            rMuxB = [address_width_B-1,max_primitive_addressB, data_width_B-1,0, max_rMux_index_B, 0, 0]
            rMux_mapping_table_B.append(rMuxB)
    
            WenSelB = [address_width_B-1,max_primitive_addressB, max_WenSel_index_B,0 , 0]
            wen_sel_mapping_table_B.append(WenSelB)
            
            if max_extend_row_index != 0:
             
                if data_width_B < data_width_A:
                    
                    mixed_addr_width  = int(max_primitive_addressB -max_primitive_addressA )
                
                    extend_addr = int(math.log2(max_extend_row_index+1))
                    
                    for index in range(0,mixed_addr_width):
                        row = index
                        address_mapping_table_B.append(row)
                    
                    for index in range(0,extend_addr):
                        row = index + max_primitive_addressB
                        address_mapping_table_B.append(row)
                        
                    for index in range(mixed_addr_width,max_primitive_addressB):
                        row = index
                        address_mapping_table_B.append(row)
                        
                    for index in range(max_primitive_addressB+extend_addr,address_width_B):
                        row = index
                        address_mapping_table_B.append(row)
            
        
    result = "Total BRam used:" + str(total_bram)
    print (result) 
 
#def create_decompose_table_scan_row(address_width, data_width, size, group_data_width ): 
#   
#    total_width = 0
#    total_bram  = 0
#    row      = 0
#    global bram_decompose_mode
#    global in_addr_width_a
#    global in_data_width_a
#    global in_addr_width_b
#    global in_data_width_b   
#    global byteen_width
#    global byteen_enable
#    global group_columns
#    global bram_decompose_table  
#    global bram_decompose_byteen_table
#    global bram_mapping_table
#    global rMux_mapping_table_A
#    global rMux_mapping_table_B
#    global wen_sel_mapping_table_A
#    global wen_sel_mapping_table_B
#    global actual_size
#       
#    bram_decompose_byteen_table = list()
#    group_columns = 1
#    group_data_count = 0;
#    group_data_ptr   = 0;
#    for x in range(0, data_width):
#        bram_data_row = [group_data_ptr,1]
#        bram_decompose_byteen_table.append(bram_data_row)
#        
#        group_data_count += 1
#        if(group_data_count == group_data_width):
#            group_data_ptr += 1
#            group_data_count = 0      
#    
#    if group_data_width != 0:
#        byteen_width =  group_data_ptr
#        byteen_enable = 1
#        if ( ( data_width % group_data_width ) != 0):
#            byteen_width += 1
#        result = "byteen width: " + str(byteen_width) + " Group Data Width: " + str(group_data_width)
#        print (result)
#
#    
#    bram_decompose_mode = 1 # 1: LOOP ROW FIRST", 0: LOOP COLUMN FIRST"
#   
#    total_address = pow(2,address_width)  
#   
#    if size != 0:
#        if size <= total_address:
#            total_address = size
#            
#    actual_size = total_address   
#
#    in_addr_width_a = address_width
#    in_data_width_a = data_width
#    in_addr_width_b = address_width
#    in_data_width_b = data_width    
#   
#    bram_decompose_table = list()
#    bram_mapping_table   = list()
#    
#    if group_data_width == 0:
#        group_data_width = data_width
#    while True:
#    
#        index, columns, column_addrw, column_dataw = create_decompose_row(data_width, total_address,group_data_width)
#        bram_row = [index,index, columns,0,0] 
#        bram_decompose_table.append(bram_row)
#    
#        total_address -= pow(2,column_addrw)
#    
#    
#        total_width += column_dataw
#        total_bram  += columns
#        
#        result = "row " + str(row) + ") Primitive index: " + str(index) + " addr"+ str(column_addrw) + " data: " + str(column_dataw) + " number of columns:" +str(columns)
#        print (result)
#   
#        data_start = 0
#        byteen_index = 0
#        total_group_width = 0 
#        for x in range(0,  columns):
#            
#            data_start = byteen_index*group_data_width +  total_group_width
#            data_end = data_start + column_dataw
#            if data_end > data_width:
#                data_end = data_width
#            if data_end > ((byteen_index+1)*group_data_width):
#                data_end = ((byteen_index+1)*group_data_width)
#        
#            data_end -= 1
#            nBits = data_end - data_start +1 
#            interval = 0
#            
#            
#            bram_map = [row,x,data_start,nBits,interval,row,row,row,byteen_index,data_start,nBits,interval,row,row,row,byteen_index]
#        
#            if group_data_width != 0:
#                total_group_width += column_dataw
#                if total_group_width >=  group_data_width :
#                    total_group_width = 0
#                    byteen_index += 1
#        
#            bram_mapping_table.append(bram_map)
#
#
#
#   
#        if total_address <= 0:
#            break
#            
#        row += 1
#    
#    #find Max Bram Address of Port A
#    max_primitive_addressA = 0
#    for row in bram_decompose_table:
#        primitive_data = bram_feature_table[row[0]][FEATURE.DATAW.value]
#        primitive_addr = bram_feature_table[row[0]][FEATURE.ADDRW.value]
#        if max_primitive_addressA < primitive_addr:
#            max_primitive_addressA = primitive_addr
#    
#    
#    max_primitive_addressB = 0
#    for row in bram_decompose_table:
#        primitive_data = bram_feature_table[row[1]][FEATURE.DATAW.value]
#        primitive_addr = bram_feature_table[row[1]][FEATURE.ADDRW.value]
#        if max_primitive_addressB < primitive_addr:
#            max_primitive_addressB = primitive_addr
#    
#    max_rMux_index_A = 0;
#    max_rMux_index_B = 0;
#    for row in bram_mapping_table:
#        if row[4] > max_rMux_index_A:
#            max_rMux_index_A = row[4];
#        if row[10] > max_rMux_index_B:
#            max_rMux_index_B = row[10];
# 
#    rMux_mapping_table_A = list()
#    rMux_mapping_table_B = list()
#    
#    wen_sel_mapping_table_A = list()
#    wen_sel_mapping_table_B = list()
#     
#    if (len(bram_decompose_table) > 1   ):
#        rMuxA = [address_width-1,max_primitive_addressA, data_width-1,0, max_rMux_index_A, 0]
#        rMux_mapping_table_A.append(rMuxA)
#       
#        rMuxB = [address_width-1,max_primitive_addressB, data_width-1,0, max_rMux_index_B, 0]
#        rMux_mapping_table_B.append(rMuxB)
#    
#        WenSelA = [address_width-1,max_primitive_addressB, len(bram_decompose_table)-1,0]
#        wen_sel_mapping_table_A.append(WenSelA)
#    
#        WenSelB = [address_width-1,max_primitive_addressB, len(bram_decompose_table)-1,0]
#        wen_sel_mapping_table_B.append(WenSelB)
#       
#    result = "Total BRam used:" + str(total_bram)
#    print (result) 


def mapping_mux_wen(address_width_A, data_width_A, address_width_B, data_width_B) :
   
    global bram_decompose_table  
    global bram_decompose_byteen_table
    global bram_mapping_table
    global rMux_mapping_table_A
    global rMux_mapping_table_B
    global wen_sel_mapping_table_A
    global wen_sel_mapping_table_B
    global address_mapping_table_A
    global address_mapping_table_B
    global byteen_width_A
    global byteen_width_B
    
    
    #find Max Bram Address of Port A
    max_primitive_addressA = 0
    
    for row in bram_decompose_table:
        primitive_data = bram_feature_table[row[0]][FEATURE.DATAW.value]
        primitive_addr = bram_feature_table[row[0]][FEATURE.ADDRW.value]
        if max_primitive_addressA < primitive_addr:
            max_primitive_addressA = primitive_addr
    
    max_primitive_addressB = 0

    for row in bram_decompose_table:
        primitive_data = bram_feature_table[row[1]][FEATURE.DATAW.value]
        primitive_addr = bram_feature_table[row[1]][FEATURE.ADDRW.value]
        if max_primitive_addressB < primitive_addr:
            max_primitive_addressB = primitive_addr
    
    max_rMux_index_A = 0;
    max_rMux_index_B = 0;
    for row in bram_mapping_table:
        if row[5] > max_rMux_index_A:
            max_rMux_index_A = row[5];
        if row[12] > max_rMux_index_B:
            max_rMux_index_B = row[12];


    max_WenSel_index_A = 0;
    max_WenSel_index_B = 0;
    for row in bram_mapping_table:
        if row[6] > max_WenSel_index_A:
            max_WenSel_index_A = row[6];
        if row[13] > max_WenSel_index_B:
            max_WenSel_index_B = row[13];
    max_extend_row_index=0

    if data_width_A > data_width_B :
        wen_sel_mapping_table_B = list()
        rMux_mapping_table_B = list()
        address_mapping_table_B = list()
        
        max_extend_row_index = data_width_A/data_width_B
        
        extend_addr = int(math.log2(max_extend_row_index+1))
        if (len(wen_sel_mapping_table_A)>0):
            for wen_sel_A in wen_sel_mapping_table_A:
            
                rMuxB = [wen_sel_A[0] + extend_addr, wen_sel_A[1], data_width_B-1,0, max_rMux_index_B, 0 , 0]
                rMux_mapping_table_B.append(rMuxB)
       
                WenSelB = [wen_sel_A[0] + extend_addr, wen_sel_A[1], max_WenSel_index_B,0 , 0]
                wen_sel_mapping_table_B.append(WenSelB)
        
        else:
            rMuxB = [max_primitive_addressA + extend_addr - 1,max_primitive_addressA, data_width_B-1,0, max_rMux_index_B, 0 , 0]
            rMux_mapping_table_B.append(rMuxB)
       
            WenSelB = [max_primitive_addressA + extend_addr - 1,max_primitive_addressA, max_WenSel_index_B,0 , 0]
            wen_sel_mapping_table_B.append(WenSelB)
            
        for index in range(0,extend_addr):
            row = index + max_primitive_addressA
            address_mapping_table_B.append(row)
            
        for index in range(0,max_primitive_addressA):
            row = index
            address_mapping_table_B.append(row)
            
        for index in range(max_primitive_addressA+extend_addr,address_width_B):
            row = index
            address_mapping_table_B.append(row)

        
        
    
        

    if data_width_B > data_width_A :
        wen_sel_mapping_table_A = list()
        rMux_mapping_table_A = list()
        address_mapping_table_A = list()
        
        max_extend_row_index = data_width_B/data_width_A
        
        extend_addr = int(math.log2(max_extend_row_index+1))
        if (len(wen_sel_mapping_table_B)>0):
            for wen_sel_B in wen_sel_mapping_table_B:
            
                rMuxA = [wen_sel_B[0] + extend_addr, wen_sel_B[1], data_width_A-1,0, max_rMux_index_A, 0 , 0]
                rMux_mapping_table_A.append(rMuxA)
       
                WenSelA = [wen_sel_B[0] + extend_addr, wen_sel_B[1], max_WenSel_index_A,0 , 0]
                wen_sel_mapping_table_A.append(WenSelA)
        
        else:
            rMuxA = [max_primitive_addressB + extend_addr - 1,max_primitive_addressB, data_width_A-1,0, max_rMux_index_A, 0 , 0]
            rMux_mapping_table_A.append(rMuxA)
       
            WenSelA = [max_primitive_addressB + extend_addr - 1,max_primitive_addressB, max_WenSel_index_A,0 , 0]
            wen_sel_mapping_table_A.append(WenSelA)
            
        for index in range(0,extend_addr):
            row = index + max_primitive_addressB
            address_mapping_table_A.append(row)
            
        for index in range(0,max_primitive_addressB):
            row = index
            address_mapping_table_A.append(row)
            
        for index in range(max_primitive_addressB+extend_addr,address_width_A):
            row = index
            address_mapping_table_A.append(row)
       
  

def mapping_mux_wen_scaleDown(address_width_A, data_width_A, address_width_B, data_width_B) :
   
   #support Scale Row only
    global bram_decompose_table  
    global bram_decompose_byteen_table
    global bram_mapping_table
    global rMux_mapping_table_A
    global rMux_mapping_table_B
    global wen_sel_mapping_table_A
    global wen_sel_mapping_table_B
    global address_mapping_table_A
    global address_mapping_table_B
    global byteen_width_A
    global byteen_width_B
    
    
    #find Max Bram Address of Port A
    max_primitive_dataA = 0
    max_primitive_addressA = 0
    max_num_column =  0
    for row in bram_decompose_table:
        primitive_data = bram_feature_table[row[0]][FEATURE.DATAW.value]
        primitive_addr = bram_feature_table[row[0]][FEATURE.ADDRW.value]    
        if max_primitive_dataA < primitive_data:
            max_primitive_dataA = primitive_data
        if max_primitive_addressA < primitive_addr:
            max_primitive_addressA = primitive_addr
        
        num_column      = row[2]            
        if max_num_column < num_column:
            max_num_column = num_column

    max_primitive_dataB = 0    
    max_primitive_addressB = 0

    for row in bram_decompose_table:
        primitive_data = bram_feature_table[row[1]][FEATURE.DATAW.value]
        primitive_addr = bram_feature_table[row[1]][FEATURE.ADDRW.value]
        if max_primitive_dataB < primitive_data:
            max_primitive_dataB = primitive_data
        if max_primitive_addressB < primitive_addr:
            max_primitive_addressB = primitive_addr
    
    max_rMux_index_A = 0;
    max_rMux_index_B = 0;
    for row in bram_mapping_table:
        if row[5] > max_rMux_index_A:
            max_rMux_index_A = row[5];
        if row[12] > max_rMux_index_B:
            max_rMux_index_B = row[12];


    max_WenSel_index_A = 0;
    max_WenSel_index_B = 0;
    for row in bram_mapping_table:
        if row[6] > max_WenSel_index_A:
            max_WenSel_index_A = row[6];
        if row[13] > max_WenSel_index_B:
            max_WenSel_index_B = row[13];
    max_extend_row_index=0

    if data_width_A > data_width_B :
        wen_sel_mapping_table_B = list()
        rMux_mapping_table_B = list()
        address_mapping_table_B = list()
        
        max_extend_row_index = data_width_A/data_width_B
        

        
        
        extend_addr = int(math.log2(max_extend_row_index+1))
        if (len(wen_sel_mapping_table_A)>0):
            for wen_sel_A in wen_sel_mapping_table_A:
            
                rMuxB = [wen_sel_A[0] + extend_addr, wen_sel_A[1], data_width_B-1,0, max_rMux_index_B, 0 , 0]
                rMux_mapping_table_B.append(rMuxB)
       
                WenSelB = [wen_sel_A[0] + extend_addr, wen_sel_A[1], max_WenSel_index_B,0 , 0]
                wen_sel_mapping_table_B.append(WenSelB)
        
        else:
            rMuxB = [max_primitive_addressA + extend_addr - 1,max_primitive_addressA, data_width_B-1,0, max_rMux_index_B, 0 , 0]
            rMux_mapping_table_B.append(rMuxB)
       
            WenSelB = [max_primitive_addressA + extend_addr - 1,max_primitive_addressA, max_WenSel_index_B,0 , 0]
            wen_sel_mapping_table_B.append(WenSelB)
            
        for index in range(0,extend_addr):
            row = index + max_primitive_addressA
            address_mapping_table_B.append(row)
            
        for index in range(0,max_primitive_addressA):
            row = index
            address_mapping_table_B.append(row)
            
        for index in range(max_primitive_addressA+extend_addr,address_width_B):
            row = index
            address_mapping_table_B.append(row)

        
        
    #           PortA Addr MSB, PortA Addr LSB, DataA[MSB],     DataA[LSB],     MuxSelA[MSB],   MuxSelA[LSB],   Bypass,  
        

    if data_width_B > data_width_A :
        wen_sel_mapping_table_A = list()
        rMux_mapping_table_A = list()
        address_mapping_table_A = list()
        
        switch_addr        = int(math.log2(max_num_column))
        scaledown_addr     = int(math.log2(max_primitive_dataB/max_primitive_dataA))
   
        
        if (len(wen_sel_mapping_table_B)>0):
            for wen_sel_B in wen_sel_mapping_table_B:
            
                rMuxA = [wen_sel_B[0] + extend_addr, wen_sel_B[1], data_width_A-1,0, max_rMux_index_A, 0 , 0]
                rMux_mapping_table_A.append(rMuxA)
       
                WenSelA = [wen_sel_B[0] + extend_addr, wen_sel_B[1], max_WenSel_index_A,0 , 0]
                wen_sel_mapping_table_A.append(WenSelA)
        
        else:
            rMuxA = [address_width_A-1,address_width_A-switch_addr, data_width_A-1,0, max_rMux_index_A, 0 , 0]
            rMux_mapping_table_A.append(rMuxA)
       
            WenSelA = [address_width_A-1,address_width_A-switch_addr,max_WenSel_index_A,0 , 0]
            wen_sel_mapping_table_A.append(WenSelA)
            
        for index in range(0,scaledown_addr):
            row = index
            address_mapping_table_A.append(row)
            
        for index in range(address_width_A-switch_addr,address_width_A):
            row = index
            address_mapping_table_A.append(row)
            
        for index in range(scaledown_addr,address_width_A-switch_addr):
            row = index
            address_mapping_table_A.append(row) 
 
def create_decompose_table_scan_row_mwm(address_width_A, data_width_A, size, group_data_width, address_width_B, data_width_B, group_data_width_B):
    
    result = True
    if(data_width_B != 0) | (address_width_B!=0):
       result, address_width_A, data_width_A, size_A, group_data_width, address_width_B, data_width_B, size_B  =  check_row_mwm(address_width_A, data_width_A, size, group_data_width, address_width_B, data_width_B)    
    else:
        size_A = size
        size_B = size
        
    
    if result == False:
        print("\nABORT! don't support current setting in Mixed Width Mode\n ")
        return 
    
    print (address_width_A, data_width_A, size_A, group_data_width, address_width_B, data_width_B, size_B, group_data_width_B)
    
    scan_index = 0
    
    if (data_width_B == 0) | (data_width_B == data_width_A) :
        create_decompose_table_scan_row(scan_index, address_width_A, data_width_A, size_A, group_data_width,  address_width_A, data_width_A, size_A, group_data_width_B)
    
    
    else:# Mixed Width Mode
        print("Mixed Width Mode is Enabled!")
        if data_width_A > data_width_B:
            scan_index = 1
        
        create_decompose_table_scan_row(scan_index, address_width_A, data_width_A, size_A, group_data_width,  address_width_B, data_width_B, size_B, group_data_width_B)

def create_decompose_table_scan_row_mwm_stack(address_width_A, data_width_A, size, group_data_width, address_width_B, data_width_B, group_data_width_A, group_data_width_B):
    
    global in_addr_width_a
    global in_data_width_a
    global in_addr_width_b
    global in_data_width_b 
    global byteen_width_A
    global byteen_width_B
    global actual_size_A
    global actual_size_B
    
       
    result = True
    if(data_width_B != 0) | (address_width_B!=0):
       result, address_width_A, data_width_A, size_A, group_data_width, address_width_B, data_width_B, size_B  =  check_row_mwm (address_width_A, data_width_A, size, group_data_width, address_width_B, data_width_B)    
    else:
        size_A = size
        size_B = size
        
    
    if result == False:
        print("\nABORT! don't support current setting in Mixed Width Mode\n ")
        return  
        
    if(data_width_A == data_width_B):
        create_decompose_table_scan_row_mwm(address_width_A, data_width_A, size, group_data_width_A, address_width_A, data_width_A, group_data_width_B)
             
        Max_byteen_index_A = 0
        Max_byteen_index_B = 0

        
        for row in bram_mapping_table:
            msb_data_A = row[3]
            msb_data_B = row[9] 
            
            byteen_index_A = 0
            byteen_index_B = 0           
            
            if byteen_index_A> Max_byteen_index_A :
                Max_byteen_index_A = byteen_index_A
                
            if byteen_index_B> Max_byteen_index_B :
                Max_byteen_index_B = byteen_index_B    
            
            row[8] = int(0)  
            row[15]= int(0)
            
            
            
            byteen_width_A =  int(1)
            byteen_width_B =  int(1)
                
        
    elif (data_width_A > data_width_B):     
        create_decompose_table_scan_row_mwm(address_width_A, data_width_A, size, data_width_B, address_width_A, data_width_A, data_width_B)
        
        print("MWM remapping Byte Enable mode")
             
        current_data_ptr = 0 
        
        group_data_ptr = 0 
        
        
        row_index = 0
        byteen_index = 0
        
        
        for row in bram_mapping_table:
            
            index_row    = row[0]    
            index_column = row[1]    
            
            msb_data_A   = row[2]    
            lsb_data_A   = row[3]
        
            primitive_dataB = row[19]
          
            
            row_index   =   int(msb_data_A/data_width_B)
            
            lsb_data_B  =   int(lsb_data_A%data_width_B)
            msb_data_B  =   int(msb_data_A%data_width_B)
            
            byteen_index =  int(0)

            row[8]  = byteen_index            
            row[9]  = msb_data_B
            row[10] = lsb_data_B
            
            row[12] = row_index
            row[13] = row_index
            row[14] = row_index
            row[15] = byteen_index
            
             
  
        print("Mapping ", address_width_A, data_width_A, address_width_B, data_width_B)
        mapping_mux_wen(address_width_A, data_width_A, address_width_B, data_width_B)
        
        in_addr_width_a = address_width_A
        in_data_width_a = data_width_A
        in_addr_width_b = address_width_B
        in_data_width_b = data_width_B    
        
        byteen_width_A = int(1)
        byteen_width_B = int(1)
            
        actual_size_A = pow(2,address_width_A)  
        if size_A != 0:
            if size_A <= actual_size_A:
                actual_size_A = size_A
    
        actual_size_B = pow(2,address_width_B)  
        if size_B != 0:
            if size_B <= actual_size_B:
                actual_size_B = size_B
        

        print("PortA: ", in_addr_width_a, in_data_width_a, actual_size_A, group_data_width_A, byteen_width_A)
        print("PortB: ", in_addr_width_b, in_data_width_b, actual_size_B, group_data_width_B, byteen_width_B)    
        
    elif (data_width_A < data_width_B):     
        create_decompose_table_scan_row_mwm(address_width_B, data_width_B, size, data_width_A, address_width_B, data_width_B, data_width_A)

        print("MWM remapping Byte Enable mode")
        
        current_data_ptr = 0 
        
        group_data_ptr = 0 
        
        
        row_index = 0
        byteen_index = 0
        
        
        for row in bram_mapping_table:
            
            index_row    = row[0]    
            index_column = row[1]    
            
            msb_data_B   = row[9]    
            lsb_data_B   = row[10]
        
            primitive_dataA = row[17]
            
            row_index   =   int(msb_data_B/data_width_A)
            
            lsb_data_A  =   int(lsb_data_B%data_width_A)
            msb_data_A  =   int(msb_data_B%data_width_A)
            
            byteen_index =  int(0)
            
            row[2]  = msb_data_A
            row[3]  = lsb_data_A
            
            row[5] = row_index
            row[6] = row_index
            row[7] = row_index
            row[8] = byteen_index
            
            row[15] = byteen_index


        print("Mapping ", address_width_A, data_width_A, address_width_B, data_width_B)
        mapping_mux_wen(address_width_A, data_width_A, address_width_B, data_width_B)
        
        in_addr_width_a = address_width_A
        in_data_width_a = data_width_A
        in_addr_width_b = address_width_B
        in_data_width_b = data_width_B    
        
        byteen_width_A = int(1)
        byteen_width_B = int(1) 
            
        actual_size_A = pow(2,address_width_A)  
        if size_A != 0:
            if size_A <= actual_size_A:
                actual_size_A = size_A
    
        actual_size_B = pow(2,address_width_B)  
        if size_B != 0:
            if size_B <= actual_size_B:
                actual_size_B = size_B
                
                
        print("PortA: ", in_addr_width_a, in_data_width_a, actual_size_A, group_data_width_A, byteen_width_A)
        print("PortB: ", in_addr_width_b, in_data_width_b, actual_size_B, group_data_width_B, byteen_width_B)

def create_decompose_table_scan_row_mwm_byteEn(address_width_A, data_width_A, size, group_data_width, address_width_B, data_width_B, group_data_width_A, group_data_width_B):
    
    global in_addr_width_a
    global in_data_width_a
    global in_addr_width_b
    global in_data_width_b 
    global byteen_width_A
    global byteen_width_B
    global actual_size_A
    global actual_size_B
    print("Debug: ", address_width_A, data_width_A, size, group_data_width, address_width_B, data_width_B, group_data_width_A, group_data_width_B)
       
    result = True
    if(data_width_B != 0) | (address_width_B!=0):
       result, address_width_A, data_width_A, size_A, group_data_width, address_width_B, data_width_B, size_B  =  check_row_mwm (address_width_A, data_width_A, size, group_data_width, address_width_B, data_width_B)    
    else:
        size_A = size
        size_B = size
    
    print("Debug: ", result, address_width_A, data_width_A, size_A, group_data_width, address_width_B, data_width_B, size_B)   
    
    if result == False:
        print("\nABORT! don't support current setting in Mixed Width Mode\n ")
        return  
        
 #   if (group_data_width_A == 0):
 #       if(group_data_width !=0):
 #           group_data_width_A = group_data_width
 #       else: 
 #       	group_data_width_A = data_width_A
 #           #print("Please input paramter group_data_width_A or group_data_width ")
 #           #return  
 #   
 #   if (group_data_width_B == 0):
 #       if(group_data_width !=0):
 #           group_data_width_B = group_data_width
 #       else: 
 #       	group_data_width_B = data_width_B
 #           #print("Please input paramter group_data_width_B or group_data_width ")
 #           #return  
  
    print("Debug: ", result, address_width_A, data_width_A, size_A, group_data_width, address_width_B, data_width_B, size_B, group_data_width_A, group_data_width_B)
                
    if(data_width_A == data_width_B):
        create_decompose_table_scan_row_mwm(address_width_A, data_width_A, size, group_data_width_A, address_width_A, data_width_A, group_data_width_B)
             
        Max_byteen_index_A = 0
        Max_byteen_index_B = 0

        
        for row in bram_mapping_table:
            msb_data_A = row[3]
            msb_data_B = row[9] 
            
            byteen_index_A = int( (msb_data_A) / group_data_width_A )
            byteen_index_B = int( (msb_data_B) / group_data_width_B )           
            
            if byteen_index_A> Max_byteen_index_A :
                Max_byteen_index_A = byteen_index_A
                
            if byteen_index_B> Max_byteen_index_B :
                Max_byteen_index_B = byteen_index_B    
            
            row[8] = byteen_index_A  
            row[15]= byteen_index_B
            
            
            
            byteen_width_A =  Max_byteen_index_A+1
            byteen_width_B =  Max_byteen_index_B+1
                
        
    elif (data_width_A > data_width_B):
        print("MWM remapping Byte Enable mode (Data width A > B)")     
        create_decompose_table_scan_row_mwm(address_width_A, data_width_A, size, group_data_width_A, address_width_A, data_width_A, group_data_width_A)
        
        
             
        current_data_ptr = 0 
        
        group_data_ptr = 0 
        
        
        row_index = 0
        byteen_index = 0
        
        
        for row in bram_mapping_table:
            
            index_row    = row[0]    
            index_column = row[1]    
            
            msb_data_A   = row[2]    
            lsb_data_A   = row[3]
            row_index_A  =  row[5]
        
            primitive_dataB = row[19]
            mixedRatio      = int (data_width_A/ data_width_B )
            
            row_index_B   =   int(msb_data_A/data_width_B) + int(mixedRatio*row_index_A)
            
            lsb_data_B  =   int(lsb_data_A%data_width_B)
            msb_data_B  =   int(msb_data_A%data_width_B)
            
            byteen_index =  int(lsb_data_B/group_data_width_B)
            
            row[9]  = msb_data_B
            row[10] = lsb_data_B
            
            row[12] = row_index_B
            row[13] = row_index_B
            row[14] = row_index_B
            row[15] = byteen_index
            
             
         #   lsb_data_B   = current_data_ptr
         #   
         #   msb_data_B   = current_data_ptr + primitive_dataB
         #
         #              
         #   if(msb_data_B>= data_width_B):
         #       msb_data_B = data_width_B
         #          
         #   row[9]  = msb_data_B-1
         #   row[10] = lsb_data_B
         #   
         #   row[12] = row_index
         #   row[13] = row_index
         #   row[14] = row_index
         #   row[15] = byteen_index
            
           
         #   current_data_ptr += primitive_dataB
         #   if(current_data_ptr>= data_width_B):
         #       current_data_ptr = 0
         #       group_data_ptr = 0
         #       byteen_index = 0
         #       row_index += 1
         #   
         #   else: 
         #       group_data_ptr += primitive_dataB
         #       if (group_data_ptr >= group_data_width_B):
         #           group_data_ptr = 0
         #           byteen_index += 1;

        print("Mapping ", address_width_A, data_width_A, address_width_B, data_width_B)
        mapping_mux_wen(address_width_A, data_width_A, address_width_B, data_width_B)
        
        in_addr_width_a = address_width_A
        in_data_width_a = data_width_A
        in_addr_width_b = address_width_B
        in_data_width_b = data_width_B    
        
        byteen_width_A = int(data_width_A / group_data_width_A)
        byteen_width_B = int(data_width_B / group_data_width_B)
        
        if (byteen_width_A ==0):
        	byteen_width_A = 1
        if (byteen_width_B ==0):
        	byteen_width_B = 1
            
        actual_size_A = pow(2,address_width_A)  
        if size_A != 0:
            if size_A <= actual_size_A:
                actual_size_A = size_A
    
        actual_size_B = pow(2,address_width_B)  
        if size_B != 0:
            if size_B <= actual_size_B:
                actual_size_B = size_B
        

        print("PortA: ", in_addr_width_a, in_data_width_a, actual_size_A, group_data_width_A, byteen_width_A)
        print("PortB: ", in_addr_width_b, in_data_width_b, actual_size_B, group_data_width_B, byteen_width_B)    
        
    elif (data_width_A < data_width_B):   
        print("MWM remapping Byte Enable mode (Data width A < B)")  
        create_decompose_table_scan_row_mwm(address_width_B, data_width_B, size, group_data_width_B, address_width_B, data_width_B, group_data_width_B)
        
        current_data_ptr = 0 
        
        group_data_ptr = 0 
        
        
        row_index = 0
        byteen_index = 0
        
        
        for row in bram_mapping_table:
            
            index_row    = row[0]    
            index_column = row[1]    
            
            msb_data_B   = row[9]    
            lsb_data_B   = row[10]
            row_index_B  =  row[12]
        
            primitive_dataA = row[17]
            mixedRatio      = int (data_width_B/ data_width_A )
            
            row_index_A   =   int(msb_data_B/data_width_A) + int(mixedRatio*row_index_B)
            
            lsb_data_A  =   int(lsb_data_B%data_width_A)
            msb_data_A  =   int(msb_data_B%data_width_A)
            
            byteen_index =  int(lsb_data_A/group_data_width_A)
            
            row[2]  = msb_data_A
            row[3]  = lsb_data_A
            
            row[5] = row_index_A
            row[6] = row_index_A
            row[7] = row_index_A
            row[8] = byteen_index
             
            #lsb_data_A   = current_data_ptr
            #
            #msb_data_A   = current_data_ptr + primitive_dataA
            #
            #
            #if(msb_data_A>= data_width_A):
            #    msb_data_A = data_width_A
            #          
            #row[2]  = msb_data_A-1
            #row[3]  = lsb_data_A
            #
            #row[5] = row_index
            #row[6] = row_index
            #row[7] = row_index
            #row[8] = byteen_index
            #
            #
            #current_data_ptr += primitive_dataA
            #if(current_data_ptr>= data_width_A):
            #    current_data_ptr = 0
            #    group_data_ptr = 0
            #    byteen_index = 0
            #    row_index += 1
            #
            #else: 
            #    group_data_ptr += primitive_dataA
            #    if (group_data_ptr >= group_data_width_A):
            #        group_data_ptr = 0
            #        byteen_index += 1;

        print("Mapping ", address_width_A, data_width_A, address_width_B, data_width_B)
        mapping_mux_wen(address_width_A, data_width_A, address_width_B, data_width_B)
        
        in_addr_width_a = address_width_A
        in_data_width_a = data_width_A
        in_addr_width_b = address_width_B
        in_data_width_b = data_width_B    
        
        if (group_data_width_A != 0):
            byteen_width_A = int(data_width_A / group_data_width_A)
            if (byteen_width_A ==0):
            	byteen_width_A = int(1)
        
        if (group_data_width_B != 0):
            byteen_width_B = int(data_width_B / group_data_width_B)
            if (byteen_width_B ==0):
            	byteen_width_B = int(1)
            
        actual_size_A = pow(2,address_width_A)  
        if size_A != 0:
            if size_A <= actual_size_A:
                actual_size_A = size_A
    
        actual_size_B = pow(2,address_width_B)  
        if size_B != 0:
            if size_B <= actual_size_B:
                actual_size_B = size_B
                
                
        print("PortA: ", in_addr_width_a, in_data_width_a, actual_size_A, group_data_width_A, byteen_width_A)
        print("PortB: ", in_addr_width_b, in_data_width_b, actual_size_B, group_data_width_B, byteen_width_B)         
                
                

def generate_memFile(loc_gen, userFile, address_width_A, data_width_A, group_data_width, address_width_B, data_width_B, port, format):
	
	memFile = open(loc_gen+"/init_hex.mem",'w')
	userMem = open(userFile,'r')
	InString = userMem.read()
	print(InString, file=memFile, sep='')
	read_hex_file(address_width_A, data_width_A, group_data_width, address_width_B, data_width_B, port, format, InString)
	userMem.close()
	memFile.close()

def generate_zero_memFile(loc_gen, userFile, address_width_A, data_width_A, group_data_width, address_width_B, data_width_B, port, format):
	
	hex_dwidth = math.ceil(data_width_A/4)
	with open(loc_gen+"/init_hex.mem",'w') as memFile:
		for _ in range(1<<address_width_A):
			n_hex = 0
			n = '{:0>{}x}'.format(n_hex, hex_dwidth)
			print(n, file=memFile, sep='')
	memFile.close()
			
			

def read_hex_file(address_width_A, data_width_A, group_data_width, address_width_B, data_width_B, port, in_format, InString):
	
	if port == 1:
		data_width = data_width_A
		addr_width = address_map_table( address_mapping_table_A, address_width_A)
		
	elif port == 2:
		data_width = data_width_B
		addr_width = address_map_table( address_mapping_table_B, address_width_B)
		
	for y in range(0,2 ** addr_width):
		column = list()
		for x in range(0,data_width):
			column.append(0)
		mem_table.append(column)
	
	
	dump2memTable(InString, in_format, port, data_width, addr_width)
	
	
def dump2memTable(InString,in_format, port, data_width, addr_width):
    ProcesseData = remove_comments(InString)
    
    #print( in_format, in_data_width, in_addr_width)
    
    #print(ProcesseData)  

    lines = ProcesseData.split()    


    address_mapping_table_A

    #print(lines)
    
    bit_count = 1 
    
    if (in_format == 1): #hex
        bit_count = 4
    
    line_ptr = 0
    for line in lines:
        if  (line_ptr+1) > (2**addr_width):
            break
        
        bit_ptr = 0
        
        for bits in reversed(line): 
        
            if (bit_ptr+1) > data_width: 
                break
            
            value = int(bits, 16)
            
            
            for x in range(0,bit_count):
            #    print ( line_ptr, bit_ptr)
                if (bit_ptr+1) > data_width: 
                    break
            
                mem_table[addr_table[line_ptr]][bit_ptr] = (value % 2)
                
                value = int(value / 2)
                bit_ptr = bit_ptr + 1
                
        #print(mem_table[line_ptr])
        line_ptr = line_ptr+1
        
        
    #print(mem_table)
    create_memory_init_file(str(loc_gen), port,data_width, addr_width )
    
def create_memory_init_file(loc_gen, port, data_width, addr_width ):
    f = open(loc_gen+"/bram_ini.vh", "w")
   
    line  = '\n'
    line += 'function [255:0] bram_ini_table;\n'
    line += 'input integer index;//Mode type \n'
    line += 'input integer val_; //Port A index, Port B Index, Number of Items in Loop, Port A Start, Port B Start, reserved \n'
    line += 'case (index)\n'
    f.write (line)
    y = 0 
    
    for row in bram_mapping_table:
       
        line = ""   
        x = 0
        
        line += '%4s: bram_ini_table=\n' %(y)
    
        index_primitive_row    = row[0]
        index_primitive_column = row[1]

        DataA_MSB              = row[2]
        DataA_LSB              = row[3]
        DataA_REPEAT           = row[4]
        DataA_RdMux            = row[5]
        
        DataB_MSB              = row[9]
        DataB_LSB              = row[10]
        DataB_REPEAT           = row[11]
        DataB_RdMux            = row[12]
        
        
        primitive_addrW_A       = row[16] 
        primitive_dataW_A       = row[17] 
        primitive_addrW_B       = row[18] 
        primitive_dataW_B       = row[19]
        
        maptable = list()
        
        if port == 1: #PORT_A
            maptable = create_primitive_map(data_width, addr_width, primitive_addrW_A, primitive_dataW_A, DataA_MSB, DataA_LSB, DataA_REPEAT, in_data_width_b, primitive_dataW_B, DataA_RdMux)
            
        
        elif port == 2: #PORT_B
            maptable = create_primitive_map(data_width, addr_width, primitive_addrW_B, primitive_dataW_B, DataB_MSB, DataB_LSB, DataB_REPEAT, in_data_width_a, primitive_dataW_A, DataB_RdMux)
           
        
      
      
        stringline = ""
        
        for Values in maptable:
            stringline ="256'h"    
            for value in Values: 
                stringline +=  '%02x' % (value)
      
            line += '(val_==%2s)?' % (x)
            line += stringline
            line += ":\n"
            x = x + 1
        line += '0;\n'    
        f.write (line)        

          
        #stringline ="256'h"
        #for hexChar in range(0,32):
        #   #stringline +=  '%02x' % (y)
        #   stringline +=  '%02x' % (0)
        #
        #
        #for x in range(0,  40):
        #    #line += '(val_==' + str(x) + ')?' + str(feature) + ':'
        #    line += '(val_==%2s)?' % (x)
        #    
        #    line += stringline
        #   #line += "256'h0000000000000000000000000000000000000000000000000000000000000000"
        #    
        #    line += ":\n"
        #    x = x + 1
        #line += '0;\n'
        #f.write (line)
        
        
        
        y = y +1
    
    
    line =  ""   
    line += "   endcase\n"
    line += "endfunction  \n"
    f.write (line)
    
    
    
    
    f.close()  
    
def address_map_table( in_address_map, in_addr_width):

#    addr_table = list()
    Map_count = int(0) 
    
   
    for y in in_address_map:
        Map_count = Map_count+1
    
   
    
    if Map_count!=0:
        for y in range(0,2 ** Map_count):
            
            BitMask     = int(1) 
            MappedAddr  = int(0)
            for mapbit in in_address_map:
                
                if(  y & BitMask   ):
                    MappedAddr = MappedAddr + (2** mapbit)
                BitMask = BitMask *2
                
            addr_table.append(MappedAddr)
                
        
    else:
        for y in range(0,2 ** in_addr_width):
            addr_table.append(y)
        Map_count = in_addr_width

    return Map_count
    
def create_primitive_map(data_width, addr_width, primitive_addr_width, primiive_data_width, map_data_msb, map_data_lsb, repeat, interval, interval_primitive, row_index):
    
    #print(data_width, addr_width, primitive_addr_width,  primiive_data_width, map_data_msb, map_data_lsb, repeat, row_index) 
    #print(data_width, addr_width, primitive_addr_width, primiive_data_width, map_data_msb, map_data_lsb, repeat, interval, row_index)    
    
    primitive_mem = list()
    
    #initial primitive memory profile
    for y in range(0,(2**primitive_addr_width)):
        row = list() 
        for x in range(0,primiive_data_width): 
            row.append(int(0))
        primitive_mem.append(row)
    
    
    primitive_y = int(0)
    primitive_x = int(0)
    
    addr_start = row_index    * (2**primitive_addr_width)
    addr_End   = (row_index+1)* (2**primitive_addr_width) -1
    
    #print(addr_start, addr_End, primiive_data_width, map_data_lsb,map_data_msb  )
    
    if(addr_End > (2**addr_width)-1):
        addr_End = (2**addr_width)-1

     
    
    for y in range(addr_start, addr_End+1  ):
        init_row = mem_table[y]
      
        primitive_x = int(0)
        if repeat == 0:
            for x in range(map_data_lsb, map_data_msb +1 ) :
                if (primitive_x+1) > primiive_data_width:
                    break
                
                primitive_mem[primitive_y][primitive_x] = init_row[x]
                primitive_x = primitive_x+1
                
            #if (map_data_lsb == 10 ):
            #    print (y, primitive_y,primitive_x, primitive_mem[primitive_y], init_row, map_data_lsb,( map_data_msb-map_data_lsb) +1 )
        else: 
            for r_x in range(0,repeat):  
                primitive_x = int(0)
                temp_data_lsb = map_data_lsb + (interval * r_x)   
                temp_data_msb = map_data_msb + (interval * r_x)
                #print (temp_data_lsb, temp_data_msb ,primiive_data_width, interval, interval_primitive)
                for x in range(temp_data_lsb, temp_data_msb +1 ) :
                    if (primitive_x+1) > primiive_data_width:
                        break
                    
                    primitive_mem[primitive_y][primitive_x+interval_primitive*r_x] = init_row[x]
                    primitive_x = primitive_x+1
            #print(primitive_mem[primitive_y])
        primitive_y = primitive_y+1
        
   
        
    #print(primitive_mem)    
    converted_init_mem = list()
       
    #initial primitive init profile    
    for y in range(0,40):
        row =list()
        for x in range(0,32): 
            row.append(int(0))
        converted_init_mem.append(row)


    #initial primitive memory profile
    
    primitive_bit_ptr = int(0)
    primitive_byte    = int(0)
    
    primitive_x_ptr   = int(31)
    primitive_y_ptr   = int(0)
    
    
    for y in range(0,(2**primitive_addr_width)): 
        for x in range(0,primiive_data_width): 
            primitive_byte = primitive_byte + primitive_mem[y][x] * (2** primitive_bit_ptr)
            
            primitive_bit_ptr = primitive_bit_ptr + 1
            if primitive_bit_ptr >= 8:
                converted_init_mem[primitive_y_ptr][primitive_x_ptr]  = primitive_byte
                primitive_bit_ptr = 0
                primitive_byte = 0
                
                primitive_x_ptr = primitive_x_ptr-1
                if primitive_x_ptr < 0:
                    primitive_x_ptr = 31
                    
                    primitive_y_ptr = primitive_y_ptr +1
                    if primitive_y_ptr >= 40:
                        break   


    return  converted_init_mem  
    
if __name__ == "__main__":
	
    parser = argparse.ArgumentParser(description='Memory Decompose to BRAM')
    parser.add_argument("memory_type", choices=['SP_RAM', 'SDP_RAM', 'TDP_RAM', 'SP_ROM', 'DP_ROM'], help="Memory type")
    parser.add_argument("address_width_A", help="Address Width Port A")
    parser.add_argument("data_width_A",    help="Data Width Port A")
    parser.add_argument("--address_width_B", default='0', help="address width of Port B")
    parser.add_argument("--data_width_B"   , default='0', help="data width of Port B")
    parser.add_argument("--device_family",      choices=['TRION', 'TITANIUM'], default='TITANIUM', help="Device family (SVF only).Default=TITANIUM")
    parser.add_argument("--memory_mode",   choices=['AREA', 'SPEED'], default='SPEED',      help="Memory decompose mode. Default=SPEED")
    parser.add_argument("--ByteEnable", choices=['1', '0'], default='0', help="Byte enable to mask off certain data input. If 0, it will disable byte enable. Default=0")
    parser.add_argument("--ByteEnable_A", choices=['1', '0'], default='0', help="Byte enable to mask off certain data input on TDPRAM-PortA. If 0, it will disable byte enable. Default=0")
    parser.add_argument("--ByteEnable_B", choices=['1', '0'], default='0', help="Byte enable to mask off certain data input on TDPRAM-PortB. If 0, it will disable byte enable. Default=0")
    parser.add_argument("--write_mode",  choices=['READ_FIRST', 'WRITE_FIRST', 'READ_UNKNOWN'], default='READ_FIRST',help="WRITE_MODE for memory content Behavior.Default=READ_FIRST")
    parser.add_argument("--write_mode_A",  choices=['READ_FIRST', 'WRITE_FIRST', 'NO_CHANGE'], default='READ_FIRST',help="WRITE_MODE for memory content Behavior.Default=READ_FIRST")
    parser.add_argument("--write_mode_B",  choices=['READ_FIRST', 'WRITE_FIRST', 'NO_CHANGE'], default='READ_FIRST',help="WRITE_MODE for memory content Behavior.Default=READ_FIRST")
    parser.add_argument("--userMemInitEnable", choices=['1', '0'], default='0', help="Enable User-defined Memory Initialization.Default=0")
    parser.add_argument('--userMemInitFilePath', default="./", help='User Memory Init File Path', required='--userMemInitEnable' in sys.argv)
    parser.add_argument('--out_path', help='Output Folder Path. Please create different directory for different configurations', required=True)
    
    args = parser.parse_args()
    
    print(args.out_path)
    
    #parser = argparse.ArgumentParser()
    #parser.add_argument('--user_project_path', help='User Project Path', required=True)
    #parser.add_argument('--parameters', 
    #                        metavar="KEY=VALUE",
    #                        nargs="+",
    #                        help='Key-Value Pair for resolved parameters from the IPXACT'
    #                        "(do not put spaces before or after the = sign). "
    #                        "If a value contains spaces, you should define "
    #                        "it with double quotes: "
    #                        'foo="this is a sentence". Note that '
    #                        "values are always treated as strings."
    #                        , required=True)
    #args = parser.parse_args()
    #
    #params = parse_parameters(args.parameters)
    #
    ## Add "{ }" to each param items
    #params_new = {}
    #for field, value in params.items():
    #        key = "{" + field + "}"
    #        params_new[key] = value.strip('"')
    #params = params_new
    
    #make destination folder
    loc = Path(args.out_path)
    loc_gen=Path(loc)
    #loc_user = Path(args.user_project_path, args.gen_name)
    loc_script = Path(__file__).parent.absolute()
    project_path = loc.parents[0]
    userFile=args.userMemInitFilePath.strip('"')
            
    #memory_type = str(params['{ARGS.MEMORY_TYPE}'])
    #device_family = str(params['{FAMILY}'])
    #memory_mode = str(params['{MEMORY_MODE}'])
    #write_mode = str(params['{WRITE_MODE}'])
    #size = int(params['{MEMORY_SIZE}'])        
    #address_width_A = int(params['{ADDR_WIDTH_A}'])
    #address_width_B = int(params['{ADDR_WIDTH_B}'])
    #data_width_A = int(params['{DATA_WIDTH_A}'])
    #data_width_B = int(params['{DATA_WIDTH_B}'])
    #group_data_width = int(params['{GROUP_DATA_WIDTH}'])
    #group_data_width_A = int(params['{GROUP_DATA_WIDTH_A}'])
    #group_data_width_B = int(params['{GROUP_DATA_WIDTH_B}'])
    ##byteen_width = int(params['{BYTEEN_WIDTH}'])
    ##byteen_width_A = int(params['{BYTEEN_WIDTH_A}'])
    ##byteen_width_B = int(params['{BYTEEN_WIDTH_B}'])
    #userMemInit=int(params['{HexFile_PathEnable}'])
    # If hex_path is absolute, change to relative path
    #if args.userMemInitPath.strip('"').is_absolute():
    #	args.out_path = os.path.relpath(args.userMemInitPath.strip('"'),project_path)
    #userFile=os.path.join(str(project_path), str(args.userMemInitPath.strip('"')))
    #port=int(params['{Port_Init}'])
    #format=int(params['{Format_Init}'])
    #ByteEnable = int(params['{BYTEEN_ENABLE}'])
    #ByteEnable_A = int(params['{BYTEENA_ENABLE}'])
    #ByteEnable_B = int(params['{BYTEENB_ENABLE}'])
    
    port = 1
    format = 1
    size = 0
  
    
    #Memory Selection
    if args.memory_type == "SP_RAM":
        print("Single_port_RAM")
        
        if args.write_mode == "NO_CHANGE":
        	print("\nABORT! BRAM don't support 'NO_CHANGE' write_mode in Single port RAM\n" )
        	sys.exit()

#Dragon 20250530        	
#        if (args.write_mode_A != "READ_FIRST") | (args.write_mode_B != "READ_FIRST"):
        if (args.write_mode_A != args.write_mode_B):
            print(args.write_mode_A)
            print(args.write_mode_B)

            print("\nABORT! Single Port RAM dont support mixed Write Mode.\n")
            sys.exit()
        
        if args.ByteEnable == '0':
        	group_data_width = 0
        else:
        	group_data_width = 8
        	
        if (args.ByteEnable_A != '0') | (args.ByteEnable_B != '0'):
        	print("\nABORT! Single Port RAM dont support Dual-port. Please use --ByteEnable.\n")
        	sys.exit()
        
        #if write_mode == 0:
        #	write_mode = "READ_FIRST"
        #elif write_mode == 1:
        #	write_mode = "WRITE_FIRST"
        #else:
        #	write_mode = "READ_UNKNOWN"
        
        if args.device_family == "TRION": #Trion
        	bram_feature_table = EFX_RAM_5K_feature_table
        	FAMILY = 0
        else: #Titanium/Topaz/etc
        	bram_feature_table = EFX_RAM10_feature_table
        	FAMILY = 1
        	
        temp_data_width_A = int(args.data_width_A)
        temp_address_width_A = int(args.address_width_A)
        
        temp_data_width_B = int(args.data_width_A)
        temp_address_width_B = int(args.address_width_A)
        
        if (int(args.data_width_B) !=0 ):
        	temp_data_width_B = int(args.data_width_B)
        if (int(args.address_width_B) !=0 ):
        	temp_address_width_B = int(args.address_width_B)
        	
        if (temp_data_width_A != temp_data_width_B) | (temp_address_width_A != temp_address_width_B ):
        	print("\nABORT! Single Port RAM don't support Mixed Width Mode.\n ")
        	sys.exit()
        else:
        	if args.memory_mode == "SPEED": #Speed
        		create_decompose_table_scan_row_mwm(int(args.address_width_A), int(args.data_width_A), int(size), int(group_data_width), int(args.address_width_B), int(args.data_width_B), int(group_data_width))
        	elif args.memory_mode == "AREA": #Area
        		create_decompose_table_scan_col(int(args.address_width_A), int(args.data_width_A), int(size), int(group_data_width), int(args.address_width_B), int(args.data_width_B))
        		byteen_width_A = byteen_width
        		byteen_width_B = byteen_width
        		
        #group_dataw_width = int(args.group_data_width)
        group_data_width = int(group_data_width)
        
        if (int(group_data_width_A)==0):
        	group_data_width_A = group_data_width
        else:
        	group_data_width_A = int(group_data_width_A)
        	
        	
        if (int(group_data_width_B)==0):
        	group_data_width_B = group_data_width
        else:
        	group_data_width_B = int(group_data_width_B)
        	
        if (group_data_width==0):
        	group_data_width = in_data_width_a
        	
        if (group_data_width_A==0):
        	group_data_width_A = in_data_width_a
        elif(group_data_width_A > in_data_width_a):
        	group_data_width_A = in_data_width_a
        
        if (group_data_width_B==0):
        	group_data_width_B = in_data_width_b
        elif(group_data_width_B > in_data_width_b):
        	group_data_width_B = in_data_width_b
        
        #Memory File Initialization
        if args.userMemInitEnable == '1': #Initialize memory
        	generate_memFile(str(loc_gen), str(userFile), int(args.address_width_A), int(args.data_width_A), int(group_data_width), int(args.address_width_B), int(args.data_width_B), int(port), int(format))
        	
        elif args.userMemInitEnable == '0': #Didnt initialize memory
        	generate_zero_memFile(str(loc_gen), str(userFile), int(args.address_width_A), int(args.data_width_A), int(group_data_width), int(args.address_width_B), int(args.data_width_B), int(port), int(format))
        	create_memory_initial_file(str(loc_gen))
        	
        create_decompose_file(str(loc_gen))
        
    #Memory Selection
    elif args.memory_type == "SDP_RAM":
    	print("Simple_Dual-port_RAM")
    	if args.write_mode == "NO_CHANGE":
    		print("\nABORT! BRAM don't support 'NO_CHANGE' write_mode in Simple Dual-port RAM\n" )
    		sys.exit()

#Dragon 20250530
#    	if (args.write_mode_A != "READ_FIRST") | (args.write_mode_B != "READ_FIRST"):   		
    	if (args.write_mode_A != args.write_mode_B ):

    		print(args.write_mode_A)
    		print(args.write_mode_B)
    		
    		print("\nABORT! Simple Dual-Port RAM dont support mixed Write Mode!\n")
    		sys.exit()
    		
    	if args.ByteEnable == '0':
    		group_data_width = args.data_width_A
    		group_data_width_A = args.data_width_A
    		group_data_width_B = args.data_width_A
    	else:
    		group_data_width = 8
    		group_data_width_A = 8
    		group_data_width_B = 8
    		
    	if args.ByteEnable_A != '0':
    		print("\nABORT! Simple Dual-port RAM cannot support mixed Byte Enable!\n")
    		sys.exit()
    		
    	if args.ByteEnable_B != '0':
    		print("\nABORT! Simple Dual-port RAM cannot support mixed Byte Enable!\n")
    		sys.exit()
    		
    	if args.data_width_B == '0':
    		data_width_B = args.data_width_A
    	else:
    		data_width_B = args.data_width_B
    		
    	if args.address_width_B == '0':
    		address_width_B = args.address_width_A
    	else:
    		address_width_B = args.address_width_B
    	
    	#if write_mode == 0:
    	#	write_mode = "READ_FIRST"
    	#elif write_mode == 1:
    	#	write_mode = "WRITE_FIRST"
    	#else:
    	#	write_mode = "READ_UNKNOWN"
    	
    	if args.device_family == "TRION": #Trion
    		bram_feature_table = EFX_RAM_5K_feature_table
    		FAMILY = 0
    	else: #Titanium/Topaz/etc
    		bram_feature_table = EFX_RAM10_feature_table
    		FAMILY = 1
    		
    	#if (int(group_data_width_B)!=0):
    	#	print("Simple dual port ram don't support group_data_width_B (byte enable on Read port ")
    	#	sys.exit()
    		
    		
    	if (int(group_data_width) >= int(args.data_width_A)) | (int(group_data_width_A) >= int(args.data_width_A)):
    		group_data_width = "0"
    		group_data_width_A = "0"
    		group_data_width_B = "0"
    		
    	if (int(args.data_width_B) !=0):
    		if (int(group_data_width) > int(args.data_width_B)):
    			print("\nABORT! BRAM dont support group_data_width > data_width_B!\n")
    			sys.exit()
    			
    			
    	if ((int(args.data_width_B) == 0)|(int(args.data_width_A) == int(args.data_width_B))) & ((int(args.address_width_B) == 0)|(int(args.address_width_A) == int(args.address_width_B))):
    		if args.memory_mode == "SPEED": #Speed
    			if (int(args.ByteEnable) == 0) & (int(args.ByteEnable_A) == 0) & (int(args.ByteEnable_B) == 0):
    				create_decompose_table_scan_row_mwm(int(args.address_width_A), int(args.data_width_A), int(size), int(group_data_width), int(address_width_B), int(data_width_B), int(group_data_width))
    			else:
    				print("Byte Enable Mode!")
    				create_decompose_table_scan_row_mwm_byteEn(int(args.address_width_A), int(args.data_width_A), int(size), int(group_data_width), int(address_width_B), int(data_width_B), int(group_data_width_A), int(group_data_width_B))
    				byteen_width = byteen_width_A
    			
    		elif args.memory_mode == "AREA": #Area
    			create_decompose_table_scan_col(int(args.address_width_A), int(args.data_width_A), int(size), int(group_data_width), int(address_width_B), int(data_width_B))
    			byteen_width_A = byteen_width
    			byteen_width_B = byteen_width
    			
    	else:
    		print("Mixed Width Mode is Enabled")
    		print(args.device_family, args.write_mode)
    		if args.device_family == "TRION": #Trion
    			bram_feature_table = EFX_RAM_5K_MWM_feature_table
    			FAMILY = 0
    		else: #Titanium/Topaz/etc
    			bram_feature_table = EFX_RAM10_MWM_feature_table
    			FAMILY = 1
    			
    		if args.memory_mode == "AREA": #Area
    			print("\nABORT! Area Mode don't support Mixed Width Case\n")
    			sys.exit()
    		elif args.memory_mode == "SPEED": #Speed
    			print("Speed Mode")
    			if (int(args.ByteEnable) == 0) & (int(args.ByteEnable_A) == 0) & (int(args.ByteEnable_B) == 0):
    				if (args.device_family != "TRION") & (args.write_mode == "WRITE_FIRST"): #Titanium/Topaz/etc dont support WRITE_FIRST
    					print("\nABORT! The configuration is not supported with WRITE_FIRST Mode\n")
    					sys.exit()
    					
    					#create_decompose_table_scan_row_mwm_stack(int(address_width_A), int(data_width_A), int(size), int(group_data_width), int(address_width_B), int(data_width_B), int(group_data_width_A), int(group_data_width_B))
    				else:
    					print("2nd check: group_data_width = " +str(group_data_width))
    					create_decompose_table_scan_row_mwm(int(args.address_width_A), int(args.data_width_A), int(size), int(group_data_width), int(address_width_B), int(data_width_B), int(group_data_width))
    					
    				
    			else:
    				print("Byte Enable Mode")
    				create_decompose_table_scan_row_mwm_byteEn(int(args.address_width_A), int(args.data_width_A), int(size), int(group_data_width), int(address_width_B), int(data_width_B), int(group_data_width_A), int(group_data_width_B))
    				byteen_width = byteen_width_A
    				
    				
    	#group_data_width = int(args.group_data_width)
    	#group_data_width = int(group_data_width)
    	
    	if (int(group_data_width_A) ==0):
    		group_data_width_A = group_data_width
    	else:
    		group_data_width_A = int(group_data_width_A)
    		
    	if (int(group_data_width_B) == 0 ):
    		group_data_width_B = group_data_width
    	else:
    		group_data_width_B = int(group_data_width_B)
    		
    	
    	if (int(group_data_width) == 0):
    		group_data_width = in_data_width_a
    		
    	if (int(group_data_width_A) == 0):
    		group_data_width_A = in_data_width_a
    	elif (int(group_data_width_A) > in_data_width_a):
    		group_data_width_A = in_data_width_a
    		
    	if (int(group_data_width_B) ==0):
    		group_data_width_B = in_data_width_b
    	elif (int(group_data_width_B) > in_data_width_b):
    		group_data_width_B = in_data_width_b
    		
    		
    	#Memory File Initialization
    	if args.userMemInitEnable == '1': #Initialize memory
    		generate_memFile(str(loc_gen), str(userFile), int(args.address_width_A), int(args.data_width_A), int(group_data_width), int(address_width_B), int(data_width_B), int(port), int(format))
    		
    	elif args.userMemInitEnable == '0': #Didnt initialize memory
    		generate_zero_memFile(str(loc_gen), str(userFile), int(args.address_width_A), int(args.data_width_A), int(group_data_width), int(address_width_B), int(data_width_B), int(port), int(format))
    		create_memory_initial_file(str(loc_gen))
    		
    	create_decompose_file(str(loc_gen))
    	
    	
    #Memory Selection
    elif args.memory_type == "TDP_RAM":
    	print("True_Dual-port_RAM")
    	
    	if (args.write_mode_A == "READ_UNKNOWN") | (args.write_mode_B == "READ_UNKNOWN") :
        	print("\nABORT! BRAM don't support 'READ_UNKNOWN' write_mode in True Dual-port RAM\n" )
        	sys.exit()
        	
    	if (args.write_mode != "READ_FIRST"):
        	print("\nABORT! Please use --write_mode_A and --write_mode_B for True Dual-port RAM.\n")
        	sys.exit()
        #Dragon 20250218#	
    	if (args.data_width_B == '0'):
        	data_width_B = args.data_width_A
    	else:
        	data_width_B = args.data_width_B
		
    	if (args.address_width_B == '0'):
        	address_width_B = args.address_width_A  
    	else:
        	address_width_B = args.address_width_B

    	data_width_A    = args.data_width_A
    	address_width_A = args.address_width_A
			

    	if (  (int(args.ByteEnable_A) != 0) & (int(args.ByteEnable_B) != 0) ):
        	print("Byte Enable Mode (A & B)")
        	scan_group_width  = 8
        	group_data_width = 8
        	group_data_width_A = 8
        	group_data_width_B = 8
				
    	elif ((int(args.ByteEnable_A) != 0) & (int(args.ByteEnable_B) == 0) ):
        	print("Byte Enable Mode (A only) ")
        	scan_group_width  = 8
        	group_data_width = 8
        	group_data_width_A = 8
        	group_data_width_B = data_width_B
    	elif ((int(args.ByteEnable_A) == 0) & (int(args.ByteEnable_B) != 0) ):
        	print("Byte Enable Mode (B only) ")
        	scan_group_width  = 8
        	group_data_width = data_width_A
        	group_data_width_A = data_width_A
        	group_data_width_B = 8

    	else:
        	scan_group_width  = 0            
        	group_data_width = data_width_A
        	group_data_width_A = data_width_A
        	group_data_width_B = data_width_B

        	

    	
    	if args.device_family == "TRION": #Trion
    		bram_feature_table = EFX_DPRAM_5K_feature_table
    		FAMILY = 0
    	else: #Titanium/Topaz/etc
    		bram_feature_table = EFX_DPRAM10_feature_table
    		FAMILY = 1
    #Dragon 20250203#	if (int(args.ByteEnable_B == 0)|(args.data_width_A==args.data_width_B)) & ((args.address_width_B == '0')|(args.address_width_A==args.address_width_B)):	
    	if ((args.data_width_B == 0)|(args.data_width_A==args.data_width_B)) & ((args.address_width_B == '0')|(args.address_width_A==args.address_width_B)):
    		if args.memory_mode == "SPEED": #Speed
    			print("SPEED Mode ")
    			if (int(args.ByteEnable_A) == 0) & (int(args.ByteEnable_B) == 0):
    				create_decompose_table_scan_row_mwm(int(args.address_width_A), int(args.data_width_A), int(size), int(group_data_width), int(args.address_width_B), int(args.data_width_B), int(group_data_width))
    			else:
    				print("Byte Enable Mode")
    				create_decompose_table_scan_row_mwm_byteEn(int(args.address_width_A), int(args.data_width_A), int(size), int(group_data_width), int(args.address_width_B), int(args.data_width_B), int(group_data_width_A), int(group_data_width_B))
    				byteen_width = byteen_width_A
    		elif args.memory_mode == "AREA": #Area
    			print("AREA Mode ")
    			create_decompose_table_scan_col(int(args.address_width_A), int(args.data_width_A), int(size), int(scan_group_width), int(args.address_width_B), int(args.data_width_B))
    			#Dragon 20250217 Updating Byten Enable was Disable
    			if (int(args.ByteEnable_A) == 0):
    				for row in bram_mapping_table:
                        		row[8] = 0;
    				byteen_width_A = 1
    			else:
    				byteen_width_A = byteen_width

    			if (int(args.ByteEnable_B) == 0):
    				for row in bram_mapping_table:
                        		row[15] = 0;
    				byteen_width_B = 1
    			else:
    				byteen_width_B = byteen_width
    			
    	else:
        	print("Mixed Width Mode is Enabled!")
        	
        	if args.device_family == "TRION": #Trion
        		bram_feature_table = EFX_DPRAM_5K_MWM_feature_table
        		FAMILY = 0
        	else: #Titanium/Topaz/etc
        		bram_feature_table = EFX_DPRAM10_MWM_feature_table
        		FAMILY = 1
        		
        	if args.memory_mode == "AREA": #Area
        		print("\nABORT! Area Mode don't support Mixed Width Case")
        		sys.exit()
        	elif args.memory_mode == "SPEED": #Speed
        		print("Speed Mode")
        		#print("GDW =" +str(group_data_width), " GDW_A = " +str(group_data_width_A), " GDW_B =  " +str(group_data_width_B))
        		if (int(args.ByteEnable_A) == 0) & (int(args.ByteEnable_B) == 0):
        			create_decompose_table_scan_row_mwm(int(args.address_width_A), int(args.data_width_A), int(size), int(group_data_width), int(args.address_width_B), int(args.data_width_B), int(group_data_width))
        		else:
        			print("Byte Enable Mode")
        			create_decompose_table_scan_row_mwm_byteEn(int(args.address_width_A), int(args.data_width_A), int(size), int(group_data_width), int(args.address_width_B), int(args.data_width_B), int(group_data_width_A), int(group_data_width_B))
        			byteen_width = byteen_width_A
    			
			
			#Dragon 20250313 Updating Byten Enable was Disable
   			
        		if (int(args.ByteEnable_A) == 0):
        			for row in bram_mapping_table:
        				row[8] = 0;
        			byteen_width_A = 1
        		else:
        			byteen_width_A = byteen_width

        		if (int(args.ByteEnable_B) == 0):
        			for row in bram_mapping_table:
        				row[15] = 0;
        			byteen_width_B = 1
        		else:
        			byteen_width_B = byteen_width
				
#Dragon 20250218 Updating Byten Enable was Disable 
    	if (int(args.ByteEnable_A) == 0):
    		#for row in bram_mapping_table:
               # 	row[8] = 0;
    		byteen_width_A = 1
    	else:
    		byteen_width_A = byteen_width

    	if (int(args.ByteEnable_B) == 0):
    	#	for row in bram_mapping_table:
               # 	row[15] = 0;
    		byteen_width_B = 1
    	else:
    		byteen_width_B = byteen_width
        #group_data_width = int(group_data_width)
    	
    	if (int(group_data_width_A) ==0):
    		group_data_width_A = int(group_data_width)
    	else:
    		group_data_width_A = int(group_data_width_A)
    		
    	if (int(group_data_width_B) == 0 ):
    		group_data_width_B = int(group_data_width)
    	else:
    		group_data_width_B = int(group_data_width_B)
    		
    	
    	if (group_data_width == 0):
    		group_data_width = 8
    		
    	if (group_data_width_A == 0):
    		group_data_width_A = in_data_width_a
    	elif (group_data_width_A > in_data_width_a):
    		group_data_width_A = in_data_width_a
    		
    	if (group_data_width_B ==0):
    		group_data_width_B = in_data_width_b
    	elif (group_data_width_B > in_data_width_b):
    		group_data_width_B = in_data_width_b
    		
    	#Memory File Initialization
    	if args.userMemInitEnable == '1': #Initialize memory
    		generate_memFile(str(loc_gen), str(userFile), int(args.address_width_A), int(args.data_width_A), int(group_data_width), int(args.address_width_B), int(args.data_width_B), int(port), int(format))
    		
    	elif args.userMemInitEnable == '0': #Didnt initialize memory
    		generate_zero_memFile(str(loc_gen), str(userFile), int(args.address_width_A), int(args.data_width_A), int(group_data_width), int(args.address_width_B), int(args.data_width_B), int(port), int(format))
    		create_memory_initial_file(str(loc_gen))
    		
    	create_decompose_file(str(loc_gen))
    	
    #Memory Selection
    elif args.memory_type == "SP_ROM":
        print("Single_port_ROM")
        
        if args.ByteEnable == '0':
        	ByteEnable_A = 0
        	ByteEnable_B = 0
        	group_data_width = 0
        	group_data_width_A = 0
        	group_data_width_B = 0
        else:
        	print("\nABORT! ROM dont support Byte Enable! \n")
        	sys.exit()
        
        #if ByteEnable == 0:
        #	group_data_width = 0
        #if ByteEnable_A == 0:
        #	group_data_width_A = 0
        #if ByteEnable_B == 0:
        #	group_data_width_B = 0
        
        if args.write_mode != "READ_FIRST":
        	print("\nABORT! Single Port ROM don't support other WRITE_MODE\n")
        	sys.exit()
        	
        if (args.write_mode_A != "READ_FIRST") | (args.write_mode_B != "READ_FIRST"):
        	print("\nABORT! Single Port ROM dont support other WRITE_MODE! \n")
        	sys.exit()
        
        if args.device_family == "TRION": #Trion
        	bram_feature_table = EFX_RAM_5K_feature_table
        	FAMILY = 0
        else: #Titanium/Topaz/etc
        	bram_feature_table = EFX_RAM10_feature_table
        	FAMILY = 1
        	
        temp_data_width_A = int(args.data_width_A)
        temp_address_width_A = int(args.address_width_A)
        
        temp_data_width_B = int(args.data_width_A)
        temp_address_width_B = int(args.address_width_A)
        
        if (int(args.data_width_B) !=0 ):
        	temp_data_width_B = int(args.data_width_B)
        if (int(args.address_width_B) !=0 ):
        	temp_address_width_B = int(args.address_width_B)
        	
        if (temp_data_width_A != temp_data_width_B) | (temp_address_width_A != temp_address_width_B ):
        	print("\nABORT! Single Port ROM don't support Mixed Width Mode.\n ")
        	sys.exit()
        else:
        	if args.memory_mode == "SPEED": #Speed
        		create_decompose_table_scan_row_mwm(int(args.address_width_A), int(args.data_width_A), int(size), int(group_data_width), int(args.address_width_B), int(args.data_width_B), int(group_data_width))
        	elif args.memory_mode == "AREA": #Area
        		create_decompose_table_scan_col(int(args.address_width_A), int(args.data_width_A), int(size), int(group_data_width), int(args.address_width_B), int(args.data_width_B))
        		byteen_width_A = byteen_width
        		byteen_width_B = byteen_width
        		
        #group_dataw_width = int(args.group_data_width)
        group_data_width = int(group_data_width)
        
        if (int(group_data_width_A)==0):
        	group_data_width_A = group_data_width
        else:
        	group_data_width_A = int(group_data_width_A)
        	
        	
        if (int(group_data_width_B)==0):
        	group_data_width_B = group_data_width
        else:
        	group_data_width_B = int(group_data_width_B)
        	
        if (group_data_width==0):
        	group_data_width = in_data_width_a
        	
        if (group_data_width_A==0):
        	group_data_width_A = in_data_width_a
        elif(group_data_width_A > in_data_width_a):
        	group_data_width_A = in_data_width_a
        
        if (group_data_width_B==0):
        	group_data_width_B = in_data_width_b
        elif(group_data_width_B > in_data_width_b):
        	group_data_width_B = in_data_width_b
        
        #Memory File Initialization
        if args.userMemInitEnable == '1': #Initialize memory
        	generate_memFile(str(loc_gen), str(userFile), int(args.address_width_A), int(args.data_width_A), int(group_data_width), int(args.address_width_B), int(args.data_width_B), int(port), int(format))
        	
        elif args.userMemInitEnable == '0': #Didnt initialize memory
        	generate_zero_memFile(str(loc_gen), str(userFile), int(args.address_width_A), int(args.data_width_A), int(group_data_width), int(args.address_width_B), int(args.data_width_B), int(port), int(format))
        	create_memory_initial_file(str(loc_gen))
        	
        create_decompose_file(str(loc_gen))
        
        
    #Memory Selection
    elif args.memory_type == "DP_ROM":
    	print("Dual-port_ROM")
    	
    	if (args.ByteEnable_A == '0') | (args.ByteEnable_B == '0'):
    		ByteEnable_A = 0
    		ByteEnable_B = 0
    		group_data_width = 0
    		group_data_width_A = 0
    		group_data_width_B = 0
    	else:
    		print("\n ABORT! ROM dont support Byte Enable!\n")
    		sys.exit()
    	
    	#if ByteEnable == 0:
    	#	group_data_width = 0
    	#if ByteEnable_A == 0:
    	#	group_data_width_A = 0
    	#if ByteEnable_B == 0:
    	#	group_data_width_B = 0
    	
    	if (args.write_mode_A != "READ_FIRST") | (args.write_mode_B != "READ_FIRST"):
    		print("\nABORT! Dual Port ROM don't support other WRITE_MODE\n")
    		sys.exit()
    		
    	if args.write_mode != "READ_FIRST":
    		print("\nABORT! Dual Port ROM dont support other WRITE_MODE\n")
    		sys.exit()
    	
    	if args.device_family == "TRION": #Trion
    		bram_feature_table = EFX_DPRAM_5K_feature_table
    		FAMILY = 0
    	else: #Titanium/Topaz/etc
    		bram_feature_table = EFX_DPRAM10_feature_table
    		FAMILY = 1
    		
    		
    	if ((group_data_width_B == 0)|(args.data_width_A==args.data_width_B)) & ((args.address_width_B == 0)|(args.address_width_A==args.address_width_B)):
    		if args.memory_mode == "SPEED": #Speed
    			if (int(args.ByteEnable) == 0) & (int(args.ByteEnable_A) == 0) & (int(args.ByteEnable_B) == 0):
    				create_decompose_table_scan_row_mwm(int(args.address_width_A), int(args.data_width_A), int(size), int(group_data_width), int(args.address_width_B), int(args.data_width_B), int(group_data_width))
    			else:
    				print("Byte Enable Mode")
    				create_decompose_table_scan_row_mwm_byteEn(int(args.address_width_A), int(args.data_width_A), int(size), int(group_data_width), int(args.address_width_B), int(args.data_width_B), int(group_data_width_A), int(group_data_width_B))
    				byteen_width = byteen_width_A
    		elif args.memory_mode == "AREA": #Area
    			create_decompose_table_scan_col(int(args.address_width_A), int(args.data_width_A), int(size), int(group_data_width), int(args.address_width_B), int(args.data_width_B))
    			byteen_width_A = byteen_width
    			byteen_width_B = byteen_width
    			
    	else:
        	print("Mixed Width Mode is Enabled!")
        	
        	if args.device_family == "TRION": #Trion
        		bram_feature_table = EFX_DPRAM_5K_MWM_feature_table
        		FAMILY = 0
        	else: #Titanium/Topaz/etc
        		bram_feature_table = EFX_DPRAM10_MWM_feature_table
        		FAMILY = 1
        		
        	if args.memory_mode == "AREA": #Area
        		print("\nABORT! Area Mode don't support Mixed Width Case\n")
        		sys.exit()
        	elif args.memory_mode == "SPEED": #Speed
        		print("Speed Mode")
        		if (int(args.ByteEnable) == 0) & (int(args.ByteEnable_A) == 0) & (int(args.ByteEnable_B) == 0):
        			create_decompose_table_scan_row_mwm(int(args.address_width_A), int(args.data_width_A), int(size), int(group_data_width), int(args.address_width_B), int(args.data_width_B), int(group_data_width))
        		else:
        			print("Byte Enable Mode")
        			create_decompose_table_scan_row_mwm_byteEn(int(args.address_width_A), int(args.data_width_A), int(size), int(group_data_width), int(args.address_width_B), int(args.data_width_B), int(group_data_width_A), int(group_data_width_B))
        			byteen_width = byteen_width_A
        

        #group_data_width = int(group_data_width)
    	
    	if (int(group_data_width_A) ==0):
    		group_data_width_A = int(group_data_width)
    	else:
    		group_data_width_A = int(group_data_width_A)
    		
    	if (int(group_data_width_B) == 0 ):
    		group_data_width_B = int(group_data_width)
    	else:
    		group_data_width_B = int(group_data_width_B)
    		
    	
    	if (group_data_width == 0):
    		group_data_width = 8
    		
    	if (group_data_width_A == 0):
    		group_data_width_A = in_data_width_a
    	elif (group_data_width_A > in_data_width_a):
    		group_data_width_A = in_data_width_a
    		
    	if (group_data_width_B ==0):
    		group_data_width_B = in_data_width_b
    	elif (group_data_width_B > in_data_width_b):
    		group_data_width_B = in_data_width_b
    		
    	#Memory File Initialization
    	if args.userMemInitEnable == '1': #Initialize memory
    		generate_memFile(str(loc_gen), str(userFile), int(args.address_width_A), int(args.data_width_A), int(group_data_width), int(args.address_width_B), int(args.data_width_B), int(port), int(format))
    		
    	elif args.userMemInitEnable == '0': #Didnt initialize memory
    		generate_zero_memFile(str(loc_gen), str(userFile), int(args.address_width_A), int(args.data_width_A), int(group_data_width), int(args.address_width_B), int(args.data_width_B), int(port), int(format))
    		create_memory_initial_file(str(loc_gen))
    		
    	create_decompose_file(str(loc_gen))
    
    
