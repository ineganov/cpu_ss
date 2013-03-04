module muldiv  ( input         CLK,
                 input         MUL,
                 input         MAD,
                 input         SIGN,
                 input  [31:0] A,
                 input  [31:0] B,
                 output [31:0] HI,
                 output [31:0] LO );

logic [63:0] MULTU, MULT, D, Q;

logic [31:0] An, Bn;
logic [31:0] hi, lo;

negate #(32) negate_a( SIGN & A[31], A, An ); //get a positive integer
negate #(32) negate_b( SIGN & B[31], B, Bn );

assign MULTU = An * Bn;

negate #(64) negate_q( SIGN & (A[31] ^ B[31]), MULTU, MULT ); //Negate result if signs differ

//mux2 #(64) mad_mux(MAD, MULT, (Q + MULT), D);

ffd #( 64) hi_lo_reg(CLK, 1'b0, MUL, MULT, Q);

assign HI = Q[63:32];
assign LO = Q[31:0];

endmodule
