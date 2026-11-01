# Native UI-Umsetzung R1 · 01.11.2026

## Ziel / Ursache
Der Nutzer hat die Bild-KI-Entwürfe ausdrücklich positiv bewertet und die Übertragung auf die echte Spiel-UI beauftragt. Die vorhandenen Theme-Helfer decken nur Teilflächen ab; harte Overrides und alte Missionsslots verhindern einheitliche Fenster und kompakte Bedienung.

## Basis und Autorisierung
- Neuer Branch `task/ui-umsetzung-r1-20261101`, gestartet von `integration/core-foundation` (`3cae5a216`), genehmigtes Konzept anschließend per Fast-forward bis `135466b5c` übernommen.
- Diese Umsetzung baut bewusst auf dem noch nicht integrierten Konzepttask auf. Der Hauptcheckout bleibt unberührt.
- Nutzerauftrag: jetzt umsetzen, mehrere sichtbare Iterationen sind vorgesehen. Der bestehende Konzeptguide ist die Gestaltungsspezifikation; keine neue Freigaberunde erforderlich.

## Umfang / Nicht-Ziele
- Gemeinsames natives Theme und schmale Fenster-/Kartenrahmen, konsistente Controls einschließlich Dropdowns, Tabs, Fokus, gesperrter Zustände, Popups und Scrollbars.
- Hauptmenü/Creator, Heimatbasis, FOB/Loadout, Charakterbogen/kompakte Karten, Debrief, Lobby, Settings/Escape/Hilfe, Editor sowie Missions-HUD an dieselbe Formsprache anbinden.
- Mission: zwei kompakte quadratische Aktionsreihen unten links, Ziel/Auftrag vor Teamparametern; Karten und Log oberhalb; Transport/Ziel oben rechts. Reale bestehende Funktionen behalten, auch wenn die Illustration sie nicht vollständig zeichnet.
- Keine neue Gameplay-Wahrheit, keine Änderungen an Simulation/Netzwerk/Balance/FoW/Transportregeln. Keine Fantasieaktionen oder illustrativen Werte übernehmen. Kein begehbarer Basisumbau und keine ungefragte Änderung der Weltgrafik.

## Relevante Verträge
- `docs/dev/ui_native_design_contract.md`, `docs/dev/ui_theme_component_library.md`
- `docs/ui_concepts/ui_20261101/MENUES_UND_KARTEN.md`, `BILDPRUEFUNG_REVISION5.md`, `UEBERGABE.md`
- `scripts/ui/mission_command_hierarchy_contract.gd`, `scripts/meta/drop_light_layout_contract.gd`
- Bestehende Read-only-/Loadout-/Shell-/Lobby-Contracts und `docs/ARCHITECTURE.md`.

## Akzeptanz
1. Ein gemeinsames Theme versorgt die genannten Screenfamilien; Fenster, Input-/Popupflächen und Fokus haben dieselben Rollenfarben.
2. Die Mission zeigt zwei echte Reihen mit quadratischen 64×64-Zielkörpern und Innenlabels. Keine erfundenen oder leeren aktiven Platzhalter. Kontextuelle Türinteraktion, Feuerregeln und bestehende Planwerkzeuge bleiben erreichbar.
3. Keine Überlagerung/Clipping der primären Aktionen bei 1920×1080 sowie repräsentativ 1280×720; geringe Auflösung darf Inhalte sinnvoll umordnen, nicht Funktionen entfernen.
4. Personen-ID, Auswahl, FTL, Transit und lesende/bearbeitbare Bögen behalten ihren bisherigen Vertrag.
5. Gezielte Godot-Verifier und echte gerenderte Viewportbilder belegen Struktur und Darstellung getrennt. Kein Ersatzbild als Runtime-Capture ausgeben.

## Dateien / lokale Prüfung
- Theme: `scripts/ui/tactical_ui_theme.gd`, `scripts/meta/meta_ui_skin.gd`.
- Konsumenten: bestehende Shell-/Meta-/Karten-/Editor-Skripte; Missionscontroller und Layoutvertrag. Kleine visuelle Helfer nur bei Bedarf.
- Gezielte neue UI-Verifier und aktualisierte historische Layoutchecks; keine pauschale Golden-Neuerzeugung.
- Nachweisordner `docs/qa/ui_native_r1_20261101/`; Import einmal zentral, dann begrenzte sequenzielle Checks; native Captures mit explizitem Renderer. Status und Git nach Prüfung aktualisieren.

## Risiken / offene Punkte
- Alte slotgebundene Layoutchecks werden durch die gewünschte Änderung absichtlich überholt; Funktionsassertions bleiben erhalten.
- Neue Theme-Mindestgrößen können enge historische Panels vergrößern. Daher echte Screenbilder prüfen und harte Overrides gezielt korrigieren.
- Generierte Icons haben uneinheitliche Motivpolster; bei Übernahme optisch prüfen. Komplettscreens nicht als Hintergrund mit unsichtbaren Controls verwenden.
- R1 ist eine überprüfbare erste Umsetzung, kein umfassender menschlicher Bedienbarkeitstest oder Release-Nachweis.

## Umsetzungsergebnis
- Gemeinsame Regeln nativ an alle genannten Screenfamilien angebunden. Keine neuen Gameplay-Owners oder Commands; vorhandene Signale/Callbacks und Lesemodelle bleiben erhalten.
- Echte Bilder führten zu Korrekturen an Header-/Feuerregelüberlagerungen, Fenster-Minimums, festen Settings-/Creatoraktionen und Popup-Z-Ebenen. Alte Slot-IDs sind im kompakten Befehlsband verborgen, ihre Metadaten bleiben erhalten.
- Unveränderte Layoutrefreshes haben eine visuelle Signatur und schreiben keine Rects erneut. Eingeschiffte Mitglieder werden entsprechend bestehendem Vertrag deaktiviert angezeigt.
- Verifier für aktuelle Besitzer und A5-Geometrie ergänzt; historische Prüfziele nur nach Quellenvergleich aktualisiert. Ergebnisdatei und Grenzen: `docs/qa/ui_native_r1_20261101/VERIFIKATION.json`, `README.md`.
- Beobachteter Generator-/Store-Randfall bleibt separater Scope; UI-Fixtures verwenden gültige kontrollierte Kernwerte und unveränderte echte Save-/Auswahlpfade.
