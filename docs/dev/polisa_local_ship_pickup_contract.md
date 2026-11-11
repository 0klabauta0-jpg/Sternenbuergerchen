# Polisa: lokale Schiffsabholung

## Erster vollstaendiger Anschluss
Lokaler Kauf ist eine ausdrueckliche Alternative zur bisherigen Heimatlieferung.
Cutlass/Buccaneer nutzen vorhandene Modelle und den geladenen Polisa-Ort.
Unbemannte echte Card/Sequence auf freiem passenden polisa_pad_01..07, keine
neue Mission, kein fingierter Anflug und keine Personenadmission. Passung folgt
MapData-Markern, vorhandenen Rendererkoerpern und R08-Padfakten, nicht Artreserve.
Ein gebautes freies Heimatpad bleibt bewusst als Rueckkehrplatz reserviert.
Spielkapazitaet inkl Pilot: Cutlass8 (acht Friendlyslots), Buccaneer1.

## Transaktion und Herkunft
Supply besitzt Credits/Stock und idempotenten Erwerbsbeleg. Fehlender
delivery_mode bedeutet alte Heimatlieferung. Lokale Ausgabe speichert eigene
versionierte Herkunft/acquisition_pad_id und getrenntes Heimatpad. Vor erster
Mutation Finanzen/Stock, Heimatpad, Identitaet, Ort/Controller, Pad und frischen
Surface-Reiseowner vollstaendig pruefen. Letzte fehlbare Mutation ist erneut
validierte Tacticalaufnahme; danach vorbereitete synchrone Publikation ohne
await oder Signale vor konsistenten Ownerbindungen. Reject ohne halbe Lieferung.

Reiseowner entsteht autorisiert direkt surface/polisa. Echter Stationsbeleg ist
kein Heimat-Outboundtoken/fremder Campaigndeparture. Services/Rueckflug pruefen
diesen Beleg und aktuelle Park-/Pilot-/Crew-/Transferdaten. Spaetere regulaere
Heimatfluege verwenden wieder ihren eigenen Departurevertrag.

## Eindeutige Besatzung
Expliziter Handoff zwischen zwei lokal geparkten Schiffen: nur reale lebende
abgesetzte Personen ohne pending Praesenzeffekte. Keine Actor-/Profilkopie,
Teleportation oder automatische Embarkbehauptung. Pilot gehoert zur Gruppe;
Kapazitaet und eindeutige globale Pilotzuordnung werden erneut geprueft.
Karten/Sequenzen, globales Pilotmapping und beide Visits (unit_ids plus parallel
indizierte fireteam_ids) werden konsistent geaendert, bevor Ereignisse folgen.
Normale Fireteams wechseln zusammen. Der echte zugewiesene Pilot darf einzeln
wechseln, auch wenn Start ihn temporaer als ft1-Actor einsortiert. Retirement
loescht Teamplaene nur ohne verbleibende lokale Restmember. Boarding/Deployment
lesen eigene Craftmitgliedschaft statt ganzes Ortsroster; vorhandene Root-
Embark-/Deployeffekte und Weg-/Distanz-/Pilotgates bleiben bestehen.

Neue leere Visits haben eigene craft_id/leere job_id. Ortsjob, Primaerbesuch,
Timer, andere Besucher und View bleiben erhalten. Abflug/Heimkehr nutzen ihre
aktualisierte eigene Mitgliedschaft. Reine Auswahl ist keine Flugberechtigung.

## Persistenz und Nachweis
Checkpoint bleibt bei Surface/Transit/Transfers gesperrt. Nach Heimkehr prueft
versionierter Beleg Erwerbsort/-pad, Modell, Herkunft, Heimatpad und Flotte.
Alte Heimatbelege bleiben gueltig. Padbelege sind keine Belegungsowner.
Nur kleine Owner-/Tactical-/Flow-/Receiptproben und Compile jetzt; native
Gesamtreise, Bedienung, Gefechte, Save/Continue und Performance spaeter.
Root/Ground/Actor-/Move-/Facing-/Doorbereiche verbleiben im Tabletop-Chat;
freigegeben sind additive Tactical-Schiffs-/Pad-/Crewbereiche und enger
Modellreader. Keine Kartenaktivierung, neue Fahrzeuge oder neue Art.
