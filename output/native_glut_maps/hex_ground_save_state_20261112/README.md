> Historische v1-Teilpruefung unten. Aktueller Produktfreeze: hex_ground_v2 mit
> Passagezusagen und explizitem v1-Legacyoffenpfad;33/0. Siehe
> ../hex_ground_passage_save_20261112/README.md und manifest.json dort.

# AP7-TEIL: Ground-Speicherwerte

Historischer erster Teil aus524fd61d1. Der gemeinsame Verifier/Runner wurde fuer
`../hex_ground_passage_save_20261112/` erweitert; aktuelle Passageversion und
35/0-Evidenz dort. Die folgenden19/0 beschreiben den damaligen Teilumfang.

Produktfreeze: `scripts/core/hex_ground_runtime.gd` ausschliesslich neue
export_state/restore_state plus private Validatoren; eigener Verifier
`scripts/tests/hex_ground_save_state_verifier.gd`. Kein Root-/Adapter-/Base-/Netz-
oder Sharedrunneranschluss. Groundreferenz wird beim Restore nicht ersetzt.

JSONschema: `schema=hex_ground_v1`, map_id, topology, tick, terrain_revision,
units, active_segments, centering. Genau bekannte Keys; IDs bis256Zeichen,
max64Units/256Segments/64Zentrierungen, Segmentdauer bis1000000Ticks, aktuelle
Uhr bis bestehendem MAX_TICK. IntegerJSONfloats werden nach strikter Pruefung
kanonisiert; Koordinaten liegen vor Vector2i-Konversion im sicheren32bitBereich.
LiveMap/Topologie/Terrainrevision muessen passen. Private Candidateaufnahme,
ganze Schedules/Timelinekonflikte und Motiongeometry werden vor Livewrite validiert.
Danach reiner synchroner Feldpublish, keine Registrycallbacks nach erstem Write.

Unterstuetzt: offene Flaechen, Facing, akzeptierte aktive/zukuenftige Segmente
einschliesslich Posthandoff-Fortschritt und intrinsische Zentrierphase. Geometrie
und Zell-/Kantenintervalle werden aus kanonischen Segmenten neu abgeleitet;
keine Privatcaches/Queues/Admission-/Ursprungsbelege werden serialisiert.

Explizit gesperrt: pending Admissions (`ground_save_pending_admission`), aktive
Corridorgrants (`ground_save_corridor_commitments_unsupported`) und ungeklaerte
Topologie. Ebenfalls gesperrt ist noch nicht durch Ground verarbeitete
Terrainrevision (`ground_save_terrain_revalidation_pending`), sowohl beim Export
als auch vor Restore-Candidateaufbau. Keine Speicheroperation revalidiert oder
veraendert den Liveowner. Restore von Passagesegmenten ohne darstellbare Zusage scheitert ueber
bestehende Corridorpolicy; kalter unvollstaendiger Topologiecache wartet geschlossen.
Der Rootkoordinator muss diese Vorbedingung spaeter pruefen/vorbereiten. AP8-Passage-
Roundtrip, Movement-Originalziele/Backoff/Wartealter/Aktionen sowie echte Actorbindung
und vollstaendiger Checkpoint sind NICHT implementiert. Keine Home-only/Awaygate-
Aenderung, keine neue Peerpayload-, Savefile- oder Autorisierungsgrenze.

Pruefung: eigener privater Projekt-/Userrunner, echte Ground/Registry/Planner,
Godot4.6.2. Keine Hauptszene, GPU oder grosse Matrix. Finale19/0 mit sauberem
Log/Exit0/Quellen- und Originalprofilidentitaet/privaterCanary:
`ground_save-0cf5b7e6c33541d8b87a368687fa193e/report.json` und `output.log`.
Ganze bereits verwendete Groundinstanz bleibt dieselbe; exportierte und
restaurierte Daten sind detached. Invalid schema/map/grid/timing/futureconflict
verwirft den gesamten Kandidaten ohne Livezustandsaenderung.

RED: `ground_save-ed685aeec1564250852bbac211dee410/` (fehlende APIs0/1).
Zwischenlauf `ground_save-5e6629b0b6af4b9b8ca793a56a5a6799/` erreichte13Checks,
danach falsche direkte Zuweisung eines untypisierten Arrays an typisierten
privaten Fixturegrant; Setupfehler/Timeout, kein Produktbefund. Durch echten
Planner-/Corridorowneraufbau ersetzt. Sauberer14/0-Zwischenlauf:
`ground_save-b4bbd5639fd14b69b4f2530b251974c5/`. Zwei gezielte Negativchecks
zu Zukunftskollision und abgewiesenem Corridorrestore fuehrten zum Abschluss16/0.

Review-RED17/2: `ground_save-b5b0aa92e47246e0ac51beb336d87fc0/`.
Nach Anheben beider legalen Plateauendpunkte konnte vorm Groundtick alte
Motiongeometrie mit neuer Terrainrevision exportiert werden. Der enge Guard
lehnt jetzt Export und Restore vor Kandidatenaufbau ab. Die dritte neue Probe
belegt: bestehendes `advance_tick` revalidiert die Route; danach stimmen
Standhoehe und JSON-Roundtrip wieder ueberein (GREEN19/0, obiger finaler Lauf).

```powershell
python output/native_glut_maps/hex_ground_save_state_20261112/run.py
```

Keine Gitaufnahme/Commits. Urspruengliche Reports/Logs bleiben erhalten.
