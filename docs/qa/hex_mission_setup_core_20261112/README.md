# AP6: tatsächlicher initialer Missionssetup

Kleine private Projekte: tatsächlicher Setup62/0 einschließlich42 Movefälle,
unmittelbarer Root-Ownernachbar56/0. Quellen-/Isolations-/Originalprofilguards
grün. Exakte Quellhashes und alle Originalversuche im Manifest/ZIP.

Der vollständige `MissionTestSetup._finish_ready_after_scenario_loaded` arbeitet
mit echten Root-/Registry-/Mapkörpern. Die Fixture liefert bekanntes Terrain,
Roster und UIgrenzen; keine Hauptszene oder Produktionskarte. Initiale direkte
Actors erhalten gemeinsam getrennte Hexfelder, unterschiedliche gewünschte
Anker bleiben erhalten. Deferpersonen sind Lookup-bekannt, aber ohne Registry-
oder Groundpräsenz. Eine wartende Gruppe bleibt vollständig und verborgen;
Root-/Terrainrevision statt unveränderter Neuplanung. Retirement und Kontextwechsel
können keine alte Absicht wiederverwenden. Gruppe maximal64 Expansionen.

Unabhängiger Review fand drei tatsächliche Grenzen. Sauberes RED57/5→GREEN62/0:

- Legacyclient ohne Authority darf weiter seine bisherigen Lookups/Foginitialisierung
  anlegen; nur deklarierte Hexclients warten verborgen auf die Hostprojektion.
- Ersatzroot mit gleichen numerischen Kontext-/Actorwerten darf keinen alten
  Platzierungsauftrag übernehmen; zusätzliche konkrete Rootinstanzbindung.
- Nullgröße und explizite leere Hexkarte werden vor Registrymutation bzw.
  Hardcodefallback geprüft. Ein reiner gemeinsamer Root-Metadatenvalidator
  dient Configure und Loader, statt voneinander abweichender Plausibilisierung.

Readonly-Authority ist eine bekannte überschreibbare Inputgrenze der kleinen
Fixture, kein echter Peer-/Receivernachweis. Die Warnung zur absichtlich unbekannten
Testkennung ist erwartet; kein Script-/Enginefehler. Keine FPS-/Grafikabnahme.

Dieser Schritt ist der initiale Setupkern. Laufende Slot-/Identitätsänderung,
spätere Wellenaktivierung, Respawn, Member-Retirement sowie AP7/8 sind weitere
Pakete. Produktionskarten erhalten keine Kennung, keine Main-/EXEfreigabe.
