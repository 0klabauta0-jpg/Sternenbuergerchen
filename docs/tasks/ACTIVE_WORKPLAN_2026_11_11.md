# Aktiver Arbeitsplan und Abschlussliste — 11.11.2026

## Ziel / Anlass / Arbeitsbasis
Der Nutzer moechte die offenen Arbeiten parallel bis zu einem nachvollziehbaren
Abschluss voranbringen. Grosse Tests sollen jetzt entfallen und spaeter gebuendelt
stattfinden. Karten/Hoehen bleiben ausdruecklich Teil des Auftrags. Dieser Plan
baut auf dem noch nicht nach Main integrierten Taskbranch
`task/native-glut-maps-20261110`, gesichert bis `e55206832`, auf.
Historische QA-Zahlen unten sind Belege dieses Standes, keine neuen Testlaeufe.

## Jetzt in Arbeit (getrennte Besitzbereiche)

1. **Hex-Rampen und Plateaus:** explizite gerichtete Rampenzelle statt automatischem
   H1-Aufstieg. Vertrag `docs/dev/explicit_hex_ramps_contract.md`; gemeinsame
   Map-/Tile-/Navigation-Wahrheit und Darstellung/Picking/FoW muessen folgen.
   Normale Plateauklippen bleiben unpassierbar. Groessere Bewegungsabnahme spaeter.
2. **Kartenkomposition:** A/B/C weiterhin je512x256. Zusammenhaengende Hochflaechen,
   Steilklippen, erkennbare Aufstiege und ruhige Wege nach den vorhandenen
   Glut-Referenzen. Kreativer Agent liefert getrennte Kandidaten; alte Karten,
   Missionsmarker, Pad-/Objektfootprints und Quellen erhalten. Erst nach Sichtung
   integrieren, nicht jeden Kandidaten als fertige Karte ausweisen.
3. **Bedienhilfe:** Escape-Menue erhaelt eine erreichbare Kartensteuerung.
   Tatsachliche vorhandene Kamera-/Zoom-Bindings nachlesen, keine neuen Befehle
   und keine geaenderte Eingabebelegung. Details im folgenden Taskabschnitt.

## Bereits integriert im Taskstand

| Bereich | Vorhandener Stand | Noch keine Abschlussaussage fuer |
| --- | --- | --- |
| Karten und Sternkarte | A/B/C512x256, Sternkarte256x256,3Orbitmarker jeKoerper, Liste und Karte | Neue explizite Rampen, neuer Kompositionskandidat, persoenliche Stilabnahme |
| Vollstaendige Gelanderessourcen | Vor Missionsbeginn2161/2161Chunks vorbereitet; Fernschwenks verwenden dieselben Ressourcen | Neue Rampen-/Kartenversion braucht spaetere erneute Abnahme |
| GO/Wegsuche | Begrenztes gemeinsames Suchbudget besser genutzt; echterB-Nachlauf vorhanden | Allgemeine Ruckelfreiheit; neue Hexbelegung/Reservierungen |
| Ruestung | R07: eigener breiterer Koerper, moderat kleinerer Kopf,3Ruestungsklassen, geschlossene Helme | Nutzerurteil, Sitz-/Transportextreme |
| Ausruestung | Gemeinsame Inventaransicht, endlicher Bestand, intrinsischer Datenslot, optionaler Rucksack | Vollstaendige manuelle Ende-zu-Ende-Abnahme nach allen Umbauten |
| Punkte-Skirmish |1000/1500Budget,3Erfahrungsstufen, Personalpakete/Rekrutieren/Entlassen, Infrastruktur und aktuell spielbare Schiffe | Finale Balance und gesamtes vereinfachtes Charakterwertesystem |
| Charakterdarstellung | Kompakte Rollen, Status, Badges; 3Erfahrungsstufen, Detailwerte aufklappbar | Neues Wertemodell, keine abgeschafften internen Faehigkeitsachsen behaupten |
| Portraets | Gezeichnete Varianten im Katalog statt der verworfenen neuen Fotovarianten | Persoenliche Bild-/Varianzabnahme |
| Kampagne | Bestehende5Auftraege/3Rezepte und Freischaltungen | Fortlaufender Runtime-Forschungsbaum |
| Kampagnenplanung | Lokale editierbare `docs/reports/campaign_research_workbench.html`, Voraussetzungen/Belohnungen/Notizen/Export | Hosting oder automatische Uebernahme in Spielstaende |

## Anderer Chat: abstimmen, nicht parallel neu erfinden

`Tabletop-Faktoren fuer Performance pruefen` untersucht Sicht-/Erkennungsdaten,
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
  bezahlte echte Heimatpads3..6. Eigener Agent arbeitet an der Integration.
  Schiffswaffen-/Komponenten-Ausruestungsowner und lokaleSchiffsabholung sind
  technische Restpunkte; kein bloss dekorativer Kauf als fertigeFunktion.
