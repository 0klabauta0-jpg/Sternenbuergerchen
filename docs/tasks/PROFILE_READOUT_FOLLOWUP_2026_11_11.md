# Profilanzeige: Vorlagen klar von individuellen Personen trennen

## Ziel / Ursache
Die kompakte Charakterkarte nennt beliebige Profile anhand eines Mittelwerts pauschal wenig/mittel/gut erfahren. Angepasste Charaktere wirken dadurch wie feste Kaufvorlagen. Die vorhandenen acht Kernwerte und weiteren Achsen bleiben intern notwendig; eine neue Balanceformel ist hier nicht autorisiert.

## Umfang / Nicht-Ziele
Read-only Vergleich der vier vorhandenen Faehigkeitsgruppen mit build_experience_patch aus dem Punkteprofilpfad. Nur bei vollstaendiger Werteuebereinstimmung heisst es Entspricht Vorlage: [Stufe]. Sonst Individuelles Profil, ohne automatische Niveaustufe oder behauptete Herkunft. Kleiner Profilwirkungs-Hinweis aus vorhandener UnitProfileMath-Ableitung, ausdruecklich nur Profilanteil. Keine Runtimegetter, Formeln, Kosten, Savefelder oder Bewegung aendern.

## Quellen / Vertraege
AGENTS; PROJECT_BRIEF; ARCHITECTURE; CODEX_RULES; AGREED_SYSTEM_SIMPLIFICATION_2026_11_11; character_roster_generation_contract; skirmish_prepared_starts_contract; profile_readout_contract. Tabletop besitzt AP5/Bewegung und behaelt seine bestehenden Runtimegetter.

## Akzeptanz
- Alle drei Vorlagen fuer Operator/Pilot/FTL werden ueber denselben Punkteprofilpfad erkannt.
- Aenderungen in irgendeiner der vier Gruppen oder fehlende/andersartige Werte ergeben keine Vorlagenbehauptung.
- UI-Aufruf veraendert kein Profil, keine Ausruestung, Identitaet oder Historie.
- Profilwirkung liest kanonische effektive Werte ohne erneute Traitboni; Waffe, Ruestung, Gelaende, Zustand und endgueltiges Laufzeittempo werden nicht simuliert.

## Dateien
scripts/meta/skirmish_start_configuration.gd, scripts/meta/character_sheet_formatter.gd, scripts/meta/character_sheet_view.gd; genau eine veraltete Beschriftungs-Assertion in scripts/tests/skirmish_points_start_test.gd an den neuen Vertrag anpassen (Suite nicht erneut ausfuehren). Eigener Contract und privater winziger Verifier unter output/native_glut_maps/profile_readout_20261111. Keine globalen Statusdateien durch den Teilagenten.

## Lokale Pruefung / Grenzen
Nur kleiner Datenfixture und check-only, keine GPU-/Browser-/Save-/Gefechtsmatrix. Der neue Formatter-Preload fuehrt in einer statischen Pfadsuche nicht zurueck zum Formatter (14 transitive GDScript-Abhaengigkeiten). Dies ist weiterhin eine Anzeigevereinfachung, kein Abbau interner Kampf-/Faehigkeitsachsen. Native Layout-/Klickabnahme und gemeinsame Laufzeitpruefung spaeter.

## Enger Umsetzungsnachweis
Umgesetzt: exakt vier Gruppen mit dem vorhandenen Punkteprofilpfad vergleichen, sonst Individuelles Profil. Profilanteil im bestehenden Werte-Foldout und im Erfahrungs-Tooltip; kein zusaetzlicher Kopfblock ueber dem Inventar. Drei Produktdateien check-only Exit0. Privater Datenfixture24/0, Import/Run Exit0, keine Script-/Leakfehler: Operator/Pilot/FTL-Vorlagen, echte Profilbuilderprojektion, Gruppenabweichungen, identischer Mittelwert mit anderem Profil, kanonische Gruppen statt veralteter Aliase, keine zweite Traitwirkung, Kopie/Unveraendertheit, NaN/Text/fehlende Werte und Nullprofil. Die bestehende Skirmish-Assertion wurde semantisch aktualisiert, ihre gesamte UI-Suite nicht erneut ausgefuehrt. Keine Runtimegetter oder Preise geaendert, kein Commit/Push durch Teilagenten.
