# Personal-/Basis-UI: Mainintegration — 10.11.2026

Beauftragt: geprüften Stand nach Main integrieren. Ausgangs-Main/origin/main:
1e3cca237604d3b293097585e19953ac08c11c7b. Kandidat:
2ea46001779397a461e6bbd39b50edaf856616e9. Fünf geradlinige Taskcommits seit Main:
5df2d3b6f (Truppkarte/Aufsitzen), 9c87a06ef (Charakter/Navigation),
0c7510f79 (Basis-Seitenfenster/Auftragsfolge), e004843e7 (Menüicons/Chip),
2ea460017 (gemeinsame Charakterausrüstung/Blueprintwerte/Auftragsdetails).

Vorbereitung auf task/personnel-ui-main-integration-20261110. Main ist direkter
Vorfahr, keine Produktkonflikte oder neuen Produktänderungen. Integrationscommit
ergänzt ausschließlich diese Dokumentation, Task, Status und Roadmap.
Produktpfade scripts/scenes/data/Assets/project.godot bleiben identisch zu 2ea460017.

## Frische Prüfung des Integrationskandidaten

- Nativ D3D12: tatsächlicher Satellitenausflug **102/0**, Prozess exit0,
  Enginefehler0. Tatsächliches Aufsitzen/Absetzen, Datenaufnahme, eindeutiger
  Lead-Rucksackchip, gemeinsame Charakteransicht mit unveränderten Controls,
  Meldungen hinter dem Bogen, wirkliche Heimkehr/Schlafen, einmaliger Upload,
  Belohnung, Herstellung und Save/Restore. Keine manipulierten Positionen/HP/
  Belohnungsbelege. Beschleunigte bestehende Simulation, kein 1×-Lastnachweis.
- Headless Basis-Seitenfenster/Auftragsauswahl: **111/0**, exit0.
- Headless Charakterbogen/Cache/Editorwechsel: **25/0**, exit0.
- Headless drei vorbereitete Skirmish-Starts: **209/0**, exit0.

Unveränderte Logs und Prozessmetadaten unter raw/. Frische Engineaufnahme des
tatsächlich geborgenen Chips unter images/satellite_carried_on_map.png, visuell
geprüft. D3D12-Host versteckt bei1280×720, logischer Viewport1920×1080; kein
physischer Mehrmonitor-Nachweis. Zwei bekannte UID-Pfadfallback-Warnungen im
nativen Lauf, keine Enginefehler. Native Basis-/Detailbilder zusätzlich unter
docs/qa/shared_personnel_equipment_20261110/ mit ihren ausdrücklich genannten Grenzen.

## Abgrenzung

Keine neue EXE oder Paketfreigabe in diesem Auftrag. Kein vollständiger Alt-
Verifier-/Multiplayerlauf, keine allgemeine FPS- oder ästhetische Nutzerabnahme.
Isolierte APPDATA-Testprofile unter output/personnel_ui_main_20261110/profiles.
Nutzerstände, gespeicherte Teams, andere Worktrees und ungetrackte Dateien erhalten.
Main wird nach dieser Prüfung ausschließlich per Fast-forward aktualisiert und
normal gepusht; lokaler und Remote-Hash werden anschließend verglichen.
