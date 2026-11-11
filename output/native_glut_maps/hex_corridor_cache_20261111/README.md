# Kleine Hex-Korridorcache-Fixture

Im Root dieses Worktrees ausfuehren:

`python output/native_glut_maps/hex_corridor_cache_20261111/run_private_check.py`

Der Reproducer kopiert ausschliesslich den Verifier und die rekursive Preload-
Closure der benoetigten Terrainhelper in das lokale Privatprojekt `project/`.
Frischer eindeutiger Godot-Profilname pro Aufruf, keine Spielautoloads oder
Spielszene. Godot4.6.2 headless,30s pro Prozess begrenzt. Das generierte
Privatprojekt samt .godot-Cache ist Scratch, kein zu integrierender Produktcode.

RED0/1 mit fehlender Cachedatei beobachtet. GREEN `HEX_CORRIDOR_CACHE_PASS 18/0`,
Import und Run Exit0, keine Script-/Leakfehler. Log: private_check.log.

Abgedeckt:80Knoten mit64+16 stattTeilpublikation; ueberlappende Pendingorigins;
stabile Enden/Passageachse; Warmhits ohne neue Nachbarreads; tiefe Ausgabekopie;
Nullbudget/64Ceiling; Typfehler vor Terrainarbeit; Revision/Registryidentitaet;
Revisionaenderung im Callback; Branchgrenze; ungerichteter6Zellkreis;
asymmetrische Helperdaten; Singleton/fehlenderOrigin; echte TerrainRegistry mit
H2/H3-Rampenachse; expliziter beidseitigerFallback; gesperrte H+0.5-Seitenplateaus.

Die echte Registry besitzt beim Paketcheck noch keine neue Nachbar-API; dieser
Teil nutzt daher den kanonischen Fallback. Die neue API wird separat ueber die
kleine FixtureRegistry geprueft. Nach Integration des owning Registryhelpers
kann derselbe Reproducer den echten APIpfad pruefen, ohne neue Testmatrix.

SHA256 Freeze:
- scripts/terrain/hex_corridor_topology_cache.gd:
  702243F7134661A458E219C4685182778D5B012328D2B36DFB81A3880B6E49CD
- verifier.gd:
  C9A1F497BB740B9BE4AC702745DA76BE185B40F31818308724F5A9397FAE6485

Nur neue Cache-/Contract-/Task-/Fixturedateien. Keine Owner-/Resolverintegration,
keine NPC-/Zeit-/Zusagewahrheit, kein Commit/Push. Die18Checks sind ein enger
CPU-Vertrag, keine Native-/Gefechts-/Save-/Netzwerk-/Performanceabnahme.
