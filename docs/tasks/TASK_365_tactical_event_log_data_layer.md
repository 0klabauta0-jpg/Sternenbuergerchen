# TASK_365 - Tactical Event Log Data Layer

## Ziel
Ein read-only Datenmodell fuer ein taktisches Missionsereignis-Log einfuehren, das bestehende `TacticalCommunicationEvent`- und Mission-Feedback-Ereignisse als chronologische Historie bereitstellt.

## Status: IMPLEMENTIERT

## Sinnhaftigkeitscheck
Der Review-Punkt ist sinnvoll, weil Comms-Bubbles und kurze HUD-Texte schnell verschwinden. Das Projekt besitzt mit `TacticalCommunicationEvent` und `TacticalCommunicationResolver` bereits passende Ereignisquellen. Deshalb braucht es keinen neuen Simulationskanal, sondern einen bounded History-Adapter.

## Problem
Wichtige Ereignisse wie Contact, Cannot Execute, Air Asset Threat, Objective Progress oder Bounding Rotation sind sichtbar, aber nicht persistent nachlesbar.

## Ursache
Der aktuelle Feedback-Pfad priorisiert direkte Anzeige in #17/#18, Map-Markern und Bubbles. Es gibt noch keine kleine, begrenzte Ereignishistorie fuer das HUD.

## Umfang
- `TacticalEventLog` oder vergleichbaren RefCounted-Adapter einfuehren.
- Bestehende tactical communication snapshots normalisieren: Zeit, Kategorie, Fireteam, Severity, Kurztext, Event-ID.
- Bounded History mit stabiler Maximalgroesse, z. B. letzte 100 Ereignisse.
- Dedupe ueber bestehende Event-IDs und Cooldown-Schluessel.
- Keine neuen SimulationRoot-Signale fuer reine UI-Ereignisse erfinden, solange bestehende Feedback-Snapshots reichen.

## Akzeptanzkriterien
- [x] Event-Log uebernimmt bestehende tactical communication events ohne Payload-Mutation.
- [x] Gleiche Event-ID wird nicht mehrfach in die Historie geschrieben.
- [x] Severity wird aus bestehender Prioritaet/Kategorie deterministisch abgeleitet.
- [x] History bleibt bounded und sortierbar nach Erstellzeit.
- [x] Headless-Test prueft Contact, Cannot Execute und Air Asset Threat als Logeintraege.

## Umsetzung
- `TacticalEventLog` ist ein `RefCounted`-Adapter fuer bestehende `TacticalCommunicationEvent`-Snapshots. Er normalisiert Event-ID, Zeit, Kategorie, Fireteam, Severity, Kurztext, Channels und Positionsanker fuer eine reine Anzeigehistorie.
- Die History ist standardmaessig auf 100 Eintraege begrenzt, dedupliziert stabile Event-IDs und kann newest-first oder oldest-first gelesen werden.
- `mission_tactical_sandbox_controller.gd` speist den Adapter aus dem bestehenden Tactical-Communication-Speicher und exposed `tactical_event_log`, `tactical_event_log_count` und `tactical_event_log_contract` im Feedback-Snapshot.
- Der Verifier prueft Contact, Cannot Execute, Air Asset Threat, Bounded History, unveraenderte Eingabe-Payloads und dass der Log-Snapshot keine `SimulationRoot` Commands oder Effects erzeugt.

## Erwartete Dateien
- `scripts/tactical/tactical_event_log.gd`
- `scripts/tactical/tactical_communication_event.gd`
- `scripts/tactical/tactical_communication_resolver.gd`
- `scripts/tests/task_365_tactical_event_log_data_layer.gd`

## Lokale Pruefung
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_365_tactical_event_log_data_layer.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_274_tactical_communication_feedback_layer.gd`
- [x] `git diff --check`

## Risiken / offene Punkte
- Das Log ist bewusst keine zweite EventRouter-Wahrheit, sondern nur eine read-only History ueber bereits vorhandene Tactical-Communication-Snapshots.
- Kampf-/Schadensereignisse duerfen weiterhin nur aufgenommen werden, wenn sie spaeter als autoritative Effects/Snapshots in den bestehenden Communication-Pfad gelangen.
