# TASK_1147 - Release Executable Singleplayer and Connected Multiplayer Entry Playtest

## Ziel / Problem
Nach der HUD-, Player-Flow- und Exit-Hygiene-Serie fehlt ein frischer produktnaher Beleg aus der exportierten EXE. Automatische Verifier beweisen Vertraege, aber nicht, ob ein Mensch den Einstieg versteht, die Wartezeiten angenehm sind und zwei Release-Prozesse sichtbar konvergieren.

## Umfang
- Den aktuellen provenance-geprueften Windows-Spieleordner verwenden.
- Singleplayer vom Hauptmenue bis zum ersten taktischen Einsatz und einer sichtbaren Entscheidung durchspielen.
- Zwei Release-Prozesse als Host und Join verbinden und bis Missionsstart/erstem Drop pruefen.
- Full-HD-Sicht, Klickpfad, Zustandswechsel, Wartezeiten, Fehlerausgaben und lokale Perspektiven dokumentieren.
- Aus echten Befunden den naechsten kleinen Produkt-Task schneiden.

## Nicht-Ziele
- Keine Headless-Fixture als Ersatz fuer den Release-EXE-Sichttest.
- Keine Gameplay-Regel aufgrund einer Vermutung aendern.
- Kein externer Matchmaking- oder Internet-Test; lokaler Host/Join reicht fuer diesen Slice.

## Akzeptanzkriterien
- Release-Provenance passt zum Integrations-HEAD und Startcheck ist gruen.
- Singleplayer erreicht eine bedienbare Mission oder liefert einen reproduzierbaren Blocker mit Screenshot.
- Host und Join zeigen eine verbundene Session sowie konsistente lokale Missions-/Drop-Zustaende oder einen reproduzierbaren Blocker.
- Findings unterscheiden Produktfehler, fehlende Bedienhinweise, visuelle Reibung und reine Testumgebungsgrenzen.
- Status, Roadmap und HTML-Arbeitsbericht enthalten den sichtbaren Beleg und den naechsten Vorschlag.

## Betroffene Dateien
- `docs/tasks/TASK_1147_release_executable_singleplayer_connected_multiplayer_entry_playtest.md`
- Playtest-Belege unter `tmp/`
- bei echtem Finding nur die minimal betroffenen Runtime-/UI-Dateien
- Status, Roadmap und HTML-Arbeitsbericht

## Lokale Pruefung
- `scripts/tools/release_runtime_start_check.ps1 -RequireNoRunningProcess`
- echter Start von `C:\dev\Sternenbuergerchen_rel\Sternenbuergerchen_rel.exe`
- Singleplayer- und lokaler Host/Join-Sichttest
- bestehende zielbezogene Regressionen bei Codeaenderung

## Risiken / offene Punkte
Godot-Canvas-Inhalte koennen in Windows UI Automation nur schwach semantisch exponiert sein. In diesem Fall werden stabile sichtbare Koordinaten aus frischen Window-Captures verwendet und jeder Zustandswechsel erneut beobachtet.
