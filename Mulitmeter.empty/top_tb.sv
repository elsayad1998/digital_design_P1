`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01/05/2020 04:27:03 PM
// Design Name: 
// Module Name: top_tb
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

`timescale 1ns/10fs

module top_tb();

  logic clk;
	 
  //Push Button Inputs	 
  logic btnC;
  logic btnU; 
  logic btnD;
  logic btnR;
  logic btnL;
  
  // Slide Switch Inputs
  //  
  //   Input A = sw[15:8]
  //  Input B = sw[7:0]	 
  logic [15:0] sw; 
 
  // Pmod Header JA
  wire [7:0] JA;


basys3_top u_dut(
  //CLK Input
  .clk(clk),
	 
  //Push Button Inputs	 
  .btnC(btnC),
  .btnU(btnU), 
  .btnD(btnD),
  .btnR(btnR),
  .btnL(btnL),
	 
  // Slide Switch Inputs
  //  
  //  Input A = sw[15:8]
  //  Input B = sw[7:0]	 
  .sw(sw), 
 
  // Pmod Header JA
  .JA(JA),  
  .JB(),

   // USB-RS232 Interface
  .RsTx (),        // O; TXD  
  .RsRx (1'b0),    // I; RXD

 // LED Outputs
  .led(),
     
  // Seven Segment Display Outputs
  .seg(),
  .an(), 
  .dp()  
);
	
  always begin
    clk = 1'b0;
    #5ns;
    clk = 1'b1;
    #5ns;
  end	

  assign JA = 8'bzzzzz01z;  
  initial begin
    btnC = 1'b1;
    sw   = 16'hf000;
    @(negedge clk);
    btnC = 1'b0;
    
    repeat (100) @(negedge clk);
    
    sw = 16'hf001;
    #10ms;
    
    sw = 16'h0001;
    #5ms;

    $finish();
    
  end
	
  initial begin
    btnU = 1'b0;
    #100us;
    btnU = 1'b1;
    #1us;
    btnU = 1'b0;
  end	
	
	logic [11:0  ] result_12f0;
  logic [11+8:0] result_12f8;
  logic [   7:0] lsb2v_factor_0f8;
  logic [11+8+8:0] result_mv_12f16;
  logic [11:0]     result_mv_12f0; 
  
  initial begin
    lsb2v_factor_0f8 = 8'd206;

    result_12f0      = 12'hFFF;
    result_12f8      = {result_12f0, 8'h00};
    result_mv_12f16  = result_12f8 * lsb2v_factor_0f8;
    result_mv_12f0   = result_mv_12f16[11+8+8:8+8];

    #1us;
    result_12f0      = 12'h7FF;
    result_12f8      = {result_12f0, 8'h00};
    result_mv_12f16  = result_12f8 * lsb2v_factor_0f8;
    result_mv_12f0   = result_mv_12f16[11+8+8:8+8];
        
    #1us;
    result_12f0      = 12'h3FF;
    result_12f8      = {result_12f0, 8'h00};
    result_mv_12f16  = result_12f8 * lsb2v_factor_0f8;
    result_mv_12f0   = result_mv_12f16[11+8+8:8+8];

    #1us;
    result_12f0      = 12'h0FF;
    result_12f8      = {result_12f0, 8'h00};
    result_mv_12f16  = result_12f8 * lsb2v_factor_0f8;
    result_mv_12f0   = result_mv_12f16[11+8+8:8+8];
    
     
  
  
  end
	

endmodule
