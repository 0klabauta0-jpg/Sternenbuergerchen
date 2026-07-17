# Aktueller Spielstand

<!-- canonical-current-state: true -->

Stand: 17. Juli 2026. Dieses Dokument ist die einzige kanonische Kurzbeschreibung des gegenwärtigen Produktstands. Es beschreibt keine zweite Gameplay-Wahrheit und ersetzt keine Runtime-Contracts.

## Spielerfantasie und erreichter Kern

SternenBuergerchen ist ein Commander-gesteuertes Echtzeit-Taktikspiel. Der Spieler stellt Teams zusammen, plant einen Einsatz und erteilt Befehle an Fire Team Leader; einzelne NPCs werden nicht direkt gesteuert. Die angestrebte Schleife lautet: Heimatbasis → Team und Loadout → FOB/Dropship → LZ und Deboard → Fireteam-Befehle → Missionsziel → Ergebnis/Debrief → Rückkehr und Weiterentwicklung.

Historische Verifier belegen Teile dieser Schleife, darunter den authored `grid_sweep`-Pfad bis Objective und Debrief. `TASK_N002` hat den frischen Checkout-Import, den minimalen Start und einen Windows-Export mit dem versionierten Bootstrap nachgewiesen. Der aktuelle Checkout ist trotzdem noch kein frisch reproduzierter Release-Kandidat: Der anschließende TASK-1179-Harness meldet nach seinen Assertions eine bereits freigegebene Instanz.

## Gegenwärtige Evidenzlage

- `TASK_1179` ist historische 18/18-Evidenz für zwei vollständige `grid_sweep`-Objective-/Debrief-Läufe auf dem Homebase-zu-Debrief-Pfad. Zwei aktuelle Läufe meldeten jeweils 18/18 Assertions und Exitcode 0, aber beide auch nachgelagert eine bereits freigegebene Instanz. Das ist kein frischer sauberer Objective-/Debrief-Vollnachweis.
- `TASK_N002` belegt auf Commit `4393a6a9a6f036ef2ca152cf10a8702c3e713780` einen externen Fresh-Clone-Import ohne UID-, Autoload-, Parse- oder Scriptfehler, einen minimalen Headless-Start mit Exitcode 0 und einen erzeugten Windows-Release-Artefaktsatz. Der zugehörige Evidence-Record unterscheidet dies bewusst vom weiter offenen Gameplay-Nachlauf.
- `TASK_1180` ist ein hashgesicherter Kandidat für einen First-Contact-/Live-Fire-Trace, aber nicht integriert. Seine Quelle liegt außerhalb dieses Checkouts unter `C:/dev/SternenBuergerchen-recovery/2026-07-17-project-forward/docs/tasks/TASK_1180_ground_mission_first_contact_live_fire_trace.md`; SHA-256 und Status stehen im versionierten Recovery-Manifest. Erst die Portierung auf den öffentlichen authored Pfad und zwei frische N004-Läufe können ihn zu Evidenz machen.
- Der datierte TASK-1181-HTML-Bericht ist eine unveränderliche Momentaufnahme und Arbeits-Workbench, kein Produktbuild und keine kanonische Gegenwartsquelle.

Exakte Commits, Artefakte, Läufe und Caveats stehen im Evidence-Manifest und in der lesbaren QA-Zusammenfassung.

## V1-Grenzen

V1 bleibt bei Commander-Befehlen für Bewegen, Nehmen, Verteidigen und Flankieren sowie FTL-Ausführung für Deckung, Zielbereich, Bekämpfen, Halten und Rückzug. Einsätze laufen in Echtzeit ohne Pause; Damage bleibt datenbasiert, Friendly Fire ist aktiv und Out-of-View-Simulation darf vereinfacht, aber konsistent sein.

Nicht V1 sind persistente PvP-Teams, ein komplexer Spieler-Map-Editor, tiefe soziale Systeme, komplexe Fahrzeuge oder Feuerregeln, echte Ballistik, abschießbare Dropships und große Content-Mengen. Heimatbasis und FOB bleiben UI-/Staging-first statt frei begehbarer Simulationsräume.

## Nächster vertrauenswürdiger Schritt

Vor neuer Produktbehauptung muss ein kleiner Folgetask den TASK-1179-Nachlauf ohne Zugriffe auf freigegebene Instanzen sauber recapturen. Erst danach folgen Command-Autorität (`TASK_N003`) und die öffentliche Produktmission mit integrierter TASK-1180-Evidenz (`TASK_N004`).
