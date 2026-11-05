# Review, Bedienkorrekturen und Gebaeudegrafikpass 2026-11-05

## Ziel / Problem
Aktuellen Main-Code auf reproduzierbare Fehler, Performance und Bedienbarkeit pruefen, belegte Befunde korrigieren, einen Grafikpass mit Original-2D-Vergleich ausfuehren und anschliessend direkt auf Main integrieren und pushen. Nutzerauftrag ausdruecklich ohne Zwischenstopps.

## Basis und Sinn
Basis origin/main 93c2e6810bf3699ea4237b8a4cdc60e2412660bb, neuer Branch task/review-graphics-20261105. Der urspruengliche Checkout bleibt mit fremden unversionierten Dateien erhalten; Arbeit im isolierten lokalen Worktree. Integration/core-foundation ist aelter als die bereits adoptierten Main-Aenderungen und wird nicht als Ruecksprung verwendet.

## Umfang / Nicht-Ziele
- Runtime: inkrementelle square8-Sichtregion gegen vollstaendiges Oracle vergleichen; konservative projizierte Bounds bei nachgewiesenem Fehler korrigieren. Performancebudget und Hexverhalten erhalten.
- Bedienung: originale EVAC-Aktion im A5-HUD erreichbar halten; den bestehenden autoritativen Abort-Payload im nativen Debrief korrekt anzeigen. Keine neue Evakuierungs-/Ergebniswahrheit.
- Grafik: bestehende geschlossene Frontier-Gebaeudehuellen an die geneigten blaugruenen Dachmassen, hellen Konstruktionskanten und grosse Eingangshierarchie der Originalvorlagen annaehern. Keine Karte, Hindernisfakten, Collider oder GLB-Schiffe aendern.
- Keine neuen Gameplay-Systeme, keine pauschale Release-/FPS-/Nutzerabnahme, kein EXE-Export erforderlich. Historische Quellen/Bilder und fremde WIP bleiben erhalten.

## Dokumente / Contracts
AGENTS.md; PROJECT_BRIEF, ARCHITECTURE, CODEX_RULES, IMPLEMENTATION_STATUS, TASK_ROADMAP; docs/dev/graphics_reference_revision_contract.md, ui_native_design_contract.md, mission_evacuation_abort_contract.md, homebase_direct_dropship_flow_contract.md, terrain_truth_visual_audit_contract.md, hex_grid_v1_contract.md. Aktuelle A5-/Review7-/Second-Sortie-Tasks.

## Akzeptanzkriterien
1. Aktuelle Fehler mit gezielten Tests vor dem Fix reproduzieren; danach identische Tests gruen plus betroffene Nachbarpruefungen.
2. Square8-Dirty-FoW gleicht nach Bewegung/Observerwechsel dem Fullscan, einschliesslich anisotroper Iso-Projektion, Rand- und Ueberlappungsfaellen. Arbeit bleibt begrenzt; Hex unveraendert.
3. Berechtigte EVAC-Aktion ist im sichtbaren HUD mit vollstaendigem Control-Rechteck erreichbar, feuert den vorhandenen Callback und behaelt Host-/Eligibility-Gates. Abbruch bleibt ausserhalb seiner gueltigen Zustaende gesperrt.
4. Autoritatives aborted/evacuation erscheint als Abbruch statt fehlender Auswertung; Payload/Progressergebnis unveraendert.
5. Grafikpass: Originalvorlage, native Vorher-/Nachherbilder bei identischer Kamera, Licht, Renderer und Aufloesung oeffnen und beurteilen. Quellen und Bildhashes dokumentieren. Bestehende Bounds/Material-/Mapgrenzen pruefen; keine konstruierten Actor-/Timer-Patches.
6. Finale Enginechecks seriell, mit isolierten Profilen, synchronem Pfadguard und unveraendertem Originalroster. Frischer Import protokollieren; bekannte Importdiagnosen gesondert behandeln.
7. Gesamt-Diff unabhaengig reviewen, status/docs aktualisieren, nur Taskdateien committen, Main ohne Force fast-forwarden und Remote-HEAD verifizieren.

## Betroffene Dateien / Besitz
Runtime-Agent: scripts/core/fog_of_war_system.gd, scripts/terrain/terrain_pathfinder.gd, neue review8_fow_projection_verifier.gd und review8_cover_path_verifier.gd; mechanisches HPA-Testoracle in gm01_hex_hpa_pruning_verifier.gd.
UX-Agent: scripts/ui/mission_a5_hud_layout.gd, scripts/meta/debrief_screen.gd, neue review8_ux_*_verifier.gd.
Grafik-Agent: scripts/terrain/frontier_closed_buildings.gd, gezielter neuer Grafikverifier.
Root: Task/Status/Reviewbericht, isolierter Test-/Captureadapter, neues Manifest und Evidence. Weitere produktive Dateien nur nach bestaetigtem Befund und expliziter Besitzzuweisung.

## Lokale Pruefung
Godot 4.6.2.stable.official.71f334935. Vorher/Rot, Nachher/Gruen und fokussierte A5/FoW/EVAC/Debrief/Materialregressionen. Native normale Menue->Homebase->GM01->LZ->Drop->Move/GO-Route, 1920x1080 und 1280x720; feste Gebaeudekameras vor/nach. Ausfuehrung ausschliesslich Root. Kein Engine-Overlap.

## Risiken / offene Punkte
Groessere konservative FoW-Bounds koennen mehr legitime Kandidaten erfordern; Budget/Timing getrennt messen, kein Genauigkeitsabbau. EVAC darf keine zweite Command-Wahrheit bilden. Prozedurale Dachrevision braucht geometrische und native Sichtpruefung. Die technische Integration ist keine gestalterische Nutzerfreigabe oder Gesamtspiel-Release.

## Ergebnis
Pruefung abgeschlossen: 39/39 gemeinsame Headless-Gates, neue Regressionen 236/236, native UI 102/102 und echter GPU-FoW-Readback 39/39. Gebaeude nativ vor/nach je30/30; normale Route bei beiden Aufloesungen vor/nach je50/50. Vier bestaetigte Fehler behoben und enger Hallenpass umgesetzt. Alle Bilder tatsaechlich geoeffnet, direkte A5-/Ist-/Kandidatenzuordnung in REVIEW8_hall_graphics.md. Unabhaengige Gesamt- und Adapterreviews APPROVED ohne wichtige offene Befunde.

Alle 1800 Sourcepins stimmen. 42 fremde Dateien und 437 vorhandene Rosterdateien sind inklusive Schreibzeit unveraendert. Benigne Mouse-Enter-Harnesswarnung und erste fehlgeschlagene Fixture-/Routingeingaben bleiben als Diagnose erhalten; keine Enginefehler in der finalen Matrix. Der einzige frische Import bestand ohne Fehler.

Bericht docs/reports/REVIEW8_2026-11-05.md und output/review_graphics_20261105/verification_summary.json. Main-Fast-forward/Push folgt im unmittelbaren Abschluss; keine Release-, EXE- oder gestalterische Nutzerabnahme.
