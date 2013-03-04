//======================================================================//
module tlb #( parameter LOG_WAYS  = 4,  //num entries = 2**LOG_WAYS
              parameter VPN_WIDTH = 23,
              parameter PFN_WIDTH = 23 )
            
            ( input                             CLK, 
              input                             RESET,

              input              [LOG_WAYS-1:0] INDEX,
              input  [VPN_WIDTH+PFN_WIDTH+10:0] WR_ENTRY,
              output [VPN_WIDTH+PFN_WIDTH+10:0] RD_ENTRY,
              input                             WE_ENTRY,
              input                       [7:0] C_ASID,

              input             [VPN_WIDTH-1:0] VPN_I,   
              output                            HIT_I,
              output            [PFN_WIDTH-1:0] PFN_I,
               
              input             [VPN_WIDTH-1:0] VPN_D,  
              output                            HIT_D,
              output                            WR_OK,
              output            [PFN_WIDTH-1:0] PFN_D );              


logic [2**LOG_WAYS-1:0] way_sel;

logic [VPN_WIDTH+PFN_WIDTH+10:0] rd_line[0:2**LOG_WAYS-1];
logic [PFN_WIDTH-1:0] ipfn_line[0:2**LOG_WAYS-1];
logic [PFN_WIDTH-1:0] dpfn_line[0:2**LOG_WAYS-1];
logic ihit_line[0:2**LOG_WAYS-1];
logic dhit_line[0:2**LOG_WAYS-1];
logic wrok_line[0:2**LOG_WAYS-1];

onehot #(LOG_WAYS) way_sel_onehot(INDEX, way_sel);

genvar i;
generate
   for(i = 0; i < 2**LOG_WAYS; i = i + 1)
   begin: tlb_cell_gen
   tlb_cell #(VPN_WIDTH, PFN_WIDTH) tlbcc ( .CLK       ( CLK                   ),
                                            .RESET     ( RESET                 ),
                                            .WR_ENTRY  ( WR_ENTRY              ),
                                            .RD_ENTRY  ( rd_line[i]            ),
                                            .WE_ENTRY  ( way_sel[i] & WE_ENTRY ),
                                            .C_ASID    ( C_ASID                ),
                                            .VPN_I     ( VPN_I                 ),
                                            .HIT_I     ( ihit_line[i]          ),
                                            .PFN_I     ( ipfn_line[i]          ),
                                            .VPN_D     ( VPN_D                 ),
                                            .HIT_D     ( dhit_line[i]          ),
                                            .WR_OK     ( wrok_line[i]          ),
                                            .PFN_D     ( dpfn_line[i]          ) );
   end 
endgenerate

assign  PFN_D = dpfn_line[ 0] | dpfn_line[ 1] | dpfn_line[ 2] | dpfn_line[ 3] | 
                dpfn_line[ 4] | dpfn_line[ 5] | dpfn_line[ 6] | dpfn_line[ 7] | 
                dpfn_line[ 8] | dpfn_line[ 9] | dpfn_line[10] | dpfn_line[11] | 
                dpfn_line[12] | dpfn_line[13] | dpfn_line[14] | dpfn_line[15] ; 
//               dpfn_line[16] | dpfn_line[17] | dpfn_line[18] | dpfn_line[19] | 
//               dpfn_line[20] | dpfn_line[21] | dpfn_line[22] | dpfn_line[23] | 
//               dpfn_line[24] | dpfn_line[25] | dpfn_line[26] | dpfn_line[27] | 
//               dpfn_line[28] | dpfn_line[29] | dpfn_line[30] | dpfn_line[31] ;

assign  PFN_I = ipfn_line[ 0] | ipfn_line[ 1] | ipfn_line[ 2] | ipfn_line[ 3] | 
                ipfn_line[ 4] | ipfn_line[ 5] | ipfn_line[ 6] | ipfn_line[ 7] | 
                ipfn_line[ 8] | ipfn_line[ 9] | ipfn_line[10] | ipfn_line[11] | 
                ipfn_line[12] | ipfn_line[13] | ipfn_line[14] | ipfn_line[15] ; 
//               ipfn_line[16] | ipfn_line[17] | ipfn_line[18] | ipfn_line[19] | 
//               ipfn_line[20] | ipfn_line[21] | ipfn_line[22] | ipfn_line[23] | 
//               ipfn_line[24] | ipfn_line[25] | ipfn_line[26] | ipfn_line[27] | 
//               ipfn_line[28] | ipfn_line[29] | ipfn_line[30] | ipfn_line[31] ;

assign  HIT_D = dhit_line[ 0] | dhit_line[ 1] | dhit_line[ 2] | dhit_line[ 3] | 
                dhit_line[ 4] | dhit_line[ 5] | dhit_line[ 6] | dhit_line[ 7] | 
                dhit_line[ 8] | dhit_line[ 9] | dhit_line[10] | dhit_line[11] | 
                dhit_line[12] | dhit_line[13] | dhit_line[14] | dhit_line[15] ; 
//               dhit_line[16] | dhit_line[17] | dhit_line[18] | dhit_line[19] | 
//               dhit_line[20] | dhit_line[21] | dhit_line[22] | dhit_line[23] | 
//               dhit_line[24] | dhit_line[25] | dhit_line[26] | dhit_line[27] | 
//               dhit_line[28] | dhit_line[29] | dhit_line[30] | dhit_line[31] ;

assign  HIT_I = ihit_line[ 0] | ihit_line[ 1] | ihit_line[ 2] | ihit_line[ 3] | 
                ihit_line[ 4] | ihit_line[ 5] | ihit_line[ 6] | ihit_line[ 7] | 
                ihit_line[ 8] | ihit_line[ 9] | ihit_line[10] | ihit_line[11] | 
                ihit_line[12] | ihit_line[13] | ihit_line[14] | ihit_line[15] ; 
//               ihit_line[16] | ihit_line[17] | ihit_line[18] | ihit_line[19] | 
//               ihit_line[20] | ihit_line[21] | ihit_line[22] | ihit_line[23] | 
//               ihit_line[24] | ihit_line[25] | ihit_line[26] | ihit_line[27] | 
//               ihit_line[28] | ihit_line[29] | ihit_line[30] | ihit_line[31] ;

assign  WR_OK = wrok_line[ 0] | wrok_line[ 1] | wrok_line[ 2] | wrok_line[ 3] |
                wrok_line[ 4] | wrok_line[ 5] | wrok_line[ 6] | wrok_line[ 7] |
                wrok_line[ 8] | wrok_line[ 9] | wrok_line[10] | wrok_line[11] |
                wrok_line[12] | wrok_line[13] | wrok_line[14] | wrok_line[15] ;

mux16 #(VPN_WIDTH+PFN_WIDTH+11) dmux16( .SEL ( INDEX       ),
                                        .D0  ( rd_line[0]  ),
                                        .D1  ( rd_line[1]  ),
                                        .D2  ( rd_line[2]  ),
                                        .D3  ( rd_line[3]  ),
                                        .D4  ( rd_line[4]  ),
                                        .D5  ( rd_line[5]  ),
                                        .D6  ( rd_line[6]  ),
                                        .D7  ( rd_line[7]  ),
                                        .D8  ( rd_line[8]  ),
                                        .D9  ( rd_line[9]  ),
                                        .D10 ( rd_line[10] ),
                                        .D11 ( rd_line[11] ),
                                        .D12 ( rd_line[12] ),
                                        .D13 ( rd_line[13] ),
                                        .D14 ( rd_line[14] ),
                                        .D15 ( rd_line[15] ),
                                        .Y   ( RD_ENTRY    ) );

endmodule
//======================================================================//
module tlb_cell #( parameter VPN_WIDTH = 23,
                   parameter PFN_WIDTH = 23 )

                 ( input                             CLK,
                   input                             RESET,

                   input  [VPN_WIDTH+PFN_WIDTH+10:0] WR_ENTRY,
                   output [VPN_WIDTH+PFN_WIDTH+10:0] RD_ENTRY,
                   input                             WE_ENTRY,
            
                   input                       [7:0] C_ASID,
                              
                   input             [VPN_WIDTH-1:0] VPN_I,    //[31:9]
                   output                            HIT_I,
                   output            [PFN_WIDTH-1:0] PFN_I,
 
                   input             [VPN_WIDTH-1:0] VPN_D,  
                   output                            HIT_D,
                   output                            WR_OK,
                   output            [PFN_WIDTH-1:0] PFN_D );

logic inst_vpn_match, data_vpn_match, asid_match, g, v, d; //global, valid, dirty
logic           [7:0] asid;
logic [VPN_WIDTH-1:0] vpn; //56 bits per entry for 23-bit vpn & pfn
logic [PFN_WIDTH-1:0] pfn;

ffd #(VPN_WIDTH+PFN_WIDTH+11) entry_reg(CLK, RESET, WE_ENTRY, WR_ENTRY, {d, v, g, asid, vpn, pfn} );

assign inst_vpn_match = (vpn == VPN_I);
assign data_vpn_match = (vpn == VPN_D);
assign asid_match     = (asid == C_ASID);
 

assign HIT_I = v & inst_vpn_match & (asid_match | g);
assign HIT_D = v & data_vpn_match & (asid_match | g);
assign WR_OK = HIT_D & d;
assign RD_ENTRY = {d, v, g, asid, vpn, pfn};

assign PFN_I = HIT_I ? pfn : '0; //'
assign PFN_D = HIT_D ? pfn : '0; //' 

endmodule
