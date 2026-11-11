# Fahrzeuge, Rüstungen und Ausbildungsstufen

## Ziel und Ursache

Die Spielfiguren sollen nach Anzug, leichter, mittlerer und schwerer Rüstung
unterscheidbar sein. Neue Kampagnenpersonen beginnen im Anzug. Leichte
Rüstung wird durch den frühen Kampagnenfortschritt verfügbar. Das vorhandene
Datenträgerfach gehört bereits zum Anzug und benötigt keinen Rucksack.

## Konkrete Rüstungsintegration

Neue Kampagnenpersonen beginnen mit der kanonischen Klasse `suit` und ohne
freie leichte Rüstung im Lager. Der bestehende frühe Satelliten-Blueprint und
die Herstellung bleiben der Erwerbsweg für leichte Rüstung. Das konkretisiert
die offene Nutzerangabe „erste Kampfmission oder so“ im vorhandenen Fortschritt.
Bestehende Checkpoints behalten ihre tatsächlich getragenen Rüstungen.
Anzug, leicht, mittel und schwer müssen in Karten, Inventar und Einsatz denselben
Loadout lesen. Der Anzug ist die intrinsische Unterbekleidung und wird beim
Rüstungstausch nicht als zusätzlicher Lagergegenstand erzeugt.
Echte zusätzliche Rüstungsmeshes werden an den vorhandenen Skeletten befestigt,
bewegen sich mit Stand/Lauf/Feuerpose und sind im Inventar sowie in der Welt
sichtbar. Der Basisakteur liest die Ausrüstung vom SimulationRoot-Owner.

## Verbindliche Einordnung

Nova ist ein Bodenpanzer, Cyclone ein Jeep. Beide benötigen den
Bodenfahrzeug-Lifecycle, Fahrer/Besatzung, passende Standflächen und
Fahrzeugtransport. Caterpillar ist Frachter, Prospector Bergbauschiff und
Vulture Bergungsschiff. Erkul liefert Rollen und Serienausrüstung.
Die dortige Crewzahl ersetzt keine Infanterie-Sitzplätze.

## Vorliegende Grundlage

- Zwölf sichtbare Erkul-Serienkonfigurationen mit Patch und Erfassungsdatum in
  docs/qa/navigation_points_20261111/erkul_reference.json.
- Originale des Nutzers unter C:/Users/bjoer/AppData/Local/Temp und den benannten
  Desktop-Archiven.
- Statische lokale Konvertierungskandidaten und Quellenkopien in
  output/native_glut_maps/vehicle_candidates.
- Drei Ausbildungsstufen und der gemeinsame Skirmish-Punktekauf sind separat
  in SKIRMISH_POINTS_START_2026_11_11 beschrieben.

## Nächste Integrationsschritte und Akzeptanz

1. Quellen, konkrete Varianten und Ansichten zuordnen. Für generische Hornet
   und Vanguard dienen F7C Mk I und Warden als vorläufige Erkul-Vergleiche.
2. Modellquellen auflösen. FBX-Importprobleme mit den gelieferten OBJ-Alternativen
   prüfen. Die Valkyrie-Datei enthält ihre sichtbaren Teile in einer anderen
   Struktur als direkte Meshobjekte der aktiven Szene.
3. Sichtbare Außenhaut, kleinere Anbauteile und bewegliche Baugruppen getrennt
   erhalten. Die erste automatische Reduktion hat offene Qualitätsbefunde,
   darunter kleine lose Inseln, Normalen und UVs. Diese Kandidaten brauchen
   Nacharbeit und einen nativen Vergleich.
4. Für Anzug und Rüstungsstufen eigenständige anziehbare 3D-Varianten am vorhandenen
   Skelett erstellen. Stand, Lauf, Feuerpose, Ein-/Aussteigen und Porträtansicht
   mit derselben Ausrüstungswahrheit prüfen.
5. Den frischen Kampagnenstart auf Anzug umstellen. Den vorhandenen frühen
   Satelliten-Blueprint und Herstellung als Erwerbsweg leichter Rüstung verwenden.
   Alte Checkpoints vollständig übernehmen. Datenträgerfach ohne Rucksack prüfen.
6. Neue Schiffe und Bodenfahrzeuge mit ihren tatsächlichen Funktionen und
   Besatzungen über die bestehenden Runtime-Owner einführen. Danach erst die
   spielbaren Varianten zum Punktekatalog hinzufügen.
7. Neue Kosteneffekte in echten Einsätzen und bei 1000/1500 Punkten testen.

## Ergänzte Bewegungs- und Feuerdarstellung

Der Nutzer verlangt weiterhin stark vereinfachte Modelle mit erhaltener
Silhouette. Rampen sollen öffnen, Fahrwerke arbeiten, Räder und Ketten sich
bewegen. Triebwerke erhalten Abgasstrahlen und passende Bodenbewegungen
Staub. Sichtbares Mündungsfeuer und gut erkennbare Projektile mit Leuchtspur
werden an allen bewaffneten Varianten geprüft. Die letzte Spracheingabe wurde
vorläufig als Projektile/Leuchtspur interpretiert.

Die ersten automatischen Collapse-Kandidaten zeigen im nativen Vergleich
zerrissene Außenhaut und Spitzen. Sie sind verworfen. Auch ein vorab
verschweißter Gladius-Kandidat verliert bei 25.000 Dreiecken wichtige Flächen.
Die unreduzierte Quelle ist wesentlich sauberer. Weitere Vereinfachung muss
Außenhaut und bewegliche Baugruppen gezielt erhalten und erneut verglichen
werden. Aktuell ist keines dieser neuen Fahrzeugmodelle spielbereit integriert.

## Zuständigkeit

SimulationRoot und die vorhandenen Kampagnen-, Ausrüstungs-, Reise- und
Fahrzeug-Owner besitzen den Zustand. UI zeigt den gemeinsamen Zustand.
Siehe graphics_reference_revision_contract.md, personnel_inventory_contract.md
und skirmish_prepared_starts_contract.md.

## Risiken und lokale Prüfung

### Rüstungsstand11.11.2026

Anzug, endliches An-/Ablegen, Legacyklasse und kanonische Basisakteur-Getter
sind umgesetzt. Erste tragbare Rüstungsmeshes werden im Basisoperator und
Einsatzmodell an den tatsächlichen Knochen geführt; Stand/Lauf/Feuer/Rückseite
nativ62/0 und tatsächlicher Inventarbutton/Basiswelt16/0 geprüft. Neun gezielte
Programme grün, QA: docs/qa/personnel_armor_20261111. Sitz-/Transportposen,
weitere Formarbeit und das Nutzerurteil bleiben offen. Kein abgeschlossener
Fahrzeug- oder allgemeiner Performance-Task.

Modellabmessungen, Blickrichtung, Türen, Kollision und Fahrzeugverladung brauchen
native Belege. Erkul-Daten und die eigenen Spielpunktpreise werden mit
jeweiligem Stand geführt. Ein bestandener Meshimport belegt die Spezialfunktion
eines Fahrzeugs erst zusammen mit dessen Runtimeprüfung.
