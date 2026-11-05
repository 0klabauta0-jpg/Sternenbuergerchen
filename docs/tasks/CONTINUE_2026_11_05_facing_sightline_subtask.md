# Teilaufgabe: Facing-, Sichtlinien- und TASK_401-Altgates, 2026-11-05

## Ziel / Problem
Die Original-Main-Gates `task_401_facing_sightline_debug_map.gd` (110/7)
und `bugfix_mission_fire_sector_overlay.gd` (22/1) werden gegen den
heutigen Missions-/Facing-Vertrag eingeordnet. Modelle, Sichtlinie und
Waffenpose sollen dieselbe aktuelle Richtung zeigen; der echte
Combat-/Schusspfad bleibt autoritativ.

## Basis / Umfang / Nicht-Ziele
Basis ist Main `01ab595a7b89632629eee0ad3523281e542148a0`, Taskbranch
`task/continue-perf-legacy-20261105`. Dies ist zuerst ein Sourceaudit;
noch kein frischer Runtime-Nachweis. Root besitzt `terrain_map_3d_view.gd`,
`mission_tactical_sandbox_controller.gd`, Engines und Git. Kein paralleler
Godot-Prozess, kein Actor-/HP-/Positions-/Timer-Patch als Spielnachweis,
keine neue Combatregel und kein Rueckbau des A5-HUDs.

## Beobachtung und eingegrenzte Ursachen
- Das erhaltene Original-Main-Log meldet eine Layerannahme, eine statische
  Nord-Sichtlinienabweichung und fuenf echte Model-vs-Orientation-Abweichungen
  waehrend Move (Frames 4, 24 und 64; zuletzt Alpha schon wieder passend).
- TASK_401 fordert `mini_panel.z_index > event_log_panel.z_index`. Das
  spaetere A5-Layout legt Truppkarten links und Protokoll rechts an.
  Massgeblich ist dort erreichbare, nicht ueberdeckte Bedienflaeche, kein
  globales Layerverhaeltnis zwischen getrennten Rechtecken. Dieser
  Teil ist eine veraltete Testannahme; Kamera-/Kartenklickregression bleibt.
- `unit_facing_visual_contract.md` beschreibt noch explizites Facing zuerst.
  Der spaetere `fireteam_behavior_modes_contract.md` TASK_459/461/464
  verlangt FireEvent, bestaetigten/spotted Kontakt, aktive Bewegung/Ziel,
  Securityscan und statisches Facing in dieser Prioritaet.
- `_resolve_unit_aim_direction()`, `_get_unit_proxy_rotation_y()` und die
  `weapon_pose_direction`-Berechnung in `_sync_unit_proxies()` verwenden
  weitgehend die neuere Prioritaet. Dagegen verwenden
  `_resolve_live_fireteam_orientation_state()` und die Orientation-Sektion
  von `_get_dynamic_unit_overlay_signature()` explizites Facing zuerst.
  Das ist ein echter widerspruechlicher Darstellungsdatenfluss.
- `_resolve_unit_motion_or_target_direction()` behandelt jedes
  `get_target_position()` als aktive Bewegungsrichtung, auch ohne
  Move-/Engage-/Retreat-/Seek-Cover-Command. TASK_401 setzt im stehenden
  Debug-NPC absichtlich ein abweichendes Runtime-Ziel. Das Ziel ueberstimmt
  dadurch das explizite Facing fuer Modell/Aim, nicht fuer Orientation.
  Die fire-sector-Regressionsfixture erzeugt denselben Konflikt.
- `SimulationRoot._store_unit_facing_from_positions()` schreibt waehrend
  Bewegung aktuelle `facing_angle`. Securityscan liest eine andere
  vorhandene Metadatenquelle; der View muss die bestehende Prioritaet
  einheitlich anwenden, statt den Gameplay-State fuer den Test umzuschreiben.

## Relevante Dokumente
AGENTS; PROJECT_BRIEF; ARCHITECTURE; CODEX_RULES; IMPLEMENTATION_STATUS;
TASK_ROADMAP; `CONTINUE_2026_11_05_command_hitches_and_legacy.md`;
`unit_facing_visual_contract.md`; `fireteam_behavior_modes_contract.md`
(TASK_459/461/464); `fireteam_runtime_execution_path_contract.md`;
`combat_loop_authority_contract.md`; `UI_2026_11_02_a5_kartenrand.md`.

## Regression und Akzeptanz vor Implementierung
1. Eng begrenzter Verifier fuer die Richtungsprioritaet mit expliziten
   Quellen: stehendes Facing + abweichende blosse Target-Metadaten; aktiver
   Movement-Command; aktiver Securityscan; bestaetigter Kontakt; FireEvent.
   Jede Variante vergleicht Model-Hips-Forward, Proxy, Sightline und
   Orientation sowie Waffenroot am unveraenderten Socket.
2. Historischer TASK_401: A5 ersetzt nur das ueberholte globale z_index-Oracle
   durch sichtbare, nicht ueberlappende Karten-/Event-Rechtecke plus echte
   Kartenhitflaeche und funktionierenden Recenter-Klick. Der Legacyzweig
   behaelt seine Layerregel, falls die Flaechen sich ueberdecken.
3. Bewegungspruefung per `SimulationRoot.enqueue_command()`, ohne
   vorgezogene `assign_unit_command()`-Mutation. Mehrere reale Physikticks
   und Richtungswechsel; Snapshot-Diagnose protokolliert `facing_angle`,
   `security_facing_active`, `security_facing_angle`, Runtime-Target,
   Commandtyp, Proxy-Yaw, Hips-Forward, Orientation-/Aimrichtung.
4. Erst wenn RED die Grenze trennt, gemeinsame read-only
   Facingaufloesung fuer Aim/Proxy/Orientation und deren Dirtysignatur.
   Aktives Commandziel bleibt vor Security; nacktes altes Target erst
   hinter explizitem Facing. FireEvent-/Contact-Vorrang bleibt erhalten.
5. Contract-Text konsolidieren; Nachbarn TASK_344/364/371/372/403/459/461/464
   und beide urspruenglich roten Gates seriell durch Root pruefen.
6. Nativer Vollbildbeleg des echten unveraenderten Missionspfades mit
   Bewegung, Kontakt und tatsaechlichen Combat-FireEvents. Diagnose und
   physischer Spielbeleg bleiben getrennt. Marker-Vorschlag:
   `CONTINUE_FACING_PHYSICAL_SAMPLE` mit Unit-ID, Tick, Event-ID, Heading-
   Quellen und Dotprodukten; PNG-Paare vor/waehrend Feuer und nach Wende.

## Betroffene Dateien
Diese Teilaufgabe; `docs/dev/unit_facing_visual_contract.md`;
`scripts/tests/task_401_facing_sightline_debug_map.gd`;
`scripts/tests/bugfix_mission_fire_sector_overlay.gd`;
`scripts/tests/task_344_ground_mission_default_enemy_visuals.gd` (nur
Karten-Extent-Oracle). Die fokussierte Prioritaetspruefung liegt im
bestehenden Firesector-Verifier. Produktivhunks ausschliesslich koordiniert
in `scripts/terrain/terrain_map_3d_view.gd` und der freigegebenen
A5-Kartengeometrie in `scripts/tests/mission_tactical_sandbox_controller.gd`.

## Ergaenzter A5-Kartengeometrie-Befund vor Korrektur
`facing_card_minimum/20261105T143230Z-9a836196` trennt den verbleibenden
Geometriefehler von der historischen z_index-Annahme: beide Karten haben
combined/custom minimum `(336,168)`, internes Minimum `(336,157)` und
Scale `(1,1)`, behalten aber tatsaechlich 179px Hoehe. Die bottom-aligned
VBox legt ihre Positionen mit 168px + 8px Abstand fest. Deshalb ueberlappen
die Karten drei Pixel und die untere Karte endet elf Pixel ausserhalb des
480px hohen Scroll-Clips. Dessen Range `max=page=344`, Value 0 ist fuer
das gemeldete Contentminimum korrekt; wiederholtes Ensure nach Layout
hilft nicht. Look ist dabei owner-selected und `selected_scroll_seen=true`.

Der freigegebene enge Fix liegt am Ende von
`MissionTacticalSandboxController._apply_native_a5_fireteam_card()`: nur
bei Abweichung der tatsaechlichen Kartengroesse vom vorhandenen nativen
combined Minimum `reset_size()` und `queue_sort()` des Parent-Containers.
Keine willkuerliche Zusatzhoehe, keine geaenderte Portrait-/Textqualitaet,
kein Scrollreset, kein Rebuild und kein Gameplay-State.

Akzeptanz vor dem Patch: beide tatsaechlichen Kartenrechtecke behalten
getrennte Klickflaechen; die untere Karte liegt vollstaendig im Viewport und
allen Clip-Parents; Karten und Protokoll bleiben getrennt. Der bestehende
Kartenklick selektiert weiterhin Look und zentriert die Kamera, der Map-
NPC-Klick zentriert weiterhin nicht. Der Verifier prueft beide Rects und
Nonoverlap zusaetzlich zum unveraenderten Klickpfad.

## Lokale Pruefung / Risiken / offene Punkte
Originalbytes beider Verifier sind unter
`output/continue_20261105/original_tests/` erhalten. Root fuehrt alle Engines
seriell aus; der delegierte Audit-/Implementationsteil startet keine Engine.

- Die erste neu geschriebene Pruefung hatte vier unzulaessige
  Variant-Typinferenzstellen. Diese Parserrunde ist kein fachlicher RED-Beleg.
- Fachliches RED: `facing_logic_red/20261105T141316Z-41665bde`, 32/7,
  Enginefehler/Warnungen 0. Hold/Scan zeigen falschen Aim-/Proxy-Vorrang
  zugunsten nackter Targetdaten; aktiver Move und confirmed Contact zeigen
  falsche Orientation. FireEvent-Vorrang besteht bereits.
- Danach exakt drei Viewstellen korrigiert: aktiver Commandtyp fuer das
  vorgezogene Target, gemeinsame Aimquelle fuer Orientation und deren
  Dirtysignatur. Proxy-/Weapon-/Combat-/Animationscode unveraendert.
- `unit_facing_visual_contract.md` ist auf den spaeteren Quellenrang
  konsolidiert. Der 401-Layouttest prueft im A5-Zweig geometrisch getrennte,
  vollstaendig erreichbare Clickflaechen; Legacy-Layerregel bleibt erhalten.
- Neue Marker sind ausdruecklich `CONTINUE_FACING_DIAGNOSTIC_SAMPLE`.
  Synthetische Contact-/FireEventdaten werden nicht als echter Schuss verkauft.

Der frische Nachbar `task_344_ground_mission_default_enemy_visuals.gd`
meldet in `final_headless/20261105T143549Z-f6e59562` 39/1. Alle echten
Enemy-/Fire-/Facing-/Aim-/Socket-/Pose-/VFX-Pruefungen sind gruen; allein
die fruehere 48x48-Kartenannahme ist rot. `gm01_frontier_map_contract.md`
Abschnitte Dispatch/Hexflaeche verankern seit A5 ausdruecklich 96x98 echte
Zellen (9408), die aktuelle JSON bestaetigt genau diese Groesse und
`hex_axial_v1`. Nach Originalbyte-Sicherung wird ausschliesslich dieses
feste Extent-Oracle auf `(96,98)` berichtigt, keine dynamische
Selbstgleichheit und keine Enemy-/Facingregel geaendert.

Die erste Nachpruefung zeigte bei wiederholten Visualsyncs desselben Ticks
eine weitere klare Ursache: das Positionsdelta war bereits verbraucht und
der View drehte zum entfernten Endziel statt zum autoritativen aktuellen
Pfad-/Avoidance-Facing. Der Helper liest bei aktuellem Root-Bewegungscommand
nun das vorhandene `facing_angle` ohne Securityoverride. Die sichtbare
Bewegung, Modell-/Hipsrichtung und Waffenlinie stimmen danach in allen sechs
Samples ueberein; dieselben Syncs ohne Tick lassen den Proxy-Yaw stabil.
Animationen und Modellachsen sind unveraendert.

`final_headless/20261105T143549Z-f6e59562`: TASK_401 125/0, Firesector 49/0,
Orientation TASK_364 17/0 und Runtime-Combat-Cases TASK_403 48/0. TASK_344
braucht nach der beschriebenen isolierten Extent-Berichtigung nur seinen
fokussierten Nachlauf. Native Fixturebilder koennen optional mit
`--facing-capture-dir=...` aufgenommen werden: Vollbild und aktive
Displaygroesse, vorhandener Stand/Move4/Move64, PNG-/Sourcehashes und
UTF-8-JSON-Displayfacts mit ausdruecklichem `source=synthetic_fixture`.
Es werden dabei keine zusaetzlichen Actor-/Zielmutationen vorgenommen.
Nativer normaler Spiel-/Schussbeleg und Abschlussintegration bleiben beim
Root und sind durch diese Headless- oder Fixtureergebnisse nicht ersetzt.
