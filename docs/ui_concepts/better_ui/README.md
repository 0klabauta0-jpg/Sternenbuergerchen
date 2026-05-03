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

## Lokaler Blick

Die Vorschau liegt hier:

`docs/ui_concepts/better_ui/index.html`

