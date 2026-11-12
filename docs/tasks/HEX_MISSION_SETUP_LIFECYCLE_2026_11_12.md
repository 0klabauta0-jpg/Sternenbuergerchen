# AP6: tatsächliche Missionsinitialisierung und Wellenzulassung

## Ziel / Ursache

Der vorhandene Setup pflegt Registry und Actorpositionen, konfiguriert aber den
Hexowner noch nicht und nimmt initiale Bodenpersonen nicht auf. Wellenaktivierung
umgeht ebenfalls die Feldzulassung. Deshalb reicht ein reiner Gruppenhelper für
die spätere kleine Kandidatenszene noch nicht.

## Umfang / Nicht-Ziele

Bestehender Setup konfiguriert Root anhand geladener Map/Registry und verwendet
gemeinsame begrenzte Ankerplanung für die tatsächlichen registrierten Actors.
Gestagte Bord-/Wellenpersonen erhalten noch kein Feld. Bei Platzmangel wartet die
vollständige Gruppe mit begrenzter, revisionsabhängiger Wiederholung. Identitäts-
oder Slotwechsel räumen die alte Bindung. Wellen zählen erst nach Gruppenzulassung.
Clients erzeugen nur verborgene Präsentationsactors, keine Groundautorität oder
lokale Erkennungsfreigabe. Peerpublikation selbst folgt in AP7.
Keine Produktionskennung, neue Kampagne, Base-/Reise-/Spacewahrheit, EXE,
große Karte oder breite Gefechts-/Netz-/Performanceprüfung.

## Dokumente / Verträge

- `docs/dev/hex_tactical_runtime_contract.md`
- `docs/dev/explicit_hex_ramps_contract.md`
- `docs/tasks/HEX_GROUND_LIFECYCLE_2026_11_11.md`
- `docs/superpowers/plans/2026-11-11-hex-sight-occupancy.md`, AP6/AP8

## Akzeptanz

- Tatsächlicher Setup übernimmt Mapkontext vor Actoraktivierung; ungültige Map
  fällt geschlossen aus, bestehende Registry nicht durch Hardcode ersetzen.
- Eindeutige gewünschte Anker bleiben erhalten, Kollisionen werden innerhalb
  legal verbundener Felder verteilt. Gruppe maximal64 Expansionen, atomarer Commit.
- Defer-/Wellenpersonen ohne Registryzulassung bleiben ohne Groundfeld. Eine
  tatsächliche Welle wartet vollständig und meldet erst erfolgreiche Aktivierung.
- Warmes Warten erzeugt keine erneuten unveränderten Gruppenplanungen. Lifecycle-,
  Actor- oder Kontextwechsel kann keine alte Platzierungsabsicht wiederverwenden.
- Bestehender Legacyweg bleibt erhalten; Präsentationsclient erhält keine lokale
  Gameplayzulassung. Die echte Peer-/Receivergrenze wird hier nicht behauptet.

## Dateien / lokale Prüfung

`mission_test_setup.gd`, `enemy_wave_controller.gd`, Root-Gruppengrenze und
kleiner isolierter Verifier/Runner. Tatsächliche Produktkörper mit bekannten
Terrain-/Roster-/UIeingaben, höchstens zwölf Felder. Gezieltes RED/GREEN und enger
Review; keine Hauptszene oder Produktionsmap laden.

## Risiken / offene Punkte

Wellen deaktivieren ihre registrierten Slots zunächst; deren vorhandener Owner
entscheidet über Zeitpunkt und Mitgliedschaft. Keine Aufnahme allein aufgrund
sichtbarer Nodes. Respawn, taktisches Member-Retirement, AP7 und vollständiger
AP8 bleiben anschließende Pakete. Keine gemessene FPS-Aussage aus Contractchecks.

## Geprüfter erster Teil: initialer Setupkern

Tatsächlicher Setup62/0 und Rootowner56/0, QA
`hex_mission_setup_core_20261112`. Fehlende API zunächst RED42/1, unabhängiger
Review schloss drei konkrete Grenzen mit RED57/5→GREEN62/0: Legacyclient-
Initialisierung, konkrete Rootinstanzbindung und Vorvalidierung von Nullgröße/
explizit leerer Hexkarte vor Registrymutation oder Hardcodefallback.

Initiale Gruppenadmission und begrenztes revisionsabhängiges Warten sind damit
angeschlossen. Laufende Slot-/Identitätsänderungen, spätere Wellenaktivierung
und Respawn sind noch keine Lieferung dieses ersten Teilpakets. Readonly-
Authorityfixture ersetzt keine reale Multiplayerabnahme. Keine Produktionsflags.

## Geprüfter zweiter Teil: tatsächliche Wellen

EnemyWaveController nimmt die vollständige nächste Welle über Root auf und
registriert die gestagten Actors erst nach dem Groundcommit. Zähler und sichtbare
Publikation folgen, dann erst Wellenmeldungen. Voll belegte Gruppen warten mit
kurzem revisionsabhängigem Retry; akzeptierte fremde Schiffsflächen sind weitere
Planereingaben. Initialisierung räumt vorherigen Feldbesitz, alte konkrete Root-
und Actorbindungen bleiben ungültig. Reinitialisierung/Entfernen und Kontext-
wechsel während Publikation setzen weder neue Timer zurück noch senden alte
Abschlussmeldungen. Legacyaktivierung bleibt erhalten.

Wellen60/0, direkter Setupnachbar62/0, Originale/Hashes unter
`docs/qa/hex_mission_waves_20261112`. Laufende Slot-/Identitätsänderungen, Respawn
und taktisches Member-Retirement bleiben weitere Lifecyclepakete. Keine große
Abnahme oder native Leistungsbehauptung aus diesen kleinen Contractchecks.
