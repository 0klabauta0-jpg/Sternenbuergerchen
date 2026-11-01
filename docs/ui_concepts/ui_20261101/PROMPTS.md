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

## Für die spätere Umsetzung

Texte, Flächen, Fokus und Zustände nativ in Godot aufbauen. Die generierten Komplettscreens bleiben Anschauungsmaterial. Kleine HUD-Icons zunächst mit Beschriftung einsetzen und bei Bedarf aus dieser Motivvorlage vereinfachen. Vorhandene Kenney-Symbole für Checkmark, Schließen und einfache Pfeile weiterhin verwenden.
