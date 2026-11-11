# Native Punktebasis

Stand 11.11.2026, isolierter Branch task/native-glut-maps-20261110 auf
52cba3f80. Hauptprojekt und andere Arbeitskopien sind erhalten.

## Ergebnis und Spielweg

Skirmish → Punktebudget → 1000/1500 → echte leere Heimatbasis. Die native
Ansicht nutzt die bestehenden Habitat-/Werkhallenmodelle, Pads und Schiffe.
Der linke Einkauf bietet reale Personenvorschläge, Konfiguration, Rekrutieren,
Entlassen und den Zugang zum bestehenden Ausrüstungsbildschirm. Gebäude,
Betten, Pads, Schiffe und Lagergegenstände teilen sich den Runtime-Kontostand.
Die Bilder zeigen tatsächlich ausgeführte Käufe im Spiel.

Ein mögliches 1000-Punkte-Paket kostet 995 Punkte. Habitat mit zwei Betten 180,
Werkhalle 120, Pad 150, Cutlass 340, wenig erfahrener Schütze mit leichter
Rüstung und Sturmgewehr 110, wenig erfahrener Pilot mit leichter Rüstung und
Pistole 95. Preise sind vorläufige Balancewerte. Gebäude nutzen feste Bauplätze.

## Automatisierte und native Prüfung

Godot 4.6.2, Windows, native D3D12 Forward+, RTX 4070 Ti SUPER.
Native Aufnahmen in 1920 × 1080 und 1280 × 720. Alle gelieferten Bilder wurden
geöffnet. Die schmale Fassung hält Einkauf und Basisbedienung räumlich getrennt.
Der Test startet über die sichtbaren Skirmish- und Budgetbuttons, erzeugt die
reale Szene und nutzt auch die tatsächlichen Rekrutierungs-/Ausrüstungsbuttons.

Der erste Headless-Satz enthält acht bestandene Programme ohne Script-/
Compile-/Enginefehler oder Laufzeitleaks. report.json und check-*.log liegen bei.

- Punktebasis 47/0 im ersten Satz. Danach native Prüfung mit aktualisierten
  Sichtbarkeits-, Eingabe- und Layoutchecks 56/0, siehe native.log.
- Abflug aus dem gekauften 995-Punkte-Deck 14/0 bis zum tatsächlichen Mondorbit.
  Reale Fußwege, bestehende Physikticks und Boarding ohne teleportierte Akteure.
- Frühere Punkte-Startform 17/0.
- Vorbereitete Starts 209/0 und Flow 98/0.
- Bestehende Kapazitätsnavigation 169/0 und Personalerweiterung 41/0.
- Kompakte Charakterkarte 28/0.

Geprüft sind fehlender/beleger Padplatz, Budget, Wiederholung und Requestkonflikt,
leere Startkapazität, geöffnete Baufläche, Wiederherstellung der echten
Blockerzellen, endliche Ausrüstung, Containerbereinigung, Personalrückgabe,
Gearwechsel vor Entlassung, letzte Person, echte Menübuttons und Schiffs-
Rückgabe einschließlich Reise-/Supply-Bereinigung. Auch das Medictool bleibt
nach Entlassung vollständig bezahlt.

Die letzte native Prüfung verwendet ein separates APPDATA-Profil unter
output/native_glut_maps/private_points_profile. Die bisherigen Presetprüfungen
bestätigen zusätzlich unveränderte gespeicherte Teamdateien.

## Grenzen

Der Editorimport beendet mit Exit 0 und der bereits vorhandenen ObjectDB-
Warnung beim Beenden. import.log dokumentiert dies. Dieser Stand enthält
keine allgemeine Editor-/Releasefreigabe. Zwei bestehende Szenen-UID-Warnungen
verwenden erfolgreich ihre Ressourcenpfade.

Die neuen Druckmodelle, bewegliche Fahrzeugteile und sichtbare Rüstungsvarianten
sind weiterhin in VEHICLE_ARMOR_TRAINING_2026_11_11 offen. Die ersten automatischen
Fahrzeugreduktionen sind verworfen. Gesamtgefechtsleistung folgt weiterhin der
separaten B-Probe unter navigation_first_go_20261111. Der Punktetest ist keine
allgemeine Framerate-Abnahme. Mainintegration und EXE-Export sind offen.
