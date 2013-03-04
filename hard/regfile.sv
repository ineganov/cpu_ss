module regfile(   input           CLK,
                  input   [4:0]   RD_ADDR_1, 
                  input   [4:0]   RD_ADDR_2, 
                  input   [4:0]   WR_ADDR_3,
                  input   [31:0]  W_DATA,
                  input           WE,
                  output  [31:0]  R_DATA_1,
                  output  [31:0]  R_DATA_2);

logic [31:0] rd1_mem, rd2_mem, rd1_bp, rd2_bp;
logic  [4:0] a1q, a2q;
logic bypass_1,  bypass_2,  zero_1,  zero_2, zero_1q, zero_2q;

assign bypass_1 = (WR_ADDR_3 == a1q );
assign bypass_2 = (WR_ADDR_3 == a2q );
assign zero_1   = (RD_ADDR_1 == 5'd0);
assign zero_2   = (RD_ADDR_2 == 5'd0);

rf_memory rf_memory ( .CLK( CLK       ),
                      .A1R( RD_ADDR_1 ), 
                      .A2R( RD_ADDR_2 ), 
                      .A3W( WR_ADDR_3 ),
                      .WD ( W_DATA    ),
                      .WE ( WE        ),
                      .RD1( rd1_mem   ),
                      .RD2( rd2_mem   ) );

ffds #(5)   a1_reg(CLK, RD_ADDR_1,    a1q );
ffds #(5)   a2_reg(CLK, RD_ADDR_2,    a2q );
ffds #(1)  zr1_reg(CLK, zero_1,   zero_1q );
ffds #(1)  zr2_reg(CLK, zero_2,   zero_2q );

mux2 bypass_mux_1(bypass_1, rd1_mem, W_DATA, rd1_bp);
mux2 bypass_mux_2(bypass_2, rd2_mem, W_DATA, rd2_bp);

mux2   zero_mux_1(zero_1q, rd1_bp, 32'd0, R_DATA_1);
mux2   zero_mux_2(zero_2q, rd2_bp, 32'd0, R_DATA_2);

//-----------simulation-only----------------
function string get_rname(input [4:0] idx);
  begin
  case(idx)
  5'd00: get_rname = "$zero";
  5'd01: get_rname = "$at";
  5'd02: get_rname = "$v0";
  5'd03: get_rname = "$v1";
  5'd04: get_rname = "$a0";
  5'd05: get_rname = "$a1";
  5'd06: get_rname = "$a2";
  5'd07: get_rname = "$a3";
  5'd08: get_rname = "$t0";
  5'd09: get_rname = "$t1";
  5'd10: get_rname = "$t2";
  5'd11: get_rname = "$t3";
  5'd12: get_rname = "$t4";
  5'd13: get_rname = "$t5";
  5'd14: get_rname = "$t6";
  5'd15: get_rname = "$t7";
  5'd16: get_rname = "$s0";
  5'd17: get_rname = "$s1";
  5'd18: get_rname = "$s2";
  5'd19: get_rname = "$s3";
  5'd20: get_rname = "$s4";
  5'd21: get_rname = "$s5";
  5'd22: get_rname = "$s6";
  5'd23: get_rname = "$s7";
  5'd24: get_rname = "$t8";
  5'd25: get_rname = "$t9";
  5'd26: get_rname = "$k0";
  5'd27: get_rname = "$k1";
  5'd28: get_rname = "$gp";
  5'd29: get_rname = "$sp";
  5'd30: get_rname = "$fp";
  5'd31: get_rname = "$ra";
  endcase
  end
endfunction


always_ff@ (posedge CLK)
  if(WE && WR_ADDR_3)
   $display("[%8tps] REFILE WR: %08x --> %s (r%02d)", $time, 
                                                   W_DATA, 
                                                   get_rname(WR_ADDR_3), 
                                                   WR_ADDR_3);

endmodule
//======================================================================//
module rf_memory( input           CLK,
                  input    [4:0]  A1R, 
                  input    [4:0]  A2R, 
                  input    [4:0]  A3W,
                  input   [31:0]  WD,
                  input           WE,
                  output  [31:0]  RD1,
                  output  [31:0]  RD2 );

logic [31:0] rf[31:0];
logic [31:0] reg_rd1, reg_rd2;

always_ff@(posedge CLK)
  begin
  reg_rd1 <= rf[A1R];
  reg_rd2 <= rf[A2R];
  if(WE) rf[A3W] <= WD;
  end

assign RD1 = reg_rd1;
assign RD2 = reg_rd2;

endmodule
//======================================================================//
