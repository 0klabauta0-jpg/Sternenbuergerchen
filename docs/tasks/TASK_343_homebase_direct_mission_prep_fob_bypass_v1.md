# TASK_343 - Homebase Direct Mission Prep FOB Bypass V1

## Ziel
Der V1-Spielablauf soll fuer schnelle Spielbarkeit und Tests vereinfacht werden: Fireteam-Auswahl, Loadout, Flight Deck und Dropship-Boarding sollen direkt in der Homebase nutzbar sein. Der FOB wird dabei nicht geloescht, sondern im Kernflow zunaechst optional umgangen.

Ziel-Loop fuer V1:

`Homebase -> Fireteams bauen -> Loadout setzen -> Dropship beladen -> Mission starten`

## Status: IMPLEMENTIERT

## Umsetzung
- Homebase zeigt einen direkten Mission-Prep-Block im Teamfenster: gestagte Operatoren bekommen FT1-Loadout-Zeilen mit Armor, Weapon 1 und Weapon 2.
- Homebase-Dropship-Shipcards bieten `Board` fuer den direkten V1-Pfad. Der Board-Pfad sendet nur ein Staging-Signal; der eigentliche Meta-Handoff wird in `MetaLayerFlow` als Mission-Drop-Payload gebaut.
- `MetaLayerFlow` haelt den direkten Homebase-Payload im gleichen Mission-Drop-Shape wie der FOB-Pfad (`embarked_unit_ids`, `queued_fireteam_ids`, `boarded_fireteam_ids`, `mission_drop_cards`, Member-Loadouts).
- Der versteckte FOB-Screen bekommt die Homebase-Loadouts in seine Fireteam-Definitionen gemergt, damit MissionSetup weiter dieselbe Loadout-Form lesen kann.
- Der Homebase-Charakterbogen kann per Doppelklick/Popup-Pfad dieselbe `CharacterSheetView` rendern; der alte rechte Fixed-Panel-Knoten bleibt aus Kompatibilitaetsgruenden fuer bestehende Layout-Gates erhalten.

## Voraussetzung
- TASK_096 - Meta-Layer Recovery
- TASK_233 - Portrait Identity Catalog and Roster Presentation
- TASK_302 - Dropship Flight Deck Boarding Rename Userology
- TASK_306 - Meta Userology Playability Smoke
- TASK_310 - FOB Flightdeck Fireteam Userology Smoke
- TASK_316 - FOB Fireteam Staging Migration
- TASK_337 - Architecture Performance UX Followup Gate

## Kontext
Der aktuelle Core Loop fuehrt ueber Homebase und FOB, obwohl beide fuer V1 aehnliche Staging-Aufgaben tragen. Dadurch entsteht im Spielgefuehl ein Umweg: Team bauen, in einen zweiten Screen wechseln, dort Loadout/Flightdeck/Dropship bedienen und dann erst in die Mission.

Die Designueberlegung ist, den FOB fuer V1 nicht als Pflichtstation zu nutzen. Die Homebase bekommt stattdessen eine direkte Mission-Prep-Flaeche, die vorhandene FOB-Mechaniken und Datenvertraege wiederverwendet. Der FOB bleibt spaeter als eigenes Feature moeglich, z.B. fuer Forward Respawn, Nachschub, Verwundetenlogistik, Risiko oder Missionsketten.

## Umfang
1. Bestand auditieren:
   - Homebase-, FOB- und Flightdeck-Pfade verfolgen.
   - Fireteam-Staging, Loadout-Auswahl, Dropship-Payload, Transport-Craft-State und Mission-Handoff identifizieren.
   - Klaeren, welche UI-Komponenten direkt wiederverwendbar sind und welche Adapter/Helper extrahiert werden muessen.
2. Homebase Mission Prep:
   - In der Homebase eine direkte Prep-Flaeche fuer Fireteams, Loadout und Flight Deck schaffen.
   - Fenster duerfen anders angeordnet sein als im FOB, muessen aber die gleichen Datenvertraege nutzen.
   - Bestehende NPC-, Fireteam- und Dropship-Karten bevorzugt wiederverwenden statt duplizieren.
3. Dropship Boarding direkt aus Homebase:
   - Fireteams oder geeignete NPC-Karten direkt in ein Dropship schieben koennen.
   - Dropship-Payload, Craft-State, Pilot/Capacity und Mission-Dispatch muessen dieselbe Wahrheit nutzen wie der bisherige FOB-Pfad.
   - Missionstart aus der Homebase darf keine zweite Transport- oder Fireteam-Wahrheit erzeugen.
4. Character Sheet Popup:
   - Der bisher rechts sichtbare Homebase-Charakterbogen wird fuer diesen Flow als Popup per Doppelklick auf NPC-/Operator-Karten vorgesehen.
   - Das Popup muss dieselbe Character-Sheet-View/Formatierung nutzen wie bestehende Character-Sheet- und Editor-Pfade.
   - Kein zweiter Character-Sheet-Renderer und keine abweichenden Gameplay-Werte.
5. FOB Bypass:
   - Der V1-Hauptpfad kann Mission Prep direkt aus der Homebase abschliessen.
   - Der FOB bleibt erreichbar oder technisch erhalten, ist aber nicht mehr Pflicht fuer den schnellen Missionstart.
   - Bestehende FOB-Smokes duerfen nicht gebrochen werden, solange der FOB noch im Projekt ist.
6. Regression und Playability:
   - Headless-Smoke fuer Homebase Direct Prep: Fireteam zusammenstellen, Loadout sichtbar/veraenderbar, Dropship beladen, Mission-Handoff vorbereitet.
   - Popup-Smoke fuer Character Sheet per Doppelklick.
   - Bestehende FOB-/Meta-/Truth-Gates weiter gruen halten.

## Nicht-Ziele
- FOB nicht loeschen.
- Kein neues Meta-State-System.
- Keine neue SimulationRoot- oder Mission-Gameplay-Wahrheit.
- Keine neue Loadout-Mechanik oder Balance-Aenderung.
- Keine Neuimplementierung der NPC-, Fireteam- oder Dropship-Karten, wenn bestehende Komponenten reichen.
- Keine finale Art-Direction fuer alle Fenster; Ziel ist spielbare V1-Vereinfachung.

## Akzeptanzkriterien
- [x] Homebase bietet einen direkten Mission-Prep-Pfad mit Fireteam-Auswahl, Loadout und Flight Deck.
- [x] Dropship-Boarding aus der Homebase nutzt dieselben Transport-/Payload-Daten wie der bestehende FOB-Pfad.
- [x] Missionstart kann ohne Pflichtwechsel in den FOB vorbereitet werden.
- [x] Character Sheet oeffnet als Popup per Doppelklick und nutzt die bestehende Character-Sheet-View.
- [x] UI bleibt Anzeige/Staging und erzeugt keine neue SimulationRoot-Wahrheit.
- [x] Bestehende FOB- und Meta-Smokes bleiben gruen.

## Erwartete Dateien
- `scripts/meta/homebase_screen.gd`
- `scripts/meta/fob_screen.gd`
- `scripts/meta/drop_light_layout_contract.gd`
- ggf. gemeinsame Meta-/UI-Helfer fuer Fireteam-, Loadout- oder Flightdeck-Staging
- ggf. Character-Sheet-Popup-Komponente oder bestehende View-Integration
- `scripts/tests/task_343_homebase_direct_mission_prep_fob_bypass_v1.gd`
- `docs/tasks/TASK_343_homebase_direct_mission_prep_fob_bypass_v1.md`
- `docs/IMPLEMENTATION_STATUS.md`

## Lokale Pruefung
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_343_homebase_direct_mission_prep_fob_bypass_v1.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_306_meta_userology_playability_smoke.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_310_fob_flightdeck_fireteam_userology_smoke.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_316_fob_fireteam_staging_migration.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_337_architecture_performance_ux_followup_gate.gd`
- [x] `git diff --check`

## Risiken
- Wenn Homebase und FOB eigene Kopien von Fireteam-, Loadout- oder Dropship-State halten, entsteht Architektur-Drift. Der Task muss deshalb gemeinsame Daten- und Component-Pfade bevorzugen.
- Das Homebase-Layout kann durch zusaetzliche Fenster ueberladen werden. Der Character-Sheet-Popup-Ansatz soll bewusst Platz fuer Mission Prep freimachen.
- FOB-Folgefeatures duerfen spaeter nicht auf einer veralteten UI-Kopie haengen bleiben. Der FOB sollte als optionaler Screen denselben Staging-State lesen.

## Naechster Schritt
Vor Umsetzung zuerst die Homebase-/FOB-Komponentenkarte erstellen und entscheiden, welche Builder extrahiert oder direkt wiederverwendet werden koennen. Danach in kleinen Slices implementieren: Character-Sheet-Popup, Homebase-Prep-Fenster, Dropship-Boarding, Mission-Handoff-Smoke.
