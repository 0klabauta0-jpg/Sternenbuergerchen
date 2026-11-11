# Hexsicht: erster Consumeranschluss — 11.11.2026

Basis814faabac, isolierter Taskbranch. Keine Karte aktiviert. Dies ist der
abgegrenzte AP3-Reader-Zwischenschritt; Sicherung, Overwatch, Flankierung und
Facingabsichten sowie Bewegung/Reservierung/Lifecycle bleiben Folgearbeit.

Finale kleine Privatprojektchecks: consumers30/0, detection25/0 und owner39/0.
Godot4.6.2, Exit0, keine Script-/Leakfehler, private Nutzerverzeichnisse und
unveränderte Originalprofile/Quellbytes. Kein großes Gefecht, keine Kartenmatrix,
keine native Visual-/Performancefreigabe oder FPSbehauptung.

Der Consumercheck lädt tatsächliche Driver-/Root-/Cache-/Resolver-/FoW-Quellen
mit ihrem Scriptabschluss und der echten unveränderten Windows-LimboAI-
GDExtension aus HEAD. Er startet ausschließlich vier kleine Testactors und
vier Terrainfelder. Der Driver-Fixture überspringt den szenenabhängigen Ready-
Aufbau und liefert feste Unitlookups; die geprüften Sicht-/Erkennungsmethoden
bleiben die tatsächlichen Produktionsmethoden. Keine Fake-Limbo-Klassen,
keine vollständige Missionsszene, kein Kampagnenprofil. MissionTestSetup-
Wiring ist statisch geprüft; sein nativer Readiness-/Übergabefluss bleibt später.

Belegt: Contact/Schuss/FoW teilen die Hexgeometrie, falsche Renderpositionen
ändern keine logische Sicht, fehlende Admission bleibt unsichtbar, rückwärtige
Ziele fehlen, renderbewegte Beobachter lösen keinen neuen FoW-Job aus,
Facing/Profile invalidieren, Teiljobs publizieren atomar und deren Deltas
blenden frühere Sicht korrekt aus. Gleich revisionierte Ersatzregistries mit
anderen Blockern sind neue Kontexte. Eine Episode hat eine feste Deadline,
Wiederholung zählt nicht doppelt, Kontextwechsel/Sichtverlust löschen sie.
Legacy-Countdown und RefCounted-LOSfallback bleiben erreichbar.

Sauberer ConsumerRED e935dd9c...0/1 wegen fehlendem Adapter, danach17/0.
Erster Setupversuch c1eafce6... ohne native LimboAI-Abhängigkeit nicht alsRED
gewertet. Ein zusätzlicher Legacytest fand Node/RefCounted-Verwechslung und
endete nach Scriptfehler im Timeout; korrigiert, danach20/0. Facingtest hatte
zunächst zu kleines Slice-Budget; mit genügend begrenzten Slices korrekt.
Unabhängiger Review fand Profil-/Kontextinvalidierung: reale Ersatzregistry-
Regression474fe540...24/2, danach29/0. Kontextreset brauchte außerdem Hide-
Deltas: b9fdcd49...29/1, danach6415f01d...30/0. EpisodenreadRED362313...1/1,
danach25/0. Originale Logs/Reports einschließlich Fehlversuchen bleiben erhalten.

consumer_runs.zip und manifest.json binden finale Quellen. Die tatsächlich
ausgeführten Quellen sind getrennt von den nur statisch geprüften Setup-/
Vertragsdateien ausgewiesen. Große Tests ausdrücklich später.
