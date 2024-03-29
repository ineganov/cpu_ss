package def;

typedef struct packed {
  logic   [5:0] OPCODE;        //6/ instruction opcode
  logic   [5:0] FCODE;         //6/ instruction fcode
  logic   [4:0] RS;            //5/ instruction RS field
  logic   [4:0] RT; } c_inst;  //5/ instruction RT field --> 22

typedef struct packed {
  logic        WRITE_REG;       //1/ write to register file
  logic        WRITE_MEM;       //1/ write data memory
  logic        MEM_PARTIAL;     //1/ memory byte- or halfword access
  logic  [1:0] MEM_OPTYPE;      //2/ mem op: 00-ubyte, 01-uhalf, 10-sb, 11-sh 
  logic        ALUORMEM_WR;     //1/ write regfile from alu or from memory
  logic        MULTIPLY;        //1/ do multiplication and write hi&lo
  logic  [1:0] REG_DST;         //2/ write destination in regfile (0 - rt, 1 - rd, 1X - 31)
  logic  [1:0] MFCOP_SEL;       //2/ move from coprocessor sel
  logic        BRANCH_E;        //1/ branch equal
  logic        BRANCH_NE;       //1/ branch not equal
  logic        BRANCH_LEZ;      //1/ branch less than or equal zero
  logic        BRANCH_LTZ;      //1/ branch less than zero
  logic        BRANCH_GEZ;      //1/ branch greater than or equal zero
  logic        BRANCH_GTZ;      //1/ branch greater than zero
  logic        JUMP;            //1/ j-type jump
  logic        JUMP_R;          //1/ r-type jump 
  logic        NOT_IMPLTD;      //1/ unimplemented instruction     
  logic        ALU_SRC_B;       //1/ ALU Operand B 0 - reg_2, 1 - immediate    
  logic  [1:0] IMMED_EXT;       //2/ Immed-extension type
  logic  [7:0] ALU_OP;  } ctrl; //8/ ALU Operation select  --> 31


endpackage

