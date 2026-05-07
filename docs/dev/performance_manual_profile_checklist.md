# Performance Manual Profile Checklist

Stand: 2026-05-06

## Ziel
Diese Checkliste ist fuer Godot 4.6 ausgerichtet und ergaenzt das TASK_222-Headless-Gate. Sie ersetzt keine automatischen Verifier; sie faengt GPU-, Visual- und Netzwerkverhalten ab, das headless nur grob sieht.

## Vorbereitung
- Projekt in Godot 4.6 mit fester 1920 x 1080 Viewportgroesse starten.
- Ein frischer Editorstart fuer Erstlade-/Pipeline-Stutter, danach ein zweiter Lauf fuer Warm-Cache-Vergleich.
- Szenen: Homebase, FOB, Live Mission 2.5D, Render Spike, Multiplayer Host/Join wenn verfuegbar.
- Werte mit Datum, Git-Stand und kurzer Hardware-Notiz dokumentieren.

## Godot Profiler
- Frame Time, Idle Time, Physics Time und Script Functions beobachten.
- Live Mission 2.5D fuer mindestens 30 Sekunden laufen lassen.
- Enemy-Taktik, Medic, Overwatch und Weapon-Fire-Events aktivieren.
- Auffaellige Spikes mit Szene, Aktion und Zeit notieren.

## Visual Profiler
- Live Mission und Render Spike bei gleicher Viewportgroesse messen.
- Draw Calls, Object Count, Material-/Surface-Spitzen und Transparenz beobachten.
- Comic-Bubbles, Muzzle-Flashes und Dropship/Flightdeck separat einmalig ausloesen.
- Keine Bewertung nach einem einzelnen Frame; wiederholbare Muster suchen.

## Monitors
- FPS, Frame Time, Physics Time, Static/Message Memory, Object Count, Node Count und Orphan Count notieren.
- Pipeline-Compilation-Monitore beim ersten Anzeigen von Units, Assets, Bubbles und VFX beobachten.
- Orphan-/Object-Anstieg nach Szenenwechseln pruefen.

## Video RAM
- Video RAM Tab nach Homebase, FOB, Live Mission und Render Spike vergleichen.
- Grosse PNGs, Comic-Bubbles, Muzzle-Flash-Texturen und GLB-Materialvarianten als Kandidaten markieren.
- Keine Importkompression anwenden, bevor sichtbare Pixel-/Comic-Qualitaet geprueft wurde.

## Network Profiler
- Zwei lokale Instanzen starten, Host/Join, Ready, Mission starten.
- State-Snapshot-Frequenz, Payloadgroesse und Fire-/Bubble-Events beobachten.
- Client-Apply darf keine Commands oder Effects erzeugen.
- Wenn Payloads auffaellig wachsen: erst Report erstellen, dann Delta-/Event-Kandidaten scharf schneiden.

## Stutter-Test
- Erstmaliges Anzeigen von Weapon-Fire-VFX, Comic-Bubbles, Dropship/Fighter/Flightdeck-Assets und neuen GLBs einzeln ausloesen.
- Sichtbare Hitches mit Szene und Asset-ID notieren.
- Warmup nur verdeckt und ohne Gameplay-Event einfuehren.

## Abschluss
- Headless TASK_222-Gate laufen lassen.
- TASK_170-Warning-Gate laufen lassen.
- Manuelle Auffaelligkeiten in `docs/performance/...` oder der passenden Taskdatei dokumentieren, bevor Budgets geaendert werden.
