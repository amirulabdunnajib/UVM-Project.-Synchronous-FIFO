# FIFO Bug Case Studies

This branch reorganizes the verification work into four self-contained bug case studies. The original `main` branch is intentionally left untouched.

## Bug map

| Bug | Failure | Main spec rules | Primary verification evidence |
|---|---|---|---|
| BUG1 | Write is dropped during simultaneous write/read while FULL | R2, R5, R8, R9 | Directed T5 + UVM full/write-read sequence |
| BUG2 | `overflow` and `underflow` are undefined during reset | R11 | UVM reset sequence, reset assertion, scoreboard |
| BUG3 | `rd_data` changes on a rejected read while EMPTY instead of holding | R10 | Drain-to-empty then extra read |
| BUG4 | `underflow` is suppressed for write+read while EMPTY | R6, R13 | EMPTY x write+read corner sequence |

## Folder convention

Each `BUGn/` folder contains:

- `RTL/before_fix.sv` — DUT at the start of that debugging step.
- `RTL/after_fix.sv` — only that bug fixed. Later intentional bugs may still remain.
- `Directed_Test/` — focused directed stimulus plus any preserved logs.
- `UVM/` — targeted UVM sequence, relevant coverage, and preserved UVM logs.
- `README.md` — what failed, why it failed, how verification exposed it, and the fix.

The final fully corrected RTL is `BUG4/RTL/after_fix.sv`.

## Evidence policy

Only real simulation logs already preserved in the repository are copied here. Missing historical runs are explicitly marked in `RUN_STATUS.md`; no simulation output is fabricated.
