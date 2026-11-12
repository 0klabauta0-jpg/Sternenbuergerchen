# Hostseitige reine Empfaengerprojektion

## Ziel / Ursache
V1-HostDTO vor spaeterer Publikation fuer genau ein kanonisches Team filtern.
Root/Driver liefert bewiesene eigene/aktuell sichtbare IDs und FT-Teamzuordnung;
dieser Helper berechnet oder veraendert keine Sicht/Detection.

## Umfang / Nichtziele
Nur neue scripts/multiplayer/multiplayer_visible_snapshot_projection.gd, eigener
Verifier/QA und Task. Keine bestehenden Contracts/Root/Driver/FoW/Sharedrunner-
oder Receiverwrites, kein Stage/Commit und keine Native-/Gesamtfreigabe.

## API / Kontext
project_state(v1_dto,recipient_team,context) liefert explizites Fullprojection-
Envelope, niemals Legacy-Teilsnapshot. Kontext: own_unit_ids,visible_unit_ids,
fireteam_team_ids und reference_provenance="host_raw" sind Pflicht; optionale
explizite craft_team_ids/asset_team_ids fuer V1-
Nebenlisten ohne eigene Teamprovenienz. Contacts.team_id bezeichnet das Ziel;
Observerteam kommt aus dessen fireteam_id. Fehlender Kontext/Version reject.
project_reliable_vitals(vitals,v1_dto,recipient_team,context) verwendet denselben
Identitaetsfilter. V1normalizer beschraenkt ausgegebene Felder auf bekannte DTOs.

## Akzeptanz / Strategie
Eigene Unitdaten vollstaendig; sichtbare Gegner nur Displayallowlist. Eigene
Plan-/Skill-/Orderlisten bleiben erhalten, gegnerische Interna entfallen.
Verdeckte IDs und zugehoerige Positionen/Referenzen aus allen Nebenlisten
entfernen; ungekoppelte eigene Zielgebiete bleiben. Unzuordenbare Assetdaten
failclosed statt Omniscient-/Spectatorfallback. Keine externen Aliase.

## Pruefung / Risiken
Kleine reine Zwei-Team-DTOfixture mit realem V1normalizer, Referenz-/Nebenlisten-,
Reliable-/Version-/Noaliaspruefung in privatem Projekt/Profil. Root-Sichtbeweis,
Senderintegration und neuer Fullprojection-Receiver bleiben Anschlussarbeit.
Raw-V1 darf das neue Envelope nicht versehentlich als Teilsnapshot akzeptieren.

## Unverzichtbare Sendergrenze
Input ist urspruengliches V1-shaped HostDTO MIT noch vorhandenen Kopplungs-
referenzen, vor verlustbehafteter V1-Normalisierung. Der bisherige V1normalizer
verwirft z.B. target_unit_id an commander_intents, behaelt aber target_position.
Nach diesem Verlust kann kein Filter freie eigene Zielgebiete von verdeckten
Unitpositionen unterscheiden. reference_provenance ist daher eine ausdrueckliche
Callerzusage, kein vom Helper erzeugter Sichtbeweis. Upstreamgetter duerfen die
Kopplung nicht vorher verlieren; andernfalls ist dieser Senderpfad noch nicht
anschliessbar. Kein spekulativer Positionsassoziationscontext wurde eingefuehrt.

## Envelope / Aktivierungsgrenze
Erfolg: {ok:true,schema_version:2,projection_schema:"multiplayer.visible_state.v1",
projection_scope:"full_recipient_state",recipient_team,tick,snapshot:<gefiltertesV1>}.
Die2 bezeichnet ausschliesslich das neue vorbereitete Envelope; bestehender
MultiplayerSnapshotContract bleibtV1 und lehnt diesen Wrapper ab. Reliablefunktion
liefert scope="recipient_vital_delta" mit vital_updates statt snapshot und gleichem
IDfilter. Receiver muss diese Scopes explizit implementieren; die Fullprojektion
insbesondere darf fehlende zuvor sichtbare Actors nicht einfach weiteranzeigen.

## Freeze / Nachweis
20/0, beide EinzelcompilesExit0, Quelle-/Originalprofilhashschutz und privater
Canary true. Tatsächlicher V1normalizer, Zwei-TeamDTO, alle bestehenden Nebenlisten,
eigene unbelegte Zielgebiete, verdeckte gekoppelten Referenzen, Kontakteobserver,
ReliableVitals, sichtbare Gegner ohne Interna, unbemannte Ownassets mit expliziter
Provenienz, Konflikt-/Unknownprovenienz und Noalias. Rootfreie Closure genau fuenf
Scripte (Helper/Verifier/V1/Roster/Isolationguard). Kein vorhandenes Produktfile
oder Sharedrunner geaendert, kein Stage/Commit, keine fullAP7-/MP-/Nativeabnahme.
