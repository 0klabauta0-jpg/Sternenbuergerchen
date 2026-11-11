# AP5 Gruppen-/Viewkonsumenten im gemeinsamen Stand

Quellcommit 5a8544fea nach unabhängigem Readonly-Review als 6a3f9c535 auf
9874511c4 übernommen. Produktdateien automatisch zusammengeführt. Einziger
Konflikt: additive Abschnitte in IMPLEMENTATION_STATUS; beide erhalten.
Warp-/Polisa-/Orbitbereiche liegen außerhalb der Produktänderungen.

Frischer enger Integrationslauf:
`python scripts/tests/run_hex_tactical_check.py --case movement_consumers`.
65 bestanden, 0 fehlgeschlagen, Prozess 0. Darin enthalten sind die 42
Grundbewegungsprüfungen; keine zusätzlichen 65 Grundtests. Report enthält
Quellhashes sowie erfolgreiche Profil-, Canary- und Sourceguards.

Tatsächliche Root-/Registry-/Actor-/Fireteam- und Viewreaderprüfung im privaten
Godotprojekt. Keine native Render-, Animations-, Spielgefühl-, Gefechts- oder
Performanceabnahme. Keine Karte aktiviert, kein Mainmerge, keine neue EXE.
Quell-Movement42/0 und Security34/0 wurden hier nicht separat wiederholt.

Offen: Türguard, Bewegungsschuss, Backoff und AP6–8. Große Tests später.
