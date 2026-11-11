# Werkstatt-Recycling: Bergungsgut wird zum Rucksack

## Ziel / Ursache / Basis
Naechster kleiner nutzbarer Industriezweig nach dem vorhandenen Bergungswerkzeug.
Echte Wracks liefern salvage, der vorhandene Rucksack gibt Kampagnenpersonen
12 Inventarplaetze. Beide Enden existieren; ein neuer funktionsloser Metallbarren
oder eine erfundene Schiffskomponente ist nicht erforderlich. Isolierter Branch
task/native-glut-maps-20261110, Root-Scope bestaetigt, keine Main-/EXE-Freigabe.

## Konkreter Umfang und vorlaeufige Balance
Nach research_industry und tatsaechlich gefertigtem salvage_tool einmal
research_recycling fuer100Cr entwickeln. Danach separat blueprint/recipe_id
backpack_recycling:2salvage aus base:homebase +20Cr ergeben1backpack dort.
Salvage-Ankauf auf Polisa ist aktuell9Cr je Einheit;2Material+20Cr entsprechen
38Cr Opportunitaetskosten gegenueber40Cr Rucksackkauf. Das ist ein erster
Balancevorschlag, keine finale Wirtschaftsbalance. Kaufangebote bleiben gleich.

## Besitz / Nicht-Ziele / Vertraege
SingleplayerSupplyState besitzt Entwicklung, Credits, Material, Output und
Requestbelege. Vor dem atomaren Commit alle Voraussetzungen/Mengen/Kapazitaet
pruefen; nur Basisbestand, kein Ferngriff auf Personen-/Schiffslager. Bestehende
Commands und Adapterrouting bleiben. UI zeigt Ownerprojektion und sendet Commands.
Bestehender _change_backpack bleibt Verbraucher; der Anzug-Datenkartenslot bleibt.
Keine Tabletop-/Bewegungs-/Combat-/SimRoot-/Inventaritem-/Fahrzeugmodellaenderung.
PROJECT_BRIEF, ARCHITECTURE, CODEX_RULES, CAMPAIGN_INDUSTRY_RUNTIME,
CAMPAIGN_RESEARCH_RUNTIME, personnel_inventory_contract und
location_resource_interaction_contract gelten.

## Schritte / betroffene Dateien
1. research.json additiv um Knoten und Materialrezept ergaenzen.
2. campaign_research_catalog.gd fuer reine Material-/Rezeptdaten bei Bedarf nutzen;
   bestehende Vorbedingungen und alte Rezepte behalten.
3. Supply-Fertigung als gemeinsame Vorschau/Mutation erweitern, Materialbelege
   kanonisch validieren, alte echte Fabricatebelege ohne Inputfelder akzeptieren.
4. singleplayer_services_presenter.gd zeigt Rezept, benoetigtes Material und
   aktuellen Owner-Sperrgrund; kein Gameplaystate in UI.
5. Eigener kleiner Domaincheck und begrenzte Compile-/Diffpruefung.

## Akzeptanz / lokale Pruefung
Entwicklung vor Voraussetzung gesperrt; kein Gratisrucksack; fehlendes Material,
voller Output oder Heimat-/Creditsfehler lassen Bestand unveraendert. Replay
verbraucht nicht zweimal, Konflikt-ID wird abgewiesen. Bestehende Container-
Transfers bleiben Voraussetzung fuer Material aus dem Schiff. Materialbelege
ueberstehen JSON-Domainroundtrip, manipulierte Belege werden abgewiesen; alte
echte Rezepte/Saves ohne Inputfelder bleiben gueltig. Ein Fertigungsrucksack
funktioniert ueber den bestehenden12Slot-Verbraucher. Nur kleine Ownerchecks,
keine grosse Save-/Reise-/Kampf-/UI-/GPUmatrix. Kein Commit/Push durch Teilagent.

## Risiken / offen
Der neue Zweig ist kein allgemeiner Raffinerie-/Flottenbaum. Kosten sind initial.
Workbench-Baseline zieht Root separat nach. Native Werkstatt-/Bergungs-/Transfer-
und Gesamtspielabnahme bleibt spaeter. Schiffswaffenowner bleibt getrennt.

## Enges Ergebnis
Umgesetzt. Frische Recyclingprobe27/0, vorhandene Schutzprobe24/0, drei betroffene
Scripts check-only0. Keine grosse Suite oder nativeUIprobe. Neue Materialbelege
und alte echte Rezepte gemeinsam geprueft. QA mit Erstlaufdiagnose und Hashes:
docs/qa/campaign_recycling_runtime_20261111. Vertrag:
docs/dev/campaign_material_fabrication_contract.md.
