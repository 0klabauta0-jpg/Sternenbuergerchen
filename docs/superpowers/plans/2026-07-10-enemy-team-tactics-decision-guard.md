# Enemy Team Tactics Decision Revision Guard

**Goal:** Avoid recomputing the same enemy cover/LOS decision every authoritative tick while preserving immediate reaction to meaningful tactical changes.

**Result:** Identical input skips the tactics rebuild; Friendly movement rebuilds immediately. The real start trace completed eight visible frames in about 4.8 seconds instead of exceeding 20 seconds after five frames. The next blocker is `lz_drop_and_deboard`.
