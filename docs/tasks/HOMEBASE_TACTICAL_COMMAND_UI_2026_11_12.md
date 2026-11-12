# Basis-Befehlsoberflaeche im Kartenstil

## Ziel und Anlass
Die Heimatbasis soll wie die Einsatzkarten aussehen und bedienbar sein: einzelne Figuren bleiben auswaehlbar, ihre jeweils sinnvollen Basisbefehle erscheinen im vertrauten unteren Befehlsband mit Auswahlbereich links unten.

## Umfang und Grenzen
Vorhandene Karten-UI-Komponenten, Stil und Interaktionsmuster wiederverwenden; Basisaktionen wie Bewegung, Schlaf, Aufwecken, Ausruesten und Ein-/Aussteigen bleiben an die bestehenden Owner gebunden. Kein taktisches Kampfkommando vortaeuschen und keine neue Gameplaywahrheit in der UI.

## Contracts und Akzeptanz
`docs/ARCHITECTURE.md`, `docs/dev/base_automatic_rest_contract.md`, vorhandene UI- und Personalcontracts. Auswahl, Befehle, gesperrte und fehlende Ziele, bestehende Tastatur-/Mauspfade, Hilfe und Rueckmeldung muessen funktionieren. Vergleichbare interne Screenshots und Regressionspruefungen fuer Basisauswahl und Kommandos; visuelle Nutzerabnahme getrennt.

## Dateien, Pruefung, Risiken
Basispresenter, `explorable_homebase.gd`, gemeinsame UI-Komponenten und gezielte Verifier. Unteres Befehlsband darf Karte, vorhandene Menues und kleine Aufloesungen nicht unbedienbar machen; Positions-/Befehlszustand bleibt bei Runtime und Simulation.

## Nutzerkorrektur und Stand 12.11.
Das Band liegt ueber die gesamte Viewportbreite an der unteren Kante. Links stehen kompakte Basisbefehle; daneben folgen die gewaehlte Person und echte Rang-/Faehigkeitsinformationen aus dem vorhandenen Profil. Weitere Personen sind horizontal scrollbar. Der echte Szenentest und eine verdeckte Aufnahme bei 1024×768 pruefen Sichtbarkeit und Scrollen; bei kleinem Fenster bleibt die Schrift relativ klein.

## Umsetzungsstand
Das Basisdock verwendet die taktische Farb- und Button-Thematik. Kompakte Befehle stehen links unten, rechts folgen die ausgewaehlte Person mit vorhandenem Portrait und weitere einzeln anklickbare Personen; weitere Eintraege sind horizontal scrollbar. Umbenennen und automatisches Ruhen bleiben erreichbar. `Bewegen` fordert ein Ziel per Linksklick an; der bisherige Rechtsklickpfad bleibt erhalten. Escape bricht eine begonnene Zielauswahl ab, bevor es die Basis verlaesst. Auswahl und Befehle gehen weiterhin ueber den bestehenden Personal-/Simulationsowner. Die linke Navigationsleiste nutzt denselben Stil; ihre Beschriftungen und Funktionen bleiben bestehen.

Die Seitenleiste verwendet vorlaeufig funktionale, eigens gezeichnete Symbole im vorhandenen nativen SVG-Stil und das vorhandene Schiffssymbol. Die per Bild-KI erstellte Iconstudie ist eine Referenz und wurde nicht ungeprueft in produktive Symbole zerschnitten; ein individuell ausgearbeiteter, vom Nutzer beurteilter Icon-Satz bleibt offen.

Der Headless-Szenentest `homebase_command_dock_verifier.gd` besteht 9/0 fuer echte Personenauswahl, bewegungszielgebenden Linksklick, anschliessenden Simulationsweg und Abbruch beim Verlassen. Der Schiffs-Kontexttest besteht nach der Anpassung der Servicepanel-Auswahl mit 36/0. Verdeckte Godot-Renderings unter `output/visual_internal_20261112/home_command_dock.png` (1280×720) und `home_command_dock_small.png` (1024×768, vor den letzten kleinen Icon-/Schriftaenderungen) zeigen das Dock; dies ist keine menschliche Designabnahme. Text ist bei der kleineren Ansicht eng; weitere Aufloesungen und Eingabemethoden sind nicht umfassend visuell geprueft. `base_personnel_world_ui_test.gd` pruefte Auswahl/Bewegung erfolgreich, scheiterte aber an einem erwarteten SMG-Austausch ohne vorhandenen Gegenstand.
