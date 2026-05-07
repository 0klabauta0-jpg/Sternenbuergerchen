# Tactical Breakout and Exception Contract

Status: TASK_276

## Zweck
Fireteams duerfen in klar definierten Ausnahmen vom Plan abweichen, ohne die Commander-Struktur zu brechen. Ausbrueche sind keine freie KI und keine UI-Wahrheit. Der Resolver erzeugt einen visual_only Snapshot mit Event-ID, Ursache, Klasse, Status und Spieleroptionen; Runtime-Autoritaet bleibt bei SimulationRoot, bestehenden Plan-/Movement-Controllern und EventRouter.

## Ausbruchsklassen
| Klasse | Bedeutung | Return-to-plan |
| --- | --- | --- |
| auto_adapt | Kleine Routen-/Deckungsanpassung innerhalb des Commander-Intent | ja, automatisch moeglich |
| hold_and_report | Anhalten, sichern, melden | ja, wenn Ursache geloest ist |
| request_orders | Rueckfrage sichtbar an Commander | nein, bis Spieler/Controller klaert |
| abort_to_safe | Kritischer Abbruch Richtung Sicherheit | nein, Folgeentscheid noetig |

## Trigger
| Trigger | Standardklasse | Feedback |
| --- | --- | --- |
| contact | hold_and_report | #17/#18 und Bubble/Map bei Bedarf |
| suppressed_pinned | hold_and_report | Planunterbrechung, Return-to-plan nach Stabilisierung |
| casualty_medic_needed | hold_and_report | Medic-/Casualty-Hinweis |
| blocked_route | auto_adapt bei gutem FTL, sonst hold_and_report | cannot_execute Event |
| out_of_weapon_range | request_orders | Reichweitenfrage |
| low_ammo_no_weapon | request_orders | Ammo-/Weapon-Frage |
| leader_down | request_orders oder hold_and_report bei starkem FTL | kritische Rueckfrage |
| air_asset_threatened | request_orders | Air-Warnung |
| air_asset_destroyed | abort_to_safe oder request_orders, falls Abort nicht erlaubt | Air-Loss |
| rule_conflict | request_orders | Plan widerspricht aktiver Regel |

Die Definitionen liegen in `data/tactical_breakout_catalog.json`; `scripts/tactical/tactical_breakout_resolver.gd` normalisiert Synonyme und faellt bei fehlender Datei auf denselben Kernkatalog zurueck.

## FTL-Skill
`breakout_judgement` und `communication_clarity` beeinflussen Klasse, Text und Erkennungsverzoegerung. Hoher Skill kann blockierte Wege automatisch anpassen; niedriger Skill fragt bei unsicherem Kontakt eher nach Orders. Das Ergebnis bleibt sichtbar und enthaelt `commander_rule_resolution`.

## Commander-Regeln
`FireteamExecutionPlan.allowed_breakout_classes` begrenzt automatische Entscheidungen. Wenn eine Klasse nicht erlaubt ist, wird sie auf eine erlaubte Klasse oder `request_orders` normalisiert. Damit bleibt der Ausbruch innerhalb Commander-Regeln oder fragt sichtbar rueck.

## Feedback
Jeder Ausbruch hat:
- `breakout_id`
- `event_id`
- `trigger`
- `breakout_class`
- `status`
- `short_label`
- `detail_text`
- `player_options`
- `return_to_plan_allowed`
- `visual_only`
- `runtime_authority = SimulationRoot`
- `ui_sets_gameplay_truth = false`

`MissionTacticalSandboxController.record_tactical_breakout()` speichert den Snapshot und baut ein TacticalCommunicationEvent fuer #17/#18, Map/Bubble-Kanaele. `get_command_feedback_snapshot()` enthaelt `tactical_breakouts`.

## Return-To-Plan
`TacticalBreakoutResolver.mark_return_to_plan()` setzt einen Breakout nur dann auf `returned_to_plan`, wenn die Klasse returnfaehig ist und die Ursache nicht mehr besteht. Suppression nutzt den bestehenden TASK_103-Pfad: Plan wird unterbrochen, stabilisiert und danach wieder aufgenommen.

## Grenzen
- Kein Moral-Paniksystem.
- Kein komplexes Munitionssystem.
- Keine echte autonome Taktik-KI.
- Keine UI-seitige Gameplay-Wahrheit.
