# Sternenbürgerchen: Neustart – Entscheidungs- und Entwicklungsplan

> **Für ausführende Agenten:** Diesen Plan nach dem Review abschnittsweise umsetzen. N0 klärt nur noch die für den nächsten Spielweg nötigen Details. Checkboxen bezeichnen zukünftige Arbeit, keine bereits implementierte Software. Die Nutzerantworten vom 12.09.2026 ersetzen widersprechende Annahmen der ersten Fassung.

**Ziel:** Als Commander mit zwei bis drei befreundeten NPCs, einer sichtbaren kleinen Basis und wenigen Schiffen eine eigene Raumfahrtorganisation aufbauen. Kleine Aufträge finanzieren Räume, Ausrüstung, Forschung und neue Crew. Boden- und Raumoperationen sowie Koop und PvP gehören zum Kernziel.

**Architektur:** Ein neues, minimales Godot-Projekt mit `SimulationRoot` als einziger Mutationsstelle. Singleplayer und Netzwerkspieler schicken Befehle durch denselben autoritativen Eingang. Das Altprojekt bleibt Referenz für gezielt übernommene Daten, Assets und Erfahrungen.

**Technik:** Godot und GDScript, taktische Commander-Kamera, Kenney als Asset-Grundlage mit ausgearbeiteter Rostwelt-Landschaft. Godot 4.6.2 ist die Nutzerpräferenz für das neue Projekt; N0 prüft den konkreten ausführbaren Pfad. Ein parallel verwendetes 4.6.1-Projekt wird nicht umgestellt.

**Spec:** [Analyse, Spielvision und Entscheidungs-Workbench](../../reports/STERNENBUERGERCHEN_NEUSTART_2026-09-12.html).

**Stand:** 12.09.2026, zweite Fassung nach Nutzerantworten. Der Auftrag umfasst Analyse, Plan und HTML. Weder neues Spielprojekt noch Runtime-Funktionen oder Modellkonvertierungen sind damit bereits umgesetzt.

## 1. Was wir aufbauen

Der Spieler führt Teams und Schiffe als Commander. Eine kleine Freundesgruppe wohnt zunächst in einer bescheidenen Basis auf der marsartigen Rostwelt. Jeder benötigt ein eigenes Bett. Am Anfang reicht ein kleiner Satellitenbergungsauftrag oder Mini-Bunker; später bewältigt die gewachsene Organisation die große Außenpostenoperation aus dem Altprojekt.

Der verbindende Kreislauf lautet: In der Basis vorbereiten → Auftrag wählen → Crew und Fracht verladen → Einsatzkarte laden → erkunden, kämpfen oder arbeiten → zurückkehren → verkaufen, forschen, herstellen und ausbauen. Die Station bietet früh einen einfachen Markt. Die Basis ist ein räumlicher Bedienzugang: Werkbank oder Maschine anklicken, einen verfügbaren geeigneten NPC zuweisen und an dessen Arbeitsplatz das passende Herstellungsmenü öffnen.

Bodenkampf ist ein Teil dieses Spiels. Mining und Bergung finden am Boden und im Weltall statt; Hauling, Raumkampf, Reparatur und Transport verbinden die Tätigkeiten. Erfahrene NPCs können zunehmend umfassende Commander-Aufträge ausführen. Bessere Crew benötigt im PvP mehr Punkte; Koop und faire Gegeneinanderspiele werden früh praktisch nachgewiesen.

### Herkunft der Idee

- **Alt-GDD, März 2026:** Commander und Teamleiter, lebendige NPCs, Schiffe mit Arbeitsplätzen, Wirtschaft, Bergung, Forschung, Rekrutierung und Organisationsalltag.
- **Originalwunsch vom 19.07.2026:** Klein anfangen wie bei XCOM; wachsende Missionen; Blueprints, Mining und Herstellung in der Basis, Forschungsstation und Hangar. Eine außerhalb der Kamera weiterlaufende Organisation.
- **Erster Auftrag vom 12.09.2026:** Kleiner Einstieg, Bewerber und Crew-Wachstum, Boden- und Raumoperationen, wenige Schiffsmuster und eine schönere Landschaft auf Kenney-Grundlage; zunächst zwei bis drei Planeten als Fernziel.
- **Antworten vom 12.09.2026:** Zwei bis drei NPC-Freunde, bewohnbare Basis mit Bauslots, Pause, verzögerter Respawn, Marktstation, geladene Einsatzkarten und zuerst eine Rostwelt. Koop und PvP sind Kernanforderungen. Weitere Planeten folgen bei Bedarf später.
- **Planvorschläge:** Etappen, konkrete Mengen, Preise, Schiffsauswahl und Netzwerkdetails sind Empfehlungen, sofern sie nicht ausdrücklich als bestätigt bezeichnet werden.

## 2. Festgehaltene Entscheidungen und verbleibende Details

| Datum | Thema | Nutzerentscheidung / Status |
| --- | --- | --- |
| 12.09.2026 | Steuerung und Start | Bestätigt: Commander für Teams und Schiffe; zwei bis drei befreundete NPCs. Die genaue Startzahl bleibt ein kleiner Balanceparameter. |
| 12.09.2026 | Basis | Bestätigt: kleiner sichtbarer Ausgangsort von N1 an; Bett je Mitglied; Räume an Verbindern beziehungsweise Slots bauen. Keine beliebige freie Gebäudeplatzierung. |
| 12.09.2026 | Ausbau | Bestätigt: Schlafplätze, Waffenkammer, Forschung, Lager und Herstellung; Bauten kosten Geld/Material, fortgeschrittene Technik gegebenenfalls zusätzlich Blueprints und schaltet neue Möglichkeiten frei. |
| 12.09.2026 | Arbeit in der Basis | Bestätigt: Objekt anklicken, geeigneten NPC zuweisen, am Arbeitsplatz das zugehörige Menü nutzen. Herstellung bindet die Person; ohne Arbeiter oder bei Spielpause stoppt ihr Fortschritt. |
| 12.09.2026 | Verluste | Bestätigt: kein dauerhafter Tod durch Kampf; Respawn nach Wartezeit, danach erneut zum Einsatz transportierbar. Verwundung, Evakuierung und Reparatur sind gewünscht. Andere Abgangsgründe sind noch kein beschlossenes System. |
| 12.09.2026 | Zeit | Bestätigt: Pause. Die alte Annahme „Echtzeit ohne Pause“ gilt für den Neustart nicht mehr. Netzwerk-Pausenregeln bleiben abzustimmen. |
| 12.09.2026 | Wirtschaft | Bestätigt: früher Kauf/Verkauf über eine vereinfachte Raumstation; Blueprints, Materialien und Einrichtungen bilden gemeinsam den Herstellungsfortschritt. |
| 12.09.2026 | Welt | Bestätigt: keine nahtlose Reise nötig; zunächst eine marsartige Rostwelt mit getrennt geladenen Außenposten-, Handels- und Bunkerkarten. Taktische Außenbereiche erlauben weit entfernte Landezonen und Patrouillenumgehung. |
| 12.09.2026 | Raumarbeit | Bestätigt: „in der Luft“ meint Weltall. Große Operationskarten mit Asteroiden suchen, scannen und abbauen; die Crewfähigkeit bestimmt den nötigen Umfang einzelner Anweisungen. |
| 12.09.2026 | Multiplayer | Bestätigt: Koop und PvP sind wichtig; stärkere Crew kostet mehr Einsatzpunkte. Die konkrete Formel und weitere Kostenbestandteile sind offen. |
| 12.09.2026 | Schiffe und Stil | Bestätigt: wenige benötigte Schiffsmuster, Kenney-Grundlage und schönere Landschaft. Die bereitgestellten Schiffsdateien liegen als FBX/OBJ vor; ihre Übernahme setzt geklärte Nutzungsrechte und technische Eignung voraus. |
| 12.09.2026 | Engine | Präferenz: Godot 4.6.2 für den Neustart; vorhandene 4.6.1-Nutzung bleibt unangetastet. Pfade und Versionen vor Projektanlage getrennt prüfen. |

| Noch zu konkretisieren | Zeitpunkt | Arbeitsvorschlag, noch nicht bestätigt |
| --- | --- | --- |
| Startschiff und Eigentum | N0 vor N1 | Gebrauchter kleiner Mehrzwecker für Personen und Fracht; an der beschriebenen Rolle orientiert. Eigenständiger deutscher Name, konkretes Modell, Besitz/Pacht und Reparaturkosten offen. |
| Respawn und Rücktransport | N0 vor N2 | Respawnort, Dauer, Ausrüstungsfolgen und Kosten des erneuten Transports mit einem kleinen Bunkerdurchlauf abstimmen; alte Sekundenwerte nicht automatisch übernehmen. |
| Multiplayer-Pause und Besitz | N0 vor N1a | Host führt die Simulation; synchronisierte Host- oder gemeinsame Pause im Koop, fest vereinbarte Pause im PvP. Kein Spieler friert nur für sich die taktische Zeit ein. Kampagnenbesitz und Befehlsrechte ausdrücklich festlegen. |
| PvP-Punktebudget | N2 | Fähigkeiten zählen wie gewünscht; Schiffe und Ausrüstung zusätzlich zu bewerten ist ein Vorschlag. Budget, Siegziel und mitgebrachte Kampagnencrew konkret festlegen. |
| Kartenausdehnung und Leistung | N0-Probe, N7-Abnahme | Größe aus Anflug, Patrouillenreichweite und sinnvollen Umwegen bestimmen; Zielhardware und Messbudgets festhalten. Kein verpflichtendes 2×2-km-Gebiet. |
| Herkunft der Schiffsmodelle | Vor Modellübernahme | Quellen und Nutzbarkeit des ausgewählten Subsets prüfen. Eindeutschen von Namen klärt die Herkunft oder Nutzungsrechte der Modelle nicht. |

Diese Details blockieren die weitere Planarbeit nicht. N0 entscheidet nur Abhängigkeiten des nächsten Schritts; übernommene Werte bleiben in Daten änderbar.

## 3. Arbeitsbasis und Zustandsverantwortung

Der Neustart löscht oder verändert das Altprojekt nicht. **Pfadvorschlag:** `C:\dev\SternenBuergerchen-Neustart`, noch nicht angelegt. Dieser Bericht bleibt im eigenen Dokumentations-Worktree von `integration/core-foundation`; die alten Aufgaben werden nicht automatisch das neue Backlog. Vor Umsetzung werden Zielpfad, Branch und kurze eigene Projektregeln festgehalten.

| Künftiger Bereich im neuen Projekt | Verantwortung |
| --- | --- |
| `project.godot`, `scenes/game.tscn` | Genau ein sichtbarer Produktstart in der Basis |
| `scripts/core/simulation_root.gd` | Commands autorisieren, Simulationszeit führen, Effekte zentral committen |
| `scripts/core/world_state.gd`, `save_store.gd` | IDs, Crew, Besitz, Basis, Aufträge und Karteninstanzen; versioniert und atomar speichern |
| `scripts/network/session_gateway.gd` | Absender, Sitzung, Befehlsrechte, Übertragung und bestätigten Zustand vermitteln |
| `scripts/crew/`, `scripts/contracts/` | Crewverfügbarkeit, Fähigkeiten, Respawn und Missionsergebnisse als Effekte auswerten |
| `scripts/base/`, `scripts/economy/` | Slots, Bettreservierung, Räume, Rezepte, Markt, Geld und Cargo fachlich prüfen |
| `scripts/world/`, `scripts/ground/`, später `scripts/space/` | Ortswechsel und ausführbare Team-/Schiffsaufträge koordinieren |
| `scenes/base/`, `scenes/ground/`, `scripts/ui/` | Sichtbare Basis, Einsatzkarten, Auswahl, Befehle und Ergebnisdarstellung |
| `data/`, `assets/curated/`, `assets/credits.md` | Kleine Kataloge und nur tatsächlich benötigte, dokumentierte Assets |
| `tests/` | Produktwege, Save-/Transaktionsintegrität und echte Zwei-Client-Fälle prüfen |

Die Fachsysteme lesen denselben Zustand und liefern Effekte. Nur `SimulationRoot` verändert ihn; UI und Netzwerkclient senden Commands. Registries liefern Lookup, Signale informieren nach dem Commit. Kein produktiver Controller liegt in `tests`.

Jeder Command trägt Anforderungs-ID, Absender/Sitzung, handelnde Crew- oder Schiffs-ID, Ziel und gegebenenfalls Auftrags-ID. Der autoritative Host prüft Rechte, Voraussetzungen und doppelte Anfragen. Singleplayer nutzt denselben Eingang lokal. Geld, Waren, Belohnungen, XP, Baukosten und Bettreservierung werden pro Vorgang genau einmal und gemeinsam verbucht; konkurrierende Käufe oder Rekrutierungen dürfen keinen Besitz duplizieren. Eine Arbeitsplatzzuweisung reserviert die Person zentral: Sie kann nicht gleichzeitig produzieren, pilotieren oder im Einsatz sein. Herstellung läuft nur mit dem zugewiesenen geeigneten Arbeiter am Arbeitsplatz; fehlt er, ruht der gespeicherte Auftrag.

Personen, Schiffe und besuchte Karten behalten stabile IDs. Kartenwechsel erzeugen keine Crewkopien und erneuern keine abgebauten Ressourcen. Außerhalb der Kamera laufen passende Zeitschritte weiter; bei Pause steht dagegen die Simulationszeit einschließlich Herstellung, Reise und Respawn still. Netzwerkverkehr, Oberfläche und Pausenabstimmung bleiben erreichbar. Das ist die vorgeschlagene gemeinsame Zeitregel; die Berechtigung zum Pausieren wird in N0 entschieden.

## 4. N0 – Neustartgrundlage und kleine Technikproben

**Ergebnis:** Kurze Zielbeschreibung, getrenntes startbares Projekt und ein verbindlicher Eingang für lokale sowie entfernte Befehle.

- [ ] Bestätigte Entscheidungen in die neue Kurz-Spec übernehmen; nur Startschiff, unmittelbare Zeit-/Besitzregeln und N1-Abhängigkeiten konkretisieren.
- [ ] Neuen Zielpfad und Branch festhalten; Godot-Executable per vollständigem Pfad und Versionsausgabe prüfen. Import-/Exportversion getrennt vom vorhandenen 4.6.1-Projekt dokumentieren.
- [ ] Host-Autorität, Kampagnen-/Sitzungsbesitz, Crew-Befehlsrechte, Verbindungsabbruch und Pausenregel für N1a/N2 knapp festlegen. Keine allein auf später verschobene Multiplayer-Architektur.
- [ ] Produktstart, stabile IDs, Commands und versioniertes Save an einem minimalen Zustand erproben; keine Übernahme des gesamten alten Gerüsts.
- [ ] Rostwelt-Stilreferenz auswählen: Kenney-Silhouetten, ausgearbeitete Höhen, Felsen, Bodenmaterialien und Licht; zuerst ein kleiner sichtbarer Ausschnitt.
- [ ] Größenprobe mit entfernten Landezonen, Patrouillenraum und Kamerabewegung entwerfen; Zielhardware, Frame-/Simulationszeit, Ladezeit und Speicher als Messgrößen festhalten.
- [ ] Modellverzeichnisse nur für das benötigte Startsubset sichten; vor Übernahme Herkunft, Geometrie und tatsächliche Spielrolle festhalten.
- [ ] Kenney-Quelle `C:\Users\bjoer\Pictures\Kenney Game Assets All-in-1 3.4.0` für das kleine Basisset nutzen; benötigte Assets kuratiert ins neue Projekt kopieren und Originale erhalten.

**Done-Gate:** Ein echter Fensterstart und sauberer Exit; Version/Pfad und neue Regeln sind eindeutig; N1a-Zwei-Client-Probe und messbare Geländeprobe sind konkret vorbereitet.
**Risiko/Stop:** Unklare Zustandsbesitzer vor Inhaltsausbau lösen. **Abhängigkeit:** Review dieses Plans. **Nicht enthalten:** fertige Welt, vollständiger Netzwerkdienst oder pauschale Assetmigration.

## 5. N1 – Freundesgruppe, kleine Basis und erster Satellit

**Ergebnis:** Ein vollständiger erster Auftrag beginnt und endet in einer sichtbaren kleinen Basis. Zwei oder drei benannte NPCs wohnen dort; Transport ist zunächst ein erklärter Übergang.

- [ ] Basiskern mit Anschlussplätzen, einem Bett pro Startmitglied, kleinem Lager und einfacher Werkbank zeigen. Die genaue Startzahl aus N0 übernehmen.
- [ ] Anfangsausrüstung, nutzbaren kleinen Mehrzwecktransport und Satellitenbergung auf einer geladenen Rostwelt-Karte anlegen.
- [ ] Auftrag in der Basis annehmen, Crew/Cargo vorbereiten, zur Landezone reisen, bewegen, bergen und zurückkehren können.
- [ ] Nähe, Arbeitsdauer und Frachtgrenzen prüfen; Abbruch, Rückzug und bereits geladene Beute ausdrücklich behandeln.
- [ ] Einmalige Auszahlung und einen Blueprint sichtbar machen. Die Werkbank per Klick öffnen, geeigneten verfügbaren NPC zuweisen und nach dessen Ankunft ein einfaches Rezept oder eine kleine Reparatur ausführen. Der Arbeiter bleibt währenddessen gebunden; Spezialwerkstätten folgen N3.
- [ ] Eine vereinfachte Stations-/Marktroute mit Kauf und Verkauf anbieten, ohne begehbare Vollstation vorauszusetzen. Waren, Geld und Kapazität gemeinsam verbuchen.
- [ ] Pause und Save vor Start, unterwegs, nach Bergung und Auszahlung prüfen; Basis, Crew, Besitz und Auftragsfortschritt bleiben erhalten.

**Done-Gate:** Der ganze Weg ist ohne Konsole spielbar. Wiederholte Abgabe, Marktanfrage oder Reload erzeugt weder mehr Geld noch Cargo, Blueprints oder XP. Der Spieler kehrt sichtbar in dieselbe Basis zurück und nutzt die Werkbank über Objekt und NPC; fehlender Arbeiter oder Pause stoppt Fortschritt, eine doppelte Einsatzzuweisung wird abgelehnt.
**Risiko/Stop:** Einzelne fertige Menüs erfüllen N1 nicht. **Abhängigkeit:** N0. **Prüfung:** Produktdurchlauf, Save-/Belohnungs-/Marktcheck und pausierte Simulationszeit.

### N1a – Verbindlicher früher Zwei-Client-Nachweis

- [ ] Unmittelbar nach dem minimalen Solo-Kreis zwei echte lokale Clients verbinden: gemeinsamer Zustand, zugewiesene Befehlsrechte, eine Bewegung/Bergung und einmalige Abgabe.
- [ ] Fremde Befehle ablehnen; doppelte Anfrage und gleichzeitigen Besitzvorgang prüfen. Pausenzustand für beide identisch zeigen; Netzwerk bleibt dabei erreichbar.
- [ ] Abbruch eines Clients sowie erneute Verbindung nach der N0-Regel durchführen; keine zweite Crew oder Auszahlung erzeugen.

**Done-Gate:** Zwei Fenster zeigen denselben autoritativen Missions- und Besitzstand. Dies ist ein Pflichtschritt vor N2 und weiterem Inhaltsausbau, keine behauptete vollständige Koop-Kampagne.

## 6. N2 – Mini-Bunker, Rettung und erste Koop-/PvP-Partie

**Ergebnis:** Kleiner Taktikauftrag mit zwei bis vier Crewmitgliedern, Verwundung, Evakuierung und verzögertem Wiedereinsatz; zusätzlich spielbarer Koop und eine faire minimale PvP-Partie.

- [ ] Wenige Bunkerräume, Deckung, klare Zugänge und ein eindeutiges Ziel bauen; Bewegen, Sichern, Angreifen/Ausführen und Rückzug befehlen.
- [ ] Sichtkontakt, Bedrohung, unterbrochene Aufträge und gegnerische Patrouillen nachvollziehbar anzeigen. Kameraschwenken verrät keine verdeckten Gegner.
- [ ] Verwundete evakuieren; nach Kampftod denselben NPC nach Timer am festgelegten Ort verfügbar machen und erneut einfliegen können. Keine automatische dauerhafte Löschung.
- [ ] Kosten, Ausrüstungsfolgen, Respawnort/-dauer und Rücktransport aus N0 sichtbar anwenden; pausierte Zeit und Reload dürfen keine Extrawartezeit oder Crewkopie erzeugen.
- [ ] Den Bunker mit zwei menschlichen Commandern kooperativ spielen; zugewiesene Crew gemeinsam zum Ziel und zurück bringen.
- [ ] Eine kleine symmetrische PvP-Karte mit gleichem Punktebudget und Siegziel bauen. Bessere Fähigkeiten kosten mehr; vorgeschlagene Schiffs-/Ausrüstungskosten vor Anwendung festlegen.

**Done-Gate:** Solo-Erfolg/Abbruch, Koop-Abschluss und PvP-Partie laufen über denselben Command-Eingang. Zwei Clients stimmen bei Schaden, Respawn, Ergebnis und Pause überein; fremde Crew ist nicht befehlbar und unaufgedeckte Gegner werden nicht über Clientzustand verraten.
**Risiko/Stop:** Wegfindung, Autorität oder Fairness vor neuen Waffen lösen. **Abhängigkeit:** N1 + N1a. **Prüfung:** Sichtbarer Bunker-/Rettungsdurchlauf, Zwei-Client-Koop/PvP, Save-/Transaktionscheck.

## 7. N3 – Basisräume, Forschung und Crew wachsen

**Ergebnis:** Die kleine Basis wächst funktional und sichtbar; mehr Betten und Räume ermöglichen neue Mitglieder, Ausrüstung und Tätigkeiten.

- [ ] Räume an freie Anschlussplätze des Basiskerns oder weiterer Verbinder setzen; Kosten, Bauzeit, Voraussetzungen und spätere Funktion vor dem Bau anzeigen.
- [ ] Schlafplätze, Lager und einfache Werkbank erweitern; zusätzliche Schlafräume, Waffenkammer, Forschungsraum und Spezialwerkstatt bauen. Gebäude, Maschinen und hochwertige Technik bei Bedarf an Blueprints binden.
- [ ] Baukosten, Slot- und Bettreservierung zentral committen. Ein neues Mitglied benötigt ein verfügbares Bett; parallele Koop-Aktionen dürfen denselben Platz nicht doppelt vergeben.
- [ ] Bewerber über Einsatzerfolge/Ruf anbieten; Fähigkeiten, Aufgaben und Belastung zeigen. Wachstum etwa von 2–3 auf 4 und 6 Personen ist ein Balancevorschlag.
- [ ] Forschung/Blueprint + passende Maschine + geeigneter Arbeiter am Arbeitsplatz + Material + Kosten + Dauer mit wenigen wirksamen Rezepten verbinden. Maschinen öffnen per Objektklick ihr Kontextmenü; Marktmaterial hält den Kreis vor Mining nutzbar.
- [ ] Rekrutierung, Einsatzlernen, Erholung, Raumzustand und Produktion speichern; die wachsende Fähigkeit in der vereinbarten PvP-Punktebewertung abbilden.

**Done-Gate:** Ein gebauter Raum schaltet tatsächlich eine Tätigkeit frei; ein Missionsfund führt zu hergestellter Ausrüstung im nächsten Einsatz. Zwei Koop-Spieler können kaufen/bauen/rekrutieren, ohne doppelte Kosten, Waren oder Betten zu erzeugen.
**Risiko/Stop:** Keine großen Forschungsketten oder Personaldramen vor diesem Kreis. **Abhängigkeit:** N2. Die Basis wird hier erweitert, nicht erst hier eingeführt.

## 8. N4 – Raumflug als Commander-Auftrag und Arbeitsdelegation

**Ergebnis:** Ein bemanntes Schiff bewegt sich auf einer geladenen Weltraum-Operationskarte, sucht ein Ziel, dockt an einem Wrack an und bringt Ladung zurück.

- [ ] Ein kleines nutzbares Raumgebiet mit ausreichenden Suchräumen, benannten Crewposten und begrenzter Fracht anlegen; keine nahtlose Atmosphärenreise bauen.
- [ ] Anfliegen, Gebiet/Route scannen, Position halten, andocken, bergen und zurückkehren befehlen; entdeckte Ziele aus tatsächlichem Scan ableiten.
- [ ] Wenig erfahrene Crew benötigt einzelne Weg-/Scanaufträge; erfahrene Crew bearbeitet einen begrenzten Gebietsauftrag selbstständig. Fähigkeit wirkt verständlich auf Ausführung und nötige Führung.
- [ ] Autonomie durch Auftragsgebiet, Cargo, Treibstoff und Gefahr begrenzen; bei Grenze halten, nachfragen oder nach angezeigter Regel zurückkehren. Das Abbauen kommt in N5 hinzu.
- [ ] Raumoperation, Besatzung, Reparatur, Wrackressourcen und Cargo in denselben Save-/Wirtschafts-/Netzwerkzustand einbinden.

**Done-Gate:** Raumauftrag und Bodenauftrag speisen denselben Besitzstand. Ein zweiter Client sieht Flug, Scan und Bergung konsistent; Reload am Wrack dupliziert nichts. Fehlender Posten oder abgebrochener Auftrag erklärt die Folge.
**Risiko/Stop:** Keine zweite Wirtschaft oder Crewkopie für den Raum. **Abhängigkeit:** N3. **Nicht enthalten:** Raumkampf, Schiffsinnenräume oder vollständige Planetenflugphysik.

## 9. N5 – Mining, Bergung und Hauling tragen die Organisation

**Ergebnis:** Unterschiedliche lohnende Tätigkeiten am Boden und im Weltall verbinden Suche, Werkzeug, Risiko, Fracht und Herstellung.

- [ ] Bodenlagerstätten und Asteroiden auf Operationskarten finden, scannen, bewerten und mit passender Ausrüstung begrenzt abbauen.
- [ ] N4-Delegation erweitern: Anfänger erhalten Route/Scan/Förderziel; geeignete Experten können ein benanntes Gebiet suchen und abbauen. Rückkehrgrenzen bleiben sichtbar.
- [ ] Bei Bergung zwischen Wert, Aufwand, Zustand und Transportkapazität entscheiden; Wracks liefern endliche Teile oder Rohstoffe.
- [ ] Hauling mit Abholung, Besitz, Route, Kapazität, Abgabe und Verlustfolgen einführen; zumindest ein tatsächliches Risiko je Tätigkeit ausspielen.
- [ ] Gewinne mit Markt und N3-Rezepten verbinden; gemeinsame Koop-Arbeitsaufträge und umkämpfte Ressourcen nach den PvP-Regeln prüfen.

**Done-Gate:** Gefördertes Material wird transportiert und verbaut. Bergung und Hauling verlangen andere Entscheidungen; Abbruch, Reload und Wiederbesuch erneuern keine geleerten Quellen. Delegierte Arbeit endet nachvollziehbar an Grenzen.
**Risiko/Stop:** Drei gleichartige Fortschrittsbalken genügen nicht. **Abhängigkeit:** N4. **Nicht enthalten:** globale Börsensimulation oder unbegrenzte Produktionsketten.

## 10. N6 – Wenige Schiffe und verständlicher Raumkampf

**Ergebnis:** Eine kleine Flotte verbindet Crewführung, Kampf, Arbeit und Transport; sie funktioniert kooperativ und gegeneinander.

- [ ] Nur für echte Rollen benötigte Muster auswählen. Startmehrzwecker plus später Arbeits-/Kampfschiff und Transporter sind ein Vorschlag; genaue Zahl und Modelle erst anhand der Einsätze entscheiden.
- [ ] Geeignete Kenney-Modelle oder andere ausdrücklich zur Spielnutzung freigegebene Modelle in Blender aufbereiten; Silhouette, Größe, Material, Polygonumfang und Godot-Import prüfen. Keine komplette Sammlung konvertieren.
- [ ] Taktischen Raumkampf zunächst mit vorgeschlagenen 2.5D-/Höhenbändern erproben: Annähern, Abstand halten, Angreifen, Schützen und Rückzug.
- [ ] Crewposten, Schaden und Reparatur an wenigen lesbaren Werten zeigen; beschädigte Schiffe retten/bergen und Mannschafts-Respawn mit Transportfolgen verbinden.
- [ ] Eskorte und Abfangen im Koop sowie eine kleine PvP-Raumbegegnung mit nachvollziehbarem Kräftebudget durchspielen.

**Done-Gate:** Schiffsrollen führen zu unterschiedlichen Entscheidungen; zwei Clients stimmen bei Bewegung, Kampf, Fracht und Recovery überein. Save/Load und Rückzug bewahren Besitz und Mannschaftsidentität.
**Risiko/Stop:** Darstellung vor zusätzlichen Mustern verbessern. **Abhängigkeit:** N5. Keine Großkampfschiffe, sechs Freiheitsgrade oder echte Innenräume voraussetzen.

## 11. N7 – Eine Rostwelt mit mehreren guten Einsatzkarten

**Ergebnis:** Eine zusammengehörige marsartige Welt bietet verschiedene geladene Schauplätze, große taktische Außenräume und kompakte Innenkarten.

- [ ] Außenposten A/B, Handelsstation C und Bunker D als beispielhafte Kartenfamilie mit eigenen IDs, Aufträgen und Wiederbesuchsfolgen aufbauen.
- [ ] Außenkarten so gestalten, dass entfernte Landezonen, Anflugwahl, Patrouillenumgehung und Ressourcenwege echte Entscheidungen ermöglichen; Innenräume können klein und getrennt geladen sein.
- [ ] Ressourcen, Schäden, Beute und laufende Vorgänge je Karteninstanz speichern; Hintergrundfortschritt folgt derselben Simulationszeit und Pausenregel.
- [ ] N0-Größenprobe mit echten Crew-/Schiffs-/Berufssystemen wiederholen. Streaming nur dort ergänzen, wo gemessene Größe es braucht; keine durchgehende Planetenkontinuität erzwingen.
- [ ] Kenney-Assets mit sorgfältigen Höhenformen, Felsen, Bodenfarben, Licht und lesbaren Wegen in den Rostwelt-Stil einbetten.
- [ ] Zusammenhängenden Koop-Kampagnenlauf über Basis, Markt, Kartenwechsel, Ausbau und Wiederverbinden durchführen; Boden-/Raum-PvP auf verschiedenen Karten mit Punktebudget abnehmen.

**Done-Gate:** Längerer echter Lauf besteht festgehaltene Hardware-/Versionsbudgets. Große Außenkarten bieten funktionierende entfernte Landungen; Kartenwechsel verlieren keine Personen oder Ressourcen. Koop-Kampagne und wiederholbare PvP-Partien sind nachgewiesen.
**Risiko/Stop:** Leere Kilometer sind kein Fortschritt. **Abhängigkeit:** N6; Vorprobe bereits N0. Weitere Planeten sind späterer Ausbau, keine Voraussetzung dieser Stufe.

## 12. N8 – Die gewachsene Organisation führt die Außenpostenoperation

**Ergebnis:** Die große kombinierte Mission entsteht aus den zuvor erworbenen Fähigkeiten, Räumen, Mannschaften und Schiffen.

- [ ] Vorbereitung, Transport, Bodenteams, Luft-/Raumsicherung und Rückkehroption in einen regulär erreichbaren Auftrag verbinden.
- [ ] AA ausschalten, Station öffnen, Computer sichern und Frachtanflug/Abflug decken als zusammenhängende Operation bauen.
- [ ] Aufgaben auf erfahrene Teams und Schiffe verteilen; Kosten, Cargo, Verletzungen, Respawn und Ersatztransport folgen derselben Kampagne.
- [ ] Erfolg, Teilabbruch und Rettung persistent abschließen; im Koop können Commander die zusammenhängenden Aufgaben teilen.

**Done-Gate:** Regulär aufgebauter Spielstand, mindestens zwei sinnvolle Einsatzpläne und vollständiger Solo-/Koop-Durchlauf ohne Testteleports. PvP erhält seine eigene faire Ziel-/Budgetregel und wird nicht aus Kampagnenungleichheit abgeleitet; seine N2/N6/N7-Nachweise sind Voraussetzung des Kernabschlusses.
**Risiko/Stop:** Kein Sondermissionssystem neben Crew, Wirtschaft und Transport. **Abhängigkeit:** N7. Historische Außenpostenoperation und technischer Alt-Default `grid_sweep` sind zu unterscheiden.

## 13. Ausbau nach dem tragfähigen Kern

Zusätzliche Planeten, mehr Schiffsmuster, tiefere Beziehungen, andere persönliche Abgangsgründe, längere Forschungsketten und Schiffsinnenräume bleiben mögliche Ausbauten. Nahtloser Atmosphärenflug und beliebige freie Basisplatzierung sind nicht nötig. Koop und PvP gehören bereits in den Kern mit konkreten Abnahmen in N1a, N2, N6 und N7; sie werden nicht hinter N8 vertagt.

## 14. Prüf- und Arbeitsrhythmus

- Pro Stufe zuerst einen realen Spielerweg und dessen Ergebnisfälle konkretisieren; dann die kleinste dafür nötige Umsetzung bauen. Neue Details verändern den nächsten Abschnitt.
- Prüfungen auf Besitz, Save, einmalige Abrechnung, Bau-/Bettreservierung, Rechte, Pause, Abbruch und Kartenwechsel konzentrieren. Tests dürfen Erfolg nicht selbst in den Zustand schreiben.
- Passende kleine automatisierte Checks mit echten Fensterläufen ergänzen. Netzwerk braucht zwei echte Clients; ein lokaler Strukturtest ist dafür kein Ersatz.
- Jede bestandene Stufe nennt Commit, Engine-/Buildversion, Ergebnisbelege und verbleibende Grenzen. Historische grüne Läufe sind keine neue Verifikation.
- Kleine fachliche Commits, nur relevante Dateien stagen. Altprojekt und fremde Arbeit erhalten; Integration und Veröffentlichung ausdrücklich benennen.

## 15. Quellen und Einordnung

- Lokales `C:\dev\SternenBuergerchen\sternenbuerger-gdd.docx`, GDD v0.1, März 2026: Kapitel 1–6 und 8–9. Historischer Entwurf, kein aktueller Runtime-Vertrag.
- Originalnachricht vom 19.07.2026, 19:15 UTC, Codex-Verlauf `019f7002-fa09-78a2-b696-51c3b6e2aaac`: kleiner Aufbau, Blueprints, Mining, Herstellung, Basis und Echtzeitorganisation.
- Nutzerauftrag, Commander-Bestätigung und konkretisierende Antworten vom 12.09.2026; die Antworten zu Pause, Basis, Respawn, Multiplayer und einer Rostwelt haben Vorrang vor früheren Planannahmen.
- `integration/core-foundation:docs/PROJECT_BRIEF.md`, `docs/DESIGN_NOTES.md`, `docs/GDD_STATUS.md`: engerer Bodenprototyp und historische Abgrenzung. Seine Menü-/Ohne-Pause-Regeln werden nicht als neue Nutzerentscheidung übernommen.
- Historische `TASK_236`, `TASK_237` und `TASK_238`: Beziehungen, Progression und Personalereignisse; keine automatische Verpflichtung zu deren Neuimplementierung.
- `data/mission_scenarios/station_route_one_screen_multiplayer_drill.json`: AA, Tür, Computer und Cargo. `scripts/meta/meta_layer_flow.gd`: historischer Singleplayer-Default `grid_sweep`.
- Vom Nutzer genannte Modellquellen: `C:\Users\bjoer\3D Objects\drive-download-20250521T120706Z-1-001` und `C:\Users\bjoer\3D Objects\drive-download-20250521T120706Z-1-002`. Der Verweis ist keine Aussage über Nutzungsrechte oder bereits fertige Spielassets.
- Bestätigte Kenney-Quelle: `C:\Users\bjoer\Pictures\Kenney Game Assets All-in-1 3.4.0`. Nur ausgewählte Assets kopieren, Originalbestand bewahren.
- Lokale Inventur der Schiffordner: 155 Dateien, 122 FBX-/OBJ-Dateien, 63 unterschiedliche Modellnamen, keine STL-Dateien; Geometrie/Materialien/Import ungeprüft. Die beigefügte `[Readme] & CTM Model Links.docx` nennt RSI als Quelle. Eine gesonderte Erlaubnis zur Verwendung in einem eigenen Spiel liegt dort nicht vor; Eindeutschen oder Low-Poly-Konvertierung ersetzt diese nicht. Vorerst passende Kenney-Schiffe verwenden. Einordnung anhand [RSI Fandom-FAQ](https://support.robertsspaceindustries.com/hc/en-us/articles/360006895793-Star-Citizen-Fankit-and-Fandom-FAQ) und [RSI-Nutzungsbedingungen](https://robertsspaceindustries.com/en/tos).
- Konkrete Kenney-Auswahl, lokal samt jeweiliger CC0-`License.txt` geprüft: Space Station Kit (Räume/Betten), Space Kit (Verbinder/Schiffe), Survival Kit (Werkbänke), Blaster Kit (Lager/Waffen), Furniture Kit (Unterkunft), Factory Kit 3.0 (Maschinen). Beispiele und Einsatzzuordnung stehen im HTML; noch keine Assets übernommen.
- N0–N8 sind zukünftige Entwicklungsarbeit. Dieser Dokumentationsstand verändert keine Runtime, Engineinstallation oder Originalmodelle.
