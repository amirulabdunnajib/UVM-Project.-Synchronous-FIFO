**23 failures out of 71 checks.** The testbench ran 71 comparisons (3 after the fill, 7 in the both-cycle, 10 in the idle cycles, 48 in the drain, 3 at the end), and 23 of them didn't match. It also ran cleanly on VCS and opened the waveform, so your setup works.

## It's probably not 23 bugs

`errors` counts **failed checks**, not bugs. One bug can fail many checks, because each wrong value carries into the later ones. Always debug the **first** failure and treat the rest as possible follow-ons.

Here is the first failure, at t=196:

```
full+wr+rd | count=15 full=0 ...
FAIL count = 0f, expected 10   (hex: 15 vs 16)
FAIL full = 00, expected 01
```

Spec R5 says `count` stays 16 and `full` stays 1. Look at the later lines: every `count` check in the drain is off by exactly one, and the 16th read returns `rd_data = 10` with `underflow = 1`. Those are consequences of the first failure. You can use them as clues, and the question to answer is: what happened to AA?

## Should you fix the RTL now?

**No. Don't fix it, and don't wait for UVM to find it.** The directed test just did its job: it found a bug. What you do next is what a DV engineer does:

1. **Write a bug report** and don't edit the RTL. A verifier reports the bug, and the designer fixes it.
2. **Keep this DUT as it is.** When the UVM environment is ready, it should find this same bug on its own. That proves the environment works.
3. After your report, I'll act as the designer and give you **v2 with this bug fixed**, so you can keep hunting the other ones.

Your directed test isn't wasted when you move to UVM. `expect_eq` becomes the scoreboard check, and the T5 sequence becomes a UVM sequence.

## Bug report template

|Field|Content|
|---|---|
|Test|T5, step "full+wr+rd"|
|Rule|R5|
|Stimulus|FIFO full, then `wr_en = 1`, `rd_en = 1`, `wr_data = AA`|
|Expected|`count = 16`, `full = 1`, `rd_data = 10`|
|Actual|`count = 15`, `full = 0`, `rd_data = 10`|
|Evidence|log line at t=196, plus the waveform|
|Suspected cause|**your turn**|
|Suspected RTL area|**your turn**|

Open the waveform and `fifo_dut.sv`, and fill in the last two rows: what do you think happened to AA, and which line of the RTL would cause it? Send it and I'll tell you if you're right.