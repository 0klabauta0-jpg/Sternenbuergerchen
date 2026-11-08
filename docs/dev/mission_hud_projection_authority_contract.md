# Mission-HUD: Projektion und Runtime-Autoritaet

Stand: 06.11.2026; Task `HUD_ARCHITECTURE_2026_11_06`.

## Datenfluss

`SimulationRoot` und die bestehenden Runtime-Komponenten verarbeiten Commands
und Interaktionen. `MissionCombatLoopDriver` besitzt die Interaction- und
Missionsablaufdaten. Er veroeffentlicht daraus den effektiven Tuerindex in der
`TerrainRegistry`. Navigation und LOS lesen diesen Index. HUD und 3D-Ansicht
lesen die zugehoerigen Snapshots; ihre Anwesenheit und Auswahl beeinflussen den
Index nicht.

## Tuerindex

- Configure, Interaction-Fortschritt, autoritativer Remote-Snapshot und
  Runtime-Tick aktualisieren die abgeleitete Projektion.
- Es gibt keine zweite gespeicherte Offen/Geschlossen-Wahrheit. Bindings und
  echte Kartenmarker verorten den vorhandenen Interaction-State.
- Die gemeinsame Oeffnungsgrenze liegt bei 85 Prozent aktiven Fortschritts.
  Unterbrechung schliesst eine unvollendete Tuer. Fehlende Marker erzeugen
  keinen erfundenen Override am Ursprung.
- Registry-Identitaet, Revision und Markerkoordinaten invalidieren die
  Projektion. Nach dem Apply wird die resultierende Revision gespeichert;
  unveraenderte Ticks erzeugen keine eigene Revisionsschleife.
- Der Getter liefert eine defensive Receipt-Kopie. Externe Index-/Marker-
  aenderungen markieren diese Kopie ungueltig, reparieren aber nichts beim
  Lesen. `producer_applied` beschreibt den letzten Producer-Pass;
  `producer_index_current` beschreibt die Zulassung dieser gelesenen Receipt.
- Der historische Controller-`apply_*`-Einstieg bleibt ein Kompatibilitaets-
  **Lesezugriff**. Er schreibt weder Registry noch Controller-Doorstate.
  `ObjectReaction` uebernimmt nur eine aktuelle angewandte Runtime-Receipt.
- Initiale Clients lesen Remote-Publikationen. Ohne neue Publikation ist ein
  externer Registryumbau auf einem initialen Client kein hier abgenommener
  Lifecyclepfad; ein HUD-Refresh darf diesen Fall nicht heimlich reparieren.

## Missionsablauf und Countdown

`get_playability_snapshot`, `get_objective_countdown_snapshot`,
`get_mission_scenario_runtime_gate_snapshot` und
`get_mission_cargo_touchdown_snapshot` schreiben keinen Gameplay-State.
Configure, Runtime-Updates und der autoritative Tick halten die Quellen frisch.
Die Kampf-Startpause unterdrueckt weiterhin Kampfentscheidungen; der vorhandene
Gate-/Countdown-Publisher laeuft dort weiter. Der Client-Authority-Guard bleibt
vor dieser Arbeit. Eine Getterabfrage ersetzt keinen Tick.

## Begrenzte HUD-Lesevorgaenge

Der vorhandene `MissionHudReadModel` teilt reine Combat-/Decision-Projektionen
nur innerhalb eines synchronen `_update_ui`-Durchlaufs. Ende, Framewechsel und
Revision verwerfen Werte; Dictionary-/Array-Ergebnisse werden defensiv kopiert.
Rekursive Produzenten duerfen keine kontextabhaengigen Fallbacks in diesen
Cache legen. Ein neuer Command-Refresh im selben Frame bekommt einen neuen
Lesevorgang. Ausserhalb des Passes wird direkt gelesen.

Auch reine Interaktions-Use-State-Projektionen duerfen in diesem bestehenden
synchronen Pass geteilt werden. Ihre alte Producerkette bleibt unveraendert;
pro Lese-Generation wird sie nur einmal fuer wiederholte Top-Level-Abfragen
aufgebaut. Rueckgaben bleiben tief defensiv kopiert. Rekursive Producer lesen
weiter direkt, selbst wenn ein Top-Level-Eintrag existiert. Passende, Frame-
oder Revisionswechsel verwerfen alle Werte; ein waehrend des Produzierens
entwerteter Pass darf nicht durch die alte Completion neu gefuellt werden.
Objective-Gate und Use-Intent werden dadurch nicht gecacht. Neue Commands
behalten ihre synchronen Feedback-/Publikationsgrenzen. Zwischen Jobs oder
Frames verbleiben keine solchen Runtime-Snapshots.

Periodisch faellige schwere HUDarbeit wird ueber vier reine Jobkeys an den
vorhandenen UpdateManager uebergeben: Primary+Secondary/Matrix, Craft,
World/Status und Cards. Pro Renderframe laeuft hoechstens ein solcher Job.
Jeder Job liest innerhalb seines eigenen synchronen ReadModel-Passes frisch;
zwischen Frames bleiben nur Scheduling-/Force-/Generation-/Zeitmetadaten.
Wiederholte Anforderungen coalescen ohne Enqueuezeit oder Reihenfolge zu
erneuern; Reentry darf neu angeforderte Arbeit nicht als alte Completion
verbrauchen. Die350ms-Light-/1s-Heavyfaelligkeit bleibt bestehen.

Explizites `_update_ui(bool,bool)` bleibt synchron. Lightfeedback laesst
angeforderte schwere Jobs bestehen. Ein expliziter Fullpass entwertet aeltere
Jobgenerationen vor seiner Arbeit; neue Requests waehrend dieses Passes
bleiben erhalten. Fehlender UpdateManager nutzt in einer aktiven Szene den
bisherigen synchronen Fullpfad, Sceneexit/detached meldet keine neuen Jobs an.
Externe Manager-Phasentimings sind keine Controller-_process-Walltime und
werden in der nativen Diagnose getrennt gefuehrt.

Die Review-Identitaet aus unveraenderlichen OS-Startargumenten wird pro
Controllerleben einmal gelesen und defensiv kopiert. Explizite Argumente
bleiben separat auswertbar. Das ist Prozesskonfiguration; eine bestehende
Live-Peer-/Teamzuordnung wird weiterhin vorrangig live gelesen.

Kompakte Contact-/Playerdecision-Ausgaben bauen keine verworfenen ausfuehrlichen
Fallbackzeilen. Der Playerdecision-Snapshot wird davor weiterhin frisch
publiziert; der ausfuehrliche Pfad behaelt seine urspruenglichen Quellen.

MissionInteractionPointBinding darf den JSONparse genau eines identischen
Szenariotextes bis1MiB UTF-8 wiederverwenden. Jede Abfrage liest weiterhin die
Datei und projiziert aktuelle Runtime-/Marker-/Mapdaten neu. Fertige Bindings
oder Runtime-Snapshots werden nicht gespeichert; Textwechsel gleicher Laenge
oder gleicher Dateizeit werden anhand des vollstaendigen Inhalts erkannt.
Uebergrosse oder Nicht-Objekt-Eingaben werden nicht im Parsecache gehalten.

Die Live-Commandmatrix fuehrt ihre bestehenden Anzeige-Contracts einmal
vorwaerts mit den bereits vorhandenen RAW-Texten aus. Sie liest dafuer keine
anderen Panels rueckwaerts neu. Leere Inputs bleiben leer und blockiert. Alte
Diagnose-Getter bleiben explizit aufrufbar; Callback und GO bleiben die
bestehenden Command-Grenzen. Der feste historische Empfehlungskontext ist
weiterhin dokumentierte Legacy-Schuld, keine zusaetzliche Spielwahrheit.

## Sichtbare Darstellung

Die nativen A5-Primary-Actions besitzen ihren finalen Stil selbst. Der
generische Basisskin setzt sie nicht vorher zurueck. Andere Controls, ROE und
Tuer-Affordance behalten ihre bisherigen Presenter und Gates.

Eine effektiv versteckte A5-Memberreihe wird periodisch nicht neu aufgebaut.
Explizite Refreshes bleiben moeglich. Effektive Sichtbarkeit und A5-Besitz
gehoeren in die Gruppensignatur: Beim Reveal wird synchron frisch gelesen;
ein unveraenderter Folgeaufruf darf wieder uebersprungen werden. Sichtbare
Mini-Karten, Ad-hoc-Bereich und geoeffnete Charakterdetails bleiben aktuell.

Die konkrete laufende Order wird aus den bestehenden ausgewählten
Movement-/Area-/Profilquellen abgeleitet. Unbekannte oder gemischte Quellen
erfinden keinen gemeinsamen Move. Ein fokussierter kuenftiger Planbefehl
bleibt getrennt und vorrangig; Feedback, Pending und Ablehnungen bleiben erhalten.

## Nachweise

Die neuen `hud_architecture_20261106_*_verifier.gd` pruefen diese Grenzen als
Komponenten. Der Command-Batch-Nachbar prueft echte oeffentliche Move-/GO-
Commands, ihren Physics-Commit, aktuelle sichtbare Karten und frische Details.
Normales Spielen, native Bilder, Framezeiten und Mainintegration sind separate
Nachweise im QA-Paket; ein Komponententest ist keine visuelle Gesamtabnahme.


## Synchrone Wegpunktfinalisierung R8, 08.11.2026
Der verbundene Client-Planungseinstieg und der direkte Wegpunkt-Testeinstieg
koennen die reine DefaultMove-Zwischenprojektion auslassen, wenn derselbe
synchrone Aufruf anschliessend den finalen Typ vollstaendig darstellt.
Kontaktmeldungserzeugung und First-Contact-Framing bleiben an der bisherigen
Zwischengrenze durch refresh_contact_overlay erhalten. So enthaelt die finale
Orderpublikation bereits die neu produzierten Kommunikationsereignisse.
Contextmenue-Erstellung behält ihre sofortige volle Vorschau als Default.
Leere und spaet ungueltige Ziele behalten ihre Fehlerprojektion. Alle finalen
Legacy-/3D-Quellfelder, Planungspublikation und Feedback bleiben synchron;
kein Cache, kein neuer Scheduler und kein verschobener Gameplaycommit.
