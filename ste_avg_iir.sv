//  --------------------------------------------------------------------------
//                    Copyright Message
//  --------------------------------------------------------------------------
//
//  CONFIDENTIAL and PROPRIETARY
//  COPYRIGHT (c) XXXX 2019
//
//  All rights are reserved. Reproduction in whole or in part is
//  prohibited without the written consent of the copyright owner.
//
//
//  ----------------------------------------------------------------------------
//                    Design Information
//  ----------------------------------------------------------------------------
//
//  File             $URL: http://.../ste.sv $
//  Author
//  Date             $LastChangedDate: 2019-02-15 08:18:28 +0100 (Fri, 15 Feb 2019) $
//  Last changed by  $LastChangedBy: kstrohma $
//  Version          $Revision: 2472 $
//
// Description       Averaging via IIR (1st order)
//
//  ----------------------------------------------------------------------------
//                    Revision History (written manually)
//  ----------------------------------------------------------------------------
//
//  Date        Author     Change Description
//  ==========  =========  ========================================================
//  2019-01-09  strohmay   Initial verison       

`default_nettype none
module ste_avg_iir #(
  parameter integer DATA_W      = 16     // _INFO_ Parameter
) (
  input   wire                clk             , // I; System clock 
  input   wire                rst_n           , // I; system cock reset (active low)  
  input   wire  [DATA_W-1:0]  din_i           , // I; Input data    
  input   wire                avg_clr_i       , // I; Clear average data 
  input   wire                avg_en_i        , // I; Enable averaging
  output  logic [DATA_W-1:0]  dout_o          , // O; Averaged data 
  output  logic               dout_update_o     // O; Averaged data update
);
  
  
  // -------------------------------------------------------------------------
  // Definition 
  // ------------------------------------------------------------------------- 
    logic [DATA_W-1:0] D_in = 0;
    logic [DATA_W-1:0] Data = 0;
    logic [DATA_W-1:0] D_out = 0;
    logic [DATA_W-1:0] Out_delayed = 0;
    logic              Update = 0;
  // -------------------------------------------------------------------------
  // Implementation
  // -------------------------------------------------------------------------

 
 // IIR SEQUNTIAL LOGIC
 always_ff @(posedge clk or negedge rst_n)
 begin
 if (~rst_n || avg_clr_i)
    begin      
    Out_delayed <= 0;
    Update <= 0;
    end
 else 
    begin
        Update <= avg_en_i;
        if (avg_en_i)
        begin
        Out_delayed <= D_out;
        end
    end
end
 
 
 // IIR COMBINATIONAL LOGIC
 always_comb
 begin
    D_in = din_i >> 3;
    Data = Out_delayed - (Out_delayed >> 3);
    D_out = D_in + Data;
 end 
  
 assign dout_update_o = Update;
 assign dout_o = D_out;
  
endmodule
`default_nettype wire  






////  --------------------------------------------------------------------------
////                    Copyright Message
////  --------------------------------------------------------------------------
////
////  CONFIDENTIAL and PROPRIETARY
////  COPYRIGHT (c) XXXX 2019
////
////  All rights are reserved. Reproduction in whole or in part is
////  prohibited without the written consent of the copyright owner.
////
////
////  ----------------------------------------------------------------------------
////                    Design Information
////  ----------------------------------------------------------------------------
////
////  File             $URL: http://.../ste.sv $
////  Author
////  Date             $LastChangedDate: 2019-02-15 08:18:28 +0100 (Fri, 15 Feb 2019) $
////  Last changed by  $LastChangedBy: kstrohma $
////  Version          $Revision: 2472 $
////
//// Description       Averaging via IIR (1st order)
////
////  ----------------------------------------------------------------------------
////                    Revision History (written manually)
////  ----------------------------------------------------------------------------
////
////  Date        Author     Change Description
////  ==========  =========  ========================================================
////  2019-01-09  strohmay   Initial verison       
//
//`default_nettype none
//module ste_avg_iir #(
//  parameter integer DATA_W      = 16     // INFO Parameter
//) (
//  input   wire                clk             , // I; System clock 
//  input   wire                rst_n           , // I; system cock reset (active low)  
//  input   wire  [DATA_W-1:0]  din_i           , // I; Input data    
//  input   wire                avg_clr_i       , // I; Clear average data 
//  input   wire                avg_en_i        , // I; Enable averaging
//  output  logic [DATA_W-1:0]  dout_o          , // O; Averaged data 
//  output  logic               dout_update_o     // O; Averaged data update
//);
//  
//  
//  // -------------------------------------------------------------------------
//  // Definition 
//  // -------------------------------------------------------------------------
// 
//  logic [DATA_W-1:0]      avg_old;
//  logic signed [DATA_W:0] diff;
//  logic signed [DATA_W:0] step;
//  logic signed [DATA_W:0] avg_new;
//
//  // -------------------------------------------------------------------------
//  // Implementation
//  // -------------------------------------------------------------------------
//
//  assign diff    = $signed({1'b0, din_i}) - $signed(avg_old);
//  assign step    = diff >>> 3;
//  assign avg_new = $signed(avg_old) + step;
//
//  always_ff @(posedge clk or negedge rst_n) begin
//    if (!rst_n) begin
//      avg_old        <= '0;
//      dout_o         <= '0;
//      dout_update_o  <= 1'b0;
//    end
//    else if (avg_clr_i) begin
//      avg_old        <= '0;
//      dout_o         <= '0;
//      dout_update_o  <= 1'b1;
//    end
//    else if (avg_en_i) begin
//      avg_old        <= avg_new[DATA_W-1:0];
//      dout_o         <= avg_new[DATA_W-1:0];
//      dout_update_o  <= 1'b1;
//    end
//    else begin
//      dout_update_o  <= 1'b0;
//    end
//  end
//
//endmodule
//`default_nettype wire