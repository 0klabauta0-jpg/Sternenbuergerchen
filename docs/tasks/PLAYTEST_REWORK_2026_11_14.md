# Vollständige Änderungsliste – Playtest vom 14.11.2026

**Status: vollständig erfasst, Umsetzung nicht beauftragt.**

Aktueller Auftrag: die Rückmeldungen sammeln, sinnvoll ordnen und als Arbeitsplan
speichern. Erst einmal nur planen, keinen Spielcode ändern oder frühere
Implementierungsversuche fortsetzen. Alle Checkboxen beschreiben offene
Zielanforderungen; sie sind keine Aussage, dass der aktuelle Code die Funktion
überhaupt nicht besitzt.

Arbeitsplan: [Arbeitspakete und Reihenfolge](../superpowers/plans/2026-11-14-playtest-rework.md).
Die Nummern **L01–L23** bleiben für Zuordnung und spätere Abnahme stabil.

## Ziel / Problem und Sinnhaftigkeit

Die Rückmeldungen betreffen den ersten Kampagnenausflug, Basis-/Truppbedienung,
Lager, Besatzung, Sternkarte, Erkundung, Einzelgefechte, Editor, Grafik und
Performance. Wiederholte Bedienprobleme und schlecht auffindbare Aktionen
unterbrechen den Spielablauf. Ein direkter Gefechtsstart soll zusätzlich einen
schnellen Weg zum eigenen Ausprobieren der Mechaniken schaffen.

Die genannten Symptome sind Nutzerbeobachtungen. Ursachen und bereits vorhandene
Teilfunktionen müssen auf der tatsächlich verwendeten Produktbasis geprüft
werden; ältere Testresultate oder begonnene Korrekturen erledigen keinen Punkt.

## Umfang und Nicht-Ziele

Umfang sind die folgenden 23 Punkte samt Unterpunkten. Die Liste ermächtigt in
diesem Auftrag ausschließlich zur Planung und Dokumentation. Kein neuer Build,
kein Mainmerge, keine Asseterzeugung, kein Spielstart und keine Änderung echter
Spielstände. Eine spätere Umsetzung soll vorhandene Systeme wiederverwenden;
neue Wirtschaft, neue allgemeine Raumkampfsimulation und eine komplette
Engine-/Architekturerneuerung sind keine impliziten Zusatzaufträge.

## L01 – Erste Kampagnenmission / Datapad

- [ ] Beheben, warum das geborgene Datapad in Anjas Inventar nicht hochgeladen werden kann.
- [ ] Upload an der Heimatbasis klar auffindbar machen.
- [ ] Abgabe aus dem tatsächlichen Personen-, Schiffs- oder Basisinventar ermöglichen.
- [ ] Missionsabschluss und Belohnung dürfen nur einmal ausgelöst werden.

## L02 – Anflug, Abflug und Orbitübergang

- [ ] Anflug sichtbar außerhalb der Bodenkarte beginnen.
- [ ] Dem ausgewählten Anflugwinkel folgen.
- [ ] Beim Abflug sichtbar bis zum Kartenrand und darüber hinaus fliegen.
- [ ] Abflugrichtung wählbar machen; alternativ den Anflug umgekehrt verwenden.
- [ ] Erst nach dem Verlassen der Bodenkarte auf die zugehörige OM-/Orbitkarte wechseln.
- [ ] Übergang und Weiterflug verständlich darstellen.
- [ ] Automatik umschaltbar machen: Bei freier Route automatisch weiterfliegen; ausgeschaltet auf der OM-Karte auf den nächsten Befehl warten. Diesen Ablauf hat der Nutzer ausdrücklich bestätigt.

## L03 – Einsteigen, Aussteigen und direkte Befehle

- [ ] Hängenbleiben am Schiffseinstieg beheben.
- [ ] Nach dem Aussteigen unmittelbar Rechtsklickbefehle für Personen beziehungsweise Trupps ermöglichen, entsprechend dem vorhandenen Basis-/Taktikbedienpfad.
- [ ] Buccaneer: Einstieg am Cockpit.
- [ ] Cutlass: Einstieg über die Heckklappe.
- [ ] Den tatsächlichen Weg zum Einstieg und das Einsteigen sichtbar zeigen.

## L04 – Schaltflächen und Klickflächen

- [ ] Auftragsannahme über die gesamte sichtbare Schaltfläche ermöglichen.
- [ ] Ausreichend große Klickflächen verwenden; nicht nur Fähnchen oder Symbol anklickbar machen.
- [ ] X-/Schließen-Schaltflächen über ihre gesamte sichtbare Fläche zuverlässig bedienbar machen.

## L05 – Trupp & Ausrüstung / Basislager

- [ ] Charakterdatenblatt mit persönlicher Ausrüstung ungefähr halb so breit gestalten.
- [ ] Rechts daneben eine ausreichend große Lagerspalte für den tatsächlichen Basisbestand anzeigen; das Basislager erhält mindestens den Platz einer vollwertigen Spalte.
- [ ] Zwischen Basislager und den Lagern einzelner Schiffe wechseln können; Schiffsauswahl unter beziehungsweise bei dieser Lageransicht anbieten.
- [ ] Gegenstände per Drag-and-drop zwischen persönlichem Inventar, Basislager und Schiffslager hinein- und herausziehen können.
- [ ] Personen durch Herausziehen ins Personal aus dem Fireteam entfernen.
- [ ] Charakterdetails per Doppelklick auf die Personenkarte öffnen.
- [ ] Die Buttons „Aus Trupp entfernen“ und „Charakter ansehen“ entfernen.

## L06 – Flugdeckansicht

- [ ] Dieselbe tatsächliche Basis zeigen wie beim Basiserkunden.
- [ ] Passenden Zoom verwenden und die Darstellung sauber in den Fensterrahmen einpassen.
- [ ] Personen beim Hinlaufen und Einsteigen sichtbar lassen.
- [ ] Die persönliche Lager-/Ausrüstungsansicht im Flugdeck weglassen.
- [ ] Personal-, Trupp- und Schiffsbedienung schmaler gestalten.
- [ ] Einzelpersonen und ganze Trupps per Drag-and-drop auf ein Schiff ziehen können, auch wenn der Pilot weiterhin zu einem Trupp gehört.
- [ ] Alle angezeigten Schiffsdetails, Personen und Funktionsplätze auf das ausgewählte Schiff beziehen.

## L07 – Schiffsplätze als Karten

- [ ] Porträtkarten und sichtbare belegbare Plätze statt der bisherigen Dropdownbedienung verwenden.
- [ ] Einen klar erkennbaren Pilotenslot anzeigen.
- [ ] Bei der Cutlass zusätzlich einen Turmslot anzeigen.
- [ ] Bei der Cutlass zunächst vier Passagier-/Jump-Seat-Slots anzeigen.
- [ ] Personen per Drag-and-drop zuweisen, zwischen Plätzen verschieben und herausziehen können.
- [ ] Turmbesetzung ausdrücklich bedienbar machen.

## L08 – Aufsitzen / Absitzen

- [ ] „Aufsitzen“ und „Absitzen“ durchgängig als Begriffe verwenden.
- [ ] Beim allgemeinen Absitzen die Personen auf Passagier-/Jump-Seat-Plätzen aussteigen lassen.
- [ ] Pilot und Turmschütze auf ihren Funktionsplätzen sitzen lassen.
- [ ] Per Rechtsklick auf deren Porträt „Aufstehen“ anbieten.
- [ ] Nach dem Aufstehen diese Personen beim anschließenden Absitzen ebenfalls berücksichtigen.

## L09 – Anpassbare Anordnung der Oberfläche

- [ ] Spalten und Bereiche möglichst verschiebbar beziehungsweise in ihrer Breite anpassbar machen.
- [ ] Dem Lager ausreichend Platz geben.
- [ ] Den Flugdeckbereich kompakter halten.
- [ ] Die bestehende Leiste als brauchbare Grundlage beibehalten und gezielt verbessern.

## L10 – NPC-Meldungen

- [ ] Meldungen als Sprechblasen an der zugehörigen Fireteamkarte anzeigen.
- [ ] Klar erkennen lassen, welcher NPC spricht.
- [ ] Verständliche Sprache statt kryptischer Kürzel und technischer Statusmeldungen verwenden.

## L11 – Satellitenabsturzstelle

- [ ] Einen erkennbar abgestürzten Satelliten darstellen.
- [ ] Eine Einschlag- beziehungsweise Schleiffurche im Boden ergänzen.
- [ ] Passende Trümmer und Absturzspuren hinzufügen.
- [ ] Die Absturzstelle tatsächlich suchen lassen; den Standort nicht vorab durch den Zielmarker verraten.

## L12 – Erkundung und Nebel des Krieges

- [ ] Noch nicht erkundete Bereiche vollständig schwarz darstellen.
- [ ] Bereits erkundete, aktuell unbeobachtete Bereiche abgedunkelt darstellen.
- [ ] Aktuell beobachtete Bereiche hell und mit den tatsächlich sichtbaren Informationen anzeigen.
- [ ] Unbekannte Kampagnenkarten zunächst schwarz lassen.
- [ ] Beim Anflug nur tatsächlich wahrgenommene Bereiche aufdecken.
- [ ] Verborgene Ziele und Marker erst nach ihrer Entdeckung anzeigen.

## L13 – Aussagekräftige Hover-Informationen

- [ ] Auf Personen-, Trupp- und Detailkarten zusätzliche nützliche Informationen anzeigen.
- [ ] Beim Überfahren eines NPCs in der Basis Rolle und Fähigkeiten zeigen, beispielsweise seine Piloteneignung.
- [ ] Namenswiederholungen und Hinweise wie „Person auswählen“ durch hilfreiche Angaben ersetzen.
- [ ] Fähigkeiten und Einsatzmöglichkeiten schnell erkennbar machen.

## L14 – Skirmish-Darstellung

- [ ] Prüfen und korrigieren, warum Betten teilweise außerhalb der Gebäude stehen.
- [ ] Platzierung und Zuordnung der Betten zu den vorgesehenen Räumen überprüfen.
- [ ] Darstellung der schweren Rüstung prüfen und überarbeiten.

## L15 – Performance

- [ ] Weiterhin auftretende Ruckler und langsame Abläufe untersuchen.
- [ ] Besonders Basiserkunden sowie das Öffnen und Aktualisieren der Bedienbereiche prüfen.
- [ ] Verbesserungen mit vergleichbaren Vorher-/Nachher-Messungen nachweisen.

## L16 – Dauerhaft aufklappbare Basismenüs

- [ ] Untermenüs beim Bedienen offen halten.
- [ ] Einen kleinen Plus-/Minus-Schalter am Navigationsbutton vorsehen, beispielsweise links unten.
- [ ] Untermenüs per Klick auf- und zuklappen können.
- [ ] Ein aufgeklapptes Menü erst bei ausdrücklichem Schließen wieder einklappen.

## L17 – Direkter Gefechtsstart

- [ ] Zwei Spielwege klar auswählbar anbieten: strategischer Modus mit Sternkarte, Raumflug, Basisaufbau und Krieg sowie direktes Einzelgefecht.
- [ ] Einzelgefechte ohne Kampagne, Suchaufträge oder vorherigen Basisaufbau starten können.
- [ ] Eine Boden- oder Weltraumkarte auswählen können.
- [ ] Die eigene Startseite wählen können, beispielsweise links, rechts, oben oder unten.
- [ ] Mit einer einsatzbereiten Mannschaft beziehungsweise Flotte starten.
- [ ] Gefechte schnell neu starten können, um Mechaniken selbst auszuprobieren.

## L18 – Editor grundlegend überarbeiten

- [ ] Werkzeuge, Auswahl und aktuelle Einstellungen übersichtlich und verständlich darstellen.
- [ ] Eine gut erreichbare Gesamtansicht der Karte anbieten.
- [ ] Den Mauergenerator korrigieren: Platzierung, Verbindungen, Ecken und Ausrichtung.
- [ ] Gelände verständlich anheben und absenken können, mit sichtbarer Höhenangabe und Vorschau.
- [ ] Maßstäbe der Kenney-Assets prüfen und unpassende Größen korrigieren.
- [ ] Personen und Fahrzeuge als Vergleichsobjekte platzieren können, um Größen, Durchgänge und Gebäudeproportionen zu beurteilen.
- [ ] Die bereits gefallende Gestaltung der selbstgebauten Heimatbasis als Grundlage erhalten.

## L19 – Dächer und einsehbare Innenräume

- [ ] Gebäude mit geschlossenem Dach oder offenem Innenraum darstellen können.
- [ ] Die Dachansicht im Editor umschalten können.
- [ ] Unbekannte Außenposten zunächst mit geschlossenem Dach und verborgenem Interieur zeigen.
- [ ] Beim Betreten das Dach ausblenden, damit der Innenraum sichtbar und bedienbar wird.
- [ ] An der Heimatbasis jederzeit eine offene Übersicht ermöglichen.
- [ ] Dort das Dach ausdrücklich wieder einblenden können.

## L20 – Sternkarte: Schiffsauswahl und Darstellung

- [ ] Schiffssymbole klar als das jeweilige Schiff erkennbar gestalten, insbesondere das Dropship.
- [ ] Verhindern, dass ein erneuter Klick auf das ausgewählte Schiff dessen benötigte Anzeige ungewollt zusammenklappt.
- [ ] Schiffsauswahl, Schiffsdetails und Reiseaktionen eindeutig zusammengehörig darstellen.

## L21 – Sternkarte: Karten per Doppelklick öffnen

- [ ] Per Doppelklick auf OM, Planet oder Planetoid die zugehörige Karte öffnen.
- [ ] Das Öffnen einer Karte von einem tatsächlichen Reisebefehl trennen.
- [ ] Unbekannte Karten dürfen geöffnet werden, zeigen aber zunächst nur den erlaubten beziehungsweise bereits erkundeten Stand.
- [ ] Noch nicht erforschte Bereiche bleiben schwarz.
- [ ] Port Olisar als bereits erkundeten Ort behandeln; aktuell unbeobachtete Bereiche bleiben durch Nebel des Krieges abgedunkelt.
- [ ] Die fehlenden Karten-/Ortsmarker auf Planetoiden prüfen und ihre Anzeige korrigieren.
- [ ] Bekannte Navigationsmarker von noch unentdeckten Missionszielen unterscheiden.

## L22 – Sternkarte: Zielwahl und ausdrücklicher Sprungbefehl

- [ ] Ein einfacher Klick auf ein Ziel wählt es nur aus und startet keinen Flug.
- [ ] Beim ausgewählten Schiff einen kleinen, klar erkennbaren Button „Sprung ausführen“ oder eine entsprechend verständliche Reiseaktion anzeigen.
- [ ] Den Flug erst durch diesen ausdrücklichen Befehl starten.
- [ ] Ziel und bevorstehende Reise vor dem Start eindeutig anzeigen.
- [ ] Die Orbit-Automatik aus L02 darf die bloße Auswahl eines neuen Ziels nicht als Reisebefehl behandeln.

## L23 – Warp-Animation

- [ ] Den Warp-Sprung mit einer sichtbaren Warp-Blase um das Schiff darstellen.
- [ ] Eintritt, Reise und Austritt als zusammenhängenden Ablauf animieren.
- [ ] Das Schiff während der Reise nachvollziehbar durch die Darstellung bewegen.
- [ ] Die Animation etwas langsamer gestalten, damit der Ablauf gut erkennbar ist.

## Offene Entscheidungen und Begriffe

- **Ortsname:** Die erste Heimatbasis heißt nach Erinnerung des Nutzers möglicherweise „Asterheim“. Nicht als bestätigte Umbenennung behandeln. „Port Olisar“ und historische Code-/Anzeigevarianten anhand der wirklichen Orts-IDs zuordnen; keine fremde Karte versehentlich umbenennen.
- **Aufstehen:** Ziel ist, den Funktionsplatz freizugeben und danach mit absitzen zu können. Verhalten bei vollständig belegten Passagierplätzen vor Umsetzung festlegen; kein zusätzlicher unsichtbarer Sitzplatz.
- **Dächer:** Was nach Verlassen eines erstmals betretenen Außenpostens geschieht, ist noch nicht festgelegt. Erkunden, aktuelle Sicht und manuelle Dachansicht getrennt halten.
- **Layout:** „Möglichst verschiebbar“ ist keine fertige Spezifikation für beliebige Dockfenster oder dauerhafte Layoutprofile. Konkrete verstellbare Spalten zunächst als Entwurf zeigen.
- **Animation:** Die genaue Warp-Dauer wurde nicht festgelegt; eine langsamere Vergleichsprobe zur Sichtabnahme vorsehen.
- **Startseite:** Links/rechts/oben/unten benötigen bei drehbarer Kamera eine stabile Vorschau und klare Zuordnung zum Kartenrand.

## Relevante Contracts / Dokumente

- [Projektüberblick](../PROJECT_BRIEF.md), [Architektur](../ARCHITECTURE.md), [Arbeitsregeln](../CODEX_RULES.md).
- [Operations-UX](../dev/homebase_operations_ux_contract.md), [Personalinventar](../dev/personnel_inventory_contract.md).
- [Kampagne](../dev/campaign_introduction_contract.md), [Orbitreise](../dev/orbit_quantum_travel_contract.md), [Fog of War](../dev/fog_of_war_modes_contract.md).
- [Skirmish-Starts](../dev/skirmish_prepared_starts_contract.md), [Editor-Assetworkflow](../dev/map_editor_asset_workflow_contract.md), [Editormodule](../dev/map_editor_module_split.md).
- [Grafikreferenzen und Revisionen](../dev/graphics_reference_revision_contract.md).

Historische Defaults werden bei Umsetzung gezielt revidiert: unbekannte
Kampagnenorte sollen schwarz beginnen statt pauschal bekanntem Terrain;
Zielklick soll nicht mehr unmittelbar Quantum/Warp starten; im Skirmish werden
die bislang dokumentierten äußeren Zusatzbetten gegen den neuen Raumwunsch
geprüft. Aktuelle Nutzerwünsche haben bei diesen Konflikten Vorrang.

## Betroffene Dateien, Prüfung und Risiken

Die konkreten Einstiegspunkte, Paketabhängigkeiten und lokalen Prüfwege stehen
im Arbeitsplan. Dieser Planungsauftrag bearbeitet ausschließlich Markdown:
diese Masterliste, den Plan, Verweise und den Dokumentationsstatus.

Lokale Prüfung: Vollständigkeit L01–L23 einschließlich Unterpunkten, vollständige
Paketzuordnung, gültige Links, widerspruchsfreie Abhängigkeiten und unveränderte
Produktdateien. Keine Godot-/Spieltests als Ergebnis dieser Planung behaupten.

Risiken: mehrere abweichende Arbeitsstände und frühere unvollständige Kandidaten;
Bestands-/Crew-Duplikation durch UI-Parallelzustand; Sichtlecks durch Marker,
Kartenvorschau oder Dächer; Maßstabsänderung ohne passende Navigation;
Performancebehauptungen ohne vergleichbare Messung.

## Herkunft und Arbeitsstand

Quelle ist die vollständige Rückmeldung dieses Chats vom 14.11.2026 bis zum
ausdrücklichen Auftrag „Erst mal nur planen, noch nichts umsetzen“.
Die anfängliche Teilliste unter
[PLAYTEST_CAMPAIGN_CONTROLS_2026_11_14.md](PLAYTEST_CAMPAIGN_CONTROLS_2026_11_14.md)
wird für diesen Gesamtumfang durch diese Masterliste ergänzt und abgelöst.

Dokumentationsbranch: `task/playtest-rework-plan-20261114`, Basis `c27528594` aus
dem zuvor offenen Review-/Dokumentationsstand. Er ist keine neue Produktbasis.
Der zuvor im Chat ermittelte R2-Build verweist auf `8571be32c`; inzwischen steht
das lokale `main` auf `03cdccc51` (Momentaufnahme bei Planerstellung).
Vor Umsetzung ist AP0 verbindlich.

Früher begonnene Quell-/Teständerungen liegen separat unter
`C:/dev/SternenBuergerchen-worktrees/playtest-r2-controls-20261114` auf
`task/playtest-r2-controls-20261114`. Sie werden durch diesen Plan weder
fortgesetzt noch zurückgesetzt, integriert oder als abgenommen ausgewiesen.
