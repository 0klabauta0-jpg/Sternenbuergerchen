# TASK_352 - Homebase Loadout Defaults Preserve Unit Profiles

## Ziel
Unveraenderte Homebase-Loadouts duerfen bestehende Unit-/Roster-Profile nicht ueberschreiben. Ein Medic bleibt Medic, solange der Spieler sein Loadout nicht bewusst aendert.

## Status: IMPLEMENTIERT

## Problem
Homebase erzeugt aktuell fuer leere Member-Loadouts harte Defaults wie `rifle` und `none`. Diese Defaults werden als `member_loadouts` exportiert und in `MissionTestSetup` als Override angewendet. Dadurch koennen Preset-Waffen wie `unit_bravo` mit `smg` + `medictool` still durch `rifle` + `none` ersetzt werden.

## Ursache
TASK_350 hat den Exportvertrag geschlossen, aber die Default-Quelle bleibt zu generisch. Die Homebase-UI kennt die Unit-Profile bereits, nutzt sie aber beim Seeding der Member-Loadouts noch nicht als autoritative Basis.

## Umfang
- `_get_member_loadout()` / Sync-Pfade in Homebase so anpassen, dass Defaults aus Unit-Profil, Selected-Config oder Roster-Preset gelesen werden.
- Harte Fallbacks nur verwenden, wenn keine Unit-spezifische Quelle existiert.
- Geaenderte Werte weiterhin explizit im `member_loadouts`-Contract speichern.
- Ungeaenderte Werte sollen im Export entweder profilgetreu enthalten sein oder als nicht-override-verdraengender Contract behandelt werden.
- Medictool-, Sniper-, Heavy-/Special-Waffen in Presets nicht durch Homebase-Defaults verlieren.

## Akzeptanzkriterien
- [x] `unit_bravo` behaelt ohne Spieleraktion `weapon_1 = smg` und `weapon_2 = medictool` bis in `MissionSetup`.
- [x] Eine bewusst geaenderte Homebase-Auswahl ueberschreibt das Preset korrekt.
- [x] Fireteam-Lead- und Armor-Informationen bleiben erhalten.
- [x] `LoadoutModifierResolver` erhaelt fuer unveraenderte Units profilgetreue Werte.
- [x] Headless-Verifier deckt mindestens Medictool-Preservation und bewussten Override ab.

## Erwartete Dateien
- `scripts/meta/homebase_screen.gd`
- `scripts/meta/meta_unit_profile_builder.gd` oder bestehende Profil-/Roster-Helfer, falls noetig
- `scripts/tests/task_352_homebase_loadout_defaults_preserve_unit_profiles.gd`
- ggf. `scripts/tests/task_350_homebase_loadout_contract_export.gd`
- ggf. `scripts/tests/medic_support_verifier.gd`

## Lokale Pruefung
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_352_homebase_loadout_defaults_preserve_unit_profiles.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_350_homebase_loadout_contract_export.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_351_homebase_direct_payload_scope_contract.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/medic_support_verifier.gd`
- [x] `git diff --check`

## Risiken / offene Punkte
- Es muss klar bleiben, ob ein exportierter Loadout-Eintrag ein bewusst gesetzter Override oder ein profilgetreues Default-Abbild ist.
- Wenn spaeter persistente Loadouts kommen, sollte dieser Task keine zweite Speicherung neben dem eigentlichen Profilmodell etablieren.

## Implementierungsnotiz
- Homebase normalisiert Member-Loadouts jetzt mit Unit-spezifischen Defaults aus Roster-/Profil-Daten.
- Explizite Homebase-Overrides gewinnen weiterhin vor Profilwerten.
- Harte Defaults greifen nur noch, wenn keine Unit-spezifische Quelle existiert.
