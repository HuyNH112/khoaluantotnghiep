import domino_pkg::*;
module domino_prefetcher_top (
    input  logic                  clk,
    input  logic                  rst_n,
    
    // Nối với HPDcache
    input  logic                  evt_cache_read_miss_i,
    input  logic [ADDR_WIDTH-1:0] miss_addr_i,
    
    // Yêu cầu Prefetch bắn ra cho HPDcache hoặc Core Arbiter
    output domino_pref_req_t      pref_req_o
);

    logic                  miss_detected;
    logic [ADDR_WIDTH-1:0] curr_miss_addr;
    logic [ADDR_WIDTH-1:0] pre_miss, pre2_miss;
    
    // 1. Trigger
    domino_trigger_detector u_trigger (
        .clk(clk), .rst_n(rst_n),
        .evt_cache_read_miss_i(evt_cache_read_miss_i),
        .miss_addr_i(miss_addr_i),
        .miss_detected_o(miss_detected),
        .miss_addr_o(curr_miss_addr)
    );
    
    // 2. History
    domino_history_buffers u_history (
        .clk(clk), .rst_n(rst_n),
        .update_en_i(miss_detected),
        .curr_miss_i(curr_miss_addr),
        .pre_miss_o(pre_miss), .pre2_miss_o(pre2_miss)
    );
    
    // 3. Hash cho MHT1 và MHT2 (TÁCH BIỆT HASH ĐỌC VÀ GHI)
    logic [INDEX_WIDTH-1:0] write_hash_mht1, write_hash_mht2;
    logic [INDEX_WIDTH-1:0] read_hash_mht1, read_hash_mht2;

    domino_xor_hash u_hash_write_mht1 (.addr_in1_i(pre_miss), .addr_in2_i('0), .hash_idx_o(write_hash_mht1));
    domino_xor_hash u_hash_write_mht2 (.addr_in1_i(pre_miss), .addr_in2_i(pre2_miss), .hash_idx_o(write_hash_mht2));

    domino_xor_hash u_hash_read_mht1 (.addr_in1_i(curr_miss_addr), .addr_in2_i('0), .hash_idx_o(read_hash_mht1));
    domino_xor_hash u_hash_read_mht2 (.addr_in1_i(curr_miss_addr), .addr_in2_i(pre_miss), .hash_idx_o(read_hash_mht2));

    // 4. Bảng MHT1 & MHT2
    logic mht1_valid, mht2_valid;
    logic [ADDR_WIDTH-1:0] mht1_data, mht2_data;
    
    domino_mht_ram u_mht1 (
        .clk(clk), .rst_n(rst_n),
        .read_en_i(miss_detected), .read_idx_i(read_hash_mht1),
        .read_valid_o(mht1_valid), .read_data_o(mht1_data),
        .write_en_i(miss_detected), .write_idx_i(write_hash_mht1), .write_data_i(curr_miss_addr)
    );
    
    domino_mht_ram u_mht2 (
        .clk(clk), .rst_n(rst_n),
        .read_en_i(miss_detected), .read_idx_i(read_hash_mht2),
        .read_valid_o(mht2_valid), .read_data_o(mht2_data),
        .write_en_i(miss_detected), .write_idx_i(write_hash_mht2), .write_data_i(curr_miss_addr)
    );
    
    // 5. Cấp quyền ưu tiên (Priority Mux)
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pref_req_o.valid <= 1'b0;
            pref_req_o.pref_addr <= '0;
        end else begin
            if (mht2_valid) begin
                pref_req_o.valid <= 1'b1;
                pref_req_o.pref_addr <= mht2_data;
            end else if (mht1_valid) begin
                pref_req_o.valid <= 1'b1;
                pref_req_o.pref_addr <= mht1_data;
            end else begin
                pref_req_o.valid <= 1'b0;
            end
        end
    end
endmodule