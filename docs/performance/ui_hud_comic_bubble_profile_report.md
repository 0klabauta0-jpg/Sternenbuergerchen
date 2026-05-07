# TASK_219 UI HUD Comic Bubble Profile Report

Stand: 2026-05-06

## Ziel
Dieser Bericht bewertet Homebase, FOB, Mission-HUD, Main Menu und Comic-Bubbles auf UI-Kosten. Der Task ist ein Mess- und Diagnose-Slice; er fuehrt kein neues UI-Design ein und lockert keine festen Drop-Light-Fenster.

## Screen-Matrix
`scripts/tests/ui_hud_comic_bubble_performance_harness.gd` zaehlt pro Screen:

- `node_count`
- `control_count`
- `visible_control_count`
- `label_count`
- `rich_text_label_count`
- `texture_rect_count`
- `button_count`
- `panel_container_count`
- `scroll_container_count`
- `max_depth`

Gemessen werden Homebase, FOB, Mission-HUD und Main Menu bei der festen Drop-Light-Zielgroesse.

## Theme-Reuse
`TacticalUITheme.build_flat_stylebox()` nutzt jetzt einen kleinen Cache fuer identische `StyleBoxFlat`-Parameter. Der Verifier prueft, dass gleiche Parameter dieselbe Instanz wiederverwenden und andere Parameter getrennte StyleBoxes bleiben.

Das reduziert wiederholte StyleBox-Erzeugung bei dichtem HUD-/Meta-Styling, ohne den Theme-Vertrag zu aendern.

## Comic-Bubbles
`ComicBubbleRuntimeGate.build_filter_performance_snapshot()` liefert einen read-only Probe-Snapshot fuer:

- Eingehende Payloads.
- Emittierte Payloads.
- Rejections.
- Cooldown-Key-Anzahl vor/nach/restored.
- Filterzeit in Mikrosekunden.
- Modus und Maximalzahl.

Der Probe-Snapshot stellt den Cooldown-State nach der Messung wieder her. Die echte Runtime-Filterung bleibt unveraendert.

## Bubble-Budgets
Der Harness prueft:

- `off`: null sichtbare Bubble-Nodes.
- `minimal`: nur wichtige Payloads kommen durch.
- `normal`: durch `max_active_bubbles_total` gedeckelt.
- `thought_hidden`: Hold ist aus, also keine dauerhaften Thought-Bubbles.
- `thought_hold`: Hold erzeugt begrenzte Thought-Bubbles.

Die 2.5D-Renderprobe nutzt `TerrainMap3DView.get_render_snapshot()` und zaehlt `feedback_bubble_visual_count` sowie Transparenzbudget.

## Fixed Window
Die Screen-Matrix laeuft bei `DropLightLayoutContract.TARGET_VIEWPORT`. TASK_181 bleibt der strengere Rect-/Scroll-Contract; TASK_219 prueft zusaetzlich, dass die Performance-Matrix keine variable Hauptfenstergroesse braucht.

## Risiken
- StyleBox-Reuse setzt voraus, dass die gecachten StyleBoxes nicht nachtraeglich pro Control mutiert werden.
- Zu starkes Bubble-Pooling waere aktuell voreilig. Der Task zaehlt erst und begrenzt per bestehendem Gate.
- Headless-Control-Zaehler ersetzen keinen manuellen Profiler-Lauf fuer echte Text-/Font-/GPU-Kosten.
