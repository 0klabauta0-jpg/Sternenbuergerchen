# Lokaler Türschutz: enge Integration

e4c098f63 nach unabhängigem Readonly-Review als 26303641d auf ce57b07f7
übernommen. Produkt automatisch zusammengeführt. Nur additive Statusabschnitte
konfliktbehaftet; beide erhalten. Warp-/Pickup-/Resource-/ShipReturnbereiche bewahrt.

Frischer gemeinsamer isolierter Lauf:
`python scripts/tests/run_hex_tactical_check.py --case door_guard`.
58 bestanden, 0 fehlgeschlagen einschließlich 42 Grundchecks. Prozess 0,
Quell-/Profil-/Canaryguards grün; konkrete Quellhashes im Report.
Tatsächlicher Driver, Root und Ground: Belegung, beide Kantenenden bis Abschluss,
vollständige Passagegrants, fehlender/inaktiver Owner und Legacyzweig geprüft.
Abgelehnter Türschluss verändert weder Ressourcen noch Bewegungszusagen.

Quell-Nachbarcases nicht erneut separat gestartet. Keine Produktionskarte,
native Spielweg-/Performance-/Save-/MP-Abnahme oder große Testmatrix.
Noch offen: AP5 Backoff, AP6 Lifecycle, AP7 Restore/Authority, AP8 Kandidat.
