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
// Description       Calculates the RMS value
//
//  ----------------------------------------------------------------------------
//                    Revision History (written manually)
//  ----------------------------------------------------------------------------
//
//  Date        Author     Change Description
//  ==========  =========  ========================================================
//  2019-01-09  strohmay   Initial verison       


// What is the limit in case I do a full calculation over the whole buffer after each sample
`default_nettype none
module ste_rms_top #(
  parameter int BUF_BIT_W = 8,   // 2^8 = 256 samples
  parameter int DATA_W    = 16
) (
  input   wire                clk,
  input   wire                rst_n,
  input   wire  [DATA_W-1:0]  din_i,
  input   wire                din_update_i,
  input   wire                clr_i,
  output  logic [DATA_W-1:0]  dout_o,
  output  logic               dout_update_o
);
logic dout_update_o_t;
sqrt s_dut(
    .clk_i(clk),   //the clock signal for all registers
    .rst_i(rst_n),   //the reset signal which is used to reset all registers
    .start_i(sig_dly), //used to start the computation
    .a_i(mean),     //non-negative input value
   
    .valid_o(dout_update_o_t), //indicates that the computation is finished
    //.busy_o,  //indicates that the module is computing the square root
    .result_o(dout_o) //contains the computed square root when the valid_o signal is high
    
);

  // -------------------------------------------------------------------------
  // Local parameters
  // -------------------------------------------------------------------------
  localparam int BUF_SIZE   = 1 << BUF_BIT_W;        // 256
  localparam int SQ_W       = DATA_W * 2;            // 32
  localparam int SUM_W      = SQ_W + BUF_BIT_W;      // 40 bits safe

  // -------------------------------------------------------------------------
  // Internal signals
  // -------------------------------------------------------------------------
  logic signed [DATA_W-1:0] din_reg;
  logic        [SQ_W-1:0]   square;

  logic [BUF_BIT_W-1:0]     buf_ptr;

  logic [SUM_W-1:0]         sum;
  logic [SUM_W-1:0]         mean;
  
  logic cal_flag;
  logic start_flag;
  logic first_time_flag;
  
  logic sig_dly;
  logic latch;
    
    
  always_ff @(posedge clk or negedge rst_n) begin
    sig_dly <= start_flag;
	end
	
	// implementing the flipflop
always_ff @ (posedge clk or negedge rst_n) begin
  if(!rst_n || (dout_update_o_t&& first_time_flag)||clr_i)
	latch=0;
  else if(din_update_i)
	latch <=1;
end
  // -------------------------------------------------------------------------
  // Square calculation
  // -------------------------------------------------------------------------
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n||clr_i)
    begin
      square <= '0;
      cal_flag<=1'b0;
    end
    else if (latch)
    begin
      square <= din_i * din_i;
      cal_flag<=1'b1;
    end
  end

  // -------------------------------------------------------------------------
  // 256-entry moving sum (circular buffer)
  // -------------------------------------------------------------------------
  integer i;
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n || clr_i) begin
      sum     <= '0;
      buf_ptr <= '0;

    end
    else if (latch && cal_flag) begin
      sum <= sum  + square;
      buf_ptr <= buf_ptr + 1'b1;
    end
  end

  // -------------------------------------------------------------------------
  // Divide by 256 → mean square
  // -------------------------------------------------------------------------
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n||clr_i) begin
      mean <= '0;
      end
    else if (start_flag) begin
      mean <= sum >> BUF_BIT_W;   // divide by 256
      end
  end
  
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n||clr_i) begin
      first_time_flag <= '0;
      end
    else if (dout_update_o_t) begin
      first_time_flag <= 1;   // divide by 256
      end
  end
  

  assign start_flag=latch && buf_ptr==8'b00000000 && cal_flag;
  assign dout_update_o=dout_update_o_t && first_time_flag;


endmodule

`default_nettype wire  

