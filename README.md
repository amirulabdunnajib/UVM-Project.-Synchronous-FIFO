# Synchronous FIFO — UVM Verification Project

This repository documents a specification-driven verification exercise for a **16-entry × 8-bit synchronous FIFO** using directed SystemVerilog tests and UVM.

The project was intentionally approached from the verification side: freeze the specification, derive expected behaviour independently of the RTL, build checkers and functional coverage, expose defects, then re-run regression after each RTL correction.

## Verification flow

```text
Specification v1.1
      ↓
Directed tests / verification planning
      ↓
UVM stimulus + monitor + scoreboard + coverage
      ↓
BUG1 → BUG2 → BUG3 → BUG4
      ↓
Final corrected RTL (v5)
      ↓
Regression: 12/12 level×operation cells, 100% functional coverage, 0 UVM errors
```

## Four injected/discovered bugs

| Bug | RTL transition | Behaviour | Main rules |
|---|---|---|---|
| [BUG1](BUG1/) | v1 → v2 | Full + simultaneous write/read drops the write | R2, R5, R8, R9 |
| [BUG2](BUG2/) | v2 → v3 | `overflow` and `underflow` are not reset | R11 |
| [BUG3](BUG3/) | v3 → v4 | `rd_data` changes on a rejected empty read | R10 |
| [BUG4](BUG4/) | v4 → v5 | Empty + simultaneous write/read suppresses `underflow` | R6, R13 |

Each bug folder contains the **RTL before and after the fix**, verification evidence, and the UVM stimulus/coverage material relevant to that defect.

## Repository map

- [`fifo_specification.md`](fifo_specification.md) — frozen FIFO specification v1.1.
- [`BUG_INDEX.md`](BUG_INDEX.md) — quick index of the four bug case studies.
- [`BUG1/`](BUG1/) … [`BUG4/`](BUG4/) — self-contained debugging/verification stories.
- [`RTL_HISTORY/`](RTL_HISTORY/) — exact v1→v5 DUT progression plus earlier learning drafts.
- [`UVM/`](UVM/) — canonical UVM environment and final EDA Playground one-file version.
- [`DIRECTED_TESTS/`](DIRECTED_TESTS/) — preserved T6/T7 development material not previously organised in GitHub.
- [`NOTES/`](NOTES/) — verification-plan and coverage-hunting notes.
- [`SOURCE_FILE_INVENTORY.md`](SOURCE_FILE_INVENTORY.md) — how the uploaded `FIFO_UVM.zip` material was interpreted and integrated.

## Final recorded regression

The preserved final regression reports:

- **140 cycles checked**
- **0 scoreboard mismatches**
- **0 UVM errors**
- **12 / 12** level × operation grid cells hit
- reset exercised from empty, mid-level and full states
- overflow and underflow pulses observed
- **100.0% functional coverage**

See [`UVM/Results/final_regression_100pct.log`](UVM/Results/final_regression_100pct.log).

## Historical material

The original repository history and earlier folder layout are intentionally preserved on the original `main` branch. This branch is the reorganised portfolio version.
