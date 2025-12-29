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

module ste_led_bar #(
  parameter int  DATA_W = 4,
  parameter logic [DATA_W-1:0] DATA_MAX = 4'hf,
  parameter int  LED_NR = 8
) (
  input  wire               clk,
  input  wire               rst_n,          // async reset (active low)
  input  wire [DATA_W-1:0]  din_i,          // value to display
  input  wire               din_update_i,   // 1-clock pulse: new value
  input  wire               clr_i,           // clear LEDs
  output logic [LED_NR-1:0] led_o            // LED bar output
);

  // ------------------------------------------------------------
  // Function: converts "number of LEDs" -> bar pattern
  // ------------------------------------------------------------
  function automatic logic [LED_NR-1:0] thermo(input int unsigned n);
    logic [LED_NR-1:0] tmp;
    begin
      if (n == 0)
        tmp = '0;                          // 00000000
      else if (n >= LED_NR)
        tmp = {LED_NR{1'b1}};              // 11111111
      else
        tmp = ({LED_NR{1'b1}} >> (LED_NR - n));
      return tmp;
    end
  endfunction

  // ------------------------------------------------------------
  // Main sequential logic
  // ------------------------------------------------------------
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      led_o <= '0;                         // immediate reset
    end else if (clr_i) begin
      led_o <= '0;                         // clear LEDs
    end else if (din_update_i) begin
      int unsigned n_leds;

      // Scale input value to range 0..8
      // din_i = 0        -> n_leds = 0
      // din_i = DATA_MAX -> n_leds = 8
      n_leds = (int'(din_i) * LED_NR) / (int'(DATA_MAX) + 1);

      led_o <= thermo(n_leds);              // update LED bar
    end
    // else: keep old led_o
  end

endmodule

`default_nettype wire
