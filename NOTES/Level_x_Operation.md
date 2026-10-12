## Where coverage fits

- **Sequences** decide what stimulus is _sent_. **Coverage** records what situations the DUT _actually experienced_. They answer different questions: "did I try it?" and "did it happen?"
- Coverage is a **subscriber** on the monitor's analysis port, the same wire the scoreboard uses. That's what the `TODO (yours)` lines in `fifo_env.sv` are for: you create it and connect `agt.mon.ap` to it.
- It samples once per observed clock cycle, with one `fifo_item` each time, and a `covergroup` turns that item into bins.

## What to cover (from your plan)

- **Level:** empty, low, mid, high, full.
- **Operation:** idle, write only, read only, write and read.
- **Cross:** level × operation. This holds the 12 cells of the `count` table, including the four unusual ones (empty+read, empty+both, full+write, full+both).
- **Flags:** `overflow` and `underflow` pulses seen.
- **Reset:** reset asserted at empty, mid and full.

One point to think about early: the monitor item has no `count`, only `full` and `empty`. The fill **level** has to come from somewhere else, such as a small model inside the coverage class or from the scoreboard. That's a good design question for us to talk through.

## Sequences

Your current two are directed. The next step is a **random sequence** with weights, plus a few targeted sequences that close the holes coverage reports. That loop (run, read the report, find holes, write a sequence for each) is the verification skill we're aiming for.
