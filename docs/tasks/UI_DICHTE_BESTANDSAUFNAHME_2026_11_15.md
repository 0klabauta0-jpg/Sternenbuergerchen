# UI-Dichte: Bestandsaufnahme gegen Mock-up A5 (15.11.2026)

Reine Mess- und Leseauftrag. Es wurde kein Spielcode, keine Szene, kein Theme und keine Datendatei geaendert. Alle Zahlen gelten fuer 1920x1080, Stretch-Faktor 1,0 (siehe Abschnitt 3.4). Pixelwerte der "Ist"-Spalten stammen aus den lebenden Control-Knoten (globales Rect, `custom_minimum_size`, `get_theme_font_size`); Pixelwerte des Mock-ups sind aus dem Bild gemessen und auf 1920 Breite hochgerechnet (Faktor 1920/1672 = 1,148), Genauigkeit etwa +-2 px im Bild, also +-3 px bei 1920.

Bilder: `docs/qa/ui_dichte_20261115/` (JPG, Qualitaet 85, alle exakt 1920x1080). Die Rohdaten (PNG und Knoten-Tabellen je Screen) liegen ausserhalb des Repos in `/home/claude/work/p3_out/`.

## 1. Aufnahmen

| Screen | Datei | Gewonnen wie |
|---|---|---|
| Hauptmenue | `01_hauptmenue.jpg`, `01b_hauptmenue_kampagnendialog.jpg` | `main_menu.tscn` instanziiert, Maus aus dem Bild geschoben |
| Mission-HUD, Trupp abgesetzt, Einsatz laeuft | `02_mission_hud_trupp_abgesetzt.jpg` | echter Weg Menue -> Skirmish "early" -> Heimatbasis -> Start -> Landezone -> "Landen" -> Trupp abgesetzt |
| Mission-HUD, Schiff bereit, Landezone gesetzt | `02b_mission_hud_landezone_gesetzt.jpg` | derselbe Lauf, frueherer Zeitpunkt (zeigt "Landen/Abheben"-Zeile der Dropship-Karte) |
| Heimatbasis "Basis erkunden" mit Seitenleiste und Kommando-Dock | `03_heimatbasis_basis_erkunden_dock.jpg` | Kampagne neu, `request_operation("navigate", base)` |
| Trupp und Ausruestung (Lager, Inventar, Rucksack) | `04_heimatbasis_trupp_ausruestung_kampagne.jpg`, `04b_..._skirmish_4er_team.jpg` | Kampagne neu bzw. Skirmish mit 4er-Team |
| Sternkarte | `05_sternkarte.jpg` | `open_location_view("star_map")` |

Nicht aufgenommen: Smart-Mobile-Auftragsapp (Job-Board), Debrief, Lobby, Einstellungen, Escape-Menue, Editor. Grund: nicht Teil des Auftrags-Minimums; die Smart-Mobile-Navigation ist in der frischen Kampagne ausserdem deaktiviert ("Noch nicht verfuegbar").

Hinweise zur Aufnahme:
- Die Mission lief in der Software-GL-Umgebung (llvmpipe); Bild 02 zeigt die Kamera nicht auf dem Trupp (Einheiten oben links am Rand). Fuer die UI-Masse ist das ohne Belang.
- Die vorhandenen Capture-Skripte (`frontier_main_startup_verifier.gd`) drueckten den veralteten "Singleplayer"-Pfad und eine einstufige "Drop"-Logik; der Lauf musste auf Skirmish-Start, gueltige Landezone (Rastersuche ueber `_place_lz_from_screen_position`) und die zweistufige Landen-Taste umgestellt werden. Es wurde kein Spielzustand gesetzt; Eingaben waren `pressed.emit()` auf den echten Buttons und die vorhandenen Platzierungs-Handler.
- Fehlende `.import`-Dateien (356 untracked Dateien, z. B. fuer `smart_mobile_fonts`) wurden aus dem Nachbar-Worktree `wt_anschluss` temporaer kopiert, sonst scheitert der Parse von `smart_mobile_theme.gd` ("Could not resolve external class member HEADING"). Sie sind nicht committet.

## 2. Messwerte

### 2.1 Mission-HUD (Bild 02), Ist gegen Mock-up A5

Mock-up: `mockup_a5_mission_zweireihig.png`, 1672x941, Messung aus dem Bild, hochgerechnet auf 1920 (+-3 px).

| Element | Ist (1920x1080) | Mock-up A5 (auf 1920) | Abweichung |
|---|---|---|---|
| Aktionsbutton | 64x64, Teilung 72, Abstand 8, Schrift 14, Icon max. 28 | ca. 75x63, Teilung ca. 84x71, Schrift ca. 15 (aus Versalhoehe geschaetzt), Icon ca. 28 | Ist gleich gross oder kleiner als das Mock-up |
| Befehlsband Hoehe | 164 (2x64 + 3x12) | ca. 149 | Ist +15 |
| Befehlsband Anker | x=0, y=916..1080, Buttons ab x=12 | x=0, Buttons ab x=ca. 18 | gleich |
| Ziel/Auftrag-Block | 320x164, 3 Textzeilen 16 px, kein Dropdown | Dropdown ca. 272x47, Zeile "Ziel gewaehlt" | anders aufgebaut |
| Team-Karte links (ausgewaehltes Team) | 336x238 (FT1: Portraits 58x58, Haltung 3x28 px hoch, Feuerregel-Dropdown 226x31, "Aufsitzen" 104x31, Statuszeile) | ALPHA-Karte ca. 311x147, Portraits ca. 63x90, BRAVO ca. 311x175 | Ist +91 px hoeher, Portraits kleiner und quadratisch |
| Schrift Kartenkopf | 18 (Name), 15 (Zusammenfassung) | ca. 20 / ca. 15 | etwa gleich |
| Ziel-/Einsatzkarte oben | 400x96, Titel 18, Text 16, Details-Button 76x30 | ca. 442x64, Titel ca. 22, Text ca. 14 | Ist +32 px hoeher |
| Dropship-Karte oben rechts | Auswahl 384x34 + Karte 384x258 bis 274 (Bild 120x96, Titel 22 in 130 px Breite, Details 68x32, Aktionszeile 2x176x44, Anflug-Dial 4x48x32) | ca. 280x134, Landezonen-Button ca. 248x40 | Ist 1,4x breiter, etwa 2,3x hoeher (312 gegen 134) |
| Log unten rechts | 384x144, Schrift 15, Zeile 24 | ca. 312x118, Schrift ca. 14 | Ist +72 breit, +26 hoch |
| Top-Navigation | 440x64; Buttons 100x48 (Mindesthoehe 36), Schrift 16 | im Mock-up nicht vorhanden | zusaetzlich |

Kernaussage: Die Aktionstasten und das Band sind schon nahe an A5. Die Abweichung liegt bei Dropship-Karte (viel zu hoch), Team-Karte (zu hoch, Portraits zu klein) und Log/Objective-Karte.

### 2.2 Heimatbasis "Basis erkunden" mit Seitenleiste und Kommando-Dock (Bild 03)

| Element | Messwert |
|---|---|
| Seitenleiste | 166 px breit (x=16..182), Hauptknoepfe 166x46 bis 50, Schrift 17 (Barlow Condensed), Icon max. 36 px (Quellbild ca. 326x336, `expand_icon`), Aufklapp-Pfeil 32x46 |
| Unterpunkte (Bauen, Werkstatt, Lager, Terminal, Tankservice) | 166x30, Schrift 13, "Datenterminal / Hochladen" zweizeilig 48 hoch |
| "Charakterdetails" | 166x40, Schrift 17 |
| Kommando-Dock | 1920x161 am unteren Rand; 9 Tasten je 75x58 (Teilung 83x66), Schrift 14, Icon max. 24; Name-Feld 196x34 (Schrift 15); Check-Button 196x28; Personenkarte "Tomas Ibarra" 88x85, Schrift 12, Icon max. 42 |
| Hinweis-Karte "Kampagne: Schritt 1/7" | 552x106, Buttons 32 bis 153 x 31, Schrift 16 |
| "Versorgung oeffnen" | 165x34, Schrift 16 |
| "Konsole aufsuchen" / "Uebersicht . Esc" | 396x40 (Schrift 13) / 172x44 (Schrift 13) |

### 2.3 Trupp und Ausruestung (Bilder 04, 04b)

| Element | Messwert |
|---|---|
| Spalten | Personal 307 breit, Trupp 320, Lager und Ausruestung 1058 (alle ca. 910 hoch); Aussenrand 16, Spaltenabstand 12 |
| Spaltenkopf | Barlow Condensed ca. 26 |
| Personenkarte (Personal/Trupp) | 267x99 bzw. 280x99 (Mindesthoehe 80 bzw. 58), Portrait 52x87 bzw. 72x87, Name-Button Schrift 19, Statuszeile ca. 15, Plus-/Haken-Button 40x42 |
| Leerer Truppplatz "Freier Platz" | 280x99 |
| Eingabe/Auswahl | Suchfeld 267x40 (Schrift 14), Dropdowns 267 bis 280 x 42 (Schrift 17), "Neuer Trupp" 121x40 |
| Ausruestungs-Slots (Ruestung, Primaer, Sekundaer) | 264x80, Icon 72x72 |
| Lagerkachel (Basislager) | 126x80 (Mindesthoehe 78), Icon max. 32, Schrift 14, Innenrand 10 |
| Container "Basislager" | 320x258, Innenrand 14 |
| Portrait Identitaet | 112x140 |
| Verschieben/Anlegen-Zeile (4b) | Dropdowns 96 bis 180 x 43 (Schrift 13), Buttons 83 bis 134 x 43 (Schrift 16) |
| Volle Breite Buttons (4b) | "Aus Trupp entfernen", "Charakter ansehen" je 1010x40 (Schrift 17), im Mock-up inventory_grid.png dagegen Buttons ca. 210x64 mit Inhaltsbreite |

Hinweis: In den Knoten-Tabellen stehen auch Knoten ausserhalb des sichtbaren Scrollbereichs (y > 1080); sie zaehlen als "sichtbar im Baum", sind aber abgeschnitten.

### 2.4 Sternkarte (Bild 05)

| Element | Messwert |
|---|---|
| Kopfzeile Buttons | "Abflug vorbereiten" 141x34, "Basis ansehen" 114x34, Schrift 16 |
| Linke Navigation (Tree) | 276x991, Schrift 17, Zeilenhoehe ca. 38 (v_separation 8) |
| Rechte Detailleiste | 320x991, Dropdown 302x32, Panorama 302x124, Buttons 302x32 bis 34 |
| Kartenbuttons | System 70x34, Orbit ansehen 111x34, Gesamtansicht 124x30 (Schrift 12), Planetenmarker 20x20 |

### 2.5 Hauptmenue (Bild 01)

| Element | Messwert |
|---|---|
| Menue-Schiene | 520 breit (27 % der Breite), Inhalt x=58..477 |
| Titel / Untertitel | Schrift 42 / 18 |
| Kampagne | 419x60, Schrift 13 (zu kleine Schrift in grosser Flaeche) |
| Skirmish | 419x76, Schrift 20 |
| Multiplayer, Editor, Einstellungen | 419x50, Schrift 15 |
| Teamname-Feld / "Neu" | 276x42 / 76x42, Schrift 14 / 13 |
| Szenenstart-Buttons | 176 bis 195 x 42, Schrift 13 |
| Neues Skirmish-Team / Team erstellen | 419x44, Schrift 13 |
| Team-Bibliothek (Panel) | 640x320, Buttons 72 bis 104 x 32, Schrift 13 |
| Hilfe "?" | 44x44 |
| Kampagnendialog | 760x260, Buttons ca. 100 bis 190 x 30 |

### 2.6 Weitere Referenzbilder (nur Sichtvergleich, Messung aus Bild, auf 1920 hochgerechnet)

Die anderen bestaetigten Bilder sind nicht dichter als das heutige UI:
- `UI_Seitenleiste_mit_Korrekturen.png`: Navigationsbuttons ca. 218x60 (heute 166x46), Kommando-Dock-Tasten ca. 350x53 mit Icon und Text nebeneinander (heute 75x58 mit Icon ueber Text).
- `inventory_grid.png`: Lagerkacheln ca. 129x80, "Ausruesten" ca. 210x64, Ausruestungs-Slots ca. 138x105 (heute: Slot 264x80, Kachel 126x80).
- `star_map.png`: Aktionsbutton "Anflug beginnen" ca. 478x76, rechte Leiste ca. 505 breit (heute 320).

Nur das Mission-Mock-up A5 ist ausdruecklich als kompaktes Ziel formuliert (Nutzerfeedback vom 01.11.). Fuer Heimatbasis, Inventar und Sternkarte gibt es kein bestaetigtes Mock-up, das eine kleinere Dichte belegt.

## 3. Wo das Aussehen definiert ist

### 3.1 Zentrale Stellen

| Datei | Inhalt |
|---|---|
| `scripts/ui/tactical_ui_theme.gd` (`TacticalUITheme`) | Hauptthema: `FONT_SIZE := 14` (Z. 22), `BUTTON_FONT_SIZE := 13` (Z. 23), `ACTION_TILE_SIZE := Vector2(52,52)` (Z. 24, nur von `style_action_tile` genutzt, 3 Aufrufer ausserhalb der Tests), `COMPACT_ICON_SIZE` 18, `TOOL_ICON_SIZE` 24, `CORNER_RADIUS` 6, `SPACING` 8, `CARD_PADDING` 8/6, Panel-Innenrand 8, Button-Innenrand 8/4 (`style_command_button`). Wird per `apply_screen()` gesetzt von Hauptmenue, Escape-Menue, Lobby, Karteneditor, Hilfe-Popup, Heimatbasis (`MetaUISkin`). Standardschrift ist die Godot-Vorgabe, Ueberschriften Barlow Condensed (`HEADING_FONT_PATH`). |
| `scripts/ui/smart_mobile_theme.gd` (`SmartMobileTheme`) | Zweites Thema im Telefon-App-Stil: `default_font_size = 17` (Z. 37), Rajdhani, Button-Innenrand 10/5 (Z. 22), Tree-`v_separation` 8. Wird nur gesetzt von `star_map_screen.gd`, `remote_inspection_screen.gd`, `singleplayer_job_board_presenter.gd`. Assets `Assets/curated/smart_mobile_fonts`, `smart_mobile_icons`. |
| `scripts/meta/drop_light_layout_contract.gd` (`DropLightLayoutContract`) | Tabelle fuer Mission-HUD: `get_mission_hud_layout(viewport)` (Z. 81) mit Stufen nach Viewport-Hoehe (>=900, >=1260): `action_edge` 52/64/72, `action_gap` 6/8/8, `action_inset` 8/12/16, `card_width` 300/336/400, `portrait_height` 53/58/64, `body_font_size` 14/16/18, `heading_font_size` 20/23/26, Team-Hoehe 226/238/254, Transport-Breite 344/384/440, Objective-Breite 344/400/456, Log-Hoehe 144 bzw. 176. Dazu die alten FullHD-Raster `get_fob_layout`, `get_homebase_layout` (feste Rechtecke). Angewendet von `scripts/ui/mission_a5_hud_layout.gd`. Bei 1920x1080 gilt die mittlere Stufe. |
| `scripts/ui/base_management_skin.gd` | Dritter Stil: Label 16, Button 16 mit `custom_minimum_size.y = 42` (Z. 42), Panel-Innenrand 22 bzw. 14, Eckenradius 7. |
| `scripts/meta/meta_ui_skin.gd` | Farbtabelle, die auf `TacticalUITheme` verweist, plus Stil-Funktionen fuer Heimatbasis/FOB. |

### 3.2 Bildschirme mit eigenen, fest eingebauten Groessen

- `scripts/meta/homebase_operations_presenter.gd` (Seitenleiste, Trupp und Ausruestung): eigener `_button()` mit `custom_minimum_size.y = 40` und Schrift 17 (Z. 1508 ff.), Navigation `custom_minimum_size.y = 46`, `icon_max_width = 36`, Schrift 17 (Z. 235 bis 241), Portrait 176x176, Slot-Beschriftung Breite 76, Abstaende 10/12/16/24; eigene Farbkonstanten.
- `scripts/meta/homebase_screen.gd`: 74 `custom_minimum_size`, 38 Schrift-Overrides, Konstanten `HOMEBASE_OPERATOR_CARD_SIZE 316x66`, `HOMEBASE_SHIPCARD_COMPACT_WIDTH 404`, `HOMEBASE_RELEASE_CTA_MIN_HEIGHT 88` u. a.
- `scripts/ui/main_menu_screen.gd`: 64 `custom_minimum_size`, 24 Schrift-Overrides; `Vector2(360,60)` Kampagne (Z. 3819), `Vector2(360,76)` Skirmish (Z. 1127), 360x58/48 u. a.
- `scripts/meta/fob_screen.gd` (33/18), `character_sheet_view.gd` (32), `npc_compact_card.gd` (28/9), `components/personnel_inventory_panel.gd` (19), `tactical_event_log_panel.gd` (19/9), `mission_a5_dropship_presenter.gd` (18/5), `transport_craft_card_ui.gd` (12/6), `debrief_screen.gd` (13/8), `map_editor.gd` (44/11).
- Zahlen in Klammern: `custom_minimum_size`-Treffer bzw. `add_theme_font_size_override`-Treffer im jeweiligen Skript.

### 3.3 Fazit zur Verteilung

Es gibt keine gemeinsame Dichte-Tabelle. Drei Themen (Tactical, Smart Mobile, BaseManagementSkin) setzen unterschiedliche Grundschriften (14, 17, 16) und Button-Innenraender; dazu die Mission-HUD-Tabelle nach Viewport-Hoehe; die Heimatbasis setzt Buttons und Schriften an Ort und Stelle. Grundschrift reicht von 12 bis 22 innerhalb eines Screens (Heimatbasis: 13, 14, 15, 16, 17, 19, 24, 26).

### 3.4 Globaler Massstab und Mobile/Desktop-Schalter

- `project.godot`: `window/size/viewport_width=1920`, `viewport_height=1080`, `window/stretch/mode="canvas_items"`, `window/stretch/aspect="expand"`. Es gibt keinen `ui_scale`, kein `content_scale_factor`, keinen Mobile/Desktop- oder Compact-Schalter und keine Einstellung dafuer in `game_settings_contract.gd` (Suche: ui_scale, gui_scale, content_scale_factor, mobile, compact, density). Treffer fuer "density" betreffen nur Kampf-HUD-Polish-Stile und Kontakt-Overlays.
- Folge: Auf 1920x1080 ist der Massstab 1:1. Auf einem Monitor mit 2560x1440 im Vollbild werden alle Pixelwerte dieser Bestandsaufnahme mit 1,33 skaliert, bei 3840x2160 mit 2,0. Welche Monitor- oder Fenstergroesse der Nutzer fuer seinen Eindruck "wie Telefon" verwendet, ist nicht bekannt und nicht gemessen. Diese Frage kann den Eindruck "klobig" erklaeren und sollte vor einer Umgestaltung geklaert werden.
- Die Stufen von `get_mission_hud_layout` richten sich nach der virtuellen Viewport-Hoehe. Bei 16:9 bleibt sie wegen "expand" bei 1080, die Stufe "gross" (>=1260) greift dann nur bei hoeheren Seitenverhaeltnissen.

## 4. Vorschlag "PC-Dichte" (Vorschlag fuer die Entscheidung im Hauptchat, keine Entscheidung)

Regeln: Klickziele fuer die Maus mindestens 28 px hoch, Fliesstext mindestens 14 px bei 1920x1080. Zielwerte orientieren sich am Mock-up A5; wo es kein Mock-up gibt, an einer einheitlichen Reihe.

| Token / Groessenklasse | Ort | Ist | Vorschlag |
|---|---|---|---|
| Grundschrift Smart-Mobile-Thema | `smart_mobile_theme.gd` Z. 37 | 17 | 15 |
| Grundschrift Tactical-Thema | `tactical_ui_theme.gd` `FONT_SIZE` | 14 | 14 (Untergrenze, bleibt) |
| Button-Schrift Tactical | `BUTTON_FONT_SIZE` | 13 (unter der 14er-Regel) | 14 |
| Button-Innenrand | Tactical 8/4, SmartMobile 10/5, BaseSkin 10 | 4 bis 10 | einheitlich 8/3 |
| Button-Mindesthoehe Standard | Heimatbasis `_button` 40, BaseSkin 42, Hauptmenue 42 bis 76 | 40 bis 76 | 30 (Haupt-Aktion 34) |
| Navigationsbutton Seitenleiste | `homebase_operations_presenter.gd` Z. 235 | 46, Icon 36, Schrift 17 | 34, Icon 24, Schrift 15 |
| Unterpunkte Seitenleiste | gleiche Datei | 30, Schrift 13 | 30, Schrift 14 |
| Hauptmenue-Buttons | `main_menu_screen.gd` | 360 bis 419 x 44 bis 76, Schrift 13 bis 20 | 300x36, Schrift 15 einheitlich; Schiene 520 auf ca. 380 |
| Personenkarte | Presenter / `npc_compact_card.gd` | 99 hoch, Portrait 52x87 | ca. 64 hoch, Portrait 48x48 |
| Ausruestungs-Slot / Lagerkachel | `personnel_inventory_panel.gd` | 264x80 / 126x80, Icon 72 | 240x60 / 110x64, Icon 48 |
| Volle-Breite-Buttons | Presenter | 1010x40 | Inhaltsbreite, 30 hoch |
| Tree-Zeilenabstand | `smart_mobile_theme.gd` | `v_separation` 8 (Zeile ca. 38) | 4 (Zeile ca. 30) |
| Mission: `action_edge` | `drop_light_layout_contract.gd` (1080-Stufe) | 64 | 64 (A5 ca. 63 hoch, keine Aenderung noetig) |
| Mission: `action_inset` / Bandhoehe | gleiche Datei | 12 / 164 | 8 / 150 |
| Mission: `card_width` Team | gleiche Datei | 336 | 312 |
| Mission: Team-Hoehe | gleiche Datei | 238 | 150 bis 175 (Portraits 63x90) |
| Mission: `body_font_size` | gleiche Datei | 16 | 15 |
| Mission: `heading_font_size` | gleiche Datei | 23 | 22 |
| Mission: Dropship-Karte | Layout + `mission_a5_dropship_presenter.gd` | 384x312 | 280 bis 312 x ca. 140 |
| Mission: Objective-Karte | gleiche Datei | 400x96 | 440x64 |
| Mission: Log | gleiche Datei | 384x144 | 312x120 |

Die Zahlen fuer Heimatbasis, Inventar, Sternkarte und Hauptmenue sind Schaetzvorschlaege aus der Regel (28/14) und der Reihe, kein aus einem bestaetigten Mock-up gemessener Zielwert.

### Aenderung mit dem groessten Effekt

Die Heimatbasis-Praesentation (`homebase_operations_presenter.gd`, Seitenleiste plus Trupp und Ausruestung) in einer Stelle auf eine Dichte-Reihe zu setzen: `_button()` 40 auf 30 und Schrift 17 auf 15, Navigationsknoepfe 46 auf 34 mit Icon 24, Personenkarten 99 auf ca. 64, Slot/Kachel auf 60 bis 64. Sie betrifft den Bildschirm, auf dem der Nutzer am meisten Zeit verbringt, und dort liegen die meisten der "telefonartigen" Elemente (siehe Abschnitt 5). Die Mission-HUD-Tasten muessen dafuer nicht angefasst werden.

Alternative, die ohne Code auskommt: die Stretch-Basis in `project.godot` (z. B. Basisaufloesung groesser, 1:1 gleichmaessig verkleinernd). Sie verkleinert alles, verletzt aber die 14-px-Regel (Schrift 13/14 wird 10 bis 11 px) und verschiebt die Hoehenstufen von `get_mission_hud_layout` (virtuelle Hoehe wuerde >= 1260 und damit die Stufe "gross" aktivieren). Wurde nicht ausprobiert.

### Risiken

- Abgeschnittene deutsche Texte: lange Woerter in schmalen Kacheln ("Sanitaetsgeraet" bricht schon heute in der 126-px-Kachel mitten im Wort, "Schwere Ruestung", "Datenterminal / Hochladen"), Buttons mit `clip_text`, Dropdown-Eintraege mit `fit_to_longest_item = false`.
- Ueberlappende Panels: Mission-HUD arbeitet mit absolut platzierten Rechtecken (`_place`), die aus der Layout-Tabelle abgeleitet sind (Team-Karte oberhalb des Bands, Fireteam-Mini darueber). Aenderungen an Hoehen verschieben die Kette Band -> Team -> Mini. Das Kampagnen-Hinweis-Panel und der Versorgungs-Button ueberdecken sich heute schon (Bild 03, oben rechts).
- Tests, die Groessen festnageln (aus `scripts/tests` per Suche ermittelt, nicht ausgefuehrt):
  - `playtest_20261105_mission_hud_groups_verifier.gd` prueft pro Aufloesung (1280x720, 1920x1080, 3440x1440) Aktionskante 52/64/72, Kartenbreite 300/336/400 und Portraithoehe.
  - `reference_polish_r3_20261106_mission_ui_verifier.gd` (Aktionstasten in quadratischem Slot, `action_edge`).
  - `task_180_mission_drop_light_fixed_hud_layout_verifier.gd` (u. a. Haltungs-Button `Vector2(64,24)`), `task_178_..._fob_...`, `task_179_..._homebase_...`, `task_181_...` (feste FullHD-Rechtecke, Achterraster).
  - `reference_polish_r3_20261106_theme_idempotency_verifier.gd` (`BUTTON_FONT_SIZE`, Schriften 11 und 19), `reference_polish_r3_20261106_native_labels_verifier.gd` (13), `reference_polish_r3_20261106_command_style_owner_verifier.gd`, `runtime_hitches_r4_20261107_native_craft_chain_verifier.gd` (12 und 13), `hud_architecture_20261106_native_style_verifier.gd` und `_style_verifier.gd` (`icon_max_width`).
  - Untergrenzen fuer Schrift (wuerden bei Verkleinerung brechen): `ui_a5_reference_groups_verifier.gd` (>=16 fuer Belegung, >=14 Transportstatus), `ui_native_r3_mission_readout_verifier.gd` (>=13), `character_sheet_compact_verifier.gd` (>=15), `task_1158_selected_fireteam_member_cards_1280_readability.gd` (>=15 und 12), `playtest_world_selection_context_verifier.gd` (>=16), `task_1131_..._header_contrast_...` (>=12), `mission_tactical_sandbox_controller.gd` (>=15/12/16).
  - `mission_tactical_sandbox_controller.gd` selbst (Testhilfe mit `body_font_size`, `portrait_height`, `card_width`, `icon_max_width`, `bottom_dock`) und `task_835_..._bottom_dock_density_polish.gd`, `task_1168_..._air_anchor_polish.gd`.

## 5. Die fuenf "telefonartigsten" Dinge in den Aufnahmen

1. Hauptmenue, Schiene und Buttons: 419x60 (Kampagne, Schrift 13) und 419x76 (Skirmish, Schrift 20) in einer 520 px breiten Schiene; ganze Spaltenbreite pro Knopf, kleine Schrift in grosser Flaeche.
2. Trupp und Ausruestung (Bild 04b), Volle-Breite-Buttons "Aus Trupp entfernen" und "Charakter ansehen": je 1010x40, Textleiste ueber die ganze Spaltenbreite; Mock-up hat Inhaltsbreite (ca. 210x64).
3. Trupp und Ausruestung, Personenkarten und Slots: Karte 267x99 mit Portrait 52x87 und 40x42-Plus-Button; Ausruestungs-Slots 264x80 mit 72-px-Icon; Lagerkachel 126x80 mit 3 Textzeilen.
4. Mission-HUD, Dropship-Karte oben rechts: 384x312 (Auswahl + Karte), Aktionszeile 2x176x44, Anflug-Dial 4x48x32, Titel Schrift 22 in 130 px Breite; Mock-up A5 hat 280x134.
5. Heimatbasis-Seitenleiste: Hauptknoepfe 166x46 bis 50 mit 36-px-Icon (Quelle 326x336) und Schrift 17, daneben Unterpunkte 166x30 mit Schrift 13; drei Hoehen und zwei Schriftgroessen in einer Leiste, dazu `Kommando-Dock` mit Tasten 75x58 (Icon ueber Text) wie App-Kacheln.

Ebenfalls auffaellig, aber nicht in den Top 5: Sternkarte, linke Baumliste mit Zeilen von ca. 38 px und Schrift 17; das zweite "Smart Mobile"-Thema mit eigener Schrift (Rajdhani) neben Barlow Condensed und Godot-Standardschrift.

## 6. Nicht bestimmbar

- Aufloesung und Fenstermodus des Nutzers (siehe 3.4). Alle Masse hier gelten bei Faktor 1,0.
- Schriftgroessen des Mock-ups sind nur aus Versalhoehen geschaetzt (+-2 px).
- Smart-Mobile-Auftragsapp, Debrief, Lobby, Einstellungen, Escape-Menue, Editor: nicht aufgenommen, nicht gemessen.
- Das Mission-HUD wurde in der Software-GL-Umgebung (llvmpipe) gemessen; die Kamera stand nicht auf dem Trupp, die HUD-Controls sind davon unabhaengig.
- Die Wirkung der Vorschlagswerte auf deutsche Texte und Tests wurde nicht ausgefuehrt, nur per Suche gelesen.
