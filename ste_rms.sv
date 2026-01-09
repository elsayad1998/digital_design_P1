
//`default_nettype none
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
logic                         Window_Full = 0;
logic [(DATA_W * 2)-1:0]      Square = 0;
logic [31:0]                  buff [0:255];
logic [7:0]                   Pointer;  // 0..255
logic [(DATA_W * 2)+7:0]      Sum = 0; 
logic [(DATA_W * 2)-1:0]      Mean = 0; 


// definitions for the sqrt calculation by try and error 

logic [(DATA_W * 2)-1:0]      prod;    
logic [DATA_W-1:0]            sqrt_reg;   // result being built
logic [DATA_W-1:0]            bit_id;     // bit index (DATA_W down to 0)
logic [(DATA_W * 2)-1:0]      Mean_Latched;


typedef enum logic [1:0] {
        IDLE,
        SET_BIT,
        CHECK,
        DONE
    } state_t;

    state_t state;

// comb logic for the square and mean
always_ff @(posedge clk)
begin
Square = din_i * din_i;
Mean <= Sum >> 8;
end

// write the values in the buffs and calculate the sum
always_ff @(posedge clk or negedge rst_n)
begin
    if (~rst_n || clr_i)
    begin
        Pointer <= 0;
        Sum <= 0;
        Window_Full <= 0;
    end
    else if (din_update_i) begin
    if (Window_Full)
        Sum <= Sum + Square - buff[Pointer];
    else
        Sum <= Sum + Square;
        buff[Pointer] <= Square;
        Pointer <= Pointer + 1;
        
        if (Pointer == 'd255)
        begin
            Window_Full <= 1;
        end    
    end
end

// sqrt part



assign dout_o = sqrt_reg;
assign dout_update_o = (state == DONE);

assign prod = sqrt_reg * sqrt_reg;



always_ff @(posedge clk or negedge rst_n) begin
    if (~rst_n || clr_i) begin
        state    <= IDLE;
        sqrt_reg <= '0;
        bit_id   <= DATA_W - 1;
        Mean_Latched <= 0;
    end else begin
        case (state)

            IDLE: begin
                if (din_update_i && Window_Full) begin
                    sqrt_reg <= '0;
                    
                    if (Mean == 0)
                        state    <= DONE;
                    else begin
                        Mean_Latched <= Mean;
                        state    <= SET_BIT;
                        end
                end
            end

            SET_BIT: begin
                sqrt_reg[bit_id] <= 1'b1;
                state <= CHECK;
            end

            CHECK: begin
                if (prod == Mean_Latched)
                 begin  
                    state <= DONE;
                 end
                else if (prod < Mean_Latched)
                        begin 
                            if (bit_id > 0)
                            begin
                            bit_id <= bit_id - 1;
                            state  <= SET_BIT;
                            end
                            //    
                            else begin
                            state <= DONE;
                            end
                        end
                else begin
                    if (bit_id > 0) begin
                         sqrt_reg[bit_id] <= 1'b0;
                         bit_id <= bit_id - 1;
                         state  <= SET_BIT;
                         end
                    else begin 
                         state <= DONE;
                    end
                end
            end

            DONE: begin
                state <= IDLE;
                bit_id   <= DATA_W - 1;
            end

            default: state <= IDLE;

        endcase
    end
end
endmodule

//`default_nettype wire  