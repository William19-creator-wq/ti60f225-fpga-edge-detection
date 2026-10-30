// Closed RDP and cyclic WHOLE-ARC pruning, microprogrammed storage variant.
// Two synchronous RAM read copies replace the wide per-state register muxes.
// One 32-bit add/sub datapath is shared by indices and address generation.
// No contour/vertex truncation. Public requests drain on cancel; unconfirmed
// drainage quarantines the contour buffer until reset. See program.json.
module shape_polygon_rdp #(
    parameter integer W=1920,H=1080,STACK_DEPTH=32,EXTERNAL_MATH=0
)(
    input wire clk,rst,cancel,
    input wire start_valid,output wire start_ready,
    input wire [95:0] start_scope,
    input wire [31:0] contour_base,
    input wire [21:0] contour_points,
    input wire [43:0] contour_box,
    output wire done_valid,input wire done_ready,
    output reg [95:0] done_scope,
    output reg [2:0] done_error,
    output reg [21:0] polygon_count,
    output wire polygon_four,
    output reg [43:0] polygon_x,polygon_y,
    output reg quarantined,output wire busy,
    output wire mem_req_valid,input wire mem_req_ready,
    output reg [31:0] mem_addr,mem_wdata,output reg [3:0] mem_wstrb,
    input wire mem_rsp_valid,output wire mem_rsp_ready,
    input wire [31:0] mem_rdata,input wire mem_error,mem_drained,
    output wire ext_valid,input wire ext_ready,
    output wire [127:0] ext_a,output wire [63:0] ext_b,
    output wire [95:0] ext_scope,output wire ext_cancel,
    input wire ext_result,output wire ext_consume,
    input wire [127:0] ext_value,input wire [95:0] ext_result_scope,
    input wire [1:0] ext_error
);
    localparam OP_NOP=0,OP_IMM=1,OP_MOV=2,OP_ADD=3,OP_SUB=4,OP_AND=5,OP_OR=6,OP_SHL2=7,OP_BEQ=8,OP_BNE=9,OP_BLT=10,OP_BGE=11,OP_JMP=12,OP_CALL=13,OP_RET=14,OP_READ=15,OP_WRITE=16,OP_VALID=17,OP_SETA=18,OP_SETB=19,OP_DIST=20,OP_MAXZERO=21,OP_MAXUPDATE=22,OP_BMAX=23,OP_BDIST=24,OP_PUSH=25,OP_POP=26,OP_COLLECT=27,OP_FINISH=28,OP_FAIL=29;
    localparam IDLE=0,INIT=1,FETCH=2,OPERANDS=3,EXECUTE=4,MREQ=5,MWAIT=6,
        DREQ=7,DWAIT=8,POP_WAIT=9,POP_LO=10,POP_HI=11,DONE=12,LOCKED=13;
    reg [3:0] state;
    reg [7:0] pc,return_pc;
    reg [63:0] instruction;
    (* syn_ramstyle="block_ram" *) reg [63:0] program_rom[0:255];
    initial begin
        program_rom[0]=64'h09f2000000000000;
        program_rom[1]=64'h34000000000000ad;
        program_rom[2]=64'h3db1000000000000;
        program_rom[3]=64'h440d000000000000;
        program_rom[4]=64'h480d000000000000;
        program_rom[5]=64'h4c0d000000000000;
        program_rom[6]=64'h09e3000000000000;
        program_rom[7]=64'h34000000000000ad;
        program_rom[8]=64'h3db1000000000000;
        program_rom[9]=64'h440d000000000000;
        program_rom[10]=64'h15cda80000000000;
        program_rom[11]=64'h09e3000000000000;
        program_rom[12]=64'h34000000000000ad;
        program_rom[13]=64'h4011700000000000;
        program_rom[14]=64'h500e000000000000;
        program_rom[15]=64'h58c3000000000000;
        program_rom[16]=64'h0c63980000000000;
        program_rom[17]=64'h2803000000000006;
        program_rom[18]=64'h0826000000000000;
        program_rom[19]=64'h09f2000000000000;
        program_rom[20]=64'h34000000000000ad;
        program_rom[21]=64'h3db1000000000000;
        program_rom[22]=64'h480d000000000000;
        program_rom[23]=64'h4c0d000000000000;
        program_rom[24]=64'h0873000000000000;
        program_rom[25]=64'h08d3000000000000;
        program_rom[26]=64'h5400000000000000;
        program_rom[27]=64'h09e3000000000000;
        program_rom[28]=64'h34000000000000ad;
        program_rom[29]=64'h3db1000000000000;
        program_rom[30]=64'h500d000000000000;
        program_rom[31]=64'h58c3000000000000;
        program_rom[32]=64'h0c63980000000000;
        program_rom[33]=64'h280300000000001b;
        program_rom[34]=64'h0846000000000000;
        program_rom[35]=64'h09f2000000000000;
        program_rom[36]=64'h34000000000000ad;
        program_rom[37]=64'h3db1000000000000;
        program_rom[38]=64'h19ada00000000000;
        program_rom[39]=64'h09f2000000000000;
        program_rom[40]=64'h34000000000000ad;
        program_rom[41]=64'h4011680000000000;
        program_rom[42]=64'h09e2000000000000;
        program_rom[43]=64'h34000000000000ad;
        program_rom[44]=64'h3db1000000000000;
        program_rom[45]=64'h19ada00000000000;
        program_rom[46]=64'h09e2000000000000;
        program_rom[47]=64'h34000000000000ad;
        program_rom[48]=64'h4011680000000000;
        program_rom[49]=64'h6402000000000000;
        program_rom[50]=64'h0892000000000000;
        program_rom[51]=64'h08a2000000000000;
        program_rom[52]=64'h0560000000000002;
        program_rom[53]=64'h0de4980000000000;
        program_rom[54]=64'h2c0f28000000005c;
        program_rom[55]=64'h09e4000000000000;
        program_rom[56]=64'h34000000000000ad;
        program_rom[57]=64'h3db1000000000000;
        program_rom[58]=64'h480d000000000000;
        program_rom[59]=64'h09e5000000000000;
        program_rom[60]=64'h34000000000000ad;
        program_rom[61]=64'h3db1000000000000;
        program_rom[62]=64'h4c0d000000000000;
        program_rom[63]=64'h0c64980000000000;
        program_rom[64]=64'h08c3000000000000;
        program_rom[65]=64'h5400000000000000;
        program_rom[66]=64'h09e3000000000000;
        program_rom[67]=64'h34000000000000ad;
        program_rom[68]=64'h3db1000000000000;
        program_rom[69]=64'h500d000000000000;
        program_rom[70]=64'h58c3000000000000;
        program_rom[71]=64'h0c63980000000000;
        program_rom[72]=64'h2803280000000042;
        program_rom[73]=64'h5c0000000000004b;
        program_rom[74]=64'h300000000000005c;
        program_rom[75]=64'h09e6000000000000;
        program_rom[76]=64'h34000000000000ad;
        program_rom[77]=64'h3db1000000000000;
        program_rom[78]=64'h19ada00000000000;
        program_rom[79]=64'h09e6000000000000;
        program_rom[80]=64'h34000000000000ad;
        program_rom[81]=64'h4011680000000000;
        program_rom[82]=64'h0d6b980000000000;
        program_rom[83]=64'h11e6200000000000;
        program_rom[84]=64'h1205300000000000;
        program_rom[85]=64'h2810780000000059;
        program_rom[86]=64'h6406280000000000;
        program_rom[87]=64'h08a6000000000000;
        program_rom[88]=64'h3000000000000035;
        program_rom[89]=64'h6404300000000000;
        program_rom[90]=64'h0886000000000000;
        program_rom[91]=64'h3000000000000035;
        program_rom[92]=64'h680000000000005e;
        program_rom[93]=64'h3000000000000035;
        program_rom[94]=64'h08f2000000000000;
        program_rom[95]=64'h05e0000000000004;
        program_rom[96]=64'h280b78000000009e;
        program_rom[97]=64'h2c0700000000009e;
        program_rom[98]=64'h09e7000000000000;
        program_rom[99]=64'h34000000000000ad;
        program_rom[100]=64'h3db1000000000000;
        program_rom[101]=64'h15eda00000000000;
        program_rom[102]=64'h200f90000000009c;
        program_rom[103]=64'h09cd000000000000;
        program_rom[104]=64'h0907000000000000;
        program_rom[105]=64'h240890000000006b;
        program_rom[106]=64'h0900000000000000;
        program_rom[107]=64'h1108980000000000;
        program_rom[108]=64'h0952000000000000;
        program_rom[109]=64'h09e8000000000000;
        program_rom[110]=64'h34000000000000ad;
        program_rom[111]=64'h3db1000000000000;
        program_rom[112]=64'h15eda00000000000;
        program_rom[113]=64'h240f900000000078;
        program_rom[114]=64'h2c0a0000000000ac;
        program_rom[115]=64'h2408900000000075;
        program_rom[116]=64'h0900000000000000;
        program_rom[117]=64'h1108980000000000;
        program_rom[118]=64'h0d4a980000000000;
        program_rom[119]=64'h300000000000006d;
        program_rom[120]=64'h480d000000000000;
        program_rom[121]=64'h0d27980000000000;
        program_rom[122]=64'h280900000000007c;
        program_rom[123]=64'h0932000000000000;
        program_rom[124]=64'h0952000000000000;
        program_rom[125]=64'h09e9000000000000;
        program_rom[126]=64'h34000000000000ad;
        program_rom[127]=64'h3db1000000000000;
        program_rom[128]=64'h15eda00000000000;
        program_rom[129]=64'h240f900000000088;
        program_rom[130]=64'h2c0a0000000000ac;
        program_rom[131]=64'h0d29980000000000;
        program_rom[132]=64'h2809000000000086;
        program_rom[133]=64'h0932000000000000;
        program_rom[134]=64'h0d4a980000000000;
        program_rom[135]=64'h300000000000007d;
        program_rom[136]=64'h4c0d000000000000;
        program_rom[137]=64'h0c68980000000000;
        program_rom[138]=64'h08a9000000000000;
        program_rom[139]=64'h280848000000008d;
        program_rom[140]=64'h0ca9000000000000;
        program_rom[141]=64'h2c03280000000095;
        program_rom[142]=64'h09e3000000000000;
        program_rom[143]=64'h34000000000000ad;
        program_rom[144]=64'h3db1000000000000;
        program_rom[145]=64'h500d000000000000;
        program_rom[146]=64'h600000000000009c;
        program_rom[147]=64'h0c63980000000000;
        program_rom[148]=64'h300000000000008d;
        program_rom[149]=64'h15cea80000000000;
        program_rom[150]=64'h09e7000000000000;
        program_rom[151]=64'h34000000000000ad;
        program_rom[152]=64'h4011700000000000;
        program_rom[153]=64'h116b980000000000;
        program_rom[154]=64'h08f2000000000000;
        program_rom[155]=64'h300000000000005f;
        program_rom[156]=64'h0ce7980000000000;
        program_rom[157]=64'h300000000000005f;
        program_rom[158]=64'h0872000000000000;
        program_rom[159]=64'h08f2000000000000;
        program_rom[160]=64'h2c030000000000aa;
        program_rom[161]=64'h09e3000000000000;
        program_rom[162]=64'h34000000000000ad;
        program_rom[163]=64'h3db1000000000000;
        program_rom[164]=64'h15eda00000000000;
        program_rom[165]=64'h200f9000000000a8;
        program_rom[166]=64'h6c07680000000000;
        program_rom[167]=64'h0ce7980000000000;
        program_rom[168]=64'h0c63980000000000;
        program_rom[169]=64'h30000000000000a0;
        program_rom[170]=64'h24075800000000ac;
        program_rom[171]=64'h700b000000000000;
        program_rom[172]=64'h7400000000000004;
        program_rom[173]=64'h280f0000000000af;
        program_rom[174]=64'h11ef000000000000;
        program_rom[175]=64'h0def080000000000;
        program_rom[176]=64'h280f0000000000b2;
        program_rom[177]=64'h11ef000000000000;
        program_rom[178]=64'h1e2f000000000000;
        program_rom[179]=64'h0e31600000000000;
        program_rom[180]=64'h3800000000000000;
        program_rom[181]=64'h7400000000000004;
        program_rom[182]=64'h7400000000000004;
        program_rom[183]=64'h7400000000000004;
        program_rom[184]=64'h7400000000000004;
        program_rom[185]=64'h7400000000000004;
        program_rom[186]=64'h7400000000000004;
        program_rom[187]=64'h7400000000000004;
        program_rom[188]=64'h7400000000000004;
        program_rom[189]=64'h7400000000000004;
        program_rom[190]=64'h7400000000000004;
        program_rom[191]=64'h7400000000000004;
        program_rom[192]=64'h7400000000000004;
        program_rom[193]=64'h7400000000000004;
        program_rom[194]=64'h7400000000000004;
        program_rom[195]=64'h7400000000000004;
        program_rom[196]=64'h7400000000000004;
        program_rom[197]=64'h7400000000000004;
        program_rom[198]=64'h7400000000000004;
        program_rom[199]=64'h7400000000000004;
        program_rom[200]=64'h7400000000000004;
        program_rom[201]=64'h7400000000000004;
        program_rom[202]=64'h7400000000000004;
        program_rom[203]=64'h7400000000000004;
        program_rom[204]=64'h7400000000000004;
        program_rom[205]=64'h7400000000000004;
        program_rom[206]=64'h7400000000000004;
        program_rom[207]=64'h7400000000000004;
        program_rom[208]=64'h7400000000000004;
        program_rom[209]=64'h7400000000000004;
        program_rom[210]=64'h7400000000000004;
        program_rom[211]=64'h7400000000000004;
        program_rom[212]=64'h7400000000000004;
        program_rom[213]=64'h7400000000000004;
        program_rom[214]=64'h7400000000000004;
        program_rom[215]=64'h7400000000000004;
        program_rom[216]=64'h7400000000000004;
        program_rom[217]=64'h7400000000000004;
        program_rom[218]=64'h7400000000000004;
        program_rom[219]=64'h7400000000000004;
        program_rom[220]=64'h7400000000000004;
        program_rom[221]=64'h7400000000000004;
        program_rom[222]=64'h7400000000000004;
        program_rom[223]=64'h7400000000000004;
        program_rom[224]=64'h7400000000000004;
        program_rom[225]=64'h7400000000000004;
        program_rom[226]=64'h7400000000000004;
        program_rom[227]=64'h7400000000000004;
        program_rom[228]=64'h7400000000000004;
        program_rom[229]=64'h7400000000000004;
        program_rom[230]=64'h7400000000000004;
        program_rom[231]=64'h7400000000000004;
        program_rom[232]=64'h7400000000000004;
        program_rom[233]=64'h7400000000000004;
        program_rom[234]=64'h7400000000000004;
        program_rom[235]=64'h7400000000000004;
        program_rom[236]=64'h7400000000000004;
        program_rom[237]=64'h7400000000000004;
        program_rom[238]=64'h7400000000000004;
        program_rom[239]=64'h7400000000000004;
        program_rom[240]=64'h7400000000000004;
        program_rom[241]=64'h7400000000000004;
        program_rom[242]=64'h7400000000000004;
        program_rom[243]=64'h7400000000000004;
        program_rom[244]=64'h7400000000000004;
        program_rom[245]=64'h7400000000000004;
        program_rom[246]=64'h7400000000000004;
        program_rom[247]=64'h7400000000000004;
        program_rom[248]=64'h7400000000000004;
        program_rom[249]=64'h7400000000000004;
        program_rom[250]=64'h7400000000000004;
        program_rom[251]=64'h7400000000000004;
        program_rom[252]=64'h7400000000000004;
        program_rom[253]=64'h7400000000000004;
        program_rom[254]=64'h7400000000000004;
        program_rom[255]=64'h7400000000000004;
    end
    reg [4:0] init_index;
    (* syn_ramstyle="block_ram" *) reg [31:0] bank_a[0:31],bank_b[0:31];
    reg [31:0] av,bv;
    wire [5:0] op=instruction[63:58];
    wire [4:0] dst=instruction[57:53],a=instruction[52:48],b=instruction[47:43];
    wire [31:0] immediate=instruction[31:0];
    reg reg_write;reg [4:0] reg_address;reg [31:0] reg_data;
    reg [31:0] base_locked;
    reg [21:0] count_locked;
    reg [43:0] box;
    reg [23:0] epsilon;
    reg [21:0] point_a,point_b,point_p;
    reg [45:0] max_distance,distance;
    reg max_beyond,dist_beyond,abort_pending;
    reg [$clog2(STACK_DEPTH+1)-1:0] sp;
    wire [43:0] stack_q;
    wire execution=state==EXECUTE&&!cancel&&!abort_pending;
    wire stack_write=execution&&op==OP_PUSH&&sp<STACK_DEPTH;
    wire stack_read=execution&&op==OP_POP&&sp!=0;
    wire [$clog2(STACK_DEPTH)-1:0] stack_address=stack_read?$clog2(STACK_DEPTH)'(sp-1'b1):$clog2(STACK_DEPTH)'(sp);
    shape_rdp_stack #(.DEPTH(STACK_DEPTH)) pending_segments(.clk(clk),.re(stack_read),.we(stack_write),
        .address(stack_address),.data({av[21:0],bv[21:0]}),.q(stack_q));
    wire subtract=op==OP_SUB||op==OP_BLT||op==OP_BGE;
    wire [32:0] arithmetic={1'b0,av}+{1'b0,(bv^{32{subtract}})}+{32'd0,subtract};
    wire less=!arithmetic[32],equal=av==bv;
    wire [10:0] span_x=contour_box[32:22]-contour_box[10:0];
    wire [10:0] span_y=contour_box[43:33]-contour_box[21:11];
    wire [10:0] span=span_x>span_y?span_x:span_y;
    wire [21:0] eps_square=span*span;
    wire dist_ready,dist_valid,distance_beyond;
    wire [63:0] dist_num;wire [23:0] unused_den;
    wire [1:0] distance_error;wire [95:0] distance_scope;
    shape_segment_distance #(.EXTERNAL_MATH(EXTERNAL_MATH)) distance_unit(
        .clk(clk),.rst(rst),.cancel(cancel||abort_pending),
        .req_valid(state==DREQ&&!cancel&&!abort_pending),.req_ready(dist_ready),
        .req_a(point_a),.req_b(point_b),.req_p(point_p),.req_epsilon(epsilon),.req_scope(done_scope),
        .rsp_valid(dist_valid),.rsp_ready(state==DWAIT),.rsp_numerator(dist_num),
        .rsp_denominator(unused_den),.rsp_beyond(distance_beyond),.rsp_error(distance_error),.rsp_scope(distance_scope),
        .ext_valid(ext_valid),.ext_ready(ext_ready),.ext_a(ext_a),.ext_b(ext_b),
        .ext_scope(ext_scope),.ext_cancel(ext_cancel),.ext_result(ext_result),.ext_consume(ext_consume),
        .ext_value(ext_value),.ext_result_scope(ext_result_scope),.ext_error(ext_error));
    assign start_ready=!rst&&!cancel&&!quarantined&&state==IDLE;
    assign done_valid=!rst&&state==DONE;
    assign busy=state!=IDLE;
    assign polygon_four=done_error==0&&polygon_count==4;
    assign mem_req_valid=!rst&&state==MREQ;
    assign mem_rsp_ready=!rst&&state==MWAIT;
    function automatic valid_point(input [31:0] word);
        valid_point=word[10:0]>=box[10:0]&&word[10:0]<=box[32:22]&&
            word[21:11]>=box[21:11]&&word[21:11]<=box[43:33]&&word[30:22]==0;
    endfunction
    always @*begin
        reg_write=0;reg_address=dst;reg_data=0;
        if(state==INIT&&!cancel&&!abort_pending)begin
            reg_write=1;reg_address=init_index;
            case(init_index)
                0:reg_data={10'd0,count_locked};
                12:reg_data=base_locked;
                19:reg_data=1;
                20:reg_data=32'h80000000;
                21:reg_data=32'h003fffff;
                default:reg_data=0;
            endcase
        end else if(execution)begin
            case(op)
                OP_IMM:begin reg_write=1;reg_data=immediate;end
                OP_MOV:begin reg_write=1;reg_data=av;end
                OP_ADD,OP_SUB:begin reg_write=1;reg_data=arithmetic[31:0];end
                OP_AND:begin reg_write=1;reg_data=av&bv;end
                OP_OR:begin reg_write=1;reg_data=av|bv;end
                OP_SHL2:begin reg_write=1;reg_data=av<<2;end
                OP_MAXUPDATE:if(distance>max_distance)begin reg_write=1;reg_data=av;end
                default:begin end
            endcase
        end else if(state==MWAIT&&mem_rsp_valid&&!mem_error&&!cancel&&!abort_pending&&op==OP_READ)begin
            reg_write=1;reg_data=mem_rdata;
        end else if(state==POP_LO&&!cancel&&!abort_pending)begin
            reg_write=1;reg_address=4;reg_data={10'd0,stack_q[43:22]};
        end else if(state==POP_HI&&!cancel&&!abort_pending)begin
            reg_write=1;reg_address=5;reg_data={10'd0,stack_q[21:0]};
        end
    end
    // RAM contents need no reset; INIT initializes every architectural word.
    always @(posedge clk)begin
        if(state==FETCH)instruction<=program_rom[pc];
        av<=bank_a[a];bv<=bank_b[b];
        if(reg_write)begin bank_a[reg_address]<=reg_data;bank_b[reg_address]<=reg_data;end
    end
    task fail(input [2:0] code);
        begin done_error<=code;polygon_count<=0;polygon_x<=0;polygon_y<=0;state<=DONE;end
    endtask
    always @(posedge clk)begin
        if(rst)begin
            state<=IDLE;pc<=0;return_pc<=0;init_index<=0;sp<=0;
            base_locked<=0;count_locked<=0;box<=0;epsilon<=0;
            point_a<=0;point_b<=0;point_p<=0;max_distance<=0;distance<=0;
            max_beyond<=0;dist_beyond<=0;abort_pending<=0;
            done_scope<=0;done_error<=0;polygon_count<=0;polygon_x<=0;polygon_y<=0;
            quarantined<=0;mem_addr<=0;mem_wdata<=0;mem_wstrb<=0;
        end else begin
            if(cancel&&state!=IDLE&&state!=DONE&&state!=LOCKED)abort_pending<=1;
            if((cancel||abort_pending)&&state!=IDLE&&state!=DONE&&state!=LOCKED&&state!=MREQ&&state!=MWAIT&&state!=DWAIT)fail(2);
            else case(state)
                IDLE:if(start_valid&&start_ready)begin
                    done_scope<=start_scope;done_error<=0;polygon_count<=0;polygon_x<=0;polygon_y<=0;
                    base_locked<=contour_base;count_locked<=contour_points;box<=contour_box;
                    sp<=0;abort_pending<=0;max_distance<=0;max_beyond<=0;init_index<=0;pc<=0;
                    epsilon<=eps_square>180625?{2'b0,eps_square}:24'd180625;
                    if(contour_points<4||contour_points>W*H|| |contour_base[1:0]||contour_base<32'h04000000||
                       {32'b0,contour_base}+({42'b0,contour_points}<<2)>64'h08000000||
                       contour_box[10:0]>contour_box[32:22]||contour_box[21:11]>contour_box[43:33]||
                       contour_box[32:22]>=W||contour_box[43:33]>=H)fail(4);
                    else state<=INIT;
                end
                INIT:if(init_index==31)state<=FETCH;else init_index<=init_index+1'b1;
                FETCH:state<=OPERANDS;
                OPERANDS:state<=EXECUTE;
                EXECUTE:begin
                    pc<=pc+1'b1;state<=FETCH;
                    case(op)
                        OP_NOP,OP_IMM,OP_MOV,OP_ADD,OP_SUB,OP_AND,OP_OR,OP_SHL2:begin end
                        OP_BEQ:if(equal)pc<=immediate[7:0];
                        OP_BNE:if(!equal)pc<=immediate[7:0];
                        OP_BLT:if(less)pc<=immediate[7:0];
                        OP_BGE:if(!less)pc<=immediate[7:0];
                        OP_JMP:pc<=immediate[7:0];
                        OP_CALL:begin return_pc<=pc+1'b1;pc<=immediate[7:0];end
                        OP_RET:pc<=return_pc;
                        OP_READ,OP_WRITE:begin
                            mem_addr<=av;mem_wdata<=bv;mem_wstrb<=op==OP_WRITE?4'b1111:4'b0000;state<=MREQ;
                        end
                        OP_VALID:if(!valid_point(av))fail(4);
                        OP_SETA:point_a<=av[21:0];
                        OP_SETB:point_b<=av[21:0];
                        OP_DIST:begin point_p<=av[21:0];state<=DREQ;end
                        OP_MAXZERO:begin max_distance<=0;max_beyond<=0;end
                        OP_MAXUPDATE:if(distance>max_distance)begin max_distance<=distance;max_beyond<=dist_beyond;end
                        OP_BMAX:if(max_beyond)pc<=immediate[7:0];
                        OP_BDIST:if(dist_beyond)pc<=immediate[7:0];
                        OP_PUSH:if(sp>=STACK_DEPTH)fail(5);else sp<=sp+1'b1;
                        OP_POP:if(sp==0)pc<=immediate[7:0];else begin sp<=sp-1'b1;state<=POP_WAIT;end
                        OP_COLLECT:case(av)
                            0:begin polygon_x[10:0]<=bv[10:0];polygon_y[10:0]<=bv[21:11];end
                            1:begin polygon_x[21:11]<=bv[10:0];polygon_y[21:11]<=bv[21:11];end
                            2:begin polygon_x[32:22]<=bv[10:0];polygon_y[32:22]<=bv[21:11];end
                            3:begin polygon_x[43:33]<=bv[10:0];polygon_y[43:33]<=bv[21:11];end
                            default:begin end
                        endcase
                        OP_FINISH:begin polygon_count<=av[21:0];state<=DONE;end
                        OP_FAIL:fail(immediate[2:0]);
                        default:fail(4);
                    endcase
                end
                MREQ:if(mem_req_ready)state<=MWAIT;
                MWAIT:if(mem_rsp_valid)begin
                    if(mem_error)begin if(!mem_drained)begin quarantined<=1;fail(3);end else fail(1);end
                    else if(cancel||abort_pending)fail(2);else state<=FETCH;
                end
                DREQ:if(dist_ready)state<=DWAIT;
                DWAIT:if(dist_valid)begin
                    if(cancel||abort_pending)fail(2);
                    else if(distance_error!=0||distance_scope!=done_scope)fail(6);
                    else begin distance<=dist_num[45:0];dist_beyond<=distance_beyond;state<=FETCH;end
                end
                POP_WAIT:state<=POP_LO;
                POP_LO:state<=POP_HI;
                POP_HI:state<=FETCH;
                DONE:if(done_ready)state<=quarantined?LOCKED:IDLE;
                LOCKED:state<=LOCKED;
                default:fail(4);
            endcase
        end
    end
endmodule
// Synchronous stack storage maps into block RAM, rather than a wide LUT mux.
// No reset of data is needed: sp=0 invalidates all entries. Read and write are
// mutually exclusive and the reader consumes q on the following clock.
module shape_rdp_stack #(parameter integer DEPTH=32)(
    input wire clk,re,we,input wire [$clog2(DEPTH)-1:0] address,
    input wire [43:0] data,output reg [43:0] q
);
    reg [43:0] words[0:DEPTH-1];
    always @(posedge clk)begin if(we)words[address]<=data;if(re)q<=words[address];end
endmodule
