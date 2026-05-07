# Audio SFX Playability Checklist

## Ziel
TASK_244 ist headless abgesichert; dieser Check ist fuer den ersten echten Hoer-/Sichtlauf im Fenster gedacht.

## Vorbereitung
- Godot im Fenster starten, nicht headless.
- Settings oeffnen und Master/SFX/UI/Combat/Movement auf hoerbare Werte setzen.
- Eine Mission mit sichtbaren Friendly- und Enemy-NPCs starten.

## UI
- Hauptmenue: Settings oeffnen, Apply, Cancel und Defaults pruefen.
- Multiplayer-Lobby: Host-Test, Ready, Roster-Modus und Start pruefen.
- Slider langsam ziehen: es soll kein Dauerklicken entstehen.

## Mission
- Sichtbares Waffenfeuer: Muzzle-Flash und Schuss-SFX sollen zusammen auftreten.
- SMG/Rifle/Sniper/Heavy: grob unterscheidbare Event-Gruppen pruefen.
- Treffer: Impact-SFX bei sichtbarem Damage pruefen.
- Rocket/Heavy Treffer: Explosion oder heavy impact getrennt wahrnehmen.
- Bewegung: Schritte nur bei sichtbaren, bewegten Units; kein Step-Teppich bei stehenden Units.

## FoW und Multiplayer
- Verdeckte Fire-Events duerfen keine exakte Position verraten.
- Snapshot/Remote-Wiederholung derselben Fire-ID darf keinen Doppel-Sound erzeugen.
- Missing-Audio-Warnungen duerfen die Mission nicht abbrechen.

## Ergebnis notieren
- Zu laut/leise:
- Zu haeufig:
- Fehlende Event-Gruppe:
- Auffaellige FoW- oder Multiplayer-Dopplung:
