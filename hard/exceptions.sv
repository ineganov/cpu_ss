module exceptions (  input          CLK,
                     input          RESET,
                     if_except.excp EXC ); //exceptions interface


logic  [31:0] epc, ejump_vector;
logic  [14:0] e_vec;
logic   [4:0] cause;
logic         e_enter;

assign e_enter = RESET            | 
                 EXC.SYSCALL      |
                 EXC.BREAK        |
                 EXC.RI           |     
                 EXC.CpU          |
                 EXC.OV           |   
                 EXC.dTLBMOD      |
                 EXC.dTLBL        | 
                 EXC.dTLBS        | 
                 EXC.dADEL        | 
                 EXC.dADES        | 
                 EXC.iTLBL        |    
                 EXC.iADEL        |
                 EXC.IBE          |
                 EXC.DBE          |
                 EXC.INT_COUNTER ;    


//Exceptions are in the order of significance
assign e_vec = {EXC.dADEL, EXC.dTLBL, EXC.dADES, EXC.dTLBMOD, EXC.dTLBS, 
                EXC.RI, EXC.CpU, EXC.BREAK, EXC.SYSCALL, EXC.iADEL, EXC.iTLBL, 
                EXC.IBE, EXC.DBE, EXC.OV, EXC.INT_COUNTER};

always_comb
  casex(e_vec)
  15'b1XXXXXXXXXXXXXX: cause = 5'd04; //dADEL
  15'b01XXXXXXXXXXXXX: cause = 5'd02; //dTLBL
  15'b001XXXXXXXXXXXX: cause = 5'd05; //dADES
  15'b0001XXXXXXXXXXX: cause = 5'd01; //dTLBMOD
  15'b00001XXXXXXXXXX: cause = 5'd03; //dTLBS
  15'b000001XXXXXXXXX: cause = 5'd10; //RI
  15'b0000001XXXXXXXX: cause = 5'd11; //CpU
  15'b00000001XXXXXXX: cause = 5'd09; //BREAK
  15'b000000001XXXXXX: cause = 5'd08; //SYSCALL
  15'b0000000001XXXXX: cause = 5'd04; //iADEL
  15'b00000000001XXXX: cause = 5'd02; //iTLBL
  15'b000000000001XXX: cause = 5'd06; //IBE
  15'b0000000000001XX: cause = 5'd07; //DBE
  15'b00000000000001X: cause = 5'd12; //Overflow
  15'b000000000000001: cause = 5'd00; //Counter interrupt
  default:             cause = 5'd00; //default
  endcase

//delay slot compensation
mux2 #(32) epc_sel( EXC.DELAY_SLOT,  EXC.PC_WB, (EXC.PC_WB - 3'd4), epc );

//Exception address vector select
mux2 #(32) vec_sel( RESET, 32'h80000100, 32'h80000000, ejump_vector);

assign EXC.RESET    = e_enter | EXC.ERET;
assign EXC.E_ENTER  = e_enter;
assign EXC.VECTOR   = ejump_vector;

assign EXC.CAUSE   = cause;
assign EXC.EPC     = epc;

endmodule
