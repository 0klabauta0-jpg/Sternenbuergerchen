# Reviewfehler behoben · 13.11.2026

Die neun ursprünglichen Codebefunde und der im vollständigen Regressionstest
zusätzlich entdeckte Fehler C10 sind behoben. Produktcommit: `8252e85ef22ecd7d43ee0e056b97ab5cf09c62e7`.
Basis: Main `9fdeb866b`; Umsetzung im Taskbranch, keine fremden Produktänderungen.

## Korrekturen

- **C1 · Host bestimmt Laufzeitmodifikatoren:** Remote-Befehle enthalten nur Spielerabsichten; interne Befehle behalten ihre legitimen Modifikatoren.
- **C2 · Missionsinteraktionen bleiben beim Host:** Ziel, Radius, Dauer, Voraussetzungen und Bediener stammen aus dem geladenen Szenario. Abbruch, Ausfall, Einschiffung und konkurrierende Trupps sind geprüft.
- **C3 · Raumkampf erreicht einen vollständigen Abschluss:** Sieg, Rückzug und beide Verlustfälle wechseln atomar in den lokalen Orbit. Kraftstoff und Ergebnis werden einmal verbucht; ein vorübergehend abgelehnter Abschluss wird erneut versucht.
- **C4 · Alte beschädigte Einsatzstände blockieren keinen Neustart:** Neue Kampagnen trennen den alten Einsatzstand erst beim sicheren Basis-Commit ab. Seine Bytes bleiben im Archiv; ein unterbrochener Archivschritt macht den neuen Stand nicht unzugänglich.
- **C5 · Basis-Rückkehr lädt ausdrücklich die Basis:** Normales Fortsetzen erhält einen gültigen Einsatzstand. Debrief und bestätigte Wiederherstellung nutzen einen eigenen Basis-Intent; Speichertexte stimmen mit dem Verhalten überein.
- **C6 · Halbe Rampenhöhen bleiben präzise:** Sichthöhe 2,5 wird bis zum Hindernisvergleich erhalten. Beide Richtungen, Cache und unveränderte ganzzahlige Legacyfälle sind geprüft.
- **C7 · Tatsächliche Schüsse verwenden logische Hexsicht:** Richtung, Reichweite, Gelände und Zulassung folgen im aktiven Hexpfad dem vorhandenen Sichtadapter. Alle sechs Achsen und Legacy-Verhalten sind abgedeckt.
- **C8 · Diagnosen würfeln und mutieren nicht:** HUD-Lesen verändert weder Zufallszustand noch Cooldowns, Ereignisse oder Befehle. Tatsächliche Disziplinentscheidungen bleiben Teil der autoritativen Feuerwahl.
- **C9 · Spielmenü hält Eingaben und Fokus zusammen:** Menü, Einstellungen und Hilfe halten den Fokus. Kameratasten und unterbrochene Mausgesten lösen keine verdeckten Aktionen aus; Simulation und gültiger Fokus werden korrekt weitergeführt.
- **C10 · Vollständiger Truppausfall verursacht keine Rekursion:** Der vollständige Kampagnentest fand zusätzlich eine rekursive Anführer-/Auswahlabfrage. Ohne fitte Mitglieder gibt es keinen Verhaltens-Leader; der reine Anzeigeanker bleibt erhalten. Der tatsächliche CombatLoopDriver ist korrekt angebunden.

## Erfolgreiche Regressionen

1048 Assertions in 17 Prüfläufen; erfolgreiche Läufe ohne Engine-/Scriptfehler.
Quellhash-, Originalprofil- und private Profilguards sind Bestandteil der Rohbelege.
Zwei private inkrementelle Editorimports liefen sauber durch; bestehender Cache,
kein behaupteter neuer Kaltimport. Tests laufen seriell mit Prozesszeitlimits.

| Prüfung | Assertions | Fehler |
| --- | ---: | ---: |
| Netzwerkautorität und Interaktionen | 71 | 0 |
| Hexsicht, Schuss und reine Diagnosen | 234 | 0 |
| Raumkampfabschluss und Adapter-Retry | 193 | 0 |
| Menüfokus und Eingabegesten | 60 | 0 |
| Anführer-/Auswahlrekursion | 43 | 0 |
| Einsatzsave, Niederlage und Basis-Recovery | 67 | 0 |
| Reguläres Continue und echte Heimkehr | 80 | 0 |
| Bestehender Netzwerkvertrag | 15 | 0 |
| Verbundene Stationsinteraktionen | 23 | 0 |
| Parallele Truppinteraktionen | 30 | 0 |
| Bestehende Türautorität | 42 | 0 |
| Hex-Sichtcache | 27 | 0 |
| Legacy-Kampf, 600 Ticks | 12 | 0 |
| Frontier-LOS und Fog of War | 76 | 0 |
| Enger Encounter-Read und Abschlussanzeige | 21 | 0 |
| Echte Hex-ENet-Regression | 24 | 0 |
| Hex-Bewegung und Save/Restore | 30 | 0 |

## Verworfen und erneut geprüft

- Erster Netzwerkversuch: Test-API-Fehler, kein akzeptiertes grünes Gate trotz
  ausgegebener 64/0. Der Runner erkennt zusätzlich Enginefehler; die korrigierte
  Probe führt auch die zuvor ausgelassenen positiven Fälle aus.
- Erster Kampagnenversuch: tatsächlicher rekursiver Produktfehler C10. Nur der
  identifizierte eigene Godot-Prozess wurde beendet; Profile blieben unverändert.
  Der gezielte Anführer-Test und der vollständige neue Kampagnenlauf sichern den Fix.
- Ein anschließender Kampagnenlauf erreichte ohne Enginefehler die 300-Sekunden-
  Grenze kurz vor dem Abschluss. Er zählt nicht als bestanden. Der vollständige
  Wiederholungslauf nutzt ein begrenztes 480-Sekunden-Fenster.
- Frühere Interaktionsfixtures 1093/1102 liefern nun echte Hostbindings und ihre
  passenden geladenen Marker; ihre fachlichen Assertions wurden nicht abgeschwächt.
- Der Encounter-Readtest unterscheidet den sichtbaren ausstehenden Rückkehrcommit
  vom bereits verbuchten Ergebnis. Der enge Readpfad bleibt erhalten.

## Nachvollziehbarkeit und Grenzen

Der Testindex steht in `summary.json`; `selection.json` bindet die finalen Läufe
ausdrücklich. `regression_evidence.zip` enthält Rohlogs, Quellhashberichte und
Testskripte, jedoch keine Originalspielerprofile. Die ursprüngliche Reviewevidenz
unter `docs/qa/astra_review_20261113` bleibt unverändert.

Gezielte Headless- und lokale ENet-Prüfungen auf Godot 4.6.2; keine Desktopübernahme. Originalspielerprofile und Quellen blieben während der freigegebenen Läufe unverändert. Kein vollständiger menschlicher Kampagnendurchlauf, WAN-Test, neues GPU-/FPS-Gate oder EXE-Export. Gestaltungs- und größere Architekturvorschläge des ursprünglichen Reviews bleiben separat offen.

Unabhängige Gegenreviews für Netzwerk, Kampagne, Hex/Diagnose und den zusätzlichen
Anführerfix sind abgeschlossen. Beim Menü gefundene Lücken (Polling, Fokus-Kreis,
unterbrochene Gesten) sind implementiert und mit realer Godot-Eingabeverarbeitung geprüft.

## Websiteveröffentlichung

Lokaler Bericht und Websitepaket bestehen jeweils 53 Offline-/Handy-/Exportchecks.
Die Code- und Berichtcommits sind in Main integriert und gepusht. Drei
Veröffentlichungsversuche scheiterten jedoch beim Hostingdienst: zunächst mit
einem allgemeinen workers-sdk-Fehler, danach mit `Failed to publish the built site.`
Auch ein kleineres Paket mit dem Roharchiv als Repositorylink blieb erfolglos.
Eine aktuelle Live-Veröffentlichung wird deshalb nicht behauptet.

Die bereits gespeicherte Websiteversion ist wiederverwendbar. Exakte Projekt-,
Versions-, Deployment- und Sourcekennungen sowie der Archivpfad stehen in
`publication_status.json`; die bestehende private Zielwebsite bleibt
https://sternenbuergerchen-spielreview.klabauta.chatgpt.site.
