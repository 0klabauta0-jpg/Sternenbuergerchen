# TASK_124 - Area Feedback in #17 Selected Fireteam

## Ziel
Das Panel `#17 SELECTED FIRETEAM` soll Area Orders lesbar machen, ohne die NPCs auf der Karte wieder mit Text zu ueberladen. Der Spieler soll verstehen, welchen Bereich das Fireteam gerade bearbeitet, welchen Modus es nutzt und ob es wartet, verteidigt, angreift oder Kontakt hat.

## Status: OFFEN

## Voraussetzung
- `TASK_121 - Area Order Marker`
- sinnvoll nach `TASK_122` und `TASK_123`

## Kontext
- Live-NPC-Text wurde bewusst reduziert, damit die Figuren sichtbar bleiben.
- Kritische Kurztexte ueber NPCs bleiben erlaubt, z.B. Feuerdisziplin-Bruch.
- #17 ist der richtige Ort fuer Details wie aktueller Wegpunkt, Bewegungsart und Ziel.

## Umfang
1. #17 zeigt fuer Area Orders kompakte Statuszeilen:
   - `DEFEND AREA | 5 Felder | SEC 360 | wartet auf Kontakt`
   - `ATTACK AREA | Approach NW | Kontakt bestaetigt`
   - `TAKE AREA | 3/7 Felder gesichert`
2. Anzeige unterscheidet:
   - Befehlstyp
   - Area-Groesse
   - aktueller Ausfuehrungsmodus
   - Security-/Contact-Status
   - GO-Wartezustand
3. Welt-Overlay bleibt reduziert:
   - Marker/Flaechen und kurze Warnbadges
   - keine langen Debugzeilen ueber NPCs
4. Mehrfachauswahl zeigt verdichtete Zeilen pro Fireteam.

## Nicht-Ziele
- Keine neue grosse UI-Ansicht.
- Keine permanente Debug-Konsole im Spielbild.
- Keine Detailwerte, die ins Charakterblatt gehoeren.

## Architekturregeln
- #17 liest Snapshots, aber verwaltet keine Gameplay-Wahrheit.
- Keine per-frame Komplett-Rebuilds; bestehende Refresh-/Dirty-Pfade nutzen.

## Akzeptanzkriterien
- [ ] Area Order wird in #17 mit Typ, Groesse und Status angezeigt.
- [ ] Defend/Attack/Take sind sprachlich klar unterscheidbar.
- [ ] NPCs auf der Map bleiben lesbar und werden nicht wieder mit langen Texten verdeckt.
- [ ] Mehrfachauswahl bleibt kompakt.
- [ ] Headless-Verifier prueft die erzeugten Statusstrings.

## Dateien (voraussichtlich)
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- ggf. `scripts/tactical/visuals/fireteam_order_visualizer.gd`
- `scripts/tests/task_124_verifier.gd`

## Risiken
- Zu viele Statusdetails machen #17 unruhig. Lieber wenige gute Worte als Debug-Wand.

