# Native UI R1 · Umsetzung und Prüfung

Die bestätigte Bildsprache ist als erste native Spiel-UI umgesetzt. Gemeinsame Regeln für Fenster, Karten, Buttons, Dropdowns, Inputs, Scrollbars und Fokus liegen in `TacticalUITheme`; `MetaUISkin` verwendet dieselben Farben und StyleBox-Fabriken. UI liest weiterhin bestehende Daten und sendet vorhandene Commands.

## Einstieg

- [Native Review-Workbench](../../reports/STERNENBUERGERCHEN_UI_NATIVE_R1_2026-11-01.html): echte Godot-Bilder, Bewertungen pro Ansicht und lokaler JSON-Export.
- [Gestaltungsvertrag](../../dev/ui_native_design_contract.md), [Umsetzungstask](../../tasks/TASK_UI_UMSETZUNG_R1_20261101.md).
- [Ursprüngliche Bild-KI-Entwürfe](../../reports/STERNENBUERGERCHEN_UI_2026-11-01.html) bleiben als Vorgeschichte erhalten.

Spiel aus diesem Checkout starten, nicht aus dem unveränderten Hauptcheckout:

```powershell
godot --path "C:\Users\bjoer\.codex\worktrees\ui-entwuerfe-20261101\SternenBuergerchen"
```

Basis ist `integration/core-foundation` (`3cae5a216`) plus ausdrücklich übernommenem Konzeptstand `135466b5c`. Implementierung auf `task/ui-umsetzung-r1-20261101`; keine Integration in den Hauptbranch.

## Was umgesetzt ist

- Dunkle matte Flächen, cremefarbene Schrift, Cyan für Interaktion/Primäraktionen, Gelb für Datensatzauswahl; eigene transparente Fokuskontur und gemeinsame schmale Rahmen.
- Hauptmenü mit separater Teamkarte rechts; Settings und Creator in begrenzten Fenstern. Lange Inhalte scrollen, Speichern/Schließen beziehungsweise Anwenden/Defaults/Abbrechen bleiben fest erreichbar.
- Heimatbasis, FOB/Loadout, Personen-/Charakteransichten, Lobby, Debrief, Editor, Escape und Kontexthilfe verwenden die gemeinsame native Basis. Vorhandene Daten, Bearbeitungsbudgets, IDs und Signale bleiben maßgeblich.
- Mission: zwei Reihen mit neun bestehenden 64×64-Aktionen unten links. Ziel/Auftrag steht vor Team/Haltung/Feuerregeln. Mitgliederkarten und Log liegen über dem Band, Einsatzkontrolle oben rechts. Kontextuelle Aktionen, WP-Löschen und vier Feuerregeln bleiben erreichbar.
- Personenoverlay liegt über den Mini-Karten. Unveränderte UI-Refreshes wenden die Geometrie nicht erneut an; StyleBox- und Iconressourcen werden wiederverwendet.
- Eingeschiffte Mitglieder bleiben in der ausgewählten Anzeige sichtbar und deaktiviert; dabei wird ausschließlich vorhandener Transit-/Embarked-State gelesen.

Sechs bytegleiche Bildgenerator-Iconkandidaten liegen mit Herkunftsmanifest unter `Assets/curated/ui_native_r1/`. Die vier Missionsbefehle nutzen den gecachten Iconkatalog; transparente Ränder werden nur durch AtlasTexture-Anzeigeregionen vereinheitlicht. Komplettscreens oder generierte Schriften werden nicht als Spielcontrols verwendet. Bestehende Weltgrafik, Portraits und Hintergründe wurden nicht durch die Konzeptillustrationen ersetzt.

## Technische Prüfung

Die aktuelle Zusammenfassung und Quelldateihashes stehen in [VERIFIKATION.json](VERIFIKATION.json). Für alle 16 ausgewählten Checktypen liegen saubere Endnachweise vor. Die letzte Gesamtrunde wird durch gezielte Nachläufe ausschließlich der anschließend geänderten A5-/Hierarchie- und Shell-Prüfungen ergänzt; ihre Herkunft ist pro Check erfasst. A5 umfasst 352 Assertions, Shell 63, der HTML-Export neun Offline-Checks. Einzelne Erstversuche/RED-Logs bleiben zur Nachvollziehbarkeit erhalten; sie sind kein aktueller grüner Nachweis.

- Theme-RED: drei neue APIs fehlen erwartungsgemäß. Theme-GREEN: zwölf tatsächliche Assertions.
- A5-RED: fünfzig Layoutfehler; spätere Tests decken zusätzlich Ebenen, unveränderte Refreshes, Callback-Gates und Kontextzugänge ab.
- Shell-Verifier prüft reale Viewports 1920/1280, Fenster-/Footergrenzen, echtes Scrollen, ausgewählte Library-Datensätze und den aktuellen lesenden Homebase-Popup über das Kartensignal.
- Gezielte vorhandene Verifier decken unter anderem Kartenreferenzen, Settings, Lobby/Shell, Befehle, Tile-/LZ-Gates, Feuerregeln und HUD-Refreshgrenzen ab.
- [HTML-Exportprüfung](html_export_qa.json): tatsächliches Inline-JavaScript offline in Node VM mit synthetischem DOM. Browserlayout, echter Clipboard-/Downloadweg und menschliche Bedienung sind damit nicht geprüft. Die bekannte `file://`-Browserblockade wurde nicht umgangen.

Der reguläre erste Editorimport meldete ein vorhandenes Plugin-Leak; Recovery-Import deaktivierte benötigte GDExtensions und war deshalb ebenfalls kein sauberer Nachweis. Der abschließende [Importnachweis](import_result.json) führt den normalen Import mit ausschließlich vorübergehend deaktivierten Editorplugins aus, behält GDExtensions bei und bestätigt Exit 0 ohne Fehler/Leaks. `project.godot` wurde bytegleich wiederhergestellt und ist kein Teil des Diffs.

Die umfangreichen früheren Importlogs bleiben verlustfrei in `import_history.zip` erhalten; der saubere Endlauf liegt direkt in `import_clean.log`.

Zusätzlich startete die echte Hauptszene mit der unveränderten Projektkonfiguration erfolgreich über D3D12/Forward+ und beendete sich nach 60 Engine-Iterationen mit Exit 0 ohne Fehler oder Leaks (`default_renderer_smoke.log`). Das ist ein Start-Smoke, kein gespielter Missionsnachweis.

Zwei zusätzlich versuchte alte Verifier (`TASK164`, `TASK235`) erwarten bereits im Basisstand stillgelegte UI-Besitzer. [Quellenvergleich](legacy_baseline_source_check.json) dokumentiert unveränderte betroffene Funktionen; das ist ein Sourcevergleich, kein ausgeführter Baseline-Test. Aktuelle Theme-/Shell-Verifier prüfen die heutigen Komponenten und den echten Popup. TASK181/312/628 wurden gezielt auf aktuelle Besitzer beziehungsweise die beauftragte neue Anordnung aktualisiert; Funktionsgates bleiben erhalten.

Ein beobachteter, separat zu bewertender Datenrandfall: Mit `native_shell_fixture` und Profil-ID `native_shell_1280_720_3799609` erzeugt der vorhandene Rostergenerator einen Toughness-Wert, den der bestehende Store als `roster_skill_out_of_range` ablehnt. Der diagnostische Wiederholungslauf ist in `shell_layout_deterministic.log` festgehalten. Weder Generator noch Speichergrenzen werden in diesem UI-Task verändert. Die Library-Geometrieprüfung benötigt gültige Daten und verwendet deshalb ausdrücklich kontrollierte, gültige mittlere Kernwerte statt zufälliger Verteilungen.

## Echte Bilder und Grenzen

`ui_native_capture.gd` nutzt einen realen Windows-Viewport mit Godot 4.6.2 und `gl_compatibility`. Es gibt keinen selbst gezeichneten oder generierten Ersatz. Versteckte Testscreen-Roots werden ausdrücklich angezeigt; ein einfarbig leerer Viewport wird abgelehnt. Daten sind gekennzeichnete Fixtures, kein Beleg eines natürlich gespielten Kampagnenverlaufs.

Elf Ansichten liegen mit 1920×1080 vor. Mission und Settings zusätzlich mit 1280×720-Ausgabe: diese beiden Bilder skalieren den logischen 1920×1080-Viewport entsprechend der Spielkonfiguration. Sie sind kein separater Reflow-Bildnachweis. Die strukturellen Verifier prüfen davon getrennt tatsächliche 1280-UI-Viewports.

R1 belegt native Darstellung und die jeweils geprüften technischen Pfade. Sprachvereinheitlichung, endgültige Textdichte, optische Iconvereinfachung, ausführliche Bedienung mit Maus/Tastatur, weitere Auflösungen und ein vollständiger Meta-Spielzyklus bleiben eigene Folgerunden. Keine neue allgemeine Performance-, Multiplayer- oder Releaseabnahme.

## Reproduktion

```powershell
godot_console --headless --path . --script res://scripts/tests/ui_a5_native_hud_verifier.gd
godot_console --headless --path . --script res://scripts/tests/ui_native_shell_layout_verifier.gd
godot_console --path . --rendering-method gl_compatibility --audio-driver Dummy --script res://scripts/tests/ui_native_capture.gd -- --view=mission --size=1920x1080
node -e "eval(JSON.parse(require('fs').readFileSync('docs/qa/ui_native_r1_20261101/html_export_qa.json','utf8')).repro_script)"
```

Für die nächste Runde aktuelle Branch-/Diffsituation und `docs/IMPLEMENTATION_STATUS.md` lesen, dann die native Workbench samt Nutzerexport bewerten. Kleine Änderungen auf den gemeinsamen Regeln aufbauen; keine unabhängigen Screen-Themes oder zweite Gameplay-Wahrheit einführen.
