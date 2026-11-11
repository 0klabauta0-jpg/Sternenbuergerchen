# Vier zusätzliche Porträtidentitäten

Stand 11.11.2026 auf task/native-glut-maps-20261110.

## Ergebnis

Vier individuelle KI-Porträts ergänzen den bisherigen Katalog mit 42 Personen.
Neue IDs char_portrait_045 bis 048. Die 42 bestehenden IDs, Bilder und
Legacy-Aliase sind weiterhin vorhanden. Die normale deterministische
Rekrutengenerierung erreicht alle vier Ergänzungen. Namen in der Prüfgalerie
sind Bild-Produktionsnamen. Bestehende Anja-Voss-Profile behalten ihre Zuordnung.

Originale liegen unter Assets/curated/portraits/frontier_20261105/individuals_20261111.
Die importierten Texturen sind auf 512 × 768 begrenzt und besitzen Mipmaps.
Gesichtsform, Alter, Haare, Bart und Kleidung unterscheiden die vier Personen.
Die Prüfgalerie und alle Einzelvorlagen wurden visuell geöffnet.

## Herkunft und Gestaltung

art/portraits_20261111 enthält die generierten Basisentwürfe als Referenzen
und ein Manifest mit Originalausgabepfaden, SHA-256 und strukturierten
Generierungsanweisungen. Der Promptdatensatz wurde aus der Ausführungs-
zusammenfassung erhalten und ist kein bytegenaues Werkzeugtranskript.
Die native Basisaufnahme base_current_1920.png aus der laufenden Arbeitskopie
war die dominante Vorlage des zweiten Basisentwurfs. Der erste Entwurf lieferte
den gewünschten Porträtstil. Beide Basisbilder sind Gestaltungsentwürfe.

## Prüfungen

Godot 4.6.2, native Aufnahme mit D3D12 Forward+, RTX 4070 Ti SUPER, 1920 × 1080.
Die Galerie zeigt die importierten Texturen und echte kompakte NPC-Karten.
Die zweite Aufnahme zeigt CharacterSheetView im regulären Lesemodus.

- portrait_variation_20261111_test.gd nativ, 59 bestanden und 0 Fehler.
- task_233_portrait_identity_catalog_and_roster_presentation.gd, 515/0.
- playtest_20261105_portrait_atlas_verifier.gd, 872/0. Die ursprünglichen
  42 Identitäten werden weiterhin einzeln geprüft. Gesamtgrößen folgen nun
  dem erweiterten Katalog, der alte Atlasmanifesttest bleibt vollständig.
- Keine Scriptfehler oder Leaks in diesen drei Laufzeitprüfungen.
- Editorimport beendet mit Exit 0. Die bereits beobachtete ObjectDB-Warnung
  beim Editorende bleibt offen und verhindert eine allgemeine Importfreigabe.

## Weiterer Umfang

Die Basis-Punktwirtschaft und die beweglichen Fahrzeugmodelle sind eigene,
weiter laufende Arbeiten. Diese Porträtprüfung bestätigt deren Verhalten nicht.
