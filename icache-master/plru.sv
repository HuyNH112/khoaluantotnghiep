// ============================================================
// plru.sv  -  Wrapper cho plru_tree.sv cua hang
//             ETH Zurich / OpenHW Group
//
// Ly do can wrapper:
//   plru_tree.sv (hang) dung interface ONE-HOT:
//     used_i  [ENTRIES-1:0]  (one-hot)
//     plru_o  [ENTRIES-1:0]  (one-hot)
//
//   cva6_icache.sv can interface BINARY INDEX:
//     access_way_i [$clog2(NUM_WAYS)-1:0]
//     replace_way_o[$clog2(NUM_WAYS)-1:0]
//
//   Wrapper nay thuc hien:
//     1. Binary -> One-hot : access_way_i  -> used_onehot
//     2. One-hot -> Binary : plru_onehot   -> replace_way_o
//     3. Them flush_i: reset cay khi ICache flush
//        (plru_tree.sv chi co rst_ni, khong co flush)
//
// File hang (plru_tree.sv) KHONG bi chinh sua, chi instantiate.
//
// Tuong thich: cv32a6_imac_sv32, NUM_WAYS = 4 (mac dinh)
// ============================================================

module plru #(
    parameter int unsigned NUM_WAYS = 4
) (
    input  logic                         clk_i,
    input  logic                         rst_ni,

    // cap nhat PLRU: assert 1 cycle khi hit hoac refill xong
    input  logic                         update_i,
    input  logic [$clog2(NUM_WAYS)-1:0]  access_way_i,

    // flush toan bo cay (khi icache flush)
    input  logic                         flush_i,

    // victim way (thay cho repl_way / rnd_way trong icache)
    output logic [$clog2(NUM_WAYS)-1:0]  replace_way_o
);

    // ----------------------------------------------------------------
    // Hang so
    // ----------------------------------------------------------------
    localparam int unsigned WAY_WIDTH = $clog2(NUM_WAYS);

    // ----------------------------------------------------------------
    // Reset tong hop: rst_ni AND (NOT flush_i)
    // plru_tree chi co rst_ni → dung tin hieu reset ao
    // khi flush_i = 1, keo rst_combined xuong 0 → plru_tree reset
    // ----------------------------------------------------------------
    logic rst_combined;
    assign rst_combined = rst_ni & ~flush_i;

    // ----------------------------------------------------------------
    // Chuyen doi Binary -> One-hot
    // Chi truyen len plru_tree khi update_i = 1
    // ----------------------------------------------------------------
    logic [NUM_WAYS-1:0] used_onehot;

    always_comb begin : bin_to_onehot
        used_onehot = '0;
        if (update_i) begin
            used_onehot[access_way_i] = 1'b1;
        end
    end

    // ----------------------------------------------------------------
    // Ket qua tu plru_tree (one-hot output)
    // ----------------------------------------------------------------
    logic [NUM_WAYS-1:0] plru_onehot;

    // ----------------------------------------------------------------
    // Instantiate plru_tree cua hang (giu nguyen, khong sua)
    // ----------------------------------------------------------------
    plru_tree #(
        .ENTRIES (NUM_WAYS)
    ) i_plru_tree (
        .clk_i   (clk_i),
        .rst_ni  (rst_combined),
        .used_i  (used_onehot),
        .plru_o  (plru_onehot)
    );

    // ----------------------------------------------------------------
    // Chuyen doi One-hot -> Binary (priority encoder)
    // plru_onehot la one-hot → tim vi tri bit = 1
    // ----------------------------------------------------------------
    always_comb begin : onehot_to_bin
        replace_way_o = '0;
        for (int unsigned w = 0; w < NUM_WAYS; w++) begin
            if (plru_onehot[w]) begin
                replace_way_o = WAY_WIDTH'(w);
            end
        end
    end

    // ----------------------------------------------------------------
    // Assertions (chi cho simulation)
    // ----------------------------------------------------------------
    // synthesis translate_off
    always_ff @(posedge clk_i) begin
        if (rst_ni && !flush_i) begin
            assert ($onehot(plru_onehot))
                else $error("plru: plru_onehot khong hop le (khong phai one-hot): %b",
                            plru_onehot);
        end
    end
    // synthesis translate_on

endmodule
// ── End of plru.sv (wrapper) ───────────────────────────────────────
