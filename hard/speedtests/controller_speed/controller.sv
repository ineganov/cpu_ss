module controller ( input CLK,
                    input  [21:0] ci,     //instruction word control fields
                    output [30:0] co );   //control outputs

                    
def::ctrl C;
def::c_inst I;

logic [21:0] ri;
logic [30:0] ro;

assign I = ri;

always_ff@(posedge CLK)
   begin
   ri <= ci;
   ro <= C;
   end
   
assign co = ro;
                    
parameter OP_RT    = 6'b000000; //regtype

parameter OP_LW    = 6'b100011;
parameter OP_LH    = 6'b100001;
parameter OP_LHU   = 6'b100101;
parameter OP_LB    = 6'b100000;
parameter OP_LBU   = 6'b100100;

parameter OP_SW    = 6'b101011;
parameter OP_SH    = 6'b101001;
parameter OP_SB    = 6'b101000;

parameter OP_ADDI  = 6'b001000;
parameter OP_ADDIU = 6'b001001;
parameter OP_ANDI  = 6'b001100;
parameter OP_ORI   = 6'b001101;
parameter OP_XORI  = 6'b001110;
parameter OP_LUI   = 6'b001111;

parameter OP_BRT   = 6'b000001; //1 branch-type
parameter OP_BEQ   = 6'b000100; //4
parameter OP_BNE   = 6'b000101; //5
parameter OP_BLEZ  = 6'b000110; //6
parameter OP_BGTZ  = 6'b000111; //7

parameter OP_J     = 6'b000010;
parameter OP_JAL   = 6'b000011;
parameter OP_SLTI  = 6'b001010;
parameter OP_SLTIU = 6'b001011;

parameter OP_COP0  = 6'b010000;
 
always_comb
  case(I.OPCODE)              
    OP_RT:
      case(I.FCODE)    //R_MPTT_AM_RD_MC_BRANCH_JRI_S_IE_SALUCTRL 
      6'b100000: C = 31'b1_0XXX_00_01_00_000000_000_0_XX_1XXX0100; // ADD
      6'b100001: C = 31'b1_0XXX_00_01_00_000000_000_0_XX_1XXX0100; // ADDU
      6'b100010: C = 31'b1_0XXX_00_01_00_000000_000_0_XX_1XXX1100; // SUB
      6'b100011: C = 31'b1_0XXX_00_01_00_000000_000_0_XX_1XXX1100; // SUBU
            
      6'b100100: C = 31'b1_0XXX_00_01_00_000000_000_0_XX_XXXXX000; // AND
      6'b100101: C = 31'b1_0XXX_00_01_00_000000_000_0_XX_XXXXX001; // OR
      6'b100110: C = 31'b1_0XXX_00_01_00_000000_000_0_XX_XXXXX010; // XOR
      6'b100111: C = 31'b1_0XXX_00_01_00_000000_000_0_XX_XXXXX011; // NOR
            
      6'b101010: C = 31'b1_0XXX_00_01_00_000000_000_0_XX_1XXX1111; // SLT
      6'b101011: C = 31'b1_0XXX_00_01_00_000000_000_0_XX_0XXX1111; // SLTU
            
      6'b000000: C = 31'b1_0XXX_00_01_00_000000_000_0_XX_X000X110; // SLL
      6'b000010: C = 31'b1_0XXX_00_01_00_000000_000_0_XX_X001X110; // SRL
      6'b000011: C = 31'b1_0XXX_00_01_00_000000_000_0_XX_X011X110; // SRA
      6'b000100: C = 31'b1_0XXX_00_01_00_000000_000_0_XX_X100X110; // SLLV
      6'b000110: C = 31'b1_0XXX_00_01_00_000000_000_0_XX_X101X110; // SRLV
      6'b000111: C = 31'b1_0XXX_00_01_00_000000_000_0_XX_X111X110; // SRAV
            
      6'b001000: C = 31'b0_0XXX_00_01_00_000000_010_0_XX_0XXX0100; // JR
      6'b001001: C = 31'b1_0XXX_00_01_00_000000_010_0_XX_0XXX0100; // JALR

      6'b010000: C = 31'b1_0XXX_00_01_01_000000_000_X_XX_XXXXXXXX; // MFHI
      6'b010010: C = 31'b1_0XXX_00_01_10_000000_000_X_XX_XXXXXXXX; // MFLO
      
      6'b011000: C = 31'b0_0XXX_01_01_00_000000_000_X_XX_1XXXXXXX; // MULT //same as multu for now
      6'b011001: C = 31'b0_0XXX_01_01_00_000000_000_X_XX_0XXXXXXX; // MULTU
            
      default:   C = 31'b0_0XXX_X0_XX_00_000000_001_0_XX_XXXXXXXX; // NOT IMPLEMENTED     
      endcase
                    //R_MPTT_AM_RD_MC_BRANCH_JRI_S_IE_SALUCTRL
    OP_LW:    C = 31'b1_00XX_10_00_00_000000_000_1_00_0XXX0100;
    OP_LH:    C = 31'b1_0111_10_00_00_000000_000_1_00_0XXX0100; 
    OP_LHU:   C = 31'b1_0101_10_00_00_000000_000_1_00_0XXX0100; 
    OP_LB:    C = 31'b1_0110_10_00_00_000000_000_1_00_0XXX0100; 
    OP_LBU:   C = 31'b1_0100_10_00_00_000000_000_1_00_0XXX0100; 
    
    OP_SW:    C = 31'b0_10XX_00_00_00_000000_000_1_00_0XXX0100;
    OP_SH:    C = 31'b0_11X1_00_00_00_000000_000_1_00_0XXX0100;
    OP_SB:    C = 31'b0_11X0_00_00_00_000000_000_1_00_0XXX0100;
  

    OP_ADDI:  C = 31'b1_0XXX_00_00_00_000000_000_1_00_1XXX0100;
    OP_ADDIU: C = 31'b1_0XXX_00_00_00_000000_000_1_00_0XXX0100;
    OP_ANDI:  C = 31'b1_0XXX_00_00_00_000000_000_1_01_XXXXX000;
    OP_ORI:   C = 31'b1_0XXX_00_00_00_000000_000_1_01_XXXXX001;
    OP_XORI:  C = 31'b1_0XXX_00_00_00_000000_000_1_01_XXXXX010;
    
    OP_SLTI:  C = 31'b1_0XXX_00_00_00_000000_000_1_00_1XXX1111;
    OP_SLTIU: C = 31'b1_0XXX_00_00_00_000000_000_1_01_0XXX1111;

    OP_LUI:   C = 31'b1_0XXX_00_00_00_000000_000_1_11_0XXX0100; 
    OP_BEQ:   C = 31'b0_0XXX_00_XX_00_100000_000_0_00_XXXX1100; 
    OP_BNE:   C = 31'b0_0XXX_00_XX_00_010000_000_0_00_XXXX1100;
    OP_BLEZ:  C = 31'b0_0XXX_00_XX_00_001000_000_0_00_XXXX0100;  
    OP_BGTZ:  C = 31'b0_0XXX_00_XX_00_000001_000_0_00_XXXX0100;
     
    OP_BRT:
      case(I.RT)      //R_MPTT_AM_RD_MC_BRANCH_JRI_S_IE_SALUCTRL
      5'b00000: C = 31'b0_0XXX_00_11_00_000100_000_0_00_XXXX0100;// BLTZ
      5'b10000: C = 31'b1_0XXX_00_11_00_000100_000_0_00_0XXX0100;// BLTZAL
      5'b00001: C = 31'b0_0XXX_00_11_00_000010_000_0_00_XXXX0100;// BGEZ
      5'b10001: C = 31'b1_0XXX_00_11_00_000010_000_0_00_0XXX0100;// BGEZAL
      default:  C = 31'b0_0XXX_X0_XX_00_000000_001_0_XX_XXXXXXXX;// NOT IMPLEMENTED
      endcase
    
    OP_COP0:
      case(I.RS)      //R_MPTT_AM_RD_MC_BRANCH_JRI_S_IE_SALUCTRL
      5'b00000: C = 31'b1_0XXX_00_00_11_000000_000_X_XX_XXXXXXXX;// MOVE FROM
      default:  C = 31'b0_0XXX_X0_XX_00_000000_001_0_XX_XXXXXXXX;// NOT IMPLEMENTED
      endcase
                    //R_MPTT_AM_RD_MC_BRANCH_JRI_S_IE_SALUCTRL
    OP_J:     C = 31'b0_0XXX_00_11_00_000000_100_X_XX_0XXX0100;
    OP_JAL:   C = 31'b1_0XXX_00_11_00_000000_100_X_XX_0XXX0100;
    
    default:  C = 31'b0_0XXX_X0_XX_00_000000_001_0_XX_XXXXXXXX; //NOT IMPLEMENTED
  endcase

endmodule
