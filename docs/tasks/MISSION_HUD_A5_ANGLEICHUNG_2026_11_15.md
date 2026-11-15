# P7: Missionsansicht an Entwurf A5 angleichen (15.11.2026)

> Fuer Hilfsagenten: Dieser Plan wird abgearbeitet, nicht ausgearbeitet. Alle Zahlen und Orte stehen hier.
> Wo eine Regel "wenn ... dann ..." steht, gilt genau diese Regel. Alles andere: anhalten und melden.
> Schritte mit Kaestchen (`- [ ]`) der Reihe nach, nach jedem Abschnitt ein Commit.

## Ziel
Die Missionsansicht bei 1920 x 1080 sieht aus wie `docs/reports/assets/ui-2026-11-01/mockup_a5_mission_zweireihig.png`:
schmale Teamkarten mit hohen Portraits links, die Parameter des gewaehlten Trupps (Haltung, Feuerregel) im
Befehlsband unten, kleine Dropship-Karte oben rechts, flache Zielkarte, kleines Protokoll.

## Ursache
Messung in `docs/tasks/UI_DICHTE_BESTANDSAUFNAHME_2026_11_15.md`, Abschnitt 2.1: Aktionstasten und Band passen schon.
Zu gross sind Dropship-Karte (384 x 312 statt ca. 280 x 134), Karte des gewaehlten Trupps (336 x 238 statt ca. 311 x 147,
Portraits 58 x 58 statt ca. 63 x 90), Zielkarte (400 x 96 statt ca. 442 x 64) und Protokoll (384 x 144 statt ca. 312 x 118).
Die Truppkarte ist so hoch, weil Haltung, Feuerregel und Aufsitzen in ihr stecken; in A5 liegen sie im Band.

## Umfang
Nur Darstellung. Dieselben Control-Knoten, dieselben Signale, dieselben Texte. Kein Knoten wird umbenannt,
umgehaengt oder geloescht; es aendern sich Rechtecke, Mindestgroessen, Schriftgroessen einzelner Knoepfe und ein Streckmodus.

## Nicht-Ziele
- Keine Aenderung an `body_font_size` und `heading_font_size` (bleiben 14/16/18 und 20/23/26; mehrere Tests haben Untergrenzen).
- Keine Aenderung an Aktionstasten (`action_edge`, `action_gap`), `top_nav`, `target_order`, FOB- und Heimatbasis-Rastern.
- Keine Textaenderung (auch nicht "Landezone waehlen"), kein neuer Knopf, kein Dropdown fuer den Auftrag.
- Details-Fenster (Team und Dropship) bleiben wie sie sind, einschliesslich `MissionDropshipApproachStyleRow`.
- Kein Eingriff in Regeln, Befehle, Simulation.

## Relevante Dokumente
- `docs/tasks/UI_DICHTE_BESTANDSAUFNAHME_2026_11_15.md` (Messwerte, Testliste)
- Zielbild: `docs/reports/assets/ui-2026-11-01/mockup_a5_mission_zweireihig.png`
- Ist-Bilder vorher: `docs/qa/ui_dichte_20261115/02_mission_hud_trupp_abgesetzt.jpg`, `02b_mission_hud_landezone_gesetzt.jpg`

## Betroffene Dateien
- `scripts/meta/drop_light_layout_contract.gd` (nur `get_mission_hud_layout`)
- `scripts/ui/mission_a5_hud_layout.gd`
- `scripts/ui/mission_a5_dropship_presenter.gd`
- `scripts/ui/components/approach_dial.gd`
- `scripts/tests/mission_tactical_sandbox_controller.gd` (genau eine Zeile, Schritt 3.3; geteilte Datei, in der Abstimmungsnotiz belegt)
- `scripts/ui/tactical_event_log_panel.gd` (nur falls Schritt 5 es verlangt)
- neu: `scripts/tests/mission_a5_dichte_capture.gd`, `scripts/tests/mission_a5_dichte_verifier.gd`
- Tests nur nach der Regel in "Erlaubte Testanpassungen"
- `docs/qa/mission_a5_20261115/` (Bilder), `docs/IMPLEMENTATION_STATUS.md` (eine Zeile), dieser Bericht (Abschnitt "Ergebnis")

## Arbeitsumgebung
- Arbeitsordner: `/home/claude/work/wt_p7`, Branch `task/claude-p7-mission-a5-20261115`. Nur dort arbeiten.
- Godot immer ueber den Sperr-Starter (es laeuft nur ein Godot zur Zeit, andere Agenten teilen sich die Maschine):
  `/home/claude/work/g.sh /home/claude/work/wt_p7 <sekunden> <godot-argumente>`
  - Test: `/home/claude/work/g.sh /home/claude/work/wt_p7 300 --headless --script res://scripts/tests/<name>.gd`
  - Bildaufnahme (braucht Fenster, deshalb ohne `--headless`): `/home/claude/work/g.sh /home/claude/work/wt_p7 300 --script res://scripts/tests/<name>.gd`
- Testlauf ueber eine Liste: `/home/claude/work/run_tests.sh /home/claude/work/wt_p7 /home/claude/work/tests_p7.txt /home/claude/work/p7_nachher.tsv`
- Ausgangslage aller Tests der Liste vor der Aenderung: `/home/claude/work/p7_vorher.tsv` (wird vom Hauptchat erzeugt; Spalten: Test, Exit-Code, letzte Ergebniszeile). Wenn die Datei beim Erreichen von Schritt 6 fehlt: warten und alle 2 Minuten nachsehen, hoechstens 40 Minuten, dann melden.
- Commits: `git -c user.name="Claude" -c user.email="noreply@anthropic.com" commit`, Nachricht deutsch, ohne Umlaute. Nicht pushen.
- Untracked `.import`-Dateien nicht committen.

## Zielwerte

### A. Tabelle `get_mission_hud_layout` (klein = Hoehe < 900, mittel = ab 900, gross = ab 1260)

| Wert | klein | mittel | gross | bisher |
|---|---|---|---|---|
| `inset` (`action_inset`) | 8 | 8 | 12 | 8 / 12 / 16 |
| `band_height` (Formel bleibt `2 * action + 3 * inset`) | 128 | 152 | 180 | 128 / 164 / 192 |
| `card_width` | 280 | 312 | 376 | 300 / 336 / 400 |
| `portrait_height` | 80 | 88 | 96 | 53 / 58 / 64 |
| `team_height` | 128 | 136 | 144 | 226 / 238 / 254 |
| `transport_width` | 304 | 320 | 376 | 344 / 384 / 440 |
| `objective_width` | 392 | 440 | 504 | 344 / 400 / 456 |
| Hoehe `mission_identity` | 56 | 64 | 72 | 88 / 96 / 112 |
| Hoehe `event_log` | 104 | 120 | 152 | 144 / 144 / 176 |
| Hoehe `mission_control` | 160 | 176 | 200 | 224 / 248 / 280 |

`team_height` ist immer `portrait_height + 48`. Alle anderen Formeln (`team_top`, `mini_height`, `command_width`,
Positionen) bleiben wie sie sind. `event_log` behaelt Breite `transport_width` und die Lage 12 ueber dem Band.

Neuer Schluessel im Rueckgabe-Dictionary:

```gdscript
"team_parameters": Rect2i(command_width + gap + target_width + gap, band_top, 528, band_height),
```

`target_width` ist die vorhandene Breite von `target_order` (272 / 320 / 344); dafuer eine lokale Variable einfuehren und in `target_order` wiederverwenden.

### B. Karte des gewaehlten Trupps und Band-Modul (`mission_a5_hud_layout.gd`)

`T` = `layout.selected_fireteam`, `P` = `layout.team_parameters`, `i` = `layout.action_inset`, `ph` = `layout.portrait_height`.

| Knoten | neues Rechteck | bisher |
|---|---|---|
| `A5TeamIdentity` | `T.pos + (10, 8)`, Groesse `(T.w - 164, 26)` | Hoehe 30 |
| `A5DetailsButton` | unveraendert `T.pos + (T.w - 144, 8)`, 76 x 24 | |
| `AllFireteamsButton` | unveraendert `T.pos + (T.w - 64, 8)`, 52 x 24 | |
| `A5TeamPortraits` | `T.pos + (10, 36)`, Groesse `(T.w - 20, ph)` | y 34 |
| `A5TeamSummary` | `P.pos + (8, i)`, Groesse `(336, 24)` | in der Karte |
| `TacticalStancePanel` | `P.pos + (8, i + 30)`, Groesse `(336, 48)` | in der Karte |
| `A5FireRuleHeading` | `P.pos + (8, i + 82)`, Groesse `(88, 28)` | in der Karte |
| `A5FireRuleSelector` | `P.pos + (100, i + 82)`, Groesse `(244, 28)` | in der Karte |
| `A5TeamBoard` | `P.pos + (360, i + 30)`, Groesse `(104, 28)` | in der Karte |
| `A5BoardStatus` | `P.pos + (360, i + 66)`, Groesse `(160, 36)` | in der Karte |

- Die versteckten Original-Feuerregel-Knoepfe (`RULES`), `info_scroll`, Kontextknoepfe und `_context_tool_rect` bleiben unveraendert.
- `team.set_meta("native_a5_parameter_group_left", true)` bleibt. Zusaetzlich `team.set_meta("native_a5_parameter_group_band", true)`.
- Portraits in `_refresh_combined_team_card`: `custom_minimum_size = Vector2(minf(kante, ph), ph)` mit
  `kante = floorf((card_width - 20.0 - 4.0 * (anzahl - 1)) / maxf(1.0, anzahl))`; `stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED`.

### C. Zielkarte (`_layout_player_readouts`)
- Koerpertext-Rechteck: Hoehe `rect.size.y - (font_size + 18) - 4` statt `rect.size.y - font_size - 26`.
- `max_lines_visible` fuer Ueberschrift und Text: 1 wenn `rect.size.y < 80`, sonst 2. `tooltip_text` des Textes = voller Text; dafuer `mouse_filter = MOUSE_FILTER_PASS` am Text-Label.
- Symbol: `rect.position + Vector2(10, (rect.size.y - 30) / 2)`, Groesse 26 x 30.

### D. Dropship-Karte (`mission_a5_dropship_presenter.gd`), Stufen nach `body_font_size` (klein < 16, mittel 16 bis 17, gross ab 18)

| Teil | klein | mittel | gross | bisher |
|---|---|---|---|---|
| Innenrand der Karte (`Vector4`) | 8, 6, 8, 6 | gleich | gleich | 12, 10, 12, 10 |
| Schiffsbild Mindestgroesse | 84 x 48 | 96 x 56 | 112 x 64 | 0,38 x Breite, 80 / 96 / 112 hoch |
| Titel Schrift | `body + 2` | | | `body + 6` |
| Titel und Status | Titel bleibt zweizeilig (`AUTOWRAP_WORD_SMART`, `max_lines_visible = 2`, `_set_readout_minimum_height(title, text_width)`); Status eine Zeile (`max_lines_visible = 1`, `AUTOWRAP_OFF`, `clip_text = true`, `_set_readout_minimum_height(status, 100000.0)`), Tooltip = Text | | | zwei Zeilen |
| Status Schrift | `maxi(14, body - 1)` | | | `body` |
| "Details" Mindestgroesse | 64 x 26 | 68 x 28 | 76 x 32 | 68 x 32 / 68 x 32 / 68 x 40 |
| Aktionsknoepfe Mindesthoehe (in `_apply_readable_geometry` und `_style_primary_action`) | 28 | 32 | 40 | 40 / 44 / 48 |
| Aktionsknoepfe Schrift (beide Stellen) | `maxi(13, body - 2)` | | | `body - 1` |
| Abstand in `Actions` | 4 | 4 | 4 | 8 |
| `CraftSelector` Mindesthoehe / Schrift | 28 / `body - 1` | 30 | 36 | 34 / 34 / 40, `body` |
| Rueckmeldezeile | Schrift `maxi(13, body - 2)`, `max_lines_visible = 1`, Tooltip = Text | | | `body - 1`, 2 Zeilen |
| Label "Anflugrichtung" | Schrift `body - 1`, `size_flags_horizontal = SIZE_EXPAND_FILL`, vertikal mittig | | | Standard |

Der Schluessel in `_apply_readable_geometry` (`native_a5_readable_metrics`) bekommt den Zusatz `":p7"`, damit die neuen Werte einmal greifen.

### E. Anflugrad (`approach_dial.gd`)
- `custom_minimum_size = Vector2(96, 56)` (bisher 112 x 80)
- Knoepfe 42 x 24 an `(0, 0)`, `(54, 0)`, `(0, 32)`, `(54, 32)` (bisher 48 x 32 an 0/64, 0/48); Schrift 13 per `add_theme_font_size_override`.
- `_draw`: Kreis um `(48, 28)` mit Radius 11; Zeiger von `(48, 28)` nach `(40 oder 56, 20 oder 36)`.

## Erlaubte Testanpassungen
Ein Test, der in `p7_vorher.tsv` bestanden hat und danach fehlschlaegt, darf NUR in diesen drei Faellen angepasst werden:
- (a) `scripts/tests/playtest_20261105_mission_hud_groups_verifier.gd`, Zeile mit den drei Groessen: Kartenbreiten 300 / 336 / 400 werden 280 / 312 / 376.
- (b) Die Pruefung nagelt eine Zahl aus der Spalte "bisher" der Tabellen A, D oder E fest: Zahl durch den neuen Wert ersetzen.
- (c) Die Pruefung verlangt, dass `TacticalStancePanel`, `A5FireRuleSelector`, `A5FireRuleHeading`, `A5TeamBoard`, `A5BoardStatus` oder `A5TeamSummary` in der Truppkarte liegt: Erwartung auf "liegt in `team_parameters` und im Band" aendern.

Jede Anpassung im Abschnitt "Ergebnis" mit Datei, Zeile, alt, neu auffuehren. Faellt ein Test aus einem anderen Grund neu durch:
Ursache im eigenen Code suchen und beheben. Gelingt das in zwei Versuchen nicht: nicht weiter aendern, im Ergebnis melden.
Tests, die schon in `p7_vorher.tsv` fehlschlagen, nicht reparieren; nur vermerken, ob sich ihre Zahl geaendert hat.

## Schritte

### 1. Tabelle
- [ ] 1.1 In `scripts/tests/mission_a5_dichte_verifier.gd` (neu, `extends SceneTree`, Muster: `playtest_20261105_mission_hud_groups_verifier.gd`) zuerst nur die reinen Tabellenpruefungen schreiben: fuer `Vector2i(1280, 720)`, `(1920, 1080)`, `(3440, 1440)` jeden Wert der Tabelle A, `team_parameters` vorhanden, `team_parameters` liegt vollstaendig in `bottom_dock` (also auch `end.x <= viewport.x`) und schneidet `target_order` nicht, `selected_fireteam.size.y == portrait_height + 48`, `body_font_size` 14 / 16 / 18 unveraendert. Ausgabe am Ende `MISSION_A5_DICHTE: %d passed, %d failed`, Exit-Code 1 bei Fehlern.
- [ ] 1.2 Test laufen lassen: muss fehlschlagen.
- [ ] 1.3 `get_mission_hud_layout` nach Tabelle A aendern.
- [ ] 1.4 Test laufen lassen: besteht. Commit "Missionsansicht A5: Layout-Tabelle auf A5-Masse".

### 2. Truppkarte und Band-Modul
- [ ] 2.1 `_layout_selected_team_controls` und die Stelle in `configure()`, die `TacticalStancePanel` platziert, nach Tabelle B umstellen. `_refresh_combined_team_card` nach B (Portraits).
- [ ] 2.2 Commit "Missionsansicht A5: Truppparameter ins Befehlsband, hohe Portraits".

### 3. Zielkarte, Dropship-Karte, Anflugrad, Portraits der Stapelkarten
- [ ] 3.1 Abschnitt C umsetzen.
- [ ] 3.2 Abschnitte D und E umsetzen.
- [ ] 3.3 `scripts/tests/mission_tactical_sandbox_controller.gd`, Funktion `_apply_fireteam_mini_member_portrait_strip`: die Zeile `portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED` wird `TextureRect.STRETCH_KEEP_ASPECT_COVERED`. Sonst nichts in dieser Datei.
- [ ] 3.4 Commit "Missionsansicht A5: flache Zielkarte, kompakte Dropship-Karte, kleines Anflugrad".

### 4. Aufnahme
- [ ] 4.1 `scripts/tests/mission_a5_dichte_capture.gd` (neu, `extends SceneTree`): fuer `1920x1080` und `1280x720` `root.size` setzen, `scenes/tests/mission_reactivity_test.tscn` instanziieren und genau so aufsetzen wie `scripts/tests/compact_fireteam_card_verifier.gd` (MissionSetup: `defer_friendly_runtime_activation = false`, vier Einheiten `unit_alpha` bis `unit_delta`, Fireteams `ft1, ft1, ft2, ft3`, vor `add_child`), 24 Frames warten, `controller.call("_set_selected_fireteams", PackedStringArray(["ft1"]), false)` und `controller.call("_update_ui")`, 12 Frames warten, `root.get_texture().get_image().save_png(...)` nach `docs/qa/mission_a5_20261115/roh_<breite>x<hoehe>.png`; danach in eine Textdatei `docs/qa/mission_a5_20261115/rechtecke_<breite>x<hoehe>.txt` je Zeile `Name<TAB>get_global_rect()<TAB>visible` fuer: `TacticalUI/BottomDock`, `FireteamPanel`, `FireteamMiniPanel`, `A5TargetOrderPanel`, `MissionIdentityPanel`, `MissionDropshipPanel`, `MissionDropshipPanel/CompactCard`, `TacticalEventLogPanel`, `TacticalStancePanel`, `A5FireRuleSelector`, `A5FireRuleHeading`, `A5TeamBoard`, `A5BoardStatus`, `A5TeamSummary`, `A5TeamPortraits` (Pfade wie in `mission_a5_hud_layout.gd`). Szene freigeben, naechste Groesse.
- [ ] 4.2 Aufnehmen. Beide PNG ansehen (Read-Werkzeug). Pruefen: nichts ueberlappt, nichts ist abgeschnitten, Portraits sind gefuellt.
- [ ] 4.3 PNG nach JPG (Qualitaet 85) als `nachher_1920x1080.jpg` und `nachher_1280x720.jpg` wandeln (Python PIL), `roh_*.png` loeschen. Ein Vergleichsbild `vergleich_a5_ist_1920.jpg` bauen: oben das Mock-up auf 1920 Breite skaliert, unten `nachher_1920x1080.jpg`.

### 5. Massprufungen am lebenden HUD
- [ ] 5.1 `mission_a5_dichte_verifier.gd` erweitern (gleiche Szene und gleicher Aufbau wie in 4.1, drei Groessen, ft1 gewaehlt). Erwartungen, Toleranz 1 px:
  - `FireteamPanel.get_global_rect()` == `layout.selected_fireteam`
  - `TacticalStancePanel`, `A5FireRuleSelector`, `A5TeamBoard`, `A5BoardStatus`, `A5TeamSummary` liegen in `layout.team_parameters` und in `BottomDock`; keines schneidet `A5TargetOrderPanel`
  - `A5TeamPortraits`: jedes Kind hat Hoehe `portrait_height`
  - `TacticalEventLogPanel.get_global_rect()` == `layout.event_log`
  - `MissionIdentityPanel.get_global_rect()` == `layout.mission_identity`
  - `MissionDropshipPanel`: Breite == `transport_width`; Hoehe bei 1920 x 1080 hoechstens 220; rechter Rand <= Viewport-Breite - `edge` + 1
  - `MissionDropshipPanel` schneidet weder `TacticalEventLogPanel` noch `MissionIdentityPanel`
  - `ApproachDial.custom_minimum_size == Vector2(96, 56)`
- [ ] 5.2 Regeln, falls eine Erwartung nicht haelt:
  - Protokoll groesser als `event_log`: in `tactical_event_log_panel.gd` die `custom_minimum_size`, die das erzwingt, nur dann verkleinern, wenn `get_meta("native_a5_layout", false)` wahr ist.
  - Dropship-Karte breiter als `transport_width`: am Knopf `set_lz` `clip_text = true` und `size_flags_stretch_ratio = 1.8` setzen, Tooltip = voller Text.
  - Dropship-Karte hoeher als 220: Messwerte ins Ergebnis schreiben, nichts weiter verkleinern.
- [ ] 5.3 Test besteht. Aufnahme aus Schritt 4 wiederholen, falls 5.2 etwas geaendert hat. Commit "Missionsansicht A5: Aufnahme und Masstest".

### 6. Bestandstests
- [ ] 6.1 `run_tests.sh` mit `tests_p7.txt` nach `p7_nachher.tsv`. Mit `p7_vorher.tsv` vergleichen (`join` oder Python).
- [ ] 6.2 Abweichungen nach "Erlaubte Testanpassungen" behandeln. Geaenderte Tests einzeln erneut laufen lassen.
- [ ] 6.3 Commit "Missionsansicht A5: Tests an die neuen Masse angepasst" (nur wenn etwas angepasst wurde).

### 7. Bericht
- [ ] 7.1 In dieser Datei den Abschnitt "Ergebnis" fuellen: gemessene Rechtecke bei 1920 x 1080 (aus `rechtecke_1920x1080.txt`) gegen Zielwert, Tabelle vorher/nachher der Tests (nur Zeilen mit Unterschied plus Summen), Liste der Testanpassungen, alles was nicht ging.
- [ ] 7.2 `docs/IMPLEMENTATION_STATUS.md`: eine Zeile anhaengen "15.11.2026 Missionsansicht an A5 angeglichen (P7), siehe docs/tasks/MISSION_HUD_A5_ANGLEICHUNG_2026_11_15.md".
- [ ] 7.3 Commit "Missionsansicht A5: Bericht". Zum Schluss `git status --short | grep -v '\.import$'` muss leer sein, `git log --oneline -8` in die Antwort.

## Akzeptanzkriterien
- `mission_a5_dichte_verifier` besteht mit 0 Fehlern.
- Kein Test der Liste, der vorher bestand, faellt danach durch, ausser er wurde nach (a) bis (c) angepasst und besteht wieder.
- Bilder `nachher_1920x1080.jpg`, `nachher_1280x720.jpg`, `vergleich_a5_ist_1920.jpg` liegen in `docs/qa/mission_a5_20261115/`.
- `git diff --stat` gegen den Startpunkt zeigt in `mission_tactical_sandbox_controller.gd` genau 1 geaenderte Zeile.

## Lokale Pruefung
Schritte 1.4, 5.3, 6.1. Der Hauptchat laesst danach dieselbe Liste auf dem Windows-Rechner laufen.

## Risiken / offene Punkte
- Die Testszene `mission_reactivity_test.tscn` zeigt nicht jeden Zustand der Dropship-Karte (drei Knoepfe gleichzeitig, Auswahl bei mehreren Schiffen). Der Hauptchat prueft das im echten Spielablauf auf dem Windows-Rechner.
- Deutsche Texte: "Landezone waehlen" ist der laengste Knopf; Regel dafuer in 5.2.
- Portraits werden beschnitten (COVERED): bei vier Mitgliedern 70 x 88 aus einem quadratischen Bild.
- Die Haltungs- und Feuerregel-Bedienung wandert aus der Karte ins Band; gleiche Knoepfe, anderer Ort.

## Ergebnis
Verifier `mission_a5_dichte_verifier`: `MISSION_A5_DICHTE: 157 passed, 0 failed`.

### Gemessene Rechtecke 1920 x 1080 (docs/qa/mission_a5_20261115/rechtecke_1920x1080.txt)
```
TacticalUI/BottomDock	[P: (0.0, 928.0), S: (1920.0, 152.0)]
FireteamPanel	[P: (16.0, 780.0), S: (312.0, 136.0)]
FireteamMiniPanel	[P: (16.0, 288.0), S: (328.0, 480.0)]
A5TargetOrderPanel	[P: (376.0, 928.0), S: (320.0, 152.0)]
MissionIdentityPanel	[P: (1124.0, 16.0), S: (440.0, 64.0)]
MissionDropshipPanel	[P: (1592.0, 16.0), S: (312.0, 92.0)]
MissionDropshipPanel/CompactCard	[P: (1592.0, 16.0), S: (312.0, 92.0)]
TacticalEventLogPanel	[P: (1592.0, 792.0), S: (312.0, 120.0)]
```
Zielwerte: FireteamPanel 312 x 136, Dropship-Karte 312 breit (hoehe 92, Grenze 220), Identity 440 x 64, Protokoll 312 x 120, Band 152 hoch.

### Bestandstests (vorher -> nachher, 38 Tests)
Bestanden 9 -> 11. Zeilen mit Unterschied:
- playtest_20261105_mission_hud_groups_verifier: 225 passed / 6 failed -> 231 / 0
- ui_mission_r2_verifier: 1 failure -> 0 (Aufgabe "Band nutzt nur noetige Hoehe" besteht jetzt)
- ui_a5_native_hud_verifier: 24 -> 22 failures
- ui_a5_reference_groups_verifier: 102 passed / 10 failed -> 108 / 4
Keine neuen Fehlschlaege in vorher fehlgeschlagenen Tests (Fehlerzeilen verglichen).

### Testanpassungen
- playtest_20261105_mission_hud_groups_verifier.gd Z.17: 300/336/400 -> 280/312/376 (a); Z.92 `>= 80` -> `>= 48` (b, Schiffsbild).
- compact_fireteam_card_verifier.gd Z.34: `<=64` -> `<=96` (b, Portraithoehe gross); Z.38 Aufsitzen-Knopf: Erwartung "in Truppkarte" -> "in team_parameters und BottomDock" (c).
- ui_mission_r2_verifier.gd Z.55: Selector "in Truppkarte" -> "in team_parameters und BottomDock" (c).
- ui_a5_reference_groups_verifier.gd: unveraendert (Anweisung Hauptchat: Titel bleibt zweizeilig, Status `maxi(14, body - 1)`; Tabelle D entsprechend geaendert).

### Abweichungen vom Plan
- Zeilenabstand im Band-Modul (Nachbesserung Hauptchat): Der Haltungsrahmen hat im lebenden HUD Mindesthoehe 44 (1080) / 47 (1440), also ueberdeckte schon Hoehe 40 die Feuerregel-Zeile. Statt i+72: `TacticalStancePanel` Groesse (336, 48), `A5FireRuleHeading`/`A5FireRuleSelector` bei i+82, `A5BoardStatus` i+66. Tabelle B oben entsprechend geaendert.
- Protokoll: `task_627_host_client_fireteam_eventlog_overlap_polish` ("Event log contract rect stays on base grid", `is_rect_on_base_grid`) verlangt Rasterlage von `event_log`; mit Abstand 12 liegt y bei 796 (nicht Vielfaches von 8) und der Test, der vorher bestand, schlug fehl. Abstand ist deshalb 16 fuer klein und mittel (y 472 / 792), 12 bleibt fuer gross (y 1096).
- Auswahlfeld `CraftSelector`: Schrift `body - 1` fuer alle Stufen (Tabelle nennt sie nur in "klein").
- Die tatsaechliche Mindesthoehe einiger Knoepfe liegt 3 px ueber der Platzierung (Selector/Board 31 statt 28); innerhalb der Toleranz der Pruefungen.
- Schritt 5.2 musste nicht angewendet werden (Protokoll, Dropship-Breite, Hoehe 92 innerhalb der Grenzen).
- Testszene zeigt Dropship-Karte ohne Schiff ("Kein Dropship"): Schiffsbild und Anflugrad nicht im Bild geprueft.

### Nachtrag: Karte mit Schiff
Mit Schiff und drei gleichzeitig sichtbaren Knoepfen (Landezone waehlen, Landen, Abheben) brauchen die Knoepfe 303 px bei 296 px Innenbreite der Karte; `transport_width` ist deshalb 304 / 320 / 376 (vorher 280 / 312 / 376). `event_log` und `mission_identity` folgen ueber die vorhandenen Formeln. Gemessen (Verifier-Block mit zwei Schiffen, Karte `a5_ui_lz_1` "Entermesser", Zustand waiting):
- 1280 x 720: Karte P(960,16) S(304,184)
- 1920 x 1080: Karte P(1584,16) S(320,198) (Grenze 220)
- 3440 x 1440: Karte P(3040,24) S(376,220)
Alle drei Knoepfe sichtbar, ohne `clip_text`, rechter Rand innerhalb des Viewports, keine Ueberschneidung mit Zielkarte und Protokoll. Bilder: `mit_schiff_1920x1080.jpg`, `mit_schiff_1280x720.jpg`.
