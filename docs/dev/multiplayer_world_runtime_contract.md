# Gemeinsame Multiplayer-Orte

`MultiplayerSession` besitzt Verbindung, Teamzuweisung, Authentifizierung und den
primären Missionskontext. `MultiplayerWorldRuntime` besitzt ausschließlich den
Ortslebenszyklus und den Index zu bestehenden lokalen SimulationRoots. Ein Ort
hat einen einmalig vergebenen Runtime-Token und ein geprüftes Kartenmanifest;
sein SimulationRoot bleibt der einzige Gameplay-Owner. Der Ortsindex enthält
weder Unitkopien noch Kampagnen-/Transportzustand.

- `start_world(assignments, primary_path)` bindet die bestehende Sessionepoche.
- `open_location(map_path, allowed_teams)` ist ausschließlich hostseitig. Nur
  vorhandene Produktkarten mit gültigem Manifest dürfen zusätzlich starten.
- `select_location(location_id)` ändert ausschließlich die lokale Ansicht und
  Eingabe. Andere Ansichten und alle laufenden Simulationen bleiben unabhängig.
- `MultiplayerLocationPresentation` nutzt wie MetaLayerFlow den vorhandenen
  `set_tactical_ui_visible`-Owner und suspendiert nur TerrainView/Kamera sowie
  Viewport-Updates/GUI-Eingabe. Eigene CanvasLayer-Sichtzustände werden erhalten;
  später angelegte Layer folgen per Child-Ereignis, nicht per Frame-Scan.
  Der Terrainmodus bleibt `unexplored_blackout`, auch nach Ansichtswechsel.
- `get_location_rows()` und `get_location_instance(id)` sind schmale Projektionen.
- Clientkatalog und READY verwenden Sessionepoche, Orts-ID und vollständigen
  Kontext. Nur aktuell authentifizierte Peers dürfen READY senden. Die Freigabe
  betrifft exakt diesen Root; eine alte primäre Session-READY entsperrt keine
  anderen Orte. Nicht berechtigte Teams erhalten keinen Ort und keine dortige
  Commandrolle oder Snapshotfreigabe.
- Zusätzliche Karten müssen bereits lokal zum Manifest passen. Fehlende Karten
  bleiben gesperrt; das bestehende ausdrückliche Downloadconsent wird nicht umgangen.
- Ergebnis/Abschluss betrifft zunächst einen Ort. Erst ohne offene Orte endet
  die Sessionmission. Rejoin publiziert den bestehenden Index erneut, ohne neue
  Hosteinheiten, Tokens oder Primärmission zu erzeugen.
- Die sichtbare Lobby-Ortsleiste nutzt diese APIs. Lokale Auswahl, Kamera und
  Canvas-/Eingabesicht sind Präsentation; kein Ansichtswechsel ist ein Transport.
- Wiederholte Zuweisungen sowie fremder Disconnect/Rejoin verändern bei gleichen
  eigenen Fireteamrechten weder Auswahl noch Kamera. Geänderte Rechte filtern nur
  die vorhandene lokale Auswahl; neue Rechte wählen keine zusätzlichen Trupps aus
  und lösen keine Kamerafokussierung aus.
- Nach dem vier Frames langen RPC-Drain werden ausschließlich Registrierung und
  Präsentationsdaten der beendeten Instanz freigegeben. Ein inzwischen anderer
  Eintrag unter derselben Orts-ID sowie verbleibende aktive Orte bleiben erhalten.

Regression: echte localhost-ENet-Session mit produktivem Coordinator, getrennten
Karten/UnitRegistries, gültigen und fremden Runtime-Tokens, gemeinsamen Fireteams,
ortsspezifischem READY, lokalem Ansichtswechsel und unabhängigem Ortsabschluss.
Keine globale Kartenregistrierung, kein SceneTree-Scan pro Frame; Präsentations-
Knoten werden nur bei Erstellung bzw. lokalem Ortswechsel erfasst.

### Host-Terrainwissen bei mehreren Karten
Jede tatsächliche MissionSetup hält ihren bestehenden FogOfWarSystem als einzigen Sicht-/Erkundungsowner. Auf dem Host werden die vorhandenen Teams getrennt durch dieselben begrenzten Sichtjobs versorgt. Schema-2-Publikationen tragen ausschließlich das Terrainwissen des adressierten Teams und bleiben an den vorhandenen Runtimekontext gebunden. Clients berechnen keine eigene Aufklärung: bis zur ersten gültigen Hostpublikation bleibt ihre Geländeansicht schwarz; spätere Kartenwechsel erhalten genau den letzten akzeptierten ortsgebundenen Stand. Falsche Team-/Runtimeidentität, veralteter Tick oder ungültige Terrainfelder dürfen keine Sicht verändern. Actorfilter bleiben unverändert.

Die Transportprojektion wird bei tatsächlicher Fogrevision/Modusänderung gecacht. Root liest je Tick nur den Revisionsschlüssel; vollständige Tile-ID-Listen werden bei Änderung beziehungsweise höchstens einmal pro Sekunde als Reparatur einer verlorenen unzuverlässigen Publikation beigefügt. Keine Map-, Prop- oder Geländedefinitionen werden repliziert. Ein zusätzlicher Teamjob erhält höchstens eine begrenzte Arbeitsscheibe pro Frame, unabhängig von der Anzahl gleichseitiger Peers.

Inkrementelle Owner-Deltas bis4096 geänderte Tile-IDs werden kompakt mitgeführt und nur für die vorhandene Renderer-Delta-API materialisiert. Vollscans/größere Änderungen transportieren keine Dictionaryliste je Zelle. Fehlende oder übersprungene Revisionen verwenden weiterhin den kompletten autoritativen Wissensstand.
