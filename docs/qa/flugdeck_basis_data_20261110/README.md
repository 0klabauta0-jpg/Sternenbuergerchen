# Flugdeck, Basisverwaltung und Missionsdaten — 10.11.2026

## Stand und Umfang
Taskbranch task/flugdeck-layout-20261110 auf aktuellem Main b92808399.
Alle im laufenden Playtest ergänzten Nutzerwünsche sind in zugehörigen Tasks
und Contracts festgehalten. Kein neuer Mainmerge/EXE-Export in diesem Nachtrag;
die vorhandene r04-EXE bleibt unverändert. Ursprünglicher Arbeitsbaum und
fremdes WIP nicht überschrieben. Tests verwenden private APPDATA-Profile.

## Korrigiertes Verhalten
- Flugdeck ersetzt Einsatz & Abflug, Sternkarte steht danach. Reales Pad/Schiff
  oben rechts; kompakter Pilot-/Statusbereich, Schiffsauswahl rechts,
  Boarding/Trupp absetzen/Abheben in gemeinsamer Zeile. Nur gebaute Pads sind
  auswählbar; Auswahl ist kein Umsetzen/Boarding. Keine doppelte Schiffskarte.
- Pilot bleibt zusätzlich FT-Mitglied. Eigene physische Anwesenheit und Anzahl
  real anwesender FT-Mitglieder werden angezeigt. Individualausstieg des
  Piloten erhält FT1 und Anjas Boarding. Rollenwechsel zu bereits anwesender
  Anja erlaubt keinen Abflug mit draußen gebliebenem früherem Piloten.
- Basisvorschau: äußeres 2D-Viewport bleibt sichtbar aktualisiert. MMB-Anker
  kommt aus dem tatsächlichen GUI-Event und demselben Canvastransform, statt
  aus einer möglicherweise veralteten globalen Mausposition. Rückkehr aus
  Pad-Nahaufnahme stellt Übersicht her. Native Panprüfung hält echte Details
  im 3D-Bild, statt lediglich geänderte Labelpixel als Erfolg zu werten.
- Basisaktionen Bauen, Werkstatt/Blueprints, Lager/Ausrüstung, Datenterminal,
  Schiff öffnen vorhandene Views/Ownercommands. Gesperrte vorhandene Rezepte
  bleiben sichtbar erklärt. Bauen umfasst derzeit das echte zweite Landepad.
  Keine freien Gebäude oder neuen Schiffskomponenten vorgetäuscht.
- Datenterminal ist über Basis erkunden direkt auffindbar. Echter Upload und
  echte Herstellung werden jetzt auch durch die kanonische Operationsseite
  geroutet. Keine zusätzliche schwebende Servicekopie auf dieser Seite.
  Kampagnenhilfe verdeckt weder Basisaktionsleiste noch Uploadseite.
- Ein ausdrücklicher Computer-Use kann Annäherung und danach echte zeitliche
  Aufnahme vorbereiten; keine Rohbewegung allein aufs Ziel. GO bleibt im
  Planmodus erforderlich. Dauer, Radius, Kontakt- und Hostgates bleiben.
  Ein neuer getakteter Hinweis zeigt Vorbereitung, Fortschritt und dauerhaft
  den echten Abschluss samt Heimtransport-/Datenterminalhinweis. Keine
  erfundene Ausrüstungsposition zum manuellen Anlegen dieser Missionsdaten.
- Trupp absetzen bezeichnet Unboard an der Basis und erneutes Deploy am
  geerdeten Kampagnenschiff. Landen bezeichnet weiterhin den Anflug. Deploy
  nutzt bestehende SimulationRoot-Effekte und respektiert Insertion Security.

## Gezielte Belege
13 saubere Läufe in results.json. Kamera52/0, Inventar28/0, Servicewahl1/0,
stationärer Use21/0, Kampagnenstart13/0, Kontextcursor12/0, echter
Maus-Press/Release/GO von Nachbarfeld und außerhalb der Reichweite je17/0.
Pilot/FT/Rollenwechsel/Save/Continue28/0. Tatsächlicher erster Ausflug mit
Pilot in FT1, erneutem Einsteigen und Absetzen, Datenaufnahme, Heimflug,
Button-Upload im Datenterminal, einmaliger Belohnung, Button-Herstellung von
Rüstung samt endlichem Lagerzugang/Kosten und realem Basischeckpoint:70/0.
Keine fingierten Missionsabschlüsse in diesem Ausflug.

Native D3D12/Forward+-Läufe: Flugdeck-/Basislayout40/0 (4 bekannte UID-Warnungen),
Basisverwaltung15/0 (2 UID-Warnungen), Satelliten-Mausweg17/0 (0 Warnungen),
je Exit0 und0 Enginefehler. Unsichtbarer eigener OS-Host1280×720;
Flugdecklayout zusätzlich mit logischen Rootgrößen1280/1920/3440 geprüft,
keine Behauptung dreier tatsächlicher OS-Fensterauflösungen. Bilder in images/
wurden geöffnet: Schiff/Pad, Basis nach Pan mit Gelände/Gebäuden, sichtbarer
leerer Datenterminal und tatsächliche Datenbestätigung. Keine menschliche
Stil-/Spielspaß- oder allgemeine GPU-/Performancefreigabe.

## Reproduktionen und Grenzen
Der ursprüngliche direkte Use konnte aus gültigem Nachbarabstand im echten
Mausweg ausgeführt werden. Nutzer bestätigte später selbst, dass die Aufnahme
funktioniert; unklare Rückmeldung/Uploadadresse waren eigenständige Probleme.
Beim ergänzten vollständigen Annäherungs-Use reproduzierte ein echter Weg die
fehlende Umstellung auf zeitliche Aufnahme: RED17/3, danach GREEN17/0.
Die erste Panprüfung akzeptierte nur geänderte Pixel; Bildsicht fand leeren
Hintergrund. Verschärft: RED39/1 bei einfarbigem3D-Bild, danach GREEN40/0
mit detaillierter Szene nach tatsächlichem MMB-Input und freier Aktionsleiste.

Altes base_personnel_runtime_verifier meldet vier identische Abweichungen auf
Task und sauberem Main b92808399: drei alte manuelle Schlafannahmen und eine
alte getauschte Pilot-/Checkpointfixture. Separat erneut mit passendem
unverändertem Icon-Importcache geprüft: beiderseits0 Enginefehler, dieselben
vier Assertions. baseline_deviations.json und Logs; kein grüner Gesamtsuiten-
Nachweis behauptet und keine Änderung an Schlafregeln in diesem Task.

Schiffskomponenten sind nur geplant in
../../tasks/SHIP_COMPONENTS_2026_11_10_PLAN.md. Modelle, Slots und Balancing
bleiben offen. Engere Gebäudeanordnung bleibt eigener älterer Authoringtask.
