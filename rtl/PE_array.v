`timescale 1ns / 1ps

module PE_ARRAY #

(
    parameter integer DATA_W = 8,
    parameter integer ARRAY_S = 16

    )(
    input wire clk,
    input wire rst_n,

    input wire                          start,

    input [DATA_W*ARRAY_S-1: 0]         w_mem_vector_in,
    input                               w_mem_vector_in_valid,
    output reg                          w_load_done;  // load w last, ready to load feture and compute

    input [DATA_W*ARRAY_S-1: 0]         act_vector_in,
    input                               act_vector_in_valid,
    output                              act_load_done

    output reg [ ARRAY_S*(DATA_W*2 + ARRAY_S)-1:0 ]  data_out,
    output reg                                       data_out_valid,
    output reg                                       data_out_last
);


//=================================================
localparam OUT_W = DATA_W*2 + ARRAY_S;
localparam LOG2_ARRAY_S = $clog2(ARRAY_S);
//=================================================



//=========gen W_mem=======================
reg [DATA_W-1:0] w_mem [0:ARRAY_S-1][0:ARRAY_S-1];
//============================================



//==============gen reg/wire====================
reg [LOG2_ARRAY_S-1:0] w_load_cnt;
reg [LOG2_ARRAY_S-1:0] act_load_cnt;

reg [LOG2_ARRAY_S-1:0] skew_out_cnt;
reg comp_done;

reg weight_in_valid;

//===============================================




 //================ for module skew_out================
wire [ARRAY_S*OUT_W-1:0] skew_out_buf; 
wire [ARRAY_S-1:0] skew_out_valid;  
//=================================================


//================ psum + act =====================
wire psum_valid [0:ARRAY_S-1][0:ARRAY_S-1];
wire act_valid [0:ARRAY_S-1][0:ARRAY_S-1];

wire [DATA_W-1 : 0] act_connect [0:ARRAY_S-1][0:ARRAY_S-1];
wire [OUT_W-1 : 0] psum_connect [0: (ARRAY_S-1)][0:ARRAY_S-1];

wire [ARRAY_S-1:0] skew_act_mem_valid;
wire [DATA_W-1:0] skew_act_mem [ARRAY_S-1:0];
//====================================================


//============ for FSM======================= 
localparam IDLE   = 2'd0;
localparam LOAD_W = 2'd1;
localparam COMP   = 2'd2;

reg [1:0] state;
reg [1:0] next_state;

always @(posedge clk or negedge rst_n)
begin
    if(!rst_n)
        state <= IDLE;
    else
        state <= next_state;
end

always @(*)
begin

    next_state = state;

    case(state)

        IDLE:
            if(start)
                next_state = LOAD_W;

        LOAD_W:
            if(w_load_done)
                next_state = COMP;

        COMP:
            if(comp_done)
                next_state = IDLE;

    endcase
end
//===========================================



//============ STATE LOAD_W====================
integer i, v;
always @(posedge clk or negedge rst_n) 
begin
    if(!rst_n)
    begin
        for(i = 0; i< ARRAY_S; i = i+ 1) 
        begin
            for (v = 0; v < ARRAY_S; v= v+1)
                w_mem[i][v] <= 0;
        end
        w_load_cnt  <= 0;
        w_load_done <= 0;
    end
    else if(state == LOAD_W && w_mem_vector_in_valid)
    begin

        for(i=0;i<ARRAY_S;i=i+1) 
            w_mem[w_load_cnt][i] <= w_mem_vector_in[(ARRAY_S-i)*DATA_W-1 -: DATA_W];

        if(w_load_cnt == ARRAY_S-1) 
        begin
            w_load_cnt  <= 0;
            w_load_done <= 1;
        end
        else 
        begin
            w_load_cnt <= w_load_cnt + 1;
            w_load_done <= 0;
        end
    end
    else if(state == COMP && comp_done)
    begin
        w_load_done <= 0;
    end
end

always @(posedge clk or negedge rst_n) 
begin
    if(!rst_n)
        weight_in_valid <= 0;
    else 
        weight_in_valid <= (state==LOAD_W && w_load_done);
end
//====================================================




//======STATE COMP===============================


            //============track act_vector_in==========
            always @(posedge clk or negedge rst_n) begin
                if(!rst_n) begin
                    act_load_cnt  <= 0;
                    act_load_done <= 0;
                end
                else begin
                    act_load_done <= 0;

                    if(act_vector_in_valid) begin

                        if(act_load_cnt == ARRAY_SIZE-1) begin
                            act_load_cnt  <= 0;
                            act_load_done <= 1;
                        end
                        else begin
                            act_load_cnt <= act_load_cnt + 1;
                        end

                    end
                end
            end
            //========================================


always @(posedge clk or negedge rst_n)
begin
    if(!rst_n)
    begin
        skew_out_cnt   <= 0;
        data_out_last  <= 0;
        data_out_valid <= 0;
        data_out       <= 0;
        comp_done      <= 0;
    end
    else if(state != COMP)
    begin
        comp_done      <= 0;
        skew_out_cnt   <= 0;
        data_out_valid <= 0;
        data_out_last  <= 0;

    end
    else if(state == COMP && &skew_out_valid)
    begin
        data_out_valid <= 1;
        data_out       <= skew_out_buf;

        if(skew_out_cnt == ARRAY_S-1)
        begin
            data_out_last  <= 1;
            skew_out_cnt   <= 0;
            comp_done      <= 1;
        end
        else
        begin
            data_out_last  <= 0;
            skew_out_cnt   <= skew_out_cnt + 1;
            comp_done      <= 0;
        end
    end
    else
    begin
        data_out_valid  <= 0;
        data_out_last   <= 0;
    end
end
//==============================================





//===========gen PE + skew_out====================
genvar row;
genvar col;

generate
for(row = 0; row < ARRAY_S; row = row + 1)
begin : PE_row

    for( col = 0; col < ARRAY_S; col = col + 1)
    begin : PE_col

            PE pe_inst
            (
                .clk(clk),
                .rst_n(rst_n),

                .weight_in_valid(weight_in_valid),
                .weight_in(w_mem[row][col]),

                .psum_in_valid( (row == 0) ? ((col == 0) ? skew_act_mem_valid[row] : act_valid[row][col-1]) : psum_valid[row-1][col] ),
                .psum_out_valid( psum_valid[row][col]),
                .psum_in( (row == 0) ? 0 : psum_connect [row-1][col]),
                .psum_out( psum_connect[row][col]),

                .act_in_valid( (col == 0 ) ? skew_act_mem_valid[row] : act_valid[row][col-1]),
                .act_out_valid(act_valid [row][col]),
                .act_in( (col == 0 ) ? skew_act_mem[row] : act_connect[row][col-1]),
                .act_out(act_connect[row][col])
            );

        if(row == ARRAY_S -1) begin

                Delay_line #(
                    .DATA_W(OUT_W),
                    .DELAY(ARRAY_S-1-col)
                )
                skew_out_inst
                (
                .clk(clk),
                .rst_n(rst_n),   

                .in_valid(psum_valid[row][col]),
                .out_valid(skew_out_valid [col]),

                .data_in(psum_connect[row][col]),
                .data_out(skew_out_buf[ (ARRAY_S - col)*OUT_W - 1 -: OUT_W])
                );
        end

        if(col == 0)begin

            Delay_line #(
                .DATA_W(DATA_W),
                .DELAY(row)
            )
            skew_act_inst
            
            (
                .clk(clk),
                .rst_n(rst_n),   

                .in_valid(act_vector_in_valid),
                .out_valid(skew_act_mem_valid[row]),

                .data_in(act_vector_in[(ARRAY_S-row)*DATA_W-1 -: DATA_W]),
                .data_out(skew_act_mem[row])                               
            );
        end 


    end

end
endgenerate
//=================================================


endmodule


