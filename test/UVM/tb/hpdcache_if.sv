`ifndef HPDCACHE_IF_SV
`define HPDCACHE_IF_SV

interface hpdcache_if (input logic clk, input logic rst_n);
    // Tín hiệu Handshake
    logic        req_valid;
    logic        req_ready;
    
    // Tín hiệu Payload (Yêu cầu từ Core)
    logic [2:0]  req_op;       // 0: LOAD, 1: STORE, 2: AMOS...
    logic [2:0]  req_size;     // 000: Byte, 001: HW, 010: Word, 011: DWord
    logic [43:0] req_addr_tag;
    logic [11:0] req_addr_offset;
    logic [63:0] req_wdata;
    logic [7:0]  req_be;       // Byte enable
    logic [7:0]  req_tid;      // Transaction ID
    logic        req_phys_indexed;
    logic        req_need_rsp;

    // Tín hiệu Phản hồi (Từ Cache về Core)
    logic        rsp_valid;
    logic [63:0] rsp_rdata;
    logic [7:0]  rsp_tid;

    // Modport cho Driver (Mô phỏng Core bơm lệnh)
    modport driver_mp (
        input  clk, rst_n, req_ready, rsp_valid, rsp_rdata, rsp_tid,
        output req_valid, req_op, req_size, req_addr_tag, req_addr_offset, 
               req_wdata, req_be, req_tid, req_phys_indexed, req_need_rsp
    );

    // Modport cho Monitor (Nghe lén trên Bus)
    modport monitor_mp (
        input clk, rst_n, req_valid, req_ready, req_op, req_size, req_addr_tag, req_addr_offset,
              req_wdata, req_be, req_tid, rsp_valid, rsp_rdata, rsp_tid
    );

endinterface : hpdcache_if

`endif