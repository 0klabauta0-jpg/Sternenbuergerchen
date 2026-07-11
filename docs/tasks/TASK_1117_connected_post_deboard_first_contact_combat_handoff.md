# TASK_1117 - Connected Post-Deboard First Contact Combat Handoff

## Ziel / Problem
Nach dem verbundenen Deboarding und dem ersten hostautoritativen Bodenbefehl muessen BLUE und GOLD ihren ersten Feindkontakt konsistent erleben. Zielerkennung, ROE, Treffer und Schaden bleiben Host-Wahrheit; Clients erhalten nur die vorhandenen read-only Combat-Snapshots.

## Sinnhaftigkeit / Ursache
`MissionCombatLoopDriver` laeuft im verbundenen Spiel bereits nur auf dem Host und `SimulationRoot` transportiert Kontakte, Feuerereignisse, Positionen und Vitalstatus. Der Client-Controller uebernimmt aus dem autoritativen Snapshot bisher jedoch nur ROE, Dropship und Missionsinteraktionen. Damit kann die Simulation korrekt laufen, waehrend Kontakt- und First-Fire-Feedback auf Clients leer bleiben.

## Umfang
- Vorhandene Contact- und Fire-Event-Daten aus dem `SimulationRoot`-Snapshot read-only in den Client-Combat-Driver spiegeln.
- Replizierte Combat-Daten nach Fireteam filterbar und fuer das bestehende HUD lesbar halten.
- Einen echten Host-/BLUE-/GOLD-ENet-Lauf vom deboardeten Zustand bis zum parallelen ersten Kontakt absichern.
- Nachweisen, dass nur der Host Combat-Effects erzeugt und Vitalstatus mutiert.

## Nicht-Ziele
- Kein neuer Combat-Resolver und kein eigener Combat-RPC.
- Kein Ballistik-, Damage- oder KI-Rewrite.
- Keine clientseitige Zielwahl, Trefferentscheidung oder Schadensmutation.
- Kein kosmetischer Umbau des gesamten Combat-HUDs.

## Relevante Contracts / Dokumente
- `docs/ARCHITECTURE.md`
- `docs/tasks/TASK_1116_connected_post_deboard_fireteam_command_handoff.md`
- `scripts/core/simulation_root.gd`
- `scripts/tests/mission_combat_loop_driver.gd`
- `scripts/tests/mission_tactical_sandbox_controller.gd`

## Akzeptanzkriterien
- Host, BLUE und GOLD laufen als drei echte ENet-Peers.
- BLUE und GOLD besitzen unterschiedliche Fireteams und sehen nach Deboarding mindestens einen hosterkannten Kontakt.
- Ein autoritatives erstes Feuerereignis ist auf beiden Clients mit stabiler Event-ID lesbar.
- Replizierter Ziel-Vitalstatus stimmt auf Host und Clients ueberein.
- Client-Combat-Driver erzeugen keine lokalen Fire-Events, Commands oder Effects.
- ROE wird weiterhin ueber den vorhandenen `tactical_rule`-Contract und Fireteam-Ownership validiert.
- Snapshot-Uebernahme erzeugt keine Gameplay-Wahrheit und keinen per-frame SceneTree-Scan.

## Betroffene Dateien
- `scripts/tests/mission_combat_loop_driver.gd`
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/tests/task_1117_connected_post_deboard_first_contact_combat_handoff.gd`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/reports/project_current_state_handbook_reentry_2026_07_01.html`

## Lokale Pruefung
- TASK_1117 Drei-Peer-Verifier.
- TASK_1116 Post-Deboard-Movement-Regression.
- TASK_281 Multiplayer-Authority-/ROE-Regression.
- TASK_466 und TASK_467 Live-Fire-/Contact-Regression.
- TASK_1104 Drei-Peer-Interaktionsregression.
- `git diff --check`.

## Risiken / offene Punkte
Der historische Combat-Driver liegt weiterhin unter `scripts/tests/`; dieser Task vergroessert seine Gameplay-Verantwortung nicht, sondern schliesst nur den bereits vorgesehenen Snapshot-Lesepfad. Nach dem funktionalen Handoff bleibt ein Real-Window-Pass fuer parallele Contact-/Fire-Readability sinnvoll.
