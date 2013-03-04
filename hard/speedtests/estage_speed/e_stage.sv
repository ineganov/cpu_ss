module e_stage( input         CLK, 
                input         RESET,
 
                input   [1:0] FWD_A_SEL,
                input   [1:0] FWD_B_SEL,
                input   [1:0] ALUOUT_SEL,
                input         SRC_A_SEL,
                input         SRC_B_SEL,
 
                input   [4:0] SH,
                input   [7:0] ALU_CTRL,
 
                input   [2:0] BR_TYPE_START,
 
                input  [31:0] START_A,
                input  [31:0] START_B,
                input  [31:0] START_M1,
                input  [31:0] START_M2,
                input  [31:0] START_WB,
                input  [31:0] START_PC,
                input  [31:0] START_IM,
                input  [31:0] START_HI,
                input  [31:0] START_LO,
                input  [31:0] START_CP,
                input  [31:0] START_RT,


                output [31:0] ALUOUT_FINISH,
                output        ALUOV_FINISH,
                output        BR_TAKE_FINISH  );


logic [31:0] src_a_e, src_b_e, aluout_m1, aluout_m2, regfile_wdata_w,
             pc_plus_4_e, immed_extend_e, hi_m1, lo_m1, cp0_out,
             src_a_fwd_e, src_b_fwd_e, aluout_final_e, aluout_mux_e,
             return_target_e, aluout_e, src_a, src_b;

logic [4:0] shamt_e;
logic [2:0] br_type_e;
logic br_inst_e, br_take_e, e_OV_e;

ffd #(32)  start_reg_a(CLK, RESET, 1'b1,  START_A, src_a_e);
ffd #(32)  start_reg_b(CLK, RESET, 1'b1,  START_B, src_b_e);
ffd #(32) start_reg_m1(CLK, RESET, 1'b1, START_M1, aluout_m1);
ffd #(32) start_reg_m2(CLK, RESET, 1'b1, START_M2, aluout_m2);
ffd #(32) start_reg_wb(CLK, RESET, 1'b1, START_WB, regfile_wdata_w);
ffd #(32) start_reg_pc(CLK, RESET, 1'b1, START_PC, pc_plus_4_e);
ffd #(32) start_reg_im(CLK, RESET, 1'b1, START_IM, immed_extend_e);
ffd #(32) start_reg_hi(CLK, RESET, 1'b1, START_HI, hi_m1);
ffd #(32) start_reg_lo(CLK, RESET, 1'b1, START_LO, lo_m1);
ffd #(32) start_reg_cp(CLK, RESET, 1'b1, START_CP, cp0_out);
ffd #(32) start_reg_rt(CLK, RESET, 1'b1, START_RT, return_target_e);

ffd #(5) start_shamt(CLK, RESET, 1'b1, SH, shamt_e);
ffd #(3) start_brtype(CLK, RESET, 1'b1, BR_TYPE_START, br_type_e);


mux4 fwd_src_a(FWD_A_SEL, src_a_e,         //00 -- no forwarding
                          aluout_m1,       //01 -- forward from MEM1
                          aluout_m2,       //10 -- forward from MEM2
                          regfile_wdata_w, //11 -- forward from WB
                          src_a_fwd_e );

mux4 fwd_src_b(FWD_B_SEL, src_b_e,         //00 -- no forwarding
                          aluout_m1,       //01 -- forward from MEM1
                          aluout_m2,       //10 -- forward from MEM2
                          regfile_wdata_w, //11 -- forward from WB
                          src_b_fwd_e );

//final alu muxes
mux2 alu_src_a_mux( SRC_A_SEL,
                    src_a_fwd_e,    //0: forwarded src a
                    pc_plus_4_e,    //1: pc+4 for branch target calculation
                    src_a );

mux2 alu_src_b_mux( SRC_B_SEL, 
                    src_b_fwd_e,    //0: forwarded src b 
                    immed_extend_e, //1: immediate
                    src_b );

//-----------Branch logic-------------------//
assign br_inst_e = br_type_e[2] | br_type_e[1] | br_type_e[0];

wire regs_equal = (src_a_fwd_e == src_b_fwd_e);
wire reg_zero   = (src_a_fwd_e == 32'd0);
wire reg_neg    = src_a_fwd_e[31];

mux8 #(1) br_mux( br_type_e,
                  1'b0,                   //3/ 0 -- NORM 
                  1'b1,                   //   1 -- JR   
                  ( regs_equal),          //   2 -- BEQ  
                  (~regs_equal),          //   3 -- BNE  
                  ( reg_neg |  reg_zero), //   4 -- BLEZ 
                  ( reg_neg ),            //   5 -- BLTZ 
                  (~reg_neg ),            //   6 -- BGEZ
                  (~reg_neg & ~reg_zero), //   7 -- BGTZ
                  br_take_e );

alu alu(ALU_CTRL, src_a, src_b, shamt_e, e_OV_e, aluout_e);

mux4 aluout_mux(  ALUOUT_SEL,
                  aluout_e,
                  hi_m1,          //MFHI
                  lo_m1,          //MFLO
                  cp0_out,        //MFC0
                  aluout_mux_e ); 

mux2 ret_target_mux (br_inst_e, aluout_mux_e, return_target_e, aluout_final_e); 

ffd #(32) aluout_finish_reg(CLK, RESET, 1'b1, aluout_final_e, ALUOUT_FINISH);
ffd  #(1)  aluov_finish_reg(CLK, RESET, 1'b1, e_OV_e,         ALUOV_FINISH);
ffd  #(1)     br_finish_reg(CLK, RESET, 1'b1, br_take_e,      BR_TAKE_FINISH);

endmodule










//=============================================================//
module ffd #( parameter WIDTH = 32)
            ( input                    CLK, 
              input                    RESET,
              input                    EN,
              input        [WIDTH-1:0] D,
              output logic [WIDTH-1:0] Q );
                 
always_ff @(posedge CLK)
  if (RESET)  Q <= 0;
  else if(EN) Q <= D;

endmodule
//=============================================================//
module mux2 #(parameter WIDTH = 32)
             ( input             S,
               input [WIDTH-1:0] D0,
               input [WIDTH-1:0] D1,
               output[WIDTH-1:0] Y);

assign Y = S ? D1 : D0;

endmodule
//=============================================================//
module mux4 #(parameter WIDTH = 32)
             ( input [1:0] S,
               input [WIDTH-1:0] D0, D1, D2, D3,
               output[WIDTH-1:0] Y);

assign Y = S[1] ? (S[0] ? D3 : D2)
                : (S[0] ? D1 : D0);
                
endmodule
//=============================================================//
module mux8 #(parameter WIDTH = 32)
             ( input [2:0]       S,
               input [WIDTH-1:0] D0, D1, D2, D3, D4, D5, D6, D7,
               output[WIDTH-1:0] Y);

assign Y = S[2] ? (S[1] ? (S[0] ? D7 : D6) :
                          (S[0] ? D5 : D4)):
                  (S[1] ? (S[0] ? D3 : D2) :
                          (S[0] ? D1 : D0));

endmodule