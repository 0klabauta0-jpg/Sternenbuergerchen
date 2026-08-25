# Projektkompass SternenBuergerchen – 2026-08-25

## Ziel

Eine direkt oeffenbare HTML-Workbench erklaert Spielidee, nachweisbaren
Projektstand, technische Grenzen und den naechsten Gameplay-Schritt fuer
Menschen ohne Repository-Kontext.

## Umfang

- Eine lokale, responsive HTML-Datei unter `docs/reports/`.
- Grundlage ist ausschliesslich `integration/core-foundation` auf
  `29e81d82516708b7f609f4163e32710cad559ebf`.
- Klar getrennte Kategorien: dokumentiert verifiziert, implementiert,
  offen und Vision.
- Lokale Notizen, Schwerpunktwahl und JSON-Export; keine Projektdatei- oder
  Gameplay-Mutation durch die HTML.

## Nicht-Ziele

- Kein Gameplay-, UI- oder Architekturumbau.
- Kein neuer Runtime-Snapshot, keine neue Evidence-Logik und keine
  Aktualisierung unversionierter Godot-Importdateien.

## Akzeptanzkriterien

- Die Datei funktioniert ohne Server per `file://`.
- Sie beschreibt den aktiven Mission-Tactical-Pfad und `SimulationRoot` als
  Autoritaet korrekt.
- Der `grid_sweep`-Objective-Trace wird als dokumentiert verifizierter Stand
  bezeichnet; der offene Ground-Contact-/Feuerentscheid wird nicht als fertig
  dargestellt.
- JSON-Export enthaelt die lokalen Bedienelemente und Notizen.

## Lokale Pruefung

- HTML-/Skript-Struktur pruefen.
- Per `file://` im Browser Tabs, lokale Eingaben, JSON-Export und responsive
  Darstellung pruefen.
