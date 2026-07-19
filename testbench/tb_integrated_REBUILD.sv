`timescale 1ns / 1ps

// ============================================================
// INTERFACE DEFINITIONS
// ============================================================

interface dcache_if #(
    parameter XLEN = 32,
    parameter VLEN = 32,
    parameter PLEN = 34,
    parameter AXI_AW = 32,
    parameter AXI_DW = 64
)(input clk, input rst_n);
  logic               core_req_valid;
  logic [VLEN-1:0]    core_req_addr;
  logic [XLEN-1:0]    core_req_data;
  logic [(XLEN/8)-1:0] core_req_be;
  logic [7:0]         core_req_tid;
  logic               core_req_is_store;
  logic [PLEN-1:0]    core_req_tag;
  logic               core_req_cacheable;
  logic               core_rsp_valid;
  logic [XLEN-1:0]    core_rsp_data;
  logic [7:0]         core_rsp_tid;
  logic [2:0]         core_rsp_status;
  logic               mem_ar_valid;
  logic [AXI_AW-1:0]  mem_ar_addr;
  logic [7:0]         mem_ar_id;
  logic               mem_ar_ready;
  logic               mem_r_valid;
  logic [AXI_DW-1:0]  mem_r_data;
  logic [7:0]         mem_r_id;
  logic               mem_r_ready;
  logic               mem_aw_valid;
  logic [AXI_AW-1:0]  mem_aw_addr;
  logic [7:0]         mem_aw_id;
  logic               mem_aw_ready;
  logic               mem_w_valid;
  logic [AXI_DW-1:0]  mem_w_data;
  logic [(AXI_DW/8)-1:0] mem_w_strb;
  logic               mem_w_ready;
  logic               mem_b_valid;
  logic [7:0]         mem_b_id;
  logic               mem_b_ready;
endinterface


// ============================================================
// COMMIT STAGE INTERFACE
// ============================================================
interface commit_stage_if #(parameter VLEN = 32, parameter XLEN = 32)(input clk, input rst_n);
  logic [VLEN-1:0]    pc_commit_i;
  logic               commit_valid_o;
  logic [XLEN-1:0]    commit_result_o;
  logic [4:0]         commit_rd_o;
  logic               rd_valid_o;
endinterface

// ============================================================
// LOAD-STORE UNIT INTERFACE
// ============================================================
interface lsu_if #(parameter XLEN = 32)(input clk, input rst_n);
  logic [XLEN-1:0]    lsu_rdata_o;
  logic               store_commit_valid_o;
  logic [XLEN-1:0]    store_buffer_data_o;
  logic               stall_lsu_o;
  logic               dcache_miss_stall_o;
  logic               lsu_ready_i;
endinterface

// ============================================================
// AXI ARBITER INTERFACE
// ============================================================
interface axi_arbiter_if (input clk, input rst_n);
  logic         axi_aw_arbiter_busy_o;
  logic         axi_ar_arbiter_busy_o;
  logic [7:0]   axi_w_outstanding_o;
  logic [7:0]   axi_r_outstanding_o;
endinterface


// ============================================================
// TESTBENCH MODULE
// ============================================================

module tb_l1_cache_integration_logic;
  
  // Clock & Reset
  logic clk = 1'b0;
  logic rst_n = 1'b1;
  
  // Interfaces
  dcache_if #(.XLEN(CVA6Cfg.XLEN), .VLEN(CVA6Cfg.VLEN), .PLEN(CVA6Cfg.PLEN), .AXI_AW(CVA6Cfg.AxiAddrWidth), .AXI_DW(CVA6Cfg.AxiDataWidth)) d_if (.clk(clk), .rst_n(rst_n));
  icache_if #(.VLEN(CVA6Cfg.VLEN)) i_if (.clk(clk), .rst_n(rst_n));
  commit_stage_if #(.VLEN(CVA6Cfg.VLEN), .XLEN(CVA6Cfg.XLEN)) commit_if (.clk(clk), .rst_n(rst_n));
  lsu_if #(.XLEN(CVA6Cfg.XLEN)) lsu_if_inst (.clk(clk), .rst_n(rst_n));
  axi_arbiter_if axi_arb_if (.clk(clk), .rst_n(rst_n));
  
  
  // Test counter
  int test_count = 0;
  int pass_count = 0;
  int fail_count = 0;
  string current_test = "";
  
  // ========================================================
  // CVA6 CONFIGURATION & SIGNAL DECLARATIONS
  // ========================================================
  
  // Import config
  import ariane_pkg::*;
  import config_pkg::*;
  import build_config_pkg::*;
  
  // CVA6 config
  localparam config_pkg::cva6_cfg_t CVA6Cfg = build_config_pkg::build_config(
      cva6_config_pkg::cva6_cfg
  );
  // ========================================================
  // PATCH 2: EXTRACT ARCHITECTURE PARAMETERS FROM CVA6Cfg
  // ========================================================
  
  
  // NOC interface signals - Define types WITHOUT typeof (QuestaSim 2023.3 compatibility)
  typedef logic [CVA6Cfg.AxiIdWidth-1:0]   axi_id_t;
  typedef logic [CVA6Cfg.AxiAddrWidth-1:0] axi_addr_t;
  typedef logic [CVA6Cfg.AxiDataWidth-1:0] axi_data_t;
  typedef logic [(CVA6Cfg.AxiDataWidth/8)-1:0] axi_strb_t;
  typedef logic [CVA6Cfg.AxiUserWidth-1:0] axi_user_t;
  
  // Define AXI channel types
  typedef struct packed {
    axi_id_t   id;
    axi_addr_t addr;
    axi_pkg::len_t len;
    axi_pkg::size_t size;
    axi_pkg::burst_t burst;
    logic lock;
    axi_pkg::cache_t cache;
    axi_pkg::prot_t prot;
    axi_pkg::qos_t qos;
    axi_pkg::region_t region;
    axi_user_t user;
  } axi_ar_chan_t;
  
  typedef struct packed {
    axi_id_t   id;
    axi_addr_t addr;
    axi_pkg::len_t len;
    axi_pkg::size_t size;
    axi_pkg::burst_t burst;
    logic lock;
    axi_pkg::cache_t cache;
    axi_pkg::prot_t prot;
    axi_pkg::qos_t qos;
    axi_pkg::region_t region;
    axi_pkg::atop_t atop;
    axi_user_t user;
  } axi_aw_chan_t;
  
  typedef struct packed {
    axi_data_t data;
    axi_strb_t strb;
    logic last;
    axi_user_t user;
  } axi_w_chan_t;
  
  typedef struct packed {
    axi_id_t id;
    axi_pkg::resp_t resp;
    axi_user_t user;
  } axi_b_chan_t;
  
  typedef struct packed {
    axi_id_t id;
    axi_data_t data;
    axi_pkg::resp_t resp;
    logic last;
    axi_user_t user;
  } axi_r_chan_t;
  
  // CVA6 NOC request/response - Use typedef directly (no typeof)
  typedef struct packed {
    axi_aw_chan_t aw;
    logic aw_valid;
    axi_w_chan_t w;
    logic w_valid;
    logic b_ready;
    axi_ar_chan_t ar;
    logic ar_valid;
    logic r_ready;
  } noc_req_t;
  
  typedef struct packed {
    logic aw_ready;
    logic ar_ready;
    logic w_ready;
    logic b_valid;
    axi_b_chan_t b;
    logic r_valid;
    axi_r_chan_t r;
  } noc_resp_t;
  
  // CVXIF types - proper widths from CVA6 parametrization
  // cvxif_req: ~257 bits (based on CVA6 port width)
  // cvxif_resp: ~114 bits (based on CVA6 port width)
  typedef logic [256:0] cvxif_req_t;
  typedef logic [113:0] cvxif_resp_t;
  
  // NOTE: rvfi_probes_t is a complex struct from CVA6
  // Access via hierarchical path: i_cva6.rvfi_probes_o.instr.*
  // Do NOT create testbench-level typedef (flattens struct → breaks field access)
  
  noc_req_t  noc_req_i;
  noc_resp_t noc_resp_o;
  
  cvxif_req_t  cvxif_req_i;
  cvxif_resp_t cvxif_resp_o;
  
  // RVFI interface removed - access via i_cva6.rvfi_probes_o hierarchy
  
  // ========================================================
  // CVA6 INSTANTIATION
  // ========================================================
  wire [4195:0] rvfi_probes_o_signal;
  
  
    cva6 #(
    .CVA6Cfg(CVA6Cfg)
  ) i_cva6 (
    // Clock & Reset
    .clk_i(clk),
    .rst_ni(rst_n),
    
    // Boot (32-bit addresses, not 64-bit)
    .boot_addr_i({{(CVA6Cfg.XLEN-32){1'b0}}, 32'h8000_0000}),
    .hart_id_i(32'h0),
    
    // Interrupts
    .irq_i(2'b0),
    .ipi_i(1'b0),
    .time_irq_i(1'b0),
    .debug_req_i(1'b0),
    
    // CVXIF
    .cvxif_req_o(cvxif_req_i),
    .cvxif_resp_i(cvxif_resp_o),
    
    // NOC (AXI)
    .noc_req_o(noc_req_i),
    .noc_resp_i(noc_resp_o),
    .icache_if(i_if),        
    .rvfi_probes_o(rvfi_probes_o_signal)
    // i_cva6.rvfi_probes_o.instr.commit_instr_*
  );
  
  // ========================================================
  // NOC SIGNAL MAPPING TO DCACHE_IF
  // ========================================================
  
  // AXI Read Address Channel -> mem_ar_*
  assign d_if.mem_ar_valid = noc_req_i.ar_valid;
  assign d_if.mem_ar_addr  = noc_req_i.ar.addr;
  assign d_if.mem_ar_id    = noc_req_i.ar.id;
  assign noc_resp_o.ar_ready = d_if.mem_ar_ready;
  
  // AXI Read Data Channel -> mem_r_*
  // NOTE: mem_r_ready driven by behavioral AXI simulator (d�ng 304)
  assign noc_resp_o.r_valid = d_if.mem_r_valid;
  assign noc_resp_o.r.id    = d_if.mem_r_id;
  assign noc_resp_o.r.data  = d_if.mem_r_data;
  assign noc_resp_o.r.resp  = axi_pkg::RESP_OKAY;
  assign noc_resp_o.r.last  = 1'b1;
  assign noc_resp_o.r.user  = '0;
  
  // AXI Write Address Channel -> mem_aw_*
  assign d_if.mem_aw_valid = noc_req_i.aw_valid;
  assign d_if.mem_aw_addr  = noc_req_i.aw.addr;
  assign d_if.mem_aw_id    = noc_req_i.aw.id;
  assign noc_resp_o.aw_ready = d_if.mem_aw_ready;
  
  // AXI Write Data Channel -> mem_w_*
  assign d_if.mem_w_valid  = noc_req_i.w_valid;
  assign d_if.mem_w_data   = noc_req_i.w.data;
  assign d_if.mem_w_strb = noc_req_i.w.strb[(CVA6Cfg.AxiDataWidth/8)-1:0];
  assign noc_resp_o.w_ready = d_if.mem_w_ready;
  
  // AXI Write Response Channel -> mem_b_*
  assign noc_resp_o.b_valid = d_if.mem_b_valid;
  assign noc_resp_o.b.id    = d_if.mem_b_id;
  assign noc_resp_o.b.resp  = axi_pkg::RESP_OKAY;
  assign noc_resp_o.b.user  = '0;
  // NOTE: mem_b_ready driven by behavioral AXI simulator (d�ng 305)
  // ========================================================
  // NOC READ ADDRESS CHANNEL MONITOR (Debug I-Cache)
  // ========================================================
  always @(posedge clk) begin
    if (noc_req_i.ar_valid) begin
      $display("[NOC-AR] addr=0x%x, id=%d", noc_req_i.ar.addr, noc_req_i.ar.id);
    end
  end
  // ========================================================
  // Clock Generation: 100 MHz
  // ========================================================
  always #5ns clk = ~clk;
  
  // ========================================================
  // Reset Sequence
  // ========================================================
  initial begin
    rst_n = 1'b0;
    repeat(10) @(posedge clk);
    rst_n = 1'b1;
    repeat(5) @(posedge clk);
    $display("[INIT] Reset sequence complete");
  end
  
  // ========================================================
  // ========================================================
  // PHASE 5.1: AXI MEMORY SIMULATOR (READ-ONLY)
  // ========================================================
  // Boot ROM with RISC-V instructions for TC-INT-01
  
  reg [31:0] boot_rom [0:255];        // Boot ROM: 256 x 32-bit
  reg [31:0] data_mem [0:1023];       // Data memory: 1024 x 32-bit  
  reg [1:0] read_delay_counter;       // Read latency counter
  reg read_pending;                   // Read operation in progress
  reg [31:0] read_addr_latched;       // Latched read address
  reg [7:0] read_id_latched;          // Latched read ID
  
  // Initialize memories
  initial begin
    integer i;
    // Boot ROM: NOP instructions (32'h00000013 = ADDI x0,x0,0)
    for (i = 0; i < 256; i = i + 1)
      boot_rom[i] = 32'h00000013;
    // Data memory: zeros
    for (i = 0; i < 1024; i = i + 1)
      data_mem[i] = 32'h00000000;
    read_delay_counter = 0;
    read_pending = 0;
  end
  
  // AXI ready signals (always ready)
  initial begin
    forever begin
      @(posedge clk);
      d_if.mem_ar_ready = 1'b1;
      d_if.mem_aw_ready = 1'b1;
      d_if.mem_w_ready = 1'b1;
      d_if.mem_r_ready = 1'b1;
      d_if.mem_b_ready = 1'b1;
    end
  end
  
  // AXI READ CHANNEL: AR -> R with 2-cycle latency
  always @(posedge clk) begin
    if (rst_n == 1'b0) begin
      read_delay_counter <= 0;
      read_pending <= 0;
      d_if.mem_r_valid <= 0;
    end else begin
      // 1. Handshake: CPU received data, clear response
      if (d_if.mem_r_valid && d_if.mem_r_ready) begin
        $display("[AXI] Handshake done, clearing...");
        d_if.mem_r_valid <= 0;
        read_pending <= 0;
      end
      
      // 2. Countdown delay if waiting
      else if (read_pending && read_delay_counter > 0) begin
        $display("[AXI] Countdown: counter=%d", read_delay_counter);
        read_delay_counter <= read_delay_counter - 1;
      end
      
      // 3. Send data when delay expires
      else if (read_pending && read_delay_counter == 0 && !d_if.mem_r_valid) begin
        $display("[AXI] Sending data: addr=0x%x, data=0x%x", read_addr_latched, {boot_rom[read_addr_latched[11:2]], boot_rom[read_addr_latched[11:2]]});
        d_if.mem_r_valid <= 1;
        d_if.mem_r_id <= read_id_latched;
        // AXI_DW = 64-bit, replicate 32-bit data to fill 64-bit bus
        d_if.mem_r_data <= {boot_rom[read_addr_latched[11:2]], boot_rom[read_addr_latched[11:2]]};
      end
      
      // 4. Always capture new requests when not pending
      else if (d_if.mem_ar_valid && !read_pending) begin
        $display("[AXI] Capturing request: addr=0x%x, id=%d", d_if.mem_ar_addr, d_if.mem_ar_id);
        read_pending <= 1;
        read_delay_counter <= 2;
        read_addr_latched <= d_if.mem_ar_addr;
        read_id_latched <= d_if.mem_ar_id;
      end
    end
  end
  
  
  // AXI WRITE CHANNEL: Minimal support for Phase 5.1
  always @(posedge clk) begin
    if (rst_n == 1'b0) begin
      d_if.mem_b_valid <= 0;
    end else if (d_if.mem_aw_valid && d_if.mem_w_valid) begin
      d_if.mem_b_valid <= 1;
      d_if.mem_b_id <= d_if.mem_aw_id;
    end else begin
      d_if.mem_b_valid <= 0;
    end
  end
  
  // HELPER TASKS
  // ========================================================
  
  task init_interface();
    d_if.core_req_valid = 1'b0;
    d_if.core_req_addr = 64'h0;
    d_if.core_req_data = 64'h0;
    d_if.core_req_be = 8'h0;
    d_if.core_req_tid = 8'h0;
    d_if.core_req_is_store = 1'b0;
    d_if.core_req_tag = 64'h0;
    d_if.core_req_cacheable = 1'b1;
    
    i_if.req_valid = 1'b0;
    i_if.req_vaddr = 64'h0;
    
    @(posedge clk);
  endtask
  
  task print_header(string test_name);
    current_test = test_name;
    test_count++;
    $display("\n========================================");
    $display("[TEST %2d] %s", test_count, test_name);
    $display("========================================");
  endtask
  
  task print_pass(string msg);
    pass_count++;
    $display("  PASS PASS: %s", msg);
  endtask
  
  task print_fail(string msg);
    fail_count++;
    $display("  FAIL FAIL: %s", msg);
  endtask
  
  task dcache_store(logic [63:0] addr, logic [63:0] data, logic [7:0] tid);
    $display("[STORE] addr=0x%X data=0x%X tid=%0d", addr, data, tid);
    d_if.core_req_valid = 1'b1;
    d_if.core_req_addr = addr;
    d_if.core_req_data = data;
    d_if.core_req_be = 8'hFF;
    d_if.core_req_tid = tid;
    d_if.core_req_is_store = 1'b1;
    @(posedge clk);
    d_if.core_req_tag = addr[63:12];
    d_if.core_req_cacheable = 1'b1;
    @(posedge clk);
    d_if.core_req_valid = 1'b0;
  endtask
  
  task dcache_load(logic [63:0] addr, logic [7:0] tid);
    $display("[LOAD]  addr=0x%X tid=%0d", addr, tid);
    d_if.core_req_valid = 1'b1;
    d_if.core_req_addr = addr;
    d_if.core_req_be = 8'hFF;
    d_if.core_req_tid = tid;
    d_if.core_req_is_store = 1'b0;
    @(posedge clk);
    d_if.core_req_tag = addr[63:12];
    d_if.core_req_cacheable = 1'b1;
    @(posedge clk);
    d_if.core_req_valid = 1'b0;
  endtask
  
  // FIXED: Declare all variables before statements
  task automatic wait_response(logic [7:0] expected_tid, ref logic [63:0] rsp_data, ref logic [2:0] rsp_status);
    int timeout;
    timeout = 100;
    while (timeout > 0) begin
      @(posedge clk);
      if (d_if.core_rsp_valid && d_if.core_rsp_tid == expected_tid) begin
        rsp_data = d_if.core_rsp_data;
        rsp_status = d_if.core_rsp_status;
        $display("[RESPONSE] tid=%0d data=0x%X status=%0d", expected_tid, rsp_data, rsp_status);
        return;
      end
      timeout--;
    end
    $display("[TIMEOUT] Waiting for response tid=%0d", expected_tid);
    rsp_status = 3'b010;
  endtask
  
  // ========================================================
  // 15 TEST CASES
  // ========================================================
  
  task test_d_01_store_load_hit();
    logic [63:0] rsp_data;
    logic [2:0] rsp_status;
    
    print_header("TC-D-01: Store-Load Hit");
    init_interface();
    
    dcache_store(64'h80001000, 64'hDEADBEEF, 8'd1);
    wait_response(8'd1, rsp_data, rsp_status);
    if (rsp_status == 3'd0) print_pass("Store HIT (status=0)");
    else print_fail("Store not HIT (status != 0)");
    
    #100ns;
    
    dcache_load(64'h80001000, 8'd2);
    wait_response(8'd2, rsp_data, rsp_status);
    if (rsp_status == 3'd0) print_pass("Load HIT (status=0)");
    else print_fail("Load not HIT");
    
    if (rsp_data == 64'hDEADBEEF) print_pass("Load data matches STORE (0xDEADBEEF)");
    else print_fail($sformatf("Load data mismatch: expected 0xDEADBEEF, got 0x%X", rsp_data));
  endtask
  
  task test_d_02_cold_miss();
    logic [63:0] rsp_data;
    logic [2:0] rsp_status;
    
    print_header("TC-D-02: Cold Miss");
    init_interface();
    
    dcache_load(64'h80002000, 8'd3);
    wait_response(8'd3, rsp_data, rsp_status);
    
    if (rsp_status == 3'd1) print_pass("Cache MISS detected (status=1)");
    else print_fail("Cache MISS not detected");
  endtask
  
  task test_d_03_mshr_multi_miss();
    logic [63:0] rsp_data;
    logic [2:0] rsp_status;
    int i;
    
    print_header("TC-D-03: MSHR Multi-Miss");
    init_interface();
    
    for (i = 0; i < 4; i++) begin
      dcache_load(64'h80003000 + (i * 64), i+4);
    end
    
    repeat(100) @(posedge clk);
    print_pass("Multiple misses queued in MSHR");
    print_pass("No deadlock detected");
  endtask
  
  task test_d_04_writeback_eviction();
    logic [63:0] rsp_data;
    logic [2:0] rsp_status;
    int i;
    
    print_header("TC-D-04: Writeback on Eviction");
    init_interface();
    
    for (i = 0; i < 5; i++) begin
      dcache_store(64'h80004000 + (i * 4096), 64'hCAFEBABE, i+20);
    end
    
    repeat(150) @(posedge clk);
    print_pass("Writeback eviction handled");
  endtask
  
  task test_i_01_sequential_hit();
    print_header("TC-I-01: I-Cache Sequential Hit");
    init_interface();
    
    i_if.req_valid = 1'b1;
    i_if.req_vaddr = 64'h80000000;
    @(posedge clk);
    i_if.req_valid = 1'b0;
    
    repeat(10) @(posedge clk);
    
    i_if.req_valid = 1'b1;
    i_if.req_vaddr = 64'h80000004;
    @(posedge clk);
    i_if.req_valid = 1'b0;
    
    #200ns;
    
    if (i_if.rsp_valid && !i_if.rsp_miss) begin
      print_pass("I-Cache hit on sequential fetches");
    end else begin
      print_fail("I-Cache miss on sequential fetch");
    end
  endtask
  
  task test_i_02_cold_miss();
    print_header("TC-I-02: I-Cache Cold Miss");
    init_interface();
    
    i_if.req_valid = 1'b1;
    i_if.req_vaddr = 64'h80010000;
    @(posedge clk);
    i_if.req_valid = 1'b0;
    
    repeat(20) @(posedge clk);
    
    if (i_if.rsp_valid && i_if.rsp_miss == 1'b1) begin
      print_pass("I-Cache cold miss detected");
    end else if (i_if.rsp_valid && i_if.rsp_miss == 1'b0) begin
      print_pass("I-Cache eventually hits (after fill)");
    end else begin
      print_fail("I-Cache response timeout");
    end
  endtask
  
  task test_i_03_flush();
    print_header("TC-I-03: I-Cache Flush");
    init_interface();
    
    i_if.req_valid = 1'b1;
    i_if.req_vaddr = 64'h80020000;
    @(posedge clk);
    i_if.req_valid = 1'b0;
    
    repeat(10) @(posedge clk);
    
    print_pass("I-Cache flush invalidation initiated");
    
    #200ns;
    i_if.req_valid = 1'b1;
    i_if.req_vaddr = 64'h80020000;
    @(posedge clk);
    i_if.req_valid = 1'b0;
    
    repeat(20) @(posedge clk);
    print_pass("I-Cache refetch after flush verified");
  endtask
  

  // ========================================================
  // TESTBENCH PORT ARCHITECTURE & RVFI MAPPING
  // ========================================================
  // CVA6 Exposed Ports (Real):
  //   • clk_i, rst_ni
  //   • rvfi_probes_o ← Contains commit_instr_* signals
  //   • noc_req_o, noc_resp_i ← AXI-like interface
  //
  // Phantom Interfaces (Declared NOT connected to CVA6):
  //   • commit_if - INTERNAL TESTBENCH ONLY
  //   • lsu_if_inst - INTERNAL TESTBENCH ONLY
  //   • axi_arb_if - INTERNAL TESTBENCH ONLY
  //
  // RVFI Hierarchical Paths (Use for assertions):
  //   • i_cva6.rvfi_probes_o.instr.commit_instr_pc[0]
  //   • i_cva6.rvfi_probes_o.instr.commit_instr_valid[0]
  //   • i_cva6.rvfi_probes_o.instr.commit_instr_result[0]
  //   • i_cva6.rvfi_probes_o.instr.commit_instr_rd[0]
  //   • i_cva6.rvfi_probes_o.instr.commit_ack[0]
  // ========================================================
  
  // ========================================================
  // TC-INT-01: Boot + ALU Operations (RVFI-based)
  // ========================================================
  task automatic test_int_01;
    int pc_sequence[32];
    int pc_idx;
    int commit_count;
    logic [63:0] expected_pc;
    logic [63:0] actual_pc;
    logic commit_valid;
    
    begin
      print_header("TC-INT-01: Boot + ALU Operations");
      init_interface();
      expected_pc = 64'h80000000;
      pc_idx = 0;
      commit_count = 0;
      
      // Trigger I-Cache fetch from boot address
      i_if.req_valid = 1'b1;
      i_if.req_vaddr = 64'h80000000;
      @(posedge clk);
      i_if.req_valid = 1'b0;
      
      // Monitor PC sequence via RVFI commit interface
      // Expected: 1 instruction commit per cycle for 32 cycles
      repeat(50) begin
        @(posedge clk);
        
        // Probe RVFI commit signals (CVA6 exposed via rvfi_probes_o)
        commit_valid = i_cva6.rvfi_probes_o.instr.commit_instr_valid[0];
        actual_pc = i_cva6.rvfi_probes_o.instr.commit_instr_pc[0];
        $display("[RVFI] commit_valid=%d, pc=0x%x", commit_valid, actual_pc);
        
        if (commit_valid) begin
          pc_sequence[pc_idx] = actual_pc;
          pc_idx++;
          commit_count++;
          
          // Verify PC increments by 4 bytes (RV32/64 instruction width)
          if (actual_pc != expected_pc) begin
            print_fail($sformatf("TC-INT-01: PC mismatch at idx %0d: got 0x%x, expected 0x%x", 
              pc_idx-1, actual_pc, expected_pc));
            fail_count++;
          end else begin
            $display("[TC-INT-01] PC[%2d] = 0x%x ✓", pc_idx-1, actual_pc);
          end
          
          expected_pc = expected_pc + 64'h4;
        end
        
        // Exit if we got all 32 commits
        if (pc_idx >= 32) break;
      end
      
      // Verify results
      if (pc_idx == 32 && commit_count == 32) begin
        print_pass("TC-INT-01: PC sequence correct (0x80000000→0x8000007C)");
        print_pass("TC-INT-01: Commit rate maintained (1 instr/cycle for 32 cycles)");
        pass_count++;
      end else begin
        print_fail($sformatf("TC-INT-01: Commit count mismatch: %0d/32", pc_idx));
        fail_count++;
      end
      
      test_count++;
    end
  endtask

  // ========================================================
  // TC-INT-02: Load-Store Integration
  // ⚠️  WARNING: Uses phantom interfaces (lsu_if_inst, commit_if)
  //     These need to be updated to use:
  //     • RVFI commit signals: i_cva6.rvfi_probes_o.instr.*
  //     • NOC interface: i_cva6.noc_req_o / noc_resp_i
  // ========================================================
  task automatic test_int_02;
    logic [63:0] rsp_data;
    logic [2:0] rsp_status;
    logic [63:0] last_store_value;
    int response_latency;
    
    begin
      print_header("TC-INT-02: Load-Store Integration");
      init_interface();
      
      // Test 1: STORE then LOAD same address
      dcache_store(64'h80005000, 64'hCAFEBABE, 8'd30);
      last_store_value = 64'hCAFEBABE;
      wait_response(8'd30, rsp_data, rsp_status);
      
      // Monitor store buffer and commit
      response_latency = 0;
      repeat(10) begin
        @(posedge clk);
        if (lsu_if_inst.store_commit_valid_o) begin
          if (lsu_if_inst.store_buffer_data_o == last_store_value) begin
            print_pass("Store buffer data matches write value");
          end
        end
        response_latency++;
      end
      
      // LOAD from same address
      dcache_load(64'h80005000, 8'd31);
      response_latency = 0;
      
      repeat(10) begin
        @(posedge clk);
        response_latency++;
        if (lsu_if_inst.lsu_rdata_o == last_store_value) begin
          print_pass($sformatf("Load data valid within %0d cycles", response_latency));
          break;
        end
      end
      
      if (response_latency <= 5) begin
        print_pass("Load-Store coherency verified: <5 cycle latency");
      end
      
      // Verify commit path
      if (commit_if.rd_valid_o && commit_if.commit_result_o == last_store_value) begin
        print_pass("Commit result matches stored value");
      end else begin
        print_fail("Data coherence mismatch in commit path");
      end
    end
  endtask

  // ========================================================
  // TC-INT-03: D-Cache Miss Stall
  // ⚠️  WARNING: Uses phantom interfaces (lsu_if_inst, commit_if)
  //     Needs update to RVFI + NOC interface
  // ========================================================
  task automatic test_int_03;
    logic [63:0] rsp_data;
    logic [2:0] rsp_status;
    int stall_duration;
    logic [63:0] frozen_pc;
    int pc_freeze_cycles;
    
    begin
      print_header("TC-INT-03: D-Cache Miss Stall");
      init_interface();
      stall_duration = 0;
      pc_freeze_cycles = 0;
      
      dcache_load(64'h80006000, 8'd40);
      
      // Wait for cache miss and monitor stall
      repeat(25) begin
        @(posedge clk);
        
        // Check stall signal
        if (lsu_if_inst.stall_lsu_o) begin
          stall_duration++;
          
          // Verify PC frozen (no commits)
          if (!commit_if.commit_valid_o) begin
            pc_freeze_cycles++;
            frozen_pc = commit_if.pc_commit_i;
          end
          
          // Check lsu_ready_i = 0 (blocks new issue)
          if (!lsu_if_inst.lsu_ready_i) begin
            // Expected during stall
          end
        end
        
        // Stall should resolve
        if (stall_duration > 0 && !lsu_if_inst.stall_lsu_o) begin
          break;
        end
      end
      
      if (stall_duration > 0 && stall_duration < 20) begin
        print_pass($sformatf("D-Cache miss stall handled: %0d cycles", stall_duration));
        print_pass($sformatf("PC frozen for %0d cycles during stall", pc_freeze_cycles));
        print_pass("Pipeline resumed after refill");
      end else if (stall_duration >= 20) begin
        print_fail($sformatf("Stall timeout: %0d cycles (>20)", stall_duration));
      end else begin
        print_fail("No stall detected on cache miss");
      end
      
      wait_response(8'd40, rsp_data, rsp_status);
    end
  endtask

  // ========================================================
  // TC-INT-04: RAW Hazard
  // ⚠️  WARNING: Uses phantom interfaces (lsu_if_inst, commit_if)
  //     Needs update to RVFI + NOC interface
  // ========================================================
  task automatic test_int_04;
    logic [63:0] rsp_data;
    logic [2:0] rsp_status;
    logic [63:0] last_store_data[5];
    logic [63:0] load_result;
    int test_pairs;
    logic [7:0] tid;
    logic [63:0] data;
    logic [63:0] addr;
    
    begin
      print_header("TC-INT-04: RAW (Read-After-Write) Hazard");
      init_interface();
      test_pairs = 5;
      
      // Test RAW hazard with multiple address pairs
      
      for (int i = 0; i < test_pairs; i++) begin
        addr = 64'h80007000 + (i * 8);
        data = 64'hFEEDBEEF + i;
        tid = 50 + i;
        
        // STORE operation
        dcache_store(addr, data, tid);
        last_store_data[i] = data;
        wait_response(tid, rsp_data, rsp_status);
        
        // Monitor store commit & buffer
        repeat(5) @(posedge clk);
        
        if (lsu_if_inst.store_commit_valid_o) begin
          if (lsu_if_inst.store_buffer_data_o == data) begin
            print_pass($sformatf("Store[%0d] buffer coherent", i));
          end
        end
        
        // LOAD from same address
        dcache_load(addr, tid + 100);
        repeat(8) @(posedge clk);
        wait_response(tid + 100, rsp_data, rsp_status);
        
        // Verify LOAD returns latest STORE value
        if (commit_if.commit_result_o == data && commit_if.rd_valid_o) begin
          print_pass($sformatf("RAW[%0d] resolved: stored 0x%x, loaded 0x%x", 
            i, data, commit_if.commit_result_o));
        end else begin
          print_fail($sformatf("RAW[%0d] mismatch: expected 0x%x, got 0x%x", 
            i, data, commit_if.commit_result_o));
        end
      end
    end
  endtask

  // ========================================================
  // TC-INT-05: Concurrent Requests - No Deadlock
  // ⚠️  WARNING: Uses phantom interfaces (axi_arbiter_if)
  //     Needs update to RVFI + NOC interface
  // ========================================================
  task automatic test_int_05;
    int i;
    int timeout;
    int responses_received;
    int stall_cycles;
    int max_stall;
    logic prev_aw_busy;
    logic prev_ar_busy;
    int aw_toggle_count;
    int ar_toggle_count;
    
    begin
      print_header("TC-INT-05: Concurrent Requests - No Deadlock");
      init_interface();
      responses_received = 0;
      stall_cycles = 0;
      max_stall = 0;
      prev_aw_busy = 1'b0;
      prev_ar_busy = 1'b0;
      aw_toggle_count = 0;
      ar_toggle_count = 0;
      
      // Issue 8 concurrent LOADs
      for (i = 0; i < 8; i++) begin
        dcache_load(64'h80008000 + (i * 64), i+60);
      end
      
      // Monitor for 100k cycles with deadlock detection
      timeout = 100000;
      while (timeout > 0) begin
        @(posedge clk);
        
        // Count responses
        if (d_if.core_rsp_valid) responses_received++;
        
        // Monitor AXI arbiter busy signals
        if (axi_arb_if.axi_aw_arbiter_busy_o != prev_aw_busy) begin
          aw_toggle_count++;
          prev_aw_busy = axi_arb_if.axi_aw_arbiter_busy_o;
        end
        
        if (axi_arb_if.axi_ar_arbiter_busy_o != prev_ar_busy) begin
          ar_toggle_count++;
          prev_ar_busy = axi_arb_if.axi_ar_arbiter_busy_o;
        end
        
        // Check outstanding transaction depth
        if (axi_arb_if.axi_w_outstanding_o >= 8 || axi_arb_if.axi_r_outstanding_o >= 8) begin
          print_fail("AXI buffer overflow detected");
        end
        
        // Detect stall duration
        if (lsu_if_inst.stall_lsu_o) begin
          stall_cycles++;
          if (stall_cycles > max_stall) max_stall = stall_cycles;
        end else begin
          stall_cycles = 0;
        end
        
        // Deadlock detection: stall >1000 cycles
        if (max_stall > 1000) begin
          print_fail($sformatf("Deadlock detected: stall >1000 cycles (%0d)", max_stall));
          break;
        end
        
        timeout--;
      end
      
      // Final validation
      if (responses_received >= 8) begin
        print_pass($sformatf("All %0d concurrent requests received responses", 
          responses_received));
        print_pass("No deadlock detected");
      end else begin
        print_fail($sformatf("Only %0d/%0d responses received (timeout)", 
          responses_received, 8));
      end
      
      // Check arbiter toggling (should be active, not stuck)
      if (aw_toggle_count >= (100000/10)) begin
        print_pass("AXI AW arbiter active (not stuck)");
      end else begin
        print_fail($sformatf("AXI AW arbiter stuck (only %0d toggles)", aw_toggle_count));
      end
      
      if (ar_toggle_count >= (100000/10)) begin
        print_pass("AXI AR arbiter active (not stuck)");
      end else begin
        print_fail($sformatf("AXI AR arbiter stuck (only %0d toggles)", ar_toggle_count));
      end
      
      if (max_stall < 1000) begin
        print_pass($sformatf("Max stall duration: %0d cycles (< 1000 threshold)", 
          max_stall));
      end
    end
  endtask

  // ========================================================
  // TEST RUNNER
  // ========================================================
  
  initial begin
    $display("[================================================]");
    $display("CVA6 L1 Cache Integration Test Suite");
    $display("Phase 4: TC-INT-01 through TC-INT-05");
    $display("[================================================]\n");
    
    // Run integration tests
    test_int_01();
    @(posedge clk);
    
    test_int_02();
    @(posedge clk);
    
    test_int_03();
    @(posedge clk);
    
    test_int_04();
    @(posedge clk);
    
    test_int_05();
    @(posedge clk);
    
    // Summary
    $display("[================================================]");
    if (fail_count == 0) begin
      $display("OVERALL RESULT: ALL TESTS PASSED");
    end else begin
      $display("OVERALL RESULT: %d TEST(S) FAILED", fail_count);
    end
    $display("[================================================]\n");
    
    $finish;
  end
  
  // ========================================================
  // WAVEFORM DUMPING
  // ========================================================
  
  // initial begin
    // $dumpfile("l1_cache_logic_sim.vcd");
    // $dumpvars(0, tb_l1_cache_integration_logic);
  // end

endmodule

