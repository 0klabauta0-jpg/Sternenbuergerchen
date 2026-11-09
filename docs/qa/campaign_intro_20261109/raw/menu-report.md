# Task 2 menu report

Commit: `3e4d56464` (local only; no push/merge).

Implemented the explicit one-shot start boundary in game_start_contract.gd: request_start(tree, mode, action="new") returns {ok,reason?}; consume_start validates and removes root metadata and defaults to skirmish:new; clear_start removes it for MP/editor.

Actual main-menu Campaign button opens New/Continue dialog. Continue calls the checkpoint store and revalidates at activation. Existing valid or invalid checkpoint requires a separate replacement confirmation. Menu only sends the request; it does not mutate campaign/checkpoint data. Dialog explains safe home milestones and interrupted-sortie rollback. Existing Singleplayer control now displays Skirmish and requests skirmish:new; team editor/library labels identify Skirmish. Release deeplink still invokes the existing handler. MP clears stale campaign context before its unchanged lobby route. Campaign help uses main_menu.campaign; root owns catalog entry.

Tests: initial RED was missing explicit contract (test failed with exit 1). Final campaign_menu_start_test: 29 checks/0 failures, exit 0, empty stderr. Covers actual scene buttons, request validation/one-shot consumption, missing/valid/invalid checkpoints, revalidation, replacement cancellation/confirmation, New without save, Skirmish labels, MP clear, release route compatibility. UI test subclass overrides scene navigation and checkpoint result, keeping tests private and headless. Domain checkpoint validation belongs to Task 1.

Regressions: task_234_persistent_player_roster_save_and_reset 42/0; task_299_team_identity_name_generation_userology 11/0; task_823_release_singleplayer_visible_findings_polish 28/0. All exit 0 with empty stderr. The initial 823 hint failed on renamed tooltip; corrected tooltip accurately retains Sortie wording and Skirmish ownership. Tests ran background headless, hidden, BelowNormal priority. No native/UI-control operations.

Owned files only committed: scripts/meta/game_start_contract.gd, scripts/ui/main_menu_screen.gd, scripts/tests/campaign_menu_start_test.gd. No scenes changed. git diff --check clean except normal CRLF normalization warnings. Native layout/usability remains user acceptance.

## Task 3 presentation subtask
Commit `7daec05d4`: campaign_tutorial_presenter Control with configure(runtime,flow), refresh(). Read-only snapshots map all nine owner next-step IDs into actionable guidance. Cached signature avoids repeated text/control rebuilds. Strip begins x260,y8 width<=560, leaving Return navigation and right-side service card free. Existing ContextualHelpService/Popup supports .45s hover/focus, 3.5s expanded detail, .15s hover exit and pinned explicit '?' reopening. Dismiss and hide only affect presentation. Off mode suppresses popups but '?' restores the current textual guidance without enabling hover help. No pause or gameplay commands.

Added campaign.* and main_menu.campaign catalog entries, updated primary menu route text to explain Skirmish-owned team tools and independent campaign saves. Native design review flags remain draft/manual_review=true.

RED missing presenter observed. Final private-APPDATA background headless BelowNormal presenter test31/0 exit0 empty stderr; actual catalog/contract task2634406/0. Existing task26443/1 expects old SettingsVBox/ContextualHelpModeOptionButton path and throws null get_meta; outside owned task, baseline confirmation deferred. Task267 larger per-entry layout run was stopped before completion to respect root real-loop exclusivity; do not count as a pass. Earlier initial parser-error process wrappers were explicitly terminated (console wrapper and actual engine names differ); final bounded test exits normally.
