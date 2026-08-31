# TASK 1197 — Selected combat hotspot

Variant A (Pair Search) is fixed by P01 evidence: fire-find-contact-pair median 38276 usec, contact-tracking 20011 usec, enemy-team-tactics 24648.5 usec. This task adds only debug-gated, read-only counters for candidate filtering, range/attackability, cache-key construction, LOS-cache lookup and terrain LOS evaluation. No selection, gameplay, snapshot or authority behavior changes are allowed.

Acceptance: the real 16v12 verifier is RED before the debug surface exists and GREEN after instrumentation; TASK-1196 remains 12/12; one cold TASK-1187 diagnostic selects exactly one largest substep for Task 2 without changing it.

## Task-3 Evidence (PASS)

Gemessen auf Produktions-SHA `24f340d59dddd8ef59d69e617d3eac895eadeda4`, Ryzen 7 7800X3D / 64 GB / Windows 10 19045 / Godot 4.6.2. Cold-Kontrolle: Exit 0, SHA korrekt; combat 99039, fire decision 40518, pair search 34635, contact tracking 21122, enemy-team-tactics 27032, simulation 100346, command queue 55458 usec.

Die vollständige Serie (3 cold, 5 warm; jeweils in Reihenfolge) lieferte acht Exit-0-/SHA-identische JSON-Zeilen. p99 usec je Zeile: combat `96388, 96113, 98287, 97086, 100202, 97334, 95232, 100785`; fire decision `37020, 38645, 40362, 39892, 39442, 40098, 40334, 45633`; pair search `30095, 32610, 32501, 32951, 32702, 33586, 33762, 39599`; contact tracking `20934, 20541, 20836, 21701, 20641, 22062, 20269, 23558`; enemy tactics `23221, 23435, 23952, 22922, 25902, 24259, 20402, 27397`; simulation `97556, 97451, 99588, 99067, 101706, 98538, 96461, 103981`; command queue `53883, 52784, 53196, 54565, 54417, 54260, 51964, 55232`.

Sortierte Min/Max/Median: combat `95232/100785/97210`, fire decision `37020/45633/39995`, pair `30095/39599/32826.5`, contact `20269/23558/20885`, enemy tactics `20402/27397/23693.5`, simulation `96461/103981/98802.5`, command queue `51964/55232/54071.5` usec. Der Effect-Gate ist PASS: pair `<38276` (-14.2374 %), contact +4.3676 % `<=21011.55`, enemy -3.8745 % `<=25880.925`, fire -10.3070 % `<=46820.55`. Combat-/Simulation-Gesamtbudgets bleiben überschritten; Release bleibt blockiert. Direkte Regressionen: TASK-1197 33/33, TASK-1196 12/12, TASK-1191 12/12, TASK-162 23/23, TASK-208 57/57, TASK-218 81/81. Nächstes Paket: TASK-1198 Command-Type-Attribution; Dynamic Overlay/FoW bleiben separate Folgearbeiten.
