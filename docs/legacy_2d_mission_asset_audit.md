# Legacy 2D Mission Asset Audit

## Stand
`TASK_150` degradiert die alte 2D-Missionsdarstellung zum Compare-/Debug-/Fallbackpfad. Es werden keine 2D-Assets geloescht, weil Editor, UI, Tests und historische Vergleichsansichten sie weiterhin brauchen.

## Normaler Live-Missionspfad
- `MapRoot` bleibt als 2D-Fallback und als Quelle fuer bestehende Markerpfade erhalten, ist aber im primaeren 3D-Missionsbild verborgen.
- Direkte Unit-Canvas-Visuals wie `UnitAlpha/Visual` bleiben an den autoritativen `Node2D`-Units haengen, werden im primaeren 3D-Modus aber verborgen. Die sichtbare Unit-Darstellung kommt aus `Mission25DVisualBridge/RuntimeVisual3D`.
- 2D-Missionsoverlays wie `TargetMarker/TargetVisual`, `LZMarker`, `DropshipPlanMarker`, `FireteamOrderVisualizer` und `ContactMapOverlay` bleiben als Daten-/Fallbackpfad erhalten, werden im primaeren 3D-Modus aber kontrolliert ausgeblendet.

## Bewusst erhaltene 2D-Nutzung
- Map-Editor und Terrain-Editor-Preview verwenden weiterhin 2D-Sprites.
- UI, Karten, Portraits, Transporter-/Loadout-Darstellung und Debug-Fallbacks duerfen 2D-Texturen weiter laden.
- Die alte 2D-Map bleibt per `set_2d_fallback_visible(true)` als Compare-Ansicht verfuegbar.

## Nicht loeschen
- `res://Assets/kenney_space-kit/Isometric/...`
- `res://scenes/maps/iso_map_v2_layout.tscn`
- direkte Unit-`Visual`-Children in der Mission, solange der 2D-Fallback und alte Tests sie noch brauchen.

## Spaeter pruefen
- Nach dem ersten Gameloop-Smoke-Test kann entschieden werden, ob einzelne 2D-Missionsoverlays komplett durch 3D- oder UI-Visuals ersetzt werden.
- Erst wenn Editor, UI und Fallback keine konkreten Pfade mehr nutzen, sollte ein echter Asset-Loesch-Task geschnitten werden.
