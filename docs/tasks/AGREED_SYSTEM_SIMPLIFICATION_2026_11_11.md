# Abgestimmte Systemvereinfachung: einfacher eigener Teamcharakter

## Ziel / Ursache
Der Punkte-Einkauf bietet bereits Rollen und drei Erfahrungsstufen. Der
Editor eigener gespeicherter Teams zeigt dagegen sofort acht Kernwerte,
fuenf Verhaltensachsen, Kommunikations- und Plattformwerte. Dieser konkrete
Bedienpfad wird vereinfacht, ohne die parallel diskutierten Kampf-/Sichtregeln
vorwegzunehmen. Arbeitsbasis task/native-glut-maps-20261110, noch nicht Main.

## Abstimmung und Vertraege
Anderer Chat Tabletop-Faktoren fuer Performance pruefen: Arbeitsplan zu
Hexsicht/Erkennung und einNPCproFeld/Engpassreservierungen, keine Produkt-
aenderungen in diesem Teilauftrag. Terrain folgt explicit_hex_ramps_contract.
PROJECT_BRIEF, ARCHITECTURE, CODEX_RULES, SKIRMISH_POINTS_START_2026_11_11,
skirmish_prepared_starts_contract und CharacterSheet/Profile-Vertraege gelten.

## Umfang / Nicht-Ziele
Hauptmenue -> eigenes Team -> Charakter beginnt mit lesbarer kompakter
Uebersicht. Einzelwerte bearbeiten ist ausdruecklich zuschaltbar; vorhandene
Werte/Schloesser bleiben erreichbar. Drei Erfahrungs-Vorlagen nutzen dieselbe
Profilsetzung wie der Punktekauf. Auswahl allein aendert nichts; erst Vorlage
anwenden setzt die Faehigkeitsgruppen ueber den bestehenden Roster-Speicherpfad.
Identitaet, Rolle, Traits, Zuordnung, Ausruestung und Fortschritt bleiben.
Kein Kauf/keine separate Preisliste hier. Keine neue Wertewahrheit, keine
Savequantisierung beim Oeffnen und kein Abschaffen interner Werte/Combatregeln.

## Schritte / Dateien / Akzeptanz
1. skirmish_start_configuration.gd bietet nichtmutierende Erfahrungs-Patch-API
   auf Grundlage ihrer bisherigen Punkteprofilfunktion, ohne Identitaetsfelder.
2. main_menu_screen.gd zeigt drei Stufen + bewussten Anwenden-Button mit Hinweis
   auf die ersetzten Gruppen. Standardansicht bleibt read-only, Expertenansicht
   behaelt die bisherigen Einzelwert-/Lockcontrols.
3. Bestehender Profil-/Rosterowner berechnet abgeleitete Werte und speichert.
   Kein Schreiben oder Profilaendern durch Dropdown/Oeffnen/Umschalten.
4. Kleiner Datencheck: drei Stufen, Operator/Pilot/FTL, ungueltige Eingabe,
   Originaldaten unveraendert, Identitaet/Loadout/Rolle nicht im Patch.

## Lokale Pruefung / Risiken / offen
Nur enges check-only und winziger Datencheck nach Root-Fensterfreigabe.
Groessere Menue-/Save-/Gameplaytests sowie native Layout-/Klickkontrolle auf
Nutzerwunsch spaeter. Keine generelle Abnahme oder Performancebehauptung.
Vorlagen ueberschreiben absichtlich individuelle Faehigkeitsgruppen; der Text
muss dies benennen. Alte Teams bleiben ohne Anwenden byteinhaltlich unberuehrt.
Kein Commit/Push oder globaler Statusedit durch den Teilagenten.


## Umgesetzt / enge Pruefung
Default kompakte read-only Personendarstellung, ausdruecklicher Experten-
schalter und drei Erfahrungs-Vorlagen mit Anwenden-Button sind implementiert.
Die Vorlagen setzen nur Faehigkeitsfelder aus der bestehenden Punktefunktion.
Die vorhandene DerivedMath-/Roster-Persistenz bleibt der Speicherpfad.
Editor-Gruppenlimits werden nur nach dem bewussten Vorlagenwechsel auf dessen
Wertebasis zurueckgesetzt; vorhandene Einzelwert-Schloesser bleiben bestehen.
Das ist eine Bedienvereinfachung, kein behaupteter Abbau aller internen Werte.

Godot4.6.2 check-only fuer main_menu_screen exit0, keine Warnung/Scriptfehler.
Ein winziger In-memory-Datenfixture prueft3Stufen xOperator/Pilot/Sanitaet,
FTL-Werte, identische Gruppen zur bisherigen Punkteprofilfunktion, unveraendertes
Original und erhaltene Identitaets-/Rollen-/Trait-/Loadout-/Zuordnungs-/Historien-
felder:163/0, exit0. KeineDatei-/Save-/Klick-/Gameplay-/Matrixsuite gestartet.
Private APPDATA unter output/native_glut_maps/simple_team_experience_20261111.
NativeLayout/Klick und echter Save/Continue gehoeren weiter zur spaeteren Abnahme.
