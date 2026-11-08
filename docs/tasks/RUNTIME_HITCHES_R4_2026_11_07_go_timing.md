# R4: verbleibende synchrone GO-Spitzen exakt aufteilen

## Ziel / aktueller Befund
Root meldet nach frischen nativen90s Kamera22 etwaP99=68ms, Maximum157ms,
16 Frames ueber100ms. Ruckelspitzen bleiben. GO bei48/72s liegt weiter bei
59-61ms, andere GO-Aufrufe etwa29-36ms. Ein gleicher Renderframe ist wegen
zwischenzeitlicher Physics-/Runtimearbeit kein Nachweis identischer Quellen.
Produktbasis Controller`0706cc52...`. Root hat nach dem frischen nativen
Diagnosebefund ausschliesslich die hier beschriebene reine Instrumentierung
freigegeben; keine weitere Optimierung. Zuerst synchrone Scopes erfassen.

## Umfang / Nicht-Ziele
Nur reine Timingdiagnose bei bereits aktiviertem
`_mission_visible_frame_timing_debug_enabled`. Keine zusaetzlichen Gameplay-
Getter, Zustandssnapshots, SceneScans oder Sourcebuilds fuer Diagnosedaten.
Keine Umbauten an Commands, Profilen, Nav, Eventreihenfolge, Cadence, Dirty-
Flags oder Budgets. Keine Actor-/HP-/Position-/Timer-/Authoritypatches und
kein neuer Runtime-/Framecache. Keine FPS-/Ursachenbehauptung aus Entwurf.

## Vorgeschlagene exakte Beobachtungsgrenzen
Ein frischer lokaler Receipt je oeffentlichem
`execute_selected_fireteam_orders`-Aufruf. Acht nicht ueberlappende Topscopes:
1. Guards und bestehende Network-/Interaction-Handoffs.
2. Ganze Execution-Schleife ueber ausgewaehlte Fireteams.
3. Koordination nach tatsaechlicher Neuaktivierung.
4. Bestehende GO-Decision-Summary.
5. Die vier bestehenden Feedback-Bubble-Aufrufgruppen zusammen.
6. Ordervisuals einschliesslich bestehender Kontaktpublikation.
7. Commandfeedback.
8. Planungssnapshot und synchrone `planning_state_changed`-Callbacks zusammen.

Commandfeedback verschachtelt in Buttonstate, bestehendes Light-UI und nativen
Endlayoutpass teilen. Das Last-UI-Debugreceipt wird sonst durch den folgenden
Heavy-UI-Aufruf ueberschrieben. Activation bei echtem Aufruf weiter in
`_resolve_fireteam_behavior_profile`, bestehende lokale Profil-/Planmetadaten
und `_issue_waypoint_for_fireteam` teilen. Letzteres bei Bedarf in
`start_execution` inklusive aktueller Argumentaufbereitung und nachfolgenden
RecentTrace/Mirror/Flank-Feedbackpfad teilen, ohne Argumente umzubauen.

Vorhandene lokale issued/continued/already_active/blocked-Arrays liefern
Branchzahlen ohne neue Ownerabfrage. `process_frame`, Start-/End-Usec und
Gesamtdauer erlauben Zuordnung zum bisherigen Harness-GO-Event. Keine
zusatzlichen Plan-/Cargo-/Runtimeabfragen fuer Kontext anlegen.

## Receipt-Lifecycle und Auswertung
- Bei jedem GO-Eintritt einen frischen Receipt beginnen, auch bei spaeterer
  Preview-/Observer-/NoOrders-/Networkablehnung; Outcome kennzeichnen. Sonst
  kann ein alter erfolgreicher Receipt dem naechsten GO zugeordnet werden.
- Kein dauerhafter Shared-Sourcezustand. Hoegstens acht reine Diagnosereceipts
  nach bestehendem Debuggetterpattern halten; bei Debugaus abschalten/leeren.
  Vorhandener Gettername im R4-Harness:
  `get_command_commit_timing_debug_snapshot`. Root liest nach dem gesamten
  Messfenster einmal aus: initiales GO plus sieben Mess-GOs bleiben erhalten,
  ohne periodische Diagnoseleser. Helper scopen ausschliesslich den aktuell
  synchron laufenden GO; normale Runtimeaktivierungen legen keine GOdaten an.
- Topscopes koennen der Gesamtdauer gegenuebergestellt werden; verschachtelte
  Scopes ausdruecklich nicht dazuaddieren. Planungspublikation erst bei
  nachgewiesener Dominanz weiter in Snapshotbuild und Callbackarbeit zerlegen.
- Unterschiedliche Branches und Outcomes getrennt vergleichen. Gemessene
  Kosten sind noch kein Beleg identischer wiederholter Arbeit.

## Dokumente / Dateien / Akzeptanz
AGENTS, PROJECT_BRIEF, ARCHITECTURE, CODEX_RULES, R4-Haupttask,
`mission_hud_projection_authority_contract.md`, Command-Projection-Task.
Moeglicher Produktbereich nur vorhandene GO-/Feedback-/Activation-Methoden
im Controller nach eigener Rootfreigabe, plus enger Harness-Debugread.

Nach Umsetzung: Debugaus erzeugt keinen Diagnoseinhalt und keine zusaetzlichen
Source-/Ownerreads. Debugan behaelt echte Commands, Callbackidentitaeten,
Queue-/Plan-/Actorwerte und Branchresultate. Native gleiche Route/Kamera/
Rate, vollstaendige GO-Receipts fuer die langsamen und schnellen Aufrufe.
Erst danach einen belegten engen Optimierungshunk mit eigenem RED festlegen.
Root bleibt alleiniger Engine-/Gitrunner. Gameplay-/Batch-/Schedulerpatch ist hold.

## Instrumentierung / Sourcefreeze
Nach ausdruecklicher enger Rootfreigabe implementiert, vor Enginepruefung:
- Getter `get_command_commit_timing_debug_snapshot` liefert maximal acht
  fertige Receipts mit Invocation-ID, Frame, Beginn/Ende/Gesamtdauer, Outcome,
  Accepted und vorhandenen lokalen Branchanzahlen. Alle acht Returnpfade
  schliessen ihren eigenen Receipt; ein reentrant synchroner GO erhaelt
  einen separaten Debugkontext. Die History ist hart auf acht begrenzt.
- Acht Topscopes, getrennte Feedback- und Activation-/Movementunterbereiche.
  Bereits vorhandene Light-UI-Messdicts und deren Buildcounts werden direkt
  uebernommen, bevor der spaetere Heavypass sie ersetzt. Keine neuen Quellen-
  oder Gameplaygetter, keine Aenderung an Ausfuehrungsreihenfolge/Returns.
- Debugaus loescht History, Debugstack und Sequenz; ohne aktiven Flag und
  laufenden GO erheben die Helper keine Zeitdaten. Der defensive Getter
  schreibt weder Quellen noch Gameplay. Verschachtelung ist explizit markiert.
- Controller-SHA256
  `bbf1c34762fc6b566e83a0000314f49d8bf49933b23b7237b669262c66bfe7eb`.
  `git diff --check` sauber. Keine Engine-/Gitaktion durch den Autor.
  Rootpruefung der Diagnose und neue native Befunde noch offen.
