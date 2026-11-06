# R3: Ruckelspitzen und Referenznaehe

Diese unabhaengige Evidenzserie begann am 6. November und wurde am 7. November
2026 fortgesetzt. Basis ist Main `173a1e3c33b733a78a396a93db9cedf631d84998`.
Historische QA, Rohbelege und geschuetzte Roster wurden nicht neu erzeugt.

`REPORT.md` bewertet die Ergebnisse und ihre Grenzen. `analysis.json` fasst
die unveraenderten Originalmessungen zusammen. `manifest.json` bindet Kopien
und Archivdateien jeweils an ihren Originalpfad und SHA256; diese Ausgabepins
sind keine Quellpins. Quellpins stehen in den jeweiligen Laufreports und in
der getrennten finalen Quellenliste unter `binding/`.

Das ZIP enthaelt auch die grossen Frame-/Tick-Rohdaten. Native PNGs werden
byte-identisch kopiert, niemals neu gerendert oder nachbearbeitet. Originale
2D-Ziele, Vorherbilder, Presenterfixtures, kontrollierte GPU-Pruefung und der
normale Spielerpfad sind klar getrennt. Eine technische Freigabe ersetzt
keine persoenliche gestalterische Nutzerabnahme.

Portable Pruefung nach dem Entpacken: `python -B verify_package.py`.
Im Repository `python -B verify_package.py --zip --originals`. Das Skript prueft Ausgaben, Originale,
Archivmitglieder und komplette ZIP-Bytes. Build und Vergleich sind ausserhalb
der Performancefenster auszufuehren.

`main_receipt.json`, `main_sources_index.json`, `main_preservation.json` und
`main_smoke/` sind getrennte Integrationsbelege nach dem eingefrorenen Paket.
Das Paket wird nach Main nicht neu beschriftet. Diese Runde verspricht keine
neue EXE, keinen Release und keine WAN-/Multiplayerabnahme.
