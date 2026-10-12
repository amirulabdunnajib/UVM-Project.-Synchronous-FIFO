# Directed Test Development

The directed tests were used before and alongside UVM to understand the FIFO specification, isolate the first failing behaviour, and convert concrete checks into reusable UVM stimulus/checking.

- T1–T4: reset behaviour (already preserved under `BUG2/Directed_Test/`).
- T5: full + simultaneous write/read; the test that exposed BUG1 (under `BUG1/Directed_Test/`).
- T6: first small read-at-empty/underflow experiments.
- T7: stronger read-at-empty test that establishes a known held value and checks R10 explicitly; this supports BUG3.

The draft files are intentionally retained because they show how the tests evolved into self-checking versions.
