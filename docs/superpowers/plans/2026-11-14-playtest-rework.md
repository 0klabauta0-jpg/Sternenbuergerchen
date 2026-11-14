# Playtest-Überarbeitung – Arbeitsplan

> **For agentic workers:** REQUIRED SUB-SKILL bei einer später beauftragten Umsetzung: `superpowers:subagent-driven-development` oder `superpowers:executing-plans`; paketweise arbeiten. **Dieser Auftrag erlaubt ausschließlich Planung. Keine Umsetzung aus diesem Dokument heraus starten.**

**Goal:** Die vollständigen Playtest-Rückmeldungen in kleine, überprüfbare und geordnet integrierbare Arbeitspakete überführen.

**Architecture:** `SimulationRoot` und vorhandene Runtime-/Datenowner behalten Gameplay, Inventare, Besatzung, Reise und Sicht. UI und Visuals lesen deren Snapshots und senden Commands. Editoränderungen verwenden die vorhandene MapData-/Authoring-/Undo-Pipeline.

**Tech Stack:** Godot 4.6.2, GDScript, vorhandene Hex-/Square-Karten, native Godot-Oberfläche und bestehende Assets. Kein Enginewechsel und keine neue Frameworkabhängigkeit.

**Spec:** [Vollständige Änderungsliste L01–L23](../../tasks/PLAYTEST_REWORK_2026_11_14.md).

**Status am 14.11.2026:** Nur geplant. Alle Pakete offen. Vorhandene frühe Quellkandidaten zählen nicht als Paketabschluss. Keine Laufzeitprüfung, kein Build und keine Spielstandänderung im Planungsauftrag.

## Globale Grenzen

- Aktuelle Nutzeranweisung: **„Erst mal nur planen, noch nichts umsetzen.“**
- Vor späteren Änderungen `AGENTS.md`, PROJECT_BRIEF, ARCHITECTURE, CODEX_RULES, IMPLEMENTATION_STATUS und die Paketcontracts auf der gewählten Basis lesen.
- Nicht auf `main` oder ungeprüft auf einem alten Taskbranch implementieren. AP0 legt den aktuellen Integrationsstand fest; vorhandenes fremdes WIP bleibt erhalten.
- Keine zweite Mission-, Unit-, Lager-, Platz-, Reise- oder Sichtwahrheit in UI/Visuals. Registries sind Lookup, keine versteckten Mutatoren.
- Keine SceneTree-Vollscans im Hotpath und keine per-frame Komplettrebuilds. Dirty-/Batch-/Cachepfade und `UpdateManager` wiederverwenden.
- Taktische Befehle bleiben im vorhandenen Fireteamweg. Die NPC-Anzeige erweitert nicht still die direkte Einzelpersonensteuerung im Gefecht.
- Tatsächliches Hinlaufen, Aufsitzen, Absitzen, Flug und Erkundung bestätigen; ein Drag, eine Auswahl oder ein Szenenwechsel ist kein Gameplayabschluss.
- Keine automatische Änderung/Überschreibung echter Profile oder Saves durch Tests. Isolierte Testprofile und Kopien verwenden.
- Alte Savegames müssen nicht kompatibel bleiben. Speicherformate dürfen sich brechend ändern; keine Migrationen, Kompatibilitätsschichten oder Altformat-Fallbacks allein zur Rettung alter Spielstände einplanen. Ein neuer Spielstart ist akzeptiert. Save/Continue-Prüfungen dieses Plans beziehen sich auf neu erzeugte Spielstände im jeweils aktuellen Format. Dies erlaubt keine eigenmächtige Löschung vorhandener Dateien.
- Performance hat hohe Priorität: Sie ist Entwurfs- und Abnahmekriterium jedes Pakets, nicht nur eine Abschlussaufgabe in AP15. Bei Zielkonflikten mit zusätzlichen Grafik-/Komforteffekten die weniger aufwendige Variante bevorzugen.
- Grafikziel, nativer Ist-Stand und Kandidat nach `graphics_reference_revision_contract.md` unterscheiden; Originale erhalten. Technischer Import ersetzt keine visuelle Nutzerabnahme.
- Neue oder stark überarbeitete HTML-Reports folgen dem HTML-Workbench-Contract. Dieser Auftrag erzeugt nur Markdown.
- Kein neues Gesamtraumkampfsystem, keine neue strategische Kriegs-KI oder Wirtschaft als Nebenprodukt des Einzelgefechtmenüs. Fehlende Voraussetzungen separat ausweisen.
- Ein späterer Export/eine EXE ist ein eigener Arbeitsschritt, kein Paketabschluss dieses Plans.

## Prüfstellen mit besonderem Risiko

1. **UI-Überlagerung und periodischer Refresh:** Buttonränder und X bleiben anklickbar; Menü, Fokus und Drag gehen beim Refresh nicht verloren. Abnahme in AP1, AP4, AP6 und AP7.
2. **Mehrere Personen/Schiffe, volle Plätze oder Container:** keine doppelte Belegung, kein verlorener Gegenstand und kein Zugriff auf entfernte Schiffe durch bloße Auswahl. Abnahme in AP2, AP4 und AP5.
3. **Unbekannte Karte oder Innenraum:** Doppelklick, Hover, Marker, Minikarte und Dachschalter verraten keine unentdeckten Ziele oder aktuellen Gegner. Abnahme in AP7, AP8 und AP13.
4. **Abbruch, Save/Continue und wiederholter Command:** keine doppelte Belohnung, Kostenbuchung, Besatzung oder Reise; inkompatible Daten vor Mutation ablehnen. Abnahme in AP2–AP5 und AP9.
5. **Große Karte, gedrehte Ansicht und geringe Fenstergröße:** außen bleibt wirklich außerhalb; Startseite eindeutig; Controls im Rahmen; gleiche Karte für Vergleichsmessungen. Abnahme in AP3, AP6, AP9, AP11 und AP15.

## Reihenfolge und Abhängigkeiten

Reihenfolge innerhalb dieses Vorhabens; andere Projektaufträge werden dadurch nicht still neu priorisiert.

| Paket | Ergebnis | Voraussetzung | Listenpunkte |
| --- | --- | --- | --- |
| AP0 | Verbindliche Ausgangsbasis, Repros und Performancebaseline | keine | querschnittlich, L15 |
| AP1 | Verlässliche Klickflächen und dauerhaft offene Menüs | AP0 | L04, L16 |
| AP2 | Sichtbarer, korrekter Datapad-Upload auf gültigem Heimstand | AP0, AP1; voller Ausflug nach AP5/AP9 | L01 |
| AP3a / AP3b | Direkte Boden- / Weltraumgefechte als schneller Prüfweg | AP0, AP1 | L17 |
| AP4 | Gemeinsames Basis-/Schiffslager und Truppbedienung | AP1, Upload-/Bestandskern aus AP2 | L05, L09 |
| AP5 | Autoritative Besatzungsplätze und Auf-/Absitzregeln | AP0; AP3a für Bodenabnahme | L03, L07, L08 |
| AP6 | Kompaktes Flugdeck auf derselben echten Basis | AP4, AP5 | L06, L07, L09, L03 |
| AP7 | Sternkartenbedienung: ansehen, auswählen, ausdrücklich reisen | AP1 | L20, L21, L22 |
| AP8 | Teambezogene Erkundung und Sichtschutz auf allen Karten | AP7; AP3a oder isolierte Szenen als Prüfweg | L12, L21, Suchanteil L11 |
| AP9a / AP9b | Echte Kartenrand-/OM-Übergänge, dann Warpdarstellung | AP5, AP7, AP8 | L02, L23, Automatikgrenze L22 |
| AP10 | Verständliche Sprechblasen und hilfreiche Hoverinfos | AP1, AP5, AP6, AP8 | L10, L13 |
| AP11 | Editorübersicht und verständliche Höhenbearbeitung | AP0 | Grundbedienung L18 |
| AP12 | Verlässliche Mauern, Assetmaßstäbe und Vergleichsobjekte | AP11 | übriges L18 |
| AP13 | Umschaltbare Dächer mit geschütztem Innenraumwissen | AP8, AP11, AP12 | L19 |
| AP14a / b / c | Absturzstelle / Skirmish-Betten / schwere Rüstung | AP8, AP12; Betten zusätzlich AP13 | L11, L14 |
| AP15 | Gemessene Performancekorrekturen und Gesamtdurchlauf | alle betroffenen Pakete | L15 und Gesamtregression |

**Warum so:** Erst Bedienblocker und den ersten Spielkreislauf lösen. Danach ermöglicht der direkte Gefechtsstart kurze, reproduzierbare Tests. Lager und Besatzungsregeln werden vor der darauf aufbauenden Flugdeckoberfläche gefestigt. Sternkarteninteraktion und Sichtschutz kommen vor Reiseeffekten, Suchkulisse und Innenraumfreigabe. Editorgrundlagen kommen vor neuem Content. Performance wird ab AP0 und in jedem Paket beobachtet; AP15 bündelt nur den verbleibenden Abschluss.

AP11 kann nach AP0 unabhängig vorbereitet werden. AP3a und AP3b sind separat abnehmbar; fehlende Raumkampfgrundlagen blockieren nicht das Bodengefecht. Gleichzeitige Bearbeitung derselben großen Presenter-/Flowdateien vermeiden. Parallele Pakete benötigen getrennte Zuständigkeit und eine gemeinsame vereinbarte Basis.

AP2 liefert zuerst den Upload-/Bestandskern auf einem gültigen isolierten
Heimstand mit bestätigter Bergungs-/Rückkehrevidenz. Erst die vollständige
Flug-/Ausstiegskette nach AP5 und AP9 schließt die native L01-Gesamtabnahme ab;
AP4 muss darauf nicht warten. AP3b ist keine Voraussetzung für Boden-Fog oder
Karten-Sichtfilter; vorhandene isolierte Szenen können fehlende direkte
Gefechtsstarts als Prüfweg ersetzen, nicht als Produktabschluss.

## Gemeinsame Arbeits- und Prüfweise bei späterer Umsetzung

- [ ] Paket auf der AP0-Basis gegen aktuelle Quellen reproduzieren; vorhandene Teilfunktion als „vorhanden, Abnahme offen“ kennzeichnen statt neu bauen.
- [ ] Gewünschtes Verhalten im zuständigen Contract festhalten und mit einem gezielten Verifier reproduzieren. Keine Tests, die nur den Aufbau des neuen Codes nachzeichnen.
- [ ] Kleinste notwendige Änderung am vorhandenen Owner-/Commandpfad ausführen.
- [ ] Gezielten Verifier und betroffene Nachbarregressionen ausführen; Fehlversuche, Baselinefehler und bestandene Läufe getrennt dokumentieren.
- [ ] Performanceauswirkung gegen AP0 und das vereinbarte Paketbudget prüfen. Relevante Verschlechterungen vor Paketabschluss beheben oder als offenen Abnahmepunkt ausweisen; einen bestandenen Funktionstest nicht als Performancefreigabe behandeln.
- [ ] Native Bedien-/Sichtprobe am tatsächlichen Kandidaten durchführen, soweit das Paket Darstellung oder Eingabe betrifft.
- [ ] Eigenen integrierbaren Commit mit ausschließlich Paketdateien erstellen; Doku und Grenzen mitführen. Integration nach Projektregeln separat ausweisen.

Standardlauf für einen existierenden Godot-Verifier, **erst bei Umsetzung**:
`godot_console --headless --path <isolierter-Paket-Checkout> --script res://scripts/tests/<Verifier>.gd`.
Den Profilpfad dabei nach dem vorhandenen Testwerkzeug isolieren; echte Kampagnenstände niemals als Schreibziel verwenden. AP0 bestätigt Enginepfad, Importcache und konkrete Verifier auf der gewählten Basis. Die unten genannten Dateien sind Einstiegspunkte, kein Auftrag für Komplettrefactors.

## AP0 – Ausgangsbasis und Prüfbarkeit

**Ziel / Ursache:** Verhindern, dass Fehler aus R2 auf einem abweichenden Reviewstand „behoben“ oder frühere Kandidaten als fertig übernommen werden.

**Quellen:** `docs/IMPLEMENTATION_STATUS.md`, `docs/TASK_ROADMAP.md`, vorhandene QA; read-only Git-/Builddaten. Dokumentationsbasis aktuell `c27528594`, im Chat ermittelte R2-Basis `8571be32c`, lokales `main` bei Planung `03cdccc51`. Das sind Momentaufnahmen, keine neue Integrationsvorgabe.

- [ ] Aktuellen Integrationsbranch, Nutzerbuild, Commit, uncommittierte Änderungen und die separat begonnenen R2-Kandidaten erfassen. Nichts ungeprüft zurücksetzen oder übernehmen.
- [ ] Kleine Repro-Matrix anlegen: Datapad, Buttonrand/X, Ausstieg/RMB, großer Kartenrand, Schiffsauswahl/Doppelklick, schwarzer Start, Betten und Mauer-/Höhenwerkzeug.
- [ ] Vergleichsszenen für Basisruhe, Kamerabewegung, Panelöffnung, Aufsitzen und große Bodenkarte festlegen. Auflösung, Renderer, Hardware, Unitanzahl, Seed und Kamerapfad protokollieren.
- [ ] Median und P95/P99 der Framezeiten sowie relevante lange Frames und UI-Öffnungszeiten erfassen; CPU/GPU und aktive/verborgene Ansichten unterscheiden.
- [ ] Daraus konkrete Framezeit-/Ruckler-/UI-Budgets für die Zielhardware ableiten und als verbindliche Paketabnahme dokumentieren. Keine unbelegte FPS-Zahl vor der Messung festschreiben; Alt-Save-Kompatibilität ist kein Planungsziel.
- [ ] Vorhandene Inventar-, Reise-, Sicht-, Gebäude- und Skirmishcontracts mit der Liste abgleichen. Konflikte ausdrücklich als Revision markieren.

**Liefert:** gemeinsame Quellbasis, isolierte Profile, Repro-/Messmatrix und Paketstatus. **Abnahme:** jeder spätere Befund hat Build-/Quellbezug; keine Behauptung einer pauschal grünen oder performanten Ausgangsbasis. Historische Performancezahlen sind kein frischer Vergleich.

## AP1 – Grundbedienung und stabile Menüs

**Dateien:** `scripts/meta/homebase_operations_presenter.gd`, `scripts/meta/singleplayer_job_board_presenter.gd`, relevante Popup-/Inputgrenzen in `homebase_screen.gd`; `docs/dev/homebase_operations_ux_contract.md`.

**Schnittstelle:** bestehende `get_operations_snapshot()` / `request_operation(operation, payload)`; nur UI-Fokus und offen/geschlossen lokal, kein Gameplayzustand.

- [ ] Reale Pointertests für Mitte, vier Randbereiche und Ecken von Annahme-/X-Buttons ergänzen, einschließlich überlagernder Controls und periodischem Refresh.
- [ ] Den tatsächlichen Eingabeempfänger korrigieren; sichtbare Fläche und Hitfläche müssen zusammenpassen. Nicht nur `pressed.emit()` testen.
- [ ] Plus-/Minus-Schalter für Basismenüs einführen; Fokus-/Mauswechsel und Panelrefresh dürfen ein angeheftetes Menü nicht schließen.
- [ ] Bei 1280×720, 1920×1080 und 3440×1440 prüfen: keine verdeckten Aktionen, kein ungewollter Weltbefehl beim UI-Klick und keine Klickdurchleitung beim Schließen.

**Abnahme:** ein Klick löst genau eine Aktion aus; Menüs bleiben bis zum expliziten Schließen offen. **Risiko:** z-Reihenfolge, Geschwisterreihenfolge und Inputfilter nicht verwechseln. Ausgangstest auf R2: `scripts/tests/job_app_safe_area_verifier.gd`.

## AP2 – Datapad und vollständiger erster Missionsabschluss

**Dateien:** `scripts/meta/singleplayer_runtime_adapter.gd`, `singleplayer_services_presenter.gd`, `scripts/core/singleplayer_campaign_state.gd`, `singleplayer_supply_state.gd`, `scripts/meta/campaign_checkpoint_store.gd`; Kampagnen-/Inventarcontracts.

**Schnittstelle:** vorhandenes `campaign_upload` über den Runtimeadapter, reale Container `base:homebase`, `craft:<craft_id>`, `unit:<unit_id>:backpack`; bestätigter Missions-/Heimkehrbeleg bleibt Voraussetzung.

- [ ] Nutzerfall auseinanderhalten: Chip tatsächlich vorhanden, Mission noch aktiv oder `pending_upload`, Schiff tatsächlich zuhause, Person und Container lokal erreichbar, Aktion sichtbar.
- [ ] Sichtbaren Basisterminalzugang herstellen und den konkreten Sperrgrund anzeigen, falls nur ein Teil der Voraussetzungen erfüllt ist.
- [ ] Upload aus jeder erlaubten lokalen Ablage prüfen; vorhandenen Chip einmal konsumieren, Abschluss und Belohnung einmal bestätigen.
- [ ] Wiederholte Requests, anderer Inhalt bei gleicher Request-ID, abgebrochene Mission, fehlender Chip und entfernter Träger dürfen keine Belohnung erzeugen. Auf einem gültigen isolierten Heimstand Save/Continue mit demselben Bestand/Fortschritt prüfen.
- [ ] Den tatsächlichen vollständigen Ausflug als offene Folgeabnahme nach AP5/AP9 vormerken und spätestens in AP15 durchführen; ein isolierter Uploadtest erledigt diesen Nachweis nicht.

**Kernabnahme für AP4:** sichtbarer Upload eines wirklich vorhandenen Chips mit gültiger lokaler Heimkehrevidenz; korrekter Verbrauch, Status, Belohnung und Save. **Gesamtabnahme nach AP5/AP9:** „bergen → zum Schiff → heimfliegen → landen → hochladen“ funktioniert sichtbar ohne Debugaktion. **Risiko:** Bestandskonsum und Missionsabschluss nicht durch einen UI-Erfolg auseinanderlaufen lassen. Vorhandene Ausgangsprüfungen: `campaign_five_missions_state_test.gd`; auf R2 zusätzlich `satellite_carried_chip_sortie_verifier.gd`.

## AP3a / AP3b – Direkter Gefechtsstart als schneller Prüfweg

**Dateien:** `scripts/ui/main_menu_screen.gd`, `scripts/meta/game_start_contract.gd`, `skirmish_start_configuration.gd`, `meta_layer_flow.gd`, vorhandene Karten-/Szenariodaten; `docs/dev/skirmish_prepared_starts_contract.md`.

**Schnittstelle:** vorhandenen Startvertrag erweitern, Karte/Szenario/Team getrennt lassen. Den neuen Einstieg mit festen gültigen Startkonfigurationen an bestehende Kampfowner übergeben, nicht einen parallelen Testkampf programmieren.

- [ ] Strategischen Spielweg und „Einzelgefecht“ klar trennen; die bestehende Kampagne bleibt erreichbar.
- [ ] **AP3a:** Bodenkarte, einsatzbereite Teams, sichtbare Startseitenvorschau und sofortiger Start; Neustart verwendet dieselbe gewählte Konfiguration.
- [ ] **AP3b:** denselben Ablauf für eine unterstützte Weltraumkarte und einsatzbereite Schiffe/Flotten anbinden. Vorhandene Begegnung nicht als vollständige beliebige Weltraumgefechtsfähigkeit ausgeben; fehlende Grundfunktionen als separaten Umfang kennzeichnen.
- [ ] Ungültige Karte oder belegter/unzugänglicher Startrand wird verständlich abgelehnt, statt in Hindernissen zu spawnen. Links/rechts/oben/unten bleiben mit Kameradrehung eindeutig.
- [ ] Neustart, Moduswechsel und Verlassen verändern weder Kampagnencheckpoint noch gespeichertes persönliches Team. Keine Suchauftrags-, Upload- oder Basisvorbereitungssperre im Einzelgefecht.

**Abnahme separat je Teil:** Auswahl → Kampf → Neustart ohne Umweg über Kampagne/Basis. **Risiko:** keine neuen Balancewerte, Gegner-KI oder Großschifffähigkeiten still festlegen. Bestehende Prüfbasis: `skirmish_prepared_starts_test.gd`, `skirmish_prepared_flow_test.gd`.

## AP4 – Gemeinsames Lager und Trupp-/Ausrüstungsbedienung

**Dateien:** `scripts/ui/components/personnel_inventory_panel.gd`, `scripts/meta/homebase_operations_presenter.gd`, `operations_drag_surface.gd`, `homebase_screen.gd`, `singleplayer_runtime_adapter.gd`; `scripts/core/singleplayer_supply_state.gd` nur falls ein nachgewiesenes Ownerdefizit besteht.

**Schnittstelle:** vorhandene `inventory_transfer`-/`inventory_equip`-Commands, bestehende Container-/Loadoutowner; Truppentfernung und Details über bisherige Operationsaktionen.

- [ ] Einen Layoutentwurf zeigen: schmalere Charakter-/Ausrüstungskarte, rechts mindestens eine vollwertige Lagerspalte, Basis-/Schiffsauswahl zugeordnet. Kein endgültiges Pixelschema aus „halb so breit“ erfinden.
- [ ] Beide Transferrichtungen aus demselben Bestandsnapshot anbieten. Menge, Zugriff, Slotkompatibilität, Kapazität und Requestwiederholung am Owner validieren.
- [ ] Entfernte Schiffe dürfen angezeigt, aber nicht durch bloße Auswahl als lokales Lager nutzbar werden. Voller Zielcontainer und abgebrochener Drag erhalten alle Bestände.
- [ ] Herausziehen ins Personal entfernt die Truppzuordnung über den vorhandenen Command. Doppelklick öffnet Details; erst danach die beiden redundanten Buttons entfernen.
- [ ] Geeignete Spaltengrenzen per Ziehen verstellen können; Mindestgrößen, Bildschirmwechsel und Fokus bleiben stabil. Dauerhafte Layoutprofile sind eine noch offene Zusatzentscheidung.

**Abnahme:** tatsächlicher Bestand ist in allen Ansichten identisch; keine Gegenstände/Personen dupliziert oder verloren. Volle Container, Busy-Personen und zweites entferntes Schiff mitprüfen. Bestehende Limits bleiben bis zu einem eigenen Balanceauftrag unverändert.

## AP5 – Besatzungsplätze und Auf-/Absitzen als Runtimevertrag

**Dateien:** `scripts/core/base_personnel_runtime.gd`, `scripts/meta/aircraft_manager.gd`, `singleplayer_runtime_adapter.gd`, vorhandene Transport-/Deploymentpfade in `scripts/tests/mission_tactical_sandbox_controller.gd`, `scripts/mission/mission_dropship_effect_adapter.gd` und vorhandene Hex-Deployment-/Footprintadapter auf AP0-Basis.

**Contractarbeit:** einen kleinen `docs/dev/ship_crew_stations_contract.md` erst bei Umsetzung anlegen beziehungsweise vorhandenen passenden Vertrag erweitern. Er beschreibt Platztypen, Belegung/Reservierung, erlaubte Übergänge und Savegrenzen; keine Belegung nur im Presenter speichern.

- [ ] Pilot, Cutlass-Turm und zunächst vier Cutlass-Passagierplätze anhand der tatsächlichen Schiffsdefinition modellieren; Truppzugehörigkeit getrennt erhalten.
- [ ] Drag auf einen Platz beauftragt einen wirklichen Weg und reserviert gültig. „An Bord“ erst nach bestätigter Ankunft; eine Person belegt nie zwei Plätze oder Schiffe.
- [ ] Buccaneer-Cockpit und Cutlass-Heckklappe als passende Ein-/Ausstiegsanker prüfen; Hull-Footprint, freie Ausstiegsfelder und Navigation verwenden dieselbe Geometrie.
- [ ] „Absitzen“ betrifft Passagiere; Funktionsbesatzung bleibt. „Aufstehen“ gibt Pilot-/Turmplatz frei, steigt nicht sofort aus und macht die Person für das folgende Absitzen verfügbar. Den Fall vollständig belegter Passagierplätze vorher entscheiden.
- [ ] Nach bestätigtem Ausstieg den vorhandenen Rechtsklick-/Fireteambefehl ohne erneute Auswahl-/Phasenblockade annehmen können.
- [ ] Doppelklick/Dragwiederholung, voller Platz, Tod/Ausfall, Schiffwechsel und Save/Continue dürfen keine Doppelbelegung oder Phantomcrew erzeugen. Bestehende Autoritäts-/Multiplayergrenzen erhalten.

**Abnahme:** je ein tatsächlicher Auf-/Absitzlauf pro Schiffstyp sowie Pilot/Turm sitzenbleiben und gezieltes Aufstehen. **Risiko:** neuer Turmslot bedeutet Besetzbarkeit; allgemeine neue Turm-Kampfmechanik ist hier nicht automatisch beauftragt.

## AP6 – Flugdeck auf gemeinsamer Basisprojektion

**Dateien:** `scripts/meta/homebase_operations_presenter.gd`, `explorable_homebase.gd`, `transport_craft_card_ui.gd`, vorhandene Personal-/Schiffsvisuals. Contract: `homebase_operations_ux_contract.md`.

**Schnittstelle:** dieselben Basisakteure, Positionen, Pads und AP5-Plätze; keine Vorschaucrew und kein Simulationsreset beim Ansichtswechsel.

- [ ] Kompakten Entwurf mit ausgewähltem Schiff, Porträt-/Platzkarten und schmalen Personal-/Truppspalten zeigen; persönliche Lager-/Ausrüstungsansicht hier weglassen.
- [ ] Basis und Flugdeck passend zum Rahmen darstellen; kein erzwungener Nahzoom, der Laufwege abschneidet. Vorschau zeigt dieselben wirklichen Personen.
- [ ] Einzelpersonen und Trupps auf Schiff/Plätze ziehen, auch Pilot aus einem Trupp. Platzwechsel und Herausziehen verwenden AP5.
- [ ] Hinlaufen bis zum korrekten Einstieg sichtbar verfolgen; zwischen Basis, Lager und Flugdeck wechseln, ohne Weg, Belegung oder Personen zu verlieren.
- [ ] Verborgenes Flugdeck rendert/pollt nicht dauerhaft. Bestehende Szene und Visuals wiederverwenden; sichtbare Bewegungsupdates gezielt anfordern.

**Abnahme:** gesamter Aufsitzvorgang und Kartenbedienung in den drei Zielauflösungen sichtbar und nutzbar. Ausgangstest: `scripts/tests/playtest_20261109_pad_preview_verifier.gd`; alte Erwartung „Personen unsichtbar“ an den neuen Nutzervertrag anpassen, nicht blind beibehalten.

## AP7 – Sternkarte: Ansicht, Auswahl und Reise trennen

**Dateien:** `scripts/ui/star_map_screen.gd`, `star_map_canvas.gd`, `scripts/meta/singleplayer_region_map_presenter.gd`, `singleplayer_runtime_adapter.gd`, `scripts/core/singleplayer_space_travel_state.gd` und vorhandener Orbitkartenpfad der AP0-Basis.

**Schnittstelle:** ausgewähltes Ziel ist Präsentations-/Planungszustand; vorhandene Reisecommands werden nur durch „Sprung ausführen“ ausgelöst. `docs/dev/orbit_quantum_travel_contract.md` muss den historischen Sofortstart durch Zielklick ausdrücklich ablösen.

- [ ] Schiffsklick hält die benötigte Anzeige offen; Dropship-/Schiffssymbole eindeutig darstellen.
- [ ] Doppelklick auf OM, Planet oder Planetoid öffnet dessen Karte ohne Fahrt, Fuelbuchung, Ortswechsel oder Erkundung. Den ersten Einzelklick eines Doppelklicks ebenfalls reisefrei halten.
- [ ] Einfacher Zielklick wählt nur; kleinen Sprungbutton am ausgewählten Schiff mit Ziel-/Bereitschaftsanzeige anbieten.
- [ ] Bekannte Planetoiden-/Ortsmarker wieder zuverlässig zeichnen und treffen lassen; Zeichen-/Pickingtransform bei Pan/Zoom gleich halten. Versteckte Ziele nicht als „Reparatur“ pauschal einblenden.
- [ ] Kartenansicht und reales Schiffsziel unabhängig halten; Wechsel der betrachteten Karte darf laufende Reise nicht umlenken. Namen „Asterheim“ und Port-Olisar-Zuordnung erst über reale IDs prüfen.

**Abnahme:** zehn reine Ziel-/Kartenklicks bewegen kein Schiff; ein gültiger Sprungbefehl startet genau eine Reise. AP8 übernimmt den Inhalt der geöffneten unbekannten Karte. Prüfbasis: `star_map_ui_verifier.gd`, `star_map_camera_verifier.gd`.

## AP8 – Erkundung, Sicht und Marker ohne Informationsleck

**Dateien:** `scripts/core/fog_of_war_system.gd`, `fog_of_war_mode_contract.gd`, bestehende Sichtowner, `scripts/terrain/terrain_map_3d_view.gd`, Karten-/Markerpresenter und Checkpointpfad. Contract: `docs/dev/fog_of_war_modes_contract.md`.

**Schnittstelle:** vorhandene `terrain_knowledge.visible_tile_ids` / `explored_tile_ids`, `current_visibility` und `last_known_contacts`; Team-/Peerfilter vor Darstellung und bei relevanten Snapshots beibehalten.

- [ ] Unbekannt schwarz, erkundet unbeobachtet dunkel und aktuell sichtbar hell auf Boden- und unterstützten Raum-/Ortskarten umsetzen. Den bisherigen Default `known_terrain` für unbekannte Kampagnenorte gezielt revidieren.
- [ ] Port Olisar mit bekanntem statischem Terrain initialisieren; aktuelle Personen/Gegner/Ereignisse folgen trotzdem Sichtregeln. Keine pauschale Entdeckung aller anderen Karten.
- [ ] Tatsächlicher Anflug und Bodensicht dürfen passende Bereiche aufdecken; Kartenöffnen, Kameraschwenk oder Kartenwechsel allein nicht.
- [ ] Satellitenziel und unbekannte Innenräume durch alle Ausgabepfade prüfen: Weltmarker, Minikarte, Hover, Zielliste, Kontextmenü und NPC-Meldung dürfen keinen Standort verraten.
- [ ] Erkundung bei Ortswechsel und unterstütztem Save/Continue erhalten; aktuelle Sicht nach Restore aus echten Beobachtern neu ableiten. Unbekannte Gegner nicht als aktuelle Kontakte rekonstruieren.

**Abnahme:** echte Entdeckung mit anschließender Sichtunterbrechung zeigt drei unterschiedliche Zustände; zweite Teamansicht erhält kein fremdes Wissen. Bestehende Fog-Verifier TASK_223–225 als Nachbarn verwenden; die echte Suchmission zusätzlich nativ prüfen.

## AP9a / AP9b – Kartenrand, OM-Automatik und Warp

**Dateien:** vorhandene Transportsequenzen in `scripts/tests/mission_tactical_sandbox_controller.gd`, `scripts/meta/meta_layer_flow.gd`, `singleplayer_runtime_adapter.gd`, `scripts/core/singleplayer_space_travel_state.gd`, vorhandener Orbit-Transitowner/-planner und `scripts/terrain/mission_flight_visual.gd` auf AP0-Basis.

**Schnittstelle:** tatsächliche Terrainbounds und akzeptierte Flugrichtung; Reise-/Payloadowner bestätigen Handoff. Vorhandene Automatik weiterverwenden, nicht parallel im UI nachbauen.

- [ ] **AP9a:** Primär- und Mehrschiffpfade gegen große Karten prüfen. Start und Ende liegen tatsächlich jenseits der äußeren Kartengeometrie; feste Entfernungsobergrenzen dürfen das nicht unterlaufen.
- [ ] Wählbaren Abflugwinkel beziehungsweise umgekehrten Anflug sauber an dieselbe Sequenz binden; kein Wechsel der Richtung mitten in einer bestätigten Flugphase durch bloßes UI-Polling.
- [ ] Schiff verlässt zuerst sichtbar die Bodenkarte, erscheint danach auf der richtigen OM-Karte und behält Besatzung, Inventar und Identität. Keine vorzeitige Heimkehr, Missionserledigung oder Kostenbuchung.
- [ ] Automatik an: nur eine bereits ausdrücklich beauftragte Route bei freiem Weg fortsetzen. Aus: auf OM stehenbleiben. Begegnung/Hindernis unterbricht; Umschalten erzeugt keinen Doppelstart.
- [ ] **AP9b:** Warp-Blase mit Eintritt, nachvollziehbarer Bewegung und Austritt ergänzen. Langsamere Probe anbieten; Darstellung an tatsächlichen Reisefortschritt binden. Eine längere Animationsprobe darf kein zweites Reisetiming erzeugen.
- [ ] Abbruch/Neustart, zweites Schiff und unterstütztes Flug-Save/Continue prüfen; neue Flug-Savefähigkeit nicht allein aus einer vorhandenen Branchprobe ableiten.

**Abnahme getrennt:** erst echter Rand-/OM-Lauf und Automatik, dann native Animationsabnahme. Auf R2 vorhandene Ausgangsgates: `orbit_auto_transit_planner_verifier.gd`, `orbit_auto_transit_owner_verifier.gd`, `orbit_auto_transit_ui_verifier.gd`.

## AP10 – Sprechblasen und aussagekräftige Hoverinfos

**Dateien:** bestehende Event-/Meldungspresenter und Fireteamkarten, `scripts/meta/homebase_operations_presenter.gd`, `explorable_homebase.gd`, vorhandene Hilfe-/Tooltipkomponenten; tatsächliche Profile und Runtimeereignisse als Quelle.

- [ ] Meldungen dem sprechenden NPC und seiner wirklichen Fireteamkarte zuordnen; Kartenwechsel erhält die korrekte Zuordnung.
- [ ] Wenige konkrete Texte pro bestehender Meldungsart formulieren: Was passiert, warum und was kann der Spieler tun? Keine erfundene Gameplayinformation aus dekorativem Text.
- [ ] Hover über Personen in Basis und Karten zeigt vorhandene Rolle/Fähigkeiten, insbesondere Piloteneignung; Name bleibt Identitätsangabe statt alleiniger Hilfetext.
- [ ] Verständliche Texte, lesbare Sprechblasen und begrenzte Anzeigezeit/Queue bei Meldungsflut prüfen. Meldungen dürfen keine Buttons oder Dragziele blockieren.
- [ ] Versteckte Gegner/Ziele nicht über Texte verraten; AP8-Sichtfilter beachten. Kein globaler Text-/UI-Rebuild je Frame.

**Abnahme:** verständlicher Normalfall, Fehlerfall und gleichzeitige Meldungen mehrerer NPCs; Nutzer kann Sprecher und nächste sinnvolle Handlung erkennen.

## AP11 – Editorübersicht und Höhenwerkzeug

**Dateien:** `scripts/editor/map_editor.gd`, `map_editor_height_tool.gd`, `map_editor_primary_view_adapter.gd`, `map_editor_tile_property_overlay.gd`, `scenes/editor/map_editor.tscn`; Editorcontracts unter `docs/dev/`.

- [ ] Klar erkennbare Werkzeuggruppen, aktive Auswahl und aktuelle Einstellungen entwerfen; Gesamtansicht als gut auffindbare Aktion anbieten.
- [ ] Höhenwerkzeug mit eindeutigen Aktionen „Anheben“ / „Absenken“, sichtbarer Höhe und Vorschau ausstatten; Hex-/Square- und Rampenregeln verwenden die vorhandene Terrainwahrheit.
- [ ] Eine Bearbeitung muss als vorhandener Authoring-/Undo-Schritt rücknehmbar sein. Gelände-/Objekt-/Markerlayer nicht versehentlich gemeinsam löschen oder ändern.
- [ ] Save As → schließen → laden erhält Höhen, Topologie, Marker, Szenariobindungen und zusätzliche Metadaten.

**Abnahme:** ohne Quellkenntnis Karte überblicken, Stelle wählen, erhöhen, absenken, rückgängig machen und korrekt neu laden können. Ausgangsprüfungen: `map_editor_metadata_saveas_verifier.gd`, `task_295_map_editor_paint_toolbar_tools_polish.gd`.

## AP12 – Mauern, Assetmaßstab und Vergleichsobjekte

**Dateien:** `scripts/editor/map_editor.gd`, bestehende Netzwerk-/Wandauthoringhelper (auf R2 `wall_gate_authoring.gd`), `scripts/terrain/terrain_tile_catalog.gd`, vorhandene Modellmappings und MapData; Editor-/Grafikcontracts.

- [ ] Mauergenerator mit Endstück, Gerade, Ecke, T-/Kreuzverbindung, Rotation und Anschluss an Tore reproduzieren; nur tatsächlich fehlerhafte Verbindungen korrigieren.
- [ ] Kette, Nachbaraktualisierung und Rücknahme über vorhandene Authoringcommands atomar halten; Sicht-/Kollisions-/Navigationsfakten an derselben Wandgeometrie prüfen.
- [ ] Betroffene Kenney-Familien mit Mensch und Fahrzeug bei derselben Kamera vergleichen. Mappingmaßstab, Instanzskalierung, Footprint, Türhöhe und Durchgang gemeinsam beurteilen.
- [ ] Referenzpersonen/-fahrzeuge im Editor zum Platzieren anbieten. Als reine Vergleichshilfen kennzeichnen und nicht still als echte Trupp-/Fahrzeugspawns in Szenarien speichern.
- [ ] Originalmodelle und funktionierende Heimatbasis erhalten. Korrektur möglichst an der tatsächlichen fehlerhaften Quelle statt pauschaler Skalierung sämtlicher Assets.

**Abnahme:** nachvollziehbare native Größenvergleiche und funktionierende Wandkombinationen einschließlich Undo/Reload. Auf R2 passende Ausgangsgates: `editor_wall_gate_verifier.gd`, `wall_direction_mapping_verifier.gd`; allgemeiner Nachbar: `task_492_map_editor_network_drag_snap_tools.gd`.

## AP13 – Dächer und Innenraumfreigabe

**Dateien:** vorhandene Gebäudedefinitionen/-visuals und Sichtanbindung, `scripts/meta/explorable_homebase.gd`, `scripts/terrain/terrain_map_3d_view.gd`, Editor und Checkpointpfad falls neues gespeichertes Wissen nötig ist. Bei Umsetzung Dach-/Innenraumvertrag ergänzen.

- [ ] Pro Gebäude geschlossenes Dach und offene Ansicht sauber zuordnen; kein Ersatz der bereits gefallenden Basiseinrichtung.
- [ ] Heimatbasis und Editor bieten einen ausdrücklichen Dachschalter. Dachansicht ist Darstellung, keine Änderung an Wänden, Türen, LOS oder Navigation.
- [ ] Unbekannter Außenposten bleibt in der Spieleransicht geschlossen; tatsächliches Betreten bestätigt Innenraumfreigabe. Spieler-Kartenvorschau und Runtimeansichten dürfen keinen fremden Innenraum aufdecken.
- [ ] Der ausdrücklich geöffnete Authoring-Editor darf dagegen das bearbeitete Gebäude vollständig offen zeigen. Dies verändert kein Erkundungswissen einer laufenden Spielwelt und wird nicht als Entdeckung gespeichert.
- [ ] Verhalten nach Verlassen vor Umsetzung festlegen und im Contract dokumentieren; aktuelles Sichtrecht und einmal erworbenes Wissen getrennt halten.
- [ ] Pro Gebäude und bei mehreren gleichzeitig betretenen Gebäuden prüfen; keine gemeinsame globale Dachvariable, die alle Gebäude enthüllt.

**Abnahme:** Heimatbasis offen/geschlossen, Editorvergleich und Außenposten vor/während/nach Betreten; AP8-Sichtschutz bleibt erhalten.

## AP14a / AP14b / AP14c – Visuelle Inhalte separat abnehmen

**Dateien:** `maps/satellite_crash_site.json` und zugehörige vorhandene Visuals; `scripts/meta/base_capacity_layout.gd` und Skirmish-Basisprojektion; Rüstungs-/Personenvisualmapping. Grafikreferenzvertrag gilt für alle Kandidaten.

- [ ] **AP14a Absturzstelle:** erkennbare Satellitenform, Schleiffurche, Trümmer und passende Bodenübergänge gestalten. Suchziel unter AP8 verborgen halten; Furche, Trümmer oder Beschriftung dürfen nicht durch unbekanntes Schwarz scheinen. Erreichbarkeit des Datapads und Heimweg erhalten.
- [ ] **AP14b Betten:** Ursprung der äußeren Skirmishbetten prüfen; vorhandener Vertrag erlaubt historische Zusatzfeldbetten. Gewünschte Innenraumzuordnung bewusst revidieren und Kapazität, Einzelbelegung und echte Wege für Early/Mid/Late erhalten. Betten nicht bloß optisch unter ein Gebäude verschieben.
- [ ] **AP14c Schwere Rüstung:** native Vorder-/Seiten-/Rückansicht und Bewegung gegen dieselbe Personenidentität vergleichen; Maßstab, Clipping und Material korrigieren. Keine Änderung der Schutz-/Bewegungswerte ohne eigenen Balanceauftrag.
- [ ] Je Teil ein eigener Kandidat, Vorher-/Nachhervergleich und Abnahme; technische Import-/Geometrieprüfung und Nutzerurteil getrennt ausweisen.

**Abnahme:** jeder Teil unabhängig. Bettennachbarn: `base_capacity_layout_test.gd`, `base_personnel_expansion_test.gd`. Die gute Gestaltung der vorhandenen Heimatbasis bleibt Referenz, keine Freigabe für einen Totalersatz.

## AP15 – Performancekorrekturen und zusammenhängende Abnahme

**Dateien:** nur die durch AP0-/Paketmessungen tatsächlich identifizierten Hotpaths; `docs/performance/` und `docs/qa/` für reproduzierbare Evidenz.

**Priorität:** Performance ist bereits in AP0 und jedem Umsetzungspaket
verbindlich. AP15 bündelt Messvergleich und Gesamtabnahme; notwendige
Korrekturen werden nicht bis hierhin aufgeschoben. Alte Savegames sind auch
hier kein Kompatibilitäts- oder Migrationsgate.

- [ ] Auf derselben Karte, Auflösung, Kamera, Unitanzahl, Engine/Renderer und Hardware wie AP0 erneut messen; Warm-up und Importspitzen gesondert kennzeichnen.
- [ ] Verbleibende teure UI-/Viewport-/Snapshot-/Sichtpfade einzeln korrigieren und jeweils den passenden kleinen Verifier oder eine dokumentierte Profilerprobe mitliefern.
- [ ] Median/P95/P99, lange Frames und Panelöffnungszeiten vorher/nachher ausweisen. CPU-Beschleunigung nicht ohne native Messung als FPS-/GPU-Gewinn bezeichnen; Zielbudget nach AP0 festlegen, keine unbelegte Zahl versprechen.
- [ ] Kampagnendurchlauf: Vorbereitung/Lager → Plätze → sichtbares Aufsitzen → Sternkartenziel wählen → ausdrücklicher Sprung → Anflug/Erkundung → Datapad → Absitzen-/Aufsitzregeln → OM an/aus → Heimatlandung → Upload → Save/Continue.
- [ ] Boden- und Raum-Einzelgefecht mit allen angebotenen Startseiten starten und neu starten; Editorhöhe/Mauer/Dach speichern und neu laden; Skirmishbetten und schwere Rüstung nativ prüfen.
- [ ] L01–L23 samt Unterpunkten einzeln bewerten: umgesetzt, technisch geprüft, native Abnahme offen oder konkret blockiert. Keine Gesamtfreigabe nur aus der Anzahl grüner Assertions ableiten.

**Abnahme:** vollständige Zuordnung der Ergebnisse zu den Anforderungen, nachvollziehbare Restpunkte und messbare Aussage zur Performance. Kein zusätzlicher Featureumfang und kein automatischer Release.

## Statusführung und Abschluss dieses Planungsauftrags

| Stand | Bedeutung |
| --- | --- |
| Geplant / offen | Anforderung erfasst, keine Umsetzung aus diesem Auftrag |
| Vorhandener Kandidat | Frühere Teiländerung gefunden; nicht automatisch integriert oder geprüft |
| Technisch geprüft | Konkreter Commit, Verifier, Ergebnis und Grenzen dokumentiert |
| Native Abnahme offen | Technische Prüfung ersetzt kein tatsächliches Bedien-/Gestaltungsurteil |
| Abgenommen | Zugehörige technische und native Kriterien nachgewiesen |

Dieser Planungsauftrag prüft nur Dokumentation: vollständige Liste, alle
Paketzuordnungen, Links, Abhängigkeiten, Scope und unveränderte Produktdateien.
Er endet mit gespeicherter Masterliste und Arbeitsplan. Umsetzung bleibt bis
zu einem späteren ausdrücklichen Arbeitsauftrag ausgesetzt.
