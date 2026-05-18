# TASK_471 - Fireteam Weapon Fire VFX Hit Feedback Perf

## Ziel / Problem
Im Fireteam-F6-Drill entstehen jetzt Contact-Fire-Events, aber der sichtbare Muzzleflash ist viel zu gross, steht falsch im Raum und bricht bei mehreren Schuessen die Performance ein. Gleichzeitig ist nicht gut lesbar, ob Gegner getroffen werden oder in den Down-State fallen.

## Sinnhaftigkeit / Ursache
Der aktuelle 3D-Visualpfad zieht die Muzzle-Textur auf eine grosse Mindestgroesse hoch und rendert sie als feste Texture-Card. Dadurch wird aus einem kurzen Muzzleflash im Kamerawinkel eine riesige gelbe Flaeche. Mehrere Fire-Events koennen parallel alte Flash-/Trace-Geometrie erzeugen. Damage existiert datenbasiert, wird am 3D-Proxy aber noch nicht deutlich genug als Hit-/Down-Feedback dargestellt.

## Umfang
- Weapon-Fire-VFX im 3D-View auf kurze gelbe, gerichtete Muzzle-Impulse und duennere Traces begrenzen.
- Grosse Texture-Card-Muzzleflashes im Drill-Visualpfad unterdruecken, bis ein gerichteter Sprite-/Particle-Pfad sauber gebaut ist.
- Anzahl gleichzeitig gerenderter Weapon-Fire-Events begrenzen.
- Unit-Proxies mit sichtbarer Hit-/HP-Diagnose und Down-Pose versehen.
- Bestehende VFX-Regressionen auf die neue kleinere Baseline aktualisieren.

## Nicht-Ziele
- Kein neues Combat-Damage-Modell.
- Keine finale Death-/Ragdoll-Animation.
- Keine Aenderung der Fireteam-Entscheidungslogik fuer Engage/Defend.
- Keine neue Enemy-KI oder Patrol-Logik.

## Relevante Contracts / Dokumente
- `docs/ARCHITECTURE.md`
- `docs/dev/fireteam_behavior_modes_contract.md`
- `docs/tasks/TASK_470_fireteam_combatloop_unit_bridge_recovery.md`
- `docs/tasks/TASK_466_fireteam_live_defend_contact_fire_damage.md`

## Akzeptanzkriterien
- Muzzleflash wird als kleiner gelber Impuls nahe der Waffe sichtbar, nicht als grosse stehende Flaeche.
- Alte Fire-Events werden visuell begrenzt, damit ein Feuerwechsel nicht unbounded Geometrie aufbaut.
- Fire-Event-Snapshots melden, dass die Texturkarte absichtlich unterdrueckt ist, aber Flash/Bloom/Trace sichtbar bleiben.
- Fit-Units mit erhaltenem Damage zeigen am 3D-Proxy eine HP-/Hit-Diagnose.
- Down-/Bleedout-Units haben einen sichtbaren Down-Visualzustand im 3D-Proxy-Snapshot.

## Betroffene Dateien
- `scripts/terrain/terrain_map_3d_view.gd`
- `scripts/tests/task_471_fireteam_weapon_fire_vfx_hit_feedback_perf.gd`
- vorhandene VFX-Regressionstests
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_471_fireteam_weapon_fire_vfx_hit_feedback_perf.gd`
- relevante Regressionen: TASK_432, TASK_435, TASK_436, TASK_438, TASK_461, TASK_466, TASK_470
- `git diff --check`

## Risiken / offene Punkte
- Die Loesung ist bewusst ein lesbarer Debug-/Prototype-Muzzleflash. Ein finaler gerichteter Particle- oder Mesh-Muzzleflash bleibt spaeter moeglich.
- Down-Visual ist ein klarer Proxy-Zustand, keine fertige Character-Death-Animation.
