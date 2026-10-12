# UVM-Project.-Synchronous-FIFO

this is a project for UVM design verification, focusing on verification planning

First, i were given a specification from LLM to implement an RTL.
then when i understand the RTL behaviour, i can write a verification plan and implement the plan in UVM style
the UVM body may resemble my 1st project

# FIFO Verification Plan: Approach and Spec v1.1

Project: UVM Self learning. Prepared 8 October 2026.

## Goal

Demonstrate two fresh-grad skills with one project:

1. **UVM development:** building a working UVM environment (Claude writes the code and explains it; Amirul drafts the backbone and rewrites the parts he understands).
2. **Verification planning:** reading a spec, finding gaps, and trying to break the design. This is the skill to emphasise.

## Why the plan changed

Verifying RTL you wrote and fixed yourself mostly confirms what you already believe. Real DV engineers verify someone else's RTL against a spec. Understanding the spec does not require writing the RTL: the test is whether you can predict the outputs on paper for a given input sequence. The scoreboard model is exactly that, written from the spec alone.

## Plan

1. Freeze spec v1.1 (below), with overflow and underflow included.
2. Write the verification plan from the spec only, without looking at any RTL.
3. Build the UVM environment. Claude writes each class and explains it briefly; Amirul rewrites the parts he understands.
4. Run it against several DUTs: the finished RTL as the baseline, plus bugged variants written by Claude. The bugs are not disclosed, only how many.
5. Report which bugs were found and which slipped through. A survivor means a gap in the plan, and a new test is added.

The reset test (tb\_reset\_test.sv) stays as a sanity check. More directed tests are replaced by the UVM environment.

## Method: from spec to test plan

For each rule in the spec:

- **Observable:** what output or signal proves it?
- **Stimulus:** which situations must be exercised? Check boundaries (0, 1, max-1, max), transitions, simultaneous events, and sequences (fill, drain, wrap-around).
- **Break-it question:** what mistake would a designer make here? Examples: off-by-one on full, count overwritten, pointer not wrapping, reset only partial.
- **Checker and coverage:** where is it checked (scoreboard or assertion), and which coverage bin proves it was hit?

The resulting table has the columns: Rule, Stimulus, Bug it targets, Checker, Coverage, Test.

## Spec v1.1

**Parameters:** DATA\_W = 8, DEPTH = 16.

**Ports**

- `clk` (in, 1): clock, rising edge.
- `rst_n` (in, 1): async reset, active low.
- `wr_en` (in, 1): write request.
- `wr_data` (in, 8): write data.
- `rd_en` (in, 1): read request.
- `rd_data` (out, 8): read data, registered.
- `rd_valid` (out, 1): 1 only when rd\_data holds data from an accepted read.
- `full` (out, 1): count == 16.
- `empty` (out, 1): count == 0.
- `overflow` (out, 1): pulses after an ignored write.
- `underflow` (out, 1): pulses after an ignored read.

**Rules**

- **R1:** Data leaves in the order it entered.
- **R2:** A write is accepted when `wr_en && (!full || rd_en)`.
- **R3:** A read is accepted when `rd_en && !empty`.
- **R4:** Write when full, no read: ignored, nothing changes.
- **R5:** Write when full, with a read: both accepted, count stays 16.
- **R6:** Read when empty: ignored, even with a write in the same cycle (no bypass). The write is accepted.
- **R7:** Read and write together at mid-level: both accepted, count unchanged.
- **R8:** count goes +1 on write only, -1 on read only, and is unchanged for both or neither.
- **R9:** full and empty come from count and are never both 1.
- **R10:** rd\_data updates one cycle after an accepted read, and otherwise holds its value.
- **R11:** Reset values (below).
- **R12:** rd\_valid is 1 exactly in the cycle when rd\_data holds new data.
- **R13:** overflow pulses one cycle after an ignored write (R4). underflow pulses one cycle after an ignored read (read when empty).

**Reset values:** pointers and count = 0, empty = 1, full = 0, rd\_data = 0, rd\_valid / overflow / underflow = 0. The memory array is not cleared.

## Behavior of count (the 12 cells to hit and check)

- **Empty:** idle stays 0. Write only goes to 1. Read only stays 0 (underflow). Write and read goes to 1 (read ignored, write accepted).
- **Mid:** idle stays the same. Write only is +1. Read only is -1. Write and read stays the same.
- **Full:** idle stays 16. Write only stays 16 (overflow). Read only goes to 15. Write and read stays 16 (both accepted).

The four unusual cells are empty+read, empty+both, full+write and full+both.

## Timing convention

All decisions use the state before the clock edge. Outputs update after the edge. rd\_data and rd\_valid appear one cycle after an accepted read. overflow and underflow pulse one cycle after the ignored operation. The monitor and scoreboard must use one agreed convention.

## Spec gaps and questions to check

- rd\_data on a cycle with no read: it must hold. Use a non-zero held value, so holding and resetting to 0 look different.
- Reset in the same cycle as wr\_en: reset wins.
- wr\_data when wr\_en = 0: it must not matter. Drive junk on it.
- Pointers and count after wrap-around: needs more than 16 writes in total.

## Verification plan table

| Rule | Stimulus | Bug it Targets | Checker | Coverage |
|---|---|---|---|---|
| **R1** | Fill, drain, then fill again past 16 total writes | Pointer does not wrap or FIFO order breaks | Scoreboard queue | Wrap-around hit |
| **R2** | Write at empty, mid, and full levels, with and without read | Write wrongly blocked during full + read | `count` after clock edge | Level × operation cross |
| **R3** | Read at empty, mid, and full levels | Read incorrectly accepted when FIFO is empty | `rd_data`, `count` | Level × operation cross |
| **R4** | Write at full with no read | Data overwritten or `count` changes | `count == 16`, oldest data remains intact | Full × write |
| **R6** | Read + write simultaneously at empty | Incorrect bypass behavior or write dropped | `count -> 1`, written data readable on next valid read | Empty × both |
| **R7** | Read + write simultaneously at mid-level | `count` incorrectly increments or decrements | `count` remains unchanged | Mid × both |
| **R8** | Perform every operation at every FIFO level | Incorrect `count` update logic | Reference `count` model | All 12 level × operation cells |
| **R9** | Drive FIFO to both empty and full conditions | `full` and `empty` both asserted, or flags lag behind `count` | Compare `full` / `empty` against `count` | Flag bins |
| **R10** | Perform a read, then idle while driving junk values on `wr_data` | `rd_data` clears or incorrectly follows input data | Verify `rd_data` holds previous non-zero read value | Idle after read |
| **R12** | Perform a read, then idle, then attempt a read at empty | `rd_valid` stuck high or fails to assert | Verify `rd_valid` pulses for one cycle per accepted read | `rd_valid` bins |
| **R13** | Write at full and read at empty; repeat each case with the opposite operation also asserted | `overflow` / `underflow` pulse missing, incorrect, or longer than one cycle | Verify `overflow` / `underflow` pulse for one cycle after ignored operation | Overflow / underflow condition bins |
