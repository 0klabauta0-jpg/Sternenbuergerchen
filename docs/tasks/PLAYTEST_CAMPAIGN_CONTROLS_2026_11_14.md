# Playtest Kampagne und Bedienung — 14.11.2026

> **Historische Teilerfassung.** Der aktuelle Auftrag ist ausschließlich Planung.
> Die vollständige Liste mit allen 23 Punkten steht in
> [PLAYTEST_REWORK_2026_11_14.md](PLAYTEST_REWORK_2026_11_14.md), die Reihenfolge im
> [Arbeitsplan](../superpowers/plans/2026-11-14-playtest-rework.md).
> Frühere Quellkandidaten werden nicht fortgesetzt oder als erledigt übernommen.

## Ziel / Problem und Ursache
Nutzer meldet in Mission 1 einen geborgenen Datenträger bei Anja ohne auffindbaren Upload, einen Start des Anflugs innerhalb der Karte, stockendes Aussteigen am Heck und fehlende direkte Rechtsklickbefehle. Auftragsannahme und Schließen reagieren nicht auf die gesamte Schaltfläche. Flugdeck ist zu eng statt eine passende Ansicht derselben Basis.
Ursachen werden gegen den aktuellen Code geprüft, nicht aus Symptomen angenommen.

## Umfang und Nicht-Ziele
Datenträgerabgabe, Boden-/Orbitübergänge, Boarding/Exit, Button-Hitflächen, Flugdeckprojektion und Truppbedienung. Keine neuen Assets, Balanceänderungen, allgemeinen Refactors oder EXE.

## Akzeptanzkriterien
- Mission-1-Datenträger kann nach tatsächlicher Heimkehr am sichtbaren Basisterminal abgegeben werden, auch aus dem tatsächlichen Personeninventar; keine doppelte Belohnung.
- Anflug beginnt außerhalb der tatsächlichen Kartenbegrenzung und folgt dem gewählten Winkel.
- Abflug führt sichtbar über den Kartenrand hinaus, entlang wählbarer Richtung oder umgekehrtem Anflug, bevor die OM-/Orbitkarte übernimmt.
- Vom Nutzer bestätigt: umschaltbare Automatik setzt bei freier Route fort; ausgeschaltet wartet das Schiff auf der OM-Karte auf den nächsten Befehl.
- Personen verlassen den Heckeinstieg ohne Blockade und nehmen nach dem Aussteigen direkt Rechtsklickbefehle an.
- Auftrag annehmen und X reagieren über ihre gesamte sichtbare Fläche.
- Flugdeck zeigt dieselbe Basis mit denselben tatsächlichen Personen-/Padpositionen; Boarding bleibt bis zum Heckeinstieg sichtbar, Darstellung passt zum Fensterrahmen.
- In Truppen/Ausrüstung entfernt Herausziehen ins Personal einen NPC aus dem Fireteam. Doppelklick öffnet Charakterdetails. Die beiden redundanten Buttons entfallen.

## Relevante Dokumente / Contracts
AGENTS.md; PROJECT_BRIEF; ARCHITECTURE; CODEX_RULES; IMPLEMENTATION_STATUS;
dev/campaign_introduction_contract.md; dev/orbit_quantum_travel_contract.md.
Weitere relevante Contracts werden bei der Ursachenprüfung ergänzt.

## Betroffene Dateien
Nach Ursachenprüfung ergänzen; UI bleibt Leseschicht, Runtime-Commands bleiben autoritativ.

## Lokale Prüfung
Gezielte Godot-Regressionen zu Inventar/Upload, tatsächlichen Fluggrenzen, Boarding, UI-Hitflächen und Truppdrag. Native visuelle Abnahme getrennt ausweisen.

## Risiken / offene Punkte
Branch task/playtest-campaign-controls-20261114 baut bewusst auf noch nicht integriertem task/hex-review-report-20261113 auf. Vorhandene fremde Änderungen bleiben erhalten. Kein Mainmerge und kein Export. Noch keine Ursachen- oder Abschlussbehauptung.
