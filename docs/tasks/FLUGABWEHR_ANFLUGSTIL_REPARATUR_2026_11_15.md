# Flugabwehr: Anflugstil je Schiff, Tiefflug, Reparatur der Schiffsintegritaet

## Ziel
Der Spieler waehlt je Missionsschiff einen Anflugstil ("vorsichtig", "normal", "aggressiv"). Der Stil
entscheidet, wie das Schiff auf Flugabwehr reagiert:
- vorsichtig: Tiefflug (Profil `low`), abdrehen unter Beschuss, Landestreukreis x 1,5.
- normal: Profil `normal`, abdrehen unter Beschuss.
- aggressiv: Profil `normal`, weiterfliegen unter Beschuss; die Landung laeuft trotz Treffern, der Spieler sieht
  "Flugabwehr: N Treffer, Rumpf N %".
Ein Servicepad, das ein Schiff repariert, setzt auch dessen `AirAssetStatus` wieder auf Integritaet 100 / intakt.

## Ursache
Nach `docs/tasks/FLUGABWEHR_ANSCHLUSS_2026_11_14.md` speichert der Missionscontroller keinen Anflugstil. Jeder
beschossene Anflug dreht ab, eine LZ in Waffenreichweite ist nie erreichbar, solange die Besatzung lebt. Der
Schaden (`AirAssetStatus`-Integritaet) wird nirgends repariert.

## Umfang
1. Anflugstil je Missionsschiff, gespeichert dort, wo der Controller den Anflugwinkel speichert: skalarer Wert des
   gewaehlten Schiffs (`_current_approach_style`, wie `_current_approach_index`), Schluessel `approach_style` in
   der Schiffskarte (`mission_drop_cards`) und im Planungszustand (`get_planning_state` / `set_planning_state`).
   Standard "normal". Neuer Befehl `set_dropship_approach_style` (wie `set_dropship_approach`) mit Pruefung im
   `MultiplayerCommandContract` (unbekannter Wert -> abgelehnt), Weitergabe in `SimulationRoot`, Anwendung im
   Controller.
2. Bedeutung im Anflugplan (`scripts/mission/air_defense_approach_plan.gd`): Stil -> Profil und Entscheidung,
   unbekannter Stil -> "normal". Zerstoert -> weiter erzwungener Abbruch mit Rumpf 1 %.
3. Preis des Tiefflugs: Streukreis der Landung x `approach_profiles.low.lz_radius_factor` (1,5), nur bei
   "vorsichtig", an der einen Stelle `_resolve_campaign_field_lz` -> `FIELD_LANDING.resolve` ->
   `DropshipLZAccuracyContract.resolve_lz_command` als optionaler Parameter mit Standard 1,0.
4. Bedienung: eine kleine Dreier-Zeile "Vorsichtig / Normal / Aggressiv" direkt unter der Befehlszeile der
   Schiffskarte (LZ, Anflugwinkel, Drop), gleicher Knopfstil, Tooltip je Knopf in einer Zeile.
   Die Verhaltens-Umschaltung des Trupps (Vorsichtig / Normal / Offensiv) ist etwas anderes und bleibt unberuehrt.
5. Reparatur: `_repair_ground_ship_at_service` in `scripts/core/simulation_root.gd` setzt nach erfolgreicher
   Reparatur auch den `AirAssetStatus` des Schiffs ueber `_apply_air_asset_status_update_effect`
   (Effekt `air_asset_status_update`) auf 100 / intakt. Gleicher Preis, gleiche Bedingungen.
6. Befund (unten): Ueberlebt der Schaden das Missionsende?

## Nicht-Ziele
- Keine Persistenz der Integritaet in diesem Schritt.
- Sichtlinie bleibt immer frei, keine Gelaendeabdeckung.
- Start und Bergung (Abflug) unter Beschuss bleiben offen.
- Keine neuen Panels, keine neue Wirtschaft, keine Kosten fuer den Abbruch.

## Contracts / Dokumente
- `docs/dev/ground_air_defense_engagement_contract.md`
- `docs/dev/air_asset_threat_damage_contract.md`
- `docs/tasks/FLUGABWEHR_ANSCHLUSS_2026_11_14.md`
- `AGENTS.md`, `docs/CODEX_RULES.md`

## Akzeptanzkriterien
- Stil -> Profil / Entscheidung: vorsichtig -> low / abdrehen, normal -> normal / abdrehen,
  aggressiv -> normal / weiter; unbekannt oder leer -> normal.
- Tiefflug unter dem Horizont einer Stellung auf einem Kamm: kein Feuer, wo `normal` beschossen wird.
- Echter Controller auf GM02: aggressiv landet trotz Treffern und schreibt den Schaden (Feld 81,86, Anflug NW:
  "Flugabwehr: 2 Treffer, Rumpf 93 %"); normal und vorsichtig drehen neben der Batterie (Feld 90,85) ab
  (Rumpf 38 % bzw. 24 %; vorsichtig wird dort trotz Tiefflug erfasst).
- Der Stil ueberlebt `get_planning_state` -> `set_planning_state` wie der Anflugwinkel; ein unbekannter Wert im
  Befehl wird abgelehnt.
- Streukreis x 1,5 nur bei vorsichtig; alle anderen Aufrufer erhalten den alten Streukreis.
- Reparatur am Servicepad setzt die Integritaet auf 100 / intakt (echter Pfad Supply -> `SimulationRoot` in
  `map_services_verifier_20261114`, Hilfsfunktion zusaetzlich im Landetest).

## Betroffene Dateien
- `scripts/mission/air_defense_approach_plan.gd`
- `scripts/mission/dropship_lz_accuracy_contract.gd`, `scripts/mission/field_landing_contract.gd`
- `scripts/multiplayer/multiplayer_command_contract.gd`
- `scripts/core/simulation_root.gd`
- `scripts/tests/mission_tactical_sandbox_controller.gd` (Speicherung, Befehl, Bedienung, Aufruf)
- `scripts/tests/air_defense_approach_plan_verifier.gd`, `scripts/tests/air_defense_approach_landing_verifier.gd`,
  `scripts/tests/map_services_verifier_20261114.gd`
- `docs/dev/ground_air_defense_engagement_contract.md`, `docs/IMPLEMENTATION_STATUS.md`

## Lokale Pruefung
- `godot --headless --path . -s scripts/tests/air_defense_approach_plan_verifier.gd`
- `godot --headless --path . -s scripts/tests/air_defense_approach_landing_verifier.gd`
- `godot --headless --path . -s scripts/tests/map_services_verifier_20261114.gd`
- Regression: `air_defense_engagement_verifier`, `ground_mission02_relay_ridge_verifier`,
  `playtest_20261110_free_landing_verifier`, `campaign_pilot_ground_loop_test`, `campaign_maps_content_verifier`,
  Tests rund um Anflugwinkel und Schiffskarte (`task_397`, `task_398`, `task_1111`).

## Befund: Ueberlebt der Schaden das Missionsende?
Nein, nicht als Integritaetswert. Belege:
- Die Integritaet liegt nur in `SimulationRoot._air_asset_status_by_id` (`scripts/core/simulation_root.gd:2306`,
  geschrieben in `_apply_air_asset_status_update_effect`). `SimulationRoot` gehoert zur Missionsinstanz; kein
  `export_state`/Speicherpfad liest diesen Wert. Ausser dem Netzwerk-Schnappschuss
  (`_build_air_asset_status_snapshots`, `simulation_root.gd:4903`) gibt es keinen Leser.
- Am Missionsende liest `MetaLayerFlow._extract_air_asset_status_from_mission` (`scripts/meta/meta_layer_flow.gd:4665`)
  zuerst den Status des Controllers (`get_air_asset_status_snapshot`, Controller Zeile ~19473, ein einzelner
  `_air_asset_status`, beim ersten Zugriff intakt angelegt) und nur ohne diesen den Wert aus `SimulationRoot`.
  Der Controller-Status wird bei Flugabwehr nur nachgefuehrt, wenn seine `asset_id` gleich der Schiff-ID ist.
- `_apply_air_asset_recovery_from_mission_result` (`meta_layer_flow.gd:4684`) macht aus einem Schadenszustand
  (`hit`/`damaged`) einen Reparaturauftrag `damaged_repairing` mit festem Zeitwert (`DEFAULT_REPAIR_SECONDS` 90 s,
  `scripts/meta/air_asset_recovery_state.gd:13`) und schickt das Schiff zur Heimatbasis. Die Hoehe des Schadens
  geht dabei nicht ein; nach Ablauf ist das Schiff wieder verfuegbar.
- Kein Pfad schreibt einen `AirAssetStatus` in die `SimulationRoot` der naechsten Mission (keine weitere
  Schreibstelle von `air_asset_status_update` ausser Bedrohungs-Resolver, Dropship-Effektadapter und Flugabwehr).
- `get_air_asset_recovery_snapshot` / `load_air_asset_recovery_snapshot` (`meta_layer_flow.gd:3861`, `3871`)
  haben ausserhalb von Tests keinen Aufrufer: auch der Reparaturauftrag wird nicht gespeichert.
- Folge: Naechste Mission, Rueckkehr zur Heimatbasis und Laden beginnen mit Integritaet 100. Innerhalb einer
  laufenden Missionsinstanz (auch Kampagnen-Ort, solange er geladen bleibt) bleibt der Schaden bestehen.

## Risiken / offene Punkte
- Vorsichtig dreht auf GM02 nur dann ab, wenn das Schiff trotz Tiefflug erfasst wird; ueber tieferem Gelaende
  bleibt es unter dem Horizont der Stellung und landet ohne Beschuss.
- Der Faktor 1,5 wirkt nur auf dem Kampagnen-Feldlandepfad (`_resolve_campaign_field_lz`); andere Landepfade
  streuen nicht ueber diesen Contract.
- Unter 35 % Rumpf dreht der Pilot auch bei aggressiv von sich aus ab (Regel des Regelkerns).
- Der Controller-Status (`_air_asset_status`) wird von der Reparatur nicht angefasst; er folgt nur der
  Flugabwehr-Schreibstelle.
- Der Effekt der Flugabwehr wird erst im naechsten Tick geschrieben; eine Reparatur im selben Frame wird von dem
  noch wartenden Effekt ueberschrieben (im Test mit Warten auf Physik-Frames abgefangen).
- Die Dreier-Zeile sitzt unter der Befehlszeile (LZ / Anflugwinkel / Drop), nicht in derselben Zeile: in der Zeile
  ist fuer drei beschriftete Knoepfe kein Platz.
