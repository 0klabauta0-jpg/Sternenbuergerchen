# TASK 050 – Server-autoritativer SimulationRoot

## Ziel
`SimulationRoot` wird so vorbereitet, dass er als Single-Source-of-Truth ueber RPC funktionieren kann: Kommandos werden vom Client gesendet, aber nur der Server/Host fuehrt sie aus.

## Pflicht vor Beginn
- Lies `docs/PROJECT_BRIEF.md`
- Lies `docs/ARCHITECTURE.md`
- Lies `docs/CODEX_RULES.md`
- Lies `docs/IMPLEMENTATION_STATUS.md`
- Pruefe den Git-Status

## Ist-Zustand
- `SimulationRoot` laeuft rein lokal in `_physics_process()`.
- Commands und Effects werden direkt per `enqueue_command()` / `enqueue_effect()` eingefuegt.
- Es gibt keine Netzwerk-Schicht, keine RPC-Annotation und keine Authority-Checks.
- Godot 4 Multiplayer-API (MultiplayerPeer, MultiplayerSpawner/Synchronizer) ist nicht eingebunden.

## Aufgabe

### 1. Multiplayer-Authority auf SimulationRoot
- `SimulationRoot` erhaelt `@export var is_server_authoritative: bool = false`.
- Wenn `is_server_authoritative == true`:
  - Nur der Server (Authority 1) darf `_process_commands()` und `_process_effects()` ausfuehren.
  - Clients koennen Commands nur ueber eine RPC-Methode einspeisen.

### 2. RPC-Methode fuer Commands
- Neue Methode `request_command(command_dict: Dictionary) -> void` mit `@rpc("any_peer", "reliable")`.
- Server validiert den Command (Typ-Check, Team-Check) und enqueued ihn bei Erfolg.
- Lokaler Fallback: wenn `is_server_authoritative == false`, funktioniert `enqueue_command()` wie bisher.

### 3. State-Broadcast vorbereiten
- Neue Methode `_broadcast_tick_state() -> void` die nach jedem Tick ein Dictionary mit dem aktuellen Zustand (Unit-Positionen, Vital-Status) an alle Peers sendet.
- `@rpc("authority", "unreliable")` fuer Position-Updates, `@rpc("authority", "reliable")` fuer Vital-Status-Aenderungen.
- Empfangende Clients speichern den letzten Server-State, wenden ihn aber noch nicht an (das folgt in TASK_053).

### 4. Bestehenden Singleplayer-Pfad nicht brechen
- Wenn kein `MultiplayerPeer` aktiv ist oder `is_server_authoritative == false`: alles funktioniert wie bisher.
- Kein Autoload, kein erzwungener Netzwerk-Setup.

## Nicht-Ziele
- keine Client-Verbindungslogik (folgt in TASK_051)
- keine UI-Anpassung
- kein Lobby-System
- keine Latenz-Kompensation
- kein Client-Side-Prediction

## Akzeptanzkriterien
- `SimulationRoot` hat RPC-faehige Methoden fuer Command-Einspeisung und State-Broadcast
- Im Singleplayer-Modus laeuft alles wie bisher
- Authority-Check verhindert, dass Clients lokal Commands ausfuehren
- Code kompiliert und Godot startet ohne Fehler

## Git-Schritte nach lokaler Pruefung
- `git status`
- `git add` nur relevante Dateien
- `git commit -m "Prepare SimulationRoot for server-authoritative multiplayer (TASK_050)"`
- `git push`
- `docs/IMPLEMENTATION_STATUS.md` aktualisieren
