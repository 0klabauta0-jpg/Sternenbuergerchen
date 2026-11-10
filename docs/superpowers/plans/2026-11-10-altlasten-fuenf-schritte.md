# Altlasten in fuenf Schritten — Implementation Plan

**Goal:** Die fuenf bestaetigten Reviewpunkte ohne Funktionsverlust bearbeiten.
**Architecture:** Bestehende Runtimeowner, Registry und Contracts wiederverwenden.
Kompatibilitaetsmethoden bleiben erhalten, duplizierte Wahrheit entfaellt.
**Tech Stack:** Godot 4.6.2, GDScript, PowerShell/Python fuer isolierte Verifikation.
**Spec:** docs/tasks/ALTLASTEN_FUENF_SCHRITTE_2026_11_10.md

## Global Constraints
Reihenfolge LOS -> Loadout -> tote Controls -> Diagnostik -> Portraetexport.
Einzelschritte separat verifizieren und committen. Bestehende Saveformate,
sichtbare funktionierende Bedienung und fremde WIP erhalten. Autorisierung
zur Ausfuehrung liegt vor; kein erneuter Planfreigabehalt.

## Review Focus
- Tuerzustand nach Cachehit, Registryersatz und Kartenwechsel.
- Pilot ohne Fireteam, restauriertes Loadout und mehrfacher Inventarrequest.
- Funktionierende GO-/Auswahlsteuerung nach Phasenbindingbereinigung.
- Vollstaendige Diagnostikparitaet inklusive geerbter Probe-Overrides.
- Bekannte Aliasdatei im Export abwesend, unbekannter Sonderpfad weiter ladbar.

## Task 1: Gemeinsamer LOS-Lesepfad
- [x] Regression fuer Anzeige geschlossen/offen/geschlossen, Revision und Ersatz.
- [x] Runtime-Blockersuche in LOSSystem gemeinsam verwenden; Registry explizit
      in PrimaryView binden; Map-only-Authoring ohne langlebigen Cache.
- [x] Square-/Hex-/Wand-/Endpointchecks und bestehende LOS-/Tuergates ausfuehren.
- [x] Befehle/Ergebnisse dokumentieren und Schritt committen.

## Task 2: Loadoutowner
- [x] Bestehende Defaults/Inventar/Continue als Baseline; UI-Snapshotmutation und
      transaktionalen Ownercommit mit einer Regression absichern.
- [x] Ein core/personnel_loadout_state.gd am SimulationRoot; UI-Kompatibilitaet
      delegiert. Supply und Loadout vor Erfolgssignal gemeinsam bestaetigen.
- [x] Checkpointformat und FOB-/Standalone-Adapter erhalten; Defaults,
      Empfehlung, Inventar-Replay und Continue pruefen.
- [x] Dokumentieren und committen.

## Task 3: Unerreichbare Controls
- [x] R/F-Deskriptoren/InputMap und unerreichbare Handler entfernen; TASK1185
      auf aktuelle erreichbare Aktionen ausrichten.
- [x] Unerreichbaren OperationsReturnButton entfernen; alte Detailcontrols erhalten.
- [x] Eingabe-/Homebasegates pruefen und committen.

## Task 4: Diagnostikgrenze
- [x] Vollstaendigen Feedbacksnapshot mit eingefrorenen Quellen vor Aenderung
      charakterisieren; Ownerstate und schmale Live-Projektion absichern.
- [x] Stateless mission/diagnostics-Helper, bestehender Controllergetter als
      kompatible Delegation; Aufrufreihenfolge und alle Varianttypen erhalten.
- [x] Paritaet/Probe-Overrides/HUD-/Snapshotgates pruefen und committen.

## Task 5: Portraetexport
- [x] Fehlende bekannte Aliasdatei und vorhandenen unbekannten Pfad als Regression.
- [x] Alias-only-Normalisierung vor direkten Load/exists-Verbrauchern; keine
      gespeicherten Pfade umschreiben. Exakt42 sichere Filter ohne Kommatrennung.
- [x] Filtermenge, reale Ressourcenaufloesung und vorhandene Portraet-/Savegates
      pruefen; Quelldateien erhalten; dokumentieren und committen.

## Abschluss
- [ ] Gezielte gemeinsame Regressionen, git diff --check, unabhaengiges Review.
- [ ] Statusbericht mit verbleibenden Grenzen und Commit-/Pushstatus.
