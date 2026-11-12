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
