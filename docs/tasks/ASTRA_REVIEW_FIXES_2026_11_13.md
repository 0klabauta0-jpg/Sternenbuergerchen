# Reviewbefunde und bestätigte Regressionen beheben · 13.11.2026

## Ziel / Problem
Alle neun bestätigten Codebefunde C1–C9 aus
docs/reviews/ASTRA_REVIEW_2026_11_13.md beheben. Nutzerauftrag: „Behebe alle Fehler.“
Basis ist Main9fdeb866b plus reiner Reviewdokumentation d7da0c539; kein fremder
Produktkandidat. Die Fehler sind mit privaten Reproläufen belegt.

Zusätzlich C10: Der vollständige Kampagnentest zeigte nach gültigem Active-Continue
und Ausfall beider Truppmitglieder einen Stackoverflow zwischen Verhaltens-Leader
und Auswahlanker. Beleg: docs/qa/astra_fixes_20261113/campaign/79b34e4c27994a3e901d8cef9c648f81/output.log,
erster Fehler Zeile 44. Die gegenseitige Fallback-Abhängigkeit wird entfernt.
Der Leaderlookup verwendet außerdem den vorhandenen CombatDriver-Lookup: die
tatsächliche Missionsszene nennt den Owner `CombatLoopDriver`, nicht
`MissionCombatLoopDriver`. Der bisherige Kompatibilitätsname bleibt unterstützt.

## Ursache / Sinnhaftigkeit
Clientdaten überschreiten Autoritätsgrenzen; Reise-/Saveübergänge widersprechen
ihren Contracts; Hexsicht und Schuss unterscheiden sich; Diagnose- und Modal-
Eingabegrenzen sind nicht rein. Korrekturen bleiben bei bestehenden Ownern.

## Umfang und Nicht-Ziele
C1/C2 Netzwerkabsicht/Interaktion; C3 Encounterabschluss; C4/C5 aktive/Basis-Saves;
C6 Höhenpräzision; C7 logische Hex-Schusssicht; C8 reine Diagnosen; C9 Menümodalität.
C10 trennt handlungsfähige Führung vom reinen Auswahlanker bei vollständigem Ausfall.
Kein neuer Kampfentwurf, keine Kartenmigration, keine Asset-Neugestaltung, kein
großer Controllerumzug. Begleitende falsche Speichertexte/Vertragsdrift korrigieren,
soweit sie die behobenen Pfade betreffen. Gestaltungsvorschläge bleiben Vorschläge.
Keine Desktopübernahme. Originalspielerprofile und fremdes WIP erhalten.

## Relevante Dokumente
AGENTS.md, PROJECT_BRIEF.md, ARCHITECTURE.md, CODEX_RULES.md;
docs/reviews/ASTRA_REVIEW_2026_11_13.md;
docs/dev/multiplayer_authority_command_contract.md;
docs/dev/combat_loop_authority_contract.md;
docs/dev/hex_tactical_runtime_contract.md;
docs/dev/orbit_quantum_travel_contract.md;
docs/dev/html_report_workbench_contract.md;
betroffene Kampagnen-/Save-/Space-Area-Contracts und frühere QA.

## Akzeptanzkriterien
- C1: Remote-Commands bestimmen keine internen Modifikatoren; gültige Befehle bleiben erlaubt.
- C2: Host löst Interaktionsdaten selbst auf; falsche IDs/Parameter/Voraussetzungen umgehen kein Gate.
- C3: gebundener Sieg/Rückzug/Niederlage erreichen konsistenten Abschluss; Fuel/Ergebnis nur einmal.
- C4: beschädigter alter aktiver Slot blockiert keine neue Kampagne und bietet sichere Wiederherstellung.
- C5: expliziter Basis-Rollback lädt tatsächlich Basis; normales Continue erhält gültigen Einsatzsave.
- C6: Halbwerthöhen bleiben bis LOS-Vergleich erhalten; Square8-/Integerfälle unverändert.
- C7: aktive Hex-Schüsse lesen logische Sicht/Richtung/Reichweite; Legacy bleibt kompatibel.
- C8: Diagnose verändert weder RNG noch Cooldowns/Ereignisse, auch leer→Gegner vorhanden.
- C9: Menü/Einstellungen/Hilfe halten Fokus und verhindern verdeckte GUI-/Gameplayaktionen;
  gültiger vorheriger Fokus kehrt zurück, Simulation läuft weiter.
- C10: Ohne fittes Truppmitglied gibt es keinen Verhaltens-Leader; ein registriertes
  Mitglied darf als reiner Auswahlanker erhalten bleiben. Lebende Driver-Führung,
  konfigurierter Lead und bester fitter Leadership-Fallback behalten ihre Reihenfolge.
  Down/Revive, leerer Trupp und veralteter Driver-Verweis terminieren ohne Rekursion
  und ohne Mutation von Units oder autoritativer Führungszuordnung.
- Regressionen verwenden tatsächliche Produktionspfade, private Profile und Prozesszeitlimits.
- Ergebnis unabhängig prüfen, in Main integrieren nach bestehendem Auftrag, Websitebericht aktualisieren.

## Betroffene Dateien / Zuständigkeit
Netz: multiplayer_command_contract.gd, Interaktionsbereich des CombatDrivers,
gegebenenfalls kleiner Host-Resolver und eng begrenzter Root-RPC-Anschluss.
Kampf: los_system.gd, combat_fire_decision_resolver.gd, übriger CombatDriver.
Kampagne: Reise-/Encounterowner, Savekonfiguration/-stores, Metaflow und Savebeschriftung.
Root: global_escape_menu.gd, Inputgrenzen, gemeinsame Runner/QA/Dokumentation/Integration.
C10: mission_tactical_sandbox_controller.gd und astra_leader_fixes_20261113.gd;
anschließend vollständiges Kampagnen-Gate erneut prüfen.
Agents bearbeiten nur zugewiesene Bereiche; gemeinsam verwendete Dateien abstimmen.

## Lokale Prüfung
Vorhandene rote Repros erhalten. Neue Erwartungstests für jede Korrektur, echte
ENet-Positiv-/Negativfälle, kombinierter Mission-Save→Fehlschlag→Basis-Rollback,
rootgebundene Encounterabschlüsse, Hex-/Legacy-/Diagnose- und Viewport-Inputfälle.
Enginechecks seriell von Root; keine konkurrierenden Imports oder Profilwrites.
Passende benachbarte Regressionen und abschließender unabhängiger Diffreview.
HTML offline/mobile/JSON-Export prüfen; private Websitezugriffe beibehalten.

## Risiken / offene Punkte
Kompatibilität interner Commands, Replay-/Fueltransaktionen, Saveerhalt und Input-
Reihenfolge benötigen konkrete Tests. Kein komplettes WAN-/GPU-/FPS-/EXEgate.
Branch task/astra-review-fixes-20261113. Neue Probleme im betroffenen Pfad lösen,
statt bekannte neun Befunde nur kosmetisch zu überdecken.

## Abschlussprüfung
Alle neun ursprünglichen Befunde und der zusätzliche C10-Ausfallpfad sind behoben.
1.048 Assertions in 17 freigegebenen Godot-Prüfläufen bestehen. Dazu kommen zwei
saubere private inkrementelle Editorimports. Der vollständige Kampagnenlauf
prüft normalen Einsatz-Continue, tatsächlichen Truppausfall/Debrief/Basis-Rollback,
beschädigte Altdateien und unterbrochene Archivierung; der bestehende 80er Lauf
prüft außerdem die reguläre physische Heimkehr. Menü-/Kameragesten werden mit
echter Godot-Eingabeverarbeitung geprüft, ohne Desktopübernahme.

Ein fehlerhafter Testzugriff, der bestätigte C10-Stackoverflow und ein zu knappes
Zeitlimit sind als verworfene Versuche dokumentiert; sie zählen nicht als grün.
Nachweisindex und Roharchive: `docs/qa/astra_fixes_20261113/`.
Keine neue EXE, kein GPU-/WAN-/menschliches Gesamtspiel-Abnahmeversprechen.
