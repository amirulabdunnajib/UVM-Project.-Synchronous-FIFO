# Directed simulation status

`historical_combined_evidence.log` is a real historical log in which the rejected final read changes `rd_data`; however, BUG1 is also active in that run, so it is not an isolated BUG3 regression.

`tb_bug3_rd_data_hold.sv` isolates R10 cleanly. A separate before/after VCS log for this focused test was not preserved in the source repository, so no synthetic log is included.
