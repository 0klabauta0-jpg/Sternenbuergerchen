# SternenBürgerchen: UI-Entwürfe und Übergabe

Stand: 01.11.2026. Auftrag: bestehende Funktionen ansehen, visuelle Alternativen und Bildgenerator-Icons entwickeln und die Gestaltung für den nächsten Chat nachvollziehbar machen.

**Status: Konzeptpaket, keine Runtime-Integration und keine allgemeine Spielabnahme.** Die erzeugten Bilder sind Kandidaten. In Bildern gezeichnete Zahlen, Karten, Figuren und Beschriftungen sind illustrative Beispiele, keine neuen Spielregeln.

- Review: [UI-Workbench](../../reports/STERNENBUERGERCHEN_UI_2026-11-01.html).
- Exakte Bildgenerator-Eingaben: [prompts.json](prompts.json).
- Exakte Eingaben der kompakten Revision: [prompts_revision2.json](prompts_revision2.json).
- Exakter Bearbeitungsauftrag A3: [prompts_revision3.json](prompts_revision3.json).
- Sichtbare Bildauslegung und Prüfergebnisse: [PRUEFUNG.md](PRUEFUNG.md).
- Task und Prüfumfang: [TASK_UI_KONZEPT_20261101](../../tasks/TASK_UI_KONZEPT_20261101.md).
- Arbeitsbasis: `integration/core-foundation`, Commit `3cae5a216`.
- Konzeptbranch: `task/ui-entwuerfe-20261101`.
- Lokale Konzeptkopie: `C:/Users/bjoer/.codex/worktrees/ui-entwuerfe-20261101/SternenBuergerchen`.
- Der Grafikpass im separaten Worktree `grafikreferenzen-20261101` ist Stilquelle, kein Bestandteil dieser Integration.
- Nutzerfeedback und Revisionsauftrag: [FEEDBACK_20261101.md](FEEDBACK_20261101.md); unveränderter [Review-Export](review_export_20261101_154755.json).

## 1. Gewählte Richtung und erhaltene Alternativen

**Nutzerentscheidung vom 01.11.2026: A für die Mission weiterentwickeln, C als Staging-Grundlage weiterführen. Aktueller Auftrag ist A3:** quadratische kompakte Buttons in einem unten links bündig beginnenden Randband; Teamkarten und Log darüber. A2 dokumentiert den vorherigen Versuch mit horizontalen Buttons. Die Auswahl bleibt eine Konzeptentscheidung, keine Runtime-Freigabe. B, ursprüngliches A und A2 bleiben als Vorgeschichte erhalten.

| Richtung | Schwerpunkt | Gewinn | Zielkonflikt |
|---|---|---|---|
| A – Kommandodeck | Dunkles taktisches Dock, Karte als Hauptfläche | Ruhige Karte; Auswahl, Plan und Ausführung eng beieinander | Dunkle Flächen brauchen klare Helligkeitsabstände und ausreichend große Schrift |
| B – Feldtablet | Helle Instrumentenflächen für dieselbe Missionssituation | Starker Textkontrast, freundlicher Anschluss an die illustrierte Welt | Große helle Flächen können den Blick von Karte und Markern abziehen |
| C – Einsatztafel | Team-/Loadout-/Flightdeck-Vorbereitung | Vorbereitung wird als geordneter Weg sichtbar; Transport bleibt zugeordnet | Eine zu große Hangarillustration könnte relevante Personen und Sperren verdrängen |

A und B wurden mit derselben Beispielmission, ALPHA 4/4 und einem geplanten Bewegungsauftrag angefordert. Tatsächlich variiert der Bildgenerator Kamera, Gelände, Portraits und ausgewählte Haltung. Die Bilder erlauben deshalb einen Vergleich der visuellen Richtung, keinen kontrollierten Vergleich von Kartenfläche oder Bediengeschwindigkeit. Für einen späteren Laufzeittest denselben echten Spielstand, Kameraausschnitt und Zustand verwenden.

C zeigt eine Staging-Richtung. Heimatbasis und FOB bleiben getrennte Zustände: Heimatbasis stellt Personal und Flugmittel bereit; FOB organisiert Fireteams, Loadout, Respawn und Boarding. Der Entwurf soll sie gestalterisch verbinden, nicht fachlich zusammenlegen.

### A2 – historischer Versuch mit horizontalen Buttons

Neuer Bildkandidat: [mockup_a2_kommandodeck_kompakt.png](../../reports/assets/ui-2026-11-01/mockup_a2_kommandodeck_kompakt.png). Das ursprüngliche A wird nicht überschrieben. Die linke Teamübersicht und die obere rechte Transport-/Dropdown-/Planungsfläche sind ausdrücklich positiv bewertet und bleiben als Aufbau erhalten. Der Spieltitel oben links entfällt.

Ziel bei 1920×1080: Aktionsbuttons 40–44px hoch, 18–22px-Icon neben lesbarem Label; das gesamte untere Dock einschließlich einer schmalen Selected-Team-Kopfzeile 112–128px hoch. Keine großen Befehlskacheln, kein ausgedehnter Zielerklärungsblock. Durch kompakte Flächen, Abstände und Gruppen Platz gewinnen, nicht durch kleinere Schrift. Die Rasterillustration muss diese Richtung zeigen; verbindliche Pixelgeometrie ist später nativ zu prüfen.

Planung und spätere Aktionen benötigen freien Raum. Deshalb Reserven im Layout lassen, ohne dafür neue oder nur vorgestellte aktive Controls zu erfinden. Bestehende Plan-/Command-Verträge bleiben maßgeblich. A2 darf GO nicht in einen Pause-/Fortsetzen-Knopf umdeuten.

Bewegen, Verteidigen, Nehmen und Ausrüstung wurden als Grundlage positiv bewertet. Flankieren und Dropship wurden als unklar bewertet; neue separate Motivvarianten sollen deren Bedeutung vereinfachen. Vorhandene Kandidaten und Entscheidungen erhalten, neue Varianten anhand der Manifest-Einträge zuordnen. Keine automatische Übernahme in aktive Assets.

### A3 – aktueller Auftrag: quadratisches Randband

Bildkandidat: [mockup_a3_randband_quadratisch.png](../../reports/assets/ui-2026-11-01/mockup_a3_randband_quadratisch.png), als neue Revision aus A2. Der Nutzer will das Befehlsband **direkt an der absoluten unteren Bildkante, beginnend an der linken unteren Ecke**, kompakt nach rechts laufend. Es darf weder unterhalb noch links daneben einen dekorativen Außenabstand geben. Teamkarten werden nach oben versetzt, das Band beginnt darunter; das Log liegt ebenfalls oberhalb des Bands.

Quadratische kompakte Buttons sind wieder ausdrücklich gewünscht. Unser Gestaltungsziel bei 1920×1080: 56–64px-Quadrate, 24–28px-Icons und lesbare, separat unter den Quadraten angeordnete Labels. Diese Maße sind eine Assistentenentscheidung, keine wörtliche Nutzerforderung. Eine Aktionsreihe plus schmale Team-/Kontextzeile hält die Bandhöhe begrenzt; Schrift wird nicht verkleinert, um Flächenmängel zu kaschieren.

Reihenfolge: **Bewegen → Nehmen → Verteidigen → Flankieren → Plan ausführen**. Das letzte Quadrat direkt rechts der Flanke ist die gewählte Entwurfsanordnung; es bleibt dieselbe GO-Planausführung. Haltung und Feuerregeln schließen rechts als kompakte bestehende Gruppen an. Freiraum bleibt frei, statt erfundene aktive Funktionen darzustellen.

Dropship oben rechts und der Missions-/Zielkasten im oberen rechten Mittelbereich bleiben erhalten. Dropship/LZ wird maßvoll kleiner. Die linke Teamübersicht behält ihren Inhalt, aber ausdrücklich nicht ihre alte vertikale Position. Zwischen Karten, Log und Band bleibt Abstand; keine Überdeckung. „Normal“ aus A2 bleibt als illustrativer Haltungszustand erhalten. Kein neuer Spieltitel oben links und kein neuer Iconpass: Die sechs aktuellen Galerie-Motive bleiben unverändert.

Für die Umsetzung gilt die echte Viewportkante als Bezug. A2 ist 1672×941px groß; dessen letzte Bildzeile ist kein festes y-Ziel für ein 1920×1080-Layout. Tatsächliche A3-Abweichungen erst nach Sichtprüfung unter [PRUEFUNG.md](PRUEFUNG.md) bewerten.

## 2. Was vom früheren UI-Konzept erhalten bleibt

Quelle: [Better UI README](../better_ui/README.md), [getrennte Screens](../better_ui/separated_screens.html), [Mischvorschläge](../better_ui/index.html).

- „Tactical Dock“: Karte führt; `#16 COMMAND MATRIX` bündelt den Bedienweg, `#17 SELECTED FIRETEAM` zeigt Kontext, `#18 MISSION CONTROL` Transport und LZ.
- „Operator Cards“: Transfer, Deck, Boarding und Recovery direkt an der betroffenen Personen-/Schiffkarte nachvollziehen.
- „Dense Loadout Drawer“: stabile Slotgrößen und kleine, erkennbare Waffenbilder. Keine erfundenen Waffen hinzufügen.
- „Hangar Ops Board“: Flightdeck als UI-Bühne, nicht als zusätzlicher begehbarer Spielraum.
- Die früheren Homebase-/FOB-Iterationen enthalten bewusst gesetzte Kenney-Pads, Schiffbilder und Boarding-Stapel. Sie bleiben als Vorgeschichte erhalten.
- Feste Panelgrößen pro Ansicht, stabile Buttonhöhen und begrenzte variable Inhaltsbereiche bleiben sinnvoll. Das ist kein Auftrag, lange wichtige Texte unzugänglich abzuschneiden.
- Eine kleine Windrose für den Anflug ist ein Entwurf; ihre Richtungen müssen dem aktuellen Eingabevertrag entsprechen.

Die Kennbuchstaben A/B/C dieses Pakets sind neue Varianten. Sie sind nicht identisch mit den A/B/C/D-Abschnitten des älteren README.

## 3. Bestandsaufnahme: Funktionen vor neuer Dekoration

Die folgenden Angaben sind aus den aktuellen Quellen der Integration-Basis ableitbar. Sie ersetzen keinen frisch durchgespielten UI-Klicktest. Zeilennummern beziehen sich auf die gelesene Basis und können nach Folgeänderungen wandern.

| Oberfläche | Vorhandener Funktionsumfang | Einstieg im Repository |
|---|---|---|
| Hauptmenü | Einzelspieler, Multiplayer, Editor, Einstellungen; Teamname, Team-Bibliothek, Roster und Teameditor | `scripts/ui/main_menu_screen.gd:3`, `:82`, `:103` |
| Heimatbasis | Mission, verfügbare Kräfte, Transferteam, Flugdeck, Piloten, Charakterbogen | `scenes/meta/homebase_test_screen.tscn:103`, `:143`, `:191`, `:297`, `:389` |
| FOB | NPC-Pool, Fireteams, Leader, Rüstung und Waffen, Loadout/Gewicht, Respawn, Boarding | `scripts/meta/fob_screen.gd:1246`, `:1253`, `:1793`, `:1879` |
| Taktik | Auswahl, Ziele/Orders, Halten/Bewegen/Nehmen/Flanke, Haltung, Feuerregeln, GO, LZ/Dropship | `scripts/ui/mission_command_hierarchy_contract.gd:77`; `scripts/tests/mission_tactical_sandbox_controller.gd:184` |
| Mission Control | LZ, Anflug, Transportstatus, ETA und Ausstiegsfortschritt | `scripts/ui/mission_control_state_presenter.gd:5`, `:48`, `:60` |
| Nachbesprechung | Ergebnis, Teamzustand, Verluste, FTL-Rückmeldung, AAR, Personen-/Skillfolgen | `scripts/meta/debrief_screen.gd:423`, `:788`, `:932`, `:961` |
| Multiplayer | Host/Join, Verbindung, Team/Roster/Map, Bereitschaft, Kartenannahme, Start | `scripts/ui/multiplayer_lobby_screen.gd:614`, `:640`, `:652`, `:690`, `:908` |
| Einstellungen/Hilfe | Auflösung/Fenstermodus/VSync, Audio, FoW, Eingabeübersicht, kontextuelle Hilfe und Sprechblasen | `scripts/ui/game_settings_contract.gd:11`, `:30`, `:171`; `scripts/ui/main_menu_screen.gd:59` |
| Editor | Auswahl, Pinsel/Radierer, Höhe, Marker/Pfade, Rotation, Scale, Palette, Save As | `scripts/editor/map_editor.gd:1085`, `:1363`, `:1551`, `:2414`, `:2468`, `:2529` |

Der Action-Katalog enthält auch `status_only`, `future_task`, versteckte und nicht implementierte Einträge. Diese dürfen in einem schönen Mockup nicht plötzlich als verfügbare Hauptaktionen erscheinen. Besonders Recon, Withdraw, zusätzliche Air-Befehle und Breakout-Controls vor Übernahme im aktuellen Contract prüfen.

### Drei besonders belastbare Ansatzpunkte

1. **Mehrdeutige Icons:** `mission_tactical_sandbox_controller.gd:184–195` verwendet `target_marker.png` unter anderem für vorsichtige Haltung, Halten, Ziel und Feuer halten. `sword_attack.png` steht unter anderem für aggressiv, Nehmen und Feuer frei. Neue Silhouetten können diese Bedeutungen trennen.
2. **Kleine Theme-Schriften:** `scripts/ui/tactical_ui_theme.gd:75`, `:78`, `:111` setzt 9px-Badges/Buttons und 10px-Standardlabels. `scripts/meta/meta_ui_skin.gd:71` nutzt 10px-Körpertext. Das begründet eine Lesbarkeitsprüfung, nicht die Behauptung eines bereits beobachteten Nutzungsfehlers.
3. **Bestehender Planvertrag:** `mission_tactical_sandbox_controller.gd:10675–10676` beschreibt GO als Ausführen geplanter Orders. Der Action-Katalog verlangt bei mehreren Befehlen auch eine Tile-Auswahl. Das neue UI muss diese Voraussetzungen sichtbar machen.

## 4. Stil: Anschluss an Spielwelt und Kenney-Bestand

Die aktuelle Runtime nutzt dunkle, matte Paneele mit heller Schrift, Cyan, Ocker, Grün und gedämpftem Rot. Quellen: `scripts/ui/tactical_ui_theme.gd:4–16`, `scripts/meta/meta_ui_skin.gd:4–25`.

Die neue Richtung übernimmt klare, kompakte Formen und die robuste Materialanmutung der Space-Station-/Factory-Welt: ruhige Metallflächen, abgerundete Ecken, wenige funktionale Farbakzente, gut erkennbare Gegenstände. Nieten und Gebrauchsspuren gehören sparsam an große Illustrationen; sie sollen keine Texte und Konturen überlagern.

Der parallele Grafikbericht liegt in `C:/Users/bjoer/.codex/worktrees/grafikreferenzen-20261101/SternenBuergerchen/docs/reports/STERNENBUERGERCHEN_GRAFIK_2026-11-01.html`. Dessen Grafik-/Hex-Stand ist getrennt von der hiesigen UI-Basis zu behandeln. Kein neuer Hex-, Gebäude- oder Figurenumfang wird dadurch beauftragt.

Vorhandene Assets wiederverwenden:

- `Assets/curated/kenney/tactical_icons/`: bisherige taktische Motive samt Lizenzdateien.
- `Assets/curated/kenney/ranks/`: Rollen-/Rangabzeichen.
- `scripts/ui/components/ui_tooltip_icon_helper.gd:7`: vorhandene Checkmark/Cross/Circle-Symbole.
- `scripts/assets/background_image_catalog.gd`: Hintergründe und deren Kontext.
- `scripts/meta/drop_light_layout_contract.gd:27`: erlaubte Kenney-Pad-, Craft- und Blaster-Preview-Pfade.
- `docs/dev/ui_theme_component_library.md`: bestehende Theme-, Card-, Badge-, Button-, Roster- und Progress-Komponenten.

Ein generiertes Icon ist ein neuer Kandidat, kein Ersatz für eine existierende Lizenzangabe. Quellen und Prompts getrennt aufbewahren.

## 5. Was mit den Bildern beabsichtigt ist

Hier steht die **von uns formulierte Gestaltungsabsicht**. Interne Gedanken des Bildgenerators sind nicht beobachtbar. Die sichtbaren Resultate sind anhand dieser Absicht zu beurteilen; abweichende Details sind keine nachträglichen neuen Anforderungen.

### A – Kommandodeck

Bild: [mockup_a_kommandodeck.png](../../reports/assets/ui-2026-11-01/mockup_a_kommandodeck.png).

- Die Karte soll das räumliche Problem erklären; das Dock die nächste Handlung.
- Teamliste und Auswahlkarte sollen denselben Teamnamen/Marker benutzen. Dadurch bleibt klar, wessen Plan bearbeitet wird.
- Befehlsintentionen stehen als beschriftete, gleich große Schaltflächen zusammen. Haltung und Feuerregeln sind erkennbare eigene Gruppen.
- GO erhält die stärkste Aktionsgewichtung erst bei ausführbarem Plan. Eine Sperre nennt die fehlende Voraussetzung.
- Rückmeldungen bleiben beim Auftrag sichtbar. Ein kurzer bestätigter Buttondruck bedeutet noch keinen angenommenen Simulationsbefehl.
- Der Vorteil gegenüber einem reinen Weltscreen ist gezielte Information; der Preis ist belegte Kartenfläche. Das Dock darf nicht durch dekorative Rahmen wachsen.

### B – Feldtablet

Bild: [mockup_b_feldtablet.png](../../reports/assets/ui-2026-11-01/mockup_b_feldtablet.png).

- Dieselben Entscheidungen wie A auf hellen, matten Instrumentenflächen vergleichen.
- Das freundliche Material passt zur illustrierten Science-Fiction-Welt, ohne futuristische Glühschrift zu benötigen.
- Dunkler Text und klare Zeilentrennung sollen längere deutsche Namen tragen.
- Die offene Frage ist die Aufmerksamkeit: Führt die helle Fläche stärker als die Karte? Mit derselben Mission wie A prüfen.
- Keine neue Tablet-Mechanik, kein zusätzlicher Ausrüstungsgegenstand und keine neue Ansichtspflicht entstehen durch den Namen.

### C – Einsatztafel

Bild: [mockup_c_einsatztafel.png](../../reports/assets/ui-2026-11-01/mockup_c_einsatztafel.png).

- Der Blick folgt Vorbereitung → Team/Loadout → Transport. Personen und Schiffe behalten klare Zuordnung.
- Boarding-Fortschritt steht am betroffenen Transport; ein Transitobjekt wirkt wartend und bleibt inspizierbar.
- Einsatzbereitschaft zeigt erfüllte und fehlende Voraussetzungen. Ein eindrucksvolles Schiff ersetzt keine verständliche Startfreigabe.
- Pads und Craft-Bilder verbinden die Oberfläche mit den Kenney-Modellen. Die Bühne bleibt grafische Staging-Darstellung.
- Pilot, Passagiere und Kapazität müssen getrennt lesbar bleiben. Keine stillschweigende zusätzliche Sitzplatzregel aus dem Bild übernehmen.

## 6. Sechs ursprüngliche Icon-Kandidaten und zwei Überarbeitungen

Dateien liegen unter `docs/reports/assets/ui-2026-11-01/`. Der Generierungsauftrag zielt auf freigestellte Rasterbilder mit klarer Silhouette, begrenzter Farbpalette und ohne eingebrannte Schrift.

| Datei | Bedeutung / beabsichtigte Form | Abgrenzung |
|---|---|---|
| `icon_move.png` | Bewegen: klarer gerichteter Bewegungspfeil | Kein generisches Zielkreuz; nicht zugleich „Weiter“ in Menüs |
| `icon_defend.png` | Halten/Verteidigen: Schutz-/Positionsmotiv | Weder Zielwahl noch Feuer halten |
| `icon_flank.png` | Flankieren: deutlich seitlich umlaufende Richtung | Nicht bloß gedrehter Bewegen-Pfeil |
| `icon_take.png` | Nehmen: Einnehmen/Sichern eines Zielpunkts | Keine Aussage, dass das Ziel bereits erobert ist |
| `icon_dropship.png` | Transport/Dropship: kompakte Craft-Silhouette | Keine beliebige Flugzeugklasse oder neue Transportfähigkeit |
| `icon_loadout.png` | Loadout: klar erkennbare Ausrüstungsanordnung | Keine neue Waffe und keine Kampfwertzusage |

Zu prüfen: sichtbare tatsächliche Form, echtes Alpha, saubere Ränder, optisch vergleichbare Größen und Erkennbarkeit auf dunklem wie hellem Grund. Die Tabelle beschreibt den Auftrag, nicht ein vorweggenommenes Prüfergebnis.

Nach dem Review liegen zusätzlich `icon_flank_v2.png` und `icon_dropship_v2.png` vor. Die Review-Seite zeigt diese zwei neuen Kandidaten mit offenem Urteil sowie die vier unveränderten positiv bewerteten Motive. Die als unklar bewerteten Originale bleiben zum Vergleich verlinkt; V2 ist noch keine Nutzerfreigabe.

Taktische Befehle zunächst mit Text anzeigen. Empfohlene Arbeitsgrößen: Icon 24–32px im Button; große Navigations-/Stagingbilder 48–64px. Produktionsgröße erst nach realer Verkleinerungsprüfung festlegen. Feine generierte Oberflächendetails dürfen kein Bedeutungsträger sein.

Statusrahmen, Fokus und Hover später nativ zeichnen. Dafür keine sechs weiteren gemalten Iconvarianten erzeugen. GO, Lupe, Schließen und einfache Pfeile können vorhandene native Controls/Symbole behalten.

## 7. Zustände und Architekturgrenzen

| Situation | Sichtbares Verhalten | Eigentümer / Grenze |
|---|---|---|
| Kein Fireteam | „Fireteam auswählen“; Befehle nicht ausführbar | UI-Auswahl, keine neue Unit-Wahrheit |
| Kein gültiges Tile/Ziel | Fehlende Auswahl direkt am Befehl nennen | Bestehender Input-/Command-Contract |
| Plan in Bearbeitung | Vorschau klar von aktivem Auftrag unterscheiden | Lokaler Planungszustand im vorhandenen Pfad |
| GO gesendet | „Auftrag angefordert“; Mehrfachklick sinnvoll behandeln | Anfrage ist noch kein ausgeführter Auftrag |
| Angenommen / läuft | Bestätigten Auftrag und Ausführungsphase zeigen | Bestehender Runtime-Snapshot / `SimulationRoot` |
| Abgelehnt | Konkreten Grund zeigen; Kontext erhalten | Autoritative Ablehnung, keine UI-eigene Korrekturbuchung |
| Transit / Boarding | Phase, betroffene Personen und ETA/Fortschritt | Bestehende Transportzustände, kein UI-Timer als Wahrheit |
| Gegner unbekannt | Nur bestätigte bekannte Informationen darstellen | FoW-/Kontaktwissen nicht mit umfassendem Sim-State verwechseln |
| Personenportrait gewählt | Charakterinformationen zeigen | In der Taktik keine individuelle NPC-Direktsteuerung |
| Menü offen | Eingaben eindeutig dem Menü zuordnen | Echtzeit ohne Pause bleibt geltender Spielvertrag |

`SimulationRoot` bleibt autoritativ. Der sichtbare Fireteam-Pfad verwendet `MissionTacticalSandboxController`, Resolver, `FireteamMovementController` und `SimulationRoot.enqueue_command()`. `RuntimeLeader` darf nicht als zweite sichtbare Autorität angebunden werden; siehe `docs/ARCHITECTURE.md`.

Bestehende lesende Presenter nutzen: `selected_fireteam_decision_presenter.gd:5` für Handlung/Grund, `mission_control_state_presenter.gd:5` für Transport, `tactical_hud_language_presenter.gd:5` für verständliche Beschriftungen. Diagnosen bei Bedarf aufklappen; sie dürfen keine fehlende Spielinformation ersetzen.

HUD-Updates weiter über vorhandene Dirty-/Readmodel-Pfade ausführen, insbesondere `scripts/tactical/mission_hud_read_model.gd`. Kein Komplettaufbau aller Karten pro Frame. Icons und StyleBoxes wiederverwenden/cachen.

## 8. Desktop-Layout und Lesbarkeit

Erste Vergleichsfläche: **1920×1080 bei unveränderter Betriebssystem-/Spielskalierung**. Der bestehende `DropLightLayoutContract` verwendet diese Größe, 8px-Basisabstand und 48×48 beziehungsweise 40×40-Aktionsflächen (`scripts/meta/drop_light_layout_contract.gd:4–8`). Neue Werte sind Entwurfsziele, keine universellen UX-Gesetze.

**Aktuell gilt A3:** quadratische Buttons als Gestaltungsziel 56–64px, Icons 24–28px bei 1920×1080; Labels separat darunter. Das kompakte Band liegt bündig unten links und enthält eine Aktionsreihe plus schmale Team-/Kontextzeile. Teamkarten und Log liegen mit Abstand darüber; Dropship/LZ bleibt oben rechts etwas kleiner. Die horizontalen 40–44px-A2-Buttons sind historische Geometrie. Das Runtime-Layout bleibt bis zu einem eigenen Implementierungsauftrag unverändert.

- Haupttexte als Entwurf 16–18px, Nebenwerte 14–16px; sehr kleine Diagnosezahlen aus dem normalen Handlungspfad nehmen.
- Panelkanten, Auswahl, Fokus, Hover und Zielmarkierung getrennt gestalten. Farbe immer durch Form, Text oder Zustand ergänzen.
- Deutsche Langtexte und lange Personen-/Teamnamen vor Integration prüfen. Ellipsis nur mit erreichbarem Volltext.
- Karten sollen bei wechselnden Statuszeilen nicht springen. Progress, ETA und Status haben feste Plätze.
- Kleine Portraits zeigen Identität, nicht die einzige Zustandsinformation. Down/Transit/Ready auch beschriften.
- Primäre Aktionen dürfen bei Scroll nicht unbemerkt verschwinden. Auswahl und aktueller Plan bleiben nachvollziehbar.
- Danach 1280×720 gezielt auf Überlagerung, abgeschnittene Aktionen und Lesbarkeit prüfen. Kein automatischer Resize-Marathon aus diesem Konzeptauftrag ableiten.

Generierte Schrift ist für die spätere Godot-UI unverbindlich. Texte und Zahlen nativ rendern; das komplette Mockup nicht als Hintergrundbild mit unsichtbaren Buttons umsetzen.

## 9. Kleine Umsetzungspakete für einen späteren Auftrag

1. **Baseline und Entscheidung:** aktuellen Integrationstand, aktive Änderungen und gewählte Variante prüfen; eine frische echte Missionsaufnahme sichern. Abnahme: Nutzerentscheidung/Workbench-Export und dieselbe Vergleichssituation nachvollziehbar.
2. **Icon-/Theme-Slice:** vier Befehlsicons samt Labels an bestehenden Controls anbinden; Transport/Loadout separat. Abnahme: keine Bedeutungsdoppelung, sauberes Alpha, kleine Ansicht auf hellem/dunklem Hintergrund, Hover/Fokus/Sperre weiterhin erkennbar.
3. **Ein Missionspfad:** Auswahl → gültiges Tile → Bewegen planen → GO → Annahme/Ablehnung → sichtbare Ausführung. Abnahme: echte Klickfolge, keine UI-eigene Gameplay-Mutation, kein Klick durch die Oberfläche auf die Karte.
4. **Staging-Slice:** eine Person aus der Basis zur FOB, Fireteam/Loadout prüfen, Boarding und Dropship verfolgen. Abnahme: keine doppelte Person, korrekter Transitstatus, Pilot/Kapazität bleiben dem bestehenden Contract treu.
5. **Folgeflächen:** erst danach Lobby, Debrief, Einstellungen und Editor an dieselbe Formsprache anbinden. Abnahme: bestehende Funktionen erreichbar; keine stillen neuen Mechaniken.

Pro Paket passende vorhandene Verifier anhand des aktuellen Tasks wählen, echte Godot-Bilder ergänzen und den Diff begrenzen. Die Konzeptprüfung hier ersetzt weder Runtime-Regression noch menschliche Verständlichkeitsprüfung.

## 10. Prüfstand und offene Entscheidungen

Die Sichtprüfung und Metadaten stehen in [PRUEFUNG.md](PRUEFUNG.md), Dateihashes und Herkunft im [Manifest](manifest.json). Alle acht Icon-PNGs einschließlich der zwei V2-Kandidaten besitzen echtes Alpha. Fünf Screenentwürfe und ein erhaltener A3-Zwischenstand sind illustrative Rasterbilder. A3 zeigt die gewünschten Positionen, ist aber kein maßgenaues Layout: Kacheln nativ mit identischer Breite/Höhe bauen und die Bandhöhe kontrollieren. Kleine Zielgrößen und der echte Godot-Klickweg bleiben offen. Der Browserzugriff des Agenten auf die lokale HTML-Datei wurde durch die Browserrichtlinie gesperrt. Syntax, Export und A3/A2/A-Umschaltung sind offline geprüft. Der echte Nutzerexport bestätigt einen erfolgten Export; die übrigen Browserinteraktionen sind dadurch nicht geprüft.

### Sichtbare Abweichungen, die der nächste Chat nicht übernehmen soll

- Das ursprüngliche A zeigt „Vorsichtig“, A2 und B „Normal“; das ist keine neue Regel oder geplante Verhaltensänderung.
- Der A-Hilfetext sagt „Einheit bewegt sich“. In der echten UI „Fireteam bewegt sich“ verwenden, damit keine individuelle NPC-Steuerung suggeriert wird.
- C zeichnet „Aufklärung“, „Technik“, „Sturmgewehr“ und „Pistole“. Diese Beispieltexte sind keine Bestätigung verfügbarer Rollen oder Waffen. Aktuellen Katalog und seine `future_task`-/`status_only`-Grenzen lesen; bestehende SMG-/Medictool- beziehungsweise tatsächlich verfügbare Slots verwenden.
- C markiert Boarding bereits im Fortschrittsstreifen und zeigt zugleich „Boarding starten“. Vor dem Start muss der Streifen bei Vorbereitung stehen; während Boarding sind Zustandsanzeige und nächste erlaubte Aktion aus dem Runtime-Vertrag abzuleiten.
- Generierte Logos, Charaktergesichter und Schiffskonstruktionen sind keine beauftragten neuen Marken-, NPC- oder Fahrzeugassets. Die bestehenden Kenney-Figuren und tatsächlich zugewiesenen Craft-Bilder bleiben maßgeblich.
- Der Bildgenerator hat FoW und bekannte Kontakte nicht als nachgewiesenen Runtime-Zustand abgebildet. Keine sichtbare Figur aus dem Bild als Freigabe für unbekannte Gegnerdaten verstehen.

Die Missionsrichtung A ist entschieden; der aktuelle Revisionsauftrag A3 ersetzt A2s horizontale Geometrie durch ein bündiges quadratisches Randband. C bleibt zur Weiterentwicklung gewählt. Offen bleiben tatsächliche A3-Zieltreue laut nachfolgender Bildprüfung, endgültige Dichte, Iconerkennung bei Zielgröße, Lesbarkeit im Gelände, Anpassung der existierenden Controls und spätere Nutzungstests. Der ursprüngliche Export enthält **null von fünf gesetzten Sichtprüfungs-Häkchen**. Seine 48px-/Dunkel-Einstellung ist kein Nachweis der 24-/32px-Prüfung. Die Icons ersetzen keinen vollständigen Zustands-/Rollenatlas.

## 11. Kopierbarer Start für den nächsten Chat

```text
Wir arbeiten an der UI von SternenBürgerchen weiter.
Lies zuerst AGENTS.md, docs/PROJECT_BRIEF.md, docs/ARCHITECTURE.md,
docs/CODEX_RULES.md und docs/IMPLEMENTATION_STATUS.md im aktuellen Checkout.
Lies dann diese UI-Übergabe und die verlinkten Originalvorschläge:
docs/ui_concepts/ui_20261101/UEBERGABE.md
Öffne docs/reports/STERNENBUERGERCHEN_UI_2026-11-01.html und lies
docs/ui_concepts/ui_20261101/FEEDBACK_20261101.md samt Review-Export.
Basis dieses Konzeptpakets: integration/core-foundation, 3cae5a216.
A ist für die Mission gewählt, C für Staging weiterzuführen. Aktuell A3:
Band ab linker unterer Ecke bündig am absoluten unteren Bildrand.
Kompakte quadratische Buttons, Ziel 56–64px / Icon 24–28px bei 1920×1080;
Labels lesbar separat darunter. Bewegen, Nehmen, Verteidigen, Flankieren,
dann Plan ausführen direkt rechts als Quadrat; Haltung/Feuerregeln rechts.
Teamkarten und Log nach oben über das Band; keine alte Position fixieren.
Dropship oben rechts und Missionsziel oberer rechter Mittelbereich bleiben;
Dropship/LZ maßvoll kleiner. Haltung Normal behalten, keinen Spieltitel.
A2s horizontale Geometrie ist Vorgeschichte. Keine neuen aktiven Funktionen,
keine kleineren Schriften, keine neue Iconrunde. Noch keine Runtime-Freigabe.
Bildtexte/Zahlen sind Illustrationen. Keine Review-Checkbox war gesetzt.
Prüfe den heutigen Branch, Diff und die wirklichen Funktionsverträge.
Nutze vorhandene UI-Komponenten, Snapshots und Commandpfade.
Keine zweite Gameplay-Wahrheit; keine individuelle NPC-Steuerung;
GO führt den Plan aus und pausiert nicht; FoW bleibt verbindlich.
Setze nur das von mir konkret beauftragte kleine Umsetzungspaket um.
Liefere echte Godot-Bilder, den geprüften Klickweg und offene Grenzen.
```
