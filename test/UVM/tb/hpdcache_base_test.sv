`ifndef HPDCACHE_BASE_TEST_SV
`define HPDCACHE_BASE_TEST_SV

import uvm_pkg::*;
`include "uvm_macros.svh"

// Gọi file seq_item vào để dùng
`include "hpdcache_agent/hpdcache_seq_item.sv"

class hpdcache_base_test extends uvm_test;
    // Đăng ký với UVM Factory
    `uvm_component_utils(hpdcache_base_test)

    // Hàm khởi tạo
    function new(string name = "hpdcache_base_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    // Pha Main Run: Nơi thực thi logic của Test
    task run_phase(uvm_phase phase);
        hpdcache_seq_item req;

        phase.raise_objection(this); // Báo cho UVM biết Test bắt đầu
        
        `uvm_info("TEST", "=== BAT DAU SINH LENH NGAU NHIEN CHO HPDCACHE ===", UVM_LOW)

        // Sinh ra 5 lệnh ngẫu nhiên
        for (int i = 0; i < 5; i++) begin
            req = hpdcache_seq_item::type_id::create("req"); // Tạo object chuẩn UVM
            
            if (!req.randomize()) begin
                `uvm_fatal("TEST", "Loi: Khong the randomize gói tin!")
            end
            
            // In kết quả ra màn hình
            `uvm_info("TEST_ITEM", $sformatf("Lenh thu %0d: %s", i+1, req.convert2string()), UVM_LOW)
        end

        `uvm_info("TEST", "=== KET THUC TEST ===", UVM_LOW)
        
        phase.drop_objection(this); // Báo cho UVM biết Test đã xong
    endtask

endclass : hpdcache_base_test

`endif