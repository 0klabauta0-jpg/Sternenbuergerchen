# UI-Konzept und Bildgenerator-Icons · 01.11.2026

## Ziel / Problem
Vorhandene Oberflächen und Funktionen sichten, visuelle Alternativen im aktuellen SternenBürgerchen-Stil erstellen und eine nachvollziehbare Übergabe für die spätere Godot-Umsetzung liefern. Der neueste Nutzerauftrag erweitert dies ausdrücklich auf alle vorhandenen Menüs, Detailtafeln und kleinen Charakterkarten sowie zwei echte Reihen kompakter Missionsbuttons.

## Grundlage / Ursache
Der Nutzer beauftragt ausdrücklich Entwürfe, Icons mit dem Bildgenerator und die Erklärung der Gestaltungsentscheidungen. Bestehende UI-Vorschläge und der laufende Grafikpass dienen als Quellen. Wiederverwendete Befehlssymbole und sehr kleine Theme-Schriften sind konkrete Ansatzpunkte aus dem Code; ihre Wirkung ist noch nicht mit Spielern geprüft.

## Umfang und Nicht-Ziele
- Funktionsinventar, Alternativen, generierte Rasterentwürfe und sechs separate Icon-Kandidaten.
- Lokale interaktive Review-Workbench und schriftliche Übergabe einschließlich exakter Prompts, Herkunft und Prüfgrenzen.
- Erweiterung A5: elf Bildtafeln für Mission, Hauptmenü, Heimatbasis, FOB/Loadout, Charakterkarten/lesenden Bogen, Detailkarten, Debrief, Lobby, Settings/Hilfe/Escape, Editor und einen getrennten bearbeitbaren Teameditor. Gestaltungsgründe und Quellumfang in `docs/ui_concepts/ui_20261101/MENUES_UND_KARTEN.md`.
- Keine Änderung an Runtime, Input, Regeln, Szenen oder aktiven Assets; keine Integration des parallelen Grafikpasses.

## Relevante Quellen
AGENTS.md; docs/PROJECT_BRIEF.md; docs/ARCHITECTURE.md; docs/CODEX_RULES.md; docs/IMPLEMENTATION_STATUS.md; docs/TASK_ROADMAP.md; docs/dev/ui_theme_component_library.md; docs/dev/html_report_workbench_contract.md; docs/ui_concepts/better_ui/README.md.

## Akzeptanzkriterien
- Vorhandene Funktionen und Vorschläge sind getrennt und mit Quellpfaden erfasst.
- Mindestens zwei vergleichbare Missionsrichtungen und ein Staging-Entwurf sind sichtbar.
- Icons liegen als separate PNG-Kandidaten vor; Transparenz, Größe und sichtbare Semantik sind geprüft.
- Begründungen, Zustände, Implementierungsanschlüsse und offene Prüfungen sind dokumentiert.
- Workbench funktioniert lokal und exportiert Entscheidungen/Notizen als JSON.

## Betroffene Dateien
docs/ui_concepts/ui_20261101/; docs/reports/STERNENBUERGERCHEN_UI_2026-11-01.html; docs/reports/assets/ui-2026-11-01/; diese Task-Datei; eine knappe Ergänzung in docs/IMPLEMENTATION_STATUS.md.

## Lokale Prüfung
Sichtprüfung der erzeugten PNGs; Metadaten-/Alpha-/Dateiverweisprüfung; Workbench im Browser einschließlich Variantenwahl und JSON-Export; git diff --check. Keine Godot-Laufzeitfreigabe durch diesen Konzepttask.

## Risiken / offene Punkte
Generierte Schrift und Layout sind Illustrationen. Texte, Controls, Zustände und Fokus müssen später nativ umgesetzt werden. Integration-Basis: 3cae5a216; der parallele Grafikbranch bleibt eine separat benannte Stilquelle. Nutzer hat SternenBürgerchen bestätigt.

## Historische Revision A2 · Nutzerfeedback vom 01.11.2026

Die horizontale Buttongeometrie dieses Abschnitts dokumentiert A2. Für den aktuellen Bildauftrag gilt die nachfolgende Revision A3 mit quadratischen Buttons.

Quelle: Export `C:/Users/bjoer/Downloads/sternenbuergerchen_ui_20261101_2026-11-01T14-47-55-564Z_01.json`, archiviert unter `docs/ui_concepts/ui_20261101/review_export_20261101_154755.json`, ergänzt um die mündliche Rückmeldung im Chat. Der vorhandene Konzeptbranch wird für diese angeforderte Revision weitergeführt.

- Mission A ist gewählt; C soll als Staging-Grundlage weiterentwickelt werden. Die zuletzt angezeigte Vorschau C ist keine Missionspräferenz.
- Bewegen, Verteidigen, Nehmen und Ausrüstung sind zur Weiterentwicklung geeignet. Flankieren und Dropship sind semantisch unklar und erhalten alternative Kandidaten.
- A2 erhält die linke Teamübersicht und die obere rechte Transport-/Dropdown-/Planungsfläche; die großen unteren Buttons werden kompakter. Der Spieltitel oben links entfällt.
- Neue Zielgeometrie bei 1920×1080: Aktionsbuttons 40–44px hoch, Icons 18–22px neben lesbaren Labels; gesamtes unteres Dock 112–128px hoch einschließlich schmaler Selected-Team-Kopfzeile. Keine große Zielerklärung.
- Platz durch geringere Flächen und klarere Gruppen gewinnen, ohne Schrift zu verkleinern. Freiraum für spätere Planung/Aktionen vorsehen, aber keine erfundenen aktiven Controls einzeichnen.
- Original A, B und C bleiben erhalten. Neuer Rasterkandidat: `docs/reports/assets/ui-2026-11-01/mockup_a2_kommandodeck_kompakt.png`.

### Akzeptanz der Revision

- A2 und ursprüngliches A sind getrennt vergleichbar; Änderungen und bewusst erhaltene Bereiche sind nachvollziehbar erklärt.
- Die kompakte Geometrie wird als Gestaltungsziel dokumentiert und nach Bilderzeugung sichtbar beurteilt; ein Rasterbild ist kein pixelgenauer Godot-Nachweis.
- Alternativen für Flanken-/Dropship-Motive sind separat prüfbar, ohne die vier positiv bewerteten Motive ungefragt zu ersetzen.
- Der Export bleibt unverändert archiviert. Alle fünf Sichtprüfungs-Checkboxen waren unmarkiert; keine technische oder native Freigabe daraus ableiten.
- Keine Runtime-, Input-, Gameplay-, Szenen- oder aktiven Assetänderungen. GO bleibt Planausführung und keine Pause.

## Historische Revision A3 · Randband und quadratische Buttons

Die Randverankerung bleibt für A4 bestehen. A3s außerhalb liegende Labels und die bisherige Blockanordnung werden durch die nachfolgende Rückmeldung ersetzt.

Die neueste Rückmeldung präzisiert denselben Konzeptauftrag: Das Befehlsband liegt bündig am absoluten unteren Bildrand, beginnt an der linken unteren Ecke und läuft kompakt nach rechts. Die Teamkarten wandern nach oben; das Band beginnt darunter. Das Log wandert ebenfalls nach oben über das Band.

- Wieder kompakte **quadratische Buttons**. Die 40–44px hohen horizontalen A2-Buttons sind damit keine aktuelle Vorgabe mehr.
- Assistentenentwurf, keine wörtliche Nutzermaßangabe: bei 1920×1080 Quadrate 56–64px mit Icons 24–28px; lesbare Beschriftungen unter den Quadraten separat anordnen.
- Eine Aktionsreihe in der Reihenfolge **Bewegen → Nehmen → Verteidigen → Flankieren → Plan ausführen**, dazu eine schmale Team-/Kontextzeile. „Plan ausführen“ steht als gleichwertiges Quadrat direkt rechts von „Flankieren“; das ist die gewählte Entwurfsanordnung.
- Haltung und Feuerregeln als bestehende kompakte Gruppen rechts anschließen. Keine zusätzlichen aktiven Funktionen erfinden.
- Teamkarten mit Abstand oberhalb des Bands; keine überdeckten Karten oder Weltspalte links neben dem Band. Kein dekorativer Freiraum unterhalb der Bandfläche.
- Dropship oben rechts und Missions-/Zielkasten im oberen rechten Mittelbereich bleiben. Dropship/LZ wird maßvoll kleiner; die Haltung „Normal“ aus A2 bleibt erhalten.
- Ein neuer Bildkandidat aus A2: `docs/reports/assets/ui-2026-11-01/mockup_a3_randband_quadratisch.png`. A und A2 bleiben erhalten. Die sechs aktuellen Galerie-Icons werden in dieser Revision nicht neu gestaltet.

### Akzeptanz A3

- Linke Bandkante berührt x=0, untere Bandkante den tatsächlichen letzten Bildrand; keinen gerenderten Außenabstand als Teil der Vorgabe übernehmen.
- Vier Befehle und „Plan ausführen“ sind als gleich große Quadrate erkennbar; Labels bleiben ohne Schriftverkleinerung lesbar und eindeutig zugeordnet.
- Teamkarten und Log sind vollständig über dem Band; obere rechte Bereiche bleiben vorhanden und Dropship/LZ wird nur behutsam verdichtet.
- Gestaltungsziel und tatsächliches Bildergebnis werden getrennt dokumentiert. Für andere Ausgabegrößen gilt die Randverankerung relativ zur echten Bildhöhe, keine feste A2-Pixelkoordinate.
- Kein Runtime-/Input-/Gameplay- oder Assetintegrationsauftrag; GO bleibt Planausführung, Echtzeit bleibt ohne Pause.

## Historische Revision A4 · Innenbeschriftung und drei kompakte Blöcke

Innenbeschriftung und die Drei-Block-Anordnung bleiben für A5 erhalten. Die nur freie Reserve für eine zweite Reihe wird durch zwei tatsächlich belegte Reihen ersetzt.

Neuester Nutzerwunsch: Buttons unten links noch kompakter und enger; **Text innerhalb der Buttons**, damit später eine zweite Reihe Platz hat. Unter dem Alpha-/Bereit-Header stehen Haltung und Feuerregel; die Gruppe rückt nach links. „Ziel gewählt / Auftrag: Bewegen“ liegt zwischen Aktionsblock und Alpha-/Haltungsblock. Die bereits mitgeteilte Auslegung lautet von links nach rechts **Aktionen → Ziel/Auftrag → Alpha + Haltung + Feuerregel**; sie ist eine konkrete Layoutausarbeitung, keine zusätzliche Gameplay-Funktion.

- Assistentenziel, keine exakte Nutzermaßangabe: fünf kompakte quadratische Bildkörper um 60px mit 4–6px Abstand; Icon oben und kurzes lesbares Label im selben Button. „Plan ausführen“ bei Bedarf zweizeilig im Button.
- Reihenfolge der fünf Aktionen bleibt Bewegen, Nehmen, Verteidigen, Flankieren, Plan ausführen. Die frühere Außenbeschriftung aus A3 gilt nicht mehr.
- Ziel/Auftrag als schmaler Mittelblock, danach eine dezente Trennung und der kompakte Alpha-Header mit Haltung/Feuerregel darunter. Keine neue Zielaktion und keine zusätzliche Bestätigung erfinden.
- Unter der ersten Aktionsreihe bleibt freie Layoutreserve für eine spätere zweite Reihe; keine neuen aktiven oder angedeuteten Platzhalterbuttons. Bandhöhe dafür nicht vergrößern.
- Bündige untere/ linke Bandkante bleibt. Welt, Teamkarten, Log, obere rechte Bereiche und aktuelle sechs Iconmotive bleiben gegenüber A3 unverändert.
- Ein neuer Kandidat aus A3: `docs/reports/assets/ui-2026-11-01/mockup_a4_band_bloecke_kompakt.png`; vorherige Bilder bleiben erhalten.

### Akzeptanz A4

- Beschriftungen liegen sichtbar innerhalb aller fünf Buttons; die erste Reihe wirkt dichter, ohne Schrift zur Platzrettung zu verkleinern.
- Drei Blöcke sind eindeutig in der Reihenfolge Aktionen → Ziel/Auftrag → Team/Haltung/Feuerregel erkennbar. Haltung und Feuerregel liegen unter dem Alpha-Header.
- Platzreserve ist leer, Bandhöhe und übrige Bildbereiche bleiben gegenüber A3 erhalten. Tatsächliche Abweichungen werden im Bildprüfbericht benannt.
- Unverändert Konzeptrevision ohne Runtime-, Input-, Gameplay- oder aktive Assetänderungen.

## Aktuelle Erweiterung A5 · alle Menüs und zwei echte Befehlsreihen

Der Nutzer verlangt weitere Bild-KI-Vorschläge für sämtliche bestehenden Menüs, Details und kompakte Charakterkarten im etablierten Stil, mit verständlicher Erklärung in der vollständigen HTML-Review. Die Bildbegründung dokumentiert unsere Absicht und später die sichtbare Auslegung; sie behauptet keine internen Gedanken des Generators.

- A5: Reihe 1 Bewegen/Nehmen/Verteidigen/Flankieren/Plan ausführen; Reihe 2 Ziel/Leeren/Löschen/Ordnen, fünfte Position leer ohne Ghost-Control. Dies sind vorhandene Actions laut `mission_command_hierarchy_contract.gd:81–113`, keine neuen Gameplay-Funktionen.
- Assistentenziel für die 1672px breite Bildvorlage: Buttonkörper etwa 50–52px, Abstand etwa 4px, zwei Reihen in der bisherigen etwa 127px-Bandhöhe. Lesbare Innenbeschriftung, Bündigkeit und Aktionen → Ziel/Auftrag → Team/Haltung/Feuerregel bleiben.
- Neun weitere Menü-/Kartentafeln plus separater Teameditor ergeben zusammen mit A5 elf neue Bilder; genaue Dateizuordnung im Menüguide. Vorherige Bildfassungen bleiben erhalten.
- Lesender Charakterbogen in Basis/FOB und kompakte Personenauswahl bleiben vom editierbaren Creator mit Budgets/Locks getrennt. Keine individuelle NPC-Bewegungssteuerung in der Mission.
- Erneuter Audit korrigiert alte Kataloggrenzen: sechs kanonische Waffen plus kontextabhängig None; Rifle/Engineer/Scout sind belegt. Rollen-Fits bestätigen keine zukünftigen Actions; Settings-Eingaben sind Übersicht ohne Rebinding.

### Akzeptanz A5 und Menüpaket

- Alle elf Tafeln sind in der HTML-Review zugeordnet; pro Tafel sind Zweck, Aufbau, relevante Zustände, Quellen und Grenzen nachvollziehbar erklärt.
- Zweite A5-Reihe enthält echte bestehende Aktionen; kein Zukunfts-/Statusfeld wird als aktiver Befehl gezeichnet. Tatsächliche Größen-/Layoutabweichungen werden getrennt von den Maßzielen bewertet.
- Kompaktkarte, lesender Detailbogen und bearbeitbarer Creator sind sichtbar verschieden. Leere/gesperrte/Transit-/Fehlerzustände und autoritative Grenzen bleiben dokumentiert.
- Exakte Prompts, Herkunft und tatsächliche Bildprüfung werden ergänzt; keine Runtime-Freigabe und kein Ersatz nativer Controls durch Komplettscreen-Raster.

### Dateien und lokale Prüfung der Erweiterung

- Bestehende Review-HTML und Status/Übergabe/Feedback fortgeschrieben; neue `MENUES_UND_KARTEN.md`, `BILDPRUEFUNG_REVISION5.md`, `prompts_revision5*.json`, `EXPORT_PRUEFUNG_REVISION5.json`; Manifest/Asset-/Paketprüfung aktualisiert.
- Elf neue Vorschläge plus fünf gezielte Korrekturen; erste Versuche separat erhalten. Keine Szenen, Runtime-Skripte oder Spielregeln ändern.
- Prüfen: tatsächliche Bildsichtung, lokale Links, PNG-/Quellenhashes, JavaScript-Syntax, fünf Missionsstände und zehn Menü-/Exportzustände offline. Bestehende Browserblockade nicht umgehen; Browser-/Godot-Prüfung offen halten.
- Restabweichungen ausdrücklich dokumentieren, insbesondere Kontur der leeren Rasterzelle, generierte Zuordnungs-/Kapazitätsbeispiele, Medictool-Glyph, FTL-Stern und numerischer Deckungswert. Bilder sind keine Nutzerabnahme.
