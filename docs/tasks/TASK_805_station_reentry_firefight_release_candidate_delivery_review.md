# TASK_805 - Station Reentry Firefight Release Candidate Delivery Review

## Ziel / Problem
TASK_804 kann einen sichtbaren EXE-/Host-Client-Smoke als sauber markieren, aber der Stand ist noch nicht als weitergabefaehige Delivery-Entscheidung zusammengefasst. TASK_805 entscheidet read-only, ob das Release-Candidate-Paket samt sichtbarem Smoke, Notizen, bekannten Risiken und naechstem Griff bereit fuer einen Handoff ist oder gezielt zurueck muss.

## Sinnhaftigkeit / Ursache
Ein Smoke ist ein Testmoment, keine Auslieferungsentscheidung. Damit der naechste Schritt nicht wieder im Chat oder in lokalen Erinnerungen haengen bleibt, braucht der Release-Candidate eine knappe Delivery-Review: Was ist das Paket, was wurde sichtbar geprueft, welche Risiken sind akzeptiert, welche Hinweise braucht der Spieler/Tester und welcher Folge-Task ist korrekt.

## Umfang
- Read-only Snapshot ueber TASK_804-Visible-Ship-Smoke.
- Delivery-Checks fuer Smoke-Quelle, Release-Dateien, Spielstart-Hinweis, Host/Client-Hinweis, bekannte Risiken, Report-/Manifest-Ablage, Taskleisten-/Shortcut-Hinweis und naechste Handoff-Entscheidung.
- Issue-Flags mit gezieltem Routing fuer stale Paket, fehlende Dateien, unklare Startanleitung, unklare Host/Client-Rollen, nicht akzeptierte Risiken, fehlenden Report-Export und sichtbaren Polish-Bedarf.
- Manifestpfad fuer die Delivery-Review und naechsten Handoff-Packet-Schritt.

## Nicht-Ziele
- Kein Export-Aufruf und kein Datei-Paketieren.
- Kein Starten oder Schliessen von Fenstern.
- Kein Screenshot-Parser und kein automatischer Sichtbeweis.
- Kein Gameplay, keine Navigation, keine Commands, keine FireEvents und keine DamageEvents.
- Kein finaler Produkt-Release; nur Delivery-Entscheidung fuer den aktuellen Release-Candidate.

## Relevante Contracts / Dokumente
- `docs/PROJECT_BRIEF.md`
- `docs/ARCHITECTURE.md`
- `docs/CODEX_RULES.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/tasks/TASK_804_station_reentry_firefight_release_candidate_visible_ship_smoke.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/reports/project_current_state_handbook_reentry_2026_07_01.html`

## Akzeptanzkriterien
- Fehlende oder ungueltige TASK_804-Quelle blockiert.
- Nicht bereiter sichtbarer Ship-Smoke wird nicht als delivery-ready markiert.
- Ohne Review-Notizen bleibt der Status `needs_delivery_review`.
- Unvollstaendige Delivery-Checks listen konkrete `missing_check_ids`.
- Aktive Issue-Flags erzeugen konkrete `action_items`.
- Vollstaendige, saubere Review setzt `release_candidate_delivery_ready = true`.
- Ein sauberer Snapshot routet zu `TASK_806 - Station Reentry Firefight Release Candidate Handoff Packet`.
- Snapshot bleibt read-only: keine Navigation, keine Commands, keine FireEvents, keine DamageEvents, keine UI-/Gameplay-/Multiplayer-Wahrheit.

## Betroffene Dateien
- `scripts/mission/station_reentry_firefight_release_candidate_delivery_review.gd`
- `scripts/tests/task_805_station_reentry_firefight_release_candidate_delivery_review.gd`
- `docs/tasks/TASK_805_station_reentry_firefight_release_candidate_delivery_review.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/reports/project_current_state_handbook_reentry_2026_07_01.html`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_805_station_reentry_firefight_release_candidate_delivery_review.gd`
- Regressionen TASK_804/TASK_803
- `git diff --check`

## Risiken / offene Punkte
- TASK_805 trifft keine Produktfreigabe fuer unbekannte Spieler, sondern nur eine kontrollierte Delivery-Entscheidung fuer den aktuellen Release-Candidate.
- Echte visuelle Schoenheit und Spielgefuehl bleiben Playtest-/Polish-Arbeit; dieses Gate verhindert nur, dass Paket, Smoke und Handoff auseinanderlaufen.
