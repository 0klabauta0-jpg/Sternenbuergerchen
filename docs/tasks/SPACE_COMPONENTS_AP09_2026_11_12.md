# AP09: Schiffskomponenten schrittweise anbinden

## Ziel und Ursache

Waffen, Schildgeneratoren und Kraftwerke sollen austauschbar sein und auf
Flug und Kampf wirken. Bisher besitzt der Equipment-Owner nur den Warp-Slot;
ein zweiter Loadout-Owner oder bloß kosmetisch verkaufte Komponenten wären
unvereinbar mit dem bestehenden Kauf-, Quittungs- und Savevertrag.

## Umfang und Nichtziele

AP09 aus dem Weltraumkampfplan in kleinen, separat integrierbaren Schritten
vorbereiten. Der Parallelchat besitzt AP6–8, Root-/Netz-/Checkpointänderungen
und deren Integration; diese Dateien nicht überschreiben. Polisa bleibt nach
Nutzerfestlegung direkt anfliegbar. Keine Produktfreigabe, kein neuer Verkauf,
keine Änderung existierender Warp-Saves ohne versionierte Migration.

## Verträge und Akzeptanz

`docs/dev/space_combat_contract.md`, `docs/dev/polisa_ship_equipment_contract.md`
und AP09 in `docs/superpowers/plans/2026-11-11-space-combat.md` gelten. Erste
Voraussetzung: klar versionierte, vorläufige Spielbalance für S1–S5-Repeater,
Rumpfslots, Schild und Kraftwerk sowie deterministische, mutationsfreie
Prüfung und Werteberechnung. Der vorhandene Equipment-Owner bleibt einziger
Besitzer installierter Komponenten. Unbekannte IDs, falsche Größe/Klasse und
ungültige Werte müssen geschlossen abgewiesen werden. Keine SC-Balancewerte
als authentisch ausgeben; alle Werte sind interne Startannahmen.

## Dateien und lokale Prüfung

Neue getrennte Komponentendaten und reiner Resolver; bestehender Warp-Owner
und bestehende Daten bleiben zunächst kompatibel. Gezielte Prüfung der
Slotgrößen, Datenvalidierung, Masse und Leistungspriorität in einem Bündel;
Integration der tatsächlichen Owner, Schaden und Restore erst nach abgestimmter
AP8-Basis. Änderungsstand und Ergebnisse hier fortschreiben.

## Risiken / offene Punkte

Ein geprüfter Katalog allein ist noch keine installierbare Komponente und kein
funktionsfähiges Kampfsystem. Die Balance muss im Spiel erprobt werden.

## Stand 12.11.

Vorläufiger Katalog für S1–S5, zwei Rümpfe und Schild/Kraftwerk sowie reine
Prüfung, Leistungs- und Massenvorschau ergänzt. Ein separater zustandsloser
Resolver berechnet Treffer zuerst auf Schild, Waffenenergie und verzögerte,
leistungsabhängige Regeneration als Vorschläge. Keine Installation, keine
persistierte Komponentenbilanz und kein Consumer: AP09 bleibt offen. Werte,
Slots und Reserve sind vorläufige Spielannahmen, keine SC-Leistungsdaten.
Gezielte gebündelte Prüfung: Komponentenresolver Exit 0, bestehender
Warp-/Savevertrag 42/42. Anpassung der Schubwerte, Root-Tick, AP8-Schaden,
Versionierung und UI-/Supply-Anbindung fehlen weiterhin. Eine reine Vorschau
für den bestehenden Flugresolver zeigt, dass dieselbe Schubabsicht mit mehr
Komponentenmasse schwächer beschleunigt; der produktive Root liefert diese
Werte bislang nicht. Gezielt mit dem echten Flugresolver geprüft, Exit 0.
Der bestehende Equipment-Owner bietet eine revisionsgebundene Kandidatenvorschau
für sein tatsächliches Schiff/Modell. Diese installiert nichts, nimmt keine
Inventaränderung vor und verändert Schema oder Quittungen nicht. Kandidat,
veraltete Revision und unbekanntes Schiff gezielt geprüft; vorhandene
Warp-/Checkpointprüfung erneut 42/42. Produktiver Einbau bleibt offen.
