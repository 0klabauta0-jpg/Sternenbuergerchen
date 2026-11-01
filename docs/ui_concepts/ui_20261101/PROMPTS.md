# Bildgenerator: Auftrag und nachvollziehbare Gestaltung

Erzeugt mit dem eingebauten `image_gen.imagegen`, nicht über eine eigene API-/CLI-Lösung. Die vollständigen, unverändert verwendeten Eingaben stehen in [prompts.json](prompts.json). Alle Ergebnisse sind Konzeptkandidaten vom 01.11.2026.

## Drei Layoutbilder

- **A / Kommandodeck:** dunkle vorhandene Theme-Farben, breite Karte, unten ein gemeinsamer Bereich für Befehl, Haltung, Feuerregel, Ziel und Planausführung. Hypothese: Der nächste Schritt lässt sich in einem Bereich verfolgen.
- **B / Feldtablet:** dieselbe Beispielsituation auf hellen, deckenden Industrieflächen; die Befehle im rechten Panel. Hypothese: ruhiger lesbarer Instrumentencharakter, mit dem möglichen Nachteil einer dominanten hellen Fläche.
- **C / Einsatztafel:** FOB-Vorbereitung mit Personal, Fireteam, Loadout und zugeordnetem Dropship. Hypothese: eine sichtbare Prozessfolge erleichtert das Zuordnen von Bereitschaft und Boarding. Die Hangarillustration ist eine UI-Bühne.

Zwei Bilder aus dem parallelen Grafikpass dienen als Referenzen für Welt und Materialien. Sie wurden im Paket als `references/taktische_rostwelt.png` und `references/aussenposten_stilstudie.png` gesichert. Die Quadratfelder des Weltbilds sind keine UI-Anforderung. Die drei Prompts verlangen ausdrücklich keine Pausefunktion, keine neue Wirtschaft und keine individuelle Soldatensteuerung.

## Sechs Iconbilder

Gemeinsamer Auftrag: ein einzelnes Motiv, echte Transparenz, keine Schrift oder Buttonplatte, Creme/Petrol mit sparsamem Cyan, große Formen und gleichmäßiger Rand. Die Originaldateien bleiben unverändert erhalten.

| Datei | Eingabemotiv | Gestalterische Absicht |
|---|---|---|
| icon_move.png | gerichteter Wegpfeil mit Ortsmarkierung | Bewegung zu einem Ort |
| icon_defend.png | aufrechtes Schild mit Standfläche | Schutz und Positionsbindung |
| icon_flank.png | Pfeilweg um ein Hindernis | seitliches Umgehen statt gerader Bewegung |
| icon_take.png | Flagge auf hexagonalem Zielmarker | Ziel sichern statt Schaden verursachen |
| icon_dropship.png | generischer kompakter Transporter | Transportfunktion ohne neue Schiffsklasse |
| icon_loadout.png | Ausrüstungsweste | Ausrüstung einer Person |

Diese Erläuterungen dokumentieren unsere Vorgaben und die beabsichtigte Bedeutung. Die sichtbare Umsetzung und ihre Grenzen werden in [PRUEFUNG.md](PRUEFUNG.md) bewertet; daraus werden keine unbekannten internen Überlegungen des Bildgenerators abgeleitet.

## Revision A2 nach Nutzerfeedback

Der wiedergefundene Review-Export wählt A für die Mission und C als Staging-Grundlage. Die mündliche Ergänzung verlangt kleinere Buttons, einen flacheren Planbereich, die bisherige linke Truppübersicht und rechte Auswahl-/Transportgruppe sowie keinen Spieltitel oben links. Exakte Eingaben: [prompts_revision2.json](prompts_revision2.json).

- `mockup_a2_kommandodeck_kompakt.png`: A als Bearbeitungsziel, kompakte horizontale Buttons mit kleinem Icon neben Text, reduzierte Zielerklärung und schmale Kopfzeile. Zielgrößen werden als Entwurfsmaß dokumentiert, nicht allein aus dem generierten Raster garantiert.
- `icon_flank_v2.png`: zwei seitlich um ein Hindernis geführte Pfeile statt eines Rückgängig-ähnlichen U-Pfeils.
- `icon_dropship_v2.png`: Transporter von schräg seitlich mit Rampe, Passagierzeichen und Abwärtspfeil statt unklarer frontaler Schiffsansicht.

Die zwei neuen Icons sind Alternativen zu den als unklar bewerteten Originalen. Für neue Varianten liegt noch keine Nutzerbewertung vor. Vier positiv bewertete Originalmotive bleiben bestehen. Alle bisherigen PNGs und Eingaben bleiben erhalten.

## Revision A3: quadratisches Randband

Der nächste Revisionsauftrag setzt das Band an die tatsächliche untere Viewportkante, beginnend links bei x=0. Kompakte Quadrate ersetzen die horizontalen A2-Buttons. Teamkarten und Protokoll wandern über das Band. Dropship/Landezone bleiben oben rechts und werden etwas kleiner; die Auftragskarte oben rechts der Mitte bleibt erhalten.

Exakter Bearbeitungsauftrag: [prompts_revision3.json](prompts_revision3.json). Eingabebild ist A2; neue Datei `mockup_a3_randband_quadratisch.png`. Bestehende Icons, A/A2 und die anderen Screens bleiben erhalten.

Der erste A3-Aufruf setzte das Protokoll entgegen der Vorgabe in das Randband. Dieser Zwischenstand bleibt als `mockup_a3_randband_versuch1.png` erhalten. Ein gezielter zweiter Aufruf versetzt das Protokoll über das Band und reduziert die Bandhöhe durch weniger Innenabstand; Eingabe und exakte Korrektur stehen in [prompts_revision3_korrektur.json](prompts_revision3_korrektur.json). Das ist eine sichtbare Ausgabekorrektur, keine Änderung des Nutzerauftrags.

Die fünf quadratischen Tasten stehen in der Folge Bewegen → Nehmen → Verteidigen → Flankieren → Plan ausführen. Die Ausführen-Taste gehört räumlich dazu, ist aber ein separater bestätigter Auslöseschritt mit eigener Akzentfläche. Lesbare Beschriftungen sitzen unter den Quadraten. Zielgrößen 56–64px bei 1920×1080 und 24–28px für Icons sind unsere Entwurfsentscheidung, keine wörtliche Maßvorgabe des Nutzers. Status, Haltung und Feuerregel bleiben eigene kompakte Gruppen.

Der freigelegte Landschaftsbereich ist Bildinterpretation. Keine einzelne Pixelgeometrie oder kleine Schrift aus dem Generator soll ungeprüft zum Godot-Control werden. Die tatsächliche Sichtprüfung folgt in [PRUEFUNG.md](PRUEFUNG.md).

## Revision A4: engere Buttons und drei kompakte Blöcke

Exakte Eingabe: [prompts_revision4.json](prompts_revision4.json). A3 ist das Bearbeitungsziel; die neue Datei heißt `mockup_a4_band_bloecke_kompakt.png`.

Der erste A4-Aufruf ordnete Blöcke und Innenlabels richtig, vergrößerte aber die Buttonkörper. Der Zwischenstand bleibt als `mockup_a4_band_versuch1.png` erhalten. [prompts_revision4_korrektur.json](prompts_revision4_korrektur.json) dokumentiert die gezielte Verkleinerung und Linksverschiebung der Folgeblöcke. Der Korrekturaufruf fügt keine Funktion hinzu.

Aktionsquadrate sollen enger stehen und Icon sowie Beschriftung im Button tragen. Damit bleibt unter der ersten Reihe Layoutreserve; es werden keine neuen Befehle oder aktiven Platzhalter ergänzt. Die konkrete Größenidee um 60px und 4–6px Abstand ist eine Assistentenausarbeitung des Nutzerwunschs, keine wörtliche Maßangabe.

Die drei Blöcke folgen nun **Aktionen → Ziel/Auftrag → Team**. „Ziel gewählt / Auftrag: Bewegen“ steht als schmaler Mittelblock. Haltung und Feuerregel werden unter den ALPHA-/FTL-/Bereit-Header gestapelt und mit ihm links ausgerichtet. Das bündige Band, Teamkarten, separates Protokoll und die oberen rechten Felder bleiben erhalten. A3s Außenbeschriftung und alte Blockfolge sind damit überholt; die Vorgeschichte bleibt unverändert abrufbar.

## Für die spätere Umsetzung

Texte, Flächen, Fokus und Zustände nativ in Godot aufbauen. Die generierten Komplettscreens bleiben Anschauungsmaterial. Kleine HUD-Icons zunächst mit Beschriftung einsetzen und bei Bedarf aus dieser Motivvorlage vereinfachen. Vorhandene Kenney-Symbole für Checkmark, Schließen und einfache Pfeile weiterhin verwenden.
