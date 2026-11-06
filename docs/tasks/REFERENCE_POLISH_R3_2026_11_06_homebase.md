# Runde 3: Heimatbasis als Vorbereitung und Flugdeck

## Ziel / Problem
Der Nutzer verlangt eine sichtbar engere Umsetzung der originalen 2D-Ziele.
Die aktuelle Operationsansicht zeigt vier aehnlich gewichtete Spalten. Bei
3440x1440 entstehen durch die zentrierte 2400px-Grenze grosse freie Flaechen
zwischen Navigation und Personal. Das Schiff steht als einzelnes Bild in
einer langen Steuerelementliste. Die Vorlage gewichtet Personal und Trupp
links, eine fokussierte Ausruestungskarte und eine grosse rechte Basisszene
mit gemeinsamem Boarding-/Abflugfuss.

## Basis / Dokumente
Main `173a1e3c33b733a78a396a93db9cedf631d84998` und Haupttask
`REFERENCE_POLISH_R3_2026_11_06.md`. Gelesen: AGENTS, PROJECT_BRIEF,
ARCHITECTURE, CODEX_RULES, IMPLEMENTATION_STATUS, die einschlaegigen
Grafikreferenz-/UI-/HUD-Autoritaetsvertraege und Game-UX-Designpraxis.

Direkt geoeffnete Originale:
- `docs/reports/assets/ui-2026-11-01/menu_heimatbasis.png`
- `docs/reports/assets/ui-2026-11-01/menu_fob_loadout.png`

Direkt geoeffneter Ist-Stand:
`output/hud_architecture_20261106/final_native_audited/20261106T144051Z-f2bdfc4c/audited_captures/02_homebase.png`.

## Gewaehlter enger Umbau
`HomebaseOperationsPresenter` bleibt eine einmal aufgebaute Lesedarstellung.
Alle Auswahl-, Loadout-, Pilot-, Boarding-, Rueckhol- und Startaktionen laufen
weiter ueber `HomebaseTestScreen.request_operation` mit unveraenderten IDs.
Die vier bestehenden Spaltenkeys bleiben fuer Nachbarn erhalten, bekommen
aber bewusst unterschiedliche Rollen und Rechtecke:

- Personal und Trupp bilden die linken durchgehenden Arbeitsbereiche.
- Die Fokus-/Ausruestungskarte liegt oben in der mittleren Flaeche.
- Eine eigene passive Basisbuehne fuellt den oberen rechten Bereich.
- Die vorhandenen Flugdeckcontrols bilden einen breiten Fuss unter Fokus und
  Buehne. Auswahl/Mission, Pilot/Status und Aktionen stehen dort in getrennten
  nativen Gruppen; der Startbutton bleibt ohne Scrollen erreichbar.

Die Buehne verwendet den vorhandenen **statischen nativen Basisrender**
`Assets/curated/main_menu/frontier_outpost_main_20261101.png`. Sie wird im
Produkt als Basisansicht gekennzeichnet, besitzt `visual_only`/Input-Ignore
und behauptet keinen aktuellen Actor-/Boarding-/Transportzustand. Die aktive
Schiffsvorschau bleibt das vom vorhandenen Craft-Snapshot gelieferte native
Ref03-Bild. Es gibt keine neue Schiffsinterpretation und keine neue GLB-Quelle.

Bestehende unveraenderte Quellenpins (SHA-256):
- Basisrender: `35c52473d92cbec346577a7be269553f8270d586f69f241067952a3be49bcea6`.
- Cutlass-Ref03-UI-Preview: `f47437b3001c95bb88ccaa026ece5cbfbd03f637afa9ab6fb828fb1e95382570`.

Am aktuellen ultrabreiten Bildschirm beginnt das Personal nahe am
Workspaceanfang. Die Szenenflaeche nimmt den zusaetzlichen Platz auf; kurze
Controls werden nicht erneut zu vier sehr breiten Tabellen gestreckt.
Abschnitts-/Identitaetsueberschriften verwenden die vorhandene Themefamilie.

## Responsive Verhalten und Zustaende
- 3440x1440 und 1920x1080: Personal, Team, obere Fokuskarte, obere rechte
  Buehne und breiter Flugdeckfuss. Alle Rechtecke bleiben im Workspace und
  verdecken sich nicht.
- 1280x720 Truppansicht: die drei vorhandenen Vorbereitungsbereiche bleiben
  lesbar. Flugdeck und passive Buehne wechseln auf die vorhandene Einsatz-
  Navigation. Keine neue verborgene Pflichtaktion.
- 1280x720 Einsatzansicht: Team/Fokus sowie Buehne und Flugdeckfuss teilen die
  verfuegbare Flaeche. Start/Boarding und Pilot bleiben wirklich erreichbar.
- Leere Teamplaetze sind kompakt und erfinden weder Portrait noch Besetzung.
  Fehlende Auswahl und fehlendes Schiff bleiben echte Leerzustaende.
- Fehlender Pilot, Boarding und Transit lesen ihre bestehenden Snapshotgates.
  Fortschritt/Farben und Schaltflaechensperren werden nicht aus Bildinhalten
  oder lokal uebersetzten Statusstrings abgeleitet.

## Akzeptanzkriterien
1. Der fokussierte neue Verifier weist die neue Raumhierarchie und die
   statische native Buehnenquelle nach. Der aktuelle Stand muss davor an
   diesen Zielunterschieden RED sein, ohne Parserfehler.
2. Bei 3440/1920 ist die Flugdeckflaeche breiter als die Fokuskarte, liegt
   unter Fokus/Buehne und ueberlappt keinen linken Arbeitsbereich. Die
   ultrabreite Personalspalte beginnt hoechstens24px nach Workspaceanfang.
3. Die native Ref03-Silhouette liegt voll innerhalb ihrer Previewflaeche.
   Die Quelle folgt dem ausgewaehlten Snapshot; leeres Craft liefert kein
   Ersatzschiff. Die passive Buehne faengt keine Eingaben ab.
4. Derselbe Selector-/Button-/Rowbaum wird ueber Resize, Navigation und
   Statuswechsel wiederverwendet. Seine Callbackidentitaeten bleiben erhalten.
5. Leere, vorbereitende, pilotlose, boardende, bereite und reisende Fixtures
   projizieren ihre genauen Gates, Progresswerte und IDs. Reiner Refresh
   schreibt weder Owner-Snapshot noch Commands.
6. Alle drei Loadoutfelder, Mission-/Craft-/Pilot-Auswahl sowie Board/Unboard/
   Start/Charakterdetails verwenden die bestehenden Operationen und Payloads.
   Die bestehende echte Homebase-Operations-Nachbarpruefung bleibt erforderlich.
7. Native Root-Captures in echtem Vollbild bei3440 sowie passenden logischen
   1920/1280-Layouts pruefen Text, reale Rects, Clipping und Fokus. Ein
   Komponentenpass ist keine gestalterische Nutzerabnahme.

## Umfang / Nicht-Ziele und Dateibesitz
Freigegeben fuer Entwurf/Verifier: diese neue Taskdatei und
`scripts/tests/reference_polish_r3_20261106_homebase_verifier.gd`.
Produktimplementierung erst nach Roots ausdruecklichem Ende der unveraenderten
Performance-Vergleichsphase. Erwartete Produktdatei:
`scripts/meta/homebase_operations_presenter.gd`; kein Ownership- oder
Gameplayumbau in `homebase_screen.gd`. Root allein startet Engines und Git.

Keine FOB-Rueckkehr, kein Live-Viewport als zweite Simulation, keine neuen
Portraitidentitaeten, keine gespeicherten Zuordnungs-/Transportwerte und keine
neuen Assets. Alte Screenshots und QA-Verzeichnisse bleiben unveraendert.

## Pruefung / Risiken / Stand
Root bestaetigt das echte Ausgangs-RED: **112/12**, Exit1, Enginefehler0,
isolierte Daten und stabile Laufquellen unter
`output/reference_polish_r3_20261106/homebase_red/20261106T183422Z-69f591c1`.
Die zwoelf Fehlschlaege betreffen ausschliesslich die neue Buehne/Gewichtung,
den ultrabreiten Abstand und die tatsaechlich abgeschnittenen Boarding-/
Startbuttons der schmalen Einsatzansicht. Die bestehende Status-/Callback-
Projektion bleibt dabei gruen.

Nach Roots ausdruecklicher Freigabe der UI-Phase wurde die vorbereitete
Kandidatur ausschliesslich in scripts/meta/homebase_operations_presenter.gd
angewandt. Die vorangehende Basis-SHA war
84959f74a6c5471b7f580bcfc795810a5d72ac514bef5db77414e0c21881c836;
die erste angewandte Kandidatur hatte SHA
cd5970be724c89b2eda3250afb3e8bf25bbaec031a736664e445def1629db1f5.
Der vorhandene Owner-Bridge-Pfad und das gemeinsame Theme bleiben unveraendert.
Die Textpruefung findet keine doppelten Funktionsnamen. Parser, fokussiertes
GREEN, echte Owner-Nachbarpruefung und native Nachherbilder liegen weiterhin
bei Roots serieller Engine-Ausfuehrung und sind noch nicht behauptet.

Roots erster Produktlauf ergab **152/6**, Enginefehler0. Die anschliessende
unveraenderte Diagnose bestaetigt den korrekten logischen Viewport1280x720,
aber ein auf974px erhoehtes Aussenlayout: Workspace y568, Einsatznavigation
y796. Ursache sind die drei neuen Workflow-Schrittlabels, die in ihrem HBox
mit Word-Wrap auf minimale Breite schrumpften und unnoetig viele Zeilen
erzeugten. Diese passiven Schrittlabels sind jetzt ausdruecklich einzeilig.
Der Verifier behaelt alle bisherigen Sichtbarkeitskriterien und prueft
zusaetzlich den realen logischen Viewport sowie den gesamten Workspace.
Roots korrigierter isolierter Lauf unter
`output/reference_polish_r3_20261106/homebase_corrected_green/20261106T231321Z-df649fd0`
ist **168/0**, Exit0, Enginefehler0 und stabile Laufquellen. Die urspruenglichen
Sichtbarkeitsgates sowie die zusaetzlichen echten Viewport-/Workspacegates
bleiben vollstaendig erhalten. Native Vollbildbilder und die echte
Owner-Nachbarpruefung sind davon getrennte Nachweise.

Die anschliessende echte40er-Nachbarmatrix fand genau eine Regression:
HomebaseOperations61/1, weil der etablierte Fokusportrait-Vertrag mindestens
176px Quadrat verlangt. Nach Matrixende wurden ausschliesslich das
Bauminimum144 und der normale Layoutwert160 wieder auf176 gesetzt;
ultrabreit224 und schmal112 bleiben erhalten. Der R3-Verifier prueft jetzt
zusaetzlich das tatsaechliche Quadrat>=176 und Portrait-Containment bei
3440/1920 sowie1600, unter Beibehaltung aller vorhandenen Rectgates.
Presenter-Pin: `c888208292fad054250ffe8e999de362102965927634a78147fd764e12958f41`.
Roots isolierte erneute Pruefung unter
`output/reference_polish_r3_20261106/portrait_homebase_regression/20261106T233726Z-4a4a1473`
ist **3/3 PASS**, Enginefehler0 und stabile Quellen: bestehendes
Flightdeck72/0, echte HomebaseOperations62/0 und erweiterter R3-Verifier203/0.
Die native Fixturewiederholung dieses Pins bleibt vom Komponenten- und
Owner-PASS getrennt und liegt nach Roots Profilen noch bei Root.

Hauptrisiken: zu kleine Steuerguppen im schmalen Flugdeckfuss,
Textminimums gegen berechnete Rects, Container-Scrollclipping sowie ungewollte
Callbacks bei UI-Reparenting. Native Controls und echte Owner-Regression
muessen diese Punkte pruefen. Die statische Buehne darf nicht als aktuelles
Transportbild missverstanden oder als live simuliert ausgegeben werden.
