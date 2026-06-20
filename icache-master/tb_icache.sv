`timescale 1ns/1ps

import ariane_pkg::*;
import wt_cache_pkg::*;
import config_pkg::*;
import cva6_config_pkg::*; 

// ===========================================================================
// 0. DINH NGHIA KIEU DU LIEU (DAT NGOAI MODULE DE TRANH LOI BINDING)
// ===========================================================================
localparam config_pkg::cva6_user_cfg_t U_Cfg = cva6_config_pkg::cva6_cfg;

localparam config_pkg::cva6_cfg_t Cfg = '{
    VLEN: U_Cfg.VLEN,
    PLEN: 34,
    ICACHE_LINE_WIDTH: U_Cfg.IcacheLineWidth,
    ICACHE_USER_LINE_WIDTH: 32,
    ICACHE_SET_ASSOC: U_Cfg.IcacheSetAssoc,
    ICACHE_SET_ASSOC_WIDTH: 2, 
    ICACHE_INDEX_WIDTH: 12,    
    ICACHE_TAG_WIDTH: 22,      
    FETCH_WIDTH: 32,
    FETCH_ALIGN_BITS: 2,
    FETCH_USER_EN: U_Cfg.FetchUserEn,
    FETCH_USER_WIDTH: U_Cfg.FetchUserWidth,
    MEM_TID_WIDTH: U_Cfg.MemTidWidth,
    NOCType: U_Cfg.NOCType,
    TechnoCut: U_Cfg.TechnoCut,
    default: '0
};

typedef struct packed {
    logic [63:0] cause;
    logic [63:0] tval;
    logic        valid;
} mock_exception_t;

typedef struct packed {
    logic                           fetch_valid;
    logic [Cfg.PLEN-1:0]            fetch_paddr;
    mock_exception_t                fetch_exception;
} mock_areq_i_t;

typedef struct packed {
    logic                           fetch_req;
    logic [Cfg.VLEN-1:0]            fetch_vaddr;
} mock_areq_o_t;

typedef struct packed {
    logic                           req;
    logic                           spec;
    logic [Cfg.VLEN-1:0]            vaddr;
    logic                           kill_s1;
    logic                           kill_s2;
} mock_dreq_i_t;

typedef struct packed {
    logic                           ready;
    logic                           valid;
    logic [Cfg.FETCH_WIDTH-1:0]     data;
    logic [Cfg.FETCH_USER_WIDTH-1:0] user;
    logic [Cfg.VLEN-1:0]            vaddr;
    mock_exception_t                ex;
} mock_dreq_o_t;

typedef struct packed {
    logic [Cfg.PLEN-1:0]            paddr;
    logic [Cfg.ICACHE_SET_ASSOC_WIDTH-1:0] way;
    logic [Cfg.MEM_TID_WIDTH-1:0]   tid;
    logic                           nc;
} mock_req_t;

typedef struct packed {
    logic [Cfg.ICACHE_INDEX_WIDTH-1:0] idx;
    logic [Cfg.ICACHE_SET_ASSOC_WIDTH-1:0] way;
    logic                           vld;
    logic                           all;
} mock_inv_t;

typedef struct packed {
    logic [3:0]                     rtype;
    mock_inv_t                      inv;
    logic [Cfg.ICACHE_LINE_WIDTH-1:0] data;
    logic [Cfg.ICACHE_USER_LINE_WIDTH-1:0] user;
} mock_rtrn_t;

module tb_icache;

  // ===========================================================================
  // 1. KHAI BAO TIN HIEU
  // ===========================================================================
  localparam CLK_PERIOD = 10;
  logic clk_i;
  logic rst_ni;
  logic flush_i;
  logic en_i;
  logic miss_o;
  
  mock_areq_i_t areq_i;
  mock_areq_o_t areq_o;
  mock_dreq_i_t dreq_i;
  mock_dreq_o_t dreq_o;

  logic         mem_rtrn_vld_i;
  mock_rtrn_t   mem_rtrn_i;
  logic         mem_data_req_o;
  logic         mem_data_ack_i;
  mock_req_t    mem_data_o;

  // ===========================================================================
  // 2. KHOI TAO DUT (DEVICE UNDER TEST)
  // ===========================================================================
  cva6_icache #(
    .CVA6Cfg        ( Cfg ),             
    .icache_areq_t  ( mock_areq_i_t ),
    .icache_arsp_t  ( mock_areq_o_t ),
    .icache_dreq_t  ( mock_dreq_i_t ),
    .icache_drsp_t  ( mock_dreq_o_t ),
    .icache_req_t   ( mock_req_t ),
    .icache_rtrn_t  ( mock_rtrn_t )
  ) dut (
    .clk_i          ( clk_i          ),
    .rst_ni         ( rst_ni         ),
    .flush_i        ( flush_i        ),
    .en_i           ( en_i           ),
    .miss_o         ( miss_o         ),
    .areq_i         ( areq_i         ),
    .areq_o         ( areq_o         ),
    .dreq_i         ( dreq_i         ),
    .dreq_o         ( dreq_o         ),
    .mem_rtrn_vld_i ( mem_rtrn_vld_i ),
    .mem_rtrn_i     ( mem_rtrn_i     ),
    .mem_data_req_o ( mem_data_req_o ),
    .mem_data_ack_i ( mem_data_ack_i ),
    .mem_data_o     ( mem_data_o     )
  );

  // ===========================================================================
  // 3. CLOCK & GIA LAP L2 CACHE/RAM
  // ===========================================================================
  initial begin
    clk_i = 0;
    forever #(CLK_PERIOD/2) clk_i = ~clk_i;
  end

  initial begin
    forever begin
      @(posedge clk_i);
      if (mem_data_req_o) begin
        mem_data_ack_i = 1; 
        @(posedge clk_i);
        mem_data_ack_i = 0;
        
        repeat(5) @(posedge clk_i); // Mo phong delay cua L2/RAM
        
        mem_rtrn_vld_i = 1;
        mem_rtrn_i.rtype = 3'b011; // ICACHE_IFILL_ACK
        // Ghep dia chi vao data de de nhin tren waveform
        mem_rtrn_i.data = {480'h0, mem_data_o.paddr}; 
        
        @(posedge clk_i);
        mem_rtrn_vld_i = 0;
      end
    end
  end

  // ===========================================================================
  // 4. TASK GUI YEU CAU (DA FIX LOI HANDSHAKE & DEADLOCK)
  // ===========================================================================
  task automatic send_vipt_req(input logic [31:0] addr, output logic is_miss);
    // 4.1 Phat yeu cau den Cache
    dreq_i.req = 1;
    dreq_i.vaddr = addr;
    areq_i.fetch_valid = 0;
    
    // QUAN TRONG: Doi Cache bao "ready" (khong bi ban Flush hay Miss)
    do begin
      @(posedge clk_i);
    end while (dreq_o.ready == 0);
    
    // Cache da vao state READ, ha req xuong
    dreq_i.req = 0;

    // 4.2 Tra ve dia chi vat ly (Mo phong ITLB tra ket qua vao Chu ky tiep theo)
    areq_i.fetch_valid = 1;
    areq_i.fetch_paddr = addr;
    @(posedge clk_i);
    areq_i.fetch_valid = 0;

    // 4.3 Doi Cache xu ly xong va tra ket qua (valid)
    wait(dreq_o.valid);
    is_miss = miss_o;
    
    if (miss_o) $display("  -> [MISS] Nap tu RAM: %h", dreq_o.data);
    else        $display("  -> [HIT]  Doc tu SRAM: %h", dreq_o.data);
    
    @(posedge clk_i); // Nghi 1 nhip giua cac transaction
  endtask

  // ===========================================================================
  // 5. KICH BAN MO PHONG (STIMULUS)
  // ===========================================================================
  logic test_miss;

  initial begin
    // Khoi tao gia tri ban dau
    areq_i = '0; dreq_i = '0; mem_rtrn_i = '0;
    mem_rtrn_vld_i = 0; mem_data_ack_i = 0;
    
    $display("==================================================");
    $display("[TB] BAT DAU CHAY MO PHONG L1 I-CACHE");
    $display("==================================================");

    // ----------------------------------------------------
    $display("\n[TC_01] KHOI DONG & FLUSH CACHE");
    rst_ni = 0; flush_i = 0; en_i = 0;
    repeat(5) @(posedge clk_i);
    rst_ni = 1;
    
    @(posedge clk_i);
    en_i = 1; flush_i = 1;
    @(posedge clk_i);
    flush_i = 0;
    
    // QUAN TRONG: Cho Cache thuc hien Flush hoan toan xong 
    // Thay vi `repeat(200)` mu quang, ta doi state machine chuyen ve IDLE
    $display("    -> Dang cho qua trinh Flush hoan tat (khoang 256 chu ky)...");
    wait(dreq_o.ready == 1'b1);
    $display("    -> Flush hoan tat! Cache da san sang.");
    repeat(5) @(posedge clk_i);
    
    // ----------------------------------------------------
    $display("\n[TC_02] VIPT & PLRU STRESS TEST (4-Way Associativity)");
    $display("Muc tieu: Doc 5 dia chi co CUNG INDEX nhung KHAC TAG.");
    
    $display("\n--- Buoc 1: Nap day 4 Way (Bat buoc phai MISS ca 4) ---");
    send_vipt_req(32'h0000_0000, test_miss); // Way 0
    send_vipt_req(32'h0000_1000, test_miss); // Way 1
    send_vipt_req(32'h0000_2000, test_miss); // Way 2
    send_vipt_req(32'h0000_3000, test_miss); // Way 3

    $display("\n--- Buoc 2: Nap dia chi thu 5 (Thrashing - Kich hoat PLRU) ---");
    send_vipt_req(32'h0000_4000, test_miss); // Ghi de len 1 Way

    $display("\n--- Buoc 3: Kiem tra cheo (Cross-check) ---");
    $display("Doc lai 0x0000 (Ky vong MISS - vi da bi PLRU day ra):");
    send_vipt_req(32'h0000_0000, test_miss); 

    $display("Doc lai 0x2000 (Ky vong HIT - vi van con trong Cache):");
    send_vipt_req(32'h0000_2000, test_miss); 

    repeat(20) @(posedge clk_i);
    $display("\n==================================================");
    $display("[TB] HOAN THANH MO PHONG!");
    $display("==================================================");
    $stop;
  end

endmodule