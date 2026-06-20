import domino_pkg::*;
module domino_trigger_detector (
    input  logic                  clk,
    input  logic                  rst_n,
    // Giao tiếp với HPDcache events
    input  logic                  evt_cache_read_miss_i,
    input  logic [ADDR_WIDTH-1:0] miss_addr_i,
    
    output logic                  miss_detected_o,
    output logic [ADDR_WIDTH-1:0] miss_addr_o
);
    // Xử lý xung cạnh để bắt đúng 1 chu kỳ Miss
    logic miss_q;
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) miss_q <= 1'b0;
        else        miss_q <= evt_cache_read_miss_i;
    end
    
    assign miss_detected_o = evt_cache_read_miss_i & ~miss_q;
    assign miss_addr_o     = miss_addr_i;
endmodule