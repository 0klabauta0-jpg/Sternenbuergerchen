# Hex Tactical Runtime V1

Stand11.11.2026, Basis97e00aba14ced147b268113085854ac67dc764c5.
Implementierte Bausteine; keine bereits aktivierte Missions-/Basisintegration.
Gesamtplan: `docs/superpowers/plans/2026-11-11-hex-sight-occupancy.md`.

## Besitz und Aktivierung

HexGroundRuntime gehört SimulationRoot. `configure_hex_ground_runtime` prüft
vor Kontextwechsel Mapname, positive Größe, Load-Issue und Registrytopologie.
Nur `tactical_grid_rules=hex_tactical_v1` mit `hex_axial_v1` aktiviert ihn;
fehlende/leere Kennung wählt Legacy. Fehler erhalten den bisherigen Zustand.
Ein abgebrochener Mapload bleibt nach bloßer Kennungskorrektur ungültig und
unspeicherbar; die vollständige korrigierte Quelle muss neu geladen werden.
Unbekannte oder falsch typisierte Kennungen sind Load-Issues. Regionalversion2
und3 sowie Rampenkennung bleiben erhalten. Keine Karte ist jetzt umgestellt.

`admit_hex_ground_units`/`release_hex_ground_unit` passieren die vorhandene
Autoritätsprüfung des Simulationsowners. `get_hex_unit_state` und
`get_hex_ground_planning_snapshot` geben Kopien aus; letzteres liest den
aktuellen Ownertick. Der private Helper wird nicht als zweiter Mutationsweg
herausgegeben. Aktive Command-/Bewegungs-/Lifecyclepfade sind noch offen. Die Helper
mutieren keine Actortransforms oder Terrain-/Unitobjekte. ContactTracker
bleibt Kontaktwissen; keine neue UI-/Registryautorität.

## Ground-State

`configure(registry, map_id, tick)` leert den vorherigen Kontext. Nur eine
gültige Hex-Registry, nichtleere Map-ID und nichtnegative Ticks konfigurieren
den neuen Kontext. `admit_units(placements)` nimmt eine ganze Gruppe oder
niemanden auf. Bestehende IDs, gleiche Zellen und ungültige Felder weisen
ohne Teilmutation zurück. Leere Gruppen und wiederholtes Entfernen sind No-ops.

Placement: `unit_id: String`, `grid: Vector2i`, optional `facing_dir: int`
von0bis5 und `posture_key: String` (Defaults0/standing; keine Balancetabelle).
ID-/Zellindizes gehören demselben Zustand. `read_unit` und
`build_planning_snapshot` liefern unabhängige Payloads. Standhöhe und Terrain-
revision werden frisch gelesen, ohne logische Zelle oder Unitrevision zu ändern.
`stand_height_steps2` misst halbe logische Höhenstufen, keine Renderweltmetrik.
Die reale Rampenstandhöhe2,5 wird als5 erhalten.

## Reservierung und reine Motionprojektion

Reservierungsowner und vollständige Terrainkomponenten sind hinter demselben
Opt-in angebunden; Einzelheiten in `hex_reservation_plan_contract.md`.
Root-Tickkern publiziert logische Feldwechsel zur Segmentmitte und hält Kanten
bis zum Segmentende. Das allein bewegt noch keinen Actor.

`get_motion_projection(unit_id,fraction,height_step_world=1.0)` bzw. Root-
Readadapter `get_hex_motion_projection` liefern `position_world`,
`stand_height_logical`, `stand_height_world`, `facing_angle`, `moving`.
Fraction wird auf0..1 begrenzt; nichtfinite Eingaben, ungültige Skala und
unbekannte IDs ergeben kein Ergebnis. Readcalls ändern weder Tick noch Revision,
Feldbesitz, Zusagen oder Erkennung. Facing stammt aus dem committeten Zustand.

Position folgt dem aktiven Segment; dessen Mitte ist die gemeinsame Feldkante.
Explizite Rampenhöhe verläuft Zentrum→gemeinsamer Endpunkt→Zentrum. So bleibt
ein Plateau bis zur Kante flach, Rampe und passend geknicktes H+0,5-Band schließen
ohne Höhensprung an. Runtime-Endpunkthöhe liest den kanonischen Tilekern nach
Registrybegehbarkeit; ein per Override geöffnetes Raw-Blockerfeld bleibt nutzbar.
Unversionierte alte Höhengänge behalten lineare Zentrumshöheninterpolation.

Die Skala ist ausschließlich ein Leseparameter des Darstellungsowners. Der
View muss seine bestehende `_get_3d_height_step()` samt Mapping-/Regionalfallback
übergeben; Ground speichert keine zweite 3D-Mappingwahrheit. Regionalhöhe0 ist
weiter ein gültiger Nichtregional-Sentinel und kein Zulassungsfehler.
Actor-/Viewanbindung, echte Commands und tatsächliche Zielankunft folgen AP5.

`stop_units(unit_ids,reason)` und Root-`stop_hex_ground_units` sind interne
autoritative, atomare Stoppgrenzen. Zukunftsintervalle aktiver Routen bestimmen
die transitive Abhängigkeit auf die jetzt dauerhaft gehaltenen aktuellen
Felder. Alle betroffenen Zusagen werden zusammen zurückgenommen; unabhängige
Routen bleiben. Vergangene Posthandoff-Quellen begründen keine neue Abhängigkeit.

Angefangene Bewegung zentriert innerhalb des aktuell besessenen Hex. Diese
`movement_state.phase=centering` zählt bis zum Ende als Bewegung, hat keinen
Feldwechsel und erlaubt neue Segmente erst nach ihrem Ende. Phasendauer besteht
aus exakten Integer-Tickdifferenzen; Wiederholung verlängert sie nicht.
Intrinsischer axialer Offset hält den Renderpfad auch bei geänderter Metrik im
eigenen Feld. Release und Kontextwechsel entfernen Phase und Geometrie.
Planersnapshots validieren Typen und aktive ganzzahlige Zentrierdeadline.

Segmentgeometrie wird beim Commit rein abgeleitet vorbereitet und bleibt für
sicheren Stopp nach Terraininvalidierung lesbar. Readcalls bauen keinen Cache.
Terrainrevision stoppt illegale Routen samt Abhängigkeiten vor Handoff und
erneuert weiterhin legale Profile. Metrikänderungen erhöhen jetzt auch bei
gleicher Topologie die Registryrevision. Ein bloßer Commit verbraucht keine
noch ausstehende Geometrieauffrischung. Geometrie bleibt privater Cache und
darf nicht als zweite gespeicherte Gameplaywahrheit exportiert werden.

Rootadapter prüft Authority und synchronen Tick, publiziert Ereignisse; echte
Command-/Verwundungsproducer müssen erst im weiteren AP5 angeschlossen werden.
Zentrierphase selbst muss AP7 beim Save/Restore ausdrücklich unterstützen.

Ortsruntimes bleiben beim bloßen Ansichtswechsel bestehen und ticken weiter.
Viewread ist weder Stop noch configure/clear/admit/release. Jeder Root nutzt
seine eigene Ground-/Registryinstanz; die aktuelle Ansicht besitzt keinen
Gameplayzustand. Kleine Zwei-Ownerprobe sichert diese Grenze, keine vollständige
MetaLayerFlow-/UI-/Transportabnahme.

## Reine Sicht

`HexVisibilityQuery.classify_candidate` prüft Hex-Registry, vorhandene Zellen,
Eingaben, Hexreichweite und Blickkegel vor Terrainarbeit. `evaluate` verwendet
danach den vorhandenen `LineOfSightSystem.find_first_blocker_grid` mit
präzisen Endpunkthöhen. Keine zweite Terrain-/Wandalgorithmik.

Observer/Ziel: `grid`, `stand_height_steps2`; Observer zusätzlich `facing_dir`.
Profil: `range_hex: int`, optional `arc_degrees` von0bis360 (Default120).
-1 ist unbegrenzte Reichweite. Ausgabe: `in_range`, `in_arc`, `terrain_clear`,
`terrain_checked`, `visible`, `reason`, nach Terrainprüfung `blocker_grid`.
Richtungen folgen HexGrid.DIRECTIONS in der physischen Hexebene; Kegelrand
einschließlich kleiner numerischer Toleranz. Keine Kontaktbestätigung,
Schusserlaubnis, Deckungsbalance, RNG oder Schadenswirkung in diesem Helper.

## Cache

`CombatVisibilityCache.query_hex_visibility` hält reine Geometrie über
Tickgrenzen. Geordnete Zellen, effektive halbe Endpunkthöhen, Registryidentität
und Terrainrevision bilden den Key. Richtung/Reichweite werden jedes Mal
frisch gefiltert; Renderpositionen sind keine Eingabe. Ohne Revisions-API
keine dauerhafte Wiederverwendung.

Maximal16384Einträge, deterministische LRU mit verketteten Dictionaryeinträgen;
kein linearer Suchlauf pro Hit/Eviction. Neue Revisionen treffen keine alten
Keys; alte Einträge bleiben begrenzt. Kapazitätswechsel und `clear_hex_cache`
leeren auch die Hex-Auditzähler. Der alte Weltpositionscache bleibt ticklokal.
`begin_tick` leert dessen Daten, nicht die neue Hex-Geometrie. Diagnosewerte
sind keine replizierte Gameplaywahrheit.

## Erkennungsepisoden

`HexDetectionState.observe_pair(observer_id, target_id, visible, now_tick,
delay_ticks)` speichert einmal pro Episode einen Fälligkeitstick. Weitere
Beobachtungen ändern ihre ursprüngliche Dauer nicht. Echte Sichtlücke beendet
die Episode; Wiedererkennung beginnt neu. Zeitstempel sind im gesamten
Helperkontext monoton. Negative/überlaufende Zeiten und veraltete Updates
werden ohne Änderung bestehender Episoden abgelehnt. IDs bleiben strukturierte
Paare. `forget_unit` entfernt Beobachter-/Zielreferenzen; `clear` auch den
Zeitkontext. Keine Skills, Würfe oder Kontaktpublikation aus diesem Helper.

`read_pair` und `build_episode_snapshot` leiten Read-Payloads und Restticks
aus diesen Deadlines ab, ohne Episoden zu erzeugen oder die Uhr zu verändern.

## Erste aktive Consumer hinter dem Opt-in

`HexSightRuntimeAdapter` hält Owner-/Cacheverweise und eine interne Sequenz
für eindeutige Absichts-IDs. Er besitzt keine zweite Unitwahrheit. Im Hexkontext lesen
Contact-, Schuss- und FoW-Abfragen die vom Owner zugelassenen logischen Zellen,
Standhöhen und Richtungen. Fehlende Zulassung ist unsichtbar; Legacy nimmt
weiter den bisherigen Weltpositionspfad. Derselbe CombatVisibilityCache dient
allen drei Lesern. Ohne dessen neue API bleibt die reine Hexquery korrekt,
aber ohne gemeinsame Geometriewiederverwendung. Weltreichweiten werden mit
der bestehenden Hexmetrik auf ganze Hexradien abgerundet; Kegeldefault120°
ist ein konfigurierbarer Vorschlagswert, keine neue Skill-/Waffenbalance.

FoW friert logische Beobachter und Profile für ihre begrenzten Jobs ein.
Normale und statische Signaturen enthalten Profil, Blickrichtung und Owner-/
Registrykontext; reine Renderbewegung ersetzt keine Arbeit. Kontextwechsel
erzwingen eine neue Probe, gleich nummerierte Revisionen fremder Registries
sind verschieden. Deltaänderungen vergleichen weiterhin die tatsächlich zuvor
publizierte Sicht, damit auch notwendige Ausblendungen an den View gehen.
Contactwissen und Schusserlaubnis bleiben eigene Entscheidungen. Die Hex-
Erkennung im Driver liest Deadlines; Legacy-Countdowns bleiben kompatibel.

Sicherung, Overwatch und Flankierung lesen ebenfalls Zellmitten und aktuelle
Richtungen. Kanonische Winkel werden in der unverzerrten Hexebene geprüft;
Visual-Metadaten erhalten daraus abgeleitete projizierte Winkel. Ein einzelner
360°-Wächter behält seinen individuellen Kegel. Für mehrere Wächter wird die
gemeinsame Basis einmal quantisiert und auf sechs Richtungen verteilt; drei
120°-Wächter können geometrisch Rundumsicht bilden. Terrain bleibt wirksam.
Alte Sicherungssnapshots erweitern weder aktuelle Richtung noch Kegelbreite.
Kontextwechsel löschen auch lokale Sicherungs-/Overwatch-/Flank-Ableitungen.

## Autoritative Blickabsichten

`SimulationRoot.queue_hex_facing_intent(unit_id,direction,command_id,reason,
ready_tick=-1)` nimmt interne Absichten an. Gültige Gründe: noise_reaction,
combat_reaction, security_assignment, movement (Prioritäten10/20/30/40).
Eine Absicht je zugelassenem Runtime-NPC; fehlende Autorität/Unit, ungültige
Richtung/Identität/Zeiten werden abgelehnt. Der Root committet nach Commands
und vor Effects/Tickverbrauchern. Frühestens nächster Tick oder der spätere
Fälligkeitstick; Wiederholungen gleicher Richtung verschieben die ursprüngliche
Deadline nicht nach hinten. Replayfenster4096IDs als begrenzter O(1)-Ring.
Ground-State ändert die Revision nur bei tatsächlichem Richtungswechsel.

Auftragsfingerprint und Kontextwechsel verwerfen veraltete Absichten. Hold,
Retreat, SeekCover, Defend/Take und reines Move erlauben keinen freien Noise- /
Combat-Nachsehauftrag; eine neue Sicherungsanweisung hat Vorrang. Der Driver-
Hook `notify_hex_sound_cue(unit_id,source_grid,event_id)` benutzt die vorhandene
Awareness-/Bereitschaftsverzögerung und Root-Auftragspolicy, bestätigt aber keinen
Kontakt. AudioEventBus ist Darstellung; ein Gameplay-Schallausbreitungsproducer
ist hier nicht vorhanden/neu eingebaut. Der explizite adressierte Hook ist der
Anschlusspunkt, keine Schallphysik und kein zusätzlicher NPC-Vollscan pro Schuss.

Terraincover, Damage-/Diagnosepositionen und Höhenbonus lesen im Hexkontext
dieselben logischen Felder; H+0,5 bleibt als halber Schritt im bestehenden
Höhenfaktor erhalten. Legacyregeln bleiben getrennt; vorhandene Skill-/
Attackbonuswerte bleiben bestehen. Der AP5-Anschluss unten ergänzt einen
ausdrücklich vorläufigen Bewegungsfaktor; Balanceabnahme bleibt offen.

Keine Karte ist aktiviert. Die folgenden AP5-Abschnitte beschreiben aktuelle
Anschlüsse; Zulassung/Lifecycle und Save-/Netzpfade bleiben AP6–8, große
Szenen-/Leistungsabnahmen AP9 folgen später.

## Rampen und offene Anbindung

Gemeinsamer Rampenvertrag: längs H/H+1, seitlich H+0,5 nur bei passenden
Rampennachbarn, StandhöheH+0,5. Breiten-/Eck-/Editorregeln stammen aus dem
Terrainowner; `allows_registry_step` ist nach beiden Registrygates das gemeinsame
Runtime-Tor, `allows_step` behält seine Authoringdefaults.

Aktueller Anschluss: echte Root-Moveabsichten, Groundzusagen, Actorprojektion
und Gruppen-/Viewleser gemäß den beiden AP5-Move-Tasks sowie Bewegungsschuss.
Lokaler Türguard und Rücksetzausführung sind ebenfalls angeschlossen, siehe
unten. Zulassung/Lifecycle, Restore/Authority und Kandidat AP6–8 bleiben offen.
Große AP9-Abnahmen bleiben später; keine gemessene FPSverbesserung.

## Echte Bewegungsabsichten und Darstellung

Im zugelassenen Hexruntime wendet Root den vorhandenen UnitCommand an und
übergibt das Ziel an seinen privaten HexMovementCommandRuntime. Dieser hält
Absicht, abgeleitete Navigation und Ankunft; Ground besitzt allein Zelle,
Segmentzusagen und Zentrierphase. `requeue_until_target` erzeugt hier keine
zweite Framebewegung. Neue Ziele stoppen alte Abhängigkeiten vor neuer Planung;
Hold/Wunde räumen auch noch nicht zugesagte Such-/Pfad-/Timingdaten auf.

Pro Root-Tick höchstens vier Navscheiben/96 Expansionen sowie16 Requests mit
je drei neuen Übergängen. Das vorhandene Navzulassungsbudget kann null sein.
Wartende unveränderte Routen benutzen ihren Such-/Oberflächenzeitcache weiter;
stehende/verwundete Figuren blockieren Navigation, gemeinsame Abfahrten werden
weiter atomar vom Planer geprüft. Zeit basiert auf physischem Hexmaß und
vorhandenen Geschwindigkeitsprofilen, unabhängig von Bildschirmrichtung.

Root projektiert nur abgeleitete Actorposition/Richtung/Höhenmetadaten. Alte
Avoidance, Abstandskorrektur und Passageplanung dürfen zugelassene Hexfiguren
nicht zusätzlich verschieben. Fractional-Renderreads würfeln oder committen
nichts. Capture liest das zugelassene logische Feld statt der Renderposition.
Ankunft verlangt aktuelle Zielidentität und Ende aller Kanten/Zentrierphasen;
die letzte Feldübergabe allein reicht nicht. Read-/Ansichtswechsel führen weder
Stop noch Neuplanung aus und benutzen ausschließlich die Registry dieses Orts.

QA hex_move_commands_20261111:42/0 echte Root-/UnitRegistry-/CapabilityActor-
Prüfungen, direkte Nachbarcases und enger Review. Kleine synthetische Bewegung,
keine vollständige TestUnit-/3D-/Meta-/Save-/Netzwerk- oder Lastabnahme.

AP5-Konsumentenanschluss: `get_hex_logical_unit_position` liest den Zellmittelpunkt
aus der zum Root gehörenden Registry. `has_hex_position_arrived(unit,target,token)`
verlangt das angefragte Zielhex, passende Absichtsidentität und Ende aller Bewegung.
Für deckende Gruppenmitglieder gilt alternativ ein tatsächlich angewendeter Hold
mit demselben Token und explizitem endlichen Ziel dieses Hex. Ein generischer Hold
ohne Ziel ist kein Ankunftsbeweis. FireteamMovementController reicht seinen
vorhandenen Rootparameter bis in Gruppenankunft, aktuelle Position, Start- und
Formationsanker einschließlich Abschlussfallback; Darstellung entscheidet nichts.

TerrainMap3DView liest abgeleitete Actorphase/-höhe und ausschließlich das separate
`hex_ground_facing_angle`. Ältere kosmetische Facingwrites bestimmen den Hexkörper
nicht. Root setzt/entfernt diese Metadaten; sie werden weder gespeichert noch zur
Wahrnehmung zurückgelesen. Rampenhöhe multipliziert der View mit seinem bestehenden
`_get_3d_height_step()` (Mapping oder regional), Position wird kein zweites Mal
geglättet. Animationsbewegung folgt der Phase, Waffenpose bleibt beim vorhandenen
Feuereventpfad. Legacyglättung und Pixelankunft bleiben im bisherigen Zweig.
Kleine Consumerprüfung65/0 samt Zweierformation und großer Metrik256/128;
QA hex_move_consumers_20261111, keine native Grafik-/Animationsfreigabe.

## Bewegungsschuss und lokale Profilreads

UnitProfileMath leitet `moving_shot_accuracy_multiplier` aus Coreaccuracy ab.
Vorläufiger Kandidat0.65..0.95 für Skill0..1:35%..5% relativer Abzug auf die
bereits fertig berechnete Trefferchance, danach dieselben Min-/Maxgrenzen.
Root verwendet den Faktor ausschließlich bei zugelassenem Angreifer mit
Groundbewegungsphase, einschließlich Zentrierung. Stationär/Legacy gilt1;
Actorposition, Animation und bewegte Renderflags entscheiden nichts. Vorhandene
Auftrags-/FireRule-Producer entscheiden weiter, ob überhaupt geschossen wird.
Kein zusätzlicher Treffer-, Rüstungs- oder Schadenswurf ist hinzugekommen.

TestUnit bietet `get_damage_profile_snapshot()` als expliziten Opt-in für die
kanonischen effektiven Combatwerte einschließlich Loadout/Leadership. Root liest
ihn höchstens einmal pro Beteiligtem/Effect; bei Selbstschaden einmal insgesamt.
Der Snapshot ist nur eine lokale Variable dieses Schusses. Weitere Effects sehen
neue Skills/Ausrüstung sofort; keine neue dauerhafte Statwahrheit. Andere Actors
behalten die bisherigen Einzelgetter und deren Vorrang, Fallbacks lesen nur die
benötigten Rollenwerte. Bewegungsskillfallback wird nur bei bewegtem Angreifer
ausgewertet und liest vorhandene Corewerte vor dem älteren Skillgetter.

Ältere TestUnit-Bundles ohne neuen Effekt leiten ihn beim Lesen aus vorhandener
Coreaccuracy ab, ohne das Bundle umzuschreiben. Hitcontext und read-only Damage-
auflösung nennen logische Bewegung und angewendeten Faktor. Schadensmenge und
Würfelkadenz behalten ihre bisherigen Regeln. Kleine MovingShot65/0 (einschließlich
42 Basisprüfungen), MoveConsumers65/0 und SightConsumers39/0 mit geschlossenem
Review; QA hex_moving_shot_20261111. Keine Balance-/Last-/FPSfreigabe.

## Lokaler Türschluss vor Ownercommit

`Ground.can_block_cells` und `Root.can_block_hex_ground_cells` sind reine
Claimreads für höchstens64 konkrete Zellen. Aktuelle Belegung (auch verwundet),
beide Endpunkte noch nicht beendeter Segmente und aktive vollständige Korridor-
grants verhindern eine neue Blockierung. Damit ist auch ein ferner Türausgang
jenseits des Dreischritthorizonts geschützt. Root prüft eigene Registry,
Autorität und synchronen Tick; unbekannte/ungültige Zellen fallen geschlossen aus.
Keine Actor-, SceneTree- oder Vollkartensuche; Grantmitgliedschaft bleibt eine
Lesearbeit über vorhandene aktive Zusagen, keine gemessene Laufzeitfreigabe.

Der tatsächliche lokale Producer ist Driver.update_mission_interaction_runtime_progress.
Bei Open→Blocked prüft er den vorhandenen DoorRuntimeCollisionLOS-Kandidaten vor
Statecommit und vor LocationResources.accept_progress. Konflikte werden explizit
abgelehnt; Interactionstate, physischer Registryoverride und Reservierungen bleiben
gleich. Kein versteckter Schließtimer, kein nur optisches Offenhalten. Öffnen,
unveränderte Blockierung und Nicht-Türinteraktionen brauchen diesen Claimread nicht.
Auf Opt-in-Karten verhindert auch fehlender/inaktiver Root den Schluss; nur echte
Legacykarten behalten den früheren Weg. ShipReturn-/Ressourcenregeln sind erhalten.

QA hex_door_guard_20261111:58/0 einschließlich42 Basisprüfungen, SightConsumers39/0,
ReservationOwner36/0, enger Review geschlossen. Neunfelderausgangsraum, tatsächlicher
Rootqueue-/Drivermutationspfad und Ressourcenseiteneffektzähler; keine native Mission.
Szenarioneuaufbau/Zulassung AP6 und atomarer Save-/Multiplayersnapshot AP7 sind eigene
Lebenszyklusgrenzen und werden dadurch nicht als abgesichert behauptet. Keine Karte
aktiviert, große AP9-Prüfungen bleiben später.

## Tatsächliches Ausweichen mit unverändertem Auftrag

HexMovementCommandRuntime nimmt höchstens einen tatsächlichen backoff_required-
Vorschlag pro Tick als temporäre Recoveryabsicht an. Nur aktive wartende
Moveabsichten ohne Motionzusagen; ausdrücklich haltende NPCs werden nicht
verschoben. Niedrigerer Prioritäts-/Wartescore, dann stabile ID entscheiden unter
geeigneten Vorschlägen. Der geräumte Standort muss auf dem Weg eines anderen
Requests liegen. Reine Vorschlagsziele meiden dessen aktuelle Quelle, nächste
drei Übergänge und Endziel; keine Rücksetzposition direkt vor dem Gegenverkehr.

Öffentliches Ziel, Commandidentität, Skill-/Auftragskontext und Wartealter bleiben
erhalten. Die Recoveryroute wird im nächsten Tick durch denselben gemeinsamen
Planer und Groundcommit geführt, samt Rampen, Zeiten und Dreischritthorizont.
An der Bay wartet der NPC auf committed Passage und Freigabe des zugehörigen
Claims; ein beendeter/ersetzter/entfernter oder ohne Bewegungszusage blockierter
konkurrierender Auftrag löst ebenfalls
die Wartebindung. Danach frische Navigation zum ursprünglichen Ziel, keine frühe
Ankunft an der Bay. Hold/Wunde/Neuziel/Release/Kontextende räumen Recovery und
den rein abgeleiteten Reverse-Watcherindex auf. Ungültige Bays und verschwundene
Clearancezellen verwerfen die private Wartebindung; Originalziel wird neu geplant.

Ein ohnehin laufender Plan kann direkt konkurrierende Retryrequests aus gültigem
Cache bis zum bestehenden16er Limit ergänzen. Das verhindert einen dauernden
Taktsversatz bei Navbudget1, ohne eine neue Suche zuzulassen. Der bei Timingaufbau
abgeleitete Pfadindex ersetzt Vollpfadscans bei Handoffs/Beziehungsprüfung; Bay-
Warten startet keine neue Navigation. Vollständige Pfadrestkopien und bestehende
Planerarbeit sind weiterhin Arbeit, kein gemessener CPU-/FPSgewinn.

QA hex_backoff_execution_20261111:55/0 einschließlich42 Basisprüfungen,
Planer26/0, Reservierungsowner36/0, enger Review geschlossen. Kleine tatsächliche
Rootqueuefälle: Gegenaufträge, Priorität, frühe Freigabe vor Fernziel, Navbudget1,
Terraininvalidierung, Hold und fehlende Bay. Keine globale Deadlockfreiheit oder
optimale Mehragentenplanung behauptet. AP7 muss Recoverysemantik einschließlich
beobachteter Passage/Wartealter sichern; Pfad-/Timing-/Watcherindizes nicht speichern.

## AP6 Gruppenplatzierung und registrierte Missionsactors

`HexGroundAdmission.plan_group` plant ohne Gameplaymutation maximal64 Personen
mit höchstens64 expandierten Feldern. Die Reihenfolge des Transport-/Rosterowners
bleibt erhalten. Erst bei ausreichend erreichbaren Feldern liefert der Helper
die vollständige Gruppe; sonst warten alle IDs ohne Teilplatzierung. Ein belegter
oder beanspruchter Anker wird nicht übersprungen. Registry-Nachbarn benutzen den
kanonischen beidseitigen Rampenkern; gesperrte Felder werden nicht durchquert.

`Root.admit_hex_ground_actor_group` validiert vor dem Write sämtliche registrierten
Missionsactors und ihre ID/Commandfähigkeit. Root, Registry und Actors gehören zur
selben Missionsszene; der globale SceneTree ist keine solche Scopebindung. Zwei
Orte dürfen dieselbe Personen-ID nur mit ihren eigenen Lookup-/Actorprojektionen
führen; ein fremder tatsächlicher Actor darf nicht zur zweiten Groundfigur werden.
Ein bestehender lebender Lookup wird im Hexpfad nicht durch einen anderen Actor
überschrieben. Dauerhafte Basisprojektionen benutzen diese Missions-API nicht.

Erst nach vollständigem Groundcommit werden Embarkedmetadaten, Transform und
Sichtbarkeit publiziert. `embark_hex_ground_actor_group` räumt Ground, Moveabsicht
und ausstehende Movecommands, erhält aber die tatsächliche Actoridentität in der
Registry. `unregister_known_unit` gibt vor Entfernen des Lookups Ground frei;
Wiederholung ändert keine Feldbelegung. Verwundung allein entfernt keinen NPC.

Auch die interne Placement-API prüft jetzt beide Endpunkte laufender Kanten und
vollständige aktive Passagegrants. Das nach Handoff freigewordene Quellfeld kann
dadurch nicht während der restlichen Überquerung neu besetzt werden.

Diese Primitive schalten bestehende Setup-/Transportadapter noch nicht um. Die
gestaffelten Aussteigephasen benötigen zuerst verbindliche Groundvormerkungen
für die gesamte Gruppe; Basisankunft und Anwesenheit folgen im nächsten AP6-Teil.
Kleine Prüfungen sind keine Produktionskarten-, Native- oder Performancefreigabe.

## AP6 Vormerkungen für gestaffelte Aussteigephasen

`Root.prepare_hex_ground_deployment(ids, anchor_grid)` prüft die ganze Gruppe und
gibt ein kontextgebundenes Admissionticket zurück. Ground hält bis zu16 Gruppen
mit je höchstens64 Personen und deren noch ungenutzte Plätze. Diese Slots sind
keine Groundunits. Auch echte, vorab bekannte Missionsactors ohne Registrierung
können vorgemerkt werden; der Missionssubtree und die tatsächliche Actoridentität
müssen bereits stimmen. Ein belegter, aber ungültiger Registryschlüssel wird vor
dem ersten Write abgelehnt. `UnitRegistry.get_unit` gibt für freigegebene Nodes
rein lesend null zurück, bereinigt den Index nicht versteckt.

Der tatsächliche Root-Deployeffect braucht für neue Hexanwesenheit `admission_id`.
Er konsumiert genau den für diese Person vorgemerkten Platz und registriert den
Actor erst nach erfolgreicher Groundvalidierung. Ein vorhandener Presence-Refresh
kann eine bereits zugelassene Person anzeigen, aber keine neue Person einsetzen
oder ihre logische Zelle teleportieren. Falsche/alte Tickets verändern nichts.
Der echte Embarkeffect benutzt den Lifecyclepfad und gibt alle Claims frei.

Vormerkungen sperren fremde Zulassung, Türschluss und Bewegung. Ein neuer
geschlossener Korridorgrant darf keine noch ungenutzten Aussteigeplätze umfassen;
der Planer wartet konservativ, bis deren Aussteigephasen abgeschlossen sind.
Ground prüft das unabhängig vom Planervorschlag. Navigation maskiert Slots und
Abbruch weckt wartende Aufträge auf. Fremde Schiffsfootprints benötigen weiterhin
den vorhandenen Landungs-/Visitowner als Eingabe des produktiven Adapters.

`cancel_hex_ground_deployment(ticket, reason)` gibt nur verbleibende Slots frei;
bereits ausgestiegene Personen behalten ihre Zelle. Entfernung einer vorgemerkten
Person verwirft die verbleibende Gruppe, ohne die anderen Bordpersonen zu löschen.
Ungültige oder nicht mehr kanonisch verbundene Zugangsflächen verhindern Consume;
bei Terrainrevision wird die Vormerkung vor dem Deployeffect verworfen.
Kontextwechsel leert alle Tickets und erlaubt keine Wiederverwendung alter IDs.

Queued Hex-Move/Hold- und Embark/Deploy-Payloads tragen intern Kontextrevision,
Actorinstanz und Lifecyclegeneration. Prüfung vor Apply und Requeue verhindert,
dass ein alter Auftrag nach Ortswechsel oder Readmission dieselbe ID trifft.
Die Felder sind keine Clientauthority. Bekannte Actors melden `tree_exiting`;
Root entfernt Ground und den passenden Registryeintrag anhand der gebundenen
Actorinstanz. Das berührt keinen neueren Actor unter derselben ID und benötigt
keinen SceneTreescan. Legacycallbacks bleiben ohne Groundmutation.

Kleiner Slotcase87/0 einschließlich63 voriger Movement-/Lifecyclechecks;
Backoff55/0, Planer26/0, Owner56/0, Quell-/Profilguards und enger Review geschlossen.
Konkrete Controller-/Setup-/Basisproducer sind der nächste AP6-Teilschritt;
ohne sie keine produktive Kartenaktivierung. Save/Peergrenzen folgen in AP7.

Integrationsnachprüfung12.11.: Ein Registry-only Lookup reicht für tatsächliche
Actorzulassung nicht aus. Derselbe gültige Actor muss explizit an Root gebunden
sein (`register_known_unit`), damit der Tree-Exitpfad bereits besteht. Admission
lehnt fehlende Bindung vor jedem Write ab. Echter Registry-only→Admission→free-
Repro87/1, nach Guard88/0; QA hex_admission_binding_fix_20261112. Die internen
datenorientierten Foundation-Placementchecks sind davon getrennt; kein Adapter
darf sie als Umgehung der tatsächlichen Actor-Lifecyclegrenze verwenden.

## AP6 tatsächliche Aussteigesequenzen

Der bestehende Missionscontroller führt primäre, parallele und ausdrücklich
angeforderte Ausstiege geparkter Crew über HexGroundDeploymentAdapter. Dieser
besitzt keinen Zustand: Nur der bestehende Sequenzowner hält den Ticketbeleg,
pending Unit-ID und Sendetick. Root besitzt weiter Slots und tatsächliche Präsenz.
MissionDropshipEffectAdapter ergänzt optional admission_id; leere ID erhält den
bisherigen Legacy-Effectdict ohne Zusatzfeld.

Queueannahme erhöht weder unit_index noch deployed und entfernt keine Bordperson.
Der Controller bestätigt einen Ausstieg erst über den Rootreceipt. Ground speichert
dazu admission_id an der tatsächlich zugelassenen Unit. Die Bestätigung bleibt
gültig, wenn die Person bereits in eine Folgezelle gelaufen ist oder das letzte
Ticket vollständig konsumiert wurde. Boarding/Release entfernt diese Präsenz.
Renderpolling erzeugt keinen doppelten Deployeffect und keinen neuen Feldwechsel.

Commitbestätigung geschieht unabhängig vom Ausstiegstimer. Nur Einreihen der
nächsten Phase verbraucht ein vorhandenes DROP_UNLOAD_INTERVAL_SECONDS; ausstehende
Bestätigung verbraucht kein zweites Intervall. Primär→Parallel überträgt den
abgetrennten Beleg und gibt seine Slots nicht frei. Wirklicher Abbruch verwirft
Restslots. Visit-Retirement benutzt genau seine gespeicherte Sequenz und liest
für genau die übergebenen Personen auch tatsächliche Root-Präsenz. Dadurch wird
ein NPC zwischen Rootcommit und verzögerter deployed-Publikation ebenfalls über
den bestehenden Embarkeffect entfernt. Andere Teams/Visits bleiben beim Owner.

Eine geladene Karte mit nichtleeren taktischen Regeln benötigt den Hexowner;
fehlender/inaktiver Root führt zu Warten oder Ablehnung vor jeder Publikation.
Root merkt seine Hexbindung auch bei Terrainverlust und wechselt für Deploy/
Embark nicht in Legacyteleports. Echte Karten ohne taktische Kennung behalten
ihren bisherigen Scheduling-/Effectpfad, ebenso die isolierte Vorschau.

Kleine private Phase95/0 und voller Controller73/0 mit höchstens zwölf Feldern
je Fixture, Quell-/Originalprofilguards und engem geschlossenem Review. Der volle
Controllerscript wird mit seiner tatsächlichen Preloadclosure geladen, keine
Quellkörperextraktion. Keine Hauptszene, große Karte, native Darstellung oder
Performancefreigabe. Fremde Schiffsfootprints und deren bindender regulärer
Landeproducer sowie Setup/Base sind weitere AP6-Teile; noch keine Kartenaktivierung.

## AP6 reine Schiffsfläche als Eingabe der Gruppenzulassung

HexGroundShipFootprint validiert das zum Craft/Modell/Asset gebundene Profil und
verwendet den vorhandenen polisa_station_craft_runtime.projected_body-Vertrag.
Dessen Rect liegt in unverzerrter X/Z-Ebene; Rastergrenzen werden über tatsächliche
Registryumrechnung bestimmt. HexGrid.corners und die tatsächliche Registrybasis
liefern die Zellfläche. Einmal berechnete SAT-Achsen/Intervalle schließen auch
Randkontakt ein, keine reine Mittelpunktprobe und keine alternative Schiffsformel.

Maximal4096 lokale Rasterkandidaten, Budget-/Koordinatenfehler vor der Iteration
ohne abgeschnittene freie Teilfläche. Nur vorhandene Kartenfelder werden als
Maskeneinträge ausgegeben; unbekannte Felder bleiben schon im Terrain unbegehbar.
Rootadmission und Deploymentvorbereitung akzeptieren optional höchstens4096
zusätzliche Ausschlussfelder. Diese Maske ist eine abgeleitete Planereingabe,
keine Belegungswahrheit oder zweite Schiffsregistry; die atomare Groundprüfung
für tatsächliche Zellen/Claims bleibt bestehen.

Kleiner Raster-/Rootcase52/0 einschließlich42 Moveprüfungen, alle Guards und
geschlossener enger Review; QA hex_ship_footprint_raster_20261112. Konkrete
Schiffsquellen/Cache, Transportconsumer, Landeclaims und regulärer Profilproducer
sind noch ein Folgeteil. Keine Produktionskarte oder große Leistungsabnahme.

## AP6 Empfänger laufender Aufträge

Ein laufender Hexauftrag bindet seine Empfänger einmal an Rootinstanz, Kontext,
Actor und dessen Root-Lifecyclegeneration. Groundpräsenz und Registrylookup
müssen weiterhin übereinstimmen. Boarding, Actorersatz und Readmission nehmen
keine neue Präsenz in den alten Auftrag auf. Reissue, Stance-/Feuerregelwechsel
und Kontaktstopp verwenden ausschließlich die verbliebenen Empfänger.

Die Bindung liegt privat in bestehenden Execution-Dictionaries. Automatische
Wegpunkt-/Area-Fortsetzungen, Unterbrechung und Rückkehr vererben sie; ein
Scope mit null verbliebenen Mitgliedern ist terminal. Neue explizite Befehle
dürfen neue Präsenzen aufnehmen. Truppübergreifende Crew eines bestehenden
Schiffsrückkehrauftrags wird einmal als return_crew innerhalb derselben Hülle
gebunden. Kein erneuter Vollroster-Capture beim automatischen Wiederaufnehmen.
Solche Instanzbindungen gehören weder in Planmetadata noch in portable
Snapshots. Sie ersetzen weder Registry noch Personal-/Visitmitgliedschaft.

Retirement entfernt nur eigene Ziele und Gruppenmitglieder. Leere Vorrückgruppen
entfallen; verbleibende Deckungsmitglieder können weiter vorrücken. Vollständiges
Execution-Clear räumt FMC und betroffene Koordination auf; ein verbleibender
Coverpartner setzt sein ursprüngliches Ziel mit seinem ursprünglichen Scope fort.
Ungekennzeichnete Legacybewegung bleibt erhalten; ein alter Legacyauftrag darf
beim Wechsel in einen Hexkontext keine neuen Empfängerbindungen erwerben.

## AP6 RuntimeSelection als Personenabgleich

RuntimeSelection ist ein Abgleich vorhandener Personen, kein Szenarioreset.
Umordnen derselben IDs erhält Actor, Health, Feld, Auftrag und Lifecycle. Auch
gestagte bekannte Personen werden wiederverwendet. preserve_existing steuert
Gearrefresh, refresh_existing_ids benennt expliziten Gear-/Fireteamrefresh.
Nur entfernte oder tatsächlich umbenannte Slots verlieren ihre vorherigen
Ground-/Move-/Lookup-/Commandbindungen. Der Identityreset heilt nicht und
ersetzt kein medizinisches Modell.

Root validiert alle vorbereiteten Actoränderungen und den vollständigen
Registrylookupbatch vor Modellwrites. Der Registrybatch ist eine reine
Indexoperation ohne Signale oder Gameplaymutationen. Identitätssetter werden
ausschließlich in der vorbereiteten Modellphase stummgeschaltet; nach vollständigen
Actor-/Known-/Registrybindings publiziert Finalize identity_changed für den
vorhandenen RuntimeIndex und anschließend Runtime-/Visualfeedback. Andere
Identitätsanwendungen behalten ihre unmittelbaren Signale.

Neue direkt aktive Personen bleiben bis Rootadmission verborgen. Deferredpersonen
bleiben Known ohne RuntimeRegistry/Ground; deklarierte Clients erhalten nur
verborgene Visualbindings. Gepufferte Auswahl gehört zur konkreten Rootinstanz,
Registry, Leader, Kontext und den bei Aufnahme vorhandenen Actorleben. Ein
Ownerwechsel darf sie nicht in einer neuen Mission anwenden. Der Statusleser
meldet applying/queued für die späteren Checkpoint-Stabilitätsgates; er enthält
keine private Bindung und keine zweite Gameplaywahrheit.
