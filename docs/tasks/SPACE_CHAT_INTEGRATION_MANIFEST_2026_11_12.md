# Gesamtmanifest des Weltraum-Chats für die Main-Integration

Stand der Inventur: 12.11.2026. Dieses Dokument ist eine Übergabe, keine
Produkt-, Integrations-, Spielbarkeits- oder Releasefreigabe.

**Unveränderter Produktpin:** `a8a098fad9a6578d56354c6a0adba14ab2680991`
auf `task/space-air-parent-20261112`. Ein späterer Commit mit ausschließlich
diesem Manifest ändert den Produktpin nicht. Ground-Parent ist
`1b924b640f589c7ca5dabcc2f2da752f315d3c4b`; Merge `e0eabf0d6` führt diesen
Parent und den Komponentenstand `99d82f999` zusammen.

Der Companion-Chat ist der einzige Main-Integrator. Zuerst dessen laufenden
Port und AP7-/Fünf-Minuten-Autosave-Stand stabilisieren, anschließend den
neuen Main pinnen und die Weltraumpakete methoden- und datenweise abgleichen.
Keine Ganzdateiimporte oder konkurrierenden Main-Schreibarbeiten. Der zum
Zeitpunkt der Inventur uncommittete Companion-WIP basierte auf `639a49d65`
und wurde weiter bearbeitet; alle nachfolgenden Aussagen über diesen WIP
sind Momentaufnahmen, vor Übernahme erneut prüfen. Fremden WIP, vorhandene
Saves und Evidenz erhalten. Keine EXE ohne erneute Nutzerfreigabe.

## 1. Konzept und Raumkampfgrundlagen

- Konzept-/Planbranch `task/space-combat-plan-20261111` bei `de87366a6` ist
  Vorfahre des Produktpins. Siehe `docs/dev/space_combat_contract.md`,
  `docs/superpowers/plans/2026-11-11-space-combat.md` und
  `docs/tasks/SPACE_COMBAT_EXECUTION_2026_11_11.md`.
- Der ursprüngliche Implementierungsbranch
  `task/space-combat-implementation-20261111` bei `1358b86eb4e2` ist **kein**
  Vorfahre von `a8a098fad`; Merge-Base ist `613a03c3c`. Das bedeutet nicht,
  dass sein gesamter Inhalt fehlt: Er wurde teilweise selektiv übernommen.
- Implementierte Grundlagen umfassen Commandvertrag, Autorisierung und
  Replay; Flightowner und indexierte Hexzellen/Footprints; gekoppelten und
  ausgekoppelten Flug; Bewegungs- und Swept-Checks; Rottenverwaltung und
  Space-Wing-Panel; Warp-/Triebwerkswerte und versionsgebundene Equipment-Saves;
  lokale Orbitkarten, unteres Eintrittsband, Gate-/Flächenrevisionen, Claims,
  lokale An-/Abreise, Crew-/Boarding- und Polisa-Pickup-Transaktionen.
- Relevante Dateien sind `scripts/core/space_flight_state.gd`,
  `space_ship_registry.gd`, `space_combat_state.gd`, `space_wing_state.gd`,
  `simulation_root.gd`, die Resolver unter `scripts/tactical/`,
  `scripts/ui/space_wing_panel.gd`, `orbit_area_canvas.gd` und
  `scripts/meta/singleplayer_runtime_adapter.gd`.
- Viele lokale Bewegungs-/Area-Wege waren ausdrücklich Fixture- oder
  Flag-gebunden. `_local_warp_arrival_enabled` bleibt für den geprüften
  regulären Polisaweg aus. Daraus folgt keine allgemeine AP00–AP08- oder
  native Spielbarkeitsfreigabe.

## 2. Ursprünglicher Branch gegenüber Parent und Produktpin

`git log --right-only --cherry-pick --no-merges a8a098fad...1358b86eb`
nennt neun nicht durch Patch-ID übereinstimmende Commits:
`8ac24b4e8`, `f83299688`, `fb9d65ff2`, `d955acfff`, `a4d6e69d7`,
`98bb2084d`, `d2f2425a1`, `42176eaa6` und `2a872b762`.

Der inhaltliche Abgleich ergab:

- Polisa-Docklayout, Orbitkatalog, `space_ship_registry.gd`,
  `space_wing_state.gd`, `space_area_transition_resolver.gd`,
  `space_navigation_resolver.gd` und `space_orbit_entry_search.gd` sind
  zwischen `1358` und Parent `1b` bytegleich. `space_combat_state.gd` ist
  zwischen diesen beiden ebenfalls bytegleich und wird in `a8` erweitert.
- `d955acfff` und `d2f2425a1` betreffen Claims und Area-Revisionen; die
  genannten Runtime-Dateien liegen damit bereits im Parent vor. Die
  branchspezifischen Tests und Dokumentationshunks trotzdem gegen den neuen
  Main prüfen.
- `2a872b762` enthält den Hex-Türguard. Parent und Produktpin besitzen
  `can_block_cells`, `can_block_hex_ground_cells` und
  `_validate_hex_door_transition` in weiterentwickelter Form; keine alte
  Datei zurückkopieren.
- `036614ee1` betrifft den Station-Birth-Receipt, `069b1ac57` die gekoppelte
  Polisa-Aufnahme und -Abfahrt. Sie erscheinen beim Cherry-Vergleich als
  patchäquivalent; `is_station_purchase_local_admission_current` und der
  Adapterpfad sind im Produktpin vorhanden.
- `1358b86eb` und `a85932807` enthalten rote Polisa-AP6-Evidenz für Boarding
  und Retirement. Der ursprüngliche Worktree enthält außerdem zahlreiche
  ungetrackte QA-, Profil- und Output-Verzeichnisse. Diese sind zu bewahren,
  weder als integriert noch als löschbar zu behandeln.

## 3. Weitere Reise- und Polisa-Heads

- `task/polisa-playable-route-20261112` bei `f743fa200` und
  `task/polisa-full-roundtrip-20261112` bei `19b38644b` sind keine Vorfahren
  von `a8`. Der Vergleich mit `--right-only --cherry-pick --no-merges` liefert
  jeweils keine einzigartigen Patch-IDs. Dies ist ein Patch-Abgleich, kein
  Ersatz für die Prüfung der weiterentwickelten gemeinsamen Ownerdateien.
- Der physische Frachtaufzug (`2ce55298b`/`49000d7f6`) liegt in
  `scripts/ui/polisa_cargo_lift_feedback.gd`: Diese Datei war in beiden
  Polisa-Heads, Parent, Produktpin und dem geprüften Companion-WIP bytegleich.
  Der Aufzug ist eine quittungsgebundene 3D-Projektion; er ist keine zweite
  Frachtwahrheit.
- Der Polisa-Rundflug und sein Owner-Verifier liegen in `1b`/`a8` vor. Root,
  Adapter und Controller wurden gegenüber älteren Zweigen weiterentwickelt.
  Polisa bleibt direkt anfliegbar und erhält keine Orbitkarte.
- Die Heads `task/orbit-owner-integration-20261111` `78f5966b5`,
  `task/orbit-base-integration-20261110` `ee0591cfe` und
  `task/orbit-quantum-travel-20261109` `0f2425aa7` sind Vorfahren von `1b`
  und `a8`; daraus ist kein zusätzliches Branchdelta abzuleiten. Alte
  Zweige und ihre Evidenz bleiben erhalten.

## 4. Komponenten und Rettungsmission

`task/space-components-ap09-20261112` bei `99d82f999024` ist Vorfahre von
`a8`, aber nicht von `1b`.

- `dbfe8e0b2` bis `af6d92f5a`: vorläufiger S1–S5-Repeater-/Rumpfslotkatalog,
  Schild und Kraftwerk, Masse und Leistung im Flug, versionierter
  Equipmentowner und Supply-/Einbautransaktion.
- `06bd729d0` bis `d3579bab0`: Ziel- und Schussresolver, Waffenenergie,
  Cooldown, Schild-/Hüllenschaden und Root-Kampftick.
- `660b3e39e` bis `99d82f999`: Buccaneer-Rettungsmission mit gegnerischer
  Cutlass und Gegnerfeuer sowie Auftrags-, Ergebnis-, Fuel- und Rückwegbindung.
- Relevante Dateien: `data/space/ship_components.json`,
  `scripts/mission/space_component_catalog.gd`,
  `scripts/tactical/space_component_systems.gd`,
  `space_targeting_resolver.gd`, `space_weapon_resolver.gd`,
  `scripts/core/singleplayer_ship_equipment_state.gd`,
  `campaign_space_encounter.gd`, `space_combat_state.gd`, `simulation_root.gd`
  sowie Adapter, Supply/Travel und Encounter-Presenter. Werte sind vorläufige
  Spielannahmen; siehe `docs/tasks/SPACE_COMPONENTS_AP09_2026_11_12.md`.

Im lesend geprüften Companion-WIP waren Komponentendaten, Katalog,
Komponentensystem, Targeting-/Waffen-/Flug-/Guidance-Resolver,
`singleplayer_ship_equipment_state.gd` und `inventory_transfer_contract.gd`
bytegleich zu `a8`. Root und SpaceCombatState unterschieden sich und benötigen
semantischen Abgleich. `campaign_space_encounter.gd` und sein Presenter waren
im Snapshot noch bytegleich zum Parent; das spätere Rettungsdelta ist dort zu
prüfen. Der WIP kann inzwischen weitergeändert worden sein.

## 5. Atmosphäre und Bodenunterstützung

Commits `e6ba3c2bb` bis `a8a098fad` nach dem Merge ergänzen Bodenwirkung und
Pilotenstreuung, gekoppelte Atmosphäre, Bindung des Missions-Roots an die
bestehenden Fleet-/Wing-/Combat-/Equipmentowner, Pilot-/Boarding-/Sicht-/
Waffenprüfungen, Laserfeedback, Kartenbefehle und den Luftflugprototyp.

Schnittstellen sind unter anderem `bind_air_support_source`,
`_resolve_air_support_craft`, `request_air_support_takeoff`,
`request_air_support_landing`, `request_air_support_move`,
`request_air_support_attack_order`, `request_air_support_ground_fire`,
`request_air_support_cease_fire` und `_advance_air_support_orders`. Controller
und 3D-Ansicht senden Befehle bzw. projizieren State; sie werden keine zweite
Gameplaywahrheit. Adapter, Flow, Flug-/Kampfowner, Controller, Terrain-View,
`scripts/mission/air_support_dispersion.gd` und Verifier zusammen abgleichen.

Der Companion-WIP zeigte bei der Momentaufnahme bereits einzelne Adapter- und
Controllerhunks, während der Root die `request_air_support_*`-Methoden dort
noch nicht zeigte. Der Port war in Bewegung; dies ist keine Aussage über den
späteren Gesamtstand. Keine doppelten Tickowner oder UI-Gameplayzustände.

## 6. Nachweise und offene Grenzen

- Polisa-Rundflug auf dem kombinierten Stand: isoliertes Profil, 25/25,
  überwachte Quellen unverändert. Gebündelte Ownerprüfungen: unter anderem
  Hex-Ship 66/66, AP06-Guidance 11/11, Kampagnen-Entry/Return und Laser grün.
- Die Rettungsmission hatte auf einem früheren Raumstand einen echten
  20/20-Befehlstest. Das ist keine Abnahme des vollständigen Kampagnenlaufs
  auf kombiniertem Main.
- Älterer Mehrschiff-UI-Test: 59/61; dieselben zwei Fehler wurden mit dem
  unveränderten Controller vor `a8a098fad` reproduziert.
- Regulärer isolierter Headless-Kampagnenlauf
  `scripts/tests/campaign_air_support_real_mission_verifier.gd`: echte
  Personen, Reise, Satellitenmission, Landung, Boarding sowie sichtbarer
  Details- und Startknopf; **35 bestanden, eine fehlgeschlagen**. Der Start
  meldet `ground_unavailable`, da die tatsächliche Satellitenkarte den
  Legacy-Bodenmodus ohne `hex_tactical_v1` nutzt. `a8` korrigiert nur die
  zuvor beim Passagier-Refresh entfernte Luftbuttonzeile.
- Der Kampagnencheckpoint verweigert das Speichern während des Einsatzes;
  der allgemeine Missionsslot speichert nur den Szenenpfad. Kein Nachweis
  für Einsatz-Save/Load, vollständigen nativen/UI-/visuellen Ablauf,
  Multiplayer, Performance, EXE oder Release.
- Radar für Raum und Luft-Luft auf Bodenkarten, automatischer Orbitdurchflug,
  optionale Asteroiden, Orientierung oben Planet/unten System und visueller
  Feinschliff sind Zielvertrag, nicht fertig.

Vor jeder Übernahme den aktuellen WIP-Stand und die betreffenden Methoden
erneut erheben. Offene rote Grenzen bleiben sichtbar; dokumentierte Owner- oder
Fixturechecks dürfen nicht als Gesamtspiel- oder Releasebeleg ausgegeben werden.
