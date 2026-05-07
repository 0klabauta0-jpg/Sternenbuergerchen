# TASK_188 - Fireteam Advance Styles Map Readability

## Ziel
Die vorhandenen Bewegungsmuster `rush`, `bounding` und `caterpillar` sollen auf der Mission Map klar ersichtlich sein. Wenn ein Fireteam ueberschlagend vorgeht (`bounding`) oder raupenartig vorgeht (`caterpillar`), muss der Spieler sehen, dass sich das ueber mehrere Tiles als bewusstes Muster abspielt.

Der Task ist kein neues KI-System, sondern ein Lesbarkeits- und Verifier-Patch fuer die bestehenden Fireteam-Bewegungscontroller.

## Status: IMPLEMENTIERT

## Voraussetzung
- TASK_110 - FireteamMovementController und Bewegungsmuster
- TASK_111 - FireteamSecurityController und Overwatch
- TASK_121 - Area Order Marker
- TASK_124 - Area Feedback in #17 Selected Fireteam
- TASK_187 - NPC Minimum Spacing and Multiplayer Authority

## Kontext
`FireteamMovementController` kennt `rush`, `bounding` und `caterpillar`. `MissionTacticalSandboxController` zeigt Bewegungsmodus bereits kompakt an. Was noch fehlt, ist die harte Abnahme: Auf der Mission Map muss man sehen koennen, welche Gruppe gerade laeuft, welche Gruppe deckt, wo der naechste Bound endet und ob das Muster ueber mehrere Tiles wirklich stattfindet.

## Umfang
1. Status-Snapshots:
   - Pro Fireteam: aktiver `advance_style`, bewegende Members, deckende Members, aktueller Bound-Index, Ziel-Tile/Bound-Ziel.
   - Snapshot kommt aus Tactical-/Movement-Systemen, nicht aus UI-Text.
2. Mission-Map-Visualisierung:
   - `rush`: alle fit Members bewegen sich gleichzeitig, mit kurzer kompakter Statusmarke.
   - `bounding`: Bewegungsgruppe und Deckungsgruppe sichtbar unterscheiden; naechster Bound ueber mehrere Tiles markiert.
   - `caterpillar`: genau ein Member bewegt sich, Rest deckt; Sequenz ueber mehrere Tiles erkennbar.
   - Keine langen Labels ueber NPCs.
3. #17 Selected Fireteam:
   - Kompakte Zeile fuer Bewegungsmuster und Fortschritt.
   - Beispiel: `BND 2/4 | Alpha moves | Bravo covers`.
   - Deutsche/Projekt-Copy kurz halten, keine Debugwand.
4. Interaktion mit Area Orders:
   - Move/Defend/Take/Engage-Areas koennen die Bewegungsmuster nutzen.
   - Take Area zeigt weiterhin Area-Fortschritt, nicht nur Movement.
5. Verifier:
   - Erzeugt je einen Plan fuer `rush`, `bounding`, `caterpillar`.
   - Prueft, dass Bound-Ziele ueber mehrere Tiles gehen.
   - Prueft, dass Map-Snapshot und #17-Status dieselbe Bewegungsphase nennen.

## Nicht-Ziele
- Keine neue Formation-KI.
- Keine neue Overwatch-Ballistik.
- Keine langen Funktexte oder Voice-Systeme.
- Keine UI-Rewrite von #16/#17/#18.
- Keine Gameplay-State-Mutation im Visualizer.

## Akzeptanzkriterien
- [x] `rush`, `bounding` und `caterpillar` sind im Mission-Map-Snapshot unterscheidbar.
- [x] Bounding zeigt Bewegungs- und Deckungsgruppe sowie ein mehrtileiges Bound-Ziel.
- [x] Caterpillar zeigt genau einen bewegenden Member und eine Sequenz ueber mehrere Tiles.
- [x] #17 Selected Fireteam zeigt kurze, konsistente Statuszeilen zu Bewegungsmuster und Fortschritt.
- [x] Area Orders bleiben lesbar und werden nicht von Movement-Text ueberdeckt.
- [x] Ein TASK_188-Verifier deckt die drei Bewegungsstile strukturell ab.

## Erwartete Dateien
- `scripts/tactical/fireteam_movement_controller.gd`
- `scripts/tactical/fireteam_security_controller.gd`
- `scripts/tactical/visuals/fireteam_order_visualizer.gd`
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/tests/task_188_fireteam_advance_styles_map_readability.gd`
- `docs/tasks/TASK_188_fireteam_advance_styles_map_readability.md`
- `docs/IMPLEMENTATION_STATUS.md`

## Lokale Pruefung
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_188_fireteam_advance_styles_map_readability.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_110_verifier.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_111_verifier.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_124_verifier.gd`
- [ ] Manueller Mission-Map-Sichtcheck fuer Rush/Bounding/Caterpillar.
- [x] `git diff --check`

## Risiken
- Zu viel Text auf der Karte verdeckt wieder die NPCs. Karte zeigt Muster, #17 zeigt Details.
- Movement-Snapshots muessen aus dem Controller kommen; der Visualizer darf keine Bewegungslogik nachbauen.

## Naechster Schritt
Nach TASK_188 sind Bewegungsmuster spielbar lesbar. TASK_189 klaert danach die Medic-Reichweite als eigene Gameplay-Regel.
