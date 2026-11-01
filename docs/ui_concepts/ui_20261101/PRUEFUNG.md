# Prüfstand · UI-Konzept · 01.11.2026

## Ergebnis und Umfang

Drei Layoutbilder und sechs separate Icons sind erzeugt, im Projekt gesichert und visuell gesichtet. Die exakten Eingaben stehen in `prompts.json`; verwendet wurde das eingebaute `image_gen.imagegen`. Die Originaldateien aus dem Generator bleiben unverändert. Dateien, Größen, Alpha und SHA256 sind in `manifest.json` und `ASSET_PRUEFUNG.json` erfasst.

Die Empfehlung lautet **A für die Mission, C als Staging-Grundlage**. B ist eine ernsthafte helle Alternative. Alle drei sind Anschauungsbilder; dieses Paket verändert keine Godot-Runtime, Szenen, Bedienung oder Spielregeln.

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
- **Browserprüfung offen:** Der Browserdienst hat `file://` aufgrund seiner URL-Richtlinie abgelehnt. Es wurde kein anderer Browser-/Serverweg als Umgehung verwendet. Tabs, Zoomdialog, reale Größenansicht, Fokus, Clipboard und tatsächlicher Download sind daher nicht im Browser verifiziert.
- **Godot-Prüfung offen:** Kein Laufzeitumbau in diesem Konzepttask; kein neuer Spielbarkeits- oder Performance-Nachweis.

## Offene Entscheidungen für die nächste Runde

Mission A oder B, Staging-C-Dichte, Iconvereinfachung bei kleinen Größen sowie native Schrift-/Panelgrößen. Die Workbench exportiert deine Bewertungen und Notizen, speichert sie aber nicht automatisch über Sitzungen hinweg.
