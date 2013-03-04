module datapath ( input              CLK,
//                input              RESET,
                  input              RUN,

                 //Controller iface
                  output def::c_inst INST_O,
                  input  def::ctrl   CI, //control input

                 //Hazard unit iface
                  if_hazard.dpath    HZRD,

                 //MMU interface
                  if_mmu.dpath       MMU,

                 //Coprocessor 0 interface
                  if_cp0.dpath       CP0,

                 //Exception unit interface
                  if_except.dpath    EXC, 

                 //External inst and data memory iface
                  if_memory.dpath    MEM );


//------------------------WIRE DEFINITIONS-----------------------------------//
//FETCH_1:
logic [31:0] next_pc, pc_f1, pc_plus_4_f1;
logic        ien_f1, exc_f1;

//FETCH_2
logic [31:0] inst_f2, pc_f2;
logic  [4:0] rs_f2, rt_f2;
logic        ien_f2, ien_f2e, exc_f2;
logic        e_iADEL_f2, e_iTLBL_f2;

//DECODE:
logic [31:0] inst_d, pc_plus_4_d, pc_d, regfile_wdata_w, immed_extend_d,
            rd1_d, rd2_d;
logic        write_cp0_d, ien_d;
logic        RI, CP_UNUSBL, e_IBE_d, e_iADEL_d, e_iTLBL_d;

//EXECUTE:
logic [31:0] branch_target_e, jump_target_e, return_target_e, pc_plus_4_e, pc_e, src_a_e, src_b_e,  
            src_a_fwd_e, src_b_fwd_e, immed_extend_e, aluout_e, aluout_mux_e, aluout_final_e,
            rd1_e, rd2_e;

logic [25:0] inst_e;
logic  [7:0] alu_op_e;
logic  [4:0] reg_dst_addr_e, rs_e, rt_e, rd_e, shamt_e;
logic  [2:0] br_type_e;
logic  [1:0] reg_dst_e, mfcop_sel_e, mem_optype_e;
logic        write_reg_e, write_mem_e, aluormem_e, multiply_e, 
            link_e, mem_partial_e, alu_a_sel_e, alu_b_sel_e,
            write_cp0_e, tlb_read_e, tlb_write_e,
            tlb_write_idx_e, ien_e, jump_e, br_inst_e, br_take_e;

logic        e_OV_e, e_iADEL_e, e_iTLBL_e, e_SYSCALL_e, e_BREAK_e, e_RI_e, 
            e_CpU_e, e_IBE_e, eret_e;


//MEM1: (DATA TLB LOOKUP)
logic [31:0] aluout_m1, pc_m1, src_b_m1, dmem_wd_m1, BAD_VA_m1, hi_m1, lo_m1;
logic  [4:0] reg_dst_addr_m1;
logic  [3:0] dmem_be_m1;
logic  [1:0] mem_optype_m1;
logic        br_inst_m1, write_reg_m1, write_mem_m1, aluormem_m1, mem_partial_m1,
            ien_m1, multiply_m1, madd_m1, signed_op_m1, write_mem_real_m1;
logic        e_OV_m1, e_iADEL_m1, e_iTLBL_m1, e_SYSCALL_m1, e_BREAK_m1, e_RI_m1, e_CpU_m1,
            e_IBE_m1, eret_m1;


//MEM2: (FETCH/STORE DATA)
logic [31:0] aluout_m2, pc_m2, dmem_wd_m2, BAD_VA_m2, mem_reordered_m2;
logic  [4:0] reg_dst_addr_m2;
logic  [3:0] dmem_be_m2;
logic  [1:0] mem_optype_m2;
logic        br_inst_m2, write_reg_m2, write_mem_m2, aluormem_m2, mem_partial_m2,
            ien_m2, eret_m2;

logic        e_OV_m2, e_iADEL_m2, e_iTLBL_m2, e_SYSCALL_m2, e_BREAK_m2, e_RI_m2, e_CpU_m2,
            e_IBE_m2, e_dTLBMOD_m2, e_dTLBL_m2, e_dTLBS_m2, e_dADEL_m2, e_dADES_m2;


//WRITEBACK:
logic [31:0] aluout_w, dmem_data_w, mem_reordered_w, pc_w, BAD_VA_w;
logic  [4:0] reg_dst_addr_w;
logic  [1:0] mem_optype_w;
logic        mem_partial_w, br_inst_w, write_reg_w, aluormem_w, delay_slot_w, eret_w, ien_w;

logic        e_OV_w, e_iADEL_w, e_iTLBL_w, e_SYSCALL_w, e_BREAK_w, e_RI_w, e_CpU_w,
            e_IBE_w, e_DBE_w, e_dTLBMOD_w, e_dTLBL_w, e_dTLBS_w, e_dADEL_w, e_dADES_w;

//------------------------FETCH STAGE----------------------------------------//
assign pc_plus_4_f1 = pc_f1 + 4;

wire [1:0] next_pc_select = EXC.E_ENTER   ? 2'b11 :
                            eret_m2       ? 2'b10 : 
                            br_take_e     ? 2'b01 :
                                            2'b00 ;

mux4  pc_src_mux( next_pc_select,
                  pc_plus_4_f1,     // 00: pc = pc + 4
                  branch_target_e,    // 01: conditional branch
                  EXC.EPC_Q,        // 10: Exception return as in CP0
                  EXC.VECTOR,       // 11: Exception vector
                  next_pc );

ffd #(32) pc_reg(CLK, 1'b0, ~HZRD.STALL & RUN,
                                next_pc,
                                pc_f1 );

//-------------------------FETCH_1 STAGE-------------------------------------//
//-----------IO BLOCK-----------//
assign MMU.INST_VA = pc_f1;
//     MMU.INST_PA  --> pipe_reg_f2

assign MEM.iADDR = MMU.INST_PA[31:2];
//     MEM.iDATA --> pipe_reg_F2
//------------------------------//

assign exc_f1 = MMU.iTLBL | MMU.iADEL;
assign ien_f1 = ~(br_take_e | exc_f1);

//-----------IO BLOCK-----------//
//     <-- CI
//------------------------------//


ffd #(35) pipe_reg_F2(CLK, EXC.RESET, ~HZRD.STALL & RUN, 
                              { ien_f1,
                                MMU.iTLBL,
                                MMU.iADEL,
                                pc_f1 }, 
                              { ien_f2e,
                                e_iTLBL_f2,
                                e_iADEL_f2,
                                pc_f2 } );

//-------------------------FETCH_2 STAGE-------------------------------------//


assign ien_f2  = ien_f2e & ~br_take_e;
assign inst_f2 = (ien_f2 & ~MEM.IBE) ? MEM.iDATA : 32'h00000000;

assign rs_f2 = inst_f2[25:21];//MEM.iDATA[25:21];
assign rt_f2 = inst_f2[20:16];//MEM.iDATA[20:16];

ffd #(68) pipe_reg_D(CLK, EXC.RESET, ~HZRD.STALL & RUN, 
                              { ien_f2,       // 1/
                                inst_f2,      //32/
                                MEM.IBE,      // 1/
                                e_iTLBL_f2,   // 1/
                                e_iADEL_f2,   // 1/
                                pc_f2 },      //32/ 
                              { ien_d,        // 1/
                                inst_d,       //32/
                                e_IBE_d,      // 1/
                                e_iTLBL_d,    // 1/
                                e_iADEL_d,    // 1/
                                pc_d });      //32/
//---------------------------------------------------------------------------//


//------------------------DECODE STAGE---------------------------------------//
//-----------IO BLOCK-----------//
assign INST_O.OPCODE = inst_d[31:26];  
assign INST_O.FCODE  = inst_d[5:0];
assign INST_O.RS     = inst_d[25:21]; 
assign INST_O.RT     = inst_d[20:16];

assign HZRD.RS_D = inst_d[25:21]; //rs_d;
assign HZRD.RT_D = inst_d[20:16]; //rt_d;

assign RI = CI.NOT_IMPLTD;
assign CP_UNUSBL = (CI.PRIVILEGED & ~CP0.KERNEL_MODE);
//  <-- CI
//------------------------------//

regfile rf_unit(.CLK        (CLK              ),
                .WE         (write_reg_w      ), 
                .RD_ADDR_1  (rs_f2            ),  //in_rd_addr
                .RD_ADDR_2  (rt_f2            ),  //in_rd_addr
                .WR_ADDR_3  (reg_dst_addr_w   ),  //in_wr_addr
                .W_DATA     (regfile_wdata_w  ),  //in
                .R_DATA_1   (rd1_d            ),  //out
                .R_DATA_2   (rd2_d            )); //out

//------IMMEDIATE EXTENSION--------                
immed_extend immed_ext_unit(CI.IMMED_EXT, inst_d[15:0], immed_extend_d);

assign write_cp0_d = CI.WRITE_CP0 & ~CP_UNUSBL;

assign pc_plus_4_d = pc_d + 3'd4;


ffd #(224) pipe_reg_E(CLK, EXC.RESET | HZRD.STALL, RUN,
                  {  ien_d,             // 1/ instruction enable
                     write_cp0_d,       // 1/ write coprocessor0
                     CI.WRITE_REG,      // 1/ write to register file
                     CI.TLB_READ,       // 1/ TLB read request (changes state!)
                     CI.TLB_WRITE,      // 1/ TLB write request
                     CI.TLB_WRITE_IDX,  // 1/ TLB write from index (1) or random (0)
                     CI.WRITE_MEM,      // 1/ write data memory
                     CI.MEM_PARTIAL,    // 1/ memory byte- or halfword access
                     CI.MEM_OPTYPE,     // 2/ mem op: 00-ubyte, 01-uhalf, 10-sb, 11-sh
                     CI.ALUORMEM_WR,    // 1/ write regfile from alu or from memory
                     CI.MULTIPLY,       // 1/ do multiplication and write hi&lo
                     CI.BRANCH_TYPE,    // 3/ branch type
                     CI.JUMP,           // 1/ j-type jump
                     CI.ALU_OP,         // 8/ ALU Operation select
                     CI.REG_DST,        // 2/ write destination in regfile (0 - rt, 1 - rd)
                     CI.MFCOP_SEL,      // 2/ mfrom coprocessor selector
                     CI.ALU_SRC_A,      // 1/ alu src a
                     CI.ALU_SRC_B,      // 1/ alu src b
                     rd1_d,             //32/ regfile operand A
                     rd2_d,             //32/ regfile operand B
                     inst_d[25:0],      //26/ RS, RT, RD, SHAMT / Jump addr
                     immed_extend_d,    //32/ extended immediate
                     pc_plus_4_d,       //32/ pc plus 4
                     CI.JUMP_ERET,      // 1/ eret instruction
                     e_IBE_d,           // 1/ exception bit
                     e_iTLBL_d,         // 1/ exception bit
                     e_iADEL_d,         // 1/ exception bit
                     CI.SYSCALL,        // 1/ exception bit
                     CI.BREAK,          // 1/ exception bit
                     RI,                // 1/ exception bit
                     CP_UNUSBL,         // 1/ exception bit
                     pc_d  },           //32/ pc 

                  {  ien_e,             // 1/ instruction enable
                     write_cp0_e,       // 1/ write coprocessor0
                     write_reg_e,       // 1/ write to register file
                     tlb_read_e,        // 1/ TLB read request (changes state!)
                     tlb_write_e,       // 1/ TLB write request
                     tlb_write_idx_e,   // 1/ TLB write from index (1) or random (0)
                     write_mem_e,       // 1/ write data memory
                     mem_partial_e,     // 1/ memory byte- or halfword access
                     mem_optype_e,      // 2/ mem op: 00-ubyte, 01-uhalf, 10-sb, 11-sh
                     aluormem_e,        // 1/ write regfile from alu or from memory
                     multiply_e,        // 1/ do multiplication and write hi&lo
                     br_type_e,         // 3/ branch type
                     jump_e,            // 1/ j-type jump
                     alu_op_e,          // 8/ ALU Operation select
                     reg_dst_e,         // 2/ write destination in regfile (0 - rt, 1 - rd)
                     mfcop_sel_e,       // 2/ mfrom coprocessor selector
                     alu_a_sel_e,       // 1/ alu src a 
                     alu_b_sel_e,       // 1/ alu src b 
                     rd1_e,             //32/ alu operand A
                     rd2_e,             //32/ alu operand B
                     inst_e,            //26/ rs,rt,rd, shamt, j target
                     immed_extend_e,    //32/ extended immediate
                     pc_plus_4_e,       //32/ pc plus 4
                     eret_e,            // 1/ eret instruction
                     e_IBE_e,           // 1/ exception bit
                     e_iTLBL_e,         // 1/ exception bit
                     e_iADEL_e,         // 1/ exception bit
                     e_SYSCALL_e,       // 1/ exception bit
                     e_BREAK_e,         // 1/ exception bit
                     e_RI_e,            // 1/ exception bit
                     e_CpU_e,           // 1/ exception bit
                     pc_e  });          //32/ pc  
                
//---------------------------------------------------------------------------//

//------------------------EXECUTE STAGE--------------------------------------//
//-----------IO BLOCK-----------//
assign CP0.IDX    = rd_e;
assign CP0.WD     = src_b_fwd_e;
assign CP0.WE     = write_cp0_e;
assign CP0.TLB_RD = tlb_read_e;    
assign MMU.TLB_WE = tlb_write_e;   
assign CP0.TLB_WI = tlb_write_idx_e;

assign HZRD.RS_E = rs_e;
assign HZRD.RT_E = rt_e;
assign HZRD.REGDST_E = reg_dst_addr_e;
assign HZRD.WRITEREG_E = write_reg_e;
assign HZRD.ALUORMEM_E = aluormem_e;
//------------------------------//

assign rs_e    = inst_e[25:21];
assign rt_e    = inst_e[20:16];
assign rd_e    = inst_e[15:11];
assign shamt_e = inst_e[10:06];

mux4 #(5) regfile_wr_addr_mux( reg_dst_e, 
                               rt_e, 
                               rd_e,
                               5'd31, //ret_address
                               5'd31, //ret_address
                               reg_dst_addr_e);

mux4 fwd_src_a(HZRD.ALU_FWD_A, rd1_e,           //00 -- no forwarding
                               aluout_m1,       //01 -- forward from MEM1
                               aluout_m2,       //10 -- forward from MEM2
                               regfile_wdata_w, //11 -- forward from WB
                               src_a_fwd_e );

mux4 fwd_src_b(HZRD.ALU_FWD_B, rd2_e,           //00 -- no forwarding
                               aluout_m1,       //01 -- forward from MEM1
                               aluout_m2,       //10 -- forward from MEM2
                               regfile_wdata_w, //11 -- forward from WB
                               src_b_fwd_e );

mux2 alu_src_a_mux( alu_a_sel_e,
                    src_a_fwd_e,    //0: register file
                    pc_plus_4_e,    //1: pc+4 for branch target calculation
                    src_a_e );

mux2 alu_src_b_mux( alu_b_sel_e, 
                    src_b_fwd_e,    //0: register file 
                    immed_extend_e, //1: immediate
                    src_b_e );

//-----------Branch logic-------------------//
assign br_inst_e = br_type_e[2] | br_type_e[1] | br_type_e[0]; // br_type != 0

//assign branch_target = immed_extend_sl2_d + pc_plus_4_e;
//assign jumpr_target  = src_a_fwd_e; 

assign jump_target_e   = {pc_plus_4_e[31:28], inst_e, 2'b00};
assign return_target_e = pc_e + 4'd8;

mux2 branch_target_mux(jump_e, aluout_e, jump_target_e, branch_target_e);

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


alu alu(alu_op_e, src_a_e, src_b_e, shamt_e, e_OV_e, aluout_e);

mux4 aluout_mux(  mfcop_sel_e,
                  aluout_e,
                  hi_m1,          //MFHI
                  lo_m1,          //MFLO
                  CP0.RD,         //MFC0
                  aluout_mux_e ); 

mux2 ret_target_mux (br_inst_e, aluout_mux_e, return_target_e, aluout_final_e);

ffd #(121) pipe_reg_M1 ( CLK, EXC.RESET, RUN,
                  {  ien_e,             // 1/ instruction enable
                     br_inst_e,         // 1/ branch instruction
                     write_reg_e,       // 1/ write to register file
                     write_mem_e,       // 1/ write data memory
                     multiply_e,        // 1/ multiplication request
                     alu_op_e[6],       // 1/ multiply-add request
                     mem_partial_e,     // 1/ memory byte- or halfword access
                     mem_optype_e,      // 2/ mem op: 00-ubyte, 01-uhalf, 10-sb, 11-sh
                     aluormem_e,        // 1/ write regfile from alu or from memory
                     aluout_final_e,    //32/ ALU result
                     src_b_fwd_e,       //32/ regfile data B
                     reg_dst_addr_e,    // 5/ destination reg addr
                     alu_op_e[7],       // 1/ signed operation
                     eret_e,            // 1/ eret instruction
                     e_OV_e,            // 1/ exception bits
                     e_IBE_e,           // 1/ exception bits
                     e_iTLBL_e,         // 1/ exception bits
                     e_iADEL_e,         // 1/ exception bits
                     e_SYSCALL_e,       // 1/ exception bits
                     e_BREAK_e,         // 1/ exception bits 
                     e_RI_e,            // 1/ exception bits
                     e_CpU_e,           // 1/ exception bits
                     pc_e },            //32/ pc

               
                  {  ien_m1,
                     br_inst_m1,
                     write_reg_m1,
                     write_mem_m1,
                     multiply_m1,
                     madd_m1,
                     mem_partial_m1,         
                     mem_optype_m1,
                     aluormem_m1,
                     aluout_m1,
                     src_b_m1,
                     reg_dst_addr_m1,
                     signed_op_m1,
                     eret_m1,
                     e_OV_m1,
                     e_IBE_m1,
                     e_iTLBL_m1,
                     e_iADEL_m1,
                     e_SYSCALL_m1,
                     e_BREAK_m1,  
                     e_RI_m1, 
                     e_CpU_m1,    
                     pc_m1 });
//---------------------------------------------------------------------------//


//--------------------DATA TLB STAGE-----------------------------------------//
//-----------IO BLOCK-----------//
assign HZRD.REGDST_M1   = reg_dst_addr_m1;
assign HZRD.ALUORMEM_M1 = aluormem_m1;
assign HZRD.WRITEREG_M1 = write_reg_m1;

assign MMU.DATA_VA = aluout_m1;
assign MMU.DATA_RD = aluormem_m1;
assign MMU.DATA_WR = write_mem_m1;

assign MEM.WE    = write_mem_real_m1;
assign MEM.RE    = aluormem_m1;
assign MEM.dADDR = MMU.DATA_PA[31:2];
assign MEM.BE    = dmem_be_m1;
assign MEM.WD    = dmem_wd_m1;
//------------------------------//

muldiv  muldiv_unit ( .CLK  ( CLK          ),
                      .MUL  ( multiply_m1  ),
                      .MAD  ( madd_m1      ),
                      .SIGN ( signed_op_m1 ),
                      .A    ( aluout_m1    ),
                      .B    ( src_b_m1     ),
                      .HI   ( hi_m1        ),
                      .LO   ( lo_m1        ));


store_reorder st_reorder_unit( .LO_ADDR ( aluout_m1[1:0] ),
                               .DATA_IN ( src_b_m1       ),
                               .PARTIAL ( mem_partial_m1 ),
                               .OP_TYPE ( mem_optype_m1  ),
                      
                               .BYTE_EN ( dmem_be_m1     ),
                               .DATA_OUT( dmem_wd_m1     ));


// inhibit loads if there were TLB exceptions,
// inhibit commits for overflowed instructions
wire write_reg_real_m1 = write_reg_m1 & ~(MMU.dTLBL | MMU.dADEL | e_OV_m1);
wire aluormem_real_m1  = aluormem_m1  & ~(MMU.dTLBL | MMU.dADEL);

//inhibit stores to memory if there were TLB exceptions
assign write_mem_real_m1 = write_mem_m1 & ~(MMU.dTLBS | MMU.dADES | MMU.dTLBMOD);

wire dtlb_exception = MMU.dTLBL | MMU.dADEL | MMU.dTLBS | MMU.dADES | MMU.dTLBMOD;

assign BAD_VA_m1 = dtlb_exception ? aluout_m1 : pc_m1;

ffd #(159) pipe_reg_M2 ( CLK, EXC.RESET, RUN,
                  {  ien_m1,              // 1/ instruction enable
                     write_reg_real_m1,   // 1/ write to register file
                     write_mem_real_m1,   // 1/ write data memory
                     aluormem_real_m1,    // 1/ write regfile from alu or from memory
                     mem_partial_m1,      // 1/ memory byte- or halfword access
                     mem_optype_m1,       // 2/ mem op: 00-ubyte, 01-uhalf, 10-sb, 11-sh
                     MMU.DATA_PA,         //32/ ALU result
                     reg_dst_addr_m1,     // 5/ destination reg addr
                     dmem_be_m1,          // 4/ prepared byte-enables
                     dmem_wd_m1,          //32/ reordered data to store
                     eret_m1,             // 1/ eret instruction
                     e_OV_m1,             // 1/ exception bit
                     e_IBE_m1,            // 1/ exception bit
                     e_iTLBL_m1,          // 1/ exception bit  
                     e_iADEL_m1,          // 1/ exception bit  
                     e_SYSCALL_m1,        // 1/ exception bit    
                     e_BREAK_m1,          // 1/ exception bit    
                     e_RI_m1,             // 1/ exception bit
                     e_CpU_m1,            // 1/ exception bit
                     MMU.dTLBMOD,      // 1/ exception bit
                     MMU.dTLBL,        // 1/ exception bit 
                     MMU.dTLBS,        // 1/ exception bit 
                     MMU.dADEL,        // 1/ exception bit 
                     MMU.dADES,        // 1/ exception bit
                     br_inst_m1,          // 1/ branch instruction
                     BAD_VA_m1,           //32/ bad virtual address -- needed for exceptions
                     pc_m1 },             //32/ pc
               
                  {  ien_m2,
                     write_reg_m2,
                     write_mem_m2,
                     aluormem_m2,
                     mem_partial_m2,         
                     mem_optype_m2,
                     aluout_m2,
                     reg_dst_addr_m2,
                     dmem_be_m2,
                     dmem_wd_m2,
                     eret_m2,
                     e_OV_m2,
                     e_IBE_m2,
                     e_iTLBL_m2,
                     e_iADEL_m2,
                     e_SYSCALL_m2,
                     e_BREAK_m2,  
                     e_RI_m2, 
                     e_CpU_m2,
                     e_dTLBMOD_m2,
                     e_dTLBL_m2,
                     e_dTLBS_m2,
                     e_dADEL_m2,
                     e_dADES_m2,
                     br_inst_m2,
                     BAD_VA_m2, 
                     pc_m2 }); 
//---------------------------------------------------------------------------//

//------------------------MEMORY STAGE---------------------------------------//
//-----------IO BLOCK-----------//
//     MEM.dDATA to ld_reorder

assign HZRD.REGDST_M2 = reg_dst_addr_m2;
assign HZRD.ALUORMEM_M2 = aluormem_m2;
assign HZRD.WRITEREG_M2 = write_reg_m2;

//assign e_DBE_w = MEM.DBE;

load_reorder ld_reorder_unit( .LO_ADDR ( aluout_m2[1:0]   ),
                              .DATA_IN ( MEM.dDATA        ),
                              .PARTIAL ( mem_partial_m2   ),
                              .OP_TYPE ( mem_optype_m2    ),
                              .DATA_OUT( mem_reordered_m2 )); 


ffd #(152) pipe_reg_W(CLK, EXC.RESET, RUN,
                  {  ien_m2,
                     write_reg_m2,        // 1/ write to register file
                     aluormem_m2,         // 1/ write regfile from alu or from memory
                     aluout_m2,           //32/ alu result
                     mem_reordered_m2,    //32/ memory data
                     reg_dst_addr_m2,     // 5/ destination register
                     br_inst_m2,          // 1/ branch instruction
                     eret_m2,             // 1/ EXC: eret instruction
                     e_OV_m2,             // 1/ Exception bit (Overflow)
                     e_IBE_m2,            // 1/ Exception bit (Instr. bus error)
                     MEM.DBE,             // 1/ Exception bit (Data bus error)
                     e_iTLBL_m2,          // 1/ Exception bit (TLB)
                     e_iADEL_m2,          // 1/ Exception bit (Address error)
                     e_SYSCALL_m2,        // 1/ Exception bit (Syscall)
                     e_BREAK_m2,          // 1/ Exception bit (Break)
                     e_RI_m2,             // 1/ Exception bit (Reserved Instruction)
                     e_CpU_m2,            // 1/ Exception bit (COP Unusable)
                     e_dTLBMOD_m2,        // 1/ Exception bit (TLB Modify)
                     e_dTLBL_m2,          // 1/ Exception bit (TLB)
                     e_dTLBS_m2,          // 1/ Exception bit (TLB)
                     e_dADEL_m2,          // 1/ Exception bit (Address Error)
                     e_dADES_m2,          // 1/ Exception bit (Address Error)
                     BAD_VA_m2,           //32/ Bad virtual address
                     pc_m2 },             //32/ instruction address
                     
                  {  ien_w,
                     write_reg_w,         // 1/ write to register file
                     aluormem_w,          // 1/ write regfile from alu or from memory
                     aluout_w,            //32/ alu result
                     mem_reordered_w,     //32/ memory data
                     reg_dst_addr_w,      // 5/ destination register
                     br_inst_w,
                     eret_w,              // 1/ EXC: eret instruction
                     e_OV_w,              // 1/ Exception bit (Overflow)
                     e_IBE_w,             // 1/ Exception bit (Instr. bus error)
                     e_DBE_w,
                     e_iTLBL_w,           // 1/ Exception bit (TLB)
                     e_iADEL_w,           // 1/ Exception bit (Address error)
                     e_SYSCALL_w,         // 1/ Exception bit (Syscall)
                     e_BREAK_w,           // 1/ Exception bit (Break)
                     e_RI_w,              // 1/ Exception bit (Reserved Instruction)
                     e_CpU_w,             // 1/ Exception bit (COP Unusable)
                     e_dTLBMOD_w,         // 1/ Exception bit (TLB Modify)
                     e_dTLBL_w,           // 1/ Exception bit (TLB)
                     e_dTLBS_w,           // 1/ Exception bit (TLB)
                     e_dADEL_w,           // 1/ Exception bit (Address Error)
                     e_dADES_w,           // 1/ Exception bit (Address Error)
                     BAD_VA_w,            //32/ Bad virtual address

                     pc_w });
                     
//---------------------------------------------------------------------------//

//-----------------------WRITEBACK STAGE-------------------------------------//
//-----------IO BLOCK-----------//
assign HZRD.REGDST_W = reg_dst_addr_w;
assign HZRD.WRITEREG_W = write_reg_w;

assign EXC.ERET    = eret_w;
assign EXC.SYSCALL = e_SYSCALL_w;
assign EXC.BREAK   = e_BREAK_w;  
assign EXC.RI      = e_RI_w;     
assign EXC.CpU     = e_CpU_w;
assign EXC.OV      = e_OV_w;   
assign EXC.dTLBMOD = e_dTLBMOD_w;
assign EXC.dTLBL   = e_dTLBL_w;  
assign EXC.dTLBS   = e_dTLBS_w;  
assign EXC.dADEL   = e_dADEL_w;  
assign EXC.dADES   = e_dADES_w;  
assign EXC.iTLBL   = e_iTLBL_w; 
assign EXC.iADEL   = e_iADEL_w; 
assign EXC.IBE     = e_IBE_w;
assign EXC.DBE     = e_DBE_w;
assign EXC.BAD_VA  = e_DBE_w ? aluout_w : BAD_VA_w;
assign EXC.PC_WB    = pc_w;
assign EXC.DELAY_SLOT = delay_slot_w;

assign CP0.IEN_M2 = ien_w;
//------------------------------//

//------------------------------//

mux2 regfile_wr_data_mux( aluormem_w, 
                          aluout_w,        //0: ALU out
                          mem_reordered_w, //1: MEM out
                          regfile_wdata_w);

ffd #(1) delay_slot_fd(CLK, EXC.RESET, 1'b1, br_inst_w, delay_slot_w);
//---------------------------------------------------------------------------//
                
endmodule

