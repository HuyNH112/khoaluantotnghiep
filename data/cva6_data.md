# CVA6 Top-Level Module - Complete Port & Parameter Inventory

**File**: `cva6.sv`  
**Module Name**: `cva6`  
**License**: Solderpad Hardware License, Version 0.51  
**Authors**: Florian Zaruba (ETH Zurich)  
**Date**: 19.03.2017

---

## Table of Contents
1. [Module Port Declaration](#module-port-declaration)
2. [Generic Parameters](#generic-parameters)
3. [Type Parameters](#type-parameters)
4. [Local Parameters (Type Definitions)](#local-parameters-type-definitions)
5. [Signal Port Details by Width](#signal-port-details-by-width)
6. [Interface Port Details](#interface-port-details)

---

## Module Port Declaration

### Syntax
```systemverilog
module cva6 
  import ariane_pkg::*;
  #( ... )
  ( ... );
```

**Total Module Ports**: 10 ports (6 input, 4 output)

---

## Generic Parameters

### 1. CVA6Cfg (Configuration Parameter)
| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `CVA6Cfg` | `config_pkg::cva6_cfg_t` | `build_config_pkg::build_config(cva6_config_pkg::cva6_cfg)` | Main configuration structure containing all CVA6 configuration parameters including VLEN, XLEN, cache dimensions, etc. |

### Key Config Fields Used
- `CVA6Cfg.VLEN`: Virtual address length (typically 64)
- `CVA6Cfg.XLEN`: Data path width (typically 64)
- `CVA6Cfg.PLEN`: Physical address length
- `CVA6Cfg.VLEN-1:0`: Virtual address bit range
- `CVA6Cfg.XLEN-1:0`: Register data bit range
- `CVA6Cfg.PLEN-1:0`: Physical address bit range
- `CVA6Cfg.NrIssuePorts`: Number of issue ports
- `CVA6Cfg.NrCommitPorts`: Number of commit ports
- `CVA6Cfg.NrWbPorts`: Number of writeback ports
- `CVA6Cfg.TRANS_ID_BITS`: Transaction ID width
- `CVA6Cfg.ICACHE_*`: I-Cache parameters
- `CVA6Cfg.DCACHE_*`: D-Cache parameters
- `CVA6Cfg.AxiIdWidth`: AXI ID width
- `CVA6Cfg.AxiAddrWidth`: AXI address width
- `CVA6Cfg.AxiDataWidth`: AXI data width
- `CVA6Cfg.AxiUserWidth`: AXI user bits width
- `CVA6Cfg.CvxifEn`: CVXIF (CoVX) enable
- `CVA6Cfg.EnableAccelerator`: Accelerator enable
- `CVA6Cfg.DebugEn`: Debug enable
- `CVA6Cfg.RVS`: Supervisor mode support
- `CVA6Cfg.PPNW`: Physical page number width
- `CVA6Cfg.ASID_WIDTH`: ASID width
- `CVA6Cfg.VMID_WIDTH`: VMID width
- `CVA6Cfg.NrPMPEntries`: PMP entries count
- `CVA6Cfg.SuperscalarEn`: Superscalar enable
- `CVA6Cfg.FETCH_WIDTH`: Fetch width
- `CVA6Cfg.FETCH_USER_WIDTH`: Fetch user bits
- `CVA6Cfg.DCACHE_USER_WIDTH`: D-Cache user bits
- `CVA6Cfg.ICACHE_USER_LINE_WIDTH`: I-Cache user line width
- `CVA6Cfg.DcacheIdWidth`: D-Cache ID width
- `CVA6Cfg.MEM_TID_WIDTH`: Memory transaction ID width
- `CVA6Cfg.ICACHE_SET_ASSOC_WIDTH`: I-Cache set associativity width
- `CVA6Cfg.ICACHE_INDEX_WIDTH`: I-Cache index width
- `CVA6Cfg.ICACHE_TAG_WIDTH`: I-Cache tag width
- `CVA6Cfg.ICACHE_LINE_WIDTH`: I-Cache line width
- `CVA6Cfg.DCACHE_INDEX_WIDTH`: D-Cache index width
- `CVA6Cfg.DCACHE_TAG_WIDTH`: D-Cache tag width
- `CVA6Cfg.DCACHE_SET_ASSOC`: D-Cache set associativity

---

## Type Parameters

### RVFI Probes (Runtime Verification)
| Parameter | Type | Description |
|-----------|------|-------------|
| `rvfi_probes_instr_t` | `struct packed` | Instruction-level RVFI probe signals |
| `rvfi_probes_csr_t` | `struct packed` | CSR-level RVFI probe signals |
| `rvfi_probes_t` | `struct packed` | Aggregated RVFI probes combining CSR and instruction probes |

### AXI Channel Types
| Parameter | Type | Fields | Description |
|-----------|------|--------|-------------|
| `axi_ar_chan_t` | `struct packed` | id, addr, len, size, burst, lock, cache, prot, qos, region, user | AXI read address channel (AR) |
| `axi_aw_chan_t` | `struct packed` | id, addr, len, size, burst, lock, cache, prot, qos, region, atop, user | AXI write address channel (AW) |
| `axi_w_chan_t` | `struct packed` | data, strb, last, user | AXI write data channel (W) |
| `b_chan_t` | `struct packed` | id, resp, user | AXI write response channel (B) |
| `r_chan_t` | `struct packed` | id, data, resp, last, user | AXI read data channel (R) |

### NoC Interface Types
| Parameter | Type | Description |
|-----------|------|-------------|
| `noc_req_t` | `struct packed` | NOC request bundle (aw + w + ar + b_ready/r_ready) |
| `noc_resp_t` | `struct packed` | NOC response bundle (aw_ready + ar_ready + w_ready + b + r) |

### CVXIF (CoVX Interface) Types
| Parameter | Type | Description |
|-----------|------|-------------|
| `readregflags_t` | macro-generated struct | Register read flags for CVXIF |
| `writeregflags_t` | macro-generated struct | Register write flags for CVXIF |
| `id_t` | macro-generated struct | ID type for CVXIF transactions |
| `hartid_t` | macro-generated struct | Hart ID type for CVXIF |
| `x_compressed_req_t` | macro-generated struct | Compressed instruction request |
| `x_compressed_resp_t` | macro-generated struct | Compressed instruction response |
| `x_issue_req_t` | macro-generated struct | X-interface issue request |
| `x_issue_resp_t` | macro-generated struct | X-interface issue response |
| `x_register_t` | macro-generated struct | X-interface register access |
| `x_commit_t` | macro-generated struct | X-interface commit information |
| `x_result_t` | macro-generated struct | X-interface result |
| `cvxif_req_t` | macro-generated struct | Complete CVXIF request interface |
| `cvxif_resp_t` | macro-generated struct | Complete CVXIF response interface |

### Accelerator Types
| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `accelerator_req_t` | type | `logic` | Accelerator request type (default: logic, can be overridden) |
| `accelerator_resp_t` | type | `logic` | Accelerator response type |
| `acc_mmu_req_t` | type | `logic` | Accelerator MMU request type |
| `acc_mmu_resp_t` | type | `logic` | Accelerator MMU response type |
| `acc_cfg_t` | type | `logic` | Accelerator configuration type |
| `AccCfg` | `acc_cfg_t` | `'0` | Accelerator configuration value |

---

## Local Parameters (Type Definitions)

### Branch Prediction
```systemverilog
localparam type branchpredict_sbe_t = struct packed {
  cf_t                     cf;               // control flow type
  logic [CVA6Cfg.VLEN-1:0] predict_address;  // prediction target address
}
```
| Field | Width | Description |
|-------|-------|-------------|
| `cf` | N/A | Control flow type enum |
| `predict_address` | `CVA6Cfg.VLEN` | Predicted branch target address |

### Exception Structure
```systemverilog
localparam type exception_t = struct packed {
  logic [CVA6Cfg.XLEN-1:0] cause;       // Exception cause code
  logic [CVA6Cfg.XLEN-1:0] tval;        // Exception additional info
  logic [CVA6Cfg.GPLEN-1:0] tval2;      // Guest mode exception info
  logic [31:0] tinst;                   // Transformed instruction
  logic gva;                             // Guest virtual address flag
  logic valid;                           // Exception valid flag
}
```
| Field | Width | Description |
|-------|-------|-------------|
| `cause` | `CVA6Cfg.XLEN` | RISC-V exception cause code |
| `tval` | `CVA6Cfg.XLEN` | Trap value (faulting address or instruction) |
| `tval2` | `CVA6Cfg.GPLEN` | Guest additional trap info |
| `tinst` | 32 | Transformed instruction (Hypervisor) |
| `gva` | 1 | Guest virtual address flag |
| `valid` | 1 | Exception valid indicator |

### I-Cache Address Translation Request/Response
```systemverilog
localparam type icache_areq_t = struct packed {
  logic                    fetch_valid;      // Address translation valid
  logic [CVA6Cfg.PLEN-1:0] fetch_paddr;      // Physical address output
  exception_t              fetch_exception;  // Translation exception
}

localparam type icache_arsp_t = struct packed {
  logic                    fetch_req;    // Address translation request input
  logic [CVA6Cfg.VLEN-1:0] fetch_vaddr;  // Virtual address input
}
```

### I-Cache Data Request/Response
```systemverilog
localparam type icache_dreq_t = struct packed {
  logic                    req;      // Data request
  logic                    kill_s1;  // Kill S1 stage
  logic                    kill_s2;  // Kill S2 stage
  logic                    spec;     // Speculative request
  logic [CVA6Cfg.VLEN-1:0] vaddr;    // Virtual address
}

localparam type icache_drsp_t = struct packed {
  logic                                ready;  // Cache ready
  logic                                valid;  // Response valid
  logic [CVA6Cfg.FETCH_WIDTH-1:0]      data;   // Fetch data
  logic [CVA6Cfg.FETCH_USER_WIDTH-1:0] user;   // User bits
  logic [CVA6Cfg.VLEN-1:0]             vaddr;  // Virtual address
  exception_t                          ex;     // Exception
}
```

### Fetch Entry (IF/ID)
```systemverilog
localparam type fetch_entry_t = struct packed {
  logic [CVA6Cfg.VLEN-1:0] address;       // Instruction address
  logic [31:0] instruction;               // 32-bit instruction word
  branchpredict_sbe_t      branch_predict;// Branch prediction info
  exception_t              ex;             // Exceptions
}
```

### JVT (Jump Vector Table) Structure
```systemverilog
localparam type jvt_t = struct packed {
  logic [CVA6Cfg.XLEN-7:0] base;  // JVT base address
  logic [5:0] mode;               // JVT mode
}
```

### Scoreboard Entry
```systemverilog
localparam type scoreboard_entry_t = struct packed {
  logic [CVA6Cfg.VLEN-1:0]         pc;                      // Program counter
  logic [CVA6Cfg.TRANS_ID_BITS-1:0] trans_id;              // Transaction ID
  fu_t                              fu;                     // Functional unit
  fu_op                             op;                     // Operation
  logic [REG_ADDR_SIZE-1:0]         rs1;                    // Source register 1
  logic [REG_ADDR_SIZE-1:0]         rs2;                    // Source register 2
  logic [REG_ADDR_SIZE-1:0]         rd;                     // Destination register
  logic [CVA6Cfg.XLEN-1:0]          result;                 // Result/immediate
  logic                             valid;                  // Result valid
  logic                             use_imm;                // Use immediate
  logic                             use_zimm;               // Use compressed immediate
  logic                             use_pc;                 // Use PC
  exception_t                       ex;                     // Exception
  branchpredict_sbe_t               bp;                     // Branch predict data
  logic                             is_compressed;          // Compressed instruction
  logic                             is_macro_instr;         // Macro instruction
  logic                             is_last_macro_instr;    // Last macro instruction
  logic                             is_double_rd_macro_instr;// Double move macro
  logic                             vfp;                    // Vector FP instruction
  logic                             is_zcmt;                // ZCMT instruction
}
```

### Writeback Transaction
```systemverilog
localparam type writeback_t = struct packed {
  logic                             valid;   // Valid flag
  logic [CVA6Cfg.XLEN-1:0]          data;    // Writeback data
  logic                             ex_valid;// Exception valid
  logic [CVA6Cfg.TRANS_ID_BITS-1:0] trans_id;// Transaction ID
}
```

### Branch Prediction Resolve
```systemverilog
localparam type bp_resolve_t = struct packed {
  logic                    valid;           // Valid prediction
  logic [CVA6Cfg.VLEN-1:0] pc;              // Prediction PC
  logic [CVA6Cfg.VLEN-1:0] target_address;  // Branch target
  logic                    is_mispredict;   // Misprediction flag
  logic                    is_taken;        // Branch taken
  cf_t                     cf_type;         // Control flow type
}
```

### Interrupt Control
```systemverilog
localparam type irq_ctrl_t = struct packed {
  logic [CVA6Cfg.XLEN-1:0] mie;         // M-mode interrupt enable
  logic [CVA6Cfg.XLEN-1:0] mip;         // M-mode interrupt pending
  logic [CVA6Cfg.XLEN-1:0] mideleg;     // M-mode interrupt delegation
  logic [CVA6Cfg.XLEN-1:0] hideleg;     // H-mode interrupt delegation
  logic                    sie;         // S-mode interrupt enable
  logic                    global_enable;// Global interrupt enable
}
```

### LSU Control
```systemverilog
localparam type lsu_ctrl_t = struct packed {
  logic                             valid;                  // Valid flag
  logic [CVA6Cfg.VLEN-1:0]          vaddr;                  // Virtual address
  logic [31:0]                      tinst;                  // Transformed instruction
  logic                             hs_ld_st_inst;          // Hypervisor load/store
  logic                             hlvx_inst;              // HLVX instruction
  logic                             overflow;               // Overflow flag
  logic                             g_overflow;             // Guest overflow
  logic [CVA6Cfg.XLEN-1:0]          data;                   // Load/store data
  logic [(CVA6Cfg.XLEN/8)-1:0]      be;                     // Byte enable
  fu_t                              fu;                     // Functional unit
  fu_op                             operation;              // Operation
  logic [CVA6Cfg.TRANS_ID_BITS-1:0] trans_id;              // Transaction ID
  logic                             is_speculative_load;   // Speculative load
  logic                             is_speculative_load_miss;// Speculative miss
}
```

### Functional Unit Data
```systemverilog
localparam type fu_data_t = struct packed {
  fu_t                              fu;        // Functional unit
  fu_op                             operation; // Operation code
  logic [CVA6Cfg.XLEN-1:0]          operand_a; // Operand A
  logic [CVA6Cfg.XLEN-1:0]          operand_b; // Operand B
  logic [CVA6Cfg.XLEN-1:0]          imm;       // Immediate
  logic [CVA6Cfg.TRANS_ID_BITS-1:0] trans_id;  // Transaction ID
}
```

### I-Cache Request (Memory)
```systemverilog
localparam type icache_req_t = struct packed {
  logic [CVA6Cfg.ICACHE_SET_ASSOC_WIDTH-1:0] way;  // Cache way to replace
  logic [CVA6Cfg.PLEN-1:0]                  paddr; // Physical address
  logic                                     nc;   // Non-cacheable
  logic [CVA6Cfg.MEM_TID_WIDTH-1:0]         tid;  // Transaction ID
}
```

### I-Cache Return (Memory)
```systemverilog
localparam type icache_rtrn_t = struct packed {
  wt_cache_pkg::icache_in_t           rtype;  // Return type
  logic [CVA6Cfg.ICACHE_LINE_WIDTH-1:0] data; // Cache line data
  logic [CVA6Cfg.ICACHE_USER_LINE_WIDTH-1:0] user; // User bits
  struct packed {
    logic                                vld;  // Invalidate one way
    logic                                all;  // Invalidate all ways
    logic [CVA6Cfg.ICACHE_INDEX_WIDTH-1:0] idx; // Invalidation index
    logic [CVA6Cfg.ICACHE_SET_ASSOC_WIDTH-1:0] way; // Invalidation way
  } inv;
  logic [CVA6Cfg.MEM_TID_WIDTH-1:0] tid;  // Transaction ID
}
```

### D-Cache Request Input
```systemverilog
localparam type dcache_req_i_t = struct packed {
  logic [CVA6Cfg.DCACHE_INDEX_WIDTH-1:0] address_index;  // Cache index
  logic [CVA6Cfg.DCACHE_TAG_WIDTH-1:0]   address_tag;    // Cache tag
  logic [CVA6Cfg.XLEN-1:0]               data_wdata;     // Write data
  logic [CVA6Cfg.DCACHE_USER_WIDTH-1:0]  data_wuser;     // User bits
  logic                                  data_req;       // Data request
  logic                                  data_we;        // Write enable
  logic [(CVA6Cfg.XLEN/8)-1:0]           data_be;        // Byte enable
  logic [1:0]                            data_size;      // Size
  logic [CVA6Cfg.DcacheIdWidth-1:0]      data_id;        // Request ID
  logic                                  kill_req;       // Kill request
  logic                                  tag_valid;      // Tag valid
  cbo_t                                  cbo_op;         // Cache op
}
```

### D-Cache Request Output
```systemverilog
localparam type dcache_req_o_t = struct packed {
  logic                                 data_gnt;   // Grant
  logic                                 data_rvalid;// Response valid
  logic [CVA6Cfg.DcacheIdWidth-1:0]     data_rid;   // Response ID
  logic [CVA6Cfg.XLEN-1:0]              data_rdata; // Response data
  logic [CVA6Cfg.DCACHE_USER_WIDTH-1:0] data_ruser; // Response user
}
```

### Cache Block Operation Type
```systemverilog
localparam type cbo_t = logic [7:0];  // Cache block operation 8-bit encoding
```

---

## Signal Port Details by Width

### Input Ports (Scalar)

| Port Name | Width | Direction | Type | Description |
|-----------|-------|-----------|------|-------------|
| `clk_i` | 1 | input | `logic` | Subsystem clock - main core clock |
| `rst_ni` | 1 | input | `logic` | Asynchronous reset (active low) |
| `irq_i` | 2 | input | `logic [1:0]` | Level-sensitive async interrupts (irq[1:0]) |
| `ipi_i` | 1 | input | `logic` | Inter-processor async interrupt |
| `time_irq_i` | 1 | input | `logic` | Timer interrupt (async) |
| `debug_req_i` | 1 | input | `logic` | Debug request (async) |

### Input Ports (Address/ID)

| Port Name | Width | Direction | Type | Description |
|-----------|-------|-----------|------|-------------|
| `boot_addr_i` | `CVA6Cfg.VLEN` | input | `logic [CVA6Cfg.VLEN-1:0]` | Reset boot address (program counter at reset) |
| `hart_id_i` | `CVA6Cfg.XLEN` | input | `logic [CVA6Cfg.XLEN-1:0]` | Hardware thread ID (reflected in CSR mhartid) |

### Output Ports (RVFI)

| Port Name | Width | Direction | Type | Description |
|-----------|-------|-----------|------|-------------|
| `rvfi_probes_o` | struct | output | `rvfi_probes_t` | Runtime verification probes (instruction & CSR level) |

### Input/Output Ports (CVXIF - Co-execution Interface)

| Port Name | Width | Direction | Type | Description |
|-----------|-------|-----------|------|-------------|
| `cvxif_req_o` | struct | output | `cvxif_req_t` | CVXIF request interface (compressed, issue, register, commit, result_ready) |
| `cvxif_resp_i` | struct | input | `cvxif_resp_t` | CVXIF response interface (compressed_ready, issue_ready, register_ready, result_valid/data) |

### Input/Output Ports (NOC - Network-on-Chip / Memory Interface)

| Port Name | Width | Direction | Type | Description |
|-----------|-------|-----------|------|-------------|
| `noc_req_o` | struct | output | `noc_req_t` | NOC request bundle (AXI AR/AW/W channels + ready signals) |
| `noc_resp_i` | struct | input | `noc_resp_t` | NOC response bundle (AXI B/R channels + ready signals) |

---

## Interface Port Details

### NOC Request Structure (`noc_req_t`)

```
Write Address Channel:
  aw.id         [CVA6Cfg.AxiIdWidth-1:0]
  aw.addr       [CVA6Cfg.AxiAddrWidth-1:0]
  aw.len        [7:0]
  aw.size       [2:0]
  aw.burst      [1:0]
  aw.lock       [0:0]
  aw.cache      [3:0]
  aw.prot       [2:0]
  aw.qos        [3:0]
  aw.region     [3:0]
  aw.atop       [5:0]
  aw.user       [CVA6Cfg.AxiUserWidth-1:0]
  aw_valid      [0:0]

Write Data Channel:
  w.data        [CVA6Cfg.AxiDataWidth-1:0]
  w.strb        [(CVA6Cfg.AxiDataWidth/8)-1:0]
  w.last        [0:0]
  w.user        [CVA6Cfg.AxiUserWidth-1:0]
  w_valid       [0:0]

Write Response Control:
  b_ready       [0:0]

Read Address Channel:
  ar.id         [CVA6Cfg.AxiIdWidth-1:0]
  ar.addr       [CVA6Cfg.AxiAddrWidth-1:0]
  ar.len        [7:0]
  ar.size       [2:0]
  ar.burst      [1:0]
  ar.lock       [0:0]
  ar.cache      [3:0]
  ar.prot       [2:0]
  ar.qos        [3:0]
  ar.region     [3:0]
  ar.user       [CVA6Cfg.AxiUserWidth-1:0]
  ar_valid      [0:0]

Read Data Control:
  r_ready       [0:0]
```

### NOC Response Structure (`noc_resp_t`)

```
Address Channel Readies:
  aw_ready      [0:0]  - Write address ready
  ar_ready      [0:0]  - Read address ready
  w_ready       [0:0]  - Write data ready

Write Response Channel:
  b_valid       [0:0]  - Write response valid
  b.id          [CVA6Cfg.AxiIdWidth-1:0]
  b.resp        [1:0]  - AXI response (OKAY/EXOKAY/SLVERR/DECERR)
  b.user        [CVA6Cfg.AxiUserWidth-1:0]

Read Data Channel:
  r_valid       [0:0]  - Read data valid
  r.id          [CVA6Cfg.AxiIdWidth-1:0]
  r.data        [CVA6Cfg.AxiDataWidth-1:0]
  r.resp        [1:0]  - AXI response
  r.last        [0:0]  - Last beat in burst
  r.user        [CVA6Cfg.AxiUserWidth-1:0]
```

### CVXIF Request Structure (`cvxif_req_t`)

```
Compressed Instruction Interface:
  compressed_valid  [0:0]           - Valid compressed request
  compressed_req    x_compressed_req_t - Request data

Issue Interface:
  issue_valid       [0:0]           - Valid issue request
  issue_req         x_issue_req_t   - Issue request data

Register Access Interface:
  register_valid    [0:0]           - Valid register request
  register          x_register_t    - Register request data

Commit Interface:
  commit_valid      [0:0]           - Valid commit
  commit            x_commit_t      - Commit data

Result Handshake:
  result_ready      [0:0]           - Ready for result
```

### CVXIF Response Structure (`cvxif_resp_t`)

```
Compressed Response:
  compressed_ready  [0:0]           - Ready for compressed request
  compressed_resp   x_compressed_resp_t - Response data

Issue Response:
  issue_ready       [0:0]           - Ready for issue request
  issue_resp        x_issue_resp_t  - Response data

Register Response:
  register_ready    [0:0]           - Ready for register request

Result Interface:
  result_valid      [0:0]           - Result valid
  result            x_result_t      - Result data
```

### RVFI Probes Structure (`rvfi_probes_t`)

```
rvfi_probes_t {
  csr:   rvfi_probes_csr_t     - CSR-level probes
    └─ Contains CSR access information for RVFI
    
  instr: rvfi_probes_instr_t   - Instruction-level probes
    └─ Contains instruction execution information for RVFI
}
```

---

## Port Connection Summary

### Clock & Reset (Subsystem)
- `clk_i`: Core clock
- `rst_ni`: Async reset (active low)

### Interrupts (Subsystem)
- `irq_i[1:0]`: External interrupts
- `ipi_i`: Inter-processor interrupt
- `time_irq_i`: Timer interrupt
- `debug_req_i`: Debug request

### Configuration (Subsystem)
- `boot_addr_i`: Reset PC address
- `hart_id_i`: Hardware thread ID

### RVFI (Formal Verification)
- `rvfi_probes_o`: Instruction + CSR probes

### CVXIF (Extension Interface)
- `cvxif_req_o`: Request (compressed/issue/register/commit)
- `cvxif_resp_i`: Response (ready signals + results)

### Memory Interface (AXI-like)
- `noc_req_o`: Request (AR/AW/W channels)
- `noc_resp_i`: Response (B/R channels)

---

## Typical Configuration Values

| Parameter | Typical Value | Description |
|-----------|---------------|-------------|
| `CVA6Cfg.VLEN` | 64 | Virtual address width |
| `CVA6Cfg.XLEN` | 64 | Register/data width |
| `CVA6Cfg.PLEN` | 56 | Physical address width |
| `CVA6Cfg.NrIssuePorts` | 2-4 | Number of issue ports |
| `CVA6Cfg.NrCommitPorts` | 2-4 | Number of commit ports |
| `CVA6Cfg.AxiIdWidth` | 4-6 | AXI ID width |
| `CVA6Cfg.AxiAddrWidth` | 56-64 | AXI address width |
| `CVA6Cfg.AxiDataWidth` | 128-256 | AXI data width |
| `CVA6Cfg.AxiUserWidth` | 1-8 | AXI user signal width |

---

## Notes

1. **Port Count**: Total 10 module ports (6 input, 4 output)
2. **Parameterization**: Heavily parameterized via CVA6Cfg
3. **AXI Compliance**: NOC interface follows AXI4 protocol
4. **CVXIF Support**: Optional Co-execution extension interface
5. **RVFI Support**: Includes runtime verification probe interface
6. **Reset Behavior**: Asynchronous reset, active low (rst_ni)
7. **Clock**: Single synchronous clock domain (clk_i)
8. **Interrupt Types**: Three types of async interrupts + debug request
9. **No Built-in Status Outputs**: Status returned via CSR interface (internal)
10. **Memory Model**: External memory via NOC (AXI-based)

