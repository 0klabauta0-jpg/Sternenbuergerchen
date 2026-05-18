# TASK 473: Fireteam Combat Feedback Runtime Overhaul

## Ziel / Problem

Im Fireteam-Drill ist der sichtbare Combat-Pfad noch schwer verstaendlich: Units schiessen scheinbar, aber Treffer/Down-State werden zu selten sichtbar, Suppression wirkt wie ein Befehlskonflikt, #16 flackert zwischen Command Matrix und Ad-hoc-Panel, #17 zeigt zu viele kryptische Runtime-Kuerzel, und Muzzle-/Impact-Feedback ist nicht eindeutig genug.

## Sinnhaftigkeit / Ursache

Der aktuelle Pfad mischt mehrere Dinge zu eng:

- `SimulationRoot` berechnet Treffer, meldet aber kein autoritatives Hit/Miss-Ergebnis an den Combat-Feedback-Pfad.
- Cover-Werte werden als Rohwerte in Treffer-/Schadensfaktoren benutzt, obwohl sie als Score/Prozentwert gedacht sind.
- Light-Suppression unterbricht Plan-/Movement-Ausfuehrung wie ein harter Pinned-Zustand und kann dadurch neue Befehle sofort wieder ueberlagern.
- Das Ad-hoc-Panel wird allein durch Combat-Kontakt sichtbar und ueberdeckt dadurch #16.
- #17 liest zwar Runtime-State, laesst aber die Ursache fuer Feuerstatus, Suppression und Kontakt noch zu roh erscheinen.

## Umfang

- Treffer-/Schadensrechnung in `SimulationRoot` normalisieren und ein autoritatives Combat-Outcome-Signal fuer Hit/Miss/Down-relevante Werte bereitstellen.
- CombatLoop-Fire-Events mit dem autoritativen Outcome anreichern, damit Visuals und Diagnosen nicht nur "Schuss versucht", sondern auch "Hit/Miss/Damage" sehen.
- Suppression in Light/Heavy trennen: Light-Suppression beeinflusst Bewegung, Aim/Fire-Qualitaet und Lesbarkeit, bricht aber den Befehl nicht hart ab; Heavy-Suppression bleibt der echte Pinned-/Interrupt-Fall.
- #16 Command Matrix screenshot-stabil halten; Ad-hoc/Return-to-Plan nur bei echter Recovery-/Ad-hoc-Lage anzeigen, nicht bei jedem Kontakt-Tick.
- #17 Header und Karten erklaerender machen: volle Stance-/Command-Texte, Suppression als Zustand, Feuerstatus/Bewegungsgrund lesbarer.
- Muzzle-/Impact-VFX kleiner, eindeutiger und gecappt darstellen: kurzer gelber Muzzle-Impuls, rote Feuerlinie, kleiner Impact-Marker am Ziel.

## Nicht-Ziele

- Keine finale Trefferbalance fuer alle Waffen.
- Keine neue Flank-Logik.
- Kein finaler Behavior-Tree-/Limbo-Umbau.
- Keine komplette HUD-Neugestaltung ausser #16/#17 und Combat-Feedback.

## Relevante Contracts / Dokumente

- `docs/dev/fireteam_behavior_modes_contract.md`
- `docs/dev/html_report_workbench_contract.md`
- `docs/ARCHITECTURE.md`
- `docs/tasks/TASK_471_fireteam_weapon_fire_vfx_hit_feedback_perf.md`
- `docs/tasks/TASK_472_fireteam_contact_perf_bubble_card_readability.md`

## Akzeptanzkriterien

- Cover-Score 20 reduziert Treffer/Schaden moderat statt Trefferchance dauerhaft auf Minimum zu klemmen.
- `SimulationRoot` liefert pro Damage-Effect ein lesbares Outcome fuer Hit/Miss, finale Trefferchance, Roll, Cover-Rohwerte und normalisierte Coverwerte.
- Fire-Events enthalten nach dem autoritativen Resolve `outcome`, `hit_chance_resolved`, `roll`, `damage_resolved` und bleiben fuer VFX/Diagnose abfragbar.
- Light-Suppression setzt keinen sofortigen Plan-Interrupt und blockiert `fire_at_will` nicht komplett; Heavy-Suppression bleibt als Pinned/Interrupt sichtbar.
- #16 bleibt im normalen Fire/Contact-Pfad die Command Matrix und wird nicht durch Ad-hoc-Flaechen geflackert.
- #17 zeigt lesbare Command-/Stance-/Suppressionstexte und laesst Kartenbreite stabil.
- Weapon-Fire-VFX erzeugt keinen grossen gelben Wand-Flash, sondern kleine Muzzle-/Impact-Hinweise.

## Betroffene Dateien

- `scripts/core/simulation_root.gd`
- `scripts/tests/mission_combat_loop_driver.gd`
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/terrain/terrain_map_3d_view.gd`
- `scripts/meta/npc_compact_card.gd`
- `scripts/tests/task_473_fireteam_combat_feedback_runtime_overhaul.gd`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`

## Lokale Pruefung

- `godot_console.exe --headless --path . --script scripts/tests/task_473_fireteam_combat_feedback_runtime_overhaul.gd`
- Relevante Regressionen aus TASK_471/TASK_472.
- `git diff --check`.

## Risiken / offene Punkte

- Die neue Outcome-Kopplung klaert Hit/Miss, ersetzt aber keine spaetere Balancing-Runde fuer Waffen, Skills und Suppression.
- Heavy-Suppression kann weiterhin Befehle unterbrechen; ob das spaeter Skill-/Leadership-abhaengig wird, bleibt ein Folgepass.
- #17 bleibt ein kompaktes Debug-HUD. Eine final gute Taktik-UI braucht spaeter einen eigenen UX-Schnitt.
