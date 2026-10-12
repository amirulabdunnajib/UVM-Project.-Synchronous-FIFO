# Bug Report: BUG-001 — Write is dropped and `count` falls to 15 when write and read happen together on a full FIFO

> [!info] How to read this report
> This is a completed report, written as a study case. Sections 1 to 5 are **facts** taken from the simulation log. Sections 6 to 8 are the **analysis**. Section 9 is the **verification follow-up**, and it is the part that matters most for the UVM work. The waveform was not captured; section 5.2 says what to capture later.

---

## 1. Summary

| Field | Value |
|---|---|
| Bug ID | BUG-001 |
| Title | Write dropped and `count` falls to 15 when write and read happen together on a full FIFO |
| Status | Open |
| Severity | Critical (data loss) |
| Found by | Amirul |
| Date found | 2026-10-08 |
| DUT file and version | `fifo_dut.sv` (initial release, v1) |
| Spec version | v1.1 |
| Spec rule(s) violated | R5 (primary), R2 (accept condition), R8 and R9 (`count`, `full` follow from it), R1 (data lost) |
| Found in test | T5, `tb_t5.sv`, step "full+wr+rd" |
| Simulator | Synopsys VCS X-2025.06-SP1 (EDA Playground) |

## 2. Description

When the FIFO is full and `wr_en` and `rd_en` are both 1 in the same cycle, the DUT accepts only the read. The new item (`AA`) is never stored, `count` goes from 16 to 15, and `full` drops to 0. Spec rule R5 requires both operations to be accepted, with `count` staying at 16 and `full` staying at 1. The write is lost silently: `overflow` stays 0, so nothing tells the user that data was discarded.

## 3. Stimulus (how to trigger it)

Starting state: reset released at a falling clock edge, FIFO empty.

| Step | Time of check (ns) | `wr_en` | `rd_en` | `wr_data` | Note |
|---|---|---|---|---|---|
| 1 | 36 to 186 (16 cycles) | 1 | 0 | 10, 11, ... 1F | Fill with 16 distinct values D0 to D15. `full` becomes 1 at t=186. |
| 2 | **196** | **1** | **1** | **AA** | **Failing cycle.** FIFO is full, write and read together. |
| 3 | 206, 216 | 0 | 0 | 55 (junk) | Idle, to check the state is stable. |
| 4 | 226 to 376 (16 cycles) | 0 | 1 | 55 (junk) | Drain, expecting D1 to D15 and then AA. |

Minimum sequence to reproduce: steps 1 and 2 only. Steps 3 and 4 give extra evidence, since they show what was stored.

## 4. Expected vs actual

Checked at: t=196 ns, 1 ns after the rising edge at 195 ns. Values are in hex in the log; `0f` is 15 and `10` is 16.

| Signal | Expected (from spec) | Actual (from simulation) | Match? |
|---|---|---|---|
| `count` | 16 (`10`) | 15 (`0f`) | **No** |
| `full` | 1 | 0 | **No** |
| `empty` | 0 | 0 | Yes |
| `rd_data` | `10` (D0, the oldest item) | `10` | Yes |
| `rd_valid` | 1 | 1 | Yes |
| `overflow` | 0 (write is accepted) | 0 | Yes |
| `underflow` | 0 | 0 | Yes |

The matching rows narrow the search. The **read side works** (`rd_data` and `rd_valid` are right). Only the **write side and `count`** are wrong.

## 5. Evidence

### 5.1 Log excerpt

```
t= 186 | fill         | in: wr=1 rd=0 wdata=1f | out: count=16 full=1 empty=0 rd_valid=0 rd_data=00 ovf=0 unf=0

--- Step 2: FULL, write AA and read in the same cycle ---
t= 196 | full+wr+rd   | in: wr=1 rd=1 wdata=aa | out: count=15 full=0 empty=0 rd_valid=1 rd_data=10 ovf=0 unf=0
      FAIL [full+wr+rd] count = 0f, expected 10  (t=196)
      FAIL [full+wr+rd] full = 00, expected 01  (t=196)
```

The run ended with `T5 FAILED: 23 error(s)`. Those 23 are failed **checks**, not 23 bugs. They break down as 2 at the failing cycle, 4 in the idle cycles, 15 `count` checks in the drain, and 2 at the end of the drain. All but the last two follow from this bug (see section 10).

### 5.2 Waveform

Not captured for this report. To capture later, open `dump.vcd` and add these signals: `clk`, `wr_en`, `rd_en`, `wr_data`, `dut.wptr`, `dut.rptr`, `dut.count`, `full`, `rd_data`, `rd_valid`, `overflow`, plus `dut.write_accepted` and `dut.read_accepted`. Zoom to 175 ns to 215 ns with a cursor on the 195 ns edge.

What the waveform should show, based on the log and the RTL:

- At the 195 ns edge, `wr_en` and `rd_en` are both 1 and `full` is 1.
- `write_accepted` is 0 (inferred from the RTL; to be confirmed in the waveform), while `read_accepted` is 1.
- `rptr` advances and `wptr` stays where it was.
- `count` steps from 16 to 15.

If you add screenshots later, embed them here: `![[waveform_01_failing_cycle.png]]`

**Observations (facts from the log):**

1. At t=186, `count` is 16 and `full` is 1, so the precondition is met.
2. At t=196 the DUT returned D0 on `rd_data` with `rd_valid` = 1, so the read was accepted.
3. At the same edge `count` went to 15 (one less), so the write was **not** counted.
4. `overflow` stayed 0, so the DUT did not report the write as ignored either.
5. In the drain, 15 items came out (D1 to D15) and the 16th read found the FIFO empty (`empty` = 1, `underflow` = 1 at t=376). `AA` never came out, so it was never stored.

## 6. Analysis

### 6.1 What differs from the working cases

Fill cycles (write only, `count` below 16) and the drain (read only) behave correctly. The failure needs **all three** of: `full` = 1, `wr_en` = 1, `rd_en` = 1. Remove `rd_en` and the correct behavior is "write ignored" (R4), so a dropped write looks right. That makes this bug easy to hide: a test that only tries write-on-full would pass.

### 6.2 Hypothesis

The DUT decides that a write is accepted only when the FIFO is not full, and ignores `rd_en`. The spec (R2) says a write is accepted when `wr_en && (!full || rd_en)`.

- Confidence: **High**
- Why this explains every symptom: with write_accepted = 0 and read_accepted = 1, the `count` logic takes the "read only" branch, so `count` becomes 15 (R8 applied to the wrong inputs). `wptr` does not advance and memory is not written, so `AA` is lost. `overflow` is computed correctly from the inputs (`wr_en && full && !rd_en` is 0 because `rd_en` is 1), so the DUT neither stores the write nor flags it.
- Alternatives I ruled out: a wrong `count` update (the `case`) would also break the mid-level case where write and read happen together, and a read/write collision on the same slot would keep `count` at 16 and change `rd_data`. Neither matches the log.
- What would confirm it: run the same both-cycle at mid-level (`count` = 8). If it passes, the problem depends on `full`, as hypothesized.

### 6.3 Suspect RTL area

File: `fifo_dut.sv`, line 21, the `write_accepted` assignment.

```systemverilog
wire write_accepted = wr_en && !full;
```

Per R2 it should be:

```systemverilog
wire write_accepted = wr_en && (!full || rd_en);
```

The line drives three things: the memory write, the `wptr` update, and the `count` `case`. That is why one wrong term causes the data loss, the wrong `count` and the wrong `full` at once.

## 7. How to reproduce

1. On EDA Playground, put `fifo_dut.sv` in `design.sv` and `tb_t5.sv` in `testbench.sv`. Choose Synopsys VCS, with "Open EPWave after run" ticked.
2. Compile and run (the log shows `vcs -full64 -sverilog design.sv testbench.sv && ./simv`).
3. Look for `FAIL [full+wr+rd] count = 0f, expected 10  (t=196)`.
4. Open `dump.vcd` and go to t = 195 ns.

The test is directed, so there is no random seed.

## 8. Impact

- **Who is affected:** any user that writes and reads in the same cycle while the FIFO is full.
- **Visible effect:** one item is lost on every such cycle. `count` is one too low, so `full` drops early and the FIFO can accept more writes than its space allows.
- **How likely:** common in steady streaming, where producer and consumer run at the same rate and the FIFO sits at full. Every full-and-both cycle drops an item.
- **Why Critical:** data loss, with no error flag. The failure is silent, which is the worst kind.

## 9. Verification follow-up

| Question | Answer |
|---|---|
| Which plan row should catch this? | R5 row, test T5 (UVM: `full_rw_test`). |
| Which check caught it in this directed test? | `expect_eq` on `count` and `full` right after the both-cycle. The drain check on order would also catch it later. |
| How will the UVM scoreboard catch it? | The model queue pushes `AA` and pops D0, so it holds 16 items. The DUT's `count` of 15 and the missing `AA` at the end of the drain both mismatch the model. |
| Which assertion would catch it earliest? | "If full, `wr_en` and `rd_en` are all 1, then `count` is 16 in the next cycle." See below. |
| Which coverage bin proves it was exercised? | Cross of level = full × operation = write and read. |
| Related scenarios to test next? | Both at full with `wptr` after a wrap. Both at full on consecutive cycles. Both at mid-level and at empty (R6). Write-only at full, which must still be ignored with `overflow` pulsing. |
| Could this hide behind other bugs? | Yes. It dominates the log from t=196 onward, and a second, unrelated problem can sit under its symptoms (see section 10). |

Assertion sketch (put it in the interface):

```systemverilog
property p_full_wr_rd_keeps_count;
  @(posedge clk) disable iff (!rst_n)
  (full && wr_en && rd_en) |=> (count == 16);
endproperty
assert property (p_full_wr_rd_keeps_count);
```

## 10. Other symptoms seen in the same run

| Failed check | Time (ns) | Consequence of this bug? | Reason |
|---|---|---|---|
| `count` / `full` at the both-cycle | 196 | Is the bug | Primary symptom. |
| `count` / `full` in the 2 idle cycles | 206, 216 | Yes | The count stays at the wrong value. |
| `count` in the drain, 15 checks | 226 to 366 | Yes | Off by one from the first failure onward. |
| `rd_data` = `10`, expected `AA`; `rd_valid` = 0, expected 1 | 376 | Partly | `AA` was never stored, so the 16th read finds an empty FIFO and is ignored (`rd_valid` 0 and `underflow` 1 are correct for that). |

**Open question for a separate report (candidate BUG-002):** at t=376 the 16th read was ignored, so R10 says `rd_data` must **hold** its previous value (`1f`, set at t=366). The log shows `10`. BUG-001 alone does not explain this value, because it changes nothing about how `rd_data` behaves on an ignored read. Investigate it separately, starting from R10 and "what loads `rd_data`".

## 11. Fix and re-verification

| Field | Value |
|---|---|
| Proposed fix | Change line 21 to `wire write_accepted = wr_en && (!full \|\| rd_en);` |
| Fixed in DUT version | Pending |
| Re-run of T5 | Pending |
| Regression (reset test, all earlier tests) | Pending |
| New check added | Pending (assertion in section 9) |
| Closed by | Pending |

## 12. Attachments

- `tb_t5.sv` (testbench)
- `fifo_dut.sv` (DUT, v1)
- EDA Playground log from 2026-10-08, 06:10 run
- `dump.vcd` (waveform not reviewed)

> [!tip] Study notes: how to debug a failing log
> 1. **Find the first failure.** Count the failures, but debug only the first one. The rest often follow from it.
> 2. **Compare expected and actual** for every output at that moment, including the ones that match. The matching ones rule things out.
> 3. **Ask what the DUT decided.** Here: was the write accepted? The answer comes from the `count` change.
> 4. **Find the line that makes that decision** and compare it with the spec rule.
> 5. **Look for a symptom that this one cause does not explain.** If there is one, there may be a second bug.
