# Runde 3: Framehitches und sichtbare Naehe zu den 2D-Vorlagen

## Ziel / Problem
Der Nutzer beauftragt die naechste autonome Runde: restliche Ruckelspitzen
abbauen und Kamera, Szenendichte, Missions-UI und Heimatbasis deutlich naeher
an die Original-2D-Ziele bringen. Echte Vollbildpruefung und anschliessende
Mainintegration mit Push sind beauftragt; keine Zwischenfreigaben.

## Basis und bestaetigter Ausgangspunkt
Main `173a1e3c33b733a78a396a93db9cedf631d84998`, neuer Branch
`task/reference-polish-r3-20261106`. Getrackter Ausgangsbaum ist sauber;
fremde ungetrackte Arbeit und alte Rohbelege bleiben erhalten.
Die letzte normale 90-s-Serie zeigt noch HUD-Aufrufe bis79.633ms und
Framezeiten bis145.424ms. Die alte Messreihe ist Ausgangshinweis, kein Ersatz
fuer den neuen, frisch gepinnten Vorlauf.

## Ansatz und Gestaltung
- Ein reiner Kamerapass macht Figuren groesser, laesst aber leere Ensembles
  und die gleichfoermige Homebase-Hierarchie bestehen.
- Gewaehlt ist eine Kombination aus messbar weniger wiederholter UI-/Fog-
  Arbeit, einer naeheren Missionskamera, gezielter visueller Verdichtung an
  vorhandenen Funktionsensembles und einer neu gewichteten Homebase-Ansicht.
  Bestehende Modelle, native Controls und Owners werden weiterverwendet.
- Eine breite neue Modellserie ist fuer diesen Schritt nicht erforderlich.
  Neue Meshrevisionen waeren separat mit Quelle/Export/Import zu pruefen.

Der technische und gestalterische Weg ist eine Agentenentscheidung innerhalb
des ausdruecklichen Durcharbeitsauftrags, keine behauptete Nutzerabnahme.

## Referenzen und konkrete Zielunterschiede
- `docs/reports/assets/ui-2026-11-01/mockup_a5_mission_zweireihig.png`:
  lokale Spielsituation fuellt den Bildraum; Figuren, Gebaeude und Wege sind
  auf Spielabstand lesbar; linke Portraitteams und zwei Befehlsreihen.
- `menu_heimatbasis.png` und `menu_fob_loadout.png` im selben Ordner:
  klare Reihenfolge Personal -> Trupp/Fokus -> Einsatz/Abflug, weniger
  gleichgewichtige leere Paneele und eine sichtbare Schiff-/Basisszene.
- Spaetere Nutzerkorrekturen bleiben: begehbare Heimatbasis, kein erzwungener
  FOB-Umweg, Teamparameter links und tatsaechliche Ref03-Cutlass-Identitaet.
  Beispielnamen, Kapazitaeten und gemalte Schiffsfakten sind keine Runtimewerte.
- Originale, heutige native Vorherbilder, Zwischenstaende und final integrierte
  Variante erhalten getrennte Pfade, Pins und Bewertungen. Kein HTMLreport.

## Umfang / Nicht-Ziele
- Performance erst nach Kausalbefund: verbleibende redundante Style-/Label-/
  Layout-/Kartenarbeit und Fog-Slices pruefen. Keine Senkung von Qualitaet,
  Sichtweite, Unitanzahl, normaler 1x-Rate oder Gameplayworkload als Optimierung.
- Naehere normale Missionskamera mit erreichbarem Zoom/Pan und ohne
  wiederholtes Ueberschreiben manueller Kamerawahl. Editor und Basis behalten
  ihre eigenen Kamerarollen. Messkamera und Produktkamera werden getrennt.
- Szenendichte nutzt echte vorhandene Modelle und deterministische rein
  visuelle Ensembles. Keine neuen Gameplayhindernisse, Nav-/LOS-/Coverfakten,
  Gegnerinformationen, Interaktionen oder Map-/Save-Migrationen.
- UI/Core-Loop bleiben bedienbar; bestehende IDs, Auswahl, Loadout, Pilot,
  Kapazitaet, Boarding, Transit, Pending/Reject, GO und Detailcallbacks erhalten.
- Keine neue Simulation/Parallelwahrheit, kein Architektur-Neubau und kein
  Wechsel der aktiven Portrait- oder Schiffsidentitaeten.
- Kein EXE-/WAN-/Releaseversprechen. Alte QA-Pakete bleiben unveraendert.

## Dokumente und Contracts
AGENTS, PROJECT_BRIEF, ARCHITECTURE, CODEX_RULES, IMPLEMENTATION_STATUS,
TASK_ROADMAP, graphics_reference_revision_contract, ui_native_design_contract,
mission_hud_projection_authority_contract, mission_command_feedback_contract,
runtime_script_layout_contract, gm01_frontier_map_contract und die vorherige
HUD_ARCHITECTURE-Runde samt Referenzreview und QA.

## Akzeptanz und Prueffolge
1. Frische Schutzpins fuer fremde Dateien und bestehende Roster; neue isolierte
   Profile/Overlays. Root ist einziger serieller Engine-/Git-Runner.
2. Frischer nativer Vorlauf mit aktueller echter Bildschirmaufloesung,
   Vollbild, Vulkan/Forward+, Kamera34, normaler1x-Route, gleicher Einheitenauswahl
   und passenden Zaehlern. Historische Werte werden nicht neu beschriftet.
3. Performancefixes fokussiert gegen Fehler bzw. wiederholte Arbeit absichern;
   native Gegenmessung noch vor den Szenen-/Kameraumbauten. CPU/GPU und
   verschachtelte Teilzeiten sauber trennen; GPUtimer ggf. nicht verfuegbar.
4. Danach Kamera-/Ensemble-/UI-Pass nativ in vergleichbaren Bildern pruefen.
   Produktkamera und volle neue Szene werden normal gespielt. Eine zusaetzliche
   feste Messkamera34 trennt Zoomaenderung von Performanceaussagen.
5. Deterministische Dekoration, FoW-Freigabe, Sicht-/Weg-/Pickingfakten,
   manuelle Kamera, Missionswechsel, Homebase-Auswahl/Loadout/Boarding/Transit,
   Details und Commandfeedback durch passende Komponenten-/Nachbargates sichern.
6. Homebase/Missions-UI bei3440x1440 sowie schmaleren logischen Vollbildgroessen
   auf vollstaendige Rects, Clipping, lange Namen und erreichbare Controls pruefen.
7. Echte PNGs oeffnen, Unterschiede zur eigenen Originalvorlage konkret
   bewerten; technische Freigabe und gestalterische Nutzerabnahme unterscheiden.
8. Unabhaengiges Nachreview, finale Quellbindung, Main-Fast-forward, frischer
   Main-Vollbildtest und normaler Push mit Remoteabgleich. Geschuetzte Dateien,
   Spieler-Roster und alte Belege bleiben nach Bytes/Groesse/mtime unveraendert.

## Besitz / betroffene Dateien
Root koordiniert Controller, TerrainMap3DView, Missionskamera, Runner,
gemeinsame Themerouten und alle Engine-/Git-Schritte. Eng begrenzte Hunk-
Freigaben werden den Agenten einzeln erteilt. Separate lesende Arbeitsbereiche:
Performance, Homebase und Welt-/Kamerakomposition. Untertasks fuehren konkrete
Dateien, Design, RED/GREEN und Risiken vor ihrer Produktimplementierung auf.

## Risiken / offene Punkte
Mehr visuelle Dichte kann Renderer-/Streamingarbeit erhoehen und darf weder
Wege verdecken noch FoW umgehen. Eine naehere Kamera verkleinert die Uebersicht;
Zoom/Pan und Zielorientierung bleiben erforderlich. UI-Guards muessen Reveal,
Auswahl und sofortiges Feedback korrekt invalidieren. Layoutgewichtung bei
Ultrawide darf kleine Vollbildansichten nicht zerlegen. Die letzte Runde liess
mehrere 50-100ms-HUD-/Fogkosten offen; nur gemessene Korrekturen werden als
Performancegewinn ausgegeben.

## Gepruefter Abschlussstand, 2026-11-07
Implementierung und Bildvergleich abgeschlossen; Bericht und eingefrorene
Quellbindung unter `docs/qa/reference_polish_r3_20261106/`.
40 verschiedene zuletzt gruene Gates, gezielter Homebase-Nachlauf nach dem
erhaltenen echten39/40-Portraitbefund. CPU-Welt45/45, native GPU56/56;
normale native90-s-Routen mit Produktkamera22 und Vergleichskamera34 je68/68.
Kamera34: P99=70.357ms und9Frames>100ms gegen128-135ms und75-77vorher.
Kamera22: P99=72.958ms und15Frames>100ms. Einzelne177ms-Spitzen bleiben;
eine allgemeine Ruckelfreiheit oder vollstaendige2D-Nutzerabnahme wird nicht
behauptet. Main-/Remote-/Smoke-Beleg folgt in der getrennten `main_receipt.json`.
