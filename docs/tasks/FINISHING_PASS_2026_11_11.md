# Abschlussarbeit: Hoehenlesbarkeit und verbleibender Arbeitsplan

## Ziel und Ursache
Der Nutzer will selbststaendig Fortschritt bis zum Abschluss, mit moeglichst
wenigen Tests jetzt. Karten und Hoehen bleiben ausdruecklich im Umfang.
Zielsystem/Sicht/Wuerfelmodell werden im Chat Tabletop-Faktoren fuer Performance
pruefen diskutiert: dort bisher Diagnose/Entwurf, kein Produktumbau.

## Umfang / Nicht-Ziele
1. Rampen und Hoehen optisch klarer, weniger verwaschen darstellen.
   Gleiche geschlossene Flaechen und Gameplayhoehen; keine neue Kollision,
   Wegsuche, Deckung oder Sichtregel. A/B/C512x256, Sternkarte256x256.
2. Verbleibenden Arbeitsplan mit erledigt/offen/andererChat/zurueckgestellt
   zusammenfuehren. Bedienung, Inventar und Kampagnenfortsetzung sichtbar halten.
3. Kleine eigenstaendige Bedienverbesserungen nach Bestand, ohne das
   Zielsystem oder dessen geplante neue Werte-/Bewegungsregeln vorwegzunehmen.
Keine Fahrzeuge (weiter zurueckgestellt), kein Main/EXE oder grosse Testsuite.

## Vertraege und Quellen
PROJECT_BRIEF, ARCHITECTURE, CODEX_RULES, graphics_reference_revision_contract,
terrain_truth_visual_audit_contract, MAP_WORLD_REBUILD_2026_11_10.
Native C_surface_final_18.png und aktuelle geschlossene Rampengeometrie sind
die Ist-Referenz. Bestehende Glut-Landschaftsvorlagen bleiben die Stilreferenz.

## Schritte / Dateien / Akzeptanz
- [ ] Vorheraufnahme der aktuellen Karte, identische Nahkamera danach.
- [ ] Terrainprojektion: vorhandene Flaechennormalen bewahren und uebermaessige
  Normalenglaettung verringern; Rampenmaterial ruhig und unterscheidbar halten.
  Dateien terrain_map_3d_view.gd, frontier_ground.gdshader.
- [ ] Uebersicht docs/tasks/ACTIVE_WORKPLAN_2026_11_11.md mit konkreten Restpunkten.
- [ ] Kleine Anzeige-/Bedienverbesserung nur auf vorhandenen Ownern.
- [ ] Gitdiff/Pfade und enges Kompilieren; keine Gefechts-/Performance-/Matrixlaeufe.

## Spaetere Pruefung / Risiken
Verschoben: voller A/B/C-Bildvergleich, Gefecht, Sicht/Ziel/Bewegung nach dem
anderen Chat, grosse UI-/Regressionstests. Native kleine Bildkontrolle jetzt
ist Formarbeit, kein Gameplay-/FPS-PASS. Zu starke Facettierung vermeiden;
Rampen duerfen optisch nicht wie gesperrte Klippen wirken.

## Bestaetigte Erweiterung
Der Nutzer hat danach explizite Plateau-/Rampenregeln und breite Baender mit
Ecken sowie vollstaendiges Editor-Mitziehen beauftragt. Die vorherige reine
Materialabgrenzung ist dafuer ueberholt. Siehe explicit_hex_ramps_contract.
