# Auftragsapp und freie Bedienfläche — 12.11.2026

Basis Main3446f3040, isolierter Branch codex/job-app-safe-area-20261112.
Task: docs/tasks/JOB_APP_SAFE_AREA_2026_11_12.md.

## Befund und Korrektur
Echter Viewportklick auf den ersten Auftrag traf die Außenklickfläche und schloss
die App. Der rote Lauf reproduziert dies; bloßes Auslösen von pressed hätte den
Fehler nicht erfasst. Geschwisterfolge des aktiven Flyouts korrigiert.

Das sichtbare Basisband (189 px) wird anhand seiner realen Geometrie reserviert.
Smart Mobile und Charakterdetails enden acht Pixel darüber. Auftragsaktionen
liegen außerhalb des scrollenden Briefings. Detailspalten berücksichtigen ihre
Mindestbreiten, damit der Schließen-Knopf auch bei1280×720 im Viewport liegt.

## Ergebnis
- Headless:24 Prüfungen /0 Fehler, Exit0, Marker JOB_APP_SAFE_AREA_PASS.
- Native OpenGL/Compatibility:24 Prüfungen /0 Fehler, Exit0, gleicher Marker.
- Beide Auflösungen1920×1080 und1280×720 im selben Lauf, inklusive Resize.
- Echte Auswahl, Refresh, Annahme beim Campaignowner, explizites und äußeres
  Schließen. Keine Freischaltung, kein Eingriff in Gameplaydaten.
- Native Ansicht auf nie aktiviertem privaten Windowsdesktop; keine OS-Maus-/
  Tastatureingaben und keine Bedienung des Nutzerdesktops. Nur lokale
  Viewport.push_input-Ereignisse im Test. Bilder aus dem echten Godotviewport.
- Zwei bestehende Scene-UID-Warnungen mit funktionierendem Textpfadfallback.
  Keine Script-/Enginefehler.
- Zwischenläufe mit Timeout sind ausdrücklich keine positiven Nachweise.

## Grenzen
Kein großes Gefecht, keine Performance- oder Multiplayerfreigabe. Native
Ansichten belegen die konkrete Layoutkorrektur, kein gestalterisches Nutzerurteil.
Der neue Windows-Paketnachweis wird separat am Paket festgehalten.
