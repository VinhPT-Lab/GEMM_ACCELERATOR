`timescale 1ns / 1ps

module PE #
(
    parameter integer DATA_W  = 8,
    parameter integer ARRAY_S = 16,
    parameter integer OUT_W   = DATA_W*2 + ARRAY_S
)
(
    input wire clk,
    input wire rst_n,

    input wire              weight_in_valid,
    input wire [DATA_W-1:0] weight_in,

    input wire              psum_in_valid,
    output wire             psum_out_valid,
    input wire [OUT_W-1:0]  psum_in,
    output wire [OUT_W-1:0] psum_out,

    input wire              act_in_valid,
    output wire             act_out_valid,
    input wire [DATA_W-1:0] act_in,
    output wire [DATA_W-1:0] act_out
);

//=================================================
localparam integer PRODUCT_W    = DATA_W*2;
localparam integer MULT_LATENCY = 2;

reg [DATA_W-1:0] weight_reg;

wire [PRODUCT_W-1:0] mult_p;

reg [OUT_W-1:0]  psum_pipe [0:MULT_LATENCY-1];
reg [DATA_W-1:0] act_pipe  [0:MULT_LATENCY-1];
reg              psum_valid_pipe [0:MULT_LATENCY-1];
reg              act_valid_pipe  [0:MULT_LATENCY-1];

integer i;
//=================================================



//============== load weight =====================
always @(posedge clk or negedge rst_n)
begin
    if(!rst_n)
        weight_reg <= 0;
    else if(weight_in_valid)
        weight_reg <= weight_in;
end
//=================================================



//============== DSP multiplier IP ================
mult_gen_0 mult_gen_0_inst
(
    .CLK(clk),
    .A(act_in),
    .B(weight_reg),
    .P(mult_p)
);
//=================================================



//============== delay valid/data =================
always @(posedge clk or negedge rst_n)
begin
    if(!rst_n)
    begin
        for(i=0;i<MULT_LATENCY;i=i+1)
        begin
            psum_pipe[i]       <= 0;
            act_pipe[i]        <= 0;
            psum_valid_pipe[i] <= 0;
            act_valid_pipe[i]  <= 0;
        end
    end
    else
    begin
        psum_pipe[0]       <= psum_in;
        act_pipe[0]        <= act_in;
        psum_valid_pipe[0] <= psum_in_valid & act_in_valid;
        act_valid_pipe[0]  <= act_in_valid;

        for(i=1;i<MULT_LATENCY;i=i+1)
        begin
            psum_pipe[i]       <= psum_pipe[i-1];
            act_pipe[i]        <= act_pipe[i-1];
            psum_valid_pipe[i] <= psum_valid_pipe[i-1];
            act_valid_pipe[i]  <= act_valid_pipe[i-1];
        end
    end
end
//=================================================



//============== output ===========================
assign psum_out_valid = psum_valid_pipe[MULT_LATENCY-1];
assign act_out_valid  = act_valid_pipe[MULT_LATENCY-1];
assign act_out        = act_pipe[MULT_LATENCY-1];
assign psum_out       = psum_pipe[MULT_LATENCY-1] +
                        {{(OUT_W-PRODUCT_W){mult_p[PRODUCT_W-1]}}, mult_p};
//=================================================

endmodule
