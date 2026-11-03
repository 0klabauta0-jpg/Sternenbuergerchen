# Native UI R3 · Leerraum und verständliche Anzeigen

## Ziel / Problem / Ursache
Der Nutzer beauftragt ausdrücklich, die verbliebenen Leerflächen und unklaren Anzeigen zu beheben. Im aktuellen R2 sind große Panels auch bei wenigen oder fehlenden Daten auf volle Arbeitsflächen gestreckt. Technische Blocknummern, englische Rohzustände und lange Diagnosetexte konkurrieren mit relevanten Spielerinformationen.

## Basis und Umfang
Branch `task/ui-verdichtung-r3-20261102`, von `integration/core-foundation` gestartet und bewusst bis zum noch nicht integrierten R2-Commit `b1342b939` vorgezogen. Hauptcheckout und R1-/R2-Nachweise bleiben erhalten.

- Heimatbasis/FOB: Inhalte und leere Arbeitsorte kompakter anordnen; Teamverwaltung, Dropziele, Transport-/Boardingaktionen und Details erhalten. Statuslabels verständlich benennen.
- Debrief: Fenster/Karten nach spärlichem, leerem und umfangreichem Resultat dimensionieren; fehlende Berichte als kurze explizite Hinweise. Vorschau und bestätigte Folgen trennen.
- Mission: Ziel/Auftrag und obere Statusgruppen zeigen klare bestätigte Spielerzustände; rohe Diagnose bleibt in erreichbaren Details.
- Eigene native Captures und lokale HTML-Workbench mit R2-Vergleich, JSON-Export und Umsetzungsbegründung. Die ältere Konzeptseite erhält nur einen sichtbaren Link auf den aktuellen nativen Stand.

## Nicht-Ziele / Grenzen
Keine Gameplay-, Balance-, Netzwerk-/Kartenpayload- oder Saveformatänderung, keine neue Zustandsautorität, keine Pause/Einzel-NPC-Steuerung. Kein vollständiger Sprachumbau des Spiels, kein Editorumbau, keine Mainintegration und kein Release/EXE-Export. Keine Füllbilder oder erfundenen Werte gegen leere Panels.

## Relevante Dokumente / Verträge
`docs/dev/ui_native_design_contract.md`, `docs/dev/html_report_workbench_contract.md`, `docs/ui_concepts/ui_20261101/MENUES_UND_KARTEN.md`, R2-Task/Nachweise sowie die bestehenden Mission-, Transport-, Read-only-, AAR- und Fortschrittsverträge. Die bestätigte Formensprache bleibt Grundlage.

## Entwurfsentscheidung
Inhaltsabhängige Größen und gestaffelte Information führen die bereits bestätigte Gestaltung fort. Nur Schriftverkleinerung würde die Ursache nicht beheben; das ersatzlose Entfernen leerer Dropziele würde Bedienwege verlieren. Daher bleiben häufige Aktionen/Arbeitsorte auffindbar, während seltene Diagnose in ausdrücklich erreichbaren Details liegt. Layout reagiert auf Viewport- und relevante Belegungswechsel, nicht auf jeden Fortschrittswert.

## Akzeptanzkriterien
1. Native Vorher-/Nachherbilder zeigen bei wenigen Daten deutlich kleinere leere Rahmenflächen in Basis/FOB und Debrief. Mehr Daten bleiben über echte Scrollflächen erreichbar.
2. Leerer Transport, aufs Flugdeck verschobene Teams, fehlende Ergebnisdaten und unbekannte Werte haben kurze ehrliche Hinweise; keine vorgetäuschte Bereitschaft oder Entwicklung.
3. Primäre überarbeitete Anzeigen verwenden verständliche Bezeichnungen statt Blocknummern/roher Statusdumps. Ausführliche ursprüngliche Informationen bleiben zugänglich.
4. Zuweisung, Fokuswechsel, Loadout/Leader, Transit-/Read-only-Gates, Rückwege und Missionseingabe folgen unveränderten Besitzern und Callbacks. Neue Statusanzeigen werden bei Statewechseln aktualisiert.
5. 1920×1080 und echte logische 1280×720: primäre Aktionen und Details liegen in Eingabegrenzen. Keine kleinere Basisschrift als R2 als Platzersatz; keine per-frame Baumrebuilds/Layoutpolls.
6. Gezielte Verifier, echte Rendereraufnahmen und Offline-HTML-Exportprüfung belegen Ergebnis und Grenzen getrennt. R2-Nachweise werden nicht überschrieben.

## Betroffene Dateien / lokale Prüfung
Homebase-/FOB-/Debrief-Skripte; Missionspräsentationshelfer mit kleinsten erforderlichen Controlleranschlüssen; fokussierte neue Verifier. Root verantwortet Capturehelper, Workbench, Status, Quellen-/Artefaktnachweis. Ein gemeinsamer Enginepfad führt Tests sequenziell aus. Umsetzungsschritte: `docs/superpowers/plans/2026-11-02-ui-verdichtung-r3.md`.

## Risiken / offene Punkte
Inhaltsabhängige Größen dürfen Arbeitsorte beim Draggen nicht springen lassen. Alte labelgebundene Checks können bewusst technische Rohtexte prüfen; Zustands-/Gateprüfungen bleiben erhalten. Menschliche Verständlichkeitsabnahme bleibt vom technischen Nachweis getrennt. Die bekannte Lobby-Payload-Netzwerklücke gehört nicht zu diesem Pass.

## Ergebnis / Abschlussnachweis
Alle sechs Akzeptanzkriterien sind im begrenzten technischen Scope erfüllt. Leere Truppfläche 128 statt 848px, leeres FOB-Flugdeck 176 statt 712px, Standarddebrief 1240×624 statt 1872×1032px. Native Belegung, Teilberichte, laufende Pläne und Rückflüge bestimmen die Anzeige; unbekannte Werte und Vorschau bleiben ehrlich. Ursprüngliche Details und Bedienpfade sind erhalten.

19 gezielte Checks mit 1.617 bestandenen Assertions, 13 echte native Captures (vier Screenfamilien jeweils 1920×1080 und echte logische/physische 1280×720 plus fünf Varianten) sowie 10 Offline-HTML-Prüfungen. Nach dem letzten Debrief-Geometriefix wurden die vier betroffenen Checks und alle fünf Debriefbilder erneuert. Ein unabhängiger Reviewer bestätigte die korrigierten sichtbaren Werte und Rückwege. Quellen, letzte Einzelruns und Artefakthashes: `docs/qa/ui_native_r3_20261102/VERIFIKATION.json`; Ursachen/Regressionen: `REVIEW.md` im selben Ordner.

Einstieg: `docs/reports/STERNENBUERGERCHEN_UI_NATIVE_R3_2026-11-02.html`. Browserlayout-/Downloadabnahme und vollständiger menschlicher Durchspieltest bleiben ausdrücklich getrennt. Keine Änderung der bekannten Lobby-Payload-Lücke und keine Mainintegration/EXE.
