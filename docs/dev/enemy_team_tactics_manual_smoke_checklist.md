# TASK_208 Enemy Team Tactics Manual Smoke Checklist

Diese Checkliste ergaenzt den Headless-Smoke. Sie ersetzt nicht die Einzelverifier aus TASK_200 bis TASK_207.

## Setup
- Mission/Fixture: `res://maps/enemy_tactics_smoke_32x32.json`
- Gegnergruppen: `red_hold`, `red_cover`, `red_push`
- Erwartete Anzeige: Friendly weiss, Enemy orange

## 2.5D Sichtcheck
- Direction: Enemy-Security-Arcs zeigen klar in die konfigurierte Richtung; `red_hold` zeigt als 360/Hold, `red_push` nach Westen in Richtung Friendly.
- Cover: `red_cover` nutzt die sichtbaren Cover-Tiles bei der Hoehe/Rampe und zeigt ein `BND`/Bounding-Taktiklabel.
- Range: SMG wirkt nicht wie eine Sniper-Waffe; Rifle/Sniper-Reichweiten bleiben sichtbar groesser als SMG.
- Advance: `red_push` erzeugt mehrere Bewegungsziele, waehrend `red_hold` stehen bleibt.
- Mindestabstand: Friendly- und Enemy-Marker liegen nicht ineinander; Push-/Cover-Zielpunkte stapeln nicht auf demselben Tile.
- VFX: Friendly- und Enemy-Schuss zeigen je genau einen Muzzle-Flash am Angreifer.
- Visuals: Enemy-Suits sind orange und gegen Friendly-Weiss klar unterscheidbar.
- Badges: Mindestens eine Mission-/FOB-Kompaktkarte zeigt abgeleitete Rank-/Skill-Badges.
- Multiplayer Viewer: Snapshot-Anwendung spiegelt Security, Tactics und Fire-Events, ohne neue Enemy-Kommandos oder Damage-Effects auf Clientseite zu erzeugen.

## Abbruchkriterien
- Gegner-Facing ist nicht erkennbar oder zeigt gegen die Profilrichtung.
- Orange Enemy-Archetyp faellt auf Friendly-Weiss zurueck.
- Muzzle-Flash fehlt oder verdoppelt sich pro Fire-Event.
- Client-/Viewer-Pfad erzeugt eigene Enemy-Bewegungen, Damage-Effects oder Reichweitenentscheidungen.
