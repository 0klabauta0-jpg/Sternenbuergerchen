# Menüicons und Satellitendatenträger — 10.11.2026
Basis0c7510f79, Mainbasis1e3cca237. Task/equipment-icons-mission-chip-20261110.
Dieser geprüfte Zwischenschritt wird durch den weiteren Nutzerwunsch nach einer
gemeinsamen Charakter-/Ausrüstungsansicht ergänzt; deren Umbau folgt separat.

Neue transparente3×2-Menüillustration aus Referenzen der vorhandenen Modelle:
leichte Rüstung, lange Rifle, Pistole, Sanitätsgerät, gelbes Miningtool, Datenträger.
Weltmodelle und Waffenwerte unverändert. AtlasTexture trennt512px-Zellen, Texturen
werden gecacht. Porträt wieder am Namen, Figur größer, Fensterbreite840px.
Tankservice zeigt keine Werkzeugkäufe/Verkäufe an der Basis; bestehende Handels-
Owner erlauben Handel nur am Handelsservice. Kleine Auftankaktion statt Vollbreite.
Briefing trennt Glut(Planet), Suchgebiet und einzelne Ziele.

Trusted RuntimeAdapter beobachtet bestätigte Use-/Scenario-Gates und erzeugt
über SimulationRoot/SupplyOwner genau einen Chip beim tatsächlichen Lead.
Ergebnisrückkehr erzeugt keinen zweiten Cargo-Chip. Upload findet vorhandenen
Gegenstand in Rucksack/Fracht/Lager; alte Cargo-Speicherung bleibt unterstützt.
Map-Charakterdetails zeigen echten Rucksackbestand mit Icon, keine UI-Kopie.
Kein neues Saveformat; keine Reparatur-/Rufregeln und keine neuen Startgeschenke.

## Nachweise
- Nativ D3D12 vollständiger tatsächlicher erster Ausflug97/0: Lead-Chip nach
  realem Sichern, kein UI-Mint, kein Duplikat, sichtbarer Chip im Map-Charakterbogen,
  wirkliche Heimkehr/Schlafen/Upload, genau eine Belohnung, Herstellung und Save.
- Zweiter vollständiger Ausflug headless101/0: zusätzlich SupplyOwner-Restore mit
  exakter Chipmenge und tatsächlicher Transfer vom Rucksack in Fracht vor Upload.
- Native Fenster103/0: beide Größen1280/1920, Porträt, breiterer Drawer, getrennte
  Ziele, keine Heimat-Shopbuttons, kompakter Refuelbutton. Handelsposten-Ansicht
  hier ausschließlich als Anzeigeprojektion geprüft, keine Reise dorthin behauptet.
- Native vergrößerte Charakteransicht32/0; Icons/Briefing19/0; Compact22/0.
- Alle nativen Läufe Enginefehler0, jeweils zwei vorhandene UID-Pfadwarnungen.
  Verborgener1280×720-Host; Screenshots in logischen Viewports, keine Behauptung
  dreier physischer OS-Auflösungen. Headless-Editorimport hatte einen separaten
  ObjectDB-Exitwarnhinweis; der native Spielprozess meldete diesen nicht.
- Bilder unter images sind echte Godot-PNGs. Atlas ist KI-Illustration, keine
  Modellrevision. Prompt/Referenzen/SHA in reference. Native Bilder angesehen;
  keine allgemeine Stil-/FPS-/Multiplayerabnahme, kein Main/EXE-Schritt.
- Tatsächlich geprüft wurde Mission1; Außenpostenchip nutzt denselben Bridgepfad,
  Mission4 wurde hier nicht als physisch abgenommen erklärt. Nutzersaves/Teams
  unverändert, alle Prüfungen in isolierten APPDATA-Verzeichnissen.
