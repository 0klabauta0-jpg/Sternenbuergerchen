# Kompakte Sternkarte und Smart Mobile

## Wahrheit / Auswahl
Campaign- und Travel-Owner bleiben Quelle für Jobs, Freigaben, Orte, Körper,
Orbit und Zielauswahl. Tree und Karte zeigen dieselbe ID-Auswahl. Ein Körperklick
fokussiert die Karte und legt seine Orte offen; erst ein Ortklick wählt ein
vorhandenes Ziel. Eine Auswahl startet weder Reise noch Mission.
Aufklappzustand und UI-Fokus sind lokale Darstellung, keine zweite Spielwahrheit.

## Orts- und Orbitansicht ohne Reise (Nutzerpräzisierung 13.11.2026)
Alle katalogisierten Orte sind über einen eigenen Ansichtsbutton erreichbar,
auch wenn ihr Auftrag oder eine Reise dorthin noch gesperrt ist. Missions-,
Treibstoff- und Reiseangebote behalten ihre bisherigen Ownerfreigaben.
Je Planet, Mond oder Planetoid steht genau ein `OM`-Ansichtsbutton direkt am
Körper im Baum. Die Sternkarte zeigt ebenfalls nur einen OM-Marker je Körper.
Die Orbitkarte gehört zum Körper; bestehende nummerierte Reisepunkt-IDs bleiben
interne kompatible Aliase, keine drei getrennten Ansichten. Alte Aliasaufrufe
werden weiter gegen den Ownerkatalog validiert und auf dieselbe Ansicht abgebildet.
`inspect_location` und `inspect_orbit` sind reine Ansichtsaktionen im Flow:
keine Reise, kein Schiff-/Figurenversetzen, kein Erzeugen einer Mission oder Area.
Ungültige IDs werden abgelehnt. Ein unbekannter Ort ohne Wissensquelle bleibt
schwarz und bietet Name und Rückkehr zur Sternkarte.
Geladene Orte nutzen ihre vorhandene Instanz und deren teambezogene FoW-Daten.
Die Inspektionsansicht zeigt nur sichtbare/erkundete Flächen; ihr Blackout ist
ein zeitweiliger Renderfilter, keine Änderung des Wissensowners oder Spielstands.
Beim Verlassen wird der bisherige Darstellungsmodus wiederhergestellt.
Orbitansichten verwenden ausschließlich die vorhandene autorisierte lokale
Area-Projektion eines tatsächlich anwesenden eigenen Schiffs. Ohne diese Quelle
bleiben sie schwarz; ein separates erfundenes Orbit-Wissensarchiv gibt es nicht.
Katalogpositionen allein sind kein Sichtbeleg. Die explizite Warp-Aktion bleibt.
Die Baumaktion `OM` sendet nur Körper-/Orbit-ID und löst niemals Warp aus.

## Sichtbare Aufträge
Ownerprojektion benutzt dieselben Voraussetzungen wie Annehmen/Starten.
Verfügbare, angenommene/aktive und abgeschlossene relevante Jobs sind sichtbar;
zukünftige gesperrte oder aktuell nicht zulässige Wiederholungen bleiben verborgen.
Abgeschlossene Jobs lassen sich ansehen. Erneuter freigegebener Ortbesuch benutzt
den bestehenden freien Besuchspfad mit leerer Job-ID, keine zweite Auszahlung.
Die tatsächlichen C-Benit-Fracht-/Rekrutierungs- und Failed/Home-Regeln bleiben.

## Namen
Eine reine gemeinsame Anzeigeprojektion ordnet bestehende stabile IDs zu:
Börner (System und Sonne), Mare Nostrum (Hauptplanet), Neralis (glut_1a), Vesper (glut_1b),
Asterholm (moon). Orte: Heimathafen (homebase), Aschental (satellite_crash),
Kestrel (trade_outpost), Bastion Silex (fortified_outpost), Fernwacht
(distress_orbit), Polisa (polisa).
Funktionsbezeichnungen wie Heimatbasis, Bergung oder Handelsaußenposten bleiben
als Kontext lesbar. Keine Änderung gespeicherter IDs, Reisegeometrie oder
Fingerprint-Definitionen. Eigene/ unbekannte Orte behalten ihre vorhandenen Namen.
Karte, Baum, Briefing, Guidance und Zieltexte nutzen denselben Anzeigenamenspfad.
Die letzte Nutzerkorrektur ersetzt den vorherigen Anzeigenamen Glut durch Börner.
Alte IDs wie `glut_1a` und historische Belegdateien bleiben unverändert.

Der zweite vorhandene Planet glut_2 heißt in der Anzeige Eidolon. Polisa bleibt
seine vorhandene Station; keine Himmelskörper oder Reisebeziehungen entfallen.

## Gestaltung
Eigene Interpretation von mobiGlas-/RTS-Instrumentoberflächen, keine RSI-Marken
oder aus Screenshots ausgeschnittenen Bedienelemente im Produkt.
Eine schlanke Appnavigation, keine doppelte Seiten- und Boden-Navigation.
Dunkle ruhige Leseflächen, schmale technische Überschriften, lesbarer Bodytext,
feine Eisblau-Linien und gedämpftes Amber für Auswahl/Hauptaktion.
Kompakte Zeilen/Knöpfe mit unterschiedlichen Rollen, keine großen Goldbevels,
übermäßigen Rundungen oder paddinglastigen Dashboard-Karten.
Farbige Missions-/Ortsbilder, Figurenporträts und Ausrüstungsicons bleiben sichtbar.
Bei 720p ausreichend Schriftgröße, Kontrast, Klickfläche und Safe Area.

## Basisdock und kompakte Dossiers
Der Name der ausgewählten Person ist ein direktes Namensfeld. Enter sendet den
vorhandenen Renamecommand; ein laufender ungesendeter Edit wird beim Refresh
nicht überschrieben. Eine andere Person wird über ihre Karte ausgewählt;
Personenwechsel verwirft keinen bereits bestätigten Ownernamen und schreibt
keinen Entwurf an die falsche Person. Es gibt keinen zweiten Namensdialog.
Porträt und vorhandene Rang-/Erfahrungsanzeigen bilden einen kompakten Block:
Porträt links, Symbole oben rechts vertikal. Zwei dünne senkrechte Linien
trennen Basisbefehle, ausgewählte Person und weitere Personen.
Im Satellitendossier steht das vollständige Bild links über den Zielen,
rechts beginnen die Metadaten auf gleicher Höhe. Der redundante generische
Beschreibungssatz entfällt. Farbige bestehende Navigationsassets bleiben
erhalten; kein Ersatz durch generische Umrissicons.

## Kosten
Normale Godot-Controls, gemeinsam gecachte Styles/Fonts und wiederverwendete
Bilder. Baumtopologie und Jobliste nur bei relevanter Signaturänderung erneuern;
Auswahl/Status getrennt nachziehen, Collapse/Fokus erhalten.
Keine SceneTree-Vollscans, per-frame Controlbaum-Neuanlage, dekorative
Vollbild-Blurpassfolge oder sinnlose Daueranimation. Tests prüfen stabile Nodes,
Ressourcen und Rebuildzähler sowie unverzügliche echte Auswahländerung.

## Nachweis
Die Satellitenbergung verwendet ausschließlich ihre eigene KI-Illustration:
abgestürzter Satellit auf offener roter Wüstenfläche. Schüssel und Solarpanels
bleiben durch Aspect-Fit innerhalb des kompakten Bildbands vollständig sichtbar.
Andere Aufträge erben dieses Motiv nicht, auch nicht bei gleicher Orts-ID.

Automatisierte Rules-/Selection-/Layout-/Input-/Refresh-Prüfungen, alte
Dateipaare, native Bilder der echten Implementation bei 1280×720/1920×1080.
KI-Referenz zeigt das Ziel; nur echte geöffnete Godotbilder belegen Umsetzung.
