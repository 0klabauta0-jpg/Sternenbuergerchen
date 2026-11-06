# Periodischen Aufbau unsichtbarer A5-Mitgliedskarten vermeiden

## Ziel / Problem
Die native A5-Darstellung verbirgt den alten horizontalen Mitgliedskartenstreifen
absichtlich. `_refresh_runtime_mission_hud_surfaces()` baut diese Controls dennoch
periodisch neu auf. Der aktuelle native Trace misst die gesamte Kartengruppe mit
etwa 18-20 ms; der isolierte Anteil der Selected-Karten ist noch nicht gemessen.

## Ursache / Sinnhaftigkeit
`mission_a5_hud_layout.gd` verbirgt `FireteamCardsScroll` ausdruecklich. Die sichtbare
Identitaet liegt in den portraitbetonten Mini-Karten. Das Team-Details-Popup liest
Labels und Tooltips, nie den alten Mitgliedskartenbaum. Dessen Default-Refresh
loescht dennoch Kinder und instanziiert/konfiguriert NPC-Compact-Cards.

## Umfang / Nicht-Ziele
- Root guardiert nur den periodischen Dispatch der Selected-Karten: vorhandenes
  Controller-Meta `native_a5_legacy_setup_complete` und effektive Unsichtbarkeit
  der Kartenreihe muessen beide vorliegen.
- Direkte `_refresh_selected_fireteam_cards()`-Aufrufe und explizite QA-/Detail-
  Snapshots behalten ihre aktuelle Semantik und koennen versteckte Daten bauen.
- Mini-Karten, Ad-hoc-Sichtbarkeit und geoeffnete Character-Overlays laufen weiter.
- Kein neuer Gameplay-State, kein Lesen anderer Panels als Wahrheit, keine
  Aenderung von Befehlsfeedback, Transport, Commands, Simulation oder Portraitstil.
- Kein pauschales Unsichtbarkeits-Caching fuer Legacy-Oberflaechen.

## Dokumente / Contracts
`HUD_ARCHITECTURE_2026_11_06.md`, `AGENTS.md`, `../ARCHITECTURE.md`,
`../dev/mission_command_feedback_contract.md`,
`TASK_1044_mission_hud_runtime_surface_guard.md`,
`TASK_1158_selected_fireteam_member_cards_1280_readability.md`.

## Akzeptanzkriterien
- A5-Meta plus effektiv unsichtbare Reihe ueberspringt den periodischen
  Selected-Dispatch und dessen echten Profilaufbau.
- Eine lokal sichtbare Reihe unter verstecktem Ancestor gilt als unsichtbar.
- Sichtbare A5-Reihen sowie Legacy-Reihen ohne A5-Meta behalten ihren Dispatch,
  auch wenn eine solche Legacy-Reihe zeitweise unsichtbar ist.
- Mini-, Ad-hoc- und geoeffneter Character-Overlay-Dispatch laufen in allen vier
  Faellen jeweils einmal weiter.
- Expliziter Refresh unter verstecktem A5 baut nach geaenderten UI-Eingaben
  aktuelle echte Profile; Member-Identitaet, Source-Context und Character-Signal
  bleiben erhalten.
- Eine ausserhalb A5 wieder sichtbare Reihe baut im selben Dispatch aktuell auf.
- Nach einem versteckten Gruppenrefresh loest sowohl Reveal als auch Abschalten
  des A5-Besitzes ohne andere Quellenaenderung einen normalen, nicht erzwungenen
  Gruppenrefresh aus. Der direkt folgende unveraenderte Aufruf bleibt quieszent.
- Bestehender Style-Verifier bleibt unveraendert und besteht weiterhin 605/605.

## Betroffene Dateien / Besitz
Root: engster Guard in `scripts/tests/mission_tactical_sandbox_controller.gd`.
Delegiert: `scripts/tests/hud_architecture_20261106_hidden_cards_verifier.gd` und
diese Subtask-Datei. Keine delegierten Produkt-, Engine- oder Git-Aenderungen.

## Lokale Pruefung
Root fuehrt RED/GREEN seriell mit isolierten Userdaten und dem bestehenden
Rosterguard aus. Marker: `HUD_HIDDEN_CARDS_VERIFY_PASS`. Der Verifier verwendet
eine echte Missionsszene, echten Selected-Karten-/Profilaufbau und gezaehlte
benachbarte Dispatch-Sinks. Er aendert nur UI-Sichtbarkeit und Preview-Inputs.

Root ergaenzt vor der naechsten nativen Messung getrennte Zeiten fuer Ad-hoc,
Selected und Mini-Karten. Erst dieser unveraenderte 1x-Workload darf den Gewinn
beziffern; die bisherigen 18-20 ms sind ausdruecklich ein Gruppenscope.

## Risiken / offene Punkte
Der Guard gehoert vor den periodischen Aufruf, nicht pauschal in die explizite
Selected-Funktion. Sonst koennten QA-/Detailsnapshots nach versteckten Aenderungen
stale bleiben. Eine spaetere neue sichtbare Nutzung dieses Baums muss seinen
Sichtbarkeits-/Aktualisierungsvertrag neu pruefen. Der zusaetzliche Aufbau der
Gruppensignatur bleibt ein separater kleinerer Kandidat.

## Nachreview P2: Invalidierung bei Sichtbarkeits-/Besitzwechsel
Der erste Dispatchguard verbraucht im Hidden-Fall die aktuelle Gruppensignatur,
waehrend die letzte Selected-Signatur aelter bleiben darf. Sichtbarkeit und
A5-Besitz fehlten dabei in der Gruppensignatur. Ein normaler Reveal-Aufruf ohne
Forceanforderung konnte deshalb die stale Selected-Projektion dauerhaft
ueberspringen. Die urspruenglichen Force-/Preview-Testfaelle deckten das nicht ab.

Der erweiterte Verifier reproduziert beide Handoffs mit exakt unveraenderten
Selected-Quellen und `force_refresh=false`; er verlangt frische Profile und
anschliessend den unveraenderten Skip. Der engste geplante Fix nimmt effektive
Sichtbarkeit und A5-Besitz in die bestehende Gruppensignatur auf. Die separate
letzte Selected-Signatur bleibt dabei unveraendert und erzwingt den noetigen
Aufbau erst, wenn der Dispatch ihn wieder zulaesst. Der Produktfix folgte dem
unten erhaltenen Root-RED.

## Ergebnisse / Evidence
- Initialer Dispatch-RED: 59 PASS / 2 FAIL, genau die beiden versteckten
  A5-Dispatch-/Profilassertionen; initiales GREEN danach 61/61.
- Nachreview-RED: 69 PASS / 8 FAIL unter
  `output/hud_architecture_20261106/hidden_cards_reveal_red/20261106T142933Z-0527104d/`.
  Sechs Fehler reproduzieren die beiden echten nicht erzwungenen Handoffs.
  Zwei weitere zeigten eine Testreihenfolgeabhaengigkeit: Der spaetere explizite
  Refresh traf wieder die zuletzt tatsaechlich gebaute Quelle. Dieser Fall
  initialisiert nun seine eigene aktuelle Ausgangsprojektion vor dem Inputwechsel;
  die Freshness-Assertions bleiben unveraendert.
- Finales P2-GREEN: 77/77 unter
  `output/hud_architecture_20261106/hidden_cards_reveal_green/20261106T143125Z-d5e20312/`.
  Report: Exit 0, Fehlerzahl 0, isoliert und Quellinputs stabil. Reveal sowie
  A5-Abschalten mit konstanten Selected-Quellen und anschliessender Quieszenz
  sind damit fokussiert belegt.
- Root startete saemtliche Engines seriell. Diese Evidence ersetzt keinen
  nativen 1x-Performancevergleich oder eine breite Spiel-/Releaseabnahme.
