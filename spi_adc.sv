module spi_adc(
  input  wire        rst_n,         // I; Reset (active low)
  input  wire        clk,           // I; Clock

  // Control
  input  wire        en_i,          // I; Enable

  // SPI interface (Pmod AD1 style: shared CS/SCK, 2× MISO)
  output logic       spi_cs_no,     // O; SPI chip select (active low)
  output logic       spi_sck_o,     // O; SPI clock
  input  wire [1:0]  spi_miso_i,    // I; SPI data in (2 bits)

  // data output
  output logic       data_update_o, // O; New data available
  output logic [11:0] data0_o,      // O; ADC data channel 0
  output logic [11:0] data1_o       // O; ADC data channel 1
);

  // "Constants" as logic (do not reassign them anywhere)
  logic [4:0] frame_bits = 5'd16;   // 16 SCLKs per frame 
  logic [3:0] n_bits     = 4'd12;   // 12-bit ADC (AD7476A) 

  // Clock divider configuration 
  logic [7:0] clk_div    = 8'd10;   // example: toggle SCK every 10 clk cycles

  // Internal signals
  logic [7:0] clk_cnt;              // divider counter
  logic [4:0] bit_cnt;              // counts SCLK rising edges 0..15
  logic       busy;                 // 1 = frame in progress
  logic [15:0] shift0;              // channel 0 shift register
  logic [15:0] shift1;              // channel 1 shift register

  // -------------------------------------------------------------------------
  // Sequential logic: reset, SPI state, shifting, and outputs
  // -------------------------------------------------------------------------
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      // Async reset
      spi_cs_no      <= 1'b1;       // deselect ADCs
      spi_sck_o      <= 1'b0;
      data_update_o  <= 1'b0;
      data0_o        <= '0;
      data1_o        <= '0;
      clk_cnt        <= '0;
      bit_cnt        <= '0;
      busy           <= 1'b0;
      shift0         <= '0;
      shift1         <= '0;
    end else begin
      // Default each cycle
      data_update_o <= 1'b0;

      if (!busy) begin
        // Idle state: start a new frame only when enabled
        if (en_i) begin
          busy      <= 1'b1;
          spi_cs_no <= 1'b0;        // assert CS low
          spi_sck_o <= 1'b0;        // start SCK low
          clk_cnt   <= '0;
          bit_cnt   <= '0;
          shift0    <= '0;
          shift1    <= '0;
        end else begin
          // Stay idle if not enabled
          spi_cs_no <= 1'b1;
          spi_sck_o <= 1'b0;
        end
      end else begin
        // Frame in progress: generate SCK via divider
        if (clk_cnt == clk_div - 1) begin
          clk_cnt  <= '0;
          spi_sck_o <= ~spi_sck_o;

          // Sample on SCK rising edge (old SCK was 0)
          if (spi_sck_o == 1'b0) begin
            // shift in current bits from both channels
            shift0 <= {shift0[14:0], spi_miso_i[0]};
            shift1 <= {shift1[14:0], spi_miso_i[1]};
            bit_cnt <= bit_cnt + 1;

            // Check end of 16-bit frame
            if (bit_cnt == frame_bits) begin
              busy      <= 1'b0;
              spi_cs_no <= 1'b1;    // deassert CS
              spi_sck_o <= 1'b0;

              // Extract 12-bit data from 16-bit frame 
              // Pmod AD1: 4 leading zeros + 12 data bits MSB first
            
              if (n_bits == 4'd12) begin
                data0_o <= shift0[11:0];
                data1_o <= shift1[11:0];
              end //else begin
                // If ever using 10/8-bit parts, adjust here
              // data0_o <= shift0[11:0];
              // data1_o <= shift1[11:0];
             // end

              data_update_o <= 1'b1; // pulse "new data" flag
            end
          end
          // On SCK falling edge, ADC updates MISO internally;
        end else begin
          // Wait for next SCK toggle
          clk_cnt <= clk_cnt + 1;
        end
      end
    end
  end

endmodule
