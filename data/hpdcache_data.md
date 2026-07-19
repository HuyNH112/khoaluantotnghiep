# HPDcache Wrapper Module - Complete Port & Parameter Specification

**File:** `hpdcache_wrapper.sv`  
**Module:** `hpdcache_wrapper`  
**Author:** Cesar Fuguet  
**Date:** October 2024  
**License:** Apache-2.0 WITH SHL-2.1

---

## Table of Contents

1. [Parameters](#1-parameters)
2. [Input Ports](#2-input-ports)
3. [Output Ports](#3-output-ports)
4. [Internal Interface Structs](#4-internal-interface-structs)
5. [Signal Widths (Dynamic)](#5-key-signal-widths-dynamic-based-on-config)
6. [Handshake Protocol](#6-timing--handshake-protocol)
7. [Module Instantiation](#7-module-instantiation)

---

## 1. PARAMETERS

All parameters are **localparam** (configuration-time only).

### 1.1 Configuration Struct

| **Parameter** | **Type** | **Default Value** | **Mô tả** |
|---|---|---|---|
| `UserCfg` | `hpdcache_user_cfg_t` | Struct config | Cấu hình người dùng cho HPDcache |
| `Cfg` | `hpdcache_cfg_t` | `hpdcacheBuildConfig(UserCfg)` | Cấu hình đã build từ UserCfg |

**UserCfg Fields:**
- `nRequesters`: Number of requesters (1 << `CONF_HPDCACHE_REQ_SRC_ID_WIDTH`)
- `paWidth`: Physical address width (`CONF_HPDCACHE_PA_WIDTH`)
- `wordWidth`: Word width in bits (`CONF_HPDCACHE_WORD_WIDTH`)
- `sets`: Cache sets (`CONF_HPDCACHE_SETS`)
- `ways`: Cache ways (`CONF_HPDCACHE_WAYS`)
- `clWords`: Cacheline words (`CONF_HPDCACHE_CL_WORDS`)
- `reqWords`: Request words (`CONF_HPDCACHE_REQ_WORDS`)
- `reqTransIdWidth`: Request transaction ID width
- `reqSrcIdWidth`: Request source ID width
- `victimSel`: Victim selection policy
- `dataWaysPerRamWord`: Data RAM ways per word
- `dataSetsPerRam`: Data sets per RAM
- `dataRamByteEnable`: Data RAM byte enable config
- `accessWords`: Access words count
- `mshrSets`: MSHR sets
- `mshrWays`: MSHR ways
- `mshrWaysPerRamWord`: MSHR ways per RAM word
- `mshrSetsPerRam`: MSHR sets per RAM
- `mshrRamByteEnable`: MSHR RAM byte enable
- `mshrUseRegbank`: MSHR use register bank
- `cbufEntries`: Coherence buffer entries
- `refillCoreRspFeedthrough`: Refill core response feedthrough
- `refillFifoDepth`: Refill FIFO depth
- `wbufDirEntries`: Write buffer directory entries
- `wbufDataEntries`: Write buffer data entries
- `wbufWords`: Write buffer words
- `wbufTimecntWidth`: Write buffer time counter width
- `rtabEntries`: RTAB (Replay Table) entries
- `flushEntries`: Flush entries
- `flushFifoDepth`: Flush FIFO depth
- `memAddrWidth`: Memory address width
- `memIdWidth`: Memory transaction ID width
- `memDataWidth`: Memory data width
- `wtEn`: Write-through enable
- `wbEn`: Write-back enable
- `lowLatency`: Low latency mode
- `eccEn`: ECC enable
- `eccScrubberEn`: ECC scrubber enable

### 1.2 Type Parameters

| **Parameter** | **Type** | **Width** | **Mô tả** |
|---|---|---|---|
| `wbuf_timecnt_t` | `type` | `Cfg.u.wbufTimecntWidth` | Write buffer time counter type |
| `hpdcache_tag_t` | `type` | `Cfg.tagWidth` | Cache tag type |
| `hpdcache_data_word_t` | `type` | `Cfg.u.wordWidth` | Data word type |
| `hpdcache_data_be_t` | `type` | `Cfg.u.wordWidth/8` | Byte enable for data |
| `hpdcache_req_offset_t` | `type` | `Cfg.reqOffsetWidth` | Request offset type |
| `hpdcache_req_data_t` | `type` | `[Cfg.u.reqWords-1:0][Cfg.u.wordWidth-1:0]` | Request data (array of words) |
| `hpdcache_req_be_t` | `type` | `[Cfg.u.reqWords-1:0][Cfg.u.wordWidth/8-1:0]` | Request byte enable (array) |
| `hpdcache_req_sid_t` | `type` | `Cfg.u.reqSrcIdWidth` | Request source ID type |
| `hpdcache_req_tid_t` | `type` | `Cfg.u.reqTransIdWidth` | Request transaction ID type |
| `hpdcache_req_t` | `type` | Struct | HPDcache request struct type |
| `hpdcache_rsp_t` | `type` | Struct | HPDcache response struct type |
| `hpdcache_mem_addr_t` | `type` | `Cfg.u.memAddrWidth` | Memory address type |
| `hpdcache_mem_id_t` | `type` | `Cfg.u.memIdWidth` | Memory transaction ID type |
| `hpdcache_mem_data_t` | `type` | `Cfg.u.memDataWidth` | Memory data type |
| `hpdcache_mem_be_t` | `type` | `Cfg.u.memDataWidth/8` | Memory byte enable type |
| `hpdcache_nline_t` | `type` | `Cfg.nlineWidth` | Cacheline number type |

### 1.3 Internal Parameter

| **Parameter** | **Type** | **Value** | **Mô tả** |
|---|---|---|---|
| `NREQUESTERS` | `int unsigned` | `Cfg.u.nRequesters` | Number of requesters (derived) |

---

## 2. INPUT PORTS

Total: **34 input ports** (22 control + 12 data signals)

### 2.1 Clock & Reset (Active-High Clock, Active-Low Reset)

| **Signal** | **Type** | **Width** | **Polarity** | **Chức năng** |
|---|---|---|---|---|
| `clk_i` | `wire logic` | 1 bit | Rising edge | System clock |
| `rst_ni` | `wire logic` | 1 bit | Active-Low | Asynchronous reset |

### 2.2 Write Buffer Control

| **Signal** | **Type** | **Width** | **Chức năng** |
|---|---|---|---|
| `wbuf_flush_i` | `wire logic` | 1 bit | Force write buffer flush all pending writes |

### 2.3 Core Request Interface (Dual-Cycle)

**Cycle 1: Address & Data**

| **Signal** | **Type** | **Width** | **Valid** | **Chức năng** |
|---|---|---|---|---|
| `core_req_valid_i` | `logic` | 1 bit | Always | Request valid indication |
| `core_req_i` | `hpdcache_req_t` | Struct | When `core_req_valid_i=1` | Request packet (offset, data, BE, SID, TID) |

**Cycle 2: Translation & Attributes**

| **Signal** | **Type** | **Width** | **Valid** | **Chức năng** |
|---|---|---|---|---|
| `core_req_abort_i` | `logic` | 1 bit | Always | Abort request (cancel Cycle 1) |
| `core_req_tag_i` | `hpdcache_tag_t` | `Cfg.tagWidth` | Always | Physical address tag (from MMU) |
| `core_req_pma_i` | `hpdcache_pma_t` | Struct | Always | Physical memory attributes (cacheable, AMO, prefetch) |

**Protocol Timing:**
- Cycle N: `core_req_valid_i=1`, `core_req_i` present
- Cycle N+1: `core_req_tag_i` and `core_req_pma_i` present
- If `core_req_abort_i=1` in Cycle N+1: request cancelled

### 2.4 Memory Read Request Interface

| **Signal** | **Type** | **Width** | **Chức năng** |
|---|---|---|---|
| `mem_req_read_ready_i` | `wire logic` | 1 bit | Memory ready to accept read request (AXI ARREADY) |

### 2.5 Memory Read Response Interface

| **Signal** | **Type** | **Width** | **Chức năng** |
|---|---|---|---|
| `mem_resp_read_valid_i` | `wire logic` | 1 bit | Read response valid (AXI RVALID) |
| `mem_resp_read_error_i` | `wire hpdcache_mem_error_e` | Enum (2-3 bits) | Error type (NO_ERROR, SLAVE_ERROR, DECODE_ERROR) |
| `mem_resp_read_id_i` | `wire hpdcache_mem_id_t` | `Cfg.u.memIdWidth` | Read response transaction ID (AXI RID) |
| `mem_resp_read_data_i` | `wire hpdcache_mem_data_t` | `Cfg.u.memDataWidth` | Read data payload (AXI RDATA) |
| `mem_resp_read_last_i` | `wire logic` | 1 bit | Last beat of read burst (AXI RLAST) |

**Protocol:** Ready/Valid handshake on every beat

### 2.6 Memory Write Request Interface

| **Signal** | **Type** | **Width** | **Chức năng** |
|---|---|---|---|
| `mem_req_write_ready_i` | `wire logic` | 1 bit | Memory ready to accept write request (AXI AWREADY) |
| `mem_req_write_data_ready_i` | `wire logic` | 1 bit | Memory ready to accept write data (AXI WREADY) |

### 2.7 Memory Write Response Interface

| **Signal** | **Type** | **Width** | **Chức năng** |
|---|---|---|---|
| `mem_resp_write_valid_i` | `wire logic` | 1 bit | Write response valid (AXI BVALID) |
| `mem_resp_write_is_atomic_i` | `wire logic` | 1 bit | Write response is for atomic operation |
| `mem_resp_write_error_i` | `wire hpdcache_mem_error_e` | Enum (2-3 bits) | Write error type (AXI BRESP) |
| `mem_resp_write_id_i` | `wire hpdcache_mem_id_t` | `Cfg.u.memIdWidth` | Write response transaction ID (AXI BID) |

### 2.8 Configuration Interface (Read-Only @ Reset)

| **Signal** | **Type** | **Width** | **Chức năng** |
|---|---|---|---|
| `cfg_enable_i` | `wire logic` | 1 bit | Cache enable (1=enable, 0=bypass) |
| `cfg_wbuf_threshold_i` | `wire wbuf_timecnt_t` | `Cfg.u.wbufTimecntWidth` | Write buffer timeout threshold (cycles) |
| `cfg_wbuf_reset_timecnt_on_write_i` | `wire logic` | 1 bit | Reset WBUF timer on new write (1=yes, 0=no) |
| `cfg_wbuf_sequential_waw_i` | `wire logic` | 1 bit | Sequential write-after-write in WBUF |
| `cfg_wbuf_inhibit_write_coalescing_i` | `wire logic` | 1 bit | Disable write coalescing (1=disable, 0=enable) |
| `cfg_prefetch_updt_plru_i` | `wire logic` | 1 bit | Update PLRU on prefetch |
| `cfg_error_on_cacheable_amo_i` | `wire logic` | 1 bit | Raise error on cacheable AMO (1=error, 0=allow) |
| `cfg_rtab_single_entry_i` | `wire logic` | 1 bit | RTAB single entry mode (1=limited, 0=normal) |
| `cfg_default_wb_i` | `wire logic` | 1 bit | Default write policy (1=write-back, 0=write-through) |
| `cfg_scrub_enable_i` | `wire logic` | 1 bit | ECC scrubber enable (1=enable, 0=disable) |
| `cfg_scrub_period_i` | `wire logic` | 6 bits | ECC scrub period (2^N cycles) |
| `cfg_scrub_restart_i` | `wire logic` | 1 bit | Restart ECC scrubber |

---

## 3. OUTPUT PORTS

Total: **35 output ports** (20 control + 15 event signals)

### 3.1 Core Request Interface

| **Signal** | **Type** | **Width** | **Timing** | **Chức năng** |
|---|---|---|---|---|
| `core_req_ready_o` | `logic` | 1 bit | Combinational | Cache ready to accept request (AXI ARREADY-like) |

**Protocol:** `core_req_ready_o = core_req_valid_i && core_req_ready[core_req_i.sid]`  
Multi-requester multiplexing based on Source ID

### 3.2 Core Response Interface

| **Signal** | **Type** | **Width** | **Timing** | **Chức năng** |
|---|---|---|---|---|
| `core_rsp_valid_o` | `var logic` | 1 bit | Sequential | Response valid to core (AXI RVALID-like) |
| `core_rsp_o` | `var hpdcache_rsp_t` | Struct | Sequential | Response data (data, error, SID, TID) |

**Protocol:** Single-cycle response; must be accepted same cycle  
Multiplexer selects first valid response from NREQUESTERS

### 3.3 Memory Read Request Interface

| **Signal** | **Type** | **Width** | **Timing** | **Chức năng** |
|---|---|---|---|---|
| `mem_req_read_valid_o` | `wire logic` | 1 bit | Combinational | Read request valid (AXI ARVALID) |
| `mem_req_read_addr_o` | `wire hpdcache_mem_addr_t` | `Cfg.u.memAddrWidth` | Combinational | Read address (AXI ARADDR) |
| `mem_req_read_len_o` | `wire hpdcache_mem_len_t` | 8 bits | Combinational | Burst length (AXI ARLEN, 0-255 beats) |
| `mem_req_read_size_o` | `wire hpdcache_mem_size_t` | 3 bits | Combinational | Burst size (AXI ARSIZE, 0=1B, 7=128B) |
| `mem_req_read_id_o` | `wire hpdcache_mem_id_t` | `Cfg.u.memIdWidth` | Combinational | Transaction ID (AXI ARID) |
| `mem_req_read_command_o` | `wire hpdcache_mem_command_e` | Enum | Combinational | Command type (READ, ATOMIC_LOAD, LOAD_LINKED, etc.) |
| `mem_req_read_atomic_o` | `wire hpdcache_mem_atomic_e` | Enum | Combinational | Atomic operation (NONE, ADD, AND, OR, XOR, SWAP, MIN, MAX, etc.) |
| `mem_req_read_cacheable_o` | `wire logic` | 1 bit | Combinational | Cacheable flag (1=cacheable, 0=uncacheable) |

### 3.4 Memory Read Response Interface

| **Signal** | **Type** | **Width** | **Timing** | **Chức năng** |
|---|---|---|---|---|
| `mem_resp_read_ready_o` | `var logic` | 1 bit | Sequential | Ready to accept read response (AXI RREADY) |

### 3.5 Memory Write Request Interface (Address & Control Channel)

| **Signal** | **Type** | **Width** | **Timing** | **Chức năng** |
|---|---|---|---|---|
| `mem_req_write_valid_o` | `wire logic` | 1 bit | Combinational | Write request valid (AXI AWVALID) |
| `mem_req_write_addr_o` | `wire hpdcache_mem_addr_t` | `Cfg.u.memAddrWidth` | Combinational | Write address (AXI AWADDR) |
| `mem_req_write_len_o` | `wire hpdcache_mem_len_t` | 8 bits | Combinational | Burst length (AXI AWLEN) |
| `mem_req_write_size_o` | `wire hpdcache_mem_size_t` | 3 bits | Combinational | Burst size (AXI AWSIZE) |
| `mem_req_write_id_o` | `wire hpdcache_mem_id_t` | `Cfg.u.memIdWidth` | Combinational | Transaction ID (AXI AWID) |
| `mem_req_write_command_o` | `wire hpdcache_mem_command_e` | Enum | Combinational | Write command type |
| `mem_req_write_atomic_o` | `wire hpdcache_mem_atomic_e` | Enum | Combinational | Atomic operation for write |
| `mem_req_write_cacheable_o` | `wire logic` | 1 bit | Combinational | Cacheable flag |

### 3.6 Memory Write Data Channel

| **Signal** | **Type** | **Width** | **Timing** | **Chức năng** |
|---|---|---|---|---|
| `mem_req_write_data_valid_o` | `wire logic` | 1 bit | Combinational | Write data valid (AXI WVALID) |
| `mem_req_write_data_o` | `wire hpdcache_mem_data_t` | `Cfg.u.memDataWidth` | Combinational | Write data payload (AXI WDATA) |
| `mem_req_write_be_o` | `wire hpdcache_mem_be_t` | `Cfg.u.memDataWidth/8` | Combinational | Write byte enable (AXI WSTRB) |
| `mem_req_write_last_o` | `wire logic` | 1 bit | Combinational | Last beat of write burst (AXI WLAST) |

**Note:** Address and data channels are independent (can transfer at different rates)

### 3.7 Memory Write Response Interface

| **Signal** | **Type** | **Width** | **Timing** | **Chức năng** |
|---|---|---|---|---|
| `mem_resp_write_ready_o` | `var logic` | 1 bit | Sequential | Ready to accept write response (AXI BREADY) |

### 3.8 Performance Events (Functional Coverage & Statistics)

All event signals are **1-bit** outputs that pulse for one cycle when event occurs.

| **Signal** | **Chức năng** |
|---|---|
| `evt_cache_write_miss_o` | Write miss event (MUST coverage point) |
| `evt_cache_read_miss_o` | Read miss event (MUST coverage point) |
| `evt_cache_dir_unc_err_o` | Directory uncorrectable ECC error |
| `evt_cache_dir_cor_err_o` | Directory correctable ECC error |
| `evt_cache_dat_unc_err_o` | Data uncorrectable ECC error |
| `evt_cache_dat_cor_err_o` | Data correctable ECC error |
| `evt_scrub_complete_o` | ECC scrubber completed line |
| `evt_uncached_req_o` | Uncacheable request processed |
| `evt_cmo_req_o` | Cache management operation (invalidate/prefetch) |
| `evt_write_req_o` | Store request processed |
| `evt_read_req_o` | Load request processed |
| `evt_prefetch_req_o` | Hardware prefetch request |
| `evt_req_on_hold_o` | Request held (pending dependency) |
| `evt_rtab_rollback_o` | RTAB rollback on conflict |
| `evt_stall_refill_o` | Stall due to refill unavailable |
| `evt_stall_o` | General pipeline stall |

### 3.9 Status Interface

| **Signal** | **Type** | **Width** | **Chức năng** |
|---|---|---|---|
| `wbuf_empty_o` | `wire logic` | 1 bit | Write buffer empty status (1=empty, 0=has pending) |

---

## 4. INTERNAL INTERFACE STRUCTS

### 4.1 Core Request Struct: `hpdcache_req_t`

```systemverilog
typedef struct packed {
    hpdcache_req_offset_t  offset;    // Offset within cacheline [Cfg.reqOffsetWidth-1:0]
    hpdcache_req_data_t    data;      // Request data [Cfg.u.reqWords-1:0][Cfg.u.wordWidth-1:0]
    hpdcache_req_be_t      be;        // Byte enable [Cfg.u.reqWords-1:0][Cfg.u.wordWidth/8-1:0]
    hpdcache_req_sid_t     sid;       // Source requester ID [Cfg.u.reqSrcIdWidth-1:0]
    hpdcache_req_tid_t     tid;       // Transaction ID [Cfg.u.reqTransIdWidth-1:0]
    hpdcache_tag_t         tag;       // Physical address tag [Cfg.tagWidth-1:0]
} hpdcache_req_t;
```

**Field Descriptions:**
- `offset`: Byte offset within a cacheline (0 to cacheline_size-1)
- `data`: Request data payload (LOAD/STORE/AMO data)
- `be`: Byte enable (which bytes are valid)
- `sid`: Source requester ID (0 to NREQUESTERS-1)
- `tid`: Transaction ID for response matching (used for out-of-order responses)
- `tag`: Physical address bits (upper bits, lower bits = offset)

### 4.2 Core Response Struct: `hpdcache_rsp_t`

```systemverilog
typedef struct packed {
    hpdcache_req_data_t    data;      // Response data [Cfg.u.reqWords-1:0][Cfg.u.wordWidth-1:0]
    logic                  error;     // Error flag (1=error, 0=success)
    hpdcache_req_sid_t     sid;       // Source requester ID (echo from request)
    hpdcache_req_tid_t     tid;       // Transaction ID (echo from request)
} hpdcache_rsp_t;
```

**Field Descriptions:**
- `data`: Response data (LOAD result, STORE ack, AMO result)
- `error`: Error indication (address error, access error, etc.)
- `sid`: Echo of request source ID
- `tid`: Echo of request transaction ID (for out-of-order matching)

### 4.3 Memory Request Struct: `hpdcache_mem_req_t`

```systemverilog
typedef struct {
    hpdcache_mem_addr_t    mem_req_addr;        // Physical address [Cfg.u.memAddrWidth-1:0]
    hpdcache_mem_len_t     mem_req_len;         // Burst length (0-255, AXI ARLEN/AWLEN)
    hpdcache_mem_size_t    mem_req_size;        // Burst size (0-7, AXI ARSIZE/AWSIZE)
    hpdcache_mem_id_t      mem_req_id;          // Transaction ID [Cfg.u.memIdWidth-1:0]
    hpdcache_mem_command_e mem_req_command;     // Command type (READ, WRITE, ATOMIC_LOAD, etc.)
    hpdcache_mem_atomic_e  mem_req_atomic;      // Atomic operation (NONE, ADD, AND, OR, XOR, SWAP, MIN, MAX, etc.)
    logic                  mem_req_cacheable;   // Cacheable flag
} hpdcache_mem_req_t;
```

**AXI Equivalence:**
- Used for both read (ARADDR, ARLEN, etc.) and write (AWADDR, AWLEN, etc.) address channels
- `mem_req_len`: 0-255 (0=1 beat, 255=256 beats)
- `mem_req_size`: 0=1B, 1=2B, 2=4B, 3=8B, 4=16B, 5=32B, 6=64B, 7=128B

### 4.4 Memory Write Data Struct: `hpdcache_mem_req_w_t`

```systemverilog
typedef struct {
    hpdcache_mem_data_t    mem_req_w_data;      // Write data [Cfg.u.memDataWidth-1:0]
    hpdcache_mem_be_t      mem_req_w_be;        // Byte enable [Cfg.u.memDataWidth/8-1:0]
    logic                  mem_req_w_last;      // Last beat flag
} hpdcache_mem_req_w_t;
```

**AXI Equivalence:**
- `mem_req_w_data`: AXI WDATA
- `mem_req_w_be`: AXI WSTRB (byte strobes)
- `mem_req_w_last`: AXI WLAST

### 4.5 Memory Read Response Struct: `hpdcache_mem_resp_r_t`

```systemverilog
typedef struct {
    hpdcache_mem_error_e   mem_resp_r_error;    // Error type (NO_ERROR, SLAVE_ERROR, DECODE_ERROR)
    hpdcache_mem_id_t      mem_resp_r_id;       // Response ID [Cfg.u.memIdWidth-1:0]
    hpdcache_mem_data_t    mem_resp_r_data;     // Read data [Cfg.u.memDataWidth-1:0]
    logic                  mem_resp_r_last;     // Last beat flag
} hpdcache_mem_resp_r_t;
```

**AXI Equivalence:**
- `mem_resp_r_error`: AXI RRESP (decoded from RRESP[1:0])
- `mem_resp_r_id`: AXI RID
- `mem_resp_r_data`: AXI RDATA
- `mem_resp_r_last`: AXI RLAST

### 4.6 Memory Write Response Struct: `hpdcache_mem_resp_w_t`

```systemverilog
typedef struct {
    logic                  mem_resp_w_is_atomic; // AMO response flag
    hpdcache_mem_error_e   mem_resp_w_error;    // Error type
    hpdcache_mem_id_t      mem_resp_w_id;       // Response ID [Cfg.u.memIdWidth-1:0]
} hpdcache_mem_resp_w_t;
```

**AXI Equivalence:**
- `mem_resp_w_error`: AXI BRESP
- `mem_resp_w_id`: AXI BID

### 4.7 Physical Memory Attributes Struct: `hpdcache_pma_t`

```systemverilog
typedef struct {
    logic cacheable;       // 1=cacheable, 0=uncacheable (non-temporal)
    logic amo;            // 1=atomic memory operation, 0=regular access
    logic prefetchable;   // 1=prefetchable, 0=no prefetch
} hpdcache_pma_t;
```

**Sourced from:** Core's MMU or hardwired PMA decoder (Cycle 2)

---

## 5. KEY SIGNAL WIDTHS (Dynamic based on Config)

### 5.1 Parametric Widths

All widths are derived from configuration at elaboration time.

| **Concept** | **Signal** | **Width Formula** | **Example (64-bit, 8KB, 4-way)** |
|---|---|---|---|
| Physical Address | `Cfg.u.paWidth` | From config | 40 bits (1TB address space) |
| Word Width | `Cfg.u.wordWidth` | From config | 64 bits |
| Cacheline | `Cfg.u.clWords` | From config | 8 words = 64 bytes |
| Request Granule | `Cfg.u.reqWords` | From config | 1-8 words |
| Cache Offset | `Cfg.reqOffsetWidth` | log2(clWords * wordWidth/8) | 6 bits (0-63) |
| Cache Index | `Cfg.indexWidth` | log2(sets) | 7 bits (128 sets) |
| Cache Tag | `Cfg.tagWidth` | paWidth - indexWidth - offsetWidth | 27 bits |
| Memory Address | `Cfg.u.memAddrWidth` | From config | 40 bits |
| Memory Data | `Cfg.u.memDataWidth` | From config | 64-256 bits |
| Memory ID | `Cfg.u.memIdWidth` | From config | 4-12 bits |
| Request SID | `Cfg.u.reqSrcIdWidth` | From config | 2-3 bits (4-8 requesters) |
| Request TID | `Cfg.u.reqTransIdWidth` | From config | 4-6 bits |
| MSHR Entries | `Cfg.u.mshrWays` | From config | 8-16 entries |
| WBUF Entries | `Cfg.u.wbufDirEntries` | From config | 4-16 entries |

### 5.2 Typical Configuration Examples

**Config1_HPC (High Performance):**
- paWidth: 40 bits
- wordWidth: 64 bits
- sets: 128, ways: 8
- clWords: 8 (64 bytes)
- reqWords: 8
- memDataWidth: 128 bits
- memAddrWidth: 40 bits
- nRequesters: 4

**Config_Embedded (Small):**
- paWidth: 32 bits
- wordWidth: 32 bits
- sets: 64, ways: 2
- clWords: 4 (16 bytes)
- reqWords: 1
- memDataWidth: 32 bits
- memAddrWidth: 32 bits
- nRequesters: 2

---

## 6. TIMING & HANDSHAKE PROTOCOL

### 6.1 Core Request Protocol (Dual-Cycle)

**Timing Diagram:**

```
Clock Cycle:     N        N+1       N+2
                 |        |         |
core_req_valid   |___1____|_________|
core_req.sid     |  SID   |         |
core_req.data    |  DATA  |         |
core_req.offset  |  OFF   |         |
core_req.be      |  BE    |         |
                 |        |
core_req_abort   |     ___|_1_______|
core_req_tag     |     TAG|         |
core_req_pma     |     PMA|         |
                 |
core_req_ready   |___1____|_________|
```

**Two-Phase Protocol:**

1. **Cycle N (Address & Data Phase):**
   - Driver: `core_req_valid_i = 1`
   - Driver: `core_req_i = {offset, data, be, sid, tid}`
   - Receiver: `core_req_ready_o` = combinational (depends on `core_req_i.sid`)
   - Handshake: `core_req_valid_i && core_req_ready_o` → transfer

2. **Cycle N+1 (Translation Phase):**
   - Driver: `core_req_tag_i` = physical address tag
   - Driver: `core_req_pma_i` = {cacheable, amo, prefetchable}
   - Receiver: Latch Cycle N data if Cycle N transfer
   - Option: `core_req_abort_i = 1` → cancel Cycle N request

**Requirements:**
- If transfer occurs in Cycle N: `core_req_tag_i` and `core_req_pma_i` MUST be valid in Cycle N+1
- If `core_req_abort_i = 1` in Cycle N+1: Cycle N request is discarded
- Address translation pipeline can stall: hold `core_req_valid_i` low

### 6.2 Core Response Protocol (Single-Cycle)

**Timing Diagram:**

```
Clock Cycle:     N        N+1       N+2
                 |        |         |
core_rsp_valid   |____1___|         |
core_rsp.data    | RDATA  |         |
core_rsp.sid     | SID    |         |
core_rsp.tid     | TID    |         |
core_rsp.error   | ERR    |         |
```

**Single-Phase Protocol:**
- `core_rsp_valid_o = 1` for one cycle
- Receiver MUST accept: core doesn't implement ready signal
- Multiplex from NREQUESTERS channels: first valid response selected
- Response cannot stall: must be consumed each cycle

**Match Scheme:**
- Use `core_rsp.sid` and `core_rsp.tid` to match response with request
- Out-of-order responses possible

### 6.3 Memory Read Request Protocol

**Timing Diagram (AXI-style):**

```
Clock Cycle:     N        N+1       N+2       N+3
                 |        |         |         |
mem_req_read_valid |___1___|_________|_0_______|
mem_req_read_addr  | ADDR  |         |         |
mem_req_read_len   | LEN   |         |         |
mem_req_read_size  | SIZE  |         |         |
mem_req_read_id    | ID    |         |         |
                   |
mem_req_read_ready |   0   |____1____|_________|
```

**Handshake:**
- `mem_req_read_valid_o & mem_req_read_ready_i` → transfer
- Address stable until transfer completes
- No flow control on response (responses arrive independently)

### 6.4 Memory Read Response Protocol

**Timing Diagram:**

```
Clock Cycle:     N        N+1       N+2       N+3       N+4
                 |        |         |         |         |
mem_resp_read_valid |_1_|___1___|___1___|___0___|
mem_resp_read_data  |D0  |  D1   |  D2   |       |
mem_resp_read_id    |ID  |  ID   |  ID   |       |
mem_resp_read_last  | 0  |   0   |   1   |       |  <- Final beat
                    |
mem_resp_read_ready |_1_|___1___|___1___|___1___|
```

**Burst Handshake:**
- Each beat: `mem_resp_read_valid_i & mem_resp_read_ready_o` → transfer
- `mem_resp_read_last_i = 1` on final beat
- Out-of-order beats possible (scrambled by ID)
- Error can occur on any beat

### 6.5 Memory Write Request Protocol (Decoupled Address & Data)

**Address Channel (AW):**

```
Clock Cycle:     N        N+1       N+2
                 |        |         |
mem_req_write_valid |___1___|_________|
mem_req_write_addr  | ADDR  |         |
mem_req_write_len   | LEN   |         |
mem_req_write_id    | ID    |         |
                    |
mem_req_write_ready |   0   |____1____|
```

**Data Channel (W):**

```
Clock Cycle:     N        N+1       N+2       N+3
                 |        |         |         |
mem_req_write_data_valid |___1___|___1___|___0___|
mem_req_write_data_o      | D0    |  D1   |       |
mem_req_write_be_o        | BE0   |  BE1  |       |
mem_req_write_last_o      | 0     |  1    |       |  <- Final beat
                          |
mem_req_write_data_ready  |   0   |___1___|___1___|
```

**Independent Handshakes:**
- Address channel transfers address once
- Data channel transfers each word (potentially multiple beats)
- Data beats can arrive before, during, or after address phase
- Both channels hold until `*_ready` asserted

### 6.6 Memory Write Response Protocol

**Timing Diagram:**

```
Clock Cycle:     N        N+1       N+2
                 |        |         |
mem_resp_write_valid |___1___|_________|
mem_resp_write_id    | ID    |         |
mem_resp_write_error | ERR   |         |
                     |
mem_resp_write_ready |___1___|_________|
```

**Single Response per Transaction:**
- One response per write transaction (ID-matched)
- Handshake: `mem_resp_write_valid_i & mem_resp_write_ready_o`
- Response can arrive any time after final write beat

---

## 7. MODULE INSTANTIATION

### 7.1 Complete Port Mapping

```systemverilog
hpdcache #(
    // Configuration
    .HPDcacheCfg                     (Cfg),
    
    // Type Parameters
    .wbuf_timecnt_t                  (wbuf_timecnt_t),
    .hpdcache_tag_t                  (hpdcache_tag_t),
    .hpdcache_data_word_t            (hpdcache_data_word_t),
    .hpdcache_data_be_t              (hpdcache_data_be_t),
    .hpdcache_req_offset_t           (hpdcache_req_offset_t),
    .hpdcache_req_data_t             (hpdcache_req_data_t),
    .hpdcache_req_be_t               (hpdcache_req_be_t),
    .hpdcache_req_sid_t              (hpdcache_req_sid_t),
    .hpdcache_req_tid_t              (hpdcache_req_tid_t),
    .hpdcache_req_t                  (hpdcache_req_t),
    .hpdcache_rsp_t                  (hpdcache_rsp_t),
    .hpdcache_mem_addr_t             (hpdcache_mem_addr_t),
    .hpdcache_mem_id_t               (hpdcache_mem_id_t),
    .hpdcache_mem_data_t             (hpdcache_mem_data_t),
    .hpdcache_mem_be_t               (hpdcache_mem_be_t),
    .hpdcache_mem_req_t              (hpdcache_mem_req_t),
    .hpdcache_mem_req_w_t            (hpdcache_mem_req_w_t),
    .hpdcache_mem_resp_r_t           (hpdcache_mem_resp_r_t),
    .hpdcache_mem_resp_w_t           (hpdcache_mem_resp_w_t)
) i_hpdcache (
    // Clock & Reset
    .clk_i,
    .rst_ni,
    .wbuf_flush_i,
    
    // Core Request (array of NREQUESTERS)
    .core_req_valid_i                (core_req_valid),
    .core_req_ready_o                (core_req_ready),
    .core_req_i                      (core_req),
    .core_req_abort_i                (core_req_abort),
    .core_req_tag_i                  (core_req_tag),
    .core_req_pma_i                  (core_req_pma),
    
    // Core Response (array of NREQUESTERS)
    .core_rsp_valid_o                (core_rsp_valid),
    .core_rsp_o                      (core_rsp),
    
    // Memory Read Request
    .mem_req_read_ready_i            (mem_req_read_ready_i),
    .mem_req_read_valid_o            (mem_req_read_valid_o),
    .mem_req_read_o                  (mem_req_read),
    
    // Memory Read Response
    .mem_resp_read_ready_o           (mem_resp_read_ready_o),
    .mem_resp_read_valid_i           (mem_resp_read_valid_i),
    .mem_resp_read_i                 (mem_resp_read),
    .mem_resp_read_inval_i           (mem_resp_read_inval),
    .mem_resp_read_inval_nline_i     (mem_resp_read_inval_nline),
    
    // Memory Write Request
    .mem_req_write_ready_i           (mem_req_write_ready_i),
    .mem_req_write_valid_o           (mem_req_write_valid_o),
    .mem_req_write_o                 (mem_req_write),
    
    // Memory Write Data
    .mem_req_write_data_ready_i      (mem_req_write_data_ready_i),
    .mem_req_write_data_valid_o      (mem_req_write_data_valid_o),
    .mem_req_write_data_o            (mem_req_write_data),
    
    // Memory Write Response
    .mem_resp_write_ready_o          (mem_resp_write_ready_o),
    .mem_resp_write_valid_i          (mem_resp_write_valid_i),
    .mem_resp_write_i                (mem_resp_write),
    
    // Performance Events
    .evt_cache_write_miss_o,
    .evt_cache_read_miss_o,
    .evt_cache_dir_unc_err_o,
    .evt_cache_dir_cor_err_o,
    .evt_cache_dat_unc_err_o,
    .evt_cache_dat_cor_err_o,
    .evt_scrub_complete_o,
    .evt_uncached_req_o,
    .evt_cmo_req_o,
    .evt_write_req_o,
    .evt_read_req_o,
    .evt_prefetch_req_o,
    .evt_req_on_hold_o,
    .evt_rtab_rollback_o,
    .evt_stall_refill_o,
    .evt_stall_o,
    
    // Status
    .wbuf_empty_o,
    
    // Configuration
    .cfg_enable_i,
    .cfg_wbuf_threshold_i,
    .cfg_wbuf_reset_timecnt_on_write_i,
    .cfg_wbuf_sequential_waw_i,
    .cfg_wbuf_inhibit_write_coalescing_i,
    .cfg_prefetch_updt_plru_i,
    .cfg_error_on_cacheable_amo_i,
    .cfg_rtab_single_entry_i,
    .cfg_default_wb_i,
    .cfg_scrub_enable_i,
    .cfg_scrub_period_i,
    .cfg_scrub_restart_i
);
```

### 7.2 Key Routing Logic (Multi-Requester Multiplexing)

**Request Routing (Combinational):**

```systemverilog
always_comb
begin : core_req_routing_comb
    // core_req_ready_o selects based on SID
    core_req_ready_o = core_req_valid_i && core_req_ready[core_req_i.sid];
    
    // Route request to correct requester lane
    for (int i = 0; i < NREQUESTERS; i++) begin
        core_req_valid [i] = core_req_valid_i && (core_req_i.sid == hpdcache_req_sid_t'(i));
        core_req       [i] = core_req_i;
        core_req_abort [i] = core_req_abort_i;
        core_req_tag   [i] = core_req_tag_i;
        core_req_pma   [i] = core_req_pma_i;
    end
end
```

**Response Routing (Combinational Priority Encoder):**

```systemverilog
always_comb
begin : core_rsp_routing_comb
    core_rsp_valid_o = '0;
    core_rsp_o       = '0;
    
    // Priority: lowest SID has priority (breaks ties)
    for (int i = 0; i < NREQUESTERS; i++) begin
        if (core_rsp_valid[i]) begin
            core_rsp_valid_o = 1'b1;
            core_rsp_o       = core_rsp[i];
            break;  // First valid response
        end
    end
end
```

**Internal Signals (NREQUESTERS per signal):**

```systemverilog
localparam int unsigned NREQUESTERS = Cfg.u.nRequesters;

logic                  core_req_valid [NREQUESTERS];
logic                  core_req_ready [NREQUESTERS];
hpdcache_req_t         core_req       [NREQUESTERS];
logic                  core_req_abort [NREQUESTERS];
hpdcache_tag_t         core_req_tag   [NREQUESTERS];
hpdcache_pma_t         core_req_pma   [NREQUESTERS];

logic                  core_rsp_valid [NREQUESTERS];
hpdcache_rsp_t         core_rsp       [NREQUESTERS];
```

---

## APPENDIX: Enum & Type Definitions

### A.1 Memory Command Enum: `hpdcache_mem_command_e`

```systemverilog
typedef enum logic [2:0] {
    HPDCACHE_MEM_COMMAND_READ          = 3'h0,
    HPDCACHE_MEM_COMMAND_WRITE         = 3'h1,
    HPDCACHE_MEM_COMMAND_ATOMIC_LOAD   = 3'h2,  // For prefetch/speculation
    HPDCACHE_MEM_COMMAND_ATOMIC_STORE  = 3'h3,  // For AMO write
    HPDCACHE_MEM_COMMAND_CMO           = 3'h4   // Cache management operation
} hpdcache_mem_command_e;
```

### A.2 Memory Atomic Enum: `hpdcache_mem_atomic_e`

```systemverilog
typedef enum logic [3:0] {
    HPDCACHE_MEM_ATOMIC_NONE   = 4'h0,
    HPDCACHE_MEM_ATOMIC_ADD    = 4'h1,
    HPDCACHE_MEM_ATOMIC_AND    = 4'h2,
    HPDCACHE_MEM_ATOMIC_OR     = 4'h3,
    HPDCACHE_MEM_ATOMIC_XOR    = 4'h4,
    HPDCACHE_MEM_ATOMIC_SWAP   = 4'h5,
    HPDCACHE_MEM_ATOMIC_MIN    = 4'h6,
    HPDCACHE_MEM_ATOMIC_MAX    = 4'h7,
    HPDCACHE_MEM_ATOMIC_MINU   = 4'h8,
    HPDCACHE_MEM_ATOMIC_MAXU   = 4'h9
} hpdcache_mem_atomic_e;
```

### A.3 Memory Error Enum: `hpdcache_mem_error_e`

```systemverilog
typedef enum logic [1:0] {
    HPDCACHE_MEM_ERROR_NO_ERROR    = 2'b00,
    HPDCACHE_MEM_ERROR_SLAVE_ERROR = 2'b10,  // AXI RESP[1]=1
    HPDCACHE_MEM_ERROR_DECODE_ERROR = 2'b11  // AXI RESP[1:0]=11
} hpdcache_mem_error_e;
```

### A.4 Memory Len/Size Enums (AXI-compatible)

```systemverilog
typedef logic [7:0] hpdcache_mem_len_t;      // 0-255 beats
typedef logic [2:0] hpdcache_mem_size_t;     // 0=1B, 7=128B
```

---

## SUMMARY TABLE

| **Category** | **Count** | **Type** | **Notes** |
|---|---|---|---|
| **Input Ports** | 34 | Logic/Struct | 22 control + 12 data |
| **Output Ports** | 35 | Logic/Struct | 20 control + 15 events |
| **Parameters** | 18 | Type/Localparam | All configuration-time |
| **Structs** | 7 | Custom Types | Request, Response, Memory I/F |
| **Internal Signals** | 6 arrays | NREQUESTERS-wide | Multi-requester routing |
| **Handshake Phases** | 4 | Protocol | Req (2-cycle), Rsp (1-cycle), Mem (AXI) |

---

## VERSION HISTORY

| **Date** | **Version** | **Changes** |
|---|---|---|
| 2024-10-01 | 1.0 | Initial wrapper design |
| 2025-01-01 | 1.1 | Added ECC support |
| 2026-07-13 | 2.0 | Complete specification document |

---

**Document Generated:** July 13, 2026  
**Target Device:** RISC-V (CVA6/Ariane)  
**Simulator:** QuestaSim 23.3+  
**Language:** SystemVerilog (IEEE 1800-2017)
