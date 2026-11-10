# Gemeinsame Charakter-/Ausrüstungsansicht — 10.11.2026
## Ziel / Ursache
Nutzer möchte freie Flächen nutzen: Porträt/Name/Rollen, große Figur, seitliche
Ausrüstungsfelder mit dünnen Zuordnungslinien und Rucksack in einer kompakten
Ansicht. Dasselbe Aussehen/Funktion in Truppausrüstung und Charakterbogen.
Automatisch-ruhen-Schalter direkt links am Text. Blueprints mit echten Werten;
Smart-Mobile-Aufträge aufklappbar und für weitere Aufträge vorbereitet.
## Umfang / Nicht-Ziele
Aufbau aufe004843e7, Mainbasis1e3cca237. Vorhandenes PersonnelInventoryPanel als
gemeinsame UI-Projektion erweitern; vorhandene Commands/Inventare/Actorvisuals
und neue geprüfte Menüicons weiterverwenden. Keine neue Rollen-/Loadoutwahrheit,
keine Balanceänderung und keine Modellrevision. Kein Main/EXE-Schritt.
## Quellen / Dateien
Pflichtdokumente/Contracts wie bisher; homebase_direct_dropship_flow_contract,
graphics_reference_revision_contract, bestehende Badge-/Profil-/Waffen-/Rüstungs-
und Craftingowner. InventoryPanel, CharacterSheetView, Homebase/Operations,
Missionoverlay, Services/JobBoard und gezielte Verifier.
TutorialPresenter/ContextCursor unterdrücken eigene Meldungen während des
geöffneten Einsatz-Charakterbogens; nach dem Schließen kehren sie zurück.
## Akzeptanz
Gemeinsame Ansicht: echtes Porträt am Namen, größere Figur, Slots daneben ohne
Überdeckung; feine Linien zu Torso/primärer/sekundärer Position, sichtbare echte
Eignungsbadges und Status. Hauptrolle/Nebenrolle aus vorhandenen Profilquellen,
keine erfundenen Zuweisungen. Rucksack zeigt vorhandene Items inkl. Datenchip.
Herkunftsübersicht entfällt; genaue Herleitung bleibt einklappbar. Ruhe-Toggle
kompakt links am Text. Blueprintdaten aus tatsächlichen Definitionen; Accordion-
ähnliche Auftragsdetails auf Klick, unveränderte Annahme-/Kartencommands.
1280/1920/3440 prüfen, bestehende Inventar-/Chipbefehle und Speicherpfade erhalten.
## Risiken / Prüfung
Keine Ressourcen/HP/Positionen/Receipts zum Bestehen verändern. Vergleichbare
native Bilder plus zielgerichtete Profil-/Inventory-/Campaignprüfungen; technische
Prüfung von Nutzerurteil trennen. UI bei unveränderten Snapshots nicht neu bauen.

## Ergebnis
Umgesetzt. Native UI107/0, Charakter35/0, tatsächlicher Kampagnenausflug102/0;
Headless Layout111/0, Compact25/0, Menüicons/Briefing19/0. Ein beobachteter
zeichenweiser Umbruch der Ruhezeile wurde korrigiert und mit einem Rechtecktest
abgesichert. QA mit nativen Bildern/Logs und Grenzen:
docs/qa/shared_personnel_equipment_20261110/README.md.
Main/EXE bleibt separater Integrationsschritt; keine ästhetische Nutzerabnahme.
