# N4 · gemeinsame Crew über echte Produktprozesse

13.09.2026: `tests/network_run.ps1 -Visual -Port 28149` verwendet jetzt den aktuellen gemeinsamen N4-Commandweg aus `internet_process_probe.gd`. Die bisherige N2-Zwangstrennung Host/Ida und Gast/Jaro ist absichtlich abgelöst; `network_probe.gd` bleibt ein kompatibler LAN-Einstieg.

**62/62 Produktfensterchecks bestanden (Host32/Gast30).** Zwei echte `scenes/game.tscn`-Instanzen, ENet, isolierte Karrierepfade; Hostzeit12×, Netzwerk und Snapshots in Echtzeit. Geprüft: Gast bewegt beide Figuren, Host besetzt Jaro, doppelte Anfrage genau einmal, kein PvP, Ortsprüfung für Handel, gemeinsame Pause, echte Save/Load-Wiederherstellung mit steigender Revision, Disconnect/Rejoin, gefertigte und aus dem erreichbaren Lager angelegte Rüstung, tatsächlich laufendes Boarding, Gast-Launch → Orbit → Reise → Landung → Kauf aus gemeinsamen Credits. Schema4 und vollständige Host-/Gast-Snapshots stimmen in Pause, Restore und Abschluss überein. Alle Enginefehlerlogs leer.

Evidenz: `C:/Users/bjoer/AppData/Local/Temp/sternen-internet-002ab527671241daa73174fff5ac1b82`. Sechs Bilder `host/guest-paused/restored/final.png` sind tatsächliche Viewport-Captures. Zusätzlicher gleicher Headless-ENet-Lauf56/56: `C:/Users/bjoer/AppData/Local/Temp/sternen-internet-83c94edc0a764702b93b1f5168600b4e`.

Die Internet-Gateway-Lifecycle-/Einladungsprüfung besteht separat15/15. Authentifizierung übernimmt weiter die tatsächliche Snapshotversion; Verbindungsabsender kommen ausschließlich vom Multiplayer-Peer. Geteilte Crewrechte benötigen keine Aufweichung des Gateways. Der öffentliche N4-WSS-Status steht in `tests/internet_report.md`.

---

## Historische N2/N3-Abnahme (vor Änderung der Koop- und Reisebedienung)
# N2 — echte Produktprozesse, Suche und Raumkontakt

Die aktuelle Abnahme benutzt `tests/network_run.ps1 -Visual -Port 28073`: zwei echte Godot4.6.2-Produktprozesse mit `scenes/game.tscn`, ENet-Verbindung und vollständig isolierten Savepfaden. `game.simulation_seed=3` legt ausschließlich den Startwert des produktiven Zufallsgenerators fest; keine Mission, Geometrie, Gesundheit oder Auszahlung wird für Erfolg injiziert. Autoritative Zeit läuft beschleunigt; Netzwerk und Snapshot-Takt bleiben echte Echtzeit.

## Geprüfter Spielerweg

Host Ida und Gast Jaro bekommen ihre vorhandenen Plätze. Fremde und gefälschte Befehle werden abgelehnt. Werkbankarbeit, gemeinsame Pause und Wiederherstellung eines älteren pausierten Saves mit streng neuerer Revision werden über ENet geprüft. Danach: reale Reise zur Rostkarte, Boarding für Suchflug, anonyme Radarsignale, Host-Anflug, Näheidentifikation, Landung, Gast-Fußbergung und Rückkehr mit genau einer Blackbox/Auszahlung.

Die anschließende Stationsreise löst über den gespeicherten regulären35%-Wurf einen separaten Raumkontakt aus. Host bleibt Pilot, Gast bedient Jaros Turm; fremde Pilot-/Turmsteuerung wird verweigert. Gemeinsame Kampfpause, Save/Reload mit Gastbesitz, tatsächlicher Turmsieg und Fortsetzung zur Station werden beobachtet. Nach Rückkehr: Disconnect pausiert und gibt Jaro zurück; Reconnect nutzt dieselben zwei Personen und behält die Auszahlung genau einmal.

## Ergebnis

```text
host: checks=46 failed=0 snapshots=57
guest: checks=29 failed=0 snapshots=47
NETWORK_TWO_PROCESS_PASS
```

**75 Checks bestanden.** Evidenz:
`C:\Users\bjoer\AppData\Local\Temp\sternenbuergerchen-network-e7849408add542848e41c5f26f8daa3a`

Beide Enginefehlerlogs sind leer. Sechs tatsächliche Viewport-Captures samt Snapshot-JSONs wurden geschrieben. Die vollständigen Host-/Gast-Snapshots sind in allen drei stabilen Phasen identisch; diese Gleichheit ist zusätzlich im Runner verankert:

| Phase | Region | Revision beider Prozesse | Credits | Snapshot |
|---|---|---:|---:|---|
| paused | base |83|180|identisch|
| contact | space |330|440|identisch|
| reconnected | base |395|440|identisch|

Der erste Lauf deckte beim Gast einen echten Rendererfehler auf: vor dem ersten Reconnect-Snapshot enthielt die Welt alte Crew-Nodes, aber ein leeres Crew-Dictionary. Der Weltverantwortliche hat diesen Lebenszyklusfehler behoben. Der gezielte Wiederlauf ist der oben dokumentierte grüne Stand; frühere doppelt gezählte Radarchecks wurden durch eine einmalige Phasenbarriere entfernt.

## Save-Lebenszyklus einschließlich v1-Migration

`tests/save_lifecycle_run.ps1` startet vier weitere echte Produktprozesse (initial,restore,guards,recovered), jeweils mit eindeutigem temporären Speicherpfad. Der erste echte Save wird verlustfrei in seine historische v1-Form serialisiert (nur additive Schema2-Felder entfernt), damit der folgende normale Produktstart tatsächlich die Migration ausführt. Fortschritt, Pause und fortgesetzte Arbeit bleiben erhalten. Beschädigte Saves bleiben geschützt; explizites Speichern stellt Autosave wieder her; ein fehlgeschlagenes Beenden-Save hält das Produkt offen.

**10 Checks /4 Produktstarts bestanden.** Evidenz:
`C:\Users\bjoer\AppData\Local\Temp\sternenbuergerchen-lifecycle-n2-88e447a169a946eeaf80bc2f8ee1ed37`

Die normalen Nutzerkarrieren wurden weder gelesen noch geändert. Alle vom Runner gestarteten Prozesse sind beendet. Tatsächliche Mausbedienung, visuelle Endgestaltung und Internet/NAT bleiben getrennte Abnahmen; dieser Nachweis betrifft reale autoritative Befehle und ihre geteilte Produktwirkung über zwei lokale ENet-Prozesse.
