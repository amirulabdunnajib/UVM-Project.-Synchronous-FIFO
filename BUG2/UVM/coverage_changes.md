# Coverage impact — BUG2

No new functional-coverage bin was needed to detect BUG2. Reset correctness is primarily a **checking** problem, not a coverage problem.

The existing `cp_reset_at` bins record where reset starts. The scoreboard and asynchronous-reset assertion must check that `overflow` and `underflow` are both 0 while reset is active.
