# R4 Performance: unabhaengiger Produkt- und Lifecycle-Review

## Ergebnis und Rollen
**APPROVED scoped. Keine offenen P1/P2 in den unten gebundenen Produktbereichen.**
Reviewer: Perf-Auditagent, unabhaengig von den Produktwritern. Dieser Agent
hat mehrere fokussierte Task-/Verifierdateien selbst verfasst. Diese Tests
werden deshalb hier ausdruecklich **nicht** als unabhaengiges Testreview
ausgegeben. Engine-, Native-, Git- und Mainnachweise liegen ausschliesslich
bei Root. Dieser Review fuehrte keine Engine und keine Produktmutation aus.

## Gebundene Quellen
- Controller: `scripts/tests/mission_tactical_sandbox_controller.gd`
  SHA256 `b247162e46edaca4e5696c9d96242384aca102ff03cb8f2e2c84c103627cddaf`.
- Reiner Schedulinghelper: `scripts/tactical/periodic_hud_projection_queue.gd`
  SHA256 `cabe261aaf2b83dbd77454eeca6f0d21608bd4f8f0add1b1d4b6ecfa4f73d98f`.
- Separat zuletzt gepruefter Posefeed-Delta im TerrainView:
  SHA256 `fb9905172a9115c6458a90c3fdb896895c0576978bd999a6567c7711458b60f2`.
- Dazu gemeinsame reine Eventauswahl `weapon_fire_feedback_layer.gd`:
  SHA256 `3087b4abdcc92c93a3449187bab623899b2d520e78f161194d77a329be75db84`.

## Periodische HUD-Queue / Autoritaet / Lifecycle
Der vier-Key-Helper haelt ausschliesslich primitive Job-, Force-, Generation-,
Ticket-, Zeit- und Zaehlerdaten. Keine Nodes, Callables, Actors oder RAW-/
Runtime-Snapshots werden fuer spaetere Frames gehalten. OR-Coalescing erhaelt
FIFO und die aelteste Enqueuezeit. Take entfernt den Key vor der Projektion;
Completion beruehrt nur ihr Ticket und loescht keinen reentrant neu
angeforderten gleichnamigen Key.

Der Controller bleibt Projektionsowner. Vorhandener UpdateManager-Core und
AI-Batch wurden nicht geaendert. Deferred Reregistrierung plus Engineframe-
Guard verhindern einen zweiten Job im selben Frame, auch nach synchronem
Fullrefresh und bei einem alten Managerentry ohne eigene Epoch. Deferred
Tokens pruefen Generation und Treezugehoerigkeit. Exit cancelt; detached
Requests registrieren nichts. Fehlender Manager innerhalb einer aktiven
Szene faellt auf den bestehenden synchronen Fullpfad zurueck.

Jede Phase oeffnet/schliesst einen eigenen frischen ReadModel-Pass. Primary
und Secondary einschliesslich RAW/Legacy-Matrix bleiben zusammen, ihre
textabhaengigen Gates werden nicht in unterschiedliche Frames aufgeteilt.
Lightfeedback bleibt unmittelbar und erhaelt ausstehende Heavyjobs. Full
bleibt synchron und entwertet alte Arbeit vor dem Projektionsbody; danach
reentrant erzeugte Anforderungen bleiben erhalten.

Unabhaengiger Bodyvergleich: Der UIbody unterscheidet sich nur durch die
ausgelagerte Force-/Cancelgrenze und den expliziten Runtime-Skip fuer Phase0.
Der Runtime-Surfacebody entspricht nach Entfernen der drei Gruppenguards
dem bisherigen Body bis auf reine Timingtags. Bestehende Getter-, Command-,
Slot-, Callback- und explizite Full-/Light-Signaturen bleiben erhalten.

## Gefundener und geschlossener P2
Im ersten Queue-Freeze793A8CCC wurde Queued-Force bei normalem
`_update_ui(true,false)` vor seiner Uebernahme geloescht. Commandpending war
bereits in die Tickets transferiert; damit konnten unveraenderte Craft-/
Card-Signaturen die gewuenschte Forcearbeit ueberspringen. Root reproduzierte
den gezielten angrenzenden Fall mit58/1. Der finale B247162E-Hunk uebernimmt
Argument-, Commandpending- und Ticketforce **vor** Cancel. Der Sourcebefund
ist damit geschlossen; der neue Root-GREEN bleibt ein eigener Nachweis.

## Weitere eng gepruefte Controllerbereiche
Lokale Shared-Sources fuer 2D/3D/Intent-Preview bleiben auf einen synchronen
Aufruf beschraenkt; Consumer kopieren defensiv. Der entfernte doppelte
GO-Buttonpass bleibt im finalen Feedbackowner vor derselben Publikation.
Native Karten-/Craftguards unterbinden nur konkurrierende besessene
Praesentationsfelder, nicht Runtimequellen, Metadaten, Tooltips oder Gates.
Strategic-OneScreen/Handoff teilt einen lokalen frischen NextInteraction;
Standalone, explizit leerer Input und Reentry behalten ihre Grenzen. Hidden
RAW wird wegen echter Detail-/Actionkonsumenten weiterhin erzeugt.

GO-Debug erhaelt alle acht Outcomes und die Commandfolge. Es liest nur
vorhandene Debugdaten, Zeit, Frame und Zaehler; acht fertige Receipts plus
synchroner Reentrystack, defensiver Getter und Leeren bei Debugaus. Kein
zusaetzlicher Gameplaygetter oder neuer Runtimecache wurde eingefuehrt.

## Enger abschliessender Posefeed-Review
Layer und Poseindex waehlen gemeinsam echte aktuelle Events nach Firetick/
stabiler Driver-ID, ueberspringen markierte History und behalten das neueste
Event pro Quelle bis maximal acht Quellen. Die frische defensive Payload
wird vor der neuen Feedrevision publiziert; der kleinere Heavy-Dreier-
Earlyreturn kann eine geaenderte Posequelle nicht mehr verschlucken.
Indexinvalidierung liest Feedrevision und vorhandene FoW-Signatur. Die
begrenzten Eingaben werden nur bei Payloadankunft serialisiert, nicht je
Proxy/Frame. Bestehende FoW-Admission, First-receipt-/No-Replay-Grenze und
Pulse-Lebenszeit werden dadurch nicht ausgehebelt. Keine Actor-/Facing-/
Combatmutation und keine neue Sicht- oder Eventwahrheit im Helper.

## Nachweisgrenzen
- Urspruenglicher Scheduling-RED0/2, angrenzende Frame-/Fullcancel-Guard-QA
  und Force-RED58/1 sind getrennte historische Rootlaeufe. Keine alten
  Artefakte oder Erwartungen wurden in diesem Review umgeschrieben.
- Phasensamples sind debug-only, auf2048 begrenzt und werden vollstaendig
  erst nach dem nativen Messfenster gelesen. Managerphasen liegen ausserhalb
  der Controller-_process-Walltime; ihre Zeitstempel muessen separat zugeordnet
  werden. Lifetime-MaxAge kann nachgelagerte Evidenz-I/O enthalten.
- Vier Frames sind das Ziel ohne Managerkonkurrenz, keine harte16-ms-Zusage.
  Source-Review beweist weder Ruckelfreiheit noch gleiche native Arbeitsmenge.
  Root muss Requests/Work/Completions/Coalescing/Age und Apply-/Skipzaehler
  zusammen mit gleicher Kamera, Route, Rate und Qualitaet vergleichen.
- Native Verteilung, Pixel-/Achsen-/echter Fire-Event-Nachweis, ganze
  Regressionen und Mainintegration sind separate Root-Gates. APPROVED scoped
  ist keine Release-, Gesamt-FPS- oder visuelle Nutzerabnahme.
