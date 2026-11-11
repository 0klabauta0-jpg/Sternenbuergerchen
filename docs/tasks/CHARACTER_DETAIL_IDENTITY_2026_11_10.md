# Grosser Charakterbogen: Identitaet, Zusammenhang und Zusammenarbeit

## Playtest-Nachtrag 11.11.2026

Im gemeinsamen Detailkopf sind Porträt und Figur zu klein. Auf 1280×720
überlagern sich fest positionierte Rollenzeilen. Der Kopf soll neben einem
lesbaren Porträt Name, Hauptrolle, Nebenrolle, Status, vorhandene Bereitschaft,
Kurzprofil und Eignungsbadges ohne abgeschnittene Rollen zeigen. Die reale
3D-Figur erhält mehr Platz und bleibt vollständig sichtbar. Ausrüstung und
Rucksack bleiben erreichbar, auch bei langem Profil und kleinem Fenster.

Umfang: gemeinsames PersonnelInventoryPanel und Modellvorschau, lesende
Profilprojektionen für Basis und Einsatz sowie die vorhandenen Detail-Gates.
Der Vertrag `docs/dev/homebase_direct_dropship_flow_contract.md` bleibt für
Datenbesitz und Inventarzugriffe maßgeblich. Kleine Truppkarten bleiben außerhalb
des Umfangs. Prüfen: Rollen/Status/Profil, Rahmen und nicht überlappende Slots bei
1280×720, 1920×1080 und 3440×1440, Modellgrenzen sowie vorhandene Inventar- und
Compact-Regressionen. Lange benutzerdefinierte Texte dürfen die Kartenhöhe
vergrößern und bleiben im vorhandenen Scrollbereich lesbar.

Der Detailkopf nutzt ein 112×140-Porträt mit umbrechenden Profilzeilen.
Die Wertebereiche des gemeinsamen Bogens stehen untereinander, damit die
breitere Figur und das Inventar im auf 1500 Pixel begrenzten Fenster bleiben.
Der Headless-Layoutlauf bestand 61 Prüfungen. Die projizierten Modellgrenzen
betragen bei 1280×720, 1920×1080 und 3440×1440 rund 352, 376 und 385 Pixel in
der Höhe und liegen vollständig im jeweiligen Vorschaufenster. Die gemeinsame
Einsatzbogen-Projektion ist im Compact-Verifier mit 28 Prüfungen abgedeckt.
Für diesen Nachtrag liegen keine neuen nativen Bildaufnahmen vor.

Status: eigener Umfang implementiert/geprueft, unabhaengige Reviews ohne
Restbefund. Nachweis `docs/qa/character_detail_20261110/README.md`.
Gemeinsame Integration/Push/EXE bleiben am Abschluss des anderen Chats haengen.

## Ziel / Problem und Ursache

Nutzerergaenzung vom 10.11.2026: Der grosse Charakterdetailbogen soll kompakt,
gut lesbar und sinnvoll von oben nach unten gegliedert werden. Name/Bild sollen
bei Standard- und neu erzeugten Figuren zusammenpassen. Beziehungen und
Herkunft von Eignungswerten sollen nachvollziehbar sein. Die kleinen Portrait-
und Rang-/Pilotenkarten waren erwuenscht und sollen gestalterisch bleiben.

Nachgewiesener Standardfehler: Anja Voss erbt Portrait003; die archivierte
Bildvorgabe bezeichnet dieses als maennliche Figur. Portrait004 ist als Frau
mit Commander-Gestaltung dokumentiert. Namen und Portraits neuer generierter
Profile werden bisher unabhaengig gewaehlt. Eine generische Geschlechts-
ableitung aus gespeicherten Namen ist ausdruecklich kein geeigneter Fix.

## Umfang / Nicht-Ziele

- Autorisierte Standardzuordnungen anhand vorhandener Art-Metadaten beheben;
  neue synthetische Figuren aus ausdruecklich zugeordneten Namen-/Portrait-
  Praesentationsgruppen erzeugen. Unbestimmte Vorlagen bleiben unbestimmt.
- Keine ungezielte Aenderung gespeicherter/custom Identitaeten. Eine etwaige
  Migration darf nur einen exakt belegten alten Kampagnenstandard betreffen.
- Vorhandene RNG-Abfolge fuer Werte, Traits und Gameplay erhalten; keine
  zusaetzlichen Zufallsziehungen, die Rollenbalance oder Skills veraendern.
- Im grossen Bogen obere Flaeche fuer Portrait, Name, Startrolle, aktuelle
  Aufgabe, Status und wichtigste Eignung nutzen. Klare, lesbare Gruppen mit
  aufklappbaren Details statt einer langen gleichgewichteten Werteliste.
- Zusammenarbeit nach Namen sichtbar machen: bestaetigte positive/negative
  Affinitaet, deutscher Beziehungstyp und gespeicherter Grund. Keine erfundene
  Kompatibilitaet aus gleichen Traits. Ohne Links: noch keine Beziehung bekannt.
- Bestehende Score-/Trait-Erklaerungen weiterverwenden. Eigene Daten/Kommentare
  bleiben erhalten; keine zweite Profil- oder Beziehungswahrheit im UI.

Nicht enthalten: neue Rollen-/Beziehungsmechanik, Genderinferenz ueber reale
Menschen, neue Portraitbilder, Aenderungen an kleinen Kartenlayouts oder
Ausruestungs-/Editorwerten. Raumkarte und Gameplay bleiben im Orbitauftrag.

## Relevante Quellen / Vertraege

`docs/PROJECT_BRIEF.md`, `docs/ARCHITECTURE.md`, `docs/CODEX_RULES.md`,
`docs/tasks/UI_CLARITY_2026_11_09.md`, vorhandene Portraitidentitaets-/Roster-/
Rangabzeichen-/Beziehungsvertraege, `art/portraits_20261105/atlas_a_prompt.json`,
Portraitmanifest und vorhandenes Review zu nicht eindeutig dargestellten
Vorlagen. `RosterRelationshipModel` besitzt die gespeicherten Links;
`NPCRankBadgeResolver` besitzt die Eignungsberechnung.

## Akzeptanzkriterien

1. Der belegte Standard-Anja-Fehler ist korrigiert; ID und Pfad loesen dasselbe
   dokumentierte Portrait auf. Eine neue Kampagne verwendet diese Zuordnung.
2. Neu generierte Figuren nutzen passende ausdrueckliche Metadatengruppen.
   Gleicher Seed erzeugt dieselben Gameplaywerte/Traits wie vor der Korrektur.
3. Unbekannte/custom Profile werden nicht anhand ihres Namens umgedeutet.
4. Grosser Bogen zeigt Identitaet/Aufgabe/Status und Zusammenarbeit gut lesbar
   oben; Details bleiben erreichbar. Keine bildschirmbreiten Kurzaktionsbuttons.
5. Drei echte Profilfixtures mit verschiedenen Links zeigen unterschiedliche
   benannte Beziehungen und gespeicherte Gruende; fehlende Links werden nicht
   erfunden. Darstellung veraendert weder Profile noch Relationship-Scores.
6. Layoutgrenzen bei1280x720 und1920x1080 sind geprueft. Kleine Karten, Rang-
   Asset-IDs, editierbarer Teameditor und numerische Scores bleiben erhalten.

## Betroffene Dateien / lokale Pruefung

Portraitkatalog/-metadaten, StartRosterGenerator, vorhandene Presets und ggf.
exakt begrenzte Kampagnen-Hydrierung; CharacterSheetView/Formatter/Copy,
HomebaseScreen-Renderoptionen und gezielte Identitaets-/Detailbogen-Verifier.
Test zuerst rot, dann gruen; echte Profile/Viewportrechtecke, unabhängiger
Review. Alle Tests im Hintergrund mit privaten Profilen, keine EXE jetzt.

## Risiken / offene Punkte

Der andere Basis-/Orte-/UI-Chat arbeitet noch. Beide fertigen Staende werden
erst danach gemeinsam integriert und geprueft, auf Main committed/gepusht;
erst anschliessend folgt die gemeinsame EXE. Aktuelle andere WIP-Piloten-/
Personalregeln muessen bei dieser Integration bewahrt werden.
