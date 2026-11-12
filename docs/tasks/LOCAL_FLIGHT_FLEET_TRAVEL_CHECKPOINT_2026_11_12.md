# Stable local Flight / Fleet / Travel checkpoint

## Ziel / Ursache
Stable actual local orbit flights and inactive surface flights need detached
checkpoint restoration. Fleet currently rejects every local Flight explicitly;
Travel also needs phase/frame/body consistency and fresh restore epochs.

## Umfang / Nicht-Ziele
Only scripts/core/{space_flight_state,singleplayer_fleet_travel_state,
singleplayer_space_travel_state}.gd and dedicated tests. No Root, Adapter, Flow,
Combat/Nav or receipt-helper edits. Preserve strategic grounded/orbit/quantum/
stopped/surface checkpoint APIs and their request receipts. No station-birth,
atmosphere/air or unfinished approach checkpoint rollout, no commit.

## Contracts / Akzeptanz
Keep space_flight_checkpoint.v1, space_travel_checkpoint.v1 and
space_fleet_checkpoint.v1 plus existing prepared handles. Typed JSON roundtrip
preserves actual pose, velocity, heading, frame, area, assist, mass, tick,
revision and travel request results. Local orbit must be tactical and local
surface inactive; area must match the catalog body of the canonical orbit and
surface location. Local position uses the current orbit-grid bounds. Travel
restore renews its area epoch/seal; Fleet rebuilds receipt owner IDs/epochs for
fresh detached owner instances. No authority refs/IDs/seals enter the wire.

## Dateien / lokale Pruefung
The three owner files above; scripts/tests/local_flight_fleet_checkpoint_verifier.gd,
scripts/tests/local_surface_fleet_checkpoint_verifier.gd
and existing space_flight_checkpoint_verifier, space_travel_checkpoint_verifier,
space_fleet_checkpoint_verifier and root_local_orbit_receipts_verifier.
Use actual Root/Fleet/Flight producer APIs for positive local states; corrupt
frame, area/body, phase/mode, position, revisions and wire values for negatives.
No engine execution until Root releases the exclusive Space1x engine slot.
The separate surface fixture issues a real Root move and advances normal Root
ticks until the real footprint reaches a real surface gate (bounded 12000
ticks). Only then may real Root departure/finish_approach produce surface/inactive.
It additionally checks actual local-return capture and preserved inactive
velocity/angular velocity; the current producer does not zero either value.

## Risiken / offene Punkte
Full running-flight Save/Load additionally needs companion Combat/Nav/intents,
Root receipt and global transaction validation. This owner-only change is no
whole-Continue, physical boarding, native, FPS or release acceptance.

## Gezielte ausgeführte Prüfung
Drei bestehende strategische Checkpointverifier PASS; neuer lokaler Flight-
/Fleet-/Receiptpfad123/0 und Surfacepfad33/0, jeweils exit0. Surface umfasst
1610 echte Root-Simulationsschritte bis zum Gate, tatsächliche Deaktivierung,
finish_approach, frische inaktive Owner und fuel-backed Localreturn. Keine
Pose-/Zähler-/Tempo-/Receiptpatches für einen Pass. Fehlende Folgeticks im
ursprünglichen Fixture wurden durch reguläre Root-Ticks ersetzt. Keine
1×-/Renderer-/Gesamt-Continueabnahme daraus. Vollständige Diagnostik und
Grenzen: docs/qa/orbit_checkpoint_20261112/README.md.
