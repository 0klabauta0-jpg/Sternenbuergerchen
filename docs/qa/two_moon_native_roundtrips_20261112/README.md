# Echte neue Mond-Rundflüge, 12.11.2026

Geprüfter Source: `2f37621a69a328c908b5d9cd1ab236ec80b2a61c`,
`task/two-moon-native-20261112`, Godot4.6.2, normale Geschwindigkeit1×.
Der Weltraumchat führte diesen Lauf exklusiv aus; Root archiviert dessen
unveränderte Originalbelege. Root hat keinen zweiten Lauf daraus behauptet.

Ergebnis: **CAMPAIGN_TWO_MOON_ROUNDTRIPS passed=84 failed=0**, Exit0.
A und B jeweils echte512×256/131072 Tiles; A auf Glut1a, B auf Glut1b.
Ursprüngliche Crew, tatsächliche Starts, Orbit-/Warpbewegung und Landungen.
A: Fußmarsch, tatsächliches Satelliten-Use, Heimflug, Landung, Datenabgabe.
Dadurch B regulär freigeschaltet. B: Anflug, Landung, Absetzen, tatsächliches
Wiederboarding und ausdrücklich abgebrochener Besuch, dann physische Heimkehr.
**Keine B-Auftragserfüllung behauptet.** Kein Actor-/Positions-/HP-/Fortschrittspatch.

Nach A-Upload wurde ein regulärer Heimatcheckpoint geschrieben und über den
Store eingelesen. Die Kopie ist bytegleich, keine manuell aufgebaute Freischaltung.
Ein Store-Read ist kein Scene-Continue. Orbit-Opt-in war nur im Test explizit
aktiv; Produktstandard bleibt ausgeschaltet, Polisa direkter Reiseweg.
Lokales Flug-Save/Continue, nativer Renderer, Sicht-/Stilabnahme, allgemeine
Performance, Netzbetrieb und Produkt-EXE sind durch diesen Lauf nicht belegt.

Originalprofil:
`C:/Users/bjoer/AppData/Local/Temp/codex-two-moon-native-fixed-503c8fc727e54ef1bf660c8504c185aa/`

Unveränderte archivierte Dateien:
- `roundtrips.log`, SHA256 `bae676c1249d0a953928ba163ce7abd8a4aa5c1e32d3a92725590bc399f6cf14`
- `source_a_upload_checkpoint.json`, SHA256 `aa6841f32b7cdd00fe7506d8c4960ebe4a76fe41416633f12e3e50770b2c7618`

Früherer Lauf71/1 bleibt im ursprünglichen Profil erhalten: Das Test-Warten
akzeptierte eine veraltete A-Missionsinstanz. Ein fokussierter Test reproduzierte
den tatsächlichen Legacy-Fallbackfehler;2f37621a6 begrenzt ihn anhand des
Craft-Standorts und wartet zielgenau auf die angeforderte Karte. Erst der hier
archivierte Wiederholungslauf liefert den84/0-Nachweis der neuen Zuordnung.
