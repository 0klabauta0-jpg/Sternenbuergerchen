# Sternkartenanzeige der Kartenvorbereitung

Root projiziert den Flow-Snapshot `map_preparation` in den bestehenden
Sternkartenbaum: Datenladen, Ressourcenfortschritt in Prozent, Ready, Fehler
und Abbruch. Nur der Flow entscheidet über Readiness und Reisephase.
Anflugabbruch sendet `space_cancel_approach`; Quantum nutzt unverändert
`space_abort_quantum`. Keine Mesh-/Chunk-/Bytezahlen im Spielertext.

Gezielter neuer Headless-Verifier: RED16Checks/8Fehler, GREEN16/0.
Bestehender Sternkarten-UI-Verifier:89/0. Private APPDATA, Godot4.6.2,
Dummy-Renderer. Native tatsächliche Vorbereitung/Abbruch und Missionübergabe
stehen zusammen mit dem Ressourcen-Task noch aus; dies ist keine visuelle
oder Performance-Freigabe. Keine Nutzerstände geändert, kein Main/EXE.

Native actual preparation and MissionSetup handoff now covered by the combined
62/0B run, including actual progress screenshot. User-triggered cancellation
is covered by the headless owner/UI gates, not a separately claimed native
cancel click. Stale-result-after-quantum regression18/0 belongs to Flow.
