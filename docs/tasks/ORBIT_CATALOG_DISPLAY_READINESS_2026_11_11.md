# Versionierte Orbitkatalog- und UI-Bereitschaft

## Ziel / Ursache
Die spaetere Einmarker-Umschaltung braucht explizite V3-Produktdaten und generische Darstellung, ohne heute den V2-Livekatalog oder Reiseowner umzuschalten.

## Scope / Nicht-Ziele
Nur scripts/core/strategic_hex_grid.gd, scripts/mission/orbit_destination_catalog.gd, scripts/ui/star_map_screen.gd und scripts/ui/star_map_canvas.gd sowie eigene Task/QA. Kein JSON-/Adapter-/Travel-/Fleet-/Rootedit, keine EXE, kein git add/Commit durch diesen Agenten.

## Vertrag / Akzeptanz
GRID.ORBITS und ORBIT_MARKER_IDS bleiben unveraendert V2. Reine Kopien aus orbits_for_version(2)=5 und (3)=6 inklusive sun_orbit; unbekannte Version leer. Draft liest V2 weiterhin streng und behaelt Migrationsaliase ausschliesslich separat. Ausdruecklicher build_v3_product liefert dieselbe gepruefte Geometrie, aber keine draft-Kennung und keine Alias-/Migrationsdaten; validate_v3_product und validate_v3_draft akzeptieren jeweils nur ihren eigenen Modus. Keine implizite Umschaltung oder Runtimealiasaufloesung.

Canvas liest Bodyzuordnung aus Travel.orbits[...].body_id und Travel.bodies, generiert Captions aus dem Katalog und prueft darstellungsrelevante Struktur/Marker. Screenliste leitet Ziele aus diesen projizierten Orbitdaten ab; bisherige vier Ziele behalten Reihenfolge, gueltiges Glut2/Polisa und V3Sun werden generisch ergaenzt. V2Markeranzahl/-koordinaten/Commands bleiben. Sonnenorbit hat kein Surface-/Anflugziel. UIvalidierung ist Darstellungsfilter, keine Gameplayfreigabe; Runtimeowner validiert Produktkataloge.

## Quellen / lokale Pruefung
ORBITAL_APPROACH_MAPS_2026_11_11.md; orbit_destination_catalog_draft_contract.md; Grafikreferenzvertrag; vorhandene Version2-JSON. Kleine Daten-/UI-Contractfixture fuer V2Konstanten/Kopie/Markererhalt, V3Product-vs-Draft, Sun/Polisa generisch, dynamischen Katalogwechsel, Draftreject und Commands. Einzelcompiles; keine GPU-/native-/Gefechts-/grosse Matrix.

## Risiken / offen
Diese Bereitschaft aktiviert weder V3-Livedaten noch Reise-/Bereichseintritt. Alte UIcommands werden nicht migriert. Explizite Datenauswahl/Savevertrag/Ownerumstellung bleiben Source-/Parentintegration. Keine Aesthetik- oder finale Aktivierungsfreigabe.

## Ergebnis / Freeze
Arbeitsbasis 562373d13. Neue kurze API-/Darstellungsvereinbarung in docs/dev/orbit_catalog_display_readiness_contract.md. Zehn gezielte Daten-/UI-Contractchecks 10/0, vier Einzelcompiles Exit 0. QA output/native_glut_maps/orbit_catalog_display_readiness_20261111. Echter Screen/Canvas, kontrollierte Travelprojektion aus realem V2-JSON bzw. rein gebautem V3Product; keine Runtimeaktivierung oder Bildabnahme. Kein Staging/Commit durch diesen Agenten; Parent integriert nach Freeze.
