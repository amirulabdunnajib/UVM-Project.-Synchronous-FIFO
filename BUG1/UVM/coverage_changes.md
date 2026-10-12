# Coverage impact — BUG1

No new coverage class was required to represent this scenario. The existing coverage model already has:

- `cp_level.full`
- `cp_op.write_read`
- `x_level_op` cross

The important stimulus-coverage cell is therefore **FULL x write_read**. The scoreboard determines pass/fail; coverage only proves that the scenario was exercised.
