`timescale 1ps/1ps
// DM02..04：真实model实例的选择/展开证据；reset不释放，不宣称DDR初始化。
module tb_ddr_profile;
    reg ck=0;
    reg finished=0;
    always #1250 ck=~ck;
    wire [15:0] dq;
    wire [1:0] dqs,dqs_n,tdqs_n;
    wire [1:0] dm_tdqs;
    assign dm_tdqs=2'd0;
    integer fd;
    longint unsigned capacity_bits;
    ddr3 #(.DEBUG(0)) dram(
        .rst_n(1'b0),.ck(ck),.ck_n(!ck),.cke(1'b0),.cs_n(1'b1),
        .ras_n(1'b1),.cas_n(1'b1),.we_n(1'b1),.dm_tdqs(dm_tdqs),.ba(3'd0),.addr(14'd0),
        .dq(dq),.dqs(dqs),.dqs_n(dqs_n),.tdqs_n(tdqs_n),.odt(1'b0));
    initial begin
        if($test$plusargs("EXPECT_FATAL"))begin #1;$fatal(1,"fatal exit probe");end
        #20000;
        capacity_bits=(64'd1 << (dram.ROW_BITS+dram.COL_BITS+dram.BA_BITS))*dram.DQ_BITS;
        if(dram.ROW_BITS!=14 || dram.COL_BITS!=10 || dram.BA_BITS!=3 || dram.DQ_BITS!=16 ||
           dram.DQS_BITS!=2 || dram.DM_BITS!=2 || capacity_bits!=64'd2147483648)
            $fatal(1,"Selected model is not2Gb/x16");
        if(dram.check_strict_mrbits!=1 || dram.check_strict_timing!=1 || dram.STOP_ON_ERROR!=1)
            $fatal(1,"Model strict checks changed");
        fd=$fopen("profile.json","w");if(!fd)$fatal(1,"Profile open");
        $fdisplay(fd,"{");
        $fdisplay(fd,"\"ADDR_BITS\":%0d,\"ROW_BITS\":%0d,\"COL_BITS\":%0d,\"BA_BITS\":%0d,",dram.ADDR_BITS,dram.ROW_BITS,dram.COL_BITS,dram.BA_BITS);
        $fdisplay(fd,"\"DQ_BITS\":%0d,\"DQS_BITS\":%0d,\"DM_BITS\":%0d,\"BL_MIN\":%0d,\"BL_MAX\":%0d,",dram.DQ_BITS,dram.DQS_BITS,dram.DM_BITS,dram.BL_MIN,dram.BL_MAX);
        $fdisplay(fd,"\"CL_MIN\":%0d,\"CL_MAX\":%0d,\"CWL_MIN\":%0d,\"CWL_MAX\":%0d,",dram.CL_MIN,dram.CL_MAX,dram.CWL_MIN,dram.CWL_MAX);
        $fdisplay(fd,"\"TCK_MIN\":%0d,\"TCK_MAX\":%0d,\"CL_TIME\":%0d,\"TAA_MIN\":%0d,",dram.TCK_MIN,dram.TCK_MAX,dram.CL_TIME,dram.TAA_MIN);
        $fdisplay(fd,"\"TRAS_MIN\":%0d,\"TRCD\":%0d,\"TRP\":%0d,\"TRC\":%0d,\"TRRD\":%0d,\"TFAW\":%0d,",dram.TRAS_MIN,dram.TRCD,dram.TRP,dram.TRC,dram.TRRD,dram.TFAW);
        $fdisplay(fd,"\"TRFC_MIN\":%0d,\"TRFC_MAX\":%0d,\"TXPR\":%0d,\"TXS\":%0d,\"TXP\":%0d,\"TCKE\":%0d,",dram.TRFC_MIN,dram.TRFC_MAX,dram.TXPR,dram.TXS,dram.TXP,dram.TCKE);
        $fdisplay(fd,"\"TDS\":%0d,\"TDH\":%0d,\"TIS\":%0d,\"TIH\":%0d,\"TDQSQ\":%0d,\"TDQSCK\":%0d,",dram.TDS,dram.TDH,dram.TIS,dram.TIH,dram.TDQSQ,dram.TDQSCK);
        $fdisplay(fd,"\"TWR\":%0d,\"TWTR\":%0d,\"TRTP\":%0d,\"TMOD\":%0d,\"TDLLK\":%0d,",dram.TWR,dram.TWTR,dram.TRTP,dram.TMOD,dram.TDLLK);
        $fdisplay(fd,"\"TDQSS\":%0.6f,\"TDSS\":%0.6f,\"TDSH\":%0.6f,\"TQSH\":%0.6f,\"TQSL\":%0.6f,",dram.TDQSS,dram.TDSS,dram.TDSH,dram.TQSH,dram.TQSL);
        $fdisplay(fd,"\"MEM_BITS\":%0d,\"AP\":%0d,\"BC\":%0d,",dram.MEM_BITS,dram.AP,dram.BC);
        $fdisplay(fd,"\"strict_mrbits\":%0d,\"strict_timing\":%0d,\"STOP_ON_ERROR\":%0d,",dram.check_strict_mrbits,dram.check_strict_timing,dram.STOP_ON_ERROR);
        $fdisplay(fd,"\"capacity_bits\":%0d,\"clock_period_ps\":2500,\"simulation_time_ps\":20000,\"reset_released\":false,\"finished\":true}",capacity_bits);
        $fclose(fd);finished=1;$finish;
    end
endmodule
