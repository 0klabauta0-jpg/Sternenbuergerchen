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
