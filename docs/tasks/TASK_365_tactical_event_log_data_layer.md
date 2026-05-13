# TASK_365 - Tactical Event Log Data Layer

## Ziel
Ein read-only Datenmodell fuer ein taktisches Missionsereignis-Log einfuehren, das bestehende `TacticalCommunicationEvent`- und Mission-Feedback-Ereignisse als chronologische Historie bereitstellt.

## Status: GEPLANT

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
- [ ] Event-Log uebernimmt bestehende tactical communication events ohne Payload-Mutation.
- [ ] Gleiche Event-ID wird nicht mehrfach in die Historie geschrieben.
- [ ] Severity wird aus bestehender Prioritaet/Kategorie deterministisch abgeleitet.
- [ ] History bleibt bounded und sortierbar nach Erstellzeit.
- [ ] Headless-Test prueft Contact, Cannot Execute und Air Asset Threat als Logeintraege.

## Erwartete Dateien
- `scripts/tactical/tactical_event_log.gd`
- `scripts/tactical/tactical_communication_event.gd`
- `scripts/tactical/tactical_communication_resolver.gd`
- `scripts/tests/task_365_tactical_event_log_data_layer.gd`

## Lokale Pruefung
- [ ] `godot_console.exe --headless --path . --script scripts/tests/task_365_tactical_event_log_data_layer.gd`
- [ ] `godot_console.exe --headless --path . --script scripts/tests/task_274_tactical_communication_feedback_layer.gd`
- [ ] `git diff --check`

## Risiken / offene Punkte
- Das Log darf keine zweite EventRouter-Wahrheit werden. Es ist eine Anzeigehistorie ueber bereits vorhandene Ereignisse.
- Kampf-/Schadensereignisse duerfen nur geloggt werden, wenn sie aus autoritativen Effects/Snapshots kommen.

