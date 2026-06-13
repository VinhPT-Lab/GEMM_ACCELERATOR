`timescale 1ns / 1ps

//=====================================================================
// BRAM CONFIGURATION
//=====================================================================
//
// IP Name:
//      blk_mem_gen_0
//
// Memory Type:
//      True Dual Port RAM
//
// Read Mode:
//      READ_FIRST
//
// Clock:
//      Port A and Port B use the same clock (clk)
//
// Primitive Output Register:
//      OFF
//
// Read Latency:
//      1 clock cycle
//
//      Cycle N:
//          addrb <= addr
//          a_rd_en = 1
//
//      Cycle N+1:
//          doutb valid
//          a_valid = 1
//
// Port Mapping:
//      Port A : DMA Write
//      Port B : PE Read
//
//=====================================================================
// MEMORY ORGANIZATION
//=====================================================================
//
// Data Width:
//      128 bits
//
// Address Width:
//      13 bits
//
// Depth:
//      2^13 = 8192 locations
//
// Capacity per BRAM:
//
//      8192 x 128 bits
//      = 1,048,576 bits
//      = 131,072 bytes
//      = 128 KB
//
// Buffer Usage:
//
//      BRAM_A : Matrix A Buffer
//      BRAM_W : Matrix W Buffer
//
// Total Buffer Size:
//
//      128 KB + 128 KB
//      = 256 KB
//
//=====================================================================
// DATA FORMAT
//=====================================================================
//
// One BRAM address stores:
//
//      128 bits
//      = 16 x int8
//      = 16 matrix elements
//
// Example:
//
//      addr 0 -> A[0][0:15]
//      addr 1 -> A[1][0:15]
//      ...
//
//=====================================================================
// WRITE PATH
//=====================================================================
//
// DDR
//   |
// AXI DMA
//   |
// AXI Stream
//   |
// BRAM Port A
//
// Write Condition:
//
//      s_axis_*_tvalid && s_axis_*_tready
//
// Write Address:
//
//      wr_addr_*
//
// After receiving tlast:
//
//      *_load_done = 1
//
//=====================================================================
// READ PATH
//=====================================================================
//
// Controller / PE
//        |
//      addr
//        |
// BRAM Port B
//        |
//      doutb
//        |
//     a_data / w_data
//
// Read Condition:
//
//      a_rd_en
//      w_rd_en
//
// Controller decides:
//
//      - Which address to read
//      - Read sequence
//      - Data scheduling for systolic array
//
// Buffer only stores and returns data.
//
//=====================================================================
// READ_FIRST BEHAVIOR
//=====================================================================
//
// Same Clock:
//
//      Port A write addr X
//      Port B read  addr X
//
// READ_FIRST:
//
//      Read returns OLD data
//
//      Cycle N:
//          mem[X] = OLD
//
//          write NEW -> mem[X]
//          read  mem[X]
//
//      Output:
//          OLD
//
//      After clock:
//          mem[X] = NEW
//
//=====================================================================
// BUFFER RELOAD
//=====================================================================
//
// clear_buffer:
//
//      wr_addr_a     <= 0
//      wr_addr_w     <= 0
//      a_load_done   <= 0
//      w_load_done   <= 0
//
// BRAM contents are NOT cleared.
//
// New DMA transfer will overwrite old data.
//
//=====================================================================


module In_buffer #
(
            // bram IP configure data in one addr = 8x16 = 128bit 
            //                         buffer depth = 8192
            // need to match parameter to bram configuration

            parameter integer DATA_W = 8,
            parameter integer ARRAY_S = 16,
            parameter integer A_DEPTH = 8192,
            parameter integer W_DEPTH = 8192
)(

(
    input clk,
    input rst_n,

    input clear_buffer,

    //=================================
    // DMA --> Buffer 
    //=================================
    input  [DATA_W*ARRAY_S-1 :0] s_axis_a_tdata,
    input          s_axis_a_tvalid,
    output         s_axis_a_tready,
    input          s_axis_a_tlast,        // dma inform load full matrix a

    input  [DATA_W*ARRAY_S-1:0] s_axis_w_tdata,
    input          s_axis_w_tvalid,
    output         s_axis_w_tready,
    input          s_axis_w_tlast,         // dma inform load full matrix w

    //=================================
    // status
    //=================================
    output         a_load_done,             // buffer inform load full matrix
    output         w_load_done,

    //=================================
    // Buffer --> PE
    //=================================
    input          a_rd_en,
    input  [$clog2(A_DEPTH)-1 :0]  a_addr,
    output [DATA_W*ARRAY_S-1:0] a_data,
    output         a_valid,                 // connect to pe array to inform data valid

    input          w_rd_en,
    input  [$clog2(W_DEPTH)-1:0]  w_addr,
    output [DATA_W*ARRAY_S-1:0] w_data,
    output         w_valid                  // connect to pe array to inform data valid
);


//====================================================
// LOAD DONE
//====================================================

    reg a_load_done_r;
    reg w_load_done_r;

    assign a_load_done = a_load_done_r;
    assign w_load_done = w_load_done_r;

//====================================================
// WRITE ADDRESS
//====================================================

    reg [$clog2(A_DEPTH)-1:0] wr_addr_a;
    reg [$clog2(W_DEPTH)-1:0] wr_addr_w;

//====================================================
// READY
//====================================================

    assign s_axis_a_tready = !a_load_done_r;
    assign s_axis_w_tready = !w_load_done_r;

//====================================================
// WRITE ADDRESS CONTROL
//====================================================

    always @(posedge clk or negedge rst_n) begin
        if(!rst_n)
            wr_addr_a <= 13'd0;
        else if(clear_buffer)
            wr_addr_a <= 13'd0;
        else if(s_axis_a_tvalid && s_axis_a_tready)
            wr_addr_a <= wr_addr_a + 13'd1;
    end

    always @(posedge clk or negedge rst_n) begin
        if(!rst_n)
            wr_addr_w <= 13'd0;
        else if(clear_buffer)
            wr_addr_w <= 13'd0;
        else if(s_axis_w_tvalid && s_axis_w_tready)
            wr_addr_w <= wr_addr_w + 13'd1;
    end

//====================================================
// LOAD DONE CONTROL
//====================================================

    always @(posedge clk or negedge rst_n) begin
        if(!rst_n)
            a_load_done_r <= 1'b0;
        else if(clear_buffer)
            a_load_done_r <= 1'b0;
        else if(s_axis_a_tvalid &&
                s_axis_a_tready &&
                s_axis_a_tlast)
            a_load_done_r <= 1'b1;
    end

    always @(posedge clk or negedge rst_n) begin
        if(!rst_n)
            w_load_done_r <= 1'b0;
        else if(clear_buffer)
            w_load_done_r <= 1'b0;
        else if(s_axis_w_tvalid &&
                s_axis_w_tready &&
                s_axis_w_tlast)
            w_load_done_r <= 1'b1;
    end

//====================================================
// BRAM A
//====================================================

    wire [127:0] doutb_a;
    wire    wea_a;

    assign wea_a =
            s_axis_a_tvalid &&
            s_axis_a_tready;

    blk_mem_gen_0 u_bram_a
    (
        //port A_1  write only
        .clka(clk),
        .ena(1'b1),
        .wea(wea_a),
        .addra(wr_addr_a),
        .dina(s_axis_a_tdata),
        .douta(),

        // port A_2  read only
        .clkb(clk),
        .enb(1'b1),
        .web(1'd0),
        .addrb(a_addr),
        .dinb(128'd0),
        .doutb(doutb_a)
    );

//====================================================
// BRAM W
//====================================================

    wire [DATA_W*ARRAY_S-1:0] doutb_w;
    wire    wea_w;

    assign wea_w =
            s_axis_w_tvalid &&
            s_axis_w_tready;

    blk_mem_gen_0 u_bram_w
    (
        //port W_1  write only
        .clka(clk),
        .ena(1'b1),
        .wea(wea_w),
        .addra(wr_addr_w),
        .dina(s_axis_w_tdata),
        .douta(),

        // port W_2  read only
        .clkb(clk),
        .enb(1'b1),
        .web(1'd0),
        .addrb(w_addr),
        .dinb(128'd0),
        .doutb(doutb_w)
    );

//====================================================
// Primitive Output Register = OFF  
//
// addr -> dout : delay  1 cycle 
//====================================================

    reg a_rd_en_d1;

    always @(posedge clk or negedge rst_n) begin
        if(!rst_n)
            a_rd_en_d1 <= 1'b0;
        else
            a_rd_en_d1 <= a_rd_en && a_load_done_r;
    end

    assign a_valid = a_rd_en_d1;
    assign a_data  = doutb_a;

    //====================================================

    reg w_rd_en_d1;

    always @(posedge clk or negedge rst_n) begin
        if(!rst_n)
            w_rd_en_d1 <= 1'b0;
        else
            w_rd_en_d1 <= w_rd_en && w_load_done_r;
    end

    assign w_valid = w_rd_en_d1;
    assign w_data  = doutb_w;

//====================================================

endmodule