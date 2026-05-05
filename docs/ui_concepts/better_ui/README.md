# Better UI concept pass

Status: Vorschau, nicht in Godot integriert.

## Ziel

Dieser Ordner sammelt erste UI-Richtungen fuer den naechsten visuellen Pass. Die Beispiele sind absichtlich statische HTML-Mockups, damit die Richtung bewertet werden kann, bevor Szenen, Runtime-Skripte oder UI-Komponenten geaendert werden.

## Quellen und Recherche

- Kenney UI Pack Sci-Fi: CC0, 130 Dateien, Buttons, Panels, Slider, Space/Sci-Fi-Interface. https://kenney.nl/assets/ui-pack-sci-fi
- Construct/Kenney Space Expansion Uebersicht: zeigt enthaltene Fonts, PNGs, Buttons und Bars. https://www.construct.net/en/game-assets/construct-free-bundled-assets/ui-pack-sci-fi-4935
- Into the Breach bei Interface In Game: gute Referenz fuer kompakte In-Game-, Overlay-, Quest-, Progress- und Stats-Flaechen. https://interfaceingame.com/games/into-the-breach/
- Tactical Breach Wizards: gutes Beispiel fuer taktische UI als Vorschau-/Feedback-System statt nur Dekoration. https://en.wikipedia.org/wiki/Tactical_Breach_Wizards

## Vorschlaege

### A - Tactical Dock

- Karte bleibt Hauptflaeche.
- `#16 COMMAND MATRIX` bekommt Move, Hold, Flank, Take, Target, Clear, Stance und `GO`.
- `#17 SELECTED FIRETEAM` wird reine Status-/Roster-Flaeche.
- `#18 MISSION CONTROL` bleibt Dropship/LZ, aber mit festen Button-Hoehen.

### B - Operator Cards

- `#04 INBOUND TO FOB` und `#06 DECK ACTIVITY` werden keine eigenen Fenster mehr.
- Transfer, Deck, Bay und Recovery stehen als kompakte Balken auf NPC-/Deck-Karten.
- Karten haben feste Hoehen; lange Texte werden gekuerzt.

### C - Dense Loadout Drawer

- `#13 LOADOUT` zeigt kleine fixe Zeilen.
- Waffenbilder sind klein und stabil, aktuell nur SMG/Blaster A und Medictool/Blaster B.
- Spaetere Waffen koennen ueber denselben Slot- und Preview-Vertrag ergaenzt werden.

### D - Hangar Ops Board

- `#05 Flightdeck` und `#14 FOB Ops` werden als kleine Operations-Buehne gedacht, nicht als echte Karte.
- Dropship, Frachter, Bay-Slots, Boarding und Medbay/Respawn werden sichtbar, aber bleiben reine UI-/Staging-Darstellung.
- NPCs koennen konzeptionell aus `#10 FIRETEAMS` oder `#13 LOADOUT` auf Dropship-/Frachter-Slots gezogen werden.
- Boarding-Zustand wird direkt am Pad und in kompakten Karten angezeigt.
- `#18 MISSION CONTROL` nutzt eine kleine Windrose statt grosser NW/NE/SW/SE-Buttons.
- `#16 COMMAND MATRIX` nutzt kleinere Buttons, damit spaeter mehr Statusinformationen Platz haben.

## Command-Vorschlag

- `Move`, `Hold`, `Flank`, `Take`: Befehlsintentionen.
- `Target`: schaltet Ziel-/Map-Auswahl.
- `Clear`: loescht den gerade gepufferten Befehl.
- `Vorsichtig`, `Normal`, `Aggressiv`: Parameter des Befehls.
- `GO`: fuehrt den gepufferten Befehl aus.

Damit ist `GO` nicht mehr allein in `#17`; der Execute-Fluss sitzt komplett in `#16`.

## Anti-Resize-Regeln

- Fenster bekommen feste Hoehen und Breiten pro Screen.
- Button-Texte duerfen niemals Button- oder Panelgroessen veraendern.
- Variable Inhalte laufen in ScrollContainer, Clip oder Ellipsis.
- Labels auf der Map sollen an Marker-/Objective-Hoehe haengen, nicht an Unit-Beinhoehe.
- Grey helper backplates hinter Squad-Namen nur verwenden, wenn sie Lesbarkeit verbessern; sonst als kleine floating labels oder Map-Badges.
- Flightdeck-/FOB-Buehnen duerfen Animationen zeigen, aber keine zweite Karten- oder Gameplay-Wahrheit werden.

## Lokaler Blick

Die bisherigen Mischvorschlaege liegen hier:

`docs/ui_concepts/better_ui/index.html`

Die nach Screen getrennten Vorschlaege liegen hier:

`docs/ui_concepts/better_ui/separated_screens.html`

Aktuelle Gewichtung:

- Homebase: Roster im Fokus; nur Fahrzeug-/Flugzeugauswahl mit Pilotenzuordnung.
- Homebase Iteration 2: schmaler Roster, weniger Fensterrahmen, mehrere Kenney-Bodenplatten als Launch-Slots, echte Isometric-Kenney-Schiffbilder und einzelne Boarding-Fortschrittsbalken pro Operator.
- Homebase Iteration 3: Launchdeck als zusammenhaengendes 4x6-Feld aus Plattform-Sprites mit Rand-/Wandteilen, Schiffe liegen auf den Feldern, Operator-Tokens sitzen oberhalb der Schiffe, unten stehen Schiff-Fuellstaende.
- Homebase Iteration 4: grosse gelb gerahmte Pads, Schiffe nur auf einzelnen Feldern, gestapelte Operator-Karten direkt ueber den Schiffen und untere Schiffkarten mit Pilot-/Passagier-Dropzone.
- Homebase Iteration 5: Hangarfeld nutzt `platform_large_NW.png` als grosse gelb gerahmte Pads in einem schraeg verbundenen Streifen; Schiffe sitzen versetzt auf jedem zweiten Pad.
- FOB: Fireteam-Zusammenstellung im Fokus; Flightdeck rechts mit sichtbaren Kenney-Space-Kit-Assetbildern.
- Mission: quadratische Buttons in `#16`; kleinere Windrose in `#18`, damit LZ/Drop-Buttons sichtbar bleiben.
