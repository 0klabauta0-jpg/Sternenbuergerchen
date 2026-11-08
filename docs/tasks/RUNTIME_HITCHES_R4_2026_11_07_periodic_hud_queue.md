# R4: periodische HUD-Arbeit auf begrenzte frische Phasen verteilen

## Problem und Sinnhaftigkeit
Im gueltigen90-s-Fenster `final_native_combat/20261107T095411Z-7b78133e`
lagen die groessten Frames bei156,7/129ms mit60-75ms Controller-UI-Arbeit;
Runtime-Surfaces30-40ms, Secondary-RAW15ms und Primary9-11ms liefen zusammen.
Fog kostete dort0-2ms. Der gesamte Lauf war wegen einer gesonderten erfolglosen
Kampfprobe rot; das stabile90-s-Fenster ist kein Gesamt-PASS. Weiteres
Mikrotuning oder kleinere Sichtbudgets adressieren diesen UI-Burst nicht.

## Ziel / Umfang / Owner
Nur der periodische Controller-`_process` darf seine bisher gebuendelte schwere
HUD-Projektion anfordern und verteilen. Feste vier Keys:
`primary_secondary`, `craft`, `world_status`, `cards`. Primary+Secondary samt
RAW/Legacy-Matrix bleiben in einem synchronen ReadModel-Pass, weil echte
Legacy-Buttongates die beiden Texte gemeinsam auswerten. Die anderen Phasen
lesen bei ihrer Ausfuehrung ebenfalls frisch und oeffnen/schliessen einen
eigenen synchronen ReadModel-Pass. Ueber Frames bleiben nur Jobkeys, Force-/
Generation-/Zeit-/Zaehlerdaten; keine Runtime-/RAW-/ReadModel-Dictionaries.

Der vorhandene UpdateManager darf `Controller.refresh_hud` bedienen. Genau
eine Phase pro Renderframe; Folgeregistrierung erst deferred und zusaetzlicher
Engineframeguard gegen mehrfachen Drain. `MAX_BATCH_SIZE20`, AI und globaler
Manager bleiben unveraendert. Der Controller bleibt der UI-Arbeitsowner.

## Synchronitaet / Dirty / Cancel / Reentry
- Explizites `_update_ui(bool,bool)` behaelt die vorhandenen Argumente und
  synchronen Ausgabe-/Callback-/Gate-Vertrag. Ein vollstaendiger Aufruf
  supersediert aeltere Heavyjobs und entwertet alte deferred Tokens.
- Command-Light `_update_ui(false,false)` wirkt sofort und laesst angeforderte
  Heavyarbeit bestehen. Sonst wuerden Move/GO-Nachrichten unvollstaendige
  World-/Cards-Arbeit als erledigt verwerfen.
- Periodischer Heavy-Due fordert nur die vier Keys an; er fuehrt nicht daneben
  Primary plus Phase0 im gleichen Frame aus. Die bestehende Lightkadenz bleibt.
- Wiederholte Requests coalescen pro Key, erhalten die bisherige Reihenfolge
  und staerkstes Force. Request/Reentry waehrend eines Jobs darf nicht durch
  dessen alten Completiontoken verlorengehen. Fullsync-Reentry darf keine
  alte deferred Queue wiederbeleben. Maximal vier pending Keys.
- Ziel bei verfuegbarem Manager ohne Konkurrenz ist ein Zyklus in vier
  Renderframes. Das ist keine allgemeine16-ms- oder harte Echtzeitgarantie;
  Contention/Age und echte Phasekosten werden nativ separat geprueft.

## Akzeptanz / gezielter RED
Echter Controller samt authored Controls, UpdateManager und Runtimequellen.
Der Verifier zwingt ausschliesslich UIkadenz-/Dirtyflags, ruft `_process(0)`
auf und beobachtet echte Super-Phasengrenzen. Das ist ein synthetischer
Schedulingnachweis, kein physischer Bewegungs-/FPS-Test.

1. Der periodische Heavyrequest erzeugt noch keine der vier schweren
   Ausgaben; der heutige synchron gebuendelte Pfad wird als echter RED sichtbar.
2. Echter Manager-HUD-Batch bedient maximal eine Controllerphase pro
   Renderframe, auch bei zweitem Drain und deferred Reregistrierung. Ein
   konkurrierender HUDpeer wird weiter bedient. Normale Requests vervollstaendigen
   alle vier Keys ohne dauerhaftes Weglassen.
3. Primary/Secondary/Legacy-Matrix haben denselben aktiven frischen Pass und
   erhalten zusammen aktuelle RAWquellen. Light ist sofort, Full ist sofort
   vollstaendig; beide vorhandenen APIs bleiben kompatibel.
4. Coalescing, Reentry-Request, Light waehrend pending und Full waehrend drain
   behalten alle neuesten Anforderungen bzw. entwerten nur wirklich ersetzte
   Arbeit. Nach Fullcancel kein Wiederaufleben durch alte deferred Tokens.
5. Reine Request-/Drain-/API-Praesentation aendert weder Actor/HP/Position/
   Runtimeposture noch Tick, Plaene oder Command-/Effectqueue. UI-Metadaten und
   reine Presenter-Caches sind keine Gameplaywahrheit.
6. Getter liefert defensive Scheduling-/Timingdaten mit requested/completed/
   coalesced/work je Key, pending/generation/maxPendingAge/maxPendingKeys;
   Arbeitszaehler und vorhandene Apply-/Skipzaehler erlauben nativ den Nachweis,
   dass der Gewinn aus Verteilung statt weggefallener Arbeit kommt.

## Dateien / Dokumente / Nicht-Ziele
Task und neuer Verifier
`runtime_hitches_r4_20261107_periodic_hud_queue_verifier.gd` wurden vom
Perf-Auditagenten vorbereitet; die Taskpflege ist nach dessen Guard-QA an
den Controllerwriter uebergeben. Produkt ausschliesslich Controllerwriter nach Root-RED
und separater Freigabe; Root ist einziger Engine-/Gitrunner. Keine Aenderung
an UpdateManager, Simulation, KI, Fog-/Cadence-/Actor-/Qualitaetsbudgets,
keine API-/Override-Signaturaenderung und kein globales UI-State-Cache.
AGENTS, ARCHITECTURE, CODEX_RULES, mission_hud_projection_authority_contract,
R4-Haupttask und Strategic-Source-Task gelten weiter. Explizite Full-API,
Command-/Move/GO-/R3-/ReadModel-/Popup-Nachbarn und native Vollbildmessung
sind eigene Gates. Umsetzung und ihr noch ausstehender Nachweis stehen unten.

## API-Abgleich / offener Status
Abgestimmt: `_request_periodic_hud_projection(force_refresh: bool)`,
`get_periodic_hud_projection_queue_debug_snapshot()` und Managercallback
`refresh_hud()`. Telemetrykeys `pending_keys`, `generation`,
`requested_counts`, `completed_counts`, `coalesced_counts`, `work_counts`,
`max_pending_age_msec`, `max_pending_keys` mit den vier festen Jobkeys.
## Gebundener RED / freigegebener Produktumfang vor Umsetzung
Root-RED `periodic_hud_queue_red/20261107T103113Z-87b36b51/`:0/2, keine
Enginefehler, stabile Quellen. Vier echte Supergruppen erscheinen im selben
Frame11; Request-/Manager-/Diagnose-API fehlt. Verifier unveraendert SHA256
`e53d4f4a33e6eb22b22366ac592e02f55dc447da2aa904e99d04be64ac1f9767`.
Root delegiert den Produktpatch exklusiv an den Controllerwriter.

Die freigegebene Umsetzung darf einen reinen RefCounted-Metadatenhelper
`scripts/tactical/periodic_hud_projection_queue.gd` einfuehren. Er besitzt
nur vier feste Keys sowie Force, Generation, Ticket-/Enqueuezeiten und
Zaehler; keine Node-/Callable-/Ownerreferenzen oder Runtime-/RAWdaten.
Controller bleibt Aufruf-/Projektionsowner; UpdateManager-Core bleibt gleich.
Coalescing veraendert weder Keyreihenfolge noch bisherige Enqueuezeit.

Fullsync cancelt VOR seiner Arbeit, damit neue Requests waehrend seiner
Ausfuehrung nicht am Ende verworfen werden. Akzeptierter periodischer Request
uebertraegt bestehendes Command-Force in die vier begrenzten Jobmetadaten;
eine spaetere Command-Light-Nachricht bleibt als neue Anforderung bestehen.
Eine alte Completion darf weder neue Keyanforderung noch neuen Force loeschen.
Ohne verfuegbaren Manager innerhalb der Szene bleibt der bisherige explizite
Fullrefresh der synchrone Fallback; detached/Sceneexit meldet keine neue Arbeit
an und entwertet alte Deferredtokens.

Debug liefert maximal2048 reine Phasensamples mit Engineframe, Beginn/Ende,
Key, Force und Superseded-Ergebnis; keine Sourcepayloads. Diese externen
UpdateManagerzeiten sind getrennt vom Controller-_process-Walltime zu lesen.
350ms-Light und1s-Heavy sowie alle Gameplay-/Qualitaetsbudgets bleiben gleich.
GREEN, Lifecycle/Source-Review und native Leistungswirkung PENDING.

## Angrenzende Guard-QA nach dem urspruenglichen RED
Nach Rootreview ergaenzt der Verifier vor dem zweiten SameFrame-Batch einen
echten oeffentlichen `UpdateManager.mark_hud_dirty(probe)`-Aufruf. Ein sonst
leerer Batch wuerde den Controller-Frameguard nicht pruefen. Zusaetzlich
werden alter Managerentry, synchroner Fullcancel und frischer Request im
selben Frame kombiniert: kein weiterer Heavyjob in diesem Frame, aber
vollstaendige spaetere Bedienung der neuen Generation. Managerentries haben
selbst keine Generation; diese Grenze muss der Controller bewahren. Das
ist neue angrenzende Guard-QA nach dem urspruenglichen0/2-RED, keine
nachtraegliche Umdeutung dieses Ursachenbelegs. Originalartefakt und dessen
Verifierpin bleiben als historische Aufnahme unveraendert dokumentiert.

## Umsetzung / Source-Freeze vor Engine-GREEN
Der Controller fordert periodisch nur die vier Keys an und bedient ueber
`refresh_hud()` einen Key pro Engineframe. Reiner RefCounted-Helper
`scripts/tactical/periodic_hud_projection_queue.gd` enthaelt ausschliesslich
primitive Schedulingmetadaten. Tickets werden vor Ausfuehrung entfernt;
Reentry kann denselben Key neu anfordern, ohne durch die alte Completion
geloescht zu werden. Fullcancel entwertet vorher die Generation und sperrt
denselben Frame auch gegen alte bereits registrierte Managerentries.
Deferredregistrierungen pruefen Generation und Scenezugehoerigkeit.

Die bestehende synchrone API und ihre Methodensignaturen bleiben. Ihr
Projektionsbody und der Runtime-Surfacebody wurden source-seitig exakt
gegen den bisherigen Body verglichen: ausschliesslich Cancel-/Wrappergrenze,
die drei festen Gruppenguards und reine Timingmetadaten sind hinzugekommen.
Jeder Managerjob schliesst seinen eigenen frischen ReadModel-Pass. Fehlender
Manager faellt synchron auf Full zurueck und wird im Timing entsprechend
markiert. Sceneexit cancelt; detached Requests melden nichts neu an.

Phasehistory ist debug-only, als2048er-Ring begrenzt und enthaelt nur Key,
Force, Generation/Ticket, Enqueuezeit, Start-/Endzeit, Frame und
Superseded-Ergebnis. Der Getter kopiert sie defensiv fuer den einmaligen
Nach-Fensterabruf; keine per-Frame-Diagnoseabfrage im nativen Messfenster.
Lifetime-MaxAge kann eine nachgelagerte Evidenz-I/O-Pause enthalten. Fuer
Window-Aussagen sind die einzelnen Zeitstempel zu filtern. Externe
Managerphasen sind nicht im Controller-_process-Walltime enthalten.

Lokale Sourcepruefung: `git diff --check` sowie exakter Bodyvergleich gruen;
keine Engine durch den Controllerwriter. Aktueller angrenzender Verifierpin
nach Guard-QA: `262942382f541d066ea98cf7135647698d47b7e2033668bcb73e54e4c87682f3`.
Root-GREEN, unabhaengiges Lifecycle-/Source-Review und native Vollbildwirkung
sind noch PENDING. Keine Ruckelfreiheits-/FPS-/Mainfreigabe aus Sourcechecks.

## Gezielte Forceuebernahme-QA aus unabhaengigem Produktreview
Auf Freeze793A8CCC/CABE261A wurde ein konkreter P2 gefunden: Der normale
Fullwrapper cancelt die Queue, bevor er deren staerkere Forceanforderung
uebernimmt. Nach erfolgreichem Enqueue ist das Commandpending bereits in
die Tickets uebertragen; `_update_ui(true,false)` kann deshalb unveraenderte
Craft-/Cards-Gruppensignaturen ueberspringen und die Anforderung verlieren.
Der neue enge Verifierfall primt die echten Gruppenguards, enqueued ForceTrue
ohne Actor-/Ownerfortschritt und verlangt anschliessend echte Craft-/Cards-
Superaufrufe bei Full(false), unmittelbaren Abschluss und Ownerreinheit.
Die staerkste Ticket-/Pending-/Argumentforce muss VOR Cancel gelesen werden;
neue Requests waehrend des synchronen Fullbody bleiben weiterhin erhalten.
Dies ist angrenzende Review-QA, kein Umschreiben des urspruenglichen0/2-RED.
Produkt bleibt bis zum neuen Root-RED und separater Freigabe eingefroren.

Root-RED `periodic_hud_force_red/20261107T110228Z-6af2c55a`:58/1, keine
Enginefehler, stabile Quellen. Reale Fullboundary zeigte nur World/Status
und Primary/Secondary; die angeforderte Craft-/Cards-Arbeit fehlte exakt.
Aktueller Verifierpin `82ff94e036d28323aa055cd770d620878ed14d87bb18d778f6c2d7d3a9349046`.
Root gab ausschliesslich die Forceuebernahme vor Cancel frei. Der Wrapper
uebernimmt jetzt Argument OR Commandpending OR staerkste Ticketforce, dann
cancel und unveraenderter Fullbody. Keine weitere Produkt-/Helperaenderung.
Root-GREEN und nativer Vollbildnachweis weiterhin PENDING.

## Gebundener GREEN / Review
Rootlauf `periodic_hud_queue_green/20261107T110454Z-0a8a0ddc`:59/0,
keine Enginefehler, stabile Quellen. Controller SHA256
`b247162e46edaca4e5696c9d96242384aca102ff03cb8f2e2c84c103627cddaf`,
Helper `cabe261aaf2b83dbd77454eeca6f0d21608bd4f8f0add1b1d4b6ecfa4f73d98f`,
Verifier `82ff94e036d28323aa055cd770d620878ed14d87bb18d778f6c2d7d3a9349046`.
Unabhaengiges Produkt-/Lifecycle-Review durch den Perf-Auditagenten:
APPROVED scoped, keine offenen P1/P2. Unabhaengiges Verifierreview durch
den Controllerwriter (nicht dessen Testautor): APPROVED scoped; Grenzen
stehen in `docs/reviews/RUNTIME_HITCHES_R4_2026_11_07_command_review.md`.
Die finale Nachbarmatrix und zwei native90-s-Vollbildmessungen bleiben
separate ausstehende Gates.59/0 ist keine Leistungs- oder Mainfreigabe.
