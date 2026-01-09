`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Klaus Strohmayer 
// 
// Create Date:   
// Design Name: 
// Module Name:    seg7_ctrl 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 4 digit 7 segement display controller
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////

`default_nettype wire
module seg7_ctrl(
  input  wire         rst_n      , // I  1; Asynchronous active low reset
  input  wire         clk        , // I  1; clock 100MHz assumed for correct times 
  input  wire         en         , // I  1; Enable  
  input  wire         dim_up_pls , // I  1; Increase brightnes 
  input  wire         dim_dwn_pls, // I  1; Decrese brightnes 
  output logic [ 3:0] dim_val    , // O  4; Actual dimming value 
  input  wire  [15:0] x          , // I 16; Input BCD value  
  input  wire  [ 3:0] x_dp       , // I  4; Display dot 
  output logic [ 6:0] seg        , // O  7; Segments 
  output logic        dp         , // O  1; Segment dot 
  output logic [ 3:0] an           // O  4; Active anode 
);
	 
  // -------------------------------------------------------------------------
  // Definition 
  // -------------------------------------------------------------------------
// Small counter used for dimming
logic [3:0] dim_cnt;

// Flags
logic reset_dim_cnt;
logic inc_dim_cnt;
logic dim_limit_reached;

// 20-bit refresh counter
logic [19:0] refresh_cnt;

logic reset_refresh_cnt;
logic inc_refresh_cnt;

// brightness boundary
logic brightness_timeout;

// Latched input data
logic [15:0] value_latched;
logic [3:0]  dp_latched;
logic [3:0]  dim = 0; 
logic [3:0]  dim_latched = 0;

// digit select from refresh counter
logic [1:0] digit_sel;

// extracted active digit nibble and DP
logic [3:0] current_digit_value;
logic       current_dp_bit;

// Segment pattern
logic [6:0] seg_pattern;

// active-low anode outputs
logic [3:0] an_reg;

// latched segment output
logic [6:0] seg_reg;
logic       dp_reg;

  // -------------------------------------------------------------------------
  // Implementation 
  // -------------------------------------------------------------------------
  


//dimining controll based on buttons
always_ff @(posedge clk or negedge rst_n)
begin
    if (!rst_n)
    begin
        dim <= 4'h0;
    end else
        if (dim_up_pls && dim != 4'hf)
            dim <= dim + 1;
    else if (dim_dwn_pls && dim != 0)
            dim <= dim - 1;
end

// FSM
typedef enum logic [1:0] {
    ST_IDLE  = 2'h0,
    ST_WAIT  = 2'h1,
    ST_DIM   = 2'h2
} state_t;

state_t state, next_state;

// ------------------------------------------------------------
// Small 4-bit dimmer counter
// ------------------------------------------------------------
always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        dim_cnt <= 4'h0;
    else begin
        if (reset_dim_cnt)
            dim_cnt <= 4'h0;
        else if (inc_dim_cnt)
            dim_cnt <= dim_cnt + 1'b1;
    end
end

assign dim_limit_reached = (dim_cnt >= 4'h8);

// ------------------------------------------------------------
// Main refresh counter
// ------------------------------------------------------------
always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        refresh_cnt <= 20'h0;
    else begin
        if (reset_refresh_cnt)
            refresh_cnt <= 20'h0;
        else if (inc_refresh_cnt) begin
            // only increment under certain dimming conditions
            if (!inc_dim_cnt || dim_limit_reached)
                refresh_cnt <= refresh_cnt + 1'b1;
        end
    end
end

assign brightness_timeout = (refresh_cnt == 20'hFFFFF);

// ------------------------------------------------------------
// FSM state register
// ------------------------------------------------------------
always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        state <= ST_IDLE;
    else
        state <= next_state;
end

// ------------------------------------------------------------
// FSM combinational logic
// ------------------------------------------------------------
always_comb begin
    // Default
    next_state         = state;
    reset_dim_cnt      = 1'b0;
    inc_dim_cnt        = 1'b0;
    reset_refresh_cnt  = 1'b0;
    inc_refresh_cnt    = 1'b0;
    //dp_reg             = 1'b0;

    case (state)

        ST_IDLE: begin
            if (en) begin
                reset_refresh_cnt = 1'b1;
                next_state = ST_WAIT;
            end
        end

        ST_WAIT: begin
            inc_refresh_cnt = 1'b1;

            if (brightness_timeout) begin
                if (dim_latched != 4'h0) begin
                    reset_dim_cnt = 1'b1;
                    reset_refresh_cnt = 1'b1;
                    next_state = ST_DIM;
                end else begin
                    next_state = ST_IDLE;
                end
            end
        end

        ST_DIM: begin
            inc_dim_cnt      = 1'b1;
            inc_refresh_cnt  = 1'b1;
            //dp_reg           = 1'b1;

            if (refresh_cnt == {dim_latched, 16'hFFFF})
                next_state = ST_IDLE;
        end

    endcase
end

// ------------------------------------------------------------
// Latch input data when starting
// ------------------------------------------------------------
always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        value_latched <= 16'h0000;
        dp_latched    <= 4'b0000;
        dim_latched   <= 4'h0;
    end else begin
        if (en) begin
            value_latched <= x;
            dp_latched    <= x_dp;
            dim_latched   <= dim;
        end
    end
end

// ------------------------------------------------------------
// Digit select from refresh counter
// ------------------------------------------------------------
assign digit_sel = refresh_cnt[19:18];

// ------------------------------------------------------------
// Select digit and DP bit
// ------------------------------------------------------------
always_comb begin
    case (digit_sel)
        2'b00: begin current_digit_value = value_latched[ 3: 0]; current_dp_bit = dp_latched[0]; end
        2'b01: begin current_digit_value = value_latched[ 7: 4]; current_dp_bit = dp_latched[1]; end
        2'b10: begin current_digit_value = value_latched[11: 8]; current_dp_bit = dp_latched[2]; end
        2'b11: begin current_digit_value = value_latched[15:12]; current_dp_bit = dp_latched[3]; end
        default: begin current_digit_value = value_latched[3:0]; current_dp_bit = dp_latched[0]; end
    endcase
end

// ------------------------------------------------------------
// Hex → 7-seg decode (unchanged behavior)
// ------------------------------------------------------------
always_comb begin
    case (current_digit_value)
        4'h0: seg_pattern = 7'b1000000;
        4'h1: seg_pattern = 7'b1111001;
        4'h2: seg_pattern = 7'b0100100;
        4'h3: seg_pattern = 7'b0110000;
        4'h4: seg_pattern = 7'b0011001;
        4'h5: seg_pattern = 7'b0010010;
        4'h6: seg_pattern = 7'b0000010;
        4'h7: seg_pattern = 7'b1111000;
        4'h8: seg_pattern = 7'b0000000;
        4'h9: seg_pattern = 7'b0010000;
        4'hA: seg_pattern = 7'b0111111;
        4'hB: seg_pattern = 7'b1111111;
        4'hC: seg_pattern = 7'b1110111;
        default: seg_pattern = 7'b0000000;
    endcase
end

// ------------------------------------------------------------
// Output registers
// ------------------------------------------------------------
always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        an_reg  <= 4'b1111;
        seg_reg <= 7'b0000000;
        dp_reg  <= 1'b1;
    end else begin
        if (!en) begin
            an_reg  <= 4'b1111;
            seg_reg <= 7'b0000000;
            dp_reg  <= 1'b1;
        end else begin
            an_reg            = 4'b1111;
            an_reg[digit_sel] = 1'b0;

            seg_reg = seg_pattern;
            dp_reg  = ~current_dp_bit;
        end
    end
end

assign an  = an_reg;
assign dp  = dp_reg;
assign seg = seg_reg;
assign dim_val = dim_latched;
  //assign an      = '0;
  //assign dp      = '0;
  //assign seg     = '0;


endmodule
