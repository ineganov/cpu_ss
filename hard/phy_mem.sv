module phy_mem ( input         CLK,
                 input         RESET,
                 output  [7:0] LEDS,
                 if_memory.mem MEM );

parameter RAM_DEPTH = 14; //num_words = 2^D; bytes = 2^(D+2)

logic [RAM_DEPTH-1:0] imem_addr, dmem_addr, io_addr;
logic          [31:0] imem_data, dmem_data, dmem_data_m, io_data, wdata;
logic           [3:0] dmem_be;
logic                 dmem_we, io_request, io_request_q;

assign imem_addr = MEM.iADDR[RAM_DEPTH-1:0];
assign dmem_addr = MEM.dADDR[RAM_DEPTH-1:0];
assign   io_addr = MEM.dADDR[RAM_DEPTH-1:0];

assign io_request = MEM.dADDR[RAM_DEPTH];
assign dmem_be = MEM.BE;
assign dmem_we = MEM.WE & ~io_request;
assign wdata   = MEM.WD;


//Raise Instruction Bus Error on any tick we try to fetch instruction not from memory
assign MEM.IBE = (MEM.iADDR[29:RAM_DEPTH+1] != '0); //'

//Raise Data Bus Error on read/write requests to reserved regions 
assign MEM.DBE = (MEM.RE  | MEM.WE) & (MEM.dADDR[29:RAM_DEPTH+1] != '0); //'

//ffd #(1) ibe_reg(CLK,  RESET,  1'b1, ibe,        MEM.IBE);
//ffd #(1) dbe_reg(CLK,  RESET,  1'b1, dbe,        MEM.DBE);
ffd #(1) iorq_reg(CLK, RESET, 1'b1, io_request, io_request_q);

onchip_ram #(RAM_DEPTH) 
           onchip_ram ( .CLK    ( CLK       ),  //input          
                        .I_ADDR ( imem_addr ),  //input  [D-1:0] 
                        .I_RD   ( imem_data ),  //output  [31:0]  
                        .D_ADDR ( dmem_addr ),  //input  [D-1:0] 
                        .D_WE   ( dmem_we   ),  //input          
                        .D_BE   ( dmem_be   ),  //input    [3:0] 
                        .D_WD   ( wdata     ),  //input   [31:0] 
                        .D_RD   ( dmem_data )); //output  [31:0] 

assign io_data = 32'hFEEDDEAD;


ffd #(8) led_reg(CLK, 1'b0, io_request, wdata[7:0], LEDS);

mux2 io_or_mem(io_request_q, dmem_data, io_data, dmem_data_m );

assign MEM.iDATA = imem_data;
assign MEM.dDATA = dmem_data_m;

endmodule
