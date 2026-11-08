# R4: unabhaengiges lesendes Review nativer Combat-/Sichtnachweise

Stand: 2026-11-08. Review vorhandener Originalbilder, JSON-Nachweise und der
zugehoerigen lesenden Sicht-/Feedbackpfade. Keine eigene Enginepruefung,
keine Produkt-, Asset-, Harness- oder Gameplayaenderung durch den Reviewer.

## Ergebnis und Grenzen

Kein bestaetigter P1/P2 im geprueften Umfang. Sichtbare menschliche Gegner,
echtes kurzes Quellenfeedback und eine horizontal liegende Originalfigur
sind fuer die unten genannten Aufnahmen belegt. Das ist keine allgemeine
Art-Direction-, Performance-, Paket-/EXE- oder Releaseabnahme.

Die liegende Silhouette und die Identitaet der Figur sind belegt.
Bodenauflage sowie vollstaendige Freiheit von Bodendurchdringung bleiben
offen. Es gibt keinen hinreichend klaren Bilddefekt fuer einen Produktfix
auf Verdacht.

## Quellen und gebundener Stand

Nachweisbasis:
`output/runtime_hitches_r4_20261107/final_side_combat/20261107T112418Z-dc934ac4/`.

- `report.json`: ein ausgewaehlter Lauf bestanden, exit 0, errors 0,
  Isolation bestaetigt, Quellen und geschuetztes Roster vor/nach unveraendert.
- `side.json`: 63 bestandene Checks, 0 fehlgeschlagen. Regulaerer
  MainMenu-/Homebase-/Missions-/Transport-/Unload-/Move-/GO-Pfad;
  `forced_arrival=false`, `forced_unloading=false`,
  `private_simulation_state_writes=false`, `synthetic_fixture=false`,
  `time_acceleration=false`.
- `side_actual_fire.json`: `actor_writes=false`, `authority_writes=false`,
  `creates_fire_event=false`; Combat-only, `performance_measurement=false`.
  Der separate Zehnsekunden-Sichtnachlauf dauerte 10126 ms, war lesend und
  sendete keine weiteren Commands.
- Renderer Forward+, Vulkan, echte Vollbildbilder 3440 x 1440, time_scale 1.
  Die Kamera fuer die Fire-Serie hat Groesse 22; die Down-Nahaufnahmen
  verwenden Groesse 8. Der Side-Lauf ersetzt keinen 90s-Performancevergleich.

Die im Laufbericht dokumentierten Produktpins stimmen mit dem zugewiesenen
R4-Stand ueberein; keine erneute Hashmessung durch dieses Review:

- Terrain: `fb9905172a9115c6458a90c3fdb896895c0576978bd999a6567c7711458b60f2`
- Feedbacklayer: `3087b4abdcc92c93a3449187bab623899b2d520e78f161194d77a329be75db84`
- Mapping: `a7d133cdc510b71eedf4d3e7fdd08d68dc49252d0377ff9e56315bfcb6c70159`

Gelesene Vertraege/Tasks: AGENTS, PROJECT_BRIEF, ARCHITECTURE, CODEX_RULES,
IMPLEMENTATION_STATUS, `graphics_reference_revision_contract.md`,
`fog_of_war_modes_contract.md` sowie R4-Combat-Visuals, Attachment-Idle-Gate
und Idle-Axis-Evidence. Das Review aendert deren Produktregeln nicht.

## Originalbilder und Fire-Timing

Alle drei Original-PNGs in `side_captures/` wurden in 3440 x 1440 geoeffnet.
Gelbes Waffenfeedback und das schwarze/gelbe Quellensymbol sind erkennbar.
Die menschlichen Figuren besitzen lesbare Helme, Torso und Gliedmassen;
kein deckender Pillencore ersetzt den erfolgreich geladenen Gegner.

Der ausgewaehlte autoritative Schuss lautet vollstaendig:
`fire_00003162_0002_player_sternenbuergerchen_01_ground_defense_01`.
Er liegt nach dem regulaeren GO-Tick 1472. Der erste beobachtete echte
Gegnerschuss ist
`fire_00003150_0001_ground_defense_01_player_sternenbuergerchen_01`.
Die ausgewaehlte Pixelserie belegt insbesondere den Player-Schuss;
der gegnerische Schuss ist hier als autoritatives Event belegt.

| Bild / Sollverzoegerung | Tatsaechliche Verzoegerung laut JSON | Aktiver Feedbackschuss | Pulsealter | Flash / Icon | Gleicher ausgewaehlter Flash |
| --- | ---: | --- | ---: | --- | --- |
| `r4_actual_fire_000ms.png` / 0 ms | 9.410 ms | `fire_00003162_0002_player_sternenbuergerchen_01_ground_defense_01` | 66 ms | true / true | true |
| `r4_actual_fire_120ms.png` / 120 ms | 217.691 ms | `fire_00003174_0003_player_sternenbuergerchen_01_ground_defense_01` | 41 ms | true / true | false |
| `r4_actual_fire_900ms.png` / 900 ms | 922.743 ms | `fire_00003198_0005_player_sternenbuergerchen_01_ground_defense_01` | 399 ms | false / true | false |

Die aktiven Pulse stammen an allen drei Punkten von echten neuen Events,
mit `source_allowed=true` und `anchor_kind=weapon_mesh_muzzle`.
Die sichtbaren Meshfront-Dots sind .897223, .896595 und .907829.
Muendungsposition und Meshankerposition stimmen in den protokollierten
Werten jeweils ueberein. Kein geschlossener Missionskontext in dieser Serie.

Die Serie darf nicht als Nachweis ausgegeben werden, dass derselbe Flash
von 0 bis 120 ms sichtbar bleibt oder bei 900 ms weiterleuchtet. Der echte
Folgeschuss ersetzt den vorherigen Pulse derselben Quelle. Bei der letzten
Probe ist nur das Icon des neueren Schusses noch aktiv.

## Originalidentitaet und liegende Silhouette

Das Target `ground_defense_01` durchlaeuft in der Serie HP 61 -> 22 -> 0,
Vitalstate fit -> fit -> down. Model-ID `1517532763930` und Proxy-ID
`1517448877845` bleiben dieselben wie bei der ersten Originalerfassung.
Model, Proxy und Target bleiben sichtbar; Body-Core existiert nicht.

Beide Original-Nahaufnahmen wurden geoeffnet:

- `r4_actual_down_closeup.png`: Der gelbe DOWN-/Trefferbereich verdeckt
  wesentliche Teile des Torsos. Diese Projektion allein akzeptiert keine
  vollstaendige liegende Silhouette.
- `r4_actual_down_side_90.png`: Die reine Kameraaenderung um Yaw +90 zeigt
  eine deutlich horizontale menschliche Figur mit getrennt sichtbaren
  Beinen links, Torso, gruenem Helm rechts und Waffe. Kein Capsule-Ersatz.
  PNG-SHA256 laut Nachweis:
  `5c0dce9c8dba324e34534bb4ad00bf5f4f50a98d345346534c392d215b6ee0c1`.

Beide Nahaufnahmen behalten dieselbe Originalmodellidentitaet und den
natuerlich eingetretenen Downzustand. Der Harness markiert
`changes_actor_hp_pose_position_or_timers=false`, `creates_down=false`
und `camera_only=true`; die Kamera wird danach wiederhergestellt.

Die protokollierte Modelrotation (72, 270, 18) und `down_pose_active=true`
sind Zusatzdaten, kein Ersatz fuer den geoeffneten Bildnachweis. Der
Proxy steht bei Y .06 ueber Ground Y 0; das Modell besitzt eine weitere
lokale Verschiebung. Statische Mesh-AABBs enthalten Attachments und
Bindposegeometrie. Daraus folgt weder exakte skinned Bodenauflage noch
eine bestaetigte Durchdringung. Diese Grenze bleibt ausdruecklich offen.

## Vollstaendiger Sichtabgleich: 22 Zustaende

Die JSON enthaelt 8 Initialzustaende und 14 Zustandsaenderungen.
`target_visible` stimmt in 22/22 Faellen mit mindestens einem positiven
aktuellen Observer-LOS ueberein. `proxy_visible` entspricht in 22/22
Faellen `target_visible OR tile_visible`. Alle erfassten effektiven
Observerreichweiten betragen 512 World; alle Kandidatenblockerlisten sind
leer. Actor-visible ist in allen Zeilen true und ist nicht mit der
FoW-gefilterten Proxyanzeige gleichzusetzen.

| Target | Tick | Art | Target | Tile | Proxy | Mindestens ein LOS | Naechster Observer: Worlddistanz |
| --- | ---: | --- | --- | --- | --- | --- | ---: |
| ground_patrol_01 | 1479 | initial | false | false | false | false | 544.414 |
| ground_patrol_02 | 1479 | initial | false | false | false | false | 753.373 |
| ground_patrol_03 | 1479 | initial | false | false | false | false | 752.130 |
| ground_patrol_04 | 1479 | initial | false | false | false | false | 859.218 |
| ground_defense_01 | 1479 | initial | true | true | true | true | 465.759 |
| ground_defense_02 | 1479 | initial | true | true | true | true | 408.620 |
| ground_defense_03 | 1479 | initial | true | true | true | true | 502.303 |
| ground_defense_04 | 1479 | initial | false | false | false | false | 521.585 |
| ground_defense_03 | 1553 | changed | false | true | true | false | 517.763 |
| ground_defense_01 | 1587 | changed | false | false | false | false | 518.714 |
| ground_defense_03 | 1665 | changed | false | false | false | false | 557.210 |
| ground_defense_03 | 2485 | changed | false | true | true | false | 543.247 |
| ground_defense_01 | 2565 | changed | true | false | true | true | 507.124 |
| ground_defense_03 | 2565 | changed | true | true | true | true | 507.672 |
| ground_defense_01 | 2580 | changed | true | true | true | true | 498.080 |
| ground_defense_04 | 2612 | changed | true | false | true | true | 505.150 |
| ground_patrol_01 | 2644 | changed | true | false | true | true | 511.319 |
| ground_defense_04 | 2663 | changed | true | true | true | true | 487.441 |
| ground_patrol_01 | 2679 | changed | true | true | true | true | 503.047 |
| ground_patrol_02 | 3434 | changed | true | false | true | true | 507.552 |
| ground_patrol_02 | 3512 | changed | true | true | true | true | 491.578 |
| ground_patrol_03 | 3512 | changed | false | true | true | false | 530.192 |

Die drei target=false/proxy=true-Faelle sind durch die sichtbare Tile-
Admission erklaert. Die vier target=true/tile=false-Faelle bleiben ueber
Target-Admission sichtbar. Targetverluste treten hier ausserhalb der
effektiven Reichweite auf; kein Nah-Ausblendungsbug ist damit reproduziert.
Dies ist ein Zustandswechselprotokoll, keine lueckenlose Frame-fuer-Frame-
Messung saemtlicher Akteure oder aller moeglichen Deckungssituationen.

## Source-, Target- und Proxy-Admission nicht gleichsetzen

Der gelesene aktuelle Produktpfad unterscheidet diese Zustaende bewusst:

- `TerrainMap3DView._fow_is_target_currently_visible` liest die aktuelle
  Target-ID-Menge.
- `_fow_allows_unit_proxy` laesst eigene Units, aktuelle Targets oder die
  aktuell sichtbare Tileposition zu; die eigentliche Anzeige verknuepft
  diese Admission zusaetzlich mit der grundlegenden Actor-Sichtbarkeit.
- `_fow_allows_weapon_fire_source` laesst eigene Quellen, aktuelle
  Source-Targets, aktuelle Event-IDs oder die aktuelle Quellposition auf
  einer sichtbaren Tile zu. Bei vorhandenem Proxy wird dessen aktuelle
  Position verwendet, nicht unbegrenzt die alte Startzelle des Events.
- Der Feedbacklayer entfernt aktive Pulse bei Verlust dieser Admission;
  abgelehnte/verbrauchte Eventkeys werden bei spaeterem Sichtgewinn nicht
  erneut abgespielt.

`target_visible=false` allein bedeutet deshalb nicht, dass die Quelle nach
der bestehenden Visualregel vollstaendig verborgen ist. Die aktuelle
Native-Serie darf weder als target-only-Sourcefilter noch als allgemeiner
nativer Beweis fuer alle Hidden-Source-/Mehrquellenfaelle ausgegeben
werden. Die fokussierten Renderer-/Admissiongates bleiben eigene Nachweise.

## Abschluss und Freeze

Nur diese neue Review-Datei wurde geschrieben. Keine Korrektur auf
Verdacht. Root bleibt alleiniger Engine-/Git-Runner. Nach Fertigstellung
dieser Datei friert der Reviewer alle weiteren Reads, Hashes und Writes
bis zum Rootsignal `PROFILE_END` ein.
