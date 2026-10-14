
module simple_dual_port_ram
#(
   parameter DATA_WIDTH       = 8,
   parameter ADDR_WIDTH       = 9,
   parameter OUTPUT_REG       = "TRUE",
   parameter RAM_INIT_FILE    = "",
   parameter RAM_INIT_RADIX   = "HEX"
)
(
   input [(DATA_WIDTH-1):0]   wdata,
   input [(ADDR_WIDTH-1):0]   waddr, raddr,
   input                      we, wclk, re, rclk,
   output [(DATA_WIDTH-1):0]  rdata
);

   localparam MEMORY_DEPTH = 2**ADDR_WIDTH;
   localparam MAX_DATA     = (1<<ADDR_WIDTH)-1;
   
   reg [DATA_WIDTH-1:0] ram[MEMORY_DEPTH-1:0];
   wire [DATA_WIDTH-1:0] r_rdata_1P;
   reg [DATA_WIDTH-1:0] r_rdata_2P;

`pragma protect begin_protected
`pragma protect version=1
`pragma protect encrypt_agent="ipecrypt"
`pragma protect encrypt_agent_info="http://ipencrypter.com Version: 20.0.8"
`pragma protect author="author-a"
`pragma protect author_info="author-a-details"
`pragma protect data_method="aes256-cbc"

`pragma protect key_keyowner="Mentor Graphics Corporation"
`pragma protect key_keyname="MGC-VERIF-SIM-RSA-1"
`pragma protect key_method="rsa"
`pragma protect encoding=(enctype="base64", line_length=64, bytes=128)
`pragma protect key_block
ec0GBw/P1rR2yi2O3pixPZMjn1X53echpKiEF6ZQZiOmFpfeuPE1wI7zI8/PU8XC
zCfarzC6qWbW0kuOp24Xx+KYuUFhT1EXEmTpeHhwgbt6PaugYMI97c854fYR/z4Z
puV14Kb6Zt4q7dHt4ZQ2anCmiRD+69ZQDoLvmaYtdfU=
`pragma protect key_keyowner="Aldec"
`pragma protect key_method="rsa"
`pragma protect key_keyname="ALDEC15_001"
`pragma protect encoding=(enctype="base64", line_length=64, bytes=256)
`pragma protect key_block
EwLecH2skBEUh8oarv0vsAaXYe4oU0cLMSlhqlbso56tSHh7wW8xBAEEHmTwnb/3
MMxnJBAfrJ7l/KWw99RoroWov16IcoAQS6TDjtqj5fi0OitNN/H1ZTe528gx0ABI
ArXkRYnlWDEqg3fLTEmfsX7gv5wbuNuVMIo/agdDlCIx3V7ZFSeU2VuxIZWJ5+Zf
OqttsOzV9GgGW0VnAQVPcS8Aj7xTYwQBoQlzrg8Spj3K7qZrbJY2mu42G0mWYj1D
8AANzIHPzIEpoqFh9dkKT2mNHE0EfiGiExkz8brBeDa07NmCDvpYDC3895Iww0HT
/aVRsoztbDnloPcM8XcdbQ==
`pragma protect key_keyowner="Synopsys"
`pragma protect key_method="rsa"
`pragma protect key_keyname="SNPS-VCS-RSA-2"
`pragma protect encoding=(enctype="base64", line_length=64, bytes=128)
`pragma protect key_block
Pcd5Wl8jE/k9M7iFfVWFCBUkr3697I0r0CM/6tV89IRxlvOIYW4xkddXk8G5/GH6
2CAbGpLy0crN2okWhFdX9o2GfwM302heV+hN8NlV+E6yBp/i52VR5QPjFbf5xPb6
8cyNThGVbLqbPtOZopjU6d8Gv6+0Td1TVBEI9cv+8WA=
`pragma protect key_keyowner="Cadence Design Systems."
`pragma protect key_method="rsa"
`pragma protect key_keyname="CDS_RSA_KEY_VER_1"
`pragma protect encoding=(enctype="base64", line_length=64, bytes=256)
`pragma protect key_block
OB4fR92QZez1iItM9wXjFwM/rcIG6r2M3wc2hbdStsc6p/wuzQvvcdx1fIPi5L+R
h3OuU3IUC9mMYQSQbNx1uP+EZ9tUgcjxB3EUM0o4L3HSJsUYkqYLDcDWqFTmBTxn
YTpWD1YsAZBOPwchJbccuYOvVobrci+fJcDC87jPsBiaRLOPZe+u+fEgUThVhxVl
RmL/u4jjBAj0yk4J4qRCAynAmrA4ihwOHNKHfF6ufJ7GwQY6U2nhkdmEkeTjFOm4
N7mbeinHnVPgnxqcXWy8HFIi2y57JVEc1aXokUi1lBe5a+heq6wG2PCvF9jDAmtx
u7UQJB+xDGkExoyo3pqB9A==
`pragma protect key_keyowner="Efinix Inc."
`pragma protect key_keyname="EFX_K01"
`pragma protect key_method="rsa"
`pragma protect encoding=(enctype="base64", line_length=64, bytes=256)
`pragma protect key_block
BIpjqP43nvmXY5fU+qlpD7naW4VRR6NXzzpswjZ3GhHLt0q2XLANa1WJ1B8To2Cr
j+mWpPOkZWzrENXEQDVPPVmwksHFxJEUFbUQFFLsO3jFyiqk3p9tYds9VpAXvRpf
gi2lCKtjq25y3Hhp9MbR/fajEOJs+dIjmPLUQsuHeHAvy4oVJlNfia+WjzqrwCWg
Pws/IMhlXcoiQaMNMYR7bXbCbBZEcha3kU+egvCUQPXyTCw1UOqu4oJVV89oGb97
GtJ1nFYI7av15hQnweV0FSzn7EKL77VzOwn3jXKRsM8QvTC4ELyC4gnEbrHKiX6E
EYDxgi6bGOZ2J3a5gdKOvg==
`pragma protect encoding=(enctype="base64", line_length=64, bytes=928)
`pragma protect data_block
zqlLFPYPkH7GSS8VO9RtQ6FwEALoqUJOJtee3bmsQhN0U6uIIYKFYNf9y4XWSets
K1nQ8YFKSmMhmpjWvzoMitP8C3AaEFTbIREm4U2QW4YOKUkuc1aifBrF2PviDAFO
DnaC3OfvrswUrHogOohuMzWbkREQcHjZaU1AA1+ZpXyXoq3KoVLYyc929SDkbrnZ
fp8Xh439Dz9mGIkqPuB6RCo85leyU1LyodVIlaYr61W4HAr4ai2SRnsBrlGO1r96
Ibi0WmbB66jvHKUrOxEdjwCEegpDKpy7FfkeAxRiavDQEDh7hmy+5Sf03MUW8Q04
5l5DfBGoJd/8CuxPs6kjP/2WER7sNiSYOzRRVdWfnSv0sP6D2n+FtwbUXElGRksh
AVD9Q1ANmlWSE9UbFGsFoj6cnMYaINAKk6Cg2X9Cmma1Fee0RKKVl9/NFGUzm1sa
HPoMdApyEHkc+tOIp3PD+yr/SCwOYCSRKDXIbQMqdDRUJi+rNamV/LUO7jglS3y/
WR4fKR6Rw3lxqpkHapjLMXuPsCZvNehf9dakW0iodO2nRkUnfrQMellmJBog+wAR
4DIH76CfSokk12iXS+Ut55wnlLstBYTft+CgpqopdBugoO58XscSlPN21a4xD8Ju
s+Nelg/No5mBTkEdf0VgEM3qKbJOpGlwFTzKBeQIxEIxswQIqiFLQT3MMCY1bi/E
d7MS/lI5K/M3Y21o4w5g/M1AWHuuS5cDZt3hFxlvrUd0xVLVr7n6ZokjilvbSTwW
vW9d+qFGnpzktkeO1n8x1Y2GbexDxx6pyU9bjzdcQ7oTo25iXJGpAzQsd2CrXxHh
W3Ti20TAaCWRKfNPkwjrMRtXg+g1WVUPMpHTMRYnUATh0d1dMHcXodRg1rcBiCOw
AOh/k6HJah6VsHj7U/znjxdJc6EZBt1pXKK8EJ4T/rfIlBWPVNgwYuKgG4kJhLE0
5DneI+5ghUakzTkhHhqZmB/6Z5xJeY7r98YHEiFfZArSGCVK1Dnh1gWWDRvB2+3Z
hbkJ+GLZPXZ1h9e6gS2p47AThFEQlvqh8s+z9TKDNvG2VemUpzplaKLVlCfrf8vz
Bct6dlYdGSMgZRFehnMqv3OBkiYK7OH/Fs2bz3QpffRyIWk6CiSy5hHowUxAcqnz
ziUD64AzzOn52WzJaKOyQtNHO0jEm4/fxUUwB8iA7RSD8BO8/i1/v2XY+OvbeIct
ftxP65l0ecrqSv3DuAuU6w==
`pragma protect end_protected

endmodule
