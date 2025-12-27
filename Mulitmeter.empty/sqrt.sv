module sqrt (
    input  logic        clk_i,   //the clock signal for all registers
    input  logic        rst_i,   //the reset signal which is used to reset all registers
    input  logic        start_i, //used to start the computation
    input  logic [39:0] a_i,     //non-negative input value

    output logic        valid_o, //indicates that the computation is finished
    output logic        busy_o,  //indicates that the module is computing the square root
    output logic [15:0] result_o //contains the computed square root when the valid_o signal is high

);
    typedef enum logic [1:0] {INIT,COMP_D, SQRT} state_t;
    logic [39:0] x_p, x_n;
    logic [39:0] d_p, d_n;
    logic [39:0] r_p, r_n;
    state_t state_p, state_n;
    
    logic valid_o_n, busy_o_n;
    logic valid_o_t, busy_o_t; //indicates that the computation is finished

    logic [15:0] result_t;
    always_ff @(posedge clk_i or negedge rst_i) begin
        if (!rst_i) begin
            busy_o_t <= 0; 
            valid_o_t <= 0;
            result_t <= 0;
        end else begin 
            valid_o_t <= valid_o_n;
            busy_o_t  <= busy_o_n;
            r_p <= r_n;
            d_p <= d_n;
            x_p <= x_n;
            state_p <= state_n;
        end
    end

    always_comb begin
        // Defautls
        state_n = INIT; // default and initial value (in case first entry), initial cannot be in always_ff (or else DFFSR)
        busy_o_n = 0; 
        valid_o_n = 0;
        x_n = x_p;
        r_n = r_p;
        d_n = d_p;

        case (state_p)
        INIT: begin 
            if(start_i)begin
                state_n = COMP_D;
                busy_o_n = 0;
                x_n = a_i;
                r_n = 0;
                d_n = 1 << 30;
            end else begin 
                busy_o_n = 0;
                r_n = 0;
                state_n = INIT;
            end
        end
        COMP_D: begin    //6:8
        valid_o_n = 0;
        busy_o_n = 1;
        if (d_p > x_p) begin
            d_n = d_p >> 2;
            state_n = COMP_D;
        end else begin 
            d_n = d_p;
            state_n = SQRT;
        end
        end
        SQRT: begin  //9:17
            if (d_p)begin
                valid_o_n = 0;
                busy_o_n = 1;
                if (x_p >= (r_p + d_p)) begin 
                    x_n = x_p - (r_p + d_p);
                    r_n = (r_p >> 1) + d_p;
                end else begin
                    r_n = r_p >> 1;
                end 
                d_n = d_p >> 2;
                state_n = SQRT;
            end else begin
                d_n = d_p;
                result_t = r_p;
                busy_o_n = 0;
                state_n = INIT;
                valid_o_n = 1;
            end
        end        
        endcase 
    end
    
    assign valid_o=valid_o_t;
    assign busy_o=busy_o_t;
    assign result_o=result_t;
endmodule