# Directed simulation status

The historical read-empty directed test and its real log are preserved as `read_empty_baseline.*`. That test covers EMPTY + read-only, which passes even in the BUG4 RTL.

`tb_bug4_empty_both.sv` is the focused test for the missing EMPTY + write/read corner. A separate VCS log for that focused directed test was not preserved in the source repository. The real failing and passing evidence for this exact corner is preserved under `../UVM/`.
