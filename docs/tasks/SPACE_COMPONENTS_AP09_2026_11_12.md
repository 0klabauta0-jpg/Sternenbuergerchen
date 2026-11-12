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

Nächster begrenzter Schritt: autoritative, katalogversionierte Startausrüstung
im vorhandenen Equipment-Owner führen und ihre Masse und Schubversorgung an
den vorhandenen Flugleser geben. Version-1-Warp-Saves nach erfolgreicher alter
Validierung auf die festen Startslots migrieren. Version 2 muss Modell, Slots
und Katalogversion prüfen; frei veränderte Slots bleiben bis zur eigentlichen
Supply-/Einbautransaktion abgewiesen. Keine Komponentenkäufe freischalten.

## Stand 12.11.

Vorläufiger Katalog für S1–S5, zwei Rümpfe und Schild/Kraftwerk sowie reine
Prüfung, Leistungs- und Massenvorschau ergänzt. Ein separater zustandsloser
Resolver berechnet Treffer zuerst auf Schild, Waffenenergie und verzögerte,
leistungsabhängige Regeneration als Vorschläge. Zum damaligen Stand gab es keine
Installation, persistierte Komponentenbilanz oder Consumer. Werte,
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
Verstärkte vorläufige Kraftwerksvarianten gleicher Slotgröße zeigen im reinen
Resolver mehr Schildladeleistung bei höherer Masse; gezielter Prüfungslauf
Exit 0. Ein tatsächlicher Kraftwerkstausch ist weiterhin nicht implementiert.

## Startausrüstung und Flugleser

Der vorhandene Equipment-Owner führt die festen Startslots bekannter Rümpfe.
Sein v2-Zustand speichert die Katalogversion und diese Slots; bei v1-Restore
werden nach erfolgreicher Warp-/Supplyprüfung die festen Startslots ergänzt.
Abweichende oder manipulierte v2-Slots werden abgewiesen, bis ein quittierter
Einbau- und Bilanzpfad existiert. Der Flugleser liest die resultierende Masse
und das verfügbare Schubbudget; Root überträgt die Masse bei Heimatstart und
Polisa-Abflug zusammen mit der autoritativen Reisepose. Der strenge spätere
Massengleichheitsguard bleibt bestehen. Guidance berücksichtigt den Bremsweg
der tatsächlich schwereren Schiffe. Keine Waffen-/Schildwirkung im Spiel,
kein Einbau/Kauf/Upgrade und keine vollständige AP09-Abnahme.

Gezielt geprüft: Owner-v1-Migration/v2-JSON und Manipulationsschutz, Heimatstart
mit Owner-Masse, Warp-/Heimflugzyklus und Polisa-Landungsowner (beide Letzteren
mit ausdrücklich an echten Start angepasster Fixture), Guidance 5/5,
Warp-/Savevertrag 42/42 und AP02 8/8. Der direkte echte Polisa-Rundflug lief
mit isoliertem Profil 25/25, Exit 0, keine Fehler. Dieser Stand basiert auf
`9fc5dba20` und ist noch nicht mit dem weiterlaufenden Parallelstand getestet.

## Komponenten-Transaktion: Ownerpfad

Der vorhandene Supply-/Equipment-Einbaupfad kann nun auch passende Repeater,
Schilde und Kraftwerke gegen einen real gekauften Gegenstand im Schiffslager
tauschen. Er prüft Slot und Größe, Lage, Bestand und Revision vor Mutation;
das ausgebaute Teil geht in dasselbe Lager. Warp- und Kampfkomponenten teilen
Revisionsfolge und Einbaubelege. Restore spielt die Belege erneut ab und prüft
die Komponentenbilanz über Startausrüstung, Käufe und alle Container; alte
Warp-Saves bleiben akzeptiert. Der produktive Adapter weist Kauf und Einbau
dieser Komponenten ausdrücklich ab, bis sie tatsächlich im Gefecht wirken. Es
gibt deshalb noch keinen nutzbaren Shop-Einbau für diese Bauteile.

Gezielte Ownerprüfung für Kauf, echten Root-/Supply-/Equipment-Tausch,
unzulässigen Service/Slot, Replay, JSON-Restore und manipulierte Ausrüstung
bestand; realer CheckpointStore validiert den ausgerüsteten Zustand. Bestehende
Warp-/Saveprüfung 42/42. Ein Test des Stationspanels mit einem ausdrücklich
freigeschalteten Testadapter bestand; ein solcher Adapter ist kein Produktpfad.
Ein verstärktes Kraftwerk ist noch kein wirksames Upgrade, weil Schild- und
Waffenverbraucher fehlen; deshalb ist dieser Shopweg weiterhin gesperrt. Der
experimentelle Polisa-Rundflug vor Aktivierung dieser Sperre erreichte 27/27;
er ersetzt keine Prüfung des gesperrten Produktpfads und ist kein Nachweis für
fertige Waffen-/Schildwirkung.

Nach Aktivierung der Kauf-/Einbausperre lief der echte Polisa-Rundflug mit
isoliertem Profil erneut 25/25, Exit 0 und ohne Fehler. Der Runner überwacht
nun zusätzlich die beteiligten Equipment-, Supply-, Inventar- und Katalogquellen;
keine der überwachten Quellen änderte sich während dieses Laufs. Atmosphärische
Missionen, Beschuss und ein nutzbares Shopangebot sind damit nicht nachgewiesen.

## Ziel- und Schussvorschau: AP07/AP08-Vorstufe

Zustandslose Resolver prüfen vorbereitete indexierte Kandidaten, Sensorreichweite,
Bereich, Deckung, Feindstatus, Feuerregel, Waffenwinkel und Reichweite. Ein
deterministischer Schussvorschlag berücksichtigt den ersten indexierten Rumpf
einschließlich freundlicher Abfangtreffer und hält die Ereignisgeometrie fest.
Unbekannte Ziele, ungedecktes Antwortfeuer, falscher Winkel und fehlender
Zielindex werden abgewiesen. Diese Funktionen sind noch nicht mit einem
autoritativ gefilterten Kontaktindex, dem Root-Kampftick, Feuerzyklen, Schaden,
Replaybelegen oder der UI verbunden und erzeugen keinen spielbaren Beschuss.
Der kleine Ziel-/Schusscheck und bestehende Komponenten-, Einbau-, Atmosphären-
und Guidanceprüfungen liefen gebündelt ohne Fehler.

## Schildzustand im Kampfowner: begrenzter Anschluss

Der bestehende `SpaceCombatState` kann für einen bereits registrierten Akteur
Komponentenwerte binden, Treffer zuerst auf Schild und anschließend Hülle
verbuchen, den gebundenen Waffenslot mit Reserve und Feuerrate prüfen, dieselbe
Ereignis-ID einmalig behandeln und die Regeneration als gebündelten Tick
anwenden. Er erzeugt keinen eigenen Flug- oder Equipmentowner.
Der interne Trefferpfad darf ausschließlich vertrauenswürdige, durch Root
aufgelöste Ereignisse erhalten. Ein isolierter Ownerlauf verbindet den
Schussvorschlag mit einem freundlichen Abfangziel und prüft Schild, Hülle,
Waffenenergie, Feuerrate, Replay, Konflikt und Regeneration.

Der Root bindet beim Eintritt eigener Schiffe in den lokalen Orbit inzwischen
die Werte des Equipment-Owners und taktet deren Systeme mit dem Raumflug. Die
eigene Bereichsprojektion enthält den Zustand; bestehender Hüllenschaden bleibt
bei einem Orbitwechsel erhalten. Der Root leitet noch keine autoritativen
Feuerbefehle oder Treffer weiter. Kontaktsicht, Waffentakt im Produkt, Tod,
Save-Lifecycle, Multiplayer und UI sind weiterhin offen. Diese Vorstufe ist
kein spielbarer Raum- oder Luftkampf; die Produktsperre bleibt bestehen.

Gebündelte Prüfung auf dem Folgebranch: lokaler Warpzyklus einschließlich
Ownerbindung und Hüllenerhalt, Schild-/Schussowner, Zielresolver,
Bereichsregistry 15/15 und Komponenteneinbau jeweils Exit 0. Der Warpzyklus
verwendet eine Fixture und setzt den Schaden für die Übergangsprüfung gezielt.
Der lokale Orbitweg bleibt im Produktflag ausgeschaltet.
