# Kampagnen-Playtest: Orte, Landung, Inventar und parallele Trupps

Stand: 10.11.2026. **Gesammelter Nutzerauftrag und Bestandsabgleich; keine Umsetzung.**

## Ziel / Problem

Die erste Kampagnenrunde ist fuer den Nutzer nach Landung und Satelliteninteraktion
nicht nachvollziehbar weiter spielbar: Wiedereinsteigen, Schiffsauswahl und
Missionsabschluss sind unklar. Die kleinen isolierten Karten, ausladenden Panels
und abstrakten Ausruestungsfelder verfehlen wichtige bereits vorhandene Bildziele.
Die Welt soll langfristig mehrere gleichzeitig benutzte Ortskarten tragen.

## Arbeitsbasis und Aussagegrenze

- Quellstand: `046b6d91a` (Main, Kampagnenersatz-Absturzfix), neuer eigener
  Doku-Branch `task/playtest-plan-20261110`. Der alte Integrationsbranch steht
  auf `3cae5a216`; er enthaelt den untersuchten aktuellen Kampagnen-/Orbitstand
  nicht. Diese Planung baut bewusst auf dem bereits integrierten Main auf.
- Quelle des Nutzerurteils: laufender Playtest in diesem Chat; Screenshot im
  Referenzpaket. Welche EXE/Quellrevision der Screenshot genau zeigt, ist
  **nicht verifiziert**. Vor Fehlerreproduktion Paketpfad/Buildbeleg erfassen.
- Quellen wurden gelesen; vorhandene QA wird als historischer Nachweis genannt.
  In dieser Planung keine neue Godot-Sitzung und keine erneut bestandenen Tests.
- `SternenBuergerchen-Neustart` ist ein separates historisches Projekt. Seine
  Screens/Implementierungen sind kein Funktionsnachweis fuer dieses Repository.

## Gewuenschtes Verhalten / vollstaendige Sammlung

### A. Kampagne wieder spielbar machen

1. Gelandetes Schiff direkt in der Welt auswaehlen und dessen Aktionen sehen.
2. Trupp nachvollziehbar zum Schiff schicken, einsteigen lassen, Besatzung und
   Pilotbereitschaft bestaetigen, dann abheben und heimkehren. Fehlende Person,
   Entfernung oder beschaedigtes Schiff brauchen konkrete Gruende.
3. Satellitenfortschritt in verstaendlichem Deutsch: Daten noch nicht gesichert,
   Sicherung laeuft, Daten gesichert, Rueckkehr/Boarding offen, Auftrag erledigt.
   Datenbergung, Auftragsabschluss und sichere Heimkehr bleiben getrennte Fakten.
4. Kampagnenhilfe darf die Navigation neben Homebase/Einsatz nicht ueberdecken;
   fester konfliktfreier Platz oder verschiebbares Panel mit sicherem Ruecksetzen.
5. `COM BLOCKED` / `NEXT COM?` und dunkle Ersatzobjekte sind unerklaerlich.
   Verstaendliche Interaktionsnamen und erkennbare Satelliten-/Rueckkehrziele
   einsetzen; technische IDs/Zustaende nur in Diagnoseansichten erhalten.

### B. Karten als Orte auf einem Planeten

6. Heimatbasis, Satellitenabsturzstelle und Handelsposten verwenden dieselbe
   zusammenhaengende Landschaftsgrundlage mit grossen einzeln ladbaren Karten.
   Terrain fuellt die sichtbare Weltflaeche, nicht ein kleines freigestelltes Brett.
7. Keine dekorative Blockkette als Kartenzaun. Endliche Karten behalten klare
   echte Grenzen, landschaftlich passend gestaltet; keine unsichtbar begehbare
   Dekoflaeche. Kamera, sichtbarer Boden und spielbare Topologie gemeinsam pruefen.
8. Basis als kleiner wohnlicher Gebaeudeverbund mit schoenem kleinem Landepad,
   erreichbaren Innenraeumen und ausreichend Erweiterungsflaeche. Kamera startet
   zur Basis gezoomt; eine grosse Karte muss nicht vollstaendig sichtbar sein.
   Bestehende eingerichtete Raeume nicht durch kahle Ersatzbauten ersetzen.
   Kein Auftrag, funktionsfaehige weitere Pads oder die zwei Originalraeume zu loeschen.
9. Andere Orte bieten raeumlich getrennte Gruende fuer Besuche: z.B. Satellit,
   Erzvorkommen und grosses verwertbares Wrack auf derselben Karte. Erst Landschaft
   und Platzierung; tatsaechliches Mining/Salvage braucht endliche Ressourcen und
   eigene bestaetigte Aktionen, keine bloss dekorativen Erfolgsbuttons.
10. Das aus der Distanz falsch gekippte/abgeschnittene Erscheinungsbild pruefen.
    Screenshot belegt das sichtbare Urteil, keine bereits diagnostizierte
    Projektions- oder Meshursache. Isometrische Lesbarkeit erhalten.

### C. Landung und Befehle

11. Auf geeigneten freien Flaechen LZ frei waehlen statt Kampagnen-Pflichtpunkt.
    Schiffsfussabdruck, Hoehe, Hindernisse, andere Schiffe, Ausstieg und anschliessend
    erreichbarer Rueckweg gelten fuer Ziel **und** tatsaechlichen Aufsetzpunkt.
12. Pro Schiff Anflugrichtung ueber Uhr/Richtungskreis einstellen; vorhandene
    Richtungsdaten wiederverwenden, Kompass/Kameraorientierung eindeutig anzeigen.
13. Normaler Anflug: gerade anfliegen, abbremsen, leicht hochziehen/abfangen,
    schweben und kontrolliert aufsetzen; sichtbare Triebwerks-/Abgasstrahlen.
    Pilotenskill beeinflusst Zielabweichung. Keine willkuerliche Teleportlandung.
    Vorhandene Skillauswertung zuerst pruefen, Einheiten/Balance nicht blind kopieren.
14. Kleiner Schalter `Planmodus an/aus` im oberen Viertel des GO-/Plan-ausfuehren-
    Buttons. An: Vorschau und bestaetigtes GO wie bisher. Aus: Rechtsklick auf
    gueltigen Boden bewegt den ausgewaehlten Trupp sofort ueber denselben Commandpfad.
    Echtzeit bleibt Echtzeit; kein Pausenschalter und keine Einzel-NPC-Steuerung.
    Ausstehende Plaene beim Umschalten nicht automatisch ausfuehren oder loeschen.

### D. Personal, Inventar und Platzaufteilung

15. Personenkarten etwa auf ein Drittel der jetzigen Breite verdichten, sofern
    Name/Status/Schrift lesbar bleiben. Vorhandene Sortierung, Doppelklick, Badges,
    Drag-and-drop und wachsende Personalzahlen erhalten. `Onboard`/`Medium`
    durch passende deutsche Status-/Ausruestungsbegriffe ersetzen.
16. Inventar nach Ida-Referenz: Figur/Person, sichtbare anlegbare Ausruestung,
    Basislager, Schiffsfracht, persoenlicher Rucksack und Gegenstandsmengen.
    Transfers und Anlegen per Drag-and-drop plus klickbarer Alternative.
    Leichte/mittlere/schwere Ruestung erkennbar; Referenz-Helm/Werkzeug/Aufsatz/
    Rucksack als Slots im Modell abgleichen. Kein Erfassen bloss vorgetaeuschter
    aktiver Slots ohne Gegenstandstyp und Owner. Keine Beispielwerte uebernehmen.
17. Personal und Truppansicht verwenden dieselbe Ausruestungsbedienung und echte
    Daten. Einheitlichen Detail-/Inventareinstieg statt zweier Inventarsysteme.
18. In Trupp & Ausruestung sowie Einsatz & Abflug erkennbares reales Schiff mit
    Besatzung/Pilot und Auswahl weiterer vorhandener Schiffe. Keine erfundene Flotte.
19. FOB-Knopf aus der normalen Navigation entfernen. Smart Mobile ganz unten an
    dessen Stelle. Der bisherige technische FOB-Pfad muss dafuer nicht geloescht werden.
20. Module mit sinnvollen Maximalbreiten, mehreren Spalten/Zeilen und lesbaren
    Schriften. Nicht jedes Feld auf volle Fensterbreite strecken. Raum fuer Inventar,
    Zusatzinformationen und spaetere Aktionen behalten; keine spekulativen Buttons.

### E. Sternkarte und parallele Welt

21. Sternkarte schoener nach Asche-System-Referenz; Orte direkt auf/bei dem
    Planeten Glut anklickbar. Rechte Ortsliste bleibt als gleichwertiger Zugang.
    Zielauswahl startet weiterhin nicht automatisch Reise oder Kartenanflug.
22. Schiffspfeil durch kleines erkennbares isometrisches Cutlass-Modell/aus dem
    bestehenden Modell gerenderte Darstellung ersetzen. Cursorzoom und Pan erhalten.
    Weitere Planeten der Referenz sind kein neuer Contentauftrag.
23. Mehrere Trupps sollen unabhaengig zu verschiedenen Orten reisen koennen.
    Aufenthaltsort, Trupp, Schiff und Reisephase sind explizit zugeordnet.
24. Ortsansicht wechseln ist kein Ortswechsel: andere Orte und beauftragte
    Taetigkeiten laufen weiter, gegebenenfalls vereinfacht. Karten koennen visuell
    geladen/entladen werden, ohne ihre autoritativen Zustaende zu verlieren.
25. Orbit-/Wartezustaende sind sichtbar und pro Schiff unabhaengig. Ein belegter
    Platz darf ein anderes Schiff warten lassen, aber nicht die gesamte Welt sperren.
26. Spaeter gemeinsame Ortsinstanz fuer Spieler mit verschiedenen Zielen
    (Auftrag/Mining/Salvage) und moeglichen PvP-Begegnungen. Multiplayer jetzt
    beruecksichtigen, aber keine neue Netzwerk-/PvP-Implementierung beauftragt.

## Bestandsabgleich: Design und Code

| Bereich | Aktueller Befund | Einordnung / Konsequenz |
|---|---|---|
| Ausser Sicht weiterlaufen | PROJECT_BRIEF: Out-of-View-Simulation darf vereinfacht weiterlaufen; ARCHITECTURE bestaetigt Konsistenz. | Grundidee vorhanden; keine Abnahme mehrerer Ortsinstanzen. |
| Mehrere Ortskarten | Orbitvertrag: ausdruecklich ein aktiver Reiseausflug. `singleplayer_space_travel_state.gd` besitzt eine `_craft_id` und `_location_id`; `meta_layer_flow.gd:4084` ersetzt `_active_mission` beim Start. | Konkrete Scope-Erweiterung gegenueber V1; kein reiner UI-Fix. Per-Craft-Departures im Kampagnenstate und parallele Dropships auf **einer** Karte loesen das nicht. |
| Orts-/Jobtrennung | `SingleplayerCampaignState` und locations/jobs JSON vorhanden; mehrere Jobs je Ort als Vertrag erlaubt. | Wiederverwenden; Ortsinhalt darf nicht nur aus aktuellem Auftrag entstehen. |
| Karte | JSON: Heimatbasis 36x28, Satellit 22x18, Handel 20x18, jeweils Hex. | Kleine aktuelle Inhalte bestaetigt. Bildschirmfuellung, Zoom und tatsaechliche Flaeche getrennt behandeln; konkrete Zielgroesse erst am Performance-/Spielabstand festlegen. |
| Freie LZ | Controller `_place_lz_from_screen_position()` lehnt andere Punkte als `spawn_alpha` explizit ab; `_get_authored_campaign_pad_position()`/Rueckkehr pruefen feste Marker. Ortsvertrag schreibt diesen Padpfad fest. | Nutzerwunsch ersetzt diesen Vertrag fuer geeignete Feldlandungen. Boarding, Szenario-Rueckkehr und Genauigkeit zusammen aendern, nicht bloss Padpruefung entfernen. |
| LZ-Skill/Richtung | `DropshipLZAccuracyContract.resolve_lz_command()` trennt Soll/Ist; Skillmix 72% Pilot/28% Team, Radius 96..12 in bisherigen Weltkoordinaten. Pro-Craft-Approach vorhanden. | Bestehende Logik anbinden/pruefen; Werte sind keine zugesagten Hex-Abweichungen. |
| Wiedereinsteigen | `request_campaign_crew_boarding()` verlangt lebende Bodenpersonen innerhalb 128 Weltkoordinaten vom geparkten Schiff, danach pending/Tick. `_request_singleplayer_return()` nutzt diesen Pfad. Kompakte Schiffskarte bietet primaer LZ/Drop, weitere Aktionen unter Details. | Funktionelle Teile existieren; Nutzer findet/erreicht Weg nicht. Produktklickpfad pruefen, nicht aus Helpertests Erfolg ableiten. |
| Satellitenabschluss | jobs JSON verlangt `secure_satellite` und `return_to_ship`; Szenario nennt 3s Dateninteraktion. Kein automatischer Erfolg durch Landung. | Eindeutige sichtbare Teilziele; Erfolg, Belohnung und Heimkehr aus echten Belegen. Ob konkrete Nutzerrunde abgeschlossen war, ist nicht ermittelt. |
| COM/NEXT | `mission_interaction_visual_state.gd` baut Token COM fuer Computer, BLOCKED fuer gesperrt und NEXT fuer naechste Interaktion. | Keine Netzwerkfehlermeldung. Technische Kurztexte stammen aus produktiver Interaktionsanzeige; benoetigen bessere Namen/Status. Herkunft dunkler Geometrie separat nativ pruefen. |
| Hilfe | `campaign_tutorial_presenter.gd:_layout()` setzt festen Ursprung (260,8). | Screenshot zeigt Ueberlagerung; zustands-/aufloesungsabhaengige Kollisionspruefung fehlt als Nutzerabnahme. |
| Planmodus | `_issue_command()`, `_on_go_phase_pressed()` und Inputguard vorhanden; bestaetigte Planvorschau im Mehrtruppvertrag. | Expliziter unmittelbarer RMB-Modus ist neue Bedienregel; vorhandene Befehlskette behalten. |
| Inventar | Operationspresenter hat Ausruestungspalette/Drag-Slots; Supply-State fuehrt item_quantities, Credits, Fuel/Angebote. Kein gemeinsamer Basis/Fracht/Rucksack-Transferowner dort. | Echte Container-/Transaktionsfunktion benoetigt; kosmetische Dropdownrevision reicht nicht. Vor Implementierung restliche Owner gezielt auf Wiederverwendung pruefen. |
| Navigation | Operationsvertrag verlangt bisher FOB sichtbar gesperrt und Smart Mobile zwischen Trupp und Karte. | Aktueller Nutzerwunsch ersetzt Reihenfolge/Sichtbarkeit. |
| Sternkarte | `StarMapCanvas`: orbit_requested, schematische Koerper, Schiff als Polygon; Orte in rechter Ansicht. | Eigene Ortsmarker und Modellprojektion ergaenzen, Zoomtransform behalten. |
| Alte Designtexte | DESIGN_NOTES enthaelt alte Grafik-nur-Mittel/Commander-Grundsaetze; GDD_STATUS stuft DOCX als historische Inspiration ein. | Neuere explizite Grafik-/Basis-/Orbitwuensche sind massgeblich. Commander/Echtzeit und Ownergrenzen bleiben. |

## Referenzpaket

Dateien: `docs/reports/assets/playtest-2026-11-10/`, Originale bleiben erhalten.
`manifest.json` enthaelt Quellpfade, SHA-256 und Status. Keine neue Bilderzeugung.

| Datei | Status / Verwendung |
|---|---|
| [inventory_drag.png](../reports/assets/playtest-2026-11-10/inventory_drag.png) | KI-Konzept 21.09., Ida, Transferpfeil: Containeranordnung und direktes Verschieben. |
| [inventory_grid.png](../reports/assets/playtest-2026-11-10/inventory_grid.png) | KI-Konzept 21.09.: groesseres Rucksackraster und lesbare Ausruestungsslots. |
| [star_map.png](../reports/assets/playtest-2026-11-10/star_map.png), [star_map_variant.png](../reports/assets/playtest-2026-11-10/star_map_variant.png) | KI-Konzepte 21.09., Asche-System: Orte, Route, Auswahl und Ortsvorschau. |
| [homebase.png](../reports/assets/playtest-2026-11-10/homebase.png) | KI-Konzept 21.09., Rostgrenze: kompakter wohnlicher Kern, Landepad, Raumaufteilung und Erweiterungsflaechen. |
| [trade_outpost.png](../reports/assets/playtest-2026-11-10/trade_outpost.png) | KI-Konzept 21.09., Freihafen: zusammenhaengendes Gelaende, Hallen/Hof/Strassen/Details. Keine Pflicht, alles sofort zu bauen. |
| [playtest_satellite.png](../reports/assets/playtest-2026-11-10/playtest_satellite.png) | Nutzerscreenshot 10.11.: aktueller visueller Befund, Buildrevision unbekannt. |

Ergaenzend vorhandene Novemberziele unter `docs/reports/assets/ui-2026-11-01/`:
`mockup_a5_mission_zweireihig.png`, `board_charakterkarten.png`,
`menu_fob_loadout.png`, `board_detailkarten.png`. Ida-Inventar bestimmt
Container-/Slotbedienung; Novemberbilder ergaenzen Gesichter, Trupp und A5-HUD.
Nicht die Personenidentitaeten, Waffen, Lore, Mengen oder Beispielwerte mischen.

## Umfang / Nicht-Ziele

Jetzt geliefert: Planungsdokumente, Bildzuordnung, Code-/Designabgleich.
Umsetzungsziel ist die unten verlinkte Paketfolge. Kein Gameplaypatch, Export,
Release, Mainmerge oder neue Multiplayerfreigabe in diesem Planungsauftrag.
Basisbausystem, vollstaendige Wirtschaft, Raumkampf, neue Grossschiffe und
unbegrenztes World-Streaming sind keine impliziten Teilauftraege.

## Akzeptanzkriterien fuer die spaetere Gesamtabnahme

- Normaler Kampagnenstart -> frei landen -> beide Personen aussteigen -> Satellit
  sichern -> echte Crew wieder einsteigen -> Rueckorbit -> Heimlandung -> zweiter
  Ausflug ohne neue Test-/Debugbuttons und ohne verlorene Personen/Gegenstaende.
- Planmodus an/aus eindeutig; sofortiger RMB setzt genau einen gueltigen
  Truppbefehl ab, UI-/Schiffs-/LZ-Klicks erzeugen keine unbeabsichtigte Bewegung.
- Drei grosse, landschaftlich passende Ortskarten; Basisstartzoom, Wege,
  Erweiterungsflaechen und erreichbare freie Landezonen nativ sichtbar.
- Inventartransfers erhalten Gesamtmengen, IDs und Kapazitaeten; abgelehnte und
  wiederholte Requests erzeugen keine Duplikate oder verlorene Gegenstaende.
- Zwei Trupps mit zwei echten Schiffen an verschiedenen Orten: Wechsel, Bewegung,
  unabhaengige Rueckkehr und zeitlicher Fortschritt ohne Reset des anderen Ortes.
  Keine zusaetzlichen Start-NPCs ungefragt in die Zwei-Personen-Kampagne aufnehmen.
- Native Pruefung bei 3440x1440, 1920x1080, 1280x720: keine verdeckten Aktionen,
  lesbare Schrift, Referenzvergleich im echten Spielabstand. Stilabnahme separat.
- Jede Performanceaenderung mit Verifier/Profilbeleg; keine gleichzeitigen
  Vollrebuilds oder dauerhaft rendernden Viewports fuer alle versteckten Orte.

## Betroffene Dateien / lokale Pruefung / Risiken

Konkrete Dateien und Pruefwege je Paket im
[Arbeitsplan](../superpowers/plans/2026-11-10-campaign-world-inventory.md).
Relevante Vertraege: PROJECT_BRIEF, ARCHITECTURE, GDD_STATUS,
homebase_operations_ux, homebase_map_services, singleplayer_locations_jobs,
orbit_quantum_travel, dropship_lz_target_accuracy, homebase_direct_dropship_flow,
multi_fireteam_plan, graphics_reference_revision (jeweils unter docs/dev ausser
den Rootdokumenten). Historische QA: campaign_intro_20261109,
orbit_base_combined_20261110 und orbit_quantum_20261109.

Groesste Risiken: Karte vergroessern ohne bezahlbare Navigation; freie LZ ohne
dynamischen Rueckkehranker; Inventar nur als UI-Kopie; mehrere Orte bei weiterhin
globalem Reise-/Missionsowner. Diese Punkte bestimmen die Reihenfolge.
