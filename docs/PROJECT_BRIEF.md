# PROJECT_BRIEF

## Projekt
SternenBuergerchen

## Lokale Projektbasis
- Projektpfad: `C:\dev\SternenBuergerchen`
- Engine: Godot 4.6.2
- Codex läuft in VS / VS Code gegen das lokale Repo
- Änderungen müssen lokal lauffähig sein und anschließend über Git nach GitHub gepusht werden

## Kernziel
Commander-gesteuertes Echtzeit-Taktikspiel mit FTL-Hierarchie, menügetriebenem Meta-Layer und taktischem Einsatz als Kern des Spiels.

## Core Loop
Mondbasis erkunden / Personal -> Trupp und Ausruestung -> Auftrag annehmen -> Abheben / Mondorbit -> Sternkarte / Quantum zum Planetenorbit -> Zielort und Anflug -> Einsatz oder Ortsbesuch -> Rueckorbit / Heimflug / Landung -> Ergebnis und Skillentwicklung

## Harte Designentscheidungen
- Spieler ist Commander
- Direkt steuerbar maximal bis Fire Team Leader (FTL)
- Im taktischen Einsatz werden Einzel-NPCs nicht direkt gesteuert; in der Heimatbasis verwaltet der Spieler die beiden echten Personen ueber deren Basisaktionen.
- Einsatz ist Echtzeit ohne Pause
- Die Heimatbasis ist begehbar und bietet dieselben Personal-/Trupp-/Abflugfunktionen wie die Operationsnavigation. Der regulaere Einzelspielerweg verwendet Homebase Direct; FOB ist vorerst gesperrt. Keine zweite Gameplay-Wahrheit in UI oder Basisdarstellung.
- PvP ist wichtig, aber Multiplayer-Prototyp V1 arbeitet zuerst mit Testteams
- Damage ist datenbasiert, nicht physikbasiert
- Friendly Fire ist an
- Respawn ist unbegrenzt mit Zeitverzögerung
- Out-of-View-Simulation läuft weiter, darf aber vereinfacht werden
- Godot bleibt gesetzt

## V1 Commander-Befehle
- Bewegen
- Nehmen
- Verteidigen
- Flankieren

## V1 FTL-Ausführung
- Deckung suchen
- Zielbereich ansteuern
- Gegner im Zielbereich bekämpfen
- Halten
- Zurückziehen

## V1 Respawn
- Rover: 30 Sekunden
- FOB: 2,5 Minuten
- Heimatbasis: 4–5 Minuten

## V1 ausdrücklich nicht enthalten
- persistente PvP-Teams
- komplexer Map-Editor für Spieler
- tiefe soziale Dynamik
- komplexe Fahrzeugsysteme
- komplizierte Feuerregeln
- echte Ballistik
- Dropship abschießen in V1
- große Content-Mengen
