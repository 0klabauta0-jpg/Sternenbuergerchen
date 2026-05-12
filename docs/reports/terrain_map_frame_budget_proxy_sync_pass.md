# TASK_332 - Terrain Map Frame Budget Proxy Sync Pass

## Ziel
Der Frame-Budget-Pass reduziert per-frame Arbeit in `TerrainMap3DView`, ohne Gameplay-Wahrheit, Fog-of-War, LOS, Dropship- oder Order-Semantik zu aendern. Es gibt bewusst keine Gameplay-Semantik-Aenderung; UI bleibt Konsument der vorhandenen Mission-/Simulation-Daten.

## Hotspots vorher
- Proxy-Sync: `_sync_unit_proxies()` bewegte Proxies zwar korrekt, zaehlte aber in jedem `_process()` alle schweren Diagnosefelder erneut: Asset-Modus, Animated-Model, AnimationPlayer, Socket-/Helmet-/Blaster-/Loadout-Status, Missing-Model und Enemy-Animated-Counter.
- Label/Badge: `_update_unit_status_badge()` gab fuer jedes sichtbare Badge `true` zurueck. Damit wurde ein sichtbares, aber unveraendertes Label wie eine Aenderung behandelt.
- Order-Visual-Signatur: `_build_order_visual_signature()` serialisierte den kompletten `order_payload` mit `var_to_str(order_payload)`. Das war robust, aber fuer groessere Plan-/Feedback-/Fire-Event-Payloads eine teure Vollserialisierung.
- Dynamische Order-Visuals: Der dynamische Refresh blieb zeitlich gedrosselt, hatte aber keine eigenen Profilpunkte fuer Refresh/Rebuild.

## Aenderung
- Proxy-Sync ist in schnelle frame-live Arbeit und schwere Dirty-Arbeit getrennt:
  - Bewegung/Rotation und Sichtbarkeit laufen weiter pro Frame.
  - Status-Badges werden pro Frame geprueft, erzeugen aber nur bei echter Text-/Farb-/Visibility-Aenderung einen Redraw-Grund.
  - Statische Diagnose-Counter laufen nur noch, wenn `_unit_proxy_static_diagnostics_dirty` gesetzt ist.
- Dirty-Ausloeser fuer statische Proxy-Diagnosen:
  - Force-Rebuild / `set_unit_nodes()`
  - Proxy-Erstellung oder Proxy-Entfernung
  - Team-Meta-Aenderung, weil sie den Enemy-Animated-Counter beeinflusst
  - `render_map()`, weil Map-/Fallback-Zaehler dort zurueckgesetzt werden
- Order-Visuals nutzen eine sortierte kompakte Signatur (`compact:v2`) mit Dictionary-Key-Counts, Array-Counts und stabil formatierten Scalar-/Vector-Werten. Identische Payloads werden weiter erkannt, aber ohne `var_to_str(order_payload)`.
- Der Render-Snapshot meldet neue lokale Profilpunkte:
  - `unit_proxy_last_sync_duration_usec`
  - `unit_proxy_static_diagnostic_refresh_count`
  - `unit_proxy_motion_sync_count`
  - `unit_proxy_visibility_sync_count`
  - `unit_proxy_status_badge_sync_count`
  - `unit_proxy_last_*_changed_count`
  - `order_visual_signature_mode`
  - `order_visual_rebuild_count`
  - `order_visual_signature_compact_count`
  - `order_dynamic_visual_refresh_count`
  - `order_dynamic_visual_rebuild_count`

## Nachher-Grenzen
- Pro Frame bleiben nur die visuell notwendigen Syncs aktiv: Position, Rotation, Sichtbarkeit, Animation und Badge-State.
- Schwere Counter-Updates sind nicht mehr an jedes `_process()` gekoppelt.
- Identische Order-Payloads werden weiterhin angewendet und im Snapshot gezaehlt, loesen aber keinen Order-Visual-Rebuild aus.
- Das SubViewport-Redraw-Fenster bleibt unveraendert; es bekommt nur weniger unnoetige Redraw-Anfragen aus unveraenderten Badges und statischen Diagnosezaehlungen.

## Lokale Mess-/Prueflogik
`scripts/tests/task_332_terrain_map_frame_budget_proxy_sync_pass.gd` prueft:
- Dokumentationsstatus und Report.
- Keine Vollserialisierung `var_to_str(order_payload)` im Order-Signaturpfad.
- Live-Mission erstellt Proxies und meldet kompakte Order-Signatur.
- Motion-/Visibility-/Badge-Sync-Zaehler steigen ueber mehrere Frames.
- `unit_proxy_static_diagnostic_refresh_count` bleibt ueber stabile Frames konstant.
- Dropship-Payload, Plan-/Area-Order, Fire-Sector und Clear-Payload bleiben sichtbar korrekt.
- Eine identische Order-Payload erhoeht den Signaturvergleich, aber nicht den Order-Visual-Rebuild.

Lokale Headless-Probe am 2026-05-12:
- Live-Mission: 10 Unit-Proxies.
- Nach stabilen Frames: Motion-/Visibility-/Badge-Sync-Zaehler liefen weiter (`36`), statische Diagnose-Refreshes blieben bei `3`.
- Letzte lokale Proxy-Sync-Dauer in den Proben: ca. `1.1-1.6 ms`.
- Identische Order-Payload: kompakte Signatur wurde erneut verglichen, `order_visual_rebuild_count` blieb stabil.

## Risiken
- Die kompakte Signatur bildet aktuelle Payload-Typen ab. Wenn spaeter Resource-/Object-Payloads in Order-Visuals landen, sollte `_append_order_signature_value()` explizit erweitert werden.
- Der Pass ist bewusst kein Renderer-/Instancing-Umbau. Wenn groessere Karten weiter Druck machen, sollte ein separater MultiMesh-/Overlay-Budget-Task folgen.
