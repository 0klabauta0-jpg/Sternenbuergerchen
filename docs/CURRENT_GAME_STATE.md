# Aktueller Spielstand

<!-- canonical-current-state: true -->

Stand: 17. Juli 2026. Dieses Dokument ist die einzige kanonische Kurzbeschreibung des gegenwärtigen Produktstands. Es beschreibt keine zweite Gameplay-Wahrheit und ersetzt keine Runtime-Contracts.

## Spielerfantasie und erreichter Kern

SternenBuergerchen ist ein Commander-gesteuertes Echtzeit-Taktikspiel. Der Spieler stellt Teams zusammen, plant einen Einsatz und erteilt Befehle an Fire Team Leader; einzelne NPCs werden nicht direkt gesteuert. Die angestrebte Schleife lautet: Heimatbasis → Team und Loadout → FOB/Dropship → LZ und Deboard → Fireteam-Befehle → Missionsziel → Ergebnis/Debrief → Rückkehr und Weiterentwicklung.

Historische Verifier belegen Teile dieser Schleife, darunter den authored `grid_sweep`-Pfad bis Objective und Debrief. Der aktuelle Checkout ist jedoch noch kein frisch reproduzierter Release-Kandidat: `TASK_N002` muss UID-, Autoload- und Startbedingungen erst sauber nachweisen.

## Gegenwärtige Evidenzlage

- `TASK_1179` ist historische 18/18-Evidenz für zwei vollständige `grid_sweep`-Objective-/Debrief-Läufe auf dem Homebase-zu-Debrief-Pfad. Ein späterer isolierter Versuch endete vor den letzten Assertions; das ist kein frischer Vollnachweis für diesen Checkout.
- `TASK_1180` ist ein hashgesicherter Kandidat für einen First-Contact-/Live-Fire-Trace, aber nicht integriert. Seine Quelle liegt außerhalb dieses Checkouts unter `C:/dev/SternenBuergerchen-recovery/2026-07-17-project-forward/docs/tasks/TASK_1180_ground_mission_first_contact_live_fire_trace.md`; SHA-256 und Status stehen im versionierten Recovery-Manifest. Erst die Portierung auf den öffentlichen authored Pfad und zwei frische N004-Läufe können ihn zu Evidenz machen.
- Der datierte TASK-1181-HTML-Bericht ist eine unveränderliche Momentaufnahme und Arbeits-Workbench, kein Produktbuild und keine kanonische Gegenwartsquelle.

Exakte Commits, Artefakte, Läufe und Caveats stehen im Evidence-Manifest und in der lesbaren QA-Zusammenfassung.

## V1-Grenzen

V1 bleibt bei Commander-Befehlen für Bewegen, Nehmen, Verteidigen und Flankieren sowie FTL-Ausführung für Deckung, Zielbereich, Bekämpfen, Halten und Rückzug. Einsätze laufen in Echtzeit ohne Pause; Damage bleibt datenbasiert, Friendly Fire ist aktiv und Out-of-View-Simulation darf vereinfacht, aber konsistent sein.

Nicht V1 sind persistente PvP-Teams, ein komplexer Spieler-Map-Editor, tiefe soziale Systeme, komplexe Fahrzeuge oder Feuerregeln, echte Ballistik, abschießbare Dropships und große Content-Mengen. Heimatbasis und FOB bleiben UI-/Staging-first statt frei begehbarer Simulationsräume.

## Nächster vertrauenswürdiger Schritt

Vor neuer Produktbehauptung muss `TASK_N002` einen frischen Godot-Checkout und den tatsächlichen Ausgang des TASK-1179-Pfads reproduzierbar prüfen. Danach folgen Command-Autorität (`TASK_N003`) und die öffentliche Produktmission mit integrierter TASK-1180-Evidenz (`TASK_N004`).
