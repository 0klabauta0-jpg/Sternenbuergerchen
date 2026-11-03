# Native UI R3 · 02.11.2026

[Vergleichs-Workbench mit JSON-Export](../../reports/STERNENBUERGERCHEN_UI_NATIVE_R3_2026-11-02.html). Sie zeigt die vier betroffenen Screenfamilien und 13 echte native Ansichten, jeweils mit R2-/Konzeptvergleich. Der maschinenlesbare Abschlussstand steht in `VERIFIKATION.json`.

## Sichtbares Ergebnis
- Leerer Heimatbasis-Truppbereich: 128 statt 848px hoch; leeres FOB-Flugdeck: 176 statt 712px. Belegte Bereiche wachsen und scrollen über dieselben bestehenden Arbeitsorte.
- Kurzer Debrief: zentriertes Fenster 1240×624 statt 1872×1032px, im Standardbeispiel rund 60 % weniger Fensterfläche. Keine Auswertungsdaten bedeuten einen kurzen Hinweis statt einer großen leeren Karte.
- Klare deutsche Hauptanzeigen für Vorbereitung, Zuordnung, Ausrüstung, Transport, Einsatzziel und Planstatus. Rohinformationen bleiben über Details/Originalbericht erreichbar. Personal und Ausrüstung behalten stabile Arbeitslisten.
- Fehlende Werte bleiben unbekannt; Vorschau und bestätigte Folgen sind getrennt. Aktive Pläne verlangen keinen erneuten Start; abgeschlossene leere Rückflüge werden nicht als unterwegs gezählt.
- Originalbericht mit echten Maus-/Tastaturgrenzen. Volle Haltungswörter auch nach Hintergrundaktualisierung; AAR-Werte bleiben vor gekürzten Bezeichnungen sichtbar.

Messdaten: `density_comparison.json`; tatsächliche native Rects stehen auch in den einzelnen Capture-Metadaten unter `ui_metrics`. R2-Werte beziehen sich auf dessen beibehaltene native Bilder und den zugehörigen Quellstand `b1342b939`.

## Funktion, Renderbild und Review trennen
`checks_final.json` enthält die 19 betroffenen Checks: drei neue R3-Verifier und die relevanten bestehenden A5-/Shell-/Vorbereitungs-/Fenster-/Command-/LZ-/Feuerregel-/Hotpath-/Debrief-Datenchecks. Akzeptiert wird pro Check ausschließlich der letzte saubere Lauf mit positivem Assertioncount, richtigem Endmarker, Exit0 und ohne Godot-/Leakfehler. Nach Korrekturen werden nur betroffene Teilmengen wiederholt. Ältere RED-/fehlgeschlagene Logs bleiben nachvollziehbar erhalten.

Abschluss: **19/19 Checks mit 1.617 bestandenen Assertions**, 13/13 echte native Captures und 10/10 Offline-HTML-Prüfungen. Die final betroffenen Debriefchecks (R3, R2-Shell, TASK588/593) wurden nach dem letzten Geometriefix erneut sauber ausgeführt. Alle fünf Debrief-Captures belegen tatsächliche Rückwegzeile=Slot und Umschließung durch die Rückwegkarte; auch reine Ancestorverschiebungen und Datenwechsel derselben Screeninstanz sind abgedeckt.

Der Editorimport wurde einmal zentral durchgeführt: Editorplugins nur vorübergehend deaktiviert, GDExtensions erhalten, `project.godot` bytegenau wiederhergestellt. `import_result.json` protokolliert Exit0 ohne Fehler. Es wurden keine Spielassets ersetzt und keine Goldens automatisch überschrieben.

Die Eingabeprüfungen verwenden echte `InputEvent`-Ereignisse für Durchklick, Tab, Shift-Tab und Enter. Fokus-/Gates-/Resultatprüfungen bleiben von sichtbaren Text-/Font-/Contentbreitenprüfungen getrennt. Kurze Teilberichte, nicht angewandte Awards, echte GO-Callbacks und bestehende Rückflugfilter haben eigene Regressionen. Ursachen und unabhängiger Review: `REVIEW.md`.

## Native Captures
`capture_r3.py` startet Godot 4.6.2 mit Windows-/GL-Compatibility-Renderer und echten Produktionsszenen. Vier Standardansichten werden bei jeweils physisch und logisch 1920×1080 sowie 1280×720 gerendert. Dazu kommen Full-HD-Fixtures für leeres, umfangreiches und partielles Debrief, belegte FOB und Teams am Boden. Metadaten, PNG-Hashes und Logs dokumentieren jeden Lauf.

Fixtures sind ausdrücklich Beispiele und Stresstests vorhandener Datenverträge, keine behaupteten abgeschlossenen Gameplayeinsätze. Der Rich-Bericht verwendet 12 Personen, 24 AAR-Zeilen und eine aus expliziten Testupdates durch den vorhandenen Resolverhelfer gebaute Awardsummary. Personenzahl/AAR-/Awardflags stehen im Capture-Summary. Kein Actor-/Save-/Runtimepatch wird als physischer Gameplaynachweis ausgegeben.

## HTML und Übergabe
Die Workbench ist aus der bestehenden R2-Workbench abgeleitet. JSON-Export erfasst alle 13 Ansichten einschließlich ausgeblendeter Notizen, Bewertungen und Prüfkontext. Der Offline-Node-VM führt das echte Inline-JavaScript mit minimalem DOM aus und prüft Tabwechsel, Fokus/Dialog, Exportdateinamen, Unicode, Clipboard-Fallback und alle lokalen Bildpfade. Das ist keine Browser-Layout-/Downloadfreigabe. Die bestehende file-Protokollgrenze wird nicht umgangen.

Die im Seitenfenster oft noch offene Konzeptseite erhält einen sichtbaren R3-Link. Ihr JavaScript und ihre Notiz-/Exportfelder bleiben bytegleich erhalten; `concept_navigation.json` belegt dies. Kein automatisches Weiterleiten oder Löschen vorhandener Exporte.

```powershell
python C:/Users/bjoer/.codex/skills/godot-game-verification/scripts/run_checks.py --project . --manifest docs/qa/ui_native_r3_20261102/checks_final.json --godot godot_console --skip-import --output docs/qa/ui_native_r3_20261102/checks_repro
python docs/qa/ui_native_r3_20261102/capture_r3.py
node docs/qa/ui_native_r3_20261102/html_qa.cjs
python docs/qa/ui_native_r3_20261102/verify_r3.py
```

## Grenzen / Gitbasis
Kein vollständiger menschlicher Durchspieltest, keine reale Mehrspielerpartie, kein Release/EXE-Export und keine Langzeit-Performanceabnahme. Die bestehende Lobby-Payload-Netzwerklücke liegt außerhalb dieses Passes. Nicht betroffene ältere Detail-/Rollentexte werden nicht pauschal neu lokalisiert.

Branch `task/ui-verdichtung-r3-20261102`, bewusst auf noch nicht integriertem R2 `b1342b939`, Integrationsbasis `3cae5a216`. Hauptcheckout und R1-/R2-Nachweise bleiben erhalten. `SOURCE_SNAPSHOT.json` fixiert die finalen Quelldateien; `VERIFIKATION.json` verbindet akzeptierte Einzelruns, native Bilder, Offlineprüfung und Artefakthashes.
