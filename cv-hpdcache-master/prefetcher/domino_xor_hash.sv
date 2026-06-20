import domino_pkg::*;
module domino_xor_hash (
    input  logic [ADDR_WIDTH-1:0] addr_in1_i,
    input  logic [ADDR_WIDTH-1:0] addr_in2_i, // Dùng cho MHT2 (XOR 2 địa chỉ)
    output logic [INDEX_WIDTH-1:0] hash_idx_o
);
    logic [ADDR_WIDTH-1:0] folded_addr;
    assign folded_addr = addr_in1_i ^ addr_in2_i; // Nếu MHT1 thì in2 sẽ nối với 0
    
    // Gấp (Fold) địa chỉ dài thành index ngắn bằng phép XOR
    assign hash_idx_o = folded_addr[INDEX_WIDTH-1:0] ^ 
                        folded_addr[2*INDEX_WIDTH-1:INDEX_WIDTH] ^ 
                        folded_addr[3*INDEX_WIDTH-1:2*INDEX_WIDTH];
endmodule