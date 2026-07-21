`timescale 1ns / 1ps

module tb_l1_cache_integration_logic();
  import cva6_config_pkg::*;
  import build_config_pkg::*;
  
  // ========================================================
  // CLOCK & RESET
  // ========================================================
  logic clk;
  logic rst_n;
  
  // ========================================================
  // CVA6 CONFIG
  // ========================================================
  localparam config_pkg::cva6_cfg_t CVA6Cfg = build_config_pkg::build_config(
      cva6_config_pkg::cva6_cfg
  );
  
  // ========================================================
  // RVFI PROBES
  // ========================================================
  wire [4195:0] rvfi_probes_o_signal;
  
  // ========================================================
  // AXI SIGNAL DECLARATIONS
  // ========================================================
  
  logic                            noc_ar_valid;
  logic [CVA6Cfg.AxiAddrWidth-1:0] noc_ar_addr;
  logic [CVA6Cfg.AxiIdWidth-1:0]   noc_ar_id;
  logic                            noc_ar_ready;
  
  logic                            noc_r_valid;
  logic [CVA6Cfg.AxiDataWidth-1:0] noc_r_data;
  logic [CVA6Cfg.AxiIdWidth-1:0]   noc_r_id;
  logic                            noc_r_ready;
  
  logic                            noc_aw_valid;
  logic [CVA6Cfg.AxiAddrWidth-1:0] noc_aw_addr;
  logic [CVA6Cfg.AxiIdWidth-1:0]   noc_aw_id;
  logic                            noc_aw_ready;
  
  logic                            noc_w_valid;
  logic [CVA6Cfg.AxiDataWidth-1:0] noc_w_data;
  logic [(CVA6Cfg.AxiDataWidth/8)-1:0] noc_w_strb;
  logic                            noc_w_ready;
  
  logic                            noc_b_valid;
  logic [CVA6Cfg.AxiIdWidth-1:0]   noc_b_id;
  logic                            noc_b_ready;
  
	// ======================================================== 
	// CVA6 INSTANTIATION 
	// ======================================================== 
	cva6 #( 
		.CVA6Cfg(CVA6Cfg) 
	) i_cva6 ( 
		.clk_i(clk), 
		.rst_ni(rst_n), 
		.boot_addr_i({{(CVA6Cfg.XLEN-32){1'b0}}, 32'h8000_0000}), 
		.hart_id_i(32'h0), 
		.irq_i(2'b0), 
		.ipi_i(1'b0), 
		.time_irq_i(1'b0), 
		.debug_req_i(1'b0), 
		.rvfi_probes_o(rvfi_probes_o_signal)
		// TUYỆT ĐỐI KHÔNG KHAI BÁO CỔNG MẠNG NOC Ở ĐÂY
	);

	// ========================================================
	// KHAI BÁO BIẾN CHO BURST AXI (BẮT BUỘC KHAI BÁO TRƯỚC)
	// ========================================================
	logic [7:0] read_len_latched; 
	logic [7:0] read_beat_count; 
	logic noc_r_last; 
	assign noc_r_last = (read_beat_count == read_len_latched);

	// ======================================================== 
	// NOC PORT MAPPING - TOP-LEVEL BOUNDARY ACCESS (100% SAFE)
	// ======================================================== 
	always_comb begin 
		// 1. READ REQUESTS (Lấy tín hiệu từ cổng chính thức của CVA6, không sợ sai đường dẫn)
		noc_ar_valid = i_cva6.noc_req_o.ar_valid; 
		noc_ar_addr  = i_cva6.noc_req_o.ar.addr; 
		noc_ar_id    = i_cva6.noc_req_o.ar.id; 
		noc_r_ready  = i_cva6.noc_req_o.r_ready;  

		// 2. WRITE REQUESTS 
		noc_aw_valid = i_cva6.noc_req_o.aw_valid;
		noc_aw_addr  = i_cva6.noc_req_o.aw.addr;
		noc_aw_id    = i_cva6.noc_req_o.aw.id;
		noc_w_valid  = i_cva6.noc_req_o.w_valid;
		noc_w_data   = i_cva6.noc_req_o.w.data;
		noc_w_strb   = i_cva6.noc_req_o.w.strb;
		noc_b_ready  = i_cva6.noc_req_o.b_ready;
	end

	initial begin 
		// 3. FORCE RESPONSES (Ép tín hiệu lệnh NOP từ Testbench thẳng vào cổng chính)
		// Cờ +acc=npr trong file do sẽ bảo vệ cổng này không bị cắt đứt.
		// CRITICAL FIX: Wrap in forever loop to track NOC signal changes continuously
		forever begin
			@(posedge clk) begin
				force i_cva6.noc_resp_i.ar_ready = noc_ar_ready; 
				force i_cva6.noc_resp_i.r_valid  = noc_r_valid; 
				force i_cva6.noc_resp_i.r.data   = noc_r_data; 
				force i_cva6.noc_resp_i.r.id     = noc_r_id; 
				force i_cva6.noc_resp_i.r.resp   = 2'b00; 
				force i_cva6.noc_resp_i.r.last   = noc_r_last;        

				force i_cva6.noc_resp_i.aw_ready = noc_aw_ready;
				force i_cva6.noc_resp_i.w_ready  = noc_w_ready;
				force i_cva6.noc_resp_i.b_valid  = noc_b_valid;
				force i_cva6.noc_resp_i.b.id     = noc_b_id;
				force i_cva6.noc_resp_i.b.resp   = 2'b00;
			end
		end
	end

	// ========================================================
	// AXI MEMORY SIMULATOR
	// ========================================================
	reg [31:0] boot_rom [0:255];
	reg [31:0] data_mem [0:1023];

	initial begin
		for (int i = 0; i < 256; i++) boot_rom[i] = 32'h0000_0013;
		for (int i = 0; i < 1024; i++) data_mem[i] = 32'h0000_0000;
	end

	// ========================================================
	// AXI READ CHANNEL (FRONTDOOR MEMORY SIMULATOR - BURST SUPPORT)
	// ========================================================
	logic read_pending;
	logic [1:0] read_delay_counter;
	logic [CVA6Cfg.AxiAddrWidth-1:0] read_addr_latched;
	logic [CVA6Cfg.AxiIdWidth-1:0]   read_id_latched;

	always @(posedge clk) begin
		if (rst_n == 1'b0) begin
			noc_ar_ready <= 1'b1;
			noc_r_valid <= 1'b0;
			read_pending <= 1'b0;
			read_delay_counter <= 2'b0;
			read_beat_count <= 8'b0;
		end else begin
			// Luôn sẵn sàng nhận yêu cầu mới nếu không bận
			noc_ar_ready <= !read_pending;

			// 1. Kết thúc 1 nhịp truyền dữ liệu (Beat Handshake)
			if (noc_r_valid && noc_r_ready) begin
				if (read_beat_count == read_len_latched) begin
					// Đã gửi xong toàn bộ gói Burst
					noc_r_valid <= 1'b0;
					read_pending <= 1'b0;
				end else begin
					// Chuyển sang nhịp tiếp theo (giữ nguyên r_valid = 1)
					read_beat_count <= read_beat_count + 1;
				end
			end
			// 2. Đếm lùi thời gian trễ cho nhịp ĐẦU TIÊN
			else if (read_pending && !noc_r_valid && read_delay_counter > 0) begin
				read_delay_counter <= read_delay_counter - 1;
			end
			// 3. Hết thời gian trễ -> Bắt đầu đẩy dữ liệu (nhịp đầu)
			else if (read_pending && !noc_r_valid && read_delay_counter == 0) begin
				noc_r_valid <= 1'b1;
				noc_r_id <= read_id_latched;
				noc_r_data <= {32'h0000_0013, 32'h0000_0013}; // Bơm lệnh NOP liên tục
			end

			// 4. Bắt yêu cầu đọc mới từ CPU
			if (noc_ar_valid && noc_ar_ready && !read_pending) begin
				read_pending <= 1'b1;
				read_delay_counter <= 2;
				read_addr_latched <= noc_ar_addr;
				read_id_latched <= noc_ar_id;
				read_len_latched <= i_cva6.noc_req_o.ar.len; // Trích xuất chiều dài Burst
				read_beat_count <= 8'b0;
			end
		end
	end
  
  // ========================================================
  // AXI WRITE CHANNEL
  // ========================================================
  
  assign noc_aw_ready = 1'b1;
  assign noc_w_ready = 1'b1;
  
  always @(posedge clk) begin
    if (rst_n == 1'b0) begin
      noc_b_valid <= 0;
    end else begin
      if (noc_aw_valid && noc_w_valid && !noc_b_valid) begin
        noc_b_valid <= 1;
        noc_b_id <= noc_aw_id;
      end else if (noc_b_valid && noc_b_ready) begin
        noc_b_valid <= 0;
      end
    end
  end
  
  // ========================================================
  // CLOCK GENERATION
  // ========================================================
  
  initial begin
    clk = 1'b0;
    forever #5 clk = ~clk;
  end
  
  // ========================================================
  // RESET SEQUENCE
  // ========================================================
  
  initial begin
    rst_n = 1'b0;
    repeat(10) @(posedge clk);
    rst_n = 1'b1;
    $display("[BOOT] Reset released");
  end
  
  // ========================================================
  // TEST HARNESS
  // ========================================================
  
  initial begin
    $display("\n================== CVA6 Integration Tests ==================");
    $display("5 TC-INT via NOC interface");
    $display("===========================================================\n");
    
    test_int_01();
    test_int_02();
    test_int_03();
    test_int_04();
    test_int_05();
    
    #1000;
    $finish;
  end
  
  // ========================================================
  // TC-INT-01: Boot + ALU (32 commits)
  // ========================================================
  
  task test_int_01();
    int commit_count, fail_count;
    logic commit_valid;
    logic [63:0] actual_pc, expected_pc;
    
    $display("\n[TC-INT-01] Boot + ALU Operations");
    $display("==================================");
    
    commit_count = 0;
    fail_count = 0;
    expected_pc = 64'h0000_0000_8000_0000;
    
    repeat(100) @(posedge clk);
    
    repeat(50) begin
      @(posedge clk);
      
      commit_valid = i_cva6.rvfi_probes_o.instr.commit_instr_valid[0];
      actual_pc = i_cva6.rvfi_probes_o.instr.commit_instr_pc[0];
      
      $display("[RVFI] commit_valid=%d, pc=0x%x", commit_valid, actual_pc);
      
      if (commit_valid) begin
        commit_count++;
        
        if (actual_pc != expected_pc) begin
          $display("[FAIL] PC mismatch: got 0x%x, expected 0x%x", actual_pc, expected_pc);
          fail_count++;
        end else begin
          $display("[PASS] PC[%2d] = 0x%x", commit_count, actual_pc);
        end
        
        expected_pc = expected_pc + 4;
      end
    end
    
    if (commit_count == 32 && fail_count == 0)
      $display("[PASS] TC-INT-01: 32/32 commits\n");
    else
      $display("[FAIL] TC-INT-01: %d/32 commits (failures: %d)\n", commit_count, fail_count);
  endtask
  
  task test_int_02();
    $display("\n[TC-INT-02] Load/Store Operations");
    $display("==================================");
    $display("[INFO] Placeholder - Phase 5.2\n");
  endtask
  
  task test_int_03();
    $display("\n[TC-INT-03] D-Cache Miss Stall");
    $display("===============================");
    $display("[INFO] Placeholder - Phase 5.3\n");
  endtask
  
  task test_int_04();
    $display("\n[TC-INT-04] RAW Hazard");
    $display("======================");
    $display("[INFO] Placeholder - Phase 5.2\n");
  endtask
  
  task test_int_05();
    $display("\n[TC-INT-05] Concurrent I+D Cache");
    $display("=================================");
    $display("[INFO] Placeholder - Phase 5.3\n");
  endtask
  
endmodule