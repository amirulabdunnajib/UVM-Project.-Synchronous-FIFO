# RTL History

The uploaded project snapshot contains a clear five-version DUT progression. Each numbered version changes one intentional defect while leaving later defects in place, which makes it useful for verification regression.

| Version | Change from previous | Bug closed |
|---|---|---|
| `fifo_dut_v1.sv` | Original bugged DUT | — |
| `fifo_dut_v2.sv` | `write_accepted = wr_en && (!full || rd_en)` | BUG1 |
| `fifo_dut_v3.sv` | Reset initializes `overflow` and `underflow` to 0 | BUG2 |
| `fifo_dut_v4.sv` | `rd_data` updates only on `read_accepted` | BUG3 |
| `fifo_dut_v5.sv` | `underflow <= rd_en && empty` | BUG4 |

`fifo_dut_v5.sv` is the final corrected RTL used for the completed regression.

The `early_drafts/` directory contains earlier hand-written learning versions. They are preserved as design-development history and are **not** the v1→v5 bug-injection sequence.
