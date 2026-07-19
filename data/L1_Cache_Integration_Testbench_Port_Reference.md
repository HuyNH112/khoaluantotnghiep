# L1 Cache Integration Testbench - Complete Port Reference

**Document Date**: July 13, 2026  
**Target Simulation**: QuestaSim 23.3  
**Test Cases**: 15 (11 MUST, 4 SHOULD)  
**Configuration**: CVA6 + HPDCache + Domino Prefetcher + I-Cache

---

## **Table of Contents**

1. [Port Inventory (All Sources)](#port-inventory-all-sources)
2. [Port Verification Matrix](#port-verification-matrix)
3. [Port Dependencies by Test Case](#port-dependencies-by-test-case)
4. [UVM Testbench Port Declarations](#uvm-testbench-port-declarations)
5. [Waveform Signal List](#waveform-signal-list)
6. [Compile & Simulation Commands](#compile--simulation-commands)
7. [Coverage & Assertion Strategy](#coverage--assertion-strategy)

---

## **Port Inventory (All Sources)**

### **1. CLOCK & RESET (CVA6)**

| Signal | Source | Width | Direction | Type | Test Cases | Notes |
|--------|--------|-------|-----------|------|-----------|-------|
| `clk_i` | CVA6 | 1 | IN | logic | ALL (15/15) | Rising edge, main core clock |
| `rst_ni` | CVA6 | 1 | IN | logic | ALL (15/15) | Active-low, async reset |

**Verification Checklist**:
- [ ] Reset pulse: 5-10 cycles
- [ ] Clock runs post-reset
- [ ] All flip-flops initialized correctly
- [ ] No X on any signal post-reset

---

### **2. BOOT & CONFIG (CVA6)**

| Signal | Source | Width | Direction | Type | Test Cases | Notes |
|--------|--------|-------|-----------|------|-----------|-------|
| `boot_addr_i` | CVA6 | 64 | IN | logic[63:0] | TC-INT-01 | Boot PC (typically 0x80000000) |
| `hart_id_i` | CVA6 | 64 | IN | logic[63:0] | — | Hart ID (for multi-core, typically 0 for single) |

**Verification Checklist**:
- [ ] boot_addr_i set to 0x80000000
- [ ] First fetch_vaddr == boot_addr_i
- [ ] RVFI first PC == boot_addr_i

---

### **3. INTERRUPT & DEBUG (CVA6)**

| Signal | Source | Width | Direction | Type | Test Cases | Notes |
|--------|--------|-------|-----------|------|-----------|-------|
| `irq_i` | CVA6 | 2 | IN | logic[1:0] | — | External interrupts (NOT tested in TC) |
| `ipi_i` | CVA6 | 1 | IN | logic | — | Inter-processor interrupt |
| `time_irq_i` | CVA6 | 1 | IN | logic | — | Timer interrupt |
| `debug_req_i` | CVA6 | 1 | IN | logic | — | Debug request |

**Verification Checklist**:
- [ ] Keep all interrupt signals LOW (not tested)
- [ ] No spurious exceptions in RVFI

---

### **4. D-CACHE: CORE REQUEST (HPDcache)**

| Signal | Source | Width | Direction | Type | Test Cases | Notes |
|--------|--------|-------|-----------|------|-----------|-------|
| `core_req_valid_i` | HPDcache | 1 | IN | logic | TC-D-01, TC-D-02, TC-D-03, TC-D-04, TC-INT-02, TC-INT-03, TC-INT-04, TC-INT-05, TC-PF-01, TC-PF-02, TC-PF-03 | Request valid (LOAD/STORE from CPU) |
| `core_req_i` | HPDcache | struct | IN | `hpdcache_req_t` | (same as above) | Request packet: {offset, data, be, sid, tid} |
| `core_req_i.offset` | HPDcache | `Cfg.reqOffsetWidth` | IN | logic[...] | (same as above) | Address bits (part of cache line) |
| `core_req_i.data` | HPDcache | struct | IN | `hpdcache_req_data_t` | TC-D-01, TC-D-04, TC-INT-02, TC-INT-04, TC-PF-03 | Write data (for STORE) |
| `core_req_i.be` | HPDcache | struct | IN | `hpdcache_req_be_t` | TC-INT-02, TC-INT-04 | Byte enable (per-word) |
| `core_req_i.sid` | HPDcache | `Cfg.u.reqSrcIdWidth` | IN | logic[...] | TC-D-03 | Source ID (requester ID, typically 0) |
| `core_req_i.tid` | HPDcache | `Cfg.u.reqTransIdWidth` | IN | logic[...] | TC-D-03, TC-INT-02, TC-INT-04 | Transaction ID (for response matching) |

**Waveform Signals to Monitor**:
```
□ core_req_valid_i pulse timing
□ core_req_i.offset address bits
□ core_req_i.data for STORE operations
□ core_req_i.tid progression (for MSHR tests)
```

**Verification Checklist**:
- [ ] Valid pulse properly aligned with clock
- [ ] Data stable during valid_i HIGH
- [ ] No gaps in consecutive requests (if back-to-back)
- [ ] TID increments for multi-miss tests

---

### **5. D-CACHE: CORE REQUEST (Cycle 2) - MMU Interface**

| Signal | Source | Width | Direction | Type | Test Cases | Notes |
|--------|--------|-------|-----------|------|-----------|-------|
| `core_req_abort_i` | HPDcache | 1 | IN | logic | — | Abort Cycle 2 (cancel pending request) |
| `core_req_tag_i` | HPDcache | `Cfg.tagWidth` | IN | logic[...] | TC-D-01, TC-D-02, TC-D-03, TC-D-04, TC-INT-02, TC-INT-03, TC-INT-04, TC-INT-05 | Physical address tag from MMU |
| `core_req_pma_i` | HPDcache | struct | IN | `hpdcache_pma_t` | TC-D-01, TC-D-02, TC-INT-02 | Physical memory attributes (cacheable, AMO) |

**Protocol Timing** (HPDcache Dual-Cycle):
```
Cycle N:     core_req_valid_i=1 (Cycle 1: address & data)
Cycle N+1:   core_req_tag_i present (Cycle 2: translation & attributes)
             If core_req_abort_i=1: request cancelled
```

**Verification Checklist**:
- [ ] tag_i arrives exactly 1 cycle after core_req_valid_i
- [ ] pma_i.cacheable flag set correctly
- [ ] No abort_i during normal tests
- [ ] Tag & PMA fields stable during cycle

---

### **6. D-CACHE: CORE RESPONSE (HPDcache)**

| Signal | Source | Width | Direction | Type | Test Cases | Notes |
|--------|--------|-------|-----------|------|-----------|-------|
| `core_rsp_valid_o` | HPDcache | 1 | OUT | logic | TC-D-01, TC-D-02, TC-D-03, TC-D-04, TC-INT-02, TC-INT-03, TC-INT-04, TC-INT-05, TC-PF-01, TC-PF-03 | Response valid (data ready) |
| `core_rsp_o` | HPDcache | struct | OUT | `hpdcache_rsp_t` | (same as above) | Response packet: {data, status, ...} |
| `core_rsp_o.data` | HPDcache | struct | OUT | logic[...] | TC-D-01, TC-INT-02, TC-INT-04, TC-PF-03 | Read data (LOAD response) |
| `core_rsp_o.status` | HPDcache | logic[2:0] | OUT | logic[2:0] | — | Status flags (hit/miss, error) |

**Waveform Signals to Monitor**:
```
□ core_rsp_valid_o latency from core_req_valid_i
  - Hit: 1-2 cycles
  - Miss: N+refill cycles
□ core_rsp_o.data content
□ core_rsp_o.status for error detection
```

**Verification Checklist**:
- [ ] TC-D-01: Response valid within 2 cycles (hit)
- [ ] TC-D-02: Response valid after memory refill
- [ ] TC-INT-04: LOAD data matches prior STORE value
- [ ] No X on response data

---

### **7. D-CACHE: WRITE BUFFER**

| Signal | Source | Width | Direction | Type | Test Cases | Notes |
|--------|--------|-------|-----------|------|-----------|-------|
| `wbuf_flush_i` | HPDcache | 1 | IN | logic | — | Force flush all write buffer entries (optional) |

**Verification Checklist**:
- [ ] Keep LOW for most tests
- [ ] If needed: pulse HIGH for 1 cycle
- [ ] Verify all pending writes drain to AXI before flush completes

---

### **8. D-CACHE: MEMORY READ REQUEST (AXI AR)**

| Signal | Source | Width | Direction | Type | Test Cases | Notes |
|--------|--------|-------|-----------|------|-----------|-------|
| `mem_req_read_valid_o` | HPDcache | 1 | OUT | logic | TC-D-02, TC-D-03, TC-INT-02, TC-INT-03, TC-INT-05 | Read request valid (AXI AR trigger) |
| `mem_req_read_o` | HPDcache | struct | OUT | `hpdcache_mem_req_t` | (same as above) | Read request: {addr, tid, ...} |
| `mem_req_read_o.addr` | HPDcache | `Cfg.u.memAddrWidth` | OUT | logic[...] | TC-D-02, TC-D-03, TC-INT-02, TC-INT-03 | Physical address (cache-line aligned) |
| `mem_req_read_o.tid` | HPDcache | `Cfg.u.memIdWidth` | OUT | logic[...] | TC-D-03, TC-INT-02 | Transaction ID (for response matching) |
| `mem_req_read_ready_i` | HPDcache | 1 | IN | logic | TC-D-02, TC-D-03, TC-INT-02, TC-INT-03 | AXI ARREADY signal (slave ready) |

**Waveform Signals to Monitor**:
```
□ mem_req_read_valid_o pulse on cache miss
□ mem_req_read_o.addr alignment (cache-line boundary)
□ mem_req_read_o.tid uniqueness (MSHR tests)
□ Handshake: valid_o HIGH ↔ ready_i HIGH
```

**Verification Checklist**:
- [ ] TC-D-02: valid_o pulses 1+ cycle(s) on miss
- [ ] TC-D-03: 4 distinct valid_o pulses with 4 unique TIDs
- [ ] Address cache-line aligned (lower offset bits = 0)
- [ ] Handshake completes in 1 cycle (ready_i asserted)

---

### **9. D-CACHE: MEMORY READ RESPONSE (AXI R)**

| Signal | Source | Width | Direction | Type | Test Cases | Notes |
|--------|--------|-------|-----------|------|-----------|-------|
| `mem_rsp_read_valid_i` | HPDcache | 1 | IN | logic | TC-D-02, TC-D-03, TC-INT-02, TC-INT-03, TC-INT-05 | Read data valid (AXI RVALID) |
| `mem_rsp_read_i` | HPDcache | struct | IN | `hpdcache_mem_rsp_t` | (same as above) | Read response: {data, id, ...} |
| `mem_rsp_read_i.data` | HPDcache | `Cfg.u.memDataWidth` | IN | logic[...] | TC-D-02, TC-D-03, TC-INT-02, TC-INT-03 | Cache line data (from memory/simulator) |
| `mem_rsp_read_i.id` | HPDcache | `Cfg.u.memIdWidth` | IN | logic[...] | TC-D-03, TC-INT-02 | Transaction ID (matches request TID) |
| `mem_rsp_read_ready_o` | HPDcache | 1 | OUT | logic | — | AXI RREADY (cache always ready) |

**Waveform Signals to Monitor**:
```
□ mem_rsp_read_valid_i timing (after AR handshake)
□ mem_rsp_read_i.data content matches expected value
□ mem_rsp_read_i.id matches corresponding mem_req_read_o.tid
□ core_rsp_valid_o follows mem_rsp_read_valid_i
```

**Verification Checklist**:
- [ ] TC-D-02: Data arrives within 10-20 cycles (simulator latency)
- [ ] TC-D-03: 4 responses, IDs match 4 requests (out-of-order OK)
- [ ] TC-INT-02: Data value correct (matches test pattern)
- [ ] No X on data bits

---

### **10. D-CACHE: MEMORY WRITE REQUEST (AXI AW+W)**

| Signal | Source | Width | Direction | Type | Test Cases | Notes |
|--------|--------|-------|-----------|------|-----------|-------|
| `mem_req_write_valid_o` | HPDcache | 1 | OUT | logic | TC-D-04, TC-INT-02, TC-PF-03 | Write request valid (eviction/write-back) |
| `mem_req_write_o` | HPDcache | struct | OUT | `hpdcache_mem_req_t` | (same as above) | Write request: {addr, tid, ...} |
| `mem_req_write_o.addr` | HPDcache | `Cfg.u.memAddrWidth` | OUT | logic[...] | TC-D-04, TC-INT-02, TC-PF-03 | Dirty line address |
| `mem_req_write_data_o` | HPDcache | struct | OUT | logic[...] | TC-D-04, TC-INT-02, TC-PF-03 | Write payload (full cache line) |
| `mem_req_write_ready_i` | HPDcache | 1 | IN | logic | TC-D-04, TC-INT-02, TC-PF-03 | AXI AWREADY + WREADY signals |

**Waveform Signals to Monitor**:
```
□ mem_req_write_valid_o pulse (on eviction)
□ mem_req_write_o.addr (dirty line address)
□ mem_req_write_data_o content (stored values)
□ Handshake with mem_req_write_ready_i
□ CRITICAL: AW before AR (TC-D-04)
```

**Verification Checklist**:
- [ ] TC-D-04: write_valid HIGH before AR valid (write-back before refill)
- [ ] Address cache-line aligned
- [ ] Data matches stored values
- [ ] Write completes before new AR issued

---

### **11. D-CACHE: MEMORY WRITE RESPONSE (AXI B)**

| Signal | Source | Width | Direction | Type | Test Cases | Notes |
|--------|--------|-------|-----------|------|-----------|-------|
| `mem_rsp_write_valid_i` | HPDcache | 1 | IN | logic | TC-D-04, TC-INT-02, TC-PF-03 | Write response valid (AXI BVALID) |
| `mem_rsp_write_i` | HPDcache | struct | IN | `hpdcache_mem_rsp_t` | (same as above) | Write response: {id, resp, ...} |
| `mem_rsp_write_ready_o` | HPDcache | 1 | OUT | logic | — | AXI BREADY (cache always ready) |

**Verification Checklist**:
- [ ] Write response arrives after data accepted
- [ ] Response code = OKAY (no errors)
- [ ] Cache eviction completes and triggers refill AR

---

### **12. I-CACHE: DATA REQUEST (Pipeline)**

| Signal | Source | Width | Direction | Type | Test Cases | Notes |
|--------|--------|-------|-----------|------|-----------|-------|
| `dreq_i.req` | I-Cache | 1 | IN | logic | TC-I-01, TC-I-02, TC-I-03, TC-INT-01, TC-INT-05 | Fetch request from pipeline |
| `dreq_i.vaddr` | I-Cache | 64 | IN | logic[63:0] | TC-I-01, TC-I-02, TC-I-03, TC-INT-01, TC-INT-05 | Virtual address (32-bit aligned) |
| `dreq_i.kill_s1` | I-Cache | 1 | IN | logic | TC-I-03 | Kill during addr translation (flush) |
| `dreq_i.kill_s2` | I-Cache | 1 | IN | logic | TC-I-03 | Kill during cache lookup (flush) |
| `dreq_i.spec` | I-Cache | 1 | IN | logic | — | Speculative request flag |

**Waveform Signals to Monitor**:
```
□ dreq_i.req to dreq_o.valid latency (1-2 cycles for hit)
□ dreq_i.vaddr changes on branch
□ dreq_i.kill_s1 / kill_s2 during flush (TC-I-03)
□ Stable address during valid_i HIGH
```

**Verification Checklist**:
- [ ] TC-I-01: Fetch requests every cycle (no gaps)
- [ ] TC-I-02: Branch changes vaddr
- [ ] TC-I-03: Kill signals trigger cache invalidation
- [ ] No X on vaddr

---

### **13. I-CACHE: DATA RESPONSE (Pipeline)**

| Signal | Source | Width | Direction | Type | Test Cases | Notes |
|--------|--------|-------|-----------|------|-----------|-------|
| `dreq_o.ready` | I-Cache | 1 | OUT | logic | TC-I-01, TC-I-02, TC-I-03, TC-INT-01, TC-INT-05 | Cache ready for new request |
| `dreq_o.valid` | I-Cache | 1 | OUT | logic | TC-I-01, TC-I-02, TC-I-03, TC-INT-01, TC-INT-05 | Response valid (instruction available) |
| `dreq_o.data` | I-Cache | 32 | OUT | logic[31:0] | TC-I-01, TC-I-02, TC-I-03, TC-INT-01, TC-INT-05 | 32-bit instruction word |
| `dreq_o.user` | I-Cache | `FETCH_USER_WIDTH` | OUT | logic[...] | — | User bits (typically 0) |
| `dreq_o.vaddr` | I-Cache | 64 | OUT | logic[63:0] | — | Virtual address echo |
| `dreq_o.ex` | I-Cache | struct | OUT | `exception_t` | — | Exception (typically valid=0 for no exception) |

**Waveform Signals to Monitor**:
```
□ dreq_o.valid latency (hit: 1-2 cycles, miss: stalls)
□ dreq_o.data instruction bits
□ dreq_o.ready ready for next request
□ Hit: valid=1 every cycle
□ Miss: valid=0 until mem_rtrn_vld_i=1
```

**Verification Checklist**:
- [ ] TC-I-01: valid=1 every cycle (16 consecutive)
- [ ] TC-I-02: valid goes LOW on miss, resumes after refill
- [ ] TC-I-03: valid goes LOW during flush
- [ ] Data contains valid instructions

---

### **14. I-CACHE: ADDRESS TRANSLATION REQUEST (to TLB)**

| Signal | Source | Width | Direction | Type | Test Cases | Notes |
|--------|--------|-------|-----------|------|-----------|-------|
| `areq_o.fetch_req` | I-Cache | 1 | OUT | logic | TC-I-01, TC-I-02, TC-I-03, TC-INT-01, TC-INT-05 | TLB request (address translation needed) |
| `areq_o.fetch_vaddr` | I-Cache | 64 | OUT | logic[63:0] | TC-I-01, TC-I-02, TC-I-03, TC-INT-01, TC-INT-05 | Virtual address to TLB (32-bit aligned) |

**Verification Checklist**:
- [ ] fetch_req pulses when TLB lookup needed
- [ ] fetch_vaddr 32-bit aligned (lower 2 bits = 0)

---

### **15. I-CACHE: ADDRESS TRANSLATION RESPONSE (from TLB)**

| Signal | Source | Width | Direction | Type | Test Cases | Notes |
|--------|--------|-------|-----------|------|-----------|-------|
| `areq_i.fetch_valid` | I-Cache | 1 | IN | logic | TC-I-01, TC-I-02, TC-I-03, TC-INT-01, TC-INT-05 | TLB translation valid (paddr ready) |
| `areq_i.fetch_paddr` | I-Cache | 34 | IN | logic[33:0] | TC-I-01, TC-I-02, TC-I-03, TC-INT-01, TC-INT-05 | Physical address (34-bit) |
| `areq_i.fetch_exception.valid` | I-Cache | 1 | IN | logic | — | Exception valid (typically 0) |
| `areq_i.fetch_exception.tval` | I-Cache | 64 | IN | logic[63:0] | — | Exception trap value |
| `areq_i.fetch_exception.cause` | I-Cache | 64 | IN | logic[63:0] | — | Exception cause |

**Verification Checklist**:
- [ ] fetch_valid HIGH within 1-2 cycles of fetch_req
- [ ] fetch_paddr valid and cache-line aligned
- [ ] No exceptions (fetch_exception.valid = 0)

---

### **16. I-CACHE: MEMORY REQUEST**

| Signal | Source | Width | Direction | Type | Test Cases | Notes |
|--------|--------|-------|-----------|------|-----------|-------|
| `mem_data_req_o` | I-Cache | 1 | OUT | logic | TC-I-02, TC-INT-02, TC-INT-05 | Memory request valid (miss) |
| `mem_data_o` | I-Cache | struct | OUT | `icache_req_t` | TC-I-02, TC-INT-02, TC-INT-05 | Request packet: {paddr, tid, way, nc} |
| `mem_data_o.paddr` | I-Cache | 34 | OUT | logic[33:0] | TC-I-02, TC-INT-02, TC-INT-05 | Physical address (cache-line aligned) |
| `mem_data_o.tid` | I-Cache | `MEM_TID_WIDTH` | OUT | logic[...] | TC-I-02, TC-INT-02, TC-INT-05 | Transaction ID |
| `mem_data_o.way` | I-Cache | 2 | OUT | logic[1:0] | — | Replacement way (0-3) |
| `mem_data_o.nc` | I-Cache | 1 | OUT | logic | — | Non-cacheable flag (typically 0) |

**Verification Checklist**:
- [ ] mem_data_req_o pulses on I-Cache miss
- [ ] paddr cache-line aligned
- [ ] TID increments on multiple misses

---

### **17. I-CACHE: MEMORY RESPONSE**

| Signal | Source | Width | Direction | Type | Test Cases | Notes |
|--------|--------|-------|-----------|------|-----------|-------|
| `mem_rtrn_vld_i` | I-Cache | 1 | IN | logic | TC-I-02, TC-INT-02, TC-INT-05 | Memory return valid (data ready) |
| `mem_rtrn_i` | I-Cache | struct | IN | `icache_rtrn_t` | TC-I-02, TC-INT-02, TC-INT-05 | Return packet: {rtype, data, user} |
| `mem_rtrn_i.rtype` | I-Cache | 4 | IN | logic[3:0] | TC-I-02, TC-INT-02, TC-INT-05 | Return type (ICACHE_IFILL_ACK=0x3) |
| `mem_rtrn_i.data` | I-Cache | 128 | IN | logic[127:0] | TC-I-02, TC-INT-02, TC-INT-05 | Cache line data (128 bits) |
| `mem_rtrn_i.user` | I-Cache | 32 | IN | logic[31:0] | — | User bits |
| `mem_data_ack_i` | I-Cache | 1 | IN | logic | TC-I-02, TC-INT-02, TC-INT-05 | ACK to memory request |

**Verification Checklist**:
- [ ] mem_rtrn_vld_i arrives after mem_data_req_o
- [ ] rtype = 0x3 (IFILL_ACK)
- [ ] data contains valid instructions
- [ ] dreq_o.valid resumes after mem_rtrn_vld_i

---

### **18. I-CACHE: CONTROL**

| Signal | Source | Width | Direction | Type | Test Cases | Notes |
|--------|--------|-------|-----------|------|-----------|-------|
| `flush_i` | I-Cache | 1 | IN | logic | TC-I-03 | Flush cache command |
| `en_i` | I-Cache | 1 | IN | logic | TC-I-01, TC-I-02, TC-I-03, TC-INT-01, TC-INT-05 | Cache enable |

**Verification Checklist**:
- [ ] en_i = 1 for all normal tests
- [ ] flush_i pulses 1 cycle (TC-I-03)
- [ ] Valid entries invalidated after flush

---

### **19. I-CACHE: DIAGNOSTIC OUTPUT**

| Signal | Source | Width | Direction | Type | Test Cases | Notes |
|--------|--------|-------|-----------|------|-----------|-------|
| `miss_o` | I-Cache | 1 | OUT | logic | TC-I-01, TC-I-02, TC-I-03, TC-INT-01, TC-INT-05 | Cache miss indicator |

**Waveform Signals to Monitor**:
```
□ miss_o pulses on each I-Cache miss
□ TC-I-01: miss_o = 0 throughout (all hits)
□ TC-I-02: miss_o pulses once (cold miss)
```

**Verification Checklist**:
- [ ] TC-I-01: miss_o stays LOW (all hits)
- [ ] TC-I-02: miss_o pulses HIGH on cold miss
- [ ] No spurious miss pulses

---

### **20. AXI BUS: READ ADDRESS CHANNEL (CVA6 → Memory)**

| Signal | Source | Width | Direction | Type | Test Cases | Notes |
|--------|--------|-------|-----------|------|-----------|-------|
| `noc_req_o.ar_valid` | CVA6 | 1 | OUT | logic | TC-D-02, TC-D-03, TC-I-02, TC-INT-02, TC-INT-03, TC-INT-05 | AXI AR channel valid |
| `noc_req_o.ar.id` | CVA6 | `AxiIdWidth` | OUT | logic[...] | TC-D-03, TC-INT-02 | Transaction ID (request ID) |
| `noc_req_o.ar.addr` | CVA6 | `AxiAddrWidth` | OUT | logic[...] | TC-D-02, TC-D-03, TC-I-02, TC-INT-02, TC-INT-03, TC-INT-05 | Physical address (cache-line aligned) |
| `noc_req_o.ar.len` | CVA6 | 8 | OUT | logic[7:0] | TC-D-02, TC-D-03, TC-I-02, TC-INT-02, TC-INT-03, TC-INT-05 | Burst length (typically 1 for single beat) |
| `noc_req_o.ar.size` | CVA6 | 3 | OUT | logic[2:0] | TC-D-02, TC-D-03, TC-I-02, TC-INT-02, TC-INT-03, TC-INT-05 | Size = log2(bytes/beat) |
| `noc_req_o.ar.burst` | CVA6 | 2 | OUT | logic[1:0] | — | Burst type (INCR=0x1) |
| `noc_req_o.ar.lock` | CVA6 | 1 | OUT | logic | — | Atomic access flag |
| `noc_req_o.ar.cache` | CVA6 | 4 | OUT | logic[3:0] | — | Cache policy bits |
| `noc_req_o.ar.prot` | CVA6 | 3 | OUT | logic[2:0] | — | Protection type |
| `noc_req_o.ar.qos` | CVA6 | 4 | OUT | logic[3:0] | — | Quality of Service |
| `noc_req_o.ar.region` | CVA6 | 4 | OUT | logic[3:0] | — | Address region |
| `noc_req_o.ar.user` | CVA6 | `AxiUserWidth` | OUT | logic[...] | — | User bits |
| `noc_resp_i.ar_ready` | CVA6 | 1 | IN | logic | TC-D-02, TC-D-03, TC-I-02, TC-INT-02, TC-INT-03, TC-INT-05 | AXI ARREADY (slave ready) |

**Waveform Signals to Monitor**:
```
□ ar_valid to ar_ready handshake
□ ar.addr cache-line aligned
□ ar.id unique per request (MSHR tests)
□ ar.len and ar.size correct for cache line size
□ No ar_valid without ar_ready response within 1 cycle
```

**Verification Checklist**:
- [ ] TC-D-02: Single AR transaction for cold miss
- [ ] TC-D-03: 4 distinct AR transactions with unique IDs
- [ ] TC-I-02: AR issued for I-Cache miss
- [ ] Address 64-byte aligned (for HPDCache) or line-aligned
- [ ] Handshake completes (ar_ready HIGH when ar_valid HIGH)

---

### **21. AXI BUS: WRITE ADDRESS CHANNEL (CVA6 → Memory)**

| Signal | Source | Width | Direction | Type | Test Cases | Notes |
|--------|--------|-------|-----------|------|-----------|-------|
| `noc_req_o.aw_valid` | CVA6 | 1 | OUT | logic | TC-D-04, TC-INT-02, TC-PF-03 | AXI AW channel valid |
| `noc_req_o.aw.id` | CVA6 | `AxiIdWidth` | OUT | logic[...] | TC-D-04, TC-INT-02, TC-PF-03 | Transaction ID |
| `noc_req_o.aw.addr` | CVA6 | `AxiAddrWidth` | OUT | logic[...] | TC-D-04, TC-INT-02, TC-PF-03 | Write address (dirty line address) |
| `noc_req_o.aw.len` | CVA6 | 8 | OUT | logic[7:0] | TC-D-04, TC-INT-02, TC-PF-03 | Burst length |
| `noc_req_o.aw.size` | CVA6 | 3 | OUT | logic[2:0] | TC-D-04, TC-INT-02, TC-PF-03 | Size |
| `noc_req_o.aw.burst` | CVA6 | 2 | OUT | logic[1:0] | — | Burst type |
| `noc_req_o.aw.lock` | CVA6 | 1 | OUT | logic | — | Atomic flag |
| `noc_req_o.aw.cache` | CVA6 | 4 | OUT | logic[3:0] | — | Cache policy |
| `noc_req_o.aw.prot` | CVA6 | 3 | OUT | logic[2:0] | — | Protection |
| `noc_req_o.aw.qos` | CVA6 | 4 | OUT | logic[3:0] | — | QoS |
| `noc_req_o.aw.region` | CVA6 | 4 | OUT | logic[3:0] | — | Region |
| `noc_req_o.aw.atop` | CVA6 | 6 | OUT | logic[5:0] | — | Atomic operation (typically 0) |
| `noc_req_o.aw.user` | CVA6 | `AxiUserWidth` | OUT | logic[...] | — | User bits |
| `noc_resp_i.aw_ready` | CVA6 | 1 | IN | logic | TC-D-04, TC-INT-02, TC-PF-03 | AXI AWREADY |

**Waveform Signals to Monitor**:
```
□ aw_valid timing (MUST come BEFORE ar_valid in eviction)
□ aw.addr dirty line address
□ aw_valid to aw_ready handshake
□ Followed by w_valid (write data)
```

**Verification Checklist**:
- [ ] TC-D-04: aw_valid HIGH BEFORE ar_valid (write-back before refill)
- [ ] Address cache-line aligned
- [ ] Handshake completes (aw_ready asserted)
- [ ] No address overlap with refill AR address (different cache lines)

---

### **22. AXI BUS: WRITE DATA CHANNEL (CVA6 → Memory)**

| Signal | Source | Width | Direction | Type | Test Cases | Notes |
|--------|--------|-------|-----------|------|-----------|-------|
| `noc_req_o.w_valid` | CVA6 | 1 | OUT | logic | TC-D-04, TC-INT-02, TC-PF-03 | Write data valid |
| `noc_req_o.w.data` | CVA6 | `AxiDataWidth` | OUT | logic[...] | TC-D-04, TC-INT-02, TC-PF-03 | Write payload (full cache line) |
| `noc_req_o.w.strb` | CVA6 | `AxiDataWidth/8` | OUT | logic[...] | TC-D-04, TC-INT-02, TC-PF-03 | Write strobes (byte enable) |
| `noc_req_o.w.last` | CVA6 | 1 | OUT | logic | TC-D-04, TC-INT-02, TC-PF-03 | Last beat flag (HIGH for single beat) |
| `noc_req_o.w.user` | CVA6 | `AxiUserWidth` | OUT | logic[...] | — | User bits |
| `noc_resp_i.w_ready` | CVA6 | 1 | IN | logic | TC-D-04, TC-INT-02, TC-PF-03 | Write ready |

**Waveform Signals to Monitor**:
```
□ w_valid within 0-1 cycles of aw_valid (write data follows AW)
□ w.data content (stored values)
□ w.strb all 1's (all bytes valid)
□ w.last = 1 (single beat)
□ w_valid to w_ready handshake
```

**Verification Checklist**:
- [ ] w_valid follows aw_valid (within 1 cycle)
- [ ] w.data contains correct stored values
- [ ] w.strb = all 1's (full cache line write)
- [ ] w.last = 1 (single beat per AXI spec)
- [ ] Handshake completes (w_ready asserted)

---

### **23. AXI BUS: WRITE RESPONSE CHANNEL (Memory → CVA6)**

| Signal | Source | Width | Direction | Type | Test Cases | Notes |
|--------|--------|-------|-----------|------|-----------|-------|
| `noc_resp_i.b_valid` | CVA6 | 1 | IN | logic | TC-D-04, TC-INT-02, TC-PF-03 | Write response valid (AXI BVALID) |
| `noc_resp_i.b.id` | CVA6 | `AxiIdWidth` | IN | logic[...] | TC-D-04, TC-INT-02, TC-PF-03 | Response ID (matches AW.id) |
| `noc_resp_i.b.resp` | CVA6 | 2 | IN | logic[1:0] | TC-D-04, TC-INT-02, TC-PF-03 | Response code (OKAY=0x0) |
| `noc_resp_i.b.user` | CVA6 | `AxiUserWidth` | IN | logic[...] | — | User bits |
| `noc_req_o.b_ready` | CVA6 | 1 | OUT | logic | TC-D-04, TC-INT-02, TC-PF-03 | Write response ready (AXI BREADY) |

**Waveform Signals to Monitor**:
```
□ b_valid timing (after w.last accepted)
□ b.resp = OKAY (0x0)
□ b.id matches aw.id
□ CRITICAL: b_valid must occur BEFORE next ar_valid (TC-D-04)
```

**Verification Checklist**:
- [ ] b_valid arrives after write data accepted
- [ ] b.resp = OKAY (no errors)
- [ ] Response completes before AR issued (TC-D-04)
- [ ] Cache can proceed with refill after B response

---

### **24. AXI BUS: READ DATA CHANNEL (Memory → CVA6)**

| Signal | Source | Width | Direction | Type | Test Cases | Notes |
|--------|--------|-------|-----------|------|-----------|-------|
| `noc_resp_i.r_valid` | CVA6 | 1 | IN | logic | TC-D-02, TC-D-03, TC-I-02, TC-INT-02, TC-INT-03, TC-INT-05 | Read data valid (AXI RVALID) |
| `noc_resp_i.r.id` | CVA6 | `AxiIdWidth` | IN | logic[...] | TC-D-03, TC-INT-02 | Response ID (matches AR.id) |
| `noc_resp_i.r.data` | CVA6 | `AxiDataWidth` | IN | logic[...] | TC-D-02, TC-D-03, TC-I-02, TC-INT-02, TC-INT-03, TC-INT-05 | Read data (cache line) |
| `noc_resp_i.r.resp` | CVA6 | 2 | IN | logic[1:0] | TC-D-02, TC-D-03, TC-I-02, TC-INT-02, TC-INT-03, TC-INT-05 | Response code (OKAY=0x0) |
| `noc_resp_i.r.last` | CVA6 | 1 | IN | logic | TC-D-02, TC-D-03, TC-I-02, TC-INT-02, TC-INT-03, TC-INT-05 | Last beat (HIGH for single beat) |
| `noc_resp_i.r.user` | CVA6 | `AxiUserWidth` | IN | logic[...] | — | User bits |
| `noc_req_o.r_ready` | CVA6 | 1 | OUT | logic | TC-D-02, TC-D-03, TC-I-02, TC-INT-02, TC-INT-03, TC-INT-05 | Read ready (AXI RREADY, always HIGH) |

**Waveform Signals to Monitor**:
```
□ r_valid timing (latency from AR)
□ r.data content
□ r.id matches corresponding ar.id (MSHR tests)
□ r.last = 1 (single beat)
□ r.resp = OKAY (0x0)
□ core_rsp_valid_o follows r_valid
```

**Verification Checklist**:
- [ ] TC-D-02: Single R transaction for single miss
- [ ] TC-D-03: 4 R responses, IDs match 4 AR requests (may arrive out-of-order)
- [ ] TC-I-02: R data valid after AR handshake
- [ ] Data matches expected values (test pattern or stored data)
- [ ] r.last = 1 (single beat per AXI spec)
- [ ] r.resp = OKAY (no errors)

---

### **25. RVFI: COMMIT INTERFACE (Runtime Verification)**

| Signal | Source | Width | Direction | Type | Test Cases | Notes |
|--------|--------|-------|-----------|------|-----------|-------|
| `rvfi_probes_o` | CVA6 | struct | OUT | `rvfi_probes_t` | TC-INT-01, TC-INT-02, TC-INT-03, TC-INT-04, TC-INT-05, TC-PF-02, TC-PF-03 | RVFI probe interface (instruction level) |
| `rvfi_probes_o.commit_valid[0]` | CVA6 | 1 | OUT | logic | TC-INT-01, TC-INT-02, TC-INT-03, TC-INT-04, TC-INT-05, TC-PF-02, TC-PF-03 | Commit valid (hart 0 commits instruction) |
| `rvfi_probes_o.commit_pc_next[0]` | CVA6 | 64 | OUT | logic[63:0] | TC-INT-01, TC-INT-02, TC-INT-03, TC-INT-04, TC-INT-05, TC-PF-02 | Program counter for next instruction |
| `rvfi_probes_o.commit_instr[0]` | CVA6 | 32 | OUT | logic[31:0] | TC-INT-01, TC-INT-02, TC-INT-04 | Committed instruction word |
| `rvfi_probes_o.commit_rd_addr[0]` | CVA6 | 5 | OUT | logic[4:0] | TC-INT-02, TC-INT-04 | Destination register address |
| `rvfi_probes_o.commit_rd_wdata[0]` | CVA6 | 64 | OUT | logic[63:0] | TC-INT-02, TC-INT-04, TC-PF-03 | Destination register write data (result) |

**Waveform Signals to Monitor**:
```
□ commit_valid[0] pulse rate (for liveness)
□ commit_pc_next[0] sequence (should be +4 per instruction)
□ commit_rd_wdata[0] correctness (for LOAD/STORE tests)
□ No gaps in PC sequence (indicates stall or exception)
```

**Verification Checklist**:
- [ ] TC-INT-01: PC sequence = 0x80000000, 0x80000004, ..., 0x8000007C (32×4 bytes)
- [ ] TC-INT-02: rd_wdata matches expected LOAD results
- [ ] TC-INT-03: commit_valid freezes during D-Cache miss
- [ ] TC-INT-04: Two LOAD instructions show correct rd_wdata (X, then Y)
- [ ] TC-INT-05: commit_valid pulsing continuously (no deadlock)
- [ ] TC-PF-02: Stall count comparison between prefetch ON/OFF

---

### **26. PREFETCHER INTERFACE (Domino Prefetcher)**

| Signal | Source | Width | Direction | Type | Test Cases | Notes |
|--------|--------|-------|-----------|------|-----------|-------|
| **prefetch_en** | Control | 1 | IN | logic | TC-PF-01, TC-PF-02, TC-PF-03 | Enable Domino Prefetcher |
| **prefetch_req_valid** | Prefetcher | 1 | OUT | logic | TC-PF-01, TC-PF-02, TC-PF-03 | Prefetch request valid |
| **prefetch_req_addr** | Prefetcher | `Cfg.u.paWidth` | OUT | logic[...] | TC-PF-01, TC-PF-02, TC-PF-03 | Prefetch address (base + stride) |
| **prefetch_req_tid** | Prefetcher | `Cfg.u.reqTransIdWidth` | OUT | logic[...] | TC-PF-01, TC-PF-03 | Prefetch transaction ID |
| **prefetch_grant** | D-Cache | 1 | IN | logic | TC-PF-01, TC-PF-02, TC-PF-03 | Prefetch accepted by cache |

**Waveform Signals to Monitor**:
```
□ prefetch_en toggle (0→1 for tests PF-02 and PF-03)
□ prefetch_req_valid pulse rate (should correlate with core_req_i rate)
□ prefetch_req_addr = core_req_i.offset + 64 (stride=64 for memory hierarchy)
□ prefetch_grant response
```

**Verification Checklist**:
- [ ] TC-PF-01: prefetch_req_addr = addr + 64, 128, 192, ... (stride detection)
- [ ] TC-PF-02: Stall count with prefetch_en=1 < stall count with prefetch_en=0
- [ ] TC-PF-03: LOAD returns stored value (no stale prefetch data)
- [ ] False prefetch rate <20%

---

## **Port Verification Matrix**

### **Test Case vs. Port Usage**

| Test | D-Cache Req | D-Cache Rsp | Mem R (AR/R) | Mem W (AW/W/B) | I-Cache Req | I-Cache Rsp | Mem (I) | RVFI | Prefetch | AXI Arb |
|------|---|---|---|---|---|---|---|---|---|---|
| **TC-D-01** | ✓ | ✓ | — | — | — | — | — | — | — | — |
| **TC-D-02** | ✓ | ✓ | ✓ | — | — | — | — | — | — | ✓ |
| **TC-D-03** | ✓×4 | ✓×4 | ✓×4 | — | — | — | — | — | — | ✓ |
| **TC-D-04** | ✓ | ✓ | ✓ | ✓ | — | — | — | — | — | ✓ |
| **TC-I-01** | — | — | — | — | ✓ | ✓ | — | — | — | — |
| **TC-I-02** | — | — | ✓ | — | ✓ | ✓ | ✓ | — | — | ✓ |
| **TC-I-03** | — | — | — | — | ✓ | ✓ | — | — | — | — |
| **TC-INT-01** | — | — | — | — | ✓ | ✓ | — | ✓ | — | — |
| **TC-INT-02** | ✓ | ✓ | ✓ | ✓ | — | — | — | ✓ | — | ✓ |
| **TC-INT-03** | ✓ | ✓ | ✓ | — | — | — | — | ✓ | — | ✓ |
| **TC-INT-04** | ✓×2 | ✓×2 | — | — | — | — | — | ✓ | — | — |
| **TC-INT-05** | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | — | ✓ |
| **TC-PF-01** | ✓ | ✓ | — | — | — | — | — | — | ✓ | — |
| **TC-PF-02** | ✓ | ✓ | — | — | — | — | — | ✓ | ✓ | — |
| **TC-PF-03** | ✓ | ✓ | — | ✓ | — | — | — | ✓ | ✓ | ✓ |

---

## **Port Dependencies by Test Case**

### **TC-D-01: D-Cache STORE→LOAD hit**

**Ports Used**:
```
Core Request:  core_req_valid_i, core_req_i.{offset, data, be, tid}
Core Tag:      core_req_tag_i
Core PMA:      core_req_pma_i
Core Response: core_rsp_valid_o, core_rsp_o.data
Verification:  core_rsp_o.data == core_req_i.data (for STORE→LOAD)
                mem_req_read_valid_o = 0 (hit, no miss)
```

**Waveform Signals**:
```
[0:100] clk_i cycles
[10] rst_ni released
[20] core_req_valid_i=1 (STORE x12)
     core_req_i.offset=0x100, core_req_i.data=0x12345678
     core_req_tag_i=0x1000, core_req_pma_i.cacheable=1
[21] core_rsp_valid_o=1, core_rsp_o.data matches STORE
[22] core_req_valid_i=1 (LOAD x11)
     core_req_i.offset=0x100 (same address)
[23] core_rsp_valid_o=1, core_rsp_o.data=0x12345678 (STORE value)
```

---

### **TC-D-02: D-Cache cold miss → refill**

**Ports Used**:
```
Core Request:  core_req_valid_i, core_req_i.offset, core_req_tag_i
Core Response: core_rsp_valid_o, core_rsp_o.data
Memory Read:   mem_req_read_valid_o, mem_req_read_o.{addr, tid}
               mem_rsp_read_valid_i, mem_rsp_read_i.data
AXI:           noc_req_o.ar_valid, noc_req_o.ar.{addr, id, len, size}
               noc_resp_i.ar_ready, noc_resp_i.r_valid, noc_resp_i.r.{data, id, last}
Verification:  mem_req_read_valid_o pulse on miss
               AXI AR handshake occurs
               core_rsp_valid_o follows AXI R data
```

**Waveform Signals**:
```
[20] core_req_valid_i=1, core_req_i.offset=0x200 (uncached)
[21] mem_req_read_valid_o=1, mem_req_read_o.addr=0x2000 (cache-line aligned)
     noc_req_o.ar_valid=1, noc_req_o.ar.addr=0x2000
[22] noc_resp_i.ar_ready=1 (handshake)
[30] noc_resp_i.r_valid=1, noc_resp_i.r.data=[cache line], noc_resp_i.r.last=1
[31] core_rsp_valid_o=1, core_rsp_o.data=[from cache line]
```

---

### **TC-D-03: MSHR multi-miss (4 outstanding)**

**Ports Used**:
```
Core Request:  core_req_valid_i×4 (sequential), core_req_i.{offset, tid}
Core Response: core_rsp_valid_o×4 (reordered via TID)
Memory Read:   mem_req_read_valid_o×4, mem_req_read_o.tid (unique)
               mem_rsp_read_valid_i×4, mem_rsp_read_i.id (out-of-order)
AXI:           noc_req_o.ar_valid×4 (unique IDs), noc_resp_i.r_valid×4
Verification:  4 requests, 4 distinct mem_req TIDs
               4 responses, IDs may arrive out-of-order
               MSHR correctly matches responses to requests
```

**Waveform Signals**:
```
[20] core_req_valid_i=1, tid=0, offset=0x300 (LOAD #1)
     → mem_req_read_valid_o=1, tid=0
     → noc_req_o.ar_valid=1, noc_req_o.ar.id=0
[21] core_req_valid_i=1, tid=1, offset=0x400 (LOAD #2)
     → mem_req_read_valid_o=1, tid=1
     → noc_req_o.ar_valid=1, noc_req_o.ar.id=1
[22] core_req_valid_i=1, tid=2, offset=0x500 (LOAD #3)
     → mem_req_read_valid_o=1, tid=2
     → noc_req_o.ar_valid=1, noc_req_o.ar.id=2
[23] core_req_valid_i=1, tid=3, offset=0x600 (LOAD #4)
     → mem_req_read_valid_o=1, tid=3
     → noc_req_o.ar_valid=1, noc_req_o.ar.id=3

[35] noc_resp_i.r_valid=1, r.id=2 (response #2 arrives first)
     → core_rsp_valid_o=1, tid=2
[36] noc_resp_i.r_valid=1, r.id=0
     → core_rsp_valid_o=1, tid=0
[37] noc_resp_i.r_valid=1, r.id=3
     → core_rsp_valid_o=1, tid=3
[38] noc_resp_i.r_valid=1, r.id=1
     → core_rsp_valid_o=1, tid=1
```

---

### **TC-D-04: Write-back eviction**

**Ports Used**:
```
Core Request:  core_req_valid_i×2 (STORE dirty, then evicting LOAD)
Memory Write:  mem_req_write_valid_o, mem_req_write_o.addr
               mem_rsp_write_valid_i
AXI:           noc_req_o.aw_valid, noc_req_o.aw.addr, noc_req_o.w_valid
               noc_req_o.w.data, noc_resp_i.b_valid
               (MUST verify: b_valid before ar_valid)
               noc_req_o.ar_valid, noc_resp_i.r_valid
Verification:  Sequence: AW → W → B → AR (correct write-back order)
                b_valid occurs BEFORE next ar_valid
```

**Waveform Signals**:
```
[20] core_req_valid_i=1 (STORE to addr A)
     core_req_i.data=[dirty value]
[21] core_rsp_valid_o=1 (STORE accepted, line marked dirty)

[30] core_req_valid_i=1 (LOAD from addr B, different set, evicts addr A)
[31] mem_req_write_valid_o=1 (eviction detected)
     noc_req_o.aw_valid=1, noc_req_o.aw.addr=A (dirty line address)
[32] noc_resp_i.aw_ready=1 (handshake)
     noc_req_o.w_valid=1, noc_req_o.w.data=[dirty value]
[33] noc_resp_i.w_ready=1 (handshake)
[35] noc_resp_i.b_valid=1 (write response)
     *** AW+W+B sequence complete ***
[36] noc_req_o.ar_valid=1 (now issue refill for addr B)
     noc_req_o.ar.addr=B (new line address)
```

**CRITICAL**: Verify `noc_resp_i.b_valid` at [35] BEFORE `noc_req_o.ar_valid` at [36]

---

### **TC-I-01: I-Cache sequential hit**

**Ports Used**:
```
I-Cache Request:  dreq_i.req, dreq_i.vaddr
I-Cache Response: dreq_o.valid, dreq_o.data
TLB Request:      areq_o.fetch_req, areq_o.fetch_vaddr
TLB Response:     areq_i.fetch_valid, areq_i.fetch_paddr
Verification:     dreq_o.valid=1 every cycle (no stalls)
                  miss_o=0 (all hits)
                  No AXI AR activity
```

**Waveform Signals**:
```
[10] rst_ni released
[20] dreq_i.req=1, dreq_i.vaddr=0x80000000 (boot address)
     areq_o.fetch_req=1 (request TLB translation)
[21] areq_i.fetch_valid=1, areq_i.fetch_paddr=0x80000000 (I-SRAM, pre-filled)
     dreq_o.valid=1, dreq_o.data=instruction[0]
[22] dreq_i.vaddr=0x80000004 (sequential)
     dreq_o.valid=1, dreq_o.data=instruction[1]
[23] dreq_i.vaddr=0x80000008
     dreq_o.valid=1, dreq_o.data=instruction[2]
...
[35] dreq_i.vaddr=0x8000003C (instruction 15)
     dreq_o.valid=1, dreq_o.data=instruction[15]
```

**Verify**: 16 consecutive `dreq_o.valid=1`, `miss_o=0` throughout

---

### **TC-I-02: I-Cache cold miss**

**Ports Used**:
```
I-Cache Request:  dreq_i.vaddr (branch to unmapped address)
I-Cache Response: dreq_o.valid (stalls), miss_o (HIGH on miss)
Memory Request:   mem_data_req_o, mem_data_o.paddr
Memory Response:  mem_rtrn_vld_i, mem_rtrn_i.data
AXI:              noc_req_o.ar_valid, noc_resp_i.r_valid
Verification:     miss_o pulses HIGH
                  dreq_o.valid goes LOW
                  AXI AR issued
                  dreq_o.valid resumes after refill
```

**Waveform Signals**:
```
[30] dreq_i.req=1, dreq_i.vaddr=0xC0000000 (unmapped, causes miss)
[31] miss_o=1 (miss detected)
     mem_data_req_o=1, mem_data_o.paddr=0xC0000000
     noc_req_o.ar_valid=1, noc_req_o.ar.addr=0xC0000000
     dreq_o.valid=0 (stall due to miss)
[32] noc_resp_i.ar_ready=1 (handshake)
[50] noc_resp_i.r_valid=1, noc_resp_i.r.data=[cache line]
     mem_rtrn_vld_i=1, mem_rtrn_i.rtype=IFILL_ACK
[51] dreq_o.valid=1 (fetch resumes)
     dreq_o.data=[instruction from refilled line]
```

---

### **TC-I-03: Flush & re-fetch**

**Ports Used**:
```
I-Cache Control:  flush_i, dreq_i.kill_s1, dreq_i.kill_s2
I-Cache Response: dreq_o.valid
Verification:     dreq_o.valid goes LOW during flush
                  After flush, re-fetch on new address
                  No stale instruction commits
```

**Waveform Signals**:
```
[40] dreq_i.req=1, dreq_i.vaddr=0x80000000
     dreq_o.valid=1 (normal fetch)
[50] flush_i=1 (flush command, 1 cycle)
     dreq_i.kill_s1=1, dreq_i.kill_s2=1
[51] flush_i=0 (flush ends)
     dreq_o.valid=0 (cache invalidated)
[52] dreq_i.vaddr=0x80000010 (new address after branch)
     dreq_i.req=1
[53] dreq_o.valid=1 (if hit on new addr)
     dreq_o.data=[new instruction]
```

---

### **TC-INT-01: Boot + ALU execution**

**Ports Used**:
```
Boot:             boot_addr_i, rst_ni
I-Cache:          dreq_i, dreq_o
RVFI:             rvfi_probes_o.commit_valid, commit_pc_next, commit_instr
Verification:     PC sequence = 0x80000000, 0x80000004, ..., 0x8000007C
                  32 instructions execute without stalls
                  No memory access (ALU-only code)
```

**Waveform Signals**:
```
[0] rst_ni=0 (reset asserted)
[10] rst_ni=1 (reset released)
     First instruction fetch from boot_addr_i=0x80000000
[20] rvfi_probes_o.commit_valid[0]=1, commit_pc_next[0]=0x80000000
     commit_instr[0]=[first instr]
[21] rvfi_probes_o.commit_valid[0]=1, commit_pc_next[0]=0x80000004
[22] rvfi_probes_o.commit_valid[0]=1, commit_pc_next[0]=0x80000008
...
[51] rvfi_probes_o.commit_valid[0]=1, commit_pc_next[0]=0x8000007C
```

**Verify**: 32 commit_valid pulses, PC increments by 4 each cycle, no gaps

---

### **TC-INT-02: LOAD/STORE correctness**

**Ports Used**:
```
D-Cache Request:  core_req_valid_i (×2: STORE, LOAD)
D-Cache Response: core_rsp_valid_o, core_rsp_o.data
Memory:           mem_req_read_valid_o, noc_req_o.ar_valid
                  noc_resp_i.r_valid, mem_rsp_read_valid_i
RVFI:             rvfi_probes_o.commit_rd_wdata (LOAD result)
Verification:     LOAD returns value from prior STORE
                  RVFI rd_wdata matches expected value
```

**Waveform Signals**:
```
[20] core_req_valid_i=1 (STORE x10 @ addr)
     core_req_i.data=0xDEADBEEF
[21] core_rsp_valid_o=1 (STORE accepted)

[30] core_req_valid_i=1 (LOAD x11 @ same addr)
[31] (check cache hit or miss)
     If hit: core_rsp_valid_o=1, core_rsp_o.data=0xDEADBEEF
     If miss: mem_req_read_valid_o=1 → noc_req_o.ar_valid=1
[40] (if miss) noc_resp_i.r_valid=1, noc_resp_i.r.data=0xDEADBEEF
[41] core_rsp_valid_o=1, core_rsp_o.data=0xDEADBEEF

[50] rvfi_probes_o.commit_rd_wdata[0]=0xDEADBEEF (LOAD result in RVFI)
```

**Verify**: RVFI rd_wdata == stored value

---

### **TC-INT-03: D-Cache miss stall**

**Ports Used**:
```
D-Cache Request:  core_req_valid_i (LOAD uncached)
D-Cache Response: core_rsp_valid_o (stalls)
Memory Read:      mem_req_read_valid_o, mem_rsp_read_valid_i
RVFI:             rvfi_probes_o.commit_valid (must freeze)
                  rvfi_probes_o.commit_pc_next (frozen during miss)
Verification:     commit_valid=0 while miss active
                  PC does not advance
                  Resume after data arrives
```

**Waveform Signals**:
```
[20] core_req_valid_i=1 (LOAD uncached)
[21] mem_req_read_valid_o=1 (miss detected)
     rvfi_probes_o.commit_valid[0]=0 (pipeline stalls)
     rvfi_probes_o.commit_pc_next[0]=CONST (frozen)
[40] mem_rsp_read_valid_i=1 (data arrives)
     core_rsp_valid_o=1
[41] rvfi_probes_o.commit_valid[0]=1 (pipeline resumes)
     rvfi_probes_o.commit_pc_next[0]=next_pc (PC advances)
```

**Verify**: Stall duration matches memory latency, no spurious commits during stall

---

### **TC-INT-04: RAW hazard via memory**

**Ports Used**:
```
D-Cache:          core_req_valid_i×2, core_rsp_o.data
RVFI:             rvfi_probes_o.commit_rd_wdata×2 (LOAD #1, LOAD #2)
Verification:     LOAD #1 returns X (from STORE)
                  LOAD #2 returns Y (from STORE #2)
                  No stale data (RAW hazard correctly resolved)
```

**Waveform Signals**:
```
[20] core_req_valid_i=1 (STORE X @ addr)
[21] core_rsp_valid_o=1 (STORE accepted)
[30] core_req_valid_i=1 (LOAD @ addr)
[31] core_rsp_valid_o=1, core_rsp_o.data=X
[40] rvfi_probes_o.commit_rd_wdata[0]=X (LOAD #1 result)

[50] core_req_valid_i=1 (STORE Y @ addr)
[51] core_rsp_valid_o=1 (STORE #2 accepted)
[60] core_req_valid_i=1 (LOAD @ addr)
[61] core_rsp_valid_o=1, core_rsp_o.data=Y
[70] rvfi_probes_o.commit_rd_wdata[0]=Y (LOAD #2 result)
```

**Verify**: LOAD #1 = X, LOAD #2 = Y (correct value forwarding)

---

### **TC-INT-05: I+D concurrent, no deadlock**

**Ports Used**:
```
I-Cache:          dreq_i, dreq_o (fetch requests)
D-Cache:          core_req_valid_i, core_rsp_valid_o (load/store)
Memory Read:      mem_req_read_valid_o (both I+D)
Memory Write:     mem_req_write_valid_o (D only)
AXI:              noc_req_o.ar_valid, noc_req_o.aw_valid
                  noc_resp_i.ar_ready, noc_resp_i.aw_ready, r_ready, b_ready
RVFI:             rvfi_probes_o.commit_valid (liveness)
Verification:     No deadlock >100k cycles
                  commit_valid pulsing regularly
                  AXI arbiter properly arbitrates I vs D requests
```

**Waveform Signals**:
```
[20-100000] Continuous execution
- I-Cache: dreq_i.req every 1-3 cycles, dreq_o.valid tracking
- D-Cache: core_req_valid_i every 2-4 cycles, responses
- AXI: Both ar_valid and aw_valid may be HIGH simultaneously
- RVFI: commit_valid pulsing every 2-5 cycles (no constant 0)
- No X on any signal
- Memory arbiter responds to both request types
```

**Verify**: Simulation completes without timeout, liveness detected

---

### **TC-PF-01: Prefetch stride detect**

**Ports Used**:
```
D-Cache Request:  core_req_i.offset (stride pattern)
Prefetcher:       prefetch_en, prefetch_req_valid, prefetch_req_addr
Verification:     prefetch_req_addr = core_req_i.offset + 64
                  Stride detection working correctly
```

**Waveform Signals**:
```
[20] prefetch_en=1 (enable prefetcher)
[30] core_req_valid_i=1, core_req_i.offset=0x1000 (LOAD iteration 0)
[31] prefetch_req_valid=1, prefetch_req_addr=0x1040 (next iteration, stride=64)
[40] core_req_valid_i=1, core_req_i.offset=0x1040 (LOAD iteration 1)
[41] prefetch_req_valid=1, prefetch_req_addr=0x1080 (iteration 2)
[50] core_req_valid_i=1, core_req_i.offset=0x1080 (LOAD iteration 2)
[51] prefetch_req_valid=1, prefetch_req_addr=0x10C0 (iteration 3)
```

**Verify**: prefetch_req_addr always equals next expected offset

---

### **TC-PF-02: Miss rate reduction**

**Ports Used**:
```
D-Cache:          miss_o, core_req_valid_i
Prefetcher:       prefetch_en (toggle 0→1)
RVFI:             rvfi_probes_o.commit_valid (stall count)
Verification:     miss_count(prefetch_OFF) > miss_count(prefetch_ON)
                  Architectural state identical
```

**Waveform Signals**:
```
Run #1 (prefetch_en=0):
[0-10000] Execute stride_access.S
- Count: miss_o=1 pulses → N_OFF
- Count: commit_valid=0 cycles (stall) → S_OFF
- Total stall metric = S_OFF + latency(N_OFF)

Run #2 (prefetch_en=1):
[0-10000] Execute same code
- Count: miss_o=1 pulses → N_ON
- Count: commit_valid=0 cycles → S_ON
- Total stall metric = S_ON + latency(N_ON)

Verify: N_OFF > N_ON or S_OFF > S_ON (or both)
```

---

### **TC-PF-03: No coherence violation**

**Ports Used**:
```
D-Cache Request:  core_req_valid_i (STORE loop, then LOAD loop)
D-Cache Response: core_rsp_o.data
Memory Write:     mem_req_write_valid_o (write-back)
Prefetcher:       prefetch_en, prefetch_req_valid
RVFI:             rvfi_probes_o.commit_rd_wdata (LOAD result)
Verification:     LOAD returns stored value (not stale)
                  No spurious AXI AW transactions
```

**Waveform Signals**:
```
STORE Phase:
[20-50] Loop: STORE X @ addr_i
[30] core_req_valid_i=1, core_req_i.offset=0x2000, core_req_i.data=X
[31] core_rsp_valid_o=1 (STORE accepted)
(concurrent with STORE loop)
[35] prefetch_req_valid=1 (prefetcher may speculate)

LOAD Phase:
[60-90] Loop: LOAD @ addr_i
[70] core_req_valid_i=1, core_req_i.offset=0x2000
[71] core_rsp_valid_o=1, core_rsp_o.data=X (NOT STALE!)
[80] rvfi_probes_o.commit_rd_wdata[0]=X (LOAD result confirmed)
```

**Verify**: All LOADs return stored value X, no stale prefetch data

---

## **UVM Testbench Port Declarations**

### **Interface Definition: cvA6_dcache_if.sv**

```systemverilog
interface cvA6_dcache_if (input logic clk_i);
  // Clock & Reset
  logic rst_ni;
  
  // Core Request (Cycle 1)
  logic core_req_valid_i;
  hpdcache_req_t core_req_i;
  
  // Core Request (Cycle 2)
  logic core_req_abort_i;
  logic [Cfg.tagWidth-1:0] core_req_tag_i;
  hpdcache_pma_t core_req_pma_i;
  
  // Core Response
  logic core_rsp_valid_o;
  hpdcache_rsp_t core_rsp_o;
  
  // Memory Read Request
  logic mem_req_read_valid_o;
  hpdcache_mem_req_t mem_req_read_o;
  logic mem_req_read_ready_i;
  
  // Memory Read Response
  logic mem_rsp_read_valid_i;
  hpdcache_mem_rsp_t mem_rsp_read_i;
  logic mem_rsp_read_ready_o;
  
  // Memory Write Request
  logic mem_req_write_valid_o;
  hpdcache_mem_req_t mem_req_write_o;
  logic mem_req_write_data_valid_o;
  logic mem_req_write_ready_i;
  
  // Memory Write Response
  logic mem_rsp_write_valid_i;
  hpdcache_mem_rsp_t mem_rsp_write_i;
  logic mem_rsp_write_ready_o;
  
  // Control
  logic wbuf_flush_i;
  
  // Clocking Block
  clocking cb @(posedge clk_i);
    default input #1ps output #0ps;
    // Inputs
    input rst_ni;
    input core_rsp_valid_o;
    input core_rsp_o;
    input mem_req_read_valid_o;
    input mem_req_read_o;
    input mem_req_write_valid_o;
    input mem_req_write_o;
    // Outputs
    output core_req_valid_i;
    output core_req_i;
    output core_req_tag_i;
    output core_req_pma_i;
    output mem_req_read_ready_i;
    output mem_rsp_read_valid_i;
    output mem_rsp_read_i;
    output mem_req_write_ready_i;
    output mem_rsp_write_valid_i;
    output mem_rsp_write_i;
  endclocking
  
  modport master (clocking cb);
endinterface
```

### **Interface Definition: cva6_icache_if.sv**

```systemverilog
interface cva6_icache_if (input logic clk_i);
  // Clock & Reset
  logic rst_ni;
  
  // Pipeline Request
  icache_dreq_t dreq_i;
  
  // Pipeline Response
  icache_drsp_t dreq_o;
  
  // Address Translation Request
  icache_arsp_t areq_o;
  
  // Address Translation Response
  icache_areq_t areq_i;
  
  // Memory Request
  logic mem_data_req_o;
  icache_req_t mem_data_o;
  logic mem_data_ack_i;
  
  // Memory Response
  logic mem_rtrn_vld_i;
  icache_rtrn_t mem_rtrn_i;
  
  // Control
  logic flush_i;
  logic en_i;
  
  // Diagnostic
  logic miss_o;
  
  // Clocking Block
  clocking cb @(posedge clk_i);
    default input #1ps output #0ps;
    // Inputs
    input rst_ni;
    input dreq_o;
    input areq_o;
    input mem_data_req_o;
    input miss_o;
    // Outputs
    output dreq_i;
    output areq_i;
    output mem_rtrn_vld_i;
    output mem_rtrn_i;
    output flush_i;
    output en_i;
  endclocking
  
  modport master (clocking cb);
endinterface
```

### **Interface Definition: cva6_axi_if.sv**

```systemverilog
interface cva6_axi_if (input logic clk_i);
  // Clock & Reset
  logic rst_ni;
  
  // AXI Read Address Channel
  logic ar_valid;
  logic [AxiIdWidth-1:0] ar_id;
  logic [AxiAddrWidth-1:0] ar_addr;
  logic [7:0] ar_len;
  logic [2:0] ar_size;
  logic [1:0] ar_burst;
  logic ar_ready;
  
  // AXI Read Data Channel
  logic r_valid;
  logic [AxiIdWidth-1:0] r_id;
  logic [AxiDataWidth-1:0] r_data;
  logic r_last;
  logic r_ready = 1'b1; // Always ready
  
  // AXI Write Address Channel
  logic aw_valid;
  logic [AxiIdWidth-1:0] aw_id;
  logic [AxiAddrWidth-1:0] aw_addr;
  logic [7:0] aw_len;
  logic [2:0] aw_size;
  logic aw_ready;
  
  // AXI Write Data Channel
  logic w_valid;
  logic [AxiDataWidth-1:0] w_data;
  logic [(AxiDataWidth/8)-1:0] w_strb;
  logic w_last;
  logic w_ready;
  
  // AXI Write Response Channel
  logic b_valid;
  logic [AxiIdWidth-1:0] b_id;
  logic [1:0] b_resp;
  logic b_ready = 1'b1; // Always ready
  
  // Clocking Block
  clocking cb @(posedge clk_i);
    default input #1ps output #0ps;
    input ar_valid, ar_id, ar_addr, ar_len, ar_size;
    input r_valid, r_id, r_data, r_last;
    input aw_valid, aw_id, aw_addr;
    input w_valid, w_data, w_strb, w_last;
    input b_valid, b_id, b_resp;
    output ar_ready;
    output w_ready, aw_ready;
  endclocking
  
  modport master (clocking cb);
endinterface
```

### **UVM Testbench Skeleton: tb_l1_cache_integration.sv**

```systemverilog
`timescale 1ns / 1ps

module tb_l1_cache_integration;
  import uvm_pkg::*;
  `include "uvm_macros.svh"
  
  // DUT Parameters
  parameter int VLEN = 64;
  parameter int PLEN = 34;
  parameter int XLEN = 64;
  parameter int DCACHE_LINE_WIDTH = 512;
  parameter int ICACHE_LINE_WIDTH = 128;
  parameter int AxiDataWidth = 512;
  parameter int AxiIdWidth = 4;
  parameter int AxiAddrWidth = 48;
  
  // Clock Generation
  logic clk_i = 0;
  initial forever #5ns clk_i = ~clk_i;
  
  // Interfaces
  cvA6_dcache_if dcache_if (clk_i);
  cva6_icache_if icache_if (clk_i);
  cva6_axi_if axi_if (clk_i);
  
  // DUT Instantiation (Placeholder)
  // cva6 dut_cva6 (.*)
  // hpdcache_wrapper dut_dcache (.*)
  // cva6_icache dut_icache (.*)
  
  // Initial Block
  initial begin
    uvm_config_db#(virtual cvA6_dcache_if)::set(null, "uvm_test_top", "dcache_if", dcache_if);
    uvm_config_db#(virtual cva6_icache_if)::set(null, "uvm_test_top", "icache_if", icache_if);
    uvm_config_db#(virtual cva6_axi_if)::set(null, "uvm_test_top", "axi_if", axi_if);
    
    // Run tests
    run_test("tc_d_01_dcache_store_load_hit");
    run_test("tc_d_02_dcache_cold_miss");
    // ... more tests
  end
  
  // Waveform Dumping
  initial begin
    if ($test$plusargs("dump_waves")) begin
      $dumpfile("l1_cache_integration.vcd");
      $dumpvars(0, tb_l1_cache_integration);
    end
  end
  
endmodule
```

---

## **Waveform Signal List**

### **Critical Signals for Each Test**

**TC-D-01 (STORE→LOAD hit)**:
```
clk_i, rst_ni
core_req_valid_i, core_req_i.offset, core_req_i.data
core_req_tag_i, core_req_pma_i
core_rsp_valid_o, core_rsp_o.data
mem_req_read_valid_o  (must be 0)
```

**TC-D-02 (Cold miss)**:
```
core_req_valid_i, core_req_i.offset
mem_req_read_valid_o, mem_req_read_o.addr
noc_req_o.ar_valid, noc_req_o.ar.addr, noc_req_o.ar.id
noc_resp_i.ar_ready, noc_resp_i.r_valid, noc_resp_i.r.data
core_rsp_valid_o, core_rsp_o.data
```

**TC-D-03 (MSHR×4)**:
```
core_req_valid_i, core_req_i.tid (×4 different values)
mem_req_read_valid_o, mem_req_read_o.tid (×4)
noc_req_o.ar_valid, noc_req_o.ar.id (×4 unique)
noc_resp_i.r_valid, noc_resp_i.r.id (×4, out-of-order)
core_rsp_valid_o (×4 responses)
```

**TC-D-04 (Write-back)**:
```
core_req_valid_i (×2: STORE, evicting LOAD)
noc_req_o.aw_valid, noc_req_o.aw.addr
noc_req_o.w_valid, noc_req_o.w.data
noc_resp_i.b_valid  (CRITICAL: before ar_valid)
noc_req_o.ar_valid, noc_req_o.ar.addr
noc_resp_i.r_valid, noc_resp_i.r.data
```

**TC-I-01 (Sequential hit)**:
```
dreq_i.req, dreq_i.vaddr (×16 increments)
dreq_o.valid (must be 1 every cycle)
dreq_o.data (×16 instructions)
miss_o  (must be 0)
noc_req_o.ar_valid  (must be 0)
```

**TC-I-02 (Cold miss)**:
```
dreq_i.vaddr (branch to unmapped)
miss_o (pulse HIGH)
dreq_o.valid (goes LOW, then HIGH)
mem_data_req_o, mem_data_o.paddr
noc_req_o.ar_valid, noc_req_o.ar.addr
noc_resp_i.r_valid, noc_resp_i.r.data
mem_rtrn_vld_i, mem_rtrn_i.data
```

**TC-I-03 (Flush)**:
```
flush_i (pulse 1 cycle)
dreq_i.kill_s1, dreq_i.kill_s2
dreq_o.valid (goes LOW during flush)
dreq_i.vaddr (changes after flush)
```

**TC-INT-01 (Boot+ALU)**:
```
rst_ni (reset sequence)
boot_addr_i, dreq_i.vaddr
rvfi_probes_o.commit_valid[0] (×32 pulses)
rvfi_probes_o.commit_pc_next[0] (sequence: 0x80000000 → 0x8000007C)
```

**TC-INT-02 (LD/ST)**:
```
core_req_valid_i (×2: STORE, LOAD)
core_req_i.data, core_rsp_o.data
mem_req_read_valid_o, noc_req_o.ar_valid
noc_resp_i.r_valid, noc_resp_i.r.data
rvfi_probes_o.commit_rd_wdata[0] (LOAD result)
```

**TC-INT-03 (Stall)**:
```
core_req_valid_i
mem_req_read_valid_o (HIGH = miss)
rvfi_probes_o.commit_valid[0] (frozen during miss)
rvfi_probes_o.commit_pc_next[0] (constant during stall)
mem_rsp_read_valid_i (data arrival)
```

**TC-INT-04 (RAW)**:
```
core_req_valid_i (×2: STORE, LOAD)
core_rsp_o.data (LOAD result)
rvfi_probes_o.commit_rd_wdata[0] (×2: should be X, then Y)
```

**TC-INT-05 (Concurrent)**:
```
dreq_i.req, dreq_o.valid (I-Cache)
core_req_valid_i, core_rsp_valid_o (D-Cache)
noc_req_o.ar_valid, noc_req_o.aw_valid
noc_resp_i.ar_ready, noc_resp_i.aw_ready
rvfi_probes_o.commit_valid[0] (liveness detector)
```

**TC-PF-01 (Stride detect)**:
```
prefetch_en (HIGH)
core_req_i.offset (stride pattern)
prefetch_req_valid, prefetch_req_addr
(verify: addr = offset + 64)
```

**TC-PF-02 (Miss rate)**:
```
prefetch_en (toggle 0→1)
miss_o (count pulses)
rvfi_probes_o.commit_valid[0] (count stalls)
(compare: OFF vs ON)
```

**TC-PF-03 (Coherence)**:
```
core_req_valid_i (STORE, then LOAD)
core_rsp_o.data (LOAD result)
prefetch_req_valid, prefetch_req_addr
noc_req_o.aw_valid, noc_req_o.w.data
rvfi_probes_o.commit_rd_wdata[0] (LOAD should return stored value)
```

---

## **Compile & Simulation Commands**

### **QuestaSim Compile Script: compile.do**

```tcl
# Compile HPDCache
vlog -sv -work work \
  hpdcache/rtl/hpdcache_wrapper.sv \
  hpdcache/rtl/hpdcache.sv \
  hpdcache/rtl/hpdcache_mshr.sv \
  hpdcache/rtl/hpdcache_wbuf.sv

# Compile CVA6
vlog -sv -work work \
  cva6/core/cva6.sv \
  cva6/core/cva6_alu.sv \
  cva6/core/fetch_stage.sv \
  cva6/core/ex_stage.sv \
  cva6/core/mem_stage.sv \
  cva6/core/cache_subsystem/cva6_icache.sv \
  cva6/core/cache_subsystem/cva6_tlb.sv

# Compile Testbench Interfaces & TB
vlog -sv -work work \
  tb/cvA6_dcache_if.sv \
  tb/cva6_icache_if.sv \
  tb/cva6_axi_if.sv \
  tb/tb_l1_cache_integration.sv

# Compile UVM Tests
vlog -sv +incdir+$UVM_HOME/uvm-1.1d/src -work work \
  tb/test/tc_d_01_dcache_store_load_hit.sv \
  tb/test/tc_d_02_dcache_cold_miss.sv \
  tb/test/tc_d_03_dcache_mshr_multi_miss.sv \
  tb/test/tc_d_04_dcache_writeback_eviction.sv \
  tb/test/tc_i_01_icache_sequential_hit.sv \
  tb/test/tc_i_02_icache_cold_miss.sv \
  tb/test/tc_i_03_icache_flush.sv \
  tb/test/tc_int_01_boot_alu.sv \
  tb/test/tc_int_02_load_store.sv \
  tb/test/tc_int_03_dcache_miss_stall.sv \
  tb/test/tc_int_04_raw_hazard.sv \
  tb/test/tc_int_05_concurrent_nodeadlock.sv \
  tb/test/tc_pf_01_prefetch_stride.sv \
  tb/test/tc_pf_02_miss_rate_reduction.sv \
  tb/test/tc_pf_03_coherence_violation.sv

# Optimize
vopt -work work tb_l1_cache_integration -o tb_l1_cache_integration_opt +acc

echo "Compile complete."
```

### **QuestaSim Simulation Script: simulate_all.do**

```tcl
# Set simulation parameters
set QUIT_ON_ERROR 1
set SIM_TIME 1000us

# Run each test
set tests {
  tc_d_01_dcache_store_load_hit
  tc_d_02_dcache_cold_miss
  tc_d_03_dcache_mshr_multi_miss
  tc_d_04_dcache_writeback_eviction
  tc_i_01_icache_sequential_hit
  tc_i_02_icache_cold_miss
  tc_i_03_icache_flush
  tc_int_01_boot_alu
  tc_int_02_load_store
  tc_int_03_dcache_miss_stall
  tc_int_04_raw_hazard
  tc_int_05_concurrent_nodeadlock
  tc_pf_01_prefetch_stride
  tc_pf_02_miss_rate_reduction
  tc_pf_03_coherence_violation
}

foreach test $tests {
  puts "===== Running $test ====="
  
  vsim -work work tb_l1_cache_integration_opt \
    +UVM_TESTNAME=$test \
    +dump_waves \
    -do "run $SIM_TIME; quit"
  
  # Check for failures
  if {[info exists env(CI)]} {
    if {[file exists l1_cache_integration.vcd]} {
      exec grep -q "UVM_FATAL\|UVM_ERROR" l1_cache_integration.vcd
      if {$? == 0} {
        puts "ERROR: $test failed!"
        exit 1
      }
    }
  }
}

puts "All tests completed."
```

### **Bash Script: run_sim.sh**

```bash
#!/bin/bash

set -e

QUESTA_HOME="/opt/Questa"
UVM_HOME="$QUESTA_HOME/verilog_src/uvm-1.1d"

export PATH="$QUESTA_HOME/bin:$PATH"
export UVM_HOME

cd $(dirname $0)

echo "===== L1 Cache Integration Verification ====="
echo "Test Plan: 15 test cases (11 MUST, 4 SHOULD)"
echo ""

# Compile
echo "[1/3] Compiling RTL & Testbench..."
questasim -c -do "source compile.do; quit" || exit 1

# Run simulations
echo "[2/3] Running simulations..."
questasim -c -do "source simulate_all.do" || exit 1

# Collect coverage
echo "[3/3] Collecting coverage..."
# (Coverage collection commands here)

echo ""
echo "===== Verification Complete ====="
```

---

## **Coverage & Assertion Strategy**

### **Functional Coverage**

```systemverilog
// D-Cache Coverage
covergroup cg_dcache_operation;
  cp_req_type: coverpoint req_type { bins LOAD={1}; bins STORE={0}; }
  cp_miss:     coverpoint (mem_req_read_valid_o) { bins MISS={1}; bins HIT={0}; }
  cp_tid:      coverpoint tid { range=[0:15]; }
  cross_req_miss: cross cp_req_type, cp_miss;
endgroup

// I-Cache Coverage
covergroup cg_icache_operation;
  cp_hit_miss: coverpoint miss_o { bins HIT={0}; bins MISS={1}; }
  cp_vaddr:    coverpoint (dreq_i.vaddr[31:0]) { 
                 bins low = {[0:0x1000]};
                 bins high = {[0x80000000:0x80001000]};
               }
endgroup

// AXI Bus Coverage
covergroup cg_axi_transactions;
  cp_ar_valid:  coverpoint ar_valid { bins YES={1}; bins NO={0}; }
  cp_r_valid:   coverpoint r_valid { bins YES={1}; bins NO={0}; }
  cp_aw_valid:  coverpoint aw_valid { bins YES={1}; bins NO={0}; }
  cp_w_valid:   coverpoint w_valid { bins YES={1}; bins NO={0}; }
  cp_b_valid:   coverpoint b_valid { bins YES={1}; bins NO={0}; }
endgroup
```

### **Assertions**

```systemverilog
// Protocol Assertions
assert property (
  @(posedge clk_i) disable iff (~rst_ni)
  (noc_req_o.ar_valid && noc_req_o.aw_valid) 
  |-> noc_resp_i.b_valid <= $past(noc_resp_i.aw_ready)
) else $error("AXI B response must precede next AR (write-back protocol)");

assert property (
  @(posedge clk_i) disable iff (~rst_ni)
  core_req_valid_i 
  |=> (core_rsp_valid_o || mem_req_read_valid_o)
) else $error("D-Cache must respond or issue memory request");

assert property (
  @(posedge clk_i) disable iff (~rst_ni)
  (noc_req_o.ar_valid && noc_resp_i.ar_ready) 
  |=> ~noc_req_o.ar_valid [*0:5] ##1 noc_resp_i.r_valid
) else $error("AXI read data must arrive after AR handshake");
```

---

## **Summary: Quick Reference**

| Aspect | Count/Details |
|--------|---|
| **Total Ports** | 26 port groups, ~150 individual signals |
| **Test Cases** | 15 (11 MUST, 4 SHOULD) |
| **D-Cache Ports** | 16 (request, response, memory interface) |
| **I-Cache Ports** | 10 (request, response, memory, control) |
| **AXI Ports** | 25 (5 channels × 5 signals/channel avg) |
| **RVFI Ports** | 6 (commit interface) |
| **Prefetcher Ports** | 5 (enable, request, grant) |
| **Compile Time** | ~30-45 seconds (QuestaSim 23.3) |
| **Simulation Time** | ~2-5 seconds per test (10,000-100,000 cycles) |
| **Total VCD Size** | ~100-500 MB (with full dumping) |

---

**File Complete** ✓ Ready for testbench development

