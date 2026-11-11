# AP5 bis AP8: abgestimmte Fortsetzung

## Fortschritt

AP5-Backoff258183ce2 als0730e760e übernommen. Enger unabhängiger Review ohne
Blocker; gemeinsamer tatsächlicher Backoff55/0 einschließlich42 Grundchecks und
Quell-/Profil-/Canaryguards grün. Kein Rootpatch, kein Produktflag. AP5-Codepfade
zusammengeführt; AP6–8 bleiben in Arbeit, große AP9-Prüfung später.

## Ziel / Anlass

Erneuter Nutzerauftrag: AP5 bis AP8 selbstständig fortsetzen und den Orbitweg
mit dem Weltraumkampf-Chat abstimmen. Große Prüfungen bleiben AP9 für später.
Vor jedem EXE-Build ausdrücklich beim Nutzer nachfragen; kein Export in diesem
Arbeitsgang. Kleinere gezielte Prüfungen sichern tatsächliche Änderungen ab.

## Arbeitsbasis / Zuständigkeiten

Gemeinsamer Taskstand 3fb8d2985, getrennt von Main. Der Tabletop-Chat besitzt
Ground-/Rootbewegung, Driverproducer und Aufnahme-/Freigabe-/Restorepfade.
Weltraumkampf besitzt SpaceFlight, Rotten, Raumindex/-navigation und Raumteile
von SimulationRoot. Dieser Chat integriert gesicherte Pakete und besitzt Orbit-
layout, Reise-/Wirtschaftsvorbereitung sowie anschließende Reise-/Ansichtsglue.
Gemeinsame Rootänderungen nur nach Abstimmung, keine parallelen Simulationsowner.

## APs / Akzeptanz

1. AP5: Backoffvorschlag tatsächlich als zugesagte Bewegung ausführen, ursprüngliches
   Ziel erhalten; gegenseitige Blockade und Abbruch dürfen keine Phantomzusage
   hinterlassen. Commands, Projektion, Ankunft, Bewegungsschuss und Türschutz
   sind bereits integriert. Gesicherte Folgearbeit liegt beim Tabletop-Chat.
2. AP6: ein autoritativer Aufnahme-/Freigabepfad für Spawns, Basisbewegung,
   Ein-/Aussteigen, Extraktion und Szenariowechsel. Ein NPC je Feld, alte Zusagen
   sauber freigeben, echte Orts-/Actoridentität bewahren. Kleinstes Quellpaket:
   Root-Embark/Deploy mit Zulassungsbatch im kleinen Ortsfixture.
3. AP7: Ziele/Zusagen/Zentrierung/Interaktionszustand zusammen wiederherstellen;
   Host-/Client-/lokale Autorität unterscheiden. Fehlender oder ungültiger
   Teilzustand darf keine teilweise restaurierte Simulation veröffentlichen.
4. AP8: die gesicherten Producer im kleinen integrierten Kandidaten zusammenführen.
   Erst danach ausdrücklich über Kartenaktivierung entscheiden. Die bisherigen
   isolierten Prüfungen sind keine Produktionskarten-/Spielbarkeitsfreigabe.

## Paralleler Orbitanschluss

Echte Reisevorbereitung ce57b07f7 ist unverdrahtet integriert. Spacechat meldet
613a03c3c als nichtproduktiven echten Warpabschluss-Rootfixtureanschluss.
Gesicherte Raumgrundlagen werden zuerst im separaten Worktree
`orbit-owner-integration-20261111` mit 3fb8d2985 zusammengeführt. Insbesondere
lokal geborene Polisa-Schiffe brauchen dieselbe echte Flight-Craft-ID.

Vor einem produktiven Oberflächenanflug müssen Supply-Fuel und Campaign-
Abflug/Job ebenfalls vorbereitet und gemeinsam vor allen Events veröffentlicht
werden. Zwei getrennte Agenten bearbeiten dafür ausschließlich SupplyState bzw.
CampaignState mit eigenen Tasks/Checks. Kein Save-Restore als Liveownerwechsel,
kein früher Debit, kein Dummyrefund, kein zweiter Flotten-/Bewegungszustand.

## Dokumente / Dateien / Prüfung

ACTIVE_WORKPLAN, TABLETOP_RESTPLAN_INTEGRATION, ORBITAL_APPROACH_MAPS,
ORBIT_DEPARTURE_ATOMICITY_AUDIT, NEXT_PLAYABLE_EXE und ihre genannten Contracts.
Betroffene Dateien je gesichertem Teilpaket, keine pauschale Dateibesitzübernahme.
Produktkonflikte einzeln prüfen, Quellbelege und eigene Integrationsprobe trennen.
Nur nötige kleine Checks/Compiles; keine erneute große Nachbarmatrix oder GPUrunde.

## Risiken / Nicht-Ziele

Noch kein vollständiger AP5–8-Abschluss, keine neue EXE, keine Mainfreigabe.
Raumfixture und private Ownerkandidaten allein erlauben keine produktive lokale
Reise. Neue Fahrzeuge, vollständiger Forschungsbaum und Away-Save gehören nicht
als zusätzliche Voraussetzung in dieses Paket. Vor Build ist Nutzerzustimmung
erforderlich; Integration und Vorbereitung laufen bis dahin weiter.
