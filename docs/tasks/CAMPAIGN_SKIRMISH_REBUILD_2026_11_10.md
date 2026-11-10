# Kampagnenumbau und drei Skirmish-Startstände — Arbeitsplan

Stand 10.11.2026. Umsetzung vom Nutzer beauftragt; Grundlage:
`CAMPAIGN_FIVE_MISSIONS_2026_11_10_PLAN.md`. Eigener Branch auf e765f507c,
bewusst auf noch nicht integrierten Orts-/Gebäudearbeiten; fremdes WIP erhalten.

## Ziel / Ursache / Umfang
Die bisherige Zweiausflug-Einführung soll fünf echte Aufträge mit Heimtransport,
Upload, Blueprints, Rekruten und zweitem Schiff/Pad erhalten. Skirmish erhält drei
vorbereitete, getrennt ladbare Starts mit offener Ortsstruktur. Bisher sind
Auftragsfolge und Speicherformat auf zwei Personen/ein Schiff begrenzt.
Alte lokale Spielstände nach erfolgreicher Prüfung entfernen, Teambibliothek erhalten.
Kein Löschen von Karten/Modellquellen, keine Auswahl neuer Schiffmodelle im Namen
des Nutzers und kein Multiplayerumbau. Fehlende Modelle klar als Platzhalter.

## Festlegungen / Annahmen
- Early: 8 Personen insgesamt inklusive Piloten, Cutlass + 2 Buccaneer,
  Sturmgewehre, gemischte mittlere/schwere Rüstung, Betten für alle.
- Mid: 20 Personen, Vanguard-Dropship/Hornet-Jäger, Valkyrie/Jeep und
  Hercules/Panzer als bezeichnete Platzhalter, solange Modelle fehlen.
- Late: kleine Flotte mit Idris als mobiler FOB/Hangar, Jagdbombern und
  Versorgungs-/Medizin-Infrastruktur; unfertige Spezialfunktionen offen ausweisen.
- Kampagnenstartschiff bleibt vorhandener Dropship-Typ; unklarer gesprochener
  Name wird nicht als neues Modell interpretiert. Technische Gebäudefunktionen
  zunächst aus existierenden Basisgebäuden bedienen.
- Zahlen/Rezepte ohne Nutzervorgabe als überprüfbare Startwerte setzen;
  erstes Blueprint: leichte Rüstung. Lieferkiste: C-Benit.

## Relevante Quellen / Owner
PROJECT_BRIEF, ARCHITECTURE, CODEX_RULES, IMPLEMENTATION_STATUS,
campaign_introduction_contract, orbit_quantum_travel_contract,
location_resource_interaction_contract, persistent_location_runtime_contract,
base_personnel_runtime, campaign/supply/travel owners und bestehende Missionsgates.

## Schritte und Dateien
- [x] 1. Kampagnenkern: fünf Aufträge/Daten, Reihenfolge, Fracht/Upload/Rewards,
  Rekruten/Pad und checkpointfähiger Fortschritt. Betroffen: core campaign,
  mission contracts, campaign checkpoint/start, runtime adapter, Tutorial/Services.
- [x] 2. Skirmish: datengetriebene Early/Mid/Late-Presets, Startauswahl im Menü,
  echter Roster/Flotten-/Inventar-Handoff ohne Überschreiben gespeicherter Teams.
- [x] 3. Karten: drei große Bodenregionen, Mission-2/4-Gegner und Interaktionen,
  Händler/Rohstoffe auf A/B, Weltraumbegegnung mit feindlicher Cutlass und
  neutraler Buccaneer; echte erreichbare Ziele statt Erfolgsbuttons.
- [x] 4. Integration: UI-Commands für Upload/Rekrut/Fracht/Pad, Benit/Inventar,
  mehrere Personen/Betten/Schiffe speichern und laden. Bestehende Owner nutzen.
- [x] 5. Verifikation: neue Funktionsverifier zuerst fehlschlagen sehen,
  nach Umsetzung neue Ablauf-/Restore-/Isolationstests und passende Regressionen.
- [x] 6. Alte Spielstände gezielt inventarisieren/entfernen; Teamdateien per Hash
  erhalten. Doku/Status aktualisieren, nur eigene Dateien committen/pushen.

## Akzeptanz / lokale Prüfung
Fünf Aufträge in Reihenfolge über echte Missionsbelege; Chips erst zuhause
hochladen, Rewards/Rekruten/Schiffe bei Wiederholung nicht verdoppeln.
Fünfte Begegnung: Cutlass feindlich, Buccaneer neutral. Wachstum 2→3→4.
Drei unterschiedliche Skirmish-Starts über Menü ladbar; Early 8 Personen/3 Schiffe,
Mid 20; Bettenkapazität passend. Vorhandene Teams unverändert. Speicherrundlauf
prüft Roster, Flotte, Fortschritt und Inventar. Headless Godot 4.6.2 und
gezielte bestehende Verifier; native Grafik-/Spielspaßabnahme separat.

## Risiken / offene Punkte und Fortschrittsprotokoll
Raumkampf/Träger-/Fahrzeugfunktionen im Bestand zuerst prüfen; Platzhaltermodelle
sind keine Behauptung fertig implementierter Spezialfähigkeiten. Mehrschiff-Saves
sind bisher gesperrt, daher vollständigen Restore vor Freigabe prüfen.
Ruling: Teambibliothek erhalten; Löschung nur alte Spielstände — Nutzerantwort.
Ruling: Early mit acht Personen — Nutzerantwort.


### Umsetzung / Prüfbefunde
- Kampagnenowner und JSON definieren fünf Jobs; sichere Heimkehr und Upload
  schalten Chipbelohnungen frei. Start: vorhandener Entermesser (Cutlass-Modell),
  zwei echte Personen mit leichter Rüstung/Pistole/Medgun.
- Skirmish Early8/3, Mid20/5 und Late30/6 Personen/Schiffe über echte Menüauswahl.
  Eigene Teams bleiben getrennt erreichbar. Größere Modelltypen bleiben benannte
  Platzhalter; Fahrzeugtransport, Trägerhangar, Aufmunitionieren und Medic-Bed sind
  explizit noch keine implementierten Sonderfähigkeiten.
- Ruling: drei reservierte, jeweils auf ein Stück begrenzte Auftragsfrachtplätze
  verhindern eine Sackgasse durch vollen normalen Frachtraum.
- Ruling: Rückbesuch mit neuem Job und Wiederholung einer beendeten Mission
  erhalten neue Szenariogates; endliche Ortsressourcen bleiben erhalten.
- Ruling: M3 verlangt nach Lieferung tatsächliche Rückkehr zum Schiff vor dem
  Abschluss, damit die weit entfernte Händlerinteraktion keine Extraktion fingiert.
- Reproduzierter Bestandsfehler: Gegnergate prüfte downed/dead statt der echten
  Vitalzustände down/bleedout/respawning. Regression mit echtem TestUnit:
  RED3 -> GREEN0; nur fit zählt noch als kampffähiger Verteidiger.
- Die kleinen Außenpostengefechte haben explizite Waffen und eine endliche
  Gegnerbesatzung. Andere Szenarien behalten ihr bisheriges Respawnverhalten.
- Erste echte Missionsrunde mit Boarding/Flug/Landung/Use/Rückweg/Upload/Save:
  55/0 bei4x Simulationsgeschwindigkeit, keine erfundenen Siege.
- Neue Domainprüfungen umfassen die Fünferkette und den4-Personen-/2-Schiff-
  Checkpoint; diese Testbelege ersetzen keine vollständige echte Missionsrunde.
- Echte Missionsabschnitte einschließlich geprüfter Basis-Fortsetzungen belegt:
  erster Ausflug55/0; letzter Lauf77/0 einschließlich finalem Speichern und
  tatsächlichem Continue mit4Personen/2Schiffen/Pad2. Kein ununterbrochener
  nativer Fünf-Missionen-Playtest behauptet.
- Stationscomputer/Schiffsrückkehr21/0, alter Ankunftsverifier10/0,
  datengesteuerte Sternkarte26/0 plus91/0/18/0, freie Skirmish-Herstellung12/0.
- Genau ein echter alter Kampagnenstand gelöscht,61 Profil-/Teamdateien nach
  SHA-256 bytegleich erhalten.24 finale Logs ohne Runtime-/Scriptfehler liegen
  unter docs/qa/campaign_skirmish_rebuild_20261110/.
- Implementierungs-/Dokumentationsprüfung abgeschlossen. Abschließende
  Git-Aktion: nur eigene Dateien im Taskbranch committen/pushen. Kein Mainmerge,
  kein Export; fremdes WIP bleibt erhalten.
