# Echte Kampagnenpersonen und begehbare Basisraeume

Stand 10.11.2026. Umsetzung auf `task/base-personnel-world-20261109`,
Grundlage Main `2302ac85a`, Produktkandidat `c9d84f58d`.

## Ergebnis und Grenzen

Die Kampagnenbasis zeigt die beiden echten Rosterpersonen, keine dritte
Commanderfigur. Auswahl funktioniert ueber Figuren und Personenliste, auch
fuer Besatzung an Bord. Ausruestung, Rollen und Transport verwenden weiterhin
die vorhandenen Owner. Basiswege laufen beim Ansichtswechsel weiter.
Schlafen bedeutet ein freies Bett reservieren, hingehen, hinlegen und wecken;
es fuehrt keine neue Heilungs-/Muedigkeitsbalance ein.

Beide Personen koennen im Einsatz am Boden teilnehmen. Eine echte Person muss
vor dem Flug den aktuell zugewiesenen Pilotenplatz besetzen; auch der Leader
darf uebernehmen. Es gibt keine unsichtbare Ersatzbesatzung und keine neue
zufaellige Absturzmechanik. Kampagnen- und Skirmish-Spielstaende bleiben getrennt.

Die eingerichteten Originalmodelle bleiben als unveraenderte Quellen erhalten.
Nachvollziehbare Ableitungen ergaenzen die fehlenden Tueroeffnungen. Feinere
statische Laufdaten passen zu deren Waenden, Moebeln und Bedienpunkten. Details,
Modellvergleiche, Quellenhashes und Messgrenzen stehen in [GEOMETRY.md](GEOMETRY.md).

Alle Agententests liefen headless mit privaten Profilen und niedriger Prioritaet.
Es wurden keine sichtbaren Testfenster geoeffnet und keine Maus-/Tastatureingaben
am Desktop gesendet. Die Bilder sind Modellpruefungen aus Blender, keine nativen
Spielaufnahmen. Gestaltung und native Mausbedienung bleiben menschliche Abnahme;
die begrenzten Messungen sind keine allgemeine FPS-/Releasefreigabe.

## Technische Nachweise

| Pruefung | Ergebnis |
|---|---|
| Reale Gebaeudemeshes / Koerperabstand | 14 Zielrouten, 1.452 Nachbarverbindungen ohne Schnitt |
| Skin-/Animationskontur | 64 Posen, Radius maximal0.165 bei geprueftem Koerperradius0.18 |
| Originalraum-/Quellenregression | 22 bestanden, 0 fehlgeschlagen |
| Blender-QA beider Modellableitungen | 0 Fehler; bekannte Quellenwarnungen dokumentiert |
| Basisruntime, Betten, Abbruch, Boarding, Save/Continue und Pilotenausruestung | 39 bestanden, 0 fehlgeschlagen |
| Tatsaechliche Controls / Welt-Personal-Bruecke | 9 bestanden, 0 fehlgeschlagen |
| Kampagnenstart | 11 bestanden, 0 fehlgeschlagen |
| Skirmish: zwei echte Ausfluege | 60 bestanden, 0 fehlgeschlagen |
| Kampagne: beide NPCs, anderer Pilot, zwei Ausfluege und zweimal Fortsetzen | 97 bestanden, 0 fehlgeschlagen, Exit0; Einzelheiten in PILOT.md |
| Menuegrenze / unvollstaendige Vorbereitung fortsetzen | 29/0 und10/0 |
| Kampagnendomain / Zweierformation | 0 Fehler und8/0 |
| Terminale Niederlage / fehlgeschlagene Extraktion / Checkpoint-Button | 56 bestanden, 0 fehlgeschlagen; CASUALTY.md |

Rohbelege liegen in `raw/`. Alte Zwischenlaeufe sind anhand ihrer Dateinamen
kenntlich; der endgueltige Runtimebeleg ist
`raw/base_personnel_runtime_verifier_final.log`.

Ein unabhaengiger Task3-Reviewer reproduzierte einen Fehler beim erneuten
Boarding nach Pilotenausstieg: Personenanzeige wurde vom echten Payload getrennt.
Idempotenz, Erhalt bereits eingeschiffter Personen und Fehlerrollback wurden
korrigiert. Der Reviewer wiederholte seinen eigenen Repro erfolgreich.
Der breite Branchreview fand einen weiteren wichtigen Befund: Terminale
Niederlagen mit ausgefallenen Personen warteten vor Ergebnis/Recovery/Debrief
auf unmoegliches Boarding. Der Fehler ist korrigiert; die beiden echten
Ausfall-/Checkpoint-Szenarien bestehen56/0. Der fehlgeschlagene Ausflug wird
ausgewertet, aber nicht gespeichert; die sichtbare Weiter-Aktion laedt den
letzten sicheren Basisstand. Details und RED/GREEN-Belege: [CASUALTY.md](CASUALTY.md).
Die gezielte Review-Nachpruefung hat den Fix freigegeben; keine verbleibenden
Critical/Important-Befunde im geprueften Umfang. Der gitgebundene Export-/Paket-
und Startnachweis wird im neuen Buildordner unter
`C:/dev/SternenBuergerchen-builds/` abgelegt.

Ein zusaetzlich ausgefuehrter aelterer Task503-HUD-Prueffall bleibt bei9/1
(read-only Roster bei eingeschifftem FT1). Er verwendet den Skirmish-Standardpfad;
eine genaue Baselinezuordnung dieses einzelnen Befunds ist noch nicht nachgewiesen.
Der HUD wurde dafuer nicht veraendert. Es wird deshalb kein komplett gruener
Gesamttestbestand behauptet. Weitere begrenzte Dropship-/Effektregressionen und
der Zweierformationsnachweis stehen in PILOT.md.

## Selbst testen

1. Hauptmenue → Kampagne → Fortsetzen oder Neue Kampagne. Im Basismenue
   `Basis erkunden` oeffnen. Einen der beiden NPCs anklicken oder in der
   Personenliste waehlen; Rechtsklick setzt sein Laufziel.
2. Durch die sichtbaren Tueren zu beiden Schlafplaetzen und den Arbeitsbereichen
   gehen. Auf ein Terminal klicken: Die Person geht zum Bedienpunkt und oeffnet
   erst dort dieselbe vorhandene Ansicht.
3. Beide Personen ausruesten, einsteigen und aussteigen lassen. Eingeschiffte
   Personen bleiben in der Liste auswaehlbar. Schlafen/Wecken, belegtes Bett und
   Wegabbruch pruefen; Ansichtswechsel duerfen den angeforderten Weg nicht stoppen.
4. Satellitenauftrag und anschliessend Handels-/Tanketappe spielen. Beide NPCs
   duerfen aussteigen. Vor dem Rueckflug beide zum Schiff fuehren und einschiffen;
   in der gelandeten Schiffskarte kann eine andere echte Person den Pilotenplatz
   uebernehmen. Ohne echte Anwesenheit muss der Flug mit einem Grund gesperrt sein.
5. An der Basis speichern lassen, zurueck ins Hauptmenue und Fortsetzen.
   Identitaeten, Ausruestung, Pilot, Ressourcen und Bett-/Boardingzustand vergleichen.
