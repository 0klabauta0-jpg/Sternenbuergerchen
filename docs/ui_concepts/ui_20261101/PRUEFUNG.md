# Prüfstand · UI-Konzept · 01.11.2026

## Ergebnis und Umfang

Die Erstrunde enthält drei Layoutbilder und sechs separate Icons. Nach dem tatsächlichen Nutzerexport sind zusätzlich ein kompakter A2-Entwurf und zwei alternative Icons erzeugt, im Projekt gesichert und visuell gesichtet: insgesamt zwölf PNG-Kandidaten. Die exakten Eingaben stehen in `prompts.json` und `prompts_revision2.json`; verwendet wurde das eingebaute `image_gen.imagegen`. Die Originaldateien aus dem Generator bleiben unverändert. Dateien, Größen, Alpha und SHA256 sind in `manifest.json` und `ASSET_PRUEFUNG.json` erfasst.

Der Nutzer hat **A für die Mission und C als Staging-Grundlage** gewählt. A2 reagiert auf seinen Wunsch nach kompakteren Buttons; die neue Ausarbeitung ist noch nicht bewertet. B bleibt eine helle Alternative. Alle Screens sind Anschauungsbilder; dieses Paket verändert keine Godot-Runtime, Szenen, Bedienung oder Spielregeln.

## Sichtprüfung der Layouts

| Bild | Sichtbarer Gewinn | Konkrete Grenze |
|---|---|---|
| A / Kommandodeck | Karte bleibt dominant; die vier beschrifteten Befehle und Planausführung bilden einen zusammenhängenden Bereich; dunkle Flächen trennen Information vom warmen Gelände | Unteres Dock ist dicht; Portraits sind illustrativ; „Einheit bewegt sich“ später als Fireteam formulieren |
| B / Feldtablet | Ruhige cremefarbene Leseflächen; eindeutiger rechter Befehlskontext und gut sichtbarer nächster Schritt | Rechte Spalte ist groß; A/B unterscheiden tatsächlich Kamera, Figuren und Haltung. Kein kontrollierter Vergleich der Kartenfläche |
| C / Einsatztafel | Zuordnung Personal → Fireteam → Loadout → Dropship ist sichtbar; Hangar bringt die neue Materialwelt ins UI | Zusätzliche Rollen-/Waffenwörter sind generiert; die Boarding-Phase widerspricht dem gleichzeitig gezeichneten Startbutton. Zustände und Texte aus bestehenden Contracts einsetzen |

Alle Layouts: 1672×941px, RGB-PNG, annähernd 16:9. Die angefragte Desktopfläche war eine Gestaltungsvorgabe, keine Zusage eines exakt 1920×1080 gelieferten Rasters. Die spätere Godot-UI muss Text und Controls nativ rendern und bei echten Zielauflösungen geprüft werden. Illustration und Portraits bestätigen weder Sichtbarkeit eines Gegners noch eine verfügbare Rolle oder Schiffs-/Waffenklasse.

## Sichtprüfung der Icons

Alle sechs Dateien: **1254×1254px, RGBA, Alpha-Minimum 0 / Maximum 255**. Die transparente Fläche beträgt je nach Motiv etwa 53–83 Prozent. Keine eingebrannte Beschriftung und keine deckende Buttonplatte. Die optische Motivgröße variiert; der Dropship ist deutlich breiter als das Schild. Einzelne sehr schwache Alpha-Pixel reichen weiter als die sichtbare Hauptform. Für Produktionsassets Ränder und optischen Maßstab gezielt bereinigen beziehungsweise neu exportieren; hier wurde das Generatororiginal bewahrt.

| Icon | Tatsächlich sichtbares Motiv | Einsatzempfehlung / nächster Prüfschritt |
|---|---|---|
| Bewegen | gebogener Pfeil von Ursprung zu Orts-Pin | gute Grundunterscheidung; bei 24–32px gegen Flanke testen |
| Verteidigen | Schild auf stabiler Standfläche | klarer Schutzgedanke; feine Nieten sind dekorativ und können entfallen |
| Flankieren | großer Umgehungspfeil um einen Block | semantisch passend; ohne Text eventuell als Rückgängig deutbar, deshalb beschriftet prüfen |
| Nehmen | Flagge auf hexagonaler Standfläche | Ziel sichern statt Schwert/Angriff; Basis und Falten bei kleiner Größe vereinfachen |
| Dropship | breiter kompakter Transporter mit zwei Seitentriebwerken | geeignet als Navigations-/Transportillustration, keine verbindliche neue Craft-Geometrie |
| Loadout | Weste mit großen Taschen und Schnalle | gut als Ausrüstung erkennbar; große Ansicht nutzen, Details sind keine Ausrüstungsslots |

Die Erkennbarkeit bei tatsächlichen 24/32px ist **noch nicht visuell abgenommen**. Die Review-Seite bietet 24/32/48/96px auf hellem und dunklem Grund zur Bewertung an. Kandidaten nicht allein wegen ihres großen Vorschaubilds freigeben. Für die erste native Runde die Befehle mit Text belassen; Fokus, Hover, Auswahl und Sperre aus nativen Controls ableiten.

## Dokument-/Exportprüfung

- Lokale Datei- und Bildverweise geprüft; keine externen Abhängigkeiten im neuen HTML.
- JavaScript-Syntax geprüft.
- Die unveränderten Exportfunktionen offline mit synthetischen Controls in Node VM ausgeführt: gewählte Radio-Option, verschachtelte Felder, deutsche Notizen, Freitext, Iconbewertungen, Auswahlgröße und eindeutige Dateinamen bestanden. Siehe `EXPORT_PRUEFUNG.json`.
- Quellprüfung durch einen zweiten Agenten: ein Widerspruch zur Auswahlfarbe wurde korrigiert. Gelb bleibt Auswahl, Cyan Interaktion/Aktivität; zusätzliche Form/Textcodierung ist vorgesehen.
- **Automatisierte Browserprüfung offen:** Der Browserdienst hat `file://` aufgrund seiner URL-Richtlinie abgelehnt. Es wurde kein anderer Browser-/Serverweg als Umgehung verwendet. Tabs, Zoomdialog, reale Größenansicht, Fokus und Clipboard sind daher nicht durch den Agenten im Browser verifiziert. Der später in Downloads wiedergefundene echte Nutzerexport belegt einen erfolgten Export; er bestätigt nicht die übrigen Interaktionen.
- **Godot-Prüfung offen:** Kein Laufzeitumbau in diesem Konzepttask; kein neuer Spielbarkeits- oder Performance-Nachweis.

## Offene Entscheidungen für die nächste Runde

A ist als Missionsrichtung gewählt; offen sind die konkrete A2-Ausarbeitung, Staging-C-Dichte, Iconvereinfachung bei kleinen Größen sowie native Schrift-/Panelgrößen. Die Workbench exportiert Bewertungen und Notizen, speichert sie aber nicht automatisch über Sitzungen hinweg. Der wiedergefundene Erstrundenexport wird als dokumentierter Ausgangsstand angezeigt.

## Revision A2: Sichtprüfung nach dem Nutzerfeedback

- Originalexport gefunden unter `C:/Users/bjoer/Downloads/sternenbuergerchen_ui_20261101_2026-11-01T14-47-55-564Z_01.json`; im Paket unverändert archiviert. Die Präferenz ist A, auch wenn zuletzt Vorschautab C angezeigt wurde. Alle fünf Prüfhäkchen bleiben ungesetzt.
- A2 hat dieselbe Rastergröße 1672×941px. Das dominante dunkle Dock ist bei gleicher Messregion ungefähr ein Drittel niedriger: eine einfache Slate-Farbmaske erfasst im Original die Zeilen 730–892 und in A2 778–886. Das ist eine grobe Bildmessung, keine Vermessung nativer Controls. Der äußere Rahmen und die kleinen Buttons sind getrennt davon zu betrachten.
- Die vier alten hohen Befehlskacheln sind deutlich flachere horizontale Icon-plus-Text-Buttons geworden. Die Schrift bleibt visuell lesbar. Die Zielerklärung ist auf Status, Auftragsauswahl und einen normalen „Plan ausführen“-Button reduziert.
- Linke ALPHA-/BRAVO-Karten und rechter Transport-/Dropdown-Kontext sind erkennbar erhalten. Die große Titel-/Logoleiste oben links fehlt vollständig; dort ist nun Landschaft zu sehen.
- Die native Vorgabe 40–44px Buttonhöhe und 112–128px Dockhöhe bei 1920×1080 bleibt ein Ziel. Die Rasterbuttons fallen teils größer aus; daraus keine exakten Godot-Abmessungen übernehmen. Zusätzliche Planung kann den gewonnenen Raum nutzen, ohne jetzt neue aktive Spielfunktionen zu erfinden.
- A2 zeigt „Normal“ statt „Vorsichtig“. Diese beiläufige Bildänderung ist keine gewünschte Änderung des Auftrags- oder Haltungssystems. Freigelegte Landschaft unter früheren UI-Flächen ist eine Bildinterpretation, keine neue Karte.
- `icon_flank_v2.png`: zwei seitlich an einem Block vorbeiführende Pfeile; die Rückgängig-Anmutung des Originals ist verringert. Die Grafik legt weder automatische Teamaufteilung noch zusätzliche Befehle fest.
- `icon_dropship_v2.png`: schräge Transportansicht mit Rampe, Personenzeichen und Abwärtspfeil; Transport/Ausstieg werden deutlicher. Kann auch als Absetzen verstanden werden; mit Beschriftung prüfen. Zwei Personenzeichen sind keine Kapazitätsregel.
- Beide neuen Icons sind 1254×1254px-RGBA-PNGs mit Alpha 0–255. Die vier positiv bewerteten Originale bleiben erhalten; neue Varianten haben die Bewertung „offen“.
- Eine zweite Sichtprüfung bestätigt die sichtbare Verdichtung und den Erhalt der gewünschten Bereiche. Syntax und Export-/A↔A2-Umschaltfunktionen wurden offline mit synthetischen Controls geprüft; siehe `EXPORT_PRUEFUNG_REVISION2.json`. Reale Browser- und Godot-Prüfung bleiben getrennt.
