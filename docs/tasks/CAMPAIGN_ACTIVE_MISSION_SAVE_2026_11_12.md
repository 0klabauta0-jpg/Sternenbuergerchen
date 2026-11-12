# Kampagnen-Einsatz speichern und fortsetzen

## Ziel und Ursache
Einen echten aktiven Kampagneneinsatz einschließlich Personen, Mission, Transport und Flug-/Kampfzuständen sicher speichern und fortsetzen. Bisher schützt der Basischeckpoint vor unvollständigen Zwischenständen; der allgemeine Missionsslot speichert nur einen Szenenpfad.

## Umfang und Nichtziele
Versionierter, atomarer Kampagnencheckpoint mit validiertem Ownerzustand und tatsächlichem Continue; bestehende Home-/AP7- und alte Spielstände erhalten. Keine zweite UI-Wahrheit, keine Scheinwiederherstellung. Zustände, die nicht verlustfrei unterstützt werden, bleiben ausdrücklich gesperrt. Keine EXE in diesem Task.

## Verträge
`docs/dev/campaign_introduction_contract.md`, `docs/dev/persistent_location_runtime_contract.md`, vorhandene Hex-Checkpointtransaktion und CampaignCheckpointStore; neue Freigabe löst die bisherige Missionssperre nur für nachweisbar vollständig unterstützte Zustände ab.

## Akzeptanz und Prüfung
Reale Mission mit tatsächlichen Personen, Positionen, Loadouts, Interaktion, Gegnern und Transport in isoliertem Profil speichern, Anwendung neu initialisieren und fortsetzen; Welt und weiterer Ablauf stimmen. Flug-/Kampfzustände und mehrortige Owner nur zulassen, wenn konsistent wiederherstellbar. Fehlerhafte/unvollständige Daten, laufende atomare Transaktionen und unbekannte Versionen dürfen weder Welt noch bisherigen sicheren Save verändern. Bestehende Basis-/AP7- und alte Checkpoints bleiben ladbar. Vor Implementierung rote gezielte Tests; danach echtes Roundtrip- und Legacy-Gate.

## Betroffene Dateien und Zusammenarbeit
CampaignCheckpointStore, SingleplayerRuntimeAdapter, MetaLayerFlow, ggf. zuständige Simulation-/Missionsowner; nur gezielte Methodenänderungen. Weltraum-/Luftchat überlappende Methoden abstimmen. Risiko: mehrere Orte und laufende Befehle besitzen eigenständige Owner; vollständiges Save ist nicht durch Szenenpfad oder unvollständigen Snapshot erfüllt.

## Zwischenstand 12.11.2026
Flugowner: versionierter JSON-Export und vorbereiteter Restore auf identischem Craftowner; ungueltige/fremde und stale Zustandsdaten werden ohne Publikation abgelehnt. Headless Roundtrip/Negativtest sowie sechs Nachbarpruefungen bestanden. Dies ist ausschliesslich ein Ownerbaustein: Es gibt weiterhin keinen aktiven Missions-Save/Continue, und die bestehenden Schutzsperren bleiben aktiv. Insbesondere Fleet, Combat, Wing, Air-Sortie, Crew, Missionszustand und atomarer Gesamt-Commit fehlen noch. Luft-Task liefert das endgueltige Sortie-Schema und Restore-Reihenfolge nach Pruefung.

## Ownerbausteine in Arbeit
Ein begrenzter typisierter JSON-Codec sowie vorbereitete Flug-, Reise-, strategische Flotten-, Rotten-, Schiffssystem- und Vitalmodell-Teile sind gesondert geprueft. Die Teil-Restores validieren Identitaeten und enthalten keine allgemeine Speicherfreigabe. Lokale Raum-/Atmosphaerenbereiche und Area-Bindungen werden durch den strategischen Flottenpfad noch abgewiesen; fehlende Missions-/Transport-/Combatindex-/Sortie-/Gesamttransaktionsdaten bleiben offen. Warp-Reise wurde mit Zwischenstand, Fortsetzung und Request-Replay geprueft; Schiffssystemtest verwendet tatsaechlichen Schaden und Replay. Kein aktiver Einsatzcheckpoint und kein EXE-Export.

## Personenmodelle
Echte Registry-Actors koennen Identitaet, medizinischen Zustand, Runtime-/UnitCommand und Kontaktzustand vorbereiten. Die gespeicherte Position muss dem separat vorbereiteten Bodenowner entsprechen; der Actor-Teil erzeugt keine zweite Positionswahrheit. Ein Batch validiert alle Actors vor signalbehafteter Finalisierung; Tests zeigen, dass ein zwischenzeitlich veraenderter zweiter Actor auch die Aenderung des ersten verhindert. Boden-, Bewegungs-, Transport- und Missionstimer sind dadurch noch nicht als Gesamteinsatz gespeichert.

## Gesamttest als Ausgangspunkt
`campaign_active_mission_continue_verifier.gd` verwendet die echte Kampagnenvorbereitung, Flug, Satellitenanflug und Landung mit beiden Originalpersonen. Isolierter RED-Lauf: 31 bestanden, ein Fehler beim bislang fehlenden aktiven Checkpointpfad. Der Test verlangt anschliessend Szenenabbau, normales Continue und die Wiederherstellung der Personen und des Schiffes am Einsatzort. Dieser RED-Test ist keine Funktionsfreigabe.

## Stabilisierter Bodenpfad (WIP)
Legacy-Positionen und Actor-Modelle werden in isolierter Vorbereitung gemeinsam validiert; map fingerprint, Walkability, Zustand von beiden Actors sowie getrennte signal-/await-freie Publikation sind gezielt geprueft. Ein enger Lifecycle-Baustein sichert synchronisierten Tick, RNG, Tokens und Missionszeit; Gefecht, Interaktionen und laufende Uebergaenge werden dort ausdruecklich abgewiesen. Die Zeit wird als Dauer mit Startoffset wiederhergestellt, damit ein laengerer Einsatz auch nach Prozessneustart keine negative Startzeit erfordert. Im echten Satellitenflug exportieren Flotten-, Lifecycle-, Actor- und LegacyGround-Bausteine; der aktive Gesamt-Save/Continue fehlt und der echte Roundtrip-Test steht weiter auf 31/1. Bestaetigte Fleet-Transitionsbelege werden nach JSON-Roundtrip an restaurierte Craftowner neu gebunden. Die bisherige Speichersperre bleibt aktiv.

## Echter Mehr-Owner-Capture
Der echte Landefall wird durch einen read-only Collector gegen die aktuell gebundenen Campaign-, Supply-, Onboarding-, Equipment-, Markt-, Fleet-, Space-, Missions-, Transport-, Actor- und LegacyGround-Owner erfasst. Homecheckpoint und echte Orts-/Pilot-/Crewidentitaeten werden gegengeprueft. Isolierter Gesamttest: 32 Checks bestanden, eine erwartete Fehlermeldung fuer den noch fehlenden aktiven Speicherpfad. Der Collector kennzeichnet sich selbst mit `complete=false`: Rootbelege, Welttransaktion und Scene-Restore fehlen. Die getrennte Aktivdatei testet atomare Ablage/Domainvalidator und schuetzt explizit den Home-Pfad, ist aber nicht als aktiver Kampagnensave verdrahtet.

## Kampagnenkennung
Neue Kampagnen erhalten eine zufaellige persistierte Run-ID; bestehende Homecheckpoints ohne Kennung behalten einen deterministischen Migrationswert. Ein Aktivstand wird spaeter an diese Kennung und den letzten Homecheckpoint-Hash gebunden. Run-ID-Negativtest und alter Home-Continue bestehen; Auswahl und Restore des aktiven Umschlags sind noch nicht angeschlossen.

## Fortsetzung: Kandidatenszene und sichere Grenzen (WIP)
Der vorbereitete Receipt-Join wurde uebernommen und mit 29/0 isoliert geprueft. Der World-Preflight kann versuchsweise gegen den bereits existierenden Heimat-Root vorbereiten, ohne dessen gebundene Owner zu ersetzen. Ein noch nicht im Spiel angeschlossener Szenen-Builder und Preflight bereiten die echten Ground-, Actor-, Lifecycle- und Transportowner gemeinsam vor; lediglich der Stand vor Erweiterung des Builders wurde auf GDScript-Syntax geprueft. Die erweiterte echte Journey-Probe fuer diese Vorbereitung ist noch nicht gelaufen. Kein aktiver Save/Continue ist damit verfuegbar.

Vorlaeufige Capture-Grenzen verweigern Home-Hexzustand, aktive Ressourcenaktionen oder Raumereignisse sowie nicht passendes Basispersonal, Ausruestung, Fireteams, Abflugtoken und Landeplatz. Die vollstaendige Wiederherstellung und Validierung des BasePersonnel-Owners, der Location-Ressourcen, des Flow/Runtime-Adapters und des sichtbaren Missionsablaufs stehen noch aus. Insbesondere darf eine rueckfallende, unvollstaendige Kopie des Homezustands nicht als Einsatz-Continue freigegeben werden. Neue Mond-/512-Karten und lokale Orbit-/Automatikzustaende werden parallel untersucht und benoetigen einen anschliessenden echten Gesamt-Nachweis.

## Isolierter echter Continue (weiter WIP)
Ein privater, ausschliesslich per `CAMPAIGN_ACTIVE_TEST_ONLY=1` zugaenglicher Pfad schreibt einen vom Homecheckpoint getrennten Aktivstand und rekonstruiert die echte Kampagnenszene. Ein isolierter Lauf bestaetigte Originalpersonen, Positionen, HP, Schiff, Credits, Kraftstoff, Missionszeit und szenariobestimmtes Zeitlimit; anschliessend wurden Satelliteninteraktion und Rueckweg/Use durch echte Befehle ausgefuehrt (66 bestanden). Die danach abgefragte Erwartung `completed` war falsch: der aktuelle Kampagnenowner fuehrt erst `pending_upload` und schliesst nach Heimatlandung und Terminalupload ab. Der entsprechend korrigierte komplette Heimflug-/Uploadtest steht noch aus. Der alte Test war deshalb kein gruenes Gesamtgate. Geplante, noch nicht gestartete Befehle/Areaorders werden nun fail-closed abgewiesen (11/0 fokussiert). Die Testschranke darf erst nach vollstaendiger Pruefung und Join aller anderen Owner entfallen.

## Echter Legacy-Continue und Heimupload bestanden
Isolierter Lauf `output/active_complete_trial_10/20261112T170733Z-pid23940/metadata/report.json`: 73/0, Runner 1/1 PASS. Echte Kampagne mit laufender Mission wurde separat gespeichert, regulaer fortgesetzt, die beiden Originalpersonen samt Position/HP und Schiff/Wirtschaft/Uhr rekonstruiert, der Satellit nach echtem Marsch und Use gesichert und der Rueckkehrpunkt benutzt. Anschliessend pending_upload, echter Heimwarp und Heimatlandung, abschliessend tatsaechlicher Chipupload. Szenariodatei setzt das 2400-s-Limit vor dem Katalogwert. Noch keine Freigabe: nur `CAMPAIGN_ACTIVE_TEST_ONLY=1`, Legacy-Boden/strategischer Pfad, kein Nachweis fuer 512-Kartenjoin, lokale Orbitfortsetzung, Gegner/Interaktionen in Zwischenzustaenden oder Mehrortwelt. Die echten Source- und Testprofile sind isoliert; keine Positions-/Zeitmanipulation. Gezielte Tests: geplante Auftraege 11/0, Navigation mit stabiler Orbitcontrol 19/0, JSON-Normalizer PASS, Root-Prebinding 29/0.

## Gemeinsamer Produktpfad und Grenzen
Nach kontrolliertem Join der Mond-/512-Karten und Orbitowner wurde der regulaere
Pausenmenue-Save ohne Testenv in einem echten Kampagnenablauf geprueft: 80/0,
Runner 1/1 PASS. Die beiden Personen, Zeit, Schiff und Wirtschaft wurden beim
Continue erhalten; nach echtem Satelliten-Use, Rueckweg, Heimwarp und Landung
wurde der Chip tatsaechlich hochgeladen. Ein danach gespeicherter Homecheckpoint
hat beim erneuten Continue Vorrang vor der alten Active-Datei, die bytegleich
erhalten bleibt. Ein simulierter fehlgeschlagener Homewrite liess sie ebenfalls
unveraendert. Zehn gezielte Regressionschecks bestehen; Details und Grenzen in
`docs/qa/campaign_active_continue_20261112/README.md`.

Der erlaubte aktive Slice ist ausdruecklich eng: ein stabiler Landeplatz auf
Legacy-Boden, eine unveraenderte Crew und Heimatbasis, keine laufenden Aktionen
oder nicht ausgefuehrten Planbefehle. Die Escape-Speicherung meldet Sperren in
der Spielersprache; ein fuenfminuetiger Autosave verwendet dieselben Guards.
Orbitautomatik bleibt standardmaessig aus; ein Dateisave waehrend des lokalen
Orbitflugs ist nicht nachgewiesen und bleibt gesperrt. Die bisherige private
Testenv-Schranke fuer den belegten stabilen Slice ist entfernt. Keine Aussage
ueber umfassende visuelle, Performance- oder Multiplayerabnahme.
