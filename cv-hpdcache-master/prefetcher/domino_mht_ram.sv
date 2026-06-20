import domino_pkg::*;
module domino_mht_ram (
    input  logic                   clk,
    input  logic                   rst_n,
    
    // Cổng Đọc (Tra cứu dự đoán)
    input  logic                   read_en_i,
    input  logic [INDEX_WIDTH-1:0] read_idx_i,
    output logic                   read_valid_o,
    output logic [ADDR_WIDTH-1:0]  read_data_o,
    
    // Cổng Ghi (Cập nhật lịch sử mới)
    input  logic                   write_en_i,
    input  logic [INDEX_WIDTH-1:0] write_idx_i,
    input  logic [ADDR_WIDTH-1:0]  write_data_i
);
    // Bảng MHT gồm cờ Valid và Địa chỉ dự đoán
    logic                  valid_array [0:(1<<INDEX_WIDTH)-1];
    logic [ADDR_WIDTH-1:0] data_array  [0:(1<<INDEX_WIDTH)-1];
    
    // Xử lý Ghi
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for(int i=0; i<(1<<INDEX_WIDTH); i++) valid_array[i] <= 1'b0;
        end else if (write_en_i) begin
            valid_array[write_idx_i] <= 1'b1;
            data_array[write_idx_i]  <= write_data_i;
        end
    end
    
    // Xử lý Đọc (Bypass nếu ghi và đọc cùng lúc)
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            read_valid_o <= 1'b0;
            read_data_o  <= '0;
        end else if (read_en_i) begin
            if (write_en_i && (write_idx_i == read_idx_i)) begin
                read_valid_o <= 1'b1;
                read_data_o  <= write_data_i;
            end else begin
                read_valid_o <= valid_array[read_idx_i];
                read_data_o  <= data_array[read_idx_i];
            end
        end else begin
            read_valid_o <= 1'b0;
        end
    end
endmodule