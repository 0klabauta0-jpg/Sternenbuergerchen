# TASK 1197 — Selected combat hotspot

Variant A (Pair Search) is fixed by P01 evidence: fire-find-contact-pair median 38276 usec, contact-tracking 20011 usec, enemy-team-tactics 24648.5 usec. This task adds only debug-gated, read-only counters for candidate filtering, range/attackability, cache-key construction, LOS-cache lookup and terrain LOS evaluation. No selection, gameplay, snapshot or authority behavior changes are allowed.

Acceptance: the real 16v12 verifier is RED before the debug surface exists and GREEN after instrumentation; TASK-1196 remains 12/12; one cold TASK-1187 diagnostic selects exactly one largest substep for Task 2 without changing it.
