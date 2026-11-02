# Gegenprüfung der Zielbildrunde

## Unabhängiger Quellreview

Der lesende Review prüfte Signal-/Objektlebensdauer des passiven Rahmenzeichners, Missionsgeometrie, Kontextwerkzeuge und Rückmeldungen, Hex-/FoW-Grenzen sowie die normale NPC-Namensgröße. Kein zusätzlicher Engineprozess durch den Reviewer.

Gefunden und korrigiert:

- Godot meldet `get_meta(key, null)` bei fehlendem Schlüssel trotzdem als Fehler. Expliziter `has_meta`-Guard; der erste Gate-Vorlauf wurde verworfen.
- Kontextwerkzeuge dürfen REQUEST-/REJECT-/TIMEOUT-Feedback nicht verdecken. Eigene Slots nach den Teamparametern, Feedback bleibt sichtbar. Der Feuerregelkopf erhält genug Breite für den vollständigen Pendingtext; bestätigter Regelwert bleibt beim bestehenden Owner.
- Die alte doppelte vertikale Stance-Innenkante erzwang mehr Höhe als der neue Slot. Innere vertikale Zusatzmargins entfallen; die tatsächlichen nativen Rects werden geprüft. Eine weitere Gate-Runde fand eine knappe Überlappung zwischen Zusammenfassung und Haltung; der Haltungsslot wurde entsprechend nach unten verschoben.

Die Korrekturen wurden erneut unabhängig gegen den Quellstand gelesen. Keine weiteren bestätigten funktionalen Befunde im begrenzten Reviewumfang. Die erweiterten vorhandenen Verifier prüfen vollständige Pendingtextbreite, sichtbares Feedback bei einem echten geplanten Wegpunkt, getrennte Rects und unveränderte Callback-/Ownergrenzen.

## Visuelle Grenze

Die direkten Originalvergleiche stehen in `BILDVERGLEICH.md`. Rahmen, Schriftgewichtung und Befehlsband sind eine begrenzte native Runde. Vereinfachte Gebäude, Felsstaffelung, entfernte Menübühne und heterogene Pixelportraits bleiben offen. Technische Grünmeldungen sind keine gestalterische Nutzerfreigabe.
