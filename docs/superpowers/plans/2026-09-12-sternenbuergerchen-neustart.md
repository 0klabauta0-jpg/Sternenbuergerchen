# Sternenbürgerchen: Neustart – Entscheidungs- und Entwicklungsplan

> **Für ausführende Agenten:** Nach dem Review diesen Plan mit `superpowers:subagent-driven-development` oder `superpowers:executing-plans` abschnittsweise umsetzen. Die offenen Entscheidungen in N0 zuerst klären. Die Checkboxen markieren zukünftige Arbeit; keine ist ein Nachweis bereits implementierter Software.

**Ziel:** Als Commander mit zwei Leuten und kleinen Aufträgen beginnen und eine eigene Organisation mit Crew, Ausrüstung, Werkstatt, Schiffen sowie Boden- und Raumoperationen aufbauen.

**Architektur:** Empfohlen wird ein neues, minimales Godot-Projekt. `SimulationRoot` ist dessen einzige Mutationsstelle; überschaubare Fachsysteme lesen denselben Zustand und liefern Änderungen zur zentralen Verarbeitung. Das Altprojekt bleibt Referenz für nachweislich nützliche Daten, Assets und Erfahrungen.

**Technik:** Godot, GDScript, räumliche Darstellung mit taktischer Commander-Kamera, Kenney als Asset-Grundlage. Die konkrete Engineversion wird in N0 entschieden.

**Spec:** [Analyse, Spielvision und Entscheidungs-Workbench](../../reports/STERNENBUERGERCHEN_NEUSTART_2026-09-12.html).

**Stand:** 12.09.2026. Dies ist ein überprüfbarer Entwurf für den Neustart. Der aktuelle Auftrag umfasst Analyse, Plan und HTML. Er erzeugt weder ein neues Spielprojekt noch neue Runtime-Funktionen; die Produktumsetzung folgt nach dem Review.

## 1. Was wir aufbauen

Der Spieler führt eine kleine Organisation. Er nimmt Aufträge an, entscheidet über Personal, Ausrüstung und Transport und gibt Teams sowie Schiffen verständliche Befehle. Besatzungen führen diese aus. Geld, geborgene Gegenstände, Rohstoffe, Blueprints und Erfahrung erweitern nach und nach die Möglichkeiten.

Der erste Erfolg soll eine abgeschlossene kleine Geschichte sein: Zwei Leute bergen etwas aus einem abgestürzten Satelliten, bringen es nach Hause und können sich danach etwas leisten oder herstellen. Die bisherige große Außenpostenoperation wird ein späterer Höhepunkt dieser Entwicklung.

Der verbindende Kreislauf lautet: Auftrag wählen → Crew und Fracht vorbereiten → reisen → erkunden, kämpfen oder arbeiten → Beute sichern → zurückkehren → Ergebnis verbuchen → Crew und Betrieb verbessern.

### Herkunft der Idee

- **Alt-GDD, März 2026:** Commander und Teamleiter; lebendige NPCs; Raum, Orbit, Atmosphäre, Boden und Innenräume; Schiffe mit Arbeitsplätzen; Wirtschaft, Bergung, Forschung, Rekrutierung und Organisationsalltag.
- **Originalwunsch vom 19.07.2026:** Klein anfangen wie bei XCOM; bessere und größere Missionen; Blueprints aus Missionen, Rohstoffe durch Mining, Waffen und Ausrüstung in der Basis herstellen; Forschungsstation und Hangar, optional ein Basebuilder. Eine Echtzeitorganisation nach dem Gedanken von KlabsCom/Tactical Suite; außerhalb der Kamera weiterrechnen.
- **Aktueller Auftrag:** Einstieg als Zweierteam, Mini-Bunker und Satellitenbergung; wachsende Crew mit Bewerbern; Raumkampf, Transport, Mining, Bergung und Hauling am Boden und im Raum; zwei bis drei große Planetenoberflächen; Kenney-Grundlage mit schönerer Landschaft.
- **Im aktuellen Gespräch bestätigt:** Der Spieler bleibt Commander für Teams und Schiffe.
- **Planvorschläge:** Die folgenden Ausbaustufen, Mengen, Schiffsrollen, Darstellungsvereinfachungen und Balancewerte sind konkrete Empfehlungen, soweit sie nicht oben als Nutzerwunsch bezeichnet sind.

## 2. Grenzen und Entscheidungen

- Der Neustart löscht, bereinigt oder überschreibt das bestehende Projekt nicht. Keine Arbeit direkt auf `main`; dieser Bericht liegt in einem eigenen Worktree von `integration/core-foundation`.
- Das neue Projekt erhält vor der Umsetzung eigene kurze Regeln, einen eigenen Zielpfad und eine eigene überprüfbare Startversion. Die alten 1.200 Aufgaben werden nicht automatisch sein Backlog.
- Bestehende Module sind weder pauschal kaputt noch automatisch geeignet. Jede Übernahme braucht eine konkrete Verwendung und eine kleine Prüfung im neuen Zusammenhang.
- Produktcode liegt in Produktverzeichnissen. Tests bedienen öffentliche Spielwege und enthalten keine für das ausgelieferte Spiel erforderlichen Controller.
- Geld, Fracht, Ausrüstung, Erfahrung und Missionsabschluss werden zentral und genau einmal verbucht. Anzeigen und Animationen dürfen keine Belohnungen auslösen.
- Alle Personen, Schiffe und besuchten Weltinstanzen haben stabile IDs. Ein Szenenwechsel erzeugt keine neuen Versionen derselben Crew oder Ladung.
- Außerhalb der Kamera läuft dieselbe Welt mit passendem Aktualisierungstakt weiter. Wegsehen stoppt weder Gefahr noch Reparatur oder Reise; Anzeigen erzeugen keinen Simulationsfortschritt.
- Sichtbarer Fortschritt, Dauer, Kosten, Cargo-Grenzen und Abbruchfolgen gehören in die Spieloberfläche. Technische Diagnostik bleibt im Entwicklungsbereich.
- Kein Zeitversprechen. Eine Stufe folgt erst, wenn ihr Spielweg verständlich ist und ihre Abnahme besteht.

| Entscheidung | Zeitpunkt | Empfehlung | Warum vor Umsetzung nötig |
| --- | --- | --- | --- |
| Engineversion | Vor N0-Umsetzung | Eine festgehaltene Godot-Version mit passendem Export und Pluginstand | Nutzer-AGENTS nennt 4.6.1, integrierte Dokumentation 4.6.2; keine stillschweigende Gleichsetzung |
| Bedeutung von „zu zweit“ | Vor N1 | Zunächst zwei Crewmitglieder in einer Singleplayer-Organisation | Zwei menschliche Koop-Spieler benötigen zusätzliche Ownership- und Netzwerkpfade |
| Erstes Schiff | Vor N1 | Nutzbares geliehenes oder gepachtetes Shuttle mit kleinen Kosten | Eigenes erstes Schiff kann ein Fortschrittsziel werden; Eigentum und Verlustfolgen müssen konsistent sein |
| Basis | Vor N3 | Sichtbare Ausbauslots für Werkstatt, Lager, Hangar; räumlicher Basebuilder als spätere Entscheidung | „Aufbauen“ kann Organisation, Einrichtungen oder freie Gebäudeplatzierung bedeuten |
| Verlust und Rettung | Vor N1 | Verletzung, Bergung, Reparatur und erklärbare Rückkehrkosten; eine neue Kampagne darf nicht dauerhaft feststecken | Alte unbegrenzte Respawns und neue Ressourcenprogression passen nicht automatisch zusammen |
| Weltverbindung | Vor N4 | Große zusammenhängende Regionen mit klaren Übergängen zu Orbit und Innenräumen | Kontinuierlicher Flug durch sämtliche Atmosphärenschichten wäre ein eigenes Großsystem |
| Echtzeit und Befehlsplanung | Vor N1 | Echtzeit ohne Pause als historische Arbeitsannahme, mit gut lesbarer Planung; Änderung ausdrücklich festhalten | Alte „ohne Pause“-Regel muss zur neuen Kampagne und späterem Koop passen |

N0 erfasst alle offenen Punkte, entscheidet aber zunächst nur die für den nächsten Spielweg benötigten. Basis und Weltverbindung bleiben bis zur jeweiligen Stufe explizite Arbeitsannahmen. Weitere Fragen zu Atmosphäre, Stil, Größe, Koop und PvP stehen in der HTML-Workbench.

## 3. Arbeitsbasis und Dateiverantwortung

**Vorschlag:** Ein separates Projekt neben dem Altprojekt, beispielsweise `C:\dev\SternenBuergerchen-Neustart`. Dieser Pfad ist noch nicht angelegt und wird in N0 festgelegt. Der Bericht-Worktree bleibt Dokumentation, nicht ein versteckter zweiter Spielstart.

Für den ersten Spielweg genügen die folgenden Bereiche. Weitere Dateien entstehen erst durch eine tatsächlich benötigte Verantwortung.

| Künftiger Pfad relativ zum neuen Projekt | Verantwortung |
| --- | --- |
| `project.godot`, `scenes/game.tscn` | Ein eindeutiger Produktstart und Verdrahtung |
| `scripts/core/simulation_root.gd` | Commands prüfen, Tick ausführen, Effekte und Zustandswechsel committen |
| `scripts/core/world_state.gd` | Autoritative Kampagne: IDs, Crew, Aufträge, Fracht, Geld, Weltinstanzen |
| `scripts/core/save_store.gd` | Versionierten Zustand atomar speichern und vollständig laden |
| `scripts/crew/crew_system.gd` | Verfügbarkeit, Aufgaben und spätere Entwicklung aus Zustand ableiten |
| `scripts/contracts/contract_system.gd` | Annehmen, Ziele, Rückkehr, Abbruch und einmaligen Abschluss auswerten |
| `scripts/economy/economy_system.gd` | Frachtkapazität, Besitzwechsel, Bezahlung und Blueprint-Freischaltung |
| `scripts/world/world_system.gd` | Ortswechsel, Reisen, Weltinstanz-IDs und Zeitschritte koordinieren |
| `scripts/ground/ground_order_system.gd` | Teamauftrag in Bewegung, Warten, Bergen und Rückkehr zerlegen |
| `scripts/ground/ground_view.gd`, `scenes/ground/satellite_site.tscn` | Bodenkarte, Figuren, Auswahl und reine Zustandsdarstellung |
| `scripts/ui/commander_screen.gd`, `scenes/ui/commander_screen.tscn` | Auftrag, Crew, Cargo, Befehle und Ergebnis lesbar darstellen |
| `data/contracts/satellite_recovery.json` | Ein vollständiger Auftrag mit Zielen und Ergebnisregeln |
| `data/items/starter_catalog.json` | Kleine Menge benannter Gegenstände, Blueprint und Kapazitätswerte |
| `assets/curated/`, `assets/credits.md` | Nur verwendete Assets, Herkunft und Nutzungsnachweise |
| `tests/satellite_recovery_flow.gd`, `tests/save_reward_integrity.gd` | Echter erster Spielweg, Save-Roundtrip und doppelte Abschlussanfragen |

`Crew`, `Contracts`, `Economy`, `World`, später `GroundCombat` und `Space` sind fachliche Verantwortungen innerhalb desselben Simulationskerns. Sie lesen State und liefern Ergebnisdaten beziehungsweise Effekte. Nur `SimulationRoot` schreibt den gemeinsamen Zustand. Registries liefern Lookup; Event-Signale informieren nach einem Commit.

Ein Command enthält eine eindeutige Anforderungs-ID, den Befehlstyp, die IDs der handelnden Crew beziehungsweise des Schiffes, das Ziel und gegebenenfalls die Auftragsinstanz. Ein Ergebnis benennt Annahme oder Ablehnungsgrund. Ereignisse tragen stabile IDs. Diese Datenform wird in N0 knapp fixiert; für entfernte Zukunftssysteme werden hier keine APIs erfunden.

## 4. N0 – Neustartgrundlage beschließen

**Ergebnis:** Eine kurze freigegebene Zielbeschreibung und anschließend ein leeres, startbares Produktprojekt mit einem Simulationskern. Noch kein Großweltbau.

- [ ] Die Entscheidungszeilen aus Abschnitt 2 im HTML durchgehen; unmittelbar vor N0/N1 benötigte Antworten in die neue Kurz-Spec übernehmen und spätere Entscheidungen als Arbeitsannahmen markieren.
- [ ] Zielpfad, Godot-Version, Startszene, Branchstrategie und die Grenze zum Altprojekt festhalten.
- [ ] Die N1-Dateiverantwortungen auf den einfachsten realen Spielweg reduzieren; ein bis zwei Seiten Regeln für Commands, IDs, Save und Assets genügen.
- [ ] Einen Landschaftsausschnitt als Stilreferenz auswählen: Kenney-Silhouetten, sorgfältige Höhenformen, abgestimmte Materialien, Licht, Vegetation und lesbare Wege.
- [ ] Eine kleine technische Größenprobe entwerfen: mehrere Weltbereiche, begrenzte sichtbare Ausschnitte und dieselben simulierten Einheiten bei bewegter Kamera. Messgrößen sind Framezeit, Simulationszeit, Ladezeit und Speicher.
- [ ] Erst im später beauftragten Ausführungsschritt das neue Projekt erzeugen, einen echten Fensterstart und sauberen Exit prüfen.

**Done-Gate:** Version und Regeln widersprechen sich nicht; genau ein Produktstart; kein benötigter Produktcode unter `tests`; Stilreferenz und messbares Größentest-Szenario sind benannt.
**Risiko/Stop:** Ohne geklärte Spielidentität keine teure Übernahme des alten UI-/Runtime-Gerüsts. Ein Größenproblem führt zu einer kleinen Technikprobe, nicht zu einer fertigen riesigen Landschaft.
**Abhängigkeit:** Review dieses Entwurfs. **Nicht enthalten:** vollständige Welt, Multiplayer, historische Testmigration.

## 5. N1 – Zwei Leute bergen einen Satelliten

**Ergebnis:** Der erste vollständige, wiederholbar spielbare Auftrag von Annahme bis sichtbarem Fortschritt. Transport ist zunächst ein erklärter Übergang mit Dauer und Zustandswechsel; er täuscht keinen fertigen Raumkampf vor.

- [ ] Zwei benannte Crewmitglieder, kleine Anfangsausrüstung, einen Bergungsauftrag und einen erreichbaren Absturzort anlegen.
- [ ] Im Commander-Bildschirm Auftrag, Ladekapazität und Rückkehrziel zeigen; Annehmen und Starten als Commands senden.
- [ ] Die Crew über den echten Ortswechsel am Landeort eintreffen lassen; Bewegung, Bergungsauftrag und Rückkehr befehlen können.
- [ ] Bergen mit Nähe, Dauer und begrenzter Fracht verbinden. Bei vollem Laderaum einen verständlichen Grund anzeigen; kein stiller Besitzwechsel.
- [ ] Die Rückkehr und Abgabe genau einmal mit Geld und einem Blueprint belohnen. Der Blueprint ist zunächst eine klar erklärte Freischaltung für die spätere Werkstatt.
- [ ] Abbruch vor der Bergung und Rückzug mit bereits geladener Fracht als ausdrückliche Ergebnisfälle behandeln; die in N0 beschlossenen Kosten und Eigentumsregeln anzeigen.
- [ ] Speichern vor Start, unterwegs, nach Bergung und nach Auszahlung; nach Neustart denselben Auftrag, dieselbe Crew und denselben Besitz wiederherstellen.

**Done-Gate:** Ein Spieler schafft den Weg im echten Fenster ohne Debug-Abkürzung. Wiederholter Abgabebefehl und Reload nach Auszahlung erzeugen kein zusätzliches Geld, keine zweite Ladung, keine zweite Freischaltung und keine doppelte XP-Vergabe. Abbruch erlaubt einen neuen Auftrag. Der Weg benötigt keine Konsole.
**Risiko/Stop:** Wenn nur einzelne Menüs oder Bergungsanimationen funktionieren, ist N1 offen. Erst den Kreis schließen; keine zweite Welt und keine weiteren Berufe ergänzen.
**Abhängigkeit:** N0. **Prüfung:** `satellite_recovery_flow.gd`, `save_reward_integrity.gd`, ein dokumentierter Fensterdurchlauf mit Commit und Buildversion.

## 6. N2 – Der kleine Bunker funktioniert als Taktikspiel

**Ergebnis:** Ein kurzer Auftrag für zwei bis vier Crewmitglieder, mit Gegnerkontakt, verständlichen Teamentscheidungen und möglicher Rettung beziehungsweise Rückkehr.

- [ ] Einen kleinen Bunker mit lesbarem Zugang, wenigen Räumen, Deckung und einem eindeutigen Missionsziel bauen.
- [ ] Bewegen, Sichern, Ziel angreifen beziehungsweise Auftrag ausführen und Rückzug als kleine Commander-Befehlspalette anbieten.
- [ ] Sichtkontakt und Bedrohung ehrlich anzeigen; Teammitglieder reagieren nachvollziehbar auf Deckung, Feindkontakt und unterbrochene Aufträge.
- [ ] Verwundung, Rettung eines Kameraden und Rückzug in den bestehenden Auftrags-/Fracht-/Save-Kreis einbinden.
- [ ] Mindestens zwei taktische Möglichkeiten spielen: vorsichtiger Zugang und direkter Vorstoß; Auswirkungen sollen sichtbar sein.

**Done-Gate:** Erfolg und Abbruch laufen über denselben Produktweg; Befehlsannahme, Bewegung, Kontakt, Treffer, Verwundung und Rückzug sind im Fenster erkennbar. Ein verdeckter Gegner wird durch bloßes Kameraschwenken nicht bekannt.
**Risiko/Stop:** Unlesbare KI oder Wegfindung vor neuen Waffen und Gegnerklassen lösen. Kein komplexes Doktrinsystem, kein Soldaten-Mikromanagement.
**Abhängigkeit:** N1. **Prüfung:** Ein kleiner Szenariotest für Kontakt/Deckung/Rettung plus derselbe Save-/Belohnungscheck wie N1 und ein echter Bunkerdurchlauf.

## 7. N3 – Crew und Werkstatt wachsen

**Ergebnis:** Der erste nachvollziehbare Aufstieg von zwei über vier zu sechs Leuten; Geld, Blueprints und Material bilden einen gemeinsamen Fortschrittskreis.

- [ ] Bewerber nach nachvollziehbaren Erfolgen beziehungsweise Rufschritten anbieten; Fähigkeiten, Rolle und laufende Belastung verständlich zeigen.
- [ ] Rekrutierung, Teamzuordnung, Training durch Einsatz und Erholung dauerhaft speichern. Die Stufen 2 → 4 → 6 sind ein Balancingvorschlag.
- [ ] Eine Werkstatt mit wenigen Rezepten öffnen: Blueprint + Material + Kosten + Herstellungsdauer ergeben einen konkreten Gegenstand.
- [ ] Rohstoffe zunächst kaufbar machen, damit die Herstellung vollständig spielbar ist, bevor das Mining hinzukommt.
- [ ] Lager, Werkstatt und Hangar als begrenzte Ausbauslots mit sichtbar neuer Funktion umsetzen; noch keine freie Gebäudeplatzierung.

**Done-Gate:** Ein Missions-Blueprint ermöglicht eine hergestellte Ausrüstung, die im nächsten Auftrag wirklich wirkt. Material, Geld und Auftrag werden einmalig abgezogen; Reload oder wiederholter Fertigungsabschluss duplizieren nichts. Ein neuer Rekrut erscheint als dieselbe Person im Einsatz.
**Risiko/Stop:** Ein weiteres Inventarmenü ohne Nutzen im Einsatz erfüllt die Stufe nicht. Preise, Unterhalt und Wartezeiten erst an wenigen realen Durchläufen abstimmen.
**Abhängigkeit:** N2. **Nicht enthalten:** große Forschungsketten, zufällige Drama-Decks, komplexer Basebuilder.

## 8. N4 – Der frühe Beweis für das Weltraumspiel

**Ergebnis:** Ein befohlenes Schiff mit Pilot und Techniker erreicht ein Orbitwrack, dockt an, birgt Ladung und bringt sie in dieselbe Wirtschaft zurück.

- [ ] Ein kleines Arbeitsschiff mit benannten Crewposten und einem begrenzten Orbitalgebiet einführen.
- [ ] Anfliegen, Position halten, andocken, bergen und zurückkehren als Commander-Aufträge umsetzen.
- [ ] Pilotierung und Technik an je einer klaren Wirkung zeigen, etwa Anflugzeit und Bergungs-/Reparaturdauer; keine verdeckten Bonusstapel.
- [ ] Schiff, Besatzung, Wrackressourcen und Cargo über die bestehenden IDs, Aufträge und Save-Daten führen.
- [ ] Kamerawechsel zwischen Boden-/Stationsübersicht und Orbit prüfen, während Reise oder Arbeit weiterläuft.

**Done-Gate:** Der Raumauftrag zahlt in denselben Besitzstand ein wie N1. Ein Reload am Wrack verändert weder Besatzung noch Fracht; wiederholtes Andocken erzeugt keine Ressourcen. Ein fehlender erforderlicher Posten erklärt, weshalb ein Auftrag nicht startet.
**Risiko/Stop:** Wenn für Raum eine zweite Wirtschaft oder neue Crewkopien nötig werden, zuerst den gemeinsamen Vertrag korrigieren. Die große Karte wartet bis dieser Beweis steht.
**Abhängigkeit:** N3. **Nicht enthalten:** Raumkampf, echte Schiffsinnenräume, vollständige Planetenflugphysik.

## 9. N5 – Mining, Bergung und Hauling tragen die Organisation

**Ergebnis:** Drei verschiedene Tätigkeiten mit echten Entscheidungen, Kosten und Risiko, am Boden und im Raum über denselben Auftragsrahmen.

- [ ] Boden- und Orbitvorkommen erkunden, geeignetes Werkzeug auswählen, begrenzte Rohstoffmenge fördern und einladen.
- [ ] Bergung als Auswahl zwischen Wert, Aufwand, Zustand und Transportkapazität ausbauen; Wracks liefern begrenzte Gegenstände oder Material.
- [ ] Hauling-Aufträge mit Abholung, Frachtbesitz, Route, Kapazität, Abgabe und ausdrücklicher Verlustfolge anbieten.
- [ ] Mindestens ein Risiko pro Beruf durch das tatsächliche Spiel erzeugen, beispielsweise gefährlicher Weg, beschädigtes Wrack oder bedrohte Transportstrecke.
- [ ] Rohstoffgewinnung mit N3-Rezepten verbinden; Wirtschaft auf wiederholbare sichere Geld-/Materialschleifen prüfen.

**Done-Gate:** Material kann durch Mining gewonnen, transportiert und verbaut werden. Bergung bietet eine andere Entscheidung als Mining; Hauling verlangt korrekte Lieferung. Abbruch, Reload und Wiederbesuch füllen geleerte Quellen nicht unbegründet auf.
**Risiko/Stop:** Drei Fortschrittsbalken mit anderem Namen genügen nicht. Erst je eine lohnende Ausführung, dann neue Rohstoffsorten.
**Abhängigkeit:** N4. **Nicht enthalten:** vollständig simulierte globale Börse, unbegrenzte Verfahrensketten.

## 10. N6 – Kleine Flotte, verständlicher Raumkampf

**Ergebnis:** Wenige unterschiedliche Schiffe erfüllen echte Rollen und verbinden Crewführung, Kampf, Arbeit und Transport.

- [ ] Zwei bis drei Kampf-/Arbeitsschiffmuster plus ein bis zwei Transportmuster als Vorschlag abgleichen: leichter Jäger, robuster Mehrzwecker, Arbeitsschiff; Shuttle und Frachter.
- [ ] Raumkampf zuerst in einem begrenzten taktischen Raum mit 2.5D-/Höhenbändern erproben; Annähern, Abstand halten, angreifen, schützen und Rückzug befehlen.
- [ ] Besatzung, Ausrüstung und Schaden an wenigen lesbaren Werten wirksam machen; Reparatur und Recovery in den vorhandenen Betrieb einbinden.
- [ ] Eine Eskorte und eine Abfangmission bauen; ein beschädigtes Schiff kann je nach beschlossener Verlustregel gerettet oder geborgen werden.

**Done-Gate:** Unterschiedliche Schiffe verlangen unterschiedliche Entscheidungen. Crewposten haben erkennbare Wirkung; Fracht- und Kampfschiff kooperieren. Save/Load, Rückzug und Schiffsverlust erhalten konsistenten Besitz und Mannschaftsstatus.
**Risiko/Stop:** Falls Höhenbänder taktisch unklar sind, vor weiteren Schiffen die Darstellung überarbeiten. Keine sechs Freiheitsgrade, Großkampfschiffe oder Innenraumsimulation voraussetzen.
**Abhängigkeit:** N5. **Prüfung:** Reproduzierbare Eskorte mit zwei Ausgangslagen, Verlust-/Rettungsfall und sichtbarer Commander-Bedienung.

## 11. N7 – Große Landschaft mit sinnvollen Wegen

**Ergebnis:** Eine erste große zusammenhängende Region mit wiedererkennbaren Orten und mehreren Auftragsarten; danach ein zweiter Planet, ein dritter als optionales Ziel.

- [ ] N0-Größenprobe mit den wirklichen Crew-, Schiffs- und Berufssystemen wiederholen; sichtbare Region und logisch laufende Welt getrennt messen.
- [ ] Streaming, Weltinstanz-Persistenz und Hintergrundsimulation für eine Region bauen; Ressourcen, Schäden und Aufträge bleiben beim Entladen erhalten.
- [ ] Handgebaute wichtige Orte durch Gelände, Reiserouten, Ressourcenfelder und Begegnungsräume verbinden. Größe in Reisegefühl und Entscheidungen bestimmen, nicht nur in Tilezahlen.
- [ ] Landschaft über die freigegebene Stilreferenz gestalten: Formen, Höhen, Felsen, Bodenfarben, Vegetation, Licht und klare Silhouetten; Kenney-Assets gezielt einbetten.
- [ ] Erst nach einem guten vollständigen Spielweg Planet zwei mit eigener Geografie und wirtschaftlichem Grund zum Reisen anlegen; Planet drei benötigt einen zusätzlichen spielerischen Zweck.

**Done-Gate:** Längerer echter Fensterlauf mit Reisen, Aufträgen, Save/Load und Kamerawechsel; keine verlorenen Personen oder Ressourcen. Dokumentierte Messung auf festgehaltener Hardware/Version besteht die in N0 beschlossenen Budgets. Off-map-Fortschritt entspricht denselben fachlichen Regeln wie vor der Kamera.
**Risiko/Stop:** Leere Kilometer und steigende Ladezeiten sind kein Fortschritt. Vor neuem Gebiet erst Dichte, Lesbarkeit und Laufzeit der ersten Region verbessern.
**Abhängigkeit:** N6; technische Vorprobe bereits N0. **Nicht enthalten:** vollständige Kugelplaneten oder unbegrenztes Universum.

## 12. N8 – Die gewachsene Organisation führt die Außenpostenoperation

**Ergebnis:** Die aus dem Altprojekt bekannte kombinierte Mission ergibt sich aus den zuvor erworbenen Fähigkeiten und Mitteln.

- [ ] Auftrag mit Vorbereitung, Transport, Bodenteams, Luft-/Raumsicherung und klarer Rückkehroption anbieten.
- [ ] AA ausschalten, Station öffnen, Computer sichern und Frachtanflug/Abflug decken als zusammenhängende Operation authoren.
- [ ] Aufgaben auf mehrere erfahrene Teams und Schiffe verteilen; Cargo, Material, Verletzungen und Ersatz folgen derselben Kampagne.
- [ ] Erfolg, Teilabbruch und Rettung in derselben persistenten Auswertung abschließen; der Spieler erkennt, warum seine gewachsene Crew diese Mission nun schafft.

**Done-Gate:** Die Operation ist aus einem regulär aufgebauten Spielstand erreichbar und ohne Testteleports abschließbar. Mindestens zwei sinnvolle Einsatzpläne funktionieren; Entscheidungen vor und während der Mission verändern Aufwand und Risiko.
**Risiko/Stop:** Kein Sondermissionssystem bauen, das die bestehenden Berufe, Crew- und Transportregeln umgeht. Für eine gute kombinierte Mission reichen wenige gut verbundene Bausteine.
**Abhängigkeit:** N7. **Bezug:** Historischer Außenposten-Testfall und spätere Station Route; der technische Singleplayer-Default `grid_sweep` ist davon zu unterscheiden.

## 13. Ausbau nach dem tragfähigen Kern

Koop mit geteilten Verantwortungen, PvP, tiefere Beziehungen, Schiffsinnenräume, Forschungsketten und ein räumlicher Basebuilder bleiben sichtbare Ausbaurichtungen. Sie sind keine stillen Voraussetzungen von N1–N8. Für Koop werden gemeinsame Kampagne, Befehlsbesitz und Verbindungsabbruch entschieden; für PvP faire Kräfteverhältnisse und die Rolle mitgebrachter persistenter Crews. Die Architektur hält eine spätere Host-Autorität offen, ohne früh ein vollständiges Netzwerkprodukt zu bauen.

## 14. Prüf- und Arbeitsrhythmus

- Pro Stufe zuerst ihren einen Spielerweg, betroffene Dateien und Ergebnisfälle konkretisieren; danach implementieren. Neue Fragen verändern den nächsten kleinen Abschnitt, nicht rückwirkend sämtliche Dokumentation.
- Prüfungen konzentrieren sich auf echte Risiken: Besitz, Save, einmalige Abrechnung, Befehlsautorität, Abbruch, Weltwechsel und beobachtbares Verhalten. Ein Test darf Erfolg nicht selbst in den Zustand schreiben.
- Erst passende kleine automatisierte Checks, dann echter Fensterlauf. Sichtbarkeit, Spaß und Verständlichkeit brauchen den tatsächlichen Spielweg; ein grüner Strukturtest ersetzt ihn nicht.
- Zu jeder bestandenen Stufe gehören ein kleines Ergebnisprotokoll, der geprüfte Commit, relevante Mess-/Bildbelege und verbleibende Grenzen. Keine übernommene historische Grünmeldung als neue Verifikation verwenden.
- Kleine fachliche Commits; nur relevante Dateien stagen. Altprojekt und fremde WIP bleiben erhalten. Integration und Veröffentlichung sind eigene klar bezeichnete Schritte.

## 15. Quellen und Einordnung

- Lokales `C:\dev\SternenBuergerchen\sternenbuerger-gdd.docx`, GDD v0.1, März 2026: Kapitel 1–6 und 8–9. Historischer Entwurf, kein aktueller Runtime-Vertrag.
- Originalnachricht vom 19.07.2026, 19:15 UTC, lokaler Codex-Verlauf `019f7002-fa09-78a2-b696-51c3b6e2aaac`: Blueprints, Mining, Herstellung, kleine XCOM-Progression, Basisoptionen und Echtzeitorganisation; für diesen Bericht aus dem tatsächlichen Nutzertext rekonstruiert.
- Aktueller Nutzerauftrag vom 12.09.2026 und anschließende Bestätigung der Commander-Rolle.
- `integration/core-foundation:docs/PROJECT_BRIEF.md:12–29`, `docs/DESIGN_NOTES.md:23–44,124–146,173–239`, `docs/GDD_STATUS.md:6–26`: engerer Bodenprototyp und ausdrückliche Einordnung des Alt-GDD.
- `docs/tasks/TASK_236_fireteam_relationship_affinity_and_cohesion.md:4–34`, `TASK_237_mission_progression_xp_morale_frustration.md:4–39`, `TASK_238_personnel_events_recruit_leave_dismiss_notifications.md:15–40`: Beziehungen, Progression und Personalereignisse.
- `data/mission_scenarios/station_route_one_screen_multiplayer_drill.json:110–124,168–200,271–277`: AA, Tür, Computer und Cargo. `scripts/meta/meta_layer_flow.gd:113`: `grid_sweep` als aktueller Singleplayer-Default.
- Die analysierten Code- und Dokumentationsstände begründen diesen Neustartentwurf; die Stufen N0–N8 sind keine Behauptung bereits vorhandener Funktionen.
