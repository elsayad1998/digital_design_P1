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
module ste_avg_fir #(
  parameter integer DATA_W = 16
) (
  input   wire                clk,
  input   wire                rst_n,
  input   wire [DATA_W-1:0]   din_i,
  input   wire                din_update_i,
  input   wire                avg_clr_i,
  output  logic [DATA_W-1:0]  dout_o,
  output  logic               dout_update_o
);

  // -------------------------------------------------------------------------
  // Definition
  // -------------------------------------------------------------------------
  logic [DATA_W-1:0] d1, d2, d3, d4, d5, d6, d7;

  logic [DATA_W+2:0] sum;
  logic [DATA_W-1:0] avg_comb;
  logic [DATA_W-1:0] dout_r;
  logic              dout_update_r;

  // -------------------------------------------------------------------------
  // Combinational sum (8 taps)
  // -------------------------------------------------------------------------
  always_comb
  begin
  sum = din_i + d1 + d2 + d3 + d4 + d5 + d6 + d7;
  avg_comb = sum >> 3;
  end

  // -------------------------------------------------------------------------
  // Sequential logic
  // -------------------------------------------------------------------------
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      d1 <= '0; d2 <= '0; d3 <= '0; d4 <= '0;
      d5 <= '0; d6 <= '0; d7 <= '0;
      dout_r        <= '0;
      dout_update_r <= 1'b0;
    end
    else begin
      dout_update_r <= 1'b0;

      if (avg_clr_i) begin
        d1 <= '0; d2 <= '0; d3 <= '0; d4 <= '0;
        d5 <= '0; d6 <= '0; d7 <= '0;
        dout_r <= '0;
      end
      else if (din_update_i) begin
        // shift register
        d7 <= d6;
        d6 <= d5;
        d5 <= d4;
        d4 <= d3;
        d3 <= d2;
        d2 <= d1;
        d1 <= din_i;

        // average (divide by 8)
       
        dout_r <= avg_comb;
        dout_update_r <= 1'b1;
      end
    end
  end

  // -------------------------------------------------------------------------
  // Output assignments (kept at the end)
  // -------------------------------------------------------------------------
  assign dout_o        = dout_r;
  assign dout_update_o = dout_update_r;

endmodule
`default_nettype wire