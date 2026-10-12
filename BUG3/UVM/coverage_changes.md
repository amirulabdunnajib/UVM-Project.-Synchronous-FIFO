# Coverage impact — BUG3

The existing `EMPTY x read_only` cross proves the rejected-read stimulus happened. No special output-value coverage is required: whether `rd_data` holds is a scoreboard/assertion responsibility.

The important verification change is the sequence: it first creates a non-zero known held value, then performs a rejected read while empty.
