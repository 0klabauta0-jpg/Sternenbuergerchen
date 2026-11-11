# Aktueller Restplan nach Polisa-Freigabe — 11.11.2026

Diese Uebersicht ersetzt die offenen Listen in der historischen Fortschreibung darunter.

Neuster Bewegungsstand: auch Bewegungsschuss a74fbab2f als 615327eaf integriert,
frischer enger gemeinsamer MovingShotlauf 65/0 mit Guards grün. Fähigkeitsfaktor
0.65..0.95 ausdrücklich vorläufig; kein zusätzlicher Wurf, Profilread pro Effect.
Türmutationsguard und Backoff sowie AP6–8 bleiben offen. Die zwei eng benannten
Driver-Türproducerbereiche sind für den Tabletop-Chat freigegeben.

Aktueller Bewegungsnachtrag: Gruppenankunft/3D-View aus 5a8544fea jetzt als
6a3f9c535 integriert, enger gemeinsamer Consumerlauf 65/0 mit Guards grün.
Diese beiden Punkte sind erledigt; Türguard, Bewegungsschuss, Backoff und
AP6–8 bleiben beim Tabletop-Chat. Native Animation und große Tests später.

- **Neue Orbitvorgabe:** genau ein gemeinsamer Bereich pro Stern/Planet/Mond,
  lokal 512 × 256; strategische Karte 256 × 256. Oben mittig ein großer Körperbogen
  nominal 256 Felder breit und höchstens vier tief, Ankunft unten, Oberfläche erst
  am erreichbaren Saum. Jedes fliegende Schiff einschließlich Dropship in genau
  einer kanonischen Rotte. Reine Layoutvorbereitung 8/0 und Compile sauber;
  Runtimeanschluss mit Weltraumkampf-Chat abgestimmt in Arbeit. Der bisherige
  Drei-Marker-Produktpfad bleibt bis zum vollständigen Anschluss bestehen.
  Vertrag: `docs/dev/orbital_approach_contract.md`; Task:
  `docs/tasks/ORBITAL_APPROACH_MAPS_2026_11_11.md`.

- **Polisa:** R08 gestalterisch vom Nutzer freigegeben. Grundform/Massstab bleiben; keine weitere Grafikrunde beauftragt.
- **Parallele Orte:** View-/Servicekorrektur implementiert: Heimat/Polisa/Einsatz auf bestehenden Ortsroots ansehen, Hintergrundankunft behaelt Fremdansicht, explizite Serviceschiffwahl und lokale Basisguards. Frische kleine Viewprobe44/0, Serviceprobe30/0, Flow/Adapter Compile0 und unabhaengiger Review nach Korrekturen. Echte Mehrortreise/-gefechte/-kaeufe noch nicht abgenommen; Vertrag und Crew-Faehrgrenze in parallel_location_operations_contract.md.
- **Bewegung:** AP4/Korridorcache, Projektion3095c11b0 und Stopkernfd8ed553a erhalten; echtes AP5-Commands-/2DActorpaket a66b84522 nach unabhaengigem Review als c5e536d0d integriert. Gemeinsamer ActualMove42/0, Polisa-Ownerheimkehr18/0 und Root/Runtimecompile0. 3DView-/Fireteamankunft, Tuerguard, Bewegungsschuss/Backoff und Lifecycle-/Save-/Authoritygrenzen folgen im Tabletop-Chat. Keine Produktionskarte aktiviert und keine FPS-/Gesamtfreigabe.
- **Profilanzeige:**6308e6f02 integriert: exakte Vorlagenzuordnung, individuelles Profil und Profilwirkung aus bestehenden Ableitungen. Keine neue Tempo-/Combatformel; interne Wertevereinfachung bleibt abgestimmt offen.
- **Forschung:**84dd481b1 integriert: Recycling von Bergungsgut zu vorhandenen Rucksaecken auf bestehendem Supply-/Inventarowner. Forschung100Cr, Fertigung2salvage+20Cr als erste Balance. Workbench-Ist-Baseline auf23Knoten aktualisiert; keine native Gesamt-/Balanceabnahme.
- **Schiffe:** Warp-Slot b67b307b0 (Odyssey C/Hemera A) gesichert; Qualitaet D bis A, Kosten/Bestand vorlaeufig. Lokale Polisa-Abholung jetzt als Alternative zur Heimatlieferung angeschlossen: echtes unbemanntes Schiff auf freiem passenden Pad, explizite Crew-/Pilotuebergabe, Boarding/Rueckflug und versionierte Erwerbsbelege. Heimatpad bleibt reserviert, Save weiter nurHome. Frische enge Vertikal18/0/Flow23/0/Backend43/0, Helper27/0/Controller26/0 als Teilbelege. Native Weg-/Presencecommit-/Rueckreise-/Saveabnahme spaeter. Umgeruestete Skirmishschiffe bleiben bis konsistenter Retire-Historie rueckgabegesperrt. Waffen und neue Fahrzeugmodelle bleiben offen/zurueckgestellt.
- **Spaeter:** grosse gemeinsame Spiel-/Performance-/Save-/Netzpruefung, dann Main/EXE. Keine erneute grosse Matrix jetzt.

Konkrete Zustaendigkeiten und Grenzen: RESTPLAN_FORTSETZUNG_2026_11_11.md.

---

## Historische Fortschreibung (aeltere offene Listen sind ueberholt)

# Aktiver Arbeitsplan und Abschlussliste — 11.11.2026

## Ziel / Anlass / Arbeitsbasis
Der Nutzer moechte die offenen Arbeiten parallel bis zu einem nachvollziehbaren
Abschluss voranbringen. Grosse Tests sollen jetzt entfallen und spaeter gebuendelt
stattfinden. Karten/Hoehen bleiben ausdruecklich Teil des Auftrags. Dieser Plan
baut auf dem noch nicht nach Main integrierten Taskbranch
`task/native-glut-maps-20261110`, mit Editorabschluss `c8c7b7d3b`, auf.
Historische QA-Zahlen unten sind Belege dieses Standes, keine neuen Testlaeufe.

## Aktueller Arbeitsstand

- **Gelaende und Editor integriert:** A/B/C bleiben 512x256. H0-H8-Plateaus,
  breite gerichtete Hex-Rampen, geschlossene Eckanschluesse und Editor mit
  3D-Pinselvorschau, sechs Richtungen, Undo/Redo und Save. Gesichert bis c8c7b7d3b.
- **Tabletop-Integration:** Foundation, AP1 und das erste AP3-Readerpaket sind nach statischem Review im
  Taskstand (22dc4cb61/0bc338151/7b532a316/2ff978d1a). Kontakt, Schusspruefung und
  FoW teilen die logische Sicht. Sicherung/Facing/Overwatch sind als b3d5f4b62 integriert. Der reine
  AP4-Reservierungsplaner30840746c liegt vor; verbindlicher Owneranschluss und
  Bewegung werden im abgestimmten Tabletop-Chat fortgesetzt. Kartenaktivierung erst nach den weiteren
  Bewegungs-/Lifecycle-Vertraegen; bisher keine Aktivierung.
- **Forschungsfortsetzung:** Industrie/Bergungswerkzeug auf vorhandenen
  Forschungs-, Herstellungs- und Ortsressourcen-Ownern integriert (1f676bfbc).
  Werkstatt und gefertigtes Mining-Tool -> Entwicklung160Cr -> Einzelwerkzeug40Cr.
  Planungs-Workbench an den Ist-Stand angeglichen (ba4135069).
- **Polisa:** Funktionskandidat und R02-Visual integriert; Tankservice und
  Frachttransparenz sind ergaenzt (538eb737e): fehlende Tankmenge und Preis,
  echter Schiffslagerbestand, kontrollierter Service-/Adapterverlust. Schiffskomponenten brauchen noch echte
  Runtime-Verwaltung; dazu konkreter Anschlussvertrag statt funktionslosem Kauf.
- **Pruefumfang:** Nur notwendige enge Compile-/Domainkontrollen jetzt.
  Grosse Gefechts-, Performance-, Save-/Netzwerk- und Bedienmatrizen spaeter.

## Bereits integriert im Taskstand

| Bereich | Vorhandener Stand | Noch keine Abschlussaussage fuer |
| --- | --- | --- |
| Karten und Sternkarte | A/B/C512x256 mitH0-H8-Plateaus und breiten expliziten Rampen integriert5204312c0; Sternkarte256x256,3Orbitmarker jeKoerper | Neue Karten im Gefecht/SaveContinue, persoenliche Stilabnahme |
| Vollstaendige Gelanderessourcen | Vor Missionsbeginn2161/2161Chunks vorbereitet; Fernschwenks verwenden dieselben Ressourcen | Neue Rampen-/Kartenversion braucht spaetere erneute Abnahme |
| GO/Wegsuche | Begrenztes gemeinsames Suchbudget besser genutzt; echterB-Nachlauf vorhanden | Allgemeine Ruckelfreiheit; neue Hexbelegung/Reservierungen |
| Ruestung | R07: eigener breiterer Koerper, moderat kleinerer Kopf,3Ruestungsklassen, geschlossene Helme | Nutzerurteil, Sitz-/Transportextreme |
| Ausruestung | Gemeinsame Inventaransicht, endlicher Bestand, intrinsischer Datenslot, optionaler Rucksack | Vollstaendige manuelle Ende-zu-Ende-Abnahme nach allen Umbauten |
| Punkte-Skirmish |1000/1500Budget,3Erfahrungsstufen, Personalpakete/Rekrutieren/Entlassen, Infrastruktur und aktuell spielbare Schiffe | Finale Balance und gesamtes vereinfachtes Charakterwertesystem |
| Charakterdarstellung | Kompakte Rollen, Status, Badges; 3Erfahrungsstufen, Detailwerte aufklappbar | Neues Wertemodell, keine abgeschafften internen Faehigkeitsachsen behaupten |
| Portraets | Gezeichnete Varianten im Katalog statt der verworfenen neuen Fotovarianten | Persoenliche Bild-/Varianzabnahme |
| Kampagne | Bestehende5Auftraege, Schutzforschung und Bergungswerkzeug-Industriezweig | Rohstoffverarbeitung, Fahrzeug-/Flottenforschung; native Forschungs-/Bergungs-/Save-Abnahme |
| Kampagnenplanung | Lokale editierbare `docs/reports/campaign_research_workbench.html`, Voraussetzungen/Belohnungen/Notizen/Export | Hosting oder automatische Uebernahme in Spielstaende |

## Anderer Chat: abstimmen, nicht parallel neu erfinden

`Tabletop-Faktoren fuer Performance pruefen` implementiert abgestimmt Sicht-/Erkennungsdaten,
Zielsuche, Skill-/Auftragsreaktionen, Wuerfelmodell und logische Hexbelegung.
EinNPCproFeld ist Nutzerziel; Zeitfenster/Vorfahrt sind noch Entwurfsdetails.
Die dortigen Square-Diagnosen sind keine FPS-Abnahme aktueller512x256Karten.
Keine unabgestimmte zweite Bewegungs-, Sicht- oder Reservierungswahrheit bauen.
Der neue Rampenvertrag ist dem Chat zur Abstimmung uebermittelt; Rampenachse
ist in beide Richtungen begehbar. Logische Standhoehe am Zentrum ist H+0.5.

## Danach in dieser Reihenfolge

1. **Neue Rampen/Karten zusammenfuehren:** Standhoehen, Anschlusskanten,
   Regelversion, gespeicherte Richtung, Picking/Raster/Nebel und Cachekontext.
2. **Bedienung im Gesamtweg:** Basis -> Trupp/Ausruestung -> Abflug -> Sternkarte
   -> Landung -> GO -> Rueckflug -> Upload. Bestehende Commands erhalten,
   unklare oder widerspruechliche Rueckmeldungen gezielt bereinigen.
3. **Werte/Faehigkeiten abschliessen:** Drei Spieler-Erfahrungsstufen und klare
   Rollen bleiben Ziel; interne Werte erst mit dem Tabletop-Entwurf vereinfachen.
4. **Forschungsfortsetzung entscheiden und integrieren:** Workbench-Vorschlaege
   zu Schutz/Industrie/Fahrzeugen auf konkrete vorhandene Rezepte und Owner
   abbilden. Kosten sind Vorschlaege. Keine erfundene bereits fertige Forschung.
5. **Kampagnen-/Skirmish-Gesamtstand abnehmen**, dann Integration/EXE separat.

## Ausdruecklich zurueckgestellt

Neue Fahrzeugmodelle und Spezialfunktionen: Caterpillar, Vulture, Prospector,
Hornet, Gladius, Sabre, Vanguard, Valkyrie sowie Nova(Panzer)/Cyclone(Jeep).
Die vorhandenen Konvertierungen sind Quellen/Kandidaten, keine spielbereiten
Fahrzeuge. Danach ggf.Caterpillar zuerst. Freies Basisbauen, umfangreicher
Content und tiefe Fahrzeugsysteme sind kein stiller Teil dieser Abschlussrunde.

## Spaetere gebuendelte Pruefung / praktische Abnahme

- Neue Rampen: beidseitiger Auf-/Abstieg, gesperrte Plateau-/Seitenkanten,
  Zwischenpodeste, A*/HPA/tatsaechliche Bewegung, Save/Continue und Cacheinvalidierung.
- A/B/C: Lesbarkeit/Wege, ganze Karte laden, Fernschwenks, echteGefechte1x,
  CPU/GPU/RAM und Frame-Spitzen auf finalem Stand. Die letzten alten
  Gefechtsmessungen zeigten weiterhin sichtbare Frame-Tails; kein FPS-PASS.
- R07: Sitzen, Transport/Ein-/Aussteigen, extreme Posen, Nutzervergleich zurVorlage.
- Bedienung: Maus/Tastatur in Basis/Einsatz/Sternkarte, FullHD/1280x720 und
  schmalere Ansicht, Hilfe/Escape/Zurueck, Auswahl und moegliche UI-Ueberlappung.
- Punkte:1000/1500, Rekrutieren/Entlassen/Lager/Pads/Abflug; Kampagnenstart,
  Auftraege/Upload/Weiterladen. AlteBelege nicht als neueAbnahme ausgeben.
- Nach abgestimmtem Tabletop-Umbau: Kontakt/Sicht/Ziel/Bewegung gemeinsam.
- Main-Integration und neue EXE sind weiterhin eigenstaendige offene Schritte.

## Kleiner Task: erreichbare Kartensteuerung

**Problem/Ursache:** Die vorhandenen Kameraaktionen sind ueber mehrere Screens
verteilt, im globalen Spielmenue steht keine lesbare Referenz. Eine reine
Anzeigehilfe kann die Bedienung klaeren, ohne das Zielsystem anzufassen.

**Umfang:** `scripts/ui/global_escape_menu.gd` und ein Katalogeintrag
`shell.map_controls` in `data/contextual_help_catalog.json`. Menuebutton,
scrollbare Leseseite, Zurueck/Escape. Keine Eingabe-/Gameplaymutation.
Relevante Vertraege: `contextual_help_popup_ux_contract.md`, Architektur-
Wahrheitsgrenzen und vorhandenes Escape-Menue (Einsatz laeuft weiter).

**Bestand:** `project.godot` CameraActions, `MissionMapCameraController` und
`StarMapCanvas` wurden gelesen. Einsatz: WASD/Pfeile, mittlereMaustasteziehen,
Rad, Q/E. Sternkarte: mittlere/rechteMaustasteziehen und Rad. Die aktuelle
mittlereMaustaste verschiebt; eine alte action namens rotate_drag wird deshalb
nicht als tatsaechliche Drehbedienung beworben.

**Akzeptanz:** Hilfe erreichbar, Escape fuehrt zuerst zur Menueebene zurueck,
Menue/Einstellungen/Hilfe gleichzeitig nicht uebereinander sichtbar. Text
benennt Kontext und tatsaechliche Kameraaktionen. Kein neuer Bindungseditor.

**Lokale Pruefung jetzt:** Nur enger Godot --check-only und JSON/Pfaddiffkontrolle.
Keine neue Testsuite, Gefechtsrunde, Render-/Screenshotmatrix. Native Lesbarkeit,
Tastaturfokus und alle Menuewechsel bewusst spaeter pruefen. Kein Commit/Push
oder IMPLEMENTATION_STATUS-Edit durch diesen Teilagenten; Root integriert.


## Ergebnis dieses Teilpakets

- Arbeitsplan aus vorhandenen Task-/QA-Quellen und aktuellem Vertrag erstellt.
- Kartensteuerung im Escape-Menue implementiert. Quelle bleibt der vorhandene
  Hilfekatalog, Eintrag shell.map_controls. Menuehoehe fuer den siebten Button
  angepasst, Hilfeseite mit Scrollbereich und Zurueck. Escape aus Hilfe wie aus
  Einstellungen zuerst ins Spielmenue. Keine neue Pause oder Tastenbelegung.
- Godot4.6.2 --headless --check-only fuer global_escape_menu.gd: Exit0,
  keine Ausgabe von Script-/Enginefehlern oder Warnungen. Log lokal:
  output/native_glut_maps/controls_help_20261111/check_only.log.
- Katalog JSON lesbar, alle help_ids eindeutig, neuer Eintrag besitzt alle
  required_fields. Enges git diff --check ohne Befund.
- Keine neue Runtime-, Layout-, Klick-, Screenshot- oder Gefechtsabnahme.
  Insbesondere native Menuegroesse/Tastaturfokus bleibt fuer spaeter offen.


## Fortschreibung nach den parallelen Auftraegen
- Kartensteuerung ist ueber Escape erreichbar (0d2864468), nur compile-geprueft.
- Schutzforschung ist jetzt ein erster Runtime-Zweig in der Werkstatt: echter
  C-Chip-Upload, Entwicklung, Medium/Heavy-Bauplan und getrennte Einzelherstellung.
  KleineDomainprobe24/0; Industrie/Fahrzeugzweige bleiben offen. 4e44521fd.
- Eigene Teamcharaktere oeffnen kompakt; bewusster Expertenmodus und drei
  Erfahrungs-Vorlagen ueber bestehenden Owner. KleineDatenprobe163/0, keine
  nativeUI-/SaveAbnahme. Ebenfalls4e44521fd.
- Expliziter Rampenvertrag mit Seitenjoins und Standhoehe H+.5 gesichert97e00aba1.
  Tabletop-Chat hat diese Basis uebernommen und arbeitet isoliert weiter.
- A/B/C-Komposition und Editor-Folgeauftrag sind jetzt implementiert; enge
  Daten-/Formkontrollen statt grosser Gefechts-/Performancelaeufe. Die alten
  Gefechtsnachweise gelten fuer den vorigen Kartenstand, nicht fuer neue Karten.
- Neuer Nutzerauftrag Polisa: zusaetzlicher Planet, begehbare Orbitalstation,
  Waren-/Infanterie-/Ruestungshandel, vorhandene Schiffe mit Heimatlieferung und
  bezahlte echte Heimatpads3..6. Funktionskandidat integriert;18 kleine Domainchecks und15 Compilechecks. Native Reise-/Shop-Abnahme folgt spaeter; eigener Kreativagent verbessert die Stationsansicht.
  Schiffswaffen-/Komponenten-Ausruestungsowner und lokaleSchiffsabholung sind
  technische Restpunkte; kein bloss dekorativer Kauf als fertigeFunktion.

- Tabletop-Chat: Foundation73a485b19 gesichert. AP1 Owner-/Version und AP3 Consumer zur isolierten Fortsetzung freigegeben; Integration gezielt durch diesen Chat. Noch kein aktiver Produktumbau aus der Foundation behauptet.

## Aktueller Anschlussauftrag
Editorgrundlage5204312c0 bleibt aktiv. Jetzt echte nichtmutierende 3D-Hoehenpinselvorschau und gleichmaessige breite Striche (jedes Feld pro Strich nur einmal); Details im EXPLICIT_HEX_RAMP_EDITOR_2026_11_11. Polisa-Funktionskandidat a7f771143 und VisualR02 f06ae7f69 integriert; native Spielwegabnahme offen. Grosse Tests bleiben zurueckgestellt.

Editor-Anschluss umgesetzt: echte3D-Vorschau mitCap/Umriss/Aufwaertspfeil, gemeinsamePatchplanung, einmaligeHoehenaenderungproStrich, UI-Release-/Hide-Behandlung und korrigierteRampenauswahl. KleineProbe12/12, dreiEditorScriptsCompile0 undViewCompile0, unabhaengigerFinalreviewohneBlocker. NativeMaus-/Layout-/Farbabnahme undgrosseTests bleibenoffen.

## Naechste offene Implementierungspunkte

1. Tabletop-AP3 um Sicherung/Facing/Overwatch vervollstaendigen, dann
   zeitliche Belegung/Reservierung und Bewegung (AP4/5) sowie Lifecycle-/Save-/
   Netzgrenzen (AP6-8) im dortigen Chat fortsetzen und gesicherte Pakete integrieren.
   Keine Kartenaktivierung aufgrund bloss vollstaendiger Reader.
2. Vereinfachtes Werte-/Faehigkeitsmodell erst gegen diese stabilen Verbraucher
   abgleichen; die vorhandenen drei Erfahrungsprofile ersetzen nicht automatisch
   alle internen Achsen.
3. Schiffswaffen/-komponenten und lokale Stationsabholung brauchen einen echten
   Owner, Verbraucher und Persistenz. Konkrete Grenzen stehen in
   polisa_ship_equipment_contract.md; beides ist weiterhin nicht implementiert.
4. Verarbeitung und Fahrzeug-/Flottenforschung bleiben weitere Design-/Content-
   schritte. Neue Fahrzeugmodelle bleiben wie beauftragt zurueckgestellt.
5. Danach die ausdruecklich verschobene grosse Abnahme auf dem gemeinsamen Stand;
   Main und EXE sind nach wie vor separate Schritte.

## Polisa nach Nutzerkorrektur R04
Aktuelle Station: oben am Kartenrand, fuenf Frontpads (S/M/L/M/S), keine hinteren Pads. RingeD52, grosse Solarausleger, fuenf24x24Shops mit sichtbaren Waren und zentraler48x32Globusraum. Standardkamera zeigt alle Inhalte ohne Drehung; weitere Kartenuebersicht durch Orbital-Zoom bis280 erreichbar. Kaufmenue nach tatsaechlichem Andocken ohne persoenlichen Schalterzwang; Credits/Bestand/Commands bleiben bei ihren bisherigen Ownern. Kleine Andock-/Kameraprobe9/0 und native Art-/UIbilder, keine grosse Spielwegabnahme. Siehe POLISA_ROOMS_FIVE_PADS_2026_11_11.

## Polisa R06 nach neuester Nutzerkorrektur
Aktuelle isoliert integrierte Station: ein Globusraum, fuenf Shops, sieben Pads, zwei Ringe, aeussere Ausleger auf512x256. R05Dreifachstation1024x512 wurde verworfen/nicht produktiv integriert. Neue KI-Illustration alsLeitbild; nativeKonturen/Moeblierung bleiben hinterderIllustration. Produktkarten38bc35468 mitganzen2D-Ruestungsbildern undechtemSupplykauf. R06NativeProduktkarte/-scene fehlerfreibildgeprueft; kleineDeck-/Kameraprobe10/0 undAuthoring15Checks, grosseTestsweiterhinspaeter. Task POLISA_COMPACT_GLOBE_R06_2026_11_11. TabletopCorridorcache4753975d8+472f1ad8f geliefert; Owner-/Bewegungsintegration bleibtimTabletopChat.

## R07-Grundform bestaetigt; R08-Anschluss
VerbindlicherS-Massstab8x6direktausHeimatbasis. R07mit2358begehbarenDeckhexenund4486gespeichertenTilesistdiegelobteGrundform. KlareresStationsrasterundnativerPadvergleichabgeschlossen. JetztR08nachPOLISA_RING_PORTS_DOORWAYS_R08_2026_11_11.md, keineerneuteGlobalskalierung; grosseTestsspaeter.

## R08 integriert
Grundformbewahrt, Ring-/Solar-/DockausbauundMauer-TuerdurchgaengeimProduktkandidatenintegriert.20kleineAuthoringchecksunddreiaktuelleNativeProduktansichtenbelegt;offenePortalesindkeineinteraktiveTuersimulation, PortskeineneueDockingfunktion. AP4Owner+Reviewfixintegriert, Root/Ground/PathfinderCompile0; AP5Projektion/KorridorcacheanschlussnochimTabletopChat. KeineMapaktivierung,grosseTestsspaeter.
