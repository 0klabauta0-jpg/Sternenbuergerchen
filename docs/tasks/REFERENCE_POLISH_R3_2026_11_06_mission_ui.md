# R3: lesbare Missionsaktionen und ruhiger Teamkopf

## Ziel / Ursache
Die A5-Vorlage zeigt eindeutige Symbole in beiden Befehlsreihen. Der aktuelle
native Stand laesst mehrere untere Aktionen und GO nur als Text erscheinen;
Target haengt fuer sein Icon noch am generischen Legacy-Iconpass. Der
Parameterblock verwendet einen24px-Kartenkopf, obwohl seine Identitaetszeile
bei y8 eine30px-Box besitzt. Dessen zusaetzliche Trennlinie laeuft durch den
Titelbereich. Referenz: `mockup_a5_mission_zweireihig.png` und die normalen
3440er Vorherbilder der R3-Serie.

## Umfang / Design
Die neun nativen Aktionen erhalten vollstaendige explizite Iconzuordnung.
Die vier vorhandenen Haupticons bleiben; fuer Ziel, Leeren, Loeschen, Ordnen
und GO kommen einfache eigene funktionale Vektorglyphen hinzu. Bestehende
Bitmaps und Portraits werden nicht veraendert. Die neuen Glyphen werden aus
gebuendeltem SVG-Text einmalig als native Texturen gecacht, ohne neue externe
Assets oder Importabhaengigkeit. Primaertext und Tooltips bleiben erhalten.
GO bekommt wegen seiner zweizeiligen Beschriftung eine kleinere Symbolhoehe.

Der linke Parameterblock verwendet die vorhandene ruhige A5-Rahmenroute ohne
24px-Kopfteiler. Identitaet, Mitglieder, Details, Alle, Haltung und Feuerregeln
bleiben an ihren bestehenden Controls. Kein neuer Zustand, Command oder Timer.
Die spaetere linke Nutzerplatzierung bleibt vorrangig vor dem alten unteren
Parameterblock der Originalillustration.

## Akzeptanz
- Alle neun nativen Aktionen haben echte nichtleere, begrenzte Iconressourcen,
  einschliesslich frischer Target/GO-Initialisierung ohne Legacy-Iconpass.
- Wiederholte Darstellung behaelt dieselben Ressourcen, Callbackverbindungen,
  Enable-Gates und Gameplay-Ownerdaten. Unbekannte Icon-IDs bleiben null.
- Bei3440x1440,1920x1080 und1280x720 bleiben die Aktionscontrols quadratisch,
  passen zu den vorhandenen Slots und halten beide Befehlsreihen frei.
- Der Teamkopf erhaelt keinen durch die Identitaet laufenden Kartenteiler;
  echte native Nachherbilder muessen dies sichtbar bestaetigen.
- Bestehende Legacy-/ROE-/Command-Batch-/ActiveOrder-Gates bleiben erhalten.

## Dateien / Pruefung
Root: `scripts/ui/native_ui_icons.gd`, nur ICON_IDS/Präsentation/Teamrahmen
in `mission_a5_hud_layout.gd`, neuer fokussierter Verifier. Produkt erst nach
der getrennten Performance-Gegenmessung. Der Verifier verwendet echte Controls
in einer synthetischen Missionsfixture, keine physischen Spielerbehauptungen.
Danach echte Vollbildbilder und normaler Spielerpfad. Die API wurde gegen
die offizielle Godot4.6-Image-Dokumentation geprueft:
https://docs.godotengine.org/en/4.6/classes/class_image.html#class-image-method-load-svg-from-string

## Risiken / Nicht-Ziele
Icon-/Text-Minima duerfen keine72/64/52px-Slots vergroessern. Kein kleinerer
Primaertext als Platzersatz und keine Icon-only-Bedienung. Reines Render-/
UI-Polish, keine neue taktische Semantik oder globale Neugestaltung aller Icons.
