# TASK_368 - FTL Readiness Gauge

## Ziel
Einen kompakten visuellen Gauge fuer FTL-Readiness bauen, der den Snapshot aus TASK_367 anzeigt.

## Status: IMPLEMENTIERT

## Sinnhaftigkeitscheck
Der Review-Punkt ist sinnvoll, aber erst nach einem sauberen Snapshot. Der HTML-Snippet nutzt Defaultwerte; im Projekt darf die Anzeige stattdessen nur echte oder explizit unavailable Readiness-Daten visualisieren.

## Problem
Reaktionszeit, Moral und Planqualitaet sind zu textlastig und schwer schnell zu vergleichen.

## Ursache
Es gibt noch kein kleines Control, das FTL-Metriken auf enger Flaeche ohne neue Gameplay-Logik darstellt.

## Umfang
- `FTLReadinessGauge` als reines `Control` oder vorhandene Tactical-UI-Komponente einfuehren.
- Ringe/Balken fuer Reaction und Morale, farbliche Planqualitaet oder Label.
- Kleine Groesse mit stabiler Mindestdimension, keine Layout-Spruenge.
- Tooltip oder Snapshot-Metadaten fuer Testbarkeit, aber keine langen In-App-Erklaertexte.
- Nur `set_snapshot()` lesen; keine Resolver-Aufrufe direkt im Control.

## Akzeptanzkriterien
- [x] Gauge rendert valide Snapshot-Werte deterministisch.
- [x] Unavailable-Werte werden neutral und eindeutig angezeigt.
- [x] Text passt in die feste Komponentengroesse.
- [x] Headless-Verifier prueft Render-/Snapshot-Diagnose fuer high, medium und low Readiness.
- [x] Gauge kann in Fireteam-Karten eingebettet werden, ohne deren Hoehe unkontrolliert wachsen zu lassen.

## Umsetzung
- `scripts/ui/ftl_readiness_gauge.gd` ist ein reines `Control`, liest nur per `set_snapshot()` und stellt Planqualitaet, Moral und Reaktionszeit als kompakte Ringe/Balken dar.
- Fehlende Werte bleiben neutral: Availability-Flags entscheiden, ob Werte angezeigt werden; unavailable wird nicht mit Fake-Mittelwerten gefuellt.
- Die Mission-Fireteam-Mini-Karten betten pro Fireteam eine feste `FTLReadinessGauge` im Header ein und speisen sie aus dem TASK_367-Readiness-Snapshot.
- Das Control stellt eine kleine Diagnostik per `get_gauge_snapshot()` bereit, damit Headless-Tests Zustand, Availability und fixe Groesse ohne visuelle Heuristik pruefen koennen.

## Erwartete Dateien
- `scripts/ui/ftl_readiness_gauge.gd`
- `scripts/tests/task_368_ftl_readiness_gauge.gd`
- ggf. `scripts/ui/tactical_ui_theme.gd`

## Lokale Pruefung
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_368_ftl_readiness_gauge.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_367_ftl_public_readiness_snapshot_contract.gd`
- [x] `git diff --check`

## Risiken / offene Punkte
- Mini-Kreisdiagramme koennen schnell zu klein werden. Falls die Lesbarkeit schlecht ist, soll der Task auf kompakte Balken umschwenken.
- Keine Animation einfuehren, wenn sie nicht klar testbar und performant bleibt.
- Manuelle Lesbarkeitspruefung im echten Mission-HUD bleibt sinnvoll, sobald weitere Status-Widgets aus TASK_369+ daneben liegen.
