import domino_pkg::*;
module domino_history_buffers (
    input  logic                  clk,
    input  logic                  rst_n,
    input  logic                  update_en_i,
    input  logic [ADDR_WIDTH-1:0] curr_miss_i,
    
    output logic [ADDR_WIDTH-1:0] pre_miss_o,  // Miss(t-1)
    output logic [ADDR_WIDTH-1:0] pre2_miss_o  // Miss(t-2)
);
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pre_miss_o  <= '0;
            pre2_miss_o <= '0;
        end else if (update_en_i) begin
            pre2_miss_o <= pre_miss_o;  // Dịch Miss(t-1) thành Miss(t-2)
            pre_miss_o  <= curr_miss_i; // Cập nhật Miss hiện tại thành Miss(t-1)
        end
    end
endmodule