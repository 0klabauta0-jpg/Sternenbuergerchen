# Visual Scale Alignment Checklist

Datum: 2026-05-07
Status: TASK_246 manuelle Sichtpruefung vorbereitet

## Vorbereitung
- Godot-Projekt im Editor oeffnen und `godot_console.exe --headless --path . --import` bei Bedarf vorher laufen lassen.
- Headless-Verifier `scripts/tests/task_246_visual_scale_alignment_asset_pass_verifier.gd` muss gruen sein.
- Als Referenz die Matrix `docs/reviews/asset_scale_alignment_matrix.md` offen halten.

## NPCs und Attachments
- [ ] Friendly Space Suit White und Enemy Space Suit Orange bei 100% Zoom auf Tile-/Cover-Groesse pruefen.
- [ ] Astro- und Military-Helmet sitzen sichtbar auf dem Kopf, nicht in Hals, Boden oder Ruecken.
- [ ] Standard-/Compact-/Medic-/Heavy-Blaster sitzen an der rechten Hand und verdecken den Koerper nicht.
- [ ] Sniper-Lauf ist als lange Waffe erkennbar, aber nicht groesser als der NPC.
- [ ] Rocket Launcher sitzt am BackSocket und beruehrt weder Boden noch Helm.

## VFX und Audio-Anker
- [ ] Rifle/SMG/Sniper/Rocket-Schuss erzeugt Muzzle-Flash am Lauf, nicht im Unit-Zentrum.
- [ ] Trace-Linie, Muzzle-Flash und Schuss-Sound wirken auf derselben sichtbaren Hoehe.
- [ ] Impact/Explosion folgt dem Trefferkontext und spielt nicht fuer versteckte oder doppelte Events mehrfach laut.
- [ ] Huegel oder Klippen verschieben Muzzle-Flash/Trace nicht unter die Oberflaeche.

## Backgrounds und feste Fenster
- [ ] Main Menu bei 1920x1080: linke Rail bleibt lesbar, Background-Crop verschiebt keine Controls.
- [ ] Multiplayer-Lobby bei 1280x720: Panel bleibt 720x560 mittig und der Hangar liegt hinter Dimming.
- [ ] Vorbereitete Mission-/Loading-/Debrief-Backgrounds in der Vorschau pruefen: wichtige Motive liegen ausserhalb typischer Panelzonen.
- [ ] Dimming wirkt lesbar, aber nicht komplett schwarz.

## Ergebnis
- [ ] Auffaellige Scale-/Offset-Probleme als separaten Folge-Task notieren.
- [ ] Keine Gameplay-Fixes in diesem Sichtcheck vornehmen.
- [ ] Ergebnis kurz in Review, Task-Kommentar oder Commit-Notiz festhalten.
