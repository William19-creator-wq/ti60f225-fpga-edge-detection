// FT-T07：只测实际pkg政策；人工等号不是主图像几何half覆盖。
module tb_fit_helpers;
    import fit_protocol_pkg::*;
    bit finished=0;
    integer checks=0;
    initial begin
        for(integer k=0;k<32;k=k+1) begin
            for(integer cmp=0;cmp<3;cmp=cmp+1) begin
                if(choose_midpoint_even(k[18:0],cmp[1:0]) != k+((cmp==2 || (cmp==0 && (k%2)))?1:0)) $fatal(1,"midpoint policy");
                for(integer upper=0;upper<2;upper=upper+1) begin
                    if(qualify_distance_bounds(k[20:0],cmp[1:0],upper[0]) !=
                       ((cmp==(upper?1:2)) || (cmp==0 && k%2==0))) $fatal(1,"boundary policy");
                    checks=checks+1;
                end
            end
        end
        if(qualify_distance_bounds(21'd2,2'd3,1) || qualify_distance_bounds(21'd2,2'd3,0)) $fatal(1,"illegal compare");
        if(!fits_return({385{1'b1}},18,1) || fits_return({385{1'b1}},18,0)) $fatal(1,"full signed qualification");
        if(fits_return(385'b1<<192,192,0) || !fits_return((385'b1<<192)-1,192,0)) $fatal(1,"high192 guard");
        if(!fits_slot(-192'd131072,18,1) || fits_slot(192'd131072,18,1)) $fatal(1,"geometry representation");
        if(!normal_ok(32'sd1073741824,0) || normal_ok(0,0) || normal_ok(32'sd1073741825,0)) $fatal(1,"normal domain");
        finished=1; $display("PASS helpers checks=%0d; isolated equality policy",checks); $finish;
    end
endmodule
