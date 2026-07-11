import uvm_pkg::*;
`include "uvm_macros.svh"

// Bao gồm file test vừa viết
`include "tb/hpdcache_base_test.sv"

module tb_top;
    initial begin
        // Gọi hàm run_test mặc định của UVM
        run_test(); 
    end
endmodule