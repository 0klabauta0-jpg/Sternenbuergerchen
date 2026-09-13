# Sternenbürgerchen — Neustart

## Aktuelle Erweiterung N3 · 13.09.2026

N3 erweitert den Aufbau um kauf- und herstellbare Rüstung mit tatsächlichem Schadensschutz, weit auseinanderliegende Mining-/Wrackfundstellen auf der größeren Rostkarte und die nur mietbare Vulture „Geier“ als erreichbares Sparziel. Der Satellit ist nach der Blackbox weiter bis zur Erschöpfung bergbar. Endliche Ressourcen, Geld, Ausrüstung und Mietzeit werden autoritativ und speicherbar geführt.

Bunkeroberfläche mit echter Flak und einfacher Wache, eine per Aufzug getrennt geladene Untergrundkarte, ein großes Verteilzentrum sowie ein eigener kleiner Handelsposten sind spielbare Einsatzorte. Die Oberflächen erlauben lokalen planaren Flug und Landung. Gemeinsame Hindernisrechtecke bilden Laufwege und blockierte Schusslinien ab; zusätzliche Landschaftsdekoration und Figuren-/Schiffskollision sind keine vollständige Physikwelt.

Bodenkampf verursacht Gesundheitsschaden. Rüstung reduziert ihn um 35 %, der aufgearbeitete Helm ergänzt 5 %. Bei null Gesundheit erfolgt nach 20 unpausierten Simulationssekunden eine Rückkehr auf derselben Karte ohne dauerhaften Verlust. Das ist die erste Genesungsregel, noch keine medizinische Evakuierungslogistik. Technik, Pilotieren, Geschützkenntnis und Werkzeugausrüstung wirken konkret; ein XP-/Lernsystem und Traits sind weiterhin offen.

Das Hauptmenü verwendet das erhaltene historische Bildmotiv. Internet-Koop verbindet einen Gast über eine temporäre öffentliche WSS-Einladung mit gegenseitigem Schlüsselnachweis und Schemaabgleich; ENet/LAN bleibt als Alternative. Verfügbarkeit, zweiter Haushalt und spätere Vermittlungsdienste bleiben eigene Betriebsfragen. Pause, Besitzregeln, Save-Migration v1/v2→v3 und Transaktionsschutz bleiben verbindlich.

Arbeitsbranch: `codex/rostgrenze-internet-aussenposten`. Aktuelle Abnahme: [N3_ACCEPTANCE.md](N3_ACCEPTANCE.md). Verbindlicher Kernvertrag: [N3_GROUND.md](contracts/N3_GROUND.md); Charakterwirkung: [N3_SKILLS_MENU.md](N3_SKILLS_MENU.md); Internetbetrieb: [INTERNET_COOP.md](INTERNET_COOP.md). Volle Crewprogression, Beziehungen/Moral, Rekrutierung, baubare Module, Forschung, Raumberufe und PvP sind spätere Entwicklung. Menschliche Spielspaß- und Verständlichkeitstests sind nicht durch technische Abnahme ersetzt.

## Historische Erweiterung N2 · 13.09.2026

Die folgenden Absätze bewahren die damaligen Entscheidungen und Etappennamen. Ihr Umsetzungsstand ist durch N3 oben fortgeschrieben; alte Zukunftsformulierungen sind keine aktuelle Funktionsliste.

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
