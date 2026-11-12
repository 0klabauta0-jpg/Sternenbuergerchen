# AP7-Teil: atomarer Groundzustand

## Ziel / Ursache
Der vorhandene Groundowner besitzt noch keinen eigenen JSON-Roundtrip. AP7
braucht getrennte kanonische Speicherdaten statt interner Planungssnapshots.

## Umfang und Grenzen
Nur `scripts/core/hex_ground_runtime.gd` mit export_state/restore_state und
privaten Validatoren, eigener `scripts/tests/hex_ground_save_state_verifier.gd`
und QA. Keine Root-/Base-/Adapter-/Netz-/Sharedrunneraenderung. Kein full_ap7.
Home-only/Awaygates werden nicht geaendert; keine tatsächliche Actorbindung.

## Akzeptiertes Schema / Strategie
JSONsafe `schema=hex_ground_v1`, `map_id`, `topology`, `tick`, `terrain_revision`,
`units` (ID, grid pair, Facing, Posture), `active_segments` (angenommene konkrete
Segmentzeiten/Endpoints/Command-ID), `centering` (ID, axialer Ausgangsoffset,
logische Ausgangshoehe, Starttick/Dauer). Kein State-/Admission-/Ownerreceipt,
keine Caches, Queues oder privaten Reservierungsdictionaries.
Nur am bereits konfigurierten passenden LiveRegistry-/Mapkontext restaurieren.
Alle Daten in privatem Groundkandidaten mit vorhandenen Schedule-/Timeline-/
Konflikt-/Terrain-/Geometrievalidatoren pruefen; erst danach im selben Groundobjekt
synchron publizieren. Referenzen des bestehenden Movementowners bleiben erhalten.

## Fachlicher Teilumfang
Pending Admissions und aktive Corridorgrants werden beim Export explizit
abgelehnt. Restore unterstuetzt nur Segmente, deren gepruefte Live-Corridorpolicy
keinen Passagegrant benoetigt; kalte/unvollstaendige Topologie wartet geschlossen.
Keine Zusage wird still verkleinert. AP8-Passage-Roundtrip und laufende Backoff-/
Aktionsfortsetzung sind NICHT erfuellt. Zentrierung wird explizit roundtripbar.

## Dokumente / Dateien / Pruefung
AP7 in `docs/superpowers/plans/2026-11-11-hex-sight-occupancy.md`,
`docs/dev/hex_tactical_runtime_contract.md`, PROJECT_BRIEF/ARCHITECTURE/CODEX_RULES.
Kleine isolierte RED/GREEN-Probe unter
`output/native_glut_maps/hex_ground_save_state_20261112/`, keine grosse Matrix.
Prueft JSONroundtrip vor/nach Handoff, Facing/Ankunft/Zentrierung, detached Werte,
duplizierte Zellen/ungueltige Version/Map/Zeiten/Konflikte mit vollem Rollback,
und ausdrueckliche Ablehnung nicht unterstuetzter Zusagen. Kein Commit.

## Reviewkorrektur: dynamisches Terrain
Export und Restore lehnen vor dem privaten Kandidaten mit
`ground_save_terrain_revalidation_pending` ab, solange die Ground-
Reservierungsterrainrevision von der aktuellen Registryrevision abweicht.
Der vorhandene `advance_tick` revalidiert akzeptierte Routen und baut deren
Motiongeometrie neu; der Speicherpfad fuehrt selbst keine Revalidierung aus.
Ein echter dynamischer Plateauwechsel prueft Export-/Restoreablehnung ohne
Mutation sowie identische Standhoehe nach normaler Tickrevalidierung.
Gezieltes RED17/2 und GREEN19/0 liegen im eigenen QA-Verzeichnis; Produktfreeze.
