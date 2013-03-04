module hazard_unit ( if_hazard.hzrd HZRD );

//  ALU Forwarding logic:
//  Replace ALU arg by the most recent write to reg file
//  I.e., if we have several instructions writing to regfile, 
//  use the closest one down the pipeline
//  Precedence: M1, M2, WB. 
//  + Don't forward if the argument is $zero since it _must_
//  work as /dev/null. Forwarding can break this logic!

//  + Keep in mind that forwarding works for arithmetic/logic
//  instructions mostly. Forwarding for loads is limited 
//  since the actual word appears in the processor at the 
//  end of M2 stage. Loaded data can be forwarded from WB only.

//  Then again, we need WB forwarding for ALU only, since it 
//  writes regfile at decode & branch state, and WB result is
//  accessible for branches directly from writeback


assign HZRD.ALU_FWD_A = 
   ((HZRD.RS_E != 0) && (HZRD.RS_E == HZRD.REGDST_M1) && HZRD.WRITEREG_M1) ? 2'b01 :
   ((HZRD.RS_E != 0) && (HZRD.RS_E == HZRD.REGDST_M2) && HZRD.WRITEREG_M2) ? 2'b10 :
   ((HZRD.RS_E != 0) && (HZRD.RS_E == HZRD.REGDST_W ) && HZRD.WRITEREG_W ) ? 2'b11 :
                                                                             2'b00 ;

assign HZRD.ALU_FWD_B = 
   ((HZRD.RT_E != 0) && (HZRD.RT_E == HZRD.REGDST_M1) && HZRD.WRITEREG_M1) ? 2'b01 :
   ((HZRD.RT_E != 0) && (HZRD.RT_E == HZRD.REGDST_M2) && HZRD.WRITEREG_M2) ? 2'b10 :
   ((HZRD.RT_E != 0) && (HZRD.RT_E == HZRD.REGDST_W ) && HZRD.WRITEREG_W ) ? 2'b11 :
                                                                             2'b00 ;



logic LW_STALL;

logic LOAD_AT_E, LOAD_AT_M1;

assign LOAD_AT_E  = HZRD.ALUORMEM_E  & (( HZRD.RS_D == HZRD.RT_E ) | 
                                        ( HZRD.RT_D == HZRD.RT_E ));

assign LOAD_AT_M1 = HZRD.ALUORMEM_M1 & (( HZRD.RS_D == HZRD.REGDST_M1) | 
                                        ( HZRD.RT_D == HZRD.REGDST_M1));

// We should stall on account of loads for 2 cycles max. 
// If the load is at M2: D-->E, M2-->WB, and
// forwarding works from WB to E
assign LW_STALL = (LOAD_AT_E | LOAD_AT_M1);

assign HZRD.STALL = LW_STALL;

endmodule
