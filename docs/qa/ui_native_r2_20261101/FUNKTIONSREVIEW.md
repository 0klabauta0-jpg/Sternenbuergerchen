# Funktionsreview R2

## Bestätigte Befunde und Korrekturen
- Roster: Die Seeds `native_shell_fixture` mit Profilen `native_shell_1280_720_3799609` und `ui_native_shell_fixture` erzeugen reguläre effektive Toughness unter 0.22. `UnitSkills` und `UnitProfileMath` besitzen den effektiven Bereich 0..1; 0.22 begrenzt nur den Basiswurf. Der Generator-Validator verwechselte beides und verhinderte den Store-Save. Die Prüfung folgt jetzt dem bestehenden effektiven Vertrag, inklusive Endlichkeit. Keine generierten Werte oder Traits geändert. Eigener Verifier prüft echte Store-Roundtrips und ungültige Werte.
- Mission: Der A5-Präsentationshelfer überschreibt beim gewöhnlichen Lösch-/Ordnungsbutton die vom Controller ermittelte Hervorhebung mit `button_pressed`. Präsentation soll denselben vorhandenen Fokuszustand lesen.
- Bibliothek: Auswahl baute alle Zeilen neu und entfernte den Fokusinhaber. Zeilen sollen bei Auswahl erhalten und nur Auswahlstile erneuert werden; reguläre vollständige Aktualisierungen stellen den passenden Fokus wieder her.
- Audio: Drei native Slider waren unbeschriftet. Kanal und Entwurfswert sollen sichtbar bleiben; Cancel darf keine Persistenz auslösen.
- FOB-Fokus: Im unabhängigen Abschlussreview war die neue Kontextzeile nur an Layoutänderungen gekoppelt. Ein unmittelbarer Wechsel von ALPHA im Loadout auf freies BRAVO zeigte noch ALPHA. Der neue Regressionstest reproduzierte dies in beiden Größen ohne Resize/Frame-Wartezeit; die Zeile folgt jetzt dem vorhandenen Toolbar-Zustandsrefresh.
- Lobby: Der bisherige Vollfenster-Scroll schnitt die Host-Zeile an und verbarg Sitzungsaktionen unter dem Falz. Nur Setup/Diagnose scrollen jetzt innerhalb des bestehenden 720×560-Fensters. Verbindungs-/Sitzungsaktionen bleiben fest; Badges umbrechen vollständig. Bereitschafts-, Client- und Consentgates sowie die Kontexthilfe werden separat geprüft.

## Bewusst offene bestehende Grenze
Die Lobby-Methode `_on_map_accept_pressed()` setzt derzeit nur den Status „Waiting for host map payload…“. `accept_pending_map_download(map_json_text, cache_root)` verarbeitet dagegen einen explizit übergebenen Payload; nach Quellenvergleich kommt dieser Aufruf derzeit nur aus Verifiern, nicht aus einem verbundenen UI-Downloadpfad. Deshalb wird keine abgeschlossene Kartenübertragung oder reale Mehrspielerpartie behauptet. Die Netzwerkanbindung ist ein separater funktionaler Task und gehört nicht in diesen Darstellungs-Pass.

## Nachweisgrenzen
Headless-Verifier prüfen native Controlbäume, echte Callbacks, Sperren und Datenpfade. Nicht-headless-Captures prüfen die gerenderte Ausgabe. Ein vollständig menschlich durchgespielter Basis→FOB→Mission→Debrief-Ablauf sowie echte verbundene Peers sind damit nicht nachgewiesen.
