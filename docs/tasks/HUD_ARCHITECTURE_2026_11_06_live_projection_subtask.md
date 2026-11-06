# Live HUD: lokale Legacy-Aktionsprojektion

## Ziel / Problem
Die produktive Commandmatrix zieht ueber zwei historische Button-Getter mehrfach
Playtest-, Polish-, Smoke- und Akzeptanzprojektionen nach. Dabei werden andere
HUD-Panels erneut aufgebaut oder deren bereits getrimmte Labeltexte rueckwaerts
als Beleg gelesen. Der frische Haupttask misst diese Ketten mit etwa 50-64 ms.

## Ursache / Sinnhaftigkeit
Die vorhandenen get_*-APIs sind einzeln fuer QA, Details und externe Aufrufer
geeignet. Ihr verschachtelter Defaultpfad ist fuer einen schon laufenden vollen
HUD-Aufbau zu breit. Derselbe aktuelle Eingabestand soll deshalb lokal einmal
durch die bestehenden Contracts laufen. Gameplayautoritaet bleibt unveraendert.

## Umfang und Nicht-Ziele
- Root implementiert `_build_live_hud_legacy_action_projection(selected_raw,
  strategic_raw)` mit den vier Darstellungssections `runtime_button`,
  `runtime_visual`, `choice_buttons`, `choice_visual` sowie `execution_hook`.
- Lokaler DAG: NextLoop -> Playtest mit aktuellen RAW-Texten -> Polish ->
  ExecutionHook -> GoSmoke -> RuntimeButton/Visual -> PlayabilitySmoke ->
  Extension -> HudWiring mit RAW-Texten -> ChoiceHook -> Choices/Visual.
- Beide Apply-Funktionen konsumieren optional diese komplette Projektion.
  Ohne Projektion bleiben ihre bisherigen APIs und QA-Getterpfade erhalten.
- Keine langfristige Cache-/Parallel-State-Schicht, keine neue Kampfpolicy,
  keine veraenderten Commands, Plans, ROE- oder GO-Regeln.
- Delegierter Besitz: ausschliesslich dieser Subtask und neuer Verifier.
  Root besitzt Produktcode, Engine-Laeufe und Git.

## Relevante Dokumente / Contracts
- `HUD_ARCHITECTURE_2026_11_06.md` und `AGENTS.md`
- `../ARCHITECTURE.md`, `../CODEX_RULES.md`
- `../dev/mission_command_feedback_contract.md`
- `TASK_963_release_first_decision_next_playable_loop.md`
- `TASK_964_release_first_decision_loop_two_playtest.md`
- `TASK_966_release_first_decision_loop_two_execution_hook.md`
- `TASK_968_release_first_decision_loop_two_runtime_button.md`
- `TASK_976_release_first_decision_loop_two_player_loop_extension.md`
- `TASK_979_release_first_decision_loop_two_player_loop_runtime_choice_buttons.md`

## Akzeptanzkriterien
- Ein lokaler DAG liest seine NextLoop-Quelle genau einmal. Bereits aktuelle
  RAW-Strings bauen Fireteam-/Strategic-Text nicht erneut auf und lesen keine
  getrimmten Texte aus diesen beiden Panels zurueck.
- Auch fehlender oder leerer RAW-Text bleibt fehlende Sichtbarkeit; ein leerer
  String darf im lokalen DAG nicht den historischen Getterfallback aktivieren.
- Bei tatsaechlich identischer Quelle, Texten, Clock und Trace stimmen alle
  fuenf Sections vollstaendig mit dem unveraenderten Getterpfad ueberein.
- Ein gueltiger aktiver Quellstand liefert den bisherigen HOLD-Defend-Draft
  fuer das ausgewaehlte Fireteam und dieselben vier geordneten Choices.
- Unbeobachteter Smoke bleibt unbeobachtet und schaltet vier Choices nicht frei.
  Nur ein eindeutig synthetischer Trace erreicht im Verifier die aktive Branch.
- Apply mit mitgegebener Projektion startet keinen weiteren DAG/Textaufbau.
- Synchronously gelesene echte Commands, Effects, Plans, ROE, Tick und Units der
  Missionsszene bleiben vor/nach Projektion und Apply identisch.

## Betroffene Dateien
- Root: `scripts/tests/mission_tactical_sandbox_controller.gd`
- Delegiert: `scripts/tests/hud_architecture_20261106_live_projection_verifier.gd`
- Delegiert: diese Subtask-Datei

## Lokale Pruefung
Nur Root startet die Engine seriell mit frischen isolierten Userdaten und dem
bestehenden Roster-/Quellguard. Erwarteter Erfolgsmarker:
`HUD_LIVE_PROJECTION_VERIFY_PASS`. RED darf vor Implementierung an der dynamisch
geprueften fehlenden API scheitern, ohne Parse-/Scriptfehler. Danach zielgerichtet
GREEN und benachbarte HUD-/Command-Gates; nativer 1x-Vergleich separat.

## Risiken / offene Punkte
Der Legacy-Kontexthelper liefert unveraendert `objective_pressure=medium`,
`known_contact_pressure=medium`, `team_condition=stable`, `ammo_pressure=low`.
Das ist ein fester Empfehlungskontext, kein aktueller Combat-Read. Er beeinflusst
in der Extension Empfehlung und WHY-Texte. Diese Restschuld wird durch den DAG
nicht behoben und darf nicht als neue beobachtete Runtimewahrheit bezeichnet
werden. Eine spaetere Ablösung benoetigt einen eigenen quellengebundenen Contract.

Der Verifier nutzt eine echte Missionsszene, kontrollierte read-only Quellen und
einen festen Clock sowie einen klar synthetischen Smoke-Trace fuer Branchabdeckung.
Er belegt weder physisches Feuer noch Benutzer-/Release-/Performanceakzeptanz.
