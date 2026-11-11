# Hex Tactical Runtime: isolierte Grundlagen V1

Stand11.11.2026, Basis97e00aba14ced147b268113085854ac67dc764c5.
Implementierte Bausteine; keine bereits aktivierte Missions-/Basisintegration.
Gesamtplan: `docs/superpowers/plans/2026-11-11-hex-sight-occupancy.md`.

## Besitz und Aktivierung

HexGroundRuntime ist zum ausschließlichen Besitz durch SimulationRoot bestimmt.
Dessen Command-/Bewegungspfade sind noch nicht angeschlossen. Die Helper
mutieren keine Actortransforms oder Terrain-/Unitobjekte. ContactTracker
bleibt Kontaktwissen; keine neue UI-/Registryautorität.

## Ground-State

`configure(registry, map_id, tick)` leert den vorherigen Kontext. Nur eine
gültige Hex-Registry, nichtleere Map-ID und nichtnegative Ticks konfigurieren
den neuen Kontext. `admit_units(placements)` nimmt eine ganze Gruppe oder
niemanden auf. Bestehende IDs, gleiche Zellen und ungültige Felder weisen
ohne Teilmutation zurück. Leere Gruppen und wiederholtes Entfernen sind No-ops.

Placement: `unit_id: String`, `grid: Vector2i`, optional `facing_dir: int`
von0bis5 und `posture_key: String` (Defaults0/standing; keine Balancetabelle).
ID-/Zellindizes gehören demselben Zustand. `read_unit` und
`build_planning_snapshot` liefern unabhängige Payloads. Standhöhe und Terrain-
revision werden frisch gelesen, ohne logische Zelle oder Unitrevision zu ändern.
`stand_height_steps2` misst halbe logische Höhenstufen, keine Renderweltmetrik.
Die reale Rampenstandhöhe2,5 wird als5 erhalten.

## Reine Sicht

`HexVisibilityQuery.classify_candidate` prüft Hex-Registry, vorhandene Zellen,
Eingaben, Hexreichweite und Blickkegel vor Terrainarbeit. `evaluate` verwendet
danach den vorhandenen `LineOfSightSystem.find_first_blocker_grid` mit
präzisen Endpunkthöhen. Keine zweite Terrain-/Wandalgorithmik.

Observer/Ziel: `grid`, `stand_height_steps2`; Observer zusätzlich `facing_dir`.
Profil: `range_hex: int`, optional `arc_degrees` von0bis360 (Default120).
-1 ist unbegrenzte Reichweite. Ausgabe: `in_range`, `in_arc`, `terrain_clear`,
`terrain_checked`, `visible`, `reason`, nach Terrainprüfung `blocker_grid`.
Richtungen folgen HexGrid.DIRECTIONS in der physischen Hexebene; Kegelrand
einschließlich kleiner numerischer Toleranz. Keine Kontaktbestätigung,
Schusserlaubnis, Deckungsbalance, RNG oder Schadenswirkung in diesem Helper.

## Cache

`CombatVisibilityCache.query_hex_visibility` hält reine Geometrie über
Tickgrenzen. Geordnete Zellen, effektive halbe Endpunkthöhen, Registryidentität
und Terrainrevision bilden den Key. Richtung/Reichweite werden jedes Mal
frisch gefiltert; Renderpositionen sind keine Eingabe. Ohne Revisions-API
keine dauerhafte Wiederverwendung.

Maximal16384Einträge, deterministische LRU mit verketteten Dictionaryeinträgen;
kein linearer Suchlauf pro Hit/Eviction. Neue Revisionen treffen keine alten
Keys; alte Einträge bleiben begrenzt. Kapazitätswechsel und `clear_hex_cache`
leeren auch die Hex-Auditzähler. Der alte Weltpositionscache bleibt ticklokal.
`begin_tick` leert dessen Daten, nicht die neue Hex-Geometrie. Diagnosewerte
sind keine replizierte Gameplaywahrheit.

## Erkennungsepisoden

`HexDetectionState.observe_pair(observer_id, target_id, visible, now_tick,
delay_ticks)` speichert einmal pro Episode einen Fälligkeitstick. Weitere
Beobachtungen ändern ihre ursprüngliche Dauer nicht. Echte Sichtlücke beendet
die Episode; Wiedererkennung beginnt neu. Zeitstempel sind im gesamten
Helperkontext monoton. Negative/überlaufende Zeiten und veraltete Updates
werden ohne Änderung bestehender Episoden abgelehnt. IDs bleiben strukturierte
Paare. `forget_unit` entfernt Beobachter-/Zielreferenzen; `clear` auch den
Zeitkontext. Keine Skills, Würfe oder Kontaktpublikation aus diesem Helper.

## Rampen und offene Anbindung

Gemeinsamer Rampenvertrag: längs H/H+1, seitlich H+0,5 nur bei passenden
Rampennachbarn, StandhöheH+0,5. Breiten-/Eck-/Editorregeln stammen aus dem
Terrainowner; `allows_step` bleibt für Bewegung/Reservierung das Terrain-Tor.

Noch offen: AP1-Versions-/Owneranbindung, AP3-Verbraucher, zeitliche
Reservierung und ihre Ausführung AP4/5, Lifecycle/Save/Netzwerk AP6–8.
Ein Datenindex ersetzt nicht die aktive Bewegung oder Minimum-Spacing.
Große AP9-Abnahmen bleiben später; keine gemessene FPSverbesserung.
