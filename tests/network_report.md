# N1a — Point-and-Click-Koop

Stand nach Nutzerkorrektur: Figuren werden ausgewählt und über Rechtsklick beziehungsweise den autoritativen `move`-Befehl zu einem Ziel geschickt. Die zusätzliche Richtungssteuerungsprobe wurde entfernt; frühere Messungen dazu sind kein Lieferstand.

`tests/network_probe.gd` enthält weiterhin den bisherigen Missions-/Save-/Reconnect-Nachweis mit zwei echten ENet-Prozessen. Er prüft Crewbesitz, verweigerte fremde Befehle, gemeinsame Pause, bestätigtes Wegziel, Werkbankarbeit, Reise, Bergung, einmalige Auszahlung und Disconnect/Reconnect. Die Revisionsbarriere nach Laden eines älteren pausierten Saves sowie die Fließkommatoleranz beim wiederhergestellten Ziel bleiben erhalten.

`tests/network_run.ps1 -Visual` lädt die echte `scenes/game.tscn` in zwei Produktfenstern. Beide Prozesse verwenden isolierte Speicherpfade und erzeugen pro Rolle Viewport-Captures für `paused` und `reconnected` samt vollständigen Snapshot-JSONs. Die Prüfung umfasst bei Erfolg weiterhin 27 Host- und 21 Gastchecks (48 insgesamt), inklusive vier Captures.

Aktueller Status: Abschließender Fensterlauf nach dem Icon-HUD-/Point-and-Click-Umbau bestanden:

```text
host: checks=27 failed=0 snapshots=55
guest: checks=21 failed=0 snapshots=35
NETWORK_TWO_PROCESS_PASS
```

Evidenzordner: `C:\Users\bjoer\AppData\Local\Temp\sternenbuergerchen-network-f0b634130bdd4dec9271c07c9d0f6b82`.

Alle vier echten 1440×900-Viewportbilder wurden geöffnet und visuell geprüft: `host-paused.png`, `guest-paused.png`, `host-reconnected.png`, `guest-reconnected.png`. Sie zeigen das aktuelle kompakte Icon-HUD, Point-and-Click-Hinweise, korrekt beschrifteten Crewbesitz und die echte Produktwelt. Die Werkstatt nennt in beiden Prozessen korrekt Ida als tatsächlich arbeitende Person. Der Gast kann die Hostarbeit nicht abbrechen.

| Phase | Vollständige Host-/Gast-Snapshots | Revision | Credits | Auftrag | Pause |
|---|---|---:|---:|---|---|
| paused | identisch | 285 | 180 | active | ja |
| reconnected | identisch | 909 | 440 | claimed | ja |

Geld/Blueprint werden genau einmal gebucht; Crewbesitz und zwei vorhandene Crewmitglieder bleiben beim Reconnect konsistent. Der ältere pausierte Save wird mit höherer Revision an den verbundenen Gast übertragen. Beide Enginefehlerlogs sind leer. Die vom Runner gestarteten Prozesse sind beendet.

Diese Abnahme belegt die echten ENet-Befehle und ihre Wirkung in zwei Produktfenstern. Tatsächliche Mausbedienung wird separat im GUI-Produktlauf geprüft. Internet/NAT, Paketverlust, PvP und die vollständige Kampagne sind nicht Gegenstand dieser begrenzten Netzprobe. Die abschließende Abnahme eröffnet keinen weiteren Testscope.
