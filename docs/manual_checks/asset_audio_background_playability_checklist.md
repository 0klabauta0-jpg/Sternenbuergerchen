# Asset Audio Background Playability Checklist

Stand: 2026-05-07
Status: TASK_250 manuelle Abnahme offen

## Hauptmenue
- [ ] Hauptmenue in 1920x1080 oeffnen; linke Schiene bleibt fest, Background ist sichtbar und Text bleibt lesbar.
- [ ] Einzelspieler-, Multiplayer-, Editor- und Settings-Pfad kurz anklicken.
- [ ] Button-Sounds hoeren: Klick, Bestaetigen, Warnung/Cancel bei passenden Aktionen.

## Settings
- [ ] Audio-Regler fuer Master/Music/SFX veraendern und anwenden.
- [ ] UI-Sound wird leiser/lauter, ohne Settings-Panel oder Fensterlayout zu verschieben.
- [ ] Gameplay-/FoW-/Bubble-Settings bleiben sichtbar und werden nicht durch Audio veraendert.

## Multiplayer
- [ ] Multiplayer-Lobby oeffnen; Hangar-Background ist projektlokal, gedimmt und stoert das feste Panel nicht.
- [ ] Host-/Join-Felder, Ready, Start, Disconnect und Back bleiben erreichbar.
- [ ] Ohne Aktion entstehen keine wiederholten Audio-Events.

## Mission
- [ ] Kleine Mission starten, LZ setzen und Dropship deployen.
- [ ] Friendly und Enemy sind sichtbar; Waffen/Helme/Loadouts sitzen plausibel.
- [ ] Schritt-, Schuss-, Impact- und Explosion-SFX hoeren.
- [ ] Muzzle-Flash und Trefferwirkung sind sichtbar; FoW zeigt nur sichtbare Fire-Events.

## Background
- [ ] Main Menu, Lobby, Mission-Setup/Select, Loading und Debrief-Backgrounds bleiben im Projekt unter `res://`.
- [ ] Backgrounds skalieren/croppen nur visuell und aendern keine festen Fenster.

## Abschlussgates
- [ ] TASK_247 Projektlokalitaetsgate laufen lassen.
- [ ] TASK_249 Audio-/Visual-Performancegate laufen lassen.
- [ ] Auffaellige Missing-Asset-, Missing-Audio-, Stutter- oder Alignment-Befunde als Folgetask notieren.
