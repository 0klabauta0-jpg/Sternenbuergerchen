# Warp-Antrieb / enger Slotvertrag

Erkul-Quantumdrive ist nur Quelldatenbezeichnung. UI: Warp-Antrieb; Qualitätsfolge
D (schlecht), C, B, A (gut). Nur explizit kanonische model_id cutlass besitzt den
quantum_drive-Slot, initial eingebaut Odyssey C. Kein externes Loadout wird für
generische Legacy-Schiffe erfunden. Diese bleiben Baseline1 ohne Slot.

Hemera A: vorläufig160Cr/Bestand4 in Polisa. Kauf ist reale Schiffsfracht; Einbau
separat nur bei realem Polisa-Service für dasselbe Schiff. Neue Komponente wird
verbraucht, alte in dasselbe Lager zurückgegeben. Voller Laderaum darf einen
1-zu-1-Wechsel; alle Prüfungen/Nettoinventar vor erstem Write. Supply ruft nur
SimulationRoot-gebundene Prepare/Commit-Ownercallables synchron ohne Signal/await
auf. Abgewiesener/staler Commit mutiert nichts; nach erfolgreichem Ownerswap
folgen ausschließlich vorvalidierte Supplyzuweisungen. Rootsignal erst danach.

Die vereinfachte Spielregel multipliziert konfigurierte Reisedauer mit1.0
(Odyssey) beziehungsweise238314/326114 (Hemera). Keine Spool-/Fuel-/Physikannahme.
Beim Start einfrieren; Tick und Snapshot lesen genau diese Dauer. UI-Payloads
sind keine Effektquelle. Bestehende quantum_* APIs bleiben kompatibel.

Equipment-Unterformat schema1/catalog1: exakte Fleetidentitäten/Slots plus
chronologische Installationsbelege. Abwesend ist ausschließlich Legacydefault;
vorhanden aber ungültig wird verworfen. Crosscheck mit Supplybelegen und
Komponentenbilanz verhindert freie/duplizierte Teile. Äußerer Checkpoint1 bleibt
heimatgebunden; Restore prüft Kandidaten vor jeder Veröffentlichung.

Verbindliche Nutzerterminologie: docs/dev/warp_drive_quality_contract.md.


## Reviewkorrektur: Schiffsrückgabe / Retirement
Skirmish-Rückgabe prüft den Equipmentowner VOR vorhandenen Mutationen/Refund.
Ein Schiff mit irgendeiner eigenen Installationshistorie wird derzeit ausdrücklich
abgewiesen: „Nach einem Antriebsumbau ist die Schiffsrückgabe derzeit nicht verfügbar“.
Auch Rückbau zum Odyssey löscht keine Geschichte und umgeht diesen Gate nicht.
Das ist der enge vorläufige Return/Retire-Lifecycle, keine behauptete Archivierung.
Unmodifizierte Schiffe ohne eigene Installationsbelege bleiben rückgebbar;
validate_craft_return/unregister_unmodified_craft entfernen sie wirklich aus dem
Owner, ohne die globale Installrevision oder fremde Belege zu ändern. Vollständige
belegkonsistente Archivierung/Retirement umgebauter Schiffe bleibt eigener Restpunkt.
