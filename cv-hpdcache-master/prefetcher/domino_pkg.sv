package domino_pkg;
    parameter ADDR_WIDTH = 56;   // Khớp với CONF_HPDCACHE_PA_WIDTH
    parameter INDEX_WIDTH = 10;  // Bảng MHT có 1024 dòng (2^10)
    
    // Cấu trúc gói tin đẩy ra cho HPDcache
    typedef struct packed {
        logic valid;
        logic [ADDR_WIDTH-1:0] pref_addr;
    } domino_pref_req_t;
endpackage