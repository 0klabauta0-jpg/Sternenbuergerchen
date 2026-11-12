# Stable local-orbit Root receipt checkpoint extension

## Ziel / Ursache
Actual local movement, completed warp arrival/departure and surface-return receipts
currently make the Root checkpoint fail closed. Preserve their exact replay
semantics across fresh Fleet/Flight/Supply owners, without deleting guards alone.

## Umfang / Nicht-Ziele
Only root_receipt_checkpoint.gd and focused owner fixtures. Producer reference:
2f37621a6:scripts/core/simulation_root.gd. No Root/Adapter/Flow edits, no new
movement authority, no commit, no engine execution while the exclusive Space1x
run is active. Orbit-intent/Nav/Fleet restore belongs to the companion owner.
Station-birth/depart_station_purchase and station enter_orbit launch receipts
remain unsupported and reject explicitly. Normal Polisa gameplay is untouched.

## Contracts / Schnittstellen
Existing Fleet prepared area transitions, Supply confirmed request receipts,
checkpoint_value_codec typed wire values; ROOT_RECEIPT_CHECKPOINT_2026_11_12.
Keep capture/prepare/prepare_prebinding/validate/validate_prebinding/publish APIs.
Add six optional v1 maps (move, warp_entry, warp_departure, local_return,
warp_latest, return_latest); legacy launch/departure-only v1 remains readable.
Actual start_quantum producer is warp_departure, not launch. land_homebase
launch receipts intentionally have no Equipment runtime reference.

## Akzeptanz / Dateien / lokale Pruefung
scripts/mission/root_receipt_checkpoint.gd reconstructs exact runtime shapes,
fresh signed Fleet replay candidates and current Supply epochs. Latest indexes
must point to the correct craft's newest recorded transition. Move receipts are
exact canonical primitive command signatures, with no command execution during
restore. Events must already be finalized. Pending searches, completion intents,
air/combat/fixture receipt families still reject. Root prebinding freshness
includes all six added maps. The publication tail only replaces maps.
scripts/tests/root_local_orbit_receipts_verifier.gd uses real Root/Fleet/Flight
transition producers, typed JSON roundtrip, detached actual owner restore,
request conflict/stale/unfinished negatives and unchanged owner/event checks.
Run with Godot 4.6.2 headless only after the exclusive run releases the engine.

## Risiken / offene Punkte
Local Flight/Fleet/Nav restore is a separate companion dependency; this helper
alone does not save a running local flight. No native journey, FPS, Continue or
all-flight-variant acceptance is claimed. Local return additionally requires
confirmed underlying Supply fuel requests even when the producer emitted no
new fuel event on replay. Capture/prepare never applies commands or burns fuel.

## Ausführung und abgeleiteter Bodycache
Abschließende Ownerprüfungen: drei bestehende strategische Checkpointverifier
PASS, lokaler Flight/Fleet/Receiptpfad123/0, tatsächlicher Surface-/Returnpfad
33/0, Prebinding29/0, Intent39/0; jeweils exit0 und stderrleer. Vollständige
rote und grüne Logs samt Befehlen/Profilen: docs/qa/orbit_checkpoint_20261112.
Das allein schaltet keinen vollständigen Missions-Save oder Orbitrollout frei.

Die reale Rootbewegung füllt _fixture_area_blockers trotz historischem Namen
mit kanonischen Bodyzellen. Statt pauschaler Sperre wird ausschließlich exakt
ORBIT.build(body).body_cells über GRID.from_offset akzeptiert, für Freshness
gestempelt und am Ziel bei Bedarf neu abgeleitet. Unbekannte/manipulierte
Masken bleiben gesperrt, kein Wire-/Publish-Gameplaystate für einen Cache.
