//===============================================//
module single_mem ( input              CLK,

                    input  def::imem_w IMEM_W,
                    output def::imem_r IMEM_R, 
        
                    input  def::dmem_w DMEM_W,
                    output def::dmem_r DMEM_R );

parameter D = 14;
              
logic [3:0][7:0] RAM[0:2**D-1];
logic [31:0] rr_i, rr_d;

//initial
//  $readmemh ("soft/data.txt", RAM);

always_ff@(posedge CLK)
   begin
   if (DMEM_W.WE) 
     begin
     if(DMEM_W.BE[0]) RAM[DMEM_W.ADDR[D-1:0]][0] <= DMEM_W.WD[07:00];
     if(DMEM_W.BE[1]) RAM[DMEM_W.ADDR[D-1:0]][1] <= DMEM_W.WD[15:08];
     if(DMEM_W.BE[2]) RAM[DMEM_W.ADDR[D-1:0]][2] <= DMEM_W.WD[23:16];
     if(DMEM_W.BE[3]) RAM[DMEM_W.ADDR[D-1:0]][3] <= DMEM_W.WD[31:24];
     end
   rr_d <= RAM[DMEM_W.ADDR[D-1:0]];
   end

always_ff@(posedge CLK)
   rr_i <= RAM[IMEM_W.ADDR[D-1:0]];

assign DMEM_R.RD = rr_d;
assign IMEM_R.RD = rr_i;

endmodule
//===============================================//
