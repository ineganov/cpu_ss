//----------------------------------------------------------------//
module mmu (   input              CLK,
               input              RESET,
               if_mmu.mmu         MMU );

logic [31:0] mapped_iaddr, mapped_daddr, unmapped_iaddr, unmapped_daddr, passthru_daddr;
logic [21:0] inst_pfn, data_pfn;
logic inst_hit, data_hit, inst_kernel, inst_mapped, data_kernel, data_mapped, write_ok;

segment_select inst_seg_sel(MMU.INST_VA[31:30], inst_kernel, inst_mapped);
segment_select data_seg_sel(MMU.DATA_VA[31:30], data_kernel, data_mapped);


//22-bit vpn --> 32-22 = 10bit-sized pages (1024 bytes)
//22-bit pfn --> 4GB of phys memory. A slight overkill.
tlb #(4, 22, 22) the_tlb   ( .CLK       ( CLK                  ),   //  input                             
                             .RESET     ( RESET                ),   //  input                             
                             .INDEX     ( MMU.INDEX            ),   //  input  [LOG_WAYS-1:0]  
                             .WR_ENTRY  ( MMU.CP0_ENTRY        ),   //  input  [VPN_W+PFN_W+9:0]  
                             .RD_ENTRY  ( MMU.TLB_ENTRY        ),   //  output [VPN_W+PFN_W+9:0]  
                             .WE_ENTRY  ( MMU.TLB_WE           ),   //  input                             
                             .C_ASID    ( MMU.ASID             ),   //  input  [7:0]      
                             .VPN_I     ( MMU.INST_VA[31:10]   ),   //  input  [VPN_W-1:0]     
                             .HIT_I     ( inst_hit             ),   //  output                            
                             .PFN_I     ( inst_pfn             ),   //  output [PFN_W-1:0]
                             .VPN_D     ( MMU.DATA_VA[31:10]   ),   //  input  [VPN_W-1:0]    
                             .HIT_D     ( data_hit             ),   //  output
                             .WR_OK     ( write_ok             ),   //  output
                             .PFN_D     ( data_pfn             ) ); //  output [PFN_W-1:0]    

assign mapped_iaddr = {inst_pfn, MMU.INST_VA[9:0] };
assign mapped_daddr = {data_pfn, MMU.DATA_VA[9:0] };

assign unmapped_iaddr = {2'b00, MMU.INST_VA[29:0] };
assign unmapped_daddr = {2'b00, MMU.DATA_VA[29:0] };

assign passthru_daddr = MMU.DATA_VA;

assign MMU.INST_PA  = inst_mapped ? mapped_iaddr : unmapped_iaddr;

// Mind the 'passthrough mode' needed for non-memory instructions,
// as the virtal address herein is computed on ALU, along with all the other uses 
assign MMU.DATA_PA  = ~(MMU.DATA_RD | MMU.DATA_WR) ? passthru_daddr :
                                       data_mapped ? mapped_daddr   : 
                                                     unmapped_daddr;

// no translation for ifetch exception:
// occurs if the request is in mapped address space and there is no hit.
// Mind you, this can happen together with ADEL as there are mapped regions
// in kernel space
assign MMU.iTLBL = inst_mapped & ~inst_hit;

// out-of-userspace exception for ifetch:
// occurs if the request is in kernel region, but we're not in kernel mode
assign MMU.iADEL = inst_kernel & ~MMU.KERNEL_MODE;

// write to clean page
assign MMU.dTLBMOD = MMU.DATA_WR & data_mapped & data_hit & ~write_ok; 

// no translation for data load
assign MMU.dTLBL = MMU.DATA_RD & data_mapped & ~data_hit;

// no translation for data store  
assign MMU.dTLBS = MMU.DATA_WR & data_mapped & ~data_hit;

// out-of-userspace for data load   
assign MMU.dADEL = MMU.DATA_RD & data_kernel & ~MMU.KERNEL_MODE;

// out-of-userspace for data store  
assign MMU.dADES = MMU.DATA_WR & data_kernel & ~MMU.KERNEL_MODE;


/*
//-----debug-only------------
always@(posedge CLK)
   if(!RESET)
   begin
//      $display("[%8tps] IMMU: %08x-->%08x", $time, MMU_VA.INST_VA, MMU_PA.INST_PA);
   
      if(MMU_VA.DATA_RD)
      $display("[%8tps] DMMU_LD: %08x-->%08x", $time, MMU_VA.DATA_VA, MMU_PA.DATA_PA);

      if(MMU_VA.DATA_WR)
      $display("[%8tps] DMMU_SW: %08x-->%08x", $time, MMU_VA.DATA_VA, MMU_PA.DATA_PA);
   end
*/
endmodule 
//----------------------------------------------------------------//
module segment_select ( input  [1:0] ADDR_MSB,
                        output       KERNEL_SEG,
                        output       MAPPED_SEG );

assign KERNEL_SEG =  ADDR_MSB[1];
assign MAPPED_SEG = ~ADDR_MSB[1] | ADDR_MSB[0];

endmodule
//----------------------------------------------------------------//
