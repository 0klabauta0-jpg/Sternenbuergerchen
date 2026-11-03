# Native UI R4 · 02.11.2026

[R4-Workbench mit Originalvorlagen, R3, neuen Bild-KI-Brücken und nativen Bildern](../../reports/STERNENBUERGERCHEN_UI_NATIVE_R4_2026-11-02.html). Der Nutzer hatte R3 ausdrücklich als visuell zu weit von den bestätigten 2D-Tafeln entfernt beurteilt. R4 bearbeitet deshalb Material, Titelhierarchie, Personenwirkung und Bildbühne, nicht nur die Panelgrößen.

## Sichtbare Änderungen und Gründe
- Tiefes Petrol, deutlichere Cyan-Konturen, helle Creme-Schrift und gelbe Auswahl führen die finale Bildfamilie fort. Große native Abschnittstitel und gewichtete Namen unterscheiden sich von Daten-/Statuszeilen. Die erste Kenney-Schrift war im Renderbild zu gesperrt; final ist Barlow Condensed Bold gebündelt. Quelle, Lizenz und SHA: `Assets/curated/ui_native_r4/manifest.json` und `OFL.txt`.
- Heimatbasis/FOB erhalten eine klar dekorative Main-Außenpostenbühne im wirklich freien rechten Bereich. Kein Arbeitsort wird dafür verdrängt. Bei wenig Platz wird die Bühne ausgeblendet. Kompakte R3-Dropziele, Scrollflächen, Zuordnungs-/Ausrüstungs-/Transportgates bleiben erhalten.
- Debrief zeigt einen markanten tatsächlichen Ergebniscode, deutlichere Abschnitte und vorhandene Personenportraits. MetaFlow ergänzt nur den realen Portraitpfad desselben Roster-/Unitlookup. Ein getrenntes Frontier-Backdrop ersetzt sichtbar den alten Pixelhintergrund, ohne dessen historischen Katalogsnapshot umzudeuten. Neutrale Ergebniswerte stehen auf dunklen Karten; semantische AAR-Füllungen bleiben lesbar.
- Die Mission besitzt eine zusammenhängende deckende Petrolfläche unter den zwei bestehenden 64px-Befehlsreihen. Team-Portraits stehen direkt unter dem Teamheader und sind in den vorhandenen Karten größer sichtbar. Titel und echte vorhandene Ziel-/Schiffssymbole bekommen mehr Gewicht.
- Schrift, Labels und Eingabe bleiben native Controls. Kein Bild enthält als Implementierung verwendete UI-Texte. Auswahl/Fokus/Hover, Pending/Bestätigt, Vorschau/angewandte Folgen und fehlende Werte bleiben getrennt.

## Bild-KI-Beitrag
Vier getrennte integrierte Bildgenerator-Aufrufe erhielten jeweils finale 2D-Vorlage, tatsächlichen R3-Screenshot und kuratierten Main-Render. Bilder und exakte Prompts liegen unter `docs/ui_concepts/ui_20261102_r4/`. [Beobachtung, Designbegründung und Übergabe](../../ui_concepts/ui_20261102_r4/BILDPRUEFUNG_UND_UEBERGABE.md) erklären, was übernommen wurde und was nicht.

Interne Modellgedanken sind nicht verfügbar. Die ausdrücklich angeforderten drei Designerhinweise im Bildfuß beschreiben sichtbare Entscheidungen. Umgezeichnete Gesichter, aktiv gezeichnete gesperrte Buttons und das Außenpostenbild als vermeintliches Spielfeld werden nicht als Daten-/Funktionsautorität übernommen.

## Main und reguläres Gelände ehrlich unterscheiden
R4 baut auf R3 `5500bcbe2` auf und führt den geprüften Main `7f594530f` ausschließlich im eigenen UI-Branch zusammen (Merge `98e3ba7b0`, gemeinsamer Vorfahr `3cae5a216`). Produktiv überschnitt sich nur der Mapeditor: Main-Gridtopologie und UI-Theme liegen in getrennten Bereichen. Im Statusdokument wurden beide Historien erhalten. Der Integrationsbranch war bereits in einem anderen Worktree ausgecheckt; der neue Taskbranch wurde deshalb ausdrücklich direkt von R3 erstellt.

Main enthält den kuratierten Außenpostenrender, gespeichertes `frontier_illustrated_v1` in GM01 und Ref03-Schiffe. **Die tatsächliche reguläre GM01 bleibt trotzdem eine gemischte Stations-/Rasteransicht mit Square8.** Eine vollständige Außenposten-/Hexmigration oder ein kaputter Dispatch ist damit nicht nachgewiesen. Die separate Hex-Werft und die dekorative kuratierte Bühne sind keine reguläre Missionsszene.

Der zusätzliche native Normalstart verwendet die bestehenden realen Menü-/Homebase-Commands, gespeicherte GM01, echte Transfer-/Anflugzeiten, normale LZ-/Drop-/Move-/GO-Handler und echte Runtimeobjekte. Die dünne Capture-Unterklasse stellt nur physische und logische Auflösung ein. Keine Teleports, Zeitbeschleunigung, erzwungene Entladung oder privaten Simulationsschreibzugriffe. Die abschließenden Läufe verwenden ein eigenes Userdatenverzeichnis, das vor der normalen Menüinitialisierung geprüft wird. Nur dieser Speicherpfad wird in der Testkonfiguration gesetzt; project.godot wird danach bytegenau wiederhergestellt. Ausgangs-/Endidentität des jeweiligen vorhandenen Testprofils prüft der bestehende Smoke. Frühere verworfene Läufe verwendeten das normale Profil; dessen Identitäten blieben erhalten, normale Speichervorgänge veränderten die Dateibytes.

## Nachweis und Grenzen
Abschlusszahlen und letzte akzeptierte Einzelruns stehen in `VERIFIKATION.json`. Es gelten nur richtige Endmarker, positiver Assertioncount, Exit0 und keine Script-/Godot-/Leakfehler. Ältere RED-Läufe bleiben erhalten. Nach der finalen typografischen Änderung wurden die betroffenen Checks wiederholt; tatsächliche nachfolgende Regressionen wurden gezielt geschlossen.

15 GL-Compatibility-Fixturebilder zeigen vier Screenfamilien, echte 1280×720-Reflows und Empty/Rich/Partial-/Portrait-/Belegungsvarianten. Zwei zusätzliche native Vulkanbilder stammen aus dem normalen GM01-/Transport-/GO-Ablauf. Zusammen sind es 17 Ansichten, davon sechs mit echter logischer und physischer 1280×720-Größe. Testfixtures sind keine behaupteten tatsächlich abgeschlossenen Missionen; der normale Startsmoke ist kein vollständiger Kampagnen-/Combat-/Langzeitnachweis.

Der Editorimport erhielt GDExtensions, deaktivierte vorübergehend nur Editorplugins und stellte `project.godot` bytegenau wieder her. Die aus bereits in Main enthaltenen GLBs erzeugten Importbegleiter/Materialtexturen werden nachvollziehbar mitgesichert; sie sind keine neu ausgewählten Schiffsmodelle.

Die lokale NodeVM-Prüfung führt das tatsächliche Inline-JavaScript aus: alle 17 Ansichten und vier getrennten Brückenbewertungen, ausgeblendete Notizen, Modal-/Tab-/Fokuslogik, Unicode, Download/Clipboard-Fallback und alle lokalen Assetpfade. Sie ersetzt keine Browserlayout-/reale Downloadabnahme. Die vorhandene file-Protokollgrenze wurde nicht umgangen.

Die unabhängige Source-/Bildprüfung und bestätigte Ursachen stehen in `REVIEW.md`. Technischer Erfolg ist keine neue Nutzerfreigabe der Stilnähe. Restabstände: bestehende Pixelportraits gegenüber großen Illustrationsportraits, dynamische native Kartenkomposition und gemischte GM01 gegenüber gemalter Außenpostenreferenz. Keine Mainintegration des UI, kein Release/EXE, keine echte Peerpartie, kein vollständiger menschlicher Durchspieltest.

## Reproduzieren
```powershell
python docs/qa/ui_native_r4_20261102/import_once.py
python C:/Users/bjoer/.codex/skills/godot-game-verification/scripts/run_checks.py --project . --manifest docs/qa/ui_native_r4_20261102/checks_final.json --godot godot_console --skip-import --output docs/qa/ui_native_r4_20261102/checks_repro
python docs/qa/ui_native_r4_20261102/capture_r4.py
python docs/qa/ui_native_r4_20261102/startup_r4.py
node docs/qa/ui_native_r4_20261102/html_qa.cjs
python docs/qa/ui_native_r4_20261102/verify_r4.py
```

Offline-Abschlussprüfung:12/12 Checks, 17 native Ansichten, 4 getrennte Bild-KI-Vorschläge und 70 vollständige Exportfelder.

## Cutlass: explizite Nutzerpräzisierung umgesetzt
Das erste Spielerdropship ist die bekannte aktive Cutlass. Das neue transparente Preview ist ein nativer Render aus genau dem bereits integrierten Ref03-GLB (SHA21484195…), ohne andere Geometrie oder Materialoverrides. Der bestehende Visualkatalog verbindet Rolle, Preview und HerkunftsJSON. Heimatbasis/FOB/alle drei Missionskartenpfade zeigen diese Silhouette und Klassenbezeichnung; gespeichert benannte Schiffe/Craft-IDs/Typen und Welt-Richtungssprites bleiben erhalten.

Der gezielte Identitätsverifier bestand33/33 und prüft tatsächliche erste Spielerfactory, transparente PNG-/GLB-Herkunft, richtige Modelle/Fremdtypen, Customnamen und reale Screengetter. Die Homebase-Konstruktion wählt 94×62 vor dem ersten Größenwrite, damit kein alter Speeder-Crop die vier Triebwerke abschneidet. Die neue kleine Protokollfläche hält den Transportstatus in 1280 frei. Endgültiger Abschluss:26/26 gezielte Checks mit 2.266 Assertions,90 normale native Startprüfungen, 17 ausgewählte native Ansichten und 12/12 Offline-HTML-Prüfungen. Native Cutlass-Modellvorschau ist ein zusätzlicher eigener Beleg, keine weitere Spielszene.
