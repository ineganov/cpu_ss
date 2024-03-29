module controller ( input  def::c_inst I,     //instruction word control fields
                    output def::ctrl   C );   //control outputs

parameter OP_RT    = 6'b000000; //regtype
parameter OP_SPCL  = 6'b011100; //special-2
parameter OP_COP0  = 6'b010000; //cop-0

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


always_comb
  case(I.OPCODE)              
    OP_RT:
      case(I.FCODE)    //C_R_TLB_MPTT_AM_RD_MC_BRT_JE_PISB_AB_IE_SALUCTRL 
      6'b100000: C = 36'b0_1_00X_0XXX_00_01_00_000_00_0000_00_XX_1XXX0100; // ADD
      6'b100001: C = 36'b0_1_00X_0XXX_00_01_00_000_00_0000_00_XX_0XXX0100; // ADDU
      6'b100010: C = 36'b0_1_00X_0XXX_00_01_00_000_00_0000_00_XX_1XXX1100; // SUB
      6'b100011: C = 36'b0_1_00X_0XXX_00_01_00_000_00_0000_00_XX_0XXX1100; // SUBU
            
      6'b100100: C = 36'b0_1_00X_0XXX_00_01_00_000_00_0000_00_XX_XXXXX000; // AND
      6'b100101: C = 36'b0_1_00X_0XXX_00_01_00_000_00_0000_00_XX_XXXXX001; // OR
      6'b100110: C = 36'b0_1_00X_0XXX_00_01_00_000_00_0000_00_XX_XXXXX010; // XOR
      6'b100111: C = 36'b0_1_00X_0XXX_00_01_00_000_00_0000_00_XX_XXXXX011; // NOR
            
      6'b101010: C = 36'b0_1_00X_0XXX_00_01_00_000_00_0000_00_XX_1XXX1111; // SLT
      6'b101011: C = 36'b0_1_00X_0XXX_00_01_00_000_00_0000_00_XX_0XXX1111; // SLTU
            
      6'b000000: C = 36'b0_1_00X_0XXX_00_01_00_000_00_0000_00_XX_X000X110; // SLL
      6'b000010: C = 36'b0_1_00X_0XXX_00_01_00_000_00_0000_00_XX_X001X110; // SRL
      6'b000011: C = 36'b0_1_00X_0XXX_00_01_00_000_00_0000_00_XX_X011X110; // SRA
      6'b000100: C = 36'b0_1_00X_0XXX_00_01_00_000_00_0000_00_XX_X100X110; // SLLV
      6'b000110: C = 36'b0_1_00X_0XXX_00_01_00_000_00_0000_00_XX_X101X110; // SRLV
      6'b000111: C = 36'b0_1_00X_0XXX_00_01_00_000_00_0000_00_XX_X111X110; // SRAV
            
      6'b001000: C = 36'b0_0_00X_0XXX_00_01_00_001_00_0000_00_XX_0XXX0101; // JR
      6'b001001: C = 36'b0_1_00X_0XXX_00_01_00_001_00_0000_00_XX_0XXX0101; // JALR

      6'b010000: C = 36'b0_1_00X_0XXX_00_01_01_000_00_0000_0X_XX_XXXXXXXX; // MFHI
      6'b010010: C = 36'b0_1_00X_0XXX_00_01_10_000_00_0000_0X_XX_XXXXXXXX; // MFLO
      
      6'b011000: C = 36'b0_0_00X_0XXX_01_01_00_000_00_0000_00_XX_10XX0101; // MULT
      6'b011001: C = 36'b0_0_00X_0XXX_01_01_00_000_00_0000_00_XX_00XX0101; // MULTU
      
      6'b001100: C = 36'b0_0_00X_0XXX_00_00_00_000_00_0010_XX_XX_XXXXXXXX; // SYSCALL
      6'b001101: C = 36'b0_0_00X_0XXX_00_00_00_000_00_0001_XX_XX_XXXXXXXX; // BREAK

      default:   C = 36'b0_0_00X_0XXX_00_00_00_000_00_0100_XX_XX_XXXXXXXX; // NOT IMPLEMENTED     
      endcase
                    //C_R_TLB_MPTT_AM_RD_MC_BRT_JE_PISB_AB_IE_SALUCTRL
    OP_LW:    C = 36'b0_1_00X_00XX_10_00_00_000_00_0000_01_00_0XXX0100;
    OP_LH:    C = 36'b0_1_00X_0111_10_00_00_000_00_0000_01_00_0XXX0100; 
    OP_LHU:   C = 36'b0_1_00X_0101_10_00_00_000_00_0000_01_00_0XXX0100; 
    OP_LB:    C = 36'b0_1_00X_0110_10_00_00_000_00_0000_01_00_0XXX0100; 
    OP_LBU:   C = 36'b0_1_00X_0100_10_00_00_000_00_0000_01_00_0XXX0100; 
    
    OP_SW:    C = 36'b0_0_00X_10XX_00_00_00_000_00_0000_01_00_0XXX0100;
    OP_SH:    C = 36'b0_0_00X_11X1_00_00_00_000_00_0000_01_00_0XXX0100;
    OP_SB:    C = 36'b0_0_00X_11X0_00_00_00_000_00_0000_01_00_0XXX0100;
 
    OP_ADDI:  C = 36'b0_1_00X_0XXX_00_00_00_000_00_0000_01_00_1XXX0100;
    OP_ADDIU: C = 36'b0_1_00X_0XXX_00_00_00_000_00_0000_01_00_0XXX0100;
    OP_ANDI:  C = 36'b0_1_00X_0XXX_00_00_00_000_00_0000_01_01_XXXXX000;
    OP_ORI:   C = 36'b0_1_00X_0XXX_00_00_00_000_00_0000_01_01_XXXXX001;
    OP_XORI:  C = 36'b0_1_00X_0XXX_00_00_00_000_00_0000_01_01_XXXXX010;
    
    OP_SLTI:  C = 36'b0_1_00X_0XXX_00_00_00_000_00_0000_01_00_1XXX1111;
    OP_SLTIU: C = 36'b0_1_00X_0XXX_00_00_00_000_00_0000_01_01_0XXX1111;

    OP_LUI:   C = 36'b0_1_00X_0XXX_00_00_00_000_00_0000_01_11_0XXX0100; 

    OP_BEQ:   C = 36'b0_0_00X_0XXX_00_00_00_010_00_0000_11_10_0XXX0100; 
    OP_BNE:   C = 36'b0_0_00X_0XXX_00_00_00_011_00_0000_11_10_0XXX0100;
    OP_BLEZ:  C = 36'b0_0_00X_0XXX_00_00_00_100_00_0000_11_10_0XXX0100;  
    OP_BGTZ:  C = 36'b0_0_00X_0XXX_00_00_00_111_00_0000_11_10_0XXX0100;
     
    OP_BRT:
      case(I.RT)      //C_R_TLB_MPTT_AM_RD_MC_BRT_JE_PISB_AB_IE_SALUCTRL
      5'b00000: C = 36'b0_0_00X_0XXX_00_11_00_101_00_0000_11_10_0XXX0100;// BLTZ
      5'b10000: C = 36'b0_1_00X_0XXX_00_11_00_101_00_0000_11_10_0XXX0100;// BLTZAL
      5'b00001: C = 36'b0_0_00X_0XXX_00_11_00_110_00_0000_11_10_0XXX0100;// BGEZ
      5'b10001: C = 36'b0_1_00X_0XXX_00_11_00_110_00_0000_11_10_0XXX0100;// BGEZAL
      default:  C = 36'b0_0_00X_0XXX_00_00_00_000_00_0100_XX_XX_XXXXXXXX;// NOT IMPLEMENTED
      endcase
    
    OP_SPCL:
      case(I.FCODE)
      5'b00000: C = 36'b0_0_00X_0XXX_01_01_00_000_00_0000_00_XX_11XX0101; // MADD
      5'b00001: C = 36'b0_0_00X_0XXX_01_01_00_000_00_0000_00_XX_01XX0101; // MADDU
//    5'b00010: C = 36'b0_1_00X_0XXX_00_01_00_000_00_0000_00_XX_1XXX0101; // MUL
      default:  C = 36'b0_0_00X_0XXX_00_00_00_000_00_0100_XX_XX_XXXXXXXX; // NOT IMPLEMENTED
      endcase

    OP_COP0:
      case(I.RS)      //C_R_TLB_MPTT_AM_RD_MC_BRT_JE_PISB_AB_IE_SALUCTRL
      5'b00000: C = 36'b0_1_00X_0XXX_00_00_11_000_00_0000_XX_XX_XXXXXXXX;// MOVE FROM
      5'b00100: C = 36'b1_0_00X_0XXX_00_00_11_000_00_1000_XX_XX_XXXXXXXX;// MOVE TO
      5'b10000:
        case(I.FCODE)    //C_R_TLB_MPTT_AM_RD_MC_BRT_JE_PISB_AB_IE_SALUCTRL
        6'b000001: C = 36'b0_0_101_0XXX_00_XX_00_000_00_1000_XX_XX_XXXXXXXX; // TLBR
        6'b000010: C = 36'b0_0_011_0XXX_00_XX_00_000_00_1000_XX_XX_XXXXXXXX; // TLBWI
        6'b000110: C = 36'b0_0_010_0XXX_00_XX_00_000_00_1000_XX_XX_XXXXXXXX; // TLBWR
        6'b011000: C = 36'b0_0_000_0XXX_00_XX_00_000_01_1000_XX_XX_XXXXXXXX; // ERET
        default:   C = 36'b0_0_00X_0XXX_00_00_00_000_00_0100_XX_XX_XXXXXXXX; // NOT IMPLEMENTED
        endcase
      default:  C = 36'b0_0_00X_0XXX_00_00_00_000_00_0100_XX_XX_XXXXXXXX;// NOT IMPLEMENTED
      endcase
                    //C_R_TLB_MPTT_AM_RD_MC_BRT_JE_PISB_AB_IE_SALUCTRL
    OP_J:     C = 36'b0_0_00X_0XXX_00_11_00_001_10_0000_XX_XX_XXXXXXXX;
    OP_JAL:   C = 36'b0_1_00X_0XXX_00_11_00_001_10_0000_XX_XX_XXXXXXXX;
    
    default:  C = 36'b0_0_00X_0XXX_00_00_00_000_00_0100_XX_XX_XXXXXXXX; //NOT IMPLEMENTED
  endcase

endmodule
