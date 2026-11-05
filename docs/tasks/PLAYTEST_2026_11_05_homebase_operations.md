# Heimatbasis: Personal, Trupp, Ausruestung und begehbare Basis

## Ziel / Problem
Die alte mehrspaltige Arbeitsoberflaeche bleibt textlastig und weit von den
bestaetigten 2D-Zielen entfernt. Der Nutzer verlangt einen echten Umbau:
grosse Portraets, klaren Vierertrupp, ein ausgewaehltes Mitglied mit drei
lesbaren Ausruestungsselektoren sowie kompaktes Boarding/Abflug und begehbare Basis.

## Ursache / Sinnhaftigkeit
Historische feste Pixelgrenzen und viele gleichzeitige Arbeitsfenster verdecken
den normalen Weg Trupp -> Ausruestung -> Boarding -> direkter Missionseinstieg.
Die vorhandenen Homebase-/Aircraft-Owners besitzen bereits die benoetigten
Zustaende und Callbacks. Ein einmal gebauter Presenter projiziert diese Daten.

## Umfang / Nicht-Ziele
- Neue primaere Navigation: Basis erkunden, Personal, Trupp & Ausruestung,
  Einsatz & Abflug. Einstieg in die handlungsfaehige Truppansicht.
- ExplorableHomebase als echte interaktive Bühne mit eigenen lokalen Runtime-
  Nodes integrieren. Nur im Modus Basis aktiv; versteckt keine Basisverarbeitung.
- Bestehende IDs, Profile, Fireteamdefinitionen, Loadouts und AircraftManager
  lesen. Whitelist-Bridge delegiert Aktionen an die bestehenden Ownercallbacks.
- Details/alte Werkzeuge erhalten, alte NodePaths bleiben bestehen.
- Kein neuer Roster-, Inventory-, Transport- oder Missionsbesitz; kein FOB-Zwang,
  keine Save-/Rosterwrites, keine Engine-/Gitaktion durch diesen Untertask.

## Dokumente / Contracts
AGENTS, PROJECT_BRIEF, ARCHITECTURE, CODEX_RULES, IMPLEMENTATION_STATUS,
PLAYTEST_2026_11_05_fullscreen_ux_visuals, homebase_operations_ux_contract,
homebase_direct_dropship_flow_contract, ui_native_design_contract und
graphics_reference_revision_contract. Bilder menu_heimatbasis.png und
menu_fob_loadout.png unter docs/reports/assets/ui-2026-11-01 direkt angesehen.

## Akzeptanzkriterien
- Responsive Nachbesserung vor Code, 05.11.: Die native 1280x720-Aufnahme
  `output/playtest_20261105/native_logical_sizes/20261105T085433Z-a588f435/visual_1280_captures/02_homebase.png`
  belegt RED: vier Spalten lassen Personennamen und Rollen buchstabenweise
  umbrechen. Bei Workspacebreite unter 1450 zeigt Trupp & Ausruestung nur
  Personal/Trupp/Ausruestung mit etwa 32/30/38 Prozent; die weiterhin lesbare
  Gesamtansicht ab 1600px behaelt ausdruecklich vier Spalten. Einsatz & Abflug bleibt
  ueber seine sichtbare Navigation als bestehender Dreispaltenmodus erreichbar.
  Personal behaelt zwei, breite Ansichten vier Spalten. Native 1920-
  Aufnahme desselben Laufs ist lesbar und bleibt in ihrer Aufteilung erhalten.
- Personenzeilen reservieren mindestens 96px Portraet, 100px Namen-/Textbereich,
  40px Zuweisung und die vorhandenen Abstaende. Rolle/Status brechen nicht
  buchstabenweise um; volle Texte bleiben als Tooltip erreichbar.
- Der bestehende Verifier behaelt alle bisherigen Gates und ergaenzt echte
  Rootgroessen 1280x720 sowie 1920x1080, Spalten-/Zeilenbreiten, Namensbreite,
  sichtbare Flightnavigation und unveraenderten Operationsstate beim Navigieren.
  Native Nachpruefung durch Root bleibt erforderlich; kein Ownerregelwechsel.
- Neue Hauptoberflaeche zeigt reale Portraetidentitaeten, vier Truppplaetze,
  fokussiertes Mitglied und lesbare Ruestung/Primaer/Sekundaer-Auswahl.
- Echte Unit-IDs zuweisen/entfernen, Loadout aendern, boarden, ausladen und
  starten delegieren an bestehende Callbackpfade. Leere/belegte/Transit-
  Zustaende haben korrekte, knappe Gates; andere freie Teams bleiben bearbeitbar.
- Keine Diagnose-/Snapshot-IDs oder dauerhafte Textwaende auf der Hauptansicht.
- Versteckter Presenter pollt nicht, Controls und ID-Caches werden wiederverwendet.
- Basis aktiviert nur ihren Branch und ihre Kamera; Terminals oeffnen echte
  Personal-/Trupp-/Flightdeck-/Missionsansicht. Verstecken pausiert nur die Basis.
- Native 3440x1440/1920x1080/1280x720-Pruefung durch Root: Controls erreichbar,
  Scroll/Crops/Dropdowns und normale Route ohne FOB. Nutzerurteil separat offen.

## Betroffene Dateien
scripts/meta/homebase_screen.gd, scripts/meta/homebase_operations_presenter.gd,
scripts/tests/playtest_20261105_homebase_operations_verifier.gd und dieser
Untertask/UXContract. Explorable-Szene wird nur eingebunden, nicht bearbeitet.

## Lokale Pruefung
Gezieltes neues Gate vor Produktcode an Root als RED-ready melden. Root fuehrt
Enginegate/Import und nativen Vollbildvergleich seriell aus. Statische Checks
und gezielte Quellpruefung hier; keine pauschale UX-/Releaseabnahme.

## Risiken / offene Punkte
Legacy-NodePaths muessen trotz versteckter alter Panels erhalten bleiben.
Beschaeftigte Transportpayloads duerfen durch neue Aktionen nicht umgebaut
werden. Layout und echte Lesbarkeit benoetigen die nativen Root-Aufnahmen.

## Status
Native Root-Aufnahme `security_scope/20261105T072613Z-0d68a564/security_scope_captures/02_homebase.png`
zeigt trotz 46/46 gruenem Enginegate einen abgeschnittenen Fokusportraetkopf:
176px Hoehe mit voller Spaltenbreite und COVERED. Korrekturziel vor Aenderung:
quadratischer 176/224px-Block mit KEEP_ASPECT_CENTERED neben Name/Rolle bei
genuegender Breite, sonst untereinander. Schiffsvorschau muss denselben
hashgebundenen Ref03-Cutlass-UIhelper wie vorhandene Schiffskarten lesen.
Groessere Personenbilder und begrenzte Kartenhoehen ersetzen hohe Leerflaechen.
Native Abnahme folgt erneut; Enginegruen allein ist keine Bildabnahme.

Zusaetzliche konkrete Akzeptanz vor der Remove-Korrektur: Entfernen gibt die
Person auch aus dem globalen Staging frei, sodass sie wieder als Pilot waehlbar
ist. Entfernen oder Wechsel des letzten Mitglieds hinterlaesst keinen
Fallback-Geistereintrag in `member_unit_ids`. Codebefund: die alte Zuweisung
aenderte nur `_selected_fireteam_ids`; `_get_member_unit_ids_for_fireteam`
las bei null Treffern das alte Definitionsfeld erneut. Die bestehende
Zuweisungsstelle muss deshalb die alte Definitionsmitgliedschaft mitpflegen.
Regression: echten Trupp bis leer entfernen, freie Person als Pilot zuweisen,
Trupp wieder aufbauen; Transit sperrt den alten Payload, freie weitere Trupps
bleiben bearbeitbar. Keine zweite Mitgliedschaftswahrheit einfuehren.

Vertrag und Akzeptanz vor Code angelegt. Root bestaetigt RED auf dem vorherigen
Produktstand: `output/playtest_20261105/registry_base_homebase_red/20261105T071206Z-24452be9/homebase_operations_red.log`,
0 PASS / 2 FAIL wegen fehlender Snapshot-/Bridge-Methoden, keine Parsefehler.

Neue Hauptoberflaeche und bestehende Ownerbridge implementiert: Personalreihen
nach ID gecacht, vier Truppplaetze, grosses fokussiertes Portraet und genau
drei Ausruestungsselektoren, getrennte Pilot-/Schiffs-/Einsatzwahl und klare
Boarding-/Abflugaktionen. Die echte Base-Szene wird bei Bedarf aktiviert.
Legacyoberflaeche bleibt ueber Erweiterte Werkzeuge erreichbar. Standard-
Portraetresolver/Legacy-Aliase werden auch von alten Homebase-Pfadladern gelesen.

Source-ready an Root gemeldet; Engine-GREEN und nativer Groessen-/Eingabetest
stehen noch aus. Kein Engine-/Gitlauf dieses Agents. Gezielte statische
Pruefung loest alle neuen lokalen Callbacknamen auf und findet weder
Replacementzeichen noch nachlaufende Leerzeichen in den drei neuen/angepassten
Produkt-/Testdateien. Keine gestalterische Abnahme daraus abgeleitet.
