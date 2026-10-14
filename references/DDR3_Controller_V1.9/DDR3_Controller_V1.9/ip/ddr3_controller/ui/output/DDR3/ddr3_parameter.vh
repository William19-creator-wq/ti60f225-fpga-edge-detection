
//Generic
`define CKE_WIDTH	1
`define CS_WIDTH	1
`define RANK_WIDTH	1
`define BANK_WIDTH	3
`define ROW_WIDTH	14
`define COL_WIDTH	10
`define DM_WIDTH	2
`define DQS_WIDTH	2
`define DQ_WIDTH	16
`define ODT_WIDTH	1
`define DQ_CNT_WIDTH	4
`define DQS_CNT_WIDTH	1
`define DRAM_WIDTH	8
`define CK_WIDTH	1
`define RANKS	1

//AXI
`define DATA_WIDTH	16
`define ADDR_WIDTH	28
`define AXI_ID_WIDTH	4
`define AXI_ADDR_WIDTH	32
`define AXI_DATA_WIDTH	128

//Timing
`define tCKE	7500
`define tFAW	50000
`define tPRDI	1000000
`define tRAS	34000
`define tRCD	13910
`define tREFI	7800000
`define tRFC	160000
`define tRP	13910
`define tRRD	10000
`define tRTP	7500
`define tWTR	7500
`define tZQI	128000000
`define tZQCS	64
`define tCK	2500
`define CWL	5
`define CL	5
`define nAL	0

//Options
`define RTT_NOM	"20"
`define RTT_WR	"60"
`define BURST_MODE	"8"
`define MEM_ADDR_ORDER	"BANK_ROW_COLUMN"
`define RX_CLK_SEL	2
`define TX_CLK_SEL	3
`define TX_CLK_90EDGE_SEL	0
