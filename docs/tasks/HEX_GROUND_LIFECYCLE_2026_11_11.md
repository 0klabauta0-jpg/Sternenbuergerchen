# AP6: Hex-Gruppenzulassung und NPC-Lifecycle

## Ziel / Ursache

Der Ground-Owner führt Bewegungen exklusiv aus. Die bestehenden Setup- und
Transportadapter können dagegen noch mehrere Personen auf denselben Anker
setzen oder einen Groundclaim beim Einsteigen behalten. Eine reine vorgelagerte
Platzsuche reicht nicht: Annahme und Veröffentlichung müssen zusammenpassen.

## Umfang und Nicht-Ziele

Erster integrierbarer Schritt: reine, auf 64 expandierte Felder begrenzte
Gruppenplatzierung; atomare Root-Zulassung tatsächlich registrierter Missions-
Actors; gemeinsame Freigabe beim Einsteigen und idempotentes Entfernen.
Aktive Kanten und vollständige Korridorgrants sperren auch die Zulassung.

Danach folgen im selben AP6 die phasenerhaltende Aussteigeanbindung mit
Ground-eigenen Platzvormerkungen, MissionSetup und der schmale Basisadapter.
Diese erste Lieferung aktiviert die bisherigen Transport-/Setupadapter noch
nicht. Keine Produktionskarte, neue Transportwahrheit, Mainintegration, EXE,
großen Gefechts-, Grafik- oder Performancetests.

## Relevante Dokumente

- `docs/superpowers/plans/2026-11-11-hex-sight-occupancy.md`, AP6
- `docs/superpowers/specs/2026-11-11-hex-sight-occupancy-design.md`
- `docs/dev/explicit_hex_ramps_contract.md`
- `docs/dev/hex_tactical_runtime_contract.md`
- `docs/dev/base_automatic_rest_contract.md`
- Parent: `docs/tasks/AP6_LOCATION_ADMISSION_AUDIT_2026_11_11.md` auf 346144881

## Akzeptanzkriterien

- Vier Personen erhalten vier verschiedene, vom Anker legal erreichbare Zellen.
- Bei drei freien Zellen wartet die gesamte Vierergruppe; keine Teilmutation.
- Suche benutzt die sechs kanonischen Registryübergänge einschließlich
  Rampenendpunkten H/H+1 und seitlich H+0,5; keine Zulassung über eine Klippe.
- Belegte Felder, beide Enden noch aktiver Kanten und ganze geschlossene
  Passagegrants sind gesperrt. Suche überschreitet keine solche Sperre.
- Root prüft alle tatsächlichen Actor-/Registryidentitäten vor dem ersten Write.
  Eine permanente Basisprojektion ist kein Missionsactor.
- Einsteigen gibt Ground, Moveabsicht und Zusagen frei, erhält die Actoridentität.
  Ein Verwundeter am Boden behält seinen Platz bis zum expliziten Entfernen.
- Zweimaliges Entfernen ist ein No-op; ein anderer Ortsroot bleibt unverändert.
- Aussteigephasen, Same-Deck-Übergabe und reale Besuchsmitgliedschaft bleiben
  beim bestehenden Transportowner. Die vollständige Gruppenplanung muss vor
  dessen erster neuer Groundzulassung erfolgen.

## Betroffene Dateien / lokale Prüfung

Neu: `scripts/mission/hex_ground_admission.gd`,
`scripts/tests/hex_ground_lifecycle_verifier.gd`.
Ändern: Ground, Root und der private `run_hex_tactical_check.py`.
Kleiner isolierter Case `--case lifecycle`, unmittelbar betroffene Ground-/
ReservationOwner-Nachbarn, Quell-/Profilguards und frischer enger Review.
Weitere Adapteränderungen erhalten eigene kleine Prüfungen vor Integration.

## Risiken / offene Punkte

Statische Platzvergabe allein schützt noch keine gestaffelte Aussteigesequenz.
Vormerkung und deren Abbruch-/Kontextbereinigung sind der nächste Teilschritt.
Fremde Schiffsfootprints müssen aus dem vorhandenen Objekt-/Transportowner
kommen; keine Ersatzliste im UI. Save/Restore und Peergrenzen folgen in AP7.
Arbeitsbasis ist der nicht auf Main integrierte Rampenstand 97e00aba1 plus
die auf `task/hex-ground-foundation-20261111` geprüften AP1–5-Pakete.

## Zweiter Teilschritt: verbindliche Aussteigeplätze

Root bereitet eine vollständige Gruppe vor und erhält ein kontextgebundenes
Admissionticket. Ground hält dessen noch ungenutzte Plätze. Personen an Bord
erhalten dabei keine Groundzelle. Pro vorhandener Aussteigephase konsumiert
genau ein tatsächlicher Deployeffect genau seinen Platz. Falsches/altes Ticket
bewirkt keine Anwesenheits- oder Registrymutation. Claims sperren auch Bewegung,
Türschluss und andere Zulassung; der Owner prüft unabhängig vom Planer.

Abbruch gibt nur verbleibende Vormerkungen frei, bereits ausgestiegene Personen
bleiben am Boden. Entfernen eines noch vorgemerkten NPCs verwirft die verbleibende
Gruppenvormerkung; Kontextwechsel räumt alle Tickets. Unpassierbare oder nicht
mehr kanonisch verbundene geplante Felder verhindern die Fortsetzung.

Kleiner Case `--case admission_slots`, gleiche isolierte Prüfbasis. Die konkrete
Transportsequenz publiziert ihren Fortschritt erst nach dem tatsächlichen
Rootcommit. Legacykarten behalten den bestehenden Effektpfad.

## Gesicherter Teilstand

AP6a `86347ca54`: Gruppenplatzierung und registrierte Missionsactorprimitive,
Lifecycle64/0, Ground25/0, ReservationOwner36/0; Parentintegration `69194ddab`.

AP6b: Slotcase87/0, Backoff55/0, Planer26/0 und Owner56/0. Tatsächliche Root-
Transporteffects, gestagte Actors, Slotabbruch, Terraininvalidierung, Tree-Exit,
stale Registry und alte Queuepayloads geprüft. Frischer enger Review schloss
stalen Registryschlüssel und leeren Releasegrund. Diese Lieferung ist weiterhin
ein Teilpaket: konkrete Controller-/Setup-/Basisproducer folgen vor AP6-Abschluss.

Integrationsreview AP6b: Registrylookup allein beweist noch keine Root-Lifecycle-
Bindung. Tatsächliche Actorzulassung verlangt deshalb den expliziten Known-Eintrag
desselben Actors, dessen Tree-Exitcleanup beim Binden verbunden wurde. Kleiner
Registry-only→Admission→free-Fall, keine Erweiterung der Prüffläche.

## AP6c konkrete Aussteigeproducer

Die bestehenden primären/parallelen Sequenzen behalten Zeitintervalle und ihren
unit_index. Ein schmaler Missionsadapter bereitet die Gruppe im Root vor und
sendet den vorhandenen Deployeffect mit optionaler admission_id. Fortschritt
und deployed/embarked-Projektionen werden erst nach tatsächlichem Groundcommit
publiziert. Der Ground hält die Herkunft seiner Zulassung als Receipt, damit ein
schon weitergelaufener NPC den erfolgreichen Ausstieg nicht nachträglich verliert.
Pollendes Rendern erzeugt keine doppelten Effects oder vorzeitigen Feldwechsel.

Offener Folgeschritt: echte Card-/Sequence-/Visit-Landestände liefern fremde Schiffsflächen;
inaktive Orbitflugpositionen sind keine Groundfootprints. Fehlende erforderliche
Schiffsgeometrie führt zu Warten. Primär→Parallel-Handoff überträgt nur den
Ticketbeleg; wirklicher Abbruch gibt Restslots frei. Parent besitzt weiterhin
Same-Deck-/Transport-/Besuchsmitgliedschaft, Basis-/Setupanschluss folgt danach.

Kleine Fixture `--case deployment_phase`: kein Fortschritt vor Roottick, kein
Duplikat beim Polling, Ausstiegsbestätigung auch nach Bewegung, einzelner
Folgeausstieg und Abschluss durch den vorhandenen Sequenzowner.

Transportteil klein geprüft: Phase95/0 und tatsächlicher vollständiger Controller73/0,
jeweils private Projekte ohne Hauptszene. Die Controllerprobe deaktiviert nur
Ready-/UIcallbacks und liefert bekannte Crew-/Mapeingaben; Ausstieg, Timer,
Handoff, Retirement, Root, Registry und Effects sind echte Produktkörper.
Review schloss verdoppelte Kadenz, parallelen Ticketverlust und Legacyfallback bei
fehlendem Hexowner. Zusätzlicher echter Zwischenzustand Rootcommit vor Receiptpoll
verlangt die Root-Präsenz statt nur des verzögerten deployed-Readouts beim Retirement.

Parent behält seine neuere exakte `_campaign_craft_crew`-Auswahl und alle Team-/
Visit-/Solo-Pilotregeln. Im Retirement werden nur die eine Root-Präsenzbedingung
und der Cancelcall für die konkrete gespeicherte craft-Sequenz ergänzt.
Fremde Footprints, reguläre Bindung akzeptierter Schiffsgeometrie, Setup und
Basisaktionen sind noch keine Lieferung dieses Transportteilpakets. Danach AP7/8.
