
 `default_nettype none
module mm_result (
  input   wire         clk                  , // I; System clock 
  input   wire         rst_n                , // I; system cock reset (active low)  
  input   wire         clr_i                , // I; Clear  data 
  input   wire  [ 1:0] din_sel_i            , // I; Input selection 
  input   wire  [11:0] din_avg_fir_i        , // I; Input data from FIR filter    
  input   wire         din_avg_fir_update_i , // I; Input data from FIR filter update  
  input   wire  [11:0] din_avg_iir_i        , // I; Input data from IIR filter    
  input   wire         din_avg_iir_update_i , // I; Input data from IIR filter update    
  input   wire  [11:0] din_rms_i            , // I; Input data from RMS module   
  input   wire         din_rms_update_i     , // I; Input data from RMS module update   
  input   wire  [11:0] din_val_i            , // I; Input data from ADC    
  input   wire         din_val_update_i     , // I; Input data from ADC update   
  output  logic [11:0] dout_o               , // O; Selected result 
  output  logic [15:0] dout_bcd_o           , // O; Selected result as BCD 
  output  logic        dout_update_o          // O; Selected result update
);

  import mm_pkg::*;

  // -------------------------------------------------------------------------
  // Definition
  // -------------------------------------------------------------------------

// Which input is active?
//
//Did that input just update?
//
//If yes:
//
//latch value
//
//scale it generate binary
//
// For BCD shift bit by bit and check if each BCD(4bit) <= 5 ( add to it  3) the size of the bcd is 16bit because we have a 12bit input  
//
//pulse dout_update_o
//
//That's the whole control flow.
//


result_sel_t Result_Sel;

logic [11:0] Latched_Value = 0;
logic [11:0] Scaled_Binary = 0;
logic [15:0] BCD = 0;
logic [15:0] BCD_next;
logic [3:0]  Bit_cnt = 12;

logic        BCD_ready = 0;
logic        Bin_ready = 0;
logic        UPDATE;
logic        BCD_busy;


  // -------------------------------------------------------------------------
  // Implementation
  // -------------------------------------------------------------------------
  
// output update   
  
always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        dout_update_o <= 0;
    else
        dout_update_o <= (BCD_ready && Bin_ready);
end


//translating the input value coming from the switch into the type def enum from the provided package  

always_comb
begin
   case (din_sel_i)
   'h0: Result_Sel = RESULT_SEL_VADC;
   'h1: Result_Sel = RESULT_SEL_VAVG;
   'h2: Result_Sel = RESULT_SEL_VRMS;
   'h3: Result_Sel = RESULT_SEL_VIIR;
   default: Result_Sel = RESULT_SEL_VADC;
   endcase
end

//latching the input value based on the chosen switch and the input update 

always_ff @(posedge clk or negedge rst_n)
begin
    if (~rst_n || clr_i) // we use the update to reset to make sure the update is for one clk cycle 
    begin
       Latched_Value <= 0; 
       UPDATE <= 0; 
    end
    
    else 
    begin
        case (Result_Sel)
        
            RESULT_SEL_VADC:begin 
                                  if (din_val_update_i) begin
                                  Latched_Value <= din_val_i;
                                  UPDATE <= 1;
                            end
                            end
            RESULT_SEL_VAVG:begin 
                                  if (din_avg_fir_update_i) begin  
                                  Latched_Value <= din_avg_fir_i;
                                  UPDATE <= 1;
                            end
                            end
            RESULT_SEL_VRMS:begin 
                                  if (din_rms_update_i) begin
                                  Latched_Value <= din_rms_i;
                                  UPDATE <= 1;
                            end
                            end
            RESULT_SEL_VIIR:begin 
                                  if (din_avg_iir_update_i) begin
                                  Latched_Value <= din_avg_iir_i;
                                  UPDATE <= 1;
                            end
                            end
            default: begin
                        Latched_Value <= 0;
                        UPDATE <= 0;              
                     end                
        endcase
    end
end


//register for the scaled binary value only works when we have a valid update flag from the input value latch

always_ff @(posedge clk or negedge rst_n)
begin
    if (~rst_n || clr_i)
    begin
        Scaled_Binary <= 0;
        Bin_ready <= 0;
    end
    else if (UPDATE)
    begin
        Scaled_Binary <= Latched_Value * 'd330 / 'd4095;
        Bin_ready <= 1;
    end
end


//the double dable algorithm must be done in combinational logic if its don in the ff the shift and correction would happen on the same clk cycle !!

always_comb begin
    BCD_next = BCD; //prevent infered latches 

    if (BCD_next[15:12] >= 5) BCD_next[15:12] = BCD_next[15:12] + 3; // we must check each part of the bcd first then shift 
    if (BCD_next[11:8]  >= 5) BCD_next[11:8]  = BCD_next[11:8]  + 3;
    if (BCD_next[7:4]   >= 5) BCD_next[7:4]   = BCD_next[7:4]   + 3;
    if (BCD_next[3:0]   >= 5) BCD_next[3:0]   = BCD_next[3:0]   + 3;

    BCD_next = {BCD_next[14:0], Scaled_Binary[Bit_cnt-1]}; //shifting to the left with the msb of the scaled binary 
end


//bcd register and output register 
always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n || clr_i) begin
        BCD <= 0;
        Bit_cnt <= 12;
        BCD_ready <= 0;
        BCD_busy <= 0;
        dout_bcd_o <= 0;
    end
    else if (Bin_ready && !BCD_busy) begin
        // start conversion
        BCD <= 0;
        Bit_cnt <= 12;
        BCD_busy <= 1;
        BCD_ready <= 0;
    end
    else if (BCD_busy) begin
        if (Bit_cnt > 0) begin
            BCD <= BCD_next;
            Bit_cnt <= Bit_cnt - 1;
        end
        else begin
            dout_bcd_o <= BCD;   // latch final value
            BCD_ready <= 1;
            BCD_busy <= 0;       // STOP
        end
    end
end



assign dout_o = Scaled_Binary;


endmodule
`default_nettype wire                                                   