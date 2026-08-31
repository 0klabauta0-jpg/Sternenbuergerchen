# TASK_1201 - FOW Stability (P06)

## Status

`VERIFIED_NO_CODE`: aktuelle Messvarianz bestaetigt den FoW-Gate-Stand; keine Produktionsaenderung.

## Ziel / No-Code-Entscheid

Die unveraenderte P05-Produktion wird gegen den FoW-Budgetbefund erneut gemessen. Die aktuelle Serie auf `f657ad68860d9ccb9be7ebb1f85ec1a2bae29060` besteht in 8/8 mit `terrain.fow_work_usec <= 2000`; P06.2-P06.6 werden gemaess Masterplan uebersprungen. Ein frueherer P05-Befund mit 8/8 ueber 2 ms wird als historische Mess-Evidence transparent gehalten, nicht als Codefehler interpretiert.

## Scope / Nichtziele

- Keine Runtime-, Test-, Phaseninstrumentierungs- oder Dokumentationsaenderung ausser dieser Evidence-Kapsel.
- Dirty Regions, bounded slices, atomic publish und Full-Scan-Oracle bleiben unveraendert.
- Renderer bleibt read-only und nicht Gameplay-Truth.
- Kein Release-GO und keine TASK-1193-Manuell-Evidence.

## Evidence

- Basis/Mess-SHA: `f657ad68860d9ccb9be7ebb1f85ec1a2bae29060`; Godot 4.6.2 official; Ryzen 7 7800X3D, 64 GB, Windows 10 19045.
- 3-cold/5-warm Frames `[6564,6510,6480,6573,6546,6448,6540,6595]`; Dauer `[145042,145750,145238,141692,141887,143166,140893,141255]` ms.
- FoW p50 `[1261,1264,1401,1621,1176,1219,1225,1193]` usec; p95/p99/max `[1653,1638,1679,1913,1909,1810,1863,1978]` usec; Status 8/8 PASS, alle `<=2000`. Dynamic p99: 2 usec in 8/8.
- Proxy p95 `[2480,2659,2624,2615,2523,2570,2559,2431]`, p99 `[2921,3083,3089,3117,3117,3110,3153,3010]` usec.
- Direkte Vertraege: TASK-1189 25/25 (128x128 und 256x256 Dirty-/Bounded-/Atomic-/Oracle-Pfade, geschaetzte Stalenzwerte jeweils 350.00 ms <=350), TASK-224 25/25, TASK-225 34/34, TASK-1188 31/31 mit 8696 Frames/60004 ms und Proxy p99 4817 usec <=8 ms.
- Produktionsstand unveraendert gegen P05: `git diff d319e3c...f657ad6 -- scripts data scenes project.godot` ist leer.

## Messgrenzen und Entscheidung

Waerend der Serie liefen fremde aktive `housing_medium_placement_smoke_test`-Prozesse; sie wurden nicht beendet. Die Serie passierte konservativ 8/8, ist aber keine freie Exklusivlast. Ein transienter native exit `-1` ohne JSON bei gleichzeitigem fremdem Godot-Lauf war ausschliesslich ein historischer P05/TASK-1200-Cold-Versuch und nicht Teil der aktuellen P06-Serie; in P06 gab es keine verworfenen oder wiederholten gueltigen Laeufe. Die fruehere P05-Serie hatte FoW 8/8 rot (`[2073,2047,2286,2766,2198,2447,2149,2411]`), die aktuelle Serie ist daher aktuelle Gate-Evidence und Messvarianz, nicht ein stiller Fix.

## Folge / Release

P06 ist `VERIFIED_NO_CODE`; Release bleibt blockiert und TASK-1193 echte 128x128-FullHD-Manuell-Evidence fehlt weiterhin. Naechster Schritt ist TASK-1202/P07 als integrierter automatischer Release-Gate-/Reparaturschleifen-Slice.
