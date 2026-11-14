# Vollständige Änderungsliste – Playtest vom 14.11.2026

**Status: vollständig erfasst, am 14.11.2026 durch ein Review ergänzt (L24–L25 und Kennzeichen [R]); Umsetzung vom Nutzer am 14.11.2026 beauftragt, paketweise nach Arbeitsplan ab AP0.**

Auftragsstand: Die Liste wurde zunächst nur als Planung erfasst („Erst mal nur planen“). Am 14.11.2026 hat der Nutzer zusätzlich beauftragt, (1) die im Review gefundenen Logikfehler und Lücken in diese Liste einzuarbeiten und (2) danach den Spielcode entsprechend zu ändern und das Spiel spielbarer zu machen. Die Umsetzung erfolgt paketweise nach dem Arbeitsplan und beginnt mit AP0. Alle Checkboxen beschreiben offene Zielanforderungen; sie sind keine Aussage, dass der aktuelle Code die Funktion überhaupt nicht besitzt.

Arbeitsplan: [Arbeitspakete und Reihenfolge](../superpowers/plans/2026-11-14-playtest-rework.md).
Die Nummern **L01–L23** bleiben für Zuordnung und spätere Abnahme stabil.
**L24–L25** und alle mit **[R]** markierten Unterpunkte stammen aus dem Review vom 14.11.2026. Wo ein [R]-Punkt eine ursprüngliche Formulierung ersetzt, steht das ausdrücklich dabei.

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

Umfang sind die folgenden 25 Punkte samt Unterpunkten. Seit dem Umsetzungsauftrag vom 14.11.2026 dürfen Quell- und Testdateien paketweise geändert werden. Weiterhin gilt: kein Mainmerge und kein Release-/Exportbuild ohne ausdrückliche Freigabe, keine Änderung echter Spielstände oder Profile und keine Asset- oder Grafikerzeugung in diesem Strang (siehe Abgrenzung zur Grafik-Überarbeitung). Die Umsetzung soll vorhandene Systeme wiederverwenden; neue Wirtschaft, neue allgemeine Raumkampfsimulation und eine komplette Engine-/Architekturerneuerung sind keine impliziten Zusatzaufträge.

## Verbindliche Prioritäten – Ergänzung des Nutzers

**Keine Rückwärtskompatibilität für alte Savegames erforderlich.** Die spätere
Umsetzung darf bestehende Spielstände und Speicherformate inkompatibel machen.
Keine Migrationen, Kompatibilitätsschichten oder Altformat-Fallbacks allein zum
Erhalt alter Savegames einplanen. Ein Neustart mit einem neuen Spielstand ist
akzeptiert. Speichern und Laden neu erzeugter Spielstände muss weiterhin
korrekt funktionieren; die Freigabe ist kein Auftrag, vorhandene Dateien zu
löschen oder echte Profile für Tests zu überschreiben.

**Performance hat hohe Priorität und ist ein verbindliches Entwurfs- und
Abnahmekriterium für jedes Arbeitspaket.** Flüssige Bedienung, stabile
Framezeiten und wenige Ruckler werden von Anfang an berücksichtigt und
gemessen. Performance nicht erst am Ende in AP15 behandeln. Zusätzliche
Grafikeffekte und Komfortfunktionen dürfen diese Priorität nicht unterlaufen;
bei Zielkonflikten eine weniger aufwendige Variante vorziehen.

## Abgrenzung zur Grafik-Überarbeitung (parallel laufender Chat) [R]

Im selben Projekt überarbeitet ein zweiter Chat Karten, Spielgrafik und UI-Optik anhand der Referenzbilder. Damit sich beide Stränge nicht überschreiben:

- **Dieser Strang (Bedienung und Logik):** Verhalten, Regeln, Eingabe, Abläufe, Texte und Begriffe sowie Daten- und Zustandslogik aller Punkte L01–L25.
- **Grafik-Strang (Optik):** Aussehen von Gelände, Karten, Modellen, Materialien, Shadern, Symbolen und UI-Stil. Bei gemischten Punkten liefert er nur die Optik: L11 (Satellit, Furche, Trümmer), L14 (schwere Rüstung), L18 (Aussehen und Maßstab der Assets), L19 (Dachmodelle), L20 (Schiffssymbole), L23 (Aussehen der Warp-Blase).
- **Für den Grafik-Strang nur lesend:** diese Masterliste, der Arbeitsplan sowie die Regeln zu Sicht und Markern (L12), Dachlogik (L19) und Reisetiming (L22, L23). Änderungswünsche dazu als Notiz melden, nicht selbst ändern.
- **Für diesen Strang nur lesend:** `shaders/`, Modell-, Textur- und Materialdateien, Blender-Quellen und die Referenzgalerie.
- **Geteilte Dateien** (`scripts/terrain/terrain_map_3d_view.gd`, `scripts/meta/explorable_homebase.gd`, `scripts/meta/homebase_operations_presenter.gd`): nie gleichzeitig bearbeiten; wer beginnt, trägt es vorher in die Abstimmungsnotiz ein.
- **Arbeitsort:** jeder Strang in eigenem Worktree und eigenem `task/`-Branch, nicht im Hauptcheckout `C:/dev/SternenBuergerchen`. Dort liegen ältere uncommittierte Änderungen vom 10.–12.11. an `terrain_map_3d_view.gd`, `frontier_ground.gdshader`, `frontier_art_geology.gd`, `explorable_homebase.gd` und `mission_test_setup.gd`; sie bleiben unangetastet, bis der Nutzer über sie entscheidet.
- **Abstimmungsnotiz:** Projektdokument „Abstimmung Bedienung und Grafik“ im Claude-Projekt „sternenbürger“.

## L01 – Erste Kampagnenmission / Datapad

- [ ] Beheben, warum das geborgene Datapad in Anjas Inventar nicht hochgeladen werden kann.
- [ ] Upload an der Heimatbasis klar auffindbar machen.
- [ ] Abgabe aus dem tatsächlichen Personen-, Schiffs- oder Basisinventar ermöglichen.
- [ ] Missionsabschluss und Belohnung dürfen nur einmal ausgelöst werden.
- [ ] **[R]** Eine an der Heimatbasis im gelandeten Schiff sitzende Person (auch die Pilotin auf ihrem Funktionsplatz) gilt für den Upload als lokal erreichbar; sie muss dafür nicht erst absitzen.
- [ ] **[R]** Upload zusätzlich per Drag-and-drop: Datapad auf die Auftragskarte oder das Terminal ziehen. Die sichtbare Terminalaktion bleibt als zweiter Weg; ein weiterer Button kommt nicht hinzu.
- [ ] **[R]** Das Datapad als Missionsgegenstand schützen: nicht verkauf- oder wegwerfbar; fällt der Träger aus, bleibt es am Ort bergbar. Die Mission darf dadurch nicht unlösbar werden.
- [ ] **[R]** Ist der Upload nicht möglich, den konkreten Grund nennen, z. B. „Datapad liegt im Lager der Cutlass, Schiff nicht an der Basis“.

## L02 – Anflug, Abflug und Orbitübergang

- [ ] Anflug sichtbar außerhalb der Bodenkarte beginnen.
- [ ] Dem ausgewählten Anflugwinkel folgen.
- [ ] Beim Abflug sichtbar bis zum Kartenrand und darüber hinaus fliegen.
- [ ] Abflugrichtung wählbar machen; alternativ den Anflug umgekehrt verwenden.
- [ ] Erst nach dem Verlassen der Bodenkarte auf die zugehörige OM-/Orbitkarte wechseln.
- [ ] Übergang und Weiterflug verständlich darstellen.
- [ ] Automatik umschaltbar machen: Bei freier Route automatisch weiterfliegen; ausgeschaltet auf der OM-Karte auf den nächsten Befehl warten. Diesen Ablauf hat der Nutzer ausdrücklich bestätigt.
- [ ] **[R]** „Freie Route“ bedeutet: eine bereits ausdrücklich befohlene Reise (L22) ohne Begegnung oder Hindernis. Die Automatik setzt nur solche Reisen fort und erzeugt nie selbst ein Ziel.
- [ ] **[R]** Bleiben beim Abflug eigene Personen auf der Bodenkarte zurück, vorher warnen („3 Personen bleiben zurück“) und die Ansicht nicht zwangsweise auf die Orbitkarte wechseln; der Wechsel ist dann eine angebotene Aktion.
- [ ] **[R]** Auf einer noch unerkundeten Karte (L12) wird vor dem Anflug nur die Anflugrichtung gewählt; der Landeplatz wird erst festgelegt, wenn der Anflug Gelände aufgedeckt hat. Keine Landeplatzauswahl, die unbekanntes Gelände verrät.
- [ ] **[R]** Anflug- und Abflugrichtung mit derselben Geste wählen: einen Richtungspfeil zum Kartenrand ziehen. Ohne Eingabe gilt: Abflug ist der umgekehrte Anflug.
- [ ] **[R]** An- und Abflug lassen sich beschleunigen (Taste halten oder Zeitraffer), ohne ein zweites Reisetiming einzuführen.

## L03 – Aufsitzen, Absitzen (Ein-/Aussteigen) und direkte Befehle

- [ ] Hängenbleiben am Schiffseinstieg beheben.
- [ ] Nach dem Aussteigen unmittelbar Rechtsklickbefehle für Personen beziehungsweise Trupps ermöglichen, entsprechend dem vorhandenen Basis-/Taktikbedienpfad.
- [ ] Buccaneer: Einstieg am Cockpit.
- [ ] Cutlass: Einstieg über die Heckklappe.
- [ ] Den tatsächlichen Weg zum Einstieg und das Einsteigen sichtbar zeigen.
- [ ] **[R]** Nach dem Absitzen sind die abgesessenen Personen beziehungsweise ihr Trupp automatisch ausgewählt, damit der erste Rechtsklick sofort ein Befehl ist.
- [ ] **[R]** Aufsitzen im Feld: Trupp oder Person auswählen, Rechtsklick auf das Schiff. Jede Person kehrt auf ihren zuletzt belegten Platz zurück, sofern er frei ist; sonst gilt die Platzregel aus L06.
- [ ] **[R]** Soll das Schiff starten, während zugewiesene Personen noch zu ihm laufen, wird nicht still gestartet: Hinweis mit der Wahl „warten“ oder „ohne sie starten“; beim Start ohne sie werden ihre reservierten Plätze frei.

## L04 – Schaltflächen und Klickflächen

- [ ] Auftragsannahme über die gesamte sichtbare Schaltfläche ermöglichen.
- [ ] Ausreichend große Klickflächen verwenden; nicht nur Fähnchen oder Symbol anklickbar machen.
- [ ] X-/Schließen-Schaltflächen über ihre gesamte sichtbare Fläche zuverlässig bedienbar machen.
- [ ] **[R]** Eine Mindestgröße für Klickflächen in AP1 verbindlich festlegen und in den drei Zielauflösungen prüfen (Vorschlag: 32 × 32 px bei 1920 × 1080, mit der UI-Skalierung mitwachsend).
- [ ] **[R]** Fenster und Dialoge zusätzlich mit Esc schließen; Esc schließt immer nur das oberste Fenster.

## L05 – Trupp & Ausrüstung / Basislager

- [ ] Charakterdatenblatt mit persönlicher Ausrüstung ungefähr halb so breit gestalten.
- [ ] Rechts daneben eine ausreichend große Lagerspalte für den tatsächlichen Basisbestand anzeigen; das Basislager erhält mindestens den Platz einer vollwertigen Spalte.
- [ ] Zwischen Basislager und den Lagern einzelner Schiffe wechseln können; Schiffsauswahl unter beziehungsweise bei dieser Lageransicht anbieten.
- [ ] Gegenstände per Drag-and-drop zwischen persönlichem Inventar, Basislager und Schiffslager hinein- und herausziehen können.
- [ ] Personen durch Herausziehen ins Personal aus dem Fireteam entfernen.
- [ ] Charakterdetails per Doppelklick auf die Personenkarte öffnen.
- [ ] Die Buttons „Aus Trupp entfernen“ und „Charakter ansehen“ entfernen.
- [ ] **[R]** Truppverwaltung vollständig per Ziehen: Person aus dem Personal auf einen Trupp ziehen (hinzufügen), von Trupp zu Trupp ziehen (direkt wechseln), auf das Feld „Neuer Trupp“ ziehen (Trupp anlegen).
- [ ] **[R]** Einen Gegenstand direkt auf eine Personenkarte in der Truppliste ziehen legt ihn in deren Inventar, ohne das Datenblatt zu öffnen.
- [ ] **[R]** Übertragungen nur zwischen Ablagen am selben Ort: Ein Schiff, das nicht an der Basis steht, und Personen im Einsatz bleiben sichtbar, sind aber gesperrt und nennen den Grund.
- [ ] **[R]** Die beiden Buttons erst entfernen, wenn die Ziehziele beim Ziehen sichtbar beschriftet aufleuchten (L24); sonst fehlt jeder Hinweis auf die Funktion.

## L06 – Flugdeckansicht

- [ ] Dieselbe tatsächliche Basis zeigen wie beim Basiserkunden.
- [ ] Passenden Zoom verwenden und die Darstellung sauber in den Fensterrahmen einpassen.
- [ ] Personen beim Hinlaufen und Einsteigen sichtbar lassen.
- [ ] Die persönliche Lager-/Ausrüstungsansicht im Flugdeck weglassen.
- [ ] Personal-, Trupp- und Schiffsbedienung schmaler gestalten.
- [ ] Einzelpersonen und ganze Trupps per Drag-and-drop auf ein Schiff ziehen können, auch wenn der Pilot weiterhin zu einem Trupp gehört.
- [ ] Alle angezeigten Schiffsdetails, Personen und Funktionsplätze auf das ausgewählte Schiff beziehen.
- [ ] **[R]** Die Flugdeckansicht zeigt die Basis immer mit offenen Dächern (L19), damit Schiffe und Laufwege nicht verdeckt sind.
- [ ] **[R]** Ziehen auf das Schiff allgemein belegt den ersten passenden freien Platz (zuerst der bisherige Platz, dann ein Passagierplatz, ein Funktionsplatz nur bei Eignung); Ziehen auf einen bestimmten Platz belegt genau diesen.
- [ ] **[R]** Ganzer Trupp auf ein Schiff: Passen nicht alle hinein, wird nichts still teilweise verteilt; das Schiff zeigt, wie viele Plätze fehlen, und der Spieler entscheidet.
- [ ] **[R]** Zugewiesene, aber noch laufende Personen erscheinen auf ihrem Platz als „unterwegs“ (reserviert), nicht als bereits an Bord.

## L07 – Schiffsplätze als Karten

- [ ] Porträtkarten und sichtbare belegbare Plätze statt der bisherigen Dropdownbedienung verwenden.
- [ ] Einen klar erkennbaren Pilotenslot anzeigen.
- [ ] Bei der Cutlass zusätzlich einen Turmslot anzeigen.
- [ ] Bei der Cutlass zunächst vier Passagier-/Jump-Seat-Slots anzeigen.
- [ ] Personen per Drag-and-drop zuweisen, zwischen Plätzen verschieben und herausziehen können.
- [ ] Turmbesetzung ausdrücklich bedienbar machen.
- [ ] **[R]** Plätze, Platzarten und Einstieg kommen aus der Schiffsdefinition des jeweiligen Typs, nicht aus fest verdrahteter Oberfläche; die Buccaneer zeigt entsprechend nur ihre tatsächlichen Plätze.
- [ ] **[R]** Während eine Person gezogen wird, leuchten die Plätze nach Eignung auf (geeignet oder nicht geeignet, mit kurzem Grund nach den vorhandenen Eignungsregeln), z. B. der Pilotenslot bei Piloteneignung.
- [ ] **[R]** Ziehen auf einen belegten Platz tauscht die beiden Personen.
- [ ] **[R]** „Turmbesetzung bedienbar“ heißt: Turmschütze zuweisen, tauschen und abziehen; ein unbesetzter Turm wird als unbesetzt angezeigt. Eine neue Turm-Kampfmechanik ist nicht gemeint.

## L08 – Aufsitzen / Absitzen

- [ ] „Aufsitzen“ und „Absitzen“ durchgängig als Begriffe verwenden.
- [ ] Beim allgemeinen Absitzen die Personen auf Passagier-/Jump-Seat-Plätzen absitzen lassen.
- [ ] Pilot und Turmschütze auf ihren Funktionsplätzen sitzen lassen.
- [ ] **[R, ersetzt „Aufstehen“]** Einen Funktionsplatz freigeben heißt „Platz verlassen“ (statt „Aufstehen“, das zu leicht mit „Aufsitzen“ verwechselt wird). Hauptweg ist Ziehen: Pilot oder Turmschütze auf einen Passagierplatz ziehen. Rechtsklick auf das Porträt bietet „Platz verlassen“ als zweiten Weg.
- [ ] Nach dem Verlassen des Funktionsplatzes diese Personen beim anschließenden Absitzen ebenfalls berücksichtigen.
- [ ] **[R]** Sind alle Passagierplätze belegt, tauscht das Ziehen auf einen belegten Platz die beiden Personen (L07). „Platz verlassen“ per Rechtsklick lässt die Person dann am gelandeten Schiff direkt absitzen und ist im Flug mit Grund gesperrt. Kein unsichtbarer Zusatzplatz.
- [ ] **[R]** Hat ein Schiff keine Passagierplätze (z. B. die Buccaneer, falls ihre Definition nur den Pilotenplatz enthält), sitzt bei „Absitzen“ der Pilot ab; der Befehl darf nie wirkungslos bleiben.
- [ ] **[R]** Eine einzelne Person sitzt ab, indem ihr Porträt aus dem Schiff herausgezogen wird.

## L09 – Anpassbare Anordnung der Oberfläche

- [ ] Spalten und Bereiche möglichst verschiebbar beziehungsweise in ihrer Breite anpassbar machen.
- [ ] Dem Lager ausreichend Platz geben.
- [ ] Den Flugdeckbereich kompakter halten.
- [ ] Die bestehende Leiste als brauchbare Grundlage beibehalten und gezielt verbessern.
- [ ] **[R]** „Dem Lager ausreichend Platz geben“ und „Flugdeckbereich kompakter halten“ werden über L05 beziehungsweise L06 abgenommen, nicht doppelt.
- [ ] **[R]** Spaltenbreiten und Anordnung sind Benutzereinstellungen und gelten für alle Spielstände; sie gehören nicht in den Spielstand.

## L10 – NPC-Meldungen

- [ ] Meldungen als Sprechblasen an der zugehörigen Fireteamkarte anzeigen.
- [ ] Klar erkennen lassen, welcher NPC spricht.
- [ ] Verständliche Sprache statt kryptischer Kürzel und technischer Statusmeldungen verwenden.
- [ ] **[R]** Sprecher ohne Fireteamkarte (Pilot, Turmschütze, Basispersonal) erhalten die Sprechblase an ihrer Porträt- beziehungsweise Platzkarte; ist keine Karte sichtbar, erscheint die Meldung mit Name und Rolle im Meldungsverlauf.
- [ ] **[R]** Mehrere gleichzeitige Meldungen werden gereiht und nach Dringlichkeit geordnet; ein Meldungsverlauf hält verpasste Meldungen nachlesbar.
- [ ] **[R]** Ein Klick auf eine Sprechblase wählt den Sprecher aus und zeigt ihn auf der Karte.

## L11 – Satellitenabsturzstelle

- [ ] Einen erkennbar abgestürzten Satelliten darstellen.
- [ ] Eine Einschlag- beziehungsweise Schleiffurche im Boden ergänzen.
- [ ] Passende Trümmer und Absturzspuren hinzufügen.
- [ ] Die Absturzstelle tatsächlich suchen lassen; den Standort nicht vorab durch den Zielmarker verraten.
- [ ] **[R]** Statt des genauen Zielmarkers ein grobes Suchgebiet angeben, damit die erste Mission ohne Marker lösbar bleibt.
- [ ] **[R]** Schleiffurche und Trümmer dienen als Spur zur Absturzstelle, werden aber erst sichtbar, wenn sie tatsächlich gesehen wurden (L12).
- [ ] **[R]** Der Marker erscheint, sobald eine eigene Person die Absturzstelle sieht; der Auftragstext wechselt dann von „suchen“ auf „bergen“.

## L12 – Erkundung und Nebel des Krieges

- [ ] Noch nicht erkundete Bereiche vollständig schwarz darstellen.
- [ ] Bereits erkundete, aktuell unbeobachtete Bereiche abgedunkelt darstellen.
- [ ] Aktuell beobachtete Bereiche hell und mit den tatsächlich sichtbaren Informationen anzeigen.
- [ ] Unbekannte Kampagnenkarten zunächst schwarz lassen.
- [ ] Beim Anflug nur tatsächlich wahrgenommene Bereiche aufdecken.
- [ ] Verborgene Ziele und Marker erst nach ihrer Entdeckung anzeigen.
- [ ] **[R]** Laufbefehle in unerkundetes Gebiet dürfen durch Routenvorschau, Zielablehnung oder Wegform keine unbekannten Hindernisse verraten; angezeigt wird höchstens der Weg bis zur Grenze des Bekannten.
- [ ] **[R]** Hover, Auswahl und Kontextmenü liefern über schwarzen Bereichen keine Information.
- [ ] **[R]** Eine Liste der von Beginn an bekannten Orte führen (mindestens die Heimatbasis und Port Olisar, siehe L25); alle anderen Karten starten schwarz.
- [ ] **[R]** Der Erkundungsstand je Karte gehört in den Spielstand.

## L13 – Aussagekräftige Hover-Informationen

- [ ] Auf Personen-, Trupp- und Detailkarten zusätzliche nützliche Informationen anzeigen.
- [ ] Beim Überfahren eines NPCs in der Basis Rolle und Fähigkeiten zeigen, beispielsweise seine Piloteneignung.
- [ ] Namenswiederholungen und Hinweise wie „Person auswählen“ durch hilfreiche Angaben ersetzen.
- [ ] Fähigkeiten und Einsatzmöglichkeiten schnell erkennbar machen.
- [ ] **[R]** Gesperrte Aktionen und Ziehziele nennen im Hover den Grund und was fehlt (L24).

## L14 – Skirmish-Darstellung

- [ ] Prüfen und korrigieren, warum Betten teilweise außerhalb der Gebäude stehen.
- [ ] Platzierung und Zuordnung der Betten zu den vorgesehenen Räumen überprüfen.
- [ ] Darstellung der schweren Rüstung prüfen und überarbeiten.
- [ ] **[R]** Für die schwere Rüstung fehlt die Beobachtung, was genau stört (Proportion, Clipping, Material, Lesbarkeit). Vor der Umsetzung vom Nutzer benennen lassen; die Optik liegt beim Grafik-Strang.

## L15 – Performance

- [ ] Performance mit hoher Priorität in jedem Arbeitspaket berücksichtigen; weiterhin auftretende Ruckler und langsame Abläufe untersuchen und beheben.
- [ ] Besonders Basiserkunden sowie das Öffnen und Aktualisieren der Bedienbereiche prüfen.
- [ ] Verbesserungen mit vergleichbaren Vorher-/Nachher-Messungen nachweisen.
- [ ] **[R]** Die Vorher-Messung entsteht in AP0, bevor irgendein Paket Code ändert; dort werden auch Referenzszenen und Zielbudgets festgelegt.
- [ ] **[R]** Lager-, Personal- und Platzlisten aktualisieren nur geänderte Einträge; kein Neuaufbau der ganzen Liste bei jeder Änderung oder jedem Ziehen.

## L16 – Dauerhaft aufklappbare Basismenüs

- [ ] Untermenüs beim Bedienen offen halten.
- [ ] **[R, ersetzt den kleinen Plus-/Minus-Schalter]** Der Auf-/Zuklapp-Schalter am Navigationsbutton erfüllt die Mindestklickfläche aus L04 und zeigt den Zustand als Pfeil (▸/▾) statt als Plus/Minus. Hat der Navigationsbutton keine eigene Aktion, klappt die ganze Buttonfläche auf und zu. Grund: Ein kleiner Schalter widerspricht L04, und Plus/Minus wird als „hinzufügen/entfernen“ gelesen. Der ursprüngliche Wunsch (kleiner Plus-/Minus-Schalter, beispielsweise links unten) bleibt als Alternative für die Sichtprobe dokumentiert.
- [ ] Untermenüs per Klick auf- und zuklappen können.
- [ ] Ein aufgeklapptes Menü erst bei ausdrücklichem Schließen wieder einklappen.
- [ ] **[R]** Mehrere Untermenüs dürfen gleichzeitig offen sein; der Auf-/Zu-Zustand ist eine Benutzereinstellung und bleibt über Bildschirmwechsel und Neustart erhalten.

## L17 – Direkter Gefechtsstart

- [ ] Zwei Spielwege klar auswählbar anbieten: strategischer Modus mit Sternkarte, Raumflug, Basisaufbau und Krieg sowie direktes Einzelgefecht.
- [ ] Einzelgefechte ohne Kampagne, Suchaufträge oder vorherigen Basisaufbau starten können.
- [ ] Eine Boden- oder Weltraumkarte auswählen können.
- [ ] Die eigene Startseite wählen können, beispielsweise links, rechts, oben oder unten.
- [ ] Mit einer einsatzbereiten Mannschaft beziehungsweise Flotte starten.
- [ ] Gefechte schnell neu starten können, um Mechaniken selbst auszuprobieren.
- [ ] **[R]** Startseite durch Ziehen der eigenen Truppe an einen Kartenrand der Vorschau wählen; die Vorschau ist fest genordet und damit unabhängig von der Kameradrehung. Der Gegner startet standardmäßig gegenüber.
- [ ] **[R]** Vor dem Start anzeigen, gegen wen gekämpft wird und wodurch das Gefecht endet; dafür vorhandene vorbereitete Szenarien verwenden, keine neue Gegner-KI.
- [ ] **[R]** Einzelgefechte verändern weder den Kampagnenspielstand noch das gespeicherte eigene Team.
- [ ] **[R]** Im Hauptmenü heißen die beiden Wege einheitlich (Vorschlag „Kampagne“ und „Einzelgefecht“, siehe L25).

## L18 – Editor grundlegend überarbeiten

- [ ] Werkzeuge, Auswahl und aktuelle Einstellungen übersichtlich und verständlich darstellen.
- [ ] Eine gut erreichbare Gesamtansicht der Karte anbieten.
- [ ] Den Mauergenerator korrigieren: Platzierung, Verbindungen, Ecken und Ausrichtung.
- [ ] Gelände verständlich anheben und absenken können, mit sichtbarer Höhenangabe und Vorschau.
- [ ] Maßstäbe der Kenney-Assets prüfen und unpassende Größen korrigieren.
- [ ] Personen und Fahrzeuge als Vergleichsobjekte platzieren können, um Größen, Durchgänge und Gebäudeproportionen zu beurteilen.
- [ ] Die bereits gefallende Gestaltung der selbstgebauten Heimatbasis als Grundlage erhalten.
- [ ] **[R]** Jede Bearbeitung ist über die vorhandene Undo-Pipeline rückgängig und wiederholbar (Strg+Z / Strg+Y).
- [ ] **[R]** „Karte testen“ startet die bearbeitete Karte direkt als Einzelgefecht (L17) und kehrt danach in den Editor zurück.
- [ ] **[R]** Der Editor warnt bei Objekten außerhalb ihres Raums oder Gebäudes (z. B. Betten, L14) und bei unerreichbaren Einstiegen oder Startfeldern.

## L19 – Dächer und einsehbare Innenräume

- [ ] Gebäude mit geschlossenem Dach oder offenem Innenraum darstellen können.
- [ ] Die Dachansicht im Editor umschalten können.
- [ ] Unbekannte Außenposten zunächst mit geschlossenem Dach und verborgenem Interieur zeigen.
- [ ] Beim Betreten das Dach ausblenden, damit der Innenraum sichtbar und bedienbar wird.
- [ ] An der Heimatbasis jederzeit eine offene Übersicht ermöglichen.
- [ ] Dort das Dach ausdrücklich wieder einblenden können.
- [ ] **[R]** Das Dach wird pro Gebäude geschaltet, nicht global; als betreten gilt ein Gebäude, sobald eine eigene Person darin ist.
- [ ] **[R]** Bei geschlossenem Dach bleibt ein Befehl in das Gebäude möglich (Rechtsklick auf das Dach setzt ein Ziel im Gebäude), ohne den Innenraum vorab zu zeigen.
- [ ] **[R]** Die Dachansicht ändert nichts an Sicht, Deckung oder Wegfindung.

## L20 – Sternkarte: Schiffsauswahl und Darstellung

- [ ] Schiffssymbole klar als das jeweilige Schiff erkennbar gestalten, insbesondere das Dropship.
- [ ] Verhindern, dass ein erneuter Klick auf das ausgewählte Schiff dessen benötigte Anzeige ungewollt zusammenklappt.
- [ ] Schiffsauswahl, Schiffsdetails und Reiseaktionen eindeutig zusammengehörig darstellen.
- [ ] **[R]** Auswahl klappt nie etwas zu: Ein Klick auf das bereits gewählte Schiff lässt alles, wie es ist. Abwählen nur über Klick ins Leere oder Esc (L24).
- [ ] **[R]** Klären, welches Schiff mit „Dropship“ gemeint ist (L25); die Symbolgestaltung liegt beim Grafik-Strang.

## L21 – Sternkarte: Karten per Doppelklick öffnen

- [ ] Per Doppelklick auf OM, Planet oder Planetoid die zugehörige Karte öffnen.
- [ ] Das Öffnen einer Karte von einem tatsächlichen Reisebefehl trennen.
- [ ] Unbekannte Karten dürfen geöffnet werden, zeigen aber zunächst nur den erlaubten beziehungsweise bereits erkundeten Stand.
- [ ] Noch nicht erforschte Bereiche bleiben schwarz.
- [ ] Port Olisar als bereits erkundeten Ort behandeln; aktuell unbeobachtete Bereiche bleiben durch Nebel des Krieges abgedunkelt.
- [ ] Die fehlenden Karten-/Ortsmarker auf Planetoiden prüfen und ihre Anzeige korrigieren.
- [ ] Bekannte Navigationsmarker von noch unentdeckten Missionszielen unterscheiden.
- [ ] **[R]** L21 darf erst zusammen mit oder nach L22 ausgeliefert werden: Solange ein Einfachklick noch einen Flug startet, würde der Doppelklick die Karte öffnen und zugleich das Schiff losschicken.
- [ ] **[R]** Eine geöffnete unbekannte Karte zeigt statt einer leeren schwarzen Fläche mindestens Name, Kartenart und den Hinweis „noch nicht erkundet“.

## L22 – Sternkarte: Zielwahl und ausdrücklicher Sprungbefehl

- [ ] Ein einfacher Klick auf ein Ziel wählt es nur aus und startet keinen Flug.
- [ ] Beim ausgewählten Schiff einen kleinen, klar erkennbaren Button „Sprung ausführen“ oder eine entsprechend verständliche Reiseaktion anzeigen.
- [ ] Den Flug erst durch diesen ausdrücklichen Befehl starten.
- [ ] Ziel und bevorstehende Reise vor dem Start eindeutig anzeigen.
- [ ] Die Orbit-Automatik aus L02 darf die bloße Auswahl eines neuen Ziels nicht als Reisebefehl behandeln.
- [ ] **[R]** Zusätzlich per Ziehen: Das Schiff auf ein Ziel ziehen wählt dieses Ziel für das Schiff vor; gestartet wird weiterhin erst mit „Sprung ausführen“.
- [ ] **[R]** Ist der Sprung nicht möglich, bleibt der Button sichtbar, ist gesperrt und nennt den Grund (kein Pilot, Ziel nicht erreichbar, Schiff bereits unterwegs).
- [ ] **[R]** Eine vorgewählte Reise lässt sich vor dem Start zurücknehmen; ob und wie eine laufende Reise abgebrochen werden kann, vor der Umsetzung festlegen.

## L23 – Warp-Animation

- [ ] Den Warp-Sprung mit einer sichtbaren Warp-Blase um das Schiff darstellen.
- [ ] Eintritt, Reise und Austritt als zusammenhängenden Ablauf animieren.
- [ ] Das Schiff während der Reise nachvollziehbar durch die Darstellung bewegen.
- [ ] Die Animation etwas langsamer gestalten, damit der Ablauf gut erkennbar ist.
- [ ] **[R]** Die langsamere Animation lässt sich beschleunigen (wie in L02), damit sie beim wiederholten Reisen nicht aufhält.
- [ ] **[R]** In der Oberfläche heißt der Vorgang einheitlich „Sprung“; „Warp-Blase“ bezeichnet nur den Effekt (L25).

## L24 – Einheitliche Bedienregeln und Drag-and-drop [R]

- [ ] Überall gilt dieselbe Grundregel: Linksklick wählt aus, Rechtsklick befiehlt, Doppelklick öffnet, Ziehen ordnet zu oder verschiebt.
- [ ] Auswahl löst nie eine Aktion aus und klappt nie etwas zu (betrifft L16, L20, L22).
- [ ] Beim Ziehen leuchten alle gültigen Ziele beschriftet auf; ungültige Ziele nennen den Grund. Das ersetzt entfallende Buttons als sichtbaren Hinweis (L05).
- [ ] Ziehen beginnt erst nach einer kleinen Mausbewegung (Ziehschwelle), damit ein leicht verwackelter Klick ein Klick bleibt (L04).
- [ ] Esc oder Rechtsklick bricht ein Ziehen ab; Loslassen über einem ungültigen Ziel lässt alles unverändert.
- [ ] Stapel lassen sich beim Ziehen teilen (z. B. Umschalt-Ziehen fragt die Menge ab); mehrere Gegenstände oder Personen lassen sich gemeinsam markieren und ziehen.
- [ ] Volle Ablagen und belegte Plätze werden vor dem Loslassen angezeigt, nicht erst als Fehlermeldung danach.
- [ ] Gesperrte Aktionen bleiben sichtbar und nennen den Grund, statt zu verschwinden.
- [ ] Wo Ziehen genügt, kommt kein zusätzlicher Button hinzu; ein vorhandener zweiter Weg (Rechtsklickmenü, Taste) darf bleiben.
- [ ] Reine Bedieneinstellungen (Spaltenbreiten, aufgeklappte Menüs) sind Benutzereinstellungen; Spielinhalte (Erkundung, Plätze, Lager) gehören in den Spielstand.

## L25 – Begriffe und bekannte Orte [R]

In der Oberfläche wird je Sache genau ein Begriff verwendet. Zeilen mit „zu bestätigen“ sind Vorschläge; AP0 prüft sie gegen Code und vorhandene Anzeigetexte.

| Begriff in der Oberfläche | Bedeutung | Nicht mehr mischen mit | Stand |
| --- | --- | --- | --- |
| Personal | alle Personen der Basis ohne Truppzuordnung | – | festgelegt |
| Trupp | vom Spieler geführte Gruppe; technisch „Fireteam“ | Fireteam, Mannschaft | zu bestätigen: Sind Trupp und Fireteam dieselbe Einheit? |
| Besatzung | Personen auf Funktionsplätzen eines Schiffs (Pilot, Turmschütze) | Crew, Mannschaft | festgelegt |
| Passagiere | Personen auf Passagierplätzen (Jump-Seats) | – | festgelegt |
| Aufsitzen / Absitzen | Schiff betreten / verlassen | Einsteigen, Aussteigen als Befehlsname | festgelegt (L08) |
| Platz verlassen | Funktionsplatz freigeben und an Bord bleiben | Aufstehen | Vorschlag aus dem Review |
| Einstieg | Stelle am Schiff, an der auf- und abgesessen wird (Cockpit, Heckklappe) | – | festgelegt |
| Inventar | was eine Person trägt | Lager, Bestand | Vorschlag |
| Lager | Ablage von Basis oder Schiff (Basislager, Schiffslager) | Inventar, Bestand | Vorschlag |
| Sprung | befohlene Reise auf der Sternkarte | Warp und Quantum (nur Effekt beziehungsweise intern) | zu bestätigen |
| Einzelgefecht | direkt startbares Gefecht ohne Kampagne | Skirmish, direkter Gefechtsstart | zu bestätigen |
| Kampagne | strategischer Modus mit Sternkarte, Raumflug, Basisaufbau und Krieg | strategischer Modus | zu bestätigen |
| Sternkarte / Orbitkarte / Bodenkarte | Systemübersicht / Karte um einen Orbitalmarker (OM) oder Himmelskörper / Karte am Boden | OM-Karte | zu bestätigen: Bedeutung von „OM“ |
| Dropship | unklar, welches Schiff gemeint ist | – | offen |

- [ ] Glossar in AP0 gegen Code und Anzeigetexte prüfen und die Zeilen „zu bestätigen“ mit dem Nutzer klären.
- [ ] Anzeigetexte paketweise an das Glossar angleichen; interne Namen im Code bleiben, wo eine Umbenennung nur Risiko wäre.
- [ ] Liste der von Beginn an bekannten Orte festlegen (L12, L21); die Heimatbasis gehört in jedem Fall dazu, unabhängig von der Namensfrage Asterheim / Port Olisar.

## Dringlichkeit nach Einschätzung des Reviews [R]

Die Einordnung ändert nicht die Paketreihenfolge des Arbeitsplans; sie zeigt nur, was den Spielablauf blockiert.

| Art | Punkte |
| --- | --- |
| Blocker (Spielablauf bricht ab) | L01, L03, L04 |
| Bedienung | L05–L10, L13, L16, L20–L22, L24 |
| Sicht und Erkundung | L11 (Suche), L12, L19 |
| Neue Funktionen | L17, L18 |
| Optik | L11 (Kulisse), L14, L23 |
| Querschnitt | L15, L25 |

## Offene Entscheidungen und Begriffe

- **Ortsname:** Die erste Heimatbasis heißt nach Erinnerung des Nutzers möglicherweise „Asterheim“. Nicht als bestätigte Umbenennung behandeln. „Port Olisar“ und historische Code-/Anzeigevarianten anhand der wirklichen Orts-IDs zuordnen; keine fremde Karte versehentlich umbenennen.
- **Platz verlassen (früher „Aufstehen“):** Durch L07/L08 [R] weitgehend gelöst: Ziehen auf einen Passagierplatz, bei belegtem Platz Tausch; kein unsichtbarer Zusatzplatz. Noch zu bestätigen ist nur der Rechtsklickfall bei vollen Passagierplätzen (Vorschlag: am Boden direkt absitzen, im Flug gesperrt).
- **Dächer:** Was nach Verlassen eines erstmals betretenen Außenpostens geschieht, ist noch nicht festgelegt. Erkunden, aktuelle Sicht und manuelle Dachansicht getrennt halten.
- **Layout:** „Möglichst verschiebbar“ ist keine fertige Spezifikation für beliebige Dockfenster oder dauerhafte Layoutprofile. Konkrete verstellbare Spalten zunächst als Entwurf zeigen.
- **Animation:** Die genaue Warp-Dauer wurde nicht festgelegt; eine langsamere Vergleichsprobe zur Sichtabnahme vorsehen.
- **Startseite:** Durch L17 [R] gelöst: Wahl per Ziehen auf einer fest genordeten Vorschau; die Kameradrehung spielt dafür keine Rolle.
- **Abflugrichtung [R]:** L02 nennt „wählbar“ und „Anflug umgekehrt“ als Alternativen. Vorschlag: beides, mit umgekehrtem Anflug als Standard.
- **Menüschalter [R]:** Pfeil statt Plus/Minus (L16) ist ein Vorschlag; die Sichtprobe entscheidet.
- **Zurückgelassene Personen [R]:** L02 regelt nur Warnung und Ansichtswechsel. Ob die Bodenkarte weiterläuft, solange das Schiff fort ist, ist nicht festgelegt.
- **Reiseabbruch [R]:** Ob und wie eine laufende Reise abgebrochen werden kann (L22), ist offen.
- **Schwere Rüstung [R]:** Die Beobachtung, was genau stört, fehlt (L14).
- **Glossar [R]:** Zeilen „zu bestätigen“ in L25, insbesondere Trupp/Fireteam, Sprung/Warp/Quantum und Dropship.

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

Die konkreten Einstiegspunkte, Paketabhängigkeiten und lokalen Prüfwege stehen im Arbeitsplan. Die Planungs- und Reviewschritte bis einschließlich der Review-Ergänzung vom 14.11.2026 haben ausschließlich Markdown bearbeitet: diese Masterliste, den Plan, Verweise und den Dokumentationsstatus.

Lokale Prüfung der Dokumente: Vollständigkeit L01–L25 einschließlich Unterpunkten, vollständige Paketzuordnung auch der [R]-Punkte, gültige Links und widerspruchsfreie Abhängigkeiten. Für die Umsetzung gelten die Prüfwege des jeweiligen Pakets; ein Dokumentenstand ist kein Nachweis für Godot-/Spieltests.

Risiken: mehrere abweichende Arbeitsstände und frühere unvollständige Kandidaten;
Bestands-/Crew-Duplikation durch UI-Parallelzustand; Sichtlecks durch Marker,
Kartenvorschau oder Dächer; Maßstabsänderung ohne passende Navigation;
Performancebehauptungen ohne vergleichbare Messung.

Zusätzliche Risiken aus dem Review: Sichtlecks über Wegfindung und Routenvorschau; entfallende Buttons ohne sichtbaren Ersatzhinweis; gleichzeitiges Arbeiten von Bedien- und Grafik-Strang an denselben Dateien; weitere Agenten arbeiten zeitgleich in anderen Worktrees desselben Repos (am 14.11. unter anderem an der nativen Navigation).

## Herkunft und Arbeitsstand

Quelle ist die vollständige Rückmeldung dieses Chats vom 14.11.2026 bis zum
ausdrücklichen Auftrag „Erst mal nur planen, noch nichts umsetzen“.
Die anfängliche Teilliste unter
[PLAYTEST_CAMPAIGN_CONTROLS_2026_11_14.md](PLAYTEST_CAMPAIGN_CONTROLS_2026_11_14.md)
wird für diesen Gesamtumfang durch diese Masterliste ergänzt und abgelöst.

Review-Ergänzung vom 14.11.2026 (zweiter Chat): Logikfehler behoben, Lücken geschlossen, L24–L25 ergänzt; alle Änderungen sind mit [R] markiert. Ursprüngliche Nutzerformulierungen wurden nur an vier Stellen geändert und sind dort benannt: Überschrift L03, L08 „aussteigen“, L08 „Aufstehen“ und L16 Plus-/Minus-Schalter. Der Nutzer hat die Review-Funde am 14.11.2026 pauschal zur Einarbeitung freigegeben und anschließend die Umsetzung beauftragt.

Dokumentationsbranch: `task/playtest-rework-plan-20261114`, Basis `c27528594` aus
dem zuvor offenen Review-/Dokumentationsstand. Er ist keine neue Produktbasis.
Der zuvor im Chat ermittelte R2-Build verweist auf `8571be32c`; inzwischen steht
das lokale `main` auf `03cdccc51` (Momentaufnahme bei Planerstellung).
Vor Umsetzung ist AP0 verbindlich.

Früher begonnene Quell-/Teständerungen liegen separat unter
`C:/dev/SternenBuergerchen-worktrees/playtest-r2-controls-20261114` auf
`task/playtest-r2-controls-20261114`. Sie werden durch diesen Plan weder
fortgesetzt noch zurückgesetzt, integriert oder als abgenommen ausgewiesen.
