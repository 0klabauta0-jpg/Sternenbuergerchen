# Sternkarte und Smart Mobile kompakt überarbeiten

## Ziel / Ursache
Nutzersteuerung vom 13.11.2026 erweitert REVIEW_COMPLETION: System, Planet,
Monde und auswählbare Orte links aufklappbar anzeigen; nur derzeit mögliche
sowie erledigte auswählbare Missionen zeigen; individuelle Ortsnamen und eine
kompakte Spieloberfläche nach Star-Citizen-/RTS-Inspiration. Die bestehenden
farbigen Bilder gefallen dem Nutzer und bleiben Bestandteil des Designs.

## Umfang / Nicht-Ziele
Sternkarte und Smart-Mobile-Auftragsoberfläche samt gemeinsamen Anzeigeprojektionen,
gezielten Owner-Verfügbarkeitsregeln und Tests. Kein globaler Skinwechsel, neue
Reisephysik, neue Mission, Belohnungswiederholung, Save-ID- oder Fingerprintumbau.
Die bereits laufenden Hex-/Architektur-/Grafikfixes und Main-/Websiteintegration
bleiben Teil des ursprünglichen Auftrags.

## Verbindliche Gestaltung und Contracts
docs/dev/starmap_smart_mobile_contract.md,
docs/dev/campaign_save_feedback_contract.md,
docs/dev/graphics_reference_revision_contract.md,
docs/dev/html_report_workbench_contract.md.
Referenzen und Bild-KI-Prompts: docs/qa/starmap_mobile_20261113/references/.
Konzept v1 ist zu großflächig; die Nutzerkorrektur verlangt schlanke Leisten,
weniger Rahmen/Leerraum, kompakte Knöpfe und erhaltene farbige Bilder.

## Akzeptanz
- Aufklappbarer Baum System → Planet → Monde → Orte; auch direkte Planetenorte
  und Stationen korrekt. Auswahl/Fokus bidirektional mit der vorhandenen Karte.
- Fokus/Körperklick startet keine Reise. Ortklick nutzt bestehenden Commandpfad.
- Alle Orte sind unabhängig von Reise-/Auftragsfreigabe über eigene
  Ansichtsbuttons erreichbar; gesperrte Zeilen lösen keine Zielwahl aus.
- Orbitalmarker-Ansichtsbuttons stehen direkt beim zugehörigen Körper.
  Nie erkundete Ansichten bleiben schwarz; vorhandene Orte zeigen nur ihre
  autoritativen FoW-Flächen. Kein Besuch, Schiff, Auftrag oder Area wird erzeugt.
  Reine Inspektion verändert keine Owner-/Savezustände und setzt den temporären
  Renderfilter beim Verlassen zurück.
- Nicht mögliche Zukunftsaufträge verborgen; laufende und erledigte relevante
  Aufträge sichtbar. C-Benit-Sonderregeln und Failed/Home-Gate kommen aus Ownern.
- Erledigte Missionen sind lesbar; freigegebene Orte bleiben besuchbar, ohne
  den abgeschlossenen bezahlten Auftrag erneut anzunehmen.
- Einheitliche Anzeigenamen in Baum, Karte, Briefing und Guidance. Bestehende
  alte Home-/Active-Saves und aktuelle Saves bleiben lesbar.
- Kompakte individuelle Typografie/Knopfhierarchie, echte Farbpanoramen/Porträts/
  Ausrüstung erhalten. Keine schwere dekorative Blur-/Shader-/Animationspipeline.
- Kein unveränderter Baum-/Control-Rebuild pro Frame; stabile Nodes/Styles/Fonts.
- Regressionen mit echten Viewportevents bei 720p und 1080p, Keyboardfokus,
  selektierter Route, Filter-/Collapsed-State, Save-/Mission-Nachbarn.
- Native Vorher-/Nachherbilder gleicher Kamera/Zustände öffnen, bewerten und im
  Websitebericht klar von KI-Entwürfen und externen Referenzen unterscheiden.

## Dateien / Prüfung / Risiken
UX-Agent: star_map_screen/canvas, Jobpresenter, reine Name-/Tree-/Verfügbarkeits-
Projektionen, begrenztes Theme und Verifier/Capturefixture. Root: Referenzen,
Fontquellen/Lizenzen, Dokumentation, unabhängige Prüfung, Bericht/Website.
Hex-Agent hält weiterhin alleinige Enginelease und private Snapshots.
Risiken: Hashkompatibilität von Namen, unvollständige Missionsfilter, zu kleine
Schrift/Klickziele, Auswahlverlust beim Refresh, teuerer Control-Rebuild.
Keine Desktop-/Tastaturübernahme; Renderdesktops bleiben nicht aktiviert.

## Präzisierung: Basisdock und Missionsdossier (13.11., Nutzerbild)
Ursache: doppelte Namenseingabe, schlecht platzierte Ranginformationen,
fehlende Bereichstrennung und zu breit gestrecktes Bildband im echten 720p-UI.
Umfang: ausgewählten Namen direkt an seiner bisherigen Stelle bearbeiten,
Enter über bestehenden Rename-Owner; Personenwahl ausschließlich per rechter
Personenkarte. Kein Dropdown, kein zusätzliches Neuer-Name-/OK-Paar.
Porträt links mit mehr Platz, vorhandene Rang-/Erfahrungssymbole rechts davon
oben vertikal; genau zwei dünne Trenner zwischen den drei Dockbereichen.
Satellitendossier: vollständiges Aspect-Fit-Bild links über den Zielen,
Metadaten rechts obenbündig; generischen redundanten Beschreibungssatz entfernen.
Vorhandene bunte Navigationsicons über tatsächliche Assetroute wiederverwenden.
Keine Änderung der Defaultnamen, Gameplayregeln oder Speicherformate.
Dateien: Basis-Personendock, Homebase-Operationspresenter, Jobpresenter und deren
gezielte Regressionen/Capturefixture. Prüfung: echte Enter-Umbenennung mit
Owner-/Savebeleg, fokussierter ungesendeter Text bleibt bei Refresh erhalten,
Kartenwechsel, zwei Separatoren und Layout bei720p/1080p; native Bilder öffnen.
Risiken: Editierfokus gegen laufende Stateprojektion, lange Namen und enge Höhe.

### Eingabe-Nachweis ohne Desktopübernahme
Godot4.6 `Tree` prüft seine eingebetteten Buttons zusätzlich mit
`get_local_mouse_position()`. Im Rootwindow liest das den Betriebssystemzeiger;
`Window.push_input()` allein aktualisiert diesen nicht. Der gemessene Fehllauf
e604 zeigte daher native Receipts=[] bei lokalem Zeiger(-9,-80), trotz korrekter
Eventposition und Tree-Hover. `viewport_tree_button_input.gd` bettet denselben
echten Tree vorübergehend mit identischer Geometrie und Theme in einen privaten
SubViewport ein: dort gelten die Eventkoordinaten. Native Press/Release und
`button_clicked` bleiben unverändert, keine Signale werden direkt ausgelöst.
Danach wird der Tree am selben Containerindex wiederhergestellt; Gesamtbilder
entstehen weiter im normalen Fenster. Kein `warp_mouse` und keine OS-Eingabe.

## Präzisierung: eine Orbitkarte pro Körper
Nutzerbild 4169510a verlangt genau einen `OM`-Ansichtsknopf je Planet/Mond/
Planetoid statt drei nummerierter Ziele. Baum und Kartenmarker zeigen dieselbe
eine körperbezogene Orbitkarte. Bestehende Reise-/Save-IDs bleiben intern gültige
Aliase; keine Katalog-/Fingerprintänderung und keine automatische Reise.
Dateien: NavigationTree, StarMapCanvas, StarMapScreen, vorhandene Flow-Inspektion
und zugehörige Verifier/Capture. Akzeptanz: exakte Knopf-/Markerzahl, echte
Maus-/Enteraktionen, identische Ansicht für alle drei gültigen alten Marker,
Ablehnung unbekannter Marker, unveränderte Owner und Dateien, native720p/1080p.
Redundante Daueranleitungen bleiben im Tooltip; konkrete Reisehindernisse sichtbar.
Risiko: Alias-Markierungen dürfen belegte/angeflogene Orbits nicht unsichtbar machen.

## Abschließende Namenskorrektur: Börner
System und Sonne heißen sichtbar Börner. Die gemeinsame Anzeigeprojektion und
sichtbare alte Standardnamen folgen dieser Nutzerkorrektur; `glut_*`-IDs,
Reise-/Save-Fingerprints und historische Bild-/Nachweisdateien bleiben unverändert.
Akzeptanz: Tree, tatsächliche Kopfzeile und Sonnenprojektion nennen Börner,
alte Standardlabels werden kompatibel angezeigt, explizite eigene Inhalte bleiben
authoritativ. Abschließende native720p/1080p-Aufnahmen zeigen den neuen Stand.
