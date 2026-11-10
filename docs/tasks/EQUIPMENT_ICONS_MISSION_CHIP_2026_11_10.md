# Ausrüstungskorrektur, Menüicons und Satellitendatenträger — 10.11.2026
## Ziel / Problem
Nutzer korrigiert die Ausrüstungssicht: ursprüngliches Porträt neben Namen zurück,
Figur doppelt statt halb so groß, nebeneinander mit ansprechenderen Sloticons;
Fenster dafür breiter. Tankservice nur Schiffsversorgung, keine Werkzeugkäufe.
Menüicons mit Bilder-KI aus vorhandenen Modellreferenzen; Rifle/SMG unterscheiden,
Miningtool gelbe handliche Pistolenform. Smart Mobile trennt Himmelskörper,
Einsatzort und Ziele. Satellitendaten als echtes Item beim Lead statt nur Text.
## Umfang / Nicht-Ziele
Aufbau auf0c7510f79 (Mainbasis1e3cca237), neue Taskbranch, keine Main/EXE.
Bestehende 3D-Kartenmodelle unverändert; neue Icons nur im Menü. Keine erfundenen
Reparatur- oder Rufregeln, keine neuen Einkäufe an Heimatbasis. Vorhandene
Handelsposten-Commands erhalten. Nur belegte Ortsnamen verwenden.
## Quellen / Dateien
Pflichtdokumente wie vorher gelesen; graphics_reference_revision_contract,
homebase_direct_dropship_flow_contract, mission_interaction_point_contract,
InventoryTransfer/Supply/Campaign-Contracts. InventoryPanel/BodyPreview,
OperationsPresenter, JobBoard, Services, SupplyState/RuntimeAdapter und gezielte
Verifier. Kleine unveränderliche Inhaltsmetadaten bei Bedarf.
## Akzeptanz / Prüfung
Porträt neben Name, Figur180x300, Slots ohne Überdeckung; Fenster passt1280/1920.
Werkzeugkäufe/Sell im Tankservice an Basis unsichtbar, Handel weiterhin benutzbar.
Neue lesbare Icons unterscheiden Pistole/Rifle/Medgerät/Miningtool; Grafikquellen,
Prompt und Hashes plus native Bilder erhalten. Mission enthält Himmelskörper,
benannten Einsatzort und verständliche Ziele. Echter Datenträger entsteht genau
nach bestätigtem Sichern beim Lead, bleibt beim Transport/Save erhalten und wird
beim Upload genau einmal verbraucht. Keine doppelten Chips durch Legacy-Rewardpfad.
## Risiken
Questgegenstände bisher erst am Missionsende in Schiffsfracht: vor Änderung
Autoritäts-/Receipt-/Upload-/Savepfad prüfen. Ursprüngliche Spielstände nicht
patchen; Tests isolieren APPDATA. Native Sichtprüfung und echte Mission nötig.
