# N4 · Dossier-Abnahme

13.09.2026, Godot 4.6.2, Branch `codex/rostgrenze-crew-reise-ausruestung`.

`tests/crew_dossier_window_test.gd` wird ohne `--headless` ausgeführt. Ein natives Dossierfenster erhält echte MouseButton-/MouseMotion-Ereignisse, inklusive tatsächlicher Drag-Schwelle und Ablage. Kein UI-Testcontroller ist Teil des Produkts. Headless prüft nur die drei API-Voraussetzungen und kennzeichnet die ausgelassene Fensterprüfung ausdrücklich.

**22/22 Fensterprüfungen bestanden.** Der vorherige fehlende-Dossier-Test war rot. Nach Implementierung: Öffnen/Schließen, private 3D-Ansicht des vorhandenen weißen Astronauten, einmaliges transfer-Signal, falscher Slot, keine Snapshotmutation und Rückmeldung. Ein ausstehendes Gast-RPC wird ausdrücklich als wartend angezeigt, niemals als bestätigter Erfolg. Anschließend entsteht ein Rucksack durch echte Werkbankarbeit und Materialverbrauch. Ida läuft an den Lagerzugang. Maus-Drops rüsten den Rucksack aus, übertragen zwei Metall, versuchen erfolglos den gefüllten Rucksack abzulegen, lagern den Inhalt zurück, legen den leeren Rucksack ab und rüsten ihn erneut aus. Autoritative Menge und Kapazität bleiben in jeder Phase erhalten.

Bild: `output/n4-crew-dossier.png`, tatsächlicher Viewport, abschließend acht nutzbare Plätze und bestätigte Ausrüstung. Bild wurde angesehen; Slots, Bestände, Menge und Rückmeldung sind vollständig sichtbar.

Produkt-API: `present(state, unit_id)`, `open_for(unit_id)`, `close()`, `present_result(result)`; ausschließlich `action_requested(action,payload)` für Befehle. Fünf Slots folgen `equipment_catalog.gd`; Medgun ist ein Werkzeug. Ausrüstung und Rucksack lesen nur bestätigte Snapshots. Rüstung/Rucksack/Werkzeug besitzen einfache separate Anzeigeteile an der vorhandenen Figur; keine neuen Charaktermodelle wurden erzeugt.

Befehle: `equip_item`, `unequip_item`, `backpack_transfer`, `use_medgun`, sowie bestätigter `transfer`-Dockweg für Lager↔Fracht. Nähe, Kapazität, Besitz der Ware und Transaktionsintegrität entscheidet der Kern. Aufsätze benötigen das Multi-Tool; das Fenster erklärt nicht passende Drops. Für vollständige Host-Ablehnungen leitet GameHud/Root `command_result` an `present_result`.

Kein Nutzer-Save gelesen oder geschrieben. Die Testsimulation entsteht frisch mit regulären Startwerten; Zeit wird ausschließlich über `advance` beschleunigt.


Die gleiche native22er-Probe wurde abschließend aus dem unveränderten exportierten N4-PCK bestanden. Für stabile künstliche Mauseingaben wartet die Probe auf Warp-/Fensterereignisse und hält ihr eigenes Fenster vorne; Produktfensterflags und Kernzustände werden dadurch nicht geändert. Beleg: output/windows-n4-delivery/dossier-final.log.
