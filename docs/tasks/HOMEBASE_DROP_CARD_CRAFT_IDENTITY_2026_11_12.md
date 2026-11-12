# Heimat-Abflugkarte: echte Craftdefinition weitergeben

## Ziel / Ursache
`HomebaseScreen._build_homebase_mission_drop_cards` verwirft vorhandene
`model_id`, `craft_type`, `visual_asset_id` und `crew_capacity`. Nachgelagerte
Visual-/Controllerreader verlieren dadurch die echte Herkunft.

## Umfang / Nicht-Ziele
Nur dieser Builderbody in `scripts/meta/homebase_screen.gd`, eigene kleine QA.
Vorhandene Felder aus der verwendeten sichtbaren Craftdefinition direkt lesen;
fehlende Felder weglassen. Keine Modellnamensvermutung, keine Kapazitaetsdefaults,
keine Aenderung anderer Definitionen/Producer oder Gameplayowner. Bestehende
Card-/Pilot-/Fireteam-/Payloadfelder bleiben unveraendert.

## Dokumente / Akzeptanz
PROJECT_BRIEF, ARCHITECTURE, CODEX_RULES, IMPLEMENTATION_STATUS,
polisa_local_ship_pickup_contract und graphics_reference_revision_contract.
Vier enge reale Builderchecks mit kontrollierter Definition-/Personenquelle:
vollstaendige Daten weitergegeben, bestehende Payloaddaten erhalten, unbekannte
Legacydefinition nicht ergaenzt, neu gelesene Starterdefinition nicht gecacht.
Isolierter Godotimport/Compile; keine grossen Tests oder native Grafikabnahme.

## Definitionsbefund / Risiko
Neue Kampagne setzt in CampaignStartConfiguration ausdruecklich `model_id=cutlass`.
Flow-Basisdefinition liefert `craft_type`, aber keine `crew_capacity` oder
`visual_asset_id`. Legacycheckpoint kann auch keine Modell-ID haben. Dieser Hook
erfindet fehlende Herkunft nicht; spaetere Producerkorrekturen muessen beim Owner
gesondert abgestimmt werden. Keine Gitaufnahme/Commits/Globalstatusaenderungen.
