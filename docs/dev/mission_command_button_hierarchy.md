# Mission Command Button Hierarchy

Status: TASK_275

## Zweck
Die Mission-Command-UI ordnet vorhandene und geplante Befehle nach Bedeutung statt nach Entstehungszeit. #16 bleibt die kurze 5x4-Command-Matrix, #17 zeigt Fireteam-Regeln und Plan-/Statusdetails, #18 sammelt Mission Control, Air/LZ-Status und kritische Rueckfragen.

UI bleibt visual_only. Sie setzt keine Gameplay-Wahrheit und `ui_sets_gameplay_truth = false`; Controller, Plan-Daten, Resolver und SimulationRoot bleiben autoritativ.

## Fensterrollen
| Bereich | Rolle | Regel |
| --- | --- | --- |
| #16 Command Matrix | Kurze Ziel- und Ausfuehrungsbuttons in einer festen 5x4-Matrix | Verb oder knapper Zieltyp, keine Erklaertexte; leere Reserve-Slots bleiben klein markiert. |
| #17 Fireteam Details | Aktive Regeln und Planlage fuer selektierte Fireteams | Tempo, fire rule, Kontakt, Deckung, Security und Fireteam-Kommunikation. |
| #18 Mission Control | Gesamtplan, Air/LZ-Status, Dropship, Warnings und Ausbrueche | Missionsweite Status-/Preview-Information bleibt getrennt von #16. |

## Vorher Matrix
| Button | Alter Ort | Problem |
| --- | --- | --- |
| Move, Hold, Flank, Take | #16 Command Grid | Kurze Zielbefehle waren da, aber nicht als Zielgruppe markiert. |
| Target, Clear | #16 Command Grid | Area-/Zielbezug war mit normalen Bewegungsbefehlen vermischt. |
| Set LZ, Drop, Approach | #18 Strategic Panel | Air-Kontext existierte, aber ohne gemeinsame Gruppe. |
| GO / Phase | #18 Phase Panel | Im fixed HUD verborgen, aber ohne einheitlichen Disabled-Grund. |
| Tempo, Fire Rule, Contact, Cover, Security | #17 Status/Regeln | Status vorhanden, aber nicht Teil einer pruefbaren Buttonhierarchie. |

## Nachher Gruppen
| Gruppe | Aktionen | Primaerer Ort |
| --- | --- | --- |
| goal | Move, Take, Defend, Engage, Secure, Recon, Withdraw, Flank, Clear Target | #16 |
| rule | Tempo, Fire Rule, Contact Response, Cover Priority, Security Mode | #17 |
| plan | Role Suggestion, Swap Roles, Preview, GO | #18 |
| air_lz | Set LZ, Call Dropship, Hold Air, Cancel Drop, LZ Secure, Evac/Recover, Approach | #18, mit Dropship-Go-Vertrag aus TASK_312 fuer #16 |
| breakout | Confirm, Override, Abort, Regroup | #18 |

## Kontextregeln
Single-Fireteam-Kontext aktiviert Ziel- und Regelbefehle fuer die Auswahl. Multi-Fireteam-Kontext aktiviert dieselben kurzen Zielbefehle, markiert aber Planstatus und Rollenvorschlag als Multi-Kontext. Ohne Auswahl bekommen Ziel- und Regelgruppen den Disabled-Grund `select one or more fireteams`.

Preview und Multiplayer-Observer bleiben Gates fuer Live-Befehle. Wenn der Host die Autoritaet haelt, melden Live-Command-Aktionen `host controls mission commands`. Wenn fixed HUD die Phase-Planung ausblendet, meldet Plan-GO `phase planning hidden in fixed HUD`; Dropship-Go folgt dem spaeteren TASK_312-LZ-/Pilot-/Team-Gate.

## Disabled Reasons
Jeder vorhandene Pflichtbutton liefert im Snapshot `command_hierarchy_disabled_reason`. Sichtbare Buttons bekommen dieselbe Information als Tooltip, ohne Buttontexte zu verlaengern. Geplante Ausbruch- und Air-Erweiterungen sind absichtlich disabled und verweisen auf TASK_276, TASK_277 oder TASK_278.

## Help IDs
Neue Gruppen-Hilfe:
- `mission.command.group.goal`
- `mission.command.group.rule`
- `mission.command.group.plan`
- `mission.command.group.air_lz`
- `mission.command.group.breakout`

Bestehende Button-Hilfen bleiben erhalten, damit alte Help-Coverage nicht bricht.

## Snapshot Contract
`get_command_hierarchy_snapshot()` liefert:
- `schema_version`
- `visual_only`
- `ui_sets_gameplay_truth`
- `single_fireteam_context`
- `multi_fireteam_context`
- `groups`
- `groups_by_id`
- `actions_by_id`

`get_command_feedback_snapshot().command_hierarchy` spiegelt denselben Contract fuer Headless-Tests. `get_command_feedback_snapshot().command_buttons.hierarchy` bleibt als Kompatibilitaetsanker neben den alten Einzelbutton-Snapshots.

## Offene UX-Fragen
- Braucht #16 spaeter echte visuelle Gruppenlinien, oder reichen 5x4-Slot-Rahmen, Reihenfolge, Tooltip und Help-Popup?
- Soll Recon als eigener area-order command kommen oder als Modus fuer Move/Secure?
- Wann darf ein Ausbruch ohne explizites Override automatisch starten?
- Welche Air-Asset-Risiken muessen vor TASK_277 sofort sichtbar sein?
