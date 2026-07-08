# TASK_891 - Release First Exchange HUD Density Visual Findings

## Ziel / Problem
TASK_890 hat den echten Fensterblick nach dem TASK_889-HUD-Density-/Fire-Visual-Polish erzeugt. Der Screenshot muss jetzt als Spielerblick bewertet werden, ohne sofort wieder Gameplay oder HUD-Wahrheit zu veraendern.

## Sinnhaftigkeit / Ursache
Der frische Window-Handle-Screenshot zeigt CONTACT FIRE in #17/#18/#19 und sichtbare Fire-/Impact-Signale. Damit ist der urspruengliche CONTACT-FIRE-Wahrheits-/Frame-Widerspruch praktisch geloest. Die verbleibende Reibung ist visuelle Entscheidungsklarheit: Schussrichtung, Impact und Zielbezug sind vorhanden, aber noch nicht so schnell und elegant lesbar, wie ein erster echter Release-Feuerwechsel sein sollte.

## Umfang
- TASK_890-Manifest und PNG-Befund read-only auswerten.
- Positive Befunde festhalten: CONTACT FIRE in #17/#18/#19, #19 Event Log sichtbar, Welt-FIRE/Impact vorhanden, Command-Surfaces weiter bedienbar.
- Restreibung konkret benennen: FireDirection/Impact/Target-Bezug noch zu schwach, Bottom-HUD/Member-Cards noch dicht.
- Konkreten Folge-Task vorschlagen, ohne Combat-, Damage-, Movement- oder Multiplayer-Wahrheit anzufassen.
- Status, Roadmap, Contract und HTML-Zwischenbericht aktualisieren.

## Nicht-Ziele
- Kein Combat-Rewrite.
- Keine neue FireEvent-, Damage-, Contact-, Movement-, Command-, UI- oder Multiplayer-Wahrheit.
- Kein neuer Capture.
- Kein automatisches "Release akzeptiert", nur weil CONTACT FIRE sichtbar ist.
- Kein Editor-/Mapbuilder-Polish.

## Relevante Contracts / Dokumente
- `docs/dev/mission_command_feedback_contract.md`
- `docs/tasks/TASK_890_release_first_exchange_hud_density_real_window_recapture.md`
- `docs/tasks/TASK_889_release_first_exchange_hud_density_and_fire_visual_polish.md`
- `docs/reports/spielstand_zwischenbericht_2026_07_08.html`

## Akzeptanzkriterien
- `ReleaseFirstExchangeHudDensityVisualFindings.build_snapshot()` akzeptiert das TASK_890-Manifest als Quelle.
- Der Snapshot meldet positive Befunde fuer CONTACT FIRE in #17/#18/#19 und sichtbare Fire-/Impact-Signale.
- Der Snapshot markiert den Befund nicht als voll akzeptiert, solange FireDirection/Impact/Target-Bezug nicht sofort lesbar sind.
- Der Snapshot empfiehlt einen engen Folge-Task fuer FireDirection-/Impact-/Target-Fokus, nicht erneute Combat-Wahrheit.
- Der Verifier prueft read-only-Grenzen: keine Commands, FireEvents, DamageEvents, Movement- oder Multiplayer-Wahrheit.

## Betroffene Dateien
- `docs/tasks/TASK_891_release_first_exchange_hud_density_visual_findings.md`
- `scripts/mission/release_first_exchange_hud_density_visual_findings.gd`
- `scripts/tests/task_891_release_first_exchange_hud_density_visual_findings.gd`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/reports/spielstand_zwischenbericht_2026_07_08.html`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_891_release_first_exchange_hud_density_visual_findings.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_890_release_first_exchange_hud_density_real_window_recapture.gd`
- `git diff --check`

## Risiken / offene Punkte
TASK_891 bewertet den Screenshot nur. Der naechste Runtime-/Visual-Polish muss eng bleiben: sichtbare Schussrichtung, Impact-Zielbezug und Fokus, ohne neue Combat- oder HUD-Wahrheit zu bauen.

## Naechster Schritt
TASK_892 - Release First Exchange Fire Direction And Impact Clarity Polish.
