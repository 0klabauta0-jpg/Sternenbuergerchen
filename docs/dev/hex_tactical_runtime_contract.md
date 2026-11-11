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
Höhenfaktor erhalten. Legacyregeln bleiben getrennt. Ein konkret skillabhängiger
Bewegungsschussabzug ist in diesem Damagepfad noch nicht nachgewiesen; vorhandene
Skill-/Attackbonuswerte bleiben bestehen. Dessen genaue Balance bleibt vor
Aktivierung der AP5-Bewegung ausdrücklich offen, kein neuer Wert wird behauptet.

Keine Karte ist aktiviert. Aktive Bewegung, Zulassung/Lifecycle und Save-/
Netzpfade bleiben AP5–8; die großen Szenen-/Leistungsabnahmen AP9 folgen später.

## Rampen und offene Anbindung

Gemeinsamer Rampenvertrag: längs H/H+1, seitlich H+0,5 nur bei passenden
Rampennachbarn, StandhöheH+0,5. Breiten-/Eck-/Editorregeln stammen aus dem
Terrainowner; `allows_registry_step` ist nach beiden Registrygates das gemeinsame
Runtime-Tor, `allows_step` behält seine Authoringdefaults.

Noch offen: aktive Ausführung AP5, Lifecycle/Save/Netzwerk AP6–8.
Ein Datenindex ersetzt nicht die aktive Bewegung oder Minimum-Spacing.
Große AP9-Abnahmen bleiben später; keine gemessene FPSverbesserung.
