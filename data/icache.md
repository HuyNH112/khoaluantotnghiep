# CVA6 I-Cache Port Width Analysis

**File**: `cva6-master/core/cache_subsystem/cva6_icache.sv`  
**Line**: 47-69 (port declaration)  
**Config**: cv64a6_imafdc_sv39_hpdcache_config_pkg + tb_icache.sv

---

## CONFIG PARAMETERS

| Parameter | Value | Source |
|-----------|-------|--------|
| **VLEN** | 64 | cva6_cfg.VLEN |
| **PLEN** | 34 | testbench (tb_icache.sv:42) |
| **ICACHE_LINE_WIDTH** | 128 | CVA6ConfigIcacheLineWidth |
| **ICACHE_USER_LINE_WIDTH** | 32 | testbench (tb_icache.sv:43) |
| **ICACHE_SET_ASSOC** | 4 | CVA6ConfigIcacheSetAssoc |
| **ICACHE_SET_ASSOC_WIDTH** | 2 | $\log_2$(4) |
| **ICACHE_INDEX_WIDTH** | 12 | testbench (tb_icache.sv:45) |
| **ICACHE_TAG_WIDTH** | 22 | testbench (tb_icache.sv:46) |
| **FETCH_WIDTH** | 32 | testbench (tb_icache.sv:47) |
| **FETCH_USER_WIDTH** | 64 | FetchUserWidth (default, or 0 if FETCH_USER_EN=0) |
| **FETCH_ALIGN_BITS** | 2 | testbench (tb_icache.sv:48) |
| **MEM_TID_WIDTH** | 4 | CVA6ConfigMemTidWidth = CVA6ConfigAxiIdWidth |
| **ICACHE_OFFSET_WIDTH** | 4 | $\log_2$(128/8) = $\log_2$(16) |

---

## INPUT PORTS (SCALAR)

| Port Name | Type | Width (bits) | RTL Line | Purpose |
|-----------|------|-------------|----------|---------|
| **clk_i** | logic | **1** | 48 | Clock input |
| **rst_ni** | logic | **1** | 49 | Active-low reset |
| **flush_i** | logic | **1** | 52 | Flush i-cache command |
| **en_i** | logic | **1** | 54 | Enable i-cache |
| **mem_rtrn_vld_i** | logic | **1** | 66 | Memory return valid |
| **mem_data_ack_i** | logic | **1** | 68 | Memory ACK to request |

---

## INPUT PORT: `areq_i` (struct icache_areq_t)

**Type**: `icache_areq_t` (parameter type)  
**RTL Line**: 60  
**Total Packed Width**: **1 + 34 + 129 = 164 bits**

| Field | Type | Width | Bits | Description |
|-------|------|-------|------|-------------|
| **fetch_valid** | logic | **1** | [0:0] | Physical addr valid (from TLB) |
| **fetch_paddr** | logic[PLEN-1:0] | **34** | [34:1] | Physical address (34 bits) |
| **fetch_exception.valid** | logic | **1** | [35:35] | Exception valid flag |
| **fetch_exception.tval** | logic[63:0] | **64** | [99:36] | Exception trap value |
| **fetch_exception.cause** | logic[63:0] | **64** | [163:100] | Exception cause code |

**RTL Assignments**:
```systemverilog
// Line 115: extract tag from paddr
assign cl_tag_d  = (areq_i.fetch_valid) ? 
    areq_i.fetch_paddr[ICACHE_TAG_WIDTH+ICACHE_INDEX_WIDTH-1:ICACHE_INDEX_WIDTH] : cl_tag_q;
// = [22+12-1:12] = [33:12] → 22 bits tag from 34-bit paddr

// Line 117-119: pass exception through
assign dreq_o.ex = areq_i.fetch_exception;
```

---

## INPUT PORT: `dreq_i` (struct icache_dreq_t)

**Type**: `icache_dreq_t` (parameter type)  
**RTL Line**: 63  
**Total Packed Width**: **1 + 1 + 64 + 1 + 1 = 68 bits**

| Field | Type | Width | Bits | Description |
|-------|------|-------|------|-------------|
| **req** | logic | **1** | [0:0] | Request valid from pipeline |
| **spec** | logic | **1** | [1:1] | Speculative request flag |
| **vaddr** | logic[VLEN-1:0] | **64** | [65:2] | Virtual address (64-bit) |
| **kill_s1** | logic | **1** | [66:66] | Kill during addr translation |
| **kill_s2** | logic | **1** | [67:67] | Kill during cache lookup |

**RTL Assignments**:
```systemverilog
// Line 123: latch vaddr for alignment
assign vaddr_d = (dreq_o.ready & dreq_i.req) ? dreq_i.vaddr : vaddr_q;
assign areq_o.fetch_vaddr = (vaddr_q >> FETCH_ALIGN_BITS) << FETCH_ALIGN_BITS;
// = (vaddr_q >> 2) << 2 → 32-bit aligned on lower bits

// Line 126: extract cache index from vaddr
assign cl_index = vaddr_d[ICACHE_INDEX_WIDTH-1:ICACHE_OFFSET_WIDTH];
// = vaddr_d[11:4] → 8-bit index (excluding offset)
```

---

## OUTPUT PORT: `miss_o` (scalar)

**Type**: logic  
**RTL Line**: 57  
**Width**: **1 bit**

```systemverilog
// Line 300: Performance counter signal
miss_o = ~paddr_is_nc;  // Asserted only on cacheable miss
```

---

## OUTPUT PORT: `areq_o` (struct icache_arsp_t)

**Type**: `icache_arsp_t` (parameter type)  
**RTL Line**: 61  
**Total Packed Width**: **1 + 64 = 65 bits**

| Field | Type | Width | Bits | Description |
|-------|------|-------|------|-------------|
| **fetch_req** | logic | **1** | [0:0] | TLB request trigger |
| **fetch_vaddr** | logic[VLEN-1:0] | **64** | [64:1] | Virtual addr to TLB (32-bit aligned) |

**RTL Assignments**:
```systemverilog
// Line 121-122: Align to 32-bit (FETCH_ALIGN_BITS=2)
assign areq_o.fetch_vaddr = (vaddr_q >> FETCH_ALIGN_BITS) << FETCH_ALIGN_BITS;
// = (vaddr_q >> 2) << 2

// Line 233: FSM trigger
areq_o.fetch_req = '1;  // Asserted in READ, KILL_ATRANS states
```

---

## OUTPUT PORT: `dreq_o` (struct icache_drsp_t)

**Type**: `icache_drsp_t` (parameter type)  
**RTL Line**: 64  
**Total Packed Width**: **1 + 1 + 32 + 64 + 64 + 129 = 291 bits**

| Field | Type | Width | Bits | Description |
|-------|------|-------|------|-------------|
| **ready** | logic | **1** | [0:0] | Cache ready for new request |
| **valid** | logic | **1** | [1:1] | Data valid output |
| **data** | logic[FETCH_WIDTH-1:0] | **32** | [33:2] | 32-bit instruction data |
| **user** | logic[FETCH_USER_WIDTH-1:0] | **64** | [97:34] | User signal (or 0 if disabled) |
| **vaddr** | logic[VLEN-1:0] | **64** | [161:98] | Virtual address echo |
| **ex.valid** | logic | **1** | [162:162] | Exception valid |
| **ex.tval** | logic[63:0] | **64** | [226:163] | Exception trap value |
| **ex.cause** | logic[63:0] | **64** | [290:227] | Exception cause |

**RTL Assignments**:
```systemverilog
// Line 119: Pass exception through
assign dreq_o.ex = areq_i.fetch_exception;

// Line 129: Echo vaddr
assign dreq_o.vaddr = vaddr_q;

// Line 330-336: Select 32-bit data from cache line
assign cl_sel[i] = cl_rdata[i][{cl_offset_q, 3'b0}+:FETCH_WIDTH];
// Selects 32 bits from 128-bit line at offset {cl_offset_q, 3'b0}

always_comb begin
  if (cmp_en_q) begin
    dreq_o.data = cl_sel[hit_idx];  // From cache on hit
    dreq_o.user = cl_user[hit_idx];
  end else begin
    dreq_o.data = mem_rtrn_i.data[{cl_offset_q, 3'b0}+:FETCH_WIDTH];  // From memory
    dreq_o.user = mem_rtrn_i.user[{cl_offset_q, 3'b0}+:FETCH_USER_WIDTH];
  end
end
```

---

## OUTPUT PORT: `mem_data_req_o` (scalar)

**Type**: logic  
**RTL Line**: 67  
**Width**: **1 bit**

```systemverilog
// Line 293: Memory request valid
mem_data_req_o = 1'b1;  // Asserted in READ state on miss
```

---

## INPUT PORT: `mem_rtrn_i` (struct icache_rtrn_t)

**Type**: `icache_rtrn_t` (parameter type)  
**RTL Line**: 66  
**Total Packed Width**: **4 + 1 + 2 + 1 + 1 + 128 + 32 = 169 bits**

| Field | Type | Width | Bits | Description |
|-------|------|-------|------|-------------|
| **rtype** | logic[3:0] | **4** | [3:0] | Return type (ICACHE_IFILL_ACK=3'b011, ICACHE_INV_REQ) |
| **inv.all** | logic | **1** | [4:4] | Invalidate all entries |
| **inv.vld** | logic | **1** | [5:5] | Invalidate specific way |
| **inv.way** | logic[ICACHE_SET_ASSOC_WIDTH-1:0] | **2** | [7:6] | Way index for inval |
| **inv.idx** | logic[ICACHE_INDEX_WIDTH-1:0] | **12** | [19:8] | Cache line index |
| **data** | logic[ICACHE_LINE_WIDTH-1:0] | **128** | [147:20] | Cache line data from L2/memory |
| **user** | logic[ICACHE_USER_LINE_WIDTH-1:0] | **32** | [179:148] | User signal for line |

**RTL Usage**:
```systemverilog
// Line 269: Check incoming invalidations
if (mem_rtrn_vld_i && mem_rtrn_i.rtype == ICACHE_INV_REQ) begin
  inv_en = 1'b1;
end

// Line 286: Check ifill completion
if (mem_rtrn_vld_i && mem_rtrn_i.rtype == ICACHE_IFILL_ACK) begin
  state_d = IDLE;
  cache_wren = ~paddr_is_nc;
end
```

---

## OUTPUT PORT: `mem_data_o` (struct icache_req_t)

**Type**: `icache_req_t` (parameter type)  
**RTL Line**: 69  
**Total Packed Width**: **1 + 2 + 4 + 34 = 41 bits**

| Field | Type | Width | Bits | Description |
|-------|------|-------|------|-------------|
| **nc** | logic | **1** | [0:0] | Non-cacheable flag (1=I/O, 0=cacheable) |
| **way** | logic[ICACHE_SET_ASSOC_WIDTH-1:0] | **2** | [2:1] | Replacement way (0-3) |
| **tid** | logic[MEM_TID_WIDTH-1:0] | **4** | [6:3] | Transaction ID |
| **paddr** | logic[PLEN-1:0] | **34** | [40:7] | Physical address request |

**RTL Assignments**:
```systemverilog
// Line 109-113: NC address (I/O region)
assign paddr_is_nc = (~cache_en_q) | (~config_pkg::is_inside_cacheable_regions(...));

// Line 135-140: Align address based on cacheable/NC
if (NOCType == NOC_TYPE_AXI4_ATOP) begin
  assign mem_data_o.paddr = (paddr_is_nc) ? 
      {cl_tag_d, vaddr_q[ICACHE_INDEX_WIDTH-1:3], 3'b0} :  // 64-bit align
      {cl_tag_d, vaddr_q[ICACHE_INDEX_WIDTH-1:ICACHE_OFFSET_WIDTH], {ICACHE_OFFSET_WIDTH{1'b0}}};  // CL align
end

// Line 147: Transaction ID
assign mem_data_o.tid = RdTxId;  // Parameter (default=0)

// Line 148-150: Signals
assign mem_data_o.nc  = paddr_is_nc;
assign mem_data_o.way = repl_way;  // 2-bit index
```

---

## SUMMARY TABLE: PORT WIDTHS

| Port | Direction | Type | Total Bits | Structure | Notes |
|------|-----------|------|-----------|-----------|-------|
| **clk_i** | IN | logic | 1 | Scalar | Clock |
| **rst_ni** | IN | logic | 1 | Scalar | Active-low |
| **flush_i** | IN | logic | 1 | Scalar | Flush command |
| **en_i** | IN | logic | 1 | Scalar | Enable |
| **miss_o** | OUT | logic | 1 | Scalar | Perf counter |
| **areq_i** | IN | struct | **164** | {1, 34, 129} | TLB req (exception=129 bits) |
| **areq_o** | OUT | struct | **65** | {1, 64} | TLB resp |
| **dreq_i** | IN | struct | **68** | {1, 1, 64, 1, 1} | Pipeline req |
| **dreq_o** | OUT | struct | **291** | {1, 1, 32, 64, 64, 129} | Pipeline resp |
| **mem_rtrn_vld_i** | IN | logic | 1 | Scalar | Return valid |
| **mem_rtrn_i** | IN | struct | **169** | {4, 16, 128, 32} | L2/memory return |
| **mem_data_ack_i** | IN | logic | 1 | Scalar | Request ACK |
| **mem_data_req_o** | OUT | logic | 1 | Scalar | Request valid |
| **mem_data_o** | OUT | struct | **41** | {1, 2, 4, 34} | Memory request |

---

## DERIVED INTERNAL WIDTHS (for simulation/debugging)

| Signal | Type | Width | RTL Line | Purpose |
|--------|------|-------|----------|---------|
| **cl_index** | logic[7:0] | **8** | 126 | Cache index (excluding offset) |
| **cl_offset_q** | logic[3:0] | **4** | 169 | Offset within cache line |
| **cl_tag_q** | logic[21:0] | **22** | 169 | Cached tag value |
| **cl_hit** | logic[3:0] | **4** | 327 | Hit vector (1 per way) |
| **vld_rdata** | logic[3:0] | **4** | 371 | Valid bit readout per way |
| **cl_sel** | logic[3:0][31:0] | **4×32=128** | 330 | 32-bit selections from all ways |
| **repl_way** | logic[1:0] | **2** | 360 | Replacement way index |
| **state_q** | state_e | **3** | 174 | FSM state (6 states) |

---

## KEY NOTES

1. **Exception Field**: `areq_i.fetch_exception` packs {cause(64), tval(64), valid(1)} = 129 bits
   - Defined in tb_icache.sv as `mock_exception_t`
   
2. **dreq_o Width Breakdown**:
   - Output ready/valid + data(32) = 34 bits minimum
   - + user(64) + vaddr(64) + ex(129) = **291 bits total packed**

3. **Cache Line Path**:
   - Full cacheline: 128 bits
   - Instruction width: 32 bits (extracted via offset)
   - Offset width: 4 bits → supports 16 different 32-bit words per 128-bit line

4. **Tag Extraction**:
   - PLEN=34 bits total
   - ICACHE_INDEX_WIDTH=12 bits
   - ICACHE_TAG_WIDTH=22 bits
   - → 22 + 12 = 34 ✓

5. **Mem_data_o (Request)**:
   - 34-bit paddr + 2-bit way + 4-bit tid + 1-bit nc = 41 bits total
   - For NC (I/O): 64-bit aligned access
   - For cacheable: cache-line (128-bit / 16-byte) aligned
