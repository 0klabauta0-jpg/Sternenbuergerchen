# Warp-Antrieb: erster funktionaler Cutlass-Slot

Teilagent liefert Produktdelta im gemeinsamen task/native-glut-maps-20261110.
Rootglue/Neukampagnenmodell und Warp-Terminologie kamen getrennt vom Rootagent.
Kein Teilagent-Commit/Push. Keine native/GPU-/Mission-/große Matrix-Abnahme.

## Verhalten
Explizite model_id cutlass: Odyssey C als Default. Hemera A kostet vorläufig
160Cr, Bestand4. Kauf ins echte Schiffslager; separater Einbau tauscht Teile
1:1, Odyssey kommt ins selbe Lager zurück. D/B bleiben Qualitätsklassen ohne
Produkte. Unsourced Legacy bleibt baseline1 und hat keinen installierbaren Slot.
Der vorhandene Reiseconsumer friert3s*238314/326114 beim Sprungstart mit Hemera
ein; Odyssey bewahrt3s. Das ist eine vereinfachte Spielregel, keine SC-Physik.

## Frisch begrenzt geprüft
- scripts/tests/warp_drive_slice_check.gd:42/0, Exit0; echte Root+Supply+Equipment+
  zwei FleetTravelowners. Keine Scene/Actors oder Benutzer-Savezugriffe.
- Kaufstock/160Cr, Missingcraftcontainer, legacy inkompatibel, fehlendes Material,
  echtes Servicecontext-/Busy-/Slots-/Revisiongate, Root-Publikation beider Owner,
  Replay/Konflikt, Rückbau zu Odyssey, voller Cargo als1:1-Nettotausch.
- Echte Reise unterschiedliche Dauer je Craft, Payloadignorierung, eingefrorener
  laufender Sprung trotz späterem Ownerrefit, nächster Sprung neu, Replay/NaN.
  Der absichtlich direkt vertrauenswürdige Domainrefit im Flug dient nur dem
  Freeze-Nachweis; Produktadapter sperrt ihn über reale Servicegates.
- Echter JSON-Roundtrip Supply+Equipment, chronologische Belege, manipulierte
  Catalog-/Craft-/Slotitem-/Receipt-/Effekt-/Historydaten, duplizierte Komponenten,
  fehlende Equipmentsektion nach Installation und Modellmismatch abgewiesen.
- Echter CampaignCheckpointStore.validate_payload: alter Heimatstand ohne neues
  Angebot/Equipment weiterhin gültig; neuer ausgerüsteter JSON-Heimatstand gültig.
- Neun Sourcefiles --headless --check-only Exit0; keine Scriptfehler/Leakwarnungen.
- roundtrip_red.log bewahrt ursprünglichen41/2-Fehler: Godot JSON float parsing.
  Korrektur kanonisiert NUR bereits integer-validierte Receiptrevisionen; übrige
  Felder bleiben exakt. Finale domain.log enthält42/0.

## Grenzen
Native Polisa-Bedienung, realer Rundflug und spätere große Save-/Kampf-/Performance-
Abnahme bleiben offen. Checkpoint weiterhin ausschließlich Heimat. Preise/Bestand
vorläufig. Keine Waffen/Fuel/Schilde, keine Fahrzeugmodelle, keine Rollenheuristik.
Root führt abschließenden unabhängigen Deltareview und Integration separat aus.


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

Kleine Reviewregression: scripts/tests/warp_skirmish_return_check.gd14/0 mit echtem
Adapter->Root->Economy->Adapter-Callback und Supply/Equipment/Travel. Nur anfängliche
Craftplatzierung/Base-/Flowsetup sind Stubs. Hemeraeinbau+Odysseyausladen bewies
vor Korrektur tatsächlich6/2 (skirmish_return_red.log). Finale Probe belegt Sperre
vor Refund/Remove, unveränderte Owner nach Reject, Rückbau bleibt historisch,
unmodifiziertes zweites Schiff wird samt Owner entfernt, Refund genau einmal.
Hauptfixture42/0 frisch wiederholt; zwei geänderte Sources erneut compile0.
