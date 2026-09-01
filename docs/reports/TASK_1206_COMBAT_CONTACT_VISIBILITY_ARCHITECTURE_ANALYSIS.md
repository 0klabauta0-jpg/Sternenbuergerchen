# TASK-1206 P03 — Topologie-Evidenz

## Laufumgebung

- Basis/Analyse-SHA: `c15a30e9028b860ff374253e7b42906120b94aad`
- Windows: Windows 10 Pro build 19045; AMD Ryzen 7 7800X3D; sichtbarer RAM 67,769,913,344 bytes
- Godot: 4.6.2.stable.official.71f334935
- Import: P00-Evidenz, Import exit 0 (prior evidence); P03 run itself had no Resource/Script errors
- Fixture: reale 16v12-Combat-Fixture, Minimum Spacing deaktiviert, 600 Ticks
- Modus: TASK-1206 Topology EIN, Varianten AUS

## Rohbeleg

`TASK1206_TOPOLOGY_JSON` (final run): schema `sternenbuergerchen.task1206.visibility_topology.v1`, SHA `c15a30e9028b860ff374253e7b42906120b94aad`, ticks `600`, pair dump `32`, oracle `7e5e7361ee194cac55e3f1795c3582cce12d9c7af9d613cce694beb6e23ce490`, control oracle identical, `oracle_match:true`.

Aggregierte Aufrufe: contact_tracking 129804 (95215 eindeutige gerichtete Paare), fire_pair_search 3735 (3539), enemy_security 10076 (10076), enemy_team_tactics 4933 (649), other_combat 200 (200). Wiederholungen: 34589, 196, 0, 4284, 0. Overlap: exact cross-consumer hits 3898; exact contact-producer/fire probes 421; reverse opportunities 93; range rejects 56042; missing producer 0.

Kosten (count/usec): signature/key 92706/3952677, lookup 92706/36408, entry write 49942/17377, terrain LoS 49942/3405698.

Final diagnostic costs (count/usec; per consumer): signature/key global 92706/3952677 — contact 73762/2956831, security 10076/902693, tactics 4933/28844, fire 3735/62961, other 200/1348. Lookup global 92706/36408 — contact 73762/27995, security 10076/3812, tactics 4933/2064, fire 3735/2427, other 200/110. Writes global 49942/17377 — contact 39180/13624, security 9517/3293, tactics 649/239, fire 592/220, other 4/1. Terrain global 49942/3405698 — contact 39180/2512978, security 9517/834128, tactics 649/11101, fire 592/46984, other 4/507.

Validity globals: direction 93 (contact 26, security 22, tactics 0, fire 44, other 1); registry identity 0 (0/0/0/0/0); registry revision 0 (0/0/0/0/0); source position 2460 (327/2041/0/92/0); target position 3713 (3713/0/0/0/0); tick 49655 (39088/9457/635/472/3).

## Query-Matrix aus den Countern

| Producer → Reuse | Richtung/Cadence | Range/Overlap | Reverse | Terrain saved | Zusatzarbeit |
|---|---|---|---:|---:|---|
| contact_tracking → fire_pair_search | gerichtete exakte Paare; tick-/zustandsabhängig | 421 exakte Producer-Fire-Probes; beide Konsumenten prüfen ihre eigenen Reichweiten | 93 nur Diagnose | nicht als Variante behauptet; reine LoS-Aufrufe 49942 | Key 92706, Lookup 92706, Writes 49942; Materialisierung nicht separat verfügbar |
| gespeicherter Producer → anderer Reuse-Consumer | gerichtete, ticklokale Abfragen; Producer-Tag nicht separat partitioniert | 3898 exakte Cross-Consumer-Hits insgesamt | nie als Hit | global 42764, nicht einem Pfad zugerechnet | per-Consumer-Kosten stehen vollständig oben; die konkrete Producer-/Reuse-Zuordnung bleibt begrenzt |

Richtungs-, Tick-, Positions- und Revisionsvalidierung bleibt im Snapshot sichtbar. Dynamische Producer-/Reuse-Reichweitenvertraege und reused-result range rejects werden von P02 nicht separat exponiert; daraus wird keine numerische Behauptung abgeleitet. Terrain-Ersparnis ist nur als Differenz reiner LoS-Auswertungen ableitbar und keinem Consumer zugeschrieben. Eine ungeordnete Paar-Wiederverwendung ist nicht belegt.

Terrain-saved evidence: `92706 - 49942 = 42764` vermiedene Terrain-Auswertungen; davon 3898 exakte Cross-Consumer-Hits. Dies ist bestehende Cache-Topologie-Evidenz, keine Varianten- oder Performancebehauptung.

## Eligibility (gefrorene Formeln)

- A `SHARED_TICK_RESULT_CONTRACT`: **eligible** — `exact_cross_consumer_hit_count` wird ausschließlich bei einem echten exakten gerichteten Cache-Hit erhöht, wenn der anfragende Consumer vom gespeicherten Producer verschieden ist. Jeder der 3898 Hits belegt daher ein exaktes Resultat mit Producer plus distinct Reuse-Consumer (mindestens zwei exakte Verbraucher); Reverse-Gelegenheiten zählen nicht.
- B `CACHE_INTERNAL_STRUCTURED_REUSE`: **excluded** — `contact_unique_ordered_pair_count / exact_cross_consumer_hit_count = 95215 / 3898 = 24.43 > 4.0`.
- C `CONTACT_DERIVED_READ_MODEL`: **excluded** — `exact_contact_producer_fire_probe_count / fire_pair_search_request_count = 421 / 3735 = 0.1127 < 0.80`.

Dies ist eine Topologie-/Eligibility-Akte, keine Performancebehauptung und keine Architekturfreigabe. Der Taskstatus bleibt `TOPOLOGY_VERIFIED_MEASUREMENT_PENDING`.

## P06 — Variante A `SHARED_TICK_RESULT_CONTRACT`

### Kandidat und Direktvertraege

- P05-Basis: `d58578bdf05f4dd9cd33b154133625b9bec6dcee`
- A-Kandidat: `5fc27f813563ed3f195803ef14ca5d1154f3b081`
- A-Evidenzmodus: `5b05404c372c54256fe3ce087cd0e3a24fa95937`
- TDD-RED: `TASK1206_VARIANT_A_MISSING`
- Direkter Vertrag: `TASK1206_RESULT: 153 passed, 0 failed`
- Regressionen: TASK-1197 `35/35`, TASK-1196 `12/12`, TASK-1191 `12/12`
- Bekannte Ausgabegrenze: nur die bereits vorhandenen Minimum-Spacing-Warnungen; keine neue Resource-, Script- oder Orakeldifferenz.

Der Prototyp war ausschließlich bei `shared_tick_result_contract` plus explizitem Enable aktiv. Er hielt je gerichtetem Source-/Target-Paar ein read-only, ticklokales Resultat mit exakter ID-, Positions-, Registry-, Revisions- und Tickvalidität. Range blieb vor dem Resultzugriff. Reverse, Positionswechsel, Registry-Identitätswechsel, Revisionswechsel und Tickwechsel mussten neu materialisieren. Das Resultat wurde weder in Events noch in Diagnose-, Savegame- oder Multiplayer-Snapshots ausgegeben.

### Verhaltens- und Strukturbeleg

Der einmalige Drei-Fixture-Lauf auf SHA `5b05404c372c54256fe3ce087cd0e3a24fa95937` lieferte genau eine `sternenbuergerchen.task1206.variant_a_cost.v1`-Zeile und Exit 0. Kontroll-, Topologie- und A-Orakel waren identisch:

`7e5e7361ee194cac55e3f1795c3582cce12d9c7af9d613cce694beb6e23ce490`

Zaehlwerte: Baseline Signature-Key `92.706`, Baseline Terrain-LoS `49.942`, daraus bestehende Reuses `42.764`; A materialisierte `49.942` read-only Results und reused `42.764`. Der A-Snapshot war `variant=shared_tick_result_contract`, `enabled=true`, `topology_enabled=false` und enthielt kein Result-Dictionary. Modus T und Variante A waren nie gleichzeitig aktiv.

### Ungueltiger Kostenlauf und Stop-Gate

Der Lauf fand waehrend zehn bereits vorhandener Godot-Prozesse statt. Acht davon waren pathlose Langlaeufer mit Laufzeiten von etwa 22 bis 77 Minuten; zusaetzlich lief ein fremder Test unter `C:\dev\InselKrieg\.worktrees\p07-r2-r3`. Kein fremder oder pathloser Prozess wurde beendet oder veraendert.

Damit sind saemtliche Zeitfelder dieses Laufs verworfen. Insbesondere werden `result_materialization_usec=72.807`, `saved_signature_key_usec=4.151.157`, der geschaetzte Terrainwert und das maschinell ausgegebene `cost_gate_pass=true` **nicht** als Kostengate gewertet. Counts und Orakel bleiben als deterministische Struktur-/Verhaltensbelege erhalten.

| P06-Gate | Ergebnis |
|---|---|
| Eligibility A | eligible |
| Direktvertrag | pass |
| 600-Tick-Verhaltensorakel | pass |
| Snapshot-/Autoritaetsgrenze | pass |
| Gueltige Modus-T-Kostenmessung | blocked — fremde/pathlose Godot-Prozesse |
| Gewertete 8-Paar-Serie | not-run |
| A-Endstatus | `BLOCKED_INVALID_MEASUREMENT_ENVIRONMENT` |

### HUMAN_SELECTED_UNMEASURED — ausdrueckliche Architekturentscheidung

Der P06-Messstatus bleibt `BLOCKED_INVALID_MEASUREMENT_ENVIRONMENT`. A wird nicht als gemessener `pass`, `fail` oder `excluded` klassifiziert; alle Zeitfelder bleiben verworfen und die feste Acht-Paar-Serie bleibt `not-run`.

Am 2026-09-01 hat der Nutzer trotz des nicht verfuegbaren Performance-Gates ausdruecklich `SHARED_TICK_RESULT_CONTRACT` als Architektur-Richtung gewaehlt. Dies ist eine menschliche Architekturentscheidung und kein Performancebeleg.

Direktvertrag, Verhaltensorakel, Snapshot-/Autoritaetsgrenze, exakte Counter sowie Kandidaten-/Evidenz-SHAs und normale Reverts bleiben unveraendert. Die Entscheidung erlaubt die serielle Analyse durch die formalen B-/C-Ausschluesse und P09 fortzusetzen, beweist aber keine Performanceverbesserung und erteilt keine Release-Freigabe.

Der Analyseprototyp bleibt revertiert. Eine spaetere Produktionsimplementierung muss als eigener Task von einer frischen `integration/core-foundation`-Basis mit eigener Vertragspruefung und gueltiger gepaarter Performance-Evidenz starten. Keine Integration, kein Merge, kein Release und kein Deployment sind hiermit autorisiert.

## P07 — Formale Ausschlussentscheidung Variante B

P06 ist net-null: Der Variante-A-Prototyp, seine Evidenz und die Produktions-/Testinstrumentierung wurden normal revertiert. Die geprüften Net-null-Dateien haben am P07-Start exakt folgende SHA-256-Hashes:

| Datei | SHA-256 |
|---|---|
| `scripts/mission/combat_visibility_cache.gd` | `C70366BAE26CAF2E6037A47B080623BBE1B660F5193D801777BDD4B9B130BC9B` |
| `scripts/tests/task_1206_combat_contact_visibility_architecture_analysis.gd` | `2FFE682F7F13216AFFB7A14B394005432F0F1A4ADD33F39C5A9ECF420932BE41` |
| `scripts/tests/run_task_1187_tactical_map_frame_budget.ps1` | `4B6793EE992977B678CCF920595C076BD66244389940FFFEA56B4CA2BB78D741` |
| `scripts/tests/tactical_map_frame_budget_harness.gd` | `E473B40945F90650DF4B750284AB5AF0F1A0D7555D5B7048F83D53A45E714C93` |

Der formale B-Status lautet `EXCLUDED_TOPOLOGY_RATIO`. Die eingefrorene P03-Eligibility-Regel ergibt exakt: `contact_unique_ordered_pair_count / exact_cross_consumer_hit_count = 95215 / 3898 = 24.43 > 4.0`.

Damit ist `CACHE_INTERNAL_STRUCTURED_REUSE` vor jeder Implementierung ausgeschlossen. B-Kandidat, RED/GREEN-Vertrag, vollständige Acht-Paar-Serie und sämtliche Performance-Gates sind `not-run`, weil die frühe Ausschlussentscheidung der plan-prescribed path ist. Es werden keine historischen Variante-B-Werte als same-build gepaarte Evidenz präsentiert.

Für dieses P07-Paket existieren weder Kandidaten-Commit noch Revert, weil kein Kandidat erstellt wurde. Runtime- und Testdateien bleiben unangetastet. Die frühere menschliche Auswahl von `SHARED_TICK_RESULT_CONTRACT` bleibt eine menschliche, ungemessene Richtung; B's Ausschluss wird nicht in einen Performance-Pass umgedeutet.

## P08 — Formale Ausschlussentscheidung Variante C

P07 ist net-null. Die für diesen Übergang geprüften Net-null-Dateien behalten die bestätigten Hashes: `mission_combat_loop_driver.gd` `74D814BC112ADE6A5C1CF3628763F36048C1848F3DD9ECC457E026FE4701A6ED`, `combat_fire_decision_resolver.gd` `65C85B9AA01CAB9E492F0C84EF2B6DF430142E5AA8AF9CC595831267302151BE` und `task_1206_combat_contact_visibility_architecture_analysis.gd` `2FFE682F7F13216AFFB7A14B394005432F0F1A4ADD33F39C5A9ECF420932BE41`.

Der formale C-Status lautet `EXCLUDED_HIT_RATIO`. Die eingefrorenen P03-Counter ergeben exakt: `exact_contact_producer_fire_probe_count / fire_pair_search_request_count = 421 / 3735 = 0.1127 < 0.80`. Nach der genehmigten 80-Prozent-Regel ist `CONTACT_DERIVED_READ_MODEL` daher vor jeder Implementierung ausgeschlossen.

C-Kandidat, Implementierung, Direktvertrag/-evidenz, RED/GREEN-Vertrag, Read-Model-/Miss-Reason-Evidence, Reverse-/Range-Validierung, die vollständige Acht-Paar-Serie sowie sämtliche Performance-Gates sind `not-run`, weil die frühe Ausschlussentscheidung der plan-prescribed path ist. Es wurde keine Reverse-Reuse- oder Symmetrie-Inferenz vorgenommen.

Für dieses P08-Paket existieren weder Kandidaten-Commit noch Revert, weil kein Kandidat erstellt wurde. Runtime-, Test-, Driver- und Resolver-Dateien bleiben unangetastet; der Laufzeit-/Teststatus bleibt net-null. Die frühere menschliche Auswahl von `SHARED_TICK_RESULT_CONTRACT` bleibt eine menschliche, ungemessene Richtung und wird durch den C-Ausschluss nicht in einen Performance-Pass umgedeutet.
