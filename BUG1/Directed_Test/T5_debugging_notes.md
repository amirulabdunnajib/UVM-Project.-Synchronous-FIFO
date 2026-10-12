**23 failures out of 71 checks.** The directed T5 ran 71 comparisons and 23 did not match. Those are failed checks, not 23 independent bugs.

The first failure was at the full+write+read cycle: `count=15` and `full=0` instead of 16/1. Every later count check was then off by one, and the final expected `AA` was missing. The debugging rule used here was: **debug the first failure first; later failures may be consequences.**

The verification follow-up was to keep the failing DUT, write a bug report, then recreate T5 as a UVM sequence so the scoreboard—not the sequence—owned the expected values.
