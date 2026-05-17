# TASK_459 - Fireteam Engage Orientation Enemy Proxy Fix

## Ziel / Problem
- Im manuellen Drill-Playtest feuert/diagnostiziert das Team zwar, bleibt aber in Engage haeufig haengen, dreht Gegnern den Ruecken zu und steht unlesbar. Gleichzeitig sind von vier Gegnern oft nur ein Body und mehrere `IDLE`-/Base-Marker sichtbar.

## Sinnhaftigkeit / Ursache
- TASK_458 macht Fire-Entscheidungen sichtbar. Der naechste Fix muss die sichtbare Runtime-Lesbarkeit verbessern: Einheiten sollen bei Engage auf reale Kontakte/Ziele ausgerichtet bleiben, und Gegner muessen als Units sichtbar sein.

## Umfang
- Engage-/Fireteam-Facing gegen aktuelle Kontakte/Ziele stabilisieren.
- Einen Debug-/Fallbackpfad ergaenzen, damit gegnerische Proxies nicht nur Base/Badge zeigen, wenn ihr Body-Modell noch nicht sichtbar ist.
- Einen Headless-Verifier fuer Engage-Facing-Snapshot und vier sichtbare Enemy-Bodies/Fallback-Bodies ergaenzen.

## Nicht-Ziele
- Keine neue Gegner-KI.
- Keine neue Pathfinding-/Avoidance-Architektur.
- Keine finale Sequenzlogik fuer Bounding/raupenartig.
- Keine neue Asset-Pipeline.

## Relevante Contracts / Dokumente
- `docs/dev/fireteam_behavior_modes_contract.md`
- `docs/tasks/TASK_458_fireteam_contact_decision_diagnostics.md`
- `docs/tasks/TASK_438_fireteam_contact_visibility_attack_visuals.md`
- `docs/tasks/TASK_457_fireteam_contact_engage_runtime_pass.md`

## Akzeptanzkriterien
- Friendly Engage-Units richten ihre Waffen-/Facing-Diagnose bei aktivem Kontakt auf den Gegner statt in Gegenrichtung.
- Der Render-Snapshot zeigt fuer alle vier Gegner im Drill einen sichtbaren Body oder expliziten Body-Fallback, nicht nur `IDLE`/Base.
- Die Diagnose bleibt read-only und UI-frei; Gameplay-State wird nicht im Panel mutiert.
- Regressionen fuer Contact/Muzzle/Enemy-Visuals bleiben gruen.

## Betroffene Dateien
- `scripts/terrain/terrain_map_3d_view.gd`
- `scripts/tests/mission_combat_loop_driver.gd`
- `scripts/tests/task_459_fireteam_engage_orientation_enemy_proxy_fix.gd`
- Doku/Status/Roadmap

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_459_fireteam_engage_orientation_enemy_proxy_fix.gd`
- Regressionen TASK_438/TASK_457/TASK_458.
- `git diff --check`.

## Risiken / offene Punkte
- Haenger durch echte Pathfinding-/Local-Avoidance-Probleme werden hier nur diagnostisch stabiler sichtbar, nicht final geloest.
- Wenn der Body-Fallback greift, ist das eine sichtbare Sicherheitsdarstellung; die eigentliche Asset-/Proxy-Ursache bleibt danach separat pruefbar.
