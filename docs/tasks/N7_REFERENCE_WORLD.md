# N7 – Referenzstil, Startwelten und Ebenen

## Verbindlicher Auftrag vom 21.09.2026

Das ursprüngliche Mars-Diorama bestimmt die Landschaft. Die sechs neueren Bilder bestimmen Systemkarte, Dossier, Heimatbasis und Freihafen. Farbe und einzelne Felsen allein erfüllen den Auftrag nicht. Referenz und tatsächlicher Spiel-Screenshot müssen direkt nebeneinander bewertet werden. N6 bleibt die ausgelieferte Version; dieser Branch ist ein Zwischenstand.

## Bildvergleich und Abnahmekriterien

- **Landschaft:** zusammenhängende, unregelmäßig geschichtete Felswände und Plateaus statt gleichförmiger Einzelkegel. Geröllfelder und kleine Senken mit bewusst freigehaltenen Wegen. Dichte sichtbar aus der normalen Spielkamera, nicht nur beim maximalen Zoom. Echte Hindernisse werden gemeinsam für Wegfindung und Darstellung definiert.
- **Heimatbasis:** zusammenhängender Baukörper, cremefarbene Wandpaneele mit orangefarbenem Band, dunklere Sockel, warme Lampen. Unterkunft mit Bettzeug/Spinden, Lager mit gefüllten Regalen, Werkstatt mit Werkzeugwand und Kleinteilen, Aufenthalt mit Küche, Tisch und persönlichen Dingen. Leitungen und beleuchtete Wege verbinden Landefeld, Versorgungsanlagen und Gebäude. Ausbauflächen bleiben frei.
- **Freihafen:** Hallen mit sichtbaren Ladebuchten, Lagerregalen und Dachdetails; Containergruppen, Umschlaghof, Bodenmarkierungen, Büro, Zaun mit Tor, Tanks und Funkmast. Details erzählen eine Nutzung und sind nicht gleichmäßig zufällig verteilt.
- **Systemkarte:** ruhiger dunkler Weltraum, großer leuchtender Stern, plastische Planeten, gekrümmte Bahnen, dichter diagonaler Asteroidengürtel. Gut zuordenbare Standortanker, rechte Zielkarte mit Vorschaubild und echten Reisevoraussetzungen, untere Schiffsinformation. Keine Texturen mit eingebrannten Beispielwerten.
- **Dossier:** Crewporträts links, große echte Figur mittig, Ausstattungskacheln unten, rechts tatsächliche Container. Keine erfundenen Werte und keine ungeprüfte Verwendung von Konzeptbildtext als Spielregel.

Abnahme erst anhand echter Aufnahmen von Basis, Geländeüberblick, Handelszentrum, Systemkarte und Dossier bei vergleichbarem Bildausschnitt. Ein Farbwechsel oder ein Konzeptbild im Bericht zählt nicht als umgesetzte Spielgrafik.

## Drei zusätzliche Startwelten – Vorschlag, noch nicht implementiert

Arbeitstitel: **Frostmark** (Eis/heller Fels), **Schlacke** (dunkler Basalt) und **Grünschiefer** (grünliche Mineralwelt). Zusammen mit Rostwelt vier mögliche Heimatplaneten. Jeder besitzt eine begehbare Startbasis, mindestens einen sicheren Handelskontakt und eine erste Ressourcen-/Bergungsregion. Gleiche nutzbare Startmittel und vergleichbare Wege; Rohstoffschwerpunkte unterscheiden spätere Handelsrouten.

Die Startauswahl belegt einen freien Heimatplatz mit Mensch oder KI. Dafür braucht der Kern Fraktionen, Eigentum, separate Lager/Geldstände, einen Heimatort je Fraktion und eine validierte Startplatzbelegung. Die bestehenden zwei Koop-Commander dürfen weiterhin dieselbe Crew führen; getrennte Starts sind ein anderer Sitzungsmodus. Ob auch Koop getrennte Heimatbasen erlauben soll, ist beim Nutzer angefragt. Keine erfundenen KI-Fortschritte: Eine erste KI muss dieselben Befehle/Materialregeln tatsächlich ausführen.

Erst Besitz und aktive Regionen simulieren, dann Startplätze freigeben. Drei zusätzliche gemalte Planeten wären nur Dekoration und dürfen nicht als erledigt gelten.

## Bunker: ein Einsatzort, zwei Ebenen – noch nicht implementiert

Ein Bunker erhält eine dauerhafte Einsatz-ID mit `surface` und `lower` als Ebenen. Oberfläche und Untergeschoss bleiben im selben Einsatzzustand. Aufzug transportiert ausgewählte Figuren; Schiff und zurückgelassene Crew bleiben oben. Gegner, Beute und Arbeiten bleiben auf ihrer Ebene erhalten.

Ein Ebenenschalter **Oberfläche / Untergeschoss** verändert nur den Kamerablick. Er teleportiert keine Crew und darf unbekannte Räume nicht aufdecken. Auswahl, Porträts und Aufzug zeigen die Ebene. Bodenbefehle und Schüsse prüfen die Ebene; Wegplanung verbindet die beiden Navigationsbereiche ausschließlich über den Aufzug. Kamera merkt sich den Ausschnitt pro Ebene.

Für Performance darf Innenraumgeometrie verzögert aufgebaut und die nicht betrachtete Ebene ausgeblendet werden. Das ist kein zweiter Reiseort und kein globaler Wechsel sämtlicher Figuren. Als Übergang dürfen interne alte IDs bestehen, aber nicht das bisherige globale Region-Wechselverhalten.

Save-Migration: die drei bisherigen Ober-/Untergrundpaare auf Einsatz-ID und Ebene abbilden; Crew, Schiff, Beute und Gegner erhalten. Test: Person A unten, Person B oben, unten kämpfen, Ansicht wechseln, speichern/laden, Koop-Gast wechselt Ansicht unabhängig. Dieser Kernumbau muss vor einer bloßen Umbenennung der UI erfolgen.

## Spielerführung

Eine priorisierte Hilfe zur Zeit, als beschrifteter Pfeil am relevanten Objekt. Anfang: neuer Auftrag über dem PC. Rückkehr: Blackbox am Lager entladen; nach Entladung Abgabe/Belohnung. Erledigte Schritte verschwinden aus bestätigtem Zustand. Lokale Anzeigeeinstellung: sanfte Bewegung, statisch, aus. Keine schnelle Blinkfolge. Ein Marker ist keine automatisch ausgeführte Aktion.

## Forschung und Baupläne

Zentrale dauerhaft erreichbare Ansicht. Vorhandene Rezepte und reale Werkbank-/Technik-/Materialvoraussetzungen anzeigen; vorhandene Baupläne, noch fehlende Baupläne und noch gar nicht implementierte Forschung deutlich unterscheiden.

Ziel ist ein grafischer Baum mit auswählbaren Knoten und nachvollziehbaren Kanten. Erste echte Kette: Bergungsauftrag → Blackbox im Lager → Abgabe → Schneider-Bauplan; parallel Werkbankausbau → Werkbank II; beides plus Technik/Material → Herstellung. Forschungsraum, Arbeitspersonal, Forschungskosten und weitere Äste benötigen neue autoritative Regeln und werden nicht durch eine UI-Liste simuliert.

## Bereits lokal umgesetzt, kein N7-Release

- Weltmarker am Auftragscomputer bzw. Lager aus bestätigtem Zustand. Sanft/statisch/aus über System, Einstellung lokal gespeichert.
- Bauplanübersicht im Header mit tatsächlichen Rezepten, Freischaltungen und Materialständen. Noch kein vollständiger grafischer Forschungsbaum.
- Erste Systemkarten-Komposition mit Stern, facettierten Planeten, Bahnen, Gürtel und Standortverbindungen. Noch ohne finale Illustrationen/Zielvorschauen.
- Erste Paneel-/Lampenänderungen, dunklere Rostpalette, feinere Felsstufen, authored Felsumrisse am Heimatort und flache Geröllinseln. Noch deutlich unter der Referenzdetaildichte.
- Drei Startplaneten, Fraktions-/KI-Starts, echter gemeinsamer Bunkerebenenzustand, reichere Möblierung und finales Dossier sind offen.

## Reihenfolge

1. Heimatbasis mit umgebender Landschaft und Systemkarte bis zum direkten Referenzvergleich fertigstellen; kein Ausrollen eines schwachen Stils auf alle Karten.
2. Freihafen/Handelsposten und Dossier mit demselben Asset-/UI-System ausarbeiten.
3. Bunkerebenen samt Migration, getrennter Crewpositionierung und Koop-Ansichten.
4. Fraktionen, regionale Simulation und Startauswahl; dann drei voll nutzbare Startwelten und erste regelgebundene KI.
5. Forschungsmechanik ausbauen; Bauplanansicht in den vollständigen grafischen Baum überführen.

Keine N7-Veröffentlichung und keine Erledigt-Markierung für die Gesamtanforderung vor diesen Nachweisen. Alte erfolgreiche N6-Prüfungen bleiben historische Evidenz.
