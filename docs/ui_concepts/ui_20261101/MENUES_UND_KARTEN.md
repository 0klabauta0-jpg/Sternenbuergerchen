# SternenBürgerchen: Menüs, Detailtafeln und Charakterkarten

Stand: 01.11.2026; Erweiterung desselben Konzeptauftrags nach A4. Grundlage ist der gelesene UI-/Datenbestand im Konzeptbranch auf Basis `integration/core-foundation` (`3cae5a216`); vor jeder Umsetzung den heutigen Stand prüfen.

**Lieferart: Bildgenerator-Vorschläge mit begründeter Gestaltung, keine Godot-Integration.** Die elf Tafeln decken Hauptansichten und zusammengehörige Detail-/Modalzustände ab. Nicht jede Kombination jedes Dropdowns erhält ein eigenes Bild.

- [Vollständige Review-Workbench](../../reports/STERNENBUERGERCHEN_UI_2026-11-01.html).
- [Übergabe und Architekturgrenzen](UEBERGABE.md), [Feedbackfolge](FEEDBACK_20261101.md).
- [Exakte neue Prompts](prompts_revision5.json), [Korrekturprompts](prompts_revision5_korrektur.json), [Datei-/Quellenmanifest](manifest.json), [tatsächliche neue Bildprüfung](BILDPRUEFUNG_REVISION5.md), [Gesamtprüfstand](PRUEFUNG.md).

## 1. Wie die Erklärungen zu verstehen sind

„Warum“ und „wie“ dokumentieren unsere Vorgaben für den Bildgenerator. Interne Gedanken des Generators sind nicht verfügbar. Was er tatsächlich gezeichnet hat, wird anschließend sichtbar interpretiert und gegen den Auftrag geprüft; eine Abweichung wird nicht nachträglich zur Absicht erklärt.

Die gemeinsame Formensprache verbindet dunkle matte Instrumentenflächen, cremefarbene Modulgehäuse, Petrol, sparsame gelbe Auswahlkanten und einfache Kenney-nahe Formen. Illustration gibt Identität; native Schrift, Konturen und Zustände müssen später die Bedienung tragen.

Priorität haben **A5-Mission, kompakte Personen, lesender Charakterbogen und FOB**: Hier treffen viele häufige Entscheidungen auf kleine Flächen. Hauptmenü, Teameditor, Details und Debrief führen dieselbe Sprache weiter. Lobby, Settings/Hilfe und Editor brauchen zusätzlich eigene fachliche Gruppen.

## 2. Bildzuordnung und Abdeckung

| Tafel / Bilddatei | Abgedeckte Ansicht und Unterzustände |
|---|---|
| [A5 Mission](../../reports/assets/ui-2026-11-01/mockup_a5_mission_zweireihig.png) | Zwei echte Befehlsreihen, Ziel/Auftrag, Team, Haltung, Feuerregeln, Log, LZ/Transport |
| [Hauptmenü](../../reports/assets/ui-2026-11-01/menu_hauptmenue.png) | Einstieg, Teamzusammenfassung/Bibliothek, vorhandener Missions-Slot |
| [Heimatbasis](../../reports/assets/ui-2026-11-01/menu_heimatbasis.png) | Briefing, Roster, Transferteam, Pilot/Flugdeck, laufende Transfers |
| [FOB / Loadout](../../reports/assets/ui-2026-11-01/menu_fob_loadout.png) | Pool, Fireteams, Leader, Rüstung/Waffen, Respawn, Boarding/Transport |
| [Charakterkarten und Bogen](../../reports/assets/ui-2026-11-01/board_charakterkarten.png) | Mehrere kompakte Zustände und vollständiger lesender Charakterbogen |
| [Detailkarten](../../reports/assets/ui-2026-11-01/board_detailkarten.png) | Fireteam, Ziel/Auftrag, Dropship/LZ, kontextuelle Türinteraktion, Tooltip/Anfrage/Ablehnung |
| [Nachbesprechung](../../reports/assets/ui-2026-11-01/menu_debrief.png) | Ergebnis, Zustand/Folgen, AAR, Skill-/XP-Änderungen, Rückweg |
| [Multiplayer-Lobby](../../reports/assets/ui-2026-11-01/menu_lobby.png) | Host/Join, Team/Map, Bereitschaft, Kartenannahme, Verbindung und Start |
| [Settings / Hilfe](../../reports/assets/ui-2026-11-01/menu_einstellungen_hilfe.png) | Einstellungen, Eingabeübersicht, Kontexthilfe und kleine Escape-Menütafel |
| [Editor](../../reports/assets/ui-2026-11-01/menu_editor.png) | Authoring-Tools, Palette, Inspector, Map-/Szenario-/Dateibedienung |
| [Teameditor](../../reports/assets/ui-2026-11-01/menu_teameditor.png) | Bearbeitbare Team-/Personenvorlage mit Budget, Locks und Speichern |

Die Screens sind Illustration mit Beispielwerten. Die zugehörige Bildprüfung nennt, welche Text-, Anordnungs- oder Funktionsabweichungen bei einer Umsetzung zu korrigieren sind.

## 3. Aktueller Datenumfang: keine veralteten Beschränkungen übernehmen

| Bereich | Im Code vorhandene Felder / Auswahl | Quelle |
|---|---|---|
| Identität | Unit-ID, Name, Portrait, Callsign, Rollen-ID/-name, Kurztext, Herkunft, Alter, Biografie | `scripts/meta/meta_unit_profile.gd:4–20` |
| Zuordnung/Zustand | Team, Fireteam, Leaderflag, Status, Verfügbarkeit, Recovery, Sekundärtext | `meta_unit_profile.gd:25–27`, `:41–45` |
| Charaktertiefe | Skills, Kommunikation, Plattform, Verhalten, Methoden/Funktionsfits, Traits, Beziehungen, Historie, Progression | `meta_unit_profile.gd:28–52` |
| Rüstung | Light, Medium, Heavy | `scripts/command/loadout_contract.gd:10` |
| Waffen | SMG, Rifle, Sniper, Railgun, Rocket launcher, Medictool; sekundär/FOB auch None | `loadout_contract.gd:11–13`, `scripts/core/weapon_data.gd:9` |
| Startrollen | Leader, Medic, Shooter, Engineer, Pilot, Heavy Support, Scout/Sniper | `scripts/meta/start_roster_generator.gd:26–34`, `:61–155` |

Die alte Beschreibung „FOB nur SMG und Medictool“ ist überholt: `fob_screen.gd:3402–3403` liest direkt `LoadoutContract.get_fob_weapon_options()`. Die sechs kanonischen Waffen und None sind belegt. Eine zusätzliche separat auswählbare Pistole ist nicht belegt.

Rollenname, Rollen-Fit und verfügbare Aktion sind verschieden: Ein Engineer-Badge oder Scout-Profil bestätigt keine frei erfundene Reparatur-/Aufklärungsfunktion. Die zulässigen Missionsaktionen kommen aus `mission_command_hierarchy_contract.gd`, nicht aus einer generierten Rollenillustration.

Kernwerte des Bogens: Accuracy, Speed, Toughness, Awareness, Recognition, Stealth, Discipline, Leadership. Sie verwenden im vorhandenen Modell Werte von 0 bis 1. Das Bild schlägt eine lesbare Skala 0–10 vor: dafür den vorhandenen Wert nur für die Anzeige mit zehn multiplizieren und die Rundung einheitlich festlegen. Auch eine Prozentdarstellung wäre eine ausdrücklich definierte Anzeigeumrechnung; das Datenmodell bleibt unverändert.

Kommunikation: Speech Quality/Quantity. Plattform: Ground Vehicle, Dropship, Freighter, Fighter. Verhalten: Initiative, Order Fidelity, Signature Control, Contact Stability, Autonomy. Plattformwerte nur bei Relevanz beziehungsweise als erklärtes „nicht anwendbar“ zeigen.

## 4. A5: zwei tatsächlich belegte Aktionsreihen

**Warum:** A4 ließ Platz für später; der neue Auftrag verlangt zwei echte Reihen bereits im Layout. Kleinere Buttons gewinnen Platz durch Fläche und Abstand, nicht durch unlesbare Schrift.

**Wie:** Randband bündig unten links beibehalten. Links zwei Reihen; daneben Ziel/Auftrag; danach Alpha/Bereit mit Haltung und Feuerregel darunter. Teamkarten und Log bleiben oberhalb, Transport/LZ oben rechts.

| Erste Reihe | Zweite Reihe |
|---|---|
| Bewegen | Ziel |
| Nehmen | Leeren |
| Verteidigen / Halten | Löschen |
| Flankieren | Ordnen |
| Plan ausführen | Leere Fläche, kein Platzhalterbutton |

Das sind vorhandene Aktionen: `mission_command_hierarchy_contract.gd:81–113`. Ziel ist der vorhandene Planungs-/Zielmodus; Leeren/Löschen bearbeiten den vorgesehenen Plan-/Zielkontext, Ordnen ordnet den ausgewählten Plan vor GO. Diese Skizze erfindet keinen neuen Befehl.

Maßziel des Assistenten für die 1672px breite Bildvorlage: etwa 50–52px-Buttonkörper, ungefähr 4px Abstand, zwei Reihen innerhalb der bisherigen etwa 127px-Bandhöhe. Innenbeschriftung bleibt lesbar, „Plan ausführen“ bei Bedarf zweizeilig. Dies sind Entwurfswerte und keine wörtlichen Nutzermaße oder bereits gemessenen Godot-Controls.

**Zustände:** Kein Team, kein gültiges Tile, keine lokale Befehlsberechtigung, kein Plan, Plan editiert, Anfrage ausstehend, angenommen, abgelehnt und laufend. Gesperrte Buttons nennen die fehlende Voraussetzung; GO ist keine Pause.

**Grenze:** Recon/Withdraw/Swap sowie Air-Hold/Cancel/Evac sind im gelesenen Action-Katalog `future_task`; Secure/Tempo/Contact/Cover/Security sind teilweise `status_only`. `return_to_plan` ist `implemented:false`, `hidden:true`. Dafür keine zusätzlichen aktiven Buttons zeichnen.

## 5. Hauptmenü: einen Einstieg finden, vorhandenes Team erkennen

**Warum:** Spielmodus und Teamverwaltung haben unterschiedliche Häufigkeit. Sie sollen erreichbar bleiben, ohne wie gleichgewichtige Primäraktionen auszusehen.

**Wie:** Einzelspieler als klare Hauptaktion; Multiplayer, Editor und Einstellungen daneben beziehungsweise darunter. Die aktive Teamzusammenfassung führt zu Bibliothek oder Teameditor. Spieltitel ist im Hauptmenü angemessen; der Wunsch „kein Titel oben links“ betrifft den Missionsscreen.

Teamname, Namensvorschlag, neues Roster, Aktivieren/Bearbeiten/Löschen gespeicherter Teams und Teameditor sind bestehende Wege. Missions-Speichern/-Laden beziehen sich auf den vorhandenen Shell-Slot; kein neues Mehrslot-Kampagnensystem daraus ableiten.

**Zustände:** Kein gespeichertes Team, aktives Team, Bibliothekseintrag ausgewählt, Lösch-/Neugenerierungsbestätigung, fehlender Missions-Slot, Speichern fehlgeschlagen. Auswahl und Aktivierung bleiben verschiedene Vorgänge.

**Quelle:** `scripts/ui/main_menu_screen.gd:910–995`, `:1058`, `:1207`, `:3515–3585`.

## 6. Heimatbasis: Personen, Transfer und Flugmittel verbinden

**Warum:** Der Spieler muss erkennen, wer verfügbar ist, wer transferiert wird und welches Flugmittel einen Piloten besitzt. Eine große Kulisse löst diese Zuordnung nicht.

**Wie:** Roster mit kompakten Karten, daneben Transferteam und Flightdeck. Briefing zeigt aktuellen Einsatz und Voraussetzungen. Fortschritt direkt am betroffenen Transport beziehungsweise an der Person anzeigen; voller Charakterbogen auf Anforderung.

Pilot und Passagiere klar trennen. Der Flugdeck-Hintergrund ist eine Staging-Bühne und bleibt von einer zusätzlichen begehbaren Basissimulation getrennt.

**Zustände:** Verfügbar, ausgewählt, für Transfer vorgesehen, unterwegs mit ETA, angekommen, Pilot fehlt, Kapazität belegt. Eine ausgegraute Transitkarte darf Identität und Details weiterhin erklären.

**Quelle:** `scenes/meta/homebase_test_screen.tscn:143`, `:191`, `:297`; `scripts/meta/homebase_screen.gd:5605–5617` zeigt den lesenden Bogen mit `editable_metrics:false` und ohne Loadout-Dropdowns.

## 7. FOB und Loadout: Teamaufbau vor Boarding

**Warum:** Personenzuordnung, Leaderwahl, Ausrüstung und Transport sind gekoppelte Entscheidungen. Sichtbare Übergabeorte erklären den Prozess besser als mehrere identische Listen.

**Wie:** NPC-Pool links, Fireteams zentral, kompakter Loadout-Bereich und zugeordnete Transportkarten. Leader, Rüstung sowie Weapon 1/2 bleiben am jeweiligen Mitglied nachvollziehbar. Eine offene Dropdownliste zeigt den belegten Katalog, keine dekorative Fantasiewaffe.

FTL-Stern und Personenauswahl sind verschiedene Controls. Boarding und Senden sind auf den bestehenden Transportzustand bezogene Aktionen. Respawnanker separat von Boarding/Loadout kennzeichnen.

**Zustände:** Unzugewiesen, Fireteam zugeordnet, kein Leader, Loadout offen, Respawn verortet, Boarding angefordert/laufend, Transport unterwegs. Ablehnung und erfolgreiche Zuordnung getrennt zeigen; Personen nicht in zwei Listen als zwei aktive Instanzen zeichnen.

**Quelle:** `scripts/meta/fob_screen.gd:1246–1254`, `:1285–1293`, `:1793–1909`, `:2704–2848`, `:3402`.

## 8. Charaktertafel: kompakte Auswahl und lesende Tiefe

**Warum:** Eine Minikarte soll Identität und Verfügbarkeit schnell vermitteln; der volle Bogen erklärt Fähigkeiten und Zusammenhänge. Alle Daten auf jede Minikarte zu drucken würde beide Aufgaben erschweren.

**Wie:** Mehrere kleine Karten nebeneinander als verfügbar, zugewiesen und Transit zeigen; ein großer **lesender** Bogen daneben. Gemeinsame Personendaten konsistent halten. Karte enthält Portrait, Name, Rolle, eine Kontextzeile, Badges und bei Bedarf Fortschritt/FTL-Marker.

Der bestehende `NPCCompactCard` besitzt unter anderem `card_pressed`, `card_open_requested`, Drag/Drop, optional Leader-/Entfernen-Signal und ausgewählt/disabled/progress-Darstellung (`npc_compact_card.gd:12–25`, `:501–526`). Je nach Host ist Detailaufruf separat beziehungsweise per Doppelklick erreichbar. In der Mission keine individuelle Bewegungssteuerung hinzufügen.

Der Bogen gruppiert Identität/Traits, Kernwerte, Rolle/Loadout, Status/Recovery, Teamfit, Progress/XP, Kommunikation, relevante Plattformwerte und abgeleitete Fits. Beziehungen, Recovery oder History dürfen fehlen; dann sinnvoll „noch keine Daten“ statt erfundener Werte zeigen.

**Zustände:** Keine Person gewählt, aktive Auswahl, zugewiesen, Transit, Recovery und Daten nicht anwendbar. Rang-/Rollenbadges sind abgeleitete Fits; sie machen eine Person nicht automatisch zum gewählten FTL.

**Quelle:** `scripts/meta/character_sheet_view.gd:20–37`, `:38–112`; `character_sheet_formatter.gd:12–58`, `:293–339`. Homebase und FOB rufen den Bogen ausdrücklich lesend auf.

## 9. Teameditor: bewusst bearbeitbar, eigener Kontext

**Warum:** Derselbe Charakterbogen darf im Live-Spiel keine freien Werteänderungen suggerieren. Team-/Personenvorbereitung braucht dagegen deutlich sichtbare Bearbeitung und Budgetrückmeldung.

**Wie:** Eigenes Bild mit „Teameditor“-Überschrift, Teamname/Emblem, Personenauswahl, Name/Portrait und Budgetgruppen. Plus/Minus, Slider und Locks nur hier zeigen. Speichern gehört zum Roster, nicht zu einer laufenden Simulationsmutation.

Vorhandene Teamwerte: Taktik, Medizin, Technik, Piloten, Disziplin, Aufklärung. Der Generator enthält 30 Startpunkte und sechs Werte von 0–10 (`start_roster_generator.gd:23–50`). Für den Detailbogen verwendet der Host getrennte Gruppenbudgets und Locks; diese nicht mit einem unbegrenzten gemeinsamen Punktepool verwechseln.

**Zustände:** Keine Person ausgewählt, Budget frei/ausgeschöpft, Metric gesperrt, veränderte Vorlage, gespeichert oder Speicherfehler. Ein Rollen-Fit wird aus Werten abgeleitet; dessen Label ist kein frei verfügbarer Live-Klassenwechsel.

**Quelle:** `main_menu_screen.gd:1207–1226`, `:1843–1879`, `:3581–3719`. Hier sind `group_editable_metrics:true`, Callbacks, Gruppenbudgets und Locks vorhanden; Homebase-/FOB-Inspektion bleibt getrennt.

## 10. Detailtafel: dieselbe Formsprache, verschiedene Besitzer

**Warum:** Fireteam, Ziel, Transport und Tür brauchen jeweils andere Zustände. Ein einheitlicher Kartenrahmen soll diese Unterschiede lesbar machen, nicht durch identische Aktionslisten verbergen.

**Wie:** Tafel mit fünf beschrifteten Kontextkarten: ausgewähltes Fireteam, Ziel/Auftrag, Dropship/LZ, kontextuelle Türinteraktion und Tooltip-/Anfragebeispiele. Anfrage ausstehend und abgelehnt ausdrücklich als zwei Beispiele beschriften; nicht als gleichzeitig bestätigte Weltzustände.

Fireteam zeigt Identität, Mannschaft/Zustand und aktuellen Auftrag. Zielkarte zeigt gewählten Zielbezug und Planphase. Transportkarte zeigt LZ/Anflug, aktuelle Transportphase und bekannte ETA. Türkarte zeigt nur im gültigen Kontext die bestehende Interaktion beziehungsweise einen erklärten Sperrgrund.

**Zustände:** Kein Ziel, lokaler Entwurf, Anfrage, Annahme, Ablehnung, Ausführung und Ende. Keine HP- oder Besitzerwerte unbekannter Gegner aus einem vollständigen Simulationsobjekt aufdecken.

**Quelle:** `scripts/ui/selected_fireteam_decision_presenter.gd:5–54`, `mission_control_state_presenter.gd:5–78`, `mission_command_hierarchy_contract.gd:83`. Türsturm ist kontextabhängig und bleibt Planung vor GO.

## 11. Nachbesprechung: Ergebnis und Folgen, dann Rückweg

**Warum:** Nach dem Gefecht müssen Ergebnis, betroffene Personen und nächste Station verständlich werden. Belohnungsdeko darf tatsächliche Verluste oder Recovery nicht verdrängen.

**Wie:** Ergebnis/Dauer/Bedingung/Objective oben, Teamzustand und Air-Recovery darunter, AAR sowie FTL-/Personenrückmeldungen und XP-/Skillfolgen als getrennte Bereiche. Rückkehr zur FOB oder Heimatbasis sind bestehende Wege; kein erfundener Direktstart einer neuen Mission.

**Zustände:** Ergebnis fehlt, Mission beendet, kein Verlust berichtet, Recovery vorhanden, keine neuen Awards, vorhandene Awards. Keine fehlenden Statistiken als Null-Kills/volle Gesundheit ausgeben und keine erfundenen Loot-/Geldbelohnungen ergänzen.

**Quelle:** `scripts/meta/debrief_screen.gd:475–552`, `:788`, `:932–980`, `:1348–1352`. AAR-Befund und Skill-Vorschau sind nicht automatisch derselbe bestätigte Award.

## 12. Lobby: Verbindung und Bereitschaft sind getrennt

**Warum:** „Verbunden“ bedeutet weder „bereit“ noch „Missionsstart erlaubt“. Der Host muss Voraussetzungen und Kartenannahme erkennen können.

**Wie:** Host/Join samt Adresse/Port, darunter Spieler/Team/Roster und Map; Bereitschaft pro Teilnehmer. Host-Start erst beim vorhandenen `can_start_mission`. Unbekannte Karte als eigener Annahme-/Ablehnungszustand mit nachvollziehbarem Kontext.

Vorhanden: Seiten Alpha/Bravo, Teammodus Zusammen/Gegeneinander, LAN/VPN, Direct IP Internet, UPnP Internet und Roster-Modus. Kein Matchmaking, Freundeslisten- oder globales Serverbrowser-System erfinden.

**Zustände:** Getrennt, verbinden, verbunden/unbereit, bereit, Karte wartet auf Annahme, abgelehnt, Host kann starten, Mission läuft, Verbindung verloren. Editierbare Felder gemäß Sessionzustand sperren; nicht alle Peer-Controls wie Host-Controls behandeln.

**Quelle:** `scripts/ui/multiplayer_lobby_screen.gd:614–711`, `:938–949`, `:1333–1358`, `:1417–1470`.

## 13. Einstellungen, Hilfe und Escape-Menü

**Warum:** Werte ändern, Eingaben nachsehen und kontextuelle Erklärung lesen sind unterschiedliche Aufgaben. Klare Gruppen verhindern, dass eine Übersicht wie ein bearbeitbares Keybinding aussieht.

**Wie:** Anzeige, Audio, Gameplay/Hilfe als Bereiche; Master/Musik/Effekte als sichtbare Kernslider. Eingaben als **Übersicht**, kein „Taste neu belegen“-Button. Kontext-Hilfe als kompakte/erweiterte Beispielkarte. Kleine Escape-Tafel zeigt Weiter, Einstellungen, Mission speichern/laden, Hauptmenü, Spiel beenden.

Vorhandene Anzeige: Auflösung, Fenster/Randlos/Vollbild, VSync. Kontexthilfe Aus/Kompakt/Erweitert; Comic-Bubbles Aus/Minimal/Normal/Debug. FoW folgt dessen aktuellem Contract. Der Audio-Contract enthält sieben Buswerte, aber das Hauptmenü rendert Master/Music/SFX; Escape-Settings rendert Master/SFX/UI. Nicht sieben bereits sichtbare Hauptmenü-Slider behaupten.

**Zustände:** Unveränderte Werte, Entwurf geändert, Übernehmen, Abbrechen, Zurücksetzen, Hilfe aus/kompakt/erweitert. „Weiter“ schließt das Menü und bedeutet keine pausierte Echtzeitmission. Ein modaler Eingabefokus darf keinen Weltbefehl gleichzeitig auslösen.

**Quelle:** `settings_screen.gd:9–24` (`rebindable_input:false`), `main_menu_screen.gd:854–883`, `game_settings_contract.gd:11–31`, `:171–199`, `global_escape_menu.gd:326–331`, `:363–365`.

## 14. Editor: Werkzeug, Vorschau und Daten auseinanderhalten

**Warum:** Authoring benötigt viele Funktionen; ausgewähltes Werkzeug und tatsächlich gespeicherte Tile-/Objekteigenschaft müssen trotzdem unterscheidbar bleiben.

**Wie:** Tools schmal links, gruppierte Assetpalette/Vorschau, große Arbeitsfläche, kontextueller Inspector rechts. Rotation/Scale gehören zum gewählten Objekt; Map-ID, Laden, Speichern und Save As zum Dokument. Keine Missionsbefehlsleiste als Editorwerkzeug umetikettieren.

Vorhandene Tools umfassen Auswahl, Terrain/Road, Assets/Factory/Space-Floor, Pipe-/Wall-/Cliff-Lines, Türzustände, Radierer, Höhe, Marker und Patrol. Inspectorfelder umfassen Walkable, LOS, Cover, Height/Object Height sowie Objektrotation/Scale. Undo ist belegt; Redo wird hier nicht als vorhandenes Control behauptet.

**Zustände:** Kein Objekt, Werkzeug aktiv, gültige/ungültige Vorschau, modifizierte Daten, Save-As-Ziel, Speichern fehlgeschlagen. Rohr-/Wandketten sind vorbereitete Editor-Authoringpfade und keine neue Wirtschaftssimulation. Den parallelen Grafik-/Hexstand nicht still integrieren.

**Quelle:** `scripts/editor/map_editor.gd:1466–1486`, `:2414–2545`, `:415`; `map_editor_tile_property_overlay.gd:73–126`.

## 15. Übergabe in kleine überprüfbare Umsetzungsschritte

Zuerst A5 und eine kompakte Personenkartenfamilie nativ an bestehende Controls/Snapshots binden; dann einen vollständigen Basis → FOB → Boarding → Einsatz → Debrief-Pfad bearbeiten. Teameditor, Settings/Lobby und Editor folgen als eigene kleine UI-Slices.

Für jede Tafel sind später reale Klickfolge, Fokus, Langtexte, Sperrgründe und leerer Zustand zu prüfen. Die Bildprüfung beurteilt nur die erzeugte Illustration. Keine Engine-/Spielerfreigabe aus schönen Tafeln, existierenden Dateien oder einem JSON-Export ableiten.

`SimulationRoot` bleibt Gameplay-Autorität. UI setzt vorhandene Commands und liest bestätigte Snapshots. Portrait, Auswahl, lokaler Entwurf, ausstehende Anfrage und bestätigtes Ergebnis bleiben verschiedene Zustände. Keine per-frame Komplett-Rebuilds und keine unabhängigen UI-Timer als Transport-/Recovery-Wahrheit.
