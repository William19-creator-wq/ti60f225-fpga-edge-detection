
//
// Verific Verilog Description of module display_renderer
//

module display_renderer (clk, rst, in_de, in_hs, in_vs, in_frame_start, 
            in_x_even, in_y, in_pair, in_render, in_pixels_valid, 
            in_identity_good, out_rgb_pair, out_de, out_hs, out_vs, 
            out_frame_start, out_x_even, out_y, out_error) /* verific EFX_ATTRIBUTE_NETLIST__EFINITY_VERSION=2026.1.132 */ ;
    input clk /* verific EFX_ATTRIBUTE_PORT__IS_PRIMARY_INPUT=TRUE */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(5)
    input rst /* verific EFX_ATTRIBUTE_PORT__IS_PRIMARY_INPUT=TRUE */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(5)
    input in_de /* verific EFX_ATTRIBUTE_PORT__IS_PRIMARY_INPUT=TRUE */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(6)
    input in_hs /* verific EFX_ATTRIBUTE_PORT__IS_PRIMARY_INPUT=TRUE */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(6)
    input in_vs /* verific EFX_ATTRIBUTE_PORT__IS_PRIMARY_INPUT=TRUE */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(6)
    input in_frame_start /* verific EFX_ATTRIBUTE_PORT__IS_PRIMARY_INPUT=TRUE */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(6)
    input [10:0]in_x_even /* verific EFX_ATTRIBUTE_PORT__IS_PRIMARY_INPUT=TRUE */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(7)
    input [10:0]in_y /* verific EFX_ATTRIBUTE_PORT__IS_PRIMARY_INPUT=TRUE */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(7)
    input [53:0]in_pair /* verific EFX_ATTRIBUTE_PORT__IS_PRIMARY_INPUT=TRUE */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(8)
    input [111:0]in_render /* verific EFX_ATTRIBUTE_PORT__IS_PRIMARY_INPUT=TRUE */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(9)
    input in_pixels_valid /* verific EFX_ATTRIBUTE_PORT__IS_PRIMARY_INPUT=TRUE */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(10)
    input in_identity_good /* verific EFX_ATTRIBUTE_PORT__IS_PRIMARY_INPUT=TRUE */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(10)
    output [47:0]out_rgb_pair /* verific EFX_ATTRIBUTE_PORT__IS_PRIMARY_OUTPUT=TRUE */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(11)
    output out_de /* verific EFX_ATTRIBUTE_PORT__IS_PRIMARY_OUTPUT=TRUE */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(12)
    output out_hs /* verific EFX_ATTRIBUTE_PORT__IS_PRIMARY_OUTPUT=TRUE */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(12)
    output out_vs /* verific EFX_ATTRIBUTE_PORT__IS_PRIMARY_OUTPUT=TRUE */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(12)
    output out_frame_start /* verific EFX_ATTRIBUTE_PORT__IS_PRIMARY_OUTPUT=TRUE */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(12)
    output [10:0]out_x_even /* verific EFX_ATTRIBUTE_PORT__IS_PRIMARY_OUTPUT=TRUE */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(13)
    output [10:0]out_y /* verific EFX_ATTRIBUTE_PORT__IS_PRIMARY_OUTPUT=TRUE */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(13)
    output [1:0]out_error /* verific EFX_ATTRIBUTE_PORT__IS_PRIMARY_OUTPUT=TRUE */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(14)
    
    wire [11:0]n228;
    wire [23:0]n805_2;
    wire [23:0]n805_3;
    wire [23:0]n805_4;
    wire [23:0]n805_5;
    wire [23:0]n805_6;
    wire [23:0]n805_7;
    wire [23:0]n805_8;
    wire [23:0]n805_10;
    wire [23:0]n805_12;
    wire [23:0]n805_14;
    wire [23:0]n805_16;
    wire [23:0]n805_18;
    wire [23:0]n805_21;
    wire [23:0]n805_22;
    wire [23:0]n805_23;
    wire [23:0]n805_24;
    wire [23:0]n805_25;
    wire [23:0]n574_2;
    wire [23:0]n574_3;
    wire [23:0]n574_4;
    wire [23:0]n574_5;
    wire [23:0]n574_6;
    wire [23:0]n574_7;
    wire [23:0]n574_8;
    wire [23:0]n574_9;
    wire [23:0]n574_10;
    wire [23:0]n574_11;
    wire [23:0]n574_12;
    wire [23:0]n574_13;
    wire [23:0]n574_14;
    wire [23:0]n574_15;
    wire [23:0]n574_16;
    wire [23:0]n574_17;
    wire [23:0]n574_18;
    wire [23:0]n574_19;
    wire [23:0]n574_20;
    wire [23:0]n574_21;
    wire [23:0]n574_22;
    wire [23:0]n574_23;
    wire [23:0]n574_24;
    wire [23:0]n574_25;
    wire [23:0]\snapshot.ann11_color ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(28)
    wire [11:0]n15;
    
    wire \add_4/n2 ;
    wire [13:0]n29;
    
    wire \add_5/n2 ;
    wire [8:0]n45;
    
    wire \add_6/n2 ;
    wire [11:0]n56;
    
    wire \add_7/n2 ;
    wire [13:0]n70;
    
    wire \add_8/n2 ;
    wire [14:0]n86;
    
    wire \add_9/n2 ;
    wire [11:0]n103;
    
    wire \add_10/n2 ;
    wire [12:0]n117;
    
    wire \add_11/n2 ;
    wire [13:0]n132;
    
    wire \add_12/n2 , \add_13/n2 ;
    wire [15:0]\next_snapshot.gray ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(28)
    
    wire \add_305/n2 ;
    wire [7:0]n177;
    
    wire \add_15/n2 ;
    wire [11:0]n187;
    
    wire \add_16/n2 ;
    wire [13:0]n201;
    
    wire \add_17/n2 ;
    wire [8:0]n217;
    
    wire \add_18/n2 , \add_19/n2 ;
    wire [13:0]n242;
    
    wire \add_20/n2 ;
    wire [14:0]n258;
    
    wire \add_21/n2 ;
    wire [11:0]n275;
    
    wire \add_22/n2 ;
    wire [12:0]n289;
    
    wire \add_23/n2 ;
    wire [13:0]n304;
    
    wire \add_24/n2 , \add_25/n2 , \add_304/n2 , \add_8/n18 ;
    wire [10:0]\snapshot.x_even ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(28)
    
    wire \snapshot.frame_start , \add_10/n22 , \snapshot.de , \snapshot.hs ;
    wire [47:0]\snapshot.rgb ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(28)
    wire [15:0]\snapshot.gray ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(28)
    wire [10:0]\snapshot.y ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(28)
    
    wire \snapshot.show_ann , \snapshot.show_edge , \snapshot.top_half ;
    wire [2:0]\snapshot.mode ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(28)
    wire [3:0]\snapshot.ann ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(28)
    wire [1:0]\snapshot.edge_bits ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(28)
    wire [23:0]\snapshot.edge_color ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(28)
    wire [23:0]\snapshot.ann01_color ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(28)
    wire [23:0]\snapshot.ann10_color ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(28)
    wire [1:0]\snapshot.error ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(28)
    
    wire \snapshot.vs , n186, \add_16/n22 , \add_16/n20 , \add_16/n18 , 
        \add_16/n16 , \add_8/n16 , \add_16/n14 , \add_18/n16 , \add_19/n4 , 
        \add_19/n6 , \add_22/n20 , \add_24/n18 , \add_304/n6 , \add_304/n8 , 
        \add_304/n10 , \add_17/n22 , \add_17/n20 , \add_17/n18 , \add_17/n16 , 
        \add_17/n14 , \add_17/n12 , \add_17/n10 , \add_17/n8 , \add_17/n6 , 
        \add_17/n4 , \add_18/n14 , \add_18/n12 , \add_18/n10 , \add_18/n8 , 
        \add_18/n6 , \add_18/n4 , \add_17/n26 , \add_17/n24 , \add_20/n26 , 
        \add_20/n24 , \add_20/n22 , \add_20/n20 , \add_20/n18 , \add_20/n16 , 
        \add_20/n14 , \add_20/n12 , \add_20/n10 , \add_20/n8 , \add_20/n6 , 
        \add_20/n4 , \add_19/n22 , \add_19/n20 , \add_19/n18 , \add_19/n16 , 
        \add_19/n14 , \add_19/n12 , \add_19/n10 , \add_19/n8 , \add_22/n18 , 
        \add_22/n16 , \add_22/n14 , \add_22/n12 , \add_22/n10 , \add_22/n8 , 
        \add_22/n6 , \add_22/n4 , \add_21/n28 , \add_21/n26 , \add_21/n24 , 
        \add_21/n22 , \add_21/n20 , \add_21/n18 , \add_21/n16 , \add_21/n14 , 
        \add_21/n12 , \add_21/n10 , \add_21/n8 , \add_21/n6 , \add_21/n4 , 
        \add_24/n16 , \add_24/n14 , \add_24/n12 , \add_24/n10 , \add_24/n8 , 
        \add_24/n6 , \add_24/n4 , \add_23/n24 , \add_23/n22 , \add_23/n20 , 
        \add_23/n18 , \add_23/n16 , \add_23/n14 , \add_23/n12 , \add_23/n10 , 
        \add_23/n8 , \add_23/n6 , \add_23/n4 , \add_22/n22 , \add_304/n4 ;
    wire [15:0]n320;
    
    wire \add_25/n30 , \add_25/n28 , \add_25/n26 , \add_25/n24 , \add_25/n22 , 
        \add_25/n20 , \add_25/n18 , \add_25/n16 , \add_25/n14 , \add_25/n12 , 
        \add_25/n10 , \add_25/n8 , \add_25/n6 , \add_25/n4 , \add_24/n26 , 
        \add_24/n24 , \add_24/n22 , \add_24/n20 , \add_304/n14 , \add_304/n12 , 
        \add_8/n14 , \add_8/n12 , \add_8/n10 , \add_8/n8 , \add_8/n6 , 
        \add_8/n4 , \add_7/n22 , \add_7/n20 , \add_7/n18 , \add_7/n16 , 
        \add_7/n14 , \add_7/n12 , \add_7/n10 , \add_7/n8 , \add_7/n6 , 
        \add_7/n4 , \add_6/n16 , \add_6/n14 , \add_6/n12 , \add_6/n10 , 
        \add_6/n8 , \add_6/n6 , \add_6/n4 , \add_5/n26 , \add_5/n24 , 
        \add_16/n12 , \add_16/n10 , \add_16/n8 , \add_16/n6 , \add_16/n4 , 
        n176, \add_15/n14 , \add_15/n12 , \add_15/n10 , \add_15/n8 , 
        \add_15/n6 , \add_15/n4 , \add_305/n14 , \add_305/n12 , \add_305/n10 , 
        \add_305/n8 , \add_305/n6 , \add_305/n4 ;
    wire [15:0]n148;
    
    wire \add_13/n30 , \add_13/n28 , \add_13/n26 , \add_13/n24 , \add_13/n22 , 
        \add_13/n20 , \add_13/n18 , \add_13/n16 , \add_13/n14 , \add_13/n12 , 
        \add_13/n10 , \add_13/n8 , \add_13/n6 , \add_13/n4 , \add_12/n26 , 
        \add_12/n24 , \add_12/n22 , \add_12/n20 , \add_12/n18 , \add_12/n16 , 
        \add_12/n14 , \add_12/n12 , \add_9/n16 , \add_10/n20 , \add_10/n18 , 
        \add_10/n16 , \add_10/n14 , \add_10/n12 , \add_10/n10 , \add_9/n14 , 
        \add_10/n8 , \add_9/n12 , \add_10/n6 , \add_9/n10 , \add_9/n8 , 
        \add_10/n4 , \add_9/n6 , \add_9/n4 , \add_9/n28 , \add_8/n26 , 
        \add_9/n26 , \add_12/n10 , \add_12/n8 , \add_12/n6 , \add_12/n4 , 
        \add_11/n24 , \add_11/n22 , \add_11/n20 , \add_11/n18 , \add_11/n16 , 
        \add_11/n14 , \add_11/n12 , \add_11/n10 , \add_11/n8 , \add_11/n6 , 
        \add_11/n4 , \add_9/n24 , \add_8/n24 , \add_9/n22 , \add_8/n22 , 
        \add_9/n20 , \add_8/n20 , \add_9/n18 , \add_5/n22 , \add_5/n20 , 
        \add_5/n18 , \add_5/n16 , \add_5/n14 , \add_5/n12 , \add_5/n10 , 
        \add_5/n8 , \add_5/n6 , \add_5/n4 , n14, \add_4/n22 , \add_4/n20 , 
        \add_4/n18 , \add_4/n16 , \add_4/n14 , \add_4/n12 , \add_4/n10 , 
        \add_4/n8 , \add_4/n6 , \add_4/n4 ;
    wire [7:0]n5;
    
    wire n4, \add_3/n14 , \add_3/n12 , \add_3/n10 , \add_3/n8 , \add_3/n6 , 
        \add_3/n4 , \add_3/n2 , n1920, \next_snapshot.top_half ;
    wire [1:0]\next_snapshot.error ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(28)
    
    wire n1605, n1604, n1603, n1602;
    wire [23:0]n805_9;
    wire [23:0]n805_11;
    wire [23:0]n805_13;
    wire [23:0]n805_15;
    wire [23:0]n805_17;
    wire [23:0]n805_19;
    wire [23:0]n805_20;
    
    wire n1340, n1341, n1342, n1343, n1344, n1345, n1346, n1347, 
        n1348, n1349, n1350, n1351, n1352, n1353, n1354, n1355, 
        n1356, n1357, n1358, n1359, n1360, n1361, n1362, n1363, 
        n1364, n1365, n1366, n1367, n1368, n1369, n1370, n1371, 
        n1372, n1373, n1374, n1375, n1376, n1377, n1378, n1379, 
        n1380, n1381, n1382, n1383, n1384, n1385, n1386, n1387, 
        n1388, n1389, n1390, n1391, n1392, n1393, n1394, n1395, 
        n1396, n1397, n1398, n1399, n1400, n1401, n1402, n1403, 
        n1404, n1405, n1406, n1407, n1408, n1409, n1410, n1411, 
        n1412, n1413, n1414, n1415, n1416, n1417, n1418, n1419, 
        n1420, n1421, n1422, n1423, n1424, n1425, n1426, n1427, 
        n1428, n1429, n1430, n1431, n1432, n1433, n1434, n1435, 
        n1436, n1437, n1438, n1439, n1440, n1441, n1442, n1443, 
        n1444, n1445, n1446, n1447, n1448, n1449, n1450, n1451, 
        n1452, n1453, n1454, n1455, n1456, n1457, n1458, n1459, 
        n1460, n1461, n1462, n1463, n1464, n1465, n1466, n1467, 
        n1468, n1469, n1470, n1471, n1472, n1473, n1474, n1475, 
        n1476, n1477, n1478, n1479, n1480, n1481, n1482, n1483, 
        n1484, n1485, n1486, n1487, n1488, n1489, n1490, n1491, 
        n1492, n1493, n1494, n1495, n1496, n1497, n1498, n1499, 
        n1500, n1501, n1502, n1503, n1504, n1505, n1506, n1507, 
        n1508, n1509, n1510, n1511, n1512, n1513, n1514, n1515, 
        n1516, n1517, n1518, n1519, n1520, n1521, n1522, n1523, 
        n1524, n1525, n1526, n1527, n1528, n1529, n1530, n1531, 
        n1532, n1533, n1534, n1535, n1536, n1537, n1538, n1539, 
        n1540, n1541, n1542, n1543, n1544, n1545, n1546, n1547, 
        n1548, n1549, n1550, n1551, n1552, n1553, n1554, n1555, 
        n1556, n1557, n1558, n1559, n1560, n1561, n1562, n1563, 
        n1564, n1565, n1566, n1567, n1568, n1569, n1570, n1571, 
        n1572, n1573, n1574, n1575, n1576, n1577, n1578, n1579, 
        n1580, n1581, n1582, n1583, n1584, n1585, n1586, n1587, 
        n1588, n1589, n1590, n1591, n1592, n1593, n1594, n1595, 
        n1596, n1597, n1598, n1599, n1600, n1601;
    
    EFX_LUT4 LUT__2947 (.I0(\snapshot.edge_bits [0]), .I1(\snapshot.mode [0]), 
            .I2(\snapshot.mode [1]), .O(n1340)) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'h7070 */ ;
    defparam LUT__2947.LUTMASK = 16'h7070;
    EFX_LUT4 LUT__2948 (.I0(\snapshot.mode [0]), .I1(\snapshot.gray [0]), 
            .I2(n1340), .I3(\snapshot.mode [2]), .O(n1341)) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'h004f */ ;
    defparam LUT__2948.LUTMASK = 16'h004f;
    EFX_FF \snapshot.ann11_color[0]~FF  (.D(in_render[2]), .CE(1'b1), .CLK(clk), 
           .SR(rst), .Q(\snapshot.ann11_color [0])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_FF, CLK_POLARITY=1'b1, D_POLARITY=1'b1, CE_POLARITY=1'b1, SR_SYNC=1'b1, SR_SYNC_PRIORITY=1'b1, SR_VALUE=1'b0, SR_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(105)
    defparam \snapshot.ann11_color[0]~FF .CLK_POLARITY = 1'b1;
    defparam \snapshot.ann11_color[0]~FF .CE_POLARITY = 1'b1;
    defparam \snapshot.ann11_color[0]~FF .SR_POLARITY = 1'b1;
    defparam \snapshot.ann11_color[0]~FF .D_POLARITY = 1'b1;
    defparam \snapshot.ann11_color[0]~FF .SR_SYNC = 1'b1;
    defparam \snapshot.ann11_color[0]~FF .SR_VALUE = 1'b0;
    defparam \snapshot.ann11_color[0]~FF .SR_SYNC_PRIORITY = 1'b1;
    EFX_FF \snapshot.x_even[7]~FF  (.D(in_x_even[7]), .CE(1'b1), .CLK(clk), 
           .SR(rst), .Q(\snapshot.x_even [7])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_FF, CLK_POLARITY=1'b1, D_POLARITY=1'b1, CE_POLARITY=1'b1, SR_SYNC=1'b1, SR_SYNC_PRIORITY=1'b1, SR_VALUE=1'b0, SR_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(105)
    defparam \snapshot.x_even[7]~FF .CLK_POLARITY = 1'b1;
    defparam \snapshot.x_even[7]~FF .CE_POLARITY = 1'b1;
    defparam \snapshot.x_even[7]~FF .SR_POLARITY = 1'b1;
    defparam \snapshot.x_even[7]~FF .D_POLARITY = 1'b1;
    defparam \snapshot.x_even[7]~FF .SR_SYNC = 1'b1;
    defparam \snapshot.x_even[7]~FF .SR_VALUE = 1'b0;
    defparam \snapshot.x_even[7]~FF .SR_SYNC_PRIORITY = 1'b1;
    EFX_FF \snapshot.frame_start~FF  (.D(in_frame_start), .CE(1'b1), .CLK(clk), 
           .SR(rst), .Q(\snapshot.frame_start )) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_FF, CLK_POLARITY=1'b1, D_POLARITY=1'b1, CE_POLARITY=1'b1, SR_SYNC=1'b1, SR_SYNC_PRIORITY=1'b1, SR_VALUE=1'b0, SR_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(105)
    defparam \snapshot.frame_start~FF .CLK_POLARITY = 1'b1;
    defparam \snapshot.frame_start~FF .CE_POLARITY = 1'b1;
    defparam \snapshot.frame_start~FF .SR_POLARITY = 1'b1;
    defparam \snapshot.frame_start~FF .D_POLARITY = 1'b1;
    defparam \snapshot.frame_start~FF .SR_SYNC = 1'b1;
    defparam \snapshot.frame_start~FF .SR_VALUE = 1'b0;
    defparam \snapshot.frame_start~FF .SR_SYNC_PRIORITY = 1'b1;
    EFX_FF \out_rgb_pair[0]~FF  (.D(n805_2[0]), .CE(1'b1), .CLK(clk), 
           .SR(n1920), .Q(out_rgb_pair[0])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_FF, CLK_POLARITY=1'b1, D_POLARITY=1'b1, CE_POLARITY=1'b1, SR_SYNC=1'b1, SR_SYNC_PRIORITY=1'b1, SR_VALUE=1'b0, SR_POLARITY=1'b0 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(105)
    defparam \out_rgb_pair[0]~FF .CLK_POLARITY = 1'b1;
    defparam \out_rgb_pair[0]~FF .CE_POLARITY = 1'b1;
    defparam \out_rgb_pair[0]~FF .SR_POLARITY = 1'b0;
    defparam \out_rgb_pair[0]~FF .D_POLARITY = 1'b1;
    defparam \out_rgb_pair[0]~FF .SR_SYNC = 1'b1;
    defparam \out_rgb_pair[0]~FF .SR_VALUE = 1'b0;
    defparam \out_rgb_pair[0]~FF .SR_SYNC_PRIORITY = 1'b1;
    EFX_FF \snapshot.ann11_color[4]~FF  (.D(in_render[6]), .CE(1'b1), .CLK(clk), 
           .SR(rst), .Q(\snapshot.ann11_color [4])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_FF, CLK_POLARITY=1'b1, D_POLARITY=1'b1, CE_POLARITY=1'b1, SR_SYNC=1'b1, SR_SYNC_PRIORITY=1'b1, SR_VALUE=1'b0, SR_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(105)
    defparam \snapshot.ann11_color[4]~FF .CLK_POLARITY = 1'b1;
    defparam \snapshot.ann11_color[4]~FF .CE_POLARITY = 1'b1;
    defparam \snapshot.ann11_color[4]~FF .SR_POLARITY = 1'b1;
    defparam \snapshot.ann11_color[4]~FF .D_POLARITY = 1'b1;
    defparam \snapshot.ann11_color[4]~FF .SR_SYNC = 1'b1;
    defparam \snapshot.ann11_color[4]~FF .SR_VALUE = 1'b0;
    defparam \snapshot.ann11_color[4]~FF .SR_SYNC_PRIORITY = 1'b1;
    EFX_FF \snapshot.ann11_color[5]~FF  (.D(in_render[7]), .CE(1'b1), .CLK(clk), 
           .SR(rst), .Q(\snapshot.ann11_color [5])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_FF, CLK_POLARITY=1'b1, D_POLARITY=1'b1, CE_POLARITY=1'b1, SR_SYNC=1'b1, SR_SYNC_PRIORITY=1'b1, SR_VALUE=1'b0, SR_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(105)
    defparam \snapshot.ann11_color[5]~FF .CLK_POLARITY = 1'b1;
    defparam \snapshot.ann11_color[5]~FF .CE_POLARITY = 1'b1;
    defparam \snapshot.ann11_color[5]~FF .SR_POLARITY = 1'b1;
    defparam \snapshot.ann11_color[5]~FF .D_POLARITY = 1'b1;
    defparam \snapshot.ann11_color[5]~FF .SR_SYNC = 1'b1;
    defparam \snapshot.ann11_color[5]~FF .SR_VALUE = 1'b0;
    defparam \snapshot.ann11_color[5]~FF .SR_SYNC_PRIORITY = 1'b1;
    EFX_FF \snapshot.ann11_color[6]~FF  (.D(in_render[8]), .CE(1'b1), .CLK(clk), 
           .SR(rst), .Q(\snapshot.ann11_color [6])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_FF, CLK_POLARITY=1'b1, D_POLARITY=1'b1, CE_POLARITY=1'b1, SR_SYNC=1'b1, SR_SYNC_PRIORITY=1'b1, SR_VALUE=1'b0, SR_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(105)
    defparam \snapshot.ann11_color[6]~FF .CLK_POLARITY = 1'b1;
    defparam \snapshot.ann11_color[6]~FF .CE_POLARITY = 1'b1;
    defparam \snapshot.ann11_color[6]~FF .SR_POLARITY = 1'b1;
    defparam \snapshot.ann11_color[6]~FF .D_POLARITY = 1'b1;
    defparam \snapshot.ann11_color[6]~FF .SR_SYNC = 1'b1;
    defparam \snapshot.ann11_color[6]~FF .SR_VALUE = 1'b0;
    defparam \snapshot.ann11_color[6]~FF .SR_SYNC_PRIORITY = 1'b1;
    EFX_FF \snapshot.x_even[10]~FF  (.D(in_x_even[10]), .CE(1'b1), .CLK(clk), 
           .SR(rst), .Q(\snapshot.x_even [10])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_FF, CLK_POLARITY=1'b1, D_POLARITY=1'b1, CE_POLARITY=1'b1, SR_SYNC=1'b1, SR_SYNC_PRIORITY=1'b1, SR_VALUE=1'b0, SR_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(105)
    defparam \snapshot.x_even[10]~FF .CLK_POLARITY = 1'b1;
    defparam \snapshot.x_even[10]~FF .CE_POLARITY = 1'b1;
    defparam \snapshot.x_even[10]~FF .SR_POLARITY = 1'b1;
    defparam \snapshot.x_even[10]~FF .D_POLARITY = 1'b1;
    defparam \snapshot.x_even[10]~FF .SR_SYNC = 1'b1;
    defparam \snapshot.x_even[10]~FF .SR_VALUE = 1'b0;
    defparam \snapshot.x_even[10]~FF .SR_SYNC_PRIORITY = 1'b1;
    EFX_FF \snapshot.ann11_color[1]~FF  (.D(in_render[3]), .CE(1'b1), .CLK(clk), 
           .SR(rst), .Q(\snapshot.ann11_color [1])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_FF, CLK_POLARITY=1'b1, D_POLARITY=1'b1, CE_POLARITY=1'b1, SR_SYNC=1'b1, SR_SYNC_PRIORITY=1'b1, SR_VALUE=1'b0, SR_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(105)
    defparam \snapshot.ann11_color[1]~FF .CLK_POLARITY = 1'b1;
    defparam \snapshot.ann11_color[1]~FF .CE_POLARITY = 1'b1;
    defparam \snapshot.ann11_color[1]~FF .SR_POLARITY = 1'b1;
    defparam \snapshot.ann11_color[1]~FF .D_POLARITY = 1'b1;
    defparam \snapshot.ann11_color[1]~FF .SR_SYNC = 1'b1;
    defparam \snapshot.ann11_color[1]~FF .SR_VALUE = 1'b0;
    defparam \snapshot.ann11_color[1]~FF .SR_SYNC_PRIORITY = 1'b1;
    EFX_FF \snapshot.x_even[9]~FF  (.D(in_x_even[9]), .CE(1'b1), .CLK(clk), 
           .SR(rst), .Q(\snapshot.x_even [9])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_FF, CLK_POLARITY=1'b1, D_POLARITY=1'b1, CE_POLARITY=1'b1, SR_SYNC=1'b1, SR_SYNC_PRIORITY=1'b1, SR_VALUE=1'b0, SR_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(105)
    defparam \snapshot.x_even[9]~FF .CLK_POLARITY = 1'b1;
    defparam \snapshot.x_even[9]~FF .CE_POLARITY = 1'b1;
    defparam \snapshot.x_even[9]~FF .SR_POLARITY = 1'b1;
    defparam \snapshot.x_even[9]~FF .D_POLARITY = 1'b1;
    defparam \snapshot.x_even[9]~FF .SR_SYNC = 1'b1;
    defparam \snapshot.x_even[9]~FF .SR_VALUE = 1'b0;
    defparam \snapshot.x_even[9]~FF .SR_SYNC_PRIORITY = 1'b1;
    EFX_FF \snapshot.de~FF  (.D(in_de), .CE(1'b1), .CLK(clk), .SR(rst), 
           .Q(\snapshot.de )) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_FF, CLK_POLARITY=1'b1, D_POLARITY=1'b1, CE_POLARITY=1'b1, SR_SYNC=1'b1, SR_SYNC_PRIORITY=1'b1, SR_VALUE=1'b0, SR_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(105)
    defparam \snapshot.de~FF .CLK_POLARITY = 1'b1;
    defparam \snapshot.de~FF .CE_POLARITY = 1'b1;
    defparam \snapshot.de~FF .SR_POLARITY = 1'b1;
    defparam \snapshot.de~FF .D_POLARITY = 1'b1;
    defparam \snapshot.de~FF .SR_SYNC = 1'b1;
    defparam \snapshot.de~FF .SR_VALUE = 1'b0;
    defparam \snapshot.de~FF .SR_SYNC_PRIORITY = 1'b1;
    EFX_FF \snapshot.x_even[6]~FF  (.D(in_x_even[6]), .CE(1'b1), .CLK(clk), 
           .SR(rst), .Q(\snapshot.x_even [6])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_FF, CLK_POLARITY=1'b1, D_POLARITY=1'b1, CE_POLARITY=1'b1, SR_SYNC=1'b1, SR_SYNC_PRIORITY=1'b1, SR_VALUE=1'b0, SR_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(105)
    defparam \snapshot.x_even[6]~FF .CLK_POLARITY = 1'b1;
    defparam \snapshot.x_even[6]~FF .CE_POLARITY = 1'b1;
    defparam \snapshot.x_even[6]~FF .SR_POLARITY = 1'b1;
    defparam \snapshot.x_even[6]~FF .D_POLARITY = 1'b1;
    defparam \snapshot.x_even[6]~FF .SR_SYNC = 1'b1;
    defparam \snapshot.x_even[6]~FF .SR_VALUE = 1'b0;
    defparam \snapshot.x_even[6]~FF .SR_SYNC_PRIORITY = 1'b1;
    EFX_FF \snapshot.x_even[5]~FF  (.D(in_x_even[5]), .CE(1'b1), .CLK(clk), 
           .SR(rst), .Q(\snapshot.x_even [5])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_FF, CLK_POLARITY=1'b1, D_POLARITY=1'b1, CE_POLARITY=1'b1, SR_SYNC=1'b1, SR_SYNC_PRIORITY=1'b1, SR_VALUE=1'b0, SR_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(105)
    defparam \snapshot.x_even[5]~FF .CLK_POLARITY = 1'b1;
    defparam \snapshot.x_even[5]~FF .CE_POLARITY = 1'b1;
    defparam \snapshot.x_even[5]~FF .SR_POLARITY = 1'b1;
    defparam \snapshot.x_even[5]~FF .D_POLARITY = 1'b1;
    defparam \snapshot.x_even[5]~FF .SR_SYNC = 1'b1;
    defparam \snapshot.x_even[5]~FF .SR_VALUE = 1'b0;
    defparam \snapshot.x_even[5]~FF .SR_SYNC_PRIORITY = 1'b1;
    EFX_FF \snapshot.x_even[8]~FF  (.D(in_x_even[8]), .CE(1'b1), .CLK(clk), 
           .SR(rst), .Q(\snapshot.x_even [8])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_FF, CLK_POLARITY=1'b1, D_POLARITY=1'b1, CE_POLARITY=1'b1, SR_SYNC=1'b1, SR_SYNC_PRIORITY=1'b1, SR_VALUE=1'b0, SR_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(105)
    defparam \snapshot.x_even[8]~FF .CLK_POLARITY = 1'b1;
    defparam \snapshot.x_even[8]~FF .CE_POLARITY = 1'b1;
    defparam \snapshot.x_even[8]~FF .SR_POLARITY = 1'b1;
    defparam \snapshot.x_even[8]~FF .D_POLARITY = 1'b1;
    defparam \snapshot.x_even[8]~FF .SR_SYNC = 1'b1;
    defparam \snapshot.x_even[8]~FF .SR_VALUE = 1'b0;
    defparam \snapshot.x_even[8]~FF .SR_SYNC_PRIORITY = 1'b1;
    EFX_FF \snapshot.ann11_color[2]~FF  (.D(in_render[4]), .CE(1'b1), .CLK(clk), 
           .SR(rst), .Q(\snapshot.ann11_color [2])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_FF, CLK_POLARITY=1'b1, D_POLARITY=1'b1, CE_POLARITY=1'b1, SR_SYNC=1'b1, SR_SYNC_PRIORITY=1'b1, SR_VALUE=1'b0, SR_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(105)
    defparam \snapshot.ann11_color[2]~FF .CLK_POLARITY = 1'b1;
    defparam \snapshot.ann11_color[2]~FF .CE_POLARITY = 1'b1;
    defparam \snapshot.ann11_color[2]~FF .SR_POLARITY = 1'b1;
    defparam \snapshot.ann11_color[2]~FF .D_POLARITY = 1'b1;
    defparam \snapshot.ann11_color[2]~FF .SR_SYNC = 1'b1;
    defparam \snapshot.ann11_color[2]~FF .SR_VALUE = 1'b0;
    defparam \snapshot.ann11_color[2]~FF .SR_SYNC_PRIORITY = 1'b1;
    EFX_FF \out_error[0]~FF  (.D(\snapshot.error [0]), .CE(1'b1), .CLK(clk), 
           .SR(rst), .Q(out_error[0])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_FF, CLK_POLARITY=1'b1, D_POLARITY=1'b1, CE_POLARITY=1'b1, SR_SYNC=1'b1, SR_SYNC_PRIORITY=1'b1, SR_VALUE=1'b0, SR_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(105)
    defparam \out_error[0]~FF .CLK_POLARITY = 1'b1;
    defparam \out_error[0]~FF .CE_POLARITY = 1'b1;
    defparam \out_error[0]~FF .SR_POLARITY = 1'b1;
    defparam \out_error[0]~FF .D_POLARITY = 1'b1;
    defparam \out_error[0]~FF .SR_SYNC = 1'b1;
    defparam \out_error[0]~FF .SR_VALUE = 1'b0;
    defparam \out_error[0]~FF .SR_SYNC_PRIORITY = 1'b1;
    EFX_FF \snapshot.hs~FF  (.D(in_hs), .CE(1'b1), .CLK(clk), .SR(rst), 
           .Q(\snapshot.hs )) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_FF, CLK_POLARITY=1'b1, D_POLARITY=1'b1, CE_POLARITY=1'b1, SR_SYNC=1'b1, SR_SYNC_PRIORITY=1'b1, SR_VALUE=1'b0, SR_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(105)
    defparam \snapshot.hs~FF .CLK_POLARITY = 1'b1;
    defparam \snapshot.hs~FF .CE_POLARITY = 1'b1;
    defparam \snapshot.hs~FF .SR_POLARITY = 1'b1;
    defparam \snapshot.hs~FF .D_POLARITY = 1'b1;
    defparam \snapshot.hs~FF .SR_SYNC = 1'b1;
    defparam \snapshot.hs~FF .SR_VALUE = 1'b0;
    defparam \snapshot.hs~FF .SR_SYNC_PRIORITY = 1'b1;
    EFX_FF \snapshot.x_even[4]~FF  (.D(in_x_even[4]), .CE(1'b1), .CLK(clk), 
           .SR(rst), .Q(\snapshot.x_even [4])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_FF, CLK_POLARITY=1'b1, D_POLARITY=1'b1, CE_POLARITY=1'b1, SR_SYNC=1'b1, SR_SYNC_PRIORITY=1'b1, SR_VALUE=1'b0, SR_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(105)
    defparam \snapshot.x_even[4]~FF .CLK_POLARITY = 1'b1;
    defparam \snapshot.x_even[4]~FF .CE_POLARITY = 1'b1;
    defparam \snapshot.x_even[4]~FF .SR_POLARITY = 1'b1;
    defparam \snapshot.x_even[4]~FF .D_POLARITY = 1'b1;
    defparam \snapshot.x_even[4]~FF .SR_SYNC = 1'b1;
    defparam \snapshot.x_even[4]~FF .SR_VALUE = 1'b0;
    defparam \snapshot.x_even[4]~FF .SR_SYNC_PRIORITY = 1'b1;
    EFX_FF \snapshot.x_even[3]~FF  (.D(in_x_even[3]), .CE(1'b1), .CLK(clk), 
           .SR(rst), .Q(\snapshot.x_even [3])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_FF, CLK_POLARITY=1'b1, D_POLARITY=1'b1, CE_POLARITY=1'b1, SR_SYNC=1'b1, SR_SYNC_PRIORITY=1'b1, SR_VALUE=1'b0, SR_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(105)
    defparam \snapshot.x_even[3]~FF .CLK_POLARITY = 1'b1;
    defparam \snapshot.x_even[3]~FF .CE_POLARITY = 1'b1;
    defparam \snapshot.x_even[3]~FF .SR_POLARITY = 1'b1;
    defparam \snapshot.x_even[3]~FF .D_POLARITY = 1'b1;
    defparam \snapshot.x_even[3]~FF .SR_SYNC = 1'b1;
    defparam \snapshot.x_even[3]~FF .SR_VALUE = 1'b0;
    defparam \snapshot.x_even[3]~FF .SR_SYNC_PRIORITY = 1'b1;
    EFX_FF \out_x_even[0]~FF  (.D(\snapshot.x_even [0]), .CE(1'b1), .CLK(clk), 
           .SR(rst), .Q(out_x_even[0])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_FF, CLK_POLARITY=1'b1, D_POLARITY=1'b1, CE_POLARITY=1'b1, SR_SYNC=1'b1, SR_SYNC_PRIORITY=1'b1, SR_VALUE=1'b0, SR_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(105)
    defparam \out_x_even[0]~FF .CLK_POLARITY = 1'b1;
    defparam \out_x_even[0]~FF .CE_POLARITY = 1'b1;
    defparam \out_x_even[0]~FF .SR_POLARITY = 1'b1;
    defparam \out_x_even[0]~FF .D_POLARITY = 1'b1;
    defparam \out_x_even[0]~FF .SR_SYNC = 1'b1;
    defparam \out_x_even[0]~FF .SR_VALUE = 1'b0;
    defparam \out_x_even[0]~FF .SR_SYNC_PRIORITY = 1'b1;
    EFX_FF \snapshot.ann11_color[3]~FF  (.D(in_render[5]), .CE(1'b1), .CLK(clk), 
           .SR(rst), .Q(\snapshot.ann11_color [3])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_FF, CLK_POLARITY=1'b1, D_POLARITY=1'b1, CE_POLARITY=1'b1, SR_SYNC=1'b1, SR_SYNC_PRIORITY=1'b1, SR_VALUE=1'b0, SR_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(105)
    defparam \snapshot.ann11_color[3]~FF .CLK_POLARITY = 1'b1;
    defparam \snapshot.ann11_color[3]~FF .CE_POLARITY = 1'b1;
    defparam \snapshot.ann11_color[3]~FF .SR_POLARITY = 1'b1;
    defparam \snapshot.ann11_color[3]~FF .D_POLARITY = 1'b1;
    defparam \snapshot.ann11_color[3]~FF .SR_SYNC = 1'b1;
    defparam \snapshot.ann11_color[3]~FF .SR_VALUE = 1'b0;
    defparam \snapshot.ann11_color[3]~FF .SR_SYNC_PRIORITY = 1'b1;
    EFX_FF \snapshot.x_even[2]~FF  (.D(in_x_even[2]), .CE(1'b1), .CLK(clk), 
           .SR(rst), .Q(\snapshot.x_even [2])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_FF, CLK_POLARITY=1'b1, D_POLARITY=1'b1, CE_POLARITY=1'b1, SR_SYNC=1'b1, SR_SYNC_PRIORITY=1'b1, SR_VALUE=1'b0, SR_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(105)
    defparam \snapshot.x_even[2]~FF .CLK_POLARITY = 1'b1;
    defparam \snapshot.x_even[2]~FF .CE_POLARITY = 1'b1;
    defparam \snapshot.x_even[2]~FF .SR_POLARITY = 1'b1;
    defparam \snapshot.x_even[2]~FF .D_POLARITY = 1'b1;
    defparam \snapshot.x_even[2]~FF .SR_SYNC = 1'b1;
    defparam \snapshot.x_even[2]~FF .SR_VALUE = 1'b0;
    defparam \snapshot.x_even[2]~FF .SR_SYNC_PRIORITY = 1'b1;
    EFX_FF \snapshot.rgb[1]~FF  (.D(in_pair[1]), .CE(1'b1), .CLK(clk), 
           .SR(rst), .Q(\snapshot.rgb [1])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_FF, CLK_POLARITY=1'b1, D_POLARITY=1'b1, CE_POLARITY=1'b1, SR_SYNC=1'b1, SR_SYNC_PRIORITY=1'b1, SR_VALUE=1'b0, SR_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(105)
    defparam \snapshot.rgb[1]~FF .CLK_POLARITY = 1'b1;
    defparam \snapshot.rgb[1]~FF .CE_POLARITY = 1'b1;
    defparam \snapshot.rgb[1]~FF .SR_POLARITY = 1'b1;
    defparam \snapshot.rgb[1]~FF .D_POLARITY = 1'b1;
    defparam \snapshot.rgb[1]~FF .SR_SYNC = 1'b1;
    defparam \snapshot.rgb[1]~FF .SR_VALUE = 1'b0;
    defparam \snapshot.rgb[1]~FF .SR_SYNC_PRIORITY = 1'b1;
    EFX_FF \snapshot.rgb[2]~FF  (.D(in_pair[2]), .CE(1'b1), .CLK(clk), 
           .SR(rst), .Q(\snapshot.rgb [2])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_FF, CLK_POLARITY=1'b1, D_POLARITY=1'b1, CE_POLARITY=1'b1, SR_SYNC=1'b1, SR_SYNC_PRIORITY=1'b1, SR_VALUE=1'b0, SR_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(105)
    defparam \snapshot.rgb[2]~FF .CLK_POLARITY = 1'b1;
    defparam \snapshot.rgb[2]~FF .CE_POLARITY = 1'b1;
    defparam \snapshot.rgb[2]~FF .SR_POLARITY = 1'b1;
    defparam \snapshot.rgb[2]~FF .D_POLARITY = 1'b1;
    defparam \snapshot.rgb[2]~FF .SR_SYNC = 1'b1;
    defparam \snapshot.rgb[2]~FF .SR_VALUE = 1'b0;
    defparam \snapshot.rgb[2]~FF .SR_SYNC_PRIORITY = 1'b1;
    EFX_FF \snapshot.rgb[3]~FF  (.D(in_pair[3]), .CE(1'b1), .CLK(clk), 
           .SR(rst), .Q(\snapshot.rgb [3])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_FF, CLK_POLARITY=1'b1, D_POLARITY=1'b1, CE_POLARITY=1'b1, SR_SYNC=1'b1, SR_SYNC_PRIORITY=1'b1, SR_VALUE=1'b0, SR_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(105)
    defparam \snapshot.rgb[3]~FF .CLK_POLARITY = 1'b1;
    defparam \snapshot.rgb[3]~FF .CE_POLARITY = 1'b1;
    defparam \snapshot.rgb[3]~FF .SR_POLARITY = 1'b1;
    defparam \snapshot.rgb[3]~FF .D_POLARITY = 1'b1;
    defparam \snapshot.rgb[3]~FF .SR_SYNC = 1'b1;
    defparam \snapshot.rgb[3]~FF .SR_VALUE = 1'b0;
    defparam \snapshot.rgb[3]~FF .SR_SYNC_PRIORITY = 1'b1;
    EFX_FF \snapshot.rgb[4]~FF  (.D(in_pair[4]), .CE(1'b1), .CLK(clk), 
           .SR(rst), .Q(\snapshot.rgb [4])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_FF, CLK_POLARITY=1'b1, D_POLARITY=1'b1, CE_POLARITY=1'b1, SR_SYNC=1'b1, SR_SYNC_PRIORITY=1'b1, SR_VALUE=1'b0, SR_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(105)
    defparam \snapshot.rgb[4]~FF .CLK_POLARITY = 1'b1;
    defparam \snapshot.rgb[4]~FF .CE_POLARITY = 1'b1;
    defparam \snapshot.rgb[4]~FF .SR_POLARITY = 1'b1;
    defparam \snapshot.rgb[4]~FF .D_POLARITY = 1'b1;
    defparam \snapshot.rgb[4]~FF .SR_SYNC = 1'b1;
    defparam \snapshot.rgb[4]~FF .SR_VALUE = 1'b0;
    defparam \snapshot.rgb[4]~FF .SR_SYNC_PRIORITY = 1'b1;
    EFX_FF \snapshot.rgb[5]~FF  (.D(in_pair[5]), .CE(1'b1), .CLK(clk), 
           .SR(rst), .Q(\snapshot.rgb [5])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_FF, CLK_POLARITY=1'b1, D_POLARITY=1'b1, CE_POLARITY=1'b1, SR_SYNC=1'b1, SR_SYNC_PRIORITY=1'b1, SR_VALUE=1'b0, SR_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(105)
    defparam \snapshot.rgb[5]~FF .CLK_POLARITY = 1'b1;
    defparam \snapshot.rgb[5]~FF .CE_POLARITY = 1'b1;
    defparam \snapshot.rgb[5]~FF .SR_POLARITY = 1'b1;
    defparam \snapshot.rgb[5]~FF .D_POLARITY = 1'b1;
    defparam \snapshot.rgb[5]~FF .SR_SYNC = 1'b1;
    defparam \snapshot.rgb[5]~FF .SR_VALUE = 1'b0;
    defparam \snapshot.rgb[5]~FF .SR_SYNC_PRIORITY = 1'b1;
    EFX_FF \snapshot.rgb[6]~FF  (.D(in_pair[6]), .CE(1'b1), .CLK(clk), 
           .SR(rst), .Q(\snapshot.rgb [6])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_FF, CLK_POLARITY=1'b1, D_POLARITY=1'b1, CE_POLARITY=1'b1, SR_SYNC=1'b1, SR_SYNC_PRIORITY=1'b1, SR_VALUE=1'b0, SR_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(105)
    defparam \snapshot.rgb[6]~FF .CLK_POLARITY = 1'b1;
    defparam \snapshot.rgb[6]~FF .CE_POLARITY = 1'b1;
    defparam \snapshot.rgb[6]~FF .SR_POLARITY = 1'b1;
    defparam \snapshot.rgb[6]~FF .D_POLARITY = 1'b1;
    defparam \snapshot.rgb[6]~FF .SR_SYNC = 1'b1;
    defparam \snapshot.rgb[6]~FF .SR_VALUE = 1'b0;
    defparam \snapshot.rgb[6]~FF .SR_SYNC_PRIORITY = 1'b1;
    EFX_FF \snapshot.rgb[7]~FF  (.D(in_pair[7]), .CE(1'b1), .CLK(clk), 
           .SR(rst), .Q(\snapshot.rgb [7])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_FF, CLK_POLARITY=1'b1, D_POLARITY=1'b1, CE_POLARITY=1'b1, SR_SYNC=1'b1, SR_SYNC_PRIORITY=1'b1, SR_VALUE=1'b0, SR_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(105)
    defparam \snapshot.rgb[7]~FF .CLK_POLARITY = 1'b1;
    defparam \snapshot.rgb[7]~FF .CE_POLARITY = 1'b1;
    defparam \snapshot.rgb[7]~FF .SR_POLARITY = 1'b1;
    defparam \snapshot.rgb[7]~FF .D_POLARITY = 1'b1;
    defparam \snapshot.rgb[7]~FF .SR_SYNC = 1'b1;
    defparam \snapshot.rgb[7]~FF .SR_VALUE = 1'b0;
    defparam \snapshot.rgb[7]~FF .SR_SYNC_PRIORITY = 1'b1;
    EFX_FF \snapshot.rgb[8]~FF  (.D(in_pair[8]), .CE(1'b1), .CLK(clk), 
           .SR(rst), .Q(\snapshot.rgb [8])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_FF, CLK_POLARITY=1'b1, D_POLARITY=1'b1, CE_POLARITY=1'b1, SR_SYNC=1'b1, SR_SYNC_PRIORITY=1'b1, SR_VALUE=1'b0, SR_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(105)
    defparam \snapshot.rgb[8]~FF .CLK_POLARITY = 1'b1;
    defparam \snapshot.rgb[8]~FF .CE_POLARITY = 1'b1;
    defparam \snapshot.rgb[8]~FF .SR_POLARITY = 1'b1;
    defparam \snapshot.rgb[8]~FF .D_POLARITY = 1'b1;
    defparam \snapshot.rgb[8]~FF .SR_SYNC = 1'b1;
    defparam \snapshot.rgb[8]~FF .SR_VALUE = 1'b0;
    defparam \snapshot.rgb[8]~FF .SR_SYNC_PRIORITY = 1'b1;
    EFX_FF \snapshot.rgb[9]~FF  (.D(in_pair[9]), .CE(1'b1), .CLK(clk), 
           .SR(rst), .Q(\snapshot.rgb [9])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_FF, CLK_POLARITY=1'b1, D_POLARITY=1'b1, CE_POLARITY=1'b1, SR_SYNC=1'b1, SR_SYNC_PRIORITY=1'b1, SR_VALUE=1'b0, SR_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(105)
    defparam \snapshot.rgb[9]~FF .CLK_POLARITY = 1'b1;
    defparam \snapshot.rgb[9]~FF .CE_POLARITY = 1'b1;
    defparam \snapshot.rgb[9]~FF .SR_POLARITY = 1'b1;
    defparam \snapshot.rgb[9]~FF .D_POLARITY = 1'b1;
    defparam \snapshot.rgb[9]~FF .SR_SYNC = 1'b1;
    defparam \snapshot.rgb[9]~FF .SR_VALUE = 1'b0;
    defparam \snapshot.rgb[9]~FF .SR_SYNC_PRIORITY = 1'b1;
    EFX_FF \snapshot.rgb[10]~FF  (.D(in_pair[10]), .CE(1'b1), .CLK(clk), 
           .SR(rst), .Q(\snapshot.rgb [10])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_FF, CLK_POLARITY=1'b1, D_POLARITY=1'b1, CE_POLARITY=1'b1, SR_SYNC=1'b1, SR_SYNC_PRIORITY=1'b1, SR_VALUE=1'b0, SR_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(105)
    defparam \snapshot.rgb[10]~FF .CLK_POLARITY = 1'b1;
    defparam \snapshot.rgb[10]~FF .CE_POLARITY = 1'b1;
    defparam \snapshot.rgb[10]~FF .SR_POLARITY = 1'b1;
    defparam \snapshot.rgb[10]~FF .D_POLARITY = 1'b1;
    defparam \snapshot.rgb[10]~FF .SR_SYNC = 1'b1;
    defparam \snapshot.rgb[10]~FF .SR_VALUE = 1'b0;
    defparam \snapshot.rgb[10]~FF .SR_SYNC_PRIORITY = 1'b1;
    EFX_FF \snapshot.rgb[11]~FF  (.D(in_pair[11]), .CE(1'b1), .CLK(clk), 
           .SR(rst), .Q(\snapshot.rgb [11])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_FF, CLK_POLARITY=1'b1, D_POLARITY=1'b1, CE_POLARITY=1'b1, SR_SYNC=1'b1, SR_SYNC_PRIORITY=1'b1, SR_VALUE=1'b0, SR_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(105)
    defparam \snapshot.rgb[11]~FF .CLK_POLARITY = 1'b1;
    defparam \snapshot.rgb[11]~FF .CE_POLARITY = 1'b1;
    defparam \snapshot.rgb[11]~FF .SR_POLARITY = 1'b1;
    defparam \snapshot.rgb[11]~FF .D_POLARITY = 1'b1;
    defparam \snapshot.rgb[11]~FF .SR_SYNC = 1'b1;
    defparam \snapshot.rgb[11]~FF .SR_VALUE = 1'b0;
    defparam \snapshot.rgb[11]~FF .SR_SYNC_PRIORITY = 1'b1;
    EFX_FF \snapshot.rgb[12]~FF  (.D(in_pair[12]), .CE(1'b1), .CLK(clk), 
           .SR(rst), .Q(\snapshot.rgb [12])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_FF, CLK_POLARITY=1'b1, D_POLARITY=1'b1, CE_POLARITY=1'b1, SR_SYNC=1'b1, SR_SYNC_PRIORITY=1'b1, SR_VALUE=1'b0, SR_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(105)
    defparam \snapshot.rgb[12]~FF .CLK_POLARITY = 1'b1;
    defparam \snapshot.rgb[12]~FF .CE_POLARITY = 1'b1;
    defparam \snapshot.rgb[12]~FF .SR_POLARITY = 1'b1;
    defparam \snapshot.rgb[12]~FF .D_POLARITY = 1'b1;
    defparam \snapshot.rgb[12]~FF .SR_SYNC = 1'b1;
    defparam \snapshot.rgb[12]~FF .SR_VALUE = 1'b0;
    defparam \snapshot.rgb[12]~FF .SR_SYNC_PRIORITY = 1'b1;
    EFX_FF \snapshot.rgb[13]~FF  (.D(in_pair[13]), .CE(1'b1), .CLK(clk), 
           .SR(rst), .Q(\snapshot.rgb [13])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_FF, CLK_POLARITY=1'b1, D_POLARITY=1'b1, CE_POLARITY=1'b1, SR_SYNC=1'b1, SR_SYNC_PRIORITY=1'b1, SR_VALUE=1'b0, SR_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(105)
    defparam \snapshot.rgb[13]~FF .CLK_POLARITY = 1'b1;
    defparam \snapshot.rgb[13]~FF .CE_POLARITY = 1'b1;
    defparam \snapshot.rgb[13]~FF .SR_POLARITY = 1'b1;
    defparam \snapshot.rgb[13]~FF .D_POLARITY = 1'b1;
    defparam \snapshot.rgb[13]~FF .SR_SYNC = 1'b1;
    defparam \snapshot.rgb[13]~FF .SR_VALUE = 1'b0;
    defparam \snapshot.rgb[13]~FF .SR_SYNC_PRIORITY = 1'b1;
    EFX_FF \snapshot.rgb[14]~FF  (.D(in_pair[14]), .CE(1'b1), .CLK(clk), 
           .SR(rst), .Q(\snapshot.rgb [14])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_FF, CLK_POLARITY=1'b1, D_POLARITY=1'b1, CE_POLARITY=1'b1, SR_SYNC=1'b1, SR_SYNC_PRIORITY=1'b1, SR_VALUE=1'b0, SR_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(105)
    defparam \snapshot.rgb[14]~FF .CLK_POLARITY = 1'b1;
    defparam \snapshot.rgb[14]~FF .CE_POLARITY = 1'b1;
    defparam \snapshot.rgb[14]~FF .SR_POLARITY = 1'b1;
    defparam \snapshot.rgb[14]~FF .D_POLARITY = 1'b1;
    defparam \snapshot.rgb[14]~FF .SR_SYNC = 1'b1;
    defparam \snapshot.rgb[14]~FF .SR_VALUE = 1'b0;
    defparam \snapshot.rgb[14]~FF .SR_SYNC_PRIORITY = 1'b1;
    EFX_FF \snapshot.rgb[15]~FF  (.D(in_pair[15]), .CE(1'b1), .CLK(clk), 
           .SR(rst), .Q(\snapshot.rgb [15])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_FF, CLK_POLARITY=1'b1, D_POLARITY=1'b1, CE_POLARITY=1'b1, SR_SYNC=1'b1, SR_SYNC_PRIORITY=1'b1, SR_VALUE=1'b0, SR_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(105)
    defparam \snapshot.rgb[15]~FF .CLK_POLARITY = 1'b1;
    defparam \snapshot.rgb[15]~FF .CE_POLARITY = 1'b1;
    defparam \snapshot.rgb[15]~FF .SR_POLARITY = 1'b1;
    defparam \snapshot.rgb[15]~FF .D_POLARITY = 1'b1;
    defparam \snapshot.rgb[15]~FF .SR_SYNC = 1'b1;
    defparam \snapshot.rgb[15]~FF .SR_VALUE = 1'b0;
    defparam \snapshot.rgb[15]~FF .SR_SYNC_PRIORITY = 1'b1;
    EFX_FF \snapshot.rgb[16]~FF  (.D(in_pair[16]), .CE(1'b1), .CLK(clk), 
           .SR(rst), .Q(\snapshot.rgb [16])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_FF, CLK_POLARITY=1'b1, D_POLARITY=1'b1, CE_POLARITY=1'b1, SR_SYNC=1'b1, SR_SYNC_PRIORITY=1'b1, SR_VALUE=1'b0, SR_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(105)
    defparam \snapshot.rgb[16]~FF .CLK_POLARITY = 1'b1;
    defparam \snapshot.rgb[16]~FF .CE_POLARITY = 1'b1;
    defparam \snapshot.rgb[16]~FF .SR_POLARITY = 1'b1;
    defparam \snapshot.rgb[16]~FF .D_POLARITY = 1'b1;
    defparam \snapshot.rgb[16]~FF .SR_SYNC = 1'b1;
    defparam \snapshot.rgb[16]~FF .SR_VALUE = 1'b0;
    defparam \snapshot.rgb[16]~FF .SR_SYNC_PRIORITY = 1'b1;
    EFX_FF \snapshot.rgb[17]~FF  (.D(in_pair[17]), .CE(1'b1), .CLK(clk), 
           .SR(rst), .Q(\snapshot.rgb [17])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_FF, CLK_POLARITY=1'b1, D_POLARITY=1'b1, CE_POLARITY=1'b1, SR_SYNC=1'b1, SR_SYNC_PRIORITY=1'b1, SR_VALUE=1'b0, SR_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(105)
    defparam \snapshot.rgb[17]~FF .CLK_POLARITY = 1'b1;
    defparam \snapshot.rgb[17]~FF .CE_POLARITY = 1'b1;
    defparam \snapshot.rgb[17]~FF .SR_POLARITY = 1'b1;
    defparam \snapshot.rgb[17]~FF .D_POLARITY = 1'b1;
    defparam \snapshot.rgb[17]~FF .SR_SYNC = 1'b1;
    defparam \snapshot.rgb[17]~FF .SR_VALUE = 1'b0;
    defparam \snapshot.rgb[17]~FF .SR_SYNC_PRIORITY = 1'b1;
    EFX_FF \snapshot.rgb[18]~FF  (.D(in_pair[18]), .CE(1'b1), .CLK(clk), 
           .SR(rst), .Q(\snapshot.rgb [18])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_FF, CLK_POLARITY=1'b1, D_POLARITY=1'b1, CE_POLARITY=1'b1, SR_SYNC=1'b1, SR_SYNC_PRIORITY=1'b1, SR_VALUE=1'b0, SR_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(105)
    defparam \snapshot.rgb[18]~FF .CLK_POLARITY = 1'b1;
    defparam \snapshot.rgb[18]~FF .CE_POLARITY = 1'b1;
    defparam \snapshot.rgb[18]~FF .SR_POLARITY = 1'b1;
    defparam \snapshot.rgb[18]~FF .D_POLARITY = 1'b1;
    defparam \snapshot.rgb[18]~FF .SR_SYNC = 1'b1;
    defparam \snapshot.rgb[18]~FF .SR_VALUE = 1'b0;
    defparam \snapshot.rgb[18]~FF .SR_SYNC_PRIORITY = 1'b1;
    EFX_FF \snapshot.rgb[19]~FF  (.D(in_pair[19]), .CE(1'b1), .CLK(clk), 
           .SR(rst), .Q(\snapshot.rgb [19])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_FF, CLK_POLARITY=1'b1, D_POLARITY=1'b1, CE_POLARITY=1'b1, SR_SYNC=1'b1, SR_SYNC_PRIORITY=1'b1, SR_VALUE=1'b0, SR_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(105)
    defparam \snapshot.rgb[19]~FF .CLK_POLARITY = 1'b1;
    defparam \snapshot.rgb[19]~FF .CE_POLARITY = 1'b1;
    defparam \snapshot.rgb[19]~FF .SR_POLARITY = 1'b1;
    defparam \snapshot.rgb[19]~FF .D_POLARITY = 1'b1;
    defparam \snapshot.rgb[19]~FF .SR_SYNC = 1'b1;
    defparam \snapshot.rgb[19]~FF .SR_VALUE = 1'b0;
    defparam \snapshot.rgb[19]~FF .SR_SYNC_PRIORITY = 1'b1;
    EFX_FF \snapshot.rgb[20]~FF  (.D(in_pair[20]), .CE(1'b1), .CLK(clk), 
           .SR(rst), .Q(\snapshot.rgb [20])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_FF, CLK_POLARITY=1'b1, D_POLARITY=1'b1, CE_POLARITY=1'b1, SR_SYNC=1'b1, SR_SYNC_PRIORITY=1'b1, SR_VALUE=1'b0, SR_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(105)
    defparam \snapshot.rgb[20]~FF .CLK_POLARITY = 1'b1;
    defparam \snapshot.rgb[20]~FF .CE_POLARITY = 1'b1;
    defparam \snapshot.rgb[20]~FF .SR_POLARITY = 1'b1;
    defparam \snapshot.rgb[20]~FF .D_POLARITY = 1'b1;
    defparam \snapshot.rgb[20]~FF .SR_SYNC = 1'b1;
    defparam \snapshot.rgb[20]~FF .SR_VALUE = 1'b0;
    defparam \snapshot.rgb[20]~FF .SR_SYNC_PRIORITY = 1'b1;
    EFX_FF \snapshot.rgb[21]~FF  (.D(in_pair[21]), .CE(1'b1), .CLK(clk), 
           .SR(rst), .Q(\snapshot.rgb [21])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_FF, CLK_POLARITY=1'b1, D_POLARITY=1'b1, CE_POLARITY=1'b1, SR_SYNC=1'b1, SR_SYNC_PRIORITY=1'b1, SR_VALUE=1'b0, SR_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(105)
    defparam \snapshot.rgb[21]~FF .CLK_POLARITY = 1'b1;
    defparam \snapshot.rgb[21]~FF .CE_POLARITY = 1'b1;
    defparam \snapshot.rgb[21]~FF .SR_POLARITY = 1'b1;
    defparam \snapshot.rgb[21]~FF .D_POLARITY = 1'b1;
    defparam \snapshot.rgb[21]~FF .SR_SYNC = 1'b1;
    defparam \snapshot.rgb[21]~FF .SR_VALUE = 1'b0;
    defparam \snapshot.rgb[21]~FF .SR_SYNC_PRIORITY = 1'b1;
    EFX_FF \snapshot.rgb[22]~FF  (.D(in_pair[22]), .CE(1'b1), .CLK(clk), 
           .SR(rst), .Q(\snapshot.rgb [22])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_FF, CLK_POLARITY=1'b1, D_POLARITY=1'b1, CE_POLARITY=1'b1, SR_SYNC=1'b1, SR_SYNC_PRIORITY=1'b1, SR_VALUE=1'b0, SR_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(105)
    defparam \snapshot.rgb[22]~FF .CLK_POLARITY = 1'b1;
    defparam \snapshot.rgb[22]~FF .CE_POLARITY = 1'b1;
    defparam \snapshot.rgb[22]~FF .SR_POLARITY = 1'b1;
    defparam \snapshot.rgb[22]~FF .D_POLARITY = 1'b1;
    defparam \snapshot.rgb[22]~FF .SR_SYNC = 1'b1;
    defparam \snapshot.rgb[22]~FF .SR_VALUE = 1'b0;
    defparam \snapshot.rgb[22]~FF .SR_SYNC_PRIORITY = 1'b1;
    EFX_FF \snapshot.rgb[23]~FF  (.D(in_pair[23]), .CE(1'b1), .CLK(clk), 
           .SR(rst), .Q(\snapshot.rgb [23])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_FF, CLK_POLARITY=1'b1, D_POLARITY=1'b1, CE_POLARITY=1'b1, SR_SYNC=1'b1, SR_SYNC_PRIORITY=1'b1, SR_VALUE=1'b0, SR_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(105)
    defparam \snapshot.rgb[23]~FF .CLK_POLARITY = 1'b1;
    defparam \snapshot.rgb[23]~FF .CE_POLARITY = 1'b1;
    defparam \snapshot.rgb[23]~FF .SR_POLARITY = 1'b1;
    defparam \snapshot.rgb[23]~FF .D_POLARITY = 1'b1;
    defparam \snapshot.rgb[23]~FF .SR_SYNC = 1'b1;
    defparam \snapshot.rgb[23]~FF .SR_VALUE = 1'b0;
    defparam \snapshot.rgb[23]~FF .SR_SYNC_PRIORITY = 1'b1;
    EFX_FF \snapshot.rgb[24]~FF  (.D(in_pair[24]), .CE(1'b1), .CLK(clk), 
           .SR(rst), .Q(\snapshot.rgb [24])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_FF, CLK_POLARITY=1'b1, D_POLARITY=1'b1, CE_POLARITY=1'b1, SR_SYNC=1'b1, SR_SYNC_PRIORITY=1'b1, SR_VALUE=1'b0, SR_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(105)
    defparam \snapshot.rgb[24]~FF .CLK_POLARITY = 1'b1;
    defparam \snapshot.rgb[24]~FF .CE_POLARITY = 1'b1;
    defparam \snapshot.rgb[24]~FF .SR_POLARITY = 1'b1;
    defparam \snapshot.rgb[24]~FF .D_POLARITY = 1'b1;
    defparam \snapshot.rgb[24]~FF .SR_SYNC = 1'b1;
    defparam \snapshot.rgb[24]~FF .SR_VALUE = 1'b0;
    defparam \snapshot.rgb[24]~FF .SR_SYNC_PRIORITY = 1'b1;
    EFX_FF \snapshot.rgb[25]~FF  (.D(in_pair[25]), .CE(1'b1), .CLK(clk), 
           .SR(rst), .Q(\snapshot.rgb [25])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_FF, CLK_POLARITY=1'b1, D_POLARITY=1'b1, CE_POLARITY=1'b1, SR_SYNC=1'b1, SR_SYNC_PRIORITY=1'b1, SR_VALUE=1'b0, SR_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(105)
    defparam \snapshot.rgb[25]~FF .CLK_POLARITY = 1'b1;
    defparam \snapshot.rgb[25]~FF .CE_POLARITY = 1'b1;
    defparam \snapshot.rgb[25]~FF .SR_POLARITY = 1'b1;
    defparam \snapshot.rgb[25]~FF .D_POLARITY = 1'b1;
    defparam \snapshot.rgb[25]~FF .SR_SYNC = 1'b1;
    defparam \snapshot.rgb[25]~FF .SR_VALUE = 1'b0;
    defparam \snapshot.rgb[25]~FF .SR_SYNC_PRIORITY = 1'b1;
    EFX_FF \snapshot.rgb[26]~FF  (.D(in_pair[26]), .CE(1'b1), .CLK(clk), 
           .SR(rst), .Q(\snapshot.rgb [26])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_FF, CLK_POLARITY=1'b1, D_POLARITY=1'b1, CE_POLARITY=1'b1, SR_SYNC=1'b1, SR_SYNC_PRIORITY=1'b1, SR_VALUE=1'b0, SR_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(105)
    defparam \snapshot.rgb[26]~FF .CLK_POLARITY = 1'b1;
    defparam \snapshot.rgb[26]~FF .CE_POLARITY = 1'b1;
    defparam \snapshot.rgb[26]~FF .SR_POLARITY = 1'b1;
    defparam \snapshot.rgb[26]~FF .D_POLARITY = 1'b1;
    defparam \snapshot.rgb[26]~FF .SR_SYNC = 1'b1;
    defparam \snapshot.rgb[26]~FF .SR_VALUE = 1'b0;
    defparam \snapshot.rgb[26]~FF .SR_SYNC_PRIORITY = 1'b1;
    EFX_FF \snapshot.rgb[27]~FF  (.D(in_pair[27]), .CE(1'b1), .CLK(clk), 
           .SR(rst), .Q(\snapshot.rgb [27])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_FF, CLK_POLARITY=1'b1, D_POLARITY=1'b1, CE_POLARITY=1'b1, SR_SYNC=1'b1, SR_SYNC_PRIORITY=1'b1, SR_VALUE=1'b0, SR_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(105)
    defparam \snapshot.rgb[27]~FF .CLK_POLARITY = 1'b1;
    defparam \snapshot.rgb[27]~FF .CE_POLARITY = 1'b1;
    defparam \snapshot.rgb[27]~FF .SR_POLARITY = 1'b1;
    defparam \snapshot.rgb[27]~FF .D_POLARITY = 1'b1;
    defparam \snapshot.rgb[27]~FF .SR_SYNC = 1'b1;
    defparam \snapshot.rgb[27]~FF .SR_VALUE = 1'b0;
    defparam \snapshot.rgb[27]~FF .SR_SYNC_PRIORITY = 1'b1;
    EFX_FF \snapshot.rgb[28]~FF  (.D(in_pair[28]), .CE(1'b1), .CLK(clk), 
           .SR(rst), .Q(\snapshot.rgb [28])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_FF, CLK_POLARITY=1'b1, D_POLARITY=1'b1, CE_POLARITY=1'b1, SR_SYNC=1'b1, SR_SYNC_PRIORITY=1'b1, SR_VALUE=1'b0, SR_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(105)
    defparam \snapshot.rgb[28]~FF .CLK_POLARITY = 1'b1;
    defparam \snapshot.rgb[28]~FF .CE_POLARITY = 1'b1;
    defparam \snapshot.rgb[28]~FF .SR_POLARITY = 1'b1;
    defparam \snapshot.rgb[28]~FF .D_POLARITY = 1'b1;
    defparam \snapshot.rgb[28]~FF .SR_SYNC = 1'b1;
    defparam \snapshot.rgb[28]~FF .SR_VALUE = 1'b0;
    defparam \snapshot.rgb[28]~FF .SR_SYNC_PRIORITY = 1'b1;
    EFX_FF \snapshot.rgb[29]~FF  (.D(in_pair[29]), .CE(1'b1), .CLK(clk), 
           .SR(rst), .Q(\snapshot.rgb [29])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_FF, CLK_POLARITY=1'b1, D_POLARITY=1'b1, CE_POLARITY=1'b1, SR_SYNC=1'b1, SR_SYNC_PRIORITY=1'b1, SR_VALUE=1'b0, SR_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(105)
    defparam \snapshot.rgb[29]~FF .CLK_POLARITY = 1'b1;
    defparam \snapshot.rgb[29]~FF .CE_POLARITY = 1'b1;
    defparam \snapshot.rgb[29]~FF .SR_POLARITY = 1'b1;
    defparam \snapshot.rgb[29]~FF .D_POLARITY = 1'b1;
    defparam \snapshot.rgb[29]~FF .SR_SYNC = 1'b1;
    defparam \snapshot.rgb[29]~FF .SR_VALUE = 1'b0;
    defparam \snapshot.rgb[29]~FF .SR_SYNC_PRIORITY = 1'b1;
    EFX_FF \snapshot.rgb[30]~FF  (.D(in_pair[30]), .CE(1'b1), .CLK(clk), 
           .SR(rst), .Q(\snapshot.rgb [30])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_FF, CLK_POLARITY=1'b1, D_POLARITY=1'b1, CE_POLARITY=1'b1, SR_SYNC=1'b1, SR_SYNC_PRIORITY=1'b1, SR_VALUE=1'b0, SR_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(105)
    defparam \snapshot.rgb[30]~FF .CLK_POLARITY = 1'b1;
    defparam \snapshot.rgb[30]~FF .CE_POLARITY = 1'b1;
    defparam \snapshot.rgb[30]~FF .SR_POLARITY = 1'b1;
    defparam \snapshot.rgb[30]~FF .D_POLARITY = 1'b1;
    defparam \snapshot.rgb[30]~FF .SR_SYNC = 1'b1;
    defparam \snapshot.rgb[30]~FF .SR_VALUE = 1'b0;
    defparam \snapshot.rgb[30]~FF .SR_SYNC_PRIORITY = 1'b1;
    EFX_FF \snapshot.rgb[31]~FF  (.D(in_pair[31]), .CE(1'b1), .CLK(clk), 
           .SR(rst), .Q(\snapshot.rgb [31])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_FF, CLK_POLARITY=1'b1, D_POLARITY=1'b1, CE_POLARITY=1'b1, SR_SYNC=1'b1, SR_SYNC_PRIORITY=1'b1, SR_VALUE=1'b0, SR_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(105)
    defparam \snapshot.rgb[31]~FF .CLK_POLARITY = 1'b1;
    defparam \snapshot.rgb[31]~FF .CE_POLARITY = 1'b1;
    defparam \snapshot.rgb[31]~FF .SR_POLARITY = 1'b1;
    defparam \snapshot.rgb[31]~FF .D_POLARITY = 1'b1;
    defparam \snapshot.rgb[31]~FF .SR_SYNC = 1'b1;
    defparam \snapshot.rgb[31]~FF .SR_VALUE = 1'b0;
    defparam \snapshot.rgb[31]~FF .SR_SYNC_PRIORITY = 1'b1;
    EFX_FF \snapshot.rgb[32]~FF  (.D(in_pair[32]), .CE(1'b1), .CLK(clk), 
           .SR(rst), .Q(\snapshot.rgb [32])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_FF, CLK_POLARITY=1'b1, D_POLARITY=1'b1, CE_POLARITY=1'b1, SR_SYNC=1'b1, SR_SYNC_PRIORITY=1'b1, SR_VALUE=1'b0, SR_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(105)
    defparam \snapshot.rgb[32]~FF .CLK_POLARITY = 1'b1;
    defparam \snapshot.rgb[32]~FF .CE_POLARITY = 1'b1;
    defparam \snapshot.rgb[32]~FF .SR_POLARITY = 1'b1;
    defparam \snapshot.rgb[32]~FF .D_POLARITY = 1'b1;
    defparam \snapshot.rgb[32]~FF .SR_SYNC = 1'b1;
    defparam \snapshot.rgb[32]~FF .SR_VALUE = 1'b0;
    defparam \snapshot.rgb[32]~FF .SR_SYNC_PRIORITY = 1'b1;
    EFX_FF \snapshot.rgb[33]~FF  (.D(in_pair[33]), .CE(1'b1), .CLK(clk), 
           .SR(rst), .Q(\snapshot.rgb [33])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_FF, CLK_POLARITY=1'b1, D_POLARITY=1'b1, CE_POLARITY=1'b1, SR_SYNC=1'b1, SR_SYNC_PRIORITY=1'b1, SR_VALUE=1'b0, SR_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(105)
    defparam \snapshot.rgb[33]~FF .CLK_POLARITY = 1'b1;
    defparam \snapshot.rgb[33]~FF .CE_POLARITY = 1'b1;
    defparam \snapshot.rgb[33]~FF .SR_POLARITY = 1'b1;
    defparam \snapshot.rgb[33]~FF .D_POLARITY = 1'b1;
    defparam \snapshot.rgb[33]~FF .SR_SYNC = 1'b1;
    defparam \snapshot.rgb[33]~FF .SR_VALUE = 1'b0;
    defparam \snapshot.rgb[33]~FF .SR_SYNC_PRIORITY = 1'b1;
    EFX_FF \snapshot.rgb[34]~FF  (.D(in_pair[34]), .CE(1'b1), .CLK(clk), 
           .SR(rst), .Q(\snapshot.rgb [34])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_FF, CLK_POLARITY=1'b1, D_POLARITY=1'b1, CE_POLARITY=1'b1, SR_SYNC=1'b1, SR_SYNC_PRIORITY=1'b1, SR_VALUE=1'b0, SR_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(105)
    defparam \snapshot.rgb[34]~FF .CLK_POLARITY = 1'b1;
    defparam \snapshot.rgb[34]~FF .CE_POLARITY = 1'b1;
    defparam \snapshot.rgb[34]~FF .SR_POLARITY = 1'b1;
    defparam \snapshot.rgb[34]~FF .D_POLARITY = 1'b1;
    defparam \snapshot.rgb[34]~FF .SR_SYNC = 1'b1;
    defparam \snapshot.rgb[34]~FF .SR_VALUE = 1'b0;
    defparam \snapshot.rgb[34]~FF .SR_SYNC_PRIORITY = 1'b1;
    EFX_FF \snapshot.rgb[35]~FF  (.D(in_pair[35]), .CE(1'b1), .CLK(clk), 
           .SR(rst), .Q(\snapshot.rgb [35])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_FF, CLK_POLARITY=1'b1, D_POLARITY=1'b1, CE_POLARITY=1'b1, SR_SYNC=1'b1, SR_SYNC_PRIORITY=1'b1, SR_VALUE=1'b0, SR_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(105)
    defparam \snapshot.rgb[35]~FF .CLK_POLARITY = 1'b1;
    defparam \snapshot.rgb[35]~FF .CE_POLARITY = 1'b1;
    defparam \snapshot.rgb[35]~FF .SR_POLARITY = 1'b1;
    defparam \snapshot.rgb[35]~FF .D_POLARITY = 1'b1;
    defparam \snapshot.rgb[35]~FF .SR_SYNC = 1'b1;
    defparam \snapshot.rgb[35]~FF .SR_VALUE = 1'b0;
    defparam \snapshot.rgb[35]~FF .SR_SYNC_PRIORITY = 1'b1;
    EFX_FF \snapshot.rgb[36]~FF  (.D(in_pair[36]), .CE(1'b1), .CLK(clk), 
           .SR(rst), .Q(\snapshot.rgb [36])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_FF, CLK_POLARITY=1'b1, D_POLARITY=1'b1, CE_POLARITY=1'b1, SR_SYNC=1'b1, SR_SYNC_PRIORITY=1'b1, SR_VALUE=1'b0, SR_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(105)
    defparam \snapshot.rgb[36]~FF .CLK_POLARITY = 1'b1;
    defparam \snapshot.rgb[36]~FF .CE_POLARITY = 1'b1;
    defparam \snapshot.rgb[36]~FF .SR_POLARITY = 1'b1;
    defparam \snapshot.rgb[36]~FF .D_POLARITY = 1'b1;
    defparam \snapshot.rgb[36]~FF .SR_SYNC = 1'b1;
    defparam \snapshot.rgb[36]~FF .SR_VALUE = 1'b0;
    defparam \snapshot.rgb[36]~FF .SR_SYNC_PRIORITY = 1'b1;
    EFX_FF \snapshot.rgb[37]~FF  (.D(in_pair[37]), .CE(1'b1), .CLK(clk), 
           .SR(rst), .Q(\snapshot.rgb [37])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_FF, CLK_POLARITY=1'b1, D_POLARITY=1'b1, CE_POLARITY=1'b1, SR_SYNC=1'b1, SR_SYNC_PRIORITY=1'b1, SR_VALUE=1'b0, SR_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(105)
    defparam \snapshot.rgb[37]~FF .CLK_POLARITY = 1'b1;
    defparam \snapshot.rgb[37]~FF .CE_POLARITY = 1'b1;
    defparam \snapshot.rgb[37]~FF .SR_POLARITY = 1'b1;
    defparam \snapshot.rgb[37]~FF .D_POLARITY = 1'b1;
    defparam \snapshot.rgb[37]~FF .SR_SYNC = 1'b1;
    defparam \snapshot.rgb[37]~FF .SR_VALUE = 1'b0;
    defparam \snapshot.rgb[37]~FF .SR_SYNC_PRIORITY = 1'b1;
    EFX_FF \snapshot.rgb[38]~FF  (.D(in_pair[38]), .CE(1'b1), .CLK(clk), 
           .SR(rst), .Q(\snapshot.rgb [38])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_FF, CLK_POLARITY=1'b1, D_POLARITY=1'b1, CE_POLARITY=1'b1, SR_SYNC=1'b1, SR_SYNC_PRIORITY=1'b1, SR_VALUE=1'b0, SR_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(105)
    defparam \snapshot.rgb[38]~FF .CLK_POLARITY = 1'b1;
    defparam \snapshot.rgb[38]~FF .CE_POLARITY = 1'b1;
    defparam \snapshot.rgb[38]~FF .SR_POLARITY = 1'b1;
    defparam \snapshot.rgb[38]~FF .D_POLARITY = 1'b1;
    defparam \snapshot.rgb[38]~FF .SR_SYNC = 1'b1;
    defparam \snapshot.rgb[38]~FF .SR_VALUE = 1'b0;
    defparam \snapshot.rgb[38]~FF .SR_SYNC_PRIORITY = 1'b1;
    EFX_FF \snapshot.rgb[39]~FF  (.D(in_pair[39]), .CE(1'b1), .CLK(clk), 
           .SR(rst), .Q(\snapshot.rgb [39])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_FF, CLK_POLARITY=1'b1, D_POLARITY=1'b1, CE_POLARITY=1'b1, SR_SYNC=1'b1, SR_SYNC_PRIORITY=1'b1, SR_VALUE=1'b0, SR_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(105)
    defparam \snapshot.rgb[39]~FF .CLK_POLARITY = 1'b1;
    defparam \snapshot.rgb[39]~FF .CE_POLARITY = 1'b1;
    defparam \snapshot.rgb[39]~FF .SR_POLARITY = 1'b1;
    defparam \snapshot.rgb[39]~FF .D_POLARITY = 1'b1;
    defparam \snapshot.rgb[39]~FF .SR_SYNC = 1'b1;
    defparam \snapshot.rgb[39]~FF .SR_VALUE = 1'b0;
    defparam \snapshot.rgb[39]~FF .SR_SYNC_PRIORITY = 1'b1;
    EFX_FF \snapshot.rgb[40]~FF  (.D(in_pair[40]), .CE(1'b1), .CLK(clk), 
           .SR(rst), .Q(\snapshot.rgb [40])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_FF, CLK_POLARITY=1'b1, D_POLARITY=1'b1, CE_POLARITY=1'b1, SR_SYNC=1'b1, SR_SYNC_PRIORITY=1'b1, SR_VALUE=1'b0, SR_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(105)
    defparam \snapshot.rgb[40]~FF .CLK_POLARITY = 1'b1;
    defparam \snapshot.rgb[40]~FF .CE_POLARITY = 1'b1;
    defparam \snapshot.rgb[40]~FF .SR_POLARITY = 1'b1;
    defparam \snapshot.rgb[40]~FF .D_POLARITY = 1'b1;
    defparam \snapshot.rgb[40]~FF .SR_SYNC = 1'b1;
    defparam \snapshot.rgb[40]~FF .SR_VALUE = 1'b0;
    defparam \snapshot.rgb[40]~FF .SR_SYNC_PRIORITY = 1'b1;
    EFX_FF \snapshot.rgb[41]~FF  (.D(in_pair[41]), .CE(1'b1), .CLK(clk), 
           .SR(rst), .Q(\snapshot.rgb [41])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_FF, CLK_POLARITY=1'b1, D_POLARITY=1'b1, CE_POLARITY=1'b1, SR_SYNC=1'b1, SR_SYNC_PRIORITY=1'b1, SR_VALUE=1'b0, SR_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(105)
    defparam \snapshot.rgb[41]~FF .CLK_POLARITY = 1'b1;
    defparam \snapshot.rgb[41]~FF .CE_POLARITY = 1'b1;
    defparam \snapshot.rgb[41]~FF .SR_POLARITY = 1'b1;
    defparam \snapshot.rgb[41]~FF .D_POLARITY = 1'b1;
    defparam \snapshot.rgb[41]~FF .SR_SYNC = 1'b1;
    defparam \snapshot.rgb[41]~FF .SR_VALUE = 1'b0;
    defparam \snapshot.rgb[41]~FF .SR_SYNC_PRIORITY = 1'b1;
    EFX_FF \snapshot.rgb[42]~FF  (.D(in_pair[42]), .CE(1'b1), .CLK(clk), 
           .SR(rst), .Q(\snapshot.rgb [42])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_FF, CLK_POLARITY=1'b1, D_POLARITY=1'b1, CE_POLARITY=1'b1, SR_SYNC=1'b1, SR_SYNC_PRIORITY=1'b1, SR_VALUE=1'b0, SR_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(105)
    defparam \snapshot.rgb[42]~FF .CLK_POLARITY = 1'b1;
    defparam \snapshot.rgb[42]~FF .CE_POLARITY = 1'b1;
    defparam \snapshot.rgb[42]~FF .SR_POLARITY = 1'b1;
    defparam \snapshot.rgb[42]~FF .D_POLARITY = 1'b1;
    defparam \snapshot.rgb[42]~FF .SR_SYNC = 1'b1;
    defparam \snapshot.rgb[42]~FF .SR_VALUE = 1'b0;
    defparam \snapshot.rgb[42]~FF .SR_SYNC_PRIORITY = 1'b1;
    EFX_FF \snapshot.rgb[43]~FF  (.D(in_pair[43]), .CE(1'b1), .CLK(clk), 
           .SR(rst), .Q(\snapshot.rgb [43])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_FF, CLK_POLARITY=1'b1, D_POLARITY=1'b1, CE_POLARITY=1'b1, SR_SYNC=1'b1, SR_SYNC_PRIORITY=1'b1, SR_VALUE=1'b0, SR_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(105)
    defparam \snapshot.rgb[43]~FF .CLK_POLARITY = 1'b1;
    defparam \snapshot.rgb[43]~FF .CE_POLARITY = 1'b1;
    defparam \snapshot.rgb[43]~FF .SR_POLARITY = 1'b1;
    defparam \snapshot.rgb[43]~FF .D_POLARITY = 1'b1;
    defparam \snapshot.rgb[43]~FF .SR_SYNC = 1'b1;
    defparam \snapshot.rgb[43]~FF .SR_VALUE = 1'b0;
    defparam \snapshot.rgb[43]~FF .SR_SYNC_PRIORITY = 1'b1;
    EFX_FF \snapshot.rgb[44]~FF  (.D(in_pair[44]), .CE(1'b1), .CLK(clk), 
           .SR(rst), .Q(\snapshot.rgb [44])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_FF, CLK_POLARITY=1'b1, D_POLARITY=1'b1, CE_POLARITY=1'b1, SR_SYNC=1'b1, SR_SYNC_PRIORITY=1'b1, SR_VALUE=1'b0, SR_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(105)
    defparam \snapshot.rgb[44]~FF .CLK_POLARITY = 1'b1;
    defparam \snapshot.rgb[44]~FF .CE_POLARITY = 1'b1;
    defparam \snapshot.rgb[44]~FF .SR_POLARITY = 1'b1;
    defparam \snapshot.rgb[44]~FF .D_POLARITY = 1'b1;
    defparam \snapshot.rgb[44]~FF .SR_SYNC = 1'b1;
    defparam \snapshot.rgb[44]~FF .SR_VALUE = 1'b0;
    defparam \snapshot.rgb[44]~FF .SR_SYNC_PRIORITY = 1'b1;
    EFX_FF \snapshot.rgb[45]~FF  (.D(in_pair[45]), .CE(1'b1), .CLK(clk), 
           .SR(rst), .Q(\snapshot.rgb [45])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_FF, CLK_POLARITY=1'b1, D_POLARITY=1'b1, CE_POLARITY=1'b1, SR_SYNC=1'b1, SR_SYNC_PRIORITY=1'b1, SR_VALUE=1'b0, SR_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(105)
    defparam \snapshot.rgb[45]~FF .CLK_POLARITY = 1'b1;
    defparam \snapshot.rgb[45]~FF .CE_POLARITY = 1'b1;
    defparam \snapshot.rgb[45]~FF .SR_POLARITY = 1'b1;
    defparam \snapshot.rgb[45]~FF .D_POLARITY = 1'b1;
    defparam \snapshot.rgb[45]~FF .SR_SYNC = 1'b1;
    defparam \snapshot.rgb[45]~FF .SR_VALUE = 1'b0;
    defparam \snapshot.rgb[45]~FF .SR_SYNC_PRIORITY = 1'b1;
    EFX_FF \snapshot.rgb[46]~FF  (.D(in_pair[46]), .CE(1'b1), .CLK(clk), 
           .SR(rst), .Q(\snapshot.rgb [46])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_FF, CLK_POLARITY=1'b1, D_POLARITY=1'b1, CE_POLARITY=1'b1, SR_SYNC=1'b1, SR_SYNC_PRIORITY=1'b1, SR_VALUE=1'b0, SR_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(105)
    defparam \snapshot.rgb[46]~FF .CLK_POLARITY = 1'b1;
    defparam \snapshot.rgb[46]~FF .CE_POLARITY = 1'b1;
    defparam \snapshot.rgb[46]~FF .SR_POLARITY = 1'b1;
    defparam \snapshot.rgb[46]~FF .D_POLARITY = 1'b1;
    defparam \snapshot.rgb[46]~FF .SR_SYNC = 1'b1;
    defparam \snapshot.rgb[46]~FF .SR_VALUE = 1'b0;
    defparam \snapshot.rgb[46]~FF .SR_SYNC_PRIORITY = 1'b1;
    EFX_FF \snapshot.rgb[47]~FF  (.D(in_pair[47]), .CE(1'b1), .CLK(clk), 
           .SR(rst), .Q(\snapshot.rgb [47])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_FF, CLK_POLARITY=1'b1, D_POLARITY=1'b1, CE_POLARITY=1'b1, SR_SYNC=1'b1, SR_SYNC_PRIORITY=1'b1, SR_VALUE=1'b0, SR_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(105)
    defparam \snapshot.rgb[47]~FF .CLK_POLARITY = 1'b1;
    defparam \snapshot.rgb[47]~FF .CE_POLARITY = 1'b1;
    defparam \snapshot.rgb[47]~FF .SR_POLARITY = 1'b1;
    defparam \snapshot.rgb[47]~FF .D_POLARITY = 1'b1;
    defparam \snapshot.rgb[47]~FF .SR_SYNC = 1'b1;
    defparam \snapshot.rgb[47]~FF .SR_VALUE = 1'b0;
    defparam \snapshot.rgb[47]~FF .SR_SYNC_PRIORITY = 1'b1;
    EFX_FF \snapshot.x_even[1]~FF  (.D(in_x_even[1]), .CE(1'b1), .CLK(clk), 
           .SR(rst), .Q(\snapshot.x_even [1])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_FF, CLK_POLARITY=1'b1, D_POLARITY=1'b1, CE_POLARITY=1'b1, SR_SYNC=1'b1, SR_SYNC_PRIORITY=1'b1, SR_VALUE=1'b0, SR_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(105)
    defparam \snapshot.x_even[1]~FF .CLK_POLARITY = 1'b1;
    defparam \snapshot.x_even[1]~FF .CE_POLARITY = 1'b1;
    defparam \snapshot.x_even[1]~FF .SR_POLARITY = 1'b1;
    defparam \snapshot.x_even[1]~FF .D_POLARITY = 1'b1;
    defparam \snapshot.x_even[1]~FF .SR_SYNC = 1'b1;
    defparam \snapshot.x_even[1]~FF .SR_VALUE = 1'b0;
    defparam \snapshot.x_even[1]~FF .SR_SYNC_PRIORITY = 1'b1;
    EFX_FF \snapshot.rgb[0]~FF  (.D(in_pair[0]), .CE(1'b1), .CLK(clk), 
           .SR(rst), .Q(\snapshot.rgb [0])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_FF, CLK_POLARITY=1'b1, D_POLARITY=1'b1, CE_POLARITY=1'b1, SR_SYNC=1'b1, SR_SYNC_PRIORITY=1'b1, SR_VALUE=1'b0, SR_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(105)
    defparam \snapshot.rgb[0]~FF .CLK_POLARITY = 1'b1;
    defparam \snapshot.rgb[0]~FF .CE_POLARITY = 1'b1;
    defparam \snapshot.rgb[0]~FF .SR_POLARITY = 1'b1;
    defparam \snapshot.rgb[0]~FF .D_POLARITY = 1'b1;
    defparam \snapshot.rgb[0]~FF .SR_SYNC = 1'b1;
    defparam \snapshot.rgb[0]~FF .SR_VALUE = 1'b0;
    defparam \snapshot.rgb[0]~FF .SR_SYNC_PRIORITY = 1'b1;
    EFX_FF \snapshot.x_even[0]~FF  (.D(in_x_even[0]), .CE(1'b1), .CLK(clk), 
           .SR(rst), .Q(\snapshot.x_even [0])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_FF, CLK_POLARITY=1'b1, D_POLARITY=1'b1, CE_POLARITY=1'b1, SR_SYNC=1'b1, SR_SYNC_PRIORITY=1'b1, SR_VALUE=1'b0, SR_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(105)
    defparam \snapshot.x_even[0]~FF .CLK_POLARITY = 1'b1;
    defparam \snapshot.x_even[0]~FF .CE_POLARITY = 1'b1;
    defparam \snapshot.x_even[0]~FF .SR_POLARITY = 1'b1;
    defparam \snapshot.x_even[0]~FF .D_POLARITY = 1'b1;
    defparam \snapshot.x_even[0]~FF .SR_SYNC = 1'b1;
    defparam \snapshot.x_even[0]~FF .SR_VALUE = 1'b0;
    defparam \snapshot.x_even[0]~FF .SR_SYNC_PRIORITY = 1'b1;
    EFX_FF \snapshot.gray[13]~FF  (.D(\next_snapshot.gray [13]), .CE(1'b1), 
           .CLK(clk), .SR(rst), .Q(\snapshot.gray [13])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_FF, CLK_POLARITY=1'b1, D_POLARITY=1'b1, CE_POLARITY=1'b1, SR_SYNC=1'b1, SR_SYNC_PRIORITY=1'b1, SR_VALUE=1'b0, SR_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(105)
    defparam \snapshot.gray[13]~FF .CLK_POLARITY = 1'b1;
    defparam \snapshot.gray[13]~FF .CE_POLARITY = 1'b1;
    defparam \snapshot.gray[13]~FF .SR_POLARITY = 1'b1;
    defparam \snapshot.gray[13]~FF .D_POLARITY = 1'b1;
    defparam \snapshot.gray[13]~FF .SR_SYNC = 1'b1;
    defparam \snapshot.gray[13]~FF .SR_VALUE = 1'b0;
    defparam \snapshot.gray[13]~FF .SR_SYNC_PRIORITY = 1'b1;
    EFX_FF \snapshot.gray[14]~FF  (.D(\next_snapshot.gray [14]), .CE(1'b1), 
           .CLK(clk), .SR(rst), .Q(\snapshot.gray [14])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_FF, CLK_POLARITY=1'b1, D_POLARITY=1'b1, CE_POLARITY=1'b1, SR_SYNC=1'b1, SR_SYNC_PRIORITY=1'b1, SR_VALUE=1'b0, SR_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(105)
    defparam \snapshot.gray[14]~FF .CLK_POLARITY = 1'b1;
    defparam \snapshot.gray[14]~FF .CE_POLARITY = 1'b1;
    defparam \snapshot.gray[14]~FF .SR_POLARITY = 1'b1;
    defparam \snapshot.gray[14]~FF .D_POLARITY = 1'b1;
    defparam \snapshot.gray[14]~FF .SR_SYNC = 1'b1;
    defparam \snapshot.gray[14]~FF .SR_VALUE = 1'b0;
    defparam \snapshot.gray[14]~FF .SR_SYNC_PRIORITY = 1'b1;
    EFX_FF \snapshot.gray[15]~FF  (.D(\next_snapshot.gray [15]), .CE(1'b1), 
           .CLK(clk), .SR(rst), .Q(\snapshot.gray [15])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_FF, CLK_POLARITY=1'b1, D_POLARITY=1'b1, CE_POLARITY=1'b1, SR_SYNC=1'b1, SR_SYNC_PRIORITY=1'b1, SR_VALUE=1'b0, SR_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(105)
    defparam \snapshot.gray[15]~FF .CLK_POLARITY = 1'b1;
    defparam \snapshot.gray[15]~FF .CE_POLARITY = 1'b1;
    defparam \snapshot.gray[15]~FF .SR_POLARITY = 1'b1;
    defparam \snapshot.gray[15]~FF .D_POLARITY = 1'b1;
    defparam \snapshot.gray[15]~FF .SR_SYNC = 1'b1;
    defparam \snapshot.gray[15]~FF .SR_VALUE = 1'b0;
    defparam \snapshot.gray[15]~FF .SR_SYNC_PRIORITY = 1'b1;
    EFX_FF \snapshot.y[10]~FF  (.D(in_y[10]), .CE(1'b1), .CLK(clk), .SR(rst), 
           .Q(\snapshot.y [10])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_FF, CLK_POLARITY=1'b1, D_POLARITY=1'b1, CE_POLARITY=1'b1, SR_SYNC=1'b1, SR_SYNC_PRIORITY=1'b1, SR_VALUE=1'b0, SR_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(105)
    defparam \snapshot.y[10]~FF .CLK_POLARITY = 1'b1;
    defparam \snapshot.y[10]~FF .CE_POLARITY = 1'b1;
    defparam \snapshot.y[10]~FF .SR_POLARITY = 1'b1;
    defparam \snapshot.y[10]~FF .D_POLARITY = 1'b1;
    defparam \snapshot.y[10]~FF .SR_SYNC = 1'b1;
    defparam \snapshot.y[10]~FF .SR_VALUE = 1'b0;
    defparam \snapshot.y[10]~FF .SR_SYNC_PRIORITY = 1'b1;
    EFX_FF \snapshot.gray[11]~FF  (.D(\next_snapshot.gray [11]), .CE(1'b1), 
           .CLK(clk), .SR(rst), .Q(\snapshot.gray [11])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_FF, CLK_POLARITY=1'b1, D_POLARITY=1'b1, CE_POLARITY=1'b1, SR_SYNC=1'b1, SR_SYNC_PRIORITY=1'b1, SR_VALUE=1'b0, SR_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(105)
    defparam \snapshot.gray[11]~FF .CLK_POLARITY = 1'b1;
    defparam \snapshot.gray[11]~FF .CE_POLARITY = 1'b1;
    defparam \snapshot.gray[11]~FF .SR_POLARITY = 1'b1;
    defparam \snapshot.gray[11]~FF .D_POLARITY = 1'b1;
    defparam \snapshot.gray[11]~FF .SR_SYNC = 1'b1;
    defparam \snapshot.gray[11]~FF .SR_VALUE = 1'b0;
    defparam \snapshot.gray[11]~FF .SR_SYNC_PRIORITY = 1'b1;
    EFX_FF \snapshot.gray[12]~FF  (.D(\next_snapshot.gray [12]), .CE(1'b1), 
           .CLK(clk), .SR(rst), .Q(\snapshot.gray [12])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_FF, CLK_POLARITY=1'b1, D_POLARITY=1'b1, CE_POLARITY=1'b1, SR_SYNC=1'b1, SR_SYNC_PRIORITY=1'b1, SR_VALUE=1'b0, SR_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(105)
    defparam \snapshot.gray[12]~FF .CLK_POLARITY = 1'b1;
    defparam \snapshot.gray[12]~FF .CE_POLARITY = 1'b1;
    defparam \snapshot.gray[12]~FF .SR_POLARITY = 1'b1;
    defparam \snapshot.gray[12]~FF .D_POLARITY = 1'b1;
    defparam \snapshot.gray[12]~FF .SR_SYNC = 1'b1;
    defparam \snapshot.gray[12]~FF .SR_VALUE = 1'b0;
    defparam \snapshot.gray[12]~FF .SR_SYNC_PRIORITY = 1'b1;
    EFX_FF \snapshot.y[9]~FF  (.D(in_y[9]), .CE(1'b1), .CLK(clk), .SR(rst), 
           .Q(\snapshot.y [9])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_FF, CLK_POLARITY=1'b1, D_POLARITY=1'b1, CE_POLARITY=1'b1, SR_SYNC=1'b1, SR_SYNC_PRIORITY=1'b1, SR_VALUE=1'b0, SR_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(105)
    defparam \snapshot.y[9]~FF .CLK_POLARITY = 1'b1;
    defparam \snapshot.y[9]~FF .CE_POLARITY = 1'b1;
    defparam \snapshot.y[9]~FF .SR_POLARITY = 1'b1;
    defparam \snapshot.y[9]~FF .D_POLARITY = 1'b1;
    defparam \snapshot.y[9]~FF .SR_SYNC = 1'b1;
    defparam \snapshot.y[9]~FF .SR_VALUE = 1'b0;
    defparam \snapshot.y[9]~FF .SR_SYNC_PRIORITY = 1'b1;
    EFX_FF \snapshot.y[8]~FF  (.D(in_y[8]), .CE(1'b1), .CLK(clk), .SR(rst), 
           .Q(\snapshot.y [8])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_FF, CLK_POLARITY=1'b1, D_POLARITY=1'b1, CE_POLARITY=1'b1, SR_SYNC=1'b1, SR_SYNC_PRIORITY=1'b1, SR_VALUE=1'b0, SR_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(105)
    defparam \snapshot.y[8]~FF .CLK_POLARITY = 1'b1;
    defparam \snapshot.y[8]~FF .CE_POLARITY = 1'b1;
    defparam \snapshot.y[8]~FF .SR_POLARITY = 1'b1;
    defparam \snapshot.y[8]~FF .D_POLARITY = 1'b1;
    defparam \snapshot.y[8]~FF .SR_SYNC = 1'b1;
    defparam \snapshot.y[8]~FF .SR_VALUE = 1'b0;
    defparam \snapshot.y[8]~FF .SR_SYNC_PRIORITY = 1'b1;
    EFX_FF \snapshot.y[7]~FF  (.D(in_y[7]), .CE(1'b1), .CLK(clk), .SR(rst), 
           .Q(\snapshot.y [7])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_FF, CLK_POLARITY=1'b1, D_POLARITY=1'b1, CE_POLARITY=1'b1, SR_SYNC=1'b1, SR_SYNC_PRIORITY=1'b1, SR_VALUE=1'b0, SR_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(105)
    defparam \snapshot.y[7]~FF .CLK_POLARITY = 1'b1;
    defparam \snapshot.y[7]~FF .CE_POLARITY = 1'b1;
    defparam \snapshot.y[7]~FF .SR_POLARITY = 1'b1;
    defparam \snapshot.y[7]~FF .D_POLARITY = 1'b1;
    defparam \snapshot.y[7]~FF .SR_SYNC = 1'b1;
    defparam \snapshot.y[7]~FF .SR_VALUE = 1'b0;
    defparam \snapshot.y[7]~FF .SR_SYNC_PRIORITY = 1'b1;
    EFX_FF \snapshot.show_ann~FF  (.D(in_render[0]), .CE(1'b1), .CLK(clk), 
           .SR(rst), .Q(\snapshot.show_ann )) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_FF, CLK_POLARITY=1'b1, D_POLARITY=1'b1, CE_POLARITY=1'b1, SR_SYNC=1'b1, SR_SYNC_PRIORITY=1'b1, SR_VALUE=1'b0, SR_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(105)
    defparam \snapshot.show_ann~FF .CLK_POLARITY = 1'b1;
    defparam \snapshot.show_ann~FF .CE_POLARITY = 1'b1;
    defparam \snapshot.show_ann~FF .SR_POLARITY = 1'b1;
    defparam \snapshot.show_ann~FF .D_POLARITY = 1'b1;
    defparam \snapshot.show_ann~FF .SR_SYNC = 1'b1;
    defparam \snapshot.show_ann~FF .SR_VALUE = 1'b0;
    defparam \snapshot.show_ann~FF .SR_SYNC_PRIORITY = 1'b1;
    EFX_FF \snapshot.show_edge~FF  (.D(in_render[1]), .CE(1'b1), .CLK(clk), 
           .SR(rst), .Q(\snapshot.show_edge )) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_FF, CLK_POLARITY=1'b1, D_POLARITY=1'b1, CE_POLARITY=1'b1, SR_SYNC=1'b1, SR_SYNC_PRIORITY=1'b1, SR_VALUE=1'b0, SR_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(105)
    defparam \snapshot.show_edge~FF .CLK_POLARITY = 1'b1;
    defparam \snapshot.show_edge~FF .CE_POLARITY = 1'b1;
    defparam \snapshot.show_edge~FF .SR_POLARITY = 1'b1;
    defparam \snapshot.show_edge~FF .D_POLARITY = 1'b1;
    defparam \snapshot.show_edge~FF .SR_SYNC = 1'b1;
    defparam \snapshot.show_edge~FF .SR_VALUE = 1'b0;
    defparam \snapshot.show_edge~FF .SR_SYNC_PRIORITY = 1'b1;
    EFX_FF \snapshot.top_half~FF  (.D(\next_snapshot.top_half ), .CE(1'b1), 
           .CLK(clk), .SR(rst), .Q(\snapshot.top_half )) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_FF, CLK_POLARITY=1'b1, D_POLARITY=1'b1, CE_POLARITY=1'b1, SR_SYNC=1'b1, SR_SYNC_PRIORITY=1'b1, SR_VALUE=1'b0, SR_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(105)
    defparam \snapshot.top_half~FF .CLK_POLARITY = 1'b1;
    defparam \snapshot.top_half~FF .CE_POLARITY = 1'b1;
    defparam \snapshot.top_half~FF .SR_POLARITY = 1'b1;
    defparam \snapshot.top_half~FF .D_POLARITY = 1'b1;
    defparam \snapshot.top_half~FF .SR_SYNC = 1'b1;
    defparam \snapshot.top_half~FF .SR_VALUE = 1'b0;
    defparam \snapshot.top_half~FF .SR_SYNC_PRIORITY = 1'b1;
    EFX_FF \snapshot.mode[0]~FF  (.D(in_render[109]), .CE(1'b1), .CLK(clk), 
           .SR(rst), .Q(\snapshot.mode [0])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_FF, CLK_POLARITY=1'b1, D_POLARITY=1'b1, CE_POLARITY=1'b1, SR_SYNC=1'b1, SR_SYNC_PRIORITY=1'b1, SR_VALUE=1'b0, SR_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(105)
    defparam \snapshot.mode[0]~FF .CLK_POLARITY = 1'b1;
    defparam \snapshot.mode[0]~FF .CE_POLARITY = 1'b1;
    defparam \snapshot.mode[0]~FF .SR_POLARITY = 1'b1;
    defparam \snapshot.mode[0]~FF .D_POLARITY = 1'b1;
    defparam \snapshot.mode[0]~FF .SR_SYNC = 1'b1;
    defparam \snapshot.mode[0]~FF .SR_VALUE = 1'b0;
    defparam \snapshot.mode[0]~FF .SR_SYNC_PRIORITY = 1'b1;
    EFX_FF \snapshot.mode[1]~FF  (.D(in_render[110]), .CE(1'b1), .CLK(clk), 
           .SR(rst), .Q(\snapshot.mode [1])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_FF, CLK_POLARITY=1'b1, D_POLARITY=1'b1, CE_POLARITY=1'b1, SR_SYNC=1'b1, SR_SYNC_PRIORITY=1'b1, SR_VALUE=1'b0, SR_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(105)
    defparam \snapshot.mode[1]~FF .CLK_POLARITY = 1'b1;
    defparam \snapshot.mode[1]~FF .CE_POLARITY = 1'b1;
    defparam \snapshot.mode[1]~FF .SR_POLARITY = 1'b1;
    defparam \snapshot.mode[1]~FF .D_POLARITY = 1'b1;
    defparam \snapshot.mode[1]~FF .SR_SYNC = 1'b1;
    defparam \snapshot.mode[1]~FF .SR_VALUE = 1'b0;
    defparam \snapshot.mode[1]~FF .SR_SYNC_PRIORITY = 1'b1;
    EFX_FF \snapshot.mode[2]~FF  (.D(in_render[111]), .CE(1'b1), .CLK(clk), 
           .SR(rst), .Q(\snapshot.mode [2])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_FF, CLK_POLARITY=1'b1, D_POLARITY=1'b1, CE_POLARITY=1'b1, SR_SYNC=1'b1, SR_SYNC_PRIORITY=1'b1, SR_VALUE=1'b0, SR_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(105)
    defparam \snapshot.mode[2]~FF .CLK_POLARITY = 1'b1;
    defparam \snapshot.mode[2]~FF .CE_POLARITY = 1'b1;
    defparam \snapshot.mode[2]~FF .SR_POLARITY = 1'b1;
    defparam \snapshot.mode[2]~FF .D_POLARITY = 1'b1;
    defparam \snapshot.mode[2]~FF .SR_SYNC = 1'b1;
    defparam \snapshot.mode[2]~FF .SR_VALUE = 1'b0;
    defparam \snapshot.mode[2]~FF .SR_SYNC_PRIORITY = 1'b1;
    EFX_FF \snapshot.ann[0]~FF  (.D(in_pair[50]), .CE(1'b1), .CLK(clk), 
           .SR(rst), .Q(\snapshot.ann [0])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_FF, CLK_POLARITY=1'b1, D_POLARITY=1'b1, CE_POLARITY=1'b1, SR_SYNC=1'b1, SR_SYNC_PRIORITY=1'b1, SR_VALUE=1'b0, SR_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(105)
    defparam \snapshot.ann[0]~FF .CLK_POLARITY = 1'b1;
    defparam \snapshot.ann[0]~FF .CE_POLARITY = 1'b1;
    defparam \snapshot.ann[0]~FF .SR_POLARITY = 1'b1;
    defparam \snapshot.ann[0]~FF .D_POLARITY = 1'b1;
    defparam \snapshot.ann[0]~FF .SR_SYNC = 1'b1;
    defparam \snapshot.ann[0]~FF .SR_VALUE = 1'b0;
    defparam \snapshot.ann[0]~FF .SR_SYNC_PRIORITY = 1'b1;
    EFX_FF \snapshot.ann[1]~FF  (.D(in_pair[51]), .CE(1'b1), .CLK(clk), 
           .SR(rst), .Q(\snapshot.ann [1])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_FF, CLK_POLARITY=1'b1, D_POLARITY=1'b1, CE_POLARITY=1'b1, SR_SYNC=1'b1, SR_SYNC_PRIORITY=1'b1, SR_VALUE=1'b0, SR_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(105)
    defparam \snapshot.ann[1]~FF .CLK_POLARITY = 1'b1;
    defparam \snapshot.ann[1]~FF .CE_POLARITY = 1'b1;
    defparam \snapshot.ann[1]~FF .SR_POLARITY = 1'b1;
    defparam \snapshot.ann[1]~FF .D_POLARITY = 1'b1;
    defparam \snapshot.ann[1]~FF .SR_SYNC = 1'b1;
    defparam \snapshot.ann[1]~FF .SR_VALUE = 1'b0;
    defparam \snapshot.ann[1]~FF .SR_SYNC_PRIORITY = 1'b1;
    EFX_FF \snapshot.ann[2]~FF  (.D(in_pair[52]), .CE(1'b1), .CLK(clk), 
           .SR(rst), .Q(\snapshot.ann [2])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_FF, CLK_POLARITY=1'b1, D_POLARITY=1'b1, CE_POLARITY=1'b1, SR_SYNC=1'b1, SR_SYNC_PRIORITY=1'b1, SR_VALUE=1'b0, SR_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(105)
    defparam \snapshot.ann[2]~FF .CLK_POLARITY = 1'b1;
    defparam \snapshot.ann[2]~FF .CE_POLARITY = 1'b1;
    defparam \snapshot.ann[2]~FF .SR_POLARITY = 1'b1;
    defparam \snapshot.ann[2]~FF .D_POLARITY = 1'b1;
    defparam \snapshot.ann[2]~FF .SR_SYNC = 1'b1;
    defparam \snapshot.ann[2]~FF .SR_VALUE = 1'b0;
    defparam \snapshot.ann[2]~FF .SR_SYNC_PRIORITY = 1'b1;
    EFX_FF \snapshot.ann[3]~FF  (.D(in_pair[53]), .CE(1'b1), .CLK(clk), 
           .SR(rst), .Q(\snapshot.ann [3])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_FF, CLK_POLARITY=1'b1, D_POLARITY=1'b1, CE_POLARITY=1'b1, SR_SYNC=1'b1, SR_SYNC_PRIORITY=1'b1, SR_VALUE=1'b0, SR_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(105)
    defparam \snapshot.ann[3]~FF .CLK_POLARITY = 1'b1;
    defparam \snapshot.ann[3]~FF .CE_POLARITY = 1'b1;
    defparam \snapshot.ann[3]~FF .SR_POLARITY = 1'b1;
    defparam \snapshot.ann[3]~FF .D_POLARITY = 1'b1;
    defparam \snapshot.ann[3]~FF .SR_SYNC = 1'b1;
    defparam \snapshot.ann[3]~FF .SR_VALUE = 1'b0;
    defparam \snapshot.ann[3]~FF .SR_SYNC_PRIORITY = 1'b1;
    EFX_FF \snapshot.edge_bits[0]~FF  (.D(in_pair[48]), .CE(1'b1), .CLK(clk), 
           .SR(rst), .Q(\snapshot.edge_bits [0])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_FF, CLK_POLARITY=1'b1, D_POLARITY=1'b1, CE_POLARITY=1'b1, SR_SYNC=1'b1, SR_SYNC_PRIORITY=1'b1, SR_VALUE=1'b0, SR_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(105)
    defparam \snapshot.edge_bits[0]~FF .CLK_POLARITY = 1'b1;
    defparam \snapshot.edge_bits[0]~FF .CE_POLARITY = 1'b1;
    defparam \snapshot.edge_bits[0]~FF .SR_POLARITY = 1'b1;
    defparam \snapshot.edge_bits[0]~FF .D_POLARITY = 1'b1;
    defparam \snapshot.edge_bits[0]~FF .SR_SYNC = 1'b1;
    defparam \snapshot.edge_bits[0]~FF .SR_VALUE = 1'b0;
    defparam \snapshot.edge_bits[0]~FF .SR_SYNC_PRIORITY = 1'b1;
    EFX_FF \snapshot.edge_bits[1]~FF  (.D(in_pair[49]), .CE(1'b1), .CLK(clk), 
           .SR(rst), .Q(\snapshot.edge_bits [1])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_FF, CLK_POLARITY=1'b1, D_POLARITY=1'b1, CE_POLARITY=1'b1, SR_SYNC=1'b1, SR_SYNC_PRIORITY=1'b1, SR_VALUE=1'b0, SR_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(105)
    defparam \snapshot.edge_bits[1]~FF .CLK_POLARITY = 1'b1;
    defparam \snapshot.edge_bits[1]~FF .CE_POLARITY = 1'b1;
    defparam \snapshot.edge_bits[1]~FF .SR_POLARITY = 1'b1;
    defparam \snapshot.edge_bits[1]~FF .D_POLARITY = 1'b1;
    defparam \snapshot.edge_bits[1]~FF .SR_SYNC = 1'b1;
    defparam \snapshot.edge_bits[1]~FF .SR_VALUE = 1'b0;
    defparam \snapshot.edge_bits[1]~FF .SR_SYNC_PRIORITY = 1'b1;
    EFX_FF \snapshot.gray[0]~FF  (.D(\next_snapshot.gray [0]), .CE(1'b1), 
           .CLK(clk), .SR(rst), .Q(\snapshot.gray [0])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_FF, CLK_POLARITY=1'b1, D_POLARITY=1'b1, CE_POLARITY=1'b1, SR_SYNC=1'b1, SR_SYNC_PRIORITY=1'b1, SR_VALUE=1'b0, SR_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(105)
    defparam \snapshot.gray[0]~FF .CLK_POLARITY = 1'b1;
    defparam \snapshot.gray[0]~FF .CE_POLARITY = 1'b1;
    defparam \snapshot.gray[0]~FF .SR_POLARITY = 1'b1;
    defparam \snapshot.gray[0]~FF .D_POLARITY = 1'b1;
    defparam \snapshot.gray[0]~FF .SR_SYNC = 1'b1;
    defparam \snapshot.gray[0]~FF .SR_VALUE = 1'b0;
    defparam \snapshot.gray[0]~FF .SR_SYNC_PRIORITY = 1'b1;
    EFX_FF \snapshot.gray[1]~FF  (.D(\next_snapshot.gray [1]), .CE(1'b1), 
           .CLK(clk), .SR(rst), .Q(\snapshot.gray [1])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_FF, CLK_POLARITY=1'b1, D_POLARITY=1'b1, CE_POLARITY=1'b1, SR_SYNC=1'b1, SR_SYNC_PRIORITY=1'b1, SR_VALUE=1'b0, SR_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(105)
    defparam \snapshot.gray[1]~FF .CLK_POLARITY = 1'b1;
    defparam \snapshot.gray[1]~FF .CE_POLARITY = 1'b1;
    defparam \snapshot.gray[1]~FF .SR_POLARITY = 1'b1;
    defparam \snapshot.gray[1]~FF .D_POLARITY = 1'b1;
    defparam \snapshot.gray[1]~FF .SR_SYNC = 1'b1;
    defparam \snapshot.gray[1]~FF .SR_VALUE = 1'b0;
    defparam \snapshot.gray[1]~FF .SR_SYNC_PRIORITY = 1'b1;
    EFX_FF \snapshot.gray[2]~FF  (.D(\next_snapshot.gray [2]), .CE(1'b1), 
           .CLK(clk), .SR(rst), .Q(\snapshot.gray [2])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_FF, CLK_POLARITY=1'b1, D_POLARITY=1'b1, CE_POLARITY=1'b1, SR_SYNC=1'b1, SR_SYNC_PRIORITY=1'b1, SR_VALUE=1'b0, SR_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(105)
    defparam \snapshot.gray[2]~FF .CLK_POLARITY = 1'b1;
    defparam \snapshot.gray[2]~FF .CE_POLARITY = 1'b1;
    defparam \snapshot.gray[2]~FF .SR_POLARITY = 1'b1;
    defparam \snapshot.gray[2]~FF .D_POLARITY = 1'b1;
    defparam \snapshot.gray[2]~FF .SR_SYNC = 1'b1;
    defparam \snapshot.gray[2]~FF .SR_VALUE = 1'b0;
    defparam \snapshot.gray[2]~FF .SR_SYNC_PRIORITY = 1'b1;
    EFX_FF \snapshot.gray[3]~FF  (.D(\next_snapshot.gray [3]), .CE(1'b1), 
           .CLK(clk), .SR(rst), .Q(\snapshot.gray [3])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_FF, CLK_POLARITY=1'b1, D_POLARITY=1'b1, CE_POLARITY=1'b1, SR_SYNC=1'b1, SR_SYNC_PRIORITY=1'b1, SR_VALUE=1'b0, SR_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(105)
    defparam \snapshot.gray[3]~FF .CLK_POLARITY = 1'b1;
    defparam \snapshot.gray[3]~FF .CE_POLARITY = 1'b1;
    defparam \snapshot.gray[3]~FF .SR_POLARITY = 1'b1;
    defparam \snapshot.gray[3]~FF .D_POLARITY = 1'b1;
    defparam \snapshot.gray[3]~FF .SR_SYNC = 1'b1;
    defparam \snapshot.gray[3]~FF .SR_VALUE = 1'b0;
    defparam \snapshot.gray[3]~FF .SR_SYNC_PRIORITY = 1'b1;
    EFX_FF \snapshot.gray[4]~FF  (.D(\next_snapshot.gray [4]), .CE(1'b1), 
           .CLK(clk), .SR(rst), .Q(\snapshot.gray [4])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_FF, CLK_POLARITY=1'b1, D_POLARITY=1'b1, CE_POLARITY=1'b1, SR_SYNC=1'b1, SR_SYNC_PRIORITY=1'b1, SR_VALUE=1'b0, SR_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(105)
    defparam \snapshot.gray[4]~FF .CLK_POLARITY = 1'b1;
    defparam \snapshot.gray[4]~FF .CE_POLARITY = 1'b1;
    defparam \snapshot.gray[4]~FF .SR_POLARITY = 1'b1;
    defparam \snapshot.gray[4]~FF .D_POLARITY = 1'b1;
    defparam \snapshot.gray[4]~FF .SR_SYNC = 1'b1;
    defparam \snapshot.gray[4]~FF .SR_VALUE = 1'b0;
    defparam \snapshot.gray[4]~FF .SR_SYNC_PRIORITY = 1'b1;
    EFX_FF \snapshot.gray[5]~FF  (.D(\next_snapshot.gray [5]), .CE(1'b1), 
           .CLK(clk), .SR(rst), .Q(\snapshot.gray [5])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_FF, CLK_POLARITY=1'b1, D_POLARITY=1'b1, CE_POLARITY=1'b1, SR_SYNC=1'b1, SR_SYNC_PRIORITY=1'b1, SR_VALUE=1'b0, SR_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(105)
    defparam \snapshot.gray[5]~FF .CLK_POLARITY = 1'b1;
    defparam \snapshot.gray[5]~FF .CE_POLARITY = 1'b1;
    defparam \snapshot.gray[5]~FF .SR_POLARITY = 1'b1;
    defparam \snapshot.gray[5]~FF .D_POLARITY = 1'b1;
    defparam \snapshot.gray[5]~FF .SR_SYNC = 1'b1;
    defparam \snapshot.gray[5]~FF .SR_VALUE = 1'b0;
    defparam \snapshot.gray[5]~FF .SR_SYNC_PRIORITY = 1'b1;
    EFX_FF \snapshot.gray[6]~FF  (.D(\next_snapshot.gray [6]), .CE(1'b1), 
           .CLK(clk), .SR(rst), .Q(\snapshot.gray [6])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_FF, CLK_POLARITY=1'b1, D_POLARITY=1'b1, CE_POLARITY=1'b1, SR_SYNC=1'b1, SR_SYNC_PRIORITY=1'b1, SR_VALUE=1'b0, SR_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(105)
    defparam \snapshot.gray[6]~FF .CLK_POLARITY = 1'b1;
    defparam \snapshot.gray[6]~FF .CE_POLARITY = 1'b1;
    defparam \snapshot.gray[6]~FF .SR_POLARITY = 1'b1;
    defparam \snapshot.gray[6]~FF .D_POLARITY = 1'b1;
    defparam \snapshot.gray[6]~FF .SR_SYNC = 1'b1;
    defparam \snapshot.gray[6]~FF .SR_VALUE = 1'b0;
    defparam \snapshot.gray[6]~FF .SR_SYNC_PRIORITY = 1'b1;
    EFX_FF \snapshot.gray[7]~FF  (.D(\next_snapshot.gray [7]), .CE(1'b1), 
           .CLK(clk), .SR(rst), .Q(\snapshot.gray [7])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_FF, CLK_POLARITY=1'b1, D_POLARITY=1'b1, CE_POLARITY=1'b1, SR_SYNC=1'b1, SR_SYNC_PRIORITY=1'b1, SR_VALUE=1'b0, SR_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(105)
    defparam \snapshot.gray[7]~FF .CLK_POLARITY = 1'b1;
    defparam \snapshot.gray[7]~FF .CE_POLARITY = 1'b1;
    defparam \snapshot.gray[7]~FF .SR_POLARITY = 1'b1;
    defparam \snapshot.gray[7]~FF .D_POLARITY = 1'b1;
    defparam \snapshot.gray[7]~FF .SR_SYNC = 1'b1;
    defparam \snapshot.gray[7]~FF .SR_VALUE = 1'b0;
    defparam \snapshot.gray[7]~FF .SR_SYNC_PRIORITY = 1'b1;
    EFX_FF \snapshot.gray[8]~FF  (.D(\next_snapshot.gray [8]), .CE(1'b1), 
           .CLK(clk), .SR(rst), .Q(\snapshot.gray [8])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_FF, CLK_POLARITY=1'b1, D_POLARITY=1'b1, CE_POLARITY=1'b1, SR_SYNC=1'b1, SR_SYNC_PRIORITY=1'b1, SR_VALUE=1'b0, SR_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(105)
    defparam \snapshot.gray[8]~FF .CLK_POLARITY = 1'b1;
    defparam \snapshot.gray[8]~FF .CE_POLARITY = 1'b1;
    defparam \snapshot.gray[8]~FF .SR_POLARITY = 1'b1;
    defparam \snapshot.gray[8]~FF .D_POLARITY = 1'b1;
    defparam \snapshot.gray[8]~FF .SR_SYNC = 1'b1;
    defparam \snapshot.gray[8]~FF .SR_VALUE = 1'b0;
    defparam \snapshot.gray[8]~FF .SR_SYNC_PRIORITY = 1'b1;
    EFX_FF \snapshot.gray[9]~FF  (.D(\next_snapshot.gray [9]), .CE(1'b1), 
           .CLK(clk), .SR(rst), .Q(\snapshot.gray [9])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_FF, CLK_POLARITY=1'b1, D_POLARITY=1'b1, CE_POLARITY=1'b1, SR_SYNC=1'b1, SR_SYNC_PRIORITY=1'b1, SR_VALUE=1'b0, SR_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(105)
    defparam \snapshot.gray[9]~FF .CLK_POLARITY = 1'b1;
    defparam \snapshot.gray[9]~FF .CE_POLARITY = 1'b1;
    defparam \snapshot.gray[9]~FF .SR_POLARITY = 1'b1;
    defparam \snapshot.gray[9]~FF .D_POLARITY = 1'b1;
    defparam \snapshot.gray[9]~FF .SR_SYNC = 1'b1;
    defparam \snapshot.gray[9]~FF .SR_VALUE = 1'b0;
    defparam \snapshot.gray[9]~FF .SR_SYNC_PRIORITY = 1'b1;
    EFX_FF \snapshot.gray[10]~FF  (.D(\next_snapshot.gray [10]), .CE(1'b1), 
           .CLK(clk), .SR(rst), .Q(\snapshot.gray [10])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_FF, CLK_POLARITY=1'b1, D_POLARITY=1'b1, CE_POLARITY=1'b1, SR_SYNC=1'b1, SR_SYNC_PRIORITY=1'b1, SR_VALUE=1'b0, SR_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(105)
    defparam \snapshot.gray[10]~FF .CLK_POLARITY = 1'b1;
    defparam \snapshot.gray[10]~FF .CE_POLARITY = 1'b1;
    defparam \snapshot.gray[10]~FF .SR_POLARITY = 1'b1;
    defparam \snapshot.gray[10]~FF .D_POLARITY = 1'b1;
    defparam \snapshot.gray[10]~FF .SR_SYNC = 1'b1;
    defparam \snapshot.gray[10]~FF .SR_VALUE = 1'b0;
    defparam \snapshot.gray[10]~FF .SR_SYNC_PRIORITY = 1'b1;
    EFX_FF \snapshot.y[6]~FF  (.D(in_y[6]), .CE(1'b1), .CLK(clk), .SR(rst), 
           .Q(\snapshot.y [6])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_FF, CLK_POLARITY=1'b1, D_POLARITY=1'b1, CE_POLARITY=1'b1, SR_SYNC=1'b1, SR_SYNC_PRIORITY=1'b1, SR_VALUE=1'b0, SR_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(105)
    defparam \snapshot.y[6]~FF .CLK_POLARITY = 1'b1;
    defparam \snapshot.y[6]~FF .CE_POLARITY = 1'b1;
    defparam \snapshot.y[6]~FF .SR_POLARITY = 1'b1;
    defparam \snapshot.y[6]~FF .D_POLARITY = 1'b1;
    defparam \snapshot.y[6]~FF .SR_SYNC = 1'b1;
    defparam \snapshot.y[6]~FF .SR_VALUE = 1'b0;
    defparam \snapshot.y[6]~FF .SR_SYNC_PRIORITY = 1'b1;
    EFX_FF \snapshot.edge_color[1]~FF  (.D(in_render[75]), .CE(1'b1), .CLK(clk), 
           .SR(rst), .Q(\snapshot.edge_color [1])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_FF, CLK_POLARITY=1'b1, D_POLARITY=1'b1, CE_POLARITY=1'b1, SR_SYNC=1'b1, SR_SYNC_PRIORITY=1'b1, SR_VALUE=1'b0, SR_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(105)
    defparam \snapshot.edge_color[1]~FF .CLK_POLARITY = 1'b1;
    defparam \snapshot.edge_color[1]~FF .CE_POLARITY = 1'b1;
    defparam \snapshot.edge_color[1]~FF .SR_POLARITY = 1'b1;
    defparam \snapshot.edge_color[1]~FF .D_POLARITY = 1'b1;
    defparam \snapshot.edge_color[1]~FF .SR_SYNC = 1'b1;
    defparam \snapshot.edge_color[1]~FF .SR_VALUE = 1'b0;
    defparam \snapshot.edge_color[1]~FF .SR_SYNC_PRIORITY = 1'b1;
    EFX_FF \snapshot.edge_color[2]~FF  (.D(in_render[76]), .CE(1'b1), .CLK(clk), 
           .SR(rst), .Q(\snapshot.edge_color [2])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_FF, CLK_POLARITY=1'b1, D_POLARITY=1'b1, CE_POLARITY=1'b1, SR_SYNC=1'b1, SR_SYNC_PRIORITY=1'b1, SR_VALUE=1'b0, SR_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(105)
    defparam \snapshot.edge_color[2]~FF .CLK_POLARITY = 1'b1;
    defparam \snapshot.edge_color[2]~FF .CE_POLARITY = 1'b1;
    defparam \snapshot.edge_color[2]~FF .SR_POLARITY = 1'b1;
    defparam \snapshot.edge_color[2]~FF .D_POLARITY = 1'b1;
    defparam \snapshot.edge_color[2]~FF .SR_SYNC = 1'b1;
    defparam \snapshot.edge_color[2]~FF .SR_VALUE = 1'b0;
    defparam \snapshot.edge_color[2]~FF .SR_SYNC_PRIORITY = 1'b1;
    EFX_FF \snapshot.edge_color[3]~FF  (.D(in_render[77]), .CE(1'b1), .CLK(clk), 
           .SR(rst), .Q(\snapshot.edge_color [3])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_FF, CLK_POLARITY=1'b1, D_POLARITY=1'b1, CE_POLARITY=1'b1, SR_SYNC=1'b1, SR_SYNC_PRIORITY=1'b1, SR_VALUE=1'b0, SR_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(105)
    defparam \snapshot.edge_color[3]~FF .CLK_POLARITY = 1'b1;
    defparam \snapshot.edge_color[3]~FF .CE_POLARITY = 1'b1;
    defparam \snapshot.edge_color[3]~FF .SR_POLARITY = 1'b1;
    defparam \snapshot.edge_color[3]~FF .D_POLARITY = 1'b1;
    defparam \snapshot.edge_color[3]~FF .SR_SYNC = 1'b1;
    defparam \snapshot.edge_color[3]~FF .SR_VALUE = 1'b0;
    defparam \snapshot.edge_color[3]~FF .SR_SYNC_PRIORITY = 1'b1;
    EFX_FF \snapshot.edge_color[4]~FF  (.D(in_render[78]), .CE(1'b1), .CLK(clk), 
           .SR(rst), .Q(\snapshot.edge_color [4])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_FF, CLK_POLARITY=1'b1, D_POLARITY=1'b1, CE_POLARITY=1'b1, SR_SYNC=1'b1, SR_SYNC_PRIORITY=1'b1, SR_VALUE=1'b0, SR_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(105)
    defparam \snapshot.edge_color[4]~FF .CLK_POLARITY = 1'b1;
    defparam \snapshot.edge_color[4]~FF .CE_POLARITY = 1'b1;
    defparam \snapshot.edge_color[4]~FF .SR_POLARITY = 1'b1;
    defparam \snapshot.edge_color[4]~FF .D_POLARITY = 1'b1;
    defparam \snapshot.edge_color[4]~FF .SR_SYNC = 1'b1;
    defparam \snapshot.edge_color[4]~FF .SR_VALUE = 1'b0;
    defparam \snapshot.edge_color[4]~FF .SR_SYNC_PRIORITY = 1'b1;
    EFX_FF \snapshot.edge_color[5]~FF  (.D(in_render[79]), .CE(1'b1), .CLK(clk), 
           .SR(rst), .Q(\snapshot.edge_color [5])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_FF, CLK_POLARITY=1'b1, D_POLARITY=1'b1, CE_POLARITY=1'b1, SR_SYNC=1'b1, SR_SYNC_PRIORITY=1'b1, SR_VALUE=1'b0, SR_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(105)
    defparam \snapshot.edge_color[5]~FF .CLK_POLARITY = 1'b1;
    defparam \snapshot.edge_color[5]~FF .CE_POLARITY = 1'b1;
    defparam \snapshot.edge_color[5]~FF .SR_POLARITY = 1'b1;
    defparam \snapshot.edge_color[5]~FF .D_POLARITY = 1'b1;
    defparam \snapshot.edge_color[5]~FF .SR_SYNC = 1'b1;
    defparam \snapshot.edge_color[5]~FF .SR_VALUE = 1'b0;
    defparam \snapshot.edge_color[5]~FF .SR_SYNC_PRIORITY = 1'b1;
    EFX_FF \snapshot.edge_color[6]~FF  (.D(in_render[80]), .CE(1'b1), .CLK(clk), 
           .SR(rst), .Q(\snapshot.edge_color [6])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_FF, CLK_POLARITY=1'b1, D_POLARITY=1'b1, CE_POLARITY=1'b1, SR_SYNC=1'b1, SR_SYNC_PRIORITY=1'b1, SR_VALUE=1'b0, SR_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(105)
    defparam \snapshot.edge_color[6]~FF .CLK_POLARITY = 1'b1;
    defparam \snapshot.edge_color[6]~FF .CE_POLARITY = 1'b1;
    defparam \snapshot.edge_color[6]~FF .SR_POLARITY = 1'b1;
    defparam \snapshot.edge_color[6]~FF .D_POLARITY = 1'b1;
    defparam \snapshot.edge_color[6]~FF .SR_SYNC = 1'b1;
    defparam \snapshot.edge_color[6]~FF .SR_VALUE = 1'b0;
    defparam \snapshot.edge_color[6]~FF .SR_SYNC_PRIORITY = 1'b1;
    EFX_FF \snapshot.edge_color[7]~FF  (.D(in_render[81]), .CE(1'b1), .CLK(clk), 
           .SR(rst), .Q(\snapshot.edge_color [7])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_FF, CLK_POLARITY=1'b1, D_POLARITY=1'b1, CE_POLARITY=1'b1, SR_SYNC=1'b1, SR_SYNC_PRIORITY=1'b1, SR_VALUE=1'b0, SR_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(105)
    defparam \snapshot.edge_color[7]~FF .CLK_POLARITY = 1'b1;
    defparam \snapshot.edge_color[7]~FF .CE_POLARITY = 1'b1;
    defparam \snapshot.edge_color[7]~FF .SR_POLARITY = 1'b1;
    defparam \snapshot.edge_color[7]~FF .D_POLARITY = 1'b1;
    defparam \snapshot.edge_color[7]~FF .SR_SYNC = 1'b1;
    defparam \snapshot.edge_color[7]~FF .SR_VALUE = 1'b0;
    defparam \snapshot.edge_color[7]~FF .SR_SYNC_PRIORITY = 1'b1;
    EFX_FF \snapshot.edge_color[8]~FF  (.D(in_render[82]), .CE(1'b1), .CLK(clk), 
           .SR(rst), .Q(\snapshot.edge_color [8])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_FF, CLK_POLARITY=1'b1, D_POLARITY=1'b1, CE_POLARITY=1'b1, SR_SYNC=1'b1, SR_SYNC_PRIORITY=1'b1, SR_VALUE=1'b0, SR_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(105)
    defparam \snapshot.edge_color[8]~FF .CLK_POLARITY = 1'b1;
    defparam \snapshot.edge_color[8]~FF .CE_POLARITY = 1'b1;
    defparam \snapshot.edge_color[8]~FF .SR_POLARITY = 1'b1;
    defparam \snapshot.edge_color[8]~FF .D_POLARITY = 1'b1;
    defparam \snapshot.edge_color[8]~FF .SR_SYNC = 1'b1;
    defparam \snapshot.edge_color[8]~FF .SR_VALUE = 1'b0;
    defparam \snapshot.edge_color[8]~FF .SR_SYNC_PRIORITY = 1'b1;
    EFX_FF \snapshot.edge_color[9]~FF  (.D(in_render[83]), .CE(1'b1), .CLK(clk), 
           .SR(rst), .Q(\snapshot.edge_color [9])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_FF, CLK_POLARITY=1'b1, D_POLARITY=1'b1, CE_POLARITY=1'b1, SR_SYNC=1'b1, SR_SYNC_PRIORITY=1'b1, SR_VALUE=1'b0, SR_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(105)
    defparam \snapshot.edge_color[9]~FF .CLK_POLARITY = 1'b1;
    defparam \snapshot.edge_color[9]~FF .CE_POLARITY = 1'b1;
    defparam \snapshot.edge_color[9]~FF .SR_POLARITY = 1'b1;
    defparam \snapshot.edge_color[9]~FF .D_POLARITY = 1'b1;
    defparam \snapshot.edge_color[9]~FF .SR_SYNC = 1'b1;
    defparam \snapshot.edge_color[9]~FF .SR_VALUE = 1'b0;
    defparam \snapshot.edge_color[9]~FF .SR_SYNC_PRIORITY = 1'b1;
    EFX_FF \snapshot.edge_color[10]~FF  (.D(in_render[84]), .CE(1'b1), .CLK(clk), 
           .SR(rst), .Q(\snapshot.edge_color [10])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_FF, CLK_POLARITY=1'b1, D_POLARITY=1'b1, CE_POLARITY=1'b1, SR_SYNC=1'b1, SR_SYNC_PRIORITY=1'b1, SR_VALUE=1'b0, SR_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(105)
    defparam \snapshot.edge_color[10]~FF .CLK_POLARITY = 1'b1;
    defparam \snapshot.edge_color[10]~FF .CE_POLARITY = 1'b1;
    defparam \snapshot.edge_color[10]~FF .SR_POLARITY = 1'b1;
    defparam \snapshot.edge_color[10]~FF .D_POLARITY = 1'b1;
    defparam \snapshot.edge_color[10]~FF .SR_SYNC = 1'b1;
    defparam \snapshot.edge_color[10]~FF .SR_VALUE = 1'b0;
    defparam \snapshot.edge_color[10]~FF .SR_SYNC_PRIORITY = 1'b1;
    EFX_FF \snapshot.edge_color[11]~FF  (.D(in_render[85]), .CE(1'b1), .CLK(clk), 
           .SR(rst), .Q(\snapshot.edge_color [11])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_FF, CLK_POLARITY=1'b1, D_POLARITY=1'b1, CE_POLARITY=1'b1, SR_SYNC=1'b1, SR_SYNC_PRIORITY=1'b1, SR_VALUE=1'b0, SR_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(105)
    defparam \snapshot.edge_color[11]~FF .CLK_POLARITY = 1'b1;
    defparam \snapshot.edge_color[11]~FF .CE_POLARITY = 1'b1;
    defparam \snapshot.edge_color[11]~FF .SR_POLARITY = 1'b1;
    defparam \snapshot.edge_color[11]~FF .D_POLARITY = 1'b1;
    defparam \snapshot.edge_color[11]~FF .SR_SYNC = 1'b1;
    defparam \snapshot.edge_color[11]~FF .SR_VALUE = 1'b0;
    defparam \snapshot.edge_color[11]~FF .SR_SYNC_PRIORITY = 1'b1;
    EFX_FF \snapshot.edge_color[12]~FF  (.D(in_render[86]), .CE(1'b1), .CLK(clk), 
           .SR(rst), .Q(\snapshot.edge_color [12])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_FF, CLK_POLARITY=1'b1, D_POLARITY=1'b1, CE_POLARITY=1'b1, SR_SYNC=1'b1, SR_SYNC_PRIORITY=1'b1, SR_VALUE=1'b0, SR_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(105)
    defparam \snapshot.edge_color[12]~FF .CLK_POLARITY = 1'b1;
    defparam \snapshot.edge_color[12]~FF .CE_POLARITY = 1'b1;
    defparam \snapshot.edge_color[12]~FF .SR_POLARITY = 1'b1;
    defparam \snapshot.edge_color[12]~FF .D_POLARITY = 1'b1;
    defparam \snapshot.edge_color[12]~FF .SR_SYNC = 1'b1;
    defparam \snapshot.edge_color[12]~FF .SR_VALUE = 1'b0;
    defparam \snapshot.edge_color[12]~FF .SR_SYNC_PRIORITY = 1'b1;
    EFX_FF \snapshot.edge_color[13]~FF  (.D(in_render[87]), .CE(1'b1), .CLK(clk), 
           .SR(rst), .Q(\snapshot.edge_color [13])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_FF, CLK_POLARITY=1'b1, D_POLARITY=1'b1, CE_POLARITY=1'b1, SR_SYNC=1'b1, SR_SYNC_PRIORITY=1'b1, SR_VALUE=1'b0, SR_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(105)
    defparam \snapshot.edge_color[13]~FF .CLK_POLARITY = 1'b1;
    defparam \snapshot.edge_color[13]~FF .CE_POLARITY = 1'b1;
    defparam \snapshot.edge_color[13]~FF .SR_POLARITY = 1'b1;
    defparam \snapshot.edge_color[13]~FF .D_POLARITY = 1'b1;
    defparam \snapshot.edge_color[13]~FF .SR_SYNC = 1'b1;
    defparam \snapshot.edge_color[13]~FF .SR_VALUE = 1'b0;
    defparam \snapshot.edge_color[13]~FF .SR_SYNC_PRIORITY = 1'b1;
    EFX_FF \snapshot.edge_color[14]~FF  (.D(in_render[88]), .CE(1'b1), .CLK(clk), 
           .SR(rst), .Q(\snapshot.edge_color [14])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_FF, CLK_POLARITY=1'b1, D_POLARITY=1'b1, CE_POLARITY=1'b1, SR_SYNC=1'b1, SR_SYNC_PRIORITY=1'b1, SR_VALUE=1'b0, SR_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(105)
    defparam \snapshot.edge_color[14]~FF .CLK_POLARITY = 1'b1;
    defparam \snapshot.edge_color[14]~FF .CE_POLARITY = 1'b1;
    defparam \snapshot.edge_color[14]~FF .SR_POLARITY = 1'b1;
    defparam \snapshot.edge_color[14]~FF .D_POLARITY = 1'b1;
    defparam \snapshot.edge_color[14]~FF .SR_SYNC = 1'b1;
    defparam \snapshot.edge_color[14]~FF .SR_VALUE = 1'b0;
    defparam \snapshot.edge_color[14]~FF .SR_SYNC_PRIORITY = 1'b1;
    EFX_FF \snapshot.edge_color[15]~FF  (.D(in_render[89]), .CE(1'b1), .CLK(clk), 
           .SR(rst), .Q(\snapshot.edge_color [15])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_FF, CLK_POLARITY=1'b1, D_POLARITY=1'b1, CE_POLARITY=1'b1, SR_SYNC=1'b1, SR_SYNC_PRIORITY=1'b1, SR_VALUE=1'b0, SR_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(105)
    defparam \snapshot.edge_color[15]~FF .CLK_POLARITY = 1'b1;
    defparam \snapshot.edge_color[15]~FF .CE_POLARITY = 1'b1;
    defparam \snapshot.edge_color[15]~FF .SR_POLARITY = 1'b1;
    defparam \snapshot.edge_color[15]~FF .D_POLARITY = 1'b1;
    defparam \snapshot.edge_color[15]~FF .SR_SYNC = 1'b1;
    defparam \snapshot.edge_color[15]~FF .SR_VALUE = 1'b0;
    defparam \snapshot.edge_color[15]~FF .SR_SYNC_PRIORITY = 1'b1;
    EFX_FF \snapshot.edge_color[16]~FF  (.D(in_render[90]), .CE(1'b1), .CLK(clk), 
           .SR(rst), .Q(\snapshot.edge_color [16])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_FF, CLK_POLARITY=1'b1, D_POLARITY=1'b1, CE_POLARITY=1'b1, SR_SYNC=1'b1, SR_SYNC_PRIORITY=1'b1, SR_VALUE=1'b0, SR_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(105)
    defparam \snapshot.edge_color[16]~FF .CLK_POLARITY = 1'b1;
    defparam \snapshot.edge_color[16]~FF .CE_POLARITY = 1'b1;
    defparam \snapshot.edge_color[16]~FF .SR_POLARITY = 1'b1;
    defparam \snapshot.edge_color[16]~FF .D_POLARITY = 1'b1;
    defparam \snapshot.edge_color[16]~FF .SR_SYNC = 1'b1;
    defparam \snapshot.edge_color[16]~FF .SR_VALUE = 1'b0;
    defparam \snapshot.edge_color[16]~FF .SR_SYNC_PRIORITY = 1'b1;
    EFX_FF \snapshot.edge_color[17]~FF  (.D(in_render[91]), .CE(1'b1), .CLK(clk), 
           .SR(rst), .Q(\snapshot.edge_color [17])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_FF, CLK_POLARITY=1'b1, D_POLARITY=1'b1, CE_POLARITY=1'b1, SR_SYNC=1'b1, SR_SYNC_PRIORITY=1'b1, SR_VALUE=1'b0, SR_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(105)
    defparam \snapshot.edge_color[17]~FF .CLK_POLARITY = 1'b1;
    defparam \snapshot.edge_color[17]~FF .CE_POLARITY = 1'b1;
    defparam \snapshot.edge_color[17]~FF .SR_POLARITY = 1'b1;
    defparam \snapshot.edge_color[17]~FF .D_POLARITY = 1'b1;
    defparam \snapshot.edge_color[17]~FF .SR_SYNC = 1'b1;
    defparam \snapshot.edge_color[17]~FF .SR_VALUE = 1'b0;
    defparam \snapshot.edge_color[17]~FF .SR_SYNC_PRIORITY = 1'b1;
    EFX_FF \snapshot.edge_color[18]~FF  (.D(in_render[92]), .CE(1'b1), .CLK(clk), 
           .SR(rst), .Q(\snapshot.edge_color [18])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_FF, CLK_POLARITY=1'b1, D_POLARITY=1'b1, CE_POLARITY=1'b1, SR_SYNC=1'b1, SR_SYNC_PRIORITY=1'b1, SR_VALUE=1'b0, SR_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(105)
    defparam \snapshot.edge_color[18]~FF .CLK_POLARITY = 1'b1;
    defparam \snapshot.edge_color[18]~FF .CE_POLARITY = 1'b1;
    defparam \snapshot.edge_color[18]~FF .SR_POLARITY = 1'b1;
    defparam \snapshot.edge_color[18]~FF .D_POLARITY = 1'b1;
    defparam \snapshot.edge_color[18]~FF .SR_SYNC = 1'b1;
    defparam \snapshot.edge_color[18]~FF .SR_VALUE = 1'b0;
    defparam \snapshot.edge_color[18]~FF .SR_SYNC_PRIORITY = 1'b1;
    EFX_FF \snapshot.edge_color[19]~FF  (.D(in_render[93]), .CE(1'b1), .CLK(clk), 
           .SR(rst), .Q(\snapshot.edge_color [19])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_FF, CLK_POLARITY=1'b1, D_POLARITY=1'b1, CE_POLARITY=1'b1, SR_SYNC=1'b1, SR_SYNC_PRIORITY=1'b1, SR_VALUE=1'b0, SR_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(105)
    defparam \snapshot.edge_color[19]~FF .CLK_POLARITY = 1'b1;
    defparam \snapshot.edge_color[19]~FF .CE_POLARITY = 1'b1;
    defparam \snapshot.edge_color[19]~FF .SR_POLARITY = 1'b1;
    defparam \snapshot.edge_color[19]~FF .D_POLARITY = 1'b1;
    defparam \snapshot.edge_color[19]~FF .SR_SYNC = 1'b1;
    defparam \snapshot.edge_color[19]~FF .SR_VALUE = 1'b0;
    defparam \snapshot.edge_color[19]~FF .SR_SYNC_PRIORITY = 1'b1;
    EFX_FF \snapshot.edge_color[20]~FF  (.D(in_render[94]), .CE(1'b1), .CLK(clk), 
           .SR(rst), .Q(\snapshot.edge_color [20])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_FF, CLK_POLARITY=1'b1, D_POLARITY=1'b1, CE_POLARITY=1'b1, SR_SYNC=1'b1, SR_SYNC_PRIORITY=1'b1, SR_VALUE=1'b0, SR_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(105)
    defparam \snapshot.edge_color[20]~FF .CLK_POLARITY = 1'b1;
    defparam \snapshot.edge_color[20]~FF .CE_POLARITY = 1'b1;
    defparam \snapshot.edge_color[20]~FF .SR_POLARITY = 1'b1;
    defparam \snapshot.edge_color[20]~FF .D_POLARITY = 1'b1;
    defparam \snapshot.edge_color[20]~FF .SR_SYNC = 1'b1;
    defparam \snapshot.edge_color[20]~FF .SR_VALUE = 1'b0;
    defparam \snapshot.edge_color[20]~FF .SR_SYNC_PRIORITY = 1'b1;
    EFX_FF \snapshot.edge_color[21]~FF  (.D(in_render[95]), .CE(1'b1), .CLK(clk), 
           .SR(rst), .Q(\snapshot.edge_color [21])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_FF, CLK_POLARITY=1'b1, D_POLARITY=1'b1, CE_POLARITY=1'b1, SR_SYNC=1'b1, SR_SYNC_PRIORITY=1'b1, SR_VALUE=1'b0, SR_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(105)
    defparam \snapshot.edge_color[21]~FF .CLK_POLARITY = 1'b1;
    defparam \snapshot.edge_color[21]~FF .CE_POLARITY = 1'b1;
    defparam \snapshot.edge_color[21]~FF .SR_POLARITY = 1'b1;
    defparam \snapshot.edge_color[21]~FF .D_POLARITY = 1'b1;
    defparam \snapshot.edge_color[21]~FF .SR_SYNC = 1'b1;
    defparam \snapshot.edge_color[21]~FF .SR_VALUE = 1'b0;
    defparam \snapshot.edge_color[21]~FF .SR_SYNC_PRIORITY = 1'b1;
    EFX_FF \snapshot.edge_color[22]~FF  (.D(in_render[96]), .CE(1'b1), .CLK(clk), 
           .SR(rst), .Q(\snapshot.edge_color [22])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_FF, CLK_POLARITY=1'b1, D_POLARITY=1'b1, CE_POLARITY=1'b1, SR_SYNC=1'b1, SR_SYNC_PRIORITY=1'b1, SR_VALUE=1'b0, SR_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(105)
    defparam \snapshot.edge_color[22]~FF .CLK_POLARITY = 1'b1;
    defparam \snapshot.edge_color[22]~FF .CE_POLARITY = 1'b1;
    defparam \snapshot.edge_color[22]~FF .SR_POLARITY = 1'b1;
    defparam \snapshot.edge_color[22]~FF .D_POLARITY = 1'b1;
    defparam \snapshot.edge_color[22]~FF .SR_SYNC = 1'b1;
    defparam \snapshot.edge_color[22]~FF .SR_VALUE = 1'b0;
    defparam \snapshot.edge_color[22]~FF .SR_SYNC_PRIORITY = 1'b1;
    EFX_FF \snapshot.edge_color[23]~FF  (.D(in_render[97]), .CE(1'b1), .CLK(clk), 
           .SR(rst), .Q(\snapshot.edge_color [23])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_FF, CLK_POLARITY=1'b1, D_POLARITY=1'b1, CE_POLARITY=1'b1, SR_SYNC=1'b1, SR_SYNC_PRIORITY=1'b1, SR_VALUE=1'b0, SR_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(105)
    defparam \snapshot.edge_color[23]~FF .CLK_POLARITY = 1'b1;
    defparam \snapshot.edge_color[23]~FF .CE_POLARITY = 1'b1;
    defparam \snapshot.edge_color[23]~FF .SR_POLARITY = 1'b1;
    defparam \snapshot.edge_color[23]~FF .D_POLARITY = 1'b1;
    defparam \snapshot.edge_color[23]~FF .SR_SYNC = 1'b1;
    defparam \snapshot.edge_color[23]~FF .SR_VALUE = 1'b0;
    defparam \snapshot.edge_color[23]~FF .SR_SYNC_PRIORITY = 1'b1;
    EFX_FF \snapshot.y[5]~FF  (.D(in_y[5]), .CE(1'b1), .CLK(clk), .SR(rst), 
           .Q(\snapshot.y [5])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_FF, CLK_POLARITY=1'b1, D_POLARITY=1'b1, CE_POLARITY=1'b1, SR_SYNC=1'b1, SR_SYNC_PRIORITY=1'b1, SR_VALUE=1'b0, SR_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(105)
    defparam \snapshot.y[5]~FF .CLK_POLARITY = 1'b1;
    defparam \snapshot.y[5]~FF .CE_POLARITY = 1'b1;
    defparam \snapshot.y[5]~FF .SR_POLARITY = 1'b1;
    defparam \snapshot.y[5]~FF .D_POLARITY = 1'b1;
    defparam \snapshot.y[5]~FF .SR_SYNC = 1'b1;
    defparam \snapshot.y[5]~FF .SR_VALUE = 1'b0;
    defparam \snapshot.y[5]~FF .SR_SYNC_PRIORITY = 1'b1;
    EFX_FF \snapshot.ann01_color[2]~FF  (.D(in_render[52]), .CE(1'b1), .CLK(clk), 
           .SR(rst), .Q(\snapshot.ann01_color [2])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_FF, CLK_POLARITY=1'b1, D_POLARITY=1'b1, CE_POLARITY=1'b1, SR_SYNC=1'b1, SR_SYNC_PRIORITY=1'b1, SR_VALUE=1'b0, SR_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(105)
    defparam \snapshot.ann01_color[2]~FF .CLK_POLARITY = 1'b1;
    defparam \snapshot.ann01_color[2]~FF .CE_POLARITY = 1'b1;
    defparam \snapshot.ann01_color[2]~FF .SR_POLARITY = 1'b1;
    defparam \snapshot.ann01_color[2]~FF .D_POLARITY = 1'b1;
    defparam \snapshot.ann01_color[2]~FF .SR_SYNC = 1'b1;
    defparam \snapshot.ann01_color[2]~FF .SR_VALUE = 1'b0;
    defparam \snapshot.ann01_color[2]~FF .SR_SYNC_PRIORITY = 1'b1;
    EFX_FF \snapshot.ann01_color[3]~FF  (.D(in_render[53]), .CE(1'b1), .CLK(clk), 
           .SR(rst), .Q(\snapshot.ann01_color [3])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_FF, CLK_POLARITY=1'b1, D_POLARITY=1'b1, CE_POLARITY=1'b1, SR_SYNC=1'b1, SR_SYNC_PRIORITY=1'b1, SR_VALUE=1'b0, SR_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(105)
    defparam \snapshot.ann01_color[3]~FF .CLK_POLARITY = 1'b1;
    defparam \snapshot.ann01_color[3]~FF .CE_POLARITY = 1'b1;
    defparam \snapshot.ann01_color[3]~FF .SR_POLARITY = 1'b1;
    defparam \snapshot.ann01_color[3]~FF .D_POLARITY = 1'b1;
    defparam \snapshot.ann01_color[3]~FF .SR_SYNC = 1'b1;
    defparam \snapshot.ann01_color[3]~FF .SR_VALUE = 1'b0;
    defparam \snapshot.ann01_color[3]~FF .SR_SYNC_PRIORITY = 1'b1;
    EFX_FF \snapshot.ann01_color[4]~FF  (.D(in_render[54]), .CE(1'b1), .CLK(clk), 
           .SR(rst), .Q(\snapshot.ann01_color [4])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_FF, CLK_POLARITY=1'b1, D_POLARITY=1'b1, CE_POLARITY=1'b1, SR_SYNC=1'b1, SR_SYNC_PRIORITY=1'b1, SR_VALUE=1'b0, SR_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(105)
    defparam \snapshot.ann01_color[4]~FF .CLK_POLARITY = 1'b1;
    defparam \snapshot.ann01_color[4]~FF .CE_POLARITY = 1'b1;
    defparam \snapshot.ann01_color[4]~FF .SR_POLARITY = 1'b1;
    defparam \snapshot.ann01_color[4]~FF .D_POLARITY = 1'b1;
    defparam \snapshot.ann01_color[4]~FF .SR_SYNC = 1'b1;
    defparam \snapshot.ann01_color[4]~FF .SR_VALUE = 1'b0;
    defparam \snapshot.ann01_color[4]~FF .SR_SYNC_PRIORITY = 1'b1;
    EFX_FF \snapshot.ann01_color[5]~FF  (.D(in_render[55]), .CE(1'b1), .CLK(clk), 
           .SR(rst), .Q(\snapshot.ann01_color [5])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_FF, CLK_POLARITY=1'b1, D_POLARITY=1'b1, CE_POLARITY=1'b1, SR_SYNC=1'b1, SR_SYNC_PRIORITY=1'b1, SR_VALUE=1'b0, SR_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(105)
    defparam \snapshot.ann01_color[5]~FF .CLK_POLARITY = 1'b1;
    defparam \snapshot.ann01_color[5]~FF .CE_POLARITY = 1'b1;
    defparam \snapshot.ann01_color[5]~FF .SR_POLARITY = 1'b1;
    defparam \snapshot.ann01_color[5]~FF .D_POLARITY = 1'b1;
    defparam \snapshot.ann01_color[5]~FF .SR_SYNC = 1'b1;
    defparam \snapshot.ann01_color[5]~FF .SR_VALUE = 1'b0;
    defparam \snapshot.ann01_color[5]~FF .SR_SYNC_PRIORITY = 1'b1;
    EFX_FF \snapshot.ann01_color[6]~FF  (.D(in_render[56]), .CE(1'b1), .CLK(clk), 
           .SR(rst), .Q(\snapshot.ann01_color [6])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_FF, CLK_POLARITY=1'b1, D_POLARITY=1'b1, CE_POLARITY=1'b1, SR_SYNC=1'b1, SR_SYNC_PRIORITY=1'b1, SR_VALUE=1'b0, SR_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(105)
    defparam \snapshot.ann01_color[6]~FF .CLK_POLARITY = 1'b1;
    defparam \snapshot.ann01_color[6]~FF .CE_POLARITY = 1'b1;
    defparam \snapshot.ann01_color[6]~FF .SR_POLARITY = 1'b1;
    defparam \snapshot.ann01_color[6]~FF .D_POLARITY = 1'b1;
    defparam \snapshot.ann01_color[6]~FF .SR_SYNC = 1'b1;
    defparam \snapshot.ann01_color[6]~FF .SR_VALUE = 1'b0;
    defparam \snapshot.ann01_color[6]~FF .SR_SYNC_PRIORITY = 1'b1;
    EFX_FF \snapshot.ann01_color[7]~FF  (.D(in_render[57]), .CE(1'b1), .CLK(clk), 
           .SR(rst), .Q(\snapshot.ann01_color [7])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_FF, CLK_POLARITY=1'b1, D_POLARITY=1'b1, CE_POLARITY=1'b1, SR_SYNC=1'b1, SR_SYNC_PRIORITY=1'b1, SR_VALUE=1'b0, SR_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(105)
    defparam \snapshot.ann01_color[7]~FF .CLK_POLARITY = 1'b1;
    defparam \snapshot.ann01_color[7]~FF .CE_POLARITY = 1'b1;
    defparam \snapshot.ann01_color[7]~FF .SR_POLARITY = 1'b1;
    defparam \snapshot.ann01_color[7]~FF .D_POLARITY = 1'b1;
    defparam \snapshot.ann01_color[7]~FF .SR_SYNC = 1'b1;
    defparam \snapshot.ann01_color[7]~FF .SR_VALUE = 1'b0;
    defparam \snapshot.ann01_color[7]~FF .SR_SYNC_PRIORITY = 1'b1;
    EFX_FF \snapshot.ann01_color[8]~FF  (.D(in_render[58]), .CE(1'b1), .CLK(clk), 
           .SR(rst), .Q(\snapshot.ann01_color [8])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_FF, CLK_POLARITY=1'b1, D_POLARITY=1'b1, CE_POLARITY=1'b1, SR_SYNC=1'b1, SR_SYNC_PRIORITY=1'b1, SR_VALUE=1'b0, SR_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(105)
    defparam \snapshot.ann01_color[8]~FF .CLK_POLARITY = 1'b1;
    defparam \snapshot.ann01_color[8]~FF .CE_POLARITY = 1'b1;
    defparam \snapshot.ann01_color[8]~FF .SR_POLARITY = 1'b1;
    defparam \snapshot.ann01_color[8]~FF .D_POLARITY = 1'b1;
    defparam \snapshot.ann01_color[8]~FF .SR_SYNC = 1'b1;
    defparam \snapshot.ann01_color[8]~FF .SR_VALUE = 1'b0;
    defparam \snapshot.ann01_color[8]~FF .SR_SYNC_PRIORITY = 1'b1;
    EFX_FF \snapshot.ann01_color[9]~FF  (.D(in_render[59]), .CE(1'b1), .CLK(clk), 
           .SR(rst), .Q(\snapshot.ann01_color [9])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_FF, CLK_POLARITY=1'b1, D_POLARITY=1'b1, CE_POLARITY=1'b1, SR_SYNC=1'b1, SR_SYNC_PRIORITY=1'b1, SR_VALUE=1'b0, SR_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(105)
    defparam \snapshot.ann01_color[9]~FF .CLK_POLARITY = 1'b1;
    defparam \snapshot.ann01_color[9]~FF .CE_POLARITY = 1'b1;
    defparam \snapshot.ann01_color[9]~FF .SR_POLARITY = 1'b1;
    defparam \snapshot.ann01_color[9]~FF .D_POLARITY = 1'b1;
    defparam \snapshot.ann01_color[9]~FF .SR_SYNC = 1'b1;
    defparam \snapshot.ann01_color[9]~FF .SR_VALUE = 1'b0;
    defparam \snapshot.ann01_color[9]~FF .SR_SYNC_PRIORITY = 1'b1;
    EFX_FF \snapshot.ann01_color[10]~FF  (.D(in_render[60]), .CE(1'b1), 
           .CLK(clk), .SR(rst), .Q(\snapshot.ann01_color [10])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_FF, CLK_POLARITY=1'b1, D_POLARITY=1'b1, CE_POLARITY=1'b1, SR_SYNC=1'b1, SR_SYNC_PRIORITY=1'b1, SR_VALUE=1'b0, SR_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(105)
    defparam \snapshot.ann01_color[10]~FF .CLK_POLARITY = 1'b1;
    defparam \snapshot.ann01_color[10]~FF .CE_POLARITY = 1'b1;
    defparam \snapshot.ann01_color[10]~FF .SR_POLARITY = 1'b1;
    defparam \snapshot.ann01_color[10]~FF .D_POLARITY = 1'b1;
    defparam \snapshot.ann01_color[10]~FF .SR_SYNC = 1'b1;
    defparam \snapshot.ann01_color[10]~FF .SR_VALUE = 1'b0;
    defparam \snapshot.ann01_color[10]~FF .SR_SYNC_PRIORITY = 1'b1;
    EFX_FF \snapshot.ann01_color[11]~FF  (.D(in_render[61]), .CE(1'b1), 
           .CLK(clk), .SR(rst), .Q(\snapshot.ann01_color [11])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_FF, CLK_POLARITY=1'b1, D_POLARITY=1'b1, CE_POLARITY=1'b1, SR_SYNC=1'b1, SR_SYNC_PRIORITY=1'b1, SR_VALUE=1'b0, SR_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(105)
    defparam \snapshot.ann01_color[11]~FF .CLK_POLARITY = 1'b1;
    defparam \snapshot.ann01_color[11]~FF .CE_POLARITY = 1'b1;
    defparam \snapshot.ann01_color[11]~FF .SR_POLARITY = 1'b1;
    defparam \snapshot.ann01_color[11]~FF .D_POLARITY = 1'b1;
    defparam \snapshot.ann01_color[11]~FF .SR_SYNC = 1'b1;
    defparam \snapshot.ann01_color[11]~FF .SR_VALUE = 1'b0;
    defparam \snapshot.ann01_color[11]~FF .SR_SYNC_PRIORITY = 1'b1;
    EFX_FF \snapshot.ann01_color[12]~FF  (.D(in_render[62]), .CE(1'b1), 
           .CLK(clk), .SR(rst), .Q(\snapshot.ann01_color [12])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_FF, CLK_POLARITY=1'b1, D_POLARITY=1'b1, CE_POLARITY=1'b1, SR_SYNC=1'b1, SR_SYNC_PRIORITY=1'b1, SR_VALUE=1'b0, SR_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(105)
    defparam \snapshot.ann01_color[12]~FF .CLK_POLARITY = 1'b1;
    defparam \snapshot.ann01_color[12]~FF .CE_POLARITY = 1'b1;
    defparam \snapshot.ann01_color[12]~FF .SR_POLARITY = 1'b1;
    defparam \snapshot.ann01_color[12]~FF .D_POLARITY = 1'b1;
    defparam \snapshot.ann01_color[12]~FF .SR_SYNC = 1'b1;
    defparam \snapshot.ann01_color[12]~FF .SR_VALUE = 1'b0;
    defparam \snapshot.ann01_color[12]~FF .SR_SYNC_PRIORITY = 1'b1;
    EFX_FF \snapshot.ann01_color[13]~FF  (.D(in_render[63]), .CE(1'b1), 
           .CLK(clk), .SR(rst), .Q(\snapshot.ann01_color [13])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_FF, CLK_POLARITY=1'b1, D_POLARITY=1'b1, CE_POLARITY=1'b1, SR_SYNC=1'b1, SR_SYNC_PRIORITY=1'b1, SR_VALUE=1'b0, SR_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(105)
    defparam \snapshot.ann01_color[13]~FF .CLK_POLARITY = 1'b1;
    defparam \snapshot.ann01_color[13]~FF .CE_POLARITY = 1'b1;
    defparam \snapshot.ann01_color[13]~FF .SR_POLARITY = 1'b1;
    defparam \snapshot.ann01_color[13]~FF .D_POLARITY = 1'b1;
    defparam \snapshot.ann01_color[13]~FF .SR_SYNC = 1'b1;
    defparam \snapshot.ann01_color[13]~FF .SR_VALUE = 1'b0;
    defparam \snapshot.ann01_color[13]~FF .SR_SYNC_PRIORITY = 1'b1;
    EFX_FF \snapshot.ann01_color[14]~FF  (.D(in_render[64]), .CE(1'b1), 
           .CLK(clk), .SR(rst), .Q(\snapshot.ann01_color [14])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_FF, CLK_POLARITY=1'b1, D_POLARITY=1'b1, CE_POLARITY=1'b1, SR_SYNC=1'b1, SR_SYNC_PRIORITY=1'b1, SR_VALUE=1'b0, SR_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(105)
    defparam \snapshot.ann01_color[14]~FF .CLK_POLARITY = 1'b1;
    defparam \snapshot.ann01_color[14]~FF .CE_POLARITY = 1'b1;
    defparam \snapshot.ann01_color[14]~FF .SR_POLARITY = 1'b1;
    defparam \snapshot.ann01_color[14]~FF .D_POLARITY = 1'b1;
    defparam \snapshot.ann01_color[14]~FF .SR_SYNC = 1'b1;
    defparam \snapshot.ann01_color[14]~FF .SR_VALUE = 1'b0;
    defparam \snapshot.ann01_color[14]~FF .SR_SYNC_PRIORITY = 1'b1;
    EFX_FF \snapshot.ann01_color[15]~FF  (.D(in_render[65]), .CE(1'b1), 
           .CLK(clk), .SR(rst), .Q(\snapshot.ann01_color [15])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_FF, CLK_POLARITY=1'b1, D_POLARITY=1'b1, CE_POLARITY=1'b1, SR_SYNC=1'b1, SR_SYNC_PRIORITY=1'b1, SR_VALUE=1'b0, SR_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(105)
    defparam \snapshot.ann01_color[15]~FF .CLK_POLARITY = 1'b1;
    defparam \snapshot.ann01_color[15]~FF .CE_POLARITY = 1'b1;
    defparam \snapshot.ann01_color[15]~FF .SR_POLARITY = 1'b1;
    defparam \snapshot.ann01_color[15]~FF .D_POLARITY = 1'b1;
    defparam \snapshot.ann01_color[15]~FF .SR_SYNC = 1'b1;
    defparam \snapshot.ann01_color[15]~FF .SR_VALUE = 1'b0;
    defparam \snapshot.ann01_color[15]~FF .SR_SYNC_PRIORITY = 1'b1;
    EFX_FF \snapshot.ann01_color[16]~FF  (.D(in_render[66]), .CE(1'b1), 
           .CLK(clk), .SR(rst), .Q(\snapshot.ann01_color [16])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_FF, CLK_POLARITY=1'b1, D_POLARITY=1'b1, CE_POLARITY=1'b1, SR_SYNC=1'b1, SR_SYNC_PRIORITY=1'b1, SR_VALUE=1'b0, SR_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(105)
    defparam \snapshot.ann01_color[16]~FF .CLK_POLARITY = 1'b1;
    defparam \snapshot.ann01_color[16]~FF .CE_POLARITY = 1'b1;
    defparam \snapshot.ann01_color[16]~FF .SR_POLARITY = 1'b1;
    defparam \snapshot.ann01_color[16]~FF .D_POLARITY = 1'b1;
    defparam \snapshot.ann01_color[16]~FF .SR_SYNC = 1'b1;
    defparam \snapshot.ann01_color[16]~FF .SR_VALUE = 1'b0;
    defparam \snapshot.ann01_color[16]~FF .SR_SYNC_PRIORITY = 1'b1;
    EFX_FF \snapshot.ann01_color[17]~FF  (.D(in_render[67]), .CE(1'b1), 
           .CLK(clk), .SR(rst), .Q(\snapshot.ann01_color [17])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_FF, CLK_POLARITY=1'b1, D_POLARITY=1'b1, CE_POLARITY=1'b1, SR_SYNC=1'b1, SR_SYNC_PRIORITY=1'b1, SR_VALUE=1'b0, SR_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(105)
    defparam \snapshot.ann01_color[17]~FF .CLK_POLARITY = 1'b1;
    defparam \snapshot.ann01_color[17]~FF .CE_POLARITY = 1'b1;
    defparam \snapshot.ann01_color[17]~FF .SR_POLARITY = 1'b1;
    defparam \snapshot.ann01_color[17]~FF .D_POLARITY = 1'b1;
    defparam \snapshot.ann01_color[17]~FF .SR_SYNC = 1'b1;
    defparam \snapshot.ann01_color[17]~FF .SR_VALUE = 1'b0;
    defparam \snapshot.ann01_color[17]~FF .SR_SYNC_PRIORITY = 1'b1;
    EFX_FF \snapshot.ann01_color[18]~FF  (.D(in_render[68]), .CE(1'b1), 
           .CLK(clk), .SR(rst), .Q(\snapshot.ann01_color [18])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_FF, CLK_POLARITY=1'b1, D_POLARITY=1'b1, CE_POLARITY=1'b1, SR_SYNC=1'b1, SR_SYNC_PRIORITY=1'b1, SR_VALUE=1'b0, SR_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(105)
    defparam \snapshot.ann01_color[18]~FF .CLK_POLARITY = 1'b1;
    defparam \snapshot.ann01_color[18]~FF .CE_POLARITY = 1'b1;
    defparam \snapshot.ann01_color[18]~FF .SR_POLARITY = 1'b1;
    defparam \snapshot.ann01_color[18]~FF .D_POLARITY = 1'b1;
    defparam \snapshot.ann01_color[18]~FF .SR_SYNC = 1'b1;
    defparam \snapshot.ann01_color[18]~FF .SR_VALUE = 1'b0;
    defparam \snapshot.ann01_color[18]~FF .SR_SYNC_PRIORITY = 1'b1;
    EFX_FF \snapshot.ann01_color[19]~FF  (.D(in_render[69]), .CE(1'b1), 
           .CLK(clk), .SR(rst), .Q(\snapshot.ann01_color [19])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_FF, CLK_POLARITY=1'b1, D_POLARITY=1'b1, CE_POLARITY=1'b1, SR_SYNC=1'b1, SR_SYNC_PRIORITY=1'b1, SR_VALUE=1'b0, SR_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(105)
    defparam \snapshot.ann01_color[19]~FF .CLK_POLARITY = 1'b1;
    defparam \snapshot.ann01_color[19]~FF .CE_POLARITY = 1'b1;
    defparam \snapshot.ann01_color[19]~FF .SR_POLARITY = 1'b1;
    defparam \snapshot.ann01_color[19]~FF .D_POLARITY = 1'b1;
    defparam \snapshot.ann01_color[19]~FF .SR_SYNC = 1'b1;
    defparam \snapshot.ann01_color[19]~FF .SR_VALUE = 1'b0;
    defparam \snapshot.ann01_color[19]~FF .SR_SYNC_PRIORITY = 1'b1;
    EFX_FF \snapshot.ann01_color[20]~FF  (.D(in_render[70]), .CE(1'b1), 
           .CLK(clk), .SR(rst), .Q(\snapshot.ann01_color [20])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_FF, CLK_POLARITY=1'b1, D_POLARITY=1'b1, CE_POLARITY=1'b1, SR_SYNC=1'b1, SR_SYNC_PRIORITY=1'b1, SR_VALUE=1'b0, SR_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(105)
    defparam \snapshot.ann01_color[20]~FF .CLK_POLARITY = 1'b1;
    defparam \snapshot.ann01_color[20]~FF .CE_POLARITY = 1'b1;
    defparam \snapshot.ann01_color[20]~FF .SR_POLARITY = 1'b1;
    defparam \snapshot.ann01_color[20]~FF .D_POLARITY = 1'b1;
    defparam \snapshot.ann01_color[20]~FF .SR_SYNC = 1'b1;
    defparam \snapshot.ann01_color[20]~FF .SR_VALUE = 1'b0;
    defparam \snapshot.ann01_color[20]~FF .SR_SYNC_PRIORITY = 1'b1;
    EFX_FF \snapshot.ann01_color[21]~FF  (.D(in_render[71]), .CE(1'b1), 
           .CLK(clk), .SR(rst), .Q(\snapshot.ann01_color [21])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_FF, CLK_POLARITY=1'b1, D_POLARITY=1'b1, CE_POLARITY=1'b1, SR_SYNC=1'b1, SR_SYNC_PRIORITY=1'b1, SR_VALUE=1'b0, SR_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(105)
    defparam \snapshot.ann01_color[21]~FF .CLK_POLARITY = 1'b1;
    defparam \snapshot.ann01_color[21]~FF .CE_POLARITY = 1'b1;
    defparam \snapshot.ann01_color[21]~FF .SR_POLARITY = 1'b1;
    defparam \snapshot.ann01_color[21]~FF .D_POLARITY = 1'b1;
    defparam \snapshot.ann01_color[21]~FF .SR_SYNC = 1'b1;
    defparam \snapshot.ann01_color[21]~FF .SR_VALUE = 1'b0;
    defparam \snapshot.ann01_color[21]~FF .SR_SYNC_PRIORITY = 1'b1;
    EFX_FF \snapshot.ann01_color[22]~FF  (.D(in_render[72]), .CE(1'b1), 
           .CLK(clk), .SR(rst), .Q(\snapshot.ann01_color [22])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_FF, CLK_POLARITY=1'b1, D_POLARITY=1'b1, CE_POLARITY=1'b1, SR_SYNC=1'b1, SR_SYNC_PRIORITY=1'b1, SR_VALUE=1'b0, SR_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(105)
    defparam \snapshot.ann01_color[22]~FF .CLK_POLARITY = 1'b1;
    defparam \snapshot.ann01_color[22]~FF .CE_POLARITY = 1'b1;
    defparam \snapshot.ann01_color[22]~FF .SR_POLARITY = 1'b1;
    defparam \snapshot.ann01_color[22]~FF .D_POLARITY = 1'b1;
    defparam \snapshot.ann01_color[22]~FF .SR_SYNC = 1'b1;
    defparam \snapshot.ann01_color[22]~FF .SR_VALUE = 1'b0;
    defparam \snapshot.ann01_color[22]~FF .SR_SYNC_PRIORITY = 1'b1;
    EFX_FF \snapshot.ann01_color[23]~FF  (.D(in_render[73]), .CE(1'b1), 
           .CLK(clk), .SR(rst), .Q(\snapshot.ann01_color [23])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_FF, CLK_POLARITY=1'b1, D_POLARITY=1'b1, CE_POLARITY=1'b1, SR_SYNC=1'b1, SR_SYNC_PRIORITY=1'b1, SR_VALUE=1'b0, SR_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(105)
    defparam \snapshot.ann01_color[23]~FF .CLK_POLARITY = 1'b1;
    defparam \snapshot.ann01_color[23]~FF .CE_POLARITY = 1'b1;
    defparam \snapshot.ann01_color[23]~FF .SR_POLARITY = 1'b1;
    defparam \snapshot.ann01_color[23]~FF .D_POLARITY = 1'b1;
    defparam \snapshot.ann01_color[23]~FF .SR_SYNC = 1'b1;
    defparam \snapshot.ann01_color[23]~FF .SR_VALUE = 1'b0;
    defparam \snapshot.ann01_color[23]~FF .SR_SYNC_PRIORITY = 1'b1;
    EFX_FF \snapshot.edge_color[0]~FF  (.D(in_render[74]), .CE(1'b1), .CLK(clk), 
           .SR(rst), .Q(\snapshot.edge_color [0])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_FF, CLK_POLARITY=1'b1, D_POLARITY=1'b1, CE_POLARITY=1'b1, SR_SYNC=1'b1, SR_SYNC_PRIORITY=1'b1, SR_VALUE=1'b0, SR_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(105)
    defparam \snapshot.edge_color[0]~FF .CLK_POLARITY = 1'b1;
    defparam \snapshot.edge_color[0]~FF .CE_POLARITY = 1'b1;
    defparam \snapshot.edge_color[0]~FF .SR_POLARITY = 1'b1;
    defparam \snapshot.edge_color[0]~FF .D_POLARITY = 1'b1;
    defparam \snapshot.edge_color[0]~FF .SR_SYNC = 1'b1;
    defparam \snapshot.edge_color[0]~FF .SR_VALUE = 1'b0;
    defparam \snapshot.edge_color[0]~FF .SR_SYNC_PRIORITY = 1'b1;
    EFX_FF \snapshot.y[4]~FF  (.D(in_y[4]), .CE(1'b1), .CLK(clk), .SR(rst), 
           .Q(\snapshot.y [4])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_FF, CLK_POLARITY=1'b1, D_POLARITY=1'b1, CE_POLARITY=1'b1, SR_SYNC=1'b1, SR_SYNC_PRIORITY=1'b1, SR_VALUE=1'b0, SR_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(105)
    defparam \snapshot.y[4]~FF .CLK_POLARITY = 1'b1;
    defparam \snapshot.y[4]~FF .CE_POLARITY = 1'b1;
    defparam \snapshot.y[4]~FF .SR_POLARITY = 1'b1;
    defparam \snapshot.y[4]~FF .D_POLARITY = 1'b1;
    defparam \snapshot.y[4]~FF .SR_SYNC = 1'b1;
    defparam \snapshot.y[4]~FF .SR_VALUE = 1'b0;
    defparam \snapshot.y[4]~FF .SR_SYNC_PRIORITY = 1'b1;
    EFX_FF \snapshot.ann10_color[3]~FF  (.D(in_render[29]), .CE(1'b1), .CLK(clk), 
           .SR(rst), .Q(\snapshot.ann10_color [3])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_FF, CLK_POLARITY=1'b1, D_POLARITY=1'b1, CE_POLARITY=1'b1, SR_SYNC=1'b1, SR_SYNC_PRIORITY=1'b1, SR_VALUE=1'b0, SR_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(105)
    defparam \snapshot.ann10_color[3]~FF .CLK_POLARITY = 1'b1;
    defparam \snapshot.ann10_color[3]~FF .CE_POLARITY = 1'b1;
    defparam \snapshot.ann10_color[3]~FF .SR_POLARITY = 1'b1;
    defparam \snapshot.ann10_color[3]~FF .D_POLARITY = 1'b1;
    defparam \snapshot.ann10_color[3]~FF .SR_SYNC = 1'b1;
    defparam \snapshot.ann10_color[3]~FF .SR_VALUE = 1'b0;
    defparam \snapshot.ann10_color[3]~FF .SR_SYNC_PRIORITY = 1'b1;
    EFX_FF \snapshot.ann10_color[4]~FF  (.D(in_render[30]), .CE(1'b1), .CLK(clk), 
           .SR(rst), .Q(\snapshot.ann10_color [4])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_FF, CLK_POLARITY=1'b1, D_POLARITY=1'b1, CE_POLARITY=1'b1, SR_SYNC=1'b1, SR_SYNC_PRIORITY=1'b1, SR_VALUE=1'b0, SR_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(105)
    defparam \snapshot.ann10_color[4]~FF .CLK_POLARITY = 1'b1;
    defparam \snapshot.ann10_color[4]~FF .CE_POLARITY = 1'b1;
    defparam \snapshot.ann10_color[4]~FF .SR_POLARITY = 1'b1;
    defparam \snapshot.ann10_color[4]~FF .D_POLARITY = 1'b1;
    defparam \snapshot.ann10_color[4]~FF .SR_SYNC = 1'b1;
    defparam \snapshot.ann10_color[4]~FF .SR_VALUE = 1'b0;
    defparam \snapshot.ann10_color[4]~FF .SR_SYNC_PRIORITY = 1'b1;
    EFX_FF \snapshot.ann10_color[5]~FF  (.D(in_render[31]), .CE(1'b1), .CLK(clk), 
           .SR(rst), .Q(\snapshot.ann10_color [5])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_FF, CLK_POLARITY=1'b1, D_POLARITY=1'b1, CE_POLARITY=1'b1, SR_SYNC=1'b1, SR_SYNC_PRIORITY=1'b1, SR_VALUE=1'b0, SR_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(105)
    defparam \snapshot.ann10_color[5]~FF .CLK_POLARITY = 1'b1;
    defparam \snapshot.ann10_color[5]~FF .CE_POLARITY = 1'b1;
    defparam \snapshot.ann10_color[5]~FF .SR_POLARITY = 1'b1;
    defparam \snapshot.ann10_color[5]~FF .D_POLARITY = 1'b1;
    defparam \snapshot.ann10_color[5]~FF .SR_SYNC = 1'b1;
    defparam \snapshot.ann10_color[5]~FF .SR_VALUE = 1'b0;
    defparam \snapshot.ann10_color[5]~FF .SR_SYNC_PRIORITY = 1'b1;
    EFX_FF \snapshot.ann10_color[6]~FF  (.D(in_render[32]), .CE(1'b1), .CLK(clk), 
           .SR(rst), .Q(\snapshot.ann10_color [6])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_FF, CLK_POLARITY=1'b1, D_POLARITY=1'b1, CE_POLARITY=1'b1, SR_SYNC=1'b1, SR_SYNC_PRIORITY=1'b1, SR_VALUE=1'b0, SR_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(105)
    defparam \snapshot.ann10_color[6]~FF .CLK_POLARITY = 1'b1;
    defparam \snapshot.ann10_color[6]~FF .CE_POLARITY = 1'b1;
    defparam \snapshot.ann10_color[6]~FF .SR_POLARITY = 1'b1;
    defparam \snapshot.ann10_color[6]~FF .D_POLARITY = 1'b1;
    defparam \snapshot.ann10_color[6]~FF .SR_SYNC = 1'b1;
    defparam \snapshot.ann10_color[6]~FF .SR_VALUE = 1'b0;
    defparam \snapshot.ann10_color[6]~FF .SR_SYNC_PRIORITY = 1'b1;
    EFX_FF \snapshot.ann10_color[7]~FF  (.D(in_render[33]), .CE(1'b1), .CLK(clk), 
           .SR(rst), .Q(\snapshot.ann10_color [7])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_FF, CLK_POLARITY=1'b1, D_POLARITY=1'b1, CE_POLARITY=1'b1, SR_SYNC=1'b1, SR_SYNC_PRIORITY=1'b1, SR_VALUE=1'b0, SR_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(105)
    defparam \snapshot.ann10_color[7]~FF .CLK_POLARITY = 1'b1;
    defparam \snapshot.ann10_color[7]~FF .CE_POLARITY = 1'b1;
    defparam \snapshot.ann10_color[7]~FF .SR_POLARITY = 1'b1;
    defparam \snapshot.ann10_color[7]~FF .D_POLARITY = 1'b1;
    defparam \snapshot.ann10_color[7]~FF .SR_SYNC = 1'b1;
    defparam \snapshot.ann10_color[7]~FF .SR_VALUE = 1'b0;
    defparam \snapshot.ann10_color[7]~FF .SR_SYNC_PRIORITY = 1'b1;
    EFX_FF \snapshot.ann10_color[8]~FF  (.D(in_render[34]), .CE(1'b1), .CLK(clk), 
           .SR(rst), .Q(\snapshot.ann10_color [8])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_FF, CLK_POLARITY=1'b1, D_POLARITY=1'b1, CE_POLARITY=1'b1, SR_SYNC=1'b1, SR_SYNC_PRIORITY=1'b1, SR_VALUE=1'b0, SR_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(105)
    defparam \snapshot.ann10_color[8]~FF .CLK_POLARITY = 1'b1;
    defparam \snapshot.ann10_color[8]~FF .CE_POLARITY = 1'b1;
    defparam \snapshot.ann10_color[8]~FF .SR_POLARITY = 1'b1;
    defparam \snapshot.ann10_color[8]~FF .D_POLARITY = 1'b1;
    defparam \snapshot.ann10_color[8]~FF .SR_SYNC = 1'b1;
    defparam \snapshot.ann10_color[8]~FF .SR_VALUE = 1'b0;
    defparam \snapshot.ann10_color[8]~FF .SR_SYNC_PRIORITY = 1'b1;
    EFX_FF \snapshot.ann10_color[9]~FF  (.D(in_render[35]), .CE(1'b1), .CLK(clk), 
           .SR(rst), .Q(\snapshot.ann10_color [9])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_FF, CLK_POLARITY=1'b1, D_POLARITY=1'b1, CE_POLARITY=1'b1, SR_SYNC=1'b1, SR_SYNC_PRIORITY=1'b1, SR_VALUE=1'b0, SR_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(105)
    defparam \snapshot.ann10_color[9]~FF .CLK_POLARITY = 1'b1;
    defparam \snapshot.ann10_color[9]~FF .CE_POLARITY = 1'b1;
    defparam \snapshot.ann10_color[9]~FF .SR_POLARITY = 1'b1;
    defparam \snapshot.ann10_color[9]~FF .D_POLARITY = 1'b1;
    defparam \snapshot.ann10_color[9]~FF .SR_SYNC = 1'b1;
    defparam \snapshot.ann10_color[9]~FF .SR_VALUE = 1'b0;
    defparam \snapshot.ann10_color[9]~FF .SR_SYNC_PRIORITY = 1'b1;
    EFX_FF \snapshot.ann10_color[10]~FF  (.D(in_render[36]), .CE(1'b1), 
           .CLK(clk), .SR(rst), .Q(\snapshot.ann10_color [10])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_FF, CLK_POLARITY=1'b1, D_POLARITY=1'b1, CE_POLARITY=1'b1, SR_SYNC=1'b1, SR_SYNC_PRIORITY=1'b1, SR_VALUE=1'b0, SR_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(105)
    defparam \snapshot.ann10_color[10]~FF .CLK_POLARITY = 1'b1;
    defparam \snapshot.ann10_color[10]~FF .CE_POLARITY = 1'b1;
    defparam \snapshot.ann10_color[10]~FF .SR_POLARITY = 1'b1;
    defparam \snapshot.ann10_color[10]~FF .D_POLARITY = 1'b1;
    defparam \snapshot.ann10_color[10]~FF .SR_SYNC = 1'b1;
    defparam \snapshot.ann10_color[10]~FF .SR_VALUE = 1'b0;
    defparam \snapshot.ann10_color[10]~FF .SR_SYNC_PRIORITY = 1'b1;
    EFX_FF \snapshot.ann10_color[11]~FF  (.D(in_render[37]), .CE(1'b1), 
           .CLK(clk), .SR(rst), .Q(\snapshot.ann10_color [11])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_FF, CLK_POLARITY=1'b1, D_POLARITY=1'b1, CE_POLARITY=1'b1, SR_SYNC=1'b1, SR_SYNC_PRIORITY=1'b1, SR_VALUE=1'b0, SR_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(105)
    defparam \snapshot.ann10_color[11]~FF .CLK_POLARITY = 1'b1;
    defparam \snapshot.ann10_color[11]~FF .CE_POLARITY = 1'b1;
    defparam \snapshot.ann10_color[11]~FF .SR_POLARITY = 1'b1;
    defparam \snapshot.ann10_color[11]~FF .D_POLARITY = 1'b1;
    defparam \snapshot.ann10_color[11]~FF .SR_SYNC = 1'b1;
    defparam \snapshot.ann10_color[11]~FF .SR_VALUE = 1'b0;
    defparam \snapshot.ann10_color[11]~FF .SR_SYNC_PRIORITY = 1'b1;
    EFX_FF \snapshot.ann10_color[12]~FF  (.D(in_render[38]), .CE(1'b1), 
           .CLK(clk), .SR(rst), .Q(\snapshot.ann10_color [12])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_FF, CLK_POLARITY=1'b1, D_POLARITY=1'b1, CE_POLARITY=1'b1, SR_SYNC=1'b1, SR_SYNC_PRIORITY=1'b1, SR_VALUE=1'b0, SR_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(105)
    defparam \snapshot.ann10_color[12]~FF .CLK_POLARITY = 1'b1;
    defparam \snapshot.ann10_color[12]~FF .CE_POLARITY = 1'b1;
    defparam \snapshot.ann10_color[12]~FF .SR_POLARITY = 1'b1;
    defparam \snapshot.ann10_color[12]~FF .D_POLARITY = 1'b1;
    defparam \snapshot.ann10_color[12]~FF .SR_SYNC = 1'b1;
    defparam \snapshot.ann10_color[12]~FF .SR_VALUE = 1'b0;
    defparam \snapshot.ann10_color[12]~FF .SR_SYNC_PRIORITY = 1'b1;
    EFX_FF \snapshot.ann10_color[13]~FF  (.D(in_render[39]), .CE(1'b1), 
           .CLK(clk), .SR(rst), .Q(\snapshot.ann10_color [13])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_FF, CLK_POLARITY=1'b1, D_POLARITY=1'b1, CE_POLARITY=1'b1, SR_SYNC=1'b1, SR_SYNC_PRIORITY=1'b1, SR_VALUE=1'b0, SR_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(105)
    defparam \snapshot.ann10_color[13]~FF .CLK_POLARITY = 1'b1;
    defparam \snapshot.ann10_color[13]~FF .CE_POLARITY = 1'b1;
    defparam \snapshot.ann10_color[13]~FF .SR_POLARITY = 1'b1;
    defparam \snapshot.ann10_color[13]~FF .D_POLARITY = 1'b1;
    defparam \snapshot.ann10_color[13]~FF .SR_SYNC = 1'b1;
    defparam \snapshot.ann10_color[13]~FF .SR_VALUE = 1'b0;
    defparam \snapshot.ann10_color[13]~FF .SR_SYNC_PRIORITY = 1'b1;
    EFX_FF \snapshot.ann10_color[14]~FF  (.D(in_render[40]), .CE(1'b1), 
           .CLK(clk), .SR(rst), .Q(\snapshot.ann10_color [14])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_FF, CLK_POLARITY=1'b1, D_POLARITY=1'b1, CE_POLARITY=1'b1, SR_SYNC=1'b1, SR_SYNC_PRIORITY=1'b1, SR_VALUE=1'b0, SR_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(105)
    defparam \snapshot.ann10_color[14]~FF .CLK_POLARITY = 1'b1;
    defparam \snapshot.ann10_color[14]~FF .CE_POLARITY = 1'b1;
    defparam \snapshot.ann10_color[14]~FF .SR_POLARITY = 1'b1;
    defparam \snapshot.ann10_color[14]~FF .D_POLARITY = 1'b1;
    defparam \snapshot.ann10_color[14]~FF .SR_SYNC = 1'b1;
    defparam \snapshot.ann10_color[14]~FF .SR_VALUE = 1'b0;
    defparam \snapshot.ann10_color[14]~FF .SR_SYNC_PRIORITY = 1'b1;
    EFX_FF \snapshot.ann10_color[15]~FF  (.D(in_render[41]), .CE(1'b1), 
           .CLK(clk), .SR(rst), .Q(\snapshot.ann10_color [15])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_FF, CLK_POLARITY=1'b1, D_POLARITY=1'b1, CE_POLARITY=1'b1, SR_SYNC=1'b1, SR_SYNC_PRIORITY=1'b1, SR_VALUE=1'b0, SR_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(105)
    defparam \snapshot.ann10_color[15]~FF .CLK_POLARITY = 1'b1;
    defparam \snapshot.ann10_color[15]~FF .CE_POLARITY = 1'b1;
    defparam \snapshot.ann10_color[15]~FF .SR_POLARITY = 1'b1;
    defparam \snapshot.ann10_color[15]~FF .D_POLARITY = 1'b1;
    defparam \snapshot.ann10_color[15]~FF .SR_SYNC = 1'b1;
    defparam \snapshot.ann10_color[15]~FF .SR_VALUE = 1'b0;
    defparam \snapshot.ann10_color[15]~FF .SR_SYNC_PRIORITY = 1'b1;
    EFX_FF \snapshot.ann10_color[16]~FF  (.D(in_render[42]), .CE(1'b1), 
           .CLK(clk), .SR(rst), .Q(\snapshot.ann10_color [16])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_FF, CLK_POLARITY=1'b1, D_POLARITY=1'b1, CE_POLARITY=1'b1, SR_SYNC=1'b1, SR_SYNC_PRIORITY=1'b1, SR_VALUE=1'b0, SR_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(105)
    defparam \snapshot.ann10_color[16]~FF .CLK_POLARITY = 1'b1;
    defparam \snapshot.ann10_color[16]~FF .CE_POLARITY = 1'b1;
    defparam \snapshot.ann10_color[16]~FF .SR_POLARITY = 1'b1;
    defparam \snapshot.ann10_color[16]~FF .D_POLARITY = 1'b1;
    defparam \snapshot.ann10_color[16]~FF .SR_SYNC = 1'b1;
    defparam \snapshot.ann10_color[16]~FF .SR_VALUE = 1'b0;
    defparam \snapshot.ann10_color[16]~FF .SR_SYNC_PRIORITY = 1'b1;
    EFX_FF \snapshot.ann10_color[17]~FF  (.D(in_render[43]), .CE(1'b1), 
           .CLK(clk), .SR(rst), .Q(\snapshot.ann10_color [17])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_FF, CLK_POLARITY=1'b1, D_POLARITY=1'b1, CE_POLARITY=1'b1, SR_SYNC=1'b1, SR_SYNC_PRIORITY=1'b1, SR_VALUE=1'b0, SR_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(105)
    defparam \snapshot.ann10_color[17]~FF .CLK_POLARITY = 1'b1;
    defparam \snapshot.ann10_color[17]~FF .CE_POLARITY = 1'b1;
    defparam \snapshot.ann10_color[17]~FF .SR_POLARITY = 1'b1;
    defparam \snapshot.ann10_color[17]~FF .D_POLARITY = 1'b1;
    defparam \snapshot.ann10_color[17]~FF .SR_SYNC = 1'b1;
    defparam \snapshot.ann10_color[17]~FF .SR_VALUE = 1'b0;
    defparam \snapshot.ann10_color[17]~FF .SR_SYNC_PRIORITY = 1'b1;
    EFX_FF \snapshot.ann10_color[18]~FF  (.D(in_render[44]), .CE(1'b1), 
           .CLK(clk), .SR(rst), .Q(\snapshot.ann10_color [18])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_FF, CLK_POLARITY=1'b1, D_POLARITY=1'b1, CE_POLARITY=1'b1, SR_SYNC=1'b1, SR_SYNC_PRIORITY=1'b1, SR_VALUE=1'b0, SR_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(105)
    defparam \snapshot.ann10_color[18]~FF .CLK_POLARITY = 1'b1;
    defparam \snapshot.ann10_color[18]~FF .CE_POLARITY = 1'b1;
    defparam \snapshot.ann10_color[18]~FF .SR_POLARITY = 1'b1;
    defparam \snapshot.ann10_color[18]~FF .D_POLARITY = 1'b1;
    defparam \snapshot.ann10_color[18]~FF .SR_SYNC = 1'b1;
    defparam \snapshot.ann10_color[18]~FF .SR_VALUE = 1'b0;
    defparam \snapshot.ann10_color[18]~FF .SR_SYNC_PRIORITY = 1'b1;
    EFX_FF \snapshot.ann10_color[19]~FF  (.D(in_render[45]), .CE(1'b1), 
           .CLK(clk), .SR(rst), .Q(\snapshot.ann10_color [19])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_FF, CLK_POLARITY=1'b1, D_POLARITY=1'b1, CE_POLARITY=1'b1, SR_SYNC=1'b1, SR_SYNC_PRIORITY=1'b1, SR_VALUE=1'b0, SR_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(105)
    defparam \snapshot.ann10_color[19]~FF .CLK_POLARITY = 1'b1;
    defparam \snapshot.ann10_color[19]~FF .CE_POLARITY = 1'b1;
    defparam \snapshot.ann10_color[19]~FF .SR_POLARITY = 1'b1;
    defparam \snapshot.ann10_color[19]~FF .D_POLARITY = 1'b1;
    defparam \snapshot.ann10_color[19]~FF .SR_SYNC = 1'b1;
    defparam \snapshot.ann10_color[19]~FF .SR_VALUE = 1'b0;
    defparam \snapshot.ann10_color[19]~FF .SR_SYNC_PRIORITY = 1'b1;
    EFX_FF \snapshot.ann10_color[20]~FF  (.D(in_render[46]), .CE(1'b1), 
           .CLK(clk), .SR(rst), .Q(\snapshot.ann10_color [20])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_FF, CLK_POLARITY=1'b1, D_POLARITY=1'b1, CE_POLARITY=1'b1, SR_SYNC=1'b1, SR_SYNC_PRIORITY=1'b1, SR_VALUE=1'b0, SR_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(105)
    defparam \snapshot.ann10_color[20]~FF .CLK_POLARITY = 1'b1;
    defparam \snapshot.ann10_color[20]~FF .CE_POLARITY = 1'b1;
    defparam \snapshot.ann10_color[20]~FF .SR_POLARITY = 1'b1;
    defparam \snapshot.ann10_color[20]~FF .D_POLARITY = 1'b1;
    defparam \snapshot.ann10_color[20]~FF .SR_SYNC = 1'b1;
    defparam \snapshot.ann10_color[20]~FF .SR_VALUE = 1'b0;
    defparam \snapshot.ann10_color[20]~FF .SR_SYNC_PRIORITY = 1'b1;
    EFX_FF \snapshot.ann10_color[21]~FF  (.D(in_render[47]), .CE(1'b1), 
           .CLK(clk), .SR(rst), .Q(\snapshot.ann10_color [21])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_FF, CLK_POLARITY=1'b1, D_POLARITY=1'b1, CE_POLARITY=1'b1, SR_SYNC=1'b1, SR_SYNC_PRIORITY=1'b1, SR_VALUE=1'b0, SR_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(105)
    defparam \snapshot.ann10_color[21]~FF .CLK_POLARITY = 1'b1;
    defparam \snapshot.ann10_color[21]~FF .CE_POLARITY = 1'b1;
    defparam \snapshot.ann10_color[21]~FF .SR_POLARITY = 1'b1;
    defparam \snapshot.ann10_color[21]~FF .D_POLARITY = 1'b1;
    defparam \snapshot.ann10_color[21]~FF .SR_SYNC = 1'b1;
    defparam \snapshot.ann10_color[21]~FF .SR_VALUE = 1'b0;
    defparam \snapshot.ann10_color[21]~FF .SR_SYNC_PRIORITY = 1'b1;
    EFX_FF \snapshot.ann10_color[22]~FF  (.D(in_render[48]), .CE(1'b1), 
           .CLK(clk), .SR(rst), .Q(\snapshot.ann10_color [22])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_FF, CLK_POLARITY=1'b1, D_POLARITY=1'b1, CE_POLARITY=1'b1, SR_SYNC=1'b1, SR_SYNC_PRIORITY=1'b1, SR_VALUE=1'b0, SR_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(105)
    defparam \snapshot.ann10_color[22]~FF .CLK_POLARITY = 1'b1;
    defparam \snapshot.ann10_color[22]~FF .CE_POLARITY = 1'b1;
    defparam \snapshot.ann10_color[22]~FF .SR_POLARITY = 1'b1;
    defparam \snapshot.ann10_color[22]~FF .D_POLARITY = 1'b1;
    defparam \snapshot.ann10_color[22]~FF .SR_SYNC = 1'b1;
    defparam \snapshot.ann10_color[22]~FF .SR_VALUE = 1'b0;
    defparam \snapshot.ann10_color[22]~FF .SR_SYNC_PRIORITY = 1'b1;
    EFX_FF \snapshot.ann10_color[23]~FF  (.D(in_render[49]), .CE(1'b1), 
           .CLK(clk), .SR(rst), .Q(\snapshot.ann10_color [23])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_FF, CLK_POLARITY=1'b1, D_POLARITY=1'b1, CE_POLARITY=1'b1, SR_SYNC=1'b1, SR_SYNC_PRIORITY=1'b1, SR_VALUE=1'b0, SR_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(105)
    defparam \snapshot.ann10_color[23]~FF .CLK_POLARITY = 1'b1;
    defparam \snapshot.ann10_color[23]~FF .CE_POLARITY = 1'b1;
    defparam \snapshot.ann10_color[23]~FF .SR_POLARITY = 1'b1;
    defparam \snapshot.ann10_color[23]~FF .D_POLARITY = 1'b1;
    defparam \snapshot.ann10_color[23]~FF .SR_SYNC = 1'b1;
    defparam \snapshot.ann10_color[23]~FF .SR_VALUE = 1'b0;
    defparam \snapshot.ann10_color[23]~FF .SR_SYNC_PRIORITY = 1'b1;
    EFX_FF \snapshot.ann01_color[0]~FF  (.D(in_render[50]), .CE(1'b1), .CLK(clk), 
           .SR(rst), .Q(\snapshot.ann01_color [0])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_FF, CLK_POLARITY=1'b1, D_POLARITY=1'b1, CE_POLARITY=1'b1, SR_SYNC=1'b1, SR_SYNC_PRIORITY=1'b1, SR_VALUE=1'b0, SR_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(105)
    defparam \snapshot.ann01_color[0]~FF .CLK_POLARITY = 1'b1;
    defparam \snapshot.ann01_color[0]~FF .CE_POLARITY = 1'b1;
    defparam \snapshot.ann01_color[0]~FF .SR_POLARITY = 1'b1;
    defparam \snapshot.ann01_color[0]~FF .D_POLARITY = 1'b1;
    defparam \snapshot.ann01_color[0]~FF .SR_SYNC = 1'b1;
    defparam \snapshot.ann01_color[0]~FF .SR_VALUE = 1'b0;
    defparam \snapshot.ann01_color[0]~FF .SR_SYNC_PRIORITY = 1'b1;
    EFX_FF \snapshot.ann01_color[1]~FF  (.D(in_render[51]), .CE(1'b1), .CLK(clk), 
           .SR(rst), .Q(\snapshot.ann01_color [1])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_FF, CLK_POLARITY=1'b1, D_POLARITY=1'b1, CE_POLARITY=1'b1, SR_SYNC=1'b1, SR_SYNC_PRIORITY=1'b1, SR_VALUE=1'b0, SR_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(105)
    defparam \snapshot.ann01_color[1]~FF .CLK_POLARITY = 1'b1;
    defparam \snapshot.ann01_color[1]~FF .CE_POLARITY = 1'b1;
    defparam \snapshot.ann01_color[1]~FF .SR_POLARITY = 1'b1;
    defparam \snapshot.ann01_color[1]~FF .D_POLARITY = 1'b1;
    defparam \snapshot.ann01_color[1]~FF .SR_SYNC = 1'b1;
    defparam \snapshot.ann01_color[1]~FF .SR_VALUE = 1'b0;
    defparam \snapshot.ann01_color[1]~FF .SR_SYNC_PRIORITY = 1'b1;
    EFX_FF \snapshot.y[3]~FF  (.D(in_y[3]), .CE(1'b1), .CLK(clk), .SR(rst), 
           .Q(\snapshot.y [3])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_FF, CLK_POLARITY=1'b1, D_POLARITY=1'b1, CE_POLARITY=1'b1, SR_SYNC=1'b1, SR_SYNC_PRIORITY=1'b1, SR_VALUE=1'b0, SR_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(105)
    defparam \snapshot.y[3]~FF .CLK_POLARITY = 1'b1;
    defparam \snapshot.y[3]~FF .CE_POLARITY = 1'b1;
    defparam \snapshot.y[3]~FF .SR_POLARITY = 1'b1;
    defparam \snapshot.y[3]~FF .D_POLARITY = 1'b1;
    defparam \snapshot.y[3]~FF .SR_SYNC = 1'b1;
    defparam \snapshot.y[3]~FF .SR_VALUE = 1'b0;
    defparam \snapshot.y[3]~FF .SR_SYNC_PRIORITY = 1'b1;
    EFX_FF \snapshot.y[2]~FF  (.D(in_y[2]), .CE(1'b1), .CLK(clk), .SR(rst), 
           .Q(\snapshot.y [2])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_FF, CLK_POLARITY=1'b1, D_POLARITY=1'b1, CE_POLARITY=1'b1, SR_SYNC=1'b1, SR_SYNC_PRIORITY=1'b1, SR_VALUE=1'b0, SR_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(105)
    defparam \snapshot.y[2]~FF .CLK_POLARITY = 1'b1;
    defparam \snapshot.y[2]~FF .CE_POLARITY = 1'b1;
    defparam \snapshot.y[2]~FF .SR_POLARITY = 1'b1;
    defparam \snapshot.y[2]~FF .D_POLARITY = 1'b1;
    defparam \snapshot.y[2]~FF .SR_SYNC = 1'b1;
    defparam \snapshot.y[2]~FF .SR_VALUE = 1'b0;
    defparam \snapshot.y[2]~FF .SR_SYNC_PRIORITY = 1'b1;
    EFX_FF \snapshot.y[1]~FF  (.D(in_y[1]), .CE(1'b1), .CLK(clk), .SR(rst), 
           .Q(\snapshot.y [1])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_FF, CLK_POLARITY=1'b1, D_POLARITY=1'b1, CE_POLARITY=1'b1, SR_SYNC=1'b1, SR_SYNC_PRIORITY=1'b1, SR_VALUE=1'b0, SR_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(105)
    defparam \snapshot.y[1]~FF .CLK_POLARITY = 1'b1;
    defparam \snapshot.y[1]~FF .CE_POLARITY = 1'b1;
    defparam \snapshot.y[1]~FF .SR_POLARITY = 1'b1;
    defparam \snapshot.y[1]~FF .D_POLARITY = 1'b1;
    defparam \snapshot.y[1]~FF .SR_SYNC = 1'b1;
    defparam \snapshot.y[1]~FF .SR_VALUE = 1'b0;
    defparam \snapshot.y[1]~FF .SR_SYNC_PRIORITY = 1'b1;
    EFX_FF \snapshot.y[0]~FF  (.D(in_y[0]), .CE(1'b1), .CLK(clk), .SR(rst), 
           .Q(\snapshot.y [0])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_FF, CLK_POLARITY=1'b1, D_POLARITY=1'b1, CE_POLARITY=1'b1, SR_SYNC=1'b1, SR_SYNC_PRIORITY=1'b1, SR_VALUE=1'b0, SR_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(105)
    defparam \snapshot.y[0]~FF .CLK_POLARITY = 1'b1;
    defparam \snapshot.y[0]~FF .CE_POLARITY = 1'b1;
    defparam \snapshot.y[0]~FF .SR_POLARITY = 1'b1;
    defparam \snapshot.y[0]~FF .D_POLARITY = 1'b1;
    defparam \snapshot.y[0]~FF .SR_SYNC = 1'b1;
    defparam \snapshot.y[0]~FF .SR_VALUE = 1'b0;
    defparam \snapshot.y[0]~FF .SR_SYNC_PRIORITY = 1'b1;
    EFX_FF \snapshot.error[1]~FF  (.D(\next_snapshot.error [1]), .CE(1'b1), 
           .CLK(clk), .SR(rst), .Q(\snapshot.error [1])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_FF, CLK_POLARITY=1'b1, D_POLARITY=1'b1, CE_POLARITY=1'b1, SR_SYNC=1'b1, SR_SYNC_PRIORITY=1'b1, SR_VALUE=1'b0, SR_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(105)
    defparam \snapshot.error[1]~FF .CLK_POLARITY = 1'b1;
    defparam \snapshot.error[1]~FF .CE_POLARITY = 1'b1;
    defparam \snapshot.error[1]~FF .SR_POLARITY = 1'b1;
    defparam \snapshot.error[1]~FF .D_POLARITY = 1'b1;
    defparam \snapshot.error[1]~FF .SR_SYNC = 1'b1;
    defparam \snapshot.error[1]~FF .SR_VALUE = 1'b0;
    defparam \snapshot.error[1]~FF .SR_SYNC_PRIORITY = 1'b1;
    EFX_FF \snapshot.ann11_color[17]~FF  (.D(in_render[19]), .CE(1'b1), 
           .CLK(clk), .SR(rst), .Q(\snapshot.ann11_color [17])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_FF, CLK_POLARITY=1'b1, D_POLARITY=1'b1, CE_POLARITY=1'b1, SR_SYNC=1'b1, SR_SYNC_PRIORITY=1'b1, SR_VALUE=1'b0, SR_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(105)
    defparam \snapshot.ann11_color[17]~FF .CLK_POLARITY = 1'b1;
    defparam \snapshot.ann11_color[17]~FF .CE_POLARITY = 1'b1;
    defparam \snapshot.ann11_color[17]~FF .SR_POLARITY = 1'b1;
    defparam \snapshot.ann11_color[17]~FF .D_POLARITY = 1'b1;
    defparam \snapshot.ann11_color[17]~FF .SR_SYNC = 1'b1;
    defparam \snapshot.ann11_color[17]~FF .SR_VALUE = 1'b0;
    defparam \snapshot.ann11_color[17]~FF .SR_SYNC_PRIORITY = 1'b1;
    EFX_FF \snapshot.ann11_color[18]~FF  (.D(in_render[20]), .CE(1'b1), 
           .CLK(clk), .SR(rst), .Q(\snapshot.ann11_color [18])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_FF, CLK_POLARITY=1'b1, D_POLARITY=1'b1, CE_POLARITY=1'b1, SR_SYNC=1'b1, SR_SYNC_PRIORITY=1'b1, SR_VALUE=1'b0, SR_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(105)
    defparam \snapshot.ann11_color[18]~FF .CLK_POLARITY = 1'b1;
    defparam \snapshot.ann11_color[18]~FF .CE_POLARITY = 1'b1;
    defparam \snapshot.ann11_color[18]~FF .SR_POLARITY = 1'b1;
    defparam \snapshot.ann11_color[18]~FF .D_POLARITY = 1'b1;
    defparam \snapshot.ann11_color[18]~FF .SR_SYNC = 1'b1;
    defparam \snapshot.ann11_color[18]~FF .SR_VALUE = 1'b0;
    defparam \snapshot.ann11_color[18]~FF .SR_SYNC_PRIORITY = 1'b1;
    EFX_FF \snapshot.ann11_color[19]~FF  (.D(in_render[21]), .CE(1'b1), 
           .CLK(clk), .SR(rst), .Q(\snapshot.ann11_color [19])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_FF, CLK_POLARITY=1'b1, D_POLARITY=1'b1, CE_POLARITY=1'b1, SR_SYNC=1'b1, SR_SYNC_PRIORITY=1'b1, SR_VALUE=1'b0, SR_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(105)
    defparam \snapshot.ann11_color[19]~FF .CLK_POLARITY = 1'b1;
    defparam \snapshot.ann11_color[19]~FF .CE_POLARITY = 1'b1;
    defparam \snapshot.ann11_color[19]~FF .SR_POLARITY = 1'b1;
    defparam \snapshot.ann11_color[19]~FF .D_POLARITY = 1'b1;
    defparam \snapshot.ann11_color[19]~FF .SR_SYNC = 1'b1;
    defparam \snapshot.ann11_color[19]~FF .SR_VALUE = 1'b0;
    defparam \snapshot.ann11_color[19]~FF .SR_SYNC_PRIORITY = 1'b1;
    EFX_FF \snapshot.ann11_color[20]~FF  (.D(in_render[22]), .CE(1'b1), 
           .CLK(clk), .SR(rst), .Q(\snapshot.ann11_color [20])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_FF, CLK_POLARITY=1'b1, D_POLARITY=1'b1, CE_POLARITY=1'b1, SR_SYNC=1'b1, SR_SYNC_PRIORITY=1'b1, SR_VALUE=1'b0, SR_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(105)
    defparam \snapshot.ann11_color[20]~FF .CLK_POLARITY = 1'b1;
    defparam \snapshot.ann11_color[20]~FF .CE_POLARITY = 1'b1;
    defparam \snapshot.ann11_color[20]~FF .SR_POLARITY = 1'b1;
    defparam \snapshot.ann11_color[20]~FF .D_POLARITY = 1'b1;
    defparam \snapshot.ann11_color[20]~FF .SR_SYNC = 1'b1;
    defparam \snapshot.ann11_color[20]~FF .SR_VALUE = 1'b0;
    defparam \snapshot.ann11_color[20]~FF .SR_SYNC_PRIORITY = 1'b1;
    EFX_FF \snapshot.ann11_color[21]~FF  (.D(in_render[23]), .CE(1'b1), 
           .CLK(clk), .SR(rst), .Q(\snapshot.ann11_color [21])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_FF, CLK_POLARITY=1'b1, D_POLARITY=1'b1, CE_POLARITY=1'b1, SR_SYNC=1'b1, SR_SYNC_PRIORITY=1'b1, SR_VALUE=1'b0, SR_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(105)
    defparam \snapshot.ann11_color[21]~FF .CLK_POLARITY = 1'b1;
    defparam \snapshot.ann11_color[21]~FF .CE_POLARITY = 1'b1;
    defparam \snapshot.ann11_color[21]~FF .SR_POLARITY = 1'b1;
    defparam \snapshot.ann11_color[21]~FF .D_POLARITY = 1'b1;
    defparam \snapshot.ann11_color[21]~FF .SR_SYNC = 1'b1;
    defparam \snapshot.ann11_color[21]~FF .SR_VALUE = 1'b0;
    defparam \snapshot.ann11_color[21]~FF .SR_SYNC_PRIORITY = 1'b1;
    EFX_FF \snapshot.ann11_color[22]~FF  (.D(in_render[24]), .CE(1'b1), 
           .CLK(clk), .SR(rst), .Q(\snapshot.ann11_color [22])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_FF, CLK_POLARITY=1'b1, D_POLARITY=1'b1, CE_POLARITY=1'b1, SR_SYNC=1'b1, SR_SYNC_PRIORITY=1'b1, SR_VALUE=1'b0, SR_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(105)
    defparam \snapshot.ann11_color[22]~FF .CLK_POLARITY = 1'b1;
    defparam \snapshot.ann11_color[22]~FF .CE_POLARITY = 1'b1;
    defparam \snapshot.ann11_color[22]~FF .SR_POLARITY = 1'b1;
    defparam \snapshot.ann11_color[22]~FF .D_POLARITY = 1'b1;
    defparam \snapshot.ann11_color[22]~FF .SR_SYNC = 1'b1;
    defparam \snapshot.ann11_color[22]~FF .SR_VALUE = 1'b0;
    defparam \snapshot.ann11_color[22]~FF .SR_SYNC_PRIORITY = 1'b1;
    EFX_FF \snapshot.ann11_color[23]~FF  (.D(in_render[25]), .CE(1'b1), 
           .CLK(clk), .SR(rst), .Q(\snapshot.ann11_color [23])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_FF, CLK_POLARITY=1'b1, D_POLARITY=1'b1, CE_POLARITY=1'b1, SR_SYNC=1'b1, SR_SYNC_PRIORITY=1'b1, SR_VALUE=1'b0, SR_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(105)
    defparam \snapshot.ann11_color[23]~FF .CLK_POLARITY = 1'b1;
    defparam \snapshot.ann11_color[23]~FF .CE_POLARITY = 1'b1;
    defparam \snapshot.ann11_color[23]~FF .SR_POLARITY = 1'b1;
    defparam \snapshot.ann11_color[23]~FF .D_POLARITY = 1'b1;
    defparam \snapshot.ann11_color[23]~FF .SR_SYNC = 1'b1;
    defparam \snapshot.ann11_color[23]~FF .SR_VALUE = 1'b0;
    defparam \snapshot.ann11_color[23]~FF .SR_SYNC_PRIORITY = 1'b1;
    EFX_FF \snapshot.ann10_color[0]~FF  (.D(in_render[26]), .CE(1'b1), .CLK(clk), 
           .SR(rst), .Q(\snapshot.ann10_color [0])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_FF, CLK_POLARITY=1'b1, D_POLARITY=1'b1, CE_POLARITY=1'b1, SR_SYNC=1'b1, SR_SYNC_PRIORITY=1'b1, SR_VALUE=1'b0, SR_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(105)
    defparam \snapshot.ann10_color[0]~FF .CLK_POLARITY = 1'b1;
    defparam \snapshot.ann10_color[0]~FF .CE_POLARITY = 1'b1;
    defparam \snapshot.ann10_color[0]~FF .SR_POLARITY = 1'b1;
    defparam \snapshot.ann10_color[0]~FF .D_POLARITY = 1'b1;
    defparam \snapshot.ann10_color[0]~FF .SR_SYNC = 1'b1;
    defparam \snapshot.ann10_color[0]~FF .SR_VALUE = 1'b0;
    defparam \snapshot.ann10_color[0]~FF .SR_SYNC_PRIORITY = 1'b1;
    EFX_FF \snapshot.ann10_color[1]~FF  (.D(in_render[27]), .CE(1'b1), .CLK(clk), 
           .SR(rst), .Q(\snapshot.ann10_color [1])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_FF, CLK_POLARITY=1'b1, D_POLARITY=1'b1, CE_POLARITY=1'b1, SR_SYNC=1'b1, SR_SYNC_PRIORITY=1'b1, SR_VALUE=1'b0, SR_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(105)
    defparam \snapshot.ann10_color[1]~FF .CLK_POLARITY = 1'b1;
    defparam \snapshot.ann10_color[1]~FF .CE_POLARITY = 1'b1;
    defparam \snapshot.ann10_color[1]~FF .SR_POLARITY = 1'b1;
    defparam \snapshot.ann10_color[1]~FF .D_POLARITY = 1'b1;
    defparam \snapshot.ann10_color[1]~FF .SR_SYNC = 1'b1;
    defparam \snapshot.ann10_color[1]~FF .SR_VALUE = 1'b0;
    defparam \snapshot.ann10_color[1]~FF .SR_SYNC_PRIORITY = 1'b1;
    EFX_FF \snapshot.ann10_color[2]~FF  (.D(in_render[28]), .CE(1'b1), .CLK(clk), 
           .SR(rst), .Q(\snapshot.ann10_color [2])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_FF, CLK_POLARITY=1'b1, D_POLARITY=1'b1, CE_POLARITY=1'b1, SR_SYNC=1'b1, SR_SYNC_PRIORITY=1'b1, SR_VALUE=1'b0, SR_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(105)
    defparam \snapshot.ann10_color[2]~FF .CLK_POLARITY = 1'b1;
    defparam \snapshot.ann10_color[2]~FF .CE_POLARITY = 1'b1;
    defparam \snapshot.ann10_color[2]~FF .SR_POLARITY = 1'b1;
    defparam \snapshot.ann10_color[2]~FF .D_POLARITY = 1'b1;
    defparam \snapshot.ann10_color[2]~FF .SR_SYNC = 1'b1;
    defparam \snapshot.ann10_color[2]~FF .SR_VALUE = 1'b0;
    defparam \snapshot.ann10_color[2]~FF .SR_SYNC_PRIORITY = 1'b1;
    EFX_FF \snapshot.ann11_color[7]~FF  (.D(in_render[9]), .CE(1'b1), .CLK(clk), 
           .SR(rst), .Q(\snapshot.ann11_color [7])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_FF, CLK_POLARITY=1'b1, D_POLARITY=1'b1, CE_POLARITY=1'b1, SR_SYNC=1'b1, SR_SYNC_PRIORITY=1'b1, SR_VALUE=1'b0, SR_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(105)
    defparam \snapshot.ann11_color[7]~FF .CLK_POLARITY = 1'b1;
    defparam \snapshot.ann11_color[7]~FF .CE_POLARITY = 1'b1;
    defparam \snapshot.ann11_color[7]~FF .SR_POLARITY = 1'b1;
    defparam \snapshot.ann11_color[7]~FF .D_POLARITY = 1'b1;
    defparam \snapshot.ann11_color[7]~FF .SR_SYNC = 1'b1;
    defparam \snapshot.ann11_color[7]~FF .SR_VALUE = 1'b0;
    defparam \snapshot.ann11_color[7]~FF .SR_SYNC_PRIORITY = 1'b1;
    EFX_FF \snapshot.ann11_color[8]~FF  (.D(in_render[10]), .CE(1'b1), .CLK(clk), 
           .SR(rst), .Q(\snapshot.ann11_color [8])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_FF, CLK_POLARITY=1'b1, D_POLARITY=1'b1, CE_POLARITY=1'b1, SR_SYNC=1'b1, SR_SYNC_PRIORITY=1'b1, SR_VALUE=1'b0, SR_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(105)
    defparam \snapshot.ann11_color[8]~FF .CLK_POLARITY = 1'b1;
    defparam \snapshot.ann11_color[8]~FF .CE_POLARITY = 1'b1;
    defparam \snapshot.ann11_color[8]~FF .SR_POLARITY = 1'b1;
    defparam \snapshot.ann11_color[8]~FF .D_POLARITY = 1'b1;
    defparam \snapshot.ann11_color[8]~FF .SR_SYNC = 1'b1;
    defparam \snapshot.ann11_color[8]~FF .SR_VALUE = 1'b0;
    defparam \snapshot.ann11_color[8]~FF .SR_SYNC_PRIORITY = 1'b1;
    EFX_FF \snapshot.ann11_color[9]~FF  (.D(in_render[11]), .CE(1'b1), .CLK(clk), 
           .SR(rst), .Q(\snapshot.ann11_color [9])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_FF, CLK_POLARITY=1'b1, D_POLARITY=1'b1, CE_POLARITY=1'b1, SR_SYNC=1'b1, SR_SYNC_PRIORITY=1'b1, SR_VALUE=1'b0, SR_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(105)
    defparam \snapshot.ann11_color[9]~FF .CLK_POLARITY = 1'b1;
    defparam \snapshot.ann11_color[9]~FF .CE_POLARITY = 1'b1;
    defparam \snapshot.ann11_color[9]~FF .SR_POLARITY = 1'b1;
    defparam \snapshot.ann11_color[9]~FF .D_POLARITY = 1'b1;
    defparam \snapshot.ann11_color[9]~FF .SR_SYNC = 1'b1;
    defparam \snapshot.ann11_color[9]~FF .SR_VALUE = 1'b0;
    defparam \snapshot.ann11_color[9]~FF .SR_SYNC_PRIORITY = 1'b1;
    EFX_FF \snapshot.ann11_color[10]~FF  (.D(in_render[12]), .CE(1'b1), 
           .CLK(clk), .SR(rst), .Q(\snapshot.ann11_color [10])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_FF, CLK_POLARITY=1'b1, D_POLARITY=1'b1, CE_POLARITY=1'b1, SR_SYNC=1'b1, SR_SYNC_PRIORITY=1'b1, SR_VALUE=1'b0, SR_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(105)
    defparam \snapshot.ann11_color[10]~FF .CLK_POLARITY = 1'b1;
    defparam \snapshot.ann11_color[10]~FF .CE_POLARITY = 1'b1;
    defparam \snapshot.ann11_color[10]~FF .SR_POLARITY = 1'b1;
    defparam \snapshot.ann11_color[10]~FF .D_POLARITY = 1'b1;
    defparam \snapshot.ann11_color[10]~FF .SR_SYNC = 1'b1;
    defparam \snapshot.ann11_color[10]~FF .SR_VALUE = 1'b0;
    defparam \snapshot.ann11_color[10]~FF .SR_SYNC_PRIORITY = 1'b1;
    EFX_FF \snapshot.ann11_color[11]~FF  (.D(in_render[13]), .CE(1'b1), 
           .CLK(clk), .SR(rst), .Q(\snapshot.ann11_color [11])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_FF, CLK_POLARITY=1'b1, D_POLARITY=1'b1, CE_POLARITY=1'b1, SR_SYNC=1'b1, SR_SYNC_PRIORITY=1'b1, SR_VALUE=1'b0, SR_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(105)
    defparam \snapshot.ann11_color[11]~FF .CLK_POLARITY = 1'b1;
    defparam \snapshot.ann11_color[11]~FF .CE_POLARITY = 1'b1;
    defparam \snapshot.ann11_color[11]~FF .SR_POLARITY = 1'b1;
    defparam \snapshot.ann11_color[11]~FF .D_POLARITY = 1'b1;
    defparam \snapshot.ann11_color[11]~FF .SR_SYNC = 1'b1;
    defparam \snapshot.ann11_color[11]~FF .SR_VALUE = 1'b0;
    defparam \snapshot.ann11_color[11]~FF .SR_SYNC_PRIORITY = 1'b1;
    EFX_FF \snapshot.ann11_color[12]~FF  (.D(in_render[14]), .CE(1'b1), 
           .CLK(clk), .SR(rst), .Q(\snapshot.ann11_color [12])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_FF, CLK_POLARITY=1'b1, D_POLARITY=1'b1, CE_POLARITY=1'b1, SR_SYNC=1'b1, SR_SYNC_PRIORITY=1'b1, SR_VALUE=1'b0, SR_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(105)
    defparam \snapshot.ann11_color[12]~FF .CLK_POLARITY = 1'b1;
    defparam \snapshot.ann11_color[12]~FF .CE_POLARITY = 1'b1;
    defparam \snapshot.ann11_color[12]~FF .SR_POLARITY = 1'b1;
    defparam \snapshot.ann11_color[12]~FF .D_POLARITY = 1'b1;
    defparam \snapshot.ann11_color[12]~FF .SR_SYNC = 1'b1;
    defparam \snapshot.ann11_color[12]~FF .SR_VALUE = 1'b0;
    defparam \snapshot.ann11_color[12]~FF .SR_SYNC_PRIORITY = 1'b1;
    EFX_FF \snapshot.ann11_color[13]~FF  (.D(in_render[15]), .CE(1'b1), 
           .CLK(clk), .SR(rst), .Q(\snapshot.ann11_color [13])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_FF, CLK_POLARITY=1'b1, D_POLARITY=1'b1, CE_POLARITY=1'b1, SR_SYNC=1'b1, SR_SYNC_PRIORITY=1'b1, SR_VALUE=1'b0, SR_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(105)
    defparam \snapshot.ann11_color[13]~FF .CLK_POLARITY = 1'b1;
    defparam \snapshot.ann11_color[13]~FF .CE_POLARITY = 1'b1;
    defparam \snapshot.ann11_color[13]~FF .SR_POLARITY = 1'b1;
    defparam \snapshot.ann11_color[13]~FF .D_POLARITY = 1'b1;
    defparam \snapshot.ann11_color[13]~FF .SR_SYNC = 1'b1;
    defparam \snapshot.ann11_color[13]~FF .SR_VALUE = 1'b0;
    defparam \snapshot.ann11_color[13]~FF .SR_SYNC_PRIORITY = 1'b1;
    EFX_FF \snapshot.ann11_color[14]~FF  (.D(in_render[16]), .CE(1'b1), 
           .CLK(clk), .SR(rst), .Q(\snapshot.ann11_color [14])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_FF, CLK_POLARITY=1'b1, D_POLARITY=1'b1, CE_POLARITY=1'b1, SR_SYNC=1'b1, SR_SYNC_PRIORITY=1'b1, SR_VALUE=1'b0, SR_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(105)
    defparam \snapshot.ann11_color[14]~FF .CLK_POLARITY = 1'b1;
    defparam \snapshot.ann11_color[14]~FF .CE_POLARITY = 1'b1;
    defparam \snapshot.ann11_color[14]~FF .SR_POLARITY = 1'b1;
    defparam \snapshot.ann11_color[14]~FF .D_POLARITY = 1'b1;
    defparam \snapshot.ann11_color[14]~FF .SR_SYNC = 1'b1;
    defparam \snapshot.ann11_color[14]~FF .SR_VALUE = 1'b0;
    defparam \snapshot.ann11_color[14]~FF .SR_SYNC_PRIORITY = 1'b1;
    EFX_FF \snapshot.ann11_color[15]~FF  (.D(in_render[17]), .CE(1'b1), 
           .CLK(clk), .SR(rst), .Q(\snapshot.ann11_color [15])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_FF, CLK_POLARITY=1'b1, D_POLARITY=1'b1, CE_POLARITY=1'b1, SR_SYNC=1'b1, SR_SYNC_PRIORITY=1'b1, SR_VALUE=1'b0, SR_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(105)
    defparam \snapshot.ann11_color[15]~FF .CLK_POLARITY = 1'b1;
    defparam \snapshot.ann11_color[15]~FF .CE_POLARITY = 1'b1;
    defparam \snapshot.ann11_color[15]~FF .SR_POLARITY = 1'b1;
    defparam \snapshot.ann11_color[15]~FF .D_POLARITY = 1'b1;
    defparam \snapshot.ann11_color[15]~FF .SR_SYNC = 1'b1;
    defparam \snapshot.ann11_color[15]~FF .SR_VALUE = 1'b0;
    defparam \snapshot.ann11_color[15]~FF .SR_SYNC_PRIORITY = 1'b1;
    EFX_FF \snapshot.ann11_color[16]~FF  (.D(in_render[18]), .CE(1'b1), 
           .CLK(clk), .SR(rst), .Q(\snapshot.ann11_color [16])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_FF, CLK_POLARITY=1'b1, D_POLARITY=1'b1, CE_POLARITY=1'b1, SR_SYNC=1'b1, SR_SYNC_PRIORITY=1'b1, SR_VALUE=1'b0, SR_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(105)
    defparam \snapshot.ann11_color[16]~FF .CLK_POLARITY = 1'b1;
    defparam \snapshot.ann11_color[16]~FF .CE_POLARITY = 1'b1;
    defparam \snapshot.ann11_color[16]~FF .SR_POLARITY = 1'b1;
    defparam \snapshot.ann11_color[16]~FF .D_POLARITY = 1'b1;
    defparam \snapshot.ann11_color[16]~FF .SR_SYNC = 1'b1;
    defparam \snapshot.ann11_color[16]~FF .SR_VALUE = 1'b0;
    defparam \snapshot.ann11_color[16]~FF .SR_SYNC_PRIORITY = 1'b1;
    EFX_FF \snapshot.vs~FF  (.D(in_vs), .CE(1'b1), .CLK(clk), .SR(rst), 
           .Q(\snapshot.vs )) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_FF, CLK_POLARITY=1'b1, D_POLARITY=1'b1, CE_POLARITY=1'b1, SR_SYNC=1'b1, SR_SYNC_PRIORITY=1'b1, SR_VALUE=1'b0, SR_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(105)
    defparam \snapshot.vs~FF .CLK_POLARITY = 1'b1;
    defparam \snapshot.vs~FF .CE_POLARITY = 1'b1;
    defparam \snapshot.vs~FF .SR_POLARITY = 1'b1;
    defparam \snapshot.vs~FF .D_POLARITY = 1'b1;
    defparam \snapshot.vs~FF .SR_SYNC = 1'b1;
    defparam \snapshot.vs~FF .SR_VALUE = 1'b0;
    defparam \snapshot.vs~FF .SR_SYNC_PRIORITY = 1'b1;
    EFX_FF \out_de~FF  (.D(\snapshot.de ), .CE(1'b1), .CLK(clk), .SR(rst), 
           .Q(out_de)) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_FF, CLK_POLARITY=1'b1, D_POLARITY=1'b1, CE_POLARITY=1'b1, SR_SYNC=1'b1, SR_SYNC_PRIORITY=1'b1, SR_VALUE=1'b0, SR_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(105)
    defparam \out_de~FF .CLK_POLARITY = 1'b1;
    defparam \out_de~FF .CE_POLARITY = 1'b1;
    defparam \out_de~FF .SR_POLARITY = 1'b1;
    defparam \out_de~FF .D_POLARITY = 1'b1;
    defparam \out_de~FF .SR_SYNC = 1'b1;
    defparam \out_de~FF .SR_VALUE = 1'b0;
    defparam \out_de~FF .SR_SYNC_PRIORITY = 1'b1;
    EFX_FF \out_hs~FF  (.D(\snapshot.hs ), .CE(1'b1), .CLK(clk), .SR(rst), 
           .Q(out_hs)) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_FF, CLK_POLARITY=1'b1, D_POLARITY=1'b1, CE_POLARITY=1'b1, SR_SYNC=1'b1, SR_SYNC_PRIORITY=1'b1, SR_VALUE=1'b0, SR_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(105)
    defparam \out_hs~FF .CLK_POLARITY = 1'b1;
    defparam \out_hs~FF .CE_POLARITY = 1'b1;
    defparam \out_hs~FF .SR_POLARITY = 1'b1;
    defparam \out_hs~FF .D_POLARITY = 1'b1;
    defparam \out_hs~FF .SR_SYNC = 1'b1;
    defparam \out_hs~FF .SR_VALUE = 1'b0;
    defparam \out_hs~FF .SR_SYNC_PRIORITY = 1'b1;
    EFX_FF \out_vs~FF  (.D(\snapshot.vs ), .CE(1'b1), .CLK(clk), .SR(rst), 
           .Q(out_vs)) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_FF, CLK_POLARITY=1'b1, D_POLARITY=1'b1, CE_POLARITY=1'b1, SR_SYNC=1'b1, SR_SYNC_PRIORITY=1'b1, SR_VALUE=1'b0, SR_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(105)
    defparam \out_vs~FF .CLK_POLARITY = 1'b1;
    defparam \out_vs~FF .CE_POLARITY = 1'b1;
    defparam \out_vs~FF .SR_POLARITY = 1'b1;
    defparam \out_vs~FF .D_POLARITY = 1'b1;
    defparam \out_vs~FF .SR_SYNC = 1'b1;
    defparam \out_vs~FF .SR_VALUE = 1'b0;
    defparam \out_vs~FF .SR_SYNC_PRIORITY = 1'b1;
    EFX_FF \out_frame_start~FF  (.D(\snapshot.frame_start ), .CE(1'b1), 
           .CLK(clk), .SR(rst), .Q(out_frame_start)) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_FF, CLK_POLARITY=1'b1, D_POLARITY=1'b1, CE_POLARITY=1'b1, SR_SYNC=1'b1, SR_SYNC_PRIORITY=1'b1, SR_VALUE=1'b0, SR_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(105)
    defparam \out_frame_start~FF .CLK_POLARITY = 1'b1;
    defparam \out_frame_start~FF .CE_POLARITY = 1'b1;
    defparam \out_frame_start~FF .SR_POLARITY = 1'b1;
    defparam \out_frame_start~FF .D_POLARITY = 1'b1;
    defparam \out_frame_start~FF .SR_SYNC = 1'b1;
    defparam \out_frame_start~FF .SR_VALUE = 1'b0;
    defparam \out_frame_start~FF .SR_SYNC_PRIORITY = 1'b1;
    EFX_FF \out_y[0]~FF  (.D(\snapshot.y [0]), .CE(1'b1), .CLK(clk), .SR(rst), 
           .Q(out_y[0])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_FF, CLK_POLARITY=1'b1, D_POLARITY=1'b1, CE_POLARITY=1'b1, SR_SYNC=1'b1, SR_SYNC_PRIORITY=1'b1, SR_VALUE=1'b0, SR_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(105)
    defparam \out_y[0]~FF .CLK_POLARITY = 1'b1;
    defparam \out_y[0]~FF .CE_POLARITY = 1'b1;
    defparam \out_y[0]~FF .SR_POLARITY = 1'b1;
    defparam \out_y[0]~FF .D_POLARITY = 1'b1;
    defparam \out_y[0]~FF .SR_SYNC = 1'b1;
    defparam \out_y[0]~FF .SR_VALUE = 1'b0;
    defparam \out_y[0]~FF .SR_SYNC_PRIORITY = 1'b1;
    EFX_FF \snapshot.error[0]~FF  (.D(\next_snapshot.error [0]), .CE(1'b1), 
           .CLK(clk), .SR(rst), .Q(\snapshot.error [0])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_FF, CLK_POLARITY=1'b1, D_POLARITY=1'b1, CE_POLARITY=1'b1, SR_SYNC=1'b1, SR_SYNC_PRIORITY=1'b1, SR_VALUE=1'b0, SR_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(105)
    defparam \snapshot.error[0]~FF .CLK_POLARITY = 1'b1;
    defparam \snapshot.error[0]~FF .CE_POLARITY = 1'b1;
    defparam \snapshot.error[0]~FF .SR_POLARITY = 1'b1;
    defparam \snapshot.error[0]~FF .D_POLARITY = 1'b1;
    defparam \snapshot.error[0]~FF .SR_SYNC = 1'b1;
    defparam \snapshot.error[0]~FF .SR_VALUE = 1'b0;
    defparam \snapshot.error[0]~FF .SR_SYNC_PRIORITY = 1'b1;
    EFX_FF \out_rgb_pair[1]~FF  (.D(n805_3[1]), .CE(1'b1), .CLK(clk), 
           .SR(n1920), .Q(out_rgb_pair[1])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_FF, CLK_POLARITY=1'b1, D_POLARITY=1'b1, CE_POLARITY=1'b1, SR_SYNC=1'b1, SR_SYNC_PRIORITY=1'b1, SR_VALUE=1'b0, SR_POLARITY=1'b0 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(105)
    defparam \out_rgb_pair[1]~FF .CLK_POLARITY = 1'b1;
    defparam \out_rgb_pair[1]~FF .CE_POLARITY = 1'b1;
    defparam \out_rgb_pair[1]~FF .SR_POLARITY = 1'b0;
    defparam \out_rgb_pair[1]~FF .D_POLARITY = 1'b1;
    defparam \out_rgb_pair[1]~FF .SR_SYNC = 1'b1;
    defparam \out_rgb_pair[1]~FF .SR_VALUE = 1'b0;
    defparam \out_rgb_pair[1]~FF .SR_SYNC_PRIORITY = 1'b1;
    EFX_FF \out_rgb_pair[2]~FF  (.D(n805_4[2]), .CE(1'b1), .CLK(clk), 
           .SR(n1920), .Q(out_rgb_pair[2])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_FF, CLK_POLARITY=1'b1, D_POLARITY=1'b1, CE_POLARITY=1'b1, SR_SYNC=1'b1, SR_SYNC_PRIORITY=1'b1, SR_VALUE=1'b0, SR_POLARITY=1'b0 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(105)
    defparam \out_rgb_pair[2]~FF .CLK_POLARITY = 1'b1;
    defparam \out_rgb_pair[2]~FF .CE_POLARITY = 1'b1;
    defparam \out_rgb_pair[2]~FF .SR_POLARITY = 1'b0;
    defparam \out_rgb_pair[2]~FF .D_POLARITY = 1'b1;
    defparam \out_rgb_pair[2]~FF .SR_SYNC = 1'b1;
    defparam \out_rgb_pair[2]~FF .SR_VALUE = 1'b0;
    defparam \out_rgb_pair[2]~FF .SR_SYNC_PRIORITY = 1'b1;
    EFX_FF \out_rgb_pair[3]~FF  (.D(n805_5[3]), .CE(1'b1), .CLK(clk), 
           .SR(n1920), .Q(out_rgb_pair[3])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_FF, CLK_POLARITY=1'b1, D_POLARITY=1'b1, CE_POLARITY=1'b1, SR_SYNC=1'b1, SR_SYNC_PRIORITY=1'b1, SR_VALUE=1'b0, SR_POLARITY=1'b0 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(105)
    defparam \out_rgb_pair[3]~FF .CLK_POLARITY = 1'b1;
    defparam \out_rgb_pair[3]~FF .CE_POLARITY = 1'b1;
    defparam \out_rgb_pair[3]~FF .SR_POLARITY = 1'b0;
    defparam \out_rgb_pair[3]~FF .D_POLARITY = 1'b1;
    defparam \out_rgb_pair[3]~FF .SR_SYNC = 1'b1;
    defparam \out_rgb_pair[3]~FF .SR_VALUE = 1'b0;
    defparam \out_rgb_pair[3]~FF .SR_SYNC_PRIORITY = 1'b1;
    EFX_FF \out_rgb_pair[4]~FF  (.D(n805_6[4]), .CE(1'b1), .CLK(clk), 
           .SR(n1920), .Q(out_rgb_pair[4])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_FF, CLK_POLARITY=1'b1, D_POLARITY=1'b1, CE_POLARITY=1'b1, SR_SYNC=1'b1, SR_SYNC_PRIORITY=1'b1, SR_VALUE=1'b0, SR_POLARITY=1'b0 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(105)
    defparam \out_rgb_pair[4]~FF .CLK_POLARITY = 1'b1;
    defparam \out_rgb_pair[4]~FF .CE_POLARITY = 1'b1;
    defparam \out_rgb_pair[4]~FF .SR_POLARITY = 1'b0;
    defparam \out_rgb_pair[4]~FF .D_POLARITY = 1'b1;
    defparam \out_rgb_pair[4]~FF .SR_SYNC = 1'b1;
    defparam \out_rgb_pair[4]~FF .SR_VALUE = 1'b0;
    defparam \out_rgb_pair[4]~FF .SR_SYNC_PRIORITY = 1'b1;
    EFX_FF \out_rgb_pair[5]~FF  (.D(n805_7[5]), .CE(1'b1), .CLK(clk), 
           .SR(n1920), .Q(out_rgb_pair[5])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_FF, CLK_POLARITY=1'b1, D_POLARITY=1'b1, CE_POLARITY=1'b1, SR_SYNC=1'b1, SR_SYNC_PRIORITY=1'b1, SR_VALUE=1'b0, SR_POLARITY=1'b0 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(105)
    defparam \out_rgb_pair[5]~FF .CLK_POLARITY = 1'b1;
    defparam \out_rgb_pair[5]~FF .CE_POLARITY = 1'b1;
    defparam \out_rgb_pair[5]~FF .SR_POLARITY = 1'b0;
    defparam \out_rgb_pair[5]~FF .D_POLARITY = 1'b1;
    defparam \out_rgb_pair[5]~FF .SR_SYNC = 1'b1;
    defparam \out_rgb_pair[5]~FF .SR_VALUE = 1'b0;
    defparam \out_rgb_pair[5]~FF .SR_SYNC_PRIORITY = 1'b1;
    EFX_FF \out_rgb_pair[6]~FF  (.D(n805_8[6]), .CE(1'b1), .CLK(clk), 
           .SR(n1920), .Q(out_rgb_pair[6])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_FF, CLK_POLARITY=1'b1, D_POLARITY=1'b1, CE_POLARITY=1'b1, SR_SYNC=1'b1, SR_SYNC_PRIORITY=1'b1, SR_VALUE=1'b0, SR_POLARITY=1'b0 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(105)
    defparam \out_rgb_pair[6]~FF .CLK_POLARITY = 1'b1;
    defparam \out_rgb_pair[6]~FF .CE_POLARITY = 1'b1;
    defparam \out_rgb_pair[6]~FF .SR_POLARITY = 1'b0;
    defparam \out_rgb_pair[6]~FF .D_POLARITY = 1'b1;
    defparam \out_rgb_pair[6]~FF .SR_SYNC = 1'b1;
    defparam \out_rgb_pair[6]~FF .SR_VALUE = 1'b0;
    defparam \out_rgb_pair[6]~FF .SR_SYNC_PRIORITY = 1'b1;
    EFX_FF \out_rgb_pair[7]~FF  (.D(n805_9[7]), .CE(1'b1), .CLK(clk), 
           .SR(n1920), .Q(out_rgb_pair[7])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_FF, CLK_POLARITY=1'b1, D_POLARITY=1'b1, CE_POLARITY=1'b1, SR_SYNC=1'b1, SR_SYNC_PRIORITY=1'b1, SR_VALUE=1'b0, SR_POLARITY=1'b0 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(105)
    defparam \out_rgb_pair[7]~FF .CLK_POLARITY = 1'b1;
    defparam \out_rgb_pair[7]~FF .CE_POLARITY = 1'b1;
    defparam \out_rgb_pair[7]~FF .SR_POLARITY = 1'b0;
    defparam \out_rgb_pair[7]~FF .D_POLARITY = 1'b1;
    defparam \out_rgb_pair[7]~FF .SR_SYNC = 1'b1;
    defparam \out_rgb_pair[7]~FF .SR_VALUE = 1'b0;
    defparam \out_rgb_pair[7]~FF .SR_SYNC_PRIORITY = 1'b1;
    EFX_FF \out_rgb_pair[8]~FF  (.D(n805_10[8]), .CE(1'b1), .CLK(clk), 
           .SR(n1920), .Q(out_rgb_pair[8])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_FF, CLK_POLARITY=1'b1, D_POLARITY=1'b1, CE_POLARITY=1'b1, SR_SYNC=1'b1, SR_SYNC_PRIORITY=1'b1, SR_VALUE=1'b0, SR_POLARITY=1'b0 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(105)
    defparam \out_rgb_pair[8]~FF .CLK_POLARITY = 1'b1;
    defparam \out_rgb_pair[8]~FF .CE_POLARITY = 1'b1;
    defparam \out_rgb_pair[8]~FF .SR_POLARITY = 1'b0;
    defparam \out_rgb_pair[8]~FF .D_POLARITY = 1'b1;
    defparam \out_rgb_pair[8]~FF .SR_SYNC = 1'b1;
    defparam \out_rgb_pair[8]~FF .SR_VALUE = 1'b0;
    defparam \out_rgb_pair[8]~FF .SR_SYNC_PRIORITY = 1'b1;
    EFX_FF \out_rgb_pair[9]~FF  (.D(n805_11[9]), .CE(1'b1), .CLK(clk), 
           .SR(n1920), .Q(out_rgb_pair[9])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_FF, CLK_POLARITY=1'b1, D_POLARITY=1'b1, CE_POLARITY=1'b1, SR_SYNC=1'b1, SR_SYNC_PRIORITY=1'b1, SR_VALUE=1'b0, SR_POLARITY=1'b0 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(105)
    defparam \out_rgb_pair[9]~FF .CLK_POLARITY = 1'b1;
    defparam \out_rgb_pair[9]~FF .CE_POLARITY = 1'b1;
    defparam \out_rgb_pair[9]~FF .SR_POLARITY = 1'b0;
    defparam \out_rgb_pair[9]~FF .D_POLARITY = 1'b1;
    defparam \out_rgb_pair[9]~FF .SR_SYNC = 1'b1;
    defparam \out_rgb_pair[9]~FF .SR_VALUE = 1'b0;
    defparam \out_rgb_pair[9]~FF .SR_SYNC_PRIORITY = 1'b1;
    EFX_FF \out_rgb_pair[10]~FF  (.D(n805_12[10]), .CE(1'b1), .CLK(clk), 
           .SR(n1920), .Q(out_rgb_pair[10])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_FF, CLK_POLARITY=1'b1, D_POLARITY=1'b1, CE_POLARITY=1'b1, SR_SYNC=1'b1, SR_SYNC_PRIORITY=1'b1, SR_VALUE=1'b0, SR_POLARITY=1'b0 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(105)
    defparam \out_rgb_pair[10]~FF .CLK_POLARITY = 1'b1;
    defparam \out_rgb_pair[10]~FF .CE_POLARITY = 1'b1;
    defparam \out_rgb_pair[10]~FF .SR_POLARITY = 1'b0;
    defparam \out_rgb_pair[10]~FF .D_POLARITY = 1'b1;
    defparam \out_rgb_pair[10]~FF .SR_SYNC = 1'b1;
    defparam \out_rgb_pair[10]~FF .SR_VALUE = 1'b0;
    defparam \out_rgb_pair[10]~FF .SR_SYNC_PRIORITY = 1'b1;
    EFX_FF \out_rgb_pair[11]~FF  (.D(n805_13[11]), .CE(1'b1), .CLK(clk), 
           .SR(n1920), .Q(out_rgb_pair[11])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_FF, CLK_POLARITY=1'b1, D_POLARITY=1'b1, CE_POLARITY=1'b1, SR_SYNC=1'b1, SR_SYNC_PRIORITY=1'b1, SR_VALUE=1'b0, SR_POLARITY=1'b0 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(105)
    defparam \out_rgb_pair[11]~FF .CLK_POLARITY = 1'b1;
    defparam \out_rgb_pair[11]~FF .CE_POLARITY = 1'b1;
    defparam \out_rgb_pair[11]~FF .SR_POLARITY = 1'b0;
    defparam \out_rgb_pair[11]~FF .D_POLARITY = 1'b1;
    defparam \out_rgb_pair[11]~FF .SR_SYNC = 1'b1;
    defparam \out_rgb_pair[11]~FF .SR_VALUE = 1'b0;
    defparam \out_rgb_pair[11]~FF .SR_SYNC_PRIORITY = 1'b1;
    EFX_FF \out_rgb_pair[12]~FF  (.D(n805_14[12]), .CE(1'b1), .CLK(clk), 
           .SR(n1920), .Q(out_rgb_pair[12])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_FF, CLK_POLARITY=1'b1, D_POLARITY=1'b1, CE_POLARITY=1'b1, SR_SYNC=1'b1, SR_SYNC_PRIORITY=1'b1, SR_VALUE=1'b0, SR_POLARITY=1'b0 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(105)
    defparam \out_rgb_pair[12]~FF .CLK_POLARITY = 1'b1;
    defparam \out_rgb_pair[12]~FF .CE_POLARITY = 1'b1;
    defparam \out_rgb_pair[12]~FF .SR_POLARITY = 1'b0;
    defparam \out_rgb_pair[12]~FF .D_POLARITY = 1'b1;
    defparam \out_rgb_pair[12]~FF .SR_SYNC = 1'b1;
    defparam \out_rgb_pair[12]~FF .SR_VALUE = 1'b0;
    defparam \out_rgb_pair[12]~FF .SR_SYNC_PRIORITY = 1'b1;
    EFX_FF \out_rgb_pair[13]~FF  (.D(n805_15[13]), .CE(1'b1), .CLK(clk), 
           .SR(n1920), .Q(out_rgb_pair[13])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_FF, CLK_POLARITY=1'b1, D_POLARITY=1'b1, CE_POLARITY=1'b1, SR_SYNC=1'b1, SR_SYNC_PRIORITY=1'b1, SR_VALUE=1'b0, SR_POLARITY=1'b0 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(105)
    defparam \out_rgb_pair[13]~FF .CLK_POLARITY = 1'b1;
    defparam \out_rgb_pair[13]~FF .CE_POLARITY = 1'b1;
    defparam \out_rgb_pair[13]~FF .SR_POLARITY = 1'b0;
    defparam \out_rgb_pair[13]~FF .D_POLARITY = 1'b1;
    defparam \out_rgb_pair[13]~FF .SR_SYNC = 1'b1;
    defparam \out_rgb_pair[13]~FF .SR_VALUE = 1'b0;
    defparam \out_rgb_pair[13]~FF .SR_SYNC_PRIORITY = 1'b1;
    EFX_FF \out_rgb_pair[14]~FF  (.D(n805_16[14]), .CE(1'b1), .CLK(clk), 
           .SR(n1920), .Q(out_rgb_pair[14])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_FF, CLK_POLARITY=1'b1, D_POLARITY=1'b1, CE_POLARITY=1'b1, SR_SYNC=1'b1, SR_SYNC_PRIORITY=1'b1, SR_VALUE=1'b0, SR_POLARITY=1'b0 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(105)
    defparam \out_rgb_pair[14]~FF .CLK_POLARITY = 1'b1;
    defparam \out_rgb_pair[14]~FF .CE_POLARITY = 1'b1;
    defparam \out_rgb_pair[14]~FF .SR_POLARITY = 1'b0;
    defparam \out_rgb_pair[14]~FF .D_POLARITY = 1'b1;
    defparam \out_rgb_pair[14]~FF .SR_SYNC = 1'b1;
    defparam \out_rgb_pair[14]~FF .SR_VALUE = 1'b0;
    defparam \out_rgb_pair[14]~FF .SR_SYNC_PRIORITY = 1'b1;
    EFX_FF \out_rgb_pair[15]~FF  (.D(n805_17[15]), .CE(1'b1), .CLK(clk), 
           .SR(n1920), .Q(out_rgb_pair[15])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_FF, CLK_POLARITY=1'b1, D_POLARITY=1'b1, CE_POLARITY=1'b1, SR_SYNC=1'b1, SR_SYNC_PRIORITY=1'b1, SR_VALUE=1'b0, SR_POLARITY=1'b0 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(105)
    defparam \out_rgb_pair[15]~FF .CLK_POLARITY = 1'b1;
    defparam \out_rgb_pair[15]~FF .CE_POLARITY = 1'b1;
    defparam \out_rgb_pair[15]~FF .SR_POLARITY = 1'b0;
    defparam \out_rgb_pair[15]~FF .D_POLARITY = 1'b1;
    defparam \out_rgb_pair[15]~FF .SR_SYNC = 1'b1;
    defparam \out_rgb_pair[15]~FF .SR_VALUE = 1'b0;
    defparam \out_rgb_pair[15]~FF .SR_SYNC_PRIORITY = 1'b1;
    EFX_FF \out_rgb_pair[16]~FF  (.D(n805_18[16]), .CE(1'b1), .CLK(clk), 
           .SR(n1920), .Q(out_rgb_pair[16])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_FF, CLK_POLARITY=1'b1, D_POLARITY=1'b1, CE_POLARITY=1'b1, SR_SYNC=1'b1, SR_SYNC_PRIORITY=1'b1, SR_VALUE=1'b0, SR_POLARITY=1'b0 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(105)
    defparam \out_rgb_pair[16]~FF .CLK_POLARITY = 1'b1;
    defparam \out_rgb_pair[16]~FF .CE_POLARITY = 1'b1;
    defparam \out_rgb_pair[16]~FF .SR_POLARITY = 1'b0;
    defparam \out_rgb_pair[16]~FF .D_POLARITY = 1'b1;
    defparam \out_rgb_pair[16]~FF .SR_SYNC = 1'b1;
    defparam \out_rgb_pair[16]~FF .SR_VALUE = 1'b0;
    defparam \out_rgb_pair[16]~FF .SR_SYNC_PRIORITY = 1'b1;
    EFX_FF \out_rgb_pair[17]~FF  (.D(n805_19[17]), .CE(1'b1), .CLK(clk), 
           .SR(n1920), .Q(out_rgb_pair[17])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_FF, CLK_POLARITY=1'b1, D_POLARITY=1'b1, CE_POLARITY=1'b1, SR_SYNC=1'b1, SR_SYNC_PRIORITY=1'b1, SR_VALUE=1'b0, SR_POLARITY=1'b0 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(105)
    defparam \out_rgb_pair[17]~FF .CLK_POLARITY = 1'b1;
    defparam \out_rgb_pair[17]~FF .CE_POLARITY = 1'b1;
    defparam \out_rgb_pair[17]~FF .SR_POLARITY = 1'b0;
    defparam \out_rgb_pair[17]~FF .D_POLARITY = 1'b1;
    defparam \out_rgb_pair[17]~FF .SR_SYNC = 1'b1;
    defparam \out_rgb_pair[17]~FF .SR_VALUE = 1'b0;
    defparam \out_rgb_pair[17]~FF .SR_SYNC_PRIORITY = 1'b1;
    EFX_FF \out_rgb_pair[18]~FF  (.D(n805_20[18]), .CE(1'b1), .CLK(clk), 
           .SR(n1920), .Q(out_rgb_pair[18])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_FF, CLK_POLARITY=1'b1, D_POLARITY=1'b1, CE_POLARITY=1'b1, SR_SYNC=1'b1, SR_SYNC_PRIORITY=1'b1, SR_VALUE=1'b0, SR_POLARITY=1'b0 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(105)
    defparam \out_rgb_pair[18]~FF .CLK_POLARITY = 1'b1;
    defparam \out_rgb_pair[18]~FF .CE_POLARITY = 1'b1;
    defparam \out_rgb_pair[18]~FF .SR_POLARITY = 1'b0;
    defparam \out_rgb_pair[18]~FF .D_POLARITY = 1'b1;
    defparam \out_rgb_pair[18]~FF .SR_SYNC = 1'b1;
    defparam \out_rgb_pair[18]~FF .SR_VALUE = 1'b0;
    defparam \out_rgb_pair[18]~FF .SR_SYNC_PRIORITY = 1'b1;
    EFX_FF \out_rgb_pair[19]~FF  (.D(n805_21[19]), .CE(1'b1), .CLK(clk), 
           .SR(n1920), .Q(out_rgb_pair[19])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_FF, CLK_POLARITY=1'b1, D_POLARITY=1'b1, CE_POLARITY=1'b1, SR_SYNC=1'b1, SR_SYNC_PRIORITY=1'b1, SR_VALUE=1'b0, SR_POLARITY=1'b0 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(105)
    defparam \out_rgb_pair[19]~FF .CLK_POLARITY = 1'b1;
    defparam \out_rgb_pair[19]~FF .CE_POLARITY = 1'b1;
    defparam \out_rgb_pair[19]~FF .SR_POLARITY = 1'b0;
    defparam \out_rgb_pair[19]~FF .D_POLARITY = 1'b1;
    defparam \out_rgb_pair[19]~FF .SR_SYNC = 1'b1;
    defparam \out_rgb_pair[19]~FF .SR_VALUE = 1'b0;
    defparam \out_rgb_pair[19]~FF .SR_SYNC_PRIORITY = 1'b1;
    EFX_FF \out_rgb_pair[20]~FF  (.D(n805_22[20]), .CE(1'b1), .CLK(clk), 
           .SR(n1920), .Q(out_rgb_pair[20])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_FF, CLK_POLARITY=1'b1, D_POLARITY=1'b1, CE_POLARITY=1'b1, SR_SYNC=1'b1, SR_SYNC_PRIORITY=1'b1, SR_VALUE=1'b0, SR_POLARITY=1'b0 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(105)
    defparam \out_rgb_pair[20]~FF .CLK_POLARITY = 1'b1;
    defparam \out_rgb_pair[20]~FF .CE_POLARITY = 1'b1;
    defparam \out_rgb_pair[20]~FF .SR_POLARITY = 1'b0;
    defparam \out_rgb_pair[20]~FF .D_POLARITY = 1'b1;
    defparam \out_rgb_pair[20]~FF .SR_SYNC = 1'b1;
    defparam \out_rgb_pair[20]~FF .SR_VALUE = 1'b0;
    defparam \out_rgb_pair[20]~FF .SR_SYNC_PRIORITY = 1'b1;
    EFX_FF \out_rgb_pair[21]~FF  (.D(n805_23[21]), .CE(1'b1), .CLK(clk), 
           .SR(n1920), .Q(out_rgb_pair[21])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_FF, CLK_POLARITY=1'b1, D_POLARITY=1'b1, CE_POLARITY=1'b1, SR_SYNC=1'b1, SR_SYNC_PRIORITY=1'b1, SR_VALUE=1'b0, SR_POLARITY=1'b0 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(105)
    defparam \out_rgb_pair[21]~FF .CLK_POLARITY = 1'b1;
    defparam \out_rgb_pair[21]~FF .CE_POLARITY = 1'b1;
    defparam \out_rgb_pair[21]~FF .SR_POLARITY = 1'b0;
    defparam \out_rgb_pair[21]~FF .D_POLARITY = 1'b1;
    defparam \out_rgb_pair[21]~FF .SR_SYNC = 1'b1;
    defparam \out_rgb_pair[21]~FF .SR_VALUE = 1'b0;
    defparam \out_rgb_pair[21]~FF .SR_SYNC_PRIORITY = 1'b1;
    EFX_FF \out_rgb_pair[22]~FF  (.D(n805_24[22]), .CE(1'b1), .CLK(clk), 
           .SR(n1920), .Q(out_rgb_pair[22])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_FF, CLK_POLARITY=1'b1, D_POLARITY=1'b1, CE_POLARITY=1'b1, SR_SYNC=1'b1, SR_SYNC_PRIORITY=1'b1, SR_VALUE=1'b0, SR_POLARITY=1'b0 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(105)
    defparam \out_rgb_pair[22]~FF .CLK_POLARITY = 1'b1;
    defparam \out_rgb_pair[22]~FF .CE_POLARITY = 1'b1;
    defparam \out_rgb_pair[22]~FF .SR_POLARITY = 1'b0;
    defparam \out_rgb_pair[22]~FF .D_POLARITY = 1'b1;
    defparam \out_rgb_pair[22]~FF .SR_SYNC = 1'b1;
    defparam \out_rgb_pair[22]~FF .SR_VALUE = 1'b0;
    defparam \out_rgb_pair[22]~FF .SR_SYNC_PRIORITY = 1'b1;
    EFX_FF \out_rgb_pair[23]~FF  (.D(n805_25[23]), .CE(1'b1), .CLK(clk), 
           .SR(n1920), .Q(out_rgb_pair[23])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_FF, CLK_POLARITY=1'b1, D_POLARITY=1'b1, CE_POLARITY=1'b1, SR_SYNC=1'b1, SR_SYNC_PRIORITY=1'b1, SR_VALUE=1'b0, SR_POLARITY=1'b0 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(105)
    defparam \out_rgb_pair[23]~FF .CLK_POLARITY = 1'b1;
    defparam \out_rgb_pair[23]~FF .CE_POLARITY = 1'b1;
    defparam \out_rgb_pair[23]~FF .SR_POLARITY = 1'b0;
    defparam \out_rgb_pair[23]~FF .D_POLARITY = 1'b1;
    defparam \out_rgb_pair[23]~FF .SR_SYNC = 1'b1;
    defparam \out_rgb_pair[23]~FF .SR_VALUE = 1'b0;
    defparam \out_rgb_pair[23]~FF .SR_SYNC_PRIORITY = 1'b1;
    EFX_FF \out_rgb_pair[24]~FF  (.D(n574_2[0]), .CE(1'b1), .CLK(clk), 
           .SR(n1920), .Q(out_rgb_pair[24])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_FF, CLK_POLARITY=1'b1, D_POLARITY=1'b1, CE_POLARITY=1'b1, SR_SYNC=1'b1, SR_SYNC_PRIORITY=1'b1, SR_VALUE=1'b0, SR_POLARITY=1'b0 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(105)
    defparam \out_rgb_pair[24]~FF .CLK_POLARITY = 1'b1;
    defparam \out_rgb_pair[24]~FF .CE_POLARITY = 1'b1;
    defparam \out_rgb_pair[24]~FF .SR_POLARITY = 1'b0;
    defparam \out_rgb_pair[24]~FF .D_POLARITY = 1'b1;
    defparam \out_rgb_pair[24]~FF .SR_SYNC = 1'b1;
    defparam \out_rgb_pair[24]~FF .SR_VALUE = 1'b0;
    defparam \out_rgb_pair[24]~FF .SR_SYNC_PRIORITY = 1'b1;
    EFX_FF \out_rgb_pair[25]~FF  (.D(n574_3[1]), .CE(1'b1), .CLK(clk), 
           .SR(n1920), .Q(out_rgb_pair[25])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_FF, CLK_POLARITY=1'b1, D_POLARITY=1'b1, CE_POLARITY=1'b1, SR_SYNC=1'b1, SR_SYNC_PRIORITY=1'b1, SR_VALUE=1'b0, SR_POLARITY=1'b0 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(105)
    defparam \out_rgb_pair[25]~FF .CLK_POLARITY = 1'b1;
    defparam \out_rgb_pair[25]~FF .CE_POLARITY = 1'b1;
    defparam \out_rgb_pair[25]~FF .SR_POLARITY = 1'b0;
    defparam \out_rgb_pair[25]~FF .D_POLARITY = 1'b1;
    defparam \out_rgb_pair[25]~FF .SR_SYNC = 1'b1;
    defparam \out_rgb_pair[25]~FF .SR_VALUE = 1'b0;
    defparam \out_rgb_pair[25]~FF .SR_SYNC_PRIORITY = 1'b1;
    EFX_FF \out_rgb_pair[26]~FF  (.D(n574_4[2]), .CE(1'b1), .CLK(clk), 
           .SR(n1920), .Q(out_rgb_pair[26])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_FF, CLK_POLARITY=1'b1, D_POLARITY=1'b1, CE_POLARITY=1'b1, SR_SYNC=1'b1, SR_SYNC_PRIORITY=1'b1, SR_VALUE=1'b0, SR_POLARITY=1'b0 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(105)
    defparam \out_rgb_pair[26]~FF .CLK_POLARITY = 1'b1;
    defparam \out_rgb_pair[26]~FF .CE_POLARITY = 1'b1;
    defparam \out_rgb_pair[26]~FF .SR_POLARITY = 1'b0;
    defparam \out_rgb_pair[26]~FF .D_POLARITY = 1'b1;
    defparam \out_rgb_pair[26]~FF .SR_SYNC = 1'b1;
    defparam \out_rgb_pair[26]~FF .SR_VALUE = 1'b0;
    defparam \out_rgb_pair[26]~FF .SR_SYNC_PRIORITY = 1'b1;
    EFX_FF \out_rgb_pair[27]~FF  (.D(n574_5[3]), .CE(1'b1), .CLK(clk), 
           .SR(n1920), .Q(out_rgb_pair[27])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_FF, CLK_POLARITY=1'b1, D_POLARITY=1'b1, CE_POLARITY=1'b1, SR_SYNC=1'b1, SR_SYNC_PRIORITY=1'b1, SR_VALUE=1'b0, SR_POLARITY=1'b0 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(105)
    defparam \out_rgb_pair[27]~FF .CLK_POLARITY = 1'b1;
    defparam \out_rgb_pair[27]~FF .CE_POLARITY = 1'b1;
    defparam \out_rgb_pair[27]~FF .SR_POLARITY = 1'b0;
    defparam \out_rgb_pair[27]~FF .D_POLARITY = 1'b1;
    defparam \out_rgb_pair[27]~FF .SR_SYNC = 1'b1;
    defparam \out_rgb_pair[27]~FF .SR_VALUE = 1'b0;
    defparam \out_rgb_pair[27]~FF .SR_SYNC_PRIORITY = 1'b1;
    EFX_FF \out_rgb_pair[28]~FF  (.D(n574_6[4]), .CE(1'b1), .CLK(clk), 
           .SR(n1920), .Q(out_rgb_pair[28])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_FF, CLK_POLARITY=1'b1, D_POLARITY=1'b1, CE_POLARITY=1'b1, SR_SYNC=1'b1, SR_SYNC_PRIORITY=1'b1, SR_VALUE=1'b0, SR_POLARITY=1'b0 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(105)
    defparam \out_rgb_pair[28]~FF .CLK_POLARITY = 1'b1;
    defparam \out_rgb_pair[28]~FF .CE_POLARITY = 1'b1;
    defparam \out_rgb_pair[28]~FF .SR_POLARITY = 1'b0;
    defparam \out_rgb_pair[28]~FF .D_POLARITY = 1'b1;
    defparam \out_rgb_pair[28]~FF .SR_SYNC = 1'b1;
    defparam \out_rgb_pair[28]~FF .SR_VALUE = 1'b0;
    defparam \out_rgb_pair[28]~FF .SR_SYNC_PRIORITY = 1'b1;
    EFX_FF \out_rgb_pair[29]~FF  (.D(n574_7[5]), .CE(1'b1), .CLK(clk), 
           .SR(n1920), .Q(out_rgb_pair[29])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_FF, CLK_POLARITY=1'b1, D_POLARITY=1'b1, CE_POLARITY=1'b1, SR_SYNC=1'b1, SR_SYNC_PRIORITY=1'b1, SR_VALUE=1'b0, SR_POLARITY=1'b0 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(105)
    defparam \out_rgb_pair[29]~FF .CLK_POLARITY = 1'b1;
    defparam \out_rgb_pair[29]~FF .CE_POLARITY = 1'b1;
    defparam \out_rgb_pair[29]~FF .SR_POLARITY = 1'b0;
    defparam \out_rgb_pair[29]~FF .D_POLARITY = 1'b1;
    defparam \out_rgb_pair[29]~FF .SR_SYNC = 1'b1;
    defparam \out_rgb_pair[29]~FF .SR_VALUE = 1'b0;
    defparam \out_rgb_pair[29]~FF .SR_SYNC_PRIORITY = 1'b1;
    EFX_FF \out_rgb_pair[30]~FF  (.D(n574_8[6]), .CE(1'b1), .CLK(clk), 
           .SR(n1920), .Q(out_rgb_pair[30])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_FF, CLK_POLARITY=1'b1, D_POLARITY=1'b1, CE_POLARITY=1'b1, SR_SYNC=1'b1, SR_SYNC_PRIORITY=1'b1, SR_VALUE=1'b0, SR_POLARITY=1'b0 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(105)
    defparam \out_rgb_pair[30]~FF .CLK_POLARITY = 1'b1;
    defparam \out_rgb_pair[30]~FF .CE_POLARITY = 1'b1;
    defparam \out_rgb_pair[30]~FF .SR_POLARITY = 1'b0;
    defparam \out_rgb_pair[30]~FF .D_POLARITY = 1'b1;
    defparam \out_rgb_pair[30]~FF .SR_SYNC = 1'b1;
    defparam \out_rgb_pair[30]~FF .SR_VALUE = 1'b0;
    defparam \out_rgb_pair[30]~FF .SR_SYNC_PRIORITY = 1'b1;
    EFX_FF \out_rgb_pair[31]~FF  (.D(n574_9[7]), .CE(1'b1), .CLK(clk), 
           .SR(n1920), .Q(out_rgb_pair[31])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_FF, CLK_POLARITY=1'b1, D_POLARITY=1'b1, CE_POLARITY=1'b1, SR_SYNC=1'b1, SR_SYNC_PRIORITY=1'b1, SR_VALUE=1'b0, SR_POLARITY=1'b0 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(105)
    defparam \out_rgb_pair[31]~FF .CLK_POLARITY = 1'b1;
    defparam \out_rgb_pair[31]~FF .CE_POLARITY = 1'b1;
    defparam \out_rgb_pair[31]~FF .SR_POLARITY = 1'b0;
    defparam \out_rgb_pair[31]~FF .D_POLARITY = 1'b1;
    defparam \out_rgb_pair[31]~FF .SR_SYNC = 1'b1;
    defparam \out_rgb_pair[31]~FF .SR_VALUE = 1'b0;
    defparam \out_rgb_pair[31]~FF .SR_SYNC_PRIORITY = 1'b1;
    EFX_FF \out_rgb_pair[32]~FF  (.D(n574_10[8]), .CE(1'b1), .CLK(clk), 
           .SR(n1920), .Q(out_rgb_pair[32])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_FF, CLK_POLARITY=1'b1, D_POLARITY=1'b1, CE_POLARITY=1'b1, SR_SYNC=1'b1, SR_SYNC_PRIORITY=1'b1, SR_VALUE=1'b0, SR_POLARITY=1'b0 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(105)
    defparam \out_rgb_pair[32]~FF .CLK_POLARITY = 1'b1;
    defparam \out_rgb_pair[32]~FF .CE_POLARITY = 1'b1;
    defparam \out_rgb_pair[32]~FF .SR_POLARITY = 1'b0;
    defparam \out_rgb_pair[32]~FF .D_POLARITY = 1'b1;
    defparam \out_rgb_pair[32]~FF .SR_SYNC = 1'b1;
    defparam \out_rgb_pair[32]~FF .SR_VALUE = 1'b0;
    defparam \out_rgb_pair[32]~FF .SR_SYNC_PRIORITY = 1'b1;
    EFX_FF \out_rgb_pair[33]~FF  (.D(n574_11[9]), .CE(1'b1), .CLK(clk), 
           .SR(n1920), .Q(out_rgb_pair[33])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_FF, CLK_POLARITY=1'b1, D_POLARITY=1'b1, CE_POLARITY=1'b1, SR_SYNC=1'b1, SR_SYNC_PRIORITY=1'b1, SR_VALUE=1'b0, SR_POLARITY=1'b0 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(105)
    defparam \out_rgb_pair[33]~FF .CLK_POLARITY = 1'b1;
    defparam \out_rgb_pair[33]~FF .CE_POLARITY = 1'b1;
    defparam \out_rgb_pair[33]~FF .SR_POLARITY = 1'b0;
    defparam \out_rgb_pair[33]~FF .D_POLARITY = 1'b1;
    defparam \out_rgb_pair[33]~FF .SR_SYNC = 1'b1;
    defparam \out_rgb_pair[33]~FF .SR_VALUE = 1'b0;
    defparam \out_rgb_pair[33]~FF .SR_SYNC_PRIORITY = 1'b1;
    EFX_FF \out_rgb_pair[34]~FF  (.D(n574_12[10]), .CE(1'b1), .CLK(clk), 
           .SR(n1920), .Q(out_rgb_pair[34])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_FF, CLK_POLARITY=1'b1, D_POLARITY=1'b1, CE_POLARITY=1'b1, SR_SYNC=1'b1, SR_SYNC_PRIORITY=1'b1, SR_VALUE=1'b0, SR_POLARITY=1'b0 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(105)
    defparam \out_rgb_pair[34]~FF .CLK_POLARITY = 1'b1;
    defparam \out_rgb_pair[34]~FF .CE_POLARITY = 1'b1;
    defparam \out_rgb_pair[34]~FF .SR_POLARITY = 1'b0;
    defparam \out_rgb_pair[34]~FF .D_POLARITY = 1'b1;
    defparam \out_rgb_pair[34]~FF .SR_SYNC = 1'b1;
    defparam \out_rgb_pair[34]~FF .SR_VALUE = 1'b0;
    defparam \out_rgb_pair[34]~FF .SR_SYNC_PRIORITY = 1'b1;
    EFX_FF \out_rgb_pair[35]~FF  (.D(n574_13[11]), .CE(1'b1), .CLK(clk), 
           .SR(n1920), .Q(out_rgb_pair[35])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_FF, CLK_POLARITY=1'b1, D_POLARITY=1'b1, CE_POLARITY=1'b1, SR_SYNC=1'b1, SR_SYNC_PRIORITY=1'b1, SR_VALUE=1'b0, SR_POLARITY=1'b0 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(105)
    defparam \out_rgb_pair[35]~FF .CLK_POLARITY = 1'b1;
    defparam \out_rgb_pair[35]~FF .CE_POLARITY = 1'b1;
    defparam \out_rgb_pair[35]~FF .SR_POLARITY = 1'b0;
    defparam \out_rgb_pair[35]~FF .D_POLARITY = 1'b1;
    defparam \out_rgb_pair[35]~FF .SR_SYNC = 1'b1;
    defparam \out_rgb_pair[35]~FF .SR_VALUE = 1'b0;
    defparam \out_rgb_pair[35]~FF .SR_SYNC_PRIORITY = 1'b1;
    EFX_FF \out_rgb_pair[36]~FF  (.D(n574_14[12]), .CE(1'b1), .CLK(clk), 
           .SR(n1920), .Q(out_rgb_pair[36])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_FF, CLK_POLARITY=1'b1, D_POLARITY=1'b1, CE_POLARITY=1'b1, SR_SYNC=1'b1, SR_SYNC_PRIORITY=1'b1, SR_VALUE=1'b0, SR_POLARITY=1'b0 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(105)
    defparam \out_rgb_pair[36]~FF .CLK_POLARITY = 1'b1;
    defparam \out_rgb_pair[36]~FF .CE_POLARITY = 1'b1;
    defparam \out_rgb_pair[36]~FF .SR_POLARITY = 1'b0;
    defparam \out_rgb_pair[36]~FF .D_POLARITY = 1'b1;
    defparam \out_rgb_pair[36]~FF .SR_SYNC = 1'b1;
    defparam \out_rgb_pair[36]~FF .SR_VALUE = 1'b0;
    defparam \out_rgb_pair[36]~FF .SR_SYNC_PRIORITY = 1'b1;
    EFX_FF \out_rgb_pair[37]~FF  (.D(n574_15[13]), .CE(1'b1), .CLK(clk), 
           .SR(n1920), .Q(out_rgb_pair[37])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_FF, CLK_POLARITY=1'b1, D_POLARITY=1'b1, CE_POLARITY=1'b1, SR_SYNC=1'b1, SR_SYNC_PRIORITY=1'b1, SR_VALUE=1'b0, SR_POLARITY=1'b0 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(105)
    defparam \out_rgb_pair[37]~FF .CLK_POLARITY = 1'b1;
    defparam \out_rgb_pair[37]~FF .CE_POLARITY = 1'b1;
    defparam \out_rgb_pair[37]~FF .SR_POLARITY = 1'b0;
    defparam \out_rgb_pair[37]~FF .D_POLARITY = 1'b1;
    defparam \out_rgb_pair[37]~FF .SR_SYNC = 1'b1;
    defparam \out_rgb_pair[37]~FF .SR_VALUE = 1'b0;
    defparam \out_rgb_pair[37]~FF .SR_SYNC_PRIORITY = 1'b1;
    EFX_FF \out_rgb_pair[38]~FF  (.D(n574_16[14]), .CE(1'b1), .CLK(clk), 
           .SR(n1920), .Q(out_rgb_pair[38])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_FF, CLK_POLARITY=1'b1, D_POLARITY=1'b1, CE_POLARITY=1'b1, SR_SYNC=1'b1, SR_SYNC_PRIORITY=1'b1, SR_VALUE=1'b0, SR_POLARITY=1'b0 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(105)
    defparam \out_rgb_pair[38]~FF .CLK_POLARITY = 1'b1;
    defparam \out_rgb_pair[38]~FF .CE_POLARITY = 1'b1;
    defparam \out_rgb_pair[38]~FF .SR_POLARITY = 1'b0;
    defparam \out_rgb_pair[38]~FF .D_POLARITY = 1'b1;
    defparam \out_rgb_pair[38]~FF .SR_SYNC = 1'b1;
    defparam \out_rgb_pair[38]~FF .SR_VALUE = 1'b0;
    defparam \out_rgb_pair[38]~FF .SR_SYNC_PRIORITY = 1'b1;
    EFX_FF \out_rgb_pair[39]~FF  (.D(n574_17[15]), .CE(1'b1), .CLK(clk), 
           .SR(n1920), .Q(out_rgb_pair[39])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_FF, CLK_POLARITY=1'b1, D_POLARITY=1'b1, CE_POLARITY=1'b1, SR_SYNC=1'b1, SR_SYNC_PRIORITY=1'b1, SR_VALUE=1'b0, SR_POLARITY=1'b0 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(105)
    defparam \out_rgb_pair[39]~FF .CLK_POLARITY = 1'b1;
    defparam \out_rgb_pair[39]~FF .CE_POLARITY = 1'b1;
    defparam \out_rgb_pair[39]~FF .SR_POLARITY = 1'b0;
    defparam \out_rgb_pair[39]~FF .D_POLARITY = 1'b1;
    defparam \out_rgb_pair[39]~FF .SR_SYNC = 1'b1;
    defparam \out_rgb_pair[39]~FF .SR_VALUE = 1'b0;
    defparam \out_rgb_pair[39]~FF .SR_SYNC_PRIORITY = 1'b1;
    EFX_FF \out_rgb_pair[40]~FF  (.D(n574_18[16]), .CE(1'b1), .CLK(clk), 
           .SR(n1920), .Q(out_rgb_pair[40])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_FF, CLK_POLARITY=1'b1, D_POLARITY=1'b1, CE_POLARITY=1'b1, SR_SYNC=1'b1, SR_SYNC_PRIORITY=1'b1, SR_VALUE=1'b0, SR_POLARITY=1'b0 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(105)
    defparam \out_rgb_pair[40]~FF .CLK_POLARITY = 1'b1;
    defparam \out_rgb_pair[40]~FF .CE_POLARITY = 1'b1;
    defparam \out_rgb_pair[40]~FF .SR_POLARITY = 1'b0;
    defparam \out_rgb_pair[40]~FF .D_POLARITY = 1'b1;
    defparam \out_rgb_pair[40]~FF .SR_SYNC = 1'b1;
    defparam \out_rgb_pair[40]~FF .SR_VALUE = 1'b0;
    defparam \out_rgb_pair[40]~FF .SR_SYNC_PRIORITY = 1'b1;
    EFX_FF \out_rgb_pair[41]~FF  (.D(n574_19[17]), .CE(1'b1), .CLK(clk), 
           .SR(n1920), .Q(out_rgb_pair[41])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_FF, CLK_POLARITY=1'b1, D_POLARITY=1'b1, CE_POLARITY=1'b1, SR_SYNC=1'b1, SR_SYNC_PRIORITY=1'b1, SR_VALUE=1'b0, SR_POLARITY=1'b0 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(105)
    defparam \out_rgb_pair[41]~FF .CLK_POLARITY = 1'b1;
    defparam \out_rgb_pair[41]~FF .CE_POLARITY = 1'b1;
    defparam \out_rgb_pair[41]~FF .SR_POLARITY = 1'b0;
    defparam \out_rgb_pair[41]~FF .D_POLARITY = 1'b1;
    defparam \out_rgb_pair[41]~FF .SR_SYNC = 1'b1;
    defparam \out_rgb_pair[41]~FF .SR_VALUE = 1'b0;
    defparam \out_rgb_pair[41]~FF .SR_SYNC_PRIORITY = 1'b1;
    EFX_FF \out_rgb_pair[42]~FF  (.D(n574_20[18]), .CE(1'b1), .CLK(clk), 
           .SR(n1920), .Q(out_rgb_pair[42])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_FF, CLK_POLARITY=1'b1, D_POLARITY=1'b1, CE_POLARITY=1'b1, SR_SYNC=1'b1, SR_SYNC_PRIORITY=1'b1, SR_VALUE=1'b0, SR_POLARITY=1'b0 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(105)
    defparam \out_rgb_pair[42]~FF .CLK_POLARITY = 1'b1;
    defparam \out_rgb_pair[42]~FF .CE_POLARITY = 1'b1;
    defparam \out_rgb_pair[42]~FF .SR_POLARITY = 1'b0;
    defparam \out_rgb_pair[42]~FF .D_POLARITY = 1'b1;
    defparam \out_rgb_pair[42]~FF .SR_SYNC = 1'b1;
    defparam \out_rgb_pair[42]~FF .SR_VALUE = 1'b0;
    defparam \out_rgb_pair[42]~FF .SR_SYNC_PRIORITY = 1'b1;
    EFX_FF \out_rgb_pair[43]~FF  (.D(n574_21[19]), .CE(1'b1), .CLK(clk), 
           .SR(n1920), .Q(out_rgb_pair[43])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_FF, CLK_POLARITY=1'b1, D_POLARITY=1'b1, CE_POLARITY=1'b1, SR_SYNC=1'b1, SR_SYNC_PRIORITY=1'b1, SR_VALUE=1'b0, SR_POLARITY=1'b0 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(105)
    defparam \out_rgb_pair[43]~FF .CLK_POLARITY = 1'b1;
    defparam \out_rgb_pair[43]~FF .CE_POLARITY = 1'b1;
    defparam \out_rgb_pair[43]~FF .SR_POLARITY = 1'b0;
    defparam \out_rgb_pair[43]~FF .D_POLARITY = 1'b1;
    defparam \out_rgb_pair[43]~FF .SR_SYNC = 1'b1;
    defparam \out_rgb_pair[43]~FF .SR_VALUE = 1'b0;
    defparam \out_rgb_pair[43]~FF .SR_SYNC_PRIORITY = 1'b1;
    EFX_FF \out_rgb_pair[44]~FF  (.D(n574_22[20]), .CE(1'b1), .CLK(clk), 
           .SR(n1920), .Q(out_rgb_pair[44])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_FF, CLK_POLARITY=1'b1, D_POLARITY=1'b1, CE_POLARITY=1'b1, SR_SYNC=1'b1, SR_SYNC_PRIORITY=1'b1, SR_VALUE=1'b0, SR_POLARITY=1'b0 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(105)
    defparam \out_rgb_pair[44]~FF .CLK_POLARITY = 1'b1;
    defparam \out_rgb_pair[44]~FF .CE_POLARITY = 1'b1;
    defparam \out_rgb_pair[44]~FF .SR_POLARITY = 1'b0;
    defparam \out_rgb_pair[44]~FF .D_POLARITY = 1'b1;
    defparam \out_rgb_pair[44]~FF .SR_SYNC = 1'b1;
    defparam \out_rgb_pair[44]~FF .SR_VALUE = 1'b0;
    defparam \out_rgb_pair[44]~FF .SR_SYNC_PRIORITY = 1'b1;
    EFX_FF \out_rgb_pair[45]~FF  (.D(n574_23[21]), .CE(1'b1), .CLK(clk), 
           .SR(n1920), .Q(out_rgb_pair[45])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_FF, CLK_POLARITY=1'b1, D_POLARITY=1'b1, CE_POLARITY=1'b1, SR_SYNC=1'b1, SR_SYNC_PRIORITY=1'b1, SR_VALUE=1'b0, SR_POLARITY=1'b0 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(105)
    defparam \out_rgb_pair[45]~FF .CLK_POLARITY = 1'b1;
    defparam \out_rgb_pair[45]~FF .CE_POLARITY = 1'b1;
    defparam \out_rgb_pair[45]~FF .SR_POLARITY = 1'b0;
    defparam \out_rgb_pair[45]~FF .D_POLARITY = 1'b1;
    defparam \out_rgb_pair[45]~FF .SR_SYNC = 1'b1;
    defparam \out_rgb_pair[45]~FF .SR_VALUE = 1'b0;
    defparam \out_rgb_pair[45]~FF .SR_SYNC_PRIORITY = 1'b1;
    EFX_FF \out_rgb_pair[46]~FF  (.D(n574_24[22]), .CE(1'b1), .CLK(clk), 
           .SR(n1920), .Q(out_rgb_pair[46])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_FF, CLK_POLARITY=1'b1, D_POLARITY=1'b1, CE_POLARITY=1'b1, SR_SYNC=1'b1, SR_SYNC_PRIORITY=1'b1, SR_VALUE=1'b0, SR_POLARITY=1'b0 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(105)
    defparam \out_rgb_pair[46]~FF .CLK_POLARITY = 1'b1;
    defparam \out_rgb_pair[46]~FF .CE_POLARITY = 1'b1;
    defparam \out_rgb_pair[46]~FF .SR_POLARITY = 1'b0;
    defparam \out_rgb_pair[46]~FF .D_POLARITY = 1'b1;
    defparam \out_rgb_pair[46]~FF .SR_SYNC = 1'b1;
    defparam \out_rgb_pair[46]~FF .SR_VALUE = 1'b0;
    defparam \out_rgb_pair[46]~FF .SR_SYNC_PRIORITY = 1'b1;
    EFX_FF \out_rgb_pair[47]~FF  (.D(n574_25[23]), .CE(1'b1), .CLK(clk), 
           .SR(n1920), .Q(out_rgb_pair[47])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_FF, CLK_POLARITY=1'b1, D_POLARITY=1'b1, CE_POLARITY=1'b1, SR_SYNC=1'b1, SR_SYNC_PRIORITY=1'b1, SR_VALUE=1'b0, SR_POLARITY=1'b0 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(105)
    defparam \out_rgb_pair[47]~FF .CLK_POLARITY = 1'b1;
    defparam \out_rgb_pair[47]~FF .CE_POLARITY = 1'b1;
    defparam \out_rgb_pair[47]~FF .SR_POLARITY = 1'b0;
    defparam \out_rgb_pair[47]~FF .D_POLARITY = 1'b1;
    defparam \out_rgb_pair[47]~FF .SR_SYNC = 1'b1;
    defparam \out_rgb_pair[47]~FF .SR_VALUE = 1'b0;
    defparam \out_rgb_pair[47]~FF .SR_SYNC_PRIORITY = 1'b1;
    EFX_FF \out_x_even[1]~FF  (.D(\snapshot.x_even [1]), .CE(1'b1), .CLK(clk), 
           .SR(rst), .Q(out_x_even[1])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_FF, CLK_POLARITY=1'b1, D_POLARITY=1'b1, CE_POLARITY=1'b1, SR_SYNC=1'b1, SR_SYNC_PRIORITY=1'b1, SR_VALUE=1'b0, SR_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(105)
    defparam \out_x_even[1]~FF .CLK_POLARITY = 1'b1;
    defparam \out_x_even[1]~FF .CE_POLARITY = 1'b1;
    defparam \out_x_even[1]~FF .SR_POLARITY = 1'b1;
    defparam \out_x_even[1]~FF .D_POLARITY = 1'b1;
    defparam \out_x_even[1]~FF .SR_SYNC = 1'b1;
    defparam \out_x_even[1]~FF .SR_VALUE = 1'b0;
    defparam \out_x_even[1]~FF .SR_SYNC_PRIORITY = 1'b1;
    EFX_FF \out_x_even[2]~FF  (.D(\snapshot.x_even [2]), .CE(1'b1), .CLK(clk), 
           .SR(rst), .Q(out_x_even[2])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_FF, CLK_POLARITY=1'b1, D_POLARITY=1'b1, CE_POLARITY=1'b1, SR_SYNC=1'b1, SR_SYNC_PRIORITY=1'b1, SR_VALUE=1'b0, SR_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(105)
    defparam \out_x_even[2]~FF .CLK_POLARITY = 1'b1;
    defparam \out_x_even[2]~FF .CE_POLARITY = 1'b1;
    defparam \out_x_even[2]~FF .SR_POLARITY = 1'b1;
    defparam \out_x_even[2]~FF .D_POLARITY = 1'b1;
    defparam \out_x_even[2]~FF .SR_SYNC = 1'b1;
    defparam \out_x_even[2]~FF .SR_VALUE = 1'b0;
    defparam \out_x_even[2]~FF .SR_SYNC_PRIORITY = 1'b1;
    EFX_FF \out_x_even[3]~FF  (.D(\snapshot.x_even [3]), .CE(1'b1), .CLK(clk), 
           .SR(rst), .Q(out_x_even[3])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_FF, CLK_POLARITY=1'b1, D_POLARITY=1'b1, CE_POLARITY=1'b1, SR_SYNC=1'b1, SR_SYNC_PRIORITY=1'b1, SR_VALUE=1'b0, SR_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(105)
    defparam \out_x_even[3]~FF .CLK_POLARITY = 1'b1;
    defparam \out_x_even[3]~FF .CE_POLARITY = 1'b1;
    defparam \out_x_even[3]~FF .SR_POLARITY = 1'b1;
    defparam \out_x_even[3]~FF .D_POLARITY = 1'b1;
    defparam \out_x_even[3]~FF .SR_SYNC = 1'b1;
    defparam \out_x_even[3]~FF .SR_VALUE = 1'b0;
    defparam \out_x_even[3]~FF .SR_SYNC_PRIORITY = 1'b1;
    EFX_FF \out_x_even[4]~FF  (.D(\snapshot.x_even [4]), .CE(1'b1), .CLK(clk), 
           .SR(rst), .Q(out_x_even[4])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_FF, CLK_POLARITY=1'b1, D_POLARITY=1'b1, CE_POLARITY=1'b1, SR_SYNC=1'b1, SR_SYNC_PRIORITY=1'b1, SR_VALUE=1'b0, SR_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(105)
    defparam \out_x_even[4]~FF .CLK_POLARITY = 1'b1;
    defparam \out_x_even[4]~FF .CE_POLARITY = 1'b1;
    defparam \out_x_even[4]~FF .SR_POLARITY = 1'b1;
    defparam \out_x_even[4]~FF .D_POLARITY = 1'b1;
    defparam \out_x_even[4]~FF .SR_SYNC = 1'b1;
    defparam \out_x_even[4]~FF .SR_VALUE = 1'b0;
    defparam \out_x_even[4]~FF .SR_SYNC_PRIORITY = 1'b1;
    EFX_FF \out_x_even[5]~FF  (.D(\snapshot.x_even [5]), .CE(1'b1), .CLK(clk), 
           .SR(rst), .Q(out_x_even[5])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_FF, CLK_POLARITY=1'b1, D_POLARITY=1'b1, CE_POLARITY=1'b1, SR_SYNC=1'b1, SR_SYNC_PRIORITY=1'b1, SR_VALUE=1'b0, SR_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(105)
    defparam \out_x_even[5]~FF .CLK_POLARITY = 1'b1;
    defparam \out_x_even[5]~FF .CE_POLARITY = 1'b1;
    defparam \out_x_even[5]~FF .SR_POLARITY = 1'b1;
    defparam \out_x_even[5]~FF .D_POLARITY = 1'b1;
    defparam \out_x_even[5]~FF .SR_SYNC = 1'b1;
    defparam \out_x_even[5]~FF .SR_VALUE = 1'b0;
    defparam \out_x_even[5]~FF .SR_SYNC_PRIORITY = 1'b1;
    EFX_FF \out_x_even[6]~FF  (.D(\snapshot.x_even [6]), .CE(1'b1), .CLK(clk), 
           .SR(rst), .Q(out_x_even[6])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_FF, CLK_POLARITY=1'b1, D_POLARITY=1'b1, CE_POLARITY=1'b1, SR_SYNC=1'b1, SR_SYNC_PRIORITY=1'b1, SR_VALUE=1'b0, SR_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(105)
    defparam \out_x_even[6]~FF .CLK_POLARITY = 1'b1;
    defparam \out_x_even[6]~FF .CE_POLARITY = 1'b1;
    defparam \out_x_even[6]~FF .SR_POLARITY = 1'b1;
    defparam \out_x_even[6]~FF .D_POLARITY = 1'b1;
    defparam \out_x_even[6]~FF .SR_SYNC = 1'b1;
    defparam \out_x_even[6]~FF .SR_VALUE = 1'b0;
    defparam \out_x_even[6]~FF .SR_SYNC_PRIORITY = 1'b1;
    EFX_FF \out_x_even[7]~FF  (.D(\snapshot.x_even [7]), .CE(1'b1), .CLK(clk), 
           .SR(rst), .Q(out_x_even[7])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_FF, CLK_POLARITY=1'b1, D_POLARITY=1'b1, CE_POLARITY=1'b1, SR_SYNC=1'b1, SR_SYNC_PRIORITY=1'b1, SR_VALUE=1'b0, SR_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(105)
    defparam \out_x_even[7]~FF .CLK_POLARITY = 1'b1;
    defparam \out_x_even[7]~FF .CE_POLARITY = 1'b1;
    defparam \out_x_even[7]~FF .SR_POLARITY = 1'b1;
    defparam \out_x_even[7]~FF .D_POLARITY = 1'b1;
    defparam \out_x_even[7]~FF .SR_SYNC = 1'b1;
    defparam \out_x_even[7]~FF .SR_VALUE = 1'b0;
    defparam \out_x_even[7]~FF .SR_SYNC_PRIORITY = 1'b1;
    EFX_FF \out_x_even[8]~FF  (.D(\snapshot.x_even [8]), .CE(1'b1), .CLK(clk), 
           .SR(rst), .Q(out_x_even[8])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_FF, CLK_POLARITY=1'b1, D_POLARITY=1'b1, CE_POLARITY=1'b1, SR_SYNC=1'b1, SR_SYNC_PRIORITY=1'b1, SR_VALUE=1'b0, SR_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(105)
    defparam \out_x_even[8]~FF .CLK_POLARITY = 1'b1;
    defparam \out_x_even[8]~FF .CE_POLARITY = 1'b1;
    defparam \out_x_even[8]~FF .SR_POLARITY = 1'b1;
    defparam \out_x_even[8]~FF .D_POLARITY = 1'b1;
    defparam \out_x_even[8]~FF .SR_SYNC = 1'b1;
    defparam \out_x_even[8]~FF .SR_VALUE = 1'b0;
    defparam \out_x_even[8]~FF .SR_SYNC_PRIORITY = 1'b1;
    EFX_FF \out_x_even[9]~FF  (.D(\snapshot.x_even [9]), .CE(1'b1), .CLK(clk), 
           .SR(rst), .Q(out_x_even[9])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_FF, CLK_POLARITY=1'b1, D_POLARITY=1'b1, CE_POLARITY=1'b1, SR_SYNC=1'b1, SR_SYNC_PRIORITY=1'b1, SR_VALUE=1'b0, SR_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(105)
    defparam \out_x_even[9]~FF .CLK_POLARITY = 1'b1;
    defparam \out_x_even[9]~FF .CE_POLARITY = 1'b1;
    defparam \out_x_even[9]~FF .SR_POLARITY = 1'b1;
    defparam \out_x_even[9]~FF .D_POLARITY = 1'b1;
    defparam \out_x_even[9]~FF .SR_SYNC = 1'b1;
    defparam \out_x_even[9]~FF .SR_VALUE = 1'b0;
    defparam \out_x_even[9]~FF .SR_SYNC_PRIORITY = 1'b1;
    EFX_FF \out_x_even[10]~FF  (.D(\snapshot.x_even [10]), .CE(1'b1), .CLK(clk), 
           .SR(rst), .Q(out_x_even[10])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_FF, CLK_POLARITY=1'b1, D_POLARITY=1'b1, CE_POLARITY=1'b1, SR_SYNC=1'b1, SR_SYNC_PRIORITY=1'b1, SR_VALUE=1'b0, SR_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(105)
    defparam \out_x_even[10]~FF .CLK_POLARITY = 1'b1;
    defparam \out_x_even[10]~FF .CE_POLARITY = 1'b1;
    defparam \out_x_even[10]~FF .SR_POLARITY = 1'b1;
    defparam \out_x_even[10]~FF .D_POLARITY = 1'b1;
    defparam \out_x_even[10]~FF .SR_SYNC = 1'b1;
    defparam \out_x_even[10]~FF .SR_VALUE = 1'b0;
    defparam \out_x_even[10]~FF .SR_SYNC_PRIORITY = 1'b1;
    EFX_FF \out_y[1]~FF  (.D(\snapshot.y [1]), .CE(1'b1), .CLK(clk), .SR(rst), 
           .Q(out_y[1])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_FF, CLK_POLARITY=1'b1, D_POLARITY=1'b1, CE_POLARITY=1'b1, SR_SYNC=1'b1, SR_SYNC_PRIORITY=1'b1, SR_VALUE=1'b0, SR_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(105)
    defparam \out_y[1]~FF .CLK_POLARITY = 1'b1;
    defparam \out_y[1]~FF .CE_POLARITY = 1'b1;
    defparam \out_y[1]~FF .SR_POLARITY = 1'b1;
    defparam \out_y[1]~FF .D_POLARITY = 1'b1;
    defparam \out_y[1]~FF .SR_SYNC = 1'b1;
    defparam \out_y[1]~FF .SR_VALUE = 1'b0;
    defparam \out_y[1]~FF .SR_SYNC_PRIORITY = 1'b1;
    EFX_FF \out_y[2]~FF  (.D(\snapshot.y [2]), .CE(1'b1), .CLK(clk), .SR(rst), 
           .Q(out_y[2])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_FF, CLK_POLARITY=1'b1, D_POLARITY=1'b1, CE_POLARITY=1'b1, SR_SYNC=1'b1, SR_SYNC_PRIORITY=1'b1, SR_VALUE=1'b0, SR_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(105)
    defparam \out_y[2]~FF .CLK_POLARITY = 1'b1;
    defparam \out_y[2]~FF .CE_POLARITY = 1'b1;
    defparam \out_y[2]~FF .SR_POLARITY = 1'b1;
    defparam \out_y[2]~FF .D_POLARITY = 1'b1;
    defparam \out_y[2]~FF .SR_SYNC = 1'b1;
    defparam \out_y[2]~FF .SR_VALUE = 1'b0;
    defparam \out_y[2]~FF .SR_SYNC_PRIORITY = 1'b1;
    EFX_FF \out_y[3]~FF  (.D(\snapshot.y [3]), .CE(1'b1), .CLK(clk), .SR(rst), 
           .Q(out_y[3])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_FF, CLK_POLARITY=1'b1, D_POLARITY=1'b1, CE_POLARITY=1'b1, SR_SYNC=1'b1, SR_SYNC_PRIORITY=1'b1, SR_VALUE=1'b0, SR_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(105)
    defparam \out_y[3]~FF .CLK_POLARITY = 1'b1;
    defparam \out_y[3]~FF .CE_POLARITY = 1'b1;
    defparam \out_y[3]~FF .SR_POLARITY = 1'b1;
    defparam \out_y[3]~FF .D_POLARITY = 1'b1;
    defparam \out_y[3]~FF .SR_SYNC = 1'b1;
    defparam \out_y[3]~FF .SR_VALUE = 1'b0;
    defparam \out_y[3]~FF .SR_SYNC_PRIORITY = 1'b1;
    EFX_FF \out_y[4]~FF  (.D(\snapshot.y [4]), .CE(1'b1), .CLK(clk), .SR(rst), 
           .Q(out_y[4])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_FF, CLK_POLARITY=1'b1, D_POLARITY=1'b1, CE_POLARITY=1'b1, SR_SYNC=1'b1, SR_SYNC_PRIORITY=1'b1, SR_VALUE=1'b0, SR_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(105)
    defparam \out_y[4]~FF .CLK_POLARITY = 1'b1;
    defparam \out_y[4]~FF .CE_POLARITY = 1'b1;
    defparam \out_y[4]~FF .SR_POLARITY = 1'b1;
    defparam \out_y[4]~FF .D_POLARITY = 1'b1;
    defparam \out_y[4]~FF .SR_SYNC = 1'b1;
    defparam \out_y[4]~FF .SR_VALUE = 1'b0;
    defparam \out_y[4]~FF .SR_SYNC_PRIORITY = 1'b1;
    EFX_FF \out_y[5]~FF  (.D(\snapshot.y [5]), .CE(1'b1), .CLK(clk), .SR(rst), 
           .Q(out_y[5])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_FF, CLK_POLARITY=1'b1, D_POLARITY=1'b1, CE_POLARITY=1'b1, SR_SYNC=1'b1, SR_SYNC_PRIORITY=1'b1, SR_VALUE=1'b0, SR_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(105)
    defparam \out_y[5]~FF .CLK_POLARITY = 1'b1;
    defparam \out_y[5]~FF .CE_POLARITY = 1'b1;
    defparam \out_y[5]~FF .SR_POLARITY = 1'b1;
    defparam \out_y[5]~FF .D_POLARITY = 1'b1;
    defparam \out_y[5]~FF .SR_SYNC = 1'b1;
    defparam \out_y[5]~FF .SR_VALUE = 1'b0;
    defparam \out_y[5]~FF .SR_SYNC_PRIORITY = 1'b1;
    EFX_FF \out_y[6]~FF  (.D(\snapshot.y [6]), .CE(1'b1), .CLK(clk), .SR(rst), 
           .Q(out_y[6])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_FF, CLK_POLARITY=1'b1, D_POLARITY=1'b1, CE_POLARITY=1'b1, SR_SYNC=1'b1, SR_SYNC_PRIORITY=1'b1, SR_VALUE=1'b0, SR_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(105)
    defparam \out_y[6]~FF .CLK_POLARITY = 1'b1;
    defparam \out_y[6]~FF .CE_POLARITY = 1'b1;
    defparam \out_y[6]~FF .SR_POLARITY = 1'b1;
    defparam \out_y[6]~FF .D_POLARITY = 1'b1;
    defparam \out_y[6]~FF .SR_SYNC = 1'b1;
    defparam \out_y[6]~FF .SR_VALUE = 1'b0;
    defparam \out_y[6]~FF .SR_SYNC_PRIORITY = 1'b1;
    EFX_FF \out_y[7]~FF  (.D(\snapshot.y [7]), .CE(1'b1), .CLK(clk), .SR(rst), 
           .Q(out_y[7])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_FF, CLK_POLARITY=1'b1, D_POLARITY=1'b1, CE_POLARITY=1'b1, SR_SYNC=1'b1, SR_SYNC_PRIORITY=1'b1, SR_VALUE=1'b0, SR_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(105)
    defparam \out_y[7]~FF .CLK_POLARITY = 1'b1;
    defparam \out_y[7]~FF .CE_POLARITY = 1'b1;
    defparam \out_y[7]~FF .SR_POLARITY = 1'b1;
    defparam \out_y[7]~FF .D_POLARITY = 1'b1;
    defparam \out_y[7]~FF .SR_SYNC = 1'b1;
    defparam \out_y[7]~FF .SR_VALUE = 1'b0;
    defparam \out_y[7]~FF .SR_SYNC_PRIORITY = 1'b1;
    EFX_FF \out_y[8]~FF  (.D(\snapshot.y [8]), .CE(1'b1), .CLK(clk), .SR(rst), 
           .Q(out_y[8])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_FF, CLK_POLARITY=1'b1, D_POLARITY=1'b1, CE_POLARITY=1'b1, SR_SYNC=1'b1, SR_SYNC_PRIORITY=1'b1, SR_VALUE=1'b0, SR_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(105)
    defparam \out_y[8]~FF .CLK_POLARITY = 1'b1;
    defparam \out_y[8]~FF .CE_POLARITY = 1'b1;
    defparam \out_y[8]~FF .SR_POLARITY = 1'b1;
    defparam \out_y[8]~FF .D_POLARITY = 1'b1;
    defparam \out_y[8]~FF .SR_SYNC = 1'b1;
    defparam \out_y[8]~FF .SR_VALUE = 1'b0;
    defparam \out_y[8]~FF .SR_SYNC_PRIORITY = 1'b1;
    EFX_FF \out_y[9]~FF  (.D(\snapshot.y [9]), .CE(1'b1), .CLK(clk), .SR(rst), 
           .Q(out_y[9])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_FF, CLK_POLARITY=1'b1, D_POLARITY=1'b1, CE_POLARITY=1'b1, SR_SYNC=1'b1, SR_SYNC_PRIORITY=1'b1, SR_VALUE=1'b0, SR_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(105)
    defparam \out_y[9]~FF .CLK_POLARITY = 1'b1;
    defparam \out_y[9]~FF .CE_POLARITY = 1'b1;
    defparam \out_y[9]~FF .SR_POLARITY = 1'b1;
    defparam \out_y[9]~FF .D_POLARITY = 1'b1;
    defparam \out_y[9]~FF .SR_SYNC = 1'b1;
    defparam \out_y[9]~FF .SR_VALUE = 1'b0;
    defparam \out_y[9]~FF .SR_SYNC_PRIORITY = 1'b1;
    EFX_FF \out_y[10]~FF  (.D(\snapshot.y [10]), .CE(1'b1), .CLK(clk), 
           .SR(rst), .Q(out_y[10])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_FF, CLK_POLARITY=1'b1, D_POLARITY=1'b1, CE_POLARITY=1'b1, SR_SYNC=1'b1, SR_SYNC_PRIORITY=1'b1, SR_VALUE=1'b0, SR_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(105)
    defparam \out_y[10]~FF .CLK_POLARITY = 1'b1;
    defparam \out_y[10]~FF .CE_POLARITY = 1'b1;
    defparam \out_y[10]~FF .SR_POLARITY = 1'b1;
    defparam \out_y[10]~FF .D_POLARITY = 1'b1;
    defparam \out_y[10]~FF .SR_SYNC = 1'b1;
    defparam \out_y[10]~FF .SR_VALUE = 1'b0;
    defparam \out_y[10]~FF .SR_SYNC_PRIORITY = 1'b1;
    EFX_FF \out_error[1]~FF  (.D(\snapshot.error [1]), .CE(1'b1), .CLK(clk), 
           .SR(rst), .Q(out_error[1])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_FF, CLK_POLARITY=1'b1, D_POLARITY=1'b1, CE_POLARITY=1'b1, SR_SYNC=1'b1, SR_SYNC_PRIORITY=1'b1, SR_VALUE=1'b0, SR_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(105)
    defparam \out_error[1]~FF .CLK_POLARITY = 1'b1;
    defparam \out_error[1]~FF .CE_POLARITY = 1'b1;
    defparam \out_error[1]~FF .SR_POLARITY = 1'b1;
    defparam \out_error[1]~FF .D_POLARITY = 1'b1;
    defparam \out_error[1]~FF .SR_SYNC = 1'b1;
    defparam \out_error[1]~FF .SR_VALUE = 1'b0;
    defparam \out_error[1]~FF .SR_SYNC_PRIORITY = 1'b1;
    EFX_ADD \add_4/i1  (.I0(in_pair[40]), .I1(in_pair[41]), .CI(1'b0), 
            .O(n15[0]), .CO(\add_4/n2 )) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(36)
    defparam \add_4/i1 .I0_POLARITY = 1'b1;
    defparam \add_4/i1 .I1_POLARITY = 1'b1;
    EFX_ADD \add_5/i1  (.I0(in_pair[40]), .I1(in_pair[42]), .CI(1'b0), 
            .O(n29[0]), .CO(\add_5/n2 )) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(36)
    defparam \add_5/i1 .I0_POLARITY = 1'b1;
    defparam \add_5/i1 .I1_POLARITY = 1'b1;
    EFX_ADD \add_6/i1  (.I0(n29[5]), .I1(in_pair[32]), .CI(1'b0), .O(n45[0]), 
            .CO(\add_6/n2 )) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(37)
    defparam \add_6/i1 .I0_POLARITY = 1'b1;
    defparam \add_6/i1 .I1_POLARITY = 1'b1;
    EFX_ADD \add_7/i1  (.I0(n29[2]), .I1(in_pair[32]), .CI(1'b0), .O(n56[0]), 
            .CO(\add_7/n2 )) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(37)
    defparam \add_7/i1 .I0_POLARITY = 1'b1;
    defparam \add_7/i1 .I1_POLARITY = 1'b1;
    EFX_ADD \add_8/i1  (.I0(n29[0]), .I1(in_pair[32]), .CI(1'b0), .O(n70[0]), 
            .CO(\add_8/n2 )) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(37)
    defparam \add_8/i1 .I0_POLARITY = 1'b1;
    defparam \add_8/i1 .I1_POLARITY = 1'b1;
    EFX_ADD \add_9/i1  (.I0(in_pair[41]), .I1(in_pair[32]), .CI(1'b0), 
            .O(n86[0]), .CO(\add_9/n2 )) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(37)
    defparam \add_9/i1 .I0_POLARITY = 1'b1;
    defparam \add_9/i1 .I1_POLARITY = 1'b1;
    EFX_ADD \add_10/i1  (.I0(n86[3]), .I1(in_pair[24]), .CI(1'b0), .O(n103[0]), 
            .CO(\add_10/n2 )) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(38)
    defparam \add_10/i1 .I0_POLARITY = 1'b1;
    defparam \add_10/i1 .I1_POLARITY = 1'b1;
    EFX_ADD \add_11/i1  (.I0(n86[2]), .I1(in_pair[24]), .CI(1'b0), .O(n117[0]), 
            .CO(\add_11/n2 )) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(38)
    defparam \add_11/i1 .I0_POLARITY = 1'b1;
    defparam \add_11/i1 .I1_POLARITY = 1'b1;
    EFX_ADD \add_12/i1  (.I0(n86[1]), .I1(in_pair[24]), .CI(1'b0), .O(n132[0]), 
            .CO(\add_12/n2 )) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(38)
    defparam \add_12/i1 .I0_POLARITY = 1'b1;
    defparam \add_12/i1 .I1_POLARITY = 1'b1;
    EFX_ADD \add_13/i1  (.I0(in_pair[40]), .I1(in_pair[24]), .CI(1'b0), 
            .CO(\add_13/n2 )) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(38)
    defparam \add_13/i1 .I0_POLARITY = 1'b1;
    defparam \add_13/i1 .I1_POLARITY = 1'b1;
    EFX_ADD \add_305/i1  (.I0(n320[8]), .I1(n320[7]), .CI(1'b0), .O(\next_snapshot.gray [0]), 
            .CO(\add_305/n2 )) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(38)
    defparam \add_305/i1 .I0_POLARITY = 1'b1;
    defparam \add_305/i1 .I1_POLARITY = 1'b1;
    EFX_ADD \add_15/i1  (.I0(in_pair[16]), .I1(in_pair[19]), .CI(1'b0), 
            .O(n177[0]), .CO(\add_15/n2 )) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(36)
    defparam \add_15/i1 .I0_POLARITY = 1'b1;
    defparam \add_15/i1 .I1_POLARITY = 1'b1;
    EFX_ADD \add_16/i1  (.I0(in_pair[16]), .I1(in_pair[17]), .CI(1'b0), 
            .O(n187[0]), .CO(\add_16/n2 )) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(36)
    defparam \add_16/i1 .I0_POLARITY = 1'b1;
    defparam \add_16/i1 .I1_POLARITY = 1'b1;
    EFX_ADD \add_17/i1  (.I0(in_pair[16]), .I1(in_pair[18]), .CI(1'b0), 
            .O(n201[0]), .CO(\add_17/n2 )) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(36)
    defparam \add_17/i1 .I0_POLARITY = 1'b1;
    defparam \add_17/i1 .I1_POLARITY = 1'b1;
    EFX_ADD \add_18/i1  (.I0(n201[5]), .I1(in_pair[8]), .CI(1'b0), .O(n217[0]), 
            .CO(\add_18/n2 )) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(37)
    defparam \add_18/i1 .I0_POLARITY = 1'b1;
    defparam \add_18/i1 .I1_POLARITY = 1'b1;
    EFX_ADD \add_19/i1  (.I0(n201[2]), .I1(in_pair[8]), .CI(1'b0), .O(n228[0]), 
            .CO(\add_19/n2 )) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(37)
    defparam \add_19/i1 .I0_POLARITY = 1'b1;
    defparam \add_19/i1 .I1_POLARITY = 1'b1;
    EFX_ADD \add_20/i1  (.I0(n201[0]), .I1(in_pair[8]), .CI(1'b0), .O(n242[0]), 
            .CO(\add_20/n2 )) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(37)
    defparam \add_20/i1 .I0_POLARITY = 1'b1;
    defparam \add_20/i1 .I1_POLARITY = 1'b1;
    EFX_ADD \add_21/i1  (.I0(in_pair[17]), .I1(in_pair[8]), .CI(1'b0), 
            .O(n258[0]), .CO(\add_21/n2 )) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(37)
    defparam \add_21/i1 .I0_POLARITY = 1'b1;
    defparam \add_21/i1 .I1_POLARITY = 1'b1;
    EFX_ADD \add_22/i1  (.I0(n258[3]), .I1(in_pair[0]), .CI(1'b0), .O(n275[0]), 
            .CO(\add_22/n2 )) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(38)
    defparam \add_22/i1 .I0_POLARITY = 1'b1;
    defparam \add_22/i1 .I1_POLARITY = 1'b1;
    EFX_ADD \add_23/i1  (.I0(n258[2]), .I1(in_pair[0]), .CI(1'b0), .O(n289[0]), 
            .CO(\add_23/n2 )) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(38)
    defparam \add_23/i1 .I0_POLARITY = 1'b1;
    defparam \add_23/i1 .I1_POLARITY = 1'b1;
    EFX_ADD \add_24/i1  (.I0(n258[1]), .I1(in_pair[0]), .CI(1'b0), .O(n304[0]), 
            .CO(\add_24/n2 )) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(38)
    defparam \add_24/i1 .I0_POLARITY = 1'b1;
    defparam \add_24/i1 .I1_POLARITY = 1'b1;
    EFX_ADD \add_25/i1  (.I0(in_pair[16]), .I1(in_pair[0]), .CI(1'b0), 
            .CO(\add_25/n2 )) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(38)
    defparam \add_25/i1 .I0_POLARITY = 1'b1;
    defparam \add_25/i1 .I1_POLARITY = 1'b1;
    EFX_ADD \add_304/i1  (.I0(n148[8]), .I1(n148[7]), .CI(1'b0), .O(\next_snapshot.gray [8]), 
            .CO(\add_304/n2 )) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(38)
    defparam \add_304/i1 .I0_POLARITY = 1'b1;
    defparam \add_304/i1 .I1_POLARITY = 1'b1;
    EFX_ADD \add_8/i9  (.I0(n56[6]), .I1(1'b0), .CI(\add_8/n16 ), .O(n70[8]), 
            .CO(\add_8/n18 )) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(37)
    defparam \add_8/i9 .I0_POLARITY = 1'b1;
    defparam \add_8/i9 .I1_POLARITY = 1'b1;
    EFX_ADD \add_10/i11  (.I0(n86[13]), .I1(1'b0), .CI(\add_10/n20 ), 
            .O(n103[10]), .CO(\add_10/n22 )) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(38)
    defparam \add_10/i11 .I0_POLARITY = 1'b1;
    defparam \add_10/i11 .I1_POLARITY = 1'b1;
    EFX_ADD \add_16/i12  (.I0(n176), .I1(1'b0), .CI(\add_16/n22 ), .O(n187[11]), 
            .CO(n1602)) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(36)
    defparam \add_16/i12 .I0_POLARITY = 1'b1;
    defparam \add_16/i12 .I1_POLARITY = 1'b1;
    EFX_ADD \add_16/i11  (.I0(n177[7]), .I1(1'b0), .CI(\add_16/n20 ), 
            .O(n187[10]), .CO(\add_16/n22 )) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(36)
    defparam \add_16/i11 .I0_POLARITY = 1'b1;
    defparam \add_16/i11 .I1_POLARITY = 1'b1;
    EFX_ADD \add_16/i10  (.I0(n177[6]), .I1(1'b0), .CI(\add_16/n18 ), 
            .O(n187[9]), .CO(\add_16/n20 )) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(36)
    defparam \add_16/i10 .I0_POLARITY = 1'b1;
    defparam \add_16/i10 .I1_POLARITY = 1'b1;
    EFX_ADD \add_16/i9  (.I0(n177[5]), .I1(1'b0), .CI(\add_16/n16 ), .O(n187[8]), 
            .CO(\add_16/n18 )) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(36)
    defparam \add_16/i9 .I0_POLARITY = 1'b1;
    defparam \add_16/i9 .I1_POLARITY = 1'b1;
    EFX_ADD \add_16/i8  (.I0(n177[4]), .I1(1'b0), .CI(\add_16/n14 ), .O(n187[7]), 
            .CO(\add_16/n16 )) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(36)
    defparam \add_16/i8 .I0_POLARITY = 1'b1;
    defparam \add_16/i8 .I1_POLARITY = 1'b1;
    EFX_ADD \add_8/i8  (.I0(n56[5]), .I1(in_pair[39]), .CI(\add_8/n14 ), 
            .O(n70[7]), .CO(\add_8/n16 )) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(37)
    defparam \add_8/i8 .I0_POLARITY = 1'b1;
    defparam \add_8/i8 .I1_POLARITY = 1'b1;
    EFX_ADD \add_16/i7  (.I0(n177[3]), .I1(in_pair[23]), .CI(\add_16/n12 ), 
            .O(n187[6]), .CO(\add_16/n14 )) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(36)
    defparam \add_16/i7 .I0_POLARITY = 1'b1;
    defparam \add_16/i7 .I1_POLARITY = 1'b1;
    EFX_ADD \add_18/i8  (.I0(n201[12]), .I1(in_pair[15]), .CI(\add_18/n14 ), 
            .O(n217[7]), .CO(\add_18/n16 )) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(37)
    defparam \add_18/i8 .I0_POLARITY = 1'b1;
    defparam \add_18/i8 .I1_POLARITY = 1'b1;
    EFX_ADD \add_18/i9  (.I0(n201[13]), .I1(1'b0), .CI(\add_18/n16 ), 
            .O(n217[8])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(37)
    defparam \add_18/i9 .I0_POLARITY = 1'b1;
    defparam \add_18/i9 .I1_POLARITY = 1'b1;
    EFX_ADD \add_19/i2  (.I0(n201[3]), .I1(in_pair[9]), .CI(\add_19/n2 ), 
            .O(n228[1]), .CO(\add_19/n4 )) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(37)
    defparam \add_19/i2 .I0_POLARITY = 1'b1;
    defparam \add_19/i2 .I1_POLARITY = 1'b1;
    EFX_ADD \add_19/i3  (.I0(n201[4]), .I1(in_pair[10]), .CI(\add_19/n4 ), 
            .O(n228[2]), .CO(\add_19/n6 )) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(37)
    defparam \add_19/i3 .I0_POLARITY = 1'b1;
    defparam \add_19/i3 .I1_POLARITY = 1'b1;
    EFX_ADD \add_22/i10  (.I0(n258[12]), .I1(1'b0), .CI(\add_22/n18 ), 
            .O(n275[9]), .CO(\add_22/n20 )) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(38)
    defparam \add_22/i10 .I0_POLARITY = 1'b1;
    defparam \add_22/i10 .I1_POLARITY = 1'b1;
    EFX_ADD \add_24/i9  (.I0(n289[7]), .I1(1'b0), .CI(\add_24/n16 ), .O(n304[8]), 
            .CO(\add_24/n18 )) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(38)
    defparam \add_24/i9 .I0_POLARITY = 1'b1;
    defparam \add_24/i9 .I1_POLARITY = 1'b1;
    EFX_ADD \add_304/i3  (.I0(n148[10]), .I1(1'b0), .CI(\add_304/n4 ), 
            .O(\next_snapshot.gray [10]), .CO(\add_304/n6 )) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(38)
    defparam \add_304/i3 .I0_POLARITY = 1'b1;
    defparam \add_304/i3 .I1_POLARITY = 1'b1;
    EFX_ADD \add_304/i4  (.I0(n148[11]), .I1(1'b0), .CI(\add_304/n6 ), 
            .O(\next_snapshot.gray [11]), .CO(\add_304/n8 )) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(38)
    defparam \add_304/i4 .I0_POLARITY = 1'b1;
    defparam \add_304/i4 .I1_POLARITY = 1'b1;
    EFX_ADD \add_304/i5  (.I0(n148[12]), .I1(1'b0), .CI(\add_304/n8 ), 
            .O(\next_snapshot.gray [12]), .CO(\add_304/n10 )) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(38)
    defparam \add_304/i5 .I0_POLARITY = 1'b1;
    defparam \add_304/i5 .I1_POLARITY = 1'b1;
    EFX_ADD \add_304/i8  (.I0(n148[15]), .I1(1'b0), .CI(\add_304/n14 ), 
            .O(\next_snapshot.gray [15])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(38)
    defparam \add_304/i8 .I0_POLARITY = 1'b1;
    defparam \add_304/i8 .I1_POLARITY = 1'b1;
    EFX_ADD \add_17/i11  (.I0(n187[9]), .I1(1'b0), .CI(\add_17/n20 ), 
            .O(n201[10]), .CO(\add_17/n22 )) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(36)
    defparam \add_17/i11 .I0_POLARITY = 1'b1;
    defparam \add_17/i11 .I1_POLARITY = 1'b1;
    EFX_ADD \add_17/i10  (.I0(n187[8]), .I1(1'b0), .CI(\add_17/n18 ), 
            .O(n201[9]), .CO(\add_17/n20 )) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(36)
    defparam \add_17/i10 .I0_POLARITY = 1'b1;
    defparam \add_17/i10 .I1_POLARITY = 1'b1;
    EFX_ADD \add_17/i9  (.I0(n187[7]), .I1(1'b0), .CI(\add_17/n16 ), .O(n201[8]), 
            .CO(\add_17/n18 )) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(36)
    defparam \add_17/i9 .I0_POLARITY = 1'b1;
    defparam \add_17/i9 .I1_POLARITY = 1'b1;
    EFX_ADD \add_17/i8  (.I0(n187[6]), .I1(1'b0), .CI(\add_17/n14 ), .O(n201[7]), 
            .CO(\add_17/n16 )) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(36)
    defparam \add_17/i8 .I0_POLARITY = 1'b1;
    defparam \add_17/i8 .I1_POLARITY = 1'b1;
    EFX_ADD \add_17/i7  (.I0(n187[5]), .I1(1'b0), .CI(\add_17/n12 ), .O(n201[6]), 
            .CO(\add_17/n14 )) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(36)
    defparam \add_17/i7 .I0_POLARITY = 1'b1;
    defparam \add_17/i7 .I1_POLARITY = 1'b1;
    EFX_ADD \add_17/i6  (.I0(n187[4]), .I1(in_pair[23]), .CI(\add_17/n10 ), 
            .O(n201[5]), .CO(\add_17/n12 )) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(36)
    defparam \add_17/i6 .I0_POLARITY = 1'b1;
    defparam \add_17/i6 .I1_POLARITY = 1'b1;
    EFX_ADD \add_17/i5  (.I0(n187[3]), .I1(in_pair[22]), .CI(\add_17/n8 ), 
            .O(n201[4]), .CO(\add_17/n10 )) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(36)
    defparam \add_17/i5 .I0_POLARITY = 1'b1;
    defparam \add_17/i5 .I1_POLARITY = 1'b1;
    EFX_ADD \add_17/i4  (.I0(n187[2]), .I1(in_pair[21]), .CI(\add_17/n6 ), 
            .O(n201[3]), .CO(\add_17/n8 )) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(36)
    defparam \add_17/i4 .I0_POLARITY = 1'b1;
    defparam \add_17/i4 .I1_POLARITY = 1'b1;
    EFX_ADD \add_17/i3  (.I0(n187[1]), .I1(in_pair[20]), .CI(\add_17/n4 ), 
            .O(n201[2]), .CO(\add_17/n6 )) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(36)
    defparam \add_17/i3 .I0_POLARITY = 1'b1;
    defparam \add_17/i3 .I1_POLARITY = 1'b1;
    EFX_ADD \add_17/i2  (.I0(n187[0]), .I1(in_pair[19]), .CI(\add_17/n2 ), 
            .O(n201[1]), .CO(\add_17/n4 )) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(36)
    defparam \add_17/i2 .I0_POLARITY = 1'b1;
    defparam \add_17/i2 .I1_POLARITY = 1'b1;
    EFX_ADD \add_18/i7  (.I0(n201[11]), .I1(in_pair[14]), .CI(\add_18/n12 ), 
            .O(n217[6]), .CO(\add_18/n14 )) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(37)
    defparam \add_18/i7 .I0_POLARITY = 1'b1;
    defparam \add_18/i7 .I1_POLARITY = 1'b1;
    EFX_ADD \add_18/i6  (.I0(n201[10]), .I1(in_pair[13]), .CI(\add_18/n10 ), 
            .O(n217[5]), .CO(\add_18/n12 )) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(37)
    defparam \add_18/i6 .I0_POLARITY = 1'b1;
    defparam \add_18/i6 .I1_POLARITY = 1'b1;
    EFX_ADD \add_18/i5  (.I0(n201[9]), .I1(in_pair[12]), .CI(\add_18/n8 ), 
            .O(n217[4]), .CO(\add_18/n10 )) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(37)
    defparam \add_18/i5 .I0_POLARITY = 1'b1;
    defparam \add_18/i5 .I1_POLARITY = 1'b1;
    EFX_ADD \add_18/i4  (.I0(n201[8]), .I1(in_pair[11]), .CI(\add_18/n6 ), 
            .O(n217[3]), .CO(\add_18/n8 )) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(37)
    defparam \add_18/i4 .I0_POLARITY = 1'b1;
    defparam \add_18/i4 .I1_POLARITY = 1'b1;
    EFX_ADD \add_18/i3  (.I0(n201[7]), .I1(in_pair[10]), .CI(\add_18/n4 ), 
            .O(n217[2]), .CO(\add_18/n6 )) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(37)
    defparam \add_18/i3 .I0_POLARITY = 1'b1;
    defparam \add_18/i3 .I1_POLARITY = 1'b1;
    EFX_ADD \add_18/i2  (.I0(n201[6]), .I1(in_pair[9]), .CI(\add_18/n2 ), 
            .O(n217[1]), .CO(\add_18/n4 )) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(37)
    defparam \add_18/i2 .I0_POLARITY = 1'b1;
    defparam \add_18/i2 .I1_POLARITY = 1'b1;
    EFX_ADD \add_17/i14  (.I0(n186), .I1(1'b0), .CI(\add_17/n26 ), .O(n201[13])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(36)
    defparam \add_17/i14 .I0_POLARITY = 1'b1;
    defparam \add_17/i14 .I1_POLARITY = 1'b1;
    EFX_ADD \add_17/i13  (.I0(n187[11]), .I1(1'b0), .CI(\add_17/n24 ), 
            .O(n201[12]), .CO(\add_17/n26 )) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(36)
    defparam \add_17/i13 .I0_POLARITY = 1'b1;
    defparam \add_17/i13 .I1_POLARITY = 1'b1;
    EFX_ADD \add_17/i12  (.I0(n187[10]), .I1(1'b0), .CI(\add_17/n22 ), 
            .O(n201[11]), .CO(\add_17/n24 )) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(36)
    defparam \add_17/i12 .I0_POLARITY = 1'b1;
    defparam \add_17/i12 .I1_POLARITY = 1'b1;
    EFX_ADD \add_20/i14  (.I0(n228[11]), .I1(1'b0), .CI(\add_20/n26 ), 
            .O(n242[13])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(37)
    defparam \add_20/i14 .I0_POLARITY = 1'b1;
    defparam \add_20/i14 .I1_POLARITY = 1'b1;
    EFX_ADD \add_20/i13  (.I0(n228[10]), .I1(1'b0), .CI(\add_20/n24 ), 
            .O(n242[12]), .CO(\add_20/n26 )) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(37)
    defparam \add_20/i13 .I0_POLARITY = 1'b1;
    defparam \add_20/i13 .I1_POLARITY = 1'b1;
    EFX_ADD \add_20/i12  (.I0(n228[9]), .I1(1'b0), .CI(\add_20/n22 ), 
            .O(n242[11]), .CO(\add_20/n24 )) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(37)
    defparam \add_20/i12 .I0_POLARITY = 1'b1;
    defparam \add_20/i12 .I1_POLARITY = 1'b1;
    EFX_ADD \add_20/i11  (.I0(n228[8]), .I1(1'b0), .CI(\add_20/n20 ), 
            .O(n242[10]), .CO(\add_20/n22 )) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(37)
    defparam \add_20/i11 .I0_POLARITY = 1'b1;
    defparam \add_20/i11 .I1_POLARITY = 1'b1;
    EFX_ADD \add_20/i10  (.I0(n228[7]), .I1(1'b0), .CI(\add_20/n18 ), 
            .O(n242[9]), .CO(\add_20/n20 )) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(37)
    defparam \add_20/i10 .I0_POLARITY = 1'b1;
    defparam \add_20/i10 .I1_POLARITY = 1'b1;
    EFX_ADD \add_20/i9  (.I0(n228[6]), .I1(1'b0), .CI(\add_20/n16 ), .O(n242[8]), 
            .CO(\add_20/n18 )) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(37)
    defparam \add_20/i9 .I0_POLARITY = 1'b1;
    defparam \add_20/i9 .I1_POLARITY = 1'b1;
    EFX_ADD \add_20/i8  (.I0(n228[5]), .I1(in_pair[15]), .CI(\add_20/n14 ), 
            .O(n242[7]), .CO(\add_20/n16 )) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(37)
    defparam \add_20/i8 .I0_POLARITY = 1'b1;
    defparam \add_20/i8 .I1_POLARITY = 1'b1;
    EFX_ADD \add_20/i7  (.I0(n228[4]), .I1(in_pair[14]), .CI(\add_20/n12 ), 
            .O(n242[6]), .CO(\add_20/n14 )) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(37)
    defparam \add_20/i7 .I0_POLARITY = 1'b1;
    defparam \add_20/i7 .I1_POLARITY = 1'b1;
    EFX_ADD \add_20/i6  (.I0(n228[3]), .I1(in_pair[13]), .CI(\add_20/n10 ), 
            .O(n242[5]), .CO(\add_20/n12 )) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(37)
    defparam \add_20/i6 .I0_POLARITY = 1'b1;
    defparam \add_20/i6 .I1_POLARITY = 1'b1;
    EFX_ADD \add_20/i5  (.I0(n228[2]), .I1(in_pair[12]), .CI(\add_20/n8 ), 
            .O(n242[4]), .CO(\add_20/n10 )) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(37)
    defparam \add_20/i5 .I0_POLARITY = 1'b1;
    defparam \add_20/i5 .I1_POLARITY = 1'b1;
    EFX_ADD \add_20/i4  (.I0(n228[1]), .I1(in_pair[11]), .CI(\add_20/n6 ), 
            .O(n242[3]), .CO(\add_20/n8 )) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(37)
    defparam \add_20/i4 .I0_POLARITY = 1'b1;
    defparam \add_20/i4 .I1_POLARITY = 1'b1;
    EFX_ADD \add_20/i3  (.I0(n228[0]), .I1(in_pair[10]), .CI(\add_20/n4 ), 
            .O(n242[2]), .CO(\add_20/n6 )) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(37)
    defparam \add_20/i3 .I0_POLARITY = 1'b1;
    defparam \add_20/i3 .I1_POLARITY = 1'b1;
    EFX_ADD \add_20/i2  (.I0(n201[1]), .I1(in_pair[9]), .CI(\add_20/n2 ), 
            .O(n242[1]), .CO(\add_20/n4 )) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(37)
    defparam \add_20/i2 .I0_POLARITY = 1'b1;
    defparam \add_20/i2 .I1_POLARITY = 1'b1;
    EFX_ADD \add_19/i12  (.I0(n217[8]), .I1(1'b0), .CI(\add_19/n22 ), 
            .O(n228[11])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(37)
    defparam \add_19/i12 .I0_POLARITY = 1'b1;
    defparam \add_19/i12 .I1_POLARITY = 1'b1;
    EFX_ADD \add_19/i11  (.I0(n217[7]), .I1(1'b0), .CI(\add_19/n20 ), 
            .O(n228[10]), .CO(\add_19/n22 )) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(37)
    defparam \add_19/i11 .I0_POLARITY = 1'b1;
    defparam \add_19/i11 .I1_POLARITY = 1'b1;
    EFX_ADD \add_19/i10  (.I0(n217[6]), .I1(1'b0), .CI(\add_19/n18 ), 
            .O(n228[9]), .CO(\add_19/n20 )) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(37)
    defparam \add_19/i10 .I0_POLARITY = 1'b1;
    defparam \add_19/i10 .I1_POLARITY = 1'b1;
    EFX_ADD \add_19/i9  (.I0(n217[5]), .I1(1'b0), .CI(\add_19/n16 ), .O(n228[8]), 
            .CO(\add_19/n18 )) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(37)
    defparam \add_19/i9 .I0_POLARITY = 1'b1;
    defparam \add_19/i9 .I1_POLARITY = 1'b1;
    EFX_ADD \add_19/i8  (.I0(n217[4]), .I1(in_pair[15]), .CI(\add_19/n14 ), 
            .O(n228[7]), .CO(\add_19/n16 )) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(37)
    defparam \add_19/i8 .I0_POLARITY = 1'b1;
    defparam \add_19/i8 .I1_POLARITY = 1'b1;
    EFX_ADD \add_19/i7  (.I0(n217[3]), .I1(in_pair[14]), .CI(\add_19/n12 ), 
            .O(n228[6]), .CO(\add_19/n14 )) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(37)
    defparam \add_19/i7 .I0_POLARITY = 1'b1;
    defparam \add_19/i7 .I1_POLARITY = 1'b1;
    EFX_ADD \add_19/i6  (.I0(n217[2]), .I1(in_pair[13]), .CI(\add_19/n10 ), 
            .O(n228[5]), .CO(\add_19/n12 )) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(37)
    defparam \add_19/i6 .I0_POLARITY = 1'b1;
    defparam \add_19/i6 .I1_POLARITY = 1'b1;
    EFX_ADD \add_19/i5  (.I0(n217[1]), .I1(in_pair[12]), .CI(\add_19/n8 ), 
            .O(n228[4]), .CO(\add_19/n10 )) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(37)
    defparam \add_19/i5 .I0_POLARITY = 1'b1;
    defparam \add_19/i5 .I1_POLARITY = 1'b1;
    EFX_ADD \add_19/i4  (.I0(n217[0]), .I1(in_pair[11]), .CI(\add_19/n6 ), 
            .O(n228[3]), .CO(\add_19/n8 )) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(37)
    defparam \add_19/i4 .I0_POLARITY = 1'b1;
    defparam \add_19/i4 .I1_POLARITY = 1'b1;
    EFX_ADD \add_22/i9  (.I0(n258[11]), .I1(1'b0), .CI(\add_22/n16 ), 
            .O(n275[8]), .CO(\add_22/n18 )) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(38)
    defparam \add_22/i9 .I0_POLARITY = 1'b1;
    defparam \add_22/i9 .I1_POLARITY = 1'b1;
    EFX_ADD \add_22/i8  (.I0(n258[10]), .I1(in_pair[7]), .CI(\add_22/n14 ), 
            .O(n275[7]), .CO(\add_22/n16 )) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(38)
    defparam \add_22/i8 .I0_POLARITY = 1'b1;
    defparam \add_22/i8 .I1_POLARITY = 1'b1;
    EFX_ADD \add_22/i7  (.I0(n258[9]), .I1(in_pair[6]), .CI(\add_22/n12 ), 
            .O(n275[6]), .CO(\add_22/n14 )) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(38)
    defparam \add_22/i7 .I0_POLARITY = 1'b1;
    defparam \add_22/i7 .I1_POLARITY = 1'b1;
    EFX_ADD \add_22/i6  (.I0(n258[8]), .I1(in_pair[5]), .CI(\add_22/n10 ), 
            .O(n275[5]), .CO(\add_22/n12 )) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(38)
    defparam \add_22/i6 .I0_POLARITY = 1'b1;
    defparam \add_22/i6 .I1_POLARITY = 1'b1;
    EFX_ADD \add_22/i5  (.I0(n258[7]), .I1(in_pair[4]), .CI(\add_22/n8 ), 
            .O(n275[4]), .CO(\add_22/n10 )) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(38)
    defparam \add_22/i5 .I0_POLARITY = 1'b1;
    defparam \add_22/i5 .I1_POLARITY = 1'b1;
    EFX_ADD \add_22/i4  (.I0(n258[6]), .I1(in_pair[3]), .CI(\add_22/n6 ), 
            .O(n275[3]), .CO(\add_22/n8 )) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(38)
    defparam \add_22/i4 .I0_POLARITY = 1'b1;
    defparam \add_22/i4 .I1_POLARITY = 1'b1;
    EFX_ADD \add_22/i3  (.I0(n258[5]), .I1(in_pair[2]), .CI(\add_22/n4 ), 
            .O(n275[2]), .CO(\add_22/n6 )) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(38)
    defparam \add_22/i3 .I0_POLARITY = 1'b1;
    defparam \add_22/i3 .I1_POLARITY = 1'b1;
    EFX_ADD \add_22/i2  (.I0(n258[4]), .I1(in_pair[1]), .CI(\add_22/n2 ), 
            .O(n275[1]), .CO(\add_22/n4 )) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(38)
    defparam \add_22/i2 .I0_POLARITY = 1'b1;
    defparam \add_22/i2 .I1_POLARITY = 1'b1;
    EFX_ADD \add_21/i15  (.I0(n242[13]), .I1(1'b0), .CI(\add_21/n28 ), 
            .O(n258[14])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(37)
    defparam \add_21/i15 .I0_POLARITY = 1'b1;
    defparam \add_21/i15 .I1_POLARITY = 1'b1;
    EFX_ADD \add_21/i14  (.I0(n242[12]), .I1(1'b0), .CI(\add_21/n26 ), 
            .O(n258[13]), .CO(\add_21/n28 )) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(37)
    defparam \add_21/i14 .I0_POLARITY = 1'b1;
    defparam \add_21/i14 .I1_POLARITY = 1'b1;
    EFX_ADD \add_21/i13  (.I0(n242[11]), .I1(1'b0), .CI(\add_21/n24 ), 
            .O(n258[12]), .CO(\add_21/n26 )) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(37)
    defparam \add_21/i13 .I0_POLARITY = 1'b1;
    defparam \add_21/i13 .I1_POLARITY = 1'b1;
    EFX_ADD \add_21/i12  (.I0(n242[10]), .I1(1'b0), .CI(\add_21/n22 ), 
            .O(n258[11]), .CO(\add_21/n24 )) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(37)
    defparam \add_21/i12 .I0_POLARITY = 1'b1;
    defparam \add_21/i12 .I1_POLARITY = 1'b1;
    EFX_ADD \add_21/i11  (.I0(n242[9]), .I1(1'b0), .CI(\add_21/n20 ), 
            .O(n258[10]), .CO(\add_21/n22 )) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(37)
    defparam \add_21/i11 .I0_POLARITY = 1'b1;
    defparam \add_21/i11 .I1_POLARITY = 1'b1;
    EFX_ADD \add_21/i10  (.I0(n242[8]), .I1(1'b0), .CI(\add_21/n18 ), 
            .O(n258[9]), .CO(\add_21/n20 )) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(37)
    defparam \add_21/i10 .I0_POLARITY = 1'b1;
    defparam \add_21/i10 .I1_POLARITY = 1'b1;
    EFX_ADD \add_21/i9  (.I0(n242[7]), .I1(1'b0), .CI(\add_21/n16 ), .O(n258[8]), 
            .CO(\add_21/n18 )) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(37)
    defparam \add_21/i9 .I0_POLARITY = 1'b1;
    defparam \add_21/i9 .I1_POLARITY = 1'b1;
    EFX_ADD \add_21/i8  (.I0(n242[6]), .I1(in_pair[15]), .CI(\add_21/n14 ), 
            .O(n258[7]), .CO(\add_21/n16 )) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(37)
    defparam \add_21/i8 .I0_POLARITY = 1'b1;
    defparam \add_21/i8 .I1_POLARITY = 1'b1;
    EFX_ADD \add_21/i7  (.I0(n242[5]), .I1(in_pair[14]), .CI(\add_21/n12 ), 
            .O(n258[6]), .CO(\add_21/n14 )) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(37)
    defparam \add_21/i7 .I0_POLARITY = 1'b1;
    defparam \add_21/i7 .I1_POLARITY = 1'b1;
    EFX_ADD \add_21/i6  (.I0(n242[4]), .I1(in_pair[13]), .CI(\add_21/n10 ), 
            .O(n258[5]), .CO(\add_21/n12 )) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(37)
    defparam \add_21/i6 .I0_POLARITY = 1'b1;
    defparam \add_21/i6 .I1_POLARITY = 1'b1;
    EFX_ADD \add_21/i5  (.I0(n242[3]), .I1(in_pair[12]), .CI(\add_21/n8 ), 
            .O(n258[4]), .CO(\add_21/n10 )) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(37)
    defparam \add_21/i5 .I0_POLARITY = 1'b1;
    defparam \add_21/i5 .I1_POLARITY = 1'b1;
    EFX_ADD \add_21/i4  (.I0(n242[2]), .I1(in_pair[11]), .CI(\add_21/n6 ), 
            .O(n258[3]), .CO(\add_21/n8 )) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(37)
    defparam \add_21/i4 .I0_POLARITY = 1'b1;
    defparam \add_21/i4 .I1_POLARITY = 1'b1;
    EFX_ADD \add_21/i3  (.I0(n242[1]), .I1(in_pair[10]), .CI(\add_21/n4 ), 
            .O(n258[2]), .CO(\add_21/n6 )) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(37)
    defparam \add_21/i3 .I0_POLARITY = 1'b1;
    defparam \add_21/i3 .I1_POLARITY = 1'b1;
    EFX_ADD \add_21/i2  (.I0(n242[0]), .I1(in_pair[9]), .CI(\add_21/n2 ), 
            .O(n258[1]), .CO(\add_21/n4 )) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(37)
    defparam \add_21/i2 .I0_POLARITY = 1'b1;
    defparam \add_21/i2 .I1_POLARITY = 1'b1;
    EFX_ADD \add_24/i8  (.I0(n289[6]), .I1(in_pair[7]), .CI(\add_24/n14 ), 
            .O(n304[7]), .CO(\add_24/n16 )) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(38)
    defparam \add_24/i8 .I0_POLARITY = 1'b1;
    defparam \add_24/i8 .I1_POLARITY = 1'b1;
    EFX_ADD \add_24/i7  (.I0(n289[5]), .I1(in_pair[6]), .CI(\add_24/n12 ), 
            .O(n304[6]), .CO(\add_24/n14 )) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(38)
    defparam \add_24/i7 .I0_POLARITY = 1'b1;
    defparam \add_24/i7 .I1_POLARITY = 1'b1;
    EFX_ADD \add_24/i6  (.I0(n289[4]), .I1(in_pair[5]), .CI(\add_24/n10 ), 
            .O(n304[5]), .CO(\add_24/n12 )) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(38)
    defparam \add_24/i6 .I0_POLARITY = 1'b1;
    defparam \add_24/i6 .I1_POLARITY = 1'b1;
    EFX_ADD \add_24/i5  (.I0(n289[3]), .I1(in_pair[4]), .CI(\add_24/n8 ), 
            .O(n304[4]), .CO(\add_24/n10 )) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(38)
    defparam \add_24/i5 .I0_POLARITY = 1'b1;
    defparam \add_24/i5 .I1_POLARITY = 1'b1;
    EFX_ADD \add_24/i4  (.I0(n289[2]), .I1(in_pair[3]), .CI(\add_24/n6 ), 
            .O(n304[3]), .CO(\add_24/n8 )) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(38)
    defparam \add_24/i4 .I0_POLARITY = 1'b1;
    defparam \add_24/i4 .I1_POLARITY = 1'b1;
    EFX_ADD \add_24/i3  (.I0(n289[1]), .I1(in_pair[2]), .CI(\add_24/n4 ), 
            .O(n304[2]), .CO(\add_24/n6 )) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(38)
    defparam \add_24/i3 .I0_POLARITY = 1'b1;
    defparam \add_24/i3 .I1_POLARITY = 1'b1;
    EFX_ADD \add_24/i2  (.I0(n289[0]), .I1(in_pair[1]), .CI(\add_24/n2 ), 
            .O(n304[1]), .CO(\add_24/n4 )) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(38)
    defparam \add_24/i2 .I0_POLARITY = 1'b1;
    defparam \add_24/i2 .I1_POLARITY = 1'b1;
    EFX_ADD \add_23/i13  (.I0(n275[11]), .I1(1'b0), .CI(\add_23/n24 ), 
            .O(n289[12])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(38)
    defparam \add_23/i13 .I0_POLARITY = 1'b1;
    defparam \add_23/i13 .I1_POLARITY = 1'b1;
    EFX_ADD \add_23/i12  (.I0(n275[10]), .I1(1'b0), .CI(\add_23/n22 ), 
            .O(n289[11]), .CO(\add_23/n24 )) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(38)
    defparam \add_23/i12 .I0_POLARITY = 1'b1;
    defparam \add_23/i12 .I1_POLARITY = 1'b1;
    EFX_ADD \add_23/i11  (.I0(n275[9]), .I1(1'b0), .CI(\add_23/n20 ), 
            .O(n289[10]), .CO(\add_23/n22 )) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(38)
    defparam \add_23/i11 .I0_POLARITY = 1'b1;
    defparam \add_23/i11 .I1_POLARITY = 1'b1;
    EFX_ADD \add_23/i10  (.I0(n275[8]), .I1(1'b0), .CI(\add_23/n18 ), 
            .O(n289[9]), .CO(\add_23/n20 )) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(38)
    defparam \add_23/i10 .I0_POLARITY = 1'b1;
    defparam \add_23/i10 .I1_POLARITY = 1'b1;
    EFX_ADD \add_23/i9  (.I0(n275[7]), .I1(1'b0), .CI(\add_23/n16 ), .O(n289[8]), 
            .CO(\add_23/n18 )) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(38)
    defparam \add_23/i9 .I0_POLARITY = 1'b1;
    defparam \add_23/i9 .I1_POLARITY = 1'b1;
    EFX_ADD \add_23/i8  (.I0(n275[6]), .I1(in_pair[7]), .CI(\add_23/n14 ), 
            .O(n289[7]), .CO(\add_23/n16 )) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(38)
    defparam \add_23/i8 .I0_POLARITY = 1'b1;
    defparam \add_23/i8 .I1_POLARITY = 1'b1;
    EFX_ADD \add_23/i7  (.I0(n275[5]), .I1(in_pair[6]), .CI(\add_23/n12 ), 
            .O(n289[6]), .CO(\add_23/n14 )) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(38)
    defparam \add_23/i7 .I0_POLARITY = 1'b1;
    defparam \add_23/i7 .I1_POLARITY = 1'b1;
    EFX_ADD \add_23/i6  (.I0(n275[4]), .I1(in_pair[5]), .CI(\add_23/n10 ), 
            .O(n289[5]), .CO(\add_23/n12 )) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(38)
    defparam \add_23/i6 .I0_POLARITY = 1'b1;
    defparam \add_23/i6 .I1_POLARITY = 1'b1;
    EFX_ADD \add_23/i5  (.I0(n275[3]), .I1(in_pair[4]), .CI(\add_23/n8 ), 
            .O(n289[4]), .CO(\add_23/n10 )) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(38)
    defparam \add_23/i5 .I0_POLARITY = 1'b1;
    defparam \add_23/i5 .I1_POLARITY = 1'b1;
    EFX_ADD \add_23/i4  (.I0(n275[2]), .I1(in_pair[3]), .CI(\add_23/n6 ), 
            .O(n289[3]), .CO(\add_23/n8 )) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(38)
    defparam \add_23/i4 .I0_POLARITY = 1'b1;
    defparam \add_23/i4 .I1_POLARITY = 1'b1;
    EFX_ADD \add_23/i3  (.I0(n275[1]), .I1(in_pair[2]), .CI(\add_23/n4 ), 
            .O(n289[2]), .CO(\add_23/n6 )) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(38)
    defparam \add_23/i3 .I0_POLARITY = 1'b1;
    defparam \add_23/i3 .I1_POLARITY = 1'b1;
    EFX_ADD \add_23/i2  (.I0(n275[0]), .I1(in_pair[1]), .CI(\add_23/n2 ), 
            .O(n289[1]), .CO(\add_23/n4 )) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(38)
    defparam \add_23/i2 .I0_POLARITY = 1'b1;
    defparam \add_23/i2 .I1_POLARITY = 1'b1;
    EFX_ADD \add_22/i12  (.I0(n258[14]), .I1(1'b0), .CI(\add_22/n22 ), 
            .O(n275[11])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(38)
    defparam \add_22/i12 .I0_POLARITY = 1'b1;
    defparam \add_22/i12 .I1_POLARITY = 1'b1;
    EFX_ADD \add_22/i11  (.I0(n258[13]), .I1(1'b0), .CI(\add_22/n20 ), 
            .O(n275[10]), .CO(\add_22/n22 )) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(38)
    defparam \add_22/i11 .I0_POLARITY = 1'b1;
    defparam \add_22/i11 .I1_POLARITY = 1'b1;
    EFX_ADD \add_304/i2  (.I0(n148[9]), .I1(1'b0), .CI(\add_304/n2 ), 
            .O(\next_snapshot.gray [9]), .CO(\add_304/n4 )) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(38)
    defparam \add_304/i2 .I0_POLARITY = 1'b1;
    defparam \add_304/i2 .I1_POLARITY = 1'b1;
    EFX_ADD \add_25/i16  (.I0(n304[13]), .I1(1'b0), .CI(\add_25/n30 ), 
            .O(n320[15])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(38)
    defparam \add_25/i16 .I0_POLARITY = 1'b1;
    defparam \add_25/i16 .I1_POLARITY = 1'b1;
    EFX_ADD \add_25/i15  (.I0(n304[12]), .I1(1'b0), .CI(\add_25/n28 ), 
            .O(n320[14]), .CO(\add_25/n30 )) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(38)
    defparam \add_25/i15 .I0_POLARITY = 1'b1;
    defparam \add_25/i15 .I1_POLARITY = 1'b1;
    EFX_ADD \add_25/i14  (.I0(n304[11]), .I1(1'b0), .CI(\add_25/n26 ), 
            .O(n320[13]), .CO(\add_25/n28 )) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(38)
    defparam \add_25/i14 .I0_POLARITY = 1'b1;
    defparam \add_25/i14 .I1_POLARITY = 1'b1;
    EFX_ADD \add_25/i13  (.I0(n304[10]), .I1(1'b0), .CI(\add_25/n24 ), 
            .O(n320[12]), .CO(\add_25/n26 )) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(38)
    defparam \add_25/i13 .I0_POLARITY = 1'b1;
    defparam \add_25/i13 .I1_POLARITY = 1'b1;
    EFX_ADD \add_25/i12  (.I0(n304[9]), .I1(1'b0), .CI(\add_25/n22 ), 
            .O(n320[11]), .CO(\add_25/n24 )) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(38)
    defparam \add_25/i12 .I0_POLARITY = 1'b1;
    defparam \add_25/i12 .I1_POLARITY = 1'b1;
    EFX_ADD \add_25/i11  (.I0(n304[8]), .I1(1'b0), .CI(\add_25/n20 ), 
            .O(n320[10]), .CO(\add_25/n22 )) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(38)
    defparam \add_25/i11 .I0_POLARITY = 1'b1;
    defparam \add_25/i11 .I1_POLARITY = 1'b1;
    EFX_ADD \add_25/i10  (.I0(n304[7]), .I1(1'b0), .CI(\add_25/n18 ), 
            .O(n320[9]), .CO(\add_25/n20 )) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(38)
    defparam \add_25/i10 .I0_POLARITY = 1'b1;
    defparam \add_25/i10 .I1_POLARITY = 1'b1;
    EFX_ADD \add_25/i9  (.I0(n304[6]), .I1(1'b0), .CI(\add_25/n16 ), .O(n320[8]), 
            .CO(\add_25/n18 )) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(38)
    defparam \add_25/i9 .I0_POLARITY = 1'b1;
    defparam \add_25/i9 .I1_POLARITY = 1'b1;
    EFX_ADD \add_25/i8  (.I0(n304[5]), .I1(in_pair[7]), .CI(\add_25/n14 ), 
            .O(n320[7]), .CO(\add_25/n16 )) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(38)
    defparam \add_25/i8 .I0_POLARITY = 1'b1;
    defparam \add_25/i8 .I1_POLARITY = 1'b1;
    EFX_ADD \add_25/i7  (.I0(n304[4]), .I1(in_pair[6]), .CI(\add_25/n12 ), 
            .CO(\add_25/n14 )) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(38)
    defparam \add_25/i7 .I0_POLARITY = 1'b1;
    defparam \add_25/i7 .I1_POLARITY = 1'b1;
    EFX_ADD \add_25/i6  (.I0(n304[3]), .I1(in_pair[5]), .CI(\add_25/n10 ), 
            .CO(\add_25/n12 )) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(38)
    defparam \add_25/i6 .I0_POLARITY = 1'b1;
    defparam \add_25/i6 .I1_POLARITY = 1'b1;
    EFX_ADD \add_25/i5  (.I0(n304[2]), .I1(in_pair[4]), .CI(\add_25/n8 ), 
            .CO(\add_25/n10 )) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(38)
    defparam \add_25/i5 .I0_POLARITY = 1'b1;
    defparam \add_25/i5 .I1_POLARITY = 1'b1;
    EFX_ADD \add_25/i4  (.I0(n304[1]), .I1(in_pair[3]), .CI(\add_25/n6 ), 
            .CO(\add_25/n8 )) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(38)
    defparam \add_25/i4 .I0_POLARITY = 1'b1;
    defparam \add_25/i4 .I1_POLARITY = 1'b1;
    EFX_ADD \add_25/i3  (.I0(n304[0]), .I1(in_pair[2]), .CI(\add_25/n4 ), 
            .CO(\add_25/n6 )) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(38)
    defparam \add_25/i3 .I0_POLARITY = 1'b1;
    defparam \add_25/i3 .I1_POLARITY = 1'b1;
    EFX_ADD \add_25/i2  (.I0(n258[0]), .I1(in_pair[1]), .CI(\add_25/n2 ), 
            .CO(\add_25/n4 )) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(38)
    defparam \add_25/i2 .I0_POLARITY = 1'b1;
    defparam \add_25/i2 .I1_POLARITY = 1'b1;
    EFX_ADD \add_24/i14  (.I0(n289[12]), .I1(1'b0), .CI(\add_24/n26 ), 
            .O(n304[13])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(38)
    defparam \add_24/i14 .I0_POLARITY = 1'b1;
    defparam \add_24/i14 .I1_POLARITY = 1'b1;
    EFX_ADD \add_24/i13  (.I0(n289[11]), .I1(1'b0), .CI(\add_24/n24 ), 
            .O(n304[12]), .CO(\add_24/n26 )) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(38)
    defparam \add_24/i13 .I0_POLARITY = 1'b1;
    defparam \add_24/i13 .I1_POLARITY = 1'b1;
    EFX_ADD \add_24/i12  (.I0(n289[10]), .I1(1'b0), .CI(\add_24/n22 ), 
            .O(n304[11]), .CO(\add_24/n24 )) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(38)
    defparam \add_24/i12 .I0_POLARITY = 1'b1;
    defparam \add_24/i12 .I1_POLARITY = 1'b1;
    EFX_ADD \add_24/i11  (.I0(n289[9]), .I1(1'b0), .CI(\add_24/n20 ), 
            .O(n304[10]), .CO(\add_24/n22 )) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(38)
    defparam \add_24/i11 .I0_POLARITY = 1'b1;
    defparam \add_24/i11 .I1_POLARITY = 1'b1;
    EFX_ADD \add_24/i10  (.I0(n289[8]), .I1(1'b0), .CI(\add_24/n18 ), 
            .O(n304[9]), .CO(\add_24/n20 )) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(38)
    defparam \add_24/i10 .I0_POLARITY = 1'b1;
    defparam \add_24/i10 .I1_POLARITY = 1'b1;
    EFX_ADD \add_304/i7  (.I0(n148[14]), .I1(1'b0), .CI(\add_304/n12 ), 
            .O(\next_snapshot.gray [14]), .CO(\add_304/n14 )) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(38)
    defparam \add_304/i7 .I0_POLARITY = 1'b1;
    defparam \add_304/i7 .I1_POLARITY = 1'b1;
    EFX_ADD \add_304/i6  (.I0(n148[13]), .I1(1'b0), .CI(\add_304/n10 ), 
            .O(\next_snapshot.gray [13]), .CO(\add_304/n12 )) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(38)
    defparam \add_304/i6 .I0_POLARITY = 1'b1;
    defparam \add_304/i6 .I1_POLARITY = 1'b1;
    EFX_ADD \add_8/i7  (.I0(n56[4]), .I1(in_pair[38]), .CI(\add_8/n12 ), 
            .O(n70[6]), .CO(\add_8/n14 )) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(37)
    defparam \add_8/i7 .I0_POLARITY = 1'b1;
    defparam \add_8/i7 .I1_POLARITY = 1'b1;
    EFX_ADD \add_8/i6  (.I0(n56[3]), .I1(in_pair[37]), .CI(\add_8/n10 ), 
            .O(n70[5]), .CO(\add_8/n12 )) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(37)
    defparam \add_8/i6 .I0_POLARITY = 1'b1;
    defparam \add_8/i6 .I1_POLARITY = 1'b1;
    EFX_ADD \add_8/i5  (.I0(n56[2]), .I1(in_pair[36]), .CI(\add_8/n8 ), 
            .O(n70[4]), .CO(\add_8/n10 )) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(37)
    defparam \add_8/i5 .I0_POLARITY = 1'b1;
    defparam \add_8/i5 .I1_POLARITY = 1'b1;
    EFX_ADD \add_8/i4  (.I0(n56[1]), .I1(in_pair[35]), .CI(\add_8/n6 ), 
            .O(n70[3]), .CO(\add_8/n8 )) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(37)
    defparam \add_8/i4 .I0_POLARITY = 1'b1;
    defparam \add_8/i4 .I1_POLARITY = 1'b1;
    EFX_ADD \add_8/i3  (.I0(n56[0]), .I1(in_pair[34]), .CI(\add_8/n4 ), 
            .O(n70[2]), .CO(\add_8/n6 )) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(37)
    defparam \add_8/i3 .I0_POLARITY = 1'b1;
    defparam \add_8/i3 .I1_POLARITY = 1'b1;
    EFX_ADD \add_8/i2  (.I0(n29[1]), .I1(in_pair[33]), .CI(\add_8/n2 ), 
            .O(n70[1]), .CO(\add_8/n4 )) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(37)
    defparam \add_8/i2 .I0_POLARITY = 1'b1;
    defparam \add_8/i2 .I1_POLARITY = 1'b1;
    EFX_ADD \add_7/i12  (.I0(n45[8]), .I1(1'b0), .CI(\add_7/n22 ), .O(n56[11])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(37)
    defparam \add_7/i12 .I0_POLARITY = 1'b1;
    defparam \add_7/i12 .I1_POLARITY = 1'b1;
    EFX_ADD \add_7/i11  (.I0(n45[7]), .I1(1'b0), .CI(\add_7/n20 ), .O(n56[10]), 
            .CO(\add_7/n22 )) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(37)
    defparam \add_7/i11 .I0_POLARITY = 1'b1;
    defparam \add_7/i11 .I1_POLARITY = 1'b1;
    EFX_ADD \add_7/i10  (.I0(n45[6]), .I1(1'b0), .CI(\add_7/n18 ), .O(n56[9]), 
            .CO(\add_7/n20 )) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(37)
    defparam \add_7/i10 .I0_POLARITY = 1'b1;
    defparam \add_7/i10 .I1_POLARITY = 1'b1;
    EFX_ADD \add_7/i9  (.I0(n45[5]), .I1(1'b0), .CI(\add_7/n16 ), .O(n56[8]), 
            .CO(\add_7/n18 )) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(37)
    defparam \add_7/i9 .I0_POLARITY = 1'b1;
    defparam \add_7/i9 .I1_POLARITY = 1'b1;
    EFX_ADD \add_7/i8  (.I0(n45[4]), .I1(in_pair[39]), .CI(\add_7/n14 ), 
            .O(n56[7]), .CO(\add_7/n16 )) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(37)
    defparam \add_7/i8 .I0_POLARITY = 1'b1;
    defparam \add_7/i8 .I1_POLARITY = 1'b1;
    EFX_ADD \add_7/i7  (.I0(n45[3]), .I1(in_pair[38]), .CI(\add_7/n12 ), 
            .O(n56[6]), .CO(\add_7/n14 )) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(37)
    defparam \add_7/i7 .I0_POLARITY = 1'b1;
    defparam \add_7/i7 .I1_POLARITY = 1'b1;
    EFX_ADD \add_7/i6  (.I0(n45[2]), .I1(in_pair[37]), .CI(\add_7/n10 ), 
            .O(n56[5]), .CO(\add_7/n12 )) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(37)
    defparam \add_7/i6 .I0_POLARITY = 1'b1;
    defparam \add_7/i6 .I1_POLARITY = 1'b1;
    EFX_ADD \add_7/i5  (.I0(n45[1]), .I1(in_pair[36]), .CI(\add_7/n8 ), 
            .O(n56[4]), .CO(\add_7/n10 )) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(37)
    defparam \add_7/i5 .I0_POLARITY = 1'b1;
    defparam \add_7/i5 .I1_POLARITY = 1'b1;
    EFX_ADD \add_7/i4  (.I0(n45[0]), .I1(in_pair[35]), .CI(\add_7/n6 ), 
            .O(n56[3]), .CO(\add_7/n8 )) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(37)
    defparam \add_7/i4 .I0_POLARITY = 1'b1;
    defparam \add_7/i4 .I1_POLARITY = 1'b1;
    EFX_ADD \add_7/i3  (.I0(n29[4]), .I1(in_pair[34]), .CI(\add_7/n4 ), 
            .O(n56[2]), .CO(\add_7/n6 )) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(37)
    defparam \add_7/i3 .I0_POLARITY = 1'b1;
    defparam \add_7/i3 .I1_POLARITY = 1'b1;
    EFX_ADD \add_7/i2  (.I0(n29[3]), .I1(in_pair[33]), .CI(\add_7/n2 ), 
            .O(n56[1]), .CO(\add_7/n4 )) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(37)
    defparam \add_7/i2 .I0_POLARITY = 1'b1;
    defparam \add_7/i2 .I1_POLARITY = 1'b1;
    EFX_ADD \add_6/i9  (.I0(n29[13]), .I1(1'b0), .CI(\add_6/n16 ), .O(n45[8])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(37)
    defparam \add_6/i9 .I0_POLARITY = 1'b1;
    defparam \add_6/i9 .I1_POLARITY = 1'b1;
    EFX_ADD \add_6/i8  (.I0(n29[12]), .I1(in_pair[39]), .CI(\add_6/n14 ), 
            .O(n45[7]), .CO(\add_6/n16 )) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(37)
    defparam \add_6/i8 .I0_POLARITY = 1'b1;
    defparam \add_6/i8 .I1_POLARITY = 1'b1;
    EFX_ADD \add_6/i7  (.I0(n29[11]), .I1(in_pair[38]), .CI(\add_6/n12 ), 
            .O(n45[6]), .CO(\add_6/n14 )) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(37)
    defparam \add_6/i7 .I0_POLARITY = 1'b1;
    defparam \add_6/i7 .I1_POLARITY = 1'b1;
    EFX_ADD \add_6/i6  (.I0(n29[10]), .I1(in_pair[37]), .CI(\add_6/n10 ), 
            .O(n45[5]), .CO(\add_6/n12 )) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(37)
    defparam \add_6/i6 .I0_POLARITY = 1'b1;
    defparam \add_6/i6 .I1_POLARITY = 1'b1;
    EFX_ADD \add_6/i5  (.I0(n29[9]), .I1(in_pair[36]), .CI(\add_6/n8 ), 
            .O(n45[4]), .CO(\add_6/n10 )) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(37)
    defparam \add_6/i5 .I0_POLARITY = 1'b1;
    defparam \add_6/i5 .I1_POLARITY = 1'b1;
    EFX_ADD \add_6/i4  (.I0(n29[8]), .I1(in_pair[35]), .CI(\add_6/n6 ), 
            .O(n45[3]), .CO(\add_6/n8 )) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(37)
    defparam \add_6/i4 .I0_POLARITY = 1'b1;
    defparam \add_6/i4 .I1_POLARITY = 1'b1;
    EFX_ADD \add_6/i3  (.I0(n29[7]), .I1(in_pair[34]), .CI(\add_6/n4 ), 
            .O(n45[2]), .CO(\add_6/n6 )) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(37)
    defparam \add_6/i3 .I0_POLARITY = 1'b1;
    defparam \add_6/i3 .I1_POLARITY = 1'b1;
    EFX_ADD \add_6/i2  (.I0(n29[6]), .I1(in_pair[33]), .CI(\add_6/n2 ), 
            .O(n45[1]), .CO(\add_6/n4 )) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(37)
    defparam \add_6/i2 .I0_POLARITY = 1'b1;
    defparam \add_6/i2 .I1_POLARITY = 1'b1;
    EFX_ADD \add_5/i14  (.I0(n14), .I1(1'b0), .CI(\add_5/n26 ), .O(n29[13])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(36)
    defparam \add_5/i14 .I0_POLARITY = 1'b1;
    defparam \add_5/i14 .I1_POLARITY = 1'b1;
    EFX_ADD \add_5/i13  (.I0(n15[11]), .I1(1'b0), .CI(\add_5/n24 ), .O(n29[12]), 
            .CO(\add_5/n26 )) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(36)
    defparam \add_5/i13 .I0_POLARITY = 1'b1;
    defparam \add_5/i13 .I1_POLARITY = 1'b1;
    EFX_ADD \add_5/i12  (.I0(n15[10]), .I1(1'b0), .CI(\add_5/n22 ), .O(n29[11]), 
            .CO(\add_5/n24 )) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(36)
    defparam \add_5/i12 .I0_POLARITY = 1'b1;
    defparam \add_5/i12 .I1_POLARITY = 1'b1;
    EFX_ADD \add_16/i6  (.I0(n177[2]), .I1(in_pair[22]), .CI(\add_16/n10 ), 
            .O(n187[5]), .CO(\add_16/n12 )) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(36)
    defparam \add_16/i6 .I0_POLARITY = 1'b1;
    defparam \add_16/i6 .I1_POLARITY = 1'b1;
    EFX_ADD \add_16/i5  (.I0(n177[1]), .I1(in_pair[21]), .CI(\add_16/n8 ), 
            .O(n187[4]), .CO(\add_16/n10 )) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(36)
    defparam \add_16/i5 .I0_POLARITY = 1'b1;
    defparam \add_16/i5 .I1_POLARITY = 1'b1;
    EFX_ADD \add_16/i4  (.I0(n177[0]), .I1(in_pair[20]), .CI(\add_16/n6 ), 
            .O(n187[3]), .CO(\add_16/n8 )) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(36)
    defparam \add_16/i4 .I0_POLARITY = 1'b1;
    defparam \add_16/i4 .I1_POLARITY = 1'b1;
    EFX_ADD \add_16/i3  (.I0(in_pair[18]), .I1(in_pair[19]), .CI(\add_16/n4 ), 
            .O(n187[2]), .CO(\add_16/n6 )) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(36)
    defparam \add_16/i3 .I0_POLARITY = 1'b1;
    defparam \add_16/i3 .I1_POLARITY = 1'b1;
    EFX_ADD \add_16/i2  (.I0(in_pair[17]), .I1(in_pair[18]), .CI(\add_16/n2 ), 
            .O(n187[1]), .CO(\add_16/n4 )) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(36)
    defparam \add_16/i2 .I0_POLARITY = 1'b1;
    defparam \add_16/i2 .I1_POLARITY = 1'b1;
    EFX_ADD \add_15/i8  (.I0(in_pair[23]), .I1(1'b0), .CI(\add_15/n14 ), 
            .O(n177[7]), .CO(n1603)) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(36)
    defparam \add_15/i8 .I0_POLARITY = 1'b1;
    defparam \add_15/i8 .I1_POLARITY = 1'b1;
    EFX_ADD \add_15/i7  (.I0(in_pair[22]), .I1(1'b0), .CI(\add_15/n12 ), 
            .O(n177[6]), .CO(\add_15/n14 )) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(36)
    defparam \add_15/i7 .I0_POLARITY = 1'b1;
    defparam \add_15/i7 .I1_POLARITY = 1'b1;
    EFX_ADD \add_15/i6  (.I0(in_pair[21]), .I1(1'b0), .CI(\add_15/n10 ), 
            .O(n177[5]), .CO(\add_15/n12 )) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(36)
    defparam \add_15/i6 .I0_POLARITY = 1'b1;
    defparam \add_15/i6 .I1_POLARITY = 1'b1;
    EFX_ADD \add_15/i5  (.I0(in_pair[20]), .I1(in_pair[23]), .CI(\add_15/n8 ), 
            .O(n177[4]), .CO(\add_15/n10 )) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(36)
    defparam \add_15/i5 .I0_POLARITY = 1'b1;
    defparam \add_15/i5 .I1_POLARITY = 1'b1;
    EFX_ADD \add_15/i4  (.I0(in_pair[19]), .I1(in_pair[22]), .CI(\add_15/n6 ), 
            .O(n177[3]), .CO(\add_15/n8 )) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(36)
    defparam \add_15/i4 .I0_POLARITY = 1'b1;
    defparam \add_15/i4 .I1_POLARITY = 1'b1;
    EFX_ADD \add_15/i3  (.I0(in_pair[18]), .I1(in_pair[21]), .CI(\add_15/n4 ), 
            .O(n177[2]), .CO(\add_15/n6 )) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(36)
    defparam \add_15/i3 .I0_POLARITY = 1'b1;
    defparam \add_15/i3 .I1_POLARITY = 1'b1;
    EFX_ADD \add_15/i2  (.I0(in_pair[17]), .I1(in_pair[20]), .CI(\add_15/n2 ), 
            .O(n177[1]), .CO(\add_15/n4 )) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(36)
    defparam \add_15/i2 .I0_POLARITY = 1'b1;
    defparam \add_15/i2 .I1_POLARITY = 1'b1;
    EFX_ADD \add_305/i8  (.I0(n320[15]), .I1(1'b0), .CI(\add_305/n14 ), 
            .O(\next_snapshot.gray [7])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(38)
    defparam \add_305/i8 .I0_POLARITY = 1'b1;
    defparam \add_305/i8 .I1_POLARITY = 1'b1;
    EFX_ADD \add_305/i7  (.I0(n320[14]), .I1(1'b0), .CI(\add_305/n12 ), 
            .O(\next_snapshot.gray [6]), .CO(\add_305/n14 )) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(38)
    defparam \add_305/i7 .I0_POLARITY = 1'b1;
    defparam \add_305/i7 .I1_POLARITY = 1'b1;
    EFX_ADD \add_305/i6  (.I0(n320[13]), .I1(1'b0), .CI(\add_305/n10 ), 
            .O(\next_snapshot.gray [5]), .CO(\add_305/n12 )) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(38)
    defparam \add_305/i6 .I0_POLARITY = 1'b1;
    defparam \add_305/i6 .I1_POLARITY = 1'b1;
    EFX_ADD \add_305/i5  (.I0(n320[12]), .I1(1'b0), .CI(\add_305/n8 ), 
            .O(\next_snapshot.gray [4]), .CO(\add_305/n10 )) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(38)
    defparam \add_305/i5 .I0_POLARITY = 1'b1;
    defparam \add_305/i5 .I1_POLARITY = 1'b1;
    EFX_ADD \add_305/i4  (.I0(n320[11]), .I1(1'b0), .CI(\add_305/n6 ), 
            .O(\next_snapshot.gray [3]), .CO(\add_305/n8 )) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(38)
    defparam \add_305/i4 .I0_POLARITY = 1'b1;
    defparam \add_305/i4 .I1_POLARITY = 1'b1;
    EFX_ADD \add_305/i3  (.I0(n320[10]), .I1(1'b0), .CI(\add_305/n4 ), 
            .O(\next_snapshot.gray [2]), .CO(\add_305/n6 )) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(38)
    defparam \add_305/i3 .I0_POLARITY = 1'b1;
    defparam \add_305/i3 .I1_POLARITY = 1'b1;
    EFX_ADD \add_305/i2  (.I0(n320[9]), .I1(1'b0), .CI(\add_305/n2 ), 
            .O(\next_snapshot.gray [1]), .CO(\add_305/n4 )) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(38)
    defparam \add_305/i2 .I0_POLARITY = 1'b1;
    defparam \add_305/i2 .I1_POLARITY = 1'b1;
    EFX_ADD \add_13/i16  (.I0(n132[13]), .I1(1'b0), .CI(\add_13/n30 ), 
            .O(n148[15])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(38)
    defparam \add_13/i16 .I0_POLARITY = 1'b1;
    defparam \add_13/i16 .I1_POLARITY = 1'b1;
    EFX_ADD \add_13/i15  (.I0(n132[12]), .I1(1'b0), .CI(\add_13/n28 ), 
            .O(n148[14]), .CO(\add_13/n30 )) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(38)
    defparam \add_13/i15 .I0_POLARITY = 1'b1;
    defparam \add_13/i15 .I1_POLARITY = 1'b1;
    EFX_ADD \add_13/i14  (.I0(n132[11]), .I1(1'b0), .CI(\add_13/n26 ), 
            .O(n148[13]), .CO(\add_13/n28 )) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(38)
    defparam \add_13/i14 .I0_POLARITY = 1'b1;
    defparam \add_13/i14 .I1_POLARITY = 1'b1;
    EFX_ADD \add_13/i13  (.I0(n132[10]), .I1(1'b0), .CI(\add_13/n24 ), 
            .O(n148[12]), .CO(\add_13/n26 )) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(38)
    defparam \add_13/i13 .I0_POLARITY = 1'b1;
    defparam \add_13/i13 .I1_POLARITY = 1'b1;
    EFX_ADD \add_13/i12  (.I0(n132[9]), .I1(1'b0), .CI(\add_13/n22 ), 
            .O(n148[11]), .CO(\add_13/n24 )) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(38)
    defparam \add_13/i12 .I0_POLARITY = 1'b1;
    defparam \add_13/i12 .I1_POLARITY = 1'b1;
    EFX_ADD \add_13/i11  (.I0(n132[8]), .I1(1'b0), .CI(\add_13/n20 ), 
            .O(n148[10]), .CO(\add_13/n22 )) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(38)
    defparam \add_13/i11 .I0_POLARITY = 1'b1;
    defparam \add_13/i11 .I1_POLARITY = 1'b1;
    EFX_ADD \add_13/i10  (.I0(n132[7]), .I1(1'b0), .CI(\add_13/n18 ), 
            .O(n148[9]), .CO(\add_13/n20 )) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(38)
    defparam \add_13/i10 .I0_POLARITY = 1'b1;
    defparam \add_13/i10 .I1_POLARITY = 1'b1;
    EFX_ADD \add_13/i9  (.I0(n132[6]), .I1(1'b0), .CI(\add_13/n16 ), .O(n148[8]), 
            .CO(\add_13/n18 )) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(38)
    defparam \add_13/i9 .I0_POLARITY = 1'b1;
    defparam \add_13/i9 .I1_POLARITY = 1'b1;
    EFX_ADD \add_13/i8  (.I0(n132[5]), .I1(in_pair[31]), .CI(\add_13/n14 ), 
            .O(n148[7]), .CO(\add_13/n16 )) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(38)
    defparam \add_13/i8 .I0_POLARITY = 1'b1;
    defparam \add_13/i8 .I1_POLARITY = 1'b1;
    EFX_ADD \add_13/i7  (.I0(n132[4]), .I1(in_pair[30]), .CI(\add_13/n12 ), 
            .CO(\add_13/n14 )) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(38)
    defparam \add_13/i7 .I0_POLARITY = 1'b1;
    defparam \add_13/i7 .I1_POLARITY = 1'b1;
    EFX_ADD \add_13/i6  (.I0(n132[3]), .I1(in_pair[29]), .CI(\add_13/n10 ), 
            .CO(\add_13/n12 )) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(38)
    defparam \add_13/i6 .I0_POLARITY = 1'b1;
    defparam \add_13/i6 .I1_POLARITY = 1'b1;
    EFX_ADD \add_13/i5  (.I0(n132[2]), .I1(in_pair[28]), .CI(\add_13/n8 ), 
            .CO(\add_13/n10 )) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(38)
    defparam \add_13/i5 .I0_POLARITY = 1'b1;
    defparam \add_13/i5 .I1_POLARITY = 1'b1;
    EFX_ADD \add_13/i4  (.I0(n132[1]), .I1(in_pair[27]), .CI(\add_13/n6 ), 
            .CO(\add_13/n8 )) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(38)
    defparam \add_13/i4 .I0_POLARITY = 1'b1;
    defparam \add_13/i4 .I1_POLARITY = 1'b1;
    EFX_ADD \add_13/i3  (.I0(n132[0]), .I1(in_pair[26]), .CI(\add_13/n4 ), 
            .CO(\add_13/n6 )) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(38)
    defparam \add_13/i3 .I0_POLARITY = 1'b1;
    defparam \add_13/i3 .I1_POLARITY = 1'b1;
    EFX_ADD \add_13/i2  (.I0(n86[0]), .I1(in_pair[25]), .CI(\add_13/n2 ), 
            .CO(\add_13/n4 )) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(38)
    defparam \add_13/i2 .I0_POLARITY = 1'b1;
    defparam \add_13/i2 .I1_POLARITY = 1'b1;
    EFX_ADD \add_12/i14  (.I0(n117[12]), .I1(1'b0), .CI(\add_12/n26 ), 
            .O(n132[13])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(38)
    defparam \add_12/i14 .I0_POLARITY = 1'b1;
    defparam \add_12/i14 .I1_POLARITY = 1'b1;
    EFX_ADD \add_12/i13  (.I0(n117[11]), .I1(1'b0), .CI(\add_12/n24 ), 
            .O(n132[12]), .CO(\add_12/n26 )) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(38)
    defparam \add_12/i13 .I0_POLARITY = 1'b1;
    defparam \add_12/i13 .I1_POLARITY = 1'b1;
    EFX_ADD \add_12/i12  (.I0(n117[10]), .I1(1'b0), .CI(\add_12/n22 ), 
            .O(n132[11]), .CO(\add_12/n24 )) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(38)
    defparam \add_12/i12 .I0_POLARITY = 1'b1;
    defparam \add_12/i12 .I1_POLARITY = 1'b1;
    EFX_ADD \add_12/i11  (.I0(n117[9]), .I1(1'b0), .CI(\add_12/n20 ), 
            .O(n132[10]), .CO(\add_12/n22 )) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(38)
    defparam \add_12/i11 .I0_POLARITY = 1'b1;
    defparam \add_12/i11 .I1_POLARITY = 1'b1;
    EFX_ADD \add_12/i10  (.I0(n117[8]), .I1(1'b0), .CI(\add_12/n18 ), 
            .O(n132[9]), .CO(\add_12/n20 )) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(38)
    defparam \add_12/i10 .I0_POLARITY = 1'b1;
    defparam \add_12/i10 .I1_POLARITY = 1'b1;
    EFX_ADD \add_12/i9  (.I0(n117[7]), .I1(1'b0), .CI(\add_12/n16 ), .O(n132[8]), 
            .CO(\add_12/n18 )) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(38)
    defparam \add_12/i9 .I0_POLARITY = 1'b1;
    defparam \add_12/i9 .I1_POLARITY = 1'b1;
    EFX_ADD \add_12/i8  (.I0(n117[6]), .I1(in_pair[31]), .CI(\add_12/n14 ), 
            .O(n132[7]), .CO(\add_12/n16 )) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(38)
    defparam \add_12/i8 .I0_POLARITY = 1'b1;
    defparam \add_12/i8 .I1_POLARITY = 1'b1;
    EFX_ADD \add_12/i7  (.I0(n117[5]), .I1(in_pair[30]), .CI(\add_12/n12 ), 
            .O(n132[6]), .CO(\add_12/n14 )) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(38)
    defparam \add_12/i7 .I0_POLARITY = 1'b1;
    defparam \add_12/i7 .I1_POLARITY = 1'b1;
    EFX_ADD \add_12/i6  (.I0(n117[4]), .I1(in_pair[29]), .CI(\add_12/n10 ), 
            .O(n132[5]), .CO(\add_12/n12 )) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(38)
    defparam \add_12/i6 .I0_POLARITY = 1'b1;
    defparam \add_12/i6 .I1_POLARITY = 1'b1;
    EFX_ADD \add_9/i8  (.I0(n70[6]), .I1(in_pair[39]), .CI(\add_9/n14 ), 
            .O(n86[7]), .CO(\add_9/n16 )) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(37)
    defparam \add_9/i8 .I0_POLARITY = 1'b1;
    defparam \add_9/i8 .I1_POLARITY = 1'b1;
    EFX_ADD \add_10/i10  (.I0(n86[12]), .I1(1'b0), .CI(\add_10/n18 ), 
            .O(n103[9]), .CO(\add_10/n20 )) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(38)
    defparam \add_10/i10 .I0_POLARITY = 1'b1;
    defparam \add_10/i10 .I1_POLARITY = 1'b1;
    EFX_ADD \add_10/i9  (.I0(n86[11]), .I1(1'b0), .CI(\add_10/n16 ), .O(n103[8]), 
            .CO(\add_10/n18 )) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(38)
    defparam \add_10/i9 .I0_POLARITY = 1'b1;
    defparam \add_10/i9 .I1_POLARITY = 1'b1;
    EFX_ADD \add_10/i8  (.I0(n86[10]), .I1(in_pair[31]), .CI(\add_10/n14 ), 
            .O(n103[7]), .CO(\add_10/n16 )) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(38)
    defparam \add_10/i8 .I0_POLARITY = 1'b1;
    defparam \add_10/i8 .I1_POLARITY = 1'b1;
    EFX_ADD \add_10/i7  (.I0(n86[9]), .I1(in_pair[30]), .CI(\add_10/n12 ), 
            .O(n103[6]), .CO(\add_10/n14 )) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(38)
    defparam \add_10/i7 .I0_POLARITY = 1'b1;
    defparam \add_10/i7 .I1_POLARITY = 1'b1;
    EFX_ADD \add_10/i6  (.I0(n86[8]), .I1(in_pair[29]), .CI(\add_10/n10 ), 
            .O(n103[5]), .CO(\add_10/n12 )) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(38)
    defparam \add_10/i6 .I0_POLARITY = 1'b1;
    defparam \add_10/i6 .I1_POLARITY = 1'b1;
    EFX_ADD \add_10/i5  (.I0(n86[7]), .I1(in_pair[28]), .CI(\add_10/n8 ), 
            .O(n103[4]), .CO(\add_10/n10 )) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(38)
    defparam \add_10/i5 .I0_POLARITY = 1'b1;
    defparam \add_10/i5 .I1_POLARITY = 1'b1;
    EFX_ADD \add_9/i7  (.I0(n70[5]), .I1(in_pair[38]), .CI(\add_9/n12 ), 
            .O(n86[6]), .CO(\add_9/n14 )) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(37)
    defparam \add_9/i7 .I0_POLARITY = 1'b1;
    defparam \add_9/i7 .I1_POLARITY = 1'b1;
    EFX_ADD \add_10/i4  (.I0(n86[6]), .I1(in_pair[27]), .CI(\add_10/n6 ), 
            .O(n103[3]), .CO(\add_10/n8 )) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(38)
    defparam \add_10/i4 .I0_POLARITY = 1'b1;
    defparam \add_10/i4 .I1_POLARITY = 1'b1;
    EFX_ADD \add_9/i6  (.I0(n70[4]), .I1(in_pair[37]), .CI(\add_9/n10 ), 
            .O(n86[5]), .CO(\add_9/n12 )) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(37)
    defparam \add_9/i6 .I0_POLARITY = 1'b1;
    defparam \add_9/i6 .I1_POLARITY = 1'b1;
    EFX_ADD \add_10/i3  (.I0(n86[5]), .I1(in_pair[26]), .CI(\add_10/n4 ), 
            .O(n103[2]), .CO(\add_10/n6 )) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(38)
    defparam \add_10/i3 .I0_POLARITY = 1'b1;
    defparam \add_10/i3 .I1_POLARITY = 1'b1;
    EFX_ADD \add_9/i5  (.I0(n70[3]), .I1(in_pair[36]), .CI(\add_9/n8 ), 
            .O(n86[4]), .CO(\add_9/n10 )) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(37)
    defparam \add_9/i5 .I0_POLARITY = 1'b1;
    defparam \add_9/i5 .I1_POLARITY = 1'b1;
    EFX_ADD \add_9/i4  (.I0(n70[2]), .I1(in_pair[35]), .CI(\add_9/n6 ), 
            .O(n86[3]), .CO(\add_9/n8 )) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(37)
    defparam \add_9/i4 .I0_POLARITY = 1'b1;
    defparam \add_9/i4 .I1_POLARITY = 1'b1;
    EFX_ADD \add_10/i2  (.I0(n86[4]), .I1(in_pair[25]), .CI(\add_10/n2 ), 
            .O(n103[1]), .CO(\add_10/n4 )) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(38)
    defparam \add_10/i2 .I0_POLARITY = 1'b1;
    defparam \add_10/i2 .I1_POLARITY = 1'b1;
    EFX_ADD \add_9/i3  (.I0(n70[1]), .I1(in_pair[34]), .CI(\add_9/n4 ), 
            .O(n86[2]), .CO(\add_9/n6 )) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(37)
    defparam \add_9/i3 .I0_POLARITY = 1'b1;
    defparam \add_9/i3 .I1_POLARITY = 1'b1;
    EFX_ADD \add_9/i15  (.I0(n70[13]), .I1(1'b0), .CI(\add_9/n28 ), .O(n86[14])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(37)
    defparam \add_9/i15 .I0_POLARITY = 1'b1;
    defparam \add_9/i15 .I1_POLARITY = 1'b1;
    EFX_ADD \add_9/i2  (.I0(n70[0]), .I1(in_pair[33]), .CI(\add_9/n2 ), 
            .O(n86[1]), .CO(\add_9/n4 )) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(37)
    defparam \add_9/i2 .I0_POLARITY = 1'b1;
    defparam \add_9/i2 .I1_POLARITY = 1'b1;
    EFX_ADD \add_9/i14  (.I0(n70[12]), .I1(1'b0), .CI(\add_9/n26 ), .O(n86[13]), 
            .CO(\add_9/n28 )) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(37)
    defparam \add_9/i14 .I0_POLARITY = 1'b1;
    defparam \add_9/i14 .I1_POLARITY = 1'b1;
    EFX_ADD \add_8/i14  (.I0(n56[11]), .I1(1'b0), .CI(\add_8/n26 ), .O(n70[13])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(37)
    defparam \add_8/i14 .I0_POLARITY = 1'b1;
    defparam \add_8/i14 .I1_POLARITY = 1'b1;
    EFX_ADD \add_8/i13  (.I0(n56[10]), .I1(1'b0), .CI(\add_8/n24 ), .O(n70[12]), 
            .CO(\add_8/n26 )) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(37)
    defparam \add_8/i13 .I0_POLARITY = 1'b1;
    defparam \add_8/i13 .I1_POLARITY = 1'b1;
    EFX_ADD \add_9/i13  (.I0(n70[11]), .I1(1'b0), .CI(\add_9/n24 ), .O(n86[12]), 
            .CO(\add_9/n26 )) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(37)
    defparam \add_9/i13 .I0_POLARITY = 1'b1;
    defparam \add_9/i13 .I1_POLARITY = 1'b1;
    EFX_ADD \add_12/i5  (.I0(n117[3]), .I1(in_pair[28]), .CI(\add_12/n8 ), 
            .O(n132[4]), .CO(\add_12/n10 )) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(38)
    defparam \add_12/i5 .I0_POLARITY = 1'b1;
    defparam \add_12/i5 .I1_POLARITY = 1'b1;
    EFX_ADD \add_12/i4  (.I0(n117[2]), .I1(in_pair[27]), .CI(\add_12/n6 ), 
            .O(n132[3]), .CO(\add_12/n8 )) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(38)
    defparam \add_12/i4 .I0_POLARITY = 1'b1;
    defparam \add_12/i4 .I1_POLARITY = 1'b1;
    EFX_ADD \add_12/i3  (.I0(n117[1]), .I1(in_pair[26]), .CI(\add_12/n4 ), 
            .O(n132[2]), .CO(\add_12/n6 )) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(38)
    defparam \add_12/i3 .I0_POLARITY = 1'b1;
    defparam \add_12/i3 .I1_POLARITY = 1'b1;
    EFX_ADD \add_12/i2  (.I0(n117[0]), .I1(in_pair[25]), .CI(\add_12/n2 ), 
            .O(n132[1]), .CO(\add_12/n4 )) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(38)
    defparam \add_12/i2 .I0_POLARITY = 1'b1;
    defparam \add_12/i2 .I1_POLARITY = 1'b1;
    EFX_ADD \add_11/i13  (.I0(n103[11]), .I1(1'b0), .CI(\add_11/n24 ), 
            .O(n117[12])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(38)
    defparam \add_11/i13 .I0_POLARITY = 1'b1;
    defparam \add_11/i13 .I1_POLARITY = 1'b1;
    EFX_ADD \add_11/i12  (.I0(n103[10]), .I1(1'b0), .CI(\add_11/n22 ), 
            .O(n117[11]), .CO(\add_11/n24 )) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(38)
    defparam \add_11/i12 .I0_POLARITY = 1'b1;
    defparam \add_11/i12 .I1_POLARITY = 1'b1;
    EFX_ADD \add_11/i11  (.I0(n103[9]), .I1(1'b0), .CI(\add_11/n20 ), 
            .O(n117[10]), .CO(\add_11/n22 )) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(38)
    defparam \add_11/i11 .I0_POLARITY = 1'b1;
    defparam \add_11/i11 .I1_POLARITY = 1'b1;
    EFX_ADD \add_11/i10  (.I0(n103[8]), .I1(1'b0), .CI(\add_11/n18 ), 
            .O(n117[9]), .CO(\add_11/n20 )) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(38)
    defparam \add_11/i10 .I0_POLARITY = 1'b1;
    defparam \add_11/i10 .I1_POLARITY = 1'b1;
    EFX_ADD \add_11/i9  (.I0(n103[7]), .I1(1'b0), .CI(\add_11/n16 ), .O(n117[8]), 
            .CO(\add_11/n18 )) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(38)
    defparam \add_11/i9 .I0_POLARITY = 1'b1;
    defparam \add_11/i9 .I1_POLARITY = 1'b1;
    EFX_ADD \add_11/i8  (.I0(n103[6]), .I1(in_pair[31]), .CI(\add_11/n14 ), 
            .O(n117[7]), .CO(\add_11/n16 )) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(38)
    defparam \add_11/i8 .I0_POLARITY = 1'b1;
    defparam \add_11/i8 .I1_POLARITY = 1'b1;
    EFX_ADD \add_11/i7  (.I0(n103[5]), .I1(in_pair[30]), .CI(\add_11/n12 ), 
            .O(n117[6]), .CO(\add_11/n14 )) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(38)
    defparam \add_11/i7 .I0_POLARITY = 1'b1;
    defparam \add_11/i7 .I1_POLARITY = 1'b1;
    EFX_ADD \add_11/i6  (.I0(n103[4]), .I1(in_pair[29]), .CI(\add_11/n10 ), 
            .O(n117[5]), .CO(\add_11/n12 )) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(38)
    defparam \add_11/i6 .I0_POLARITY = 1'b1;
    defparam \add_11/i6 .I1_POLARITY = 1'b1;
    EFX_ADD \add_11/i5  (.I0(n103[3]), .I1(in_pair[28]), .CI(\add_11/n8 ), 
            .O(n117[4]), .CO(\add_11/n10 )) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(38)
    defparam \add_11/i5 .I0_POLARITY = 1'b1;
    defparam \add_11/i5 .I1_POLARITY = 1'b1;
    EFX_ADD \add_11/i4  (.I0(n103[2]), .I1(in_pair[27]), .CI(\add_11/n6 ), 
            .O(n117[3]), .CO(\add_11/n8 )) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(38)
    defparam \add_11/i4 .I0_POLARITY = 1'b1;
    defparam \add_11/i4 .I1_POLARITY = 1'b1;
    EFX_ADD \add_11/i3  (.I0(n103[1]), .I1(in_pair[26]), .CI(\add_11/n4 ), 
            .O(n117[2]), .CO(\add_11/n6 )) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(38)
    defparam \add_11/i3 .I0_POLARITY = 1'b1;
    defparam \add_11/i3 .I1_POLARITY = 1'b1;
    EFX_ADD \add_11/i2  (.I0(n103[0]), .I1(in_pair[25]), .CI(\add_11/n2 ), 
            .O(n117[1]), .CO(\add_11/n4 )) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(38)
    defparam \add_11/i2 .I0_POLARITY = 1'b1;
    defparam \add_11/i2 .I1_POLARITY = 1'b1;
    EFX_ADD \add_10/i12  (.I0(n86[14]), .I1(1'b0), .CI(\add_10/n22 ), 
            .O(n103[11])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(38)
    defparam \add_10/i12 .I0_POLARITY = 1'b1;
    defparam \add_10/i12 .I1_POLARITY = 1'b1;
    EFX_ADD \add_9/i12  (.I0(n70[10]), .I1(1'b0), .CI(\add_9/n22 ), .O(n86[11]), 
            .CO(\add_9/n24 )) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(37)
    defparam \add_9/i12 .I0_POLARITY = 1'b1;
    defparam \add_9/i12 .I1_POLARITY = 1'b1;
    EFX_ADD \add_8/i12  (.I0(n56[9]), .I1(1'b0), .CI(\add_8/n22 ), .O(n70[11]), 
            .CO(\add_8/n24 )) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(37)
    defparam \add_8/i12 .I0_POLARITY = 1'b1;
    defparam \add_8/i12 .I1_POLARITY = 1'b1;
    EFX_ADD \add_9/i11  (.I0(n70[9]), .I1(1'b0), .CI(\add_9/n20 ), .O(n86[10]), 
            .CO(\add_9/n22 )) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(37)
    defparam \add_9/i11 .I0_POLARITY = 1'b1;
    defparam \add_9/i11 .I1_POLARITY = 1'b1;
    EFX_ADD \add_8/i11  (.I0(n56[8]), .I1(1'b0), .CI(\add_8/n20 ), .O(n70[10]), 
            .CO(\add_8/n22 )) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(37)
    defparam \add_8/i11 .I0_POLARITY = 1'b1;
    defparam \add_8/i11 .I1_POLARITY = 1'b1;
    EFX_ADD \add_9/i10  (.I0(n70[8]), .I1(1'b0), .CI(\add_9/n18 ), .O(n86[9]), 
            .CO(\add_9/n20 )) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(37)
    defparam \add_9/i10 .I0_POLARITY = 1'b1;
    defparam \add_9/i10 .I1_POLARITY = 1'b1;
    EFX_ADD \add_8/i10  (.I0(n56[7]), .I1(1'b0), .CI(\add_8/n18 ), .O(n70[9]), 
            .CO(\add_8/n20 )) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(37)
    defparam \add_8/i10 .I0_POLARITY = 1'b1;
    defparam \add_8/i10 .I1_POLARITY = 1'b1;
    EFX_ADD \add_9/i9  (.I0(n70[7]), .I1(1'b0), .CI(\add_9/n16 ), .O(n86[8]), 
            .CO(\add_9/n18 )) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(37)
    defparam \add_9/i9 .I0_POLARITY = 1'b1;
    defparam \add_9/i9 .I1_POLARITY = 1'b1;
    EFX_ADD \add_5/i11  (.I0(n15[9]), .I1(1'b0), .CI(\add_5/n20 ), .O(n29[10]), 
            .CO(\add_5/n22 )) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(36)
    defparam \add_5/i11 .I0_POLARITY = 1'b1;
    defparam \add_5/i11 .I1_POLARITY = 1'b1;
    EFX_ADD \add_5/i10  (.I0(n15[8]), .I1(1'b0), .CI(\add_5/n18 ), .O(n29[9]), 
            .CO(\add_5/n20 )) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(36)
    defparam \add_5/i10 .I0_POLARITY = 1'b1;
    defparam \add_5/i10 .I1_POLARITY = 1'b1;
    EFX_ADD \add_5/i9  (.I0(n15[7]), .I1(1'b0), .CI(\add_5/n16 ), .O(n29[8]), 
            .CO(\add_5/n18 )) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(36)
    defparam \add_5/i9 .I0_POLARITY = 1'b1;
    defparam \add_5/i9 .I1_POLARITY = 1'b1;
    EFX_ADD \add_5/i8  (.I0(n15[6]), .I1(1'b0), .CI(\add_5/n14 ), .O(n29[7]), 
            .CO(\add_5/n16 )) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(36)
    defparam \add_5/i8 .I0_POLARITY = 1'b1;
    defparam \add_5/i8 .I1_POLARITY = 1'b1;
    EFX_ADD \add_5/i7  (.I0(n15[5]), .I1(1'b0), .CI(\add_5/n12 ), .O(n29[6]), 
            .CO(\add_5/n14 )) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(36)
    defparam \add_5/i7 .I0_POLARITY = 1'b1;
    defparam \add_5/i7 .I1_POLARITY = 1'b1;
    EFX_ADD \add_5/i6  (.I0(n15[4]), .I1(in_pair[47]), .CI(\add_5/n10 ), 
            .O(n29[5]), .CO(\add_5/n12 )) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(36)
    defparam \add_5/i6 .I0_POLARITY = 1'b1;
    defparam \add_5/i6 .I1_POLARITY = 1'b1;
    EFX_ADD \add_5/i5  (.I0(n15[3]), .I1(in_pair[46]), .CI(\add_5/n8 ), 
            .O(n29[4]), .CO(\add_5/n10 )) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(36)
    defparam \add_5/i5 .I0_POLARITY = 1'b1;
    defparam \add_5/i5 .I1_POLARITY = 1'b1;
    EFX_ADD \add_5/i4  (.I0(n15[2]), .I1(in_pair[45]), .CI(\add_5/n6 ), 
            .O(n29[3]), .CO(\add_5/n8 )) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(36)
    defparam \add_5/i4 .I0_POLARITY = 1'b1;
    defparam \add_5/i4 .I1_POLARITY = 1'b1;
    EFX_ADD \add_5/i3  (.I0(n15[1]), .I1(in_pair[44]), .CI(\add_5/n4 ), 
            .O(n29[2]), .CO(\add_5/n6 )) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(36)
    defparam \add_5/i3 .I0_POLARITY = 1'b1;
    defparam \add_5/i3 .I1_POLARITY = 1'b1;
    EFX_ADD \add_5/i2  (.I0(n15[0]), .I1(in_pair[43]), .CI(\add_5/n2 ), 
            .O(n29[1]), .CO(\add_5/n4 )) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(36)
    defparam \add_5/i2 .I0_POLARITY = 1'b1;
    defparam \add_5/i2 .I1_POLARITY = 1'b1;
    EFX_ADD \add_4/i12  (.I0(n4), .I1(1'b0), .CI(\add_4/n22 ), .O(n15[11]), 
            .CO(n1604)) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(36)
    defparam \add_4/i12 .I0_POLARITY = 1'b1;
    defparam \add_4/i12 .I1_POLARITY = 1'b1;
    EFX_ADD \add_4/i11  (.I0(n5[7]), .I1(1'b0), .CI(\add_4/n20 ), .O(n15[10]), 
            .CO(\add_4/n22 )) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(36)
    defparam \add_4/i11 .I0_POLARITY = 1'b1;
    defparam \add_4/i11 .I1_POLARITY = 1'b1;
    EFX_ADD \add_4/i10  (.I0(n5[6]), .I1(1'b0), .CI(\add_4/n18 ), .O(n15[9]), 
            .CO(\add_4/n20 )) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(36)
    defparam \add_4/i10 .I0_POLARITY = 1'b1;
    defparam \add_4/i10 .I1_POLARITY = 1'b1;
    EFX_ADD \add_4/i9  (.I0(n5[5]), .I1(1'b0), .CI(\add_4/n16 ), .O(n15[8]), 
            .CO(\add_4/n18 )) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(36)
    defparam \add_4/i9 .I0_POLARITY = 1'b1;
    defparam \add_4/i9 .I1_POLARITY = 1'b1;
    EFX_ADD \add_4/i8  (.I0(n5[4]), .I1(1'b0), .CI(\add_4/n14 ), .O(n15[7]), 
            .CO(\add_4/n16 )) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(36)
    defparam \add_4/i8 .I0_POLARITY = 1'b1;
    defparam \add_4/i8 .I1_POLARITY = 1'b1;
    EFX_ADD \add_4/i7  (.I0(n5[3]), .I1(in_pair[47]), .CI(\add_4/n12 ), 
            .O(n15[6]), .CO(\add_4/n14 )) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(36)
    defparam \add_4/i7 .I0_POLARITY = 1'b1;
    defparam \add_4/i7 .I1_POLARITY = 1'b1;
    EFX_ADD \add_4/i6  (.I0(n5[2]), .I1(in_pair[46]), .CI(\add_4/n10 ), 
            .O(n15[5]), .CO(\add_4/n12 )) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(36)
    defparam \add_4/i6 .I0_POLARITY = 1'b1;
    defparam \add_4/i6 .I1_POLARITY = 1'b1;
    EFX_ADD \add_4/i5  (.I0(n5[1]), .I1(in_pair[45]), .CI(\add_4/n8 ), 
            .O(n15[4]), .CO(\add_4/n10 )) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(36)
    defparam \add_4/i5 .I0_POLARITY = 1'b1;
    defparam \add_4/i5 .I1_POLARITY = 1'b1;
    EFX_ADD \add_4/i4  (.I0(n5[0]), .I1(in_pair[44]), .CI(\add_4/n6 ), 
            .O(n15[3]), .CO(\add_4/n8 )) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(36)
    defparam \add_4/i4 .I0_POLARITY = 1'b1;
    defparam \add_4/i4 .I1_POLARITY = 1'b1;
    EFX_ADD \add_4/i3  (.I0(in_pair[42]), .I1(in_pair[43]), .CI(\add_4/n4 ), 
            .O(n15[2]), .CO(\add_4/n6 )) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(36)
    defparam \add_4/i3 .I0_POLARITY = 1'b1;
    defparam \add_4/i3 .I1_POLARITY = 1'b1;
    EFX_ADD \add_4/i2  (.I0(in_pair[41]), .I1(in_pair[42]), .CI(\add_4/n2 ), 
            .O(n15[1]), .CO(\add_4/n4 )) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(36)
    defparam \add_4/i2 .I0_POLARITY = 1'b1;
    defparam \add_4/i2 .I1_POLARITY = 1'b1;
    EFX_ADD \add_3/i8  (.I0(in_pair[47]), .I1(1'b0), .CI(\add_3/n14 ), 
            .O(n5[7]), .CO(n1605)) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(36)
    defparam \add_3/i8 .I0_POLARITY = 1'b1;
    defparam \add_3/i8 .I1_POLARITY = 1'b1;
    EFX_ADD \add_3/i7  (.I0(in_pair[46]), .I1(1'b0), .CI(\add_3/n12 ), 
            .O(n5[6]), .CO(\add_3/n14 )) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(36)
    defparam \add_3/i7 .I0_POLARITY = 1'b1;
    defparam \add_3/i7 .I1_POLARITY = 1'b1;
    EFX_ADD \add_3/i6  (.I0(in_pair[45]), .I1(1'b0), .CI(\add_3/n10 ), 
            .O(n5[5]), .CO(\add_3/n12 )) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(36)
    defparam \add_3/i6 .I0_POLARITY = 1'b1;
    defparam \add_3/i6 .I1_POLARITY = 1'b1;
    EFX_ADD \add_3/i5  (.I0(in_pair[44]), .I1(in_pair[47]), .CI(\add_3/n8 ), 
            .O(n5[4]), .CO(\add_3/n10 )) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(36)
    defparam \add_3/i5 .I0_POLARITY = 1'b1;
    defparam \add_3/i5 .I1_POLARITY = 1'b1;
    EFX_ADD \add_3/i4  (.I0(in_pair[43]), .I1(in_pair[46]), .CI(\add_3/n6 ), 
            .O(n5[3]), .CO(\add_3/n8 )) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(36)
    defparam \add_3/i4 .I0_POLARITY = 1'b1;
    defparam \add_3/i4 .I1_POLARITY = 1'b1;
    EFX_ADD \add_3/i3  (.I0(in_pair[42]), .I1(in_pair[45]), .CI(\add_3/n4 ), 
            .O(n5[2]), .CO(\add_3/n6 )) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(36)
    defparam \add_3/i3 .I0_POLARITY = 1'b1;
    defparam \add_3/i3 .I1_POLARITY = 1'b1;
    EFX_ADD \add_3/i2  (.I0(in_pair[41]), .I1(in_pair[44]), .CI(\add_3/n2 ), 
            .O(n5[1]), .CO(\add_3/n4 )) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(36)
    defparam \add_3/i2 .I0_POLARITY = 1'b1;
    defparam \add_3/i2 .I1_POLARITY = 1'b1;
    EFX_ADD \add_3/i1  (.I0(in_pair[40]), .I1(in_pair[43]), .CI(1'b0), 
            .O(n5[0]), .CO(\add_3/n2 )) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(36)
    defparam \add_3/i1 .I0_POLARITY = 1'b1;
    defparam \add_3/i1 .I1_POLARITY = 1'b1;
    EFX_LUT4 LUT__2949 (.I0(\snapshot.show_ann ), .I1(\snapshot.mode [0]), 
            .I2(\snapshot.ann [1]), .O(n1342)) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'h8080 */ ;
    defparam LUT__2949.LUTMASK = 16'h8080;
    EFX_LUT4 LUT__2950 (.I0(\snapshot.ann [1]), .I1(\snapshot.ann [0]), 
            .I2(\snapshot.show_ann ), .I3(\snapshot.mode [0]), .O(n1343)) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'he000 */ ;
    defparam LUT__2950.LUTMASK = 16'he000;
    EFX_LUT4 LUT__2951 (.I0(n1342), .I1(n1343), .O(n1344)) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'h4444 */ ;
    defparam LUT__2951.LUTMASK = 16'h4444;
    EFX_LUT4 LUT__2952 (.I0(\snapshot.ann10_color [0]), .I1(\snapshot.ann11_color [0]), 
            .I2(\snapshot.ann [0]), .I3(n1342), .O(n1345)) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'hca00 */ ;
    defparam LUT__2952.LUTMASK = 16'hca00;
    EFX_LUT4 LUT__2953 (.I0(\snapshot.mode [2]), .I1(\snapshot.mode [0]), 
            .I2(\snapshot.mode [1]), .O(n1346)) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'h0e0e */ ;
    defparam LUT__2953.LUTMASK = 16'h0e0e;
    EFX_LUT4 LUT__2954 (.I0(n1344), .I1(\snapshot.ann01_color [0]), .I2(n1345), 
            .I3(n1346), .O(n1347)) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'hf800 */ ;
    defparam LUT__2954.LUTMASK = 16'hf800;
    EFX_LUT4 LUT__2955 (.I0(\snapshot.edge_bits [0]), .I1(\snapshot.show_edge ), 
            .O(n1348)) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'h8888 */ ;
    defparam LUT__2955.LUTMASK = 16'h8888;
    EFX_LUT4 LUT__2956 (.I0(n1343), .I1(n1346), .O(n1349)) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'h4444 */ ;
    defparam LUT__2956.LUTMASK = 16'h4444;
    EFX_LUT4 LUT__2957 (.I0(\snapshot.edge_color [0]), .I1(\snapshot.rgb [0]), 
            .I2(n1348), .I3(n1349), .O(n1350)) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'hac00 */ ;
    defparam LUT__2957.LUTMASK = 16'hac00;
    EFX_LUT4 LUT__2958 (.I0(\snapshot.mode [1]), .I1(\snapshot.mode [0]), 
            .I2(\snapshot.mode [2]), .O(n1351)) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'h0b0b */ ;
    defparam LUT__2958.LUTMASK = 16'h0b0b;
    EFX_LUT4 LUT__2959 (.I0(\snapshot.edge_bits [0]), .I1(\snapshot.gray [0]), 
            .I2(\snapshot.top_half ), .I3(n1351), .O(n1352)) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'h3500 */ ;
    defparam LUT__2959.LUTMASK = 16'h3500;
    EFX_LUT4 LUT__2960 (.I0(\snapshot.mode [1]), .I1(\snapshot.mode [2]), 
            .O(n1353)) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'h1111 */ ;
    defparam LUT__2960.LUTMASK = 16'h1111;
    EFX_LUT4 LUT__2961 (.I0(n1351), .I1(\snapshot.rgb [0]), .I2(n1352), 
            .I3(n1353), .O(n1354)) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'hf100 */ ;
    defparam LUT__2961.LUTMASK = 16'hf100;
    EFX_LUT4 LUT__2962 (.I0(n1347), .I1(n1350), .I2(n1341), .I3(n1354), 
            .O(n805_2[0])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'h00fe */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(71)
    defparam LUT__2962.LUTMASK = 16'h00fe;
    EFX_LUT4 LUT__2963 (.I0(rst), .I1(\snapshot.error [1]), .I2(\snapshot.error [0]), 
            .I3(\snapshot.de ), .O(n1920)) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'h0100 */ ;
    defparam LUT__2963.LUTMASK = 16'h0100;
    EFX_LUT4 LUT__2964 (.I0(in_render[100]), .I1(in_y[2]), .I2(in_render[101]), 
            .I3(in_y[3]), .O(n1355)) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'hb0bb */ ;
    defparam LUT__2964.LUTMASK = 16'hb0bb;
    EFX_LUT4 LUT__2965 (.I0(in_y[1]), .I1(in_y[0]), .I2(in_render[99]), 
            .I3(in_render[98]), .O(n1356)) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'h8eaf */ ;
    defparam LUT__2965.LUTMASK = 16'h8eaf;
    EFX_LUT4 LUT__2966 (.I0(in_y[4]), .I1(in_render[102]), .O(n1357)) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'h4444 */ ;
    defparam LUT__2966.LUTMASK = 16'h4444;
    EFX_LUT4 LUT__2967 (.I0(in_y[3]), .I1(in_y[2]), .I2(in_render[101]), 
            .I3(in_render[100]), .O(n1358)) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'h8eaf */ ;
    defparam LUT__2967.LUTMASK = 16'h8eaf;
    EFX_LUT4 LUT__2968 (.I0(n1356), .I1(n1355), .I2(n1357), .I3(n1358), 
            .O(n1359)) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'h0b00 */ ;
    defparam LUT__2968.LUTMASK = 16'h0b00;
    EFX_LUT4 LUT__2969 (.I0(in_render[102]), .I1(in_y[4]), .I2(in_render[103]), 
            .I3(in_y[5]), .O(n1360)) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'hb0bb */ ;
    defparam LUT__2969.LUTMASK = 16'hb0bb;
    EFX_LUT4 LUT__2970 (.I0(in_render[104]), .I1(in_y[6]), .I2(in_render[105]), 
            .I3(in_y[7]), .O(n1361)) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'hb0bb */ ;
    defparam LUT__2970.LUTMASK = 16'hb0bb;
    EFX_LUT4 LUT__2971 (.I0(in_y[6]), .I1(in_y[5]), .I2(in_render[104]), 
            .I3(in_render[103]), .O(n1362)) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'h8eaf */ ;
    defparam LUT__2971.LUTMASK = 16'h8eaf;
    EFX_LUT4 LUT__2972 (.I0(in_y[7]), .I1(in_render[105]), .I2(n1362), 
            .O(n1363)) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'hb2b2 */ ;
    defparam LUT__2972.LUTMASK = 16'hb2b2;
    EFX_LUT4 LUT__2973 (.I0(n1359), .I1(n1361), .I2(n1360), .I3(n1363), 
            .O(n1364)) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'hbf00 */ ;
    defparam LUT__2973.LUTMASK = 16'hbf00;
    EFX_LUT4 LUT__2974 (.I0(in_render[106]), .I1(in_y[8]), .O(n1365)) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'h4444 */ ;
    defparam LUT__2974.LUTMASK = 16'h4444;
    EFX_LUT4 LUT__2975 (.I0(in_render[107]), .I1(in_y[9]), .I2(in_render[108]), 
            .I3(in_y[10]), .O(n1366)) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'hb0bb */ ;
    defparam LUT__2975.LUTMASK = 16'hb0bb;
    EFX_LUT4 LUT__2976 (.I0(in_y[9]), .I1(in_y[8]), .I2(in_render[107]), 
            .I3(in_render[106]), .O(n1367)) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'h8eaf */ ;
    defparam LUT__2976.LUTMASK = 16'h8eaf;
    EFX_LUT4 LUT__2977 (.I0(in_y[10]), .I1(in_render[108]), .I2(n1367), 
            .O(n1368)) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'hb2b2 */ ;
    defparam LUT__2977.LUTMASK = 16'hb2b2;
    EFX_LUT4 LUT__2978 (.I0(n1365), .I1(n1364), .I2(n1366), .I3(n1368), 
            .O(\next_snapshot.top_half )) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'h10ff */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(80)
    defparam LUT__2978.LUTMASK = 16'h10ff;
    EFX_LUT4 LUT__2979 (.I0(in_y[9]), .I1(in_y[8]), .I2(in_y[7]), .I3(in_y[6]), 
            .O(n1369)) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'h0001 */ ;
    defparam LUT__2979.LUTMASK = 16'h0001;
    EFX_LUT4 LUT__2980 (.I0(in_y[5]), .I1(in_y[4]), .I2(in_y[3]), .I3(n1369), 
            .O(n1370)) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'h7f00 */ ;
    defparam LUT__2980.LUTMASK = 16'h7f00;
    EFX_LUT4 LUT__2981 (.I0(in_render[106]), .I1(in_render[105]), .I2(in_render[107]), 
            .I3(in_render[102]), .O(n1371)) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'h1000 */ ;
    defparam LUT__2981.LUTMASK = 16'h1000;
    EFX_LUT4 LUT__2982 (.I0(in_render[110]), .I1(in_render[111]), .I2(n1371), 
            .O(n1372)) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'h7070 */ ;
    defparam LUT__2982.LUTMASK = 16'h7070;
    EFX_LUT4 LUT__2983 (.I0(in_x_even[10]), .I1(in_x_even[9]), .I2(in_x_even[8]), 
            .I3(in_x_even[7]), .O(n1373)) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'h8000 */ ;
    defparam LUT__2983.LUTMASK = 16'h8000;
    EFX_LUT4 LUT__2984 (.I0(in_render[108]), .I1(in_render[104]), .I2(in_render[103]), 
            .I3(in_render[101]), .O(n1374)) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'h0100 */ ;
    defparam LUT__2984.LUTMASK = 16'h0100;
    EFX_LUT4 LUT__2985 (.I0(in_x_even[0]), .I1(in_render[99]), .I2(in_render[98]), 
            .I3(in_render[100]), .O(n1375)) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'h0100 */ ;
    defparam LUT__2985.LUTMASK = 16'h0100;
    EFX_LUT4 LUT__2986 (.I0(n1373), .I1(n1374), .I2(n1375), .O(n1376)) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'h4040 */ ;
    defparam LUT__2986.LUTMASK = 16'h4040;
    EFX_LUT4 LUT__2987 (.I0(n1370), .I1(in_y[10]), .I2(n1372), .I3(n1376), 
            .O(n1377)) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'hb000 */ ;
    defparam LUT__2987.LUTMASK = 16'hb000;
    EFX_LUT4 LUT__2988 (.I0(n1377), .I1(in_identity_good), .I2(in_de), 
            .O(\next_snapshot.error [1])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'h7070 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(90)
    defparam LUT__2988.LUTMASK = 16'h7070;
    EFX_LUT4 LUT__2989 (.I0(in_identity_good), .I1(in_pixels_valid), .I2(in_de), 
            .I3(n1377), .O(\next_snapshot.error [0])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'h7000 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(89)
    defparam LUT__2989.LUTMASK = 16'h7000;
    EFX_LUT4 LUT__2990 (.I0(\snapshot.mode [0]), .I1(\snapshot.gray [1]), 
            .I2(n1340), .I3(\snapshot.mode [2]), .O(n1378)) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'h004f */ ;
    defparam LUT__2990.LUTMASK = 16'h004f;
    EFX_LUT4 LUT__2991 (.I0(\snapshot.ann10_color [1]), .I1(\snapshot.ann11_color [1]), 
            .I2(\snapshot.ann [0]), .I3(n1342), .O(n1379)) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'hca00 */ ;
    defparam LUT__2991.LUTMASK = 16'hca00;
    EFX_LUT4 LUT__2992 (.I0(n1344), .I1(\snapshot.ann01_color [1]), .I2(n1379), 
            .I3(n1346), .O(n1380)) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'hf800 */ ;
    defparam LUT__2992.LUTMASK = 16'hf800;
    EFX_LUT4 LUT__2993 (.I0(\snapshot.edge_color [1]), .I1(\snapshot.rgb [1]), 
            .I2(n1348), .I3(n1349), .O(n1381)) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'hac00 */ ;
    defparam LUT__2993.LUTMASK = 16'hac00;
    EFX_LUT4 LUT__2994 (.I0(\snapshot.edge_bits [0]), .I1(\snapshot.gray [1]), 
            .I2(\snapshot.top_half ), .I3(n1351), .O(n1382)) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'h3500 */ ;
    defparam LUT__2994.LUTMASK = 16'h3500;
    EFX_LUT4 LUT__2995 (.I0(n1351), .I1(\snapshot.rgb [1]), .I2(n1382), 
            .I3(n1353), .O(n1383)) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'hf100 */ ;
    defparam LUT__2995.LUTMASK = 16'hf100;
    EFX_LUT4 LUT__2996 (.I0(n1380), .I1(n1381), .I2(n1378), .I3(n1383), 
            .O(n805_3[1])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'h00fe */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(71)
    defparam LUT__2996.LUTMASK = 16'h00fe;
    EFX_LUT4 LUT__2997 (.I0(\snapshot.mode [0]), .I1(\snapshot.gray [2]), 
            .I2(n1340), .I3(\snapshot.mode [2]), .O(n1384)) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'h004f */ ;
    defparam LUT__2997.LUTMASK = 16'h004f;
    EFX_LUT4 LUT__2998 (.I0(\snapshot.ann10_color [2]), .I1(\snapshot.ann11_color [2]), 
            .I2(\snapshot.ann [0]), .I3(n1342), .O(n1385)) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'hca00 */ ;
    defparam LUT__2998.LUTMASK = 16'hca00;
    EFX_LUT4 LUT__2999 (.I0(n1344), .I1(\snapshot.ann01_color [2]), .I2(n1385), 
            .I3(n1346), .O(n1386)) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'hf800 */ ;
    defparam LUT__2999.LUTMASK = 16'hf800;
    EFX_LUT4 LUT__3000 (.I0(\snapshot.edge_color [2]), .I1(\snapshot.rgb [2]), 
            .I2(n1348), .I3(n1349), .O(n1387)) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'hac00 */ ;
    defparam LUT__3000.LUTMASK = 16'hac00;
    EFX_LUT4 LUT__3001 (.I0(\snapshot.edge_bits [0]), .I1(\snapshot.gray [2]), 
            .I2(\snapshot.top_half ), .I3(n1351), .O(n1388)) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'h3500 */ ;
    defparam LUT__3001.LUTMASK = 16'h3500;
    EFX_LUT4 LUT__3002 (.I0(n1351), .I1(\snapshot.rgb [2]), .I2(n1388), 
            .I3(n1353), .O(n1389)) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'hf100 */ ;
    defparam LUT__3002.LUTMASK = 16'hf100;
    EFX_LUT4 LUT__3003 (.I0(n1386), .I1(n1387), .I2(n1384), .I3(n1389), 
            .O(n805_4[2])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'h00fe */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(71)
    defparam LUT__3003.LUTMASK = 16'h00fe;
    EFX_LUT4 LUT__3004 (.I0(\snapshot.mode [0]), .I1(\snapshot.gray [3]), 
            .I2(n1340), .I3(\snapshot.mode [2]), .O(n1390)) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'h004f */ ;
    defparam LUT__3004.LUTMASK = 16'h004f;
    EFX_LUT4 LUT__3005 (.I0(\snapshot.ann10_color [3]), .I1(\snapshot.ann11_color [3]), 
            .I2(\snapshot.ann [0]), .I3(n1342), .O(n1391)) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'hca00 */ ;
    defparam LUT__3005.LUTMASK = 16'hca00;
    EFX_LUT4 LUT__3006 (.I0(n1344), .I1(\snapshot.ann01_color [3]), .I2(n1391), 
            .I3(n1346), .O(n1392)) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'hf800 */ ;
    defparam LUT__3006.LUTMASK = 16'hf800;
    EFX_LUT4 LUT__3007 (.I0(\snapshot.edge_color [3]), .I1(\snapshot.rgb [3]), 
            .I2(n1348), .I3(n1349), .O(n1393)) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'hac00 */ ;
    defparam LUT__3007.LUTMASK = 16'hac00;
    EFX_LUT4 LUT__3008 (.I0(\snapshot.edge_bits [0]), .I1(\snapshot.gray [3]), 
            .I2(\snapshot.top_half ), .I3(n1351), .O(n1394)) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'h3500 */ ;
    defparam LUT__3008.LUTMASK = 16'h3500;
    EFX_LUT4 LUT__3009 (.I0(n1351), .I1(\snapshot.rgb [3]), .I2(n1394), 
            .I3(n1353), .O(n1395)) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'hf100 */ ;
    defparam LUT__3009.LUTMASK = 16'hf100;
    EFX_LUT4 LUT__3010 (.I0(n1392), .I1(n1393), .I2(n1390), .I3(n1395), 
            .O(n805_5[3])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'h00fe */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(71)
    defparam LUT__3010.LUTMASK = 16'h00fe;
    EFX_LUT4 LUT__3011 (.I0(\snapshot.mode [0]), .I1(\snapshot.gray [4]), 
            .I2(n1340), .I3(\snapshot.mode [2]), .O(n1396)) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'h004f */ ;
    defparam LUT__3011.LUTMASK = 16'h004f;
    EFX_LUT4 LUT__3012 (.I0(\snapshot.ann10_color [4]), .I1(\snapshot.ann11_color [4]), 
            .I2(\snapshot.ann [0]), .I3(n1342), .O(n1397)) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'hca00 */ ;
    defparam LUT__3012.LUTMASK = 16'hca00;
    EFX_LUT4 LUT__3013 (.I0(n1344), .I1(\snapshot.ann01_color [4]), .I2(n1397), 
            .I3(n1346), .O(n1398)) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'hf800 */ ;
    defparam LUT__3013.LUTMASK = 16'hf800;
    EFX_LUT4 LUT__3014 (.I0(\snapshot.edge_color [4]), .I1(\snapshot.rgb [4]), 
            .I2(n1348), .I3(n1349), .O(n1399)) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'hac00 */ ;
    defparam LUT__3014.LUTMASK = 16'hac00;
    EFX_LUT4 LUT__3015 (.I0(\snapshot.edge_bits [0]), .I1(\snapshot.gray [4]), 
            .I2(\snapshot.top_half ), .I3(n1351), .O(n1400)) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'h3500 */ ;
    defparam LUT__3015.LUTMASK = 16'h3500;
    EFX_LUT4 LUT__3016 (.I0(n1351), .I1(\snapshot.rgb [4]), .I2(n1400), 
            .I3(n1353), .O(n1401)) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'hf100 */ ;
    defparam LUT__3016.LUTMASK = 16'hf100;
    EFX_LUT4 LUT__3017 (.I0(n1398), .I1(n1399), .I2(n1396), .I3(n1401), 
            .O(n805_6[4])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'h00fe */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(71)
    defparam LUT__3017.LUTMASK = 16'h00fe;
    EFX_LUT4 LUT__3018 (.I0(\snapshot.mode [0]), .I1(\snapshot.gray [5]), 
            .I2(n1340), .I3(\snapshot.mode [2]), .O(n1402)) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'h004f */ ;
    defparam LUT__3018.LUTMASK = 16'h004f;
    EFX_LUT4 LUT__3019 (.I0(\snapshot.ann10_color [5]), .I1(\snapshot.ann11_color [5]), 
            .I2(\snapshot.ann [0]), .I3(n1342), .O(n1403)) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'hca00 */ ;
    defparam LUT__3019.LUTMASK = 16'hca00;
    EFX_LUT4 LUT__3020 (.I0(n1344), .I1(\snapshot.ann01_color [5]), .I2(n1403), 
            .I3(n1346), .O(n1404)) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'hf800 */ ;
    defparam LUT__3020.LUTMASK = 16'hf800;
    EFX_LUT4 LUT__3021 (.I0(\snapshot.edge_color [5]), .I1(\snapshot.rgb [5]), 
            .I2(n1348), .I3(n1349), .O(n1405)) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'hac00 */ ;
    defparam LUT__3021.LUTMASK = 16'hac00;
    EFX_LUT4 LUT__3022 (.I0(\snapshot.edge_bits [0]), .I1(\snapshot.gray [5]), 
            .I2(\snapshot.top_half ), .I3(n1351), .O(n1406)) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'h3500 */ ;
    defparam LUT__3022.LUTMASK = 16'h3500;
    EFX_LUT4 LUT__3023 (.I0(n1351), .I1(\snapshot.rgb [5]), .I2(n1406), 
            .I3(n1353), .O(n1407)) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'hf100 */ ;
    defparam LUT__3023.LUTMASK = 16'hf100;
    EFX_LUT4 LUT__3024 (.I0(n1404), .I1(n1405), .I2(n1402), .I3(n1407), 
            .O(n805_7[5])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'h00fe */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(71)
    defparam LUT__3024.LUTMASK = 16'h00fe;
    EFX_LUT4 LUT__3025 (.I0(\snapshot.mode [0]), .I1(\snapshot.gray [6]), 
            .I2(n1340), .I3(\snapshot.mode [2]), .O(n1408)) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'h004f */ ;
    defparam LUT__3025.LUTMASK = 16'h004f;
    EFX_LUT4 LUT__3026 (.I0(\snapshot.ann10_color [6]), .I1(\snapshot.ann11_color [6]), 
            .I2(\snapshot.ann [0]), .I3(n1342), .O(n1409)) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'hca00 */ ;
    defparam LUT__3026.LUTMASK = 16'hca00;
    EFX_LUT4 LUT__3027 (.I0(n1344), .I1(\snapshot.ann01_color [6]), .I2(n1409), 
            .I3(n1346), .O(n1410)) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'hf800 */ ;
    defparam LUT__3027.LUTMASK = 16'hf800;
    EFX_LUT4 LUT__3028 (.I0(\snapshot.edge_color [6]), .I1(\snapshot.rgb [6]), 
            .I2(n1348), .I3(n1349), .O(n1411)) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'hac00 */ ;
    defparam LUT__3028.LUTMASK = 16'hac00;
    EFX_LUT4 LUT__3029 (.I0(\snapshot.edge_bits [0]), .I1(\snapshot.gray [6]), 
            .I2(\snapshot.top_half ), .I3(n1351), .O(n1412)) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'h3500 */ ;
    defparam LUT__3029.LUTMASK = 16'h3500;
    EFX_LUT4 LUT__3030 (.I0(n1351), .I1(\snapshot.rgb [6]), .I2(n1412), 
            .I3(n1353), .O(n1413)) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'hf100 */ ;
    defparam LUT__3030.LUTMASK = 16'hf100;
    EFX_LUT4 LUT__3031 (.I0(n1410), .I1(n1411), .I2(n1408), .I3(n1413), 
            .O(n805_8[6])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'h00fe */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(71)
    defparam LUT__3031.LUTMASK = 16'h00fe;
    EFX_LUT4 LUT__3032 (.I0(\snapshot.mode [0]), .I1(\snapshot.gray [7]), 
            .I2(n1340), .I3(\snapshot.mode [2]), .O(n1414)) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'h004f */ ;
    defparam LUT__3032.LUTMASK = 16'h004f;
    EFX_LUT4 LUT__3033 (.I0(\snapshot.ann10_color [7]), .I1(\snapshot.ann11_color [7]), 
            .I2(\snapshot.ann [0]), .I3(n1342), .O(n1415)) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'hca00 */ ;
    defparam LUT__3033.LUTMASK = 16'hca00;
    EFX_LUT4 LUT__3034 (.I0(n1344), .I1(\snapshot.ann01_color [7]), .I2(n1415), 
            .I3(n1346), .O(n1416)) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'hf800 */ ;
    defparam LUT__3034.LUTMASK = 16'hf800;
    EFX_LUT4 LUT__3035 (.I0(\snapshot.edge_color [7]), .I1(\snapshot.rgb [7]), 
            .I2(n1348), .I3(n1349), .O(n1417)) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'hac00 */ ;
    defparam LUT__3035.LUTMASK = 16'hac00;
    EFX_LUT4 LUT__3036 (.I0(\snapshot.edge_bits [0]), .I1(\snapshot.gray [7]), 
            .I2(\snapshot.top_half ), .I3(n1351), .O(n1418)) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'h3500 */ ;
    defparam LUT__3036.LUTMASK = 16'h3500;
    EFX_LUT4 LUT__3037 (.I0(n1351), .I1(\snapshot.rgb [7]), .I2(n1418), 
            .I3(n1353), .O(n1419)) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'hf100 */ ;
    defparam LUT__3037.LUTMASK = 16'hf100;
    EFX_LUT4 LUT__3038 (.I0(n1416), .I1(n1417), .I2(n1414), .I3(n1419), 
            .O(n805_9[7])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'h00fe */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(71)
    defparam LUT__3038.LUTMASK = 16'h00fe;
    EFX_LUT4 LUT__3039 (.I0(\snapshot.edge_color [8]), .I1(\snapshot.rgb [8]), 
            .I2(n1348), .I3(n1349), .O(n1420)) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'hac00 */ ;
    defparam LUT__3039.LUTMASK = 16'hac00;
    EFX_LUT4 LUT__3040 (.I0(\snapshot.ann10_color [8]), .I1(\snapshot.ann11_color [8]), 
            .I2(\snapshot.ann [0]), .I3(n1342), .O(n1421)) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'hca00 */ ;
    defparam LUT__3040.LUTMASK = 16'hca00;
    EFX_LUT4 LUT__3041 (.I0(n1344), .I1(\snapshot.ann01_color [8]), .I2(n1421), 
            .I3(n1346), .O(n1422)) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'hf800 */ ;
    defparam LUT__3041.LUTMASK = 16'hf800;
    EFX_LUT4 LUT__3042 (.I0(n1351), .I1(\snapshot.rgb [8]), .I2(n1352), 
            .I3(n1353), .O(n1423)) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'hf100 */ ;
    defparam LUT__3042.LUTMASK = 16'hf100;
    EFX_LUT4 LUT__3043 (.I0(n1422), .I1(n1341), .I2(n1420), .I3(n1423), 
            .O(n805_10[8])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'h00fe */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(71)
    defparam LUT__3043.LUTMASK = 16'h00fe;
    EFX_LUT4 LUT__3044 (.I0(\snapshot.edge_color [9]), .I1(\snapshot.rgb [9]), 
            .I2(n1348), .I3(n1349), .O(n1424)) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'hac00 */ ;
    defparam LUT__3044.LUTMASK = 16'hac00;
    EFX_LUT4 LUT__3045 (.I0(\snapshot.ann10_color [9]), .I1(\snapshot.ann11_color [9]), 
            .I2(\snapshot.ann [0]), .I3(n1342), .O(n1425)) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'hca00 */ ;
    defparam LUT__3045.LUTMASK = 16'hca00;
    EFX_LUT4 LUT__3046 (.I0(n1344), .I1(\snapshot.ann01_color [9]), .I2(n1425), 
            .I3(n1346), .O(n1426)) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'hf800 */ ;
    defparam LUT__3046.LUTMASK = 16'hf800;
    EFX_LUT4 LUT__3047 (.I0(n1351), .I1(\snapshot.rgb [9]), .I2(n1382), 
            .I3(n1353), .O(n1427)) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'hf100 */ ;
    defparam LUT__3047.LUTMASK = 16'hf100;
    EFX_LUT4 LUT__3048 (.I0(n1426), .I1(n1378), .I2(n1424), .I3(n1427), 
            .O(n805_11[9])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'h00fe */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(71)
    defparam LUT__3048.LUTMASK = 16'h00fe;
    EFX_LUT4 LUT__3049 (.I0(\snapshot.edge_color [10]), .I1(\snapshot.rgb [10]), 
            .I2(n1348), .I3(n1349), .O(n1428)) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'hac00 */ ;
    defparam LUT__3049.LUTMASK = 16'hac00;
    EFX_LUT4 LUT__3050 (.I0(\snapshot.ann10_color [10]), .I1(\snapshot.ann11_color [10]), 
            .I2(\snapshot.ann [0]), .I3(n1342), .O(n1429)) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'hca00 */ ;
    defparam LUT__3050.LUTMASK = 16'hca00;
    EFX_LUT4 LUT__3051 (.I0(n1344), .I1(\snapshot.ann01_color [10]), .I2(n1429), 
            .I3(n1346), .O(n1430)) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'hf800 */ ;
    defparam LUT__3051.LUTMASK = 16'hf800;
    EFX_LUT4 LUT__3052 (.I0(n1351), .I1(\snapshot.rgb [10]), .I2(n1388), 
            .I3(n1353), .O(n1431)) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'hf100 */ ;
    defparam LUT__3052.LUTMASK = 16'hf100;
    EFX_LUT4 LUT__3053 (.I0(n1430), .I1(n1384), .I2(n1428), .I3(n1431), 
            .O(n805_12[10])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'h00fe */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(71)
    defparam LUT__3053.LUTMASK = 16'h00fe;
    EFX_LUT4 LUT__3054 (.I0(\snapshot.edge_color [11]), .I1(\snapshot.rgb [11]), 
            .I2(n1348), .I3(n1349), .O(n1432)) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'hac00 */ ;
    defparam LUT__3054.LUTMASK = 16'hac00;
    EFX_LUT4 LUT__3055 (.I0(\snapshot.ann10_color [11]), .I1(\snapshot.ann11_color [11]), 
            .I2(\snapshot.ann [0]), .I3(n1342), .O(n1433)) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'hca00 */ ;
    defparam LUT__3055.LUTMASK = 16'hca00;
    EFX_LUT4 LUT__3056 (.I0(n1344), .I1(\snapshot.ann01_color [11]), .I2(n1433), 
            .I3(n1346), .O(n1434)) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'hf800 */ ;
    defparam LUT__3056.LUTMASK = 16'hf800;
    EFX_LUT4 LUT__3057 (.I0(n1351), .I1(\snapshot.rgb [11]), .I2(n1394), 
            .I3(n1353), .O(n1435)) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'hf100 */ ;
    defparam LUT__3057.LUTMASK = 16'hf100;
    EFX_LUT4 LUT__3058 (.I0(n1434), .I1(n1390), .I2(n1432), .I3(n1435), 
            .O(n805_13[11])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'h00fe */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(71)
    defparam LUT__3058.LUTMASK = 16'h00fe;
    EFX_LUT4 LUT__3059 (.I0(\snapshot.edge_color [12]), .I1(\snapshot.rgb [12]), 
            .I2(n1348), .I3(n1349), .O(n1436)) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'hac00 */ ;
    defparam LUT__3059.LUTMASK = 16'hac00;
    EFX_LUT4 LUT__3060 (.I0(\snapshot.ann10_color [12]), .I1(\snapshot.ann11_color [12]), 
            .I2(\snapshot.ann [0]), .I3(n1342), .O(n1437)) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'hca00 */ ;
    defparam LUT__3060.LUTMASK = 16'hca00;
    EFX_LUT4 LUT__3061 (.I0(n1344), .I1(\snapshot.ann01_color [12]), .I2(n1437), 
            .I3(n1346), .O(n1438)) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'hf800 */ ;
    defparam LUT__3061.LUTMASK = 16'hf800;
    EFX_LUT4 LUT__3062 (.I0(n1351), .I1(\snapshot.rgb [12]), .I2(n1400), 
            .I3(n1353), .O(n1439)) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'hf100 */ ;
    defparam LUT__3062.LUTMASK = 16'hf100;
    EFX_LUT4 LUT__3063 (.I0(n1438), .I1(n1396), .I2(n1436), .I3(n1439), 
            .O(n805_14[12])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'h00fe */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(71)
    defparam LUT__3063.LUTMASK = 16'h00fe;
    EFX_LUT4 LUT__3064 (.I0(\snapshot.edge_color [13]), .I1(\snapshot.rgb [13]), 
            .I2(n1348), .I3(n1349), .O(n1440)) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'hac00 */ ;
    defparam LUT__3064.LUTMASK = 16'hac00;
    EFX_LUT4 LUT__3065 (.I0(\snapshot.ann10_color [13]), .I1(\snapshot.ann11_color [13]), 
            .I2(\snapshot.ann [0]), .I3(n1342), .O(n1441)) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'hca00 */ ;
    defparam LUT__3065.LUTMASK = 16'hca00;
    EFX_LUT4 LUT__3066 (.I0(n1344), .I1(\snapshot.ann01_color [13]), .I2(n1441), 
            .I3(n1346), .O(n1442)) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'hf800 */ ;
    defparam LUT__3066.LUTMASK = 16'hf800;
    EFX_LUT4 LUT__3067 (.I0(n1351), .I1(\snapshot.rgb [13]), .I2(n1406), 
            .I3(n1353), .O(n1443)) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'hf100 */ ;
    defparam LUT__3067.LUTMASK = 16'hf100;
    EFX_LUT4 LUT__3068 (.I0(n1442), .I1(n1402), .I2(n1440), .I3(n1443), 
            .O(n805_15[13])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'h00fe */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(71)
    defparam LUT__3068.LUTMASK = 16'h00fe;
    EFX_LUT4 LUT__3069 (.I0(\snapshot.edge_color [14]), .I1(\snapshot.rgb [14]), 
            .I2(n1348), .I3(n1349), .O(n1444)) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'hac00 */ ;
    defparam LUT__3069.LUTMASK = 16'hac00;
    EFX_LUT4 LUT__3070 (.I0(\snapshot.ann10_color [14]), .I1(\snapshot.ann11_color [14]), 
            .I2(\snapshot.ann [0]), .I3(n1342), .O(n1445)) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'hca00 */ ;
    defparam LUT__3070.LUTMASK = 16'hca00;
    EFX_LUT4 LUT__3071 (.I0(n1344), .I1(\snapshot.ann01_color [14]), .I2(n1445), 
            .I3(n1346), .O(n1446)) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'hf800 */ ;
    defparam LUT__3071.LUTMASK = 16'hf800;
    EFX_LUT4 LUT__3072 (.I0(n1351), .I1(\snapshot.rgb [14]), .I2(n1412), 
            .I3(n1353), .O(n1447)) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'hf100 */ ;
    defparam LUT__3072.LUTMASK = 16'hf100;
    EFX_LUT4 LUT__3073 (.I0(n1446), .I1(n1408), .I2(n1444), .I3(n1447), 
            .O(n805_16[14])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'h00fe */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(71)
    defparam LUT__3073.LUTMASK = 16'h00fe;
    EFX_LUT4 LUT__3074 (.I0(\snapshot.edge_color [15]), .I1(\snapshot.rgb [15]), 
            .I2(n1348), .I3(n1349), .O(n1448)) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'hac00 */ ;
    defparam LUT__3074.LUTMASK = 16'hac00;
    EFX_LUT4 LUT__3075 (.I0(\snapshot.ann10_color [15]), .I1(\snapshot.ann11_color [15]), 
            .I2(\snapshot.ann [0]), .I3(n1342), .O(n1449)) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'hca00 */ ;
    defparam LUT__3075.LUTMASK = 16'hca00;
    EFX_LUT4 LUT__3076 (.I0(n1344), .I1(\snapshot.ann01_color [15]), .I2(n1449), 
            .I3(n1346), .O(n1450)) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'hf800 */ ;
    defparam LUT__3076.LUTMASK = 16'hf800;
    EFX_LUT4 LUT__3077 (.I0(n1351), .I1(\snapshot.rgb [15]), .I2(n1418), 
            .I3(n1353), .O(n1451)) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'hf100 */ ;
    defparam LUT__3077.LUTMASK = 16'hf100;
    EFX_LUT4 LUT__3078 (.I0(n1450), .I1(n1414), .I2(n1448), .I3(n1451), 
            .O(n805_17[15])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'h00fe */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(71)
    defparam LUT__3078.LUTMASK = 16'h00fe;
    EFX_LUT4 LUT__3079 (.I0(\snapshot.edge_color [16]), .I1(\snapshot.rgb [16]), 
            .I2(n1348), .I3(n1349), .O(n1452)) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'hac00 */ ;
    defparam LUT__3079.LUTMASK = 16'hac00;
    EFX_LUT4 LUT__3080 (.I0(\snapshot.ann10_color [16]), .I1(\snapshot.ann11_color [16]), 
            .I2(\snapshot.ann [0]), .I3(n1342), .O(n1453)) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'hca00 */ ;
    defparam LUT__3080.LUTMASK = 16'hca00;
    EFX_LUT4 LUT__3081 (.I0(n1344), .I1(\snapshot.ann01_color [16]), .I2(n1453), 
            .I3(n1346), .O(n1454)) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'hf800 */ ;
    defparam LUT__3081.LUTMASK = 16'hf800;
    EFX_LUT4 LUT__3082 (.I0(n1351), .I1(\snapshot.rgb [16]), .I2(n1352), 
            .I3(n1353), .O(n1455)) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'hf100 */ ;
    defparam LUT__3082.LUTMASK = 16'hf100;
    EFX_LUT4 LUT__3083 (.I0(n1454), .I1(n1341), .I2(n1452), .I3(n1455), 
            .O(n805_18[16])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'h00fe */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(71)
    defparam LUT__3083.LUTMASK = 16'h00fe;
    EFX_LUT4 LUT__3084 (.I0(\snapshot.edge_color [17]), .I1(\snapshot.rgb [17]), 
            .I2(n1348), .I3(n1349), .O(n1456)) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'hac00 */ ;
    defparam LUT__3084.LUTMASK = 16'hac00;
    EFX_LUT4 LUT__3085 (.I0(\snapshot.ann10_color [17]), .I1(\snapshot.ann11_color [17]), 
            .I2(\snapshot.ann [0]), .I3(n1342), .O(n1457)) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'hca00 */ ;
    defparam LUT__3085.LUTMASK = 16'hca00;
    EFX_LUT4 LUT__3086 (.I0(n1344), .I1(\snapshot.ann01_color [17]), .I2(n1457), 
            .I3(n1346), .O(n1458)) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'hf800 */ ;
    defparam LUT__3086.LUTMASK = 16'hf800;
    EFX_LUT4 LUT__3087 (.I0(n1351), .I1(\snapshot.rgb [17]), .I2(n1382), 
            .I3(n1353), .O(n1459)) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'hf100 */ ;
    defparam LUT__3087.LUTMASK = 16'hf100;
    EFX_LUT4 LUT__3088 (.I0(n1458), .I1(n1378), .I2(n1456), .I3(n1459), 
            .O(n805_19[17])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'h00fe */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(71)
    defparam LUT__3088.LUTMASK = 16'h00fe;
    EFX_LUT4 LUT__3089 (.I0(\snapshot.edge_color [18]), .I1(\snapshot.rgb [18]), 
            .I2(n1348), .I3(n1349), .O(n1460)) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'hac00 */ ;
    defparam LUT__3089.LUTMASK = 16'hac00;
    EFX_LUT4 LUT__3090 (.I0(\snapshot.ann10_color [18]), .I1(\snapshot.ann11_color [18]), 
            .I2(\snapshot.ann [0]), .I3(n1342), .O(n1461)) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'hca00 */ ;
    defparam LUT__3090.LUTMASK = 16'hca00;
    EFX_LUT4 LUT__3091 (.I0(n1344), .I1(\snapshot.ann01_color [18]), .I2(n1461), 
            .I3(n1346), .O(n1462)) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'hf800 */ ;
    defparam LUT__3091.LUTMASK = 16'hf800;
    EFX_LUT4 LUT__3092 (.I0(n1351), .I1(\snapshot.rgb [18]), .I2(n1388), 
            .I3(n1353), .O(n1463)) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'hf100 */ ;
    defparam LUT__3092.LUTMASK = 16'hf100;
    EFX_LUT4 LUT__3093 (.I0(n1462), .I1(n1384), .I2(n1460), .I3(n1463), 
            .O(n805_20[18])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'h00fe */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(71)
    defparam LUT__3093.LUTMASK = 16'h00fe;
    EFX_LUT4 LUT__3094 (.I0(\snapshot.edge_color [19]), .I1(\snapshot.rgb [19]), 
            .I2(n1348), .I3(n1349), .O(n1464)) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'hac00 */ ;
    defparam LUT__3094.LUTMASK = 16'hac00;
    EFX_LUT4 LUT__3095 (.I0(\snapshot.ann10_color [19]), .I1(\snapshot.ann11_color [19]), 
            .I2(\snapshot.ann [0]), .I3(n1342), .O(n1465)) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'hca00 */ ;
    defparam LUT__3095.LUTMASK = 16'hca00;
    EFX_LUT4 LUT__3096 (.I0(n1344), .I1(\snapshot.ann01_color [19]), .I2(n1465), 
            .I3(n1346), .O(n1466)) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'hf800 */ ;
    defparam LUT__3096.LUTMASK = 16'hf800;
    EFX_LUT4 LUT__3097 (.I0(n1351), .I1(\snapshot.rgb [19]), .I2(n1394), 
            .I3(n1353), .O(n1467)) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'hf100 */ ;
    defparam LUT__3097.LUTMASK = 16'hf100;
    EFX_LUT4 LUT__3098 (.I0(n1466), .I1(n1390), .I2(n1464), .I3(n1467), 
            .O(n805_21[19])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'h00fe */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(71)
    defparam LUT__3098.LUTMASK = 16'h00fe;
    EFX_LUT4 LUT__3099 (.I0(\snapshot.edge_color [20]), .I1(\snapshot.rgb [20]), 
            .I2(n1348), .I3(n1349), .O(n1468)) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'hac00 */ ;
    defparam LUT__3099.LUTMASK = 16'hac00;
    EFX_LUT4 LUT__3100 (.I0(\snapshot.ann10_color [20]), .I1(\snapshot.ann11_color [20]), 
            .I2(\snapshot.ann [0]), .I3(n1342), .O(n1469)) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'hca00 */ ;
    defparam LUT__3100.LUTMASK = 16'hca00;
    EFX_LUT4 LUT__3101 (.I0(n1344), .I1(\snapshot.ann01_color [20]), .I2(n1469), 
            .I3(n1346), .O(n1470)) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'hf800 */ ;
    defparam LUT__3101.LUTMASK = 16'hf800;
    EFX_LUT4 LUT__3102 (.I0(n1351), .I1(\snapshot.rgb [20]), .I2(n1400), 
            .I3(n1353), .O(n1471)) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'hf100 */ ;
    defparam LUT__3102.LUTMASK = 16'hf100;
    EFX_LUT4 LUT__3103 (.I0(n1470), .I1(n1396), .I2(n1468), .I3(n1471), 
            .O(n805_22[20])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'h00fe */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(71)
    defparam LUT__3103.LUTMASK = 16'h00fe;
    EFX_LUT4 LUT__3104 (.I0(\snapshot.edge_color [21]), .I1(\snapshot.rgb [21]), 
            .I2(n1348), .I3(n1349), .O(n1472)) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'hac00 */ ;
    defparam LUT__3104.LUTMASK = 16'hac00;
    EFX_LUT4 LUT__3105 (.I0(\snapshot.ann10_color [21]), .I1(\snapshot.ann11_color [21]), 
            .I2(\snapshot.ann [0]), .I3(n1342), .O(n1473)) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'hca00 */ ;
    defparam LUT__3105.LUTMASK = 16'hca00;
    EFX_LUT4 LUT__3106 (.I0(n1344), .I1(\snapshot.ann01_color [21]), .I2(n1473), 
            .I3(n1346), .O(n1474)) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'hf800 */ ;
    defparam LUT__3106.LUTMASK = 16'hf800;
    EFX_LUT4 LUT__3107 (.I0(n1351), .I1(\snapshot.rgb [21]), .I2(n1406), 
            .I3(n1353), .O(n1475)) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'hf100 */ ;
    defparam LUT__3107.LUTMASK = 16'hf100;
    EFX_LUT4 LUT__3108 (.I0(n1474), .I1(n1402), .I2(n1472), .I3(n1475), 
            .O(n805_23[21])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'h00fe */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(71)
    defparam LUT__3108.LUTMASK = 16'h00fe;
    EFX_LUT4 LUT__3109 (.I0(\snapshot.edge_color [22]), .I1(\snapshot.rgb [22]), 
            .I2(n1348), .I3(n1349), .O(n1476)) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'hac00 */ ;
    defparam LUT__3109.LUTMASK = 16'hac00;
    EFX_LUT4 LUT__3110 (.I0(\snapshot.ann10_color [22]), .I1(\snapshot.ann11_color [22]), 
            .I2(\snapshot.ann [0]), .I3(n1342), .O(n1477)) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'hca00 */ ;
    defparam LUT__3110.LUTMASK = 16'hca00;
    EFX_LUT4 LUT__3111 (.I0(n1344), .I1(\snapshot.ann01_color [22]), .I2(n1477), 
            .I3(n1346), .O(n1478)) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'hf800 */ ;
    defparam LUT__3111.LUTMASK = 16'hf800;
    EFX_LUT4 LUT__3112 (.I0(n1351), .I1(\snapshot.rgb [22]), .I2(n1412), 
            .I3(n1353), .O(n1479)) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'hf100 */ ;
    defparam LUT__3112.LUTMASK = 16'hf100;
    EFX_LUT4 LUT__3113 (.I0(n1478), .I1(n1408), .I2(n1476), .I3(n1479), 
            .O(n805_24[22])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'h00fe */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(71)
    defparam LUT__3113.LUTMASK = 16'h00fe;
    EFX_LUT4 LUT__3114 (.I0(\snapshot.edge_color [23]), .I1(\snapshot.rgb [23]), 
            .I2(n1348), .I3(n1349), .O(n1480)) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'hac00 */ ;
    defparam LUT__3114.LUTMASK = 16'hac00;
    EFX_LUT4 LUT__3115 (.I0(\snapshot.ann10_color [23]), .I1(\snapshot.ann11_color [23]), 
            .I2(\snapshot.ann [0]), .I3(n1342), .O(n1481)) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'hca00 */ ;
    defparam LUT__3115.LUTMASK = 16'hca00;
    EFX_LUT4 LUT__3116 (.I0(n1344), .I1(\snapshot.ann01_color [23]), .I2(n1481), 
            .I3(n1346), .O(n1482)) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'hf800 */ ;
    defparam LUT__3116.LUTMASK = 16'hf800;
    EFX_LUT4 LUT__3117 (.I0(n1351), .I1(\snapshot.rgb [23]), .I2(n1418), 
            .I3(n1353), .O(n1483)) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'hf100 */ ;
    defparam LUT__3117.LUTMASK = 16'hf100;
    EFX_LUT4 LUT__3118 (.I0(n1482), .I1(n1414), .I2(n1480), .I3(n1483), 
            .O(n805_25[23])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'h00fe */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(71)
    defparam LUT__3118.LUTMASK = 16'h00fe;
    EFX_LUT4 LUT__3119 (.I0(\snapshot.edge_bits [1]), .I1(\snapshot.mode [0]), 
            .I2(\snapshot.mode [1]), .O(n1484)) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'h7070 */ ;
    defparam LUT__3119.LUTMASK = 16'h7070;
    EFX_LUT4 LUT__3120 (.I0(\snapshot.mode [0]), .I1(\snapshot.gray [8]), 
            .I2(n1484), .I3(\snapshot.mode [2]), .O(n1485)) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'h004f */ ;
    defparam LUT__3120.LUTMASK = 16'h004f;
    EFX_LUT4 LUT__3121 (.I0(\snapshot.show_ann ), .I1(\snapshot.mode [0]), 
            .I2(\snapshot.ann [3]), .O(n1486)) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'h8080 */ ;
    defparam LUT__3121.LUTMASK = 16'h8080;
    EFX_LUT4 LUT__3122 (.I0(\snapshot.ann [3]), .I1(\snapshot.ann [2]), 
            .I2(\snapshot.show_ann ), .I3(\snapshot.mode [0]), .O(n1487)) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'he000 */ ;
    defparam LUT__3122.LUTMASK = 16'he000;
    EFX_LUT4 LUT__3123 (.I0(n1486), .I1(n1487), .O(n1488)) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'h4444 */ ;
    defparam LUT__3123.LUTMASK = 16'h4444;
    EFX_LUT4 LUT__3124 (.I0(\snapshot.ann10_color [0]), .I1(\snapshot.ann11_color [0]), 
            .I2(\snapshot.ann [2]), .I3(n1486), .O(n1489)) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'hca00 */ ;
    defparam LUT__3124.LUTMASK = 16'hca00;
    EFX_LUT4 LUT__3125 (.I0(n1488), .I1(\snapshot.ann01_color [0]), .I2(n1489), 
            .I3(n1346), .O(n1490)) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'hf800 */ ;
    defparam LUT__3125.LUTMASK = 16'hf800;
    EFX_LUT4 LUT__3126 (.I0(\snapshot.edge_bits [1]), .I1(\snapshot.show_edge ), 
            .O(n1491)) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'h8888 */ ;
    defparam LUT__3126.LUTMASK = 16'h8888;
    EFX_LUT4 LUT__3127 (.I0(n1487), .I1(n1346), .O(n1492)) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'h4444 */ ;
    defparam LUT__3127.LUTMASK = 16'h4444;
    EFX_LUT4 LUT__3128 (.I0(\snapshot.edge_color [0]), .I1(\snapshot.rgb [24]), 
            .I2(n1491), .I3(n1492), .O(n1493)) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'hac00 */ ;
    defparam LUT__3128.LUTMASK = 16'hac00;
    EFX_LUT4 LUT__3129 (.I0(\snapshot.edge_bits [1]), .I1(\snapshot.gray [8]), 
            .I2(\snapshot.top_half ), .I3(n1351), .O(n1494)) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'h3500 */ ;
    defparam LUT__3129.LUTMASK = 16'h3500;
    EFX_LUT4 LUT__3130 (.I0(n1351), .I1(\snapshot.rgb [24]), .I2(n1494), 
            .I3(n1353), .O(n1495)) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'hf100 */ ;
    defparam LUT__3130.LUTMASK = 16'hf100;
    EFX_LUT4 LUT__3131 (.I0(n1490), .I1(n1493), .I2(n1485), .I3(n1495), 
            .O(n574_2[0])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'h00fe */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(71)
    defparam LUT__3131.LUTMASK = 16'h00fe;
    EFX_LUT4 LUT__3132 (.I0(\snapshot.mode [0]), .I1(\snapshot.gray [9]), 
            .I2(n1484), .I3(\snapshot.mode [2]), .O(n1496)) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'h004f */ ;
    defparam LUT__3132.LUTMASK = 16'h004f;
    EFX_LUT4 LUT__3133 (.I0(\snapshot.ann10_color [1]), .I1(\snapshot.ann11_color [1]), 
            .I2(\snapshot.ann [2]), .I3(n1486), .O(n1497)) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'hca00 */ ;
    defparam LUT__3133.LUTMASK = 16'hca00;
    EFX_LUT4 LUT__3134 (.I0(n1488), .I1(\snapshot.ann01_color [1]), .I2(n1497), 
            .I3(n1346), .O(n1498)) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'hf800 */ ;
    defparam LUT__3134.LUTMASK = 16'hf800;
    EFX_LUT4 LUT__3135 (.I0(\snapshot.edge_color [1]), .I1(\snapshot.rgb [25]), 
            .I2(n1491), .I3(n1492), .O(n1499)) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'hac00 */ ;
    defparam LUT__3135.LUTMASK = 16'hac00;
    EFX_LUT4 LUT__3136 (.I0(\snapshot.edge_bits [1]), .I1(\snapshot.gray [9]), 
            .I2(\snapshot.top_half ), .I3(n1351), .O(n1500)) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'h3500 */ ;
    defparam LUT__3136.LUTMASK = 16'h3500;
    EFX_LUT4 LUT__3137 (.I0(n1351), .I1(\snapshot.rgb [25]), .I2(n1500), 
            .I3(n1353), .O(n1501)) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'hf100 */ ;
    defparam LUT__3137.LUTMASK = 16'hf100;
    EFX_LUT4 LUT__3138 (.I0(n1498), .I1(n1499), .I2(n1496), .I3(n1501), 
            .O(n574_3[1])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'h00fe */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(71)
    defparam LUT__3138.LUTMASK = 16'h00fe;
    EFX_LUT4 LUT__3139 (.I0(\snapshot.mode [0]), .I1(\snapshot.gray [10]), 
            .I2(n1484), .I3(\snapshot.mode [2]), .O(n1502)) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'h004f */ ;
    defparam LUT__3139.LUTMASK = 16'h004f;
    EFX_LUT4 LUT__3140 (.I0(\snapshot.ann10_color [2]), .I1(\snapshot.ann11_color [2]), 
            .I2(\snapshot.ann [2]), .I3(n1486), .O(n1503)) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'hca00 */ ;
    defparam LUT__3140.LUTMASK = 16'hca00;
    EFX_LUT4 LUT__3141 (.I0(n1488), .I1(\snapshot.ann01_color [2]), .I2(n1503), 
            .I3(n1346), .O(n1504)) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'hf800 */ ;
    defparam LUT__3141.LUTMASK = 16'hf800;
    EFX_LUT4 LUT__3142 (.I0(\snapshot.edge_color [2]), .I1(\snapshot.rgb [26]), 
            .I2(n1491), .I3(n1492), .O(n1505)) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'hac00 */ ;
    defparam LUT__3142.LUTMASK = 16'hac00;
    EFX_LUT4 LUT__3143 (.I0(\snapshot.edge_bits [1]), .I1(\snapshot.gray [10]), 
            .I2(\snapshot.top_half ), .I3(n1351), .O(n1506)) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'h3500 */ ;
    defparam LUT__3143.LUTMASK = 16'h3500;
    EFX_LUT4 LUT__3144 (.I0(n1351), .I1(\snapshot.rgb [26]), .I2(n1506), 
            .I3(n1353), .O(n1507)) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'hf100 */ ;
    defparam LUT__3144.LUTMASK = 16'hf100;
    EFX_LUT4 LUT__3145 (.I0(n1504), .I1(n1505), .I2(n1502), .I3(n1507), 
            .O(n574_4[2])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'h00fe */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(71)
    defparam LUT__3145.LUTMASK = 16'h00fe;
    EFX_LUT4 LUT__3146 (.I0(\snapshot.mode [0]), .I1(\snapshot.gray [11]), 
            .I2(n1484), .I3(\snapshot.mode [2]), .O(n1508)) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'h004f */ ;
    defparam LUT__3146.LUTMASK = 16'h004f;
    EFX_LUT4 LUT__3147 (.I0(\snapshot.ann10_color [3]), .I1(\snapshot.ann11_color [3]), 
            .I2(\snapshot.ann [2]), .I3(n1486), .O(n1509)) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'hca00 */ ;
    defparam LUT__3147.LUTMASK = 16'hca00;
    EFX_LUT4 LUT__3148 (.I0(n1488), .I1(\snapshot.ann01_color [3]), .I2(n1509), 
            .I3(n1346), .O(n1510)) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'hf800 */ ;
    defparam LUT__3148.LUTMASK = 16'hf800;
    EFX_LUT4 LUT__3149 (.I0(\snapshot.edge_color [3]), .I1(\snapshot.rgb [27]), 
            .I2(n1491), .I3(n1492), .O(n1511)) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'hac00 */ ;
    defparam LUT__3149.LUTMASK = 16'hac00;
    EFX_LUT4 LUT__3150 (.I0(\snapshot.edge_bits [1]), .I1(\snapshot.gray [11]), 
            .I2(\snapshot.top_half ), .I3(n1351), .O(n1512)) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'h3500 */ ;
    defparam LUT__3150.LUTMASK = 16'h3500;
    EFX_LUT4 LUT__3151 (.I0(n1351), .I1(\snapshot.rgb [27]), .I2(n1512), 
            .I3(n1353), .O(n1513)) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'hf100 */ ;
    defparam LUT__3151.LUTMASK = 16'hf100;
    EFX_LUT4 LUT__3152 (.I0(n1510), .I1(n1511), .I2(n1508), .I3(n1513), 
            .O(n574_5[3])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'h00fe */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(71)
    defparam LUT__3152.LUTMASK = 16'h00fe;
    EFX_LUT4 LUT__3153 (.I0(\snapshot.mode [0]), .I1(\snapshot.gray [12]), 
            .I2(n1484), .I3(\snapshot.mode [2]), .O(n1514)) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'h004f */ ;
    defparam LUT__3153.LUTMASK = 16'h004f;
    EFX_LUT4 LUT__3154 (.I0(\snapshot.ann10_color [4]), .I1(\snapshot.ann11_color [4]), 
            .I2(\snapshot.ann [2]), .I3(n1486), .O(n1515)) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'hca00 */ ;
    defparam LUT__3154.LUTMASK = 16'hca00;
    EFX_LUT4 LUT__3155 (.I0(n1488), .I1(\snapshot.ann01_color [4]), .I2(n1515), 
            .I3(n1346), .O(n1516)) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'hf800 */ ;
    defparam LUT__3155.LUTMASK = 16'hf800;
    EFX_LUT4 LUT__3156 (.I0(\snapshot.edge_color [4]), .I1(\snapshot.rgb [28]), 
            .I2(n1491), .I3(n1492), .O(n1517)) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'hac00 */ ;
    defparam LUT__3156.LUTMASK = 16'hac00;
    EFX_LUT4 LUT__3157 (.I0(\snapshot.edge_bits [1]), .I1(\snapshot.gray [12]), 
            .I2(\snapshot.top_half ), .I3(n1351), .O(n1518)) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'h3500 */ ;
    defparam LUT__3157.LUTMASK = 16'h3500;
    EFX_LUT4 LUT__3158 (.I0(n1351), .I1(\snapshot.rgb [28]), .I2(n1518), 
            .I3(n1353), .O(n1519)) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'hf100 */ ;
    defparam LUT__3158.LUTMASK = 16'hf100;
    EFX_LUT4 LUT__3159 (.I0(n1516), .I1(n1517), .I2(n1514), .I3(n1519), 
            .O(n574_6[4])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'h00fe */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(71)
    defparam LUT__3159.LUTMASK = 16'h00fe;
    EFX_LUT4 LUT__3160 (.I0(\snapshot.mode [0]), .I1(\snapshot.gray [13]), 
            .I2(n1484), .I3(\snapshot.mode [2]), .O(n1520)) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'h004f */ ;
    defparam LUT__3160.LUTMASK = 16'h004f;
    EFX_LUT4 LUT__3161 (.I0(\snapshot.ann10_color [5]), .I1(\snapshot.ann11_color [5]), 
            .I2(\snapshot.ann [2]), .I3(n1486), .O(n1521)) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'hca00 */ ;
    defparam LUT__3161.LUTMASK = 16'hca00;
    EFX_LUT4 LUT__3162 (.I0(n1488), .I1(\snapshot.ann01_color [5]), .I2(n1521), 
            .I3(n1346), .O(n1522)) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'hf800 */ ;
    defparam LUT__3162.LUTMASK = 16'hf800;
    EFX_LUT4 LUT__3163 (.I0(\snapshot.edge_color [5]), .I1(\snapshot.rgb [29]), 
            .I2(n1491), .I3(n1492), .O(n1523)) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'hac00 */ ;
    defparam LUT__3163.LUTMASK = 16'hac00;
    EFX_LUT4 LUT__3164 (.I0(\snapshot.edge_bits [1]), .I1(\snapshot.gray [13]), 
            .I2(\snapshot.top_half ), .I3(n1351), .O(n1524)) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'h3500 */ ;
    defparam LUT__3164.LUTMASK = 16'h3500;
    EFX_LUT4 LUT__3165 (.I0(n1351), .I1(\snapshot.rgb [29]), .I2(n1524), 
            .I3(n1353), .O(n1525)) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'hf100 */ ;
    defparam LUT__3165.LUTMASK = 16'hf100;
    EFX_LUT4 LUT__3166 (.I0(n1522), .I1(n1523), .I2(n1520), .I3(n1525), 
            .O(n574_7[5])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'h00fe */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(71)
    defparam LUT__3166.LUTMASK = 16'h00fe;
    EFX_LUT4 LUT__3167 (.I0(\snapshot.mode [0]), .I1(\snapshot.gray [14]), 
            .I2(n1484), .I3(\snapshot.mode [2]), .O(n1526)) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'h004f */ ;
    defparam LUT__3167.LUTMASK = 16'h004f;
    EFX_LUT4 LUT__3168 (.I0(\snapshot.ann10_color [6]), .I1(\snapshot.ann11_color [6]), 
            .I2(\snapshot.ann [2]), .I3(n1486), .O(n1527)) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'hca00 */ ;
    defparam LUT__3168.LUTMASK = 16'hca00;
    EFX_LUT4 LUT__3169 (.I0(n1488), .I1(\snapshot.ann01_color [6]), .I2(n1527), 
            .I3(n1346), .O(n1528)) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'hf800 */ ;
    defparam LUT__3169.LUTMASK = 16'hf800;
    EFX_LUT4 LUT__3170 (.I0(\snapshot.edge_color [6]), .I1(\snapshot.rgb [30]), 
            .I2(n1491), .I3(n1492), .O(n1529)) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'hac00 */ ;
    defparam LUT__3170.LUTMASK = 16'hac00;
    EFX_LUT4 LUT__3171 (.I0(\snapshot.edge_bits [1]), .I1(\snapshot.gray [14]), 
            .I2(\snapshot.top_half ), .I3(n1351), .O(n1530)) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'h3500 */ ;
    defparam LUT__3171.LUTMASK = 16'h3500;
    EFX_LUT4 LUT__3172 (.I0(n1351), .I1(\snapshot.rgb [30]), .I2(n1530), 
            .I3(n1353), .O(n1531)) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'hf100 */ ;
    defparam LUT__3172.LUTMASK = 16'hf100;
    EFX_LUT4 LUT__3173 (.I0(n1528), .I1(n1529), .I2(n1526), .I3(n1531), 
            .O(n574_8[6])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'h00fe */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(71)
    defparam LUT__3173.LUTMASK = 16'h00fe;
    EFX_LUT4 LUT__3174 (.I0(\snapshot.mode [0]), .I1(\snapshot.gray [15]), 
            .I2(n1484), .I3(\snapshot.mode [2]), .O(n1532)) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'h004f */ ;
    defparam LUT__3174.LUTMASK = 16'h004f;
    EFX_LUT4 LUT__3175 (.I0(\snapshot.ann10_color [7]), .I1(\snapshot.ann11_color [7]), 
            .I2(\snapshot.ann [2]), .I3(n1486), .O(n1533)) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'hca00 */ ;
    defparam LUT__3175.LUTMASK = 16'hca00;
    EFX_LUT4 LUT__3176 (.I0(n1488), .I1(\snapshot.ann01_color [7]), .I2(n1533), 
            .I3(n1346), .O(n1534)) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'hf800 */ ;
    defparam LUT__3176.LUTMASK = 16'hf800;
    EFX_LUT4 LUT__3177 (.I0(\snapshot.edge_color [7]), .I1(\snapshot.rgb [31]), 
            .I2(n1491), .I3(n1492), .O(n1535)) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'hac00 */ ;
    defparam LUT__3177.LUTMASK = 16'hac00;
    EFX_LUT4 LUT__3178 (.I0(\snapshot.edge_bits [1]), .I1(\snapshot.gray [15]), 
            .I2(\snapshot.top_half ), .I3(n1351), .O(n1536)) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'h3500 */ ;
    defparam LUT__3178.LUTMASK = 16'h3500;
    EFX_LUT4 LUT__3179 (.I0(n1351), .I1(\snapshot.rgb [31]), .I2(n1536), 
            .I3(n1353), .O(n1537)) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'hf100 */ ;
    defparam LUT__3179.LUTMASK = 16'hf100;
    EFX_LUT4 LUT__3180 (.I0(n1534), .I1(n1535), .I2(n1532), .I3(n1537), 
            .O(n574_9[7])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'h00fe */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(71)
    defparam LUT__3180.LUTMASK = 16'h00fe;
    EFX_LUT4 LUT__3181 (.I0(\snapshot.edge_color [8]), .I1(\snapshot.rgb [32]), 
            .I2(n1491), .I3(n1492), .O(n1538)) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'hac00 */ ;
    defparam LUT__3181.LUTMASK = 16'hac00;
    EFX_LUT4 LUT__3182 (.I0(\snapshot.ann10_color [8]), .I1(\snapshot.ann11_color [8]), 
            .I2(\snapshot.ann [2]), .I3(n1486), .O(n1539)) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'hca00 */ ;
    defparam LUT__3182.LUTMASK = 16'hca00;
    EFX_LUT4 LUT__3183 (.I0(n1488), .I1(\snapshot.ann01_color [8]), .I2(n1539), 
            .I3(n1346), .O(n1540)) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'hf800 */ ;
    defparam LUT__3183.LUTMASK = 16'hf800;
    EFX_LUT4 LUT__3184 (.I0(n1351), .I1(\snapshot.rgb [32]), .I2(n1494), 
            .I3(n1353), .O(n1541)) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'hf100 */ ;
    defparam LUT__3184.LUTMASK = 16'hf100;
    EFX_LUT4 LUT__3185 (.I0(n1540), .I1(n1485), .I2(n1538), .I3(n1541), 
            .O(n574_10[8])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'h00fe */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(71)
    defparam LUT__3185.LUTMASK = 16'h00fe;
    EFX_LUT4 LUT__3186 (.I0(\snapshot.edge_color [9]), .I1(\snapshot.rgb [33]), 
            .I2(n1491), .I3(n1492), .O(n1542)) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'hac00 */ ;
    defparam LUT__3186.LUTMASK = 16'hac00;
    EFX_LUT4 LUT__3187 (.I0(\snapshot.ann10_color [9]), .I1(\snapshot.ann11_color [9]), 
            .I2(\snapshot.ann [2]), .I3(n1486), .O(n1543)) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'hca00 */ ;
    defparam LUT__3187.LUTMASK = 16'hca00;
    EFX_LUT4 LUT__3188 (.I0(n1488), .I1(\snapshot.ann01_color [9]), .I2(n1543), 
            .I3(n1346), .O(n1544)) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'hf800 */ ;
    defparam LUT__3188.LUTMASK = 16'hf800;
    EFX_LUT4 LUT__3189 (.I0(n1351), .I1(\snapshot.rgb [33]), .I2(n1500), 
            .I3(n1353), .O(n1545)) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'hf100 */ ;
    defparam LUT__3189.LUTMASK = 16'hf100;
    EFX_LUT4 LUT__3190 (.I0(n1544), .I1(n1496), .I2(n1542), .I3(n1545), 
            .O(n574_11[9])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'h00fe */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(71)
    defparam LUT__3190.LUTMASK = 16'h00fe;
    EFX_LUT4 LUT__3191 (.I0(\snapshot.edge_color [10]), .I1(\snapshot.rgb [34]), 
            .I2(n1491), .I3(n1492), .O(n1546)) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'hac00 */ ;
    defparam LUT__3191.LUTMASK = 16'hac00;
    EFX_LUT4 LUT__3192 (.I0(\snapshot.ann10_color [10]), .I1(\snapshot.ann11_color [10]), 
            .I2(\snapshot.ann [2]), .I3(n1486), .O(n1547)) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'hca00 */ ;
    defparam LUT__3192.LUTMASK = 16'hca00;
    EFX_LUT4 LUT__3193 (.I0(n1488), .I1(\snapshot.ann01_color [10]), .I2(n1547), 
            .I3(n1346), .O(n1548)) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'hf800 */ ;
    defparam LUT__3193.LUTMASK = 16'hf800;
    EFX_LUT4 LUT__3194 (.I0(n1351), .I1(\snapshot.rgb [34]), .I2(n1506), 
            .I3(n1353), .O(n1549)) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'hf100 */ ;
    defparam LUT__3194.LUTMASK = 16'hf100;
    EFX_LUT4 LUT__3195 (.I0(n1548), .I1(n1502), .I2(n1546), .I3(n1549), 
            .O(n574_12[10])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'h00fe */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(71)
    defparam LUT__3195.LUTMASK = 16'h00fe;
    EFX_LUT4 LUT__3196 (.I0(\snapshot.edge_color [11]), .I1(\snapshot.rgb [35]), 
            .I2(n1491), .I3(n1492), .O(n1550)) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'hac00 */ ;
    defparam LUT__3196.LUTMASK = 16'hac00;
    EFX_LUT4 LUT__3197 (.I0(\snapshot.ann10_color [11]), .I1(\snapshot.ann11_color [11]), 
            .I2(\snapshot.ann [2]), .I3(n1486), .O(n1551)) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'hca00 */ ;
    defparam LUT__3197.LUTMASK = 16'hca00;
    EFX_LUT4 LUT__3198 (.I0(n1488), .I1(\snapshot.ann01_color [11]), .I2(n1551), 
            .I3(n1346), .O(n1552)) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'hf800 */ ;
    defparam LUT__3198.LUTMASK = 16'hf800;
    EFX_LUT4 LUT__3199 (.I0(n1351), .I1(\snapshot.rgb [35]), .I2(n1512), 
            .I3(n1353), .O(n1553)) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'hf100 */ ;
    defparam LUT__3199.LUTMASK = 16'hf100;
    EFX_LUT4 LUT__3200 (.I0(n1552), .I1(n1508), .I2(n1550), .I3(n1553), 
            .O(n574_13[11])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'h00fe */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(71)
    defparam LUT__3200.LUTMASK = 16'h00fe;
    EFX_LUT4 LUT__3201 (.I0(\snapshot.edge_color [12]), .I1(\snapshot.rgb [36]), 
            .I2(n1491), .I3(n1492), .O(n1554)) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'hac00 */ ;
    defparam LUT__3201.LUTMASK = 16'hac00;
    EFX_LUT4 LUT__3202 (.I0(\snapshot.ann10_color [12]), .I1(\snapshot.ann11_color [12]), 
            .I2(\snapshot.ann [2]), .I3(n1486), .O(n1555)) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'hca00 */ ;
    defparam LUT__3202.LUTMASK = 16'hca00;
    EFX_LUT4 LUT__3203 (.I0(n1488), .I1(\snapshot.ann01_color [12]), .I2(n1555), 
            .I3(n1346), .O(n1556)) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'hf800 */ ;
    defparam LUT__3203.LUTMASK = 16'hf800;
    EFX_LUT4 LUT__3204 (.I0(n1351), .I1(\snapshot.rgb [36]), .I2(n1518), 
            .I3(n1353), .O(n1557)) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'hf100 */ ;
    defparam LUT__3204.LUTMASK = 16'hf100;
    EFX_LUT4 LUT__3205 (.I0(n1556), .I1(n1514), .I2(n1554), .I3(n1557), 
            .O(n574_14[12])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'h00fe */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(71)
    defparam LUT__3205.LUTMASK = 16'h00fe;
    EFX_LUT4 LUT__3206 (.I0(\snapshot.edge_color [13]), .I1(\snapshot.rgb [37]), 
            .I2(n1491), .I3(n1492), .O(n1558)) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'hac00 */ ;
    defparam LUT__3206.LUTMASK = 16'hac00;
    EFX_LUT4 LUT__3207 (.I0(\snapshot.ann10_color [13]), .I1(\snapshot.ann11_color [13]), 
            .I2(\snapshot.ann [2]), .I3(n1486), .O(n1559)) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'hca00 */ ;
    defparam LUT__3207.LUTMASK = 16'hca00;
    EFX_LUT4 LUT__3208 (.I0(n1488), .I1(\snapshot.ann01_color [13]), .I2(n1559), 
            .I3(n1346), .O(n1560)) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'hf800 */ ;
    defparam LUT__3208.LUTMASK = 16'hf800;
    EFX_LUT4 LUT__3209 (.I0(n1351), .I1(\snapshot.rgb [37]), .I2(n1524), 
            .I3(n1353), .O(n1561)) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'hf100 */ ;
    defparam LUT__3209.LUTMASK = 16'hf100;
    EFX_LUT4 LUT__3210 (.I0(n1560), .I1(n1520), .I2(n1558), .I3(n1561), 
            .O(n574_15[13])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'h00fe */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(71)
    defparam LUT__3210.LUTMASK = 16'h00fe;
    EFX_LUT4 LUT__3211 (.I0(\snapshot.edge_color [14]), .I1(\snapshot.rgb [38]), 
            .I2(n1491), .I3(n1492), .O(n1562)) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'hac00 */ ;
    defparam LUT__3211.LUTMASK = 16'hac00;
    EFX_LUT4 LUT__3212 (.I0(\snapshot.ann10_color [14]), .I1(\snapshot.ann11_color [14]), 
            .I2(\snapshot.ann [2]), .I3(n1486), .O(n1563)) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'hca00 */ ;
    defparam LUT__3212.LUTMASK = 16'hca00;
    EFX_LUT4 LUT__3213 (.I0(n1488), .I1(\snapshot.ann01_color [14]), .I2(n1563), 
            .I3(n1346), .O(n1564)) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'hf800 */ ;
    defparam LUT__3213.LUTMASK = 16'hf800;
    EFX_LUT4 LUT__3214 (.I0(n1351), .I1(\snapshot.rgb [38]), .I2(n1530), 
            .I3(n1353), .O(n1565)) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'hf100 */ ;
    defparam LUT__3214.LUTMASK = 16'hf100;
    EFX_LUT4 LUT__3215 (.I0(n1564), .I1(n1526), .I2(n1562), .I3(n1565), 
            .O(n574_16[14])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'h00fe */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(71)
    defparam LUT__3215.LUTMASK = 16'h00fe;
    EFX_LUT4 LUT__3216 (.I0(\snapshot.edge_color [15]), .I1(\snapshot.rgb [39]), 
            .I2(n1491), .I3(n1492), .O(n1566)) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'hac00 */ ;
    defparam LUT__3216.LUTMASK = 16'hac00;
    EFX_LUT4 LUT__3217 (.I0(\snapshot.ann10_color [15]), .I1(\snapshot.ann11_color [15]), 
            .I2(\snapshot.ann [2]), .I3(n1486), .O(n1567)) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'hca00 */ ;
    defparam LUT__3217.LUTMASK = 16'hca00;
    EFX_LUT4 LUT__3218 (.I0(n1488), .I1(\snapshot.ann01_color [15]), .I2(n1567), 
            .I3(n1346), .O(n1568)) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'hf800 */ ;
    defparam LUT__3218.LUTMASK = 16'hf800;
    EFX_LUT4 LUT__3219 (.I0(n1351), .I1(\snapshot.rgb [39]), .I2(n1536), 
            .I3(n1353), .O(n1569)) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'hf100 */ ;
    defparam LUT__3219.LUTMASK = 16'hf100;
    EFX_LUT4 LUT__3220 (.I0(n1568), .I1(n1532), .I2(n1566), .I3(n1569), 
            .O(n574_17[15])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'h00fe */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(71)
    defparam LUT__3220.LUTMASK = 16'h00fe;
    EFX_LUT4 LUT__3221 (.I0(\snapshot.edge_color [16]), .I1(\snapshot.rgb [40]), 
            .I2(n1491), .I3(n1492), .O(n1570)) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'hac00 */ ;
    defparam LUT__3221.LUTMASK = 16'hac00;
    EFX_LUT4 LUT__3222 (.I0(\snapshot.ann10_color [16]), .I1(\snapshot.ann11_color [16]), 
            .I2(\snapshot.ann [2]), .I3(n1486), .O(n1571)) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'hca00 */ ;
    defparam LUT__3222.LUTMASK = 16'hca00;
    EFX_LUT4 LUT__3223 (.I0(n1488), .I1(\snapshot.ann01_color [16]), .I2(n1571), 
            .I3(n1346), .O(n1572)) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'hf800 */ ;
    defparam LUT__3223.LUTMASK = 16'hf800;
    EFX_LUT4 LUT__3224 (.I0(n1351), .I1(\snapshot.rgb [40]), .I2(n1494), 
            .I3(n1353), .O(n1573)) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'hf100 */ ;
    defparam LUT__3224.LUTMASK = 16'hf100;
    EFX_LUT4 LUT__3225 (.I0(n1572), .I1(n1485), .I2(n1570), .I3(n1573), 
            .O(n574_18[16])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'h00fe */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(71)
    defparam LUT__3225.LUTMASK = 16'h00fe;
    EFX_LUT4 LUT__3226 (.I0(\snapshot.edge_color [17]), .I1(\snapshot.rgb [41]), 
            .I2(n1491), .I3(n1492), .O(n1574)) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'hac00 */ ;
    defparam LUT__3226.LUTMASK = 16'hac00;
    EFX_LUT4 LUT__3227 (.I0(\snapshot.ann10_color [17]), .I1(\snapshot.ann11_color [17]), 
            .I2(\snapshot.ann [2]), .I3(n1486), .O(n1575)) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'hca00 */ ;
    defparam LUT__3227.LUTMASK = 16'hca00;
    EFX_LUT4 LUT__3228 (.I0(n1488), .I1(\snapshot.ann01_color [17]), .I2(n1575), 
            .I3(n1346), .O(n1576)) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'hf800 */ ;
    defparam LUT__3228.LUTMASK = 16'hf800;
    EFX_LUT4 LUT__3229 (.I0(n1351), .I1(\snapshot.rgb [41]), .I2(n1500), 
            .I3(n1353), .O(n1577)) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'hf100 */ ;
    defparam LUT__3229.LUTMASK = 16'hf100;
    EFX_LUT4 LUT__3230 (.I0(n1576), .I1(n1496), .I2(n1574), .I3(n1577), 
            .O(n574_19[17])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'h00fe */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(71)
    defparam LUT__3230.LUTMASK = 16'h00fe;
    EFX_LUT4 LUT__3231 (.I0(\snapshot.edge_color [18]), .I1(\snapshot.rgb [42]), 
            .I2(n1491), .I3(n1492), .O(n1578)) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'hac00 */ ;
    defparam LUT__3231.LUTMASK = 16'hac00;
    EFX_LUT4 LUT__3232 (.I0(\snapshot.ann10_color [18]), .I1(\snapshot.ann11_color [18]), 
            .I2(\snapshot.ann [2]), .I3(n1486), .O(n1579)) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'hca00 */ ;
    defparam LUT__3232.LUTMASK = 16'hca00;
    EFX_LUT4 LUT__3233 (.I0(n1488), .I1(\snapshot.ann01_color [18]), .I2(n1579), 
            .I3(n1346), .O(n1580)) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'hf800 */ ;
    defparam LUT__3233.LUTMASK = 16'hf800;
    EFX_LUT4 LUT__3234 (.I0(n1351), .I1(\snapshot.rgb [42]), .I2(n1506), 
            .I3(n1353), .O(n1581)) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'hf100 */ ;
    defparam LUT__3234.LUTMASK = 16'hf100;
    EFX_LUT4 LUT__3235 (.I0(n1580), .I1(n1502), .I2(n1578), .I3(n1581), 
            .O(n574_20[18])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'h00fe */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(71)
    defparam LUT__3235.LUTMASK = 16'h00fe;
    EFX_LUT4 LUT__3236 (.I0(\snapshot.edge_color [19]), .I1(\snapshot.rgb [43]), 
            .I2(n1491), .I3(n1492), .O(n1582)) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'hac00 */ ;
    defparam LUT__3236.LUTMASK = 16'hac00;
    EFX_LUT4 LUT__3237 (.I0(\snapshot.ann10_color [19]), .I1(\snapshot.ann11_color [19]), 
            .I2(\snapshot.ann [2]), .I3(n1486), .O(n1583)) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'hca00 */ ;
    defparam LUT__3237.LUTMASK = 16'hca00;
    EFX_LUT4 LUT__3238 (.I0(n1488), .I1(\snapshot.ann01_color [19]), .I2(n1583), 
            .I3(n1346), .O(n1584)) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'hf800 */ ;
    defparam LUT__3238.LUTMASK = 16'hf800;
    EFX_LUT4 LUT__3239 (.I0(n1351), .I1(\snapshot.rgb [43]), .I2(n1512), 
            .I3(n1353), .O(n1585)) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'hf100 */ ;
    defparam LUT__3239.LUTMASK = 16'hf100;
    EFX_LUT4 LUT__3240 (.I0(n1584), .I1(n1508), .I2(n1582), .I3(n1585), 
            .O(n574_21[19])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'h00fe */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(71)
    defparam LUT__3240.LUTMASK = 16'h00fe;
    EFX_LUT4 LUT__3241 (.I0(\snapshot.edge_color [20]), .I1(\snapshot.rgb [44]), 
            .I2(n1491), .I3(n1492), .O(n1586)) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'hac00 */ ;
    defparam LUT__3241.LUTMASK = 16'hac00;
    EFX_LUT4 LUT__3242 (.I0(\snapshot.ann10_color [20]), .I1(\snapshot.ann11_color [20]), 
            .I2(\snapshot.ann [2]), .I3(n1486), .O(n1587)) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'hca00 */ ;
    defparam LUT__3242.LUTMASK = 16'hca00;
    EFX_LUT4 LUT__3243 (.I0(n1488), .I1(\snapshot.ann01_color [20]), .I2(n1587), 
            .I3(n1346), .O(n1588)) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'hf800 */ ;
    defparam LUT__3243.LUTMASK = 16'hf800;
    EFX_LUT4 LUT__3244 (.I0(n1351), .I1(\snapshot.rgb [44]), .I2(n1518), 
            .I3(n1353), .O(n1589)) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'hf100 */ ;
    defparam LUT__3244.LUTMASK = 16'hf100;
    EFX_LUT4 LUT__3245 (.I0(n1588), .I1(n1514), .I2(n1586), .I3(n1589), 
            .O(n574_22[20])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'h00fe */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(71)
    defparam LUT__3245.LUTMASK = 16'h00fe;
    EFX_LUT4 LUT__3246 (.I0(\snapshot.edge_color [21]), .I1(\snapshot.rgb [45]), 
            .I2(n1491), .I3(n1492), .O(n1590)) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'hac00 */ ;
    defparam LUT__3246.LUTMASK = 16'hac00;
    EFX_LUT4 LUT__3247 (.I0(\snapshot.ann10_color [21]), .I1(\snapshot.ann11_color [21]), 
            .I2(\snapshot.ann [2]), .I3(n1486), .O(n1591)) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'hca00 */ ;
    defparam LUT__3247.LUTMASK = 16'hca00;
    EFX_LUT4 LUT__3248 (.I0(n1488), .I1(\snapshot.ann01_color [21]), .I2(n1591), 
            .I3(n1346), .O(n1592)) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'hf800 */ ;
    defparam LUT__3248.LUTMASK = 16'hf800;
    EFX_LUT4 LUT__3249 (.I0(n1351), .I1(\snapshot.rgb [45]), .I2(n1524), 
            .I3(n1353), .O(n1593)) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'hf100 */ ;
    defparam LUT__3249.LUTMASK = 16'hf100;
    EFX_LUT4 LUT__3250 (.I0(n1592), .I1(n1520), .I2(n1590), .I3(n1593), 
            .O(n574_23[21])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'h00fe */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(71)
    defparam LUT__3250.LUTMASK = 16'h00fe;
    EFX_LUT4 LUT__3251 (.I0(\snapshot.edge_color [22]), .I1(\snapshot.rgb [46]), 
            .I2(n1491), .I3(n1492), .O(n1594)) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'hac00 */ ;
    defparam LUT__3251.LUTMASK = 16'hac00;
    EFX_LUT4 LUT__3252 (.I0(\snapshot.ann10_color [22]), .I1(\snapshot.ann11_color [22]), 
            .I2(\snapshot.ann [2]), .I3(n1486), .O(n1595)) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'hca00 */ ;
    defparam LUT__3252.LUTMASK = 16'hca00;
    EFX_LUT4 LUT__3253 (.I0(n1488), .I1(\snapshot.ann01_color [22]), .I2(n1595), 
            .I3(n1346), .O(n1596)) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'hf800 */ ;
    defparam LUT__3253.LUTMASK = 16'hf800;
    EFX_LUT4 LUT__3254 (.I0(n1351), .I1(\snapshot.rgb [46]), .I2(n1530), 
            .I3(n1353), .O(n1597)) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'hf100 */ ;
    defparam LUT__3254.LUTMASK = 16'hf100;
    EFX_LUT4 LUT__3255 (.I0(n1596), .I1(n1526), .I2(n1594), .I3(n1597), 
            .O(n574_24[22])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'h00fe */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(71)
    defparam LUT__3255.LUTMASK = 16'h00fe;
    EFX_LUT4 LUT__3256 (.I0(\snapshot.edge_color [23]), .I1(\snapshot.rgb [47]), 
            .I2(n1491), .I3(n1492), .O(n1598)) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'hac00 */ ;
    defparam LUT__3256.LUTMASK = 16'hac00;
    EFX_LUT4 LUT__3257 (.I0(\snapshot.ann10_color [23]), .I1(\snapshot.ann11_color [23]), 
            .I2(\snapshot.ann [2]), .I3(n1486), .O(n1599)) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'hca00 */ ;
    defparam LUT__3257.LUTMASK = 16'hca00;
    EFX_LUT4 LUT__3258 (.I0(n1488), .I1(\snapshot.ann01_color [23]), .I2(n1599), 
            .I3(n1346), .O(n1600)) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'hf800 */ ;
    defparam LUT__3258.LUTMASK = 16'hf800;
    EFX_LUT4 LUT__3259 (.I0(n1351), .I1(\snapshot.rgb [47]), .I2(n1536), 
            .I3(n1353), .O(n1601)) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'hf100 */ ;
    defparam LUT__3259.LUTMASK = 16'hf100;
    EFX_LUT4 LUT__3260 (.I0(n1600), .I1(n1532), .I2(n1598), .I3(n1601), 
            .O(n574_25[23])) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_LUT4, LUTMASK=16'h00fe */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(71)
    defparam LUT__3260.LUTMASK = 16'h00fe;
    EFX_ADD \add_3/i8__AUX_ADD_CO  (.I0(1'b0), .I1(1'b0), .CI(n1605), 
            .O(n4)) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(36)
    defparam \add_3/i8__AUX_ADD_CO .I0_POLARITY = 1'b1;
    defparam \add_3/i8__AUX_ADD_CO .I1_POLARITY = 1'b1;
    EFX_ADD \add_4/i12__AUX_ADD_CO  (.I0(1'b0), .I1(1'b0), .CI(n1604), 
            .O(n14)) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(36)
    defparam \add_4/i12__AUX_ADD_CO .I0_POLARITY = 1'b1;
    defparam \add_4/i12__AUX_ADD_CO .I1_POLARITY = 1'b1;
    EFX_ADD \add_15/i8__AUX_ADD_CO  (.I0(1'b0), .I1(1'b0), .CI(n1603), 
            .O(n176)) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(36)
    defparam \add_15/i8__AUX_ADD_CO .I0_POLARITY = 1'b1;
    defparam \add_15/i8__AUX_ADD_CO .I1_POLARITY = 1'b1;
    EFX_ADD \add_16/i12__AUX_ADD_CO  (.I0(1'b0), .I1(1'b0), .CI(n1602), 
            .O(n186)) /* verific EFX_ATTRIBUTE_CELL_NAME=EFX_ADD, I0_POLARITY=1'b1, I1_POLARITY=1'b1 */ ;   // D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_renderer\runs\renderer_map_001\flow\rtl\display_renderer.sv(36)
    defparam \add_16/i12__AUX_ADD_CO .I0_POLARITY = 1'b1;
    defparam \add_16/i12__AUX_ADD_CO .I1_POLARITY = 1'b1;
    
endmodule

//
// Verific Verilog Description of module EFX_LUT4_ddeb67bd_0
// module not written out since it is a black box. 
//


//
// Verific Verilog Description of module EFX_LUT4_ddeb67bd_1
// module not written out since it is a black box. 
//


//
// Verific Verilog Description of module EFX_FF_ddeb67bd_0
// module not written out since it is a black box. 
//


//
// Verific Verilog Description of module EFX_FF_ddeb67bd_1
// module not written out since it is a black box. 
//


//
// Verific Verilog Description of module EFX_ADD_ddeb67bd_0
// module not written out since it is a black box. 
//


//
// Verific Verilog Description of module EFX_LUT4_ddeb67bd_2
// module not written out since it is a black box. 
//


//
// Verific Verilog Description of module EFX_LUT4_ddeb67bd_3
// module not written out since it is a black box. 
//


//
// Verific Verilog Description of module EFX_LUT4_ddeb67bd_4
// module not written out since it is a black box. 
//


//
// Verific Verilog Description of module EFX_LUT4_ddeb67bd_5
// module not written out since it is a black box. 
//


//
// Verific Verilog Description of module EFX_LUT4_ddeb67bd_6
// module not written out since it is a black box. 
//


//
// Verific Verilog Description of module EFX_LUT4_ddeb67bd_7
// module not written out since it is a black box. 
//


//
// Verific Verilog Description of module EFX_LUT4_ddeb67bd_8
// module not written out since it is a black box. 
//


//
// Verific Verilog Description of module EFX_LUT4_ddeb67bd_9
// module not written out since it is a black box. 
//


//
// Verific Verilog Description of module EFX_LUT4_ddeb67bd_10
// module not written out since it is a black box. 
//


//
// Verific Verilog Description of module EFX_LUT4_ddeb67bd_11
// module not written out since it is a black box. 
//


//
// Verific Verilog Description of module EFX_LUT4_ddeb67bd_12
// module not written out since it is a black box. 
//


//
// Verific Verilog Description of module EFX_LUT4_ddeb67bd_13
// module not written out since it is a black box. 
//


//
// Verific Verilog Description of module EFX_LUT4_ddeb67bd_14
// module not written out since it is a black box. 
//


//
// Verific Verilog Description of module EFX_LUT4_ddeb67bd_15
// module not written out since it is a black box. 
//


//
// Verific Verilog Description of module EFX_LUT4_ddeb67bd_16
// module not written out since it is a black box. 
//


//
// Verific Verilog Description of module EFX_LUT4_ddeb67bd_17
// module not written out since it is a black box. 
//


//
// Verific Verilog Description of module EFX_LUT4_ddeb67bd_18
// module not written out since it is a black box. 
//


//
// Verific Verilog Description of module EFX_LUT4_ddeb67bd_19
// module not written out since it is a black box. 
//


//
// Verific Verilog Description of module EFX_LUT4_ddeb67bd_20
// module not written out since it is a black box. 
//


//
// Verific Verilog Description of module EFX_LUT4_ddeb67bd_21
// module not written out since it is a black box. 
//


//
// Verific Verilog Description of module EFX_LUT4_ddeb67bd_22
// module not written out since it is a black box. 
//


//
// Verific Verilog Description of module EFX_LUT4_ddeb67bd_23
// module not written out since it is a black box. 
//


//
// Verific Verilog Description of module EFX_LUT4_ddeb67bd_24
// module not written out since it is a black box. 
//


//
// Verific Verilog Description of module EFX_LUT4_ddeb67bd_25
// module not written out since it is a black box. 
//


//
// Verific Verilog Description of module EFX_LUT4_ddeb67bd_26
// module not written out since it is a black box. 
//


//
// Verific Verilog Description of module EFX_LUT4_ddeb67bd_27
// module not written out since it is a black box. 
//


//
// Verific Verilog Description of module EFX_LUT4_ddeb67bd_28
// module not written out since it is a black box. 
//

