`timescale 1ns / 1ps

module PE_LINE
#(
    parameter ARRAY_M = 4,
    parameter ARRAY_N = 4,
    parameter DATA_WIDTH = 8,
    parameter LOG2_ARRAY_M = 2
)
(
    input                                               clk,
    input                                               rst_n,
    input                                               weight_load,

    input  [DATA_WIDTH-1:0]                             act_in,

    input  [ARRAY_N*(LOG2_ARRAY_M+DATA_WIDTH*2)-1:0]    psum_in_bus,
    input  [ARRAY_N*DATA_WIDTH-1:0]                     weight_bus,

    output [ARRAY_N*(LOG2_ARRAY_M+DATA_WIDTH*2)-1:0]    psum_out_bus
);

wire [2*DATA_WIDTH+LOG2_ARRAY_M-1:0] psum_in_vec  [ARRAY_N-1:0];
wire [2*DATA_WIDTH+LOG2_ARRAY_M-1:0] psum_out_vec [ARRAY_N-1:0];

wire [DATA_WIDTH-1:0] weight_vec [ARRAY_N-1:0];

wire [DATA_WIDTH-1:0] act_pipe [ARRAY_N:0];

assign act_pipe[0] = act_in;

genvar i;

generate
    for(i=0;i<ARRAY_N;i=i+1)
    begin : bus_unpack

        assign weight_vec[i] =
               weight_bus[DATA_WIDTH*i +: DATA_WIDTH];

        assign psum_in_vec[i] =
               psum_in_bus[(LOG2_ARRAY_M+DATA_WIDTH*2)*i +:
                           (LOG2_ARRAY_M+DATA_WIDTH*2)];

        assign psum_out_bus[(LOG2_ARRAY_M+DATA_WIDTH*2)*i +:
                            (LOG2_ARRAY_M+DATA_WIDTH*2)]
               = psum_out_vec[i];

    end
endgenerate


generate
    for(i=0;i<ARRAY_N;i=i+1)
    begin : pe_chain

        PE
        #(
            .DATA_WIDTH(DATA_WIDTH),
            .ARRAY_M(ARRAY_M),
            .ARRAY_N(ARRAY_N),
            .LOG2_ARRAY_M(LOG2_ARRAY_M)
        )
        u_pe
        (
            .clk(clk),
            .rst_n(rst_n),

            .weight_load(weight_load),

            .act_in(act_pipe[i]),
            .weight_in(weight_vec[i]),

            .psum_in(psum_in_vec[i]),

            .act_out(act_pipe[i+1]),
            .psum_out(psum_out_vec[i])
        );

    end
endgenerate

endmodule