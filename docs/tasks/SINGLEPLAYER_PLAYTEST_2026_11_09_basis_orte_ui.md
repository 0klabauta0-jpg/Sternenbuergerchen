# Einzelspieler: Heimatbasis, Personal, Aufträge und erste Orte

Stand: 09.11.2026. Status: **Implementierung AP0–AP7 lokal geprueft; AP8 technisch bestanden, native Bedien-/Gestaltungsabnahme offen.**
Quelle: Nutzerdiktat in diesem Chat, anschließend ausdrücklicher Auftrag zur Zusammenfassung und Planung.
Danach autorisierte der Nutzer Umsetzung, lokale Commits und direkte lokale
Mainintegration, weiterhin ohne Push. Die spaetere PC-Nutzungsanweisung begrenzt
weitere Tests auf Hintergrund/Headless. Nachweis: [QA](../qa/singleplayer_20261109/README.md).

## Ziel / Problem

Die neue Heimatbasis soll der verständliche Ausgangspunkt des Einzelspielers werden:
Personal und Trupp ausrüsten, Auftrag annehmen, Zielort auf der Karte verstehen,
zum Ort fliegen, Aufgabe erledigen und zurückkehren. Die neue Gestaltung gefällt;
die alten Arbeitsansichten stören diesen Ablauf. Die Basis soll ein glaubwürdiger,
begehbarer Ort mit einsehbaren Innenräumen werden.

## Vollständige Zusammenfassung des Playtests

### Oberfläche und Navigation
- Die neue Heimatbasisoberfläche und den grundsätzlichen Aufbau von Einsatz & Abflug erhalten.
- Erweiterte Werkzeuge führt laut Playtest in eine unerwünschte alte Ansicht, aus der der Nutzer
  nicht zurückfindet. Die alte Ansicht soll aus dem regulären Einzelspielerweg verschwinden.
- Steuerung und UI insgesamt übersichtlicher machen; benötigte Alt-Funktionen in den neuen
  Weg übernehmen, statt den alten Bildschirm wieder als Voraussetzung einzuführen.
- Rechten blauen Informationsbereich besser lesbar und weniger textlastig gestalten.
- FOB vorerst nicht auswählbar machen und sichtbar durchstreichen; als vorübergehend gesperrt kennzeichnen.

### Personal, Charaktere, Trupp und Ausrüstung
- Personalansicht auf Personen und ihre Ausrüstung konzentrieren; störenden Zusatzbereich entfernen.
  Das diktierte Wort „Cutlist“ ist nicht eindeutig identifiziert.
- Kleinere Personenbilder/-karten, damit mehr Personal gleichzeitig sichtbar ist.
- Nach Rang, Erfahrung und weiteren sinnvollen vorhandenen Werten sortieren, wie in der alten Ansicht.
- Doppelklick auf eine Person öffnet den Charakterbogen.
- Bestehende Gesichter gefallen und sollen erhalten bleiben.
- Uniform/Ausstattungsdarstellung soll Schütze, Sani und andere Rollen besser erkennbar machen.
- Rang-/Rollenabzeichen auch bei Trupp und Ausrüstung zeigen.
- Neu angelegte Trupps ohne umständlichen Zuweisungsweg per Drag-and-drop mit Personen besetzen.
- Fireteam-Zuweisung und Ausrüstungsbedienung im neuen Bildschirm ebenfalls per Drag-and-drop anbieten.
- Personal einzeln und innerhalb des Trupps über übersichtliche 2D-Ausrüstungsslots ausrüsten.
- Später die tatsächliche Verfügbarkeit aus Lager/Vorräten berücksichtigen; kein sofortiger Auftrag
  für eine vollständige Lagerwirtschaft.

### Heimatbasis als Karte
- Basis erkunden zu einer richtigen, größeren begehbaren Spielkarte ausbauen.
- Zunächst die zwei bestehenden Gebäude und einen überschaubaren Landeplatzbereich verwenden.
- Gebäude innen einsehbar machen, ohne verdeckendes Dach; die Figur soll hineingehen können.
- Zwei Landepads nebeneinander und eine Tank-/Servicestation in deren Nähe vorsehen.
- Felsen weiter an den Rand; mehr Platz, sinnvolle Wege und Raum für spätere Erweiterungen.
- Bauliche Elemente sollen langfristig baubar sein; für den ersten Test dürfen sie vorplatziert sein.
- Basisinteraktionen anbieten, insbesondere Aufträge und Auftanken sowie die vorhandenen
  Personal-/Trupp-/Abflugaktionen.

### Auftrag, Ort, Karte und Abflug
- Einsatzinformationen und Planung aus der Basis erreichen.
- Links eine mit Planung und Einsatz & Abflug verbundene Orts-/Regionalkarte anbieten,
  sinngemäß wie die angesprochene KlabsCom-Lösung.
- Klar erkennbar machen: Dieser Auftrag gehört zu diesem Ort, dorthin fliegt das Schiff.
- An einen Ort fliegen; ein Auftrag ist kein abstraktes Reiseziel.
- Mission in der Einsatzplanung auswählen können.
- Auftragsannahme als eigenen linken Einstieg in Richtung Smart Mobile gestalten, angelehnt an
  die Funktion des mobiGlas für Einzelspieleraufträge; zusätzlich aus der begehbaren Basis erreichbar.
- Hintergrund von Einsatz & Abflug durch eine passende Sicht auf das echte Schiff auf seinem Pad ersetzen.
- Sichtbar zum Schiff laufende und einsteigende Figuren wurden als Möglichkeit angesprochen;
  zunächst als optionale Erweiterung behandeln.

### Erste Inhalte und Rahmen
- Eine Mission um einen abgestürzten Satelliten.
- Einen Außenposten, an dem gehandelt werden kann.
- Zunächst zwei bis drei Karten/Orte bereitstellen.
- Weitere Außenposten wurden als offene Idee genannt, nicht konkret bestellt.
- Savegame-Abwärtskompatibilität ist für diesen Umbau nicht erforderlich.
  Das ist keine Anweisung, vorhandene Nutzerdaten zu löschen.

## Sinnhaftigkeit / aktueller Befund

Geprüfter Quellstand: main ed77c105854bf11b3abfd2c90e32a99bcf62f753,
09.11.2026. Dies ist ein Source-Audit, kein neuer nativer Playtest.

- homebase_operations_presenter.gd besitzt bereits die neue Navigation, Personal-, Trupp-,
  Ausrüstungs- und Flugdeckansicht. Die eigene Personenzeile hat Suche und Buttons,
  aber keine Sortierung, Doppelklickdetails oder Drag-and-drop.
- homebase_screen.gd und npc_compact_card.gd besitzen bereits verwendbare Sortier-,
  Charakterbogen-, Badge- und Drag-and-drop-Pfade.
- Ein OperationsReturnButton existiert im Code. Die gemeldete Sackgasse ist ein
  beobachtetes Bedienproblem; ein fehlender Rückweg-Callback wurde nicht nachgewiesen.
- Die Basis ist bereits eine echte lokale Hexkarte (24 × 20 / 480 Felder) mit einem
  durch SimulationRoot bewegten ephemeren Commander. Sie ist kein bloßes Hintergrundbild.
- Die Basis enthält zwei Gebäude, einen Fuel-Prop und einen statischen Cutlass-Prop.
  Die Gebäude werden derzeit durch geschlossene Hüllen dargestellt; ganze Gebäudegrundflächen
  sind reserviert. Dächer ausblenden allein macht die Innenräume nicht begehbar.
- Der geparkte Cutlass besitzt ausdrücklich keine reale Craft-/Payload-ID.
- Der vorhandene Kartenweg ist eine taktische Missionskarte, keine Regionalkarte.
- Auftragsboard, allgemeiner Orts-/Reisevertrag, mengenbasiertes Lager, Währung,
  Handel und Fuel-Spielmechanik wurden im produktiven Bestand nicht gefunden.
- station_outpost_64x64.json / station_outpost_192x192.json sind bestehende Szenario-/Kartenquellen,
  belegen aber keinen funktionierenden Handelsaußenposten.
- Bestehende Rang-Badges leiten Rollen/Fähigkeiten ab. Ein eigener militärischer
  Dienstgrad wurde im geprüften MetaUnitProfile nicht gefunden.

## Vorgeschlagener erster Umfang

**Planannahme:** genau drei Startorte insgesamt: Heimatbasis, Satelliten-Absturzstelle,
Handelsaußenposten. Keine zusätzlichen zwei bis drei Außenkarten obendrauf.
Die ausdrückliche frühere Angabe zweier nebeneinanderliegender Pads bleibt Planbasis;
die spätere ungenaue Einzahl wird nicht als Streichung des zweiten Pads interpretiert.

Empfohlener Spielerweg:

Auftrag in Smart Mobile annehmen → Zielort auf der Regionalkarte sehen →
Trupp ausrüsten → Schiff/Payload prüfen → zum Ort fliegen →
Aufgabe/Handel durchführen → Rückflug → Ergebnis in der Heimatbasis.

Auftragsannahme, Planung und Welterkundung bleiben unterscheidbar. Annahme startet keinen Flug.
Mehrere Aufträge dürfen später auf denselben Ort zeigen. Die Heimatbasis bleibt auch ohne
laufenden Auftrag bedienbar. Der Handelsort ist ohne Kampfauftrag besuchbar.

## Lösungsentscheidung im Plan

Empfohlen ist die schrittweise Erweiterung der bestehenden neuen Oberfläche und bestehenden
Runtime-/Commandpfade. Ein kompletter Neubau würde funktionierende Owner/Gates duplizieren;
nur die alte Oberfläche neu einzufärben erfüllt den gewünschten Ablauf nicht.
Diese Abwägung ist eine Planungsempfehlung, keine behauptete Nutzerentscheidung.

Die neue Oberfläche wird der einzige reguläre Einzelspielerweg. Benötigte Alt-Callbacks,
Daten und Tests werden übernommen; großflächiges Löschen aller Legacy-Skripte ist kein Ziel.
Die Basisinteraktionen und die linke Navigation öffnen dieselben Funktionen.

## Architektur / Contracts

- Godot 4.6.2; vorhandene Hex-Topologie hex_axial_v1 für neue Karten.
- SimulationRoot und vorgesehene Runtime-/Domainkomponenten besitzen Gameplayzustand.
- UI/3D zeigen Snapshots und senden Commands; keine zweite Auftrags-, Orts-, Personal-,
  Loadout-, Inventar- oder Transportwahrheit.
- get_operations_snapshot() und request_operation(operation, payload) bleiben UI-Brücke.
- TerrainMapData/TerrainRegistry besitzen Grundflächen, Begehbarkeit und Marker;
  Dach-/Cutaway-Darstellung ändert diese Werte nicht eigenständig.
- Der ephemere Basis-Commander bleibt von den taktischen NPCs getrennt.
- Falls Handel/Fuel neue Daten erfordern: kleiner eigener Domain-State mit autoritativen Commands,
  dauerhaft über Basis-/Kartenwechsel hinweg. Nicht im Presenter und nicht ausschließlich
  im deaktivierbaren Bewegungs-SimulationRoot der Erkundungsansicht verstecken.
- AP4 implementiert zusätzlich einen langlebigen Campaign-State für Aufträge, Zielzuordnung
  und Abschlussbelege; Transportphasen bleiben beim vorhandenen Aircraft-/Runtimeowner.
- Planempfehlung für Fuel: feste datenbasierte Kosten je Ortsverbindung, einmalige Abbuchung
  bei autorisiertem Abflug. Kein kontinuierliches Verbrauchs- oder Notfallsystem.
- Keine SceneTree-Vollscans im Hotpath; Control-/Zeilen-Caches und Dirty-/Batch-Updates erhalten.
- Keine Savegame-Migration erforderlich; frische Testprofile verwenden und normale Nutzerdaten erhalten.

Relevante Dokumente:
AGENTS.md; docs/PROJECT_BRIEF.md; docs/ARCHITECTURE.md; docs/CODEX_RULES.md;
docs/IMPLEMENTATION_STATUS.md; docs/TASK_ROADMAP.md;
docs/dev/homebase_operations_ux_contract.md;
docs/dev/homebase_direct_dropship_flow_contract.md;
docs/dev/hex_grid_v1_contract.md;
docs/dev/mission_interaction_point_contract.md;
docs/dev/graphics_reference_revision_contract.md;
docs/dev/player_roster_save_contract.md;
docs/tasks/PLAYTEST_2026_11_05_explorable_homebase.md;
docs/tasks/PLAYTEST_2026_11_05_homebase_operations.md.
Die aktuelle Nutzeranweisung ersetzt die alte Pflicht, Erweiterte Werkzeuge sichtbar zu erhalten,
und die historische UI-first-Basisgrenze; vorhandene Autoritätsregeln bleiben verbindlich.

## Nicht-Ziele im ersten Durchlauf

Keine vollständige Bau-/Lager-/Handelswirtschaft, kein Produktionsnetz, keine große Kampagne,
keine weiteren Außenposten, kein neues Beförderungssystem, keine aufwendige Boardinganimation.
Keine Multiplayer-Neuentwicklung, Engineumstellung, Release-/EXE-Erstellung oder Deployment.
Keine Zusage, dass vorhandene Savegames migriert werden; keine Löschung normaler Nutzerdateien.

## Akzeptanzkriterien

1. Der neue Einzelspielerweg benötigt keinen alten Bildschirm und keinen FOB-Wechsel.
2. Jede reguläre Ansicht hat einen sichtbaren funktionierenden Rückweg; FOB ist nicht aktivierbar.
3. Kompakte Personalansicht sortiert stabil, zeigt reale Identitäten und öffnet Details per Doppelklick.
4. Personen → neuer Trupp, Wechsel/Entfernen und Fireteam → Schiff funktionieren per Drag-and-drop,
   ohne Duplikate, verlorene Mitglieder oder Umgehung von Transit-/Kapazitätsgrenzen.
5. Ausrüstungslots und Rollen-/Rangdarstellung lesen bestätigte Profile/Loadouts.
6. Zwei Gebäude sind durch echte Türen erreichbar und innen einsehbar; zwei Pads, Servicepunkt,
   Wege und spätere Erweiterungsflächen bilden eine zusammenhängende Karte.
7. Auftragsboard, Regionalkarte, Planung und Abflug zeigen denselben Auftrag und dessen Zielort.
8. Annahme eines Auftrags löst keinen Flug oder automatischen Missionssieg aus.
9. Abflug zeigt das ausgewählte reale Schiff am richtigen Pad; Transit/Rückkehr bleiben pro Craft getrennt.
10. Satellitenauftrag hat einen ausführbaren Start, sichtbaren Fortschritt, einmaligen Abschluss und Rückflug.
11. Handelsort erlaubt eine echte begrenzte Transaktion und Service über autoritativen Zustand;
    eine reine Händlerkulisse gilt nicht als fertiger Handel.
12. Normaler Gesamtablauf ist bei 1280×720, 1920×1080 und 3440×1440 nativ bedienbar;
    technische Gates, gestalterisches Urteil und menschlicher Playtest werden getrennt ausgewiesen.

## Betroffene Dateien / lokale Prüfung

Die konkreten Arbeitspakete, Dateipfade und Prüfungen stehen im
[Umsetzungsplan](../superpowers/plans/2026-11-09-singleplayer-basis-orte-ui.md).
Die urspruengliche Planungsphase enthielt keine Spielcodeaenderung. Die danach
autorisierte Umsetzung wurde mit Godot 4.6.2 geprueft, inklusive echtem
Zweiausflugslauf 60/60, 20 fokussierten Gates und sechs Transportregressionen.
Native OS-Bedienung, Grafikurteil und allgemeine Leistung bleiben getrennt offen.

## Risiken / offene Punkte

- „Cutlist“ genau zuordnen, bevor ein konkretes Element entfernt wird.
- Dienstgrad versus Rollen-/Fähigkeitsbadge vor Rangsortierung definieren; keine Beförderungsregeln erfinden.
- Smart Mobile ist die vorgeschlagene Arbeitsbezeichnung; finales Label/Anordnung bleiben gestaltbar.
- Zwei bis drei Karten sind als drei Orte einschließlich Basis ausgelegt.
- Minimalhandel braucht neue kleine Domainlogik; Umfang vor Code eng festlegen.
- Innenräume benötigen Navigation und Kollision zusätzlich zur Dachoptik.
- Boardingvisualisierung optional; sie darf den ersten durchgängigen Ablauf nicht blockieren.

## Git- und Quellenstand

Der urspruengliche Planungsbranch basierte auf integration/core-foundation.
Umgesetzt wurde auf dem frischen task/singleplayer-loop-20261109 ab main
ed77c1058, damit die 91 neueren Maincommits erhalten bleiben. Produktstand nach
Reviewfixes: 6d0e463fe. Direkte lokale Mainintegration anschliessend vom Nutzer
autorisiert; weiterhin kein Push/Release. Der gemeinsame Integrationsbranch bleibt
unveraendert. Exakte Pruef- und Integrationsbelege stehen im QA-Paket.
