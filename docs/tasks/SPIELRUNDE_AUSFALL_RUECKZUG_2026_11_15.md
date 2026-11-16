# Spielrunde, Paket 3a: Ausfall und Rückzug in der Kampagne (15.11.2026)

Status: Von Björn am 15.11.2026 freigegeben („deine Vorschläge sind freigegeben, aber es muss einen Malus geben bei Totalverlust“). Regeln mit [B] hat Björn entschieden; Regeln mit [V] sind Vorschläge von Claude, die er mit dieser Freigabe angenommen hat. Offen ist nur die Ausgestaltung des Malus in Regel 7.
Arbeitsplan: `docs/superpowers/plans/2026-11-15-ausfall-und-rueckzug.md`. Vertrag: `docs/dev/campaign_casualty_retreat_contract.md`. Stand der Umsetzung: letzter Abschnitt dieser Datei. Entscheidungen von Björn vom 15.11., 23:07 sind mit [B] eingetragen (Regeln 3, 6 und 8).

## Ziel / Problem

Heute steht jede ausgefallene Person nach 30 Sekunden wieder auf (Respawn), in jedem Spielmodus. Bleibt am Ende trotzdem jemand liegen, wertet die Kampagne den Einsatz als Niederlage und springt zum letzten Basisstand zurück. Ein Einsatz kann dadurch weder knapp ausgehen noch etwas kosten, und ein Rückzug gilt als gescheiterter Auftrag.

Ziel ist die Runde aus der Spielvision: Missionen dürfen misslingen, man zieht sich zurück, wird mit Nebenaufträgen stärker und kommt wieder.

## Regeln

Sie gelten nur in der Kampagne. Skirmish und Mehrspieler bleiben unverändert.

1. **Kein Respawn für eigene Leute.** [B]
2. **Versorgungsfrist.** Wer ausfällt, liegt 60 Sekunden „am Boden“. In dieser Zeit kann ein Sanitäter ihn wieder aufrichten. Danach ist er „kritisch“ und kann im Feld nicht mehr aufgerichtet werden. [V]
3. **Tot ist nur, wer zurückbleibt.** [B] Solange es das Tragen noch nicht gibt (Paket 3b), gilt als geborgen [V]:
   - bei Sieg jeder Ausgefallene (das Gebiet ist gesichert);
   - sonst, wer an Bord ist oder höchstens 180 Einheiten vom Einstiegspunkt des gelandeten Schiffs entfernt liegt (zwei Hexfelder). Ursprünglich waren 72 vorgesehen (Radius der Evakuierungszone); auf Hex-Karten liegt der Feldabstand aber bei etwa 88, 72 hätte nur das Einstiegsfeld selbst erfasst und wäre enger gewesen als der Einschiff-Radius (128). Geändert am 15.11. vom Hauptchat, Björn gemeldet.
   **Geschützte Personen** [B, 15.11., 23:07]: Personen, die die Kampagne voraussetzt (`campaign_outpost_recruit`, `campaign_rescue_pilot`, der Pilot eines Schiffs, der Anwerber des Polisa-Marktes), können nicht sterben; sie überleben schwer verwundet. Die Prüfung gilt je Person, nie für den ganzen Einsatz. Im Ergebnis tragen sie `protected_from_death`.
4. **Verwundungsstufen.** [B: abgestuft; Zuordnung V]
   - leicht: im Einsatz ausgefallen und vom Sanitäter wieder aufgerichtet;
   - mittel: am Ende „am Boden“ und geborgen;
   - schwer: am Ende „kritisch“ und geborgen.
5. **Ausfallzeit in Echtzeit**, auch während andere im Einsatz sind: leicht 3 Minuten, mittel 15 Minuten, schwer 40 Minuten. Die Werte stehen in `data/singleplayer/casualty_rules.json` und sind vorläufig. [V]
6. **Einsatzsperre.** Verwundete können an der Basis nicht eingeschifft werden; die Ablehnung nennt Name, Stufe und Restzeit. [B]
   **Wo die Sperre gilt** [V, 15.11.]: nur an der Heimatbasis (Einschiffen, und Start eines dort gelandeten Schiffs mit einer Verwundeten an Bord). Unterwegs sperrt eine Verwundete an Bord keinen Flug, sonst könnte ein Schiff nach einem Einsatz nirgends mehr anlegen. **Entscheidung** [B, 15.11., 23:07]: Ein Schiff mit einer Verwundeten an Bord darf direkt den nächsten Einsatzort anfliegen; die Einsatzsperre gilt nur an der Heimatbasis. Das ist gewollt, keine Lücke mehr. (Vorher stand hier eine „bekannte Lücke“ mit der strengeren Variante als eigener Aufgabe; Björn hat sie verworfen.)
7. **Totalverlust.** Fällt der Pilot aus, ist am Ende niemand vom Bodentrupp mehr einsatzfähig, oder bliebe nach den Toten kein Truppführer oder kein Pilot im Kader, dann stirbt niemand: Der Einsatz gilt wie heute als verloren und die Kampagne springt zum letzten Basisstand zurück. [B, 15.11.]
   **Malus bei Totalverlust** [B: es muss einen geben; Ausgestaltung V]: Der Rücksprung gilt als Notbergung durch einen Rettungsdienst. Sie kostet 25 % des Guthabens, mindestens 50 Credits (höchstens das vorhandene Guthaben). Jeder, der im Einsatz am Boden lag, ist danach leicht verwundet. Die Moral aller Beteiligten sinkt um 0,08. Der Auftrag steht nach dem Rücksprung so, wie ihn der wiederhergestellte Basisstand hält (meist angenommen); der Malus besteht aus Bergungsgebühr, leichter Verwundung und Moral [Ruling des Koordinators vom 16.11.2026, dem Nutzer zur Kenntnis; der Code bleibt unverändert]. Der Malus wird auf den wiederhergestellten Basisstand angewendet und sofort gespeichert, damit er sich nicht durch Neuladen umgehen lässt. Werte in `data/singleplayer/casualty_rules.json`.
8. **Rückzug ist ein normaler Ausgang.** Nach „Evakuieren“ bleibt der Auftrag angenommen und kann ohne „Erneut annehmen“ wieder angeflogen werden; die Zahl der Rückzüge wird mitgezählt. [B]
   **Was als Rückzug zählt** [B, 15.11., 12:05]: „Evakuieren“ und jeder Abflug vom Einsatzort bei aktivem Auftrag, nach dem keine einsatzfähige eigene Person mehr am Ort bleibt. Bleiben einsatzfähige Leute am Ort (Verstärkung mit nur einem Schiff nachholen, einen Außenposten halten, während das Schiff weiterfliegt), ist der Abflug in keiner Form ein Rückzug: keine Verlustauswertung, der Auftrag bleibt, wie er ist. Im Code ist ein Rückzug ein Ergebnis `aborted` mit `win_condition_type` `evacuation` oder `departure`. Ein Abflug ohne Ausfälle zählt ebenfalls als Rückzug (`win_condition_type` `departure`), wenn keine einsatzfähige Person am Ort bleibt; das Abflug-Gate bleibt ohne Ausfälle `handled: false`. Friedliche Besuche ohne Auftrag und Skirmish bleiben unverändert. Stand heute: Das Spiel lässt ein Schiff noch nicht abfliegen, solange ein Einsatzfähiger nicht an Bord ist, und gibt den Ort frei, sobald kein Schiff mehr dort ist; jeder Abflug mit Auftrag ist heute daher ein Rückzug. „Truppen bleiben am Ort“ wird in Paket 3c gebaut; dieses Paket schreibt nur die Regel fest.
   **Abflug mit Ausgefallenen** [V]: Ein Abflug wird nur ausgewertet, wenn der Abschluss sicher durchläuft. Reicht der Treibstoff nicht für den Rückflug, hebt das Schiff nicht ab und nichts wird gebucht. Ein Abflug, der von außerhalb der Ortsansicht ausgelöst wird, ist gesperrt, solange dort Ausgefallene liegen.
   **Treibstoff** [B, 15.11., 23:07]: Das Schiff fliegt so weit, wie der Treibstoff reicht: entweder nicht in den Orbit oder in den Orbit; für den Warpsprung muss der Treibstoff vorher reichen; im Zweifel kommt später ein Tankschiff. Das wird ein eigenes späteres Paket am Flug- und Treibstoffsystem (etappenweiser Treibstoff, Tankschiff), mit dem Bedien-Strang abzustimmen. In Paket 3a gilt übergangsweise: Mit Ausgefallenen am Boden und zu wenig Treibstoff für den ganzen Rückflug hebt das Schiff nicht ab und meldet es.

## Nicht-Ziele dieses Pakets

- Tragen und Bergen von Ausgefallenen (Paket 3b; braucht den Missionscontroller und die Einzelsteuerung).
- Der Ort merkt sich nach einem Rückzug getötete Gegner, Türen und Aufklärung (Paket 3c).
- Treibstoff etappenweise und Tankschiff (eigenes späteres Paket am Flug- und Treibstoffsystem, siehe Regel 8).
- Krankenstation, die Ausfallzeiten verkürzt (Etappe 2).
- Änderungen an Skirmish, Mehrspieler, Gegner-Respawn, Eingabe oder Missionsansicht.

## Relevante Verträge

`docs/dev/campaign_introduction_contract.md` (Zeilen 82 und 117–121 werden geändert), `docs/dev/mission_evacuation_abort_contract.md`, `docs/dev/combat_loop_authority_contract.md`, `docs/dev/singleplayer_locations_jobs_contract.md`, `docs/dev/base_automatic_rest_contract.md`, `docs/dev/mission_interaction_point_contract.md`. Neu: `docs/dev/campaign_casualty_retreat_contract.md`.

## Akzeptanz

1. In einem Kampagneneinsatz steht ein Ausgefallener nicht von selbst wieder auf; in Skirmish weiterhin nach 30 Sekunden.
2. Ein Sieg mit einem Ausgefallenen endet als Sieg mit Belohnung; die Person ist danach verwundet und für die Ausfallzeit gesperrt.
3. Ein Rückzug mit einem Ausgefallenen außerhalb des Radius: Die Person ist tot und aus Kader, Basis, Trupp und Schiffsbelegung entfernt; der Auftrag bleibt angenommen.
4. Pilot ausgefallen oder ganzer Bodentrupp ausgefallen: Rücksprung zum Basisstand wie heute, niemand stirbt.
5. Speichern und Fortsetzen erhält Verwundung, Restzeit und Tote. Ein mehrfach zugestelltes Missionsergebnis wendet Verluste genau einmal an.

## Betroffene Dateien

Siehe Arbeitsplan. Geteilte Datei: `scripts/tests/mission_tactical_sandbox_controller.gd`, nur `request_campaign_crew_boarding` und `get_campaign_pilot_flight_guard`; vor Beginn in der Abstimmungsnotiz eintragen.

## Risiken / offene Punkte

- Der Kampagnen-Checkpoint verlangt den Truppführer an Kaderplatz 0 und den Piloten an Platz 1; Tod des ersten Truppführers braucht eine Nachrückregel (Aufgabe 6 im Plan).
- Ob der Respawn auf Hex-Karten heute überhaupt greift, ist ungeklärt (`begin_hex_respawn` hat keinen Aufrufer). Aufgabe 2 prüft das zuerst.
- Balance der Ausfallzeiten ist ungespielt.

## Stand der Umsetzung (15.11.2026)

Quelle: das Protokoll `.superpowers/sdd/ausfall-und-rueckzug/progress.md`, die Berichte je Aufgabe im selben Ordner und `git log`. Branch `task/spielrunde-ausfall-rueckzug-20261115` (von `main` `9fe0b659b`). Die Zahlen sind die zuletzt im Protokoll oder Bericht gemessenen; dieser Abschnitt hat nichts neu gemessen. „Geprüft“ heißt: Umsetzer fertig, Prüfer (Anforderungen und Qualität) ohne offenen Kritisch- oder Wichtig-Befund, gegebenenfalls nach Fix-Runden. Aufruf der Tests: `$env:APPDATA = "$env:TEMP\<Wegwerf-Profil>"; godot_console.exe --headless --path . -s scripts/tests/<name>.gd`; maßgeblich ist die Schlusszeile.

Zur Aufgabendatei und zum Plan selbst gehören die Commits `2fcf3bd23` (Entwurf), `658e6940c` (Regeln freigegeben, Malus in Aufgabendatei und Plan), `0c9b82ede` (Bergungsradius 180) und `4284b9ea5` (was als Rückzug zählt, Abflug mit Ausgefallenen, Einsatzsperre nur an der Heimatbasis).

| Aufgabe | Inhalt | Commits | Test, zuletzt gemessen | Stand |
| --- | --- | --- | --- | --- |
| 1 | Regeln als Daten und reiner Resolver | `dea226123`, Fix `7530fa037` | `campaign_casualty_rules_verifier` 20/0 | geprüft |
| 2 | Driver: Schalter, kein Respawn, Versorgungsfrist | `7874d5376`, Fix `cecdc69fd` | `campaign_casualty_driver_verifier` 36/0 | geprüft |
| 3 | Kampagnenschalter beim Missionsaufbau, `was_downed`/`near_ship`/`aboard`, Radius 180 | `d8ec72aa7` | `campaign_casualty_result_verifier` 68/0 | geprüft |
| 4 | Einschiffen mit Ausgefallenen | `db648de9b`, Fix `9a279ff12` | `campaign_casualty_boarding_verifier` 64/0 | geprüft |
| 5a | Verluste erkennen und genau einmal anwenden | `555b5a403`, Fix `e3e3e6384` | `campaign_casualty_apply_verifier` 225/0 (219/0 bis Aufgabe 8b), `campaign_casualty_debrief_retry_test` 164/0 | geprüft |
| 5b | Malus bei Totalverlust nach dem Rücksprung | `ad3428128`, Umbau auf Zusatzdatei `e947cded6` | `campaign_total_loss_penalty_verifier` 266/0 (P5 einzeln 44/0) | geprüft (Stand 16.11.2026) |
| 3a Gesamtprüfung | K1 Beleg gefallener Polisa-Anwerber bleibt gültig (`validate_payload`), I1 Abflug ohne Ausfälle als Rückzug, I2 Ausfallregeln nach Fortsetzen eines Einsatz-Autosaves (`_apply_campaign_casualty_rules`), I3 Gate sperrt bei wartendem Ergebnis (`mission_result_pending`); Vertrag und Aufgabendatei berichtigt | Code-Commit und Dokumente-Commit dieser Runde (Hashes im Bericht `final-fix-report.md`) | `campaign_casualty_roster_verifier` (Z17), `campaign_casualty_departure_verifier` A und M einzeln, `campaign_retreat_reopen_at_home_verifier` R4, `campaign_casualty_final_fix_verifier` 44/0 | umgesetzt, Zahlen im Bericht |
| Merge | aktuelles `main` eingemergt (Merge-Commit `14eca8465`) | `14eca8465` | siehe Bericht | erledigt |
| 5c | Abflug ohne Missionsauflösung durch die Verlustauswertung, Abflug-Gate im Controller | `854662390`, `7ea87deda`, `fb813cfcd` | `campaign_casualty_departure_verifier` 519/0 (voller Lauf rund 25 Minuten, auf `fb813cfcd`) | geprüft |
| 6a | Gefallenenliste im Kampagnen-Checkpoint | `77a090df5` | `campaign_casualty_fallen_list_verifier` 45/0 | geprüft |
| 6b | Gefallene aus Kader, Basis, Trupps, Ausrüstung; Nachrücken; geschützte Personen | `1646e0b53`, Fix `ae15afbae` | `campaign_casualty_roster_verifier` 234/0 | geprüft (ein Punkt per Ruling zurückgestellt: leerer Trupp bleibt stehen) |
| 7a | Ausfallzeit zählen und beschreiben, Einsatzsperre, Abflugsperre nur an der Heimatbasis | `0bcec32bd`, Fix `8eba7a990` | `campaign_casualty_recovery_verifier` 44/0 | geprüft |
| 7b | Ausfallzeit im Spielablauf in Echtzeit, Einsatzsperre aus dem Kader | `414c386df`, Fix `2abfb0565` | `campaign_casualty_recovery_flow_verifier` 105/0 (rund 4 Minuten) | geprüft |
| 8a | Kampagnenstand: `retreat_count`, `reopen_at_home`, Operation `reopen_retreated_job` | `f2c321bbf` | `campaign_retreat_keeps_job_open_verifier` 102/0 | geprüft |
| 8b | Wiederöffnen bei Heimkehr vor dem Basis-Checkpoint, `recovery_*` im Ergebnis | `8bfb79370` | `campaign_retreat_reopen_at_home_verifier` 194/0 (rund 4 Minuten) | geprüft |
| 9 | Anzeige in Debrief, Charakterblatt, Personenkarte, Auftragstafel | `b413384c6`, Fix `334494a74` | `campaign_casualty_display_verifier` 72/0 | geprüft |
| 10 | Verträge und Unterlagen (10a), Aufsetzen auf `main` und kurze Regression (10b), Gesamtprüfung (10c) | 10a: der Commit mit dieser Datei | 10a: keine Tests (nur `docs/`) | 10a erledigt (Malus-Unterlagen am 16.11.2026 nach 5b gegen den Code nachgezogen); 10b „Aufsetzen auf `main` und kurze Regression“ und 10c „Gesamtprüfung“ offen |

Vergleichsläufe nach den Aufgaben (unverändert gegenüber vorher, soweit im Bericht belegt): `campaign_save_menu_routing_verifier` PASS (mit `POLISA_TEST_PROFILE=1`), `campaign_checkpoint_run_id_verifier` PASS, `review8_ux_debrief_abort_verifier` 50/0, `character_sheet_compact_verifier` 25/0, `campaign_hex_autosave_interval_verifier` 17/0, `hex_campaign_continue_verifier` 17/0, `hex_base_personnel_owner_verifier` 68/0, `campaign_five_missions_state_test` 15/0, `campaign_five_missions_chain_test` 64/0, `campaign_supply_progression_verifier` failures=0, `medic_support_verifier` 30/0, `task_513_mission_combat_resolution_boundary` 26/0, `campaign_guard_vital_gate_verifier` failures=0, `playtest_l03_boarding_repro_verifier` 44/0 (nur für den Lauf vom anderen Branch geholt).

### Abweichungen vom Plan

Aus den Rulings des Protokolls; Björn entschieden sind mit [B] gekennzeichnet.

- Radius: `recovery_radius_world` 180 statt 72 (Ruling bei Aufgabe 3, Björn gemeldet; Begründung bei Regel 3).
- Aufgaben geteilt: 5 in 5a, 5b, 5c; 6 in 6a, 6b; 7 in 7a, 7b; 8 in 8a, 8b; 10 in 10a, 10b, 10c. Aufgabe 5c (Abflug ohne Missionsauflösung) ist neu und kam aus der Prüfung von 5a: Der Rückflug ohne Missionsauflösung verarbeitete keine Verluste.
- Abflug [B, 12:05]: Nur ein Abflug, nach dem keine einsatzfähige Person am Ort bleibt, ist ein Rückzug. Das ersetzt ein früheres Ruling („jeder freiwillige Abflug ist ein Rückzug“).
- Abflug-Gate im Missionscontroller statt nur im Flow (Ruling bei 5c): `_campaign_departure_gate` mit Setter `set_campaign_departure_gate`, weil der HUD-Knopf „Abheben“ den Flow umgeht. Der Controller ist eine geteilte Datei; der Eintrag stand vorher im Abstimmungsdokument.
- Das Gate löst nur auf, wenn der Abschluss sicher durchläuft (Vorprüfung des Treibstoffs); bei zu wenig Treibstoff kein Abheben, nichts gebucht. Ein Abflug aus einer nicht fokussierten Ortsinstanz mit Ausgefallenen wird gesperrt (`location_not_focused`), kein Kontextwechsel.
- Pilot fehlt in `team_states` gilt als einsatzfähig (Ruling bei Aufgabe 1).
- Einschiffen: Ein einsatzfähiger Pilot zählt als einsatzfähige Person; `crew_unavailable` wegen Ausfall nur, wenn in der betrachteten Gruppe niemand einsatzfähig ist; den Totalverlust `ground_team_down` stellt `resolve_mission` fest. `casualty_unit_ids` darf in frühen Ablehnungen fehlen.
- Die Versorgungsfrist gilt nur für eigene Einheiten (Aufgabe 2); Gegner bleiben unverändert.
- Verwundung wird nie kürzer oder leichter (Ruling bei 5a): Das Größere aus alter Restzeit und neuer Zeit, die schwerere Stufe; zwei leichte Wunden addieren sich nicht.
- Einsatzsperre nur an der Heimatbasis (Ruling bei 7a) [B, 23:07 bestätigt, siehe Regel 6].
- Aufgabe 8a: Der Aufruf des Wiederöffnens aus dem Flow kam erst mit 8b; eine vierte Datei (Befehlsvertrag) wurde freigegeben. Aufgabe 9: Die Auftragstafel zeigt „Offen · N Rückzüge“ auch für den zu Hause wieder geöffneten, angenommenen Auftrag; der Debrief liest keine Regeldatei, sondern die angewendeten `recovery_*`-Felder aus dem Ergebnis (Lieferseite in 8b).
- Aufgabe 6b: Geschützte Personen sterben nicht, sie überleben schwer verwundet [B, 23:07; als Ruling zuvor vorgeschlagen]. Die Absicherung greift nur bei „vorher gültig, nachher ungültig“; dafür wurde genau eine Prüfung im `campaign_casualty_apply_verifier` auf die neue Wahrheit umgestellt. Rucksack: neue Funktion `discard_person_equipment` beim Versorgungsstand; von der Auftragsfracht kommt höchstens ein Stück ins Basislager, der Rest wird verworfen (weicht vom Plansatz „kein Übertrag“ ab). Trupp-Bereinigung im Flow statt über Knopf-Handler der Basisansicht. Ein leer gewordener Trupp wird nicht aufgelöst, sondern bleibt stehen (weicht vom Plan ab).
- Aufgabe 5a: In `campaign_casualty_debrief_retry_test` wurde die Wartezeit angepasst und eine Erwartung geändert (Einschiffen mit liegendem Truppführer und fittem Piloten ist seit Aufgabe 4 `ok`); der Test lief vorher 25/1, danach 164/0.
- Aufgabe 7b: Das Frame-Delta wird auf 2,0 Sekunden gedeckelt, damit lange Hänger nicht als Ausfallzeit zählen.
- Reihenfolge am Ende [B, 23:07 und 23:10]: Paket 3a fertig machen, dann Merge nach `main` (Björns Ja gilt für diesen einen Merge), dann EXE bauen, dann die langen Läufe. Vor dem Merge bleibt Pflicht: Aufsetzen auf aktuelles `main`, kurze Tests, die drei Prüfskripte des Bedien-Strangs, Gesamtprüfung des Branches.

### Nicht geprüft / offen

- Der Malus bei Totalverlust (Aufgabe 5b) ist umgesetzt und geprüft; Feld- und Funktionsnamen stehen im Vertrag (Regel 7). Ungeprüft bleiben `review_completion_ux_20261113` und `review_completion_home_save_verifier` (ohne Projektkopie nicht lauffähig), und `scripts/tests/astra_campaign_fixes_20261113.gd` Zeile 57 ist durch den Malus bewusst falsch.
- Bekannte Grenzen aus der Gesamtprüfung: Die `was_downed`-Flags überleben kein Einsatz-Autosave (nicht gespeichert, offen). Ein lebender `polisa_recruit_*` in einer Hex-Kampagne scheitert vorbestehend an `checkpoint_recruit_presence_missing`. Nicht gelaufen: voller `campaign_casualty_departure_verifier`, `campaign_two_moon_roundtrips_real_verifier`, `playtest_20261110_two_location_runtime_verifier -- revisit`.
- Zurückgestellt (Ruling): leerer Trupp bleibt stehen (Funktion `remove_fireteam` in `homebase_screen.gd` fehlt); Restzeit auf der Personenkarte läuft nicht sichtbar mit (Kaderkopie der Basisansicht); Meldung „Alle an Bord“ mit Liegenden und `get_selected_team_boarding_snapshot` setzt bei 0 Gesundheit `can_board = false` (Wunsch an den Bedien-Strang). Alle drei nach dem Merge.
- Ungeklärt aus der Prüfung von 6b (heute nicht erreichbar, wird mit größeren Trupps relevant): (a) Mitglieder, die in der Ansichts-Definition eines Trupps stehen, aber nicht gestagt sind, könnten die Tote in den Checkpoint tragen; (b) `_mission_planning_state["selected_fireteam_definitions"]` und `drop_state` werden nicht bereinigt.
- Ein echter Einsatz mit Toten ist mit der Zweierbesatzung nicht herstellbar; der Pfad ist direkt geprüft, nicht Ende-zu-Ende. Ebenso nur am Code belegt: die Buchung eines Siegs mit Verwundetem (`completed` oder `pending_upload`; der Auftrag bleibt im Test `active`), Fortsetzen mit laufendem Einsatz und Sperre, ein zweiter Einsatz in derselben Instanz nach einem ausgewerteten Abflug, die Altquellen `fob` und `homebase_direct_then_fob`.
- Nicht prüfbar ohne Projektkopie: `review_completion_ux_20261113` (isoliertes Projekt erforderlich) und `review_completion_home_save_verifier` (nicht gefahren).
- Textlängen in der Anzeige sind kopflos nicht prüfbar; Björn sieht sie beim Spielen. Die Balance der Ausfallzeiten und des Malus ist ungespielt.
- Weitere Einzelheiten und kleine zurückgestellte Punkte der Prüfer stehen im Vertrag unter „Bekannte Grenzen“ und im Protokoll.
- Schon vor Paket 3a rot (im Protokoll geführt, nach dem Aufsetzen auf `main` neu messen): `campaign_five_actual_sorties_verifier` 92/1, `campaign_active_mission_continue_verifier`, `campaign_pilot_ground_loop_test` 31/1, `character_navigation_equipment_verifier` 4, `playtest_20261110_place_dressing_verifier` 2, `playtest_20261105_explorable_homebase_verifier` 2, `task_182_terrain_hill_rules_contract_verifier` 83/3, `campaign_retry_boundary_test` failed=3, `task_237_mission_progression_xp_morale_frustration` 16/2, `task_1069_station_route_evac_abort_outcome` 14/2, `playtest_20261110_extraction_loop` 31/1, `campaign_legacy_satellite_boarding_verifier` 32/1, `playtest_20261109_campaign_landed_craft_verifier` 4/7, `playtest_20261109_actual_craft_return_binding_verifier` 9/7, `polisa_shuttle_full_loop_verifier` 9/2, `polisa_shuttle_real_ground_verifier` 9/4, `polisa_recruit_controller_verifier` (2 SCRIPT ERROR), `compact_singleplayer_panels_verifier` 7/1, `polisa_player_departure_flow_verifier` (Parse Error), `campaign_onboarding_state_test` (SCRIPT ERROR Zeile 129). Bekannt und nicht von diesem Paket: `_on_mission_combat_resolved` bricht bei gescheitertem `authorize_return` ab (Einsatz aufgelöst, nichts gebucht).
- Die neun vorhandenen Tests aus Task 10 des Plans (`campaign_two_moon_roundtrips_real_verifier`, `campaign_five_actual_sorties_verifier`, `campaign_pilot_ground_loop_test`, `campaign_active_mission_continue_verifier`, `campaign_onboarding_state_test`, `campaign_supply_progression_verifier`, `task_237_mission_progression_xp_morale_frustration`, `task_1071_station_route_full_victory_debrief_trace`, `review2_20261102_p1_hidden_mission_verifier`) sind als Ganzes gegen die vor Beginn notierten Zahlen noch nicht verglichen (10b). Einzelne davon liefen als Vergleich in Aufgaben: `campaign_supply_progression_verifier` failures=0, `task_237` 16/2 (vorher gleich), `campaign_onboarding_state_test` mit SCRIPT ERROR Zeile 129 (vorher gleich), `campaign_two_moon_roundtrips_real_verifier` 83/0.
- `main` steht inzwischen auf `05878c9bd` (Grafik P7 bis P9, Einzelsteuerung des Bedien-Strangs; Missionscontroller mit mehr als 300 Zeilen Änderung). Der Branch ist vor dem Merge neu aufzusetzen, die geänderten `.glb` brauchen einen Neuimport, danach laufen die drei Prüfskripte des Bedien-Strangs und `campaign_two_moon_roundtrips_real_verifier`.

### Lange Läufe, noch nachzuholen

Auf Anweisung von Björn [B, 15.11., 18:27] („überspringe so lange Tests und mach die später“) in den Aufgaben ausgelassen und nach dem Merge auf `main` gesammelt nachzuholen. Was nicht gelaufen ist, gilt nicht als bestanden.

- `campaign_casualty_departure_verifier`: zuletzt 519/0 auf `fb813cfcd` (voller Lauf, rund 25 Minuten). Seither nach den Aufgaben 6a, 6b, 7b, 8b und 9 nicht wiederholt.
- `campaign_two_moon_roundtrips_real_verifier`: zuletzt 83/0 laut Protokoll auf `7ea87deda` (gut 10 Minuten). Nach den späteren Änderungen nicht wiederholt.
- Aus den Aufgaben 6b und später übersprungen, weil nicht verlangt oder lang: `campaign_casualty_boarding_verifier`, `campaign_casualty_result_verifier`, `campaign_casualty_driver_verifier` nach den Änderungen von 6b (zuletzt 64/0, 68/0, 36/0).
- Zusätzlich nach Task 5b: der neue Test `campaign_total_loss_penalty_verifier` und, was 5b als übersprungen meldet. P5 des Tests ist gelaufen (einzeln 44/0 in 110 s); der Gesamtlauf mit 266/0 steht im Vertrag.
- Aufruf: `cd C:\dev\SternenBuergerchen-worktrees\spielrunde-ausfall-20261115; $env:APPDATA="$env:TEMP\sb_spielrunde_profil"; cmd /c "start /belownormal /b /wait godot_console.exe --headless --path . -s scripts/tests/<NAME>.gd" *> "$env:TEMP\<NAME>.out"; Get-Content "$env:TEMP\<NAME>.out" -Tail 30`. Immer nur ein Godot-Prozess, Schlusszeile auswerten.
