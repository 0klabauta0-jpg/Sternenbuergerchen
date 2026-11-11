# Hex-Facing und Sicherung — 11.11.2026

Basis2a0ffeef8, isolierter Taskbranch. Keine aktivierte Karte und keine große
Szene. AP3-Kern/Consumer ergänzen den gesicherten Reader-Zwischenschritt.
Vertrag: docs/dev/hex_tactical_runtime_contract.md. AP4-Reservierungsresolver
entwickelt der koordinierende Chat getrennt; keine Änderungen daran hier.

Kleine reale Privatprojekt-Cases mit Godot4.6.2: facing24/0, security34/0,
consumers39/0; ergänzende direkt betroffene Foundation-/Ownerchecks siehe
manifest.json. Alle akzeptierten finalen Läufe Exit0, ohne Script-/Leakfehler,
private Nutzerverzeichnisse und unveränderte Originalprofile/Quellbytes.

Facingfixture führt einen echten Root-Physikschritt samt Ticksignal aus und
prüft Commitreihenfolge, exakte Delaygrenze, Replayring/Verdrängung, niedrigere
Priorität, Coalescing ohne Deadlineverschiebung, geänderten Auftrag, Kontext,
Downed, Release und verweigerte Autoritätspolicy. Letzteres kein Peerabnahmetest.
Securityfixture nutzt drei kleine Actors/vier Tiles, echte Resolver/Root/Cache.
Belegt sind sechs Projektionsrichtungen, einzelne Kegel, erlaubte Feldwechsel
für Overwatch, keine reinen Rendertrigger, aktuelle Flankendeckung samt Label,
Cover/Halb-Rampenhöhe und Legacyzweige. Drei Wächter verteilen sich auch bei
allen sechs Halbsektor-Ties ohne Rundungsblindlücke. Consumerfixture nutzt den
echten Driver hinter einem Ready-/Lookup-Testadapter und beweist zusätzlich
Soundhinweis ohne Kontaktbestätigung, Skilldelay, Auftragssperre und Replay.

MissionTacticalSandboxController hat ausschließlich die zwei abgestimmten
Kontext-/Visualhooks erhalten. Diese große Klasse wird hier statisch geprüft;
zusammengeführter Check-only folgt im Kartenchat. Kein vollständiger nativer
Trupp-/Missions-/Bereitschaftsfluss, kein GPU-/FPSversprechen. Bestehende
Overwatch-Bereitschaftsregeln werden nicht neu freigeschaltet. Soundhook ist
adressierter Anschluss, kein neu gebauter Producer oder Schallausbreitungsmodell.
Skillabhängige Bewegungsschussbalance bleibt vor AP5-Aktivierung offen.

## RED/GREEN und Review

- Facing d636de46...0/1 (fehlendeOwnerAPI), danach15/0, Ring16/0,
  Reviewlücken24/0. Coalescing5020c29b...22/2, danach0f347687...24/0.
- Security ce4bff79...0/1 (fehlendeBridge), danach16/0. Ein Zwischenversuch
  hatte ein fehlendes tatsächliches NPC-Fixturefeld is_fireteam_lead und
  Timeout; Setup korrigiert, nicht als gültigesRED gezählt.
- Logische Damagegeometrie6b6b3bdf...16/3, danach19/0; Legacyfälle21/0.
- Frischer Review: kanonischer Kegelrand, Kontextrest und gewünschte statt
  committete Flankendeckung af06122c...21/4 (inkl gleicher-Tick-ID), danach25/0.
  Richtungslabel f25406d6...25/1, danach26/0. Dreierrings61549aeb...26/1,
  danach27/0. Halbsektor-Ties plus alter Membersnapshot3759ee97...31/3,
  danach34/0. Letzter enger Nachreview ohne offene Befunde.
- Soundhook e410d9bb...30/1, danach36/0; logische Diagnosen/Legacycallbacks39/0.
  Ein erweiterter Fixturelauf hatte vorübergehend ungleiche Registryrevisionen
  nach neuem Covertest; Repro wieder gleich revisioniert, keine Runtimekorrektur.

Originale Logs/Reports aller Versuche in facing_security_runs.zip; Manifest
trennt tatsächlich ausgeführte Quellen und statisch geprüfte Adapter. Keine
historischen Fehlversuche überschrieben oder als Green gewertet.
