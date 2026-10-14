`timescale 1ns/1ps
// CT02..07：由外部SCL/SDA边沿解释独立寄存器设备，不读取DUT状态。
module i2c_sensor_model(
    input wire scl,sda,input logic [6:0] device_address,input integer case_id,
    input integer nack_transaction,nack_ordinal,stretch_ns,corrupt_read_register,
    input logic [7:0] corrupt_read_xor,
    output logic sda_drive_low=0,scl_drive_low=0
);
    byte unsigned memory_bytes[0:65535];
    typedef enum {RECEIVE_ADDRESS,RECEIVE_HIGH,RECEIVE_LOW,RECEIVE_DATA,SEND_DATA,MASTER_ACK,IGNORE} mode_t;
    mode_t mode=IGNORE,next_mode=IGNORE;
    logic active=0,ack_ok=0,byte_accepted=0,reading=0;
    logic [7:0] shift_byte=0,received_byte=0,send_byte=0;
    logic [15:0] register_pointer=0;
    integer bits=0,wire_ordinal=0,transaction_index=0,starts=0,restarts=0,stops=0,writes=0,reads=0,master_nacks=0;
    integer trace_handle=0;
    realtime last_fall=0,last_rise=0,last_sda_change=0,last_start=0,last_stop=0;
    realtime min_low=1e30,min_high=1e30,min_setup=1e30,min_start_hold=1e30,min_stop_setup=1e30,min_bus_free=1e30;
    logic timing_enabled=1,stretch_pending=0;
    task automatic reset_model;
        for(integer i=0;i<65536;i++)memory_bytes[i]=0;
        memory_bytes['h3107]='hcd;memory_bytes['h3108]='h6b;
        memory_bytes['h3018]='h72;memory_bytes['h3031]='h0a;memory_bytes['h3037]='h20;memory_bytes['h303f]=0;
        active=0;mode=IGNORE;next_mode=IGNORE;bits=0;wire_ordinal=0;transaction_index=0;
        starts=0;restarts=0;stops=0;writes=0;reads=0;master_nacks=0;register_pointer=0;
        sda_drive_low=0;scl_drive_low=0;stretch_pending=0;
        timing_enabled=1;
        last_fall=0;last_rise=0;last_sda_change=0;last_start=0;last_stop=0;
        min_low=1e30;min_high=1e30;min_setup=1e30;min_start_hold=1e30;min_stop_setup=1e30;min_bus_free=1e30;
    endtask
    always @(sda)last_sda_change=$realtime;
    always @(negedge sda)if(scl===1'b1)begin
        if(active)begin restarts++;if(trace_handle)$fwrite(trace_handle,"S,%0d,%0d,1,%0.0f\n",case_id,transaction_index,$realtime);end
        else begin
            starts++;wire_ordinal=0;
            if(last_stop>0 && timing_enabled && $realtime-last_stop<min_bus_free)min_bus_free=$realtime-last_stop;
            if(trace_handle)$fwrite(trace_handle,"S,%0d,%0d,0,%0.0f\n",case_id,transaction_index,$realtime);
        end
        active=1;mode=RECEIVE_ADDRESS;bits=0;shift_byte=0;last_start=$realtime;
    end
    always @(posedge sda)if(scl===1'b1 && active)begin
        if(timing_enabled && $realtime-last_rise<min_stop_setup)min_stop_setup=$realtime-last_rise;
        active=0;mode=IGNORE;sda_drive_low=0;stops++;
        if(trace_handle)$fwrite(trace_handle,"P,%0d,%0d,%0.0f\n",case_id,transaction_index,$realtime);
        transaction_index++;last_stop=$realtime;
    end
    always @(negedge scl)begin
        if(last_rise>0 && active && timing_enabled && $realtime-last_rise<min_high)min_high=$realtime-last_rise;
        if(last_start>0 && last_start>last_fall && active && timing_enabled && $realtime-last_start<min_start_hold)min_start_hold=$realtime-last_start;
        last_fall=$realtime;
        if(active)begin
            if(mode==SEND_DATA)sda_drive_low=!send_byte[7-bits];
            else if(bits==8)sda_drive_low=ack_ok;
            else sda_drive_low=0;
            if(bits==8 && stretch_ns>0 && !stretch_pending)begin
                stretch_pending=1;scl_drive_low=1;
                fork
                    begin #(stretch_ns);scl_drive_low=0;stretch_pending=0;end
                join_none
            end
        end else sda_drive_low=0;
    end
    always @(posedge scl)begin
        if(last_fall>0 && active && timing_enabled && $realtime-last_fall<min_low)min_low=$realtime-last_fall;
        if(active && timing_enabled && $realtime-last_sda_change<min_setup)min_setup=$realtime-last_sda_change;
        last_rise=$realtime;
        if(active)begin
            if(mode==SEND_DATA)begin
                bits++;
                if(bits==8)begin
                    reads++;
                    if(trace_handle)$fwrite(trace_handle,"R,%0d,%0d,%04h,%02h,%0.0f\n",case_id,transaction_index,register_pointer,send_byte,$realtime);
                    mode=MASTER_ACK;bits=0;
                end
            end else if(mode==MASTER_ACK)begin
                if(sda===1'b1)master_nacks++;
                if(trace_handle)$fwrite(trace_handle,"M,%0d,%0d,%0d,%0.0f\n",case_id,transaction_index,sda,$realtime);
                mode=IGNORE;bits=0;
            end else if(mode!=IGNORE)begin
                if(bits<8)begin
                    shift_byte={shift_byte[6:0],sda};bits++;
                    if(bits==8)begin
                        received_byte=shift_byte;
                        ack_ok=!(transaction_index==nack_transaction && wire_ordinal==nack_ordinal);
                        next_mode=mode;
                        case(mode)
                            RECEIVE_ADDRESS:begin
                                ack_ok=ack_ok && received_byte[7:1]==device_address;
                                reading=received_byte[0];next_mode=reading ? SEND_DATA : RECEIVE_HIGH;
                            end
                            RECEIVE_HIGH:next_mode=RECEIVE_LOW;
                            RECEIVE_LOW:next_mode=RECEIVE_DATA;
                            RECEIVE_DATA:next_mode=RECEIVE_DATA;
                        endcase
                    end
                end else begin
                    if(trace_handle)$fwrite(trace_handle,"A,%0d,%0d,%0d,%02h,%0d,%0.0f\n",case_id,transaction_index,wire_ordinal,received_byte,sda,$realtime);
                    wire_ordinal++;
                    if(ack_ok)begin
                        case(mode)
                            RECEIVE_HIGH:register_pointer[15:8]=received_byte;
                            RECEIVE_LOW:register_pointer[7:0]=received_byte;
                            RECEIVE_DATA:begin
                                memory_bytes[register_pointer]=received_byte;writes++;
                                if(trace_handle)$fwrite(trace_handle,"W,%0d,%0d,%04h,%02h,%0.0f\n",case_id,transaction_index,register_pointer,received_byte,$realtime);
                            end
                        endcase
                        mode=next_mode;
                        if(mode==SEND_DATA)begin
                            send_byte=memory_bytes[register_pointer];
                            if(integer'(register_pointer)==corrupt_read_register)send_byte=send_byte^corrupt_read_xor;
                        end
                    end else mode=IGNORE;
                    bits=0;shift_byte=0;
                end
            end
        end
    end
endmodule
