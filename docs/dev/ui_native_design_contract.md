# Native UI Design Contract · R1

Gültig für den vom Nutzer am 01.11.2026 beauftragten Umsetzungsschritt auf Basis der bestätigten UI-Konzepte. Die Bilder bestimmen Formsprache und Gruppierung; bestehende Runtime-/Datenverträge bestimmen Inhalt und erlaubte Aktionen.

## Gemeinsame Sprache
- Dunkle matte Flächen `151c21` / `252d33`, tiefer Hintergrund `0c1114`.
- Haupttext `edf3f6`, Nebeninformation `a9b4bc`; kein dunkler Text auf dunkler Fläche.
- Cyan `63d1d2`: Interaktion/primäre Aktion. Gelb `f2c94c`: ausgewählter Datensatz oder Team. Fokus erhält eine sichtbare eigene Kontur; Auswahl, Hover und Fokus bleiben unterscheidbar.
- Statusfarben ergänzen Text/Form. Normaler Transit ist kein Fehlerzustand.
- 8px-Basisabstand, schmale einheitliche Rahmen, kleine Eckradien, zurückhaltender Schatten. Native StyleBoxes statt gerasterter Vollbildrahmen.
- Gemeinsame Regeln in `TacticalUITheme`, bestehende `MetaUISkin` delegiert/übersetzt. Keine zweite Theme- oder Gameplay-Architektur.

## Öffentliche Darstellungs-API
- `TacticalUITheme.get_theme() -> Theme`: wiederverwendetes natives Theme für vererbende Controls/Popups.
- `TacticalUITheme.apply_screen(root: Control) -> void`: Theme am UI-Root anwenden, bei Bedarf einmalige optische Vorbereitung; niemals pro Frame SceneTree durchsuchen.
- Bestehende `style_card`, `style_command_button`, `style_label`, `style_progress_bar` bleiben kompatibel.
- `TacticalUITheme.style_action_tile(button: Button, selected: bool = false, primary: bool = false) -> void`: kompakte quadratische Missionsaktionen, vorhandenen Zustand ausschließlich anzeigen.
- Screenfamilien können erforderliche kleine Textgrößen/Abstände setzen. Neue pauschale Mindestgrößen dürfen bestehende Controls nicht unbemerkt aus Panels drücken.

## Mission
- Band beginnt an der linken unteren Viewportkante; Aktionen in zwei sichtbaren Reihen. Ziel/Auftrag als eigener nächster Block; danach Teamheader und Haltung/Feuerregeln.
- Native Referenzgröße für Aktionstasten 64×64 bei 1920×1080, Abstand 4–8px, Text innen. Die 50–52px im Generatorbrief waren Rasterziele, keine verbindlichen Laufzeitmaße.
- Keine aktive leere Reservekachel. Kontextaktionen wie Türsturm bleiben nur im richtigen Kontext erreichbar. Alle bestehenden Feuerregeln und Planwerkzeuge bleiben bedienbar. GO führt aus, keine Pause.
- Teamkarten und Protokoll liegen vollständig über dem Band. Missionsziel und Transport/LZ bleiben oben rechts. Keine Titelillustration oben links.
- Layoutänderung verändert keine Commands, Zustandsbesitzer, Callback-Gates oder Feindinformation.

## Weitere Screenfamilien
- Hauptmenü, Bibliothek und Creator behalten Aktivieren/Bearbeiten/Löschen/Speichern/Laden sowie bestehende Bestätigungen.
- Heimatbasis/FOB: Zuweisung, Pilot, Kapazität, Boarding und Transit stammen aus denselben bestehenden IDs/Owners. Keine Bildbeispielzahlen übernehmen.
- Kompaktkarten zeigen Identität und Zustand; der volle Bogen liest Daten. Nur der vorgesehene Creator bietet Metrik-/Budgetbearbeitung.
- Lobby: verbunden, bereit, Karte angenommen und Startfreigabe bleiben getrennt. Settings-Hilfe erfindet kein Rebinding. Escape pausiert nicht.
- Editor behält Authoring-Funktionen und Wertebereiche (Deckung 0–100). Kein Rasterwechsel durch Bildreferenzen.

## Nachweis
Native Strukturchecks prüfen Controls, Quadrate, Positionen, Erreichbarkeit und Zustandsgrenzen. Echte nicht-headless Viewport-Captures prüfen das gerenderte Ergebnis. Kein simuliertes Capture-/Ersatzboard gilt als Bildbeleg. Menschliche Verständlichkeitsprüfung bleibt offen.
