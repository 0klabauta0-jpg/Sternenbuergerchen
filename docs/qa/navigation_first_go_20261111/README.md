# Erster GO und echtes B-Gefecht

Stand 11.11.2026. Branch task/native-glut-maps-20261110, Aufbau auf
5b1be7081. Alle A/B/C-Dateien behalten ihre geprüften SHA-256 und
je 512 × 256 Zellen.

## Änderung

Der normale regionale Bewegungsweg verwendet eine fortgesetzte A*-Suche
mit den vorhandenen Schritt- und Gelände-/Deckungskosten. Ein Slice
bearbeitet höchstens 24 Expansionen, alle regionalen Jobs zusammen 96
je Simulationstick. Gleich priorisierte Jobs erhalten ihre Turns nach
dem letzten Bedienungstick. Ein erneuter identischer Marschbefehl behält
die laufende Suche und die noch gültige Route. Neue Ziele, Kosten,
Terrainrevisionen und explizite Vermeidungs-Neuplanung werden geprüft.
Ein unerreichbares Originalziel endet am nächsten verbundenen Feld.

Der vorhandene räumliche Registry-Index löst blockierte Formationsziele
lokal auf. Bei weiter Entfernung oder fehlendem lokalen Beweis wird die
bestehende vollständige Abfrage verwendet. Der Index wird während des
Kartenaufbaus vorbereitet. Die Route wird linear rekonstruiert.

## Native Messung

Godot 4.6.2.stable.official.71f334935, D3D12 Forward+, RTX 4070 Ti SUPER.
Fenster 1280 × 720, taktischer Viewport 1920 × 1080, Engine.time_scale 1.
Normales Continue mit isolierter Kopie des realen A-Upload-Checkpoints.
Landung auf B, dieselben beiden eigenen Personen, dieselbe Wache und
derselbe reguläre GO zur Wache. Acht Schussereignisse und tatsächlich
abgeschlossenes Gefechtsziel, 35 Prüfungen erfolgreich.

| Metrik | Vorher | Abschließender Lauf |
| --- | ---: | ---: |
| Längster Frame nach GO bis Kontakt | 8.574,0 ms | 161,6 ms |
| Annäherung Frame P95 | 300,5 ms | 28,7 ms |
| Annäherung Frame P99 | 496,3 ms | 40,7 ms |
| Annäherung Command-Arbeit P99 | 428,8 ms | 6,8 ms |
| Gefecht Command-Arbeit P99 | 131,1 ms | 2,0 ms |
| Gefecht Frame P95 | 85,0 ms | 81,8 ms |
| Gefecht maximaler Frame | 229,0 ms | 120,4 ms |

GO-Dispatch benötigt 39,8 ms. Die erste physische Bewegung folgt nach
2.294,7 ms. Das engere Budget verlängert die verteilte Suchlatenz gegenüber
den ersten Kandidaten mit größeren Slices. Im vorletzten Kandidaten lag
die erste Bewegung bei 1.010,5 ms und der längste Annäherungsframe bei
223,5 ms. Die letzte Fassung stellt Fortschritt für parallele Jobs sicher.

Die Annäherung bis zum ersten Schuss dauerte im letzten Lauf rund 54,5 s.
Die Karten- und Grafikqualität wurde für diese Änderung gleich belassen.
Die GPU-Zeit schwankt zwischen den vorhandenen und neuen Proben. Aus ihr
wird keine Verbesserung der GPU oder allgemeine FPS-Freigabe abgeleitet.
Die sichtbaren Gesamtframes im Gefecht zeigen weiteren Optimierungsbedarf.
Weitere Gegnerzahlen und längere Gefechte benötigen eigene Messungen.

[Vorher](before.json) · [Nachher](after.json) · [Nativer Lauf](battle.log)

## Funktionsprüfungen

Die gezielte Verifikation meldet zwölf erfolgreiche Checks. Für diese
Änderung sind besonders relevant

- Slices und exakte Kostenparität, Rampen in allen sechs Richtungen.
- Sechs echte TestUnit-Aufträge durch SimulationRoot, fünf lange unerreichbare
  Ziele und ein letzter kurzer Weg, 15 erfolgreiche Assertions. Revision
  während wartender und bereits begonnener Bewegung, Hold, keine weitere
  Expansion des verworfenen Jobs und neues GO.
- 50 Nächstfeldvergleiche gegen die vollständige Registry-Abfrage auf B,
  inklusive Tür-Override und weit entferntem Ziel.
- Bestehende Budget-, Bewegungslifecycle-, Token-, Nächstfeld- und
  Hex-HPA-Regressionsprüfungen.

Der separate Editor-Import endet mit Exit 0 und einer SceneTreeTimer-
Leakwarnung. Ein Wiederholungslauf mit ausführlichem Log bestätigt diese
Warnung. Die Checks wurden danach separat mit dem vorhandenen Importstand
ausgeführt und enthalten keine Script-/Compilefehler oder Leakwarnungen.
Der Import gilt daher als offen. Der vollständige Editor-/Release-Gate
wird daraus nicht abgeleitet.
