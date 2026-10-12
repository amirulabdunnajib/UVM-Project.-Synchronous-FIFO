# Directed simulation status

The uploaded local snapshot supplied the missing T7 material.

- `../../DIRECTED_TESTS/T7/t7_final.sv` is the strengthened self-checking test.
- `../../DIRECTED_TESTS/T7/simulation_after_bug3_fix.log` is the preserved passing VCS run.
- The test explicitly proves that rejected reads at EMPTY do not move `rptr` and do not change the last valid `rd_data`.
