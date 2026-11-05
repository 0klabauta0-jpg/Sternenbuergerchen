# Vollbild-Spielpass, lesbare Zustaende und neue Basis-UX

## Ziel / Problem
Der Nutzer berichtet regelmaessiges Hakeln, fehlendes lesbares Schussfeedback,
Kapseln statt liegender NPCs im Bleedout, gepunktete Hexkanten bei Fernsicht,
bodennahen Dropshipflug ohne sichtbare Landung und statische Drohnen.
Basis/Teambildung/Loadout, linke Fireteamauswahl und Dropshipkarte sollen den
bestaetigten 2D-Zielen wesentlich naeher kommen, mit deutlich weniger Text.
Neue zusammenhaengende Vierer-Portraets sollen den alten Bildstil ersetzen.
Das urspruengliche Hauptmenuebild soll wieder aktiv sein. Danach Multiplayer
mindestens konkret vorbereiten und vorhandene Grenzen pruefen.

## Basis und Arbeitsweise
Main 90e1f373cd4e070a9a29135225e19cebd297b201, neuer Task-Branch
task/playtest-ux-visuals-20261105. Fremde unversionierte Dateien und normales
Roster sind vor Beginn gehasht. Alle Python-Textzugriffe explizit UTF-8;
die im vorherigen Dokumentationspass entstandene CP1252-Fehlinterpretation
wird bei den betroffenen eigenen Dokumenten nachvollziehbar korrigiert.
Aktuelle Nutzeranweisungen ersetzen alte grafische Groessen-/UI-first-Grenzen.
Keine konkurrierenden Engineprozesse; Root fuehrt alle Laeufe seriell aus.

## Umfang / Arbeitspakete
1. Normalen GM01-Spielpfad im echten Vollbild bei 1x reproduzieren, frametimes
   und wiederkehrende Arbeit erfassen; Ursache vor Optimierung belegen.
2. Echte Waffenereignisse in gut sichtbares Muendungsfeuer und begrenztes
   Schuss-/Zustandsfeedback projizieren. Keine erfundenen Schuesse oder Damage.
3. Im Down/Bleedout das bestehende Figurenmodell erhalten und sichtbar legen;
   bestehende Heilungs-/Respawn-/Sichtregeln behalten. Passende Icons zeigen
   reale Zustaende, mit Form/Tooltip statt reiner Farbunterscheidung.
4. Hexkanten in Fernsicht ruhig und zusammenhaengend darstellen. Dropship
   erhaelt klaren Reiseflug, Abstieg, Landekontakt und Start; Drohnen zeigen
   lesbare sanfte Bewegungs-/Schubsignale. Darstellung bleibt lesend.
5. Referenzgefuehrte Basis-/Roster-/Loadout- und HUD-Revision. Normale Route
   ohne FOB-Zwang; vorhandene FOB-Kompatibilitaet nicht loeschen. Gewuenschte
   begehbare Basis zuerst gegen vorhandene Implementierung/Historie pruefen,
   dann als echte native interaktive Basis umsetzen, ohne zweite Roster- oder
   Transportwahrheit. Aufgaben bleiben auch per gut erreichbarer UI bedienbar.
6. Originales Hauptmenuebild zurueckverfolgen und exakt wieder aktivieren.
   Neue illustrierte Vierer-Portraets samt Einzelportraet-Zuordnung, Prompt,
   Originalausgabe und Variantenmanifest erhalten. Aktuelle Ziele verwenden;
   neue Bild-KI-Vorschlaege bei Bedarf als Entwurf, nie als Runtimebeweis.
7. Vollbild-Eingaben, Teambildung/Ausruestung, normale Mission und Save/Lifecycle
   gezielt testen. Native Vorher-/Nachherbilder und kurze Designbegruendung.
8. Anschliessend Host/Join/Authority/Karten-/Roster-/Versionsabgleich lokal
   untersuchen und mindestens einen konkreten Multiplayer-Vorbereitungsstand
   mit Tests, Voraussetzungen und verbleibenden externen Grenzen liefern.

## Dokumente / Contracts
AGENTS, PROJECT_BRIEF, ARCHITECTURE, CODEX_RULES, IMPLEMENTATION_STATUS,
TASK_ROADMAP; graphics_reference_revision_contract, ui_native_design_contract,
homebase_direct_dropship_flow_contract, flight_altitude_layer_contract,
dropship_lz_target_accuracy_contract, unit_facing_visual_contract sowie die
betroffenen Combat-/Vitals-/Multiplayervertraege. Originale unter
docs/reports/assets/ui-2026-11-01, aktive Frontier-/Ref03-Quellen bleiben erhalten.

## Akzeptanzkriterien / Pruefung
- Alle nativen Spiel-/Bedientests laufen im echten Vollbild auf dem aktiven
  Display; Fenstermodus, Screen-/Viewportgroesse und Renderer werden erfasst.
  Headless-Strukturtests werden separat benannt.
- Ein 1x-Vorher-/Nachherlauf zeigt Frametimeverteilung und wiederkehrende
  Hitches bei unveraendertem Workload; keine pauschale FPS-Aussage aus Medians.
- Schussfeedback, liegende Identitaet und Icons lesen autoritativen Zustand;
  Unknown-Gegner erhalten keine zusaetzlichen Informationen.
- Flug-/Schubdarstellung passt zum vorhandenen Transfer-/Landestatus und
  endet sauber bei Ankunft, Ende, Respawn, Mapwechsel oder Ownerentfernung.
- Teambildung/Loadout/Start sind mit wenigen klaren Aktionen erreichbar;
  Datenwaende wandern in Details. Linkes ausgewaehltes Fireteam und kompakte
  obere Transportkarte sind nativ direkt gegen die Originalvorlage geprueft.
- Originales Menuebild und neue Portraits sind im regulaeren Spiel eingebunden,
  nicht nur als Katalogkandidaten. Vorherige Bilder/IDs bleiben nachvollziehbar.
- Neue/angepasste Befunde vor Code als Untertask/Contract festhalten und mit
  gezielter Regression absichern. Sourcepins und geschuetzte Daten pruefen.
- Unabhaengiges Nachreview; danach wie im fortgesetzten Auftrag auf Main
  integrieren und normal pushen. Keine EXE-/Releaseabnahme ohne eigenen Beleg.

## Dateibesitz
Root: UI/Meta/Portraits/Hauptmenue, zentrale Task-/UXvertraege, Vollbildharness,
Enginekoordination, Evidenz und Git. Performance-Agent: erst Diagnose und
abgesprochene Runtime-/Navigationdateien. NPC-Agent: Figuren-/Combatvisuals.
Flug/Grid-Agent: TerrainMap3DView und abgegrenzte Flug-/Gridvisualhelper.
Zentrale Dateien erst nach konkreter Besitzabstimmung parallel bearbeiten.

## Risiken / offene Punkte
Begehbare Basis und breite UXrevision duerfen bestehende Roster-/Transport-
Owners nicht duplizieren. Grafische Bewegungen aendern keine Gameplayhoehen
oder Schadensregeln. Neue Portraits benoetigen stabile Zuordnung zu bestehenden
Identitaeten. Echter Mehrrechner-/Internetbetrieb braucht externe Teilnehmer;
lokale Loopbacktests sind davon getrennt. Nutzerurteil bleibt gestalterisch offen.

## Status
Implementierung und unabhaengige Nachreviews abgeschlossen. 34/34 gezielte
Headlessgates und native Einzelspieler-/Flug-/Responsive-/Bewegungsgates
bestanden. Echte zwei Sourceprozesse bestehen den vollstaendigen lokalen
Host/Join/Ready/GM01/Drop/Befehls-/Disconnectcheck ohne Enginefehler; Vorlaeufe
mit Fehlern bleiben erhalten. 90 s fortgesetzte Bewegung bei 1x und 0.984
Simulationsdurchsatz belegt. Einzelne Move-/GO-Klickspitzen bis 391.848 ms,
sieben identische Original-Main-Altgates und alle Aussagegrenzen stehen im
Bericht. Originalroster und fremde Dateien bleiben geschuetzt. Integration
und frischer Main-Smoke folgen nach dem Quellcommit. Es wurde keine
Zwischenfreigabe benoetigt.
