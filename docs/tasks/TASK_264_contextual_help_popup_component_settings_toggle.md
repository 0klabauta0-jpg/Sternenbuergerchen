# TASK_264 - Contextual Help Popup Component Settings Toggle

## Ziel
Die Hilfe-Popups sollen als wiederverwendbare UI-Komponente umgesetzt werden: kompakt, viewport-sicher, abschaltbar, mit globalem Hilfe-Button und progressiver Detailanzeige nach laengerem Hover.

## Status: IMPLEMENTIERT

## Voraussetzung
- TASK_226 - Main Menu Settings Shell Display Audio Input Gameplay
- TASK_257 - Button Reachability and Interaction Verifier
- TASK_258 - Fixed Window Clipping Scrollbar Playability Audit
- TASK_263 - Contextual Help Popup UX Contract

## Kontext
Godot-Standard-Tooltips reichen fuer das Ziel vermutlich nicht aus: Sie sind schwer global zu testen, koennen lange Einzeiler erzeugen und haben keine gute zweistufige Erklaerung. Sternenbuergerchen braucht eine kleine eigene Help-Schicht, die `help_id`s aus einem Katalog liest und ueber Settings kontrollierbar ist.

## Umfang
1. Help-Service:
   - `ContextualHelpService` oder vergleichbare Autoload-/UI-Schicht.
   - Laedt `data/contextual_help_catalog.json`.
   - Liefert Kurz- und Detailhilfe pro `help_id`.
   - Zaehlt fehlende IDs, leere Texte und deaktivierte Popups.
2. Popup-Komponente:
   - Kompakter Container mit Titel, Kurztext, optionalem Detailbereich.
   - Maximalbreite, Maximalhoehe, Text-Wrapping.
   - Positioniert sich im Viewport und vermeidet Offscreen.
   - Detailbereich nach laengerem Hover oder Pin.
3. Timing:
   - Kurzhilfe nach kurzer Verzoegerung.
   - Detailhilfe nach ca. 3 bis 4 Sekunden Hover oder aktivem Help-Modus.
   - Keine Flacker-Popups bei schneller Mausbewegung.
4. Settings:
   - Hilfe aus/an.
   - Optional: kompakt/erweitert.
   - Delay-Werte nur intern oder als einfache Presets, nicht als ueberladenes Settings-Menue.
5. Globaler Hilfe-Button:
   - Kleiner Button oben im App-Shell/HUD-Kontext.
   - Schaltet Help-Modus oder Help-Popups schnell an/aus.
   - Muss mit festen Fensterlayouts kompatibel sein.
6. Control-Anbindung:
   - Helper zum Registrieren von `help_id` an Buttons, Labels, Panels, Stat-Zeilen, Slots.
   - Keine Freitext-Duplikate in jedem Screen.

## Nicht-Ziele
- Keine finalen Hilfe-Inhalte fuer alle Screens.
- Kein Tutorial-Overlay.
- Kein neues UI-Theme.
- Kein Mouse-Tracking, das Gameplay-Input stoert.

## Akzeptanzkriterien
- [x] Wiederverwendbare Popup-Komponente existiert.
- [x] Hilfe kann in Settings ausgeschaltet werden.
- [x] Kleiner globaler Hilfe-Button ist in App-Shell/HUD-Kontext vorbereitet.
- [x] Kurzhilfe und Detailhilfe haben getrennte Timing-Regeln.
- [x] Popup bleibt im Viewport und bricht Text kompakt um.
- [x] Fehlende `help_id`s werden diagnostiziert, ohne die UI zu crashen.
- [x] Ein Verifier prueft Settings, Toggle, Timing, Positionierung und Text-Wrapping.

## Erwartete Dateien
- `scripts/ui/contextual_help_service.gd`
- `scripts/ui/contextual_help_popup.gd`
- optional `scenes/ui/contextual_help_popup.tscn`
- `data/contextual_help_catalog.json`
- `scripts/tests/task_264_contextual_help_popup_component_settings_toggle.gd`
- `docs/tasks/TASK_264_contextual_help_popup_component_settings_toggle.md`
- `docs/IMPLEMENTATION_STATUS.md`

## Lokale Pruefung
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_264_contextual_help_popup_component_settings_toggle.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_258_fixed_window_clipping_scrollbar_playability_audit.gd`
- [x] `git diff --check`

## Risiken
- Popups duerfen keine festen Fenster verschieben oder Inputs blockieren.
- Help-Button oben darf keine bestehenden HUD-/Topbar-Controls verdecken.
- Zu aggressive Hover-Logik kann sich nervoes anfuehlen.

## Ergebnis
`ContextualHelpService` laedt den Katalog, normalisiert Modi, liefert kompakte oder detaillierte Payloads, trennt Timing-Regeln und diagnostiziert fehlende IDs, leere Texte sowie deaktivierte Requests. `ContextualHelpPopup` ist eine wiederverwendbare, viewport-sichere Panel-Komponente mit Wrap-Labels und Detailbereich. `GameSettingsContract`, `SettingsScreen` und `MainMenu` kennen den Settings-Modus `contextual_help_mode`; das Main Menu bereitet einen kleinen globalen Help-Button und Help-IDs fuer App-Shell/Settings-Ziele vor.

## Naechster Schritt
TASK_265 und TASK_266 koennen die eigentlichen Hilfeinhalte fuer Charakterbogen, Loadout, Befehle und Screens eintragen und an die neue Schicht anbinden.
