# Schiffmodelle: Prospector, Vulture, Caterpillar, Gladius, F7C Hornet

Status: fuenf separate Modellkandidaten lokal erstellt und geprueft.

## Ziel / Ursache
Die vom Nutzer bereits bereitgestellten Originalmodelle in Blender fuer den
Spieleinsatz aufbereiten und Polygonzahlen wie bei Buccaneer/Cutlass senken.
Die vorhandene F7C Hornet wurde am 14.11.2026 ausdruecklich bestaetigt.

## Umfang / Nicht-Ziele
- Fuenf separate, editierbare Blender-Kandidaten und GLB-Exporte mit Quellenhashes.
- Originale erhalten; Silhouette, Teile, Materialzuordnung und Massstab pruefen.
- Caterpillar-Klappen und Aufzug separat erhalten bzw. trennen, Pivots vorbereiten
  und eine pruefbare Bewegung vorsehen. Spaetere Gameplay-Ansteuerung bleibt offen.
- Keine Aenderung an aktiven Schiffen, Kampagne, Main, fremdem WIP oder EXE.
- Keine Verbindung zur gemeinsamen Blender-MCP-Sitzung. Ausschliesslich eigene
  headless Blender-Prozesse mit Factory-Startup und begrenzten Threads.

## Basis / Dokumente
Eigener sparse Worktree `task/ship-model-preparation-20261114` auf dem vorgeschriebenen
`integration/core-foundation` (`3cae5a216`, 31.08.2026). Dies ist ein separates
Assetpaket, keine Integration des aktuellen November-Spielstands.
Gelesen: PROJECT_BRIEF, ARCHITECTURE, CODEX_RULES, relevante IMPLEMENTATION_STATUS-
und TASK_ROADMAP-Eintraege sowie aktueller graphics_reference_revision_contract.
Als Vorbild dienen die archivierten prepare_freibeuter/prepare_geier-Skripte;
die neu modellierten November-Ref03-Schiffe sind eine andere Pipeline.

## Akzeptanz
- Je Schiff nachvollziehbare Quelle, Vorher-/Nachher-Dreieckszahl und Bounds.
- Sichtvergleich bei gleichen Ansichten; Material-/Teile- und Drahtgitterpruefung.
- Editierbare .blend und frisch importierbarer .glb, keine Nullbyte-Dateien.
- Caterpillar-Bewegungsteile nicht mit statischem Rumpf verschmelzen.
- Warnungen/Quellenluecken offen benennen, keine gestalterische Nutzerabnahme behaupten.

## Betroffene Dateien
`art/ship_models_20261114/` (Skripte, Quellenmanifest, Kandidaten, QA), diese Taskdatei
und ein enger Abschlussvermerk in IMPLEMENTATION_STATUS.

## Lokale Pruefung
Blender 5.1.1 isoliert; Geometriestatistik, Asset-QA, Mehransichten,
Export-Roundtrip und isolierter Godot-Import. Keine globale Laufzeit-/FPS-Abnahme.

## Risiken / offene Punkte
Quellmodelle koennen untexturiert, trianguliert oder zusammengefuegt sein.
Hornet-Quelldatei heisst allgemein ANVIL-HORNET; genaue visuelle Identitaet pruefen.
Klappen-/Aufzugstrennung und Mechanik muessen am konkreten Caterpillar-Mesh
geprueft werden. Keine automatische Abnahme durch reine Polygonreduktion.

## Ergebnis
Fuenf editierbare Blender-Dateien und fuenf GLBs. Dreieckszahlen:
Prospector 19.932, Vulture 17.970, Caterpillar 32.826, Gladius 14.000,
Hornet 15.840. Alle finalen Geometrieberichte ohne Fehler; akzeptierte
verdeckte Gegenflaechen dokumentiert. Caterpillar-Geometriepruefung ohne UV,
da nur konstante Farbmaterialien verwendet werden.

Caterpillar besitzt neun getrennte Klappen und eine neue Liftplattform mit
Fuehrungen. Exportierter 3-Sekunden-Clip oeffnet/senkt und schliesst/hebt;
Hull bleibt fest. Source-Mechanik war nicht vorhanden, Lift daher neuer
Kandidat. Kein begehbarer Frachtraum, Gameplaytransport oder Kollisionsvertrag.

Unabhaengiger Godot-4.6.2-Import 109/109, native Pruefung 132/132, keine
Enginefehler/Leaks. Quellen/Kandidaten und native Bilder geoeffnet. Datei-Hashes,
genaue Grenzen und finale Evidenz stehen in `art/ship_models_20261114/RESULTS.md`
und `godot_probe/final/`. Die lokale ZIP-Lieferung enthaelt nur aktuelle Modelle
und passende Nachweise. Binaerassets/Bilder bleiben lokal; oeffentliches Git
erhaelt Pipeline und Dokumentation. Kein Mainmerge und keine EXE.
