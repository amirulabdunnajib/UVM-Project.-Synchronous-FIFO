# Coverage impact — BUG4

BUG4 was exposed after expanding the stimulus to cover the missing **EMPTY x write_read** cell.

The later coverage class also prints the full 3 x 4 level/operation hit grid, making holes visible in the simulation log. This does not replace the scoreboard: coverage proves the corner was exercised; the scoreboard detects the wrong underflow value.

- `coverage_before.sv` — original covergroup/cross.
- `coverage_after.sv` — same functional coverage plus explicit grid hit counters and hole reporting.
