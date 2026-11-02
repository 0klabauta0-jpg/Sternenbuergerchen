# Zielbild-QA · 02.11.2026

Begrenzte Zielbildrunde lokal geprüft. Alle Aufrufe ausschließlich nacheinander; sie setzen während des jeweiligen Engineprozesses temporär eine eigene `user://`-Namespace in `project.godot` und stellen anschließend die ursprünglichen Bytes auch bei Fehler/Timeout wieder her. Kein anderer Engine-/Importprozess darf gleichzeitig laufen. Die Wrapper brechen bei bereits gesetzter eigener Userdir ab.

## Gewählte finale Ergebnisse

- Acht Engine-Gates / **857 Assertions**, alle grün: `headless/20261102T161521_480369Z/checks/20261102T161521Z-pid142392/metadata/report.json`.
- Zwei echte normale Startläufe / **102 Checks**, je 51, Exit0 ohne Script-/Leakfehler: `normal_start/20261102T162357_805920Z/capture_results.json`.
- Sechs separate echte Fixturebilder bei beiden Auflösungen: `fixtures/20261102T162723_807177Z/capture_results.json`.
- Zehn Offline-HTML-/Exportchecks: `html_export_qa.json`. Keine Browserlayoutabnahme.
- Direkte Originalanalyse: `BILDVERGLEICH.md`; neue native Bildnachprüfung und konkreter Gebäude-Renderpfad: `NACHPRUEFUNG.md`; gefundene/korrigierte Funktionsbefunde: `REVIEW.md`.

Die zwei früheren Normalstart-Vorläufe wurden wegen Ogg-Bewegungs-Audioobjekten beim Exit verworfen, trotz bestandener funktionaler Route. Der neue Testadapter wartet nur nach dem Entfernen der Spielszene 350ms auf Audiofreigabe. Gameplay, Audio-Produktionscode und Warnfilter sind unverändert. Frühere rote Gate-Läufe bleiben Rohbelege; sie sind keine finale Abnahme.

Arbeitsbasis ist bewusst der noch nicht integrierte GM01-Branch `6e05e080d` mit dessen UI-R4-/Main-Grafikbasis. Keine Mainänderung oder Integration. `source_snapshot.py` friert die explizit gewählten finalen Quellen und Bilder ein; Standardaufruf verifiziert nur, ohne neue Hashes zu übernehmen.

Jeder Aufruf legt einen neuen UTC-Zeitstempelordner in dieser Runde an. Bestehende GM01-/R4-Berichte, Bilder und Hashpins werden weder überschrieben noch aktualisiert. Fehlgeschlagene Ausgaben bleiben sichtbar. Normale Mission und Fixturebilder sind getrennte Nachweisarten.

## Kleine Regressionauswahl

Einmaliger isolierter Import nach Quellen-/Assetänderungen:

```powershell
python docs/qa/ui_zielbild_20261102/import_once.py
```

Dieser Import deaktiviert vorübergehend ausschließlich die `[editor_plugins]`-Liste; GDExtensions bleiben aktiv. Eigenes Importprofil, 180-Sekunden-Grenze und neuer Ordner `import/<Zeitstempel>/` mit `import.log` sowie `import_result.json`: Exitcode, Fehler, `passed`, ursprünglicher/testweiser Projekt-SHA und bytegenauer Wiederherstellungsnachweis. Erst nach erfolgreichem Import die Gates ohne erneuten Import starten:

```powershell
python docs/qa/ui_zielbild_20261102/run_isolated_checks.py --skip-import
```

Das Manifest verwendet acht vorhandene Gates: Hex-FoW, Hex-Rebuild, UI A5, Shelllayout, R2-Vorbereitung, R2-Missionsfeedback, R3-Missionsanzeigen und exakte R4-Cutlass-Identität. `--filter hex` wählt nur passende Namen daraus. Standardmäßig ist der Import des installierten `godot-game-verification`-Runners aktiv. Nach erfolgreichem `python docs/qa/ui_zielbild_20261102/import_once.py` kann derselbe unveränderte Checkout mit `--skip-import` geprüft werden. `--godot` erlaubt den expliziten Enginepfad. Ergebnisse unter `headless/<Zeitstempel>/checks/<Runner-Zeitstempel>/metadata/report.json`; vollständiges Runnerlog und Profilwiederherstellung daneben.

Callback-, Zustands- und Identitätsprüfungen bleiben erhalten. Der A5-Geometriewert wurde bewusst auf 52px-Aktionen und 128px-Band geändert; zusätzliche echte Rect-/Pending-/Kontextfeedback-Assertions sichern die Verdichtung ab. Kein pauschales Nachziehen alter Hashpins.

Statischer Schreibpfad-Audit dieser sieben Gates: Hex-Rebuild schreibt Roundtrips und Ergebnis nach `user://`; Shelllayout verwendet nur seine expliziten `user://native_ui_shell_fixtures`. Die anderen fünf enthalten keine direkten Dateischreiber. Der alte `frontier_runtime_map_slice_verifier.gd` mit historischem `headless_check.json` ist nicht ausgewählt. Der Hex-Rebuild nutzt vom Offline-Autor ausschließlich die statischen `compose_payload`-/`validate_payload`-Funktionen; dessen Writer-Initialisierung wird nicht gestartet. Dies ist ein Quellenbefund, kein ausgeführter Laufzeitnachweis.

## Normaler Spielstart bei beiden Zielgrößen

```powershell
python docs/qa/ui_zielbild_20261102/startup_ui_zielbild.py
```

Forward+/Vulkan, echte Route Menü → Heimatbasis → gespeicherte GM01 → echte Transportzeit → LZ → Ausladen → Bewegen/GO. Der neue Captureadapter erweitert denselben Normalstart-Verifier wie die alte GM01-Runde und prüft seine eigene Userdir exakt. Kameraansichten und Capture-IDs bleiben vergleichbar: `06_go_movement`, `07_outpost_overview`, `08_eastern_supply`, `09_expanded_map`. Kein Fixture, keine Zeitbeschleunigung und keine privaten Simulationsänderungen. PNGs, Kameraangaben, SHA-256, Startupbericht und Logs unter `normal_start/<Zeitstempel>/<Größe>/`. `capture_results.json` verweist auf die unveränderten Originaldateien; es wird keine alte Bilddatei ersetzt.

Teilaufruf: `--sizes 1280x720`. Der Wrapper überprüft die Bildmaße und Hashes sämtlicher vom Verifier gemeldeter Captures. Technisch vorhandene Rasterlinien ersetzen keine menschliche Prüfung ihrer Erkennbarkeit im tatsächlichen Spielabstand.

## FOB, Heimatbasis und Nachbesprechung

```powershell
python docs/qa/ui_zielbild_20261102/capture_ui_zielbild.py
```

Sechs echte native GL-Compatibility-Captures: befüllte FOB (`populated`), Heimatbasis mit Teams (`teams`), Nachbesprechung mit Portraits (`portraits`), jeweils 1920×1080 und 1280×720. Dieser Wrapper nutzt unverändert `ui_native_capture.gd` mit neuem Ausgabeordner, eigenem Fixture-Scope und eigener Userdir. Er zeigt bewusst Testdaten; die Bilder sind kein normaler Missions- oder Transportnachweis. Ausgaben unter `fixtures/<Zeitstempel>/captures/`, Logs und Ergebnisliste daneben.

Teilaufrufe: `--views fob`, `--sizes 1280x720`; für dieselben Standardfixtures wie früher `--variants standard`. Für alle zwölf angebotenen Fälle: `--variants standard populated teams portraits`.

## Quellen und gewählte Nachweise einfrieren

`source_snapshot.py` legt von selbst keine Hashdatei an. Erst nach finalen Quellen, tatsächlich erfolgreichen Captures und erzeugtem Report ausdrücklich einfrieren, mit den vom jeweiligen Wrapper ausgegebenen echten Pfaden:

```powershell
python docs/qa/ui_zielbild_20261102/source_snapshot.py --record --normal-result "docs/qa/ui_zielbild_20261102/normal_start/<UTC>/capture_results.json" --fixture-result "docs/qa/ui_zielbild_20261102/fixtures/<UTC>/capture_results.json" --report "docs/reports/<tatsaechlicher-neuer-report>.html"
```

Der Snapshot enthält relevante aktuelle Code-/Dokumentbytes aus `git diff HEAD --name-only`, feste Normalstart-Parents, die sieben Gatequellen, QA-Helfer, GM01-Map/Szenario, das exakte Cutlass-Modell mit Previewprovenienz sowie die ausdrücklich gewählten Capturemanifeste, deren native PNGs/JSON und Reportbytes. Direkt im Report referenzierte lokale Ziel-/Spielbilder werden ebenfalls eingefroren. Neue ungetrackte Assets oder weitere Quellen ausdrücklich mit wiederholtem `--source Pfad` angeben. Keine rekursive Assetsuche. Ein vorhandener Snapshot wird nicht überschrieben; für eine bewusst neue Aufnahme `--snapshot docs/qa/ui_zielbild_20261102/<neuer-name>.json` wählen.

Danach prüft der Standardaufruf ausschließlich die bereits gespeicherten Hashes und Bytegrößen. Er führt weder Git noch Engine aus und aktualisiert keinen Erwartungswert:

```powershell
python docs/qa/ui_zielbild_20261102/source_snapshot.py
```

Bei einer anders benannten Aufnahme denselben `--snapshot`-Pfad auch beim Prüfen angeben. Ein Quellen-SHA ersetzt weder Funktionsprüfung noch menschlichen Bildvergleich.

## Grenzen

Die Wrapper prüfen Prozess-/Rendererfehler, echte unskalierte Bildausgaben und gezielte Funktionsgates. Stilnähe, Rastererkennbarkeit und Erfüllung der 2D-Ziele müssen an geöffneten Originalbildern bei beiden Größen zusätzlich beurteilt werden. Keine pauschale Gameplay-, Kampagnen-, Leistungs-, Export- oder Releaseabnahme. Die Helfer selbst starten beim Anlegen weder Engine noch Import; Python-/JSON-Prüfung ist davon getrennt.
