export RUNDIR=`pwd`

##RESULT_CHECKER##
##SDP
python3 ../../generator/generation_integrated.py CONSOLE SDP_RAM 6 16 --out_path $RUNDIR --ByteEnable 0      --memory_mode SPEED --write_mode READ_FIRST    --device_family TITANIUM --data_width_B 16  --address_width_B 6 > sdp_ti_speed_byteoff_6x16_texp1.log
python3 ../../generator/generation_integrated.py CONSOLE SDP_RAM 6 32 --out_path $RUNDIR --ByteEnable 0      --memory_mode SPEED --write_mode READ_FIRST    --device_family TITANIUM --data_width_B 32  --address_width_B 6 > sdp_ti_speed_byteoff_6x32_texp2.log
python3 ../../generator/generation_integrated.py CONSOLE SDP_RAM 14 16 --out_path $RUNDIR --ByteEnable 0      --memory_mode SPEED --write_mode READ_FIRST    --device_family TITANIUM --data_width_B 16  --address_width_B 14 > sdp_ti_speed_byteoff_14x16_texp32.log

python3 ../../generator/generation_integrated.py CONSOLE SDP_RAM 6 16 --out_path $RUNDIR --ByteEnable 1      --memory_mode SPEED --write_mode READ_FIRST    --device_family TITANIUM --data_width_B 16  --address_width_B 6 > sdp_ti_speed_byteon_6x16_texp1.log
python3 ../../generator/generation_integrated.py CONSOLE SDP_RAM 6 32 --out_path $RUNDIR --ByteEnable 1      --memory_mode SPEED --write_mode READ_FIRST    --device_family TITANIUM --data_width_B 32  --address_width_B 6 > sdp_ti_speed_byteon_6x32_texp2.log
python3 ../../generator/generation_integrated.py CONSOLE SDP_RAM 14 16 --out_path $RUNDIR --ByteEnable 1      --memory_mode SPEED --write_mode READ_FIRST    --device_family TITANIUM --data_width_B 16  --address_width_B 14 > sdp_ti_speed_byteon_14x16_texp32.log

python3 ../../generator/generation_integrated.py CONSOLE SDP_RAM 6 16 --out_path $RUNDIR --ByteEnable 0      --memory_mode SPEED --write_mode READ_FIRST    --device_family TRION --data_width_B 16  --address_width_B 6 > sdp_tr_speed_byteoff_6x16_texp1.log
python3 ../../generator/generation_integrated.py CONSOLE SDP_RAM 6 32 --out_path $RUNDIR --ByteEnable 0      --memory_mode SPEED --write_mode READ_FIRST    --device_family TRION --data_width_B 32  --address_width_B 6 > sdp_tr_speed_byteoff_6x32_texp2.log
python3 ../../generator/generation_integrated.py CONSOLE SDP_RAM 14 16 --out_path $RUNDIR --ByteEnable 0      --memory_mode SPEED --write_mode READ_FIRST    --device_family TRION --data_width_B 16  --address_width_B 14 > sdp_tr_speed_byteoff_14x16_texp64.log

python3 ../../generator/generation_integrated.py CONSOLE SDP_RAM 6 16 --out_path $RUNDIR --ByteEnable 1      --memory_mode SPEED --write_mode READ_FIRST    --device_family TRION --data_width_B 16  --address_width_B 6 > sdp_tr_speed_byteon_6x16_texp2.log
python3 ../../generator/generation_integrated.py CONSOLE SDP_RAM 6 32 --out_path $RUNDIR --ByteEnable 1      --memory_mode SPEED --write_mode READ_FIRST    --device_family TRION --data_width_B 32  --address_width_B 6 > sdp_tr_speed_byteon_6x32_texp4.log
python3 ../../generator/generation_integrated.py CONSOLE SDP_RAM 14 16 --out_path $RUNDIR --ByteEnable 1      --memory_mode SPEED --write_mode READ_FIRST    --device_family TRION --data_width_B 16  --address_width_B 14 > sdp_tr_speed_byteon_14x16_texp64.log


python3 ../../generator/generation_integrated.py CONSOLE SDP_RAM 6 16 --out_path $RUNDIR --ByteEnable 0      --memory_mode AREA --write_mode READ_FIRST    --device_family TITANIUM --data_width_B 16  --address_width_B 6 > sdp_ti_area_byteoff_6x16_texp1.log
python3 ../../generator/generation_integrated.py CONSOLE SDP_RAM 6 32 --out_path $RUNDIR --ByteEnable 0      --memory_mode AREA --write_mode READ_FIRST    --device_family TITANIUM --data_width_B 32  --address_width_B 6 > sdp_ti_area_byteoff_6x32_texp2.log
python3 ../../generator/generation_integrated.py CONSOLE SDP_RAM 14 16 --out_path $RUNDIR --ByteEnable 0      --memory_mode AREA --write_mode READ_FIRST    --device_family TITANIUM --data_width_B 16  --address_width_B 14 > sdp_ti_area_byteoff_14x16_texp26.log

python3 ../../generator/generation_integrated.py CONSOLE SDP_RAM 6 16 --out_path $RUNDIR --ByteEnable 1      --memory_mode AREA --write_mode READ_FIRST    --device_family TITANIUM --data_width_B 16  --address_width_B 6 > sdp_ti_area_byteon_6x16_texp1.log
python3 ../../generator/generation_integrated.py CONSOLE SDP_RAM 6 32 --out_path $RUNDIR --ByteEnable 1      --memory_mode AREA --write_mode READ_FIRST    --device_family TITANIUM --data_width_B 32  --address_width_B 6 > sdp_ti_area_byteon_6x32_texp2.log
python3 ../../generator/generation_integrated.py CONSOLE SDP_RAM 14 16 --out_path $RUNDIR --ByteEnable 1      --memory_mode AREA --write_mode READ_FIRST    --device_family TITANIUM --data_width_B 16  --address_width_B 14 > sdp_ti_area_byteon_14x16_texp32.log

python3 ../../generator/generation_integrated.py CONSOLE SDP_RAM 6 16 --out_path $RUNDIR --ByteEnable 0      --memory_mode AREA --write_mode READ_FIRST    --device_family TRION --data_width_B 16  --address_width_B 6 > sdp_tr_area_byteoff_6x16_texp1.log
python3 ../../generator/generation_integrated.py CONSOLE SDP_RAM 6 32 --out_path $RUNDIR --ByteEnable 0      --memory_mode AREA --write_mode READ_FIRST    --device_family TRION --data_width_B 32  --address_width_B 6 > sdp_tr_area_byteoff_6x32_texp2.log
python3 ../../generator/generation_integrated.py CONSOLE SDP_RAM 14 16 --out_path $RUNDIR --ByteEnable 0      --memory_mode AREA --write_mode READ_FIRST    --device_family TRION --data_width_B 16  --address_width_B 14 > sdp_tr_area_byteoff_14x16_texp52.log

python3 ../../generator/generation_integrated.py CONSOLE SDP_RAM 6 16 --out_path $RUNDIR --ByteEnable 1      --memory_mode AREA --write_mode READ_FIRST    --device_family TRION --data_width_B 16  --address_width_B 6 > sdp_tr_area_byteon_6x16_texp2.log
python3 ../../generator/generation_integrated.py CONSOLE SDP_RAM 6 32 --out_path $RUNDIR --ByteEnable 1      --memory_mode AREA --write_mode READ_FIRST    --device_family TRION --data_width_B 32  --address_width_B 6 > sdp_tr_area_byteon_6x32_texp4.log
python3 ../../generator/generation_integrated.py CONSOLE SDP_RAM 14 16 --out_path $RUNDIR --ByteEnable 1      --memory_mode AREA --write_mode READ_FIRST    --device_family TRION --data_width_B 16  --address_width_B 14 > sdp_tr_area_byteon_14x16_texp64.log


##TDP
#python3 ../../generator/generation_integrated.py CONSOLE TDP_RAM 6 16 --out_path $RUNDIR --ByteEnable_A 0 --ByteEnable_B 0      --memory_mode SPEED --write_mode_A READ_FIRST --write_mode_B READ_FIRST    --device_family TITANIUM --data_width_B 16  --address_width_B 6 > tdp_ti_speed_byteoff_6x16.log
#python3 ../../generator/generation_integrated.py CONSOLE TDP_RAM 6 32 --out_path $RUNDIR --ByteEnable_A 0 --ByteEnable_B 0      --memory_mode SPEED --write_mode_A READ_FIRST --write_mode_B READ_FIRST   --device_family TITANIUM --data_width_B 32  --address_width_B 6 > tdp_ti_speed_byteoff_6x32.log
#python3 ../../generator/generation_integrated.py CONSOLE TDP_RAM 14 16 --out_path $RUNDIR --ByteEnable_A 0 --ByteEnable_B 0      --memory_mode SPEED --write_mode_A READ_FIRST --write_mode_B READ_FIRST   --device_family TITANIUM --data_width_B 16  --address_width_B 14 > tdp_ti_speed_byteoff_14x16.log
#python3 ../../generator/generation_integrated.py CONSOLE TDP_RAM 6 16 --out_path $RUNDIR --ByteEnable_A 1 --ByteEnable_B 0      --memory_mode SPEED --write_mode_A READ_FIRST --write_mode_B READ_FIRST   --device_family TITANIUM --data_width_B 16  --address_width_B 6 > tdp_tr_speed_byteon_6x16.log
#python3 ../../generator/generation_integrated.py CONSOLE TDP_RAM 6 32 --out_path $RUNDIR --ByteEnable_A 1 --ByteEnable_B 0      --memory_mode SPEED --write_mode_A READ_FIRST --write_mode_B READ_FIRST   --device_family TITANIUM --data_width_B 32  --address_width_B 6 > tdp_tr_speed_byteon_6x32.log
#python3 ../../generator/generation_integrated.py CONSOLE TDP_RAM 14 16 --out_path $RUNDIR --ByteEnable_A 1 --ByteEnable_B 0      --memory_mode SPEED --write_mode_A READ_FIRST --write_mode_B READ_FIRST   --device_family TITANIUM --data_width_B 16  --address_width_B 14 > tdp_tr_speed_byteon_14x16.log

#python3 ../../generator/generation_integrated.py CONSOLE TDP_RAM 6 16 --out_path $RUNDIR --ByteEnable_A 0 --ByteEnable_B 0      --memory_mode AREA --write_mode_A READ_FIRST --write_mode_B READ_FIRST   --device_family TITANIUM --data_width_B 16  --address_width_B 6 > tdp_ti_area_byteoff_6x16.log
#python3 ../../generator/generation_integrated.py CONSOLE TDP_RAM 6 32 --out_path $RUNDIR --ByteEnable_A 0 --ByteEnable_B 0      --memory_mode AREA --write_mode_A READ_FIRST --write_mode_B READ_FIRST   --device_family TITANIUM --data_width_B 32  --address_width_B 6 > tdp_ti_area_byteoff_6x32.log
#python3 ../../generator/generation_integrated.py CONSOLE TDP_RAM 14 16 --out_path $RUNDIR --ByteEnable_A 0 --ByteEnable_B 0      --memory_mode AREA --write_mode_A READ_FIRST --write_mode_B READ_FIRST   --device_family TITANIUM --data_width_B 16  --address_width_B 14 > tdp_ti_area_byteoff_14x16.log
#python3 ../../generator/generation_integrated.py CONSOLE TDP_RAM 6 16 --out_path $RUNDIR --ByteEnable_A 1 --ByteEnable_B 0         --memory_mode AREA --write_mode_A READ_FIRST --write_mode_B READ_FIRST   --device_family TITANIUM --data_width_B 16  --address_width_B 6 > tdp_tr_area_byteon_6x16.log
#python3 ../../generator/generation_integrated.py CONSOLE TDP_RAM 6 32 --out_path $RUNDIR --ByteEnable_A 1 --ByteEnable_B 0      --memory_mode AREA --write_mode_A READ_FIRST --write_mode_B READ_FIRST   --device_family TITANIUM --data_width_B 32  --address_width_B 6 > tdp_tr_area_byteon_6x32.log
#python3 ../../generator/generation_integrated.py CONSOLE TDP_RAM 14 16 --out_path $RUNDIR --ByteEnable_A 1 --ByteEnable_B 0      --memory_mode AREA --write_mode_A READ_FIRST --write_mode_B READ_FIRST    --device_family TITANIUM --data_width_B 16  --address_width_B 14 > tdp_tr_area_byteon_14x16.log
