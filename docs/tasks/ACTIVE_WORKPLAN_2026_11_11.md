# Aktueller Arbeitsplan — 11.11.2026

Diese Uebersicht ist der aktuelle Stand. Die Fortschreibung unter der Trennlinie
bleibt als Historie erhalten und ist keine neue Offenliste.

## Aktiver Auftrag und Grenzen

AP5 bis AP8 selbststaendig mit dem Tabletop-Chat weiterfuehren; Orbitanschluss mit
dem Weltraumkampf-Chat abstimmen. Nur kleine notwendige Integrationspruefungen.
Grosse AP9-Tests spaeter. Vor JEDEM EXE-Build den Nutzer ausdruecklich fragen.
Kein Build beauftragt, keine Mainintegration. Isolierter noch nicht integrierter
Taskbranch task/native-glut-maps-20261110; keine Arbeit direkt auf Main.

A/B/C bleiben 512x256, strategische Sternkarte256x256, lokale Orbitbereiche512x256.
PolisaR08 bleibt gestalterisch freigegeben; neue Fahrzeugmodelle zurueckgestellt.

## Bewegung: AP5 bis AP8

- AP5-Codepfade zusammengefuehrt: Commands/Actorbewegung, Gruppen-/3D-Verbraucher,
  Blickrichtung/Sicherung, Bewegungsschuss, Tuerschutz und Backoff. Backoff55/0
  frisch im gemeinsamen Stand. Native Gesamt-/Balance-/Leistungsabnahme offen.
- AP6a Source86347ca54 als69194ddab integriert: vollstaendige begrenzte
  Gruppenplatzierung und Aufnahme/Freigabe echter Missionsactors. Frisch64/0
  inklusive42 Bewegungsgrundfaellen, Quell-/Profil-/Isolationsguards gruen.
  AP6b-Gruppenvormerkungen Sourcea74514742 plus Bindungsfix0535b3b2f sind als
  68ca862aa/0a63027d7 integriert; frische gemeinsame Slotpruefung88/0 mit Guards.
  Registry-only-Actor ohne Root-Exitbindung wird vor Admission abgewiesen.
  Konkrete Transportphasen Sourcee4b3e4cb8 sind als058fc6e5f integriert, frisch
  privat95/0 Phasen und73/0 echter kontrollierter Controller samt Guards.
  Crew-/Visitfilter und verbleibende Team-/Solo-Pilotregeln im Merge erhalten.
  Fremde Bodyflaechen als begrenzter Raster Source62b1454af sind alsd9059a590
  integriert, frisch52/0 mit Guards.
  Parent55ccb737a reicht echte Homebase-Craftherkunft durch (4/0); b9f194d9e
  liefert geplante/aktuelle Landedgeometrie und stabiles gebundenes Render-Yaw
  (7/0, zwei Compiles0). Unabhaengige Reviews ohne engen Blocker. Konkreter
  Sourceproducer6a+d184 als7fd42e2b6/e0f58b924 integriert, frisch66/0 und73/0
  Controller samt Guards. Echter Controller/Cutlassgetter/Renderjoin6/0 als
  7eff857f5 gesichert. Basiskern Sourcecd830 alsf8238ee28 integriert, frisch63/0
  plus64/0 Lifecycle. Remotehandoff-/Padmethoden erhalten. Gemeinsames
  Boarding/Unboard ist bis3694d35e6/f838c739e integriert: stille Gruppen- und
  Screenpublikation, echte Screenprobe46/0 und Boarding53/0.
  Initiales MissionSetup Source306 als125a905b4 integriert, frisch62/0 plus
  Owner56/0 und Actornachbar24/0; erwartete Schema-Rejectwarnungen dokumentiert.
  Wellen785+c4f sind in enger Review, anschliessend Import. ActorMedicalaf56
  stellt vorbereitete stille Gesundheits-/Befehls-/Kontaktpatches bereit (24/0);
  Root-/Ground-/Respawnmanagerverbund und Member-Retirement bleiben bei Tabletop.
- AP7 Ground524fd61d1 plusPassage8d333eb95: atomarer kanonischer Roundtrip mit
  Terrainrevalidierungsgrenze und ganzen aktiven Kohorten;35/0 nach gemeinsamem
  64-Topologiebudgetfix und unabhaengigem Review. PendingAdmissions bleiben
  klarer Saveguard. GroundPrepared b431a350b (14/0) und AcceptedMovementintents
  f24656107 (30/0) erlauben allValidate vor Ground-/Movementtails; Originalziele,
  Wartealter und Backoff werden semantisch erhalten, keine Queue-/Cachedumps.
  Echte Known-/Registryidentitaet und fehlende Intents gegen Groundcommitments
  sind nach Review abgesichert. Noch kein Root-/Checkpointanschluss daraus.
  MPContract0bef0e658 prueft
  explizite Version vor Normalisierung und verbietet Client-Groundstate rekursiv;
  10/0 plus20/0 betroffener Nachbar, zwei Compiles0. Keine Peer-Sichtfilter dadurch.
  Reiner V2-Fullscope-Publishfilter0134f53ae ist reviewed (20/0), noch unverdrahtet.
  Root-Lifecyclecommandstempel werden im portablen Movementexport nur nach
  echter Rootvalidierung ausgelassen (2eab1f01b,9/0). Session-/Lobbylaufzeitkontext
  ist reviewed und vorbereitet (30/0 nach echtem Snapshotreject-RED24/3);
  Rootbinder, Hostpublisher und Receiver folgen bei Tabletop.
  Er benoetigt originale Hostdaten mit Kopplungsreferenzen; nach verlustbehafteter
  V1-Normalisierung ist keine sichere Positionszuordnung mehr moeglich.
  Restore-/Authoritygrenzen folgen abgestimmt mit vorhandenen Checkpoint-
  und Netzwerkownern. Home-only-/Away-Savegates bleiben. Keine Serialisierung
  privater Claims/Recovery-/Reservierungslisten in Peerpayloads.
- AP8 danach: kleiner opt-in Integrationsslice gemaess Hexplan, keine globale
  Aktivierung der grossen A/B/C-Karten. AP6 bis AP8 sind NICHT abgeschlossen.
  Teilfixture8f3b18a2e verbindet auf12Hexes echte Bewegung/Rampe/Tuer/Sicht/
  Schusspruefung/Ankunft samt Ground-/Movement-Passageroundtrip,15/0.
  Rootcheckpoint, Hostpublisher, Receiver und echte Peers fehlen weiterhin:
  ausdruecklich full_ap8=false. Keine grosse Kartenaktivierung.

Belege: docs/qa/tabletop_restplan_integration_20261111; aktueller Hexplan
unter docs/superpowers/plans/2026-11-11-hex-sight-occupancy.md.

## Orbit: integrierte Schritte und naechste Gates

Root/Fleet/Travel/Flight/Rotte/Raumindex sind gemeinsam integriert. Produktive
Abflug-/Anfluggruppe bis2171e7f25 und lokaler Rueckweg60dc78f62 verwenden
vorbereitete Ownerpatches; Fuel wird beim lokalen Rueckweg erst im gemeinsamen
Uebergang gebucht. Replays binden konkrete Owner samt Einzel-Travelownerepoche.
Anflugabbruch71ec552a0, tactical-Erstbeitrittfix6437af3b6 und validierte
Aufnahme2abd780cc integriert. Enge gemeinsame Tests und Reviews dokumentiert
unter docs/qa/orbit_owner_integration_20261111; keine native Vollreiseabnahme.

OrbitAreaCanvas und Screen-/Flow-Narrowprovider sind angeschlossen. Explizite
Schiffswahl, kein Default-/Erstschiff-Fallback; Positionswahrheit bleibt beim
Root. Kleine UI-Pruefung10/0 und Compiles0, keine native Gestaltungsabnahme.

Versionierte Katalog-/Darstellungsbereitschaft6c899fe77 gesichert: Produkt- und
Draftvalidator getrennt, V3 sechs einzelne Koerperorbits einschliesslich Sonne,
Polisa zusaetzlich als Stationsziel. Strikter V2/V3-Travelreader0bbcee40b als
c1a1de786 integriert und frisch privat mit echten Kaltstarts/Negativfaellen
geprueft; SourceJSON und Spielerprofil unveraendert. LiveJSON bleibt V2.
Wiederanflug nach Abbruch ist mit Source878801344 plus Mehrschiff-Fix21ec46ff5
integriert und frisch privat geprueft. Unverdrahteter Warpankunft-Owner8990daabd
ebenfalls integriert/geprueft; Completionreceipt/Observeraf0bd88f4 als855036033
nach engem Review integriert und privat im gemeinsamen Stand bestanden.
Warpabflug Sourcef311042a0 als7a8129784 integriert, frischer privater Ownerzyklus
lokaler Planet -> Warp -> manuelle Mondankunft bestanden, enger Review geschlossen.
Fruehe Pflichtrotte, ausdrueckliche Heimatlandung und strategischer Polisa-
Stationsstart bisSource605/ed/a9 sind als9c293ac8d integriert; drei frische private
Lifecycleproben samt Guards bestanden. Automatischer lokaler Warptick ist als
standardmaessig ausgeschaltete Vorstufe vorhanden; Retryfix61af7ec9a als8d50f8172
integriert, frische private Entry-/Gatezyklusproben samt Guards bestanden.
Noch offen: gemeinsame Aktivierung und abgestimmter Live-V3-/Einmarkerwechsel
sowie echte Besuchs-/Reiseverknuepfung. Der fuer Polisa-Profilhook244a7354a
benoetigte regulaere Bindungsproducer ist jetzt mit AP6-Source6a integriert.
Polisa-Maske und vorbereitete getrennte Fleet-/Traveloperationen sind bis
Sourcee1559e440 integriert; private Masken-/Ownerproben bestanden. Lesende echte
Gate-/Deaktivierungspruefungen5d4fa0cdd/ee3aafe16 als338d1e333/93da77676
integriert, frisch privat bestanden. Das erzeugt keine Dock-/Visit-/Fuelmutation.
Lesende Dockoverlayd1ba65920 liest das inzwischen vorhandene Root-Dock-DTO.
Dock-/Undockea831 mitCallbackfixes a906/b1d sind als2eaf34cbb/ffdd3cc2e/
b0aa558b0 integriert; frische gemeinsame Dock-/SurfaceCancelproben gruen.
UI785b73306 bietet expliziten Dockcommand nur bei aktuellem RootDTO (10/0).
Kauf-Erstaufnahme e040/1dab+a3c als25e4664d5/8d568332d/0cf33d103,
privat42/0 plus42/0 reentrant. Source069+036 als42cf96602/8570e1da0 verbindet
Polisa-Ankunft und oeffentlichen Kaufabflug hinter weiterhin ausgeschaltetem
Lokalflag; frische oeffentliche Retryprobe42/0 plusgepaarter PolisaOwnerzyklus
bestanden. Echter AP6-/Crew-/UI-/Retirenachweis und gemeinsame Aktivierung
bleiben offen. Sun-V3-Ownerzyklus in privater Datenkopie bestanden, Original-
JSONhash unveraendert. Keine produktive Teilumschaltung. Bekannte Belege:
docs/qa/orbit_owner_integration_20261111/parent_polisa_dock_staging und
parent_polisa_gate. Keine Teilumschaltung mit Einbahnweg. Sonnenorbit
hat keine erfundene Oberflaeche; Polisa bleibt separater Dockpfad.

## Erhaltene weitere Pakete

R07-Ruestungs-/Koerperstand, PolisaR08/Shop-/Padmassstab, lokale Abholung und
explizite Crewuebergabe, parallele Ortsansichten, Warp-Antrieb D bis A,
Profilreadout6308e6f02 und Recycling/Workbench84dd481b1 sind implementiert.
Grosse native Mehrort-/Handels-/Rueckreise-/Save-/Gefechts-/Performanceabnahme
bleibt spaeter. Schiffswaffen, konsistentes Retrofit-Retirement, vollstaendige
interne Wertevereinfachung und weitere Forschungsinhalte sind benannte spaetere
Restpunkte, keine stillen Voraussetzungen fuer neue Modelle oder diesen Slice.

Naechster Kandidat: docs/tasks/NEXT_PLAYABLE_EXE_2026_11_11.md.

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
