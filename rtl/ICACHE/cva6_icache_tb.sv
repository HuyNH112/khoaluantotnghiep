`timescale 1ns/1ps

module cva6_icache_tb;

  // Import các package cần thiết của CVA6
  import ariane_pkg::*;
  import wt_cache_pkg::*;

  // Parameters
  localparam CLK_PERIOD = 10;
  
  // Tín hiệu Clock và Reset
  logic clk;
  logic rst_n;
  
  // Tín hiệu kết nối DUT
  logic         flush;
  logic         en;
  logic         miss;
  icache_areq_t areq_i;
  icache_arsp_t areq_o;
  icache_dreq_t dreq_i;
  icache_drsp_t dreq_o;
  
  logic         mem_rtrn_vld;
  icache_rtrn_t mem_rtrn;
  logic         mem_data_req;
  logic         mem_data_ack;
  icache_req_t  mem_data_o;

  // 1. Khởi tạo DUT (Device Under Test)
  cva6_icache #(
    .CVA6Cfg        ( config_pkg::cva6_cfg_empty ), // Sử dụng config mặc định
    .icache_areq_t  ( icache_areq_t ),
    .icache_arsp_t  ( icache_arsp_t ),
    .icache_dreq_t  ( icache_dreq_t ),
    .icache_drsp_t  ( icache_drsp_t ),
    .icache_req_t   ( icache_req_t  ),
    .icache_rtrn_t  ( icache_rtrn_t )
  ) dut (
    .clk_i          ( clk          ),
    .rst_ni         ( rst_n        ),
    .flush_i        ( flush        ),
    .en_i           ( en           ),
    .miss_o         ( miss         ),
    .areq_i         ( areq_i       ),
    .areq_o         ( areq_o       ),
    .dreq_i         ( dreq_i       ),
    .dreq_o         ( dreq_o       ),
    .mem_rtrn_vld_i ( mem_rtrn_vld ),
    .mem_rtrn_i     ( mem_rtrn     ),
    .mem_data_req_o ( mem_data_req ),
    .mem_data_ack_i ( mem_data_ack ),
    .mem_data_o     ( mem_data_o   )
  );

  // 2. Tạo xung Clock
  initial begin
    clk = 0;
    forever #(CLK_PERIOD/2) clk = ~clk;
  end

  // 3. Logic mô phỏng Bộ nhớ (Memory Model)
  initial begin
    mem_rtrn_vld = 0;
    mem_data_ack = 0;
    mem_rtrn = '0;
    
    forever begin
      @(posedge clk);
      if (mem_data_req) begin
        // Giả lập độ trễ bộ nhớ là 5 chu kỳ
        mem_data_ack = 1; 
        repeat(5) @(posedge clk);
        mem_data_ack = 0;
        
        // Trả về dữ liệu (Refill)
        mem_rtrn_vld = 1;
        mem_rtrn.rtype = ICACHE_IFILL_ACK;
        mem_rtrn.data = 512'hDEADBEEF_CAFEDODE_12345678_...; // Dữ liệu mẫu 64B
        @(posedge clk);
        mem_rtrn_vld = 0;
      end
    end
  end

  // 4. Chương trình kiểm thử chính (Test Program)
  initial begin
    // Reset hệ thống
    rst_n = 0;
    flush = 0;
    en = 0;
    dreq_i = '0;
    areq_i = '0;
    repeat(5) @(posedge clk);
    rst_n = 1;
    
    // Bước 1: Enable Cache
    @(posedge clk);
    en = 1;
    repeat(100) @(posedge clk); // Chờ Flush trạng thái ban đầu hoàn tất

    // Bước 2: Request Cold Miss
    $display("[TB] Requesting address 0x1000 (Cold Miss)");
    dreq_i.req = 1;
    dreq_i.vaddr = 32'h0000_1000;
    
    // Giả lập ITLB dịch địa chỉ ngay lập tức
    wait(areq_o.fetch_req);
    areq_i.fetch_valid = 1;
    areq_i.fetch_paddr = 32'h0000_1000;
    
    @(posedge clk);
    dreq_i.req = 0;
    
    // Đợi cho đến khi Cache xử lý xong Refill
    wait(dreq_o.valid);
    $display("[TB] Data received from memory: %h", dreq_o.data);

    // Bước 3: Request Cache Hit (Đọc lại địa chỉ cũ)
    repeat(5) @(posedge clk);
    $display("[TB] Requesting address 0x1000 again (Expected Hit)");
    dreq_i.req = 1;
    dreq_i.vaddr = 32'h0000_1000;
    
    @(posedge clk);
    if (dreq_o.valid && !miss) 
      $display("[TB] SUCCESS: Cache Hit detected!");
    else
      $display("[TB] ERROR: Cache Miss on previously filled data!");
    
    dreq_i.req = 0;

    // Bước 4: Test Flush
    $display("[TB] Asserting Flush");
    flush = 1;
    @(posedge clk);
    flush = 0;
    repeat(100) @(posedge clk);

    $display("[TB] Requesting address 0x1000 after Flush (Expected Miss)");
    dreq_i.req = 1;
    @(posedge clk);
    // Kiểm tra miss ở đây...

    repeat(10) @(posedge clk);
    $display("[TB] Test Completed.");
    $finish;
  end

endmodule