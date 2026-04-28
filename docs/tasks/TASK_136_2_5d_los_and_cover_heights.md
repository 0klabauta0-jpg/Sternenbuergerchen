# TASK_136 - 2.5D LOS und Cover Heights

## Ziel
LOS und Cover so erweitern, dass Hoehenwerte aus TASK_135 beruecksichtigt werden: Sicht und Beschuss laufen weiter datenbasiert, koennen aber Auge, Zielhoehe, niedrige Deckung, hohe Deckung und volle Blocker unterscheiden.

## Status: IMPLEMENTIERT

## Kontext
- Aktuelle LOS-/Cover-Logik arbeitet grid- und terrainbasiert, aber noch ohne echte Hoeheninterpretation.
- 2.5D soll taktische Vorteile wie Dachpositionen, Mauern, Graben und niedrige Deckung ermoeglichen, ohne Ballistik oder Full-3D-Physik einzufuehren.

## Umfang
1. Kleinen `HeightAwareLOSResolver` oder Erweiterung am bestehenden LOS-Pfad einfuehren.
2. Sichtlinie als Verbindung von `eye_height` zu `target_height` auswerten.
3. Terrain-Samples entlang der Linie gegen `blocks_los_height` pruefen.
4. Cover-Auswertung um `cover_height` und relative Hoehenlage erweitern:
   - niedrige Deckung
   - hohe Deckung
   - voller Sichtblocker
   - Hoehenvorteil reduziert bestimmte Coverwirkung
5. Debug-/Test-Snapshots fuer blockierendes Grid und Hoehenwerte liefern.

## Nicht-Ziele
- Keine echte Projektilphysik.
- Keine Durchschlags- oder Materialsimulation.
- Keine Multi-Floor-Auswahl.
- Keine neue Combat-Damage-Formel ausser Cover-/LOS-Modifiern.

## Akzeptanzkriterien
- [x] Eine niedrige Mauer blockt nicht automatisch jede Sichtlinie.
- [x] Ein hoher Blocker unterbricht LOS nachvollziehbar.
- [x] Eine erhoehte Unit kann ueber niedrige Deckung hinweg sehen.
- [x] Cover-Modifier enthalten Hoehen- und Coverhoehen-Anteil.
- [x] Verifier prueft Boden-vs-Boden, oben-vs-unten und Blocker-Faelle.

## Lokale Pruefung
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_136_verifier.gd`

## Risiken
- Zu viele Sonderfaelle koennen Combat unlesbar machen; die V1-Regeln muessen einfach und gut debugbar bleiben.
- Hoehenvorteil darf Deckung nicht komplett entwerten, sonst verlieren Area-/Defend-Orders ihren Nutzen.
