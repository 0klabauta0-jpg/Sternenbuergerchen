# Prüfstand · UI-Konzept · 01.11.2026

## Ergebnis und Umfang

Aktuell enthält das Paket 32 PNG-Artefakte: 17 Screen-/Kartentafeln, sieben erhaltene Zwischenversuche und acht Icons. Hinzu kommen zwei Referenzbilder. A5 und zehn weitere Menü-/Kartentafeln erweitern die bisherigen sechzehn Artefakte; fünf neue erste Versuche bleiben nach gezielten Bildkorrekturen erhalten. Exakte Eingaben stehen in `prompts.json` und `prompts_revision2/3/4/5*.json`; verwendet wurde das eingebaute `image_gen.imagegen`. Die Originaldateien bleiben unverändert. Größen, Alpha und SHA256 sind in `manifest.json` und `ASSET_PRUEFUNG.json` erfasst.

Der Nutzer hat **A für die Mission und C als Staging-Grundlage** gewählt. Aktuell zeigt A5 zwei tatsächlich belegte Reihen vorhandener Aktionen mit Innenlabels sowie Aktionen → Ziel/Auftrag → Team mit Haltung/Feuerregel darunter. A4/A3/A2/A bleiben vergleichbar. A5 und die zehn neuen Tafeln sind noch nicht bewertet. Die vollständige Sichtprüfung samt verbleibenden Bildfehlern steht in [BILDPRUEFUNG_REVISION5.md](BILDPRUEFUNG_REVISION5.md), die Begründung und Quellen im [Menüguide](MENUES_UND_KARTEN.md). Alle Screens sind Anschauungsbilder; dieses Paket verändert keine Godot-Runtime, Szenen, Bedienung oder Spielregeln.

## Sichtprüfung der Layouts

| Bild | Sichtbarer Gewinn | Konkrete Grenze |
|---|---|---|
| A / Kommandodeck | Karte bleibt dominant; die vier beschrifteten Befehle und Planausführung bilden einen zusammenhängenden Bereich; dunkle Flächen trennen Information vom warmen Gelände | Unteres Dock ist dicht; Portraits sind illustrativ; „Einheit bewegt sich“ später als Fireteam formulieren |
| B / Feldtablet | Ruhige cremefarbene Leseflächen; eindeutiger rechter Befehlskontext und gut sichtbarer nächster Schritt | Rechte Spalte ist groß; A/B unterscheiden tatsächlich Kamera, Figuren und Haltung. Kein kontrollierter Vergleich der Kartenfläche |
| C / Einsatztafel | Zuordnung Personal → Fireteam → Loadout → Dropship ist sichtbar; Hangar bringt die neue Materialwelt ins UI | Boarding-Phase widerspricht gleichzeitigem Startbutton. Rollen-/Waffentexte sind Beispiele; Rifle, Engineer und Scout/Sniper sind im aktuellen Bestand belegt, eine separat wählbare Pistole nicht bestätigt. Zustände und Texte aus bestehenden Contracts einsetzen |

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

A ist als Missionsrichtung gewählt; offen sind A5 und die zehn neuen Menü-/Kartentafeln, Iconvereinfachung bei kleinen Größen sowie native Schrift-/Panelgrößen. Die Workbench exportiert Bewertungen und Notizen, speichert sie aber nicht automatisch über Sitzungen hinweg. Der wiedergefundene Erstrundenexport wird als dokumentierter Ausgangsstand angezeigt. Alle zehn neuen Tafeln starten mit offenem Urteil; einzelne Bewertungen und Notizen werden auch aus ausgeblendeten Tafeln exportiert.

## Revision A5 und vollständiges Menüpaket

Die [tatsächliche Bildprüfung](BILDPRUEFUNG_REVISION5.md) dokumentiert alle elf Tafeln, fünf Korrekturen und verbleibende Abweichungen. Hauptmenü, Heimatbasis, FOB/Loadout, Charakterbogen/kompakte Karten, Detailkarten, Nachbesprechung, Lobby, Einstellungen/Hilfe/Escape, Karteneditor und Teameditor sind in der Workbench einzeln bewertbar. A5 bleibt im Missionsvergleich.

Fünf Missionsstände und zehn Menüselektionen einschließlich Export wurden offline mit synthetischen Controls geprüft: neun Checks bestanden; siehe [EXPORT_PRUEFUNG_REVISION5.json](EXPORT_PRUEFUNG_REVISION5.json). Lokale Verweise, PNG-/Generatororiginale, alle Prompt-Hashes und unveränderte Erstrundenbewertungen sind bestätigt; siehe [PAKET_PRUEFUNG.json](PAKET_PRUEFUNG.json). Diese eng begrenzte Prüfung ersetzt keine Browser-/Fokus- oder native Godot-Abnahme.

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

## Revision A3: Randband und kompakte quadratische Tasten

- Aktueller Kandidat: `mockup_a3_randband_quadratisch.png`, 1672×941px RGB. A2 bleibt umschaltbar; sämtliche bisherigen Icons sind unverändert.
- Der erste A3-Aufruf setzte das Protokoll noch in das Band. Er bleibt als `mockup_a3_randband_versuch1.png` erhalten. Ein gezielter zweiter Bildgenerator-Aufruf verschob das Protokoll darüber und reduzierte den Innenabstand. Beide Eingaben und Generatororiginale sind dokumentiert.
- Die finale Sichtprüfung bestätigt ein von der linken unteren Ecke durchgehendes dunkles Band bis an die Unterkante. Die letzte Bildzeile ist vollständig dunkler Bandhintergrund; es bleibt kein dekorativer Geländeabstand darunter.
- Fünf kompakte Kacheln stehen links in einer Reihe: Bewegen, Nehmen, Verteidigen, Flankieren, Plan ausführen. Die letzte folgt direkt nach Flankieren und ist durch gefülltes Cyan plus Play-Symbol vom Befehlswechsel unterschieden. Beschriftungen liegen unter den Kacheln.
- Teamkarten sind nach oben versetzt. Das Protokoll steht als eigenes Panel rechts darüber, mit sichtbarem Abstand zum Band. Missionsziel bleibt oben rechts der Mitte; Dropship-/Landezone-Panel ist gegenüber A2 sichtbar kleiner. Kein Spieltitel oben links.
- Die Rasterkacheln sind annähernd quadratisch, nicht maßgenau: Die Farbkontur der ausgewählten Kachel ergibt ungefähr 65×56px; das ist keine native Control-Geometrie. Für die spätere Umsetzung Breite und Höhe ausdrücklich gleich setzen. Das Ziel 56–64px bei 1920×1080 ist eine Entwurfsvorgabe. Siehe `A3_GEOMETRIE_PRUEFUNG.json`.
- Das Band ist im Raster höher als die angefragten etwa 90–96px. Für eine exakt kompakte native Fassung Innenabstände, Kontext und Beschriftungszeile kontrollieren; den Bildmaßstab nicht blind übernehmen. Schrift und lange deutsche Labels dürfen dabei nicht unlesbar werden.
- Landschaft wirkt nach den Bildbearbeitungen weicher als A2. Dies ist ein Mockup-Artefakt und kein Auftrag, im Spiel einen Unschärfefilter oder weichere Weltgrafik einzuführen. „Normal“ bleibt nur der illustrative Haltungszustand.
- Unabhängige zweite Bildsichtung bestätigt die gewünschten räumlichen Änderungen ohne schwere Layoutinkonsistenz. JavaScript-Syntax und die Umschaltung A3/A2/A einschließlich übereinstimmender Bild-/Zoomziele, Metadaten und unveränderter Iconurteile sind offline geprüft: `EXPORT_PRUEFUNG_REVISION3.json`. Kein automatisierter Browser- oder Godot-Nachweis.

## Revision A4: Innenlabels und umgestellte Blöcke

- Aktueller Kandidat: `mockup_a4_band_bloecke_kompakt.png`, 1672×941px RGB. Erster Versuch mit zu großen Tasten: `mockup_a4_band_versuch1.png`. Ein zweiter Aufruf verkleinerte die Aktionsgruppe und zog die Folgeblöcke nach links. Alle bisherigen Bilder und Icons bleiben erhalten.
- Fünf bestehende Aktionen bleiben in gleicher Reihenfolge. Alle Beschriftungen liegen innerhalb ihrer Tasten; „Plan ausführen“ ist zweizeilig im cyanfarbenen Quadrat. Keine externe Beschriftungszeile unter den Tasten.
- Die sichtbare Folge lautet Aktionen → Ziel/Auftrag → ALPHA. Haltung und Feuerregel sind unter dem ALPHA-/FTL-/Bereit-Header links ausgerichtet. Ziel/Auftrag steht dadurch zwischen den bisherigen ersten und zweiten Funktionsblöcken.
- Die Gesamtgruppe der fünf Aktionen ist enger als A3, ungefähr bis x=430 statt x=536 im Raster; die Beschriftungszeile ist integriert. Einzelne Tastenkörper sind dadurch nicht zwingend kleiner als A3 ohne Beschriftung. Zielmaße um 60px und 4–6px Abstand sind im Raster nicht exakt erreicht. Für die native Umsetzung Größen, Abstände und Textlayout kontrollieren.
- Unter der ersten Reihe bleibt eine freie Reserve von ungefähr 40px. Das belegt noch keinen Platz für eine vollständige zweite Reihe in endgültiger Größe. Eine spätere native Grid-Anordnung muss zwei echte Reihen einschließlich Text, Abstand und Fokusrahmen aufnehmen können. Keine neuen aktiven oder ausgegrauten Fantasiebefehle sind hinzugefügt.
- Das Band bleibt bündig am Rand. Seine Oberkante liegt im Raster geringfügig höher als A3; eine exakt unveränderte oder kleinere Bandhöhe wird deshalb nicht behauptet. Teamkarten und separates Log bleiben darüber, obere rechte Bereiche und fehlender Spieltitel bleiben erhalten.
- Die Welt bleibt illustriertes Anschauungsmaterial und ist weiterhin weicher als in der Ausgangsreferenz. Daraus keine Änderung der Runtime-Grafik ableiten. Kleine Schrift und deutsche Langtexte später nativ prüfen, nicht aus dem Raster als akzeptiert übernehmen.
- Zweite unabhängige Bildsichtung bestätigt die gewünschte Innenbeschriftung und Blockanordnung ohne schwere Inkonsistenz. Vier Umschaltstände A4/A3/A2/A mit Bild-/Zoom-/Titel-/Metadaten sowie unveränderten Iconurteilen sind offline geprüft: `EXPORT_PRUEFUNG_REVISION4.json`. Browser-, native Eingabe- und Godot-Prüfung bleiben offen.
