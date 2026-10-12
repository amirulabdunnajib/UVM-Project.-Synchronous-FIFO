The FIFO is a **queue of up to 16 items**, and `count` is the single source of truth. Each clock cycle works like this:

1. Look at the state **before** the edge (`count`, so `full` and `empty`).
2. Decide which operations are accepted:
    - write accepted = `wr_en && (!full || rd_en)`
    - read accepted = `rd_en && !empty`
3. At the edge, apply the accepted operations. All outputs update **after** the edge.

Nothing in the same cycle can change the decision. That's why R6 works with no extra logic.

## Behavior table: what happens to `count`

|State|idle|write only|read only|write + read|
|---|---|---|---|---|
|**Empty**|0|1|0, read ignored (underflow)|1, read ignored, write accepted|
|**Mid**|same|+1|-1|same|
|**Full**|16|16, write ignored (overflow)|15|16, both accepted|

That's 12 cells. A verification engineer's job is to make sure **every cell is hit and checked**. The four unusual cells are empty+read, empty+both, full+write and full+both. That's where designers make mistakes.

## Timing of outputs

- `full` / `empty`: change one cycle after the operation, because they come from `count`.
- `rd_data` and `rd_valid`: appear one cycle after an accepted read.
- `overflow` / `underflow`: pulse one cycle after an ignored write or read.

## Questions a verifier asks about this spec

1. What is `rd_data` on a cycle with no read? It must hold its value.
2. What if reset arrives in the same cycle as `wr_en`? Reset wins.
3. Does `wr_data` matter when `wr_en = 0`? It should not; drive junk to prove it.
4. Do pointers and `count` always agree after wrap-around? This needs more than 16 writes in total.
