# FIFO Verification Plan: Approach and Spec v1.1

Project: UVM Self learning. Prepared 8 October 2026.

## Goal

Demonstrate two fresh-grad skills with one project:

1. **UVM development:** building a working UVM environment.
2. **Verification planning:** reading a spec, finding gaps, and trying to break the design.

## Plan

1. Freeze spec v1.1, with overflow and underflow included.
2. Write the verification plan from the spec only, without looking at any RTL.
3. Build the UVM environment.
4. Run it against the finished RTL plus bugged variants.
5. Report which bugs were found and which slipped through; a survivor becomes a new verification-plan item.

## Method: from spec to test plan

For each rule:

- **Observable:** what output or signal proves it?
- **Stimulus:** which situations must be exercised? Check boundaries, transitions, simultaneous events and sequences.
- **Break-it question:** what mistake would a designer make here?
- **Checker and coverage:** where is it checked, and which coverage bin proves it was hit?

## Core behaviour table

- **Empty:** idle stays 0; write only goes to 1; read only stays 0 with underflow; write+read goes to 1 with the read rejected.
- **Mid:** idle same; write +1; read -1; both same.
- **Full:** idle 16; write only stays 16 with overflow; read only 15; both stay 16.

The four unusual cells are empty+read, empty+both, full+write and full+both.

## Timing convention

All decisions use the state before the clock edge. Outputs update after the edge. `rd_data`/`rd_valid`, overflow and underflow are checked using one agreed monitor/scoreboard timing convention.

## Verification plan rows developed in this project

- R11 reset held with active requests (T1/T2).
- R11 asynchronous reset while occupied (T3).
- R11 + R1 first write/read after reset (T4).
- R5 full + simultaneous write/read (T5).
- R3/R10/R13 read while empty and data hold (T6/T7).
- Coverage-closing corner sequence for all 12 level × operation cells.

The full frozen specification is maintained separately in `../fifo_specification.md`.
