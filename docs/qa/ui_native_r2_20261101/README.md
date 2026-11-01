# Native UI R2 · 02.11.2026

Einstieg: [native Vergleichs-Workbench](../../reports/STERNENBUERGERCHEN_UI_NATIVE_R2_2026-11-02.html). Pro Ansicht sind die neue native Aufnahme, Runde 1 und die bestätigte Bild-KI-Vorlage getrennt beschriftet. Die Workbench bietet Bewertungen, Notizen und lokalen JSON-Export für alle 17 Ansichten.

Abschlussstand: **27/27 Checks mit 1.731 Assertions, 17 native Captures und 10/10 Offline-HTML-Checks bestanden.** Die akzeptierten Einzelruns stehen im maschinenlesbaren Nachweis.

## Änderung und Zweck
- Mission: niedrigeres 160px-Randband, begrenzte 512px-Teamgruppe, 104px-Mitgliederstreifen. Verständliche Haltungssegmente und vier ausgeschriebene Feuerregeln. Vollständige alte Diagnose bleibt über Details erreichbar.
- Feuerregeln delegieren an die bisherigen gegateten Buttons; bestätigter Konsens, Pending und Gemischtzustand bleiben getrennt. Aktionsmarkierungen lesen den vorhandenen Owner. Detailfenster und Dropdown schließen beim Wechsel aus der Mission.
- Heimatbasis: kompaktes Briefing mit erreichbaren Details und drei volle Arbeitsbereiche. Bereits aufs Flugdeck versetzte Teams werden als solche erklärt. Der aktive Zuweisungspfad bleibt Drag-and-drop; seit R1 unsichtbare Legacy-Assign-Buttons werden nicht wiederbelebt.
- FOB: mehr Breite für Team/Loadout, klare Ortsangabe für versetzte Teams, beschriftete native Rüstungs-/Waffenauswahl und ehrlicher leerer Transportzustand. Keine künstliche Transportfreigabe.
- Debrief: echte Ergebnis-, Personen-, FTL-, Ereignis-, Gefechtsauswertungs-, Entwicklungs- und Rückwegkarten aus dem übergebenen Resultat. Fehlende HP bleiben unbekannt; fehlende Ereignisse/Awards werden nicht erfunden. Optional vorhandene Portraitfelder dürfen echte Projektportraits laden.
- Lobby: Verbindung und Sitzungsaktionen bleiben außerhalb der scrollbaren Setupfläche; vorhandene Gates und Kontexthilfe erhalten.
- Audioregler zeigen Kanal und Entwurfswert. Bibliotheksauswahl erhält Controls und Fokus. Reguläre Teams mit niedrigen effektiven Traitwerten können gespeichert werden; Generatorwerte bleiben unverändert.

## Nachweise getrennt lesen
Der maschinenlesbare Abschlussstand und Quellen-/Artefakthashes stehen in `VERIFIKATION.json`. `FUNKTIONSREVIEW.md` erklärt bestätigte Ursachen und verbleibende Grenzen. Rote und fehlgeschlagene Zwischenläufe bleiben als Verlauf erhalten; sie sind keine akzeptierten Endnachweise.

### Gezielte Funktion und Geometrie
`checks_final.json` benennt 27 Checks: neue R2-Lobby-, Missions-, Vorbereitungs-, Debrief/Shell- und Roster-Save-Verifier sowie betroffene bestehende Theme-, Shell-, Karten-, Settings-, Navigations-, Command-, LZ-, HUD-, Consent- und Debrief-Datenchecks. Der Skillrunner verlangt Exit 0, den richtigen Endmarker und einen sauberen Fehler-/Leak-Scan. Die neuen Verifier arbeiten mit echten logischen SubViewports 1920×1080 und 1280×720.

Geprüfte Pfade umfassen die vorhandenen Feuerregel-Callbacks und Sperren, Detailfenster-Lebensdauer ohne Pause, Zuweisung, Rüstung/Waffen, Leaderidentität, Transit-Drag-Sperre, lesende Charakterdetails, Ergebnis-Rückwegsignale, Fokus, Audio-Cancel sowie echtes Erzeugen/Speichern/Laden/Bestätigen/Archivieren. Der Pending-Test ist ausdrücklich eine Präsentationsfixture und kein Netzwerknachweis.

Die Layoutprüfung hat echte späte Container-Sortierungen aufgedeckt. Debrief-Positionen folgen jetzt koaleszierten Slot-Änderungssignalen; Idleframes lösen keine Layoutpolls aus. Bei Vorbereitungsfenstern werden tatsächliche Mindestgrößen berücksichtigt. Historische Prüfziele wurden nur auf aktuelle Besitzer/Bedienpfade umgestellt, nicht um neue Layoutfehler zu übergehen.

Der erste Gesamtlauf hatte 22 akzeptierte Checks und zwei sachlich grüne Debrief-Läufe mit falsch eingetragenem Endmarker. Die richtigen Marker wurden aus den Verifiern gelesen und beide Läufe über den strengen Runner wiederholt. Nach dem Lobby-Fix wurden nur dessen betroffene Checks wiederholt; nach dem unabhängigen FOB-Fokusbefund nur Vorbereitung, Fensteraudit und verschobene Kontexthilfe. `VERIFIKATION.json` benennt pro Check den letzten akzeptierten Lauf; es verdeckt keine älteren Fehlläufe.

### Native Sichtprüfung
`capture_r2.py` erstellt echte Windows-/GL-Compatibility-Viewportbilder mit Godot 4.6.2 und getrennten Testprofilen. Keine Bildersatzfläche. `capture_results.json`, einzelne Capture-Metadaten und Logs dokumentieren jeden Lauf.

Elf Screenfamilien werden bei 1920×1080 gerendert. Mission, Heimatbasis, FOB, Settings, Debrief und Lobby werden zusätzlich bei **physisch und logisch 1280×720** aufgenommen. Das unterscheidet sich bewusst von den skalierten kleinen R1-Bildern. Eine direkte Charakterkarten-Fixture ergänzt echte Produktionscontrols; Personen-/Missionswerte sind Prüfbeispiele.

### HTML
`html_qa.cjs` führt das tatsächliche Inline-JavaScript im Node-VM mit minimalem synthetischem DOM aus. Geprüft werden Umschalten, ARIA/Fokus, Bilddialog, alle verdeckten Reviewfelder, Unicode, eindeutige Exportnamen, Clipboard-Fallback und lokale Bildpfade. Dies ist **keine Browser-Layout-/Downloadfreigabe**. Browserprüfung wurde wegen der bestehenden file-Protokollgrenze nicht erneut versucht; kein Server-/Browser-Workaround.

## Reproduktion
```powershell
python C:/Users/bjoer/.codex/skills/godot-game-verification/scripts/run_checks.py --project . --manifest docs/qa/ui_native_r2_20261101/checks_final.json --godot godot_console --skip-import --output docs/qa/ui_native_r2_20261101/checks_repro
python docs/qa/ui_native_r2_20261101/capture_r2.py
node docs/qa/ui_native_r2_20261101/html_qa.cjs
python docs/qa/ui_native_r2_20261101/verify_r2.py
```
`capture_r2.py --views mission` wiederholt bei Bedarf nur die betroffene Screenfamilie. R1-Bilder werden dabei nicht überschrieben.

## Grenzen / Integration
Kein vollständiger menschlicher Durchspieltest, kein Release-/EXE-/Langzeit-Performance-Nachweis und keine reale Mehrspielerpartie. Der vorhandene UI-Kartendownload in der Lobby ist noch nicht mit einem echten Payload-Transport verbunden; siehe Funktionsreview. Englische Alttexte und technische Blocknummern bleiben teilweise sichtbar. Die Bild-KI bestimmt die Gestaltungsvorlage; interne Modellgedanken werden nicht als Erklärung ausgegeben.

Der Task baut bewusst auf dem noch nicht integrierten R1-Commit `80593f416` und Konzeptcommit `135466b5c` auf; Integrationsbasis `3cae5a216`. Keine Main-Integration und kein Export. Alte Konzept-/R1-Nachweise und der Hauptcheckout bleiben erhalten.
