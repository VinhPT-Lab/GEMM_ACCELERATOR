`timescale 1ns / 1ps

module Delay_line
#(
    parameter integer DATA_W = 8,
    parameter integer DELAY  = 0
)
(
    input  wire              clk,
    input  wire              rst_n,

    input  wire              in_valid,
    output wire              out_valid,

    input  wire [DATA_W-1:0] data_in,
    output wire [DATA_W-1:0] data_out
);

generate

    if(DELAY == 0)
    begin : NO_DELAY

        assign data_out  = data_in;
        assign out_valid = in_valid;

    end
    else
    begin : WITH_DELAY

        reg [DATA_W-1:0] data_pipe  [0:DELAY-1];
        reg              valid_pipe [0:DELAY-1];

        integer i;

        always @(posedge clk or negedge rst_n)
        begin
            if(!rst_n)
            begin
                for(i=0;i<DELAY;i=i+1)
                begin
                    data_pipe[i]  <= 0;
                    valid_pipe[i] <= 0;
                end
            end
            else
            begin
                data_pipe[0]  <= data_in;
                valid_pipe[0] <= in_valid;

                for(i=1;i<DELAY;i=i+1)
                begin
                    data_pipe[i]  <= data_pipe[i-1];
                    valid_pipe[i] <= valid_pipe[i-1];
                end
            end
        end

        assign data_out  = data_pipe[DELAY-1];
        assign out_valid = valid_pipe[DELAY-1];

    end

endgenerate

endmodule