# SternenBuergerchen - User-Handbuch

Stand: 2026-05-06

Dieses Handbuch beschreibt den aktuellen spielbaren Stand von SternenBuergerchen aus Spielersicht. Es erklaert, was du im Spiel siehst, welche Aktionen du ausloesen kannst und welche Bereiche noch sichtbar in Arbeit sind.

Merksatz: Die UI zeigt Spielzustand und Rueckmeldungen an. Sie ist nicht die Gameplay-Wahrheit; diese liegt in der Mission, den Fireteams und der Simulation.

## Kurzueberblick

SternenBuergerchen ist ein taktisches Fireteam-Spiel mit Meta-Ebene. Du stellst ein Team zusammen, bereitest es in Homebase und FOB vor, schickst es per Dropship in eine Mission und fuehrst dort Fireteams ueber knappe Befehle.

Der Grundablauf ist:

1. Im Hauptmenue Einzelspieler, Multiplayer, Editor oder Einstellungen waehlen.
2. Ein lokales Roster erzeugen oder laden.
3. In Homebase und FOB Fireteams, Loadout und Transport vorbereiten.
4. Eine Mission starten, Landing Zone sichern und Objectives bearbeiten.
5. Nach der Mission kehren Status, Ausfaelle und Recovery wieder in die Meta-Ebene zurueck.

Du kommandierst nicht jeden NPC als Mikromanagement-Einheit. Du gibst Fireteam Leadern Ziele, Regeln und Prioritaeten. Die Fireteam Leader fuehren diese Befehle innerhalb der simulierten Mission aus.

## Hauptmenue

Das Hauptmenue ist der Einstiegspunkt fuer die Spielmodi.

`Einzelspieler` startet den lokalen Spielpfad mit deinem gespeicherten oder neu erzeugten Roster.

`Multiplayer` fuehrt in Host/Join und Lobby. Der Host bleibt fuer Missionsstart, autoritative Simulation und Gameplay-Snapshots verantwortlich.

`Editor` oeffnet den Map-/Szenario-Workflow. Dort baust du Karten, Terrain, Marker, Spawns und taktische Profile fuer Missionen.

`Einstellungen` sammelt Darstellung, Fenster, Audio, Hilfe und Gameplay-Optionen wie Fog of War.

## Erster Start und Roster

Beim ersten Start wird ein lokales Spielerprofil verwendet. Das Default-Profil heisst `local_player`. Wenn noch kein Roster existiert oder der Save ungueltig ist, erzeugt das Spiel ein neues Startteam und speichert es lokal.

Ein Roster besteht aus NPCs mit Namen, Callsigns, Rollen, Portraits, Skills, Traits und Status. Dieses Roster gehoert zu deinem lokalen Profil. In Multiplayer-Runden wird dein privates Roster nicht automatisch als vollstaendige Wahrheit an andere Peers verteilt.

Ein Reset erzeugt nur nach ausdruecklicher Bestaetigung ein neues Team. Vorhandene Saves werden archiviert, statt still ueberschrieben zu werden.

## Homebase, FOB und Dropship

`Homebase` ist die breitere Meta-Ansicht. Hier siehst du dein Roster, Transfer- und Flightdeck-Informationen, Mission Briefs und Character Details.

`FOB` ist die Einsatzvorbereitung. Hier stehen Fireteams, Loadout, Flightdeck, Boarding Status und Actions im Vordergrund.

Das `Dropship` oder ein anderes Air Asset bringt Teams in die Mission. Wenn ein Air Asset verloren oder beschaedigt ist, blockieren Homebase und FOB den naechsten Launch so lange, bis Recovery oder Ersatz wieder bereit ist.

Die festen Drop-Light-Fenster sind fuer Full-HD ausgelegt. Inhalte in den Fenstern duerfen scrollen, aber die Hauptfenster selbst sollen stabil sitzen.

## Mission Map und Missionsstart

Die Mission Map ist die taktische 2.5D-Ansicht. Du siehst Fireteams, Gegnerkontakte soweit sichtbar, Objectives, LZ, Dropship-Marker, Wegpunkte, Area Orders und kurze Statusmarker.

Ein Missionsstart laeuft typischerweise ueber:

1. LZ oder Missionsplan bestaetigen.
2. Dropship anfordern oder halten.
3. Fireteams deployen.
4. Fireteams auswaehlen und Befehle setzen.
5. Objectives sichern, halten, einnehmen oder Gegnerdruck beantworten.

Wenn eine Aktion nicht erlaubt ist, zeigt die UI einen kurzen Grund. Beispiele sind fehlende Auswahl, Host-only Multiplayer-Rechte, versteckte Phase-Planung oder ungueltige Ziele.

## Kamera und Auswahl

Die Mission Map ist fuer Schwenken, Zoomen und taktische Uebersicht gedacht. Fireteams und relevante Marker bleiben ueber Snapshots sichtbar, damit Auswahl und Kartenanzeige denselben Missionsstand spiegeln.

Du waehlst Fireteams aus, nicht jede Figur als dauerhafte Einzelsteuerung. Eine einzelne Auswahl aktiviert kurze Zielbefehle und Detailstatus. Mehrfachauswahl erlaubt gemeinsame Zielbefehle und zeigt Plan-/Multi-Kontext.

Gegner-Inspect und Friendly-Befehle sind getrennte Pfade. Ein sichtbarer Gegnerkontakt ist Information und Zielkontext, aber kein direkter Schreibzugriff auf Gegnerzustand.

## Befehle und Fireteam Leader

Die Command Matrix enthaelt kurze Zielbefehle wie `Move`, `Take`, `Defend`, `Engage`, `Secure`, `Recon`, `Withdraw`, `Flank` oder `Clear Target`.

Weitere Regeln liegen im Fireteam-Kontext:

- `Tempo`: wie vorsichtig oder schnell das Fireteam vorgeht.
- `Fire Rule`: wann Feuer eroeffnet oder gehalten wird.
- `Contact Response`: wie Kontakte gemeldet, beantwortet oder ignoriert werden.
- `Cover Priority`: wie stark Deckung bevorzugt wird.
- `Security Mode`: wie das Fireteam Sicherung und Blickrichtung behandelt.

Der Fireteam Leader uebersetzt diese Absicht in Bewegung, Deckung, Kommunikation und Ausfuehrung. Unbekannte oder fehlerhafte Befehlswerte werden sicher normalisiert und diagnostiziert, statt still riskante Werte zu erzeugen.

## Bewegungsstile

Fireteams koennen unterschiedliche Advance Styles nutzen:

`Rush` bedeutet: fitte Mitglieder bewegen sich gemeinsam und kompakt.

`Bounding` bedeutet: eine Gruppe bewegt sich, waehrend eine andere deckt. Die Karte zeigt Bewegungs- und Deckungsgruppe sowie den naechsten Bound.

`Caterpillar` bedeutet: einzelne Mitglieder bewegen sich nacheinander, waehrend der Rest sichert. Die Karte zeigt die laufende Sequenz knapp an.

Details gehoeren in das Selected-Fireteam-Fenster, nicht als lange Textwand ueber die NPCs.

## NPCs, Gegner und Gefechtsverhalten

Friendly- und Enemy-NPCs halten autoritativ einen Mindestabstand. Sie sollen nicht sichtbar ineinander stapeln, auch nicht bei Deploy, Respawn, Engpaessen oder Kontaktstop.

Downed-, Bleedout- und Respawn-Units belegen weiter Raum. Wenn eine Karte zu eng ist, erzeugt das Spiel Diagnose statt eine Figur still auf nicht begehbares Terrain zu schieben.

Gegner haben taktische Profile. Sie koennen Deckung suchen, Sicherheitsrichtung nutzen, LOS und Reichweiten beachten und je nach Profil vorsichtiger oder aggressiver vorgehen.

Gefechtsrichtung, Sichtlinie, Deckung, Hoehe und Terrain beeinflussen die Situation. Kartenlabels und UI-Badges zeigen diese Lage an, entscheiden sie aber nicht selbst.

## Waffen, Ausruestung und Gewicht

Aktuelle spielbare Waffen-IDs sind:

- `smg`
- `rifle`
- `sniper`
- `rocket_launcher`
- `medictool`
- `none`

`none` bedeutet keine Waffe. Ein NPC mit `none` in beiden Waffenslots hat keine aktive Kampfwaffe.

`medictool` ist ein Support-Tool, keine Fernwaffe.

`rocket_launcher` ist als grosse Anti-Armor-Waffe sichtbar vorbereitet. Deutsche Begriffe wie Panzerfaust oder Raketenwerfer werden auf die interne ID gemappt.

Gewicht entsteht aus Ruestung und Waffen. Es darf Gameplay-Modifier beeinflussen, aber keine versteckten Items oder dekorativen Visuals in den Spielzustand schmuggeln.

Visual-Loadouts, Previews, Sockets und Modelle sind Darstellung. Reichweite und Kampfwerte kommen aus den Weapon-/Loadout-Daten.

## Spezialrollen und Medic-Regeln

Rollen wie Leader, Medic, Pilot oder Engineer helfen dir, Fireteams zu lesen und Aufgaben zu planen.

Ein Combat Medic kann mit `medictool` eigene Teammitglieder unterstuetzen. Die Standard-Reichweite ist `tile_range = 1`: Die eigentliche Heilung wirkt nur auf einem orthogonal benachbarten Terrain-Tile. Ein Ziel in zwei Tiles Entfernung wird nicht sofort geheilt; der Medic darf sich aber zu einem begehbaren Nachbar-Tile bewegen.

Teamfremde Ziele werden nicht geheilt. Ohne `medictool` gibt es keinen Medic-Heal.

## Terrain, Hoehen und Deckung

Terrain besteht aus Tiles mit Hoehe, Oberflaeche, Begehbarkeit, LOS-Blockade, Cover und optionalen Objekten.

`height_level` beschreibt die Bodenhoehe. `object_height` beschreibt ein Objekt auf diesem Boden, zum Beispiel Wand oder Fels. Eine Wand auf einem Huegel macht den Huegel nicht hoeher; sie sitzt auf der Huegeloberseite.

Oberflaechen gelten auf jeder Hoehe:

- `ground`: normal.
- `road`: schneller und guenstiger.
- `sand`: langsamer und teurer.
- `rock`: etwas langsamer und teurer.

Hoehenkanten sind bewusst:

- `slope`: begehbarer Hoehenuebergang mit Zusatzkosten.
- `cliff`: harte Blockade bei Hoehendifferenz.
- `none`: nur fuer gleiche Hoehe oder Plateau-Innenbereiche. Bei echter Hoehendifferenz ist das ein Authoring-Konflikt.

Diagonale Bewegung darf blockierte orthogonale Schritte nicht umgehen. LOS liest Terrain- und Objektblocker, Cover kommt aus den Tile-/Objektdaten, und Combat-Hoehenboni nutzen die Bodenhoehe der Unit-Tiles.

## Fog of War und Sichtmodi

Fog of War trennt drei Dinge: bekanntes Terrain, aktuelle Sicht und letzte bekannte Kontakte.

Verfuegbare Modi:

`off`: Kein unbekanntes Terrain durch FoW. Normale Debug-/Gameplay-Regeln gelten.

`known_terrain`: Das Terrain ist lesbar, aber dynamische Ziele und Gegner folgen aktueller Sicht oder letzten bekannten Kontakten. Das ist der Default.

`unexplored_blackout`: Sichtbare Tiles sind hell, erkundete Tiles bleiben als Erinnerung sichtbar, nie gesehene Tiles gelten als unbekannt.

Im Multiplayer ist FoW Team- und Peer-bezogen. Clients duerfen versteckte Gegner nicht aus Snapshots rekonstruieren.

## Feedback, Bubbles und Gedanken

Sprechblasen geben kurze Rueckmeldungen, zum Beispiel ACKs, blockierte Befehle, Kontakte oder Warnungen. Sie sind Feedback, keine neue Regelquelle.

Bubble-Modi:

- `Normal`: normale Rueckmeldungen sichtbar.
- `Minimal`: ruhiger, wichtige Warnungen bleiben sichtbar.
- `Aus`: Befehle bleiben spielbar, aber Bubbles erscheinen nicht.

NPC-Gedanken koennen per Halten der entsprechenden Anzeige eingeblendet werden. Sie bleiben auf sichtbare Friendlys begrenzt und sollen keine versteckten Gegnerinfos verraten.

## Help-Popups

Kontext-Hilfe erklaert Controls und Werte, ohne die Fenster zu verschieben. Sie ist eine UI-Hilfe und veraendert keinen Spielzustand.

Help-Modi:

- `off`: keine Hover-Popups.
- `compact`: kurze Hilfe nach stabilem Hover oder Fokus.
- `expanded`: kompakte Hilfe plus Detail nach laengerem Halten oder Pin.

Der globale Help-Button schaltet einen Hilfeblick fuer den aktuellen Screen. Help-Texte erklaeren Spielerbedeutung, nicht interne Klassennamen.

## Audio und visuelle Rueckmeldungen

Audio und VFX begleiten Bewegung, Kampf, UI-Aktionen, Warnungen und Air-Asset-Ereignisse. Das Spiel dedupliziert Events, damit schnelle Eingaben nicht unkontrolliert Sound- oder Effekt-Spam erzeugen.

Explosionen, Warnungen, Funk-/Kommunikationsereignisse und Mapmarker sind Feedback auf Missionszustand. Sie erzeugen nicht alleine Damage, Heal oder Commands.

## Air Assets und LZ-Sicherheit

Air Assets koennen durch Enemy-Anti-Armor-Bedrohungen gefaehrdet werden. Bei passender LOS, Reichweite und niedriger LZ-Sicherheit erscheint zuerst eine Warnung. Danach kann ein weiterer gueltiger Treffer Schaden oder Verlust ausloesen.

Ein Verlust fuehrt zu sichtbarer Kommunikation, VFX/SFX, Debrief-Status und Recovery in Homebase/FOB. Das soll erklaeren, warum ein Launch blockiert ist und wann Ersatz oder Reparatur wieder bereit wird.

## Multiplayer

Multiplayer V1 ist host-autoritativer Host/Join-Spielbetrieb.

Der Host:

- startet die Lobby und Mission.
- validiert Commands.
- haelt Simulation und Snapshots autoritativ.
- entscheidet, welche Maps und Szenarien gespielt werden.

Joiner:

- koennen Befehle nur innerhalb ihrer Rolle und Zuweisung senden.
- wenden Snapshots als Anzeigezustand an.
- duerfen keinen direkten Damage-, Heal-, AirAsset- oder Runtime-State setzen.

Editor-Maps werden vor der Mission ueber ein Manifest abgeglichen. Wenn eine Map fehlt oder der Hash anders ist, fragt die Lobby nach Zustimmung. Map-Download ist nie automatisch. Akzeptierte Maps werden in einen sicheren User-Ordner geschrieben, nicht in Projektdateien.

Bekannt: Ein echter Zwei-Instanzen-LAN-Spieltest bleibt ein manueller Check.

## Editor

Der Editor schreibt Karten- und Szenariodaten, nicht laufenden Missionszustand.

Du kannst Terrain malen, Hoehen und Kanten setzen, Oberflaechen wie Sand/Road/Rock verwenden, Waende/Felsen platzieren, Marker setzen und Szenarioelemente vorbereiten.

Wichtige Editor-Regeln:

- Hoehenwerkzeug schreibt `height_level` und `edge_type`.
- Surface-Painting darf Hoehe, LOS, Walkability und Cover nicht still zuruecksetzen.
- Objektplatzierung darf die Gelaendehoehe nicht veraendern.
- Szenarien duerfen LZ, Spawns, Patrols, Objectives und taktische Profile referenzieren, aber keine Live-Runtime-Wahrheit speichern.

Wenn `edge_type = none` bei echter Hoehendifferenz entsteht, ist das ein Authoring-Konflikt und sollte korrigiert werden.

## Einstellungen

Einstellungen betreffen Darstellung, Audio, Hilfe und Gameplay-Optionen.

Typische Bereiche:

- Fenster und Aufloesung.
- Fullscreen, Windowed und VSync.
- Audio-Lautstaerken und Busse.
- Contextual Help Mode.
- Bubble-/Thought-Anzeige.
- Fog-of-War-Modus.

Settings speichern nur bekannte Einstellungswerte. Fremde Roster-, Map- oder AirAsset-Daten werden nicht als Settings uebernommen.

## Troubleshooting

`Ein Button ist deaktiviert`: Pruefe Auswahl, Host-Rechte, Zielkontext und ob die Mission gerade in der passenden Phase ist. Der Tooltip oder die Statuszeile sollte einen kurzen Grund nennen.

`Mein Medic heilt nicht`: Der Medic braucht `medictool`, muss zum eigenen Team gehoeren und orthogonal neben dem Ziel stehen. Bei groesserer Distanz bewegt er sich erst.

`Ein Fireteam laeuft anders als erwartet`: Pruefe Tempo, Fire Rule, Contact Response, Cover Priority, Security Mode und Advance Style.

`Ich sehe Gegner nicht`: Pruefe Fog of War, LOS, Terrainblocker und letzte bekannte Kontakte. Im Multiplayer zeigt dein Client nur Team-/Peer-erlaubte Sicht.

`Eine Map laedt im Multiplayer nicht`: Pruefe den Consent-Prompt, Hash/Groesse und ob das Manifest gueltig ist. Ohne Zustimmung startet der Client nicht mit einer unbekannten Map.

`Ein Air Asset ist nicht verfuegbar`: Pruefe Debrief, Recovery und Homebase/FOB-Status. Ein verlorenes oder beschaedigtes Asset blockiert den Launch, bis Recovery greift.

`Terrain wirkt falsch`: Pruefe im Editor Hoehe, `edge_type`, `walkable`, `blocks_los`, `cover_value`, `surface_type` und Objektfelder.

## Noch in Arbeit / bekannte Einschraenkungen

Diese Punkte sind bewusst nicht als final poliert versprochen:

- Echter Zwei-Instanzen-LAN-Smoke muss weiterhin manuell gespielt werden.
- Full-HD-Mission-Lesbarkeit braucht Sichtcheck fuer Karte, HUD, Labels und Popups.
- AirAsset-Fairness, Anti-Armor-Haeufigkeit und Loss-Recovery sind integriert, aber Balance bleibt offen.
- Bubble-Laerm, Audio/VFX-Gefuehl und Drag-and-drop-Feeling brauchen echte Spielgefuehl-Checks.
- Cover-/Security-Defaults sind sicher, aber die Unterscheidung zwischen expliziter Spielerwahl und internem Default ist noch ein kleiner Folgepatch.
- Breakout-Diagnosen fuer fehlende oder unbekannte Trigger sind korrekt sicher, aber fuer Debug noch nicht immer ausfuehrlich.
- Statische Architektur-Gates muessen bei neuen Runtime-APIs und UI-Panels gepflegt werden.

## Glossar

`Air Asset`: Dropship oder anderes Luftfahrzeug fuer Insertion, Evac oder Transport.

`Area Order`: Befehl fuer eine Flaeche, zum Beispiel sichern, verteidigen oder einnehmen.

`Cover`: Deckungswert eines Tiles oder Objekts.

`Fireteam`: Kleine Gruppe unter einem Fireteam Leader.

`FTL`: Fireteam Leader. Er fuehrt Spielerabsichten fuer sein Fireteam aus.

`Fog of War`: System fuer bekannte Karte, aktuelle Sicht und letzte bekannte Kontakte.

`FOB`: Forward Operating Base, die direkte Einsatzvorbereitung.

`Homebase`: Meta-Basis fuer Roster, Transfer, Flightdeck und Missionsuebersicht.

`LOS`: Line of Sight, also Sichtlinie zwischen Einheiten oder Punkten.

`LZ`: Landing Zone fuer Dropship oder Air Asset.

`Roster`: Dein lokales Team mit NPCs, Rollen und Status.

`Snapshot`: Read-only Anzeigezustand fuer UI, 2.5D-View oder Multiplayer-Client.

`Terrain Tile`: Eine Kartenkachel mit Hoehe, Oberflaeche, Begehbarkeit, Deckung und Sichtblockade.

## Pflegehinweise

Wenn neue Features spielbar werden, sollten die betroffenen Abschnitte dieses Handbuchs im selben Patch aktualisiert werden. Besonders empfindlich sind Mission Commands, Multiplayer-Grenzen, Editor-Save-Regeln, Settings, Fog of War, Waffen/Loadout, Medic, Terrain und die Liste bekannter Einschraenkungen.

Hilfreiche Wartungsquellen:

- [Projektbrief](PROJECT_BRIEF.md)
- [Architektur](ARCHITECTURE.md)
- [Codex-Regeln](CODEX_RULES.md)
- [Implementierungsstatus](IMPLEMENTATION_STATUS.md)
- [Fog-of-War-Vertrag](dev/fog_of_war_modes_contract.md)
- [Terrain-Hoehenvertrag](dev/terrain_height_hill_rules.md)
- [Loadout-Regeln](dev/loadout_playability_rules.md)
- [Multiplayer-Map-Transfer](dev/multiplayer_editor_map_transfer_contract.md)
- [Contextual-Help-Vertrag](dev/contextual_help_popup_ux_contract.md)
