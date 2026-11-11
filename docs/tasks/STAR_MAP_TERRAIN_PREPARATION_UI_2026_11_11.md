# Sternkarte: tatsächlicher Ladefortschritt im Anflug

Ziel/Ursache: Vollständige Geländevorbereitung benötigt sichtbaren Fortschritt,
bevor die Mission Einheiten aktiviert. Die UI darf weder Readiness noch Reise
selbst erzeugen. Übergeordneter Task TERRAIN_RESOURCE_PREFILL_2026_11_11.md;
Architektur-/Grafikvertrag und bestehender Orbitreisevertrag gelten weiter.

Umfang: Nur scripts/ui/star_map_screen.gd, neuer gezielter UI-Verifier, QA.
Flow liefert TOP-LEVEL snapshot.map_preparation mit status, progress0..1,
ready, cancel_available, error (Spielertext) und optionalen Debugzahlen.
Status loading_data zeigt Laden; preparing_resources tatsächlichen Prozent-
fortschritt. Anflugabbruch sendet nur space_cancel_approach mit craft_id.
Quantum-Abbruch bleibt space_abort_quantum. Fehler-/Cancelzustand aus Flow
bleibt beim Rückorbit sichtbar; keine lokale Abschluss-/Ready-Mutation.
Keine Chunk-/Byte-/Meshzahlen im normalen Spielertext, keine zweite Wahrheit.

Akzeptanz: Datenladen/Vorbereitung/Ready/Fehler/Cancel korrekt projizieren,
Prozentleiste nutzt dieselbe Eingabe, Commands allein ändern keine Phase.
Ohne cancel_available kein Abbruchbutton/-Command. Bestehende Quantum-/Orbit-
Navigation und Buttons bleiben. Unveränderte UI-Bäume bei getakteten Refreshes.
Gezielter RED/GREEN-Headless-Verifier und bestehender Sternkartenverifier;
anschließend native tatsächliche Anflug-/Ladeprobe im privaten Profil.
Risiko: alter Fehlersnapshot darf eine spätere Quantumphase nicht überdecken.
Besitz: Root nur Anzeige; Resourceagent Flow/Preloader/Readiness/Commands.
