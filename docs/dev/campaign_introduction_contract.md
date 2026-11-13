# Kampagneneinfuehrung und Modusgrenze

## Revision: fünf Missionen, 10.11.2026

Der neue Ziel-/Umsetzungsumfang steht in
`docs/tasks/CAMPAIGN_FIVE_MISSIONS_2026_11_10_PLAN.md` und
`docs/tasks/CAMPAIGN_SKIRMISH_REBUILD_2026_11_10.md`.
Die folgenden früheren Drei-Etappen-Regeln werden durch diese Revision ersetzt,
soweit sie Reihenfolge, Teamgröße, Schiffszahl und Belohnungszeitpunkt betreffen.

- Basisvorbereitung mit zwei echten Personen und einem Schiff, leichter Rüstung,
  Pistole und Medgun. Danach fünf echte Aufträge: Satellit → Außenposten →
  C-Benit-Lieferung zur Satellitenkarte → befestigter Außenposten → Raumrettung.
- `singleplayer_campaign_state.gd` besitzt Auftragssperren, `pending_upload`,
  Fortschrittsflags und einmalige Abschlussbelege. Vorgängerabschluss ist vor
  Annahme erforderlich. Skirmish konfiguriert denselben Owner ohne diese
  Kampagnenreihenfolge; ein Skirmish-Save darf die Kampagne nicht entsperren.
- Die bestätigten Missionsgates erzeugen bei Mission 1/4 einen physischen Chip
  im beteiligten Schiff. Erst echte Heimkehr und `campaign_upload` am Basisterminal
  konsumieren ihn und lösen Credits/Blueprint aus. Ein Erfolg im Bodenszenario
  allein zahlt diese Aufträge nicht aus. Chip und Lieferkiste besitzen reservierte,
  begrenzte Frachtplätze; volle reguläre Fracht darf keinen Auftrag zerstören.
- Nach bestätigtem Sichern des ersten Außenpostens und tatsächlicher Händler-
  Interaktion kann `campaign_recruit` den dritten NPC aufnehmen. Dies geschieht
  vor der letzten Rückkehrinteraktion, damit automatische Extraktion die
  Rekrutierung nicht unerreichbar macht. Ein erneuter Klick erzeugt keinen NPC.
- Bestätigte Bergung auf Karte B übernimmt eine C-Benit-Kiste ins Schiff.
  Mission 3 darf nur mit der tatsächlichen Kiste im gewählten Schiff anfliegen;
  der bestätigte Liefer-Use konsumiert sie vor Abschluss. Der Mining-Blueprint
  schaltet Herstellung frei; das Werkzeug ist kein Kampagnen-Startgegenstand.
- Mission 5 beginnt erst beim ausdrücklichen Anflug auf `distress_orbit`.
  `campaign_space_encounter.gd` wird an `SimulationRoot` gebunden. Feindliche
  Cutlass und neutrale Buccaneer sind getrennte Ziele. Simulationstick und
  bestätigte Rettungsaktion erzeugen echte Ergebnisbelege; kein UI-Siegknopf.
- Der gerettete Pilot tritt einmalig mit seiner Buccaneer bei: Team 3→4.
  Ein fehlendes zweites Pad bleibt ein konkreter Ausbaugrund; `campaign_build_pad`
  kostet derzeit 100 Credits und schaltet Pad 2 frei. Diese Startwerte sind
  Implementierungsannahmen, keine nachgewiesene finale Balance.
- Onboarding speichert sieben geordnete Schritte als Schema 2: Vorbereitung,
  fünf Missionen und Padbau. Die UI liest diesen Owner. Blueprints befinden sich
  ausschließlich in bestätigten Supply-Belohnungsbelegen.
- Basischeckpoints enthalten vollständigen Roster (2–4), Flotte (1–2),
  Piloten/Standorte, Inventare, Ortsressourcen, Fortschritt und Belege.
  Mehrschiffstände sind nur bei geerdeter Reise und sicherem Basiszustand erlaubt.
  Restore validiert Auftragssperren, Belohnungsdaten, Flottenzuordnung und
  Ressourcenmengen vor Anwendung. Alte Drei-Etappen-Saves sind kein kompatibler
  fünf-Missionen-Fortschritt und werden nicht still migriert.

Technische Domainprüfungen und native Spiel-/Gestaltungsabnahme bleiben getrennt.
Der Raumkampf ist ein begrenzter erster deterministischer Begegnungsslice,
keine allgemeine Abnahme einer Flotten-/Trägersimulation.

## Historischer Drei-Etappen-Vertrag (vor dieser Revision)

Freigegebener Entwurf: `docs/tasks/CAMPAIGN_START_2026_11_09_DESIGN.md`.

## Einstieg und Team

Das Hauptmenue trennt **Kampagne**, **Skirmish** und **Multiplayer**. Der Teameditor und die Teambibliothek bearbeiten das bestehende Skirmish-Profil `local_player`. Kampagne verwendet dieses Profil weder als Startroster noch als Speicherziel fuer Missionsergebnisse.

`game_start_contract.gd` transportiert ausschliesslich den einmaligen Startwunsch `mode`/`action` bis zum Flow. Ohne Wunsch bleibt der direkte Szenenstart kompatibel zu Skirmish. Multiplayer und Editor entfernen den Wunsch; Karten-/Szenario-Handoffs bleiben ihre bestehenden autoritativen Pfade.

Eine neue Kampagne besitzt genau zwei NPCs: `campaign_leader` als einsatzfaehigen Leader und `campaign_pilot` als getrennten Dropship-Piloten. Ein einziger Leader darf einen realen Fireteam-Einsatz ausfuehren. Automatische Alt-Bootstrap-Auffuellung darf kein weiteres Personal erzeugen. Profile kommen beim Missions-Handoff aus dem Kampagnenroster; die umgangene FOB-Anzeige ist keine Profilquelle.

Nutzerpraezisierung vom 09./10.11.: Es gibt keine zusaetzliche Commanderfigur in der Kampagnenbasis. Die beiden echten Rosterpersonen sind dort auswaehlbar. Beide duerfen nach der Landung aussteigen und am Bodeneinsatz teilnehmen. Vor jedem tatsaechlichen Flug muss die aktuell zugewiesene, lebende Person wirklich am Pilotenplatz sein. Auch ein anderer echter NPC darf diesen Platz uebernehmen; seine eigenen Flugfaehigkeiten bleiben massgeblich. Dieser Schritt fuehrt keine neue zufaellige Absturzmechanik ein. Eine Rollenbezeichnung oder unsichtbare Ersatzperson ersetzt keine physische Anwesenheit.

## Orte und Reihenfolge

| Etappe | Reale Voraussetzung | Freischaltung |
| --- | --- | --- |
| Basis vorbereiten | Satellitenauftrag angenommen, Pilot zugewiesen, Leader als Payload fertig geboardet | Abheben in den Mondorbit |
| Satellit bergen | Bestehende Szenariogates `secure_satellite` und `return_to_ship`, bestaetigter Auftragserfolg, reale Heimkehr | Handelsort |
| Versorgung sichern | Echter Handelsflug, Haendler-Use, erfolgreicher Kauf, erfolgreiche Betankung und reale Heimkehr | Einfuehrung abgeschlossen, vorhandene Orte frei besuchbar |

Ein Popup schliessen, ein Panel oeffnen oder einen Ortsnamen waehlen ist kein Missionsabschluss. Fehlschlag bleibt wiederholbar ueber `Erneut annehmen`; vergangene Ergebnis-/Command-Belege duerfen weder Wiederholung blockieren noch erneut Fuel, Waren oder Belohnungen erzeugen.

Basisdarstellung verwendet `maps/campaign_intro_base.json`: nach Nutzerkorrektur wieder die groessere36x28-Heimatbasis mit beiden vorhandenen moeblierten Cutaway-Gebaeuden und beiden stabilen Pad-Flaechen. Der Startumfang bleibt klein (zwei NPCs und ein reales Schiff); die Karte wird deshalb nicht verkleinert. Skirmish behaelt dieselbe grosse Basisgrundlage. Satelliten- und Handelsort laden weiterhin ihre eigenen Karten und Szenarien. Ort, Auftrag, Karte, Szenario und Startmodus sind getrennte Begriffe.

Die vereinfachte Behandlung des Handelspostens ist keine Gestaltungsvorgabe fuer die Heimatbasis. Die erhaltenen `structures_pass04`-Quellen bleiben unveraendert. Fuer tatsaechlich betretbare Schlafraeume duerfen nachvollziehbare Modellableitungen ausschliesslich fehlende Tueroeffnungen ergaenzen; Einrichtung, Materialstil und Raumaufteilung bleiben erhalten. Kahle Ersatzwaende sind kein Basisstil. Quelle: `docs/tasks/BASE_ORIGINAL_ROOMS_2026_11_09.md`; Durchgangs-/Personenauftrag: `docs/tasks/BASE_REAL_PERSONNEL_2026_11_09_DESIGN.md`.

Seit dem freigegebenen Orbitauftrag vom 09.11.2026 liegt die Heimatbasis auf
dem Mond und beide Aussenziele auf einem Planeten. Abheben startet noch keine
Mission. Mondorbit -> kurzer abbrechbarer Quantum -> Planetenorbit -> Zielwahl
-> ausdruecklicher Anflug folgt `orbit_quantum_travel_contract.md`. Die reale
Heimkehr verlangt den Rueckweg in den Mondorbit und Landung an der Basis.
Auftrags-/Versorgungsbelege und die Reihenfolge der Einfuehrung bleiben erhalten.

## Autoritaet und Hilfe

`campaign_onboarding_state.gd` ist der an `SimulationRoot` gebundene Fortschrittsowner. Nur der Runtime-Adapter liefert vertrauenswuerdige Evidenz aus Bereitschaft, echten Missions-/Transportdaten und bestaetigten Versorgungskommandos. UI-Payloads sind keine Evidenz. `campaign_tutorial_presenter.gd` liest Snapshots; dessen Ausblenden-, Gelesen- und Popup-Zustand ist Praesentation.

Kleine aktuelle Anleitung, schliessbare Ersthinweise, wieder aufrufbare Hilfe und Hover-/Fokushilfen verwenden den bestehenden Kontext-Hilfevertrag und Katalog. Hilfe-Aus schaltet keine Hover-Popups heimlich wieder ein. Echtzeit bleibt unveraendert, keine Tutorial-Pause.

## Checkpoint

Ein konsistenter Stand an der Heimatbasis wird in `user://campaigns/introduction/checkpoint_v1.json` geschrieben. Roster, Fireteam-/Mitgliederausruestung, Pilot, Craft, Ressourcen, Auftragsstatus, Fortschritt und Belege werden zusammen validiert und ueber eine temporaere Datei ersetzt. Unterstuetzte stabile Ein-Schiff-Bodeneinsaetze koennen zusaetzlich in `active_checkpoint_v1.json` gespeichert werden; Capture und Restore validieren alle beteiligten Owner. Orbitflug, laufendes Gefecht und nicht unterstuetzte Mehrort-/Hex-Heimatstaende sind damit nicht pauschal speicherbar.

`Fortsetzen` (`continue`) bevorzugt den gueltigen aktiven Einsatzstand derselben Kampagne und desselben Basisstands. Ein nachweislich neuerer Basisstand ersetzt den alten Einsatzstand bei der Auswahl. Ein ungueltiger, nicht ausdruecklich ausrangierter Einsatzstand fuehrt dagegen zu einem Ladefehler mit Wiederherstellungshinweis, nicht zu einem stillen Verlust gueltigen Einsatzfortschritts. **Letzten Basisstand laden** (`continue_home`) ist ein eigener ausdruecklicher Startwunsch: Nach Basisvalidierung wird ein vorhandener Einsatzstand bytegleich in eine `active_checkpoint_v1.retired-<sha256>.json`-Datei verschoben. Scheitert dies, bleiben die vorhandenen Staende erhalten und der Start wird abgelehnt. Das Hauptmenue bestaetigt diesen Ruecksprung separat; der Fehlschlag-Debrief benennt ihn direkt.

Eine bestaetigte neue Kampagne erzeugt eine neue Laufkennung. Ihr erster erfolgreicher atomarer Basis-Commit haelt den SHA-256 eines vorhandenen alten Einsatzstands in `retired_active_checkpoint_sha256` fest und archiviert erst danach diese Datei bytegleich. Bei unterbrochener oder fehlgeschlagener Archivierung bleibt die Originaldatei erhalten; `continue` ignoriert ausschliesslich das durch diesen Commit ausrangierte Byteartefakt. Eine andere/neue Datei ist dadurch nicht freigegeben. Fehlgeschlagene Basisvalidierung ersetzt weder Basis- noch Einsatzdatei. Regulaere spaetere Heimkehr-Checkpoints erhalten das bisherige Verhalten fuer alte, bereits ueberholte Einsatzdateien.

Optionale `base_personnel`-Felder speichern echte Basisposition, Bettbelegung/Schlaf und bestaetigte Anwesenheit an Bord. Laufende Wege werden beim Laden nicht blind erneut ausgeloest. Aeltere gueltige Checkpoints ohne diese Felder bleiben ladbar und stellen die beiden Personen an freien Startpositionen dar. Gespeichertes Boarding wird auch im bestehenden Payloadowner wiederhergestellt, nicht nur durch ausgeblendete Figuren behauptet.

Ungueltige/veraltete Staende werden vor Mutation abgelehnt. `Neue Kampagne` ersetzt einen vorhandenen Stand nur nach Menuebestaetigung. Save-/Ladefehler duerfen keinen Skirmish-Fallback oder stillen Kampagnenneustart ausloesen.

## Pruefung

Domainpruefungen decken Reihenfolge, unzulaessige Restore-Fakten, Wiederholung, Save-Roundtrip und Belegkonsistenz ab. Menue- und Flow-Gates pruefen getrennte Einstiege, genau zwei NPCs, den echten Profil-Handoff und Ortsgrenzen. `campaign_intro_loop_smoke.gd` verwendet denselben realen Flug-/Bewegungs-/Use-Treiber wie der bisherige Einzelspieler-Smoke, mit einem Leader und echten Checkpoint-Neuladungen nach beiden Ausfluegen. Native Bedienbarkeit und Lernerfolg bleiben getrennte Nutzerabnahme.

## Terminaler Personalausfall und fehlgeschlagene Extraktion

Ist ein bereits aufgeloester Kampagneneinsatz wegen eines nicht flugfaehigen Piloten oder eines nicht boardingfaehigen Besatzungsmitglieds nicht heimkehrfaehig, wird er einmalig als Fehlschlag abgewickelt. Auch ein vorheriger Objective-Sieg ist ohne moegliche Extraktion kein erfolgreicher Ausflug; das urspruengliche Ergebnis bleibt im Debrief-Datensatz nachvollziehbar. Der vorhandene Ergebnis-/Personal-/Recovery-Pfad liefert den Debrief mit den echten beiden Personen und ihren Verletzungsfolgen. Es gibt keinen Ersatzpiloten, keine fingierte Rettung/Heimkehr, keinen Rueckflug-Fuelabzug und keine Erfolgsbelohnung.

Der Debrief benennt die unmoegliche Heimkehr und bietet als primaere Aktion **Letzten sicheren Checkpoint fortsetzen**. Auch der alte FOB-Rueckweg verwendet in diesem Fall ausschliesslich diesen ausdruecklichen `continue_home`-Pfad. Dieser laedt den bereits vorhandenen Basis-Checkpoint, auch wenn noch ein gueltiger Einsatzstand existiert: Roster, Ressourcen und Vorbereitung fallen auf diesen letzten sicheren Stand zurueck; der gescheiterte Ausflug wird nicht gespeichert. Der zuvor gespeicherte Einsatz bleibt als Archivdatei erhalten. Das ist ein ausdruecklicher Neustart ab Checkpoint, keine physische Ankunft oder neue Heilungsmechanik. Das Ergebnis wartet nicht endlos auf unmoegliches Boarding; erneute Ergebniszustellung erzeugt weder neue Belege noch Kosten. Normales Boarding und tatsaechlicher Flug verlangen weiter den lebenden, aktuell zugewiesenen realen Piloten an Bord.
