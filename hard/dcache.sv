module dcache  (  input         CLK_CPU,
                  input         CLK_MEM,
                  input         RESET,

                  //CPU interface
                  input         CPU_WE,
                  input         CPU_RE,
                  input   [3:0] CPU_BE,
                  input  [29:0] CPU_A,
                  input  [31:0] CPU_WD,
                  output [31:0] CPU_RD,
                  output        HALT,

                  //Mem controller interface
                  output        REQ_C2M,
                  output        REQ_M2C,
                  output [12:0] NEW_TAG_A,
                  output [12:0] OLD_TAG_A,
                  input         DONE,
                  input         MEM_WE,
                  input   [2:0] MEM_A,
                  input  [31:0] MEM_WD,
                  output [31:0] MEM_RD );

//parameter DEPTH = 10; //1024 32-bit words / 4K

// The cache maps 32 megabytes of data in external memory
// Ergo, byte address is 25 bits wide, word address is 23-bit wide, or CPU_A[22:0]

// For 4K cache / 32 byte line / 128 lines
// 3 bits to select a word inside the line
// 7 bits to select the line
// 13 bits for a tag

wire  [12:0] TAG_SEL   = CPU_A[22:10];
wire   [9:0] DADDR_SEL = CPU_A[9:0];
wire   [6:0] LINE_SEL  = CPU_A[9:3];
wire   [2:0] WORD_SEL  = CPU_A[2:0];

//Tag nets. 
//  tag[14]:   valid; 
//  tag[13]:   dirty; 
//  tag[12:0]: address tag;
logic [14:0] current_tag, new_tag;

logic FSM_IDLE;

wire HIT = current_tag[14] && (current_tag[12:0] == TAG_SEL);
wire CPU_RQ = CPU_RE | CPU_WE;
wire MISS   = CPU_RQ && !HIT;

assign HALT = CPU_RQ && (!HIT || !FSM_IDLE);


logic [31:0] saved_value;
ffd overwrite_save( CLK_MEM, RESET, (CPU_WE && !HIT), CPU_RD, saved_value);

// This mux automaticaly substitutes read and saved value from the 
// written data mem cell on a write miss
// beware read the read miss, though
logic [31:0] dmem2mux;
logic [31:0] TO_MEM_CONTROL;
mux2 reg_or_mem( CPU_WE && (WORD_SEL == MEM_A), dmem2mux, saved_value, MEM_RD);

cache_data_mem cdata(   .CLK    ( CLK_MEM           ),
                        .WE_A   ( CPU_WE            ),
                        .BE_A   ( CPU_BE            ),
                        .ADDR_A ( DADDR_SEL         ),
                        .WD_A   ( CPU_WD            ),
                        .RD_A   ( CPU_RD            ),

                        .WE_B   ( MEM_WE            ),
                        .ADDR_B ( {LINE_SEL, MEM_A} ),
                        .WD_B   ( MEM_WD            ),
                        .RD_B   ( dmem2mux          ) );

cache_fsm cfsm( .CLK        ( CLK_CPU         ),
                .RESET      ( RESET           ),
     
                .MISS       ( MISS            ),
                .VALID      ( current_tag[14] ),
                .DIRTY      ( current_tag[13] ),
     
                .IDLE       ( FSM_IDLE        ),
                .REQ_C2M    ( REQ_C2M         ),
                .REQ_M2C    ( REQ_M2C         ),
                .DONE       ( DONE            ) );
     

logic [1:0] TAG_MUX_SEL;

cache_tag_upd ctupd( .CPU_READ    ( CPU_RE      ),
                     .CPU_WRITE   ( CPU_WE      ),
                     .HIT         ( HIT         ),
                     .TAG_MUX_SEL ( TAG_MUX_SEL ) );


mux4 #(15) new_tag_mux ( TAG_MUX_SEL,
                         current_tag,                // 00: No change
                         {2'b10, TAG_SEL},           // 01: set new valid tag
                         {2'b11, current_tag[12:0]}, // 10: update dirty flag, leave addr_tag unchanged
                         {2'b00, current_tag[12:0]}, // 11: invalidate. (not necessarily used)
                         new_tag );

cache_tag_mem ctag( .CLK      ( CLK_MEM     ),
                    .WE       ( CPU_RQ      ), 
                    .LINE_SEL ( LINE_SEL    ),
                    .TAG_IN   ( new_tag     ),
                    .TAG_OUT  ( current_tag ) );

ffd #(13) old_tag_reg( CLK_MEM, RESET, 1'b1, current_tag[12:0], OLD_TAG_A );
assign NEW_TAG_A = TAG_SEL;

endmodule

//=================================================================================//
module cache_data_mem( input         CLK,

                       input         WE_A,
                       input   [9:0] ADDR_A,
                       input   [3:0] BE_A,
                       input  [31:0] WD_A,
                       output [31:0] RD_A,

                       input         WE_B,
                       input   [9:0] ADDR_B,
                       input  [31:0] WD_B,
                       output [31:0] RD_B );


parameter D = 10;

logic [3:0][7:0] RAM[0:2**D-1];
logic [31:0] read_reg_a, read_reg_b;

//initial
  //$readmemh ("soft/data.txt", RAM);


always_ff@(posedge CLK)
  begin
  read_reg_a <= RAM[ADDR_A];
  read_reg_b <= RAM[ADDR_B];

  if (WE_A && !WE_B) 
    begin
    if(BE_A[0]) RAM[ADDR_A][0] <= WD_A[07:00];
    if(BE_A[1]) RAM[ADDR_A][1] <= WD_A[15:08];
    if(BE_A[2]) RAM[ADDR_A][2] <= WD_A[23:16];
    if(BE_A[3]) RAM[ADDR_A][3] <= WD_A[31:24];
    end
  else if(WE_B)
    RAM[ADDR_B] <= WD_B;
  end


assign RD_A = read_reg_a;
assign RD_B = read_reg_b;

endmodule

//=================================================================================//
module cache_tag_mem (  input         CLK,
                        input         WE,
                        input   [6:0] LINE_SEL,
                        input  [14:0] TAG_IN,
                        output [14:0] TAG_OUT );

logic [14:0] TAG_RAM[0:127];
logic [14:0] read_reg;

initial
  begin
  for(int i = 0; i < 127; i = i + 1)
    TAG_RAM[i] = 0;
  end

always_ff@ (posedge CLK)
  begin
  if(WE) TAG_RAM[LINE_SEL] <= TAG_IN;
  read_reg <= TAG_RAM[LINE_SEL];
  end  

assign TAG_OUT = read_reg;

endmodule
//=================================================================================//
module cache_fsm (  input  CLK,
                    input  RESET,

                    input  MISS,
                    input  VALID,
                    input  DIRTY,

                    output IDLE,
                    output REQ_C2M,
                    output REQ_M2C,
                    input  DONE );

enum int unsigned { ST_IDLE    = 0, 
                    ST_EVICT   = 1,
                    ST_FILL    = 2,
                    ST_EVICT_W = 3,
                    ST_FILL_W  = 4 } state, next;

always_comb
  case(state)
    ST_IDLE:    if(MISS)
                  begin
                  if(VALID && DIRTY) next = ST_EVICT;
                  else               next = ST_FILL;
                  end
                else                 next = state;

    ST_EVICT:   if(!DONE)            next = ST_EVICT_W; //wait for ACK (DONE goes lo)
                else                 next = state;

    ST_FILL:    if(!DONE)            next = ST_FILL_W;  //wait for ACK (DONE goes lo)
                else                 next = state;

    ST_EVICT_W: if(DONE)             next = ST_FILL;  //wait for DONE (DONE goes hi)
                else                 next = state;

    ST_FILL_W:  if(DONE)             next = ST_IDLE;  //wait for DONE (DONE goes hi)
                else                 next = state;

    default:                         next = ST_IDLE;
  endcase

always_ff@ (posedge CLK)
  if(RESET) state <= ST_IDLE;
  else      state <= next;

assign REQ_C2M = (state == ST_EVICT);
assign REQ_M2C = (state == ST_FILL);
assign IDLE    = (state == ST_IDLE);

endmodule
//=================================================================================//
module cache_tag_upd( input        CPU_READ,
                      input        CPU_WRITE,
                      input        HIT,
                      output [1:0] TAG_MUX_SEL );

logic [1:0] tu_sel;
wire [2:0] rwh = {CPU_READ, CPU_WRITE, HIT};

always_comb
  case(rwh)
    3'b011:  tu_sel = 2'b10; //in case of write hit, set the dirty flag
    3'b100:  tu_sel = 2'b01; //in case of write or read miss, set valid flag and update addr
    3'b010:  tu_sel = 2'b01; //in case of write or read miss, set valid flag and update addr
    default: tu_sel = 2'b00; //do nothing otherwise
  endcase

assign TAG_MUX_SEL = tu_sel;
endmodule
//=================================================================================//

