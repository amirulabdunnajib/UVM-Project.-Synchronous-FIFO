# Directed simulation status

The historical `original_reset_test.sv` and its real log are preserved here. That test did not check `overflow`/`underflow`, which is why BUG2 escaped it.

`tb_bug2_reset_flags.sv` is the focused regression added for the discovered gap. A separate VCS run of this focused directed test was not preserved in the source repository, so no fabricated before/after log is included.
