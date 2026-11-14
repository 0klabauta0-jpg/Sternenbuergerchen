# Flugabwehr am echten Landeanflug anschliessen

## Ziel
"Hagel" und "Donnerkeil" stehen auf `maps/Ground_Mission02_128x128.json` als Props. Ein Landeanflug, der in ihre
Reichweite fuehrt, wird jetzt mit dem vorhandenen Regelkern gewuerfelt: Das Schiff nimmt Schaden, der Anflug
wird abgebrochen oder geht weiter.

## Ursache
Der Regelkern `scripts/combat/air_defense_engagement.gd` ist fertig und geprueft, hat aber keinen Aufrufer.
Der Missionscontroller startet die Landung in `_try_start_drop_sequence`, ohne die Fahrzeuge zu kennen.

## Umfang
- Neues reines Skript `scripts/mission/air_defense_approach_plan.gd`: Fahrzeuge aus den Map-Props, Anflugweg in
  Salven, Besatzung aus den Fit-Zaehlern der Gegnergruppe, Schiffswerte, Ergebnis, Statusbild fuer das Schiff.
- Ein abgesicherter Aufruf im Missionscontroller am Startpunkt der Landung, nach der LZ-Pruefung und vor dem
  Inbound. Nur auf der autoritativen Seite (Einzelspieler / Server), nie auf einem Netzwerk-Client.
- Kleine oeffentliche Abfrage `get_enemy_group_fit_counts()` im Kampftreiber, die die vorhandene Zaehlung
  `_build_enemy_group_fit_counts()` wiederverwendet.

### Festgelegte Regeln dieses Schritts
1. Fahrzeug = jedes Prop, dessen `asset` ein Schluessel von `data/combat/air_defense_units.json` `units` ist.
   Feld = Prop-`center` (Kartenebene x,z) als Hexfeld, Bodenhoehe = `height_level` dieses Feldes.
2. Besatzung: Ein Fahrzeug feuert nur, solange die Gegnergruppe aus
   `tactical_authoring.air_asset_risk.enemy_group_id` noch mindestens ein kampffaehiges Mitglied hat. Fehlt die
   Angabe oder kennt der Kampftreiber die Gruppe (noch) nicht, sind die Fahrzeuge Kulisse.
3. Ausloeser: einmal am Startpunkt der Landung. Start und Bergung (Abflug) sind nicht Teil dieses Schritts.
4. Anflugweg: gerade Linie in der Kartenebene vom Inbound-Startpunkt, den der Controller schon benutzt
   (LZ + Anflugrichtung x Abstand ausserhalb der Karte), bis zur aufgeloesten LZ; alle 4 Hexfelder eine Salve,
   dazu die LZ selbst. Bodenhoehe unter dem Schiff = Hoehe des Feldes darunter, ausserhalb der Karte 0.
   Profil "normal". Sichtlinie: `true` (siehe offene Punkte).
5. Entscheidung: Der Controller speichert keinen Anflugstil (`approach_style_options` gibt es nur als Liste).
   Daher immer "abdrehen" (`AD.DECISION_BREAK_OFF`). "aggressiv" wuerde "weiter anfliegen" bedeuten.
6. Pilotenkoennen `dropship_piloting` wie bei `_resolve_campaign_field_lz` (Standard 0,5);
   Seed = Schiff-ID + LZ + ":air_defense".
7. Schiffszustand: Weg (b), `AirAssetStatus` je Schiff (`asset_id` = Schiff-ID), Integritaet 0..100 = Rumpfanteil,
   Zustand `hit` / `damaged`, ueber den vorhandenen Effekt `air_asset_status_update` an `SimulationRoot`.
   Weg (a) gibt es nicht: `space_combat_state` haelt Schiffssysteme nur fuer zugelassene Weltraum-Akteure, und die
   einzige Schreibstelle `_commit_ship_impact` verlangt ein schiessendes Schiff mit Waffe. Schiffswerte fuer den
   Regelkern: `space_component_catalog.effective_stats(model_id, default_slots)`, Modell der Karte oder "cutlass".
8. Ergebnis: abgebrochen -> Landung startet nicht, Rueckgabe `false`, Meldung "Flugabwehr: Anflug abgebrochen,
   Rumpf 72 %". Das Schiff bleibt fuer einen neuen Versuch verfuegbar. Weiter -> Landung wie bisher, Meldung
   "Flugabwehr: 3 Treffer, Rumpf 82 %". Zerstoert -> der Controller hat keinen Pfad fuer ein abgestuerztes Schiff
   im Inbound; deshalb erzwungener Abbruch, Rumpf auf 1 % gehalten (offener Punkt).
9. Keine Ereignisse (kein besetztes Fahrzeug erfasst das Schiff) -> Verhalten genau wie vorher.

## Nicht-Ziele
- Keine neue Abfrage "abdrehen?" im HUD, keine Anzeige der einzelnen Salven.
- Keine Gelaendeabdeckung der Sichtlinie, kein Tiefflug.
- Keine Reparatur der Integritaet, kein Absturzpfad, keine Kosten fuer den Abbruch.
- Fahrzeug als Bodeneinheit (Beschuss, Uebernehmen) bleibt offen.

## Contracts / Dokumente
- `docs/dev/ground_air_defense_engagement_contract.md`
- `docs/dev/air_asset_threat_damage_contract.md`
- `docs/CODEX_RULES.md`, `AGENTS.md`

## Akzeptanzkriterien
- Auf GM02 werden genau zwei Fahrzeuge gefunden (Hagel, Donnerkeil) mit Feld und Bodenhoehe aus der Karte.
- Ein Anflug auf das westliche Landefeld (LZ Alpha) aus Nordwest oder Suedwest liefert keine Ereignisse.
- Ein Anflug, der nahe der Flugabwehr-Ecke endet, liefert Radarkontakt und Feuer.
- Hat die Besatzungsgruppe null kampffaehige Mitglieder, feuert nichts.
- Gleicher Seed -> gleiches Ergebnis.
- Abbruch -> keine Landung, Meldung auf Deutsch; Weiterflug -> Landung wie vorher plus Kurzmeldung.
- Ohne Ereignisse aendert sich am Start der Landung nichts.

## Betroffene Dateien
- `scripts/mission/air_defense_approach_plan.gd` (neu)
- `scripts/tests/air_defense_approach_plan_verifier.gd` (neu)
- `scripts/tests/air_defense_approach_landing_verifier.gd` (neu, Integration mit echtem Controller)
- `scripts/tests/mission_tactical_sandbox_controller.gd` (Aufruf + Kleber)
- `scripts/tests/mission_combat_loop_driver.gd` (eine oeffentliche Abfrage)
- `docs/dev/ground_air_defense_engagement_contract.md`, `docs/IMPLEMENTATION_STATUS.md`

## Lokale Pruefung
- `godot --headless --path . -s scripts/tests/air_defense_approach_plan_verifier.gd`
- `godot --headless --path . -s scripts/tests/air_defense_approach_landing_verifier.gd`
- Regression: `air_defense_engagement_verifier`, `ground_mission02_relay_ridge_verifier`,
  `campaign_pilot_ground_loop_test`, `campaign_maps_content_verifier` und Tests rund um `_try_start_drop_sequence`.

## Risiken / offene Punkte
- Sichtlinie ist nicht an das Gelaende angeschlossen (immer frei). Die vorhandenen LOS-Helfer rechnen Boden zu
  Boden mit Bodenhoehen der Endfelder und passen nicht zu einem Schiff in Flughoehe.
- Ohne gespeicherten Anflugstil wird immer abgedreht: Eine LZ in Waffenreichweite ist nicht erreichbar, solange
  die Besatzung lebt. Das ist so gewollt bis zur Abfrage "abdrehen?".
- Zerstoerung im Anflug: kein vorhandener Absturzpfad; erzwungener Abbruch mit Rumpf 1 %.
- Die Integritaet wird nirgends repariert; `_repair_ground_ship_at_service` repariert nur die
  Weltraum-Schiffssysteme. Die Integritaet wird beim naechsten Anflug als Startrumpf gelesen.
- Der Effekt wird erst im naechsten `SimulationRoot`-Tick geschrieben; ein zweiter Versuch im selben Frame liest
  noch den alten Wert.
- Wiederholte Versuche zur selben LZ wuerfeln mit demselben Seed vom gespeicherten Rumpf aus weiter; im
  Integrationstest fuehrt der zweite Versuch an der Batterie zur erzwungenen Abbruch-Zerstoerung (Rumpf 1 %),
  danach bleibt das Schiff bei 1 % und kann dort nie landen, solange die Besatzung lebt.
- Kennt der Kampftreiber die Gruppe zum Zeitpunkt der Landung noch nicht (noch nicht erschienen), bleibt die
  Flugabwehr fuer diesen Anflug Kulisse.
