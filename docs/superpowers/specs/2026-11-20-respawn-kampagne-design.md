# Respawn in der Kampagne – Entwurf (Spec)

Stand 20.11.2026. Von Bjoern am 20.11. um 20:19 bestaetigt. Ersetzt in `docs/dev/campaign_casualty_retreat_contract.md` die Regel 1 („Kein Respawn fuer eigene Leute“) teilweise und die Regel 3 („Tot ist nur, wer zurueckbleibt“) in ihrer Folge. Gleicher Text liegt als Projektdokument `claude/Respawn-Kampagne-Entwurf-2026-11-20.md`.

## Ziel
Kampagne und Skirmish sollen sich beim Tod nicht grundsaetzlich unterscheiden, aber eine Rettung muss sich lohnen. Ein Zurueckgelassener kommt wieder, faellt aber lange aus, und das nur begrenzt oft.

## Regeln (bindend, mit genauen Werten)
1. **Gerettet bleibt gerettet.** Wer am Boden lag und gerettet wird (Sieg, an Bord oder nahe am Schiff), ist verwundet wie heute (180 / 900 / 2400 Sekunden). Das verbraucht keinen Respawn.
2. **Zurueckgelassen heisst gestorben.** Die Person bleibt im Kader, faellt aber aus. Ausruestung, Rucksack und Loadout sind verloren wie heute; sie verliert ihren Platz in Trupp, Auswahl und Schiff.
3. **Ausfallzeit je Tod:** `3600 + 1800 × (Todesnummer − 1)` Sekunden, also 3600 / 5400 / 7200 / 9000 … Die Uhr laeuft wie bei Verwundeten in Echtzeit, nur waehrend das Spiel laeuft. Werte in `data/singleplayer/casualty_rules.json` (Block `respawn`: `outage_base_seconds` 3600, `outage_step_seconds` 1800, `pickup_location_id` „polisa“), als vorlaeufig markiert.
4. **Danach wartet die Person auf Polisa** und muss dort abgeholt werden, so wie ein Angeworbener an Bord kommt. Bis sie an Bord ist, ist sie nicht einsetzbar.
5. **Grenze:** Einstellung „Respawns je Person“, ganze Zahl 0 bis 9, Vorgabe 3. Hat eine Person so viele Respawns verbraucht wie die Grenze erlaubt, ist ihr naechster Tod endgueltig: Sie verlaesst den Kader wie heute und steht in der Gefallenenliste mit Grund `respawn_limit`, verbrauchten Respawns und der Grenze.
6. **Grenze 0** = Verhalten von Paket 3a (jeder Tod endgueltig). Das ist die Gegenprobe fuer alle vorhandenen Tests.
7. **Einstellung gilt global** (eine Einstellungsdatei, wie alle Einstellungen heute). Aenderung mitten in der Kampagne gilt ab dem naechsten Tod; endgueltig Gefallene bleiben gefallen.
8. **Unveraendert:** Geschuetzte Personen sterben nicht (schwer verwundet). Beim Totalverlust stirbt niemand. Im Einsatz steht in der Kampagne niemand von allein wieder auf (Schalter `campaign_casualty_rules_enabled` bleibt). Skirmish und Mehrspieler unveraendert; `respawn_manager.gd` und die Respawn-Stellen in `simulation_root.gd` werden nicht angefasst.
9. **Totalverlust-Gruende** `roster_too_small`, `no_leader_left`, `no_pilot_left` zaehlen nur endgueltig Gefallene. `pilot_down` und `ground_team_down` unveraendert.
10. **Alte Spielstaende** laden weiter: fehlender Zaehler = 0. `schema_version` bleibt 1.

## Daten
- Kader-Eintrag (rohes Dictionary in `_all_team_units`, und `MetaUnitProfile.to_dict`/`_apply_dict`): neues Feld `respawns_used` (int, Vorgabe 0).
- Waehrend des Ausfalls: `availability_status = "respawning"`, `recovery_state = {state:"respawning", death_number, seconds_total, seconds_remaining, pickup_location_id, source}`.
- Nach Ablauf: `availability_status = "awaiting_pickup"`, `recovery_state = {state:"awaiting_pickup", pickup_location_id}`.
- Nach dem Abholen: `availability_status = "active"`, `recovery_state = {}`.
- Gefallenenliste: Eintrag zusaetzlich `reason` („respawn_limit“), `respawns_used`, `respawn_limit`; alte Eintraege ohne diese Felder bleiben gueltig.

## Texte (Deutsch, Sprachregel: Lebende werden gerettet, Tote und Gegenstaende geborgen)
- Personenkarte, Ausfall: „Gestorben · Respawn in m:ss“ (ab einer Stunde „h:mm:ss“).
- Personenkarte, danach: „Wartet auf Polisa · abholen“.
- Charakterblatt: „Respawns: 2 von 3“; bei erreichter Grenze „Respawns: 3 von 3 · nächster Tod endgültig“.
- Einsatzende, Tod mit Respawn: „Gestorben · zurückgelassen · Respawn 2 von 3 · Ausfall 90:00, dann auf Polisa“.
- Einsatzende, endgueltig: „Gefallen · Respawn-Grenze erreicht (3 von 3)“.
- Sperre beim Aufstellen: „Name: gestorben, Respawn in m:ss“ bzw. „Name: wartet auf Polisa“.
- „Gefallen“ steht nur noch beim endgueltigen Tod.

## Verglichene Wege
- A (gewaehlt): Person bleibt im Kader mit neuem Zustand. Kosten: der Zustand `station` der Angeworbenen ist an die Kennung `polisa_recruit_` gebunden und muss verallgemeinert werden.
- B: Person verlaesst den Kader und wird auf Polisa als Angeworbener neu angelegt. Verworfen: neue Kennung, Erfahrung und Verlauf muessten kopiert werden.
- C: Aufstehen im Einsatz wie im Skirmish. Verworfen: Rettung lohnt sich dann nicht.

## Nicht in diesem Paket
Skirmish/Mehrspieler; Mission zu einem zurueckgelassenen Toten; Raeume auf Polisa; Medic-Schiff und Ressourcen; eine Ansicht der Gefallenenliste.

## Abschnitte
R1 Regeln und Zahlen (reine Rechnung) · R2 Einstellung · R3 Anwenden am Einsatzende, Uhr, Spielstand · R4 Abholen auf Polisa · R5 Anzeige · R6 Vertraege und Handbuch. R3 und R4 kommen nur zusammen nach `main`.
