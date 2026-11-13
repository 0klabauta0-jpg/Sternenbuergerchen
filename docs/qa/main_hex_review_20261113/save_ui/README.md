# Mainintegration: ehrliche Speicher-UI

Scope: `docs/tasks/MAIN_INTEGRATION_HEX_REVIEW_2026_11_13.md`.
Gezielter Port auf aktuelle Mainowner, keine Übernahme alter UI-/Savekörper.

Nichtkampagnen-Shellslots bleiben `scene_path_v1` und werden als
`Szenenstart merken` / `Gemerkte Szene neu starten` mit fehlendem Fortschritts-
Restore beschrieben. Kampagne behält `request_campaign_save` samt Ownerfeedback
und Fortsetzen über das Hauptmenü. Save im Hauptmenü ist deaktiviert.

## TDD / Ergebnis

- Sauberer ROT-Stand vor Produktedit: `74cc08259763489aa9386d938262974a`,9/7,
  ausschließlich neue Beschriftungs-/Enabledassertions rot; keine Enginefehler.
- Finale Probe: `9153725c5b394f3696dc5c9448457c5a`, **16/0**, Exit0, alle
  Quellen-/Originalprofil-/Canaryguards grün und Logs ohne Scriptfehler/Leaks.
- Voriger Fixtureversuch `e291...` hatte fehlende deklarierte Onreadycontrols;
  diese Testvorbedingung wurde vor dem sauberen ROT ergänzt. Zwischenstand
  `c8a...`15/1 verglich Groß-/Kleinschreibung von Spielfortschritt zu eng;
  die Textsemantikassertion prüft nun unabhängig davon. Rohberichte bleiben erhalten.

`python scripts/tests/run_main_hex_save_ui_20261113.py --execute` startet genau
diesen Fall in frischem privatem Projekt und Profil; ohne Flag nur Plananzeige.
Der Runner erzeugt lediglich privat eine minimale Bookmarkszene und verwendet
eine eigene Bookmark-/Settingsdatei unter dem privaten user://.

Tatsächliche Shell-/Menümethoden, echte ConfigFile-Bookmarkdatei, API-Capability-
Kampagnenowner mit Erfolg/Ablehnung sowie tatsächliche Continue-Revalidierung.
Nur unbenutzte Menüstartup-/Audiowiedergabe und der finale Szenenstart sind in
den Capabilityfixtures unterdrückt. Keine echte Mission-/Fortsetzen-Abnahme,
kein Desktop, kein Render-/Klick-/Nativebeleg. Menüwechsel pausiert nicht.

Produktdateien: ausschließlich `scripts/ui/global_escape_menu.gd` und
`scripts/ui/main_menu_screen.gd`. Kampagnenowner und bestehende Save-/Startpfade
unverändert. `git diff --check` sauber; keine Gitmutation durch Teilagenten.
