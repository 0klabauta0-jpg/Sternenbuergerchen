# TASK_ROADMAP

## Zweck
Diese Roadmap definiert die Reihenfolge der Tasks fuer das Projekt.

Ziel:
- kontrollierter Aufbau der Architektur
- klare Trennung von Daten, Simulation und Darstellung
- schrittweiser Uebergang von Struktur -> Integration -> sichtbares Verhalten

Diese Datei ist verbindlich fuer Codex.
Tasks duerfen nicht in anderer Reihenfolge umgesetzt werden, ausser es ist explizit angegeben.

---

## TASK_1057 - Controlled Dropship Inbound to Deboard Trace (implementiert im Arbeitsstand)
- Grundlage: TASK_1056 startet den Drop mit korrekten zwei Runtime-Units nach Transferankunft.
- Ergebnis: TASK_396 prueft 17/17 den echten Alpha-/Beta-Handoff: vier Units, korrekte ft1-/ft2-Paare, getrennte LZs, parallelen Inbound, Deboarding und beide aktiven Runtime-Fireteams.
- Ursache/Fix: Die Direct-Contract-Auswahl wird aus den payloadtragenden Karten kombiniert statt aus dem zuletzt gestarteten Einzel-Dropship ueberschrieben.
- Naechster Schritt: First-Contact-Trace auf den nun verifizierten Mehr-Fireteam-Deboarding-Pfad ausweiten und dabei Combat-Registry/LOS pruefen.

## TASK_1058 - Embarked Fireteam Selected HUD Truth (implementiert im Arbeitsstand)
- Grundlage: TASK_503 zeigt fuer ein eingebarktes, aber ausgewaehltes Fireteam disabled Boden-Member-Cards statt des klaren Dropship-Hinweises.
- Ergebnis: Selected-Fireteam-Cards und ihr Dirty-Signature-Pfad filtern embarked Units wie die linke Mini-Card-Liste. TASK_503 prueft 10/10: Hinweis waehrend Inbound, echte Cards nach Deboarding.
- Naechster Schritt: Mehr-Fireteam First Contact nach Deboarding mit Combat-Registry und LOS verifizieren.

## TASK_1059 - Multi-Fireteam First Contact Runtime Trace (implementiert im Arbeitsstand)
- Grundlage: TASK_1057 prueft zwei deboardete Runtime-Fireteams, aber der alte First-Contact-Trace stammt aus der frueheren, unvollstaendigen Transportkette.
- Ergebnis: TASK_1059 ist 10/10 gruen. ft1 und ft2 erscheinen mit korrekten Unit-Paaren in CombatRegistry, erhalten jeweils eine gueltige LOS-Fixture und erzeugen bestaetigte ContactTracker-Reports ohne UI-Gameplay-Wahrheit.
- Naechster Schritt: Den nun technisch belegten First-Contact-Moment als sichtbaren Spielergriff pruefen: Auswahl, Contact-Overlay, Threat-/Fire-Feedback und erster Command mit beiden Teams.

## TASK_1060 - Multi-Fireteam First Command Player Grip (implementiert im Arbeitsstand)
- Grundlage: TASK_1059 belegt getrennte Contacts fuer zwei deboardete Teams, aber noch nicht den gemeinsamen Commander-Griff vor und nach `GO`.
- Ergebnis: TASK_1060 ist 14/14 gruen. Beide Teams erhalten eigene Ghost-/Pfad-/Risk-Previews und Contact-Kontexte. `GO` bleibt ein separater Commit; danach bildet der vorhandene CoordinationManager sichtbar Vorstoss plus Partner-Deckung statt einen Team-Plan still zu verlieren.
- Naechster Schritt: Mehr-Fireteam-Missionsflow gegen die verbleibenden sichtbaren Runtime-/Framekosten messen, bevor weitere Bedienoberflaechen auf einen noch langsamen Pfad gelegt werden.

## TASK_1061 - Multi-Fireteam Mission Runtime Budget (implementiert im Arbeitsstand)
- Grundlage: TASK_1060 macht den gemeinsamen Commander-Griff funktional, aber der aktuelle Missionsstart und UI-Refresh enthalten noch messbare Laufzeitspitzen.
- Ergebnis: TASK_1061 ist 11/11 gruen. Der neue Zwei-Team-Trace zerlegt die echten Player-Stufen und die Controller-UI bis zu Runtime-Surfaces. Security-Coverage-Segmente der Mini-Cards werden bei reiner Suppression wiederverwendet statt neu aufgebaut.
- Naechster Schritt: Fireteam-Card-Delta-Rendering auf die verbleibenden echten Karten-/Text-Refresh-Kosten konzentrieren und dabei Contact, Suppression, Coordination und Lead-Zeile sichtbar erhalten.

## TASK_1062 - Fireteam Card Delta Rendering (implementiert im Arbeitsstand)
- Grundlage: TASK_1061 isolierte wiederkehrende Fireteam-Card-/Textkosten, obwohl die Karten bereits bei vollstaendig unveraendertem Runtime-State uebersprungen wurden.
- Ergebnis: TASK_1062 ist 18/18 gruen. Statische Kartenidentitaet wird nur bei geaenderter Referenz erneut eingerichtet; Selection, Suppression, Contact, Bewegung und Coordination bleiben kleine Runtime-Deltas. Lead- und Member-Portraets werden bei gleicher Identitaet nicht erneut gesetzt. Der frische Zwei-Team-Trace misst rund 46 bis 48 ms Fireteam-Card-Surface in Contact/Preview/GO.
- Naechster Schritt: Ein kleines spielbares Objective-Szenario bauen, das den nun lesbaren und stabilen Homebase-zu-Mission-zu-Debriefing-Pfad fuer einen Menschen erlebbar macht.

## TASK_1063 - First Objective Scenario (implementiert im Arbeitsstand)
- Grundlage: Die Station-Route hatte schon AA-, Door-, Computer-, Cargo-, HUD- und Debriefing-Bausteine, war fuer einen Spieler aber nicht im echten Homebase-Katalog waehlbar.
- Ergebnis: TASK_1063 ist 14/14 gruen. `Operation: Station Route` startet aus Homebase mit der vorhandenen Stationkarte und ScenarioData. Die Mission erhaelt echte Runtime-Gates; der sichtbare erste Schritt ist AA-Shutdown. TASK_726 30/30 und TASK_586 37/37 halten Route und Debriefing-Handoff als bestehende Folgegrenzen gruen.
- Naechster Schritt: Einen kurzen echten Spielrunden-Readability-/Balance-Slice fuer Station Route bauen: erster Kontakt, NPC-Druck, erste Erfolg- oder Abbruchentscheidung und Debriefing ohne technischen Leerlauf.

## TASK_1065 - Mission Runtime Review and Performance Pass (implementiert im Arbeitsstand)
- Grundlage: TASK_1061/1062 hatten den sichtbaren Zwei-Fireteam-Flow profiliert und statische Mini-Card-Arbeit bereits getrennt, aber die Member-Statusrow bei jedem Runtime-Refresh weiter gezeichnet.
- Ergebnis: TASK_1065 ist 13/13 gruen. Unveraenderte read-only Member-Snapshots ueberspringen jetzt die Row-Normalisierung und ihr Redraw; Suppression bleibt sichtbar live und ein echter Member-Statuswechsel wird weiter gezeichnet. Der aktuelle Code-/Performancebericht dokumentiert Messgrenzen, Architektur- und Hotpath-Befunde als HTML-Workbench.
- Naechster Schritt: TASK_1066 - Mission Feedback Surface Delta Extraction. Command-Feedback, Event-Log und Sekundaerlabels muessen weiter voneinander entkoppelt werden, ohne SimulationRoot- oder Multiplayer-Autoritaet in die UI zu ziehen.

## TASK_1066 - Mission Feedback Surface Delta Extraction (implementiert im Arbeitsstand)
- Grundlage: TASK_1065 belegte den breiten wiederkehrenden UI-Refresh; das Event-Log besass zwar einen Render-Guard, kopierte aber davor noch jedes Mal seine Daten.
- Ergebnis: TASK_1066 ist 8/8 gruen. Identisches Event-Log-Feedback wird am Panel-Eingang uebersprungen, ohne bestehende Entries zu verlieren. Neue Events und sichtbare Style-/Auswahl-Aenderungen werden weiter angewendet. Der Controller uebergibt den vorhandenen Polish-Contract nur noch einmal an den Panel-Eingang.
- Naechster Schritt: Die Command-Feedback- und Sekundaerlabel-Surfaces gegen denselben Zwei-Fireteam-Trace schneiden; danach den gewonnenen stabilen Pfad fuer eine kurze spielbare Station-Route-Runde nutzen.

## TASK_1067 - Mission Command Label Delta Rendering (implementiert im Arbeitsstand)
- Grundlage: TASK_1065/1066 haben redundante Karten- und Event-Log-Arbeit entfernt; weitere sichtbare Command-/Sekundaerlabels wurden im wiederkehrenden Refresh dennoch bei gleichem Text beschrieben.
- Ergebnis: TASK_1067 ist 8/8 gruen. Ein gemeinsamer, rein visueller Text-Delta-Helper laesst gleiche Werte liegen und wendet echte Command-Aenderungen weiter an. Die Diagnose bleibt read-only; Tooltips, Buttons und Simulation werden nicht mitgecacht.
- Naechster Schritt: Keine weitere pauschale HUD-Optimierung. Die stabilisierte Kette soll jetzt als kurze Station-Route-First-Round mit NPC-Druck, Erfolg-/Abbruchentscheidung und Debriefing fuer einen Menschen spielbar werden.

## TASK_1068 - Station Route First Playable Round Trace (implementiert im Arbeitsstand)
- Grundlage: Station Route war aus Homebase startbar und ihre einzelnen Route-, Dropship-, Contact- und Preview-Grenzen waren separat getestet. Es fehlte ein realer, zusammenhaengender Erstentscheidungsnachweis vor GO.
- Ergebnis: TASK_1068 ist 16/16 gruen. Der echte Katalogstart behaelt die Station-Scenario-Datei am MissionSetup und fuehrt durch Craft-Ankunft, LZ und Deboarding zu einem Ground-Fireteam. AA bleibt der erste Route-Schritt, ein LOS-Kontakt entsteht reproduzierbar und die Move-Preview zeigt Ghost, Pfad und Risiko, ohne Bewegung vor GO zu committen.
- Naechster Schritt: Eine kleine, spielbare Vorstoss-gegen-Abbruch-Entscheidung unter NPC-Druck bauen und ihren klaren Erfolg- oder Debriefing-Ausgang verbinden.

## TASK_1069 - Station Route LZ Evacuation Abort Outcome (implementiert im Arbeitsstand)
- Grundlage: Die Station-Route konnte echten Erstkontakt und Move-Preview zeigen, besass aber keinen spielbaren Rueckzug. Die vorhandene Dropship-RTB-Aktion war kein Evac, sondern nur Craft-Rueckkehr.
- Ergebnis: TASK_1069 ist 28/28 gruen. EVAC wird nur fuer ein ausgewaehltes Ground-Fireteam im LZ aktiv. Ein Host beendet die Mission ueber den bestehenden Combat-Result- und Debrief-Pfad mit `aborted / evacuation`; ein Nicht-Authority-Aufruf wird ohne lokale Mutation abgelehnt.
- Naechster Schritt: Den komplementaeren Vorstossausgang zur AA-Interaktion als kleinen NPC-Druck- und Erfolg-zu-Door-Cue-Slice bauen.

## TASK_1070 - Station Route AA Assault and Door Transition (implementiert im Arbeitsstand)
- Grundlage: AA war als erster Scenario-Gate und allgemeiner Use-Intent vorhanden, aber der sichtbare CommandGrid-Slot konnte nur Doors planen. Eine allgemeine Feedback-Prioritaet zog zudem einen spaeteren blockierten Cargo-Schritt vor die aktive AA-Route.
- Ergebnis: TASK_1070 ist 23/23 gruen. Slot `16.8` folgt jetzt dem naechsten Objective-Gate, zeigt `AA` ausser Reichweite und `AA->GO` im Radius. Die Aktion erzeugt nur den bestehenden `take`-Intent; erst GO durchlaeuft Formation/Movement/Runtime-Progress, setzt AA ab und leitet sichtbar zur Door-Cue weiter.
- Naechster Schritt: Den sichtbaren Door -> Computer -> Cargo-Folgepfad unter NPC-Druck als kurze vollstaendige Station-Route bis Debrief pruefen, bevor weitere neue Missionsmechanik entsteht.

## TASK_1071 - Station Route Full Victory Debrief Trace (implementiert im Arbeitsstand)
- Grundlage: TASK_1070 machte den ersten AA-Erfolgsuebergang sichtbar, aber Door, Computer, Cargo und Debrief waren noch nur als getrennte Gate-/Smoke-Nachweise vorhanden.
- Ergebnis: TASK_1071 ist 47/47 gruen. Der reale Context-Slot fuehrt AA -> Door -> Computer -> Cargo; jede Aktion plant nur und GO fuehrt aus. Cargo schliesst die vorhandenen Scenario-Gates und erreicht ueber Combat-Result und MetaLayerFlow den bestehenden Debrief-Screen mit `victory / won`.
- Naechster Schritt: Einen echten sichtbaren Station-Route-F6-Lauf mit NPC-Druck und dieser vollstaendigen Route bewerten. Neue Mechanik erst nach einem belegten Bedien-, Lesbarkeits- oder Performance-Befund.

## TASK_1072 - Contextual Interaction HUD Semantics (implementiert im Arbeitsstand)
- Grundlage: Der sichtbare Context-Slot plante die richtige AA-/Door-/Computer-/Cargo-Interaction, konnte nach dem statischen Command-Hierarchy-Pass aber noch den historischen Breach-Tooltip, Door-Hilfe und Hotkey `B` zeigen.
- Ergebnis: TASK_1072 ist 23/23 gruen. Nach dem Hierarchy-Pass und weiteren UI-Frames folgt der Slot wieder der aktiven Interaction: AA/Computer verwenden Take ohne Breach/B, Cargo verwendet Defend ohne Breach/B, echte Doors behalten Breach, `B->GO` und `B`.
- Naechster Schritt: Den gesamten Station-Route-Spielzug als sichtbaren F6-Playtest unter NPC-Druck bewerten und nur konkrete Bedien-, Lesbarkeits- oder Performance-Befunde in Folgearbeit schneiden.

## TASK_1073 - Release Build Provenance Guard (implementiert im Arbeitsstand)
- Grundlage: Der Runtime-Startcheck bestaetigte EXE/PCK, schrieb jedoch den aktuellen Git-HEAD ohne Nachweis, dass der vorhandene PCK wirklich daraus exportiert wurde.
- Ergebnis: TASK_1073 ist 13/13 gruen. Erfolgreiche Exporte schreiben Commit- und PCK-Hash-Provenance; der read-only Startcheck verlangt sie und lehnt fehlende oder abweichende Pakete hart ab. TASK_511 27/27 dokumentiert `scripts/tests/` explizit als aktuelle Runtime-Legacy-Abhaengigkeit.
- Naechster Schritt: Den Release aus dem sauberen Commit erzeugen, positiv pruefen und den belegten Spieleordner fuer den naechsten sichtbaren Station-Route- oder Host/Client-Playtest verwenden.

## TASK_1074 - Host Client F6 Contract Refresh (implementiert im Arbeitsstand)
- Grundlage: Der echte lokale ENet-Host/Client-Pfad war korrekt, aber Firefight-Labels und F6-Snapshots konnten durch alte Statusanhaenge und einen kurzlebigen Visual-Persistenzwert auseinanderlaufen.
- Ergebnis: TASK_1074 ist mit TASK_607 41/41, TASK_604 28/28, TASK_606 39/39, TASK_817 34/34, TASK_833 23/23, TASK_169 15/15 und ENet 3/3 gruen. Beide Seiten zeigen im Feuerkontakt `CONTACT FIRE` und die kompakte `NEXT ... | WHY ...`-Zeile; ACT-/Objective-/Cargo-/ROE bleiben strukturiert und read-only erhalten.
- Naechster Schritt: Den separaten Large-Map-Befund `unit_status_badge_count = 0` nach Missionsende als kleinen Badge-Lifecycle-Slice klaeren und danach aus dem sauberen Integrationscommit einen frischen Provenance-Release exportieren.

## TASK_1075 - Large Map Tactical Badge Lifecycle Audit (implementiert im Arbeitsstand)
- Grundlage: TASK_505 behaelt 192x192-Streaming und das Renderbudget, zeigte nach Sieg aber keine sichtbaren Unit-Tactical-Badges.
- Ergebnis: TASK_505 ist nach Sieg wieder gruen: fuenf sichtbare Proxies tragen lesbare Badges, Chunk-Streaming bleibt aktiv. TASK_160 22/22 und TASK_833 23/23 sichern die normale Missionsansicht sowie den weiterhin kompakten aktiven Feuerkontakt ab.
- Ursache/Fix: Der Release-Firefight-Declutter blieb trotz autoritativem Missionsresultat aktiv, weil nur die noch sichtbare Decision-Line ausgewertet wurde. Nach `victory`, `defeat` oder `aborted` wird die normale World-Label-Dichte verwendet; Gameplay- und Streaming-Wahrheit bleiben unveraendert.
- Naechster Schritt: Sauberen Integrationscommit exportieren und einen frischen Provenance-Release fuer den sichtbaren Station-Route- oder Host/Client-Lauf erzeugen. TASK_838/839 brauchen getrennt einen Refresh ihrer alten Release-UI-Snapshot-Kette.

## TASK_1080 - Station Route Live Fire-Rule Propagation (implementiert im Arbeitsstand)
- Grundlage: TASK_1079 zeigte, dass `Hold Fire` im echten Guard-Contact keinen freiwilligen FireEvent hinzufuegt. Der Setter aktualisierte dabei aber nur Controller und Behavior-Profil; laufende Unit-Commands konnten ihre vorherige ROE behalten.
- Ergebnis: TASK_1080 ist 17/17 gruen. `return` und `free` erreichen im realen Homebase -> Drop -> Deboard -> GO -> Guard-Contact sofort Movement-State und alle aktiven Bravo-Unit-Commands. Die Command-Revision steigt bei jedem Wechsel; TASK_1079, TASK_570, TASK_501 und TASK_607 bleiben gruen.
- Ursache/Fix: Der bestehende Live-Stance-Refresh wurde als Fire-Rule-Refresh gespiegelt. Der aktuelle Stage wird mit unveraendertem Ziel ueber `SimulationRoot` neu ausgegeben, sodass alte tokenisierte Move-Commands die neuere ROE nicht zuruecksetzen koennen.
- Naechster Schritt: TASK_1081 macht die jetzt echte Wirkung lesbar: kurze Konsequenzanzeige fuer Hold/Return/Free, Incoming-Fire-Fenster sowie Friendly-Fire-/Cover-Grund im Guard-Contact.

## TASK_1079 - Station Route Real First Exchange (implementiert im Arbeitsstand)
- Grundlage: Die vorhandenen First-Engagement-Smokes erzeugten ihren Gegnerkontakt teilweise per Test-Positionierung. Nach TASK_1078 musste geklaert werden, ob der echte Scenario-Guard nach dem Advance denselben Entscheidungsweg erreicht.
- Ergebnis: TASK_1079 ist 14/14 gruen. Der reale Guard-Contact liefert Fire-/Wait-/No-Fire-Status, Grund und Deckungs-/Range-/LOS-Kontext ohne Teleport, Status-Manipulation oder erzwungenen Treffer. Hold Fire setzt im selben Contact keine freiwilligen FireEvents; Evac bleibt erreichbar.
- Ursache/Fix: Kein neuer Produktionsfehler. Die bestehende Contact-, Combat- und Feedback-Kette funktioniert auf der echten Route; der neue Trace ersetzt die unsichere Annahme durch einen wiederholbaren End-to-End-Nachweis.
- Naechster Schritt: Den bestehenden Fire-/Wait-Entscheid als sichtbare Commander-Wahl balancen: Guard-Deckung, Feuerdisziplin, Friendly-Fire-Hinweis sowie Advance, Hold und Evac.

## TASK_1078 - Station Route Approach Contact Timing (implementiert im Arbeitsstand)
- Grundlage: Der neue TASK-1077-Guard erzeugte zwar einen echten Scenario-Contact, stand nach Deboard aber bereits in Kontaktreichweite. Damit fehlte die kurze, lesbare Planungsphase vor dem ersten `GO`.
- Ergebnis: Der normale Drop beginnt kontaktfrei. Ein vorhandener Move bleibt als Ghost/Pfad/Risiko Preview; erst der bestaetigte Move in die Approach-Zone erzeugt einen Bravo-Contact. Die LZ-Evac-Alternative bleibt erreichbar. TASK_1078 ist 11/11 und TASK_1077 10/10 gruen.
- Ursache/Fix: Der benannte Guard-Posten ist um einen Tile-Schritt nach aussen abgestimmt. Der Runtime-Patrol-, Contact-, Command- und Evac-Pfad wird unveraendert wiederverwendet; kein Test teleportiert NPCs oder mutiert Contact-Wahrheit.
- Naechster Schritt: Den ersten Feuerwechsel nach dem jetzt echten Advance-Contact als kleine Spielerentscheidung pruefen: Guard-Deckung, Feuerdisziplin, Friendly-Fire-Hinweis und die sichtbare Wahl zwischen Advance und Evac.

## TASK_1077 - Station Route First Contact Pressure (implementiert im Arbeitsstand)
- Grundlage: Die Station Route beschrieb Guard-Druck, aber TASK_1068 musste einen Bravo-NPC fuer den ersten sichtbaren Kontakt noch manuell umsetzen. Beide Bravo-Gruppen starteten am fernen AA-Spawn.
- Ergebnis: Nach normalem Homebase -> Drop -> Deboard ist der Szenarioguard vorbereitet, ohne den Spawn in Contact zu sperren. Ghost, Pfad und Risiko bleiben ein Plan; der Spieler kann den Move bestaetigen oder die vorhandene LZ-Evac-Alternative nutzen. TASK_1078 sichert den folgenden Contact nach `GO`; AA, Door, Computer, Cargo und der volle Debriefing-Pfad bleiben gruen.
- Ursache/Fix: `bravo_station_guard` startet am neuen `approach_guard_post` und bindet die bestehende `station_loop_route` gegen seine Group-ID. `bravo_air_defense` bleibt bei `spawn_bravo`. Der Validator akzeptiert nun dieselbe Enemy-Group-Referenz, die der Runtime-Patrol-Resolver seit jeher aufloesen konnte.
- Naechster Schritt: TASK_1078 legt die zeitliche Contact-Grenze fest; danach den sichtbaren First-Contact-Run auf Guard-Deckung, Feuerdisziplin und die Wahl zwischen Advance und Evac abnehmen.

## TASK_1076 - Release Firefight Contract Chain Refresh (implementiert im Arbeitsstand)
- Grundlage: TASK_1074 etablierte `CONTACT FIRE` vor `NEXT/WHY`, aber die alten TASK_834- bis TASK_839-Gates erwarteten noch die umgekehrte Reihenfolge und fielen dadurch als ganze Kette.
- Ergebnis: TASK_834 27/27, TASK_835 28/28, TASK_836 29/29, TASK_838 28/28 und TASK_839 31/31 sind wieder gruen. Die Kette prueft damit den aktuellen sichtbaren Firefight-Contract statt historische Presentation-Details.
- Ursache/Fix: Read-only Snapshots exportieren nun die lokale Contact-Zeile und die gemeinsame sichtbare Decision-Zeile. Der Event-Log akzeptiert neben dem alten Fallback den vorhandenen TASK_847-Visibility-Presenter. Keine UI, Combat-, Command- oder Multiplayer-Wahrheit wurde veraendert.
- Naechster Schritt: Den zusammenhaengenden Firefight mit Large-Map, Host/Client und frischem Provenance-Release pruefen; danach den sichtbaren Station-Route-First-Round-Playtest anhand konkreter Befunde verbessern.

## TASK_1056 - Active Mission Transport Payload Consumer Repair (implementiert im Arbeitsstand)
- Grundlage: TASK_1055 belegt korrekte Homebase-/Planning-Payloads, aber keine Runtime-Units nach Start.
- Ergebnis: Nach der vorhandenen Transferankunft startet der Einzel-Dropship mit seinem korrekten Pending-/Sequence-Payload; TASK_1057 prueft den Mehr-Dropship-Folgepfad.

## TASK_1055 - Homebase Transport Payload to Active Mission Audit (implementiert im Arbeitsstand)
- Ergebnis: Payload ist vor Missionsstart vollstaendig. TASK_1056 stellte klar, dass der Einzel-Dropship-Consumer nach Transferankunft korrekt arbeitet; TASK_1057 korrigiert den separaten Mehr-Dropship-Contract-Handoff.

## TASK_1054 - Deboarded Fireteam Combat Registry Activation Audit (implementiert im Arbeitsstand)
- Grundlage: TASK_1053 findet nach Deboarding keine Combat-registrierte ft1-LOS-Basis.
- Ergebnis: deployed IDs und Combat-Friendlies sind nach Deboarding leer; der Fehler liegt im Homebase-zu-Mission-Payload-Handoff.

## TASK_1053 - LOS-Valid First Contact Fixture (implementiert im Arbeitsstand)
- Grundlage: TASK_1052 erreicht First Contact, erzeugt aber noch keinen validen LOS-Kontakt.
- Ergebnis: Die Fixture nutzt echte Combat-Friendlies und LOS, belegt aber eine fehlende Deboarded-Runtime-Registry-Basis.

## TASK_1052 - First Move and Contact Flow Trace (implementiert im Arbeitsstand)
- Grundlage: TASK_1051 bringt den Flow durch LZ/Drop/Deboard.
- Ergebnis: Move/GO und Contact-Stages liegen unter Budget; Contact ist wegen fehlender LOS-Gueltigkeit noch `review`.

## TASK_1051 - Planning State Signal Fanout Guard (implementiert im Arbeitsstand)
- Grundlage: TASK_1050 misst `_emit_planning_state_changed()` mit rund 13,2 Sekunden beim LZ-Setzen.
- Ergebnis: Unsichtbare Meta-Screen-Refreshes werden waehrend aktiver Mission nicht mehr ausgefuehrt. LZ: 13,8 s auf 1,0 s; LZ-/Drop-/Deboard-Stage schliesst nach 17,5 s ab.

## TASK_1050 - LZ Drop and Deboard Flow Timing Breakdown (implementiert im Arbeitsstand)
- Grundlage: TASK_1049 beendet den sichtbaren Startframe-Blocker; TASK_1045 erreicht erstmals LZ/Drop und stoppt dort kontrolliert.
- Ziel: LZ setzen, Drop ausloesen, Aussteigen und Runtime-Aktivierung nach Transport-, Simulation-, Terrain- und HUD-Teilpfaden messen.
- Ergebnis: LZ-Setzen misst rund 13,8 Sekunden, davon `_emit_planning_state_changed()` rund 13,2 Sekunden. Transport und Deboarding sind noch nicht der erste Blocker.
- Naechster Schritt: TASK_1051 - Planning State Signal Fanout Audit and Guard.

## TASK_1049 - Enemy Team Tactics Hotpath Breakdown and Decision Revision Guard (implementiert im Arbeitsstand)
- Grundlage: TASK_1048 misst `enemy_team_tactics_usec` mit rund 405-420 ms als dominanten Anteil des Combat-Listeners.
- Ziel: Enemy-Team-Taktik intern nach Gruppen-/Threat-/Cover-/Flank-Entscheidungen aufschluesseln und bei unveraendertem Entscheidungsinput wiederholte Berechnung vermeiden, ohne Reaktionszeit oder Autoritaet zu verlieren.
- Ergebnis: TASK_1049 ist 6/6 gruen. Identische Taktikinpute skippen Cover-/LOS-Rebuilds; Friendly-Bewegung berechnet sofort neu. Der reale Starttrace erreicht acht sichtbare Frames in rund 4,8 Sekunden, danach ist `lz_drop_and_deboard` der erste Blocker.
- Naechster Schritt: TASK_1050 - LZ Drop and Deboard Flow Timing Breakdown.

## TASK_1048 - Simulation Tick Signal Fanout Audit and Guard (implementiert im Arbeitsstand)
- Grundlage: TASK_1047 misst `SimulationRoot.tick_processed.emit()` mit rund 400-478 ms innerhalb langsamer Missionsframes.
- Ziel: Alle verbundenen Tick-Empfaenger, ihre teure Folgearbeit und vermeidbare Wiederholungswege transparent machen; nur belegte Viewer-/Visual-Listener gezielt takten oder dirty-gaten.
- Ergebnis: TASK_1048 ist 7/7 gruen. Der einzige direkte Listener ist `MissionCombatLoopDriver`; seine `enemy_team_tactics_usec` kostet im echten Startfenster rund 405-420 ms und erklaert die Signal-Emit-Zeit.
- Naechster Schritt: TASK_1049 - Enemy Team Tactics Hotpath Breakdown and Decision Revision Guard.

## TASK_1047 - Mission Visible Frame Cross-System Timing Breakdown (implementiert im Arbeitsstand)
- Grundlage: TASK_1045 belegt langsame sichtbare Missionsframes; TASK_1046 schuetzt wiederholte Terrain-Statusvisuals, senkt den kombinierten Frame aber nicht messbar.
- Ziel: Den einzelnen sichtbaren Missionsframe entlang Controller, SimulationRoot und TerrainMap3DView in benannte Teilpfade und Zeiten zerlegen, ohne den Runtime-State zu veraendern.
- Ergebnis: TASK_1047 ist 11/11 gruen. Im echten Startfenster ist `SimulationRoot.tick_signal_emit_usec` mit rund 400-478 ms der erste belegte Code-Hotpath; Terrain-Skriptarbeit liegt bei rund 32-37 ms, Controller einmal bei rund 444 ms.
- Naechster Schritt: TASK_1048 - Simulation Tick Signal Fanout Audit and Guard.

## TASK_1046 - Terrain Mission Status Payload Signature Guard (implementiert im Arbeitsstand)
- Grundlage: TASK_1045 zeigte wiederkehrende Terrain-Statusvisuals als plausiblen Kandidaten innerhalb des Controller-/Simulation-/Terrain-Hotpaths.
- Ziel: Gleiche sichtbare Objective-, Route-, Interaction- und Result-Daten duerfen `StatusRoot3D` nicht erneut aufbauen; echte Sichtaenderungen muessen unmittelbar bleiben.
- Ergebnis: TASK_1046 ist 12/12 gruen, TASK_170 bleibt 62/62 gruen. Der Guard behaelt gleiche Status-3D-Nodes und filtert nicht gerenderte Diagnostik aus der Visual-Signatur. Die integrierte Kombinationsprobe liegt dennoch weiter bei rund 3.396 ms pro Frame.
- Naechster Schritt: TASK_1047 - Mission Visible Frame Cross-System Timing Breakdown.

## TASK_1045 - Mission First Contact End-to-End Timing Trace (implementiert im Arbeitsstand)
- Grundlage: TASK_542 blieb nach den HUD-Guards offen und lieferte nur ein externes Timeout.
- Ziel: Den echten Homebase-zu-First-Contact-Ablauf intern pro Stage zeitmarkieren und den wartenden Lebenszyklus-Schritt eindeutig nennen.
- Ergebnis: Der Trace misst sichtbare Missionsframes als Blocker: 5 Frames brauchten rund 21 Sekunden, mit einzelnen Frames von rund 3,4 bis 7,0 Sekunden. Die Interaktion `MissionTacticalSandboxController + SimulationRoot + TerrainMap3DView` ist der gemessene Hotpath.
- Naechster Schritt: TASK_1047 - Mission Visible Frame Cross-System Timing Breakdown.

## TASK_1044 - Mission HUD Runtime Surface Guard (implementiert im Arbeitsstand)
- Grundlage: TASK_1043 entfernte den Event-Log-Vollsnapshot; die Frame-Probe zeigte danach weiter wiederholte Matrix- und Fireteam-Card-Rebuilds.
- Ziel: Command Matrix, Selected Member Cards und Fireteam Mini Cards nur bei sichtbarer Zustandsaenderung neu anwenden oder aufbauen.
- Ergebnis: Controller-lokale UI-Fingerprints behalten unveraenderte Node-Instanzen, wenden echte Zustandsaenderungen sofort an und bleiben read-only.
- Naechster Schritt: Den verbleibenden Meta-/Missionsuebergang im TASK-542-Gesamtflow zeitlich markieren und den naechsten tatsaechlichen Blocker entfernen.

## TASK_1043 - Mission HUD Hotpath Event Log Guard (implementiert im Arbeitsstand)
- Grundlage: Der echte Homebase-zu-First-Contact-Flow zeigte einen ueberladenen wiederkehrenden HUD-Refresh.
- Ziel: Das Tactical Event Log ueber einen schmalen Live-Snapshot versorgen, statt im 0.35-Sekunden-Refresh den vollstaendigen Command-Feedback-/Release-Report zu bauen.
- Ergebnis: `get_live_tactical_event_log_feedback_snapshot()` bleibt read-only, haelt CONTACT-FIRE-First und Event-Log-Polish sichtbar und erzeugt keine Gameplay-, Command-, Movement-, Combat-, Damage- oder Multiplayer-Wahrheit.
- Naechster Schritt: Die verbleibenden gemessenen HUD-Surfaces gezielt entschlacken und erst danach den First-Contact-Player-Feel-Befund als sichtbaren Task schneiden.

## TASK_1042 - Release First Decision Loop Two Player Loop Scenario First Contact Integrated Playtest (implementiert im Arbeitsstand)
- Grundlage: bestandener TASK_1041 First Contact Acceptance Slice.
- Ziel: Den First-Contact-Griff im integrierten Release-/Mission-Kontext pruefen: Entry, Command-Feedback, CONTACT, WHY, NEXT, FIRE/WAIT, GO, FEEDBACK, Rueckkehr zu NEXT, Performance und Systemgrenzen.
- Ergebnis: Read-only Snapshot `blocked | needs_first_contact_integrated_playtest_trace | first_contact_integrated_playtest_regression_found | first_contact_integrated_playtest_passed`.
- Naechster Schritt: TASK_1043 - Release First Decision Loop Two Player Loop Scenario First Contact Player Feel Findings.

## TASK_1041 - Release First Decision Loop Two Player Loop Scenario First Contact Acceptance Slice (implementiert im Arbeitsstand)
- Grundlage: TASK_1040 First Contact Visual Polish mit bereiten CONTACT-/WHY-/NEXT-/FIRE-WAIT-/FEEDBACK-/GO-/HUD-MP-Surface-Specs.
- Ziel: Den gepolishte First-Contact-Griff als kleinen Acceptance-Slice pruefen: Spieler versteht Kontakt, Risiko, naechsten Griff, Feuerwahl, Feedback und bewusste GO-Grenze.
- Ergebnis: Read-only Snapshot `blocked | needs_first_contact_acceptance_trace | first_contact_acceptance_regression_found | first_contact_acceptance_slice_passed`.
- Naechster Schritt: TASK_1042 - Release First Decision Loop Two Player Loop Scenario First Contact Integrated Playtest.

## TASK_1040 - Release First Decision Loop Two Player Loop Scenario First Contact Visual Polish (implementiert im Arbeitsstand)
- Grundlage: TASK_1039 First Contact Visual Findings mit Reibung oder akzeptiertem Befund.
- Ziel: CONTACT, WHY, NEXT, FIRE/WAIT, FEEDBACK, GO und HUD/MP als ruhige read-only Surface-Specs fuer den ersten Kontakt polishen.
- Ergebnis: Read-only Snapshot `blocked | first_contact_visual_polish_ready` mit Polish-Line, Surface-Specs, FIRE/WAIT-Microcopy und GO-Microcopy.
- Naechster Schritt: TASK_1041 - Release First Decision Loop Two Player Loop Scenario First Contact Acceptance Slice.

## TASK_1039 - Release First Decision Loop Two Player Loop Scenario First Contact Visual Findings (implementiert im Arbeitsstand)
- Grundlage: akzeptierter TASK_1038 First Contact Real Window Capture.
- Ziel: Echten Fensterblick als Sichtbefund schneiden: CONTACT, WHY, NEXT, FIRE/WAIT, FEEDBACK, `GO separat`, HUD-Ruhe und Multiplayer-Grenze.
- Ergebnis: Read-only Snapshot `blocked | needs_first_contact_visual_review | ready_for_first_contact_visual_polish | accepted_for_first_contact_acceptance_slice`.
- Naechster Schritt: TASK_1040 - Release First Decision Loop Two Player Loop Scenario First Contact Visual Polish oder TASK_1040 - Release First Decision Loop Two Player Loop Scenario First Contact Acceptance Slice.

## TASK_1038 - Release First Decision Loop Two Player Loop Scenario First Contact Real Window Capture (implementiert im Arbeitsstand)
- Grundlage: TASK_1037 First Contact Playability Slice.
- Ziel: Echten Fenster-/Capture-Rahmen fuer CONTACT, WHY, NEXT, FIRE/WAIT, FEEDBACK und `GO separat` vorbereiten.
- Ergebnis: Read-only Snapshot `blocked | needs_first_contact_real_window_capture | review_ready | accepted`.
- Naechster Schritt: TASK_1039 - Release First Decision Loop Two Player Loop Scenario First Contact Visual Findings.

## TASK_1037 - Release First Decision Loop Two Player Loop Scenario First Contact Playability Slice (implementiert im Arbeitsstand)
- Grundlage: TASK_1036 First Contact Player Feel Polish.
- Ziel: CONTACT, WHY, NEXT, FIRE/WAIT, FEEDBACK und `GO separat` als kleinen spielbaren First-Contact-Griff pruefen.
- Ergebnis: Read-only Snapshot `blocked | needs_first_contact_playability_trace | first_contact_playability_regression_found | first_contact_playability_slice_passed`.
- Naechster Schritt: TASK_1038 - Release First Decision Loop Two Player Loop Scenario First Contact Real Window Capture.

## TASK_1036 - Release First Decision Loop Two Player Loop Scenario First Contact Player Feel Polish (implementiert im Arbeitsstand)
- Grundlage: TASK_1035 First Contact Player Feel Findings mit Reibung oder akzeptiertem First-Contact-Befund.
- Ziel: CONTACT, WHY, NEXT, FEEDBACK, GO und HUD/MP als ruhige read-only Surface-Specs fuer den ersten Kontakt polishen.
- Ergebnis: Read-only Snapshot `blocked | first_contact_player_feel_polish_ready` mit Polish-Line, Surface-Specs, GO-Microcopy und NEXT-Griff.
- Naechster Schritt: TASK_1037 - Release First Decision Loop Two Player Loop Scenario First Contact Playability Slice.

## TASK_1035 - Release First Decision Loop Two Player Loop Scenario First Contact Player Feel Findings (implementiert im Arbeitsstand)
- Grundlage: bestandener TASK_1034 First Contact Runtime Smoke.
- Ziel: Den Spielerblick auf den ersten Kontakt schneiden: CONTACT klar, WHY handlungsfaehig, NEXT verstaendlich, `GO separat`, Feedback, HUD-Ruhe, Responsiveness und Multiplayer-Grenze.
- Ergebnis: Read-only Snapshot `blocked | needs_first_contact_player_feel_review | first_contact_player_feel_rework_needed | accepted_for_first_contact_playability_slice`.
- Naechster Schritt: TASK_1036 - Release First Decision Loop Two Player Loop Scenario First Contact Player Feel Polish oder TASK_1036 - Release First Decision Loop Two Player Loop Scenario First Contact Playability Slice.

## TASK_1034 - Release First Decision Loop Two Player Loop Scenario First Contact Runtime Smoke (implementiert im Arbeitsstand)
- Grundlage: bereiter TASK_1033 First Contact Runtime Hook.
- Ziel: CONTACT, WHY, NEXT, FEEDBACK und `GO separat` in einem read-only Smoke-Trace gegen echten Snapshot-Kontext pruefen.
- Ergebnis: Read-only Snapshot `blocked_until_first_contact_runtime_hook | needs_first_contact_runtime_smoke_trace | needs_first_contact_runtime_smoke_completion | first_contact_runtime_smoke_regression_found | first_contact_runtime_smoke_passed`.
- Naechster Schritt: TASK_1035 - Release First Decision Loop Two Player Loop Scenario First Contact Player Feel Findings.

## TASK_1033 - Release First Decision Loop Two Player Loop Scenario First Contact Runtime Hook (implementiert im Arbeitsstand)
- Grundlage: bereiter TASK_1032 Next Playable Slice Plan.
- Ziel: Den ersten Kontakt als Runtime-Hook lesbar machen: CONTACT, COVER, LOS, FIRE/WAIT, FEEDBACK und `GO separat`.
- Ergebnis: Read-only Snapshot `blocked_until_next_playable_slice_plan | needs_first_contact_runtime_hook_context | first_contact_runtime_hook_review | first_contact_runtime_hook_ready`.
- Naechster Schritt: TASK_1034 - Release First Decision Loop Two Player Loop Scenario First Contact Runtime Smoke.

## TASK_1032 - Release First Decision Loop Two Player Loop Scenario Next Playable Slice Plan (implementiert im Arbeitsstand)
- Grundlage: akzeptierter TASK_1031 Scenario Tester Run Acceptance.
- Ziel: Den naechsten konkreten spielbaren Slice festlegen: erster Kontakt mit lesbarer CONTACT/COVER/LOS/FIRE-WAIT/FEEDBACK-Entscheidung.
- Ergebnis: Read-only Snapshot `blocked_until_tester_run_acceptance | needs_next_playable_slice_plan | needs_next_playable_slice_plan_completion | next_playable_slice_plan_regression_found | next_playable_slice_plan_ready`.
- Naechster Schritt: TASK_1033 - Release First Decision Loop Two Player Loop Scenario First Contact Runtime Hook.

## TASK_1017 - Release First Decision Loop Two Player Loop Scenario Playability Slice (implementiert im Arbeitsstand)
- Grundlage: TASK_1016 Scenario Player Feel Polish.
- Ziel: Kleinen FOB-Szenario-Griff mit Trace gegen Spielerfragen pruefen: FOB, Objective, Rollen, NEXT/CONFIRM/GO, Feedback, HUD-Ruhe und Multiplayer-Grenze.
- Ergebnis: Read-only Snapshot `scenario_playability_slice_passed | needs_scenario_playability_trace | scenario_playability_regression_found`.
- Naechster Schritt: TASK_1018 - Release First Decision Loop Two Player Loop Scenario Real Window Capture.

## TASK_1018 - Release First Decision Loop Two Player Loop Scenario Real Window Capture (implementiert im Arbeitsstand)
- Grundlage: TASK_1017 Scenario Playability Slice.
- Ziel: Echten Release-Fenster-Capture-Rahmen fuer den kleinen FOB-Szenario-Griff vorbereiten.
- Ergebnis: Read-only Snapshot `needs_scenario_real_window_capture | review_ready | accepted`.
- Naechster Schritt: TASK_1019 - Release First Decision Loop Two Player Loop Scenario Visual Findings.

## TASK_1019 - Release First Decision Loop Two Player Loop Scenario Visual Findings (implementiert im Arbeitsstand)
- Grundlage: TASK_1018 Scenario Real Window Capture.
- Ziel: Echten Fensterblick als Sichtbefund schneiden: FOB-Entry, Objective, Rollen, NEXT/CONFIRM/GO, Feedback, HUD-Ruhe und Multiplayer-Grenze.
- Ergebnis: Read-only Snapshot `needs_manual_review | ready_for_scenario_visual_polish | accepted_for_scenario_acceptance_slice`.
- Naechster Schritt: TASK_1020 - Release First Decision Loop Two Player Loop Scenario Visual Polish oder TASK_1020 - Release First Decision Loop Two Player Loop Scenario Acceptance Slice.

## TASK_1020 - Release First Decision Loop Two Player Loop Scenario Acceptance Slice (implementiert im Arbeitsstand)
- Grundlage: akzeptierte TASK_1019 Scenario Visual Findings.
- Ziel: Kleinen FOB-Szenario-Griff als Acceptance-Slice pruefen: FOB, Objective, Rollen, NEXT/CONFIRM/GO, Feedback, HUD-Ruhe und Multiplayer-Grenze.
- Ergebnis: Read-only Snapshot `needs_scenario_acceptance_trace | scenario_acceptance_regression_found | scenario_acceptance_slice_passed`.
- Naechster Schritt: TASK_1021 - Release First Decision Loop Two Player Loop Scenario Integrated Playtest.

## TASK_1021 - Release First Decision Loop Two Player Loop Scenario Integrated Playtest (implementiert im Arbeitsstand)
- Grundlage: bestandener TASK_1020 Scenario Acceptance Slice.
- Ziel: Kleinen FOB-Szenario-Griff im integrierten Release-/Mission-Kontext pruefen: Entry, Command-Feedback, FOB, NEXT/CONFIRM/GO, GO separat, Post-GO-Feedback, Rueckkehr zu NEXT, Performance und Multiplayer-Grenze.
- Ergebnis: Read-only Snapshot `needs_scenario_integrated_playtest_trace | scenario_integrated_playtest_regression_found | scenario_integrated_playtest_passed`.
- Naechster Schritt: TASK_1022 - Release First Decision Loop Two Player Loop Scenario Player Feel Findings.

## TASK_1022 - Release First Decision Loop Two Player Loop Scenario Player Feel Findings (implementiert im Arbeitsstand)
- Grundlage: bestandener TASK_1021 Scenario Integrated Playtest.
- Ziel: Menschlichen Player-Feel-Befund schneiden: fuehlt sich Entry, FOB, NEXT/CONFIRM/GO, Post-GO-Feedback, HUD, Performance, Zwei-Spieler-Kontext und Multiplayer-Grenze wie ein kleiner runder Spielmoment an?
- Ergebnis: Read-only Snapshot `needs_scenario_integrated_player_feel_review | scenario_integrated_player_feel_rework_needed | accepted_for_small_game_acceptance_slice`.
- Naechster Schritt: TASK_1023 - Release First Decision Loop Two Player Loop Scenario Player Feel Polish oder TASK_1023 - Release First Decision Loop Two Player Loop Scenario Small Game Acceptance Slice.

## TASK_1023 - Release First Decision Loop Two Player Loop Scenario Small Game Acceptance Slice (implementiert im Arbeitsstand)
- Grundlage: akzeptierter TASK_1022 Scenario Integrated Player Feel Findings.
- Ziel: Kleinen FOB-Szenario-Griff als kleines Spielmoment akzeptieren: FOB/NEXT sichtbar, Objective/Rollen klar, GO separat, Feedback zurueck zu NEXT, HUD ruhig, Zwei-Spieler-Kontext und Multiplayer-Grenze erhalten.
- Ergebnis: Read-only Snapshot `needs_small_game_acceptance_trace | small_game_acceptance_regression_found | small_game_acceptance_slice_passed`.
- Naechster Schritt: TASK_1024 - Release First Decision Loop Two Player Loop Scenario Release Candidate Playtest.

## TASK_1024 - Release First Decision Loop Two Player Loop Scenario Release Candidate Playtest (implementiert im Arbeitsstand)
- Grundlage: bestandener TASK_1023 Small Game Acceptance Slice.
- Ziel: Kleinen FOB-Szenario-Griff im Release-Candidate-Playtest pruefen: Release-Exe, Singleplayer, FOB, Rollen, NEXT/CONFIRM/GO, GO, FEEDBACK, Rueckkehr zu NEXT, Performance und Multiplayer-Grenze.
- Ergebnis: Read-only Snapshot `needs_release_candidate_playtest_manifest | needs_release_candidate_playtest_completion | release_candidate_playtest_regression_found | release_candidate_playtest_passed`.
- Naechster Schritt: TASK_1025 - Release First Decision Loop Two Player Loop Scenario Release Candidate Acceptance oder TASK_1025 - Release First Decision Loop Two Player Loop Scenario Targeted RC Polish.

## TASK_1025 - Release First Decision Loop Two Player Loop Scenario Release Candidate Acceptance (implementiert im Arbeitsstand)
- Grundlage: bestandener TASK_1024 Release Candidate Playtest.
- Ziel: Acceptance-Entscheidung fuer den kleinen FOB-Szenario-Griff schneiden: keine sichtbaren Spielerblocker, keine Regressionen, keine Input-Sackgasse, Performance akzeptabel, Multiplayer-/HUD-Grenze erhalten und Ship-Readiness-Notizen vorhanden.
- Ergebnis: Read-only Snapshot `needs_release_candidate_acceptance_review | release_candidate_acceptance_regression_found | release_candidate_accepted`.
- Naechster Schritt: TASK_1026 - Release First Decision Loop Two Player Loop Scenario Ship Readiness Review.

## TASK_1026 - Release First Decision Loop Two Player Loop Scenario Ship Readiness Review (implementiert im Arbeitsstand)
- Grundlage: akzeptierter TASK_1025 Release Candidate.
- Ziel: Uebergabe fuer den sichtbaren EXE-/Ship-Smoke pruefen: Release-EXE, PCK, Szenario-ID, Testerhinweise, Operator-Ziel, bekannte Risiken, Uebergabe-Items, Multiplayer-Grenze, HUD-Wahrheit und Review-Abschluss.
- Ergebnis: Read-only Snapshot `needs_ship_readiness_packet | ship_readiness_incomplete | ship_readiness_ready`.
- Naechster Schritt: TASK_1027 - Release First Decision Loop Two Player Loop Scenario Visible Ship Smoke.

## TASK_1027 - Release First Decision Loop Two Player Loop Scenario Visible Ship Smoke (implementiert im Arbeitsstand)
- Grundlage: bereite TASK_1026 Ship Readiness.
- Ziel: Sichtbaren Release-Smoke fuer den kleinen FOB/NEXT/GO/FEEDBACK-Spielmoment schneiden: frische EXE, Einzelspieler, FOB, NEXT, GO, FEEDBACK, keine Input-Sackgasse, Responsiveness und keine stale Taskbar-/Build-Verwechslung.
- Ergebnis: Read-only Snapshot `needs_visible_ship_smoke | needs_visible_ship_smoke_completion | visible_ship_smoke_regression_found | visible_ship_smoke_passed`.
- Naechster Schritt: TASK_1028 - Release First Decision Loop Two Player Loop Scenario Delivery Review oder TASK_1027 - Release First Decision Loop Two Player Loop Scenario Visible Ship Smoke Polish.

## TASK_1028 - Release First Decision Loop Two Player Loop Scenario Delivery Review (implementiert im Arbeitsstand)
- Grundlage: bestandener TASK_1027 Visible Ship Smoke.
- Ziel: Delivery-Review fuer den kleinen Release-Spielmoment schneiden: Release-Dateien, Startanweisung, bekannte Risiken, Risikoannahme, Shortcut-Warnung, Multiplayer-/HUD-Grenze und naechsten Handoff pruefen.
- Ergebnis: Read-only Snapshot `needs_delivery_review | needs_delivery_review_completion | delivery_review_regression_found | delivery_review_ready`.
- Naechster Schritt: TASK_1029 - Release First Decision Loop Two Player Loop Scenario Handoff Packet oder TASK_1028 - Release First Decision Loop Two Player Loop Scenario Delivery Polish.

## TASK_1029 - Release First Decision Loop Two Player Loop Scenario Handoff Packet (implementiert im Arbeitsstand)
- Grundlage: bereite TASK_1028 Delivery Review.
- Ziel: Kleines Tester-Handoff fuer den FOB/NEXT/GO/FEEDBACK-Spielmoment schneiden: Release-Dateien, Startanweisung, Shortcut-Warnung, Risiken, naechste Tester-Aktion, Multiplayer-Grenze und HUD-Wahrheit.
- Ergebnis: Read-only Snapshot `needs_handoff_packet | needs_handoff_packet_completion | handoff_packet_regression_found | handoff_packet_ready`.
- Naechster Schritt: TASK_1030 - Release First Decision Loop Two Player Loop Scenario Tester Run oder TASK_1029 - Release First Decision Loop Two Player Loop Scenario Handoff Polish.

## TASK_1030 - Release First Decision Loop Two Player Loop Scenario Tester Run (implementiert im Arbeitsstand)
- Grundlage: bereites TASK_1029 Handoff Packet.
- Ziel: Frischen Tester-Run fuer den FOB/NEXT/GO/FEEDBACK-Spielmoment schneiden: Handoff genutzt, frische EXE gestartet, Singleplayer/Homebase handlungsfaehig, erster Loop reagiert, HUD/Performance/Multiplayer-Grenze geprueft.
- Ergebnis: Read-only Snapshot `needs_tester_run | needs_tester_run_completion | tester_run_regression_found | tester_run_ready`.
- Naechster Schritt: TASK_1031 - Release First Decision Loop Two Player Loop Scenario Tester Run Acceptance oder TASK_1030 - Release First Decision Loop Two Player Loop Scenario Tester Run Polish.

## TASK_1031 - Release First Decision Loop Two Player Loop Scenario Tester Run Acceptance (implementiert im Arbeitsstand)
- Grundlage: bereiter TASK_1030 Tester Run.
- Ziel: Tester-Run bewusst akzeptieren oder gezielt zur Politur zurueckgeben: Release-Dateien, Singleplayer-Pfad, FOB/NEXT/GO/FEEDBACK, Performance, HUD-Grenze, Multiplayer-Grenze, bekannte Risiken und naechster spielbarer Slice.
- Ergebnis: Read-only Snapshot `needs_acceptance_review | needs_acceptance_review_completion | tester_run_acceptance_regression_found | tester_run_accepted`.
- Naechster Schritt: TASK_1032 - Release First Decision Loop Two Player Loop Scenario Next Playable Slice Plan oder TASK_1031 - Release First Decision Loop Two Player Loop Scenario Acceptance Polish.

# Arbeitsregeln

## Reihenfolge
- Tasks muessen strikt in der angegebenen Reihenfolge umgesetzt werden
- keine Tasks ueberspringen
- keine Tasks zusammenziehen, ausser im Batch-Mode erlaubt

## Branch-Regel
Vor jedem Task:

```bash
git checkout integration/core-foundation
git checkout -b task/<task-name>
```

Bei Batch-Arbeit:

```bash
git checkout integration/core-foundation
git checkout -b batch/<batch-name>
```

## Task-Hygiene
- Nicht-triviale Aenderungen brauchen eine konkrete Task-Datei unter `docs/tasks/`.
- Task-Dateien nennen relevante Contracts und Dokumente explizit.
- Review-Befunde werden vor dem Task gegen den aktuellen Code geprueft.
- Gameplay-Wahrheit bleibt bei Simulation/Runtime/Contracts/Registries; UI-Tasks duerfen keine zweite Wahrheit einfuehren.
- Hotpath-Tasks muessen SceneTree-Vollscans und per-frame Komplett-Rebuilds vermeiden.

## Aktueller Release-Hotfix
- TASK_1016 - Release First Decision Loop Two Player Loop Scenario Player Feel Polish (implementiert): TASK_1015-Findings werden in sieben read-only Surface-Specs uebersetzt: FOB-Entry, Objective, Alpha/Bravo-Rollen, NEXT/CONFIRM/GO, Feedback, GO-Grenze und Multiplayer-Grenze plus kompakte Polish-Zeilen.
- TASK_1015 - Release First Decision Loop Two Player Loop Scenario Player Feel Findings (implementiert): Der bestandene TASK_1014-Smoke wird gegen Player-Feel-Notizen bewertet: Entry, FOB-Objective, zwei Rollen, NEXT/CONFIRM/GO, Feedback, HUD-Ruhe, Responsiveness und Multiplayer-Grenze routen zu Polish oder Scenario-Playability.
- TASK_1014 - Release First Decision Loop Two Player Loop Scenario Runtime Smoke (implementiert): Der TASK_1013-Runtime-Hook wird als Smoke-Trace bewertet: ENTRY, NEXT, CONFIRM, GO separat, Feedback-zurueck-zu-NEXT sowie HUD-/Multiplayer-Grenzen.
- TASK_1013 - Release First Decision Loop Two Player Loop Scenario Runtime Hook (implementiert): Der TASK_1012-FOB-Stitch wird als Runtime-Hook sichtbar: Szenario-Schritte, `SICHERN/DRUECKEN/SAMMELN`, Mission-Control-Zeile, Selected-Fireteam-Zeile und read-only Command-Matrix-Hooks fuer `NEXT`, `CONFIRM` und `GO`.
- TASK_1012 - Release First Decision Loop Two Player Loop Scenario Stitch (implementiert): Der akzeptierte TASK_1011-Round-Loop wird in einen kleinen FOB-Szenario-Rahmen ueberfuehrt: Einstieg, Objective, NPC-Druck, zwei Spielerrollen, FEEL/NEXT/GO, Feedback-zurueck-zu-NEXT, Exit und naechster Runtime-Hook.
- TASK_1011 - Release First Decision Loop Two Player Loop Micro Objective Round Loop Acceptance Slice (implementiert): Der TASK_1010-Player-Feel-Polish wird mit Trace-Evidence als akzeptierter kleiner Spielergriff bewertet: `FEEL/NEXT/GO`, Feedback-zurueck-zu-NEXT, GO separat, ruhiges HUD, Performance-Gefuehl und Multiplayer-Grenze.
- TASK_1010 - Release First Decision Loop Two Player Loop Micro Objective Round Loop Player Feel Polish (implementiert): TASK_1009-Findings werden in sechs read-only Player-Feel-Surface-Specs uebersetzt: Start, ROUND/NEXT/GO-Rhythmus, Feedback, GO-Grenze, HUD-Ruhe und Multiplayer-Grenze plus `FEEL | NEXT | GO`-Zeile.
- TASK_1009 - Release First Decision Loop Two Player Loop Micro Objective Round Loop Player Feel Findings (implementiert): Der bestandene TASK_1008-Integrated-Playtest wird mit Player-Feel-Notizen als read-only Befund bewertet: keine Notizen halten Review offen, Reibung routet zu Player-Feel-Polish, sauberer Befund routet zum Round-Loop-Acceptance-Slice.
- TASK_1008 - Release First Decision Loop Two Player Loop Micro Objective Round Loop Integrated Playtest (implementiert): Der bestandene TASK_1007-Round-Loop wird im Release-/Mission-Kontext mit Trace-Evidence bewertet: Entry, Command-Feedback, `ROUND`, `NEXT`, Confirm, separates `GO`, Post-GO-Feedback, Rueckkehr zu NEXT, HUD-/Multiplayer-Grenze und Performance-Budget.
- TASK_1007 - Release First Decision Loop Two Player Loop Micro Objective Round Loop Playability Slice (implementiert): Der TASK_1006-Round-Loop-Polish wird mit Trace-Evidence als read-only Spielergriff bewertet: `ROUND`, `NEXT`, `GO separat`, Feedback-zurueck-zu-NEXT, Confirm-Grenze sowie HUD-/Multiplayer-Grenzen bleiben erhalten.
- TASK_1006 - Release First Decision Loop Two Player Loop Micro Objective Round Loop Visual Polish (implementiert): TASK_1005-Findings werden in sechs read-only Surface-Specs fuer `ROUND`, `NEXT`, `GO`, Selected Fireteam, Mission Control und Command Feedback uebersetzt; der naechste Schritt ist der Playability Slice.
- TASK_1005 - Release First Decision Loop Two Player Loop Micro Objective Round Loop Visual Findings (implementiert): Der TASK_1004-Capture wird als read-only Sichtbefund geschnitten; Reibung routet zu Round-Loop Visual Polish, sauberer Befund zum Round-Loop Playability Slice.
- TASK_1004 - Release First Decision Loop Two Player Loop Micro Objective Round Loop Real Window Capture (implementiert): Der TASK_1003-Runtime-Polish bekommt einen read-only Real-Window-Capture-/Manifest-Rahmen fuer `ROUND`, `NEXT`, `GO separat`, Screenshotpfade, manuelle Pflichtchecks und erhaltene HUD-/Multiplayer-Grenzen.
- TASK_1003 - Release First Decision Loop Two Player Loop Micro Objective Round Loop Runtime Polish (implementiert): Der bestandene TASK_1002-Zwei-Runden-Slice erzeugt read-only Runtime-Surfaces fuer `ROUND`, `NEXT` und `GO` plus kurze HUD-Zeilen mit sichtbarer `GO separat`-Grenze.
- TASK_1002 - Release First Decision Loop Two Player Loop Micro Objective Round Loop Playtest Slice (implementiert): Ein bestandener TASK_1001-Smoke wird mit Trace-Evidence als read-only Zwei-Runden-Slice bewertet; `NEXT -> CONFIRM -> GO -> FEEDBACK -> NEXT`, kein Feedback-Dead-End und HUD-/Multiplayer-Grenzen bleiben erhalten.
- TASK_1001 - Release First Decision Loop Two Player Loop Micro Objective Round Trip Smoke (implementiert): Ein bestandener TASK_1000-Slice wird mit Trace-Evidence als read-only `NEXT -> CONFIRM -> GO -> FEEDBACK`-Smoke bewertet; Rueckkehr in den naechsten Entscheidungszustand und HUD-/Multiplayer-Grenzen bleiben erhalten.
- TASK_1000 - Release First Decision Loop Two Player Loop Micro Objective Playability Slice (implementiert): Der TASK_999-Polish wird mit Trace-Evidence als read-only Playability-Slice bewertet: OUTCOME/OBJ/NEXT lesbar, naechster Griff verstanden, GO-Grenze und HUD-/Multiplayer-Grenzen erhalten.
- TASK_999 - Release First Decision Loop Two Player Loop Micro Objective Visual Polish (implementiert): Ein TASK_998-Befund erzeugt drei read-only Micro-Objective-Surface-Specs fuer Outcome, Mini-Zielzustand und naechsten Griff plus `OUTCOME | OBJ | NEXT`-Polish-Zeile.
- TASK_998 - Release First Decision Loop Two Player Loop Micro Objective Visual Findings (implementiert): Der TASK_997-Capture wird als read-only Sichtbefund geschnitten; Reibung routet zu Micro-Objective Visual Polish, sauberer Befund zum Micro-Objective Playability Slice.
- TASK_997 - Release First Decision Loop Two Player Loop Micro Objective Real Window Capture (implementiert): Der TASK_996-Micro-Objective-Outcome bekommt einen read-only Real-Window-Capture-/Manifest-Rahmen fuer sichtbare Outcome-Zeile, Mini-Zielzustand und naechsten Griff.
- TASK_996 - Release First Decision Loop Two Player Loop Micro Objective Outcome Slice (implementiert): Der akzeptierte Micro-Objective-Griff erhaelt read-only Outcome-Zeile, Mini-Zielzustand und naechsten Griff; HUD- und Multiplayer-Grenzen bleiben erhalten.
- TASK_995 - Release First Decision Loop Two Player Loop Micro Objective Acceptance Slice (implementiert): Der Micro-Objective-Loop `SICHERN / DRUECKEN / SAMMELN` wird read-only als Spielergriff akzeptiert: sichtbar, lesbar, Confirm-Feedback, `GO` separat und Multiplayer-Grenze erhalten.
- TASK_994 - Release First Decision Loop Two Player Loop Micro Objective Confirm Smoke (implementiert): Micro-Objective-Buttondruck wird als read-only Smoke bewertet; Confirm nutzt den vorhandenen Command-Pfad, Feedback wird sichtbar und `GO` bleibt getrennt.
- TASK_993 - Release First Decision Loop Two Player Loop Micro Objective Runtime Buttons (implementiert): `SICHERN`, `DRUECKEN` und `SAMMELN` bekommen read-only Runtime-Button-Specs auf `CommandSlot08` bis `CommandSlot10`; Confirm und `GO` bleiben getrennt.
- TASK_992 - Release First Decision Loop Two Player Loop Micro Objective Choice Hook (implementiert): Das fokussierte TASK_991-Micro-Objective wird read-only als Command-Draft fuer `_issue_command` plus separaten `GO`-Pfad vorbereitet.
- TASK_991 - Release First Decision Loop Two Player Loop Micro Objective HUD Wiring (implementiert): Die TASK_990-Micro-Objectives werden read-only als HUD-Chips plus Selected-Fireteam-, Mission-Control- und Command-Feedback-Zeilen exportiert; `GO` bleibt separat.
- TASK_990 - Release First Decision Loop Two Player Loop Next Micro Objective (implementiert): Ein bestandener TASK_989-Outcome-Slice erzeugt drei read-only Micro-Objective-Karten fuer `SICHERN`, `DRUECKEN` und `SAMMELN` plus Empfehlung und `GO separat`.
- TASK_989 - Release First Decision Loop Two Player Loop Outcome Playability Slice (implementiert): Der TASK_988-Outcome-Polish wird mit Trace-Evidence als read-only Playability-Slice bewertet: RESULT/OBJ/NEXT lesbar, naechster Griff verstanden, HUD-/Multiplayer-Grenze erhalten.
- TASK_988 - Release First Decision Loop Two Player Loop Outcome Visual Polish (implementiert): Das TASK_987-Finding erzeugt drei read-only Outcome-Surface-Specs fuer Ergebnis, Mini-Zielzustand und naechsten Griff plus `RESULT | OBJ | NEXT`-Polish-Zeile.
- TASK_987 - Release First Decision Loop Two Player Loop Outcome Visual Findings (implementiert): Der TASK_986-Outcome-Capture wird als read-only Sichtbefund geschnitten; Reibung routet zu Outcome Visual Polish, sauberer Befund zum Outcome-Playability-Slice.
- TASK_986 - Release First Decision Loop Two Player Loop Outcome Real Window Capture (implementiert): Das TASK_985-Outcome bekommt einen read-only Real-Window-Capture-Rahmen mit Manifest, Screenshotpfaden, manuellen Pflichtchecks und unveraenderter HUD-/Multiplayer-Grenze.
- TASK_985 - Release First Decision Loop Two Player Loop Scenario Outcome Slice (implementiert): Der akzeptierte Vier-Choice-Loop erhaelt einen read-only Outcome-Schnitt mit gewaehlter Choice, Outcome-Zeile, Mini-Zielzustand, naechstem Griff und HUD-/Multiplayer-Grenze.
- TASK_984 - Release First Decision Loop Two Player Loop Acceptance Slice (implementiert): Der gepolishte Vier-Choice-Loop wird read-only als Ablauf bewertet: vier Choices sichtbar/lesbar, Confirm-Feedback, `GO separat`, keine Auto-Ausfuehrung, HUD-/Multiplayer-Grenze.
- TASK_983 - Release First Decision Loop Two Player Loop Visual Polish (implementiert): Die vier Runtime-Choice-Buttons erhalten read-only Visual-Specs mit Mindestgroessen, Tooltips, ruhiger Akzentlogik, Confirm-Feedback und klarer `GO separat`-Grenze.
- TASK_982 - Release First Decision Loop Two Player Loop Visual Findings (implementiert): Der TASK_981-Capture wird als read-only Sichtbefund geschnitten; Reibung routet zu Visual Polish, sauberer Befund zum Player-Loop-Acceptance-Slice.
- TASK_981 - Release First Decision Loop Two Player Loop Real Window Capture (implementiert): Der bestandene Choice-Confirm-Smoke bekommt einen read-only Real-Window-Capture-/Manifest-Rahmen fuer sichtbare vier Choice-Buttons, Confirm-Feedback und getrenntes `GO`.
- TASK_980 - Release First Decision Loop Two Player Loop Choice Confirm Smoke (implementiert): Die Runtime-Choice-Buttons werden als Smoke bestaetigt; Confirm nutzt vorhandene Command-Pfade, zeigt Feedback und laesst `GO` getrennt.
- TASK_979 - Release First Decision Loop Two Player Loop Runtime Choice Buttons (implementiert): `SECURE / PUSH / FLANK / RESET` bekommen stabile Runtime-Button-Specs auf `CommandSlot08` bis `CommandSlot11`, mit getrenntem `GO` und ohne Gameplay-Mutation im Snapshot.
- TASK_978 - Release First Decision Loop Two Player Loop Choice Hook (implementiert): Die sichtbaren `SECURE / PUSH / FLANK / RESET`-Choices erzeugen read-only Command-Drafts fuer vorhandene Pfade, behalten `GO` separat und mutieren keine Gameplay-Wahrheit.
- TASK_977 - Release First Decision Loop Two Player Loop HUD Wiring (implementiert): Die TASK_976-Choices `SECURE / PUSH / FLANK / RESET` werden read-only als Selected-Fireteam-, Mission-Control- und Command-Feedback-Zeilen plus Choice-Chips exportiert.
- TASK_976 - Release First Decision Loop Two Player Loop Extension (implementiert): Der bestandene zweite Acceptance-Slice erzeugt read-only den naechsten Spielergriff `SECURE / PUSH / FLANK / RESET`.
- TASK_975 - Release First Decision Loop Two Acceptance Slice (implementiert): Akzeptierte TASK_974-Findings werden mit einem read-only Ablauf-Trace als kleiner `2ND -> GO -> Feedback`-Acceptance-Slice bewertet.
- TASK_974 - Release First Decision Loop Two Recapture Visual Findings (implementiert): Der TASK_973-Recapture wird als read-only Sichtbefund geschnitten; Reibung routet zu engem Visual Polish, sauberer Befund zum Loop-Two-Acceptance-Slice.
- TASK_973 - Release First Decision Loop Two Real Window Recapture (implementiert): Der bestandene `2ND -> GO -> Feedback`-Smoke bekommt einen read-only Recapture-/Manifest-Rahmen; echte manuelle Sichtabnahme bleibt offen und routet zu TASK_974.
- TASK_972 - Release First Decision Loop Two Playability Smoke (implementiert): Der zweite Griff wird als read-only `2ND -> GO -> Feedback`-Smoke bewertet; fehlendes GO/Feedback routet zurueck zum Polish, bestandene Evidence zum Real-Window-Recapture.
- TASK_971 - Release First Decision Loop Two Visual Polish (implementiert): `2ND` bekommt eine klare read-only Leseschicht mit Tooltip, Command-Feedback-Zeile, Mindestgroesse und sichtbarer `GO separat`-Grenze.
- TASK_970 - Release First Decision Loop Two Visual Findings (implementiert): Der TASK_969-Capture wird als read-only Sichtbefund geschnitten; Reibung routet zu engem Visual Polish, sauberer Befund zum Loop-Two-Playability-Smoke.
- TASK_969 - Release First Decision Loop Two Real Window Capture (implementiert): Der `2ND`-Runtime-Button bekommt einen read-only Real-Window-Capture-/Manifest-Rahmen; echte manuelle Sichtabnahme bleibt offen und routet zu TASK_970.
- TASK_968 - Release First Decision Loop Two Runtime Button (implementiert): Der zweite Griff ist als `2ND`-Button auf `CommandSlot07` erreichbar; er bestaetigt nur ueber vorhandene Pfade und laesst `GO` als separaten bestehenden Ausfuehrungsschritt stehen.
- TASK_967 - Release First Decision Loop Two GO Smoke (implementiert): Der zweite Intent ist als Smoke-Evidence pruefbar; bestandene Evidence braucht vorhandene Confirm-/GO-Pfade, getrennte Schritte, erfolgreiche Resultate und sichtbares Post-GO-Feedback, bleibt aber read-only.
- TASK_966 - Release First Decision Loop Two Execution Hook (implementiert): Der zweite Intent erzeugt read-only einen Command-Draft fuer vorhandene Pfade (`_issue_command`, `return_selected_fireteams_to_plan`, `execute_selected_fireteam_orders`), ohne automatisch zu bestaetigen oder GO auszufuehren.
- TASK_965 - Release First Decision Loop Two Polish (implementiert): Die sichtbare zweite Entscheidung wird read-only in klare Intents uebersetzt: `HOLD Defend`, `ADV Move`, `BACK Return`; jeder Intent bleibt `requires_go` und erzeugt noch keine Commands oder Movement.
- TASK_964 - Release First Decision Loop Two Playtest (implementiert): Die TASK_963-Zeile wird read-only gegen die sichtbaren HUD-Flaechen geprueft; Selected Fireteam, Mission Control und Command Feedback muessen `HOLD / ADV / BACK` zeigen, sonst routet der Befund zu TASK_965.
- TASK_963 - Release First Decision Next Playable Loop (implementiert): Der erste Decision-Griff fuehrt read-only in eine zweite sichtbare Auswahl aus Hold/Advance/Fallback; Live-Preview bleibt als nicht akzeptierte Preview markiert, akzeptierte TASK_962-Findings aktivieren den zweiten Loop.
- TASK_962 - Release First Decision Playtest Findings (implementiert): Der TASK_961-Playteststand wird als read-only Befund geschnitten; offene Review bleibt offen, Reibungen routen zu engem Polish, saubere Review fuehrt zum naechsten kleinen spielbaren Loop.
- TASK_961 - Release First Decision Integrated Playtest (implementiert): Der TASK_960-Slice bekommt einen read-only integrierten Playtest-/Manifest-Rahmen mit Release-Prozess, Deep-Link, Fensterinhalt, Homebase-bis-Mission, LZ/Drop, Preview, GO, Post-GO, Performance und Multiplayer-Grenze.
- TASK_960 - First Decision Release Playable Slice (implementiert): Bestandener TASK_959-Smoke wird mit einem Release-Spine-Trace von Homebase ueber Flightdeck, Dropship, LZ/Drop, Decision-Preview, GO und Post-GO-Feedback als kleiner spielbarer Ablauf bewertet.
- TASK_959 - First Decision Playability Smoke (implementiert): Akzeptierte TASK_958-Findings werden mit einem Playthrough-Trace gegen NEXT, WHY, Choice-Zeilen, Empfehlung, Preview, Risk, Line-of-Fire, GO-Grenze, Post-GO-Feedback, Hotpath-Ruhe und HUD-Read-only-Grenze bewertet.
- TASK_958 - First Decision Real Playthrough Visual Findings (implementiert): Der TASK_957-Fensterblick wird read-only als manueller Befund geschnitten; offene Sichtbefunde bleiben offen, Reibungen routen zu einem engen Polish-Followup, saubere Befunde zum First-Decision-Playability-Smoke.
- TASK_957 - First Decision Real Playthrough Capture (implementiert): Der erste Decision-Micro-Scenario-Polish bekommt einen read-only Real-Window-Capture-/Review-Rahmen mit LZ-Drop-Preview-Deep-Link, Screenshotpfaden und manuellen Pflichtchecks.
- TASK_956 - First Decision Micro Scenario Polish (implementiert): Der bestandene Decision-Overlay-Smoke wird im Controller als kurze NEXT/WHY/GO-Spielerzeile und drei lesbare Choice-Zeilen in Command Feedback exportiert.
- TASK_955 - Decision Overlay Playability Smoke (implementiert): Akzeptierte TASK_954-Findings werden mit einem Playthrough-Trace gegen Zielpreview, Pfad, Risk-Level, GO-Grenze, Command-Surfaces, Post-GO-Feedback und Hotpath-Ruhe als kleiner Playability-Smoke bewertet.
- TASK_954 - Decision Overlay Real Window Visual Findings (implementiert): TASK_953-Recapture-Snapshots und manuelle Sichtnotizen werden read-only bewertet; offene Sichtbefunde bleiben offen, Reibungen routen zum Polish-Follow-up, saubere Befunde zum Playability-Smoke.
- BUGFIX - Singleplayer Release Homebase Start Bootstrap (implementiert): EXE-Startpfad seedet Roster, ALPHA-Fireteam, Dropship, Pilot und fertiges Boarding, damit `Einzelspieler` nicht in einer blockierten Homebase-Readiness haengen bleibt.
- BUGFIX - Singleplayer Release Homebase Partial Save Actionability (implementiert): halbvolle lokale Saves werden beim Release-Start additiv repariert, damit vorhandenes Fireteam plus fehlender Pilot/Flightdeck-Payload nicht wieder in `Start blockiert` endet.
- BUGFIX - Player Roster Corrupt Save Quiet Recovery (implementiert): leere oder kaputte lokale Roster-Saves werden diagnostiziert und vom Bootstrap reparierbar gehalten, statt beim Singleplayer-Start Godot-JSON-Errors auszugeben.
- BUGFIX - Singleplayer Release EXE Actionability And Firefight Decision Guard (implementiert): stale Flightdeck-Seed-Handoffs fallen auf das sichtbare Homebase-Fireteam zurueck, und die Firefight-Decision-Line laeuft nicht mehr in Snapshot-Rekursion.
- BUGFIX - Singleplayer Release Visible Homebase Deadend Guard (implementiert): der sichtbare Einzelspieler-Start repariert einen leeren Homebase-Rohzustand erneut, bevor der Spieler in einem Flightdeck-/Payload-Dead-End haengen bleibt.
- BUGFIX - Singleplayer Release Homebase Post-Show Actionability Guard (implementiert): nach dem sichtbaren Homebase-Show laeuft ein gezielter zweiter Guard, damit spaete UI-/Save-Zustaende den Release-Start nicht wieder in leere Operator-/Flightdeck-Panels kippen.
- BUGFIX - Singleplayer Release Direct Sortie Default (implementiert): `Einzelspieler` startet als kleine Homebase-direct `grid_sweep`-Sortie statt im alten FOB-Transfer-Arbeitsmodus.
- BUGFIX - Singleplayer Release Mission Selection Guard (implementiert): der sichtbare Release-Start repariert spaete oder lokale `fob_transfer`-Auswahlzustaende zur kleinen `grid_sweep`-Direktsortie, bevor der Spieler wieder in `Start blockiert` landet.
- BUGFIX - Release Export Mission Runtime Test Dependencies (implementiert): Runtime-Export packt die aktuell noch missionskritischen `scripts/tests/*`-Abhaengigkeiten wieder ein, damit `MetaLayerFlow` im exportierten Singleplayer ueberhaupt laedt.
- BUGFIX - Release Singleplayer Normal Click Homebase Guard (implementiert): der normale sichtbare `EXE -> Einzelspieler`-Klickpfad fuehrt den Homebase-Actionability-Guard beim Show sofort erneut aus und prueft `grid_sweep`, Flightdeck, Payload, Boarding, Readiness und aktives `Start Mission`.
- TASK_825 - Release First GO Recent Movement Trace (implementiert): der integrierte erste GO-/Firefight-Smoke behaelt direkt nach einer abgeschlossenen kurzen Bewegung eine read-only Movement-Spur, damit der Spieler den ausgefuehrten Move noch lesen kann.
- TASK_818 - Station Reentry Release Candidate Playable Build Acceptance (implementiert): Release-Startcheck prueft den vertraglichen Spieleordner, Pflichtdateien, laufende EXE-Prozesse und `~RF*.TMP`-Dateien, ohne Prozesse oder Shortcuts zu veraendern.
- TASK_819 - Release Runtime Checked Launcher (implementiert): bewusster Playtest-Startgriff fuer den geprueften Release-Ordner, optional mit Stop alter Release-EXE, Temp-Datei-Cleanup und Launch.
- TASK_820 - Release Runtime Launch Acceptance Gate (implementiert): nach bewusstem Launch zaehlt der erwartete neue Release-Prozess als Start-Erfolg, waehrend unerwartete Altprozesse Review-Warnungen bleiben.
- TASK_821 - Release First Homebase CTA Emphasis (implementiert): der erste Singleplayer-Homebase-Cue ist visuell priorisiert und am `Start Mission`-Button gespiegelt.
- TASK_822 - Release Singleplayer Visible Window Findings (implementiert): der laufende Release-Build erzeugt ein read-only Screenshot-/Manifest-Paket fuer den sichtbaren Singleplayer-Pfad.
- TASK_823 - Release Singleplayer Visible Findings Polish (implementiert): der erste Main-Menu-Singleplayer-Griff ist als primaerer Release-CTA sichtbar priorisiert, waehrend sekundaere Werkzeuge ruhiger markiert bleiben.
- TASK_824 - Release Capture Tmp Import Guard (implementiert): lokale Capture-PNGs aus `tmp/` werden von Godot nicht mehr als Projektassets importiert und bleiben aus dem Runtime-Paket heraus.
- TASK_826 - Release Mission LZ Drop Next Step Cue (implementiert): nach `Start Mission` erklaert die Selected-Fireteam-Anzeige den Dropship-Zwischenzustand als `Naechster Griff: LZ ... danach Drop`, statt nur `keine Einheiten aktiv` zu melden.
- TASK_827 - Release Homebase Save Override Guard (implementiert): alte lokale Save-Fragmente mit `FOB Transfer`/`mission_drop_source = fob` werden beim sichtbaren Singleplayer-Release-Start zur `grid_sweep`-Homebase-Direct-Sortie normalisiert.
- TASK_828 - Release Ultrawide Canvas Stretch (implementiert): der Release nutzt `canvas_items` + `expand`, damit UI-Screens auf breiteren Fenstern nicht als 1920px-Insel links oben mit leerer rechter Flaeche wirken.
- TASK_829 - Release Singleplayer Deep-Link Evidence (implementiert): der Release-Launcher kann die EXE mit `--release-singleplayer` starten, damit QA den Singleplayer-Homebase-Pfad reproduzierbar ohne fragile Maus-Injektion erreicht.
- TASK_830 - Release Start Mission Deep-Link Evidence (implementiert): `--release-singleplayer-start-mission` oeffnet den Singleplayer und loest danach den bestehenden `Start Mission`-Pfad aus, damit die EXE reproduzierbar bis zur Mission/LZ-Phase gecaptured werden kann.
- TASK_831 - Release LZ Drop Preview Deep-Link Evidence (implementiert): `--release-singleplayer-lz-drop-preview` fuehrt die EXE bis LZ, Drop und Move-Preview vor `GO`, damit die erste echte Missionsentscheidung sichtbar reproduzierbar wird.
- TASK_832 - Release First GO Firefight Deep-Link Evidence (implementiert): `--release-singleplayer-first-go-firefight` fuehrt den Release-Pfad bis nach `GO`, erster Bewegung, erstem Kontakt und erster Engagement-Rueckmeldung.
- TASK_833 - Release Firefight HUD Readability Polish (implementiert): Die Firefight-`NEXT/WHY`-Decision-Line steht im Selected-Fireteam-Status oben, damit der Spieler den naechsten Griff im ersten Feuerwechsel sofort lesen kann.
- TASK_834 - Release Firefight HUD Real Window Polish (implementiert): Die priorisierte Firefight-Decision-Line nutzt im Selected-Fireteam-Status einen groesseren Real-Window-Stil mit Autowrap, Outline und Mindesthoehe.
- TASK_835 - Release Firefight Bottom Dock Density Polish (implementiert): Mission Control beginnt im ersten Firefight ebenfalls mit `NEXT/WHY`, zeigt den Kampf-Readout direkt darunter und schuetzt den Bottom-Dock-Status gegen Abschneiden.
- TASK_836 - Release Firefight Command Matrix Visual Polish (implementiert): #16 Command Matrix macht GO, Primaerbefehle und die aktive Fire-Rule im ersten Firefight sichtbar unterscheidbar, ohne Gameplay-State im HUD zu speichern.
- TASK_837 - Release First GO Firefight Real Window Review (implementiert): Der gepruefte Release kann mit `--release-singleplayer-first-go-firefight` gestartet, gecaptured und als TASK_837-Manifest fuer den echten Fensterbefund abgelegt werden.
- TASK_838 - Release Firefight Real Window Findings Polish (implementiert): #19 Event Log zeigt bei leerem echten Log eine read-only Firefight-Statuszeile aus vorhandenen Decision-/Combat-Snapshots statt `NO EVENTS`.
- TASK_839 - Release Firefight World Label Declutter (implementiert): Primary3D nutzt im ersten Release-Firefight einen visuellen `release_firefight_declutter`-Modus, der redundante Welttexte unterdrueckt und Fire-VFX/Friendly-Fire/kritische Unit-Zustaende erhaelt.
- TASK_840 - Release Firefight World Label Real Window Recapture (implementiert): Der gepruefte First-GO-Firefight-Capture erzeugt nach TASK_839 ein eigenes Manifest und eigene Screenshotpfade fuer den echten Declutter-Fensterbefund.
- TASK_841 - Release Firefight World Label Visual Findings (implementiert): Der TASK_840-PNG-/Manifest-Befund ist als read-only Findings-Snapshot bewertet; primaerer Folgepunkt sind Insertionsreste im Firefight-Weltbild.
- TASK_842 - Release Firefight Insertion Residue Declutter (implementiert): Nicht-Cargo LZ-Weltlabels und Dropship-Approach-Pfeile werden erst mit explizitem Firefight-Insertion-Residue-Schalter nach Deployment-Beginn unterdrueckt, waehrend Pre-GO-LZ-/Drop-Feedback und Cargo-Visuals erhalten bleiben.
- BUGFIX - Homebase Parallel Direct Dropship Fireteam Catalog Guard (implementiert): Homebase-Fireteam-Definitionen bleiben nach dem ersten Direct-Launch additiv erhalten, damit weitere Fireteams auf eigene Dropships gestaged und parallel zur Mission geschickt werden koennen.
- TASK_843 - Release First Firefight Contact Framing (implementiert): Der erste Release-Firefight wird als `fire_exchange` oder `contact_pressure` gerahmt; der Event-Log-Fallback nennt im No-Fire-Fall `CONTACT PRESSURE` mit naechstem Griff statt nur technischem `NO FIRE`.
- TASK_844 - Release First Exchange Tension Tuning (implementiert): Der First-GO-Firefight-Deep-Link prueft die erste Gegnerposition gegen Combat-Readouts und erzeugt reproduzierbar FireEvent-Evidenz fuer einen echten ersten Fire-Exchange.
- TASK_845 - Release First Exchange Real Window Recapture (implementiert): Der First-GO-Firefight-Capture erzeugt nach TASK_844 ein eigenes Manifest und eigene Screenshotpfade fuer den echten Fire-Exchange-Fensterbefund.
- TASK_846 - Release First Exchange Visual Findings (implementiert): TASK_845-PNG-/Manifest-Befund bewertet die echte Fensterreibung als `first_exchange_not_visible_in_window`, `hud_surfaces_stale_pressure` und `fire_trace_or_impact_not_obvious`.
- TASK_847 - Release Fire Exchange Visibility Persistence (implementiert): Fire-Exchange-Evidence bleibt in Event Log, #17 und #18 kurz sichtbar, ohne neue Combat- oder UI-Wahrheit zu erzeugen.
- TASK_848 - Release First Exchange Recapture Acceptance (implementiert): Frischer Release-Export und TASK_845-Recapture nach TASK_847 werden als Acceptance-Paket mit Screenshotpfaden und manuellen Pflichtchecks festgehalten.
- TASK_849 - Release Fire Exchange Visual Polish Findings (implementiert): Neuer TASK_848-Screenshot ist als read-only Findings-Schnitt bewertet; primaere Reibungen sind Start-/Automatik-Overlay, dominante Weltlinien, schwache FireTrace/Impact-Lesbarkeit und nicht eindeutig bestaetigter CONTACT-FIRE-HUD-Moment.
- TASK_850 - Release Fire Exchange Focused Visual Polish (implementiert): TASK_847-Visibility-Persistence setzt einen expliziten Focus-Visual-Schalter; Primary3D dimmt Weltlinien und priorisiert FireTrace/Impact/Target-Focus, ohne Combat- oder Gameplay-Wahrheit zu veraendern.
- TASK_851 - Release Fire Exchange Focused Visual Recapture (implementiert): Frischer Focus-Recapture-Slice mit eigenem Manifest, Analyzer, Pflichtchecks und Screenshotpfaden nach TASK_850, ohne Gameplay-Wahrheit zu veraendern.
- TASK_852 - Release Fire Exchange Focused Visual Findings (implementiert): TASK_851-Fensterblick ist als read-only Findings-Schnitt bewertet; primaere Reibung ist, dass der sichtbare Moment weiter als CONTACT PRESSURE / NO FIRE statt klarer CONTACT FIRE gelesen wird.
- TASK_853 - Release Fire Exchange Engagement Readability Polish (implementiert): Release-Fire-Exchange-Persistenz reicht fuer den bekannten 32s-Fensterblick; #17/#18/#19 teilen im aktiven Exchange-Fenster FIRE/CONTACT-FIRE und primaere Zeilen zeigen kein Debug-`NO FIRE`.
- TASK_854 - Release Fire Exchange Focused Recapture After Readability Polish (implementiert): Frischen echten Fenster-Capture nach TASK_853 als eigenes Manifest, Analyzer und Pflichtcheck-Paket vorbereiten, um CONTACT-FIRE-Lesbarkeit im echten Fenster zu pruefen.
- TASK_855 - Release Fire Exchange After Readability Visual Findings (implementiert): TASK_854-Fensterblick als read-only Findings-Schnitt bewertet; primaere Reibung ist, dass der sichtbare HUD-Primaertext weiter `NO FIRE NO_LOS` statt CONTACT FIRE liest.
- TASK_856 - Release Fire Exchange Contact-Fire Primary HUD Polish (implementiert): Aktive Release-Fire-Exchange-Evidence wird in #17/#18 als gemeinsame `CONTACT FIRE | ...`-Primaerzeile priorisiert, ohne Combat- oder Gameplay-Wahrheit zu veraendern.
- TASK_857 - Release Fire Exchange Contact-Fire Primary HUD Recapture (implementiert): Frischer Recapture-Slice nach TASK_856 mit eigenem Manifest, Analyzer, Pflichtchecks und Screenshotpfaden, um den CONTACT-FIRE-Primary-HUD-Polish im echten Fenster zu pruefen.
- TASK_858 - Release Fire Exchange Contact-Fire Primary HUD Visual Findings (implementiert): TASK_857-Fensterblick als read-only Findings-Schnitt bewertet; primaere Reibung ist, dass der sichtbare HUD-Primaertext weiter `NO FIRE NO_LOS` / LOS-Korrektur statt CONTACT FIRE liest.
- TASK_859 - Release Fire Exchange Real Window Primary HUD Source Binding Polish (implementiert): Der echte #17/#18-Window-HUD-Pfad wird bei aktiver Fire-Exchange-Persistence an die TASK_856-CONTACT-FIRE-Primaerquelle gebunden, ohne Combat- oder Gameplay-Wahrheit zu veraendern.
- TASK_860 - Release Fire Exchange Real Window Contact-Fire Recapture (implementiert): Nach TASK_859 neu exportieren/capturen und pruefen, ob der echte Fensterblick CONTACT FIRE nun als erste #17/#18-Lesung zeigt.
- TASK_861 - Release Fire Exchange Real Window Contact-Fire Visual Findings (implementiert): TASK_860-Fensterblick read-only bewerten und nur belegte Restreibung fuer den naechsten Polish benennen.
- TASK_862 - Release Fire Exchange Real Window Primary HUD Runtime Text Polish (implementiert): Den echten #17/#18-Runtime-Window-Text so polieren, dass CONTACT FIRE im aktiven Exchange-Fenster die erste Spielerlesung wird.
- TASK_863 - Release Fire Exchange Runtime Text Recapture (implementiert): Nach TASK_862 neu exportieren/capturen und pruefen, ob der echte Fensterblick CONTACT FIRE nun als erste #17/#18-Lesung zeigt.
- TASK_864 - Release Fire Exchange Runtime Text Visual Findings (implementiert): TASK_863-Fensterblick read-only bewerten und nur belegte Restreibung fuer den naechsten Polish benennen.
- TASK_865 - Release Fire Exchange Runtime Text Visible Status Polish (implementiert): Den sichtbaren #17/#18-Status-/Decision-Pfad so polieren, dass CONTACT FIRE im aktiven Exchange-Fenster nicht mehr von LOS-/NO-FIRE-Text ueberstimmt wird.
- TASK_866 - Release Fire Exchange Runtime Text Status Recapture (implementiert): Nach TASK_865 neu exportieren/capturen und pruefen, ob der echte Fensterblick CONTACT FIRE nun als erste #17/#18-Lesung zeigt.
- TASK_867 - Release Fire Exchange Runtime Text Status Visual Findings (implementiert): TASK_866-Fensterblick read-only bewerten und nur belegte Restreibung oder Akzeptanz fuer den naechsten Schritt benennen.
- TASK_868 - Release First Exchange LOS Setup Polish (implementiert): Den Release-First-Exchange so herstellen, dass der Deep-Link ein validiertes LOS-/Range-/Attackable-Zielpaar nutzt und der Force-Schritt nicht auf einen anderen `NO_LOS`-Gegner kippt.
- TASK_869 - Release First Exchange Real Window Recapture (implementiert): Nach TASK_868 neu exportieren/capturen und pruefen, ob der echte Fensterblick #17/#18/#19 nun als CONTACT FIRE statt `NO_LOS` / `CONTACT PRESSURE` gelesen wird.
- TASK_870 - Release First Exchange Post-LOS Visual Findings (implementiert): TASK_869-Fensterblick read-only bewerten und nur belegte Restreibung oder Akzeptanz fuer den naechsten Spielbarkeits-/Visual-Polish benennen.
- TASK_871 - Release Window Identity Capture Target Fix (implementiert): Klaeren und haerten, warum der formal gestartete `Sternenbuergerchen_rel.exe`-Prozess im Screenshot eine fremde World-at-War/TripleA-Karte zeigt oder warum Capture-Ziel und sichtbarer Inhalt auseinanderlaufen.
- TASK_872 - Release Correct Window First Exchange Visual Findings (implementiert): Den neuen `window_handle_print`-Fensterblick als korrekten Sternenbuergerchen-Inhalt sichern und den verbleibenden `NO_LOS`-/`CONTACT PRESSURE`-/CONTACT-FIRE-Befund read-only schneiden.
- TASK_873 - Release First Exchange CONTACT-FIRE Readability Fix (implementiert): Der First-GO-Firefight-Deep-Link seeded vorhandene Fire-Exchange-Evidence in die bestehende CONTACT-FIRE-Persistenz und refreshed #17/#18/#19 sofort, ohne neue Gameplay-Wahrheit zu erzeugen.
- TASK_874 - Release First Exchange CONTACT-FIRE Real Window Recapture (implementiert): Frischer Real-Window-Recapture-Slice nach TASK_873 mit eigenem Manifest, Screenshotpfaden, Window-Handle-Trust und manuellen Pflichtchecks fuer CONTACT FIRE / FireTrace / Impact.
- TASK_875 - Release First Exchange CONTACT-FIRE Visual Findings (implementiert): TASK_874-PNG read-only bewertet; primaere Reibung ist `task_873_evidence_not_real_window_first_reading`, weil #17/#18/#19 im echten Fenster weiter NO_LOS/CONTACT PRESSURE zuerst lesen.
- TASK_876 - Release First Exchange Visible Status Source Reconciliation (implementiert): TASK_873-Evidence bleibt als read-only First-Exchange-Statusquelle im echten Release-Fenster aktiv und speist #17/#18/#19 ueber den bestehenden Combat-HUD-Density-Pfad.
- TASK_877 - Release First Exchange Visible Status Recapture (implementiert): Nach TASK_876 neu exportieren/capturen und pruefen, ob der echte Window-Handle-Screenshot CONTACT FIRE, Event-Log und FireTrace/Impact nun sichtbar macht.
- TASK_878 - Release First Exchange Visible Status Visual Findings (implementiert): TASK_877-PNG read-only bewertet; primaere Reibung ist `task_876_status_source_not_real_window_first_reading`, weil der exportierte echte Fensterblick weiter NO_LOS/CONTACT PRESSURE zuerst liest.
- TASK_879 - Release First Exchange Exported Status Source Trace (implementiert): Im exportierten Runtime-Fenster tracebar machen, ob die TASK_876-Statusquelle aktiviert wird, zu spaet kommt oder von HUD-/Decision-Refresh ueberschrieben wird.
- TASK_880 - Release First Exchange Fire Visual Polish (implementiert): Nach TASK_879 ist der finale Export-Statusquellenpfad belegt; FireTrace, Impact, Target-Fokus und das kurze HIT/MISS/FIRE-Label werden im belegten First-Exchange-Fenster ueber die TASK_850-Focus-Baseline angehoben.
- TASK_881 - Release First Exchange Fire Visual Recapture (implementiert): Nach TASK_880 frisch exportieren/capturen und pruefen, ob der echte Window-Handle-Screenshot CONTACT FIRE, FireTrace, Impact und Target-Fokus jetzt sofort lesbar macht.
- TASK_882 - Release First Exchange Fire Visual Findings (implementiert): TASK_881-PNG read-only bewertet; primaere Reibung ist `task_880_fire_visual_not_real_window_first_reading`, weil der echte Fensterblick trotz trusted Capture und sauberem finalem Trace weiter NO_LOS/CONTACT PRESSURE zuerst liest.
- TASK_883 - Release First Exchange Real Window HUD Source Sync Fix (implementiert): Die sichtbaren #17/#18/#19-Quellen im echten Fenster werden mit dem finalen CONTACT-FIRE-Trace-Stand synchronisiert, ohne neue Gameplay-Wahrheit im HUD zu erzeugen.
- TASK_884 - Release First Exchange HUD Source Sync Recapture (implementiert): Nach TASK_883 erzeugt ein eigener Recapture-/Acceptance-Slice Manifest, Screenshotpfade und read-only Pflichtchecks fuer CONTACT FIRE in #17/#18/#19, FireTrace, Impact und Target-Fokus.
- TASK_885 - Release First Exchange HUD Source Sync Visual Findings (implementiert): TASK_884-PNG und Manifest read-only bewertet; primaere Reibung ist `task_883_hud_source_sync_not_real_window_first_reading`, weil der echte Fensterframe trotz sauberem Trace weiter NO_FIRE/CONTACT_PRESSURE zuerst liest.
- TASK_886 - Release First Exchange Real Window HUD Render Frame Trace (implementiert): Screenshot-Zeitpunkt, gerenderte #17/#18/#19-Texte und finalen CONTACT-FIRE-Source-Snapshot im echten Fenster zusammen tracebar machen.
- TASK_887 - Release First Exchange Real Window HUD Render Frame Sync Fix (implementiert): Der Capture-/Acceptance-Pfad wartet bis `deeplink_final` und captured danach denselben laufenden Release-Prozess erneut, sodass echter Fensterframe und finale CONTACT-FIRE-Quelle synchron belegt sind.
- TASK_888 - Release First Exchange Player Readability Polish Review (implementiert): Nach synchronem CONTACT-FIRE-Frame ist der echte Spielerblick als read-only Review geschnitten; primaere Reibung ist Bottom-HUD-/Event-Log-/FireTrace-Dichte, nicht mehr CONTACT-FIRE-Wahrheit.
- TASK_889 - Release First Exchange HUD Density And Fire Visual Polish (implementiert): Den TASK_888-Befund klein umgesetzt: #17/#18 schneller lesbar machen, Event Log komfortabler rahmen und FireTrace/Impact/Zielbezug staerker priorisieren, ohne Combat-Wahrheit im HUD zu erzeugen.
- TASK_890 - Release First Exchange HUD Density Real Window Recapture (implementiert): Nach TASK_889 frisch exportieren/capturen und pruefen, ob der echte Window-Handle-Screenshot CONTACT FIRE, Event Log, FireTrace, Impact und Target-Fokus jetzt angenehmer lesbar macht.
- TASK_891 - Release First Exchange HUD Density Visual Findings (implementiert): Den TASK_890-PNG-/Manifest-Befund read-only bewerten und nur belegte Restreibung oder Akzeptanz fuer den naechsten Spielbarkeits-/Visual-Polish benennen.
- TASK_892 - Release First Exchange Fire Direction And Impact Clarity Polish (implementiert): FireDirection, Impact und Target-Fokus im bestaetigten CONTACT-FIRE-Moment werden mit eigenem Primary3D-Style, staerkerem Trace/Impact und Ziel-End-/Direction-Anchor lesbarer gemacht, ohne Combat-Wahrheit zu veraendern.
- TASK_893 - Release First Exchange Fire Direction Impact Real Window Recapture (implementiert): Nach TASK_892 frisch exportieren/capturen und pruefen, ob der echte Window-Handle-Screenshot Schussrichtung, Impact und Zielbezug jetzt als eine Aktion lesbar macht.
- TASK_894 - Release First Exchange Fire Direction Impact Visual Findings (implementiert): TASK_893-PNG und Manifest read-only bewerten und nur belegte Restreibung oder Akzeptanz fuer den naechsten Spielbarkeits-/Visual-Polish benennen.
- TASK_895 - Release First Exchange World Combat Focal Hierarchy Polish (implementiert): Weltkampf-Fokus, Source-to-target-Hierarchie und Raster-/Weltinhalt-Konkurrenz im ersten CONTACT-FIRE-Moment polieren, ohne Combat- oder HUD-Wahrheit zu veraendern.
- TASK_896 - Release First Exchange World Combat Focal Real Window Recapture (implementiert): Nach TASK_895 frisch exportieren/capturen und pruefen, ob Source-to-target-Lane, Source-Glow, Target-Halo und gedimmtes Umfeld im echten Window-Handle-Screenshot als eine Kampfaktion lesbar sind.
- TASK_897 - Release First Exchange World Combat Focal Visual Findings (implementiert): TASK_896-PNG und Manifest read-only bewerten und nur belegte Restreibung oder Akzeptanz fuer den naechsten Spielbarkeits-/Visual-Polish benennen.
- TASK_898 - Release First Exchange Combat Focal Elegance Polish (implementiert): Sichtbare Focal-Signale aus TASK_897 weniger debughaft und eleganter als natuerliche Schussbahn darstellen, ohne Combat- oder HUD-Wahrheit zu veraendern.
- TASK_899 - Release First Exchange Combat Focal Elegance Real Window Recapture (implementiert): Nach TASK_898 frisch exportieren/capturen und pruefen, ob die weichere Lane, der kleinere Target-Halo und der dezente Source-Glow im echten Window-Handle-Screenshot natuerlicher wirken.
- TASK_900 - Release First Exchange Combat Focal Elegance Visual Findings (implementiert): TASK_899-PNG und Manifest read-only bewerten und nur belegte Restreibung oder Akzeptanz fuer den naechsten Spielbarkeits-/Visual-Polish benennen.
- TASK_901 - Release First Exchange Combat Marker Scale And World Noise Polish (implementiert): Den belegten TASK_900-Befund eng umsetzen: Target-Halo/Fire-Marker weniger scheibenhaft skalieren, Grid-/World-Noise im Feuerbereich ruhiger machen und Source-to-target-Beziehung eleganter halten, ohne Combat- oder HUD-Wahrheit zu veraendern.
- TASK_902 - Release First Exchange Combat Marker Scale Real Window Recapture (implementiert): Nach TASK_901 frisch exportieren/capturen und pruefen, ob kleinerer Target-Halo, ruhigeres Raster und reduzierte World-Lines im echten Window-Handle-Screenshot natuerlicher wirken.
- TASK_903 - Release First Exchange Combat Marker Scale Visual Findings (implementiert): TASK_902-PNG und Manifest read-only bewerten und nur belegte Restreibung oder Akzeptanz fuer den naechsten Spielbarkeits-/Visual-Polish benennen.
- TASK_904 - Release First Exchange Fire Lane Readability Polish (implementiert): Den belegten TASK_903-Befund eng umsetzen: Source-to-target-Fire-Lane klarer und weniger markerhaft lesbar machen, ohne Combat- oder HUD-Wahrheit zu veraendern.
- TASK_905 - Release First Exchange Fire Lane Real Window Recapture (implementiert): Nach TASK_904 frisch exportieren/capturen und pruefen, ob die Fire-Lane im echten Window-Handle-Screenshot als erste Weltlesung funktioniert.
- TASK_906 - Release First Exchange Fire Lane Visual Findings (implementiert): TASK_905-PNG und Manifest read-only bewerten und nur belegte Restreibung oder Akzeptanz fuer den naechsten Spielbarkeits-/Visual-Polish benennen.
- TASK_907 - Release First Exchange Fire Lane Label Cluster Polish (implementiert): Den belegten TASK_906-Befund eng umsetzen: FIRE/CONTACT-/Halo-Cluster und Fire-Lane-Hierarchie klarer machen, ohne Combat- oder HUD-Wahrheit zu veraendern.
- TASK_908 - Release First Exchange Fire Lane Label Cluster Real Window Recapture (implementiert): Nach TASK_907 frisch exportieren/capturen und pruefen, ob die Fire-Lane im echten Window-Handle-Screenshot jetzt vor dem Label-/Halo-Cluster gelesen wird.
- TASK_909 - Release First Exchange Fire Lane Label Cluster Visual Findings (implementiert): TASK_908-PNG und Manifest read-only bewerten und nur belegte Restreibung oder Akzeptanz fuer den naechsten Spielbarkeits-/Visual-Polish benennen.
- TASK_910 - Release First Exchange Fire Lane World Read Micro Polish (implementiert): Den belegten TASK_909-Befund eng umsetzen: Label-/Halo-Cluster weiter in den Hintergrund, Fire-Lane-Core/Source-/Target-Beziehung als erste Weltbewegung staerken, ohne Combat- oder HUD-Wahrheit zu veraendern.
- TASK_911 - Release First Exchange Fire Lane World Read Real Window Recapture (implementiert): Nach TASK_910 frisch exportieren/capturen und pruefen, ob die Fire-Lane im echten Window-Handle-Screenshot jetzt wirklich vor Label/Halo/Marker gelesen wird.
- TASK_912 - Release First Exchange Fire Lane World Read Visual Findings (implementiert): TASK_911-PNG und Manifest read-only bewerten und nur belegte Restreibung oder Akzeptanz fuer den naechsten Spielbarkeits-/Visual-Polish benennen.
- TASK_913 - Release First Exchange Fire Lane World Read Acceptance Polish (implementiert): Den belegten TASK_912-Befund eng umsetzen, damit Source-to-target-Fire-Lane, Anker und ruhigeres Label/Halo-Cluster im echten Fenster als erste Weltbewegung gelesen werden.
- TASK_914 - Release First Exchange Fire Lane World Read Acceptance Recapture (implementiert): Nach TASK_913 frisch exportieren/capturen und pruefen, ob die Fire-Lane im echten Window-Handle-Screenshot jetzt wirklich die erste Weltbewegung ist.
- TASK_915 - Release First Exchange Fire Lane World Read Acceptance Visual Findings (implementiert): TASK_914-PNG und Manifest read-only bewerten und nur belegte Restreibung oder Akzeptanz fuer den naechsten Spielbarkeits-/Visual-Polish benennen.
- TASK_915 Entscheidungsstand: Bei Akzeptanz waere `TASK_916 - Release First Exchange Playability Smoke` der naechste Slice gewesen; bei Restreibung wurde stattdessen `TASK_916 - Release First Exchange Fire Lane World Read Final Polish` umgesetzt.
- TASK_916 - Release First Exchange Fire Lane World Read Final Polish (implementiert): Den TASK_915-Restbefund eng umsetzen: Fire-Lane-Core und Anker final staerken, Label/Halo/Grid/Weltlinien weiter beruhigen, ohne Combat- oder HUD-Wahrheit zu oeffnen.
- TASK_917 - Release First Exchange Final World Read Recapture (implementiert): Nach TASK_916 frisch exportieren/capturen und pruefen, ob die Fire-Lane im echten Window-Handle-Screenshot jetzt als erste Weltbewegung gelesen wird.
- TASK_918 - Release First Exchange Final World Read Visual Findings (implementiert): TASK_917-PNG und Manifest read-only bewerten und entscheiden, ob danach ein First-Exchange-Playability-Smoke reicht.
- TASK_919 - Release First Exchange Playability Smoke Gate (implementiert): TASK_918-Findings read-only als `manual_review_required`, `followup_fix_required` oder `smoke_ready` auswerten und den Smoke nur bei echter Akzeptanz freigeben.
- TASK_920 - Release First Exchange Final World Read Followup Fix (implementiert): Den echten TASK_917/TASK_918-Restbefund eng umsetzen: Fire-Lane-Core und Richtunganker staerken, Label/Halo/Grid/Weltlinien weiter beruhigen, ohne Combat- oder HUD-Wahrheit zu oeffnen.
- TASK_921 - Release First Exchange Followup World Read Recapture (implementiert): Nach TASK_920 frisch exportieren/capturen und pruefen, ob die Fire-Lane im echten Window-Handle-Screenshot jetzt als erste Weltbewegung gelesen wird.
- TASK_922 - Release First Exchange Followup World Read Visual Findings (implementiert): TASK_921-PNG und Manifest read-only bewerten und entscheiden, ob danach ein First-Exchange-Playability-Smoke reicht.
- TASK_922 Entscheidungsstand: Bei Akzeptanz waere `TASK_923 - Release First Exchange Playability Smoke` der naechste Slice gewesen; bei Restreibung wurde stattdessen `TASK_923 - Release First Exchange Followup World Read Player Polish` umgesetzt.
- TASK_923 - Release First Exchange Followup World Read Player Polish (implementiert): Den TASK_922-Restbefund eng umsetzen: Fire-Lane-Core und Richtunganker staerker als erste Weltbewegung lesen lassen, Label/Halo/Grid/Weltlinien weiter beruhigen, ohne Combat- oder HUD-Wahrheit zu oeffnen.
- TASK_924 - Release First Exchange Followup Player Polish Recapture (implementiert): Nach TASK_923 frischen Window-Handle-Recapture-/Review-Rahmen bereitstellen und pruefen, ob die Source-to-target-Fire-Lane im echten Fenster jetzt vor FIRE/CONTACT-Text und Zielcluster gelesen wird.
- TASK_925 - Release First Exchange Followup Player Polish Visual Findings (implementiert): TASK_924-PNG und Manifest read-only bewerten und entscheiden, ob danach ein First-Exchange-Playability-Smoke reicht.
- TASK_925 Entscheidungsstand: Ohne akzeptierten TASK_925-Spielerblick wurde `TASK_926 - Release First Exchange Playability Smoke` nicht gestartet; stattdessen ist `TASK_926 - Release First Exchange Followup Player Polish Tuning` der engere Folge-Schnitt.
- TASK_926 - Release First Exchange Followup Player Polish Tuning (implementiert): Fire-Lane/Core staerker vor Text/Halo lesen lassen, Source-/Target-Anker klarer machen und Label/Halo/Grid/Weltlinien beruhigen, ohne Combat- oder HUD-Wahrheit zu oeffnen.
- TASK_927 - Release First Exchange Followup Player Polish Tuning Recapture (implementiert): Nach TASK_926 einen frischen Window-Handle-Recapture-/Review-Rahmen bereitstellen und pruefen, ob die Tuning-Fire-Lane im echten Fenster jetzt vor FIRE/CONTACT-Text und Zielcluster gelesen wird.
- TASK_928 - Release First Exchange Followup Player Polish Tuning Visual Findings (implementiert): TASK_927-PNG und Manifest read-only bewerten und entscheiden, ob danach ein First-Exchange-Playability-Smoke reicht.
- TASK_928 Entscheidungsstand: Ohne akzeptierten TASK_928-Spielerblick wird `TASK_929 - Release First Exchange Playability Smoke` nicht gestartet; bei Restreibung ist `TASK_929 - Release First Exchange Followup Player Polish Tuning Final Readability Polish` der engere Folge-Schnitt.
- TASK_929 - Release First Exchange Followup Player Polish Tuning Final Readability Polish (implementiert): Die letzte belegte Lesereibung eng polieren: Fire-Lane/Core minimal klarer, Label/Halo/Grid/Weltlinien leiser, Source-/Target-Anker tragender, ohne Combat- oder HUD-Wahrheit zu oeffnen.
- TASK_930 - Release First Exchange Final Readability Recapture (implementiert): Nach TASK_929 frisch capturen und pruefen, ob danach der Playability-Smoke freigegeben werden kann.
- TASK_931 - Release First Exchange Final Readability Visual Findings (implementiert): TASK_930-PNG und Manifest read-only bewerten und entscheiden, ob danach ein First-Exchange-Playability-Smoke reicht.
- TASK_931 Entscheidungsstand: Bei Akzeptanz waere `TASK_932 - Release First Exchange Playability Smoke` der naechste Slice gewesen; ohne akzeptierten TASK_931-Spielerblick wurde stattdessen `TASK_932 - Release First Exchange Final Readability Followup Fix` umgesetzt.
- TASK_932 - Release First Exchange Final Readability Followup Fix (implementiert): Ohne akzeptierten TASK_931-Spielerblick wird kein Smoke gestartet; der enge Folgefix staerkt Fire-Lane/Core minimal und beruhigt Label/Halo/Grid/Weltlinien weiter, ohne Combat- oder HUD-Wahrheit zu oeffnen.
- TASK_933 - Release First Exchange Followup Fix Recapture (implementiert): Nach TASK_932 frisch capturen und pruefen, ob danach der Playability-Smoke freigegeben werden kann.
- TASK_934 - Release First Exchange Followup Fix Visual Findings (implementiert): TASK_933-PNG und Manifest read-only bewerten und entscheiden, ob danach ein First-Exchange-Playability-Smoke reicht.
- TASK_934 Entscheidungsstand: Bei Akzeptanz waere `TASK_935 - Release First Exchange Playability Smoke` der naechste Slice; bei Restreibung ist `TASK_935 - Release First Exchange Followup Fix Player Polish` der engere Folge-Schnitt.
- TASK_935 - Release First Exchange Followup Fix Player Polish (implementiert): Den TASK_934-Restbefund eng umsetzen: Fire-Lane/Core minimal klarer, Label/Halo/Grid/Weltlinien leiser und Richtunganker tragender, ohne Combat- oder HUD-Wahrheit zu oeffnen.
- TASK_936 - Release First Exchange Followup Fix Player Polish Recapture (implementiert): Nach TASK_935 frischen Window-Handle-Recapture-/Review-Rahmen bereitstellen und pruefen, ob die Player-Polish-Fire-Lane im echten Fenster jetzt vor FIRE/CONTACT-Text und Zielcluster gelesen wird.
- TASK_937 - Release First Exchange Followup Fix Player Polish Visual Findings (implementiert): TASK_936-PNG und Manifest read-only bewerten und entscheiden, ob danach ein First-Exchange-Playability-Smoke reicht.
- TASK_937 Entscheidungsstand: Bei Akzeptanz waere `TASK_938 - Release First Exchange Playability Smoke` der naechste Slice; bei Restreibung ist `TASK_938 - Release First Exchange Followup Fix Player Polish Final Tuning` der engere Folge-Schnitt.
- TASK_938 - Release First Exchange Followup Fix Player Polish Final Tuning (implementiert): Nur belegte TASK_937-Spielerblick-Reibung eng polieren: Fire-Lane/Core staerker, Label/Halo/Grid/Weltlinien leiser und Richtunganker tragender, ohne Combat- oder HUD-Wahrheit zu oeffnen.
- TASK_939 - Release First Exchange Followup Fix Player Polish Final Tuning Recapture (implementiert): Nach TASK_938 frischen Window-Handle-Recapture-/Review-Rahmen bereitstellen und pruefen, ob die Final-Tuning-Fire-Lane im echten Fenster jetzt vor FIRE/CONTACT-Text und Zielcluster gelesen wird.
- TASK_940 - Release First Exchange Followup Fix Player Polish Final Tuning Visual Findings (implementiert): TASK_939-PNG und Manifest read-only bewerten und entscheiden, ob danach ein First-Exchange-Playability-Smoke reicht.
- TASK_940 Entscheidungsstand: Bei Akzeptanz waere `TASK_941 - Release First Exchange Playability Smoke` der direkte naechste Slice gewesen; bei Restreibung waere `TASK_941 - Release First Exchange Followup Fix Player Polish Final Tuning Followup Fix` der engere Folge-Schnitt gewesen. Ohne direkten Smoke-Run wird zuerst `TASK_941 - Release First Exchange Final Tuning Playability Smoke Gate` als sauberer Gate-Schnitt umgesetzt.
- TASK_941 - Release First Exchange Final Tuning Playability Smoke Gate (implementiert): TASK_940-Findings read-only als `smoke_ready`, `manual_review_required`, `followup_fix_required` oder `blocked` auswerten und den Smoke nur bei echter TASK_940-Akzeptanz freigeben.
- TASK_941 Entscheidungsstand: Bei `smoke_ready` ist `TASK_942 - Release First Exchange Playability Smoke Run` der naechste Slice; bei Restreibung ist `TASK_942 - Release First Exchange Followup Fix Player Polish Final Tuning Followup Fix` der enge Folge-Schnitt; bei offenem Sichtbefund ist `TASK_942 - Release First Exchange Manual Window Review` der sichere Folge-Schnitt.
- TASK_942 - Release First Exchange Followup Fix Player Polish Final Tuning Followup Fix (implementiert): Den TASK_941-Restpfad eng umsetzen: Fire-Lane/Core sicherer als erste Weltbewegung vor FIRE/CONTACT-Text, Zielcluster, Label/Halo/Grid und Weltlinien lesen lassen, ohne Combat- oder HUD-Wahrheit zu oeffnen.
- TASK_942 Entscheidungsstand: TASK_943 - Release First Exchange Followup Fix Player Polish Final Tuning Followup Recapture ist der naechste Slice, weil TASK_942 nur Presentation-Fix ist und einen echten Fensterbeweis braucht.
- TASK_943 - Release First Exchange Followup Fix Player Polish Final Tuning Followup Recapture (implementiert): Nach TASK_942 frischen Window-Handle-Recapture-/Review-Rahmen bereitstellen und pruefen, ob die TASK_942-Fire-Lane im echten Fenster jetzt vor FIRE/CONTACT-Text und Zielcluster gelesen wird.
- TASK_943 Entscheidungsstand: TASK_944 - Release First Exchange Followup Fix Player Polish Final Tuning Followup Visual Findings ist der naechste Slice; erst dessen Akzeptanz darf den Playability-Smoke wieder freigeben.
- TASK_944 - Release First Exchange Followup Fix Player Polish Final Tuning Followup Visual Findings (implementiert): TASK_943-PNG und Manifest read-only bewerten und entscheiden, ob danach ein First-Exchange-Playability-Smoke reicht.
- TASK_944 Entscheidungsstand: Bei Akzeptanz ist `TASK_945 - Release First Exchange Playability Smoke` der naechste Slice; bei Restreibung ist `TASK_945 - Release First Exchange Followup Fix Player Polish Final Tuning Followup Second Fix` der engere Folge-Schnitt.
- TASK_945 - Release First Exchange Followup Fix Player Polish Final Tuning Followup Second Fix (implementiert): Den TASK_944-Restbefund eng umsetzen: Fire-Lane/Core als erste Weltbewegung weiter staerken, Zielhalo/Label/Grid/Weltlinien leiser ziehen und die TASK_942-Basis nicht als Gameplay-Wahrheit oeffnen.
- TASK_945 Entscheidungsstand: TASK_946 - Release First Exchange Followup Fix Player Polish Final Tuning Followup Second Recapture ist der naechste Slice, weil TASK_945 wieder nur Presentation-Fix ist und einen frischen echten Fensterbeweis braucht.
- TASK_946 - Release First Exchange Followup Fix Player Polish Final Tuning Followup Second Recapture (implementiert): Nach TASK_945 frischen Window-Handle-Recapture-/Review-Rahmen bereitstellen und pruefen, ob die TASK_945-Fire-Lane im echten Fenster jetzt vor FIRE/CONTACT-Text und Zielcluster gelesen wird.
- TASK_946 Entscheidungsstand: TASK_947 - Release First Exchange Followup Fix Player Polish Final Tuning Followup Second Visual Findings ist der naechste Slice; erst dessen Akzeptanz darf den Playability-Smoke wieder freigeben.
- TASK_947 - Release First Exchange Followup Fix Player Polish Final Tuning Followup Second Visual Findings (implementiert): TASK_946-PNG und Manifest read-only bewerten und entscheiden, ob danach der First-Exchange-Playability-Smoke sinnvoll ist.
- TASK_947 Entscheidungsstand: Bei Akzeptanz ist `TASK_948 - Release First Exchange Playability Smoke` der naechste Slice; bei Restreibung wird die reine First-Exchange-Polish-Schleife gestoppt und `TASK_948 - Tactical Decision Clarity Scenario Return` priorisiert.
- TASK_948 - Tactical Decision Clarity Scenario Return (implementiert): Den TASK_947-Restreibungs-Pfad bewusst aus der First-Exchange-Mikropolish-Schleife heraus auf den vorhandenen Order-Preview-/Threat-/Line-of-Fire-Stack zurueckfuehren.
- TASK_948 Entscheidungsstand: Naechster konkreter Slice ist `TASK_949 - Order Preview Threat Overlay Playtest Scenario`, damit Ghost, Pfad, Risiko und Line-of-Fire wieder in einer kleinen spielbaren Entscheidung vor `GO` zusammenkommen.
- TASK_949 - Order Preview Threat Overlay Playtest Scenario (implementiert): Drei konkrete Move-Choices (`covered_push`, `exposed_crossing`, `kill_zone_dash`) mit Ghost, Pfad, Risiko und Threat-Line-Zaehlern aus den vorhandenen Preview-/Threat-Resolvern bereitstellen.
- TASK_949 Entscheidungsstand: Naechster Slice ist `TASK_950 - Wire Decision Scenario Into F6 Mission HUD`, damit die drei Preview-Choices im Missionsfenster sichtbar und spielbar lesbar werden.
- TASK_950 - Wire Decision Scenario Into F6 Mission HUD (implementiert): TASK_949-Choices als read-only Mission-Control-Zeile und Command-Feedback-Snapshot im F6-HUD verdrahten.
- TASK_950 Entscheidungsstand: Naechster Slice ist `TASK_951 - Decision Overlay Real F6 Visual Review`, um die echte Fensterlesbarkeit von Position, Kontrast und Textlaenge zu pruefen.
- TASK_951 - Decision Overlay Real F6 Visual Review (implementiert): TASK_950-Choice-Line von rohen IDs auf spielernahe Labels umstellen und einen automatisierten Review-Snapshot fuer den echten F6-Sichtcheck bereitstellen.
- TASK_951 Entscheidungsstand: Naechster Slice ist `TASK_952 - Decision Overlay F6 Visual Polish`, falls der echte F6-Sichtcheck Kontrast, Position oder Rhythmus der Preview-Zeile noch als Reibung meldet.
- TASK_952 - Decision Overlay F6 Visual Polish (implementiert): Die Decision-Preview als drei kompakte safe/risky/suicidal-Badges mit stabilen Farbrollen und niedrigem HUD-Laerm fuer den Real-Window-Recapture vorbereiten.
- TASK_952 Entscheidungsstand: Naechster Slice ist `TASK_953 - Decision Overlay Real Window Recapture`, um die Badge-/Line-Politur im echten Fenster zu belegen.
- TASK_953 - Decision Overlay Real Window Recapture (implementiert): Einen read-only Recapture-/Review-Rahmen mit TASK_952-Source, Screenshot-Pfaden, Pflichtchecks und offener manueller Abnahme bereitstellen.
- TASK_953 Entscheidungsstand: Naechster Slice ist `TASK_954 - Decision Overlay Real Window Visual Findings`, um den echten Fensterbefund zu schneiden.
- BUGFIX - Release Singleplayer EXE Stale FOB Transfer Actionability Guard (implementiert): Der sichtbare `EXE -> Einzelspieler`-Normalstart gilt erst als actionable, wenn `grid_sweep` und `homebase_direct` wiederhergestellt sind.
- BUGFIX - Release Homebase Direct Start Copy Clarity (implementiert): Der sichtbare `EXE -> Einzelspieler`-Normalstart zeigt Homebase-Direct als `Mission payload`/`Direct sortie` mit aktivem `Start Mission`, statt alte FOB-Transfer- und Slot-Ueberlauf-Texte zu mischen.

## Aktueller Station-Route-Abnahmeblock
- TASK_721 - Station Route Two-Window Visual Findings (implementiert)
- TASK_722 - Station Route HUD Visual Polish (implementiert)
- TASK_723 - Station Route Host/Client Recapture Review (implementiert)
- TASK_724 - Station Route Recapture Visual Followup (implementiert)
- TASK_725 - Station Route Host/Client Recapture Acceptance Review (implementiert)
- TASK_726 - One-Screen Multiplayer Station Scenario Drill (implementiert)
- TASK_727 - Station Scenario F6/Host Client Playtest Notes (implementiert)
- TASK_728 - Station Scenario Playtest Findings (implementiert)
- TASK_729 - Station Scenario Visible Playtest Run Packet (implementiert)
- TASK_730 - Station Scenario Targeted Playtest Polish (implementiert)
- TASK_731 - Station Scenario Workbench Export Review (implementiert)
- TASK_732 - Station Scenario Route Cue Polish (implementiert)
- TASK_733 - Station Scenario HUD Overlap Pass (implementiert)
- TASK_734 - Station Scenario Performance Feel Pass (implementiert)
- TASK_735 - Station Scenario Current Report Sync Guard (implementiert)
- TASK_736 - Station Scenario Command Feedback Polish (implementiert)
- TASK_737 - Station Scenario Visible Cue Run Packet Refresh (implementiert)
- TASK_738 - Station Scenario Identity Cue Visibility Polish (implementiert)
- TASK_739 - Station Scenario Identity Cue Recapture Findings (implementiert)
- TASK_740 - Scenario Harness Modernization (geparkt; nur bei belegten Harness-Problemen)
- TASK_741 - Station Scenario Workbench Recapture Prefill (implementiert)
- TASK_742 - Station Scenario Cargo Endgame Cue Polish (implementiert)
- TASK_743 - Station Scenario Debrief Handoff Cue (implementiert)
- TASK_744 - Station Scenario Meta Debrief Route Smoke (implementiert)
- TASK_745 - Station Scenario Post Debrief Homebase Readability (implementiert)
- TASK_746 - Station Scenario Homebase Next Sortie Readiness (implementiert)
- TASK_747 - Station Scenario Homebase Visible Readiness Review (implementiert)
- TASK_748 - Station Scenario Homebase Readiness Visual Polish Findings (implementiert)
- TASK_749 - Station Homebase Follow-up Microcopy Polish (implementiert)
- TASK_750 - Station Homebase Host/Client Recapture Packet (implementiert)
- TASK_751 - Station Homebase Capture Metadata Hook (implementiert)
- TASK_752 - Station Homebase Recapture Workbench Prefill (implementiert)
- TASK_753 - Station Homebase Recapture Review Gate (implementiert)
- TASK_754 - Station Homebase Recapture Findings (implementiert)
- TASK_755 - Station Homebase Return Panel Polish (implementiert)
- TASK_756 - Station Homebase Real Window Recapture (implementiert)
- TASK_757 - Station Homebase Recapture Findings Refresh (implementiert)
- TASK_758 - Station Homebase Return Acceptance Review (implementiert)
- TASK_759 - Station Slice Next Playtest Target (implementiert)
- TASK_760 - Station Reentry Playtest Run Packet (implementiert)
- TASK_761 - Station Reentry Visible Playtest Findings (implementiert)
- TASK_762 - Station Reentry Targeted Polish (implementiert)
- TASK_763 - Station Reentry Fireteam Staging Polish (implementiert)
- TASK_764 - Station Reentry Loadout Bridge Polish (implementiert)
- TASK_765 - Station Reentry Dropship Boarding Bridge Polish (implementiert)
- TASK_766 - Station Reentry Start Permission Bridge Polish (implementiert)
- TASK_767 - Station Reentry Visible Playtest Review Gate (implementiert)
- TASK_768 - Station Reentry First Mission Preview Polish (implementiert)
- TASK_769 - Station Reentry Performance Feel Pass (implementiert)
- TASK_770 - Station Reentry Host Client Next Order Sync (implementiert)
- TASK_771 - Station Reentry Visible Host Client Playtest Export (implementiert)
- TASK_772 - Station Reentry Host Client Export Findings (implementiert)
- TASK_773 - Station Reentry Host Client Identity Cue Polish (implementiert)
- TASK_774 - Station Reentry Next Playable Slice Acceptance (implementiert)
- TASK_775 - Station Reentry Mission Interaction Feel Pass (implementiert)
- TASK_776 - Station Reentry Contact Pressure Feel Pass (implementiert)
- TASK_777 - Station Reentry Firefight Tension Feel Pass (implementiert)
- TASK_778 - Station Reentry Firefight Visual Playtest Packet (implementiert)
- TASK_779 - Station Reentry Firefight Visual Findings (implementiert)
- TASK_780 - Station Reentry Firefight Interaction Polish (implementiert)
- TASK_781 - Station Reentry Firefight Command Surface Recapture (implementiert)
- TASK_782 - Station Reentry Firefight Command Surface Findings (implementiert)
- TASK_783 - Station Reentry Firefight Command Surface Polish (implementiert)
- TASK_784 - Station Reentry Firefight Command Surface Playtest Packet Refresh (implementiert)
- TASK_785 - Station Reentry Firefight Command Surface Visible Findings Refresh (implementiert)
- TASK_786 - Station Reentry Firefight Host Client Polished Surface Check (implementiert)
- TASK_787 - Station Reentry Firefight Player Decision Readability Pass (implementiert)
- TASK_788 - Station Reentry Firefight Decision Evidence Packet (implementiert)
- TASK_789 - Station Reentry Firefight Decision Evidence Findings (implementiert)
- TASK_790 - Station Reentry Firefight Decision Polish Acceptance (implementiert)
- TASK_791 - Station Reentry Firefight Decision Host Client Recapture (implementiert)
- TASK_792 - Station Reentry Firefight Decision Host Client Findings (implementiert)
- TASK_793 - Station Reentry Firefight Multiplayer Decision Acceptance (implementiert)
- TASK_794 - Station Reentry Firefight Multiplayer Decision Playtest Packet (implementiert)
- TASK_795 - Station Reentry Firefight Multiplayer Decision Playtest Findings (implementiert)
- TASK_796 - Station Reentry Firefight Multiplayer Decision Playtest Acceptance (implementiert)
- TASK_797 - Station Reentry Firefight Multiplayer Playable Slice Candidate (implementiert)
- TASK_798 - Station Reentry Firefight Multiplayer Playable Candidate Real Run Findings (implementiert)
- TASK_799 - Station Reentry Firefight Multiplayer Playable Candidate Acceptance (implementiert)
- TASK_800 - Station Reentry Firefight Multiplayer Release Candidate Packet (implementiert)
- TASK_801 - Station Reentry Firefight Release Candidate Playtest Findings (implementiert)
- TASK_802 - Station Reentry Firefight Release Candidate Acceptance (implementiert)
- TASK_803 - Station Reentry Firefight Release Candidate Ship Readiness (implementiert)
- TASK_804 - Station Reentry Firefight Release Candidate Visible Ship Smoke (implementiert)
- TASK_805 - Station Reentry Firefight Release Candidate Delivery Review (implementiert)
- TASK_806 - Station Reentry Firefight Release Candidate Handoff Packet (implementiert)
- TASK_807 - Station Reentry Firefight Release Candidate Tester Run (implementiert)
- TASK_808 - Station Reentry Firefight Release Candidate Tester Run Acceptance (implementiert)
- TASK_809 - Station Reentry Release Candidate Playability Polish Backlog (implementiert)
- TASK_810 - Station Reentry Release Candidate First Mission CTA Visual Smoke (implementiert)
- TASK_811 - Station Reentry Release Candidate Mission Launch Actionability Smoke (implementiert)
- TASK_812 - Station Reentry Release Candidate LZ Drop Preview Actionability Smoke (implementiert)
- TASK_813 - Station Reentry Release Candidate First GO Firefight Actionability Smoke (implementiert)
- TASK_814 - Station Reentry Release Candidate Firefight Feel And HUD Polish Review (implementiert)
- TASK_815 - Station Reentry Release Candidate Real Window Firefight Sight Review (implementiert)
- TASK_816 - Station Reentry Release Candidate Visible Firefight Findings (implementiert)
- TASK_817 - Station Reentry Release Candidate Targeted Firefight Polish (implementiert)
- Naechster Schritt: TASK_818 - Station Reentry Release Candidate Playable Build Acceptance oder gezielter HUD-Style-Polish nach Fensterbefund.

## Aktueller Fireteam-Arbeitsblock
- TASK_414 - Fireteam Overview HTML
- TASK_415 - Fireteam Runtime Execution Path Switch
- TASK_416 - Fireteam Command Drill Map
- TASK_417 - Fireteam Waypoint Completion Cleanup
- TASK_418 - Fireteam Mini Card Suppression Explainer
- TASK_419 - GO Recovery Action And NPC Speed
- TASK_420 - Waypoint Completion Area Followup Hotfix
- TASK_421 - Move Stance Posture Speed Sight
- TASK_422 - GO Continue Fireteam HUD Cleanup
- TASK_423 - Normal Move Parallel Spacing
- TASK_424 - Fireteam Drill Enemy Visibility Grounding
- TASK_425 - Live Move Stance Update
- TASK_426 - Cautious Move Parallel Aim
- TASK_427 - Fireteam Decision Feedback Aim Pose
- TASK_428 - Fireteam Behavior Control List
- TASK_429 - Fireteam Behavior Modes Runtime
- TASK_430 - Fireteam Task Corruption Repair
- TASK_431 - Fireteam Aim Pose And Card UI Hotfix
- TASK_432 - Fireteam Muzzle Flash And Baseline Attack Movement
- TASK_433 - Install Third Party Godot Plugins
- TASK_434 - LimboAI Enemy Behavior Adapter Smoke
- TASK_435 - Fireteam Manual Visual Regression Pass
- TASK_436 - Fireteam Sight Security Visuals
- TASK_437 - Fireteam Selection Patrol Contact Pass
- TASK_438 - Fireteam Contact Visibility Attack Visuals
- TASK_439 - Fireteam Runtime Map Flow Limbo Review
- TASK_440 - Enemy Limbo Contact Diagnostics
- TASK_441 - Fireteam Map Tool Drill Rebuild
- TASK_442 - Fireteam Engage Behavior Control
- TASK_443 - Fireteam Take Behavior Control
- TASK_444 - Fireteam Behavior Playtest Workbench HTML
- TASK_445 - HTML Report Workbench Standard
- TASK_446 - Fireteam Workbench Spacing Runtime Pass
- TASK_447 - Fireteam Contact Initiative Rules
- TASK_448 - Fireteam Workbench Profile Clarity
- TASK_449 - Fireteam Distance CNA Workbench Rules
- TASK_450 - Fireteam Stance Command Preset Workbench
- TASK_451 - Fireteam Workbench Runtime Import
- TASK_452 - Fireteam Runtime Baseline Visual Contact Pass
- TASK_453 - Fireteam Terrain LOS Sequence Direction Audit
- TASK_454 - Terrain Truth Visual Audit
- TASK_455 - Terrain Truth Editor Overlay Visibility
- TASK_456 - Wall Segment LOS And Tile Truth Inspector
- TASK_457 - Fireteam Contact Engage Runtime Pass
- TASK_458 - Fireteam Contact Decision Diagnostics
- TASK_459 - Fireteam Engage Orientation Enemy Proxy Fix
- TASK_460 - Fireteam Movement Avoidance Stability
- TASK_461 - Fireteam Engage Visual Stuck Hotfix
- TASK_462 - Fireteam Auto Defend Completion Release
- TASK_463 - Fireteam Auto Defend Guard And Enemy Model Visibility
- TASK_464 - Fireteam Contact Scan Fire Feedback Readability
- TASK_465 - Fireteam Engage Resume Contact Progress
- TASK_466 - Fireteam Live Defend Contact Fire Damage
- TASK_467 - Fireteam Engage Contact Halt Fire
- TASK_468 - Fireteam Engage Live Command Conflict Audit
- TASK_469 - Fireteam F6 Drill Combat Config
- TASK_470 - Fireteam CombatLoop Unit Bridge Recovery
- TASK_471 - Fireteam Weapon Fire VFX Hit Feedback Perf
- TASK_472 - Fireteam Contact Performance Bubble Card Readability
- TASK_473 - Fireteam Combat Feedback Runtime Overhaul
- TASK_474 - Fireteam Down VFX Performance Stabilization
- TASK_475 - Fireteam Pathfinding Avoidance Stability Pass
- TASK_476 - Fireteam Corridor Lane Cover Navigation
- TASK_477 - Fireteam Contact Cover Decision V1
- TASK_478 - Fireteam Soft Completion Final Stage Guard
- TASK_479 - Fireteam Runtime Hotpath Guards
- TASK_480 - Mission UI Hotpath Feedback Guard
- TASK_481 - Loadout Heavy Weapon Selection
- TASK_482 - Mission Briefing Data Contract
- TASK_483 - Map Editor Asset Workflow Polish
- TASK_484 - Map Editor Palette Browser Layout
- TASK_485 - Map Editor Save As and Modular Scale Fix
- TASK_486 - Map Builder Tooling Spike
- TASK_487 - Install Godot Asset Placer
- TASK_488 - Map Builder Workbench MeshLibrary MVP
- TASK_489 - Map Builder Workbench Editor Entry
- TASK_490 - Map Builder Paint Tools MVP
- TASK_491 - Map Editor Runtime Builder Workbench
- TASK_492 - Map Editor Network Drag Snap Tools
- TASK_493 - Map Editor Station Builder Focus
- TASK_494 - Station Outpost 64x64 Map
- TASK_495 - Mission Combat Driver Boundary Review
- TASK_496 - Mission Combat Registry and Elimination Hotfix
- TASK_497 - Mission TestSetup Reference Cleanup
- TASK_498 - Runtime Script Layout Alignment
- TASK_499 - Review Followup Architecture Cleanup
- TASK_500 - Gameflow Spine Hardening
- TASK_501 - Integrated Movement Command Lifecycle Hardening
- TASK_503 - Mission Dropship Fireteam HUD Truth
- TASK_504 - Startmap Expansion Performance Pass
- TASK_505 - Frontier Probe Large Map Playtest Hotfix
- TASK_506 - Tactical Decision Clarity Contract (implementiert)
- TASK_507 - Order Preview Ghosts MVP (implementiert)
- TASK_508 - Line-of-Fire / Threat Analyzer MVP (implementiert)
- TASK_509 - Combined Preview Overlay (implementiert)
- TASK_510 - Contact Report Upgrade (implementiert)
- TASK_511 - Export Runtime Package Hygiene (implementiert)
- TASK_512 - Mission Controller Boundary Slice (implementiert)
- TASK_513 - Mission Combat Resolution Boundary (implementiert)
- TASK_514 - Enemy Behavior Orchestrator (implementiert)
- TASK_515 - Combat Readability Presenter (implementiert)
- TASK_516 - Editor Builder UX Pass (implementiert)
- TASK_517 - Mission Scenario Vertical Slice (implementiert)
- TASK_518 - Mission Scenario Runtime Gates (implementiert)
- TASK_519 - Cargo Touchdown Visual/Runtime Bridge (implementiert)
- TASK_520 - Multiplayer Team Ownership Smoke (implementiert)
- TASK_521 - Builder Drag Preview Visual Polish (implementiert)
- TASK_522 - Cargo Touchdown Visual Polish (implementiert)
- TASK_523 - PvP Team Readability UI Pass (implementiert)
- TASK_524 - Export Warning Noise Cleanup (implementiert)
- TASK_525 - Team Badge / Spawn Readability Polish (implementiert)
- TASK_526 - Mission HUD Team Chip Polish (implementiert)
- TASK_527 - Briefing Minimap Team Spawn Overlay (implementiert)
- TASK_528 - Rolling HTML Status Report (implementiert)
- TASK_529 - Mission HUD Team Icon Polish (implementiert)
- TASK_530 - Briefing Panel Renderer MVP (implementiert)
- TASK_531 - Briefing Minimap Visual Renderer (implementiert)
- TASK_532 - Briefing Background / Loadout Recommendation Polish (implementiert)
- TASK_533 - Recommended Loadout Selection Bridge (implementiert)
- TASK_534 - Pre-Mission Readiness Checklist (implementiert)
- TASK_535 - Pre-Mission FullHD Startflow Visual Pass (implementiert)
- TASK_536 - Startflow Icon And Status Color Polish (implementiert)
- TASK_537 - Pre-Mission F6 Screenshot Visual Audit (implementiert)
- TASK_538 - Homebase To Mission Launch Handoff Smoke (implementiert)
- TASK_539 - Mission Insertion First Order Readability Pass (implementiert)
- TASK_540 - Mission First Move Decision Readability Pass (implementiert)
- TASK_541 - Mission First Move Execution Feedback Pass (implementiert)
- TASK_542 - Mission First Contact Readability Pass (implementiert)
- TASK_543 - Mission First Engagement Feedback Pass (implementiert)
- TASK_544 - Mission Fire And Cover Visual Polish Pass (implementiert)
- TASK_545 - Mission Fire Cover Integrated Flow Smoke (implementiert)
- TASK_546 - Mission Combat Feedback HUD Density Polish (implementiert)
- TASK_547 - Multi-Fireteam Combat HUD Consistency Smoke (implementiert)
- TASK_548 - Combat HUD Visual Detail Tooltip Pass (implementiert)
- TASK_549 - Combat HUD F6 Visual Audit (implementiert)
- TASK_550 - Combat HUD Manual Screenshot Notes Pass (implementiert)
- TASK_551 - Combat HUD Tooltip Style Polish (implementiert)
- TASK_552 - Mission Objective Interaction Readability Pass (implementiert)
- TASK_553 - Mission Cargo Extract Readability Pass (implementiert)
- TASK_554 - Frontier Probe Integrated Objective Playthrough Smoke (implementiert)
- TASK_555 - Frontier Probe Multiplayer Objective Ownership Smoke (implementiert)
- TASK_556 - Frontier Probe Host Client Objective Handoff Smoke (implementiert)
- TASK_557 - Frontier Probe Multiplayer F6 Readability Pass (implementiert)
- TASK_558 - Frontier Probe Multiplayer Manual Screenshot Notes Pass (implementiert)
- TASK_559 - Factory Colormap UID Loader Guard (implementiert)
- TASK_560 - Frontier Probe Multiplayer Teamchip Tooltip Polish (implementiert)
- TASK_561 - Frontier Probe Multiplayer Manual Visual Review Guide (implementiert)
- TASK_562 - Frontier Probe Multiplayer F6 Visual Evidence Capture (implementiert)
- TASK_563 - Frontier Probe Multiplayer F6 Evidence Report Preview (implementiert)
- TASK_564 - Frontier Probe Multiplayer Apply Visual Polish Findings (implementiert)
- TASK_565 - Frontier Probe Multiplayer Real F6 Screenshot Review Pass (implementiert)
- TASK_566 - Frontier Probe Multiplayer F6 Hover And Panel Polish Pass (implementiert)
- TASK_567 - Frontier Probe First Move Threat Preview Readability Pass (implementiert)
- TASK_568 - Frontier Probe Risky Contact Preview Fixture (implementiert)
- TASK_569 - Frontier Probe Threat Preview Visual Review (implementiert)
- TASK_570 - Hold Fire Discipline Mission Bridge (implementiert)
- TASK_571 - Fire Rule Controls Readability Polish (implementiert)
- TASK_572 - Fire Rule F6 Readability Smoke (implementiert)
- TASK_573 - Fire Rule Manual Screenshot Notes Pass (implementiert)
- TASK_574 - Fire Rule Real F6 Screenshot Review Pass (implementiert)
- TASK_575 - Fire Rule Evidence Polish Findings (implementiert)
- TASK_576 - Suppress Fire Preview Readability Spike (implementiert)
- TASK_577 - Suppress Fire Visual Evidence Pass (implementiert)
- TASK_578 - Suppress Fire Visual Polish Findings (implementiert)
- TASK_579 - Suppress Fire Manual F6 Review (implementiert)
- TASK_580 - Suppress Fire Visual Tuning Findings (implementiert)
- TASK_581 - Suppress Fire Intent Outcome Smoke (implementiert)
- TASK_582 - Suppress Fire Outcome AAR Diagnostic Stub (implementiert)
- TASK_583 - Suppress Fire AAR Report Panel Readability (implementiert)
- TASK_584 - Mini AAR Combat Metrics Shell (implementiert)
- TASK_585 - Mini AAR Debrief Screen Stub (implementiert)
- TASK_586 - Debrief Return To Homebase Handoff (implementiert)
- TASK_587 - Debrief Visual Polish Pass (implementiert)
- TASK_588 - Debrief AAR Data Bridge (implementiert)
- TASK_589 - Debrief AAR F6 Visual Evidence Pass (implementiert)
- TASK_590 - Debrief AAR Layout Polish Findings (implementiert)
- TASK_591 - Debrief AAR Player Review Notes Pass (implementiert)
- TASK_592 - Debrief Skill Progress Preview Shell (implementiert)
- TASK_593 - Skill Progress Award Contract (implementiert)
- TASK_594 - Post Mission Skill Delta Homebase Bridge (implementiert)
- TASK_595 - Homebase Progression Visual Polish (implementiert)
- TASK_596 - Homebase Progression Player Review Notes (implementiert)
- TASK_597 - Homebase Progression F6 Evidence Capture (implementiert)
- TASK_598 - Homebase Progression Evidence Polish Findings (implementiert)
- TASK_599 - Integrated Core Loop Playtest Evidence Pass (implementiert)
- TASK_600 - Integrated Core Loop Flow Polish Findings (implementiert)
- TASK_601 - Core Loop Manual FullHD Playtest Capture (implementiert)
- TASK_602 - Core Loop Transition Pacing Polish (implementiert)
- TASK_603 - Mission HUD Density Interaction Polish (implementiert)
- TASK_604 - Core Loop Host Client Feel Smoke (implementiert)
- TASK_605 - Host Client F6 Visual Review Pass (implementiert)
- TASK_606 - Host Client F6 Visual Polish Findings (implementiert)
- TASK_607 - Two Instance Host Client Runtime Smoke (implementiert)
- TASK_608 - Host Client Runtime Visual Capture (implementiert)
- TASK_609 - Host Client Runtime Visual Polish Findings (implementiert)
- TASK_610 - Host Client Two Window Playtest Notes (implementiert)
- TASK_611 - Host Client Two Window Launch Helper (implementiert)
- TASK_612 - Host Client Two Window Screenshot Review (implementiert)
- TASK_613 - Host Client Two Window Visual Polish Findings (implementiert)
- TASK_614 - Host Client Two Window Real Run Review (implementiert)
- TASK_615 - Host Client Real Run Findings (implementiert)
- TASK_616 - Host Client Visible UI Real Run Review (implementiert)
- TASK_617 - Host Client Standard Window Layout Hardening (implementiert)
- TASK_618 - Host Client Standard Capture Crop Review (implementiert)
- TASK_619 - Host Client Role Peer Badge HUD (implementiert)
- TASK_620 - Host Client Badge Re-Capture Review (implementiert)
- TASK_621 - Host Client Multiplayer Feel Review Bundle (implementiert)
- TASK_622 - Host Client Command Authority Live Interaction Review (implementiert)
- TASK_623 - Host Client Authority Visual Findings (implementiert)
- TASK_624 - Host Client Live Input Feedback Review (implementiert)
- TASK_625 - Host Client Visible Reject Feedback Polish (implementiert)
- TASK_626 - Host Client Real Click Review Evidence (implementiert)
- TASK_627 - Host Client Fireteam Eventlog Overlap Polish (implementiert)
- TASK_628 - Mission HUD Legacy Contract Refresh (implementiert)
- TASK_629 - Host Client Real Click Playtest Evidence Pass (implementiert)
- TASK_630 - Frontier Probe Mini Scenario Feel Route (implementiert)
- TASK_631 - Frontier Probe Mini Scenario Visual Feel Polish (implementiert)
- TASK_632 - Frontier Probe Mini Scenario F6 Visual Review (implementiert)
- TASK_633 - Frontier Probe Callout Layout Polish (implementiert)
- TASK_634 - Frontier Probe Real F6 Callout Sight Review (implementiert)
- TASK_635 - Frontier Probe Callout Sight Findings (implementiert)
- TASK_636 - Frontier Probe Real F6 Re-Capture (implementiert)
- TASK_637 - Frontier Probe Playfeel Next Interaction (implementiert)
- TASK_638 - Frontier Probe Debrief Handoff Feel (implementiert)
- TASK_639 - Frontier Probe Meta Debrief Route Smoke (implementiert)
- TASK_640 - Frontier Probe Post Debrief Homebase Readability (implementiert)
- TASK_641 - Frontier Probe Homebase Next Sortie Readiness (implementiert)
- TASK_642 - Frontier Probe Homebase Visible Readiness Review (implementiert)
- TASK_643 - Frontier Probe Homebase Readiness Visual Polish Findings (implementiert)
- TASK_644 - Frontier Probe Homebase Real Window Review (implementiert)
- TASK_645 - Frontier Probe Homebase Summary Next Sortie Polish (implementiert)
- TASK_646 - Homebase MissionPanel Density Playfeel Review (implementiert)
- TASK_647 - Homebase MissionPanel Density Findings (implementiert)
- TASK_648 - Homebase Next Sortie Action Cue (implementiert)
- TASK_649 - Current State Handbook Report (implementiert)
- TASK_650 - Host Client Click Feedback Followup (implementiert)
- TASK_651 - Host Client Click Followup Evidence (implementiert)
- TASK_652 - Current State Handbook Refresh (implementiert)
- TASK_653 - Frontier Probe One-Screen Playability Pass (implementiert)
- TASK_654 - Frontier Probe One-Screen F6 Playtest Notes (implementiert)
- TASK_655 - Frontier Probe One-Screen Visual Tuning Findings (implementiert)
- TASK_656 - Frontier Probe Real F6 Visual Review (implementiert)
- TASK_657 - Frontier Probe F6 Visual Polish Findings (implementiert)
- TASK_658 - Frontier Probe One-Screen Player Decision Drill (implementiert)
- TASK_659 - Frontier Probe Decision Drill F6 Evidence (implementiert)
- TASK_660 - Decision Drill Snapshot Performance Budget (implementiert)
- TASK_661 - Host Client Decision Drill Click Evidence (implementiert)
- TASK_662 - Host Client Decision Drill Real Window Capture (implementiert)
- TASK_663 - Host Client Decision Drill Visual Findings (implementiert)
- TASK_664 - Host Client Decision Drill Real Click Recheck (implementiert)
- TASK_665 - Host Client Decision Drill Technical Click Guard (implementiert)
- TASK_666 - Host Client Decision Drill Real Click Findings (implementiert)
- TASK_667 - Map Editor Persistent Palette Presets (implementiert)
- TASK_668 - Map Editor Asset Scale Override Presets (implementiert)
- TASK_669 - Map Editor Placement Rotation Overrides (implementiert)
- TASK_670 - Builder Drag Preview Handles (implementiert)
- TASK_671 - Builder Chain Auto Snapping (implementiert)
- TASK_672 - FullHD Drag Preview Art Direction (implementiert)
- TASK_673 - Mission Interaction Point Contract (implementiert)
- TASK_674 - Mission Interaction Point Bindings (implementiert)
- TASK_675 - Mission Interaction Runtime Use State (implementiert)
- TASK_676 - Mission Interaction Use Feedback (implementiert)
- TASK_677 - Mission Interaction Use Intent (implementiert)
- TASK_678 - Mission Interaction Runtime Progress (implementiert)
- TASK_679 - Mission Interaction Progress Readability (implementiert)
- TASK_680 - Mission Interaction Binding Inspector (implementiert)
- TASK_681 - Mission Interaction Binding Editor (implementiert)
- TASK_682 - Mission Interaction Binding Presets (implementiert)
- TASK_683 - Map Editor Interaction FullHD Sight Pass (implementiert)
- TASK_684 - Map Editor Interaction Focus Scroll (implementiert)
- TASK_685 - Mission Interaction Objective Gate (implementiert)
- TASK_686 - Mission Interaction Visual State (implementiert)
- TASK_687 - Mission Interaction Object Reaction (implementiert)
- TASK_688 - Mission Interaction FullHD Evidence (implementiert)
- TASK_689 - Mission Interaction Visual Polish Findings (implementiert)
- TASK_690 - Mission Interaction Manual Sight Notes (implementiert)
- TASK_691 - Mission Interaction Runtime Visual Assets (implementiert)
- TASK_692 - Door Runtime Collision/LOS Contract (implementiert)
- TASK_693 - Door Runtime State Producer (implementiert)
- TASK_694 - Door Use/Breach Command Hook (implementiert)
- TASK_695 - Door Interaction HUD Button/Shortcut (implementiert)
- TASK_696 - Door Runtime Visual Animation/Asset Swap (implementiert)
- TASK_697 - Door Interaction Multiplayer Authority Check (implementiert)
- TASK_698 - Door Authority UI Feedback (implementiert)
- TASK_699 - Multiplayer Door Feedback Capture (implementiert)
- TASK_700 - Host/Client Door Real Click Workbench (implementiert)
- TASK_701 - Door Authority Feedback Polish (implementiert)
- TASK_702 - Door Authority Compact HUD Surface (implementiert)
- TASK_703 - Door Authority Button Affordance (implementiert)
- TASK_704 - Host/Client Door Real Click Findings (implementiert)
- TASK_705 - Host/Client Door Real Click Manual Run Packet (implementiert)
- TASK_706 - Mission Door Layout/Visual Polish (implementiert)
- TASK_707 - Mission Door/Computer/Cargo Smoke (implementiert)
- TASK_708 - Station Route Visual Evidence (implementiert)
- TASK_709 - Station Route Window Playtest Notes (implementiert)
- TASK_710 - Station Route Polish Readiness Findings (implementiert)
- TASK_711 - Station Route Evidence Board Visual Polish (implementiert)
- TASK_712 - Station Route Host/Client Acceptance Packet (implementiert)
- TASK_713 - Station Route Host/Client Findings (implementiert)
- TASK_714 - Station Route Multiplayer Scenario Guard (implementiert)
- TASK_715 - Station Route Empty Event Log Polish (implementiert)
- TASK_716 - Station Route Run Readout Polish (implementiert)
- TASK_717 - Station Route Real Host/Client Click Findings (implementiert)
- TASK_718 - Station Route Door/GO/Reject Visual Polish (implementiert)
- TASK_719 - Station Route Post-Polish Recheck Guard (implementiert)
- TASK_720 - Station Route Capture Recheck + Handbuch (implementiert)
- TASK_721 - Station Route Two-Window Visual Findings (implementiert)
- TASK_722 - Station Route HUD Visual Polish (implementiert)
- TASK_723 - Station Route Host/Client Recapture Review (implementiert)
- TASK_724 - Station Route Recapture Visual Followup (implementiert)
- TASK_725 - Station Route Host/Client Recapture Acceptance Review (implementiert)
- TASK_726 - One-Screen Multiplayer Station Scenario Drill (implementiert)

Phase 0 – Fundament (abgeschlossen)
TASK_006 Workflow Setup
TASK_001 RuntimeLeader
TASK_002 EventRouter
TASK_003 SimulationRoot
TASK_004 Registries
TASK_005 UpdateManager
Phase 1 – Integration (abgeschlossen)
TASK_007 RuntimeLeader Integration Test
TASK_008 Unit Stub + Registry Test
TASK_009 Minimaler Command-Flow
TASK_010 Tick-Verarbeitung in SimulationRoot
TASK_011 Unit-Target Command
TASK_012 Team-/FTL-Command
Phase 2 – Datenmodelle (abgeschlossen)
TASK_013 CommanderCommand
TASK_014 FTLTask
TASK_015 Command -> FTLTask Translator
Phase 3 – FTL-Datenfluss vervollstaendigen
TASK_016 – FTLTask im RuntimeLeader annehmen

Ziel:

RuntimeLeader kann FTLTask empfangen
minimaler Nachweis
keine Ausfuehrung
TASK_017 – FTLTask-Queue im RuntimeLeader

Ziel:

RuntimeLeader verwaltet Tasks
aktueller Task + Queue
keine KI
TASK_018 – FTL-State-Modell minimal

Ziel:

States definieren:
idle
moving
holding
engaging
retreating
keine echte Wirkung
TASK_019 – FTLTask -> RuntimeStatus

Ziel:

Task fuehrt zu einfachem Statuswechsel
keine Bewegung
Phase 4 – Unit-Ebene anbinden
TASK_020 – UnitCommand-Stub

Ziel:

einfache Unit-Kommandos als Daten
TASK_021 – TestUnit Runtime-Status

Ziel:

Unit hat Zustandsmodell:
idle
assigned
pending_move
holding
TASK_022 – FTLTask -> Unit-Zuweisung

Ziel:

FTL referenziert Units korrekt
keine Aktion
TASK_023 – mehrere Units pro FTL

Ziel:

2–3 Units pro Team
nur Datenfluss
Phase 5 – erste sichtbare Reaktion
TASK_024 – Missions-Testszene

Ziel:

einfache Szene mit:
FTL
Units
Ziel
TASK_025 – Move-Target als Daten

Ziel:

Zielposition speichern
keine Navigation
TASK_026 – minimaler Move im SimulationRoot

Ziel:

einfache Positionsaenderung erlaubt
kein Pathfinding
TASK_027 – erster sichtbarer Flow

Ziel:
Commander -> FTL -> SimulationRoot -> Unit

Phase 6 – taktische Grundsysteme
TASK_028 – Line of Sight minimal
TASK_029 – Fog of War minimal
TASK_030 – Treffer-/Damage-Modell minimal
TASK_031 – Down-/Bleedout-Zustaende
TASK_032 – Friendly Fire
Phase 7 – Meta-Layer
TASK_033 – Heimatbasis
TASK_034 – FOB
TASK_035 – Teamtransfer
TASK_036 – Respawn-Logik
TASK_037 – Rover/Frachter minimal
Phase 8 – Vertical Slice
TASK_038 – Fireteam-Aufteilung
TASK_039 – Phasen-Wirkung
TASK_040 – Take-Befehl und Objective
TASK_041 – Siegbedingung
TASK_042 – Respawn-Timer-Anzeige
Phase 9 – Gegner-Verhalten
TASK_043 – Einfache Gegner-Positionierung
TASK_044 – Gegner-Reaktion auf Kontakt
TASK_045 – Gegner-Wellen
Phase 10 – Unit-Identitaet
TASK_046 – Unit-Skill-Werte
TASK_047 – Skill-Wirkung im Combat
TASK_048 – Persoenlichkeitsmerkmale
TASK_049 – Heimatbasis: Unit-Uebersicht mit Skills
Phase 11 – Multiplayer-Prototyp V1
TASK_050 – Server-autoritativer SimulationRoot
TASK_051 – Host/Join mit Testteams
TASK_052 – Befehlsuebertragung ueber Netzwerk
TASK_053 – Synchronisierte Spielzustandsanzeige
Phase 12 – Terrain-System und Gameplay-Wirkung
TASK_054 – Terrain-Tile-Datenmodell und Registry
TASK_055 – Walkability und einfaches A*-Pathfinding
TASK_056 – LOS ueber Terrain-Tiles
TASK_057 – Cover aus Terrain-Tiles
TASK_058 – Hoehenstufen
TASK_059 – Strassen und Oberflaechen
Phase 13 – Map Editor
TASK_060 – Terrain-Daten als JSON-Datei
TASK_061 – Map-Editor-Szene: Tile-Auswahl und Anzeige
TASK_062 – Map-Editor: Tile-Properties bearbeiten
TASK_063 – Map-Editor: Speichern und Laden
TASK_064 – MissionTestSetup: Terrain aus JSON laden
Phase 14 – Map-Editor-Workflow und Politur
TASK_065 – Tile-Typ-Katalog und Palette
TASK_066 – Corridor-Wall Typen, Typ-Texturen und Auto-Cliff
TASK_067 – Fix Map-Editor 64x64 Flat Ground
TASK_068 – Zoom-Inversion und Auto-Wall-Overlays
TASK_068b – Drag-Painting und Hover-Preview
TASK_068c – Gitternetz-Overlay und Himmelsrichtungen
TASK_069 – Map-Editor: Auswahl, Save As und Workflow-Polish
Phase 15 – Meta-Layer-Roster-Lesbarkeit
TASK_070 – NPC-Karten-Komponente
TASK_071 – Heimatbasis: NPC-Karten und Auswahlfokus
TASK_072 – FOB: Teamkarten und Einsatzstatus
TASK_073 – Homebase: Charakterbogen und Drag-and-Drop-Teamstaging
TASK_074 – Homebase: Layout-Neuordnung und Missionsinfoleiste
TASK_075 – Homebase: Kartenverdichtung, Tooltip-Polish und Charakterbogen-Fokus
TASK_076 – Meta-Layer: Graue Kenney-UI-Rahmen
TASK_077 – FOB: Fireteam-Auswahl und Startvorbereitung
TASK_078 – Meta-Layer: Navigation und Map-Ansicht
TASK_079 – FOB: Fireteam-Management, Respawn-/Loadout-Staging und Dropship-Wartezone
TASK_080 – Meta-Layer: Transfer-Sichtbarkeit, Pool-DnD und Charakterbogen-Toggle
TASK_081 – Meta-Layer: UI-Harmonisierung fuer FOB, Homebase und Loadout

Phase 16 – Charakterbogen-Kampfwirkung
TASK_082 – Gemeinsamer Terrain-Renderer fuer Editor und Mission
TASK_085 – Charakterbogen Combat-Integration (get_combat_effects)
TASK_086 – Waffenmodell (WeaponData)
TASK_087 – Loadout-Pipeline und Waffen-Sprites

Phase 17A – Waffen und Loadout (abhaengig von 086/087)
(bereits in Phase 16 enthalten)

Phase 17B – Teamdynamik
TASK_088 – Leadership-Bonus auf Fireteam-Mitglieder

Phase 17C – Gegner
TASK_089 – Enemy Cover-Seeking
TASK_090 – Differenzierte Enemy-Typen

Phase 17D – Wahrnehmung
TASK_091 – Awareness: Detection-Delay
TASK_092 – Stealth: Reduzierte Sichtreichweite

Phase 17E – Verhaltensqualitaet
TASK_093 – Discipline: Hold-Fire-Disziplinbrueche
TASK_094 – Recognition: Friendly-Fire-Verwechslung

Phase 17F – Support-Rollen
TASK_095 – Combat Medic Support

Phase 17G – Meta-Layer Recovery
TASK_096 – Meta-Layer Recovery: Missionskarte, Dropship-LZ und Character-Sheet-Umbau

Phase 17H – Taktisches Kampfsystem
TASK_097 – Datenmodelle, engage und Ad-hoc-Vertraege (implementiert)
TASK_098 – TacticalInputController und Fireteam-Auswahl (implementiert)
TASK_099 – Wegpunktplanung, Kontextmenue und Order-Visualisierung (implementiert)
TASK_100 – PhaseController und globale Plan-Ausfuehrung
TASK_101 – FireteamBehaviorResolver, geplantes Flankieren und Standardverhalten
TASK_102 – AdHocOrderController und Gefechts-Sofortbefehle
TASK_103 – Suppression, Interruption und Return-to-Plan
TASK_104 – Inter-Fireteam-Koordination und Leader-initiiertes Flankieren
TASK_105 – Leader-Nachfolge, Lead-Rueckgabe und UI-Synchronisierung
TASK_106 – Dropship-LZ, Insertion und verzoegerte Aktivierung
TASK_107 – LoadoutModifierResolver und initiale Missions-Effects

Phase 17I – Gegner-Patrouillen und Editor
TASK_108 – PatrolEditorTool und Pre-Contact-Patrol

Phase 17J – Taktische Erweiterungen
TASK_109 – TacticalStanceController und TacticalStancePanel
TASK_110 – FireteamMovementController und Bewegungsmuster
TASK_111 – FireteamSecurityController und Overwatch
TASK_112 – ContactTracker und ContactMapOverlay
TASK_113 – FlankVulnerabilityResolver und Sektorstrafen

Phase 17K – Marker-Follow-up
TASK_115 – Gemeinsames Markersystem fuer Editor und Taktikkarte

Phase 17L – Architektur- und Spielgefuehl-Nacharbeit
TASK_116 – Runtime-Systeme aus scripts/tests herausloesen
TASK_117 – Dropship-Deploy als SimulationRoot-Effects
TASK_118 – Combat-Entscheidungen aus MissionCombatLoopDriver herausloesen
TASK_119 – Seeded Combat RNG und roll_override begrenzen
TASK_120 – Teamqualitaet als FTL-Ausfuehrungsfaktor

Phase 17M – Area Orders und Bewegungsrobustheit
TASK_121 – Area Order Marker
TASK_122 – Defend Area Semantik
TASK_123 – Attack Area Semantik
TASK_124 – Area Feedback in #17 Selected Fireteam
TASK_125 – Terrain Blocker Debug und Walkability Tests

Phase 17N – HPA Navigation und Performance
TASK_126 – HPA Navigation Foundation
TASK_127 – HPA Pathfinder Integration
TASK_128 – Navigation Budgeting und Debug
TASK_129 – Deckungsbewusste Pfade mit HPA und Subgoal-Vorbereitung
TASK_130 – Lokale Unit-Avoidance mit ORCA/RVO-Light

Phase 18 – Erweiterung (spaeter)
Skillsystem
soziale Dynamik
persistente Teams
Multiplayer
Map Editor
Fahrzeuge
komplexe Taktik
Phase 18A - Navigation-, Cover- und Rendering-Labs
TASK_131 - Navigation Benchmark Harness
TASK_151 - Engpass-Reservierung und MAPF-Light (implementiert)
TASK_152 - Seeded Cover Placement Lab (implementiert)
TASK_153 - 3D Transparency Material Presets (implementiert)

Phase 18B - Editor-Asset-Ausbau
TASK_132 - Kenney Isometric Asset Palette Expansion

Phase 18C - Tactical Mission Authoring
TASK_155 - Tactical Mission Test Presets (implementiert)
TASK_156 - Mission Scenario Data Contract (implementiert)
TASK_157 - Tactical Mission Editor MVP (implementiert)
TASK_158 - Editor-to-Live Mission Validation (implementiert)
TASK_159 - 2.5D Editor and Mission Primary View (implementiert)
TASK_160 - Tactical Mission Playability Smoke (implementiert)

Phase 18D - Strategic Review, UI-Assets und Multiplayer-Vorbereitung
TASK_161 - Mission Runtime Boundary Cleanup (implementiert)
TASK_162 - Combat Loop Authority Split (implementiert)
TASK_163 - Map Editor Module Split (implementiert)
TASK_164 - UI Theme and Component Library (implementiert)
TASK_165 - Local Asset Curation and Import Plan (implementiert)
TASK_166 - Multiplayer Authority Command Contract (implementiert)
TASK_167 - Multiplayer Session and Lobby Extraction (implementiert)
TASK_168 - Multiplayer Snapshot Replication Contract (implementiert)
TASK_169 - Multiplayer Two-Client Playability Smoke (implementiert)
TASK_170 - Performance and Warning Budget Gate (implementiert)

Phase 18E - NPC Visual Replacement
TASK_171 - NPC Model Replacement Animated Characters (implementiert)
TASK_172 - NPC Animation Scale Helmets and Enemy Visuals (implementiert)
TASK_173 - NPC Animation Skeleton Socket Contract (implementiert)
TASK_174 - Character Helmet and Blaster Attachment Visuals (implementiert)

Phase 18F - NPC Loadout Visuals
TASK_175 - NPC Loadout Attachments (implementiert)
TASK_176 - FOB Loadout Weapon Preview Selector (implementiert)

Phase 18G - Drop Light Fixed UI Layout
TASK_177 - Drop Light Fixed UI Layout Contract (implementiert)
TASK_178 - FOB Drop Light Fixed FullHD Layout (implementiert)
TASK_179 - Homebase Drop Light Fixed FullHD Layout (implementiert)
TASK_180 - Mission Drop Light Fixed HUD Layout (implementiert)
TASK_181 - Drop Light Fixed Window Audit Patch (implementiert)

Phase 18H - Terrain Height and Hill Rules
TASK_182 - Terrain Hill Rules Contract (implementiert)
TASK_183 - Editor Hill Authoring Patch (implementiert)
TASK_184 - Gameplay Hill Semantics Patch (implementiert)
TASK_185 - Hill Visuals and Edge Lines Patch (implementiert)

Phase 18I - Mission Map NPC Behavior and Command Feedback
TASK_186 - Mission Map Unit Presence and Registry Audit (implementiert)
TASK_187 - NPC Minimum Spacing and Multiplayer Authority (implementiert)
TASK_188 - Fireteam Advance Styles Map Readability (implementiert)
TASK_189 - Medic Adjacent Tile Healing Rule (implementiert)
TASK_190 - Weapon Visual Loadout Expansion and Scale (implementiert)
TASK_191 - Command Chain Selection and Area Feedback Pass (implementiert)
TASK_192 - Mission Map NPC Behavior Playability Smoke (implementiert)

Phase 18J - Asset Intake and Availability Expansion
TASK_193 - Asset Source Inventory and Availability Matrix (implementiert)
TASK_194 - Space Modular and Station Setpiece Import (implementiert)
TASK_195 - UI Input and Cursor Asset Availability Pass (implementiert)
TASK_196 - Rank and Particle Asset Subset Import (implementiert)
TASK_197 - Curated Asset Catalog and Usage Mapping (implementiert)
TASK_198 - Asset Import Gate and Visual Smoke (implementiert)

Phase 18K - Main Menu and App Entry
TASK_199 - Main Menu Shell and Background Image (implementiert)

Phase 18L - Enemy Team Tactics Weapon Ranges and NPC Identity
TASK_200 - Enemy Team Tactics Contract and Editor Config (implementiert)
TASK_201 - Weapon Range Scale and Tile Distance Patch (implementiert)
TASK_202 - Enemy Security Direction and LOS Patch (implementiert)
TASK_203 - Enemy Cover Advance and Team Tactics Patch (implementiert)
TASK_204 - Enemy Tactics Multiplayer Authority Snapshot Patch (implementiert)
TASK_205 - Weapon Fire VFX Muzzle Flash Particles (implementiert)
TASK_206 - Enemy Visual Faction Archetypes Orange Suit (implementiert)
TASK_207 - NPC Rank Skill Badge Derivation (implementiert)
TASK_208 - Enemy Team Tactics Playability Smoke (implementiert)

Phase 18M - Comic Bubble Feedback and NPC Thoughts
TASK_209 - Comic Bubble Asset Catalog and Visual Contract (implementiert)
TASK_210 - Fireteamleader Command Feedback Bubbles (implementiert)
TASK_211 - Comic Bubble Toggles Cooldowns and Settings (implementiert)
TASK_212 - NPC Thought Bubble Hold to Peek Overlay (implementiert)
TASK_213 - Skill Based Bubble Text Resolver and Content Pass (implementiert)
TASK_214 - Comic Bubble Feedback Playability Smoke (implementiert)

Phase 18N - Deep Performance Profiling and Optimization Pass
TASK_215 - Performance Deep Pass Baseline and Research (implementiert)
TASK_216 - 2.5D Rendering Node and Draw Budget Pass (implementiert)
TASK_217 - Navigation Pathfinding LOS Performance Pass (implementiert)
TASK_218 - Simulation Combat AI Tick Budget Pass (implementiert)
TASK_219 - UI HUD Meta Comic Bubble Performance Pass (implementiert)
TASK_220 - Asset Import VRAM Shader Pipeline Stutter Pass (implementiert)
TASK_221 - Multiplayer Snapshot Serialization Performance Pass (implementiert)
TASK_222 - Performance Regression Gate and Manual Profile Checklist (implementiert)

Phase 18O - App Shell Settings Fog of War Multiplayer Maps and Editor Usability
TASK_223 - Fog of War Modes Contract and Settings (implementiert)
TASK_224 - Fog of War Tile Visibility Height Cover Runtime (implementiert)
TASK_225 - Fog of War 2.5D Visual Overlay and Contacts (implementiert)
TASK_226 - Main Menu Settings Shell Display Audio Input Gameplay (implementiert)
TASK_227 - Main Menu Multiplayer Host Join Lobby Flow (implementiert)
TASK_228 - Multiplayer Editor Map Manifest Download Consent (implementiert)
TASK_229 - Map Editor Usability Authoring Pass (implementiert)
TASK_230 - Flight Altitude Layer and Air Visibility Audit (implementiert)
TASK_231 - App Shell Game Setup Integration and Open Items Review (implementiert)

Phase 18P - Character Gameplay Roster Progression and Team Identity
TASK_232 - Start Roster Generation Contract (implementiert)
TASK_233 - Portrait Identity Catalog and Roster Presentation (implementiert)
TASK_234 - Persistent Player Roster Save and Reset (implementiert)
TASK_235 - Character Sheet Roster Gameplay Expansion (implementiert)
TASK_236 - Fireteam Relationship Affinity and Cohesion (implementiert)
TASK_237 - Mission Progression XP Morale Frustration (implementiert)
TASK_238 - Personnel Events Recruit Leave Dismiss Notifications (implementiert)
TASK_239 - Character Gameplay Bubble Mission Integration (implementiert)
TASK_240 - Multiplayer Player Roster Ownership Contract (implementiert)
TASK_241 - Character Gameplay Playability Smoke (implementiert)

Phase 18Q - Audio SFX Backgrounds Asset Locality and Alignment
TASK_242 - Audio SFX Source Inventory and Curated Import (implementiert)
TASK_243 - Audio Event Contract and Bus Setup (implementiert)
TASK_244 - Combat Movement UI SFX Integration (implementiert)
TASK_245 - Background Image Catalog and Screen Usage (implementiert)
TASK_246 - Visual Scale Alignment Asset Pass (implementiert)
TASK_247 - Used Asset Project Locality Audit Gate (implementiert)
TASK_248 - Audio Visual Import and Playback Smoke (implementiert)
TASK_249 - Post Audio Visual Performance Optimization Pass (implementiert)
TASK_250 - Asset Audio Background Playability Smoke (implementiert)

Phase 18R - Nature Kit Terrain Cliffs Ground and Vegetation
TASK_251 - Nature Kit Classic Source Inventory and Subset Import (implementiert)
TASK_252 - Nature Cliff Hill Edge Visual Mapping (implementiert)
TASK_253 - Nature Ground Surface Editor Palette Pass (implementiert)
TASK_254 - Nature Trees Rocks Vegetation Cover Props (implementiert)
TASK_255 - Nature Kit Hill Playability Visual Performance Smoke (implementiert)

Phase 18S - Automated Playability QA and UI Flow Coverage
TASK_256 - Automated Playability Coverage Contract (implementiert)
TASK_257 - Button Reachability and Interaction Verifier (implementiert)
TASK_258 - Fixed Window Clipping Scrollbar Playability Audit (implementiert)
TASK_259 - Character Card Roster Switching Playability (implementiert)
TASK_260 - Loadout Selection Decorative Weapons Weight Playability (implementiert)
TASK_261 - Cross Screen State Loss Playability Smoke (implementiert)
TASK_262 - Playability Regression Gate and Manual Open Items (implementiert)

Phase 18T - Contextual Help Popups and Explainability
TASK_263 - Contextual Help Popup UX Contract (implementiert)
TASK_264 - Contextual Help Popup Component Settings Toggle (implementiert)
TASK_265 - Character Sheet Loadout Help Content Pass (implementiert)
TASK_266 - Command Mission Editor Settings Help Content Pass (implementiert)
TASK_267 - Contextual Help Coverage Layout Verifier (implementiert)
TASK_268 - Post Help Popup Playability Regression Smoke (implementiert)

Phase 18U - Tactical Command Doctrine Fireteam Delegation and Air Asset Risk
TASK_269 - Tactical Doctrine Source Review Game Abstraction (implementiert)
TASK_270 - Commander to Fireteam Leader Delegation Contract (implementiert)
TASK_271 - Tactical Command Modes ROE Fire Rules (implementiert)
TASK_272 - Multi Fireteam Coordinated Area Plan (implementiert)
TASK_273 - Fireteam Leader Skill Tactical Progression (implementiert)
TASK_274 - Tactical Communication Feedback Layer (implementiert)
TASK_275 - Command Button Hierarchy Arrangement Overhaul (implementiert)
TASK_276 - Tactical Breakout and Exception Behavior (implementiert)
TASK_277 - Dropship Freighter Anti Armor Threat Contract (implementiert)
TASK_278 - Air Asset Loss Recovery Meta Loop (implementiert)
TASK_279 - LZ Security Air Asset Tactical Playability Smoke (implementiert)
TASK_280 - Tactical Profile Editor Scenario Authoring (implementiert)
TASK_281 - Tactical Command Multiplayer Authority Snapshot (implementiert)
TASK_282 - Tactical Overhaul Playability Performance Help Gate (implementiert)

Phase 18V - Post Tactical Docs Architecture and Sneaky Code Review
TASK_283 - Post Tactical Docs Consistency Audit (implementiert)
TASK_284 - Gameplay Truth Architecture Boundary Audit (implementiert)
TASK_285 - Tactical Decision Branch Integrity Review (implementiert)
TASK_286 - UI Feedback Truth Regression Review (implementiert)
TASK_287 - Editor Save Multiplayer Contract Regression Review (implementiert)
TASK_288 - Regression Gate Coverage Gap Audit (implementiert)
TASK_289 - Final Sneaky Code Review Patch Queue (implementiert)
TASK_290 - User Handbuch Weekly Closeout (implementiert)

Phase 18W - Editor Terrain Visual Recovery and Authoring UX
TASK_291 - Editor Terrain Visual Recovery Coordinator (implementiert)
TASK_292 - Editor Hill Cliff Grid Depth Repair (implementiert)
TASK_293 - Editor Lighting Shadow Readability Pass (implementiert)
TASK_294 - Nature Prop Scale Cover Visibility Repair (implementiert)
TASK_295 - Map Editor Paint Toolbar Tools Polish (implementiert)
TASK_296 - Map Editor Palette Taxonomy Space Station Assets (implementiert)
TASK_297 - Map Editor Inspector Collapsible Panels (implementiert)
TASK_298 - Editor Terrain Visual Playability Smoke (implementiert)

Phase 18X - Meta Userology Main Menu FOB Transfer UX
TASK_299 - Team Identity Name Generation Userology (implementiert)
TASK_300 - App Shell Return To Main Menu Navigation (implementiert)
TASK_301 - NPC Card Drag Z-Order Badges Tooltips (implementiert)
TASK_302 - Dropship Flight Deck Boarding Rename Userology (implementiert)
TASK_303 - FOB Transfer Dragdrop Card Readability (implementiert)
TASK_304 - Unified Transit Progress Ghosting Homebase FOB (implementiert)
TASK_305 - Fireteam Staging Copy Cohesion Status (implementiert)
TASK_306 - Meta Userology Playability Smoke (implementiert)

Phase 18Y - FOB VB Flightdeck Fireteam Assignment UX
TASK_307 - FOB Arrivals Unassigned Operator Pool (implementiert)
TASK_308 - Compact Flightdeck Dropship Occupants Actions (implementiert)
TASK_309 - Fireteam Assignment Board Compact Frames (implementiert)
TASK_310 - FOB Flightdeck Fireteam Userology Smoke (implementiert)

Phase 18Z - Dropship LZ Command Matrix Targeting Feedback
TASK_311 - Dropship LZ Target Pick Accuracy Contract (implementiert)
TASK_312 - Dropship Command Matrix LZ Go Layout (implementiert)
TASK_313 - Dropship Arrival Visibility Feedback Smoke (implementiert)

Phase 18ZA - FOB Fireteam Assignment Visibility Fix
TASK_314 - FOB NPC Pool Window Left Of Fireteams (implementiert)

Phase 18ZB - Mission Grid Tile Selection Visibility Fix
TASK_315 - Mission Grid Tile Selection Command Gate (implementiert)

Phase 18ZC - FOB Fireteam Staging Migration
TASK_316 - FOB Fireteam Staging Migration (implementiert)

Phase 18ZD - Manual Playtest Followups Backfill
TASK_317 - Manual Playtest Mission Fireteam FOB Payload and Bubbles (implementiert)
TASK_318 - Manual Playtest Debrief Background and Main Menu Team Library (implementiert)
TASK_319 - Manual Playtest FOB Second Dropship Assignment and Scale (implementiert)
TASK_320 - Manual Playtest Dropship Cards Per-Craft Dispatch and Return (implementiert)
TASK_321 - Manual Playtest Map Editor Station Floor Layering Undo (implementiert)
TASK_322 - Manual Playtest Map Editor Asset Import Rotation Context Menu (implementiert im Arbeitsstand)
TASK_323 - Manual Playtest Mission Command Visuals Fire Sector Dropships (implementiert im Arbeitsstand)
TASK_324 - Manual Playtest Team Editor Character Overlay Usability (implementiert im Arbeitsstand)
TASK_325 - Manual Playtest Documentation Backfill (implementiert)
TASK_326 - Manual Playtest Multiplayer Setup Asset Catalog Floor Followup (implementiert im Arbeitsstand)
TASK_327 - Manual Playtest Right Click Orders Tactics Dropship Visibility (implementiert im Arbeitsstand)
TASK_328 - Manual Playtest Marker Help Roster UPnP Followup (implementiert im Arbeitsstand)

Phase 18ZE - Manual Playtest Stabilization and Docs Truth Fix
TASK_329 - Manual Playtest Stabilization GDD Godot Fix Pass (implementiert im Arbeitsstand)

Phase 18ZF - Ground Mission Default Playability
TASK_344 - Ground Mission Default Enemy Visuals (implementiert)

Phase 18ZG - NPC Movement Posture Standard Behavior
TASK_345 - NPC Standard Movement Posture Policy (implementiert)

Phase 18ZH - Homebase Direct Staging FOB Bypass
TASK_346 - Homebase Direct Staging Character Popup (implementiert)

Phase 18ZI - Homebase Direct Staging Review Followups
TASK_347 - Homebase Direct Staging Start Guard (implementiert)
TASK_348 - Homebase FOB Payload State Isolation (implementiert)
TASK_349 - Homebase Direct Staging Real Flightdeck Craft Gate (implementiert)
TASK_350 - Homebase Loadout Contract Export (implementiert)

Phase 18ZJ - Homebase Direct Review Followups
TASK_351 - Homebase Direct Payload Scope Contract (implementiert)
TASK_352 - Homebase Loadout Defaults Preserve Unit Profiles (implementiert)
TASK_353 - Shared Loadout Contract Helper (implementiert)
TASK_354 - Homebase Direct Loadout Regression Matrix (implementiert)
TASK_355 - Homebase Direct UX Payload Truth (implementiert)

Phase 18ZK - MapEditor and Homebase Performance Refactor Followups
TASK_356 - MapEditor Lazy Terrain Texture Catalog (implementiert)
TASK_357 - MapEditor Height Cliff Dirty Neighborhood Cache (implementiert)
TASK_358 - MapEditor Undo Stroke Transactions (implementiert)
TASK_359 - MapEditor Dirty UI Refresh Batching (implementiert)
TASK_360 - MapEditor Mission Scenario Panel Extraction (implementiert)
TASK_361 - NPCCompactCard Readonly Profile Reference Contract (implementiert)
TASK_362 - Homebase Aircraft State Manager Extraction (implementiert)
TASK_363 - Homebase Roster Card Pool Incremental Refresh (implementiert)

Phase 18ZL - Mission Visualization Review Followups
TASK_364 - Mission Fireteam Orientation Indicators (implementiert)
TASK_365 - Tactical Event Log Data Layer (implementiert)
TASK_366 - Tactical Event Log HUD Panel (implementiert)
TASK_367 - FTL Public Readiness Snapshot Contract (implementiert)
TASK_368 - FTL Readiness Gauge (implementiert)
TASK_369 - Fireteam Status Card Enhancement (implementiert)
TASK_370 - Fireteam Member Health Status Row (implementiert)
TASK_371 - Fire Sector Security Arc Overlay Toggle (implementiert)
TASK_372 - Mission LOS Debug Overlay Toggle (implementiert)
TASK_373 - Cover Effectiveness Readout (implementiert)
TASK_374 - Objective Countdown Indicator (implementiert)
TASK_375 - Waypoint Intent Preview (implementiert)
TASK_376 - Command Validation Bubble (implementiert)
TASK_377 - Contact Density Heat Map Layer (implementiert)
TASK_378 - MapEditor Patrol Route Preview (implementiert)
TASK_379 - MapEditor Tile Property Grid Overlay (implementiert)
TASK_380 - Terrain Adjacency Solver Indicator (implementiert)

Phase 18ZM - Homebase Manual Test UX Polish
TASK_381 - Homebase Fireteam Loadout Flightdeck Polish (implementiert)
TASK_382 - Homebase Direct Mission Flightdeck Display (implementiert)
TASK_383 - Homebase Flightdeck Fireteam Card Single Owner (implementiert)
TASK_384 - Homebase Flightdeck Boarding Hotfix (implementiert)
TASK_385 - Homebase Direct Return Isolation (implementiert)
TASK_386 - Homebase Flightdeck Member Portraits (implementiert)
TASK_387 - Homebase Flightdeck Payload Polish (implementiert)
TASK_388 - Homebase Fireteam Roster Shipcard Polish (implementiert)
TASK_389 - Homebase Card Wide Drop Targets (implementiert)
TASK_390 - Homebase Direct Mission Transit Cards (implementiert)
TASK_391 - Global Escape Menu and Button SFX (implementiert)
TASK_392 - Parallel Boarding Transit Feedback (implementiert)
TASK_393 - Direct Dropship Independence LZ Vector (implementiert)
TASK_394 - Per Craft Shipcard Commands (implementiert)
TASK_395 - Manual Dropship Parallel Flow Stabilization (implementiert)
TASK_396 - Mission Dropship LZ Drop Hotfix (implementiert)
TASK_397 - Mission Dropship UX Hotfix (implementiert)
TASK_398 - Mission Dropship Outbound Command Hotfix (implementiert)
TASK_399 - Dropship Flow Contract Performance Pass (implementiert)
TASK_400 - Agent Rules Doc Refresh (implementiert)

Phase 18ZN - Facing Sightline Debug Fixture
TASK_401 - Facing Sightline Debug Map (implementiert)

Batch-Empfehlung

Codex soll Tasks in kleinen Gruppen bearbeiten:

Batch 1
TASK_016–019
Batch 2
TASK_020–023
Batch 3
TASK_024–027

Batch 4
TASK_074–077

Batch 5
TASK_078–079

Batch 6
TASK_080–081

Nach jedem Batch:

Godot starten
Fehler pruefen
ggf. Integrationsbranch aktualisieren
Definition of Done

Ein Task ist fertig, wenn:

Code kompiliert / Godot startet
Scope eingehalten wurde
keine unerlaubten Nebenumbauten
IMPLEMENTATION_STATUS.md aktualisiert
Commit + Push erfolgt
Wichtig

Diese Roadmap ist verbindlich.

Wenn ein Task:

groesser wird als erwartet
neue Architektur erfordert
bestehenden Code massiv veraendert

Dann:

stoppen
Problem melden
nicht improvisieren
