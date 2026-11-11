# Polisa R07 — Heimatbasismaßstab und gerade Tragachse

## Ziel / Ursache
S-Pads müssen exakt die Größe des Heimatbasispads verwenden. Die bisherigen18×20 waren7.5-mal dessen Fläche; der Komplex war entsprechend zu groß und leer. R07 ordnet Räume und Pads im menschlichen Maßstab neu, ohne Personen zu verkleinern. R06 bleibt historisch.

## Umfang / Nichtziele
Privates Artpaket mit gemeinsamem Layout, Mapcompiler, statischer GDScriptgeometrie und zwei nativen Bildern. Keine Produktdateien, UI, Runtimewahrheit, Registry, Schiffsfreigabe oder Commits. Root besitzt Integration und optionalen Maßstabsvergleich.

## Maßplan vor Code
S-Größe direkt aus maps/homebase_frontier_exploration.json/homebase_exploration/landing_pads lesen; beide Pads müssen übereinstimmen. M=1.5×S-Breite und2×S-Tiefe; L=2×S-Breite und4×S-Tiefe. Aktuell ergibt das S8×6, M12×12, L16×24. Reserve nur0.65proSeite.

Lobby28×20, fünf Shops12×12, drei unverändert große R07-Schaukästen und unveränderte Globuskonsole. KoncourseX±42/Z18..24. Zwei parallele YZ-Ringe beiX±42, gemeinsame MitteY−12/Z21, Radius24, Querschnitt3.2, Yaw0. Hauptausleger exakt gerade auf dieser X-Achse; Solarstreben orthogonal inZ aufdemselbenY. Keine schrägen Übergänge zu versetzten Ringhubs. AußenportsX±76.

Stationorigin(0,−70), hintere technische Sperrfläche bislokalemZ−20 an WeltZ−90. Karte512×256/Bounds[-256,-90,256,132] bleibt. NahkameraSize62/Yaw24/Pitch50 auflokal(0,14) soll einzelne Hexfelder am S-Pad zählbar zeigen. WholeMap ehrlich vollständig.

## Grundlagen / Akzeptanz
AGENTS.md, PROJECT_BRIEF, ARCHITECTURE, CODEX_RULES, IMPLEMENTATION_STATUS und graphics_reference_revision_contract.md; godot-procedural-worlds. Bestehende R06-KI-Referenz nur für Stil, aktuelle Maße kommen aus der Heimatbasisquelle. Ein Hub/fünf Shops/sieben Pads/zwei Ringe. Gleiche Fakten für Deck/Blocker/Marker; alle Raum- und Padanker erreichbar; S-Größe exakt owning source; Ringachsen identisch und Ausleger rechtwinklig. Kein per-frame Neuaufbau.

## Prüfung / Risiken
Kleiner Offlinegraph, Quellenhash, Godotcheck-only, zwei tatsächlich geöffnete native Bilder. GPU nach Root-Freigabe. Größere Tests später. PadreServen sind Entwurfshüllen ohne Schiffsfitclaim. Der512erGesamtrahmen enthält wegen korrekter kleiner Weltmaße viel Raum; Nahaufnahme dient der Detail-/Rasterprüfung.
