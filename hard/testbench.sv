module testbench;
//====================================================================// 
logic       CLK_CPU, CLK_MEM, RESET, RUN;
logic [7:0] LEDS;
//====================================================================// 
always
  begin
  CLK_CPU = ~CLK_CPU;
  #10ns;
  end 

always@ (posedge CLK_CPU)
  begin
  #6.66ns;
  CLK_MEM = 1;  
  end
  
always@ (negedge CLK_CPU)
  begin
  #6.66ns;
  CLK_MEM = 0;  
  end
//====================================================================// 
initial
  begin
  CLK_CPU = 0;
  CLK_MEM = 0;
  RESET = 1;
  RUN = 0;

  repeat(2)
    @(posedge CLK_CPU) #10;
  RESET = 0; 

  end
//====================================================================// 

mcpu   mcpu  (.CLK       ( CLK_CPU   ),
              .RESET     ( RESET     ),
              .RUN       ( ~RUN      ),
              .LEDS      ( LEDS      ));

//====================================================================// 
endmodule
