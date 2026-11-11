# Bewegungsschuss: enge Integration

Quellcommit a74fbab2f nach unabhängigem Readonly-Review als 615327eaf auf
698188f64 übernommen. Produkt automatisch zusammengeführt; nur additive
IMPLEMENTATION_STATUS-Abschnitte konfliktbehaftet, beide erhalten.

Frischer gemeinsamer isolierter Lauf:
`python scripts/tests/run_hex_tactical_check.py --case moving_shot`.
65 bestanden, 0 fehlgeschlagen, Prozess 0. Darin enthalten: 42 Grundchecks.
Profil-/Canary-/Sourceguards grün, Report enthält konkrete Quellhashes.
Selfdamage nutzt einen Snapshot; andere Actors behalten alte Getterpräzedenz.
Kein zusätzlicher RNG-Aufruf, Legacy und stationär ohne Bewegungsabzug.

0.65 bis 0.95 ist vorläufige Balance, keine Nutzerabnahme. Reduzierte Getterzahl
belegt keine FPSverbesserung. Keine neue Karte aktiviert, kein nativer Gefechts-,
Animations- oder Leistungstest. Quell-Nachbarcases hier nicht separat wiederholt.
Türguard, Backoff, AP6–8 und große Tests folgen. Main und EXE unverändert.
