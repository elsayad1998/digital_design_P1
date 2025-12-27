`default_nettype none

module uart_top #(
  parameter int CHAR_NR   = 8,              // Number of characters to send
  parameter int CLK_FREQ  = 100_000_000,     // Clock frequency (Hz)
  parameter int BAUD_RATE = 9600          // UART baud rate
) (
  input   wire                     clk,
  input   wire                     rst_n,
  input   wire [(CHAR_NR*8)-1:0]   char_array_i,
  input   wire                     char_array_update_i,
  input   wire                     clr_i,
  output  logic                    busy_o,
  output  logic                    txd_o
);

  // ---------------------------------------------------------
  // UART timing
  // ---------------------------------------------------------
  localparam int BAUD_DIV = CLK_FREQ / BAUD_RATE;

  // ---------------------------------------------------------
  // State machine
  // ---------------------------------------------------------
  typedef enum logic [1:0] {
    IDLE,
    START,
    DATA,
    STOP
  } uart_state_t;

  uart_state_t state;

  // ---------------------------------------------------------
  // Registers
  // ---------------------------------------------------------
  logic [$clog2(BAUD_DIV)-1:0] baud_cnt;  // to save the size of the clog2(BAUD_DIV) to prevent overflow fronm happen 
  logic [3:0]                 bit_cnt;
  logic [7:0]                 tx_byte;// ton take the character byte by byte
  logic [$clog2(CHAR_NR):0]   char_cnt; // to count th character that it send 

  // ---------------------------------------------------------
  // UART transmitter
  // ---------------------------------------------------------
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      state     <= IDLE;
      baud_cnt  <= '0;
      bit_cnt   <= '0;
      char_cnt  <= '0;
      txd_o     <= 1'b1;   // UART idle line is HIGH
      busy_o    <= 1'b0;
    end
    else if (clr_i) begin
      state     <= IDLE;
      char_cnt  <= '0;
      txd_o     <= 1'b1;
      busy_o    <= 1'b0;
    end
    else begin
      case (state)

        // ---------------- IDLE ----------------
        IDLE: begin
          txd_o  <= 1'b1;
          busy_o <= 1'b0;

          if (char_array_update_i) begin
            tx_byte <= char_array_i[7:0];
            char_cnt <= 0;
            baud_cnt <= 0;
            state <= START;
            busy_o <= 1'b1;
          end
        end

        // ---------------- START BIT ----------------
        START: begin
          txd_o <= 1'b0;  // Start bit

          if (baud_cnt == BAUD_DIV-1) begin // baud_div -1 because you start frm 0
            baud_cnt <= 0;
            bit_cnt  <= 0;
            state    <= DATA;
          end else begin
            baud_cnt <= baud_cnt + 1;
          end
        end

        // ---------------- DATA BITS ----------------
        DATA: begin
          txd_o <= tx_byte[bit_cnt];

          if (baud_cnt == BAUD_DIV-1) begin
            baud_cnt <= 0;

            if (bit_cnt == 7) begin // because only uart frame consist of 8 bit 
              state <= STOP;
            end else begin
              bit_cnt <= bit_cnt + 1;
            end
          end else begin
            baud_cnt <= baud_cnt + 1;
          end
        end

        // ---------------- STOP BIT ----------------
        STOP: begin
          txd_o <= 1'b1;

          if (baud_cnt == BAUD_DIV-1) begin
            baud_cnt <= 0;

            if (char_cnt == CHAR_NR-1) begin
              state <= IDLE;
            end else begin
              char_cnt <= char_cnt + 1;
              tx_byte <= char_array_i[(char_cnt+1)*8 +: 8];// to save the all char in 64 bit and the tx vector[start_index +: width]

              state <= START;
            end
          end else begin
            baud_cnt <= baud_cnt + 1;
          end
        end

      endcase
    end
  end

endmodule

`default_nettype wire
