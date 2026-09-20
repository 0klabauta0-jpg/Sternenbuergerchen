# Sternenbürgerchen — Neustart

## Aktuell N6 · Reise und Fracht

[N6_ACCEPTANCE.md](N6_ACCEPTANCE.md) ist der aktuelle Umfang und Prüfstand: animierte Reise/Systemkarte, Frachtkarten mit Lagerabgabe, Büroterminal, neu angeordnete Bedienung und autoritative Hindernisumwege/Patrouille/Suche. ship.order ist ein streng geprüfter optionaler Zusatz zu Schema5; fehlende alte Felder werden ergänzt. Alte blockierte Flugpositionen werden beim Laden sichtbar korrigiert. Die folgenden N5/N4-Abschnitte bewahren Grundlagen und damalige Ausbaustände. Schiffsinnenräume bleiben geplant und sind nicht Teil von N6.

## Aktuelle Erweiterung N5 · 13.09.2026

N5 liefert neun Reiseziele und vierzehn getrennte Karten: größere Orbit-/Kontaktkarten, drei Bunker mit eigenem Untergrund, freundliches Freihafen und besetztes Knotenwerk. Ein echter Handelsring verbindet Meridian, Freihafen und Staubmarkt. Kenney-Details, terrassierte Felsen/Schluchten, die Entersäbel mit9714 Dreiecken und der kleine Reparaturaufsatz ergänzen den bisherigen Spielkreis.

Schema5 erhält streng geprüfte alte Karrieren über eingefrorene N4-Abhängigkeiten. `regions.gd` vereinheitlicht Welt-/Reise-/Aufzugs-IDs; regionale Preise stammen aus `trade_routes.gd`. Der Host bleibt einzige Autorität; beide Commander führen alle Personen.

Verbindliche Umsetzung, Zahlen, Nachweise und Grenzen: [N5_ACCEPTANCE.md](N5_ACCEPTANCE.md). Aufgabe: [N5_ROUTES_WORLD.md](tasks/N5_ROUTES_WORLD.md). Die nächsten begehbaren Schiffsinnenräume bleiben im anschließenden Ausbau. Alle folgenden N4-/N3-Abschnitte sind historische Stände.


## Aktuelle Erweiterung N4 · 13.09.2026

N4 verbindet gemeinsame Crewführung, echte Einsteigewege, ausdrückliche Reisephasen und persönliche Ausrüstung. Figuren laufen durch Türen und um gemeinsam definierte Möbel-, Fels-, Wand- und Schiffsumrisse. Die Basis behält vier Räume; zwei belegte und vier vorbereitete Betten sind sichtbar, ohne bereits Rekrutierung zu liefern. Die Außenkarten sind mindestens960×960m groß; das Verteilzentrum misst1280×1280m. Alle Karten werden weiterhin einzeln geladen.

Ausgewählte Figuren steigen per Rechtsklick am erreichbaren Schiffszugang ein. Der Kern reserviert freie Plätze nach Fähigkeiten; manuelle Pilot-/Turm-/Passagierzuweisung hat Vorrang. Ein besetzter Pilot und die tatsächlich eingestiegene gesamte Crew sind Voraussetzung zum Abheben. Danach folgen lokaler Flug, ausdrücklicher Orbitaufstieg, Zielwahl auf der Reisekarte, schwebende Ankunft am Kartenrand, Landung und eigener Aussteigebefehl. Reisebegegnungen verwenden einen einmalig gespeicherten, zielabhängigen Wurf. Sieg oder Rückzug setzt die gewählte Reise fort; Niederlage führt zur Notbergung ohne dauerhaften Verlust.

Beide verbundenen Commander dürfen sämtliche Crew, Schiff, Arbeit, Handel und gemeinsame Pause befehligen. Der Host bleibt einzige Simulations-, Sitzungs- und Dateiautorität. Herkunftsfelder an Figuren sperren in Koop keine Befehle. Unbekannte Absender, unzulässige Ziele, fehlende Materialien und doppelte Anfragen werden weiterhin autoritativ geprüft; PvP ist nicht implementiert.

Ein Doppelklick auf das Porträt öffnet ein Dossier mit der tatsächlichen weißen Figur. Fünf Plätze zeigen Helm, Rüstung, Werkzeug, Aufsatz und Rucksack. Drag-and-drop bewegt echte Gegenstände zwischen zulässigen Slots, Basislager, Fracht und persönlichem Rucksack unter Nähe- und Kapazitätsprüfung. Der Rucksack ist kauf-/herstellbar und bietet acht Einzelplätze. Multi-Tool samt Mining-/Salvage-Aufsatz eröffnet Handgewinnung; die Medgun benötigt endliche Med-Ladungen im eigenen Rucksack und heilt oder reaktiviert eine erreichbare Figur. Die erste Blackbox-Bergung bleibt ohne diese neue Ausrüstung möglich.

Schema4 migriert zuerst streng validierte v1/v2/v3-Karrieren unter Erhalt von Beständen, laufender Arbeit, Sitzungsbelegen und freigeschalteten Inhalten. Internet-Koop bleibt die temporäre öffentliche WSS-Lösung, ENet/LAN bleibt verfügbar. Zweiter Haushalt, Langzeitbetrieb und stabile Vermittlungsräume sind eigene Betriebsgrenzen.

Arbeitsbranch: `codex/rostgrenze-crew-reise-ausruestung`. Verbindlicher Vertrag: [N4_CREW_TRAVEL.md](contracts/N4_CREW_TRAVEL.md), Aufgabe: [N4_CREW_TRAVEL_EQUIPMENT.md](tasks/N4_CREW_TRAVEL_EQUIPMENT.md), aktueller Prüfstand: [IMPLEMENTATION_STATUS.md](IMPLEMENTATION_STATUS.md). Der aktuelle N4-Produktdurchlauf besteht mit76/76 Prüfungen; abschließende Steuerungs-/Fenster- und Paketprüfung werden getrennt geführt. Frühere Etappen gelten als historische Abnahmen.

**Vom Nutzer ausdrücklich als nächster Ausbau gewählt:** begehbare Schiffsinnenräume mit Schnittansicht und sichtbaren Wegen zwischen Cockpit, Turm sowie Lade-/Betankungsplätzen. N4 endet bei den Einsteigewegen und abstrahierten Sitzen. Unabhängig gleichzeitig simulierte Regionen, Rekrutierung, tatsächlich baubare Erweiterungsslots, Forschung, volle XP-/Trait-/Beziehungssysteme und PvP bleiben offen.
## Historische Erweiterung N3 · 13.09.2026

N3 erweitert den Aufbau um kauf- und herstellbare Rüstung mit tatsächlichem Schadensschutz, weit auseinanderliegende Mining-/Wrackfundstellen auf der größeren Rostkarte und die nur mietbare Vulture „Geier“ als erreichbares Sparziel. Der Satellit ist nach der Blackbox weiter bis zur Erschöpfung bergbar. Endliche Ressourcen, Geld, Ausrüstung und Mietzeit werden autoritativ und speicherbar geführt.

Bunkeroberfläche mit echter Flak und einfacher Wache, eine per Aufzug getrennt geladene Untergrundkarte, ein großes Verteilzentrum sowie ein eigener kleiner Handelsposten sind spielbare Einsatzorte. Die Oberflächen erlauben lokalen planaren Flug und Landung. Gemeinsame Hindernisrechtecke bilden Laufwege und blockierte Schusslinien ab; zusätzliche Landschaftsdekoration und Figuren-/Schiffskollision sind keine vollständige Physikwelt.

Bodenkampf verursacht Gesundheitsschaden. Rüstung reduziert ihn um 35 %, der aufgearbeitete Helm ergänzt 5 %. Bei null Gesundheit erfolgt nach 20 unpausierten Simulationssekunden eine Rückkehr auf derselben Karte ohne dauerhaften Verlust. Das ist die erste Genesungsregel, noch keine medizinische Evakuierungslogistik. Technik, Pilotieren, Geschützkenntnis und Werkzeugausrüstung wirken konkret; ein XP-/Lernsystem und Traits sind weiterhin offen.

Das Hauptmenü verwendet das erhaltene historische Bildmotiv. Internet-Koop verbindet einen Gast über eine temporäre öffentliche WSS-Einladung mit gegenseitigem Schlüsselnachweis und Schemaabgleich; ENet/LAN bleibt als Alternative. Verfügbarkeit, zweiter Haushalt und spätere Vermittlungsdienste bleiben eigene Betriebsfragen. Pause, Besitzregeln, Save-Migration v1/v2→v3 und Transaktionsschutz bleiben verbindlich.

Arbeitsbranch: `codex/rostgrenze-internet-aussenposten`. Aktuelle Abnahme: [N3_ACCEPTANCE.md](N3_ACCEPTANCE.md). Verbindlicher Kernvertrag: [N3_GROUND.md](contracts/N3_GROUND.md); Charakterwirkung: [N3_SKILLS_MENU.md](N3_SKILLS_MENU.md); Internetbetrieb: [INTERNET_COOP.md](INTERNET_COOP.md). Volle Crewprogression, Beziehungen/Moral, Rekrutierung, baubare Module, Forschung, Raumberufe und PvP sind spätere Entwicklung. Menschliche Spielspaß- und Verständlichkeitstests sind nicht durch technische Abnahme ersetzt.

## Historische Erweiterung N2 · 13.09.2026

Die folgenden Absätze bewahren die damaligen Entscheidungen und Etappennamen. Ihr Umsetzungsstand ist durch N4 oben fortgeschrieben; alte Zukunftsformulierungen sind keine aktuelle Funktionsliste.

Unterkünfte, Lager, Werkstatt sowie Küche/Aufenthalt mit Auftragscomputer erhalten getrennte Räume und einen gemeinsamen Gang. Etwas weiterer Kamerablick, größere Rostlandschaft und freie Andockflächen bereiten späteren Slot-Ausbau vor. Die Werkbank beginnt auf Stufe 1 mit einfacher Herstellung und Reparatur; bessere Maschinen ermöglichen höherwertige Rezepte.

Alle Orte sind **einzeln geladene Karten**. Große lokale Einsatzgebiete ersetzen keinen nahtlosen Planeten. Die größere Handelsstation wird angeflogen; mit Zufallschance unterbricht eine eigene Weltraumkarte die Reise. Raumbewegung bleibt auf einer Ebene. Die lokal vereinfachte Buccaneer heißt Freibeuter; die Entersäbel erhält einen von der zweiten Person bedienten Geschützturm. Radar zeigt zunächst unbekannte Kontakte, die erst in der Nähe identifiziert werden. Alte Crewideen und Charakterbögen bleiben im Gesamtplan erhalten.

Arbeitsbranch dieser Erweiterung: `codex/rostgrenze-raeume-orbit`. Die historische N2-Abnahme steht in `docs/ROOMS_ORBIT_ACCEPTANCE.md`.

## Ursprüngliche Neustartentscheidung N0/N1 · 12.09.2026

Autorisiert durch „Dann leg los“ am 12.09.2026 nach Review 3 des Neustartplans. Neue Projektbasis: `C:\dev\SternenBuergerchen-Neustart`, eigener Branch `codex/neustart-n0-n1`, neue Historie im bestehenden GitHub-Repository; kein Umbau der alten Runtime.

Commander führt zunächst zwei befreundete NPCs aus einer sichtbaren kleinen Rostwelt-Basis. Zwei Betten, Lager, Werkbank und eigenes kleines Shuttle sind der Einstieg. Anklickbare Arbeitsplätze öffnen passende Menüs; geeignete Arbeiter führen die Aufträge dort aus. Satellitenbergung, Geld/Blueprint, Markt, Herstellung, Reparatur und Rückkehr schließen den ersten Spielkreis.

Rostwelt mit Space-Opera-Formen: großzügige Gebiete um einzelne Einsatzorte, entfernte Landung, klare Wege und geschichtete Felsen. Einzelne Karten und sichtbare Reiseübergänge genügen. Kenney ist die Modellbasis.

Nachgereichte Nutzerentscheidung während N1: Den bereitgestellten Cutlass-OBJ in Blender vereinfachen und als lokales Startshuttle „Entersäbel“ einsetzen. Weiße Astronauten mit Helm aus den schöneren Kenney-Figuren ersetzen die bisherigen Blocky-Figuren. Factory-Wände und eine größere Grafiküberholung sind ausdrücklich später dran. Die vom Nutzer bereitgestellte Schiffskonvertierung liegt separat unter dem Git-ignorierten `assets/local/`; reproduzierbares Werkzeug und Herkunftsnachweis werden mitgeführt, ohne aus der Konvertierung eine Veröffentlichungslizenz abzuleiten.

Echtzeit mit Pause in Solo und Multiplayer. Koop und PvP bleiben Kernziele. N1 startet lokal; danach folgt N1a als echter Zwei-Client-Nachweis vor Bunker, Kampf oder breiterem Inhalt. Spätere Etappen N2–N8 umfassen Evakuierung/Respawn, Ausbau/Rekrutierung, Raumberufe, Flotte und große kombinierte Operation.

Quelle: `C:\dev\SternenBuergerchen-worktrees\task-neustart-vision-2026-09-12\docs\superpowers\plans\2026-09-12-sternenbuergerchen-neustart.md`, Review-Commit `375f8d21e`.

Weiterhin gültige Bedienentscheidung: Figuren werden ausgewählt und per Rechtsklick zu einem Laufziel geschickt. Rahmenauswahl für Gruppen; Einzelansicht schaltet Kamerafolge zu. WASD bewegt ausschließlich die Kamera. Die vorübergehend erprobte WASD-Figurensteuerung wurde auf Nutzerkorrektur entfernt.

Bereits in N1 bestätigte Grafikentscheidung: geschlossene Basiswandkontur mit transparenten Frontwänden sowie ein schlankes Strategie-HUD mit Icons, Crewporträts, kurzen Aktionsbeschriftungen und Tooltips. Der Skill `game-ux-design` und konkrete Referenzscreens wurden dafür verwendet; dokumentiert in `docs/UX_DECISIONS.md`.
