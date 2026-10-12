# BUG3 — `rd_data` changes on a rejected read

## Failure

After the FIFO becomes empty, another read request is rejected. The specification says `rd_data` must hold its previous accepted-read value, but the faulty RTL still reloads memory whenever `rd_en` is high.

## Specification

**R10:** except during reset, `rd_data` updates only on an accepted read. Otherwise it holds.

## Root cause

Faulty:

```systemverilog
if (rd_en) rd_data <= mem[rptr];
```

Fixed:

```systemverilog
if (read_accepted) rd_data <= mem[rptr];
```

## Reproduction strategy

Fill all 16 entries with known data and drain all 16. The read pointer wraps to address 0 and `rd_data` holds the last item. Issue one extra read while empty. The faulty DUT reloads the known old value from address 0; the correct DUT holds the last read value.

The original BUG1 failure log also contained this symptom at the end of its drain, which is why it is retained as historical evidence here.
