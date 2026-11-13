# Combat-, Hex- und Multiplayerprüfung 12.11.2026

Quellbasis `cfddc129b`, Taskbranch `task/game-review-fixes-20261112` mit vorhandenem
fremdem WIP. Begrenzter Quellaudit; Testausführung wird vom Root sequentiell
koordiniert. Keine Produktdatei und kein echter Spielstand geändert.

## Aktiver Weg und Regelumfang

- Menü startet `scenes/ui/main_menu.tscn` (`project.godot:14`). Der reguläre
  Metaflow instanziiert tatsächlich `mission_reactivity_test.tscn`
  (`scripts/meta/meta_layer_flow.gd:3`, `:4133`). Der historische Tests-Pfad ist
  deshalb kein Beleg für inaktiven Code.
- Diese Szene besitzt genau einen `SimulationRoot`, `CombatLoopDriver` und
  `TacticalController` (`scenes/tests/mission_reactivity_test.tscn:41`, `:261`,
  `:672`). Der sichtbare Fireteampfad führt über TacticalController und
  FireteamMovementController zu UnitCommands; RuntimeLeader ist der erhaltene
  Kompatibilitätspfad, kein zusätzlich nachgewiesener Damage-Owner.
- CombatLoopDriver hängt auf der lokalen Authority an `tick_processed`
  (`scripts/tests/mission_combat_loop_driver.gd:249`, `:275`, `:1604`).
  CombatFireDecisionResolver wählt fit/angriffsbereite Ziele unter Feuerregel,
  Erkennung, Kontakt, LOS und Waffenreichweite (`scripts/tactical/combat_fire_decision_resolver.gd:8`,
  `:233`, `:322`). Sein Effect trägt Waffenwerte, Flanken- und Kontaktmodifikatoren
  (`:84`). Driver enqueued ihn (`scripts/tests/mission_combat_loop_driver.gd:1960`).
- SimulationRoot verarbeitet Commands und dann Effects im Physics-Tick
  (`scripts/core/simulation_root.gd:1058`). Trefferchance enthält Accuracy,
  Attackbonus, Profil, Höhe, Deckung und Evasion; derselbe DamageModel-Aufruf
  entscheidet Treffer und gerundeten Schaden (`:3173`, `:3230`, `:3250`, `:3297`).
  Es handelt sich um einen kontinuierlichen Zufallswert [0,1], nicht um mehrere
  belegte D6-/Rüstungswürfe (`scripts/core/damage_model.gd:5`).
- Hex ist wirklich in Terrain-/Navigations-/LOS-Geometrie aktiv: LOS benutzt
  Registry-Hexlinien und physische Distanz, während Legacy-Wände im Hexmodus
  ganze Blockerzellen bleiben (`scripts/core/los_system.gd:67`, `:87`, `:116`,
  `:144`). Das ist keine vollständige Migration aller Karten.
- Die aktive Zielschablone ist AreaOrder mit Zellen/Weltpolygon; sie filtert
  Zielpositionen und plant Stellungen (`scripts/tactical/area_order_resolver.gd:83`).
  Kein aktiver Explosions-/Kegel-/Abweichungs-AoE-Würfelpfad wurde in den
  untersuchten Kern-, Tactical- und Commanddateien nachgewiesen. Waffen besitzen
  Einzelzielschaden/Reichweite/Kadenz (`scripts/core/weapon_data.gd:9`).
- Ein NPC pro Hexfeld, zeitliche Feld-/Kantenreservierung und gemeinsame logische
  Hexsicht sind ausdrücklich erst geplant; siehe
  `docs/tasks/HEX_SIGHT_OCCUPANCY_2026_11_11_PLAN.md:3`. Die vorhandene
  kontinuierliche Bewegung/Spacing darf nicht als fertiger Planabschluss gelten.

## Singleplayer, Host und Client

Singleplayer und Host verwenden denselben Authority-Damagepfad und den privaten
seedbaren Combat-RNG von SimulationRoot (`scripts/core/simulation_root.gd:498`,
`:3381`). Normale und Overwatch-Effectproducer setzen kein `roll_override`;
das bestehende TASK119-Gate prüft diese Grenze. Globale `randf()`-Entscheidungen
für Disziplin/Misidentifikation im Driver sind zusätzlich vorhanden (`:2891`,
`:3105`); damit ist die gesamte Mission nicht allein durch combat_rng_seed
vollständig reproduzierbar. Das ist keine zweite Trefferautorität.

Verbundene server-authoritative Clients überspringen den Physics-Tick
(`scripts/core/simulation_root.gd:1126`) und Combatdriver entscheidet anhand
derselben Hostgrenze (`scripts/tests/mission_combat_loop_driver.gd:3848`).
Clients sollen deshalb keine gleichen lokalen Würfe ausführen, sondern die
Hostentscheidung spiegeln. Netzwerkcommands werden auf Authority validiert und
queued (`scripts/core/simulation_root.gd:783`, `:871`); Snapshots validieren
Reihenfolge und spiegeln Units/Objectives/Events (`:1525`), ohne Commands oder
Damageeffects daraus zu erzeugen. ENet-Konnektivität und echte mehrprozessige
Missionreplikation sind getrennte Nachweise.

## Befunde und bewusst verworfene Verdachtsfälle

Root-Ergänzung: `scripts/core/campaign_space_encounter.gd:23-30` ist ein
separater aktiver orbitaler Kampagnenpfad. Er zieht feste Hüllenpunkte pro
Sekunde ab (Cutlass26/3, Spieler7, neutral3/9), würfelt nicht und nutzt keine
Hex-/Zielschablone. Mutationen bleiben im CampaignSpace-Commandowner. Das ist
kein zweiter Boden-Unit-Damage-Owner, aber ausdrücklich keine spielweit
vereinheitlichte Würfelmechanik. `campaign_space_encounter_verifier.gd`
deckt Sieg, Neutralität, unautorisierte Ticks und Niederlage ab. Eine
Vereinheitlichung ist Design-/Migrationsarbeit, kein beiläufiger Bugfix.

**Keine bestätigten aktiven P1/P2/P3-Produktfehler aus diesem begrenzten Audit.**
Das bedeutet keine vollständige Multiplayer- oder Spielabnahme.

OverwatchController kann bei künstlichem `overwatch_ready = true` die normale
Feuerregel umgehen; sein früh gebauter Damageeffect enthält außerdem nicht die
später im Driver erzeugte fire_event_id (`scripts/tactical/overwatch_controller.gd:83`,
`:163`; `scripts/tests/mission_combat_loop_driver.gd:5552`). Der reale freundliche
Securityproducer gibt jedoch derzeit immer `overwatch_ready = false` zurück
(`scripts/tactical/fireteam_security_controller.gd:491`). Das ist ein latenter
Reaktivierungsbedarf, kein belegter Fehler im regulär aktiven Spielpfad; kein
Produktpatch im Rahmen dieses Audits. Feindliche Securitymetadaten enthalten
ebenfalls ein Overwatchlabel, werden aber nicht an diesen freundlichen
Overwatchproducer weitergereicht.

## Gezielte Prüfabdeckung

Neue Regression `scripts/tests/game_review_combat_20261112_parity.gd`:
12 identische Effects über echte SP-/Host-flag Physics-Queues, identische
Auflösung einschließlich Roll/Hit/Schaden/Vitals; Host-Snapshots spiegeln Health,
erzeugen keine Spiegelqueues und verbrauchen keinen Spiegel-Combat-RNG.
Erwarteter Marker: `GAME_REVIEW_COMBAT_PARITY: 37 passed, 0 failed`.
Dies ist ein lokaler Paritätstest ohne ENetpeer, kein echter verbundener Client.

Zusätzlich `scripts/tests/game_review_enet_20261112.gd`: zwei wirklich verbundene
ENet-/MultiplayerAPI-Subtrees mit identischen relativen SimulationRoot-Pfaden.
Acht echte Host-Physics-Ticks senden produktive komprimierte Snapshotchunks
per RPC; der Client wartet auf Reassembly und prüft identische Health.
Absichtlich lokal queued Clientdamage bleibt trotz manueller Tickversuche
unverarbeitet, erzeugt kein Damage-Signal und verbraucht keinen Combat-RNG.
Erwarteter Marker: `GAME_REVIEW_ENET: 31 passed, 0 failed`, Timeout60s.
Das ist reale lokale Transport-/Damageauthority-Abdeckung mit synthetischen
Units, kein vollständiger Lobby-/Missiondriver-/Internetpartielauf.

Empfohlene vorhandene Gates, jeweils 60s Timeout und Exit0/keine Scriptfehler:

| Script unter scripts/tests/ | Inhalt | Erfolgsmarker |
|---|---|---|
| task_119_verifier.gd | Seed-Replay, Seedunterschiede, explizite Testrolls, Liveproducer | ALL TESTS PASSED |
| task_166_multiplayer_authority_command_contract_verifier.gd | Team-/Fireteamrechte, Stateinjektion, Commandwhitelist | ALL TESTS PASSED |
| task_168_multiplayer_snapshot_contract_verifier.gd | Snapshotfelder, neuere/alte Ticks, keine Commandqueues | ALL TESTS PASSED |
| task_281_tactical_command_multiplayer_authority_snapshot.gd | Tactical-Whitelist, Privacy, Events, Spiegelung | ALL TESTS PASSED |
| frontier_hex_visibility_verifier.gd | Sechs Richtungen, Blocker, Umkehr, physische Reichweite/FOW, Squarelegacy | RESULTS mit 0 failed |
| bugfix_multiplayer_enet_connectivity_smoke.gd | Reale lokale ENetbindung/Verbindung, Port19327 | RESULTS: 3 passed, 0 failed |

Ausführungsergebnisse/Logs ergänzt der Root im zentralen Evidenzindex. Native
Bildqualität, Framerate, Netzwerkverlust/Latenz, Internetverbindungen und eine
vollständige Kampagnen-/PvP-Partie sind hier nicht geprüft.
