# AP6: tatsächlicher Respawn mit durchgehend eindeutiger Feldbelegung

## Ziel / Ursache

RespawnManager meldet bislang Queueannahme als Abschluss und ignoriert abgelehnte
medizinische Beginaufrufe. Der freie Actorrespawn versetzt den Körper ohne
Groundabgleich und publiziert mitten im medizinischen Reset. Ein alter Timer darf
außerdem keinen neu gebundenen Actor derselben ID wiederbeleben.

## Umfang / Nicht-Ziele

Root bindet ein Ticket bereits beim Timerstart an konkreten Actor, Manager,
Weltkontext und Lifecycle. Manager besitzt weiterhin Timer und Spawnart. Nach
Ablauf wartet ein belegtes Ziel bei null; genau ein Versuch ist in Flight.
Ground verlegt die vorhandene Person atomar und räumt ausschließlich ihre eigenen
Bewegungszusagen/Grantmitgliedschaft. Vorbereitete Actor-/Manager-/Rootmodelle
stehen vollständig vor ersten Pose-/Vital-/Runtime-/Abschlusscallbacks bereit.
Historische erfolgreiche Receipts bleiben nach legitimer Lifecycleerhöhung lesbar.
Kein Release→fehlbare Admission, keine Ausweichsuche, neue Medizin-/Zeitbalance,
Produktionskennung, Mainintegration, EXE oder große Testmatrix.

## Verträge / Akzeptanz

- `hex_tactical_runtime_contract.md`, `explicit_hex_ramps_contract.md`,
  `ACTOR_PREPARED_RESPAWN_2026_11_12.md`, Gesamtplan AP6–8.
- Echte Actor-/Root-/Registry-/Managerscopebindung und Authority verlangen;
  Fit, fehlender Ground oder Bordperson wird vor Timer-/Modelländerung abgelehnt.
- Downed/Respawning hält genau ein Feld. Fremder Occupant, Admission, aktive/
  zukünftige Kante oder Korridorclaim blockiert den Zielcommit vollständig.
- Freies legales Ziel wird kanonische Weltmitte. Eigene Order/Recovery und alte
  Queuefortsetzungen enden, fremde Cohortclaims bleiben unverändert.
- Actor-/Kontext-/Lifecyclewechsel macht alte Timer und Queueeffects ungültig.
- Beobachter lesen beim ersten Callback die vollständigen Ownerzustände;
  Reentry kann weder doppelt bestätigen noch einen neuen Auftrag löschen.
- Nicht versionierte Altpfade bleiben erhalten; Hex ohne Ticket fällt geschlossen aus.

## Dateien / kleine lokale Prüfung

Root, `respawn_manager.gd`, ausschließlich neue Ground-Verlegungsprimitive und
vorbereitete Actor-API. Neue kleine private Fixture/Runnercase mit realen Owners
und TestUnit; Driverabschluss nur an tatsächlichem Managercommit prüfen. Höchstens
zwölf Felder, RED/GREEN und direkt betroffener Ground-/Lifecycle-Nachbar.
Keine Hauptszene, native Gefechtstests, Peermatrix oder Performancefreigabe.

## Risiken / offene Punkte

Die Begin-/Completepublikation muss den Actor-Prepared-Vertrag einhalten; direkte
alte Respawneffects dürfen den neuen Weg nicht umgehen. Save aus laufendem
Respawn ist eine explizite AP7-Grenze; keine stillschweigende Timerpersistenz.
Slot-/Identitätswechsel und taktisches Member-Retirement sind weitere AP6-Pakete.

## Ergebnis

Tatsächlicher Verbund76/0 und unmittelbare Nachbarn Actor24/0/Reservationsowner36/0,
alle Guards grün; QA `hex_respawn_transaction_20261112`. Enger Review schloss
veraltete Actorfolgeevents nach lifecycle-only Wechsel sowie Respawn auf eigener
Bestandszelle im Sharedgrant. Parentreview schloss erneuten echten Schaden,
Root-/Registrypfadwechsel am selben Manager, intervenierende BEGIN-Runtime und
akzeptierte fremde Schiffsmasken mit sauberem71/5→76/0.

Vorbereitete Medicalmodelle werden vor Pose/Signalen zusammen mit Timer/Receipt
übernommen. Vollständige Identität wird beim Actorfinalizeeintritt versiegelt;
legitime Root-Lifecycleerhöhung im stillen Commit davor bleibt erlaubt. Danach
veraltete Modelle/Managerbindings unterdrücken nur alte Folgeveröffentlichung;
ein historischer erfolgreicher Commit wird nicht zurückgerollt. Große Prüfung,
Slot-/Visit-/Member-Retirement und AP7/8 bleiben getrennte nachfolgende Pakete.
