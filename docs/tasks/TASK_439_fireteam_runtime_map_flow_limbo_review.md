# TASK 439: Fireteam Runtime Map Flow + Limbo Review

## Ziel / Problem
Der aktuelle Fireteam-Playtest ist schwer nachvollziehbar: UI, Mission-Controller, Fireteam-Controller, Combat Loop, SimulationRoot und 3D-Visuals greifen ineinander. Fuer weitere Korrekturen braucht es eine bedienbare Uebersicht, welche Funktion welchen State liest, welche Commands erzeugt und warum auf der Karte etwas sichtbar wird oder ausbleibt.

Zusaetzlich soll bewertet werden, ob LimboAI fuer Einheiten- bzw. Gegnerverhalten jetzt sinnvoll eingesetzt werden soll und wo die Grenze zur bestehenden autoritativen Simulation liegt.

## Sinnhaftigkeit / Ursache
Die letzten manuellen Playtests haben mehrere schwer einzugrenzende Symptome gezeigt:
- Waffenhaltung, Muzzle Flash und rote Kontaktlinien waren nicht immer erwartbar sichtbar.
- Gegnerkontakt, Patrouille und Angriff wirkten nicht transparent.
- Fireteam-Entscheidungen werden ueber mehrere Controller und Visual-Snapshots verteilt.
- LimboAI ist bereits als Enemy-Adapter angedacht, darf aber keine zweite Gameplay-Wahrheit werden.

Eine HTML-Referenz hilft, die Debug-Fragen direkt gegen den Codepfad zu stellen und naechste Tasks kontrolliert zu schneiden.

## Umfang
- Bedienbare HTML in `docs/reports`.
- Funktionsuebersicht vom Input bis zur 3D-Karte.
- Erwartetes Verhalten fuer Move, Defend, Take, Engage und Kontakt.
- Offene Fragen und empfohlene naechste Schritte.
- LimboAI-Vorteile, Nachteile, Einsatzgrenzen und aktuelle Empfehlung.
- Einarbeitung der User-Antworten zu Produktionspfad, Skills, Flanking, Sicherungsvisuals, Sicht-/Schussreichweite und LimboAI-Umstiegsoptionen.

## Nicht-Ziele
- Keine Runtime-Codeaenderung.
- Keine BehaviorTree-Umstellung.
- Keine neue UI im Spiel.
- Keine Aenderung an Terrain, Gegnern, Waffenhaltung oder Muzzle Flash.

## Relevante Contracts / Dokumente
- `docs/dev/fireteam_behavior_modes_contract.md`
- `docs/dev/fireteam_runtime_execution_path_contract.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/dev/enemy_team_tactics_contract.md`
- `docs/tasks/TASK_434_limboai_enemy_behavior_adapter_smoke.md`
- `docs/tasks/TASK_438_fireteam_contact_visibility_attack_visuals.md`

## Akzeptanzkriterien
- Die HTML zeigt den aktiven Pfad von Eingabe bis Kartenvisual.
- Die HTML enthaelt such- oder filterbare Funktionskarten.
- Offene Unklarheiten sind sichtbar getrennt von gesicherten Erwartungen.
- LimboAI wird nicht pauschal empfohlen, sondern mit klaren Einsatzgrenzen bewertet.
- Der empfohlene naechste Schritt ist als kleiner, pruefbarer Slice formuliert.
- Die HTML klaert, dass LimboAI keinen Gameplay-Code automatisch generiert, sondern BehaviorTree/HSM/Blackboard/Custom-Task-Strukturen bereitstellt.
- Die HTML enthaelt eine Umstiegsoptionen-Tabelle von aktuellem Pfad ueber Hybrid bis Vollumstieg.

## Betroffene Dateien
- `docs/reports/fireteam_runtime_map_flow_limbo_review.html`
- `docs/tasks/TASK_439_fireteam_runtime_map_flow_limbo_review.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`

## Lokale Pruefung
- Statische Datei existiert und oeffnet lokal im Browser.
- `git diff --check`

## Risiken / offene Punkte
- Codezeilen koennen durch weitere Aenderungen driften; die HTML nennt daher vor allem Funktionsnamen und Dateien.
- LimboAI ist nur als Entscheidungsadapter sicher, solange alle Mutationen weiter ueber `SimulationRoot` laufen.
- ContactConfirm/ThreatLevel sind noch nicht sauber definiert und brauchen einen eigenen Contract-Slice.
- Full-Limbo fuer Low-Level-Bewegung, LOS, Schaden und VFX bleibt riskant, weil LimboAI diese Autoritaets- und Pathing-Probleme nicht automatisch loest.
