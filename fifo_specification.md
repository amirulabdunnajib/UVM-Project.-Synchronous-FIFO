# Synchronous FIFO Specification

**Version:** 1.1  
**Configuration:** 8-bit data width, 16 entries  
**Interface:** Single clock, registered read output, no bypass

## 1. Overview

This document defines the functional behavior, interface, reset requirements, and implementation constraints of a synchronous first-in, first-out (FIFO) buffer. It serves as the reference for RTL implementation and verification.

The FIFO supports simultaneous reads and writes. A read may free a slot for a write when the FIFO is full. When the FIFO is empty, a simultaneous write and read stores the new item but does not return it immediately.

Registered `overflow` and `underflow` outputs are required features of this design.

## 2. Parameters and Internal State

| Parameter | Value | Description |
| --- | --- | --- |
| `DATA_W` | 8 | Width of each stored item in bits |
| `DEPTH` | 16 | Maximum number of stored items |

| Internal state | Size | Description |
| --- | --- | --- |
| Memory array | 16 × 8 bits | Data storage |
| `wr_ptr` | 4 bits | Address of the next write |
| `rd_ptr` | 4 bits | Address of the next read |
| `count` | 5 bits | Number of stored items, from 0 through 16 |

Each pointer advances only when its corresponding operation is accepted. With a depth of 16, four-bit pointer arithmetic wraps naturally from 15 to 0. This specification covers the stated configuration; support for other parameter values is outside its scope.

## 3. Port Interface

| Port | Direction | Width | Description |
| --- | --- | --- | --- |
| `clk` | Input | 1 | Clock; operations are sampled on the rising edge |
| `rst_n` | Input | 1 | Active-low reset with asynchronous assertion |
| `wr_en` | Input | 1 | Write request |
| `wr_data` | Input | 8 | Data sampled for an accepted write |
| `rd_en` | Input | 1 | Read request |
| `rd_data` | Output | 8 | Registered read data; holds its value between accepted reads |
| `rd_valid` | Output | 1 | Registered indication that a new read result is available in the current cycle |
| `full` | Output | 1 | High when all 16 entries are occupied |
| `empty` | Output | 1 | High when no entries are occupied |
| `overflow` | Output | 1 | Registered indication of a rejected write request |
| `underflow` | Output | 1 | Registered indication of a rejected read request |

## 4. Operation and Timing Convention

All acceptance decisions use the requests and FIFO state immediately **before** the rising clock edge, with reset inactive. Accepted operations update the state and registered outputs immediately **after** that edge.

```systemverilog
assign wr_accept = wr_en && (!full || rd_en);
assign rd_accept = rd_en && !empty;
```

A request presented during a cycle is sampled at the next rising edge. An accepted read produces `rd_data` and `rd_valid` in the cycle following that edge. There is no additional pipeline stage after the accepting edge and no combinational read bypass.

Reset takes priority over all requests.

## 5. Functional Requirements

| ID | Requirement |
| --- | --- |
| **R1** | Accepted reads shall return stored items in the order of accepted writes. Reset discards all queued items. |
| **R2** | A write shall be accepted when `wr_en && (!full \|\| rd_en)` is true. |
| **R3** | A read shall be accepted when `rd_en && !empty` is true. |
| **R4** | A write requested while full, without a simultaneous read request, shall be rejected. Memory, pointers, and occupancy shall remain unchanged; `overflow` shall assert as defined in R13. |
| **R5** | When full and both requests are asserted, both operations shall be accepted. The oldest item shall be returned, the new item shall be stored, both pointers shall advance, and `count` shall remain 16. |
| **R6** | A read requested while empty shall be rejected, including when a write is requested simultaneously. A simultaneous write shall be accepted and increase `count` to 1. Without a write, `count` shall remain 0. There shall be no bypass. |
| **R7** | When `0 < count < DEPTH` and both requests are asserted, both operations shall be accepted and `count` shall remain unchanged. |
| **R8** | `count` shall increment for an accepted write only, decrement for an accepted read only, and remain unchanged when both or neither operation is accepted. |
| **R9** | `full` shall equal `(count == DEPTH)` and `empty` shall equal `(count == 0)`. They shall never assert simultaneously. |
| **R10** | Except during reset, `rd_data` shall update only on an accepted read, using the oldest stored item from before the accepting edge. Otherwise, it shall retain its previous value. Timing shall follow Section 4. |
| **R11** | Reset shall establish the state specified in Section 6, regardless of the request inputs. |
| **R12** | `rd_valid` shall be registered and shall equal the read acceptance decision from the sampling edge. It shall assert alongside the corresponding read data and deassert after an edge with no accepted read. |
| **R13** | `overflow` shall assert for the cycle following an edge that rejects a write request. `underflow` shall assert for the cycle following an edge that rejects a read request. Both outputs shall be registered and shall clear after an edge without their respective error condition. |

### 5.1 Occupancy Update

| `wr_accept` | `rd_accept` | `count` update |
| --- | --- | --- |
| 0 | 0 | Unchanged |
| 0 | 1 | Decrement by 1 |
| 1 | 0 | Increment by 1 |
| 1 | 1 | Unchanged |

Occupancy shall always remain within `0 <= count <= DEPTH`.

### 5.2 Registered Status Outputs

At each rising edge with reset inactive, the following next values shall be captured from the pre-edge conditions:

```systemverilog
rd_valid  <= rd_accept;
overflow  <= wr_en && !wr_accept;
underflow <= rd_en && !rd_accept;
```

Consecutive rejected requests keep the corresponding error output high across consecutive cycles. These outputs are not sticky and do not require a separate clear input. Likewise, consecutive accepted reads keep `rd_valid` high while producing one result per cycle.

## 6. Reset Requirements

Reset shall assert asynchronously when `rst_n` goes low. While reset is active, no read or write shall be performed. Normal operation resumes on a rising clock edge after reset is released.

| State or output | Reset value |
| --- | --- |
| `wr_ptr` | 0 |
| `rd_ptr` | 0 |
| `count` | 0 |
| `full` | 0 |
| `empty` | 1 |
| `rd_data` | 0 |
| `rd_valid` | 0 |
| `overflow` | 0 |
| `underflow` | 0 |
| Memory array | Not cleared; contents are unspecified and logically invalid |

## 7. Timing Examples

Each row shows requests and state **before** the named rising edge, followed by outputs and state **after** that same edge. Reset is inactive throughout these examples.

### 7.1 Consecutive Reads

Initially, the FIFO contains `A` followed by `B`, with `rd_data = 0` and `rd_valid = 0`. No writes are requested.

| Rising edge | `count` before | `rd_en` | Read accepted | `count` after | `rd_valid` after | `rd_data` after |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | 2 | 1 | Yes | 1 | 1 | A |
| 2 | 1 | 1 | Yes | 0 | 1 | B |
| 3 | 0 | 0 | No | 0 | 0 | B |
| 4 | 0 | 0 | No | 0 | 0 | B |

`rd_data` retains the last result when `rd_valid` is low. It does not indicate another completed read.

### 7.2 Writes While Full

Initially, the FIFO contains 16 items.

| Rising edge | `wr_en` | `rd_en` | Write accepted | Read accepted | `count` after | `rd_valid` after | `overflow` after | `underflow` after |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 1 | 1 | 0 | No | No | 16 | 0 | 1 | 0 |
| 2 | 1 | 1 | Yes | Yes | 16 | 1 | 0 | 0 |

At edge 2, the read returns the oldest item present before the edge. The simultaneous write becomes the newest item in the FIFO.

## 8. Boundary and Simultaneous-Operation Cases

The state column describes occupancy before the sampling edge. `N` denotes a mid-level occupancy where `0 < N < 16`. Status columns show registered values after the edge.

| State | `wr_en` | `rd_en` | Write | Read | `count` after | `rd_valid` | `overflow` | `underflow` |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Empty | 0 | 0 | None | None | 0 | 0 | 0 | 0 |
| Empty | 1 | 0 | Accepted | None | 1 | 0 | 0 | 0 |
| Empty | 0 | 1 | None | Rejected | 0 | 0 | 0 | 1 |
| Empty | 1 | 1 | Accepted | Rejected | 1 | 0 | 0 | 1 |
| Mid-level | 0 | 0 | None | None | N | 0 | 0 | 0 |
| Mid-level | 1 | 0 | Accepted | None | N + 1 | 0 | 0 | 0 |
| Mid-level | 0 | 1 | None | Accepted | N - 1 | 1 | 0 | 0 |
| Mid-level | 1 | 1 | Accepted | Accepted | N | 1 | 0 | 0 |
| Full | 0 | 0 | None | None | 16 | 0 | 0 | 0 |
| Full | 1 | 0 | Rejected | None | 16 | 0 | 1 | 0 |
| Full | 0 | 1 | None | Accepted | 15 | 1 | 0 | 0 |
| Full | 1 | 1 | Accepted | Accepted | 16 | 1 | 0 | 0 |

## 9. RTL Implementation Requirements

- Use `always_ff @(posedge clk or negedge rst_n)` for resettable sequential state.
- Use non-blocking assignments (`<=`) for sequential updates.
- Compute `wr_accept` and `rd_accept` once as combinational signals and reuse them consistently.
- Update `count` in one `case ({wr_accept, rd_accept})` statement, rather than separate increment and decrement statements.
- Advance each pointer only for its accepted operation, using natural four-bit wraparound.
- Do not reset the memory array.
- Preserve the old stored value for a simultaneous read and write to the same address when full. Any inferred or instantiated memory must support this required behavior.
- Keep all RTL synthesizable; do not use `#delay` or `initial` blocks.

## 10. Design and Verification Review Checklist

The following items are review targets, not claims of completed verification.

- [ ] FIFO ordering is preserved across accepted operations and pointer wraparound (R1).
- [ ] Write acceptance uses `wr_en && (!full || rd_en)` (R2).
- [ ] Read acceptance uses `rd_en && !empty` (R3).
- [ ] A rejected full write preserves stored contents, pointers, and occupancy (R4).
- [ ] Simultaneous operations while full return the old item and store the new item (R5).
- [ ] An empty simultaneous read/write accepts only the write and asserts `underflow` (R6, R13).
- [ ] Simultaneous accepted operations leave occupancy unchanged (R7, R8).
- [ ] Occupancy remains between 0 and 16, and the flags match occupancy (R8, R9).
- [ ] `rd_data` holds its value when no read is accepted, except during reset (R10).
- [ ] Reset establishes every specified state and output value without clearing memory (R11).
- [ ] `rd_valid` aligns with each accepted read result, including consecutive reads (R12).
- [ ] Both error outputs assert and clear correctly, including consecutive rejected requests (R13).
- [ ] Both pointers wrap from 15 to 0 without explicit wrap-reset logic.
