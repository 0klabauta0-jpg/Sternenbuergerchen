# App Shell Full Flow Checklist

## Vorbereitung
- Godot 4.6.2 starten.
- Projekt `C:\dev\SternenBuergerchen` oeffnen.
- Startszene muss das Hauptmenue sein.

## Hauptmenue
- Hauptmenue erscheint mit Hintergrundbild und den Buttons Einzelspieler, Multiplayer, Editor und Einstellungen.
- Einstellungen oeffnen und wieder abbrechen.
- Einstellungen erneut oeffnen, FoW auf Blackout und Comic-Bubbles auf Minimal setzen, anwenden.
- Zurueck im Hauptmenue pruefen, dass kein Missions-State oder Debugfenster offen bleibt.

## Einzelspieler
- Einzelspieler starten.
- Mission/Meta-Testpfad laedt ohne Scriptfehler.
- FoW-Modus und Comic-Bubble-Modus wirken sichtbar in der Mission.
- Zurueck zum Hauptmenue oder Szene neu starten.

## Multiplayer
- Multiplayer oeffnen.
- Host starten, lokale Peers im Testpfad ready setzen oder den manuellen Zwei-Instanzen-Test ausfuehren.
- Start Mission bleibt host-only und erst aktiv, wenn Ready-Bedingungen erfuellt sind.
- Unbekannte Host-Map zeigt Consent-Prompt.
- Reject blockiert den Client-Start fuer diese Map.
- Accept cached die Map erst nach Zustimmung.

## Editor
- Editor oeffnen.
- Neue oder bestehende 32x32-Map laden.
- Hoehe, Edge, Marker, Patrol und Scenario-Felder setzen.
- Speichern, neu laden, Live-Test ausloesen.
- Multiplayer-Manifest-Status pruefen.

## FoW und Air
- In einer Huegel-/Wall-Testmap Dropship/LZ anzeigen.
- Dropship sitzt sichtbar ueber Terrain.
- LZ-/Approach-Marker verschwinden auf unknown Tiles.
- Friendly Dropship bleibt fuer das eigene Team sichtbar.
- Enemy-/Air-Contacts erscheinen nur nach FoW-/Contact-Regel.

## Abnahme
- Keine roten Errors im Godot-Ausgabe-Fenster.
- Keine offensichtlichen UI-Ueberlappungen in FullHD.
- Keine Gameplay-Wahrheit wird in UI-Skripten manuell nachgebaut.
- Offene Sichtbefunde als kleine neue Tasks notieren, nicht gesammelt im Review verstecken.
