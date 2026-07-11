//tb kiem tra lenh add
`timescale 1ns/1ps
import ariane_pkg::*;
import config_pkg::*;
import cva6_config_pkg::*;
import axi_pkg::*;

module tb_cva6;

    // ========== THAM SỐ ==========
    parameter CLK_PERIOD = 10; // ns
    
    // Lấy cấu hình của CPU
    localparam config_pkg::cva6_cfg_t CVA6Cfg = build_config_pkg::build_config(cva6_config_pkg::cva6_cfg);
    
    // ========== ĐỊNH NGHĨA KIỂU DỮ LIỆU AXI / NOC ==========
    typedef struct packed {
      logic [CVA6Cfg.AxiIdWidth-1:0]   id;
      logic [CVA6Cfg.AxiAddrWidth-1:0] addr;
      axi_pkg::len_t                   len;
      axi_pkg::size_t                  size;
      axi_pkg::burst_t                 burst;
      logic                            lock;
      axi_pkg::cache_t                 cache;
      axi_pkg::prot_t                  prot;
      axi_pkg::qos_t                   qos;
      axi_pkg::region_t                region;
      logic [CVA6Cfg.AxiUserWidth-1:0] user;
    } axi_ar_chan_t;

    typedef struct packed {
      logic [CVA6Cfg.AxiIdWidth-1:0]   id;
      logic [CVA6Cfg.AxiAddrWidth-1:0] addr;
      axi_pkg::len_t                   len;
      axi_pkg::size_t                  size;
      axi_pkg::burst_t                 burst;
      logic                            lock;
      axi_pkg::cache_t                 cache;
      axi_pkg::prot_t                  prot;
      axi_pkg::qos_t                   qos;
      axi_pkg::region_t                region;
      axi_pkg::atop_t                  atop;
      logic [CVA6Cfg.AxiUserWidth-1:0] user;
    } axi_aw_chan_t;

    typedef struct packed {
      logic [CVA6Cfg.AxiDataWidth-1:0]     data;
      logic [(CVA6Cfg.AxiDataWidth/8)-1:0] strb;
      logic                                last;
      logic [CVA6Cfg.AxiUserWidth-1:0]     user;
    } axi_w_chan_t;

    typedef struct packed {
      logic [CVA6Cfg.AxiIdWidth-1:0]   id;
      axi_pkg::resp_t                  resp;
      logic [CVA6Cfg.AxiUserWidth-1:0] user;
    } axi_b_chan_t;

    typedef struct packed {
      logic [CVA6Cfg.AxiIdWidth-1:0]   id;
      logic [CVA6Cfg.AxiDataWidth-1:0] data;
      axi_pkg::resp_t                  resp;
      logic                            last;
      logic [CVA6Cfg.AxiUserWidth-1:0] user;
    } axi_r_chan_t;

    typedef struct packed {
      axi_aw_chan_t aw;
      logic         aw_valid;
      axi_w_chan_t  w;
      logic         w_valid;
      logic         b_ready;
      axi_ar_chan_t ar;
      logic         ar_valid;
      logic         r_ready;
    } noc_req_t;

    typedef struct packed {
      logic         aw_ready;
      logic         ar_ready;
      logic         w_ready;
      logic         b_valid;
      axi_b_chan_t  b;
      logic         r_valid;
      axi_r_chan_t  r;
    } noc_resp_t;

    // ========== TÍN HIỆU CƠ BẢN ==========
    logic clk;
    logic rst_n;
    
    logic [CVA6Cfg.VLEN-1:0] boot_addr_i;
    logic [CVA6Cfg.XLEN-1:0] hart_id_i;
    logic [1:0]              irq_i;
    logic                    ipi_i;
    logic                    time_irq_i;
    logic                    debug_req_i;
    
    noc_req_t  noc_req;
    noc_resp_t noc_resp;

    // ========== KHỞI TẠO CVA6 CORE ==========
    cva6 #(
        .CVA6Cfg(CVA6Cfg),
        .noc_req_t(noc_req_t),
        .noc_resp_t(noc_resp_t)
    ) u_cva6 (
        .clk_i       (clk),
        .rst_ni      (rst_n),
        .boot_addr_i (boot_addr_i),
        .hart_id_i   (hart_id_i),
        .irq_i       (irq_i),
        .ipi_i       (ipi_i),
        .time_irq_i  (time_irq_i),
        .debug_req_i (debug_req_i),
        .rvfi_probes_o(),
        .cvxif_req_o  (),
        .cvxif_resp_i ('0),
        .noc_req_o    (noc_req),  
        .noc_resp_i   (noc_resp)  
    );
    
    // ========== MÔ HÌNH BỘ NHỚ GIẢ LẬP (AXI SLAVE) ==========
    
    // 1. Tăng kích thước RAM lên 256KB (18-bit address) để chứa được code ở 0x10094
    logic [7:0] memory [0:262143]; 

    // 2. Khởi tạo RAM và nạp file HEX
    initial begin
        // CHỈ dùng hàm hệ thống để nạp mã máy, không gán tay bằng vòng lặp nữa
        $readmemh("D:/HCMUS/THESIS/test/matrix_test.hex", memory);
        $display("[INFO] Da nap file matrix_test.hex vao RAM he thong!");
    end

    // --- Logic Xử lý AXI Đa luồng (Chống Đỏ X) ---
    logic        r_valid_q;
    axi_r_chan_t r_data_q;
    logic        b_valid_q;
    axi_b_chan_t b_data_q;

    // 3. Kỹ thuật Address Masking (Đã fix lỗi AXI Protocol)
    logic [17:0] safe_ar_addr;
    assign safe_ar_addr = noc_req.ar.addr[17:0];

    // --- CÁC THANH GHI CHỐT KÊNH GHI (AW CHANNEL LATCH) ---
    logic [17:0] latched_aw_addr;
    logic [CVA6Cfg.AxiIdWidth-1:0] latched_aw_id;
    logic [17:0] current_aw_addr;
    logic [CVA6Cfg.AxiIdWidth-1:0] current_aw_id;

    // Tự động chọn: Nếu AW đến cùng lúc thì dùng trực tiếp, nếu AW đến trước thì dùng đồ đã chốt
    assign current_aw_addr = (noc_req.aw_valid) ? noc_req.aw.addr[17:0] : latched_aw_addr;
    assign current_aw_id   = (noc_req.aw_valid) ? noc_req.aw.id : latched_aw_id;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            r_valid_q <= 1'b0;
            b_valid_q <= 1'b0;
            r_data_q  <= '0;
            b_data_q  <= '0;
        end else begin
            // 4. Phản hồi Kênh Đọc (Cấp lệnh/Data cho CPU)
            if (noc_req.ar_valid && noc_resp.ar_ready) begin
                r_valid_q      <= 1'b1;
                r_data_q.data  <= {memory[safe_ar_addr+7], memory[safe_ar_addr+6],
                                   memory[safe_ar_addr+5], memory[safe_ar_addr+4],
                                   memory[safe_ar_addr+3], memory[safe_ar_addr+2],
                                   memory[safe_ar_addr+1], memory[safe_ar_addr]};
                r_data_q.resp  <= 2'b00;
                r_data_q.last  <= 1'b1;  
                r_data_q.id    <= noc_req.ar.id;
            end else if (r_valid_q && noc_req.r_ready) begin
                r_valid_q      <= 1'b0;
            end
            
            // =================================================================
            // [FIX] 5. PHẢN HỒI KÊNH GHI (TÁCH BẠCH AW VÀ W)
            // =================================================================
            // BƯỚC 1: Chốt Address và ID khi kênh AW đến
            if (noc_req.aw_valid && noc_resp.aw_ready) begin
                latched_aw_addr <= noc_req.aw.addr[17:0];
                latched_aw_id   <= noc_req.aw.id;
            end

            // BƯỚC 2: Ghi RAM và trả B-Response khi kênh W đến
            if (noc_req.w_valid && noc_resp.w_ready) begin
                for (int i = 0; i < 8; i++) begin
                    if (noc_req.w.strb[i]) begin
                        memory[current_aw_addr + i] <= noc_req.w.data[i*8 +: 8];
                    end
                end
                b_valid_q      <= 1'b1;
                b_data_q.resp  <= 2'b00; 
                b_data_q.id    <= current_aw_id; // Đã sửa: Không còn bị rác ID
            end else if (b_valid_q && noc_req.b_ready) begin
                b_valid_q      <= 1'b0;
            end
        end
    end
    
    // Gộp tín hiệu gửi lên CPU
    always_comb begin
        noc_resp          = '0; 
        noc_resp.ar_ready = 1'b1;
        noc_resp.aw_ready = 1'b1;
        noc_resp.w_ready  = 1'b1;
        noc_resp.r_valid  = r_valid_q;
        noc_resp.r        = r_data_q;
        noc_resp.b_valid  = b_valid_q;
        noc_resp.b        = b_data_q;
    end
    
    // ========== TẠO XUNG CLOCK & RESET ==========
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end
    
    initial begin
        rst_n = 0;
        #100;
        rst_n = 1;
    end
    
    initial begin
        // Đặt địa chỉ Boot của CPU trỏ đúng vào địa chỉ bắt đầu trong file HEX (@00010094)
        boot_addr_i = 64'h00010094; 
        hart_id_i   = '0;   
        irq_i       = 2'b0;
        ipi_i       = 1'b0;
        time_irq_i  = 1'b0;
        debug_req_i = 1'b0;
    end
    
    // ========== KIỂM TRA KẾT QUẢ ==========
    logic [31:0] expected_result = 32'd8; 
    
    initial begin
        #500000; // Đổi thành thời gian này để CPU chạy thoải mái qua các chu kỳ pipeline
        // Kiểm tra xem CPU có tính ra 8 và ghi vào RAM không
        if ({memory['h103], memory['h102], memory['h101], memory['h100]} == expected_result) begin
            $display("[INFO] TEST PASSED! Result = %d", expected_result);
        end
        else begin
            $display("[ERROR] TEST FAILED! Expected = %d, Got = %d", expected_result, {memory['h103], memory['h102], memory['h101], memory['h100]});
        end
        $stop; // Tạm dừng để xem Waveform
    end
    
endmodule