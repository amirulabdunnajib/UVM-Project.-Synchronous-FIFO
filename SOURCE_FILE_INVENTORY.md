# Source File Inventory — `FIFO_UVM.zip`

The uploaded ZIP was inspected file-by-file, including its nested `UVM_environment/archive/files.zip` and both screenshots. The material falls into five groups.

## 1. Bug-specific RTL snapshots

The `BUG1`–`BUG4` folders and `RTL/` establish the exact progressive chain:

- `fifo_dut.sv` / v1 → BUG1 present.
- `fifo_dut_v2.sv` → BUG1 fixed.
- `fifo_dut_v3.sv` → BUG2 fixed.
- `fifo_dut_v4.sv` → BUG3 fixed.
- `fifo_dut_v5.sv` → BUG4 fixed; final DUT.

Duplicate copies under `BUG1/`…`BUG4/` were used to validate which before/after RTL belongs to each case; they are not treated as independent designs.

## 2. Directed verification history

- T1–T4 reset test: `TestbenchT1,T2,T3,T4` / `TestReset/TB_Reset` plus passing log.
- T5 full + write/read: original draft, corrected self-checking test, failing simulation log, debugging notes and `bug_report_BUG-001.md`.
- T6 read-at-empty: small underflow test plus two logs showing the evolution of `rd_data` observation.
- T7 read-data hold: user's draft, corrected self-checking version, passing log and a coverage-hunting patch.
- `class fifo_corner_seq...sv`: standalone version of the later coverage-closing corner sequence.

These are integrated under the relevant BUG folders and `DIRECTED_TESTS/`.

## 3. UVM environment

The ZIP contains both modular source files and one-file EDA Playground snapshots:

- transaction, interface, driver, monitor, scoreboard, agent and environment;
- reset, full+RW, read-empty and corner sequences;
- level×operation functional coverage with hit-count grid;
- focused tests and combined `fifo_all_test`;
- saved UVM result logs;
- `archive/` snapshots showing the environment before/while coverage was added.

The canonical `UVM/` folder uses the latest behaviour. Historical snapshots remain represented by the original branch history and archived files.

## 4. Notes

The four files under `NOTES/` document the specification-first approach, the 12-cell level×operation model, coverage planning and the transition from passing focused tests to coverage-hole hunting. They are copied into the branch unchanged.

## 5. Screenshots and nested archive

Two PNG screenshots were inspected:

- 2026-10-08: EDA Playground T5 failure at FULL + write/read, showing `count=15` instead of 16.
- 2026-10-10: EDA Playground UVM reset run with `UVM_ERROR: 0` after the reset-flag fix.

The nested `archive/files.zip` contains earlier copies of the modular UVM files (pre-coverage/focused-test stage). Its contents were checked against the surrounding archive files; it is development history rather than a separate verification implementation.

The screenshots and nested ZIP are not required to reproduce the source-level verification flow, so the reorganised branch references their meaning in documentation rather than duplicating the binary archive into every bug folder.
