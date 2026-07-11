`timescale 1ns/1ps

module tb_plru;
  
  // Thông số cấu hình dựa theo CVA6Cfg.ICACHE_SET_ASSOC
  localparam NUM_WAYS = 4;
  localparam WAY_WIDTH = $clog2(NUM_WAYS);

  // Tín hiệu giao tiếp DUT
  logic                 clk_i;
  logic                 rst_ni;
  logic                 flush_i;
  logic                 update_i;
  logic [WAY_WIDTH-1:0] access_way_i;
  logic [WAY_WIDTH-1:0] replace_way_o;

  // Khởi tạo DUT (Device Under Test) [cite: 510, 511]
  plru #(
    .NUM_WAYS (NUM_WAYS)
  ) i_plru (
    .clk_i         (clk_i),
    .rst_ni        (rst_ni),
    .flush_i       (flush_i),
    .update_i      (update_i),
    .access_way_i  (access_way_i),
    .replace_way_o (replace_way_o)
  );

  // Tạo Clock (1GHz -> Chu kỳ 1ns)
  initial begin
    clk_i = 0;
    forever #0.5 clk_i = ~clk_i;
  end

  // Task gửi stimulus (Đã tối ưu cho hiển thị Waveform)
  task automatic plru_access(input logic [WAY_WIDTH-1:0] way);
    @(negedge clk_i); // Đổi thành cạnh XUỐNG
    update_i     = 1'b1;
    access_way_i = way;
    @(negedge clk_i); // Đổi thành cạnh XUỐNG
    update_i     = 1'b0;
  endtask

  // Kịch bản kiểm thử (Test Sequences)
  initial begin
    // 1. Reset hệ thống
    rst_ni       = 1'b0;
    flush_i      = 1'b0;
    update_i     = 1'b0;
    access_way_i = '0;
    #5.2;
    rst_ni       = 1'b1;
    
    $display("=== STARTING PLRU VERIFICATION ===");
    
    // 2. Kịch bản Miss & Fill toàn bộ các Way (0 -> 1 -> 2 -> 3)
    // Sau khi fill xong, PLRU phải chỉ về Way 0
    $display("Test 1: Sequential Fill");
    plru_access(2'd0);
    plru_access(2'd1);
    plru_access(2'd2);
    plru_access(2'd3);
    
    @(posedge clk_i);
    if (replace_way_o !== 2'd0) 
      $error("Mismatch Test 1! Expected: 0, Got: %0d", replace_way_o);
    else 
      $display("Test 1 PASS.");

    // 3. Kịch bản Hit trên Way 0 và 2
    // MRU hiện tại là 0 và 2, PLRU phải chỉ vào nhánh còn lại (Way 1)
    $display("Test 2: Access specific ways (0 then 2)");
    plru_access(2'd0);
    plru_access(2'd2);
    
    @(posedge clk_i);
    if (replace_way_o !== 2'd1) 
      $error("Mismatch Test 2! Expected: 1, Got: %0d", replace_way_o);
    else 
      $display("Test 2 PASS.");

    // 4. Kịch bản Flush
    // Mọi trạng thái Tree-PLRU bị reset
    $display("Test 3: Hardware Flush");
    @(posedge clk_i);
    flush_i = 1'b1;
    @(posedge clk_i);
    flush_i = 1'b0;
    
    @(posedge clk_i);
    $display("After Flush, Replacement Way points to: %0d", replace_way_o);

    // 5. Kết thúc
    #10;
    $display("=== PLRU VERIFICATION COMPLETED ===");
    $finish;
  end

  // SystemVerilog Assertions (SVA)
  // Đảm bảo không bao giờ PLRU gợi ý replace way vừa mới được access (MRU)
  property p_mru_not_replaced;
    @(posedge clk_i) disable iff (!rst_ni || flush_i)
      (update_i) |=> (replace_way_o != $past(access_way_i));
  endproperty
  assert property (p_mru_not_replaced) else $error("SVA VIOLATION: PLRU indicated replacement of the MRU way!");

endmodule