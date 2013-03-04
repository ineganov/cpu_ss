package def;



typedef struct packed {
  logic [13:0] ADDR; } imem_w;

typedef struct packed {
  logic  [31:0] RD;  } imem_r;

typedef struct packed {
  logic         RE;
  logic         WE;
  logic  [ 3:0] BE;
  logic  [29:0] ADDR;
  logic  [31:0] WD; } dmem_w;

typedef struct packed {
  logic  [31:0] RD; } dmem_r;


endpackage

