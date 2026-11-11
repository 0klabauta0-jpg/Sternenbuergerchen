# Budgetierter Hex-Korridortopologiecache

Ziel/Ursache: Korridore groesser64Felder schrittweise vollstaendig erkennen,
statt abgeschnittene lokale Komponenten als fertige Gaenge zu behandeln.
Basis: task/native-glut-maps-20261110, bestehender noch nicht Main-integrierter
Karten-/Tabletopstand. Nur neue Dateien dieses separaten Teilauftrags.
Umfang: scripts/terrain/hex_corridor_topology_cache.gd, eigener Contract und
kleiner privater Verifier unter output/native_glut_maps/hex_corridor_cache_20261111.
Nichtziele: Owner/Registry/Resolver/Runner/Status editieren, NPC-/Zeit-/Zusage-
wahrheit, aktive Integration oder grosse Tests, Commit/Push.
Vertraege: explicit_hex_ramps_contract.md, hex_tactical_runtime_contract.md,
hex_reservation_plan_contract.md, hex_corridor_topology_cache_contract.md.
Akzeptanz: hoechstens64neueKnoten/Call, ein serieller Komponentenjob mit
deduplizierten Pendingorigins, keine Teilpublikation, Branch-/Zyklusgrenzen,
Registry-/Revisionsinvalidierung, unabhaengige Kopien und Typpruefung.
Pruefung: kleine private CPU-Fixture ueber64Knoten, Revision/Copy/Branch/Cycle,
Import/Run und Diffcheck. Keine Spielszene und kein echtes Profil.
Risiken: Registryhelper-Signatur wird mit owning Chat abgestimmt; fertige Daten
gehen erst spaeter via OwnerOptions an Resolver. Kein Performance-PASS.

Abschluss: eigener serieller Cache umgesetzt. API mit owning Chat bestaetigt:
get_legal_hex_neighbors mit beidseitiger allows_step-Legalitaet, is_walkable,
get_revision und Registryidentitaet. Exakter Fallback solange Helper noch fehlt.
Ownerpraezisierung: directed=true bedeutet Passageachse mehrzelliger Pfade,
keine Einbahnbegehbarkeit; Singleton und Cycle directed=false.
RED0/1 wegen fehlender Cachedatei beobachtet. Kleine private CPU-Fixture18/0,
Import0/Run0, keine Script-/Leakfehler, Diffcheck sauber. 80Felder in64+16,
Overlaporigins,0Budget,Copy/Revision/Registrywechsel, Branch/Cycle, Asymmetrie,
Singleton/blockedOrigin, echte Registry-Rampen und expliziterFallback geprueft.
Keine vorhandenen Source-/Owner-/Registry-/Resolver-/Runnerdateien editiert.
Kein Commit/Push, keine native oder grosse Performancefreigabe.
