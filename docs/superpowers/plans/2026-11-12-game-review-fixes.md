# Spielreview und Fehlerbehebung — Ausführungsplan

**Goal:** Mehrschiff-P2s mit echten Regressionen beheben, weitere aktive Spielpfade
prüfen und einen mobilen HTML-Bericht mit belastbarer Evidenz liefern.
**Architecture:** Bestehende Owner/Commands verwenden. UI ergänzt keine Gameplay-
Wahrheit. Reine Fixturefehler getrennt von Produktfehlern behandeln.
**Tech Stack:** Godot 4.6.2, GDScript, Python-Prüfrunner, lokale HTML-Workbench.
**Spec:** `docs/tasks/GAME_REVIEW_FIXES_2026_11_12.md`.
**Ausführung:** Vom Nutzer ausdrücklich autorisiert: autonom mit geeignetem Agenten,
sparsamem Kontext, keine Unterbrechung nach jeweils zwei Befunden.

## Grenzen / Reviewfokus
Keine Desktop-Eingaben, echten Spielerstände, fremdes WIP oder Mainintegration.
Besonders prüfen: tatsächliches Schiff statt UI-Auswahl; partielle Teams;
Fighter-Sperre vs zulässiger Transport; Clients ohne eigenen Schadenscommit;
ESC läuft in Echtzeit und darf Szenen-Neustart nicht als Zustandssave anbieten.

## Pakete
- [x] Taskbranch und Taskdefinition, ursprüngliches WIP dokumentieren.
- [x] Headless-Import, isolierte APPDATA-Testprofile, temporär Standby verhindern.
- [x] Agent: Mehrschiff-Verhaltensrepros ROT, Owner-Fixes, GRÜN und Nachbarregressionen.
- [x] Agent: aktive Combat-/Hex-/RNG-/Multiplayer-Callchain, Legacy unterscheiden.
- [x] Root: irreführenden Szenenslot ROT testen, UI präzisieren, Echtzeit absichern.
- [x] Root: begrenzte aktuelle Hex-, Kampagnen-, Inventar-, Grafik-, UI-/Netztests.
- [x] Unabhängiger Patchreview, echte Fehler schließen, Grenzen klar dokumentieren.
- [x] Bericht aus `_html_workbench_template.html` ableiten; Handybreiten und
  Offline-JSON-Export mit privatem headless Browser prüfen.
- [x] Finalen Diff prüfen, nur eigene Änderungen integrierbar dokumentieren,
  Wachhalteprozess beenden, Ergebnis und Bericht verlinken.
