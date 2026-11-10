# Kompakte Truppkarte und Aufsitzen — 10.11.2026
## Ziel / Ursache
Nutzer findet Einsteigen am Schiff unintuitiv und wünscht die Aktion am Trupp.
Zwei linke FT1-Karten sollen zu einer gemeinsamen Karte werden; quadratische
Porträts etwa ein Drittel kleiner, kleinere Buttons, Platz für weitere Teams.
## Umfang / Entwurf
Bestehende ausgewählte Truppkarte erhält Identität, quadratische Porträts,
Status, Haltung, Feuerregel, Details und Aufsitzen. Die gleiche ausgewählte
Identität wird nicht noch einmal als Minikarte angezeigt; andere Teams bleiben
in der scrollbaren Liste auswählbar. Bestehende NodePaths/Controls bleiben,
neue Portraits sind nur gecachte Projektion der vorhandenen Minikarten.
Aufsitzen am ausgewählten Kampagnentrupp benutzt vorhandenen autoritativen
Sammel-/Boardingpfad zum eigenen tatsächlich gelandeten Truppschiff. Kein
Schiff auswählen nötig. Keine automatische Rückreise; Abheben bleibt am Schiff.
Kein Phantomschiff in Skirmish, wenn kein geparktes Schiff existiert; konkrete
Sperrgründe. Keine neue Transport-/Crew-Wahrheit und keine Multiplayererweiterung.
## Quellen / Dateien
PROJECT_BRIEF, ARCHITECTURE, CODEX_RULES, IMPLEMENTATION_STATUS/TASK_ROADMAP;
homebase_direct_dropship_flow_contract, mission_interaction_point_contract.
Betroffen: drop_light_layout_contract, mission_a5_hud_layout,
mission_tactical_sandbox_controller, ggf. dropship_presenter und gezielter Verifier.
## Akzeptanz / Prüfung
Eine sichtbare Identität für ausgewählten FT, weitere Teams bleiben auswählbar.
Portraitkanten max. zwei Drittel des alten Werts, quadratisch; kompakte Buttons
ohne Überlauf bei1280/1920/3440 logischen Größen. Details/Doppelklick und
Haltung/Feuerregel bleiben bedienbar. Aufsitzen prüft Auswahl, echte Groundcrew,
gelandenes eigenes Schiff und zeigt laufenden/fertigen Boardingstatus; keine
implizite Abreise. Echte Bewegungs-/Boardingregression und native Bildprüfung.
Unveränderte Snapshots dürfen keine Controlbäume neu aufbauen.
## Ergänzung aus Playtest
Basisverwaltung als Hover-Untermenü direkt unter Basis erkunden statt über der
Karte. Beim Verlassen zuklappen; Klick/Tastatur bleiben bedienbar. Bestehende
Servicecommands unverändert. Berichteter fehlender Upload nach Schlafen wird
mit echtem Missionschip und Heimkehr geprüft; keine erfundenen Chips/Reparatur
von Nutzersaves. Betroffen zusätzlich homebase_operations_presenter und Verifier.
## Grenzen / Risiken
Mainbasis1e3cca237, eigener Taskbranch. Keine neue EXE/Mainintegration in diesem
Implementierungsschritt. Gestalterisches Nutzerurteil bleibt getrennt.
