"""SC03/CT01：只提取原164活动赋值，生成数据和一个RAM10的静态初始化。"""
import hashlib, json, pathlib, re
ROOT=pathlib.Path('D:/大三/FPGA_verilog/_fpga_edge_agent')
source=ROOT/'work/active/track4_ip_precheck_20261004/C2/rtl/cam_i2c_ctrl/i2c/i2c_master_reg_rom.v'
assert hashlib.sha256(source.read_bytes()).hexdigest().upper()=='DB13D1EED22A9478FD0AFFB9AC86B8265302A474886D7FFF688447AF2470FFE3'
rows=[]
for line in source.read_text(encoding='utf-8-sig').splitlines():
    m=re.match(r"\s*ROM\[8'h([0-9a-fA-F]+)\]\s*=\s*\{16'h([0-9a-fA-F]+),\s*8'h([0-9a-fA-F]+),1'b([01])\}",line)
    if m:rows.append(tuple(int(v,16) for v in m.groups()))
assert len(rows)==164 and [r[0] for r in rows]==list(range(164)) and all(r[3]==0 for r in rows)
assert rows[0][1:3]==(0x0100,0) and rows[144][1:3]==(0x0100,1) and rows[-1][1:3]==(0x3221,0x66)
verify=[(0x100,1,1),(0x3018,0x60,0xe0),(0x3031,0x0a,0xf),(0x3037,0x20,0x60),(0x303f,0,0x80),
        (0x3208,7,255),(0x3209,0x80,255),(0x320a,4,255),(0x320b,0x38,255),
        (0x3210,1,255),(0x3211,0x44,255),(0x3212,0,255),(0x3213,5,255),(0x3221,0x66,0x66)]
unit=ROOT/'work/active/track4_algorithms_20261004/sc431hai_config'
for folder in ('rtl','model','data','tb','scripts','project','docs','runs'):(unit/folder).mkdir(parents=True,exist_ok=True)
def fresh(relative,body):
    path=unit/relative;assert not path.exists();path.write_text(body,encoding='utf-8')
data=dict(source=str(source),source_sha256=hashlib.sha256(source.read_bytes()).hexdigest().upper(),
          writes=[dict(index=i,address=a,value=v) for i,a,v,_ in rows],
          verify=[dict(address=a,expected=v,mask=m) for a,v,m in verify],chip_id=0xcd6b,
          label='ORIGINAL_ORDER_DIGITAL_CONFIG_PROFILE_NOT_HARDWARE_ACCEPTANCE')
fresh('data/sc431hai_profile.json',json.dumps(data,ensure_ascii=False,indent=2))
pkg=['// SC03/CT01：公开字段、诊断编码；原表顺序另在实际RAM10。','package sc431hai_profile_pkg;',
     '    localparam integer WRITE_COUNT=164,VERIFY_COUNT=14;',
     '    localparam logic [7:0] NONE=0,BAD_FIELD=1,NACK=2,ARBITRATION=3,TIMEOUT=4,ID_MISMATCH=5,READBACK=6,PLATFORM=7,TAG_EXHAUSTED=8,PROTOCOL=9;',
     "    localparam logic [15:0] SENSOR_ID=16'hcd6b;"]
for name,bits,which in [('verify_address',16,0),('verify_expected',8,1),('verify_bits',8,2)]:
    pkg += [f'    function automatic logic [{bits-1}:0] {name}(input logic [3:0] index);','        case(index)']
    pkg += [f"            4'd{i}:{name}={bits}'h{v[which]:0{bits//4}x};" for i,v in enumerate(verify)]
    pkg += [f'            default:{name}=0;','        endcase','    endfunction']
pkg += ['endpackage','']
fresh('rtl/sc431hai_profile_pkg.sv','\n'.join(pkg))
words=[]
for _,a,v,_ in rows:
    body=(a<<8)|v;words += [body&0xfffff,body>>20]
packed=sum(word<<(i*20) for i,word in enumerate(words))
rom=['// SC03/CT01：一个512×20原语；两词组成reg16/value8。WE永0。',
     'module sc431hai_profile_rom(input wire clk,re,input wire [8:0] address,output wire [19:0] word_out);',
     '    EFX_RAM10 #(.READ_WIDTH(20),.WRITE_WIDTH(20),.OUTPUT_REG(1\'b0),.WRITE_MODE("READ_FIRST"),']
rom += [f"        .INIT_{i:X}(256'h{(packed>>(i*256))&((1<<256)-1):064x})"+(',' if i<39 else '') for i in range(40)]
rom += ["    ) ram(.WCLK(clk),.WE(2'b00),.WCLKE(1'b0),.WADDREN(1'b1),.WDATA(20'd0),.WADDR(9'd0),",
        "        .RCLK(clk),.RE(re),.RST(1'b0),.RADDREN(1'b1),.RDATA(word_out),.RADDR(address));",
        '    // synthesis translate_off',
        '    always @(posedge clk)if(re && address>=328)$fatal(1,"SC431 profile ROM address");',
        '    // synthesis translate_on','endmodule','']
fresh('rtl/sc431hai_profile_rom.sv','\n'.join(rom))
print('SC431: 164 original writes; 14 public checks; 328 native20bit words')
