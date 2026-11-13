# Performance-Review — 13.11.2026

Basis Main `5196cc08b`, Task `task/performance-review-20261113`. Zwei begrenzte
Agentreviews, serielle Engineproben durch den Hauptagenten. Keine Desktopbedienung.
Godot `4.6.2.stable.official.71f334935`, Windows x64, Ryzen 7 7800X3D,
8 Kerne / 16 logische CPUs. Headless, aufgewärmte CPU-Pfade; keine GPUzeiten.
Qualität, Karten, Akteure und Spielregeln unverändert.

## Drei bestätigte und behobene Befunde

| Pfad / identische Last | Median vorher | Median nachher | Änderung |
|---|---:|---:|---:|
| Hexsicht: 64 gerichtete Paare × 4 Leser pro Tick | 4,330 ms | 2,591 ms | −40,2 % |
| Snapshotpacken: 96 Units, 3 Peers desselben Teams | 0,936 ms | 0,313 ms | −66,5 % |
| Begegnungsread verborgen, 20 Aufrufe | 12,428 ms | 0,013 ms | −99,9 % |
| Begegnungsread sichtbar, 20 Aufrufe | 11,858 ms | 0,031 ms | −99,7 % |

Je 30 Samples nach Warmup. Rohwerte, Mittelwert, Median, p95 und Maximum in
`*_before.json`, `*_after.json`, `*_comparison.json`; `summary.json` verknüpft sie.
Deskriptive lokale Vergleiche, keine Signifikanz-/Produktions- oder FPSgarantie.
Der schmale Begegnungsread spart pro Poll etwa 0,6ms in der kleinen Startkampagne;
die großen relativen Prozente beziehen sich ausschließlich auf diesen Getter.

1. `CombatVisibilityCache` implementiert jetzt die vom Hexadapter bereits
   angebotene API. Range/Facing bleiben frisch; nur Terrainblocker werden geteilt.
   Schlüssel enthält geordnete Zellen, halbe Standhöhen, Registryinstanz und
   Terrainrevision. Tickwechsel leert, 4096 Einträge begrenzen die Lebensdauer;
   Terrainleser ohne Revision sowie nicht begonnene Ticks bleiben ungespeichert.
   Keine neue Gameplaywahrheit oder Export-/Restorekomponente.
2. `SimulationRoot._broadcast_tick_state` gruppiert bereits zulässige Empfänger
   frisch je Team. Einmal projizieren, serialisieren und komprimieren pro Team.
   Reliable-Vitals bleiben je Peer; Team-/Lifetime-/Blockgrenzen bleiben erhalten.
   Tatsächlicher ENet-Nachweis nutzt drei Clients. Der separate 96-Unit-CPUprobe
   misst Variantserialisierung und ZSTD mit der beobachteten Packanzahl 3→1;
   RPC, Bandbreite und Latenz sind nicht in dieser Zeitmessung enthalten.
   Beide Seiten verarbeiten identische 52.740 rohe / 4.008 komprimierte Bytes.
3. `CampaignSpaceEncounterPresenter` pollt den neuen schmalen Adapterread statt
   vollständiger Campaign-/Supply-/Fuel-/Launch-/Baseprojektionen. Bestehender
   Encounterowner liefert dieselbe unabhängige Kopie. Pollkadenz und Commands
   unverändert; Null-/freigegebene Owner blenden das Panel aus.
   Echte konfigurierte Startkampagne, zwei Personen und echte Craftdefinitionen;
   Baselineausdruck bleibt der unveränderte vollständige Getter. Messreihenfolge
   alterniert, Startup/Teardown ausgeschlossen. Tick, RNG und alle beobachteten
   Owner bleiben über beide Varianten identisch. „Combat“ ist ein Lesefixture
   des Encounterstates, keine gemessene laufende Raumschlacht.

## Regressionen: 177 / 0

- Hexcache 27: Wiederverwendung, Blick/Rangengrenzen, Terrainrevision, Höhen,
  Zielzelle, Registrywechsel, Tickwechsel, Mutation der Antwort, Kapazität nach
  5000 unterschiedlichen Inputs, Vergleich mit reiner Query und fehlende Revision.
- Encounter-UI 18: verborgen/sichtbar, Phasen, Buttons, Commands, Besitzerwechsel,
  unabhängige Antwort und Teardown.
- Netzwerkfanout 11: drei echte Clients, tatsächliche Chunks/Empfänger/Reliable-
  Vitals, Teamwechsel, verborgene Gegnereinträge und gesperrter Peer.
- Tatsächlicher Encounterbenchmark 9: gleiche Antworten und unveränderte Owner.
- Frontier-LOS/FoW-Nachbar 76: sechs Richtungen, Overrides, Dirtybereiche, Legacy.
- Legacy-Combatcache 12: identischer 16v12-Kampf über 600 Ticks mit/ohne Cache.
- Bestehender Hex-/ENet-/Checkpointnachbar 24: echte RPCs, Authority, Sichtgrenzen,
  Bewegungs-/RNG-Restore und Legacy-Driver. Frischer Report unter
  `docs/qa/hex_enet_regression_20261113/cd97c9088d7347e288f57d37545ba361/`.

Alle finalen Runner prüfen Exit, Marker, Script-/Enginefehler, Leaks sowie
Quellenhash, echtes Spielerprofil und privaten user://-Canary. Vorhandene
UID-Pfadfallbackwarnungen beim echten Kampagnenstart bleiben im Rohlog sichtbar.
Keine Originalprofile oder Caches eingecheckt.

## ROT / Versuche transparent

Valide rote Befunde: Hex `red_f527...` 1/1; Encounter `red_081b...` 9/5;
Fanout `red_7890...` 9/2. Einzelne zusätzliche Hexprüfungen kamen nach dem Fix
hinzu; sie werden nicht als sämtlich vorher rote Assertions bezeichnet.
Erster Hexrunner benannte eine nicht existierende Configuremethode und wurde
gezielt samt Kindprozess beendet. Erster Fanoutfixture fehlte das Authorityflag,
deshalb erreichte er den Publisher nicht. Zwei frühe Hexassertions verwendeten
falsche Overridenamen; Fixtures korrigiert, Produktassertions erhalten. Diese
Versuche sind Harnessfehler und keine zusätzlichen Produktbefunde.

`raw_logs.zip` bewahrt alle lokalen Versuche und die finalen Ausgaben byteweise.
SHA256 der ZIP und Logs in `summary.json`; Einzelreports bewahren Quellenhashes.
`summarize.py` verwendet den Skillkomparator mit übereinstimmendem Lastkontext.

## Weitere Kandidaten und Grenzen

Basisvisualisierung liest noch vollständige Personensnapshots pro Renderframe.
Das ist ein Quellkandidat, hier nicht vermessen. Eine Reduktion braucht korrekte
Invalidierung für Boarding/Away, Schlafen, Umbenennen, Hinzufügen und Ownerwechsel;
kein unbewiesener Statuscache wurde eingeführt. Native GPU-/Framezeiten,
512×256-Last, Streaming, Autosave-I/O, Langzeit-Speicher und Internetlatenz sind
durch diese engen CPUproben nicht freigegeben. Keine neue EXE.
