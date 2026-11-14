# Kartenoberflaechen und lokale Bodendienste · 14.11.2026

Der neue Produktstand ist getrennt vom ausgelieferten Windows-Build a377c7346.
Das alte Paket wurde nicht veraendert. Branch/Commitintegration und ein eventueller
R2-Export erfolgen durch den Root nach diesem Freeze.

## Ergebnis

Final:81/0gezielte Kernassertions,25/0native Aufnahmeassertions und drei
passende Bestandschecks gruen. Keine Enginefehler/Leaks in den gueltigen Laeufen.

- GM02: olivbrauner Boden, dunkle Schieferwege, warmer matter Zielboden und
  gruene/braune Naturmodelle in ihren tatsaechlichen Batch-/Individualrouten.
- Station64 und alle neun Station192-Ensembles: vier geschlossene Aussenecken,
  geschlossenes Kreuz, vier Raeume und vier passierbare einzelne Tueren. Die
  vorhandenen zweizelligen Missions-Breachpaare bleiben erhalten. Seitenflaechen
  sind blockerfreie Lager-/Reserveaprons; daraus folgt kein Tankservice.
- GM01:83 gespeicherte, vollstaendig von echten flachen Kappen getragene Hexzellen;
  genau eine neue breite Mesa bei Plane(41,42). Vorhandene Silhouetten behalten
  ihre Form, Kappenhoehen sind auf den bestehenden0,5m-Terrainmassstab quantisiert.
  Hoehenowner/Editor unterstuetzen16Stufen. Lebende exakte Meshowner unterdruecken
  nur doppelte Fuellung; Freigabe/Hoehenedit erzeugt wieder eine echte Hexkappe.
- Die vier braunen Legacy-Square-Rampen sind echte gespeicherte Hexrampen.
  Workyard hat erstmals26erhoehte Tiles, der Handelsort eine eigene61-Zellen-
  Huegelgruppe. Die Varianten sind ueber die vorhandenen Karten-/Editorwege
  zugaenglich; es gibt keine neuen versteckten Kartenkopien.
- Handelsservicekern: drei Gebaeude, zwei Pads und ein fester Frachtaufzug. Kauf
  liefert in den endlichen persistenten Liftcontainer; bestehender zeitlicher
  Frachttransfer arbeitet in beide Richtungen; Verkauf liest echten Liftbestand.
- Feldlandung bleibt unabhaengig vom Service. Vor Annahme/Touchdown wird die
  vollstaendige importierte Schiffsprojektion auf ebene, freie, vorhandene
  Terrainzellen geprueft. Gemischte Hoehe, Randblocker und Belegung lehnen ab.
- Tanken/Reparieren verlangen das eigene geparkte Schiff und einen explizit
  zugelassenen lokalen Dienst. Repair geht Adapter→Root→Supply→SpaceCombatState,
  repariert den echten lebenden Rumpf, ohne Schild/Pose/Fuel/Fracht neu zu setzen.
  Reparatur hat hier keinen neuen Preis; zerstoerte Rumpfsysteme werden dadurch
  nicht wiederbelebt. Der getrennte Meta-Recoveryclock arbeitet am lokalen Pad
  in surface/grounded weiter und teleportiert das Schiff nicht zur Heimatbasis.
- Satelliten-NPC-Handel bleibt nach Kontakt fuer ein lokal geparktes eigenes
  Schiff verfuegbar. Mangels Tank-/Reparaturpad entsteht dort kein solcher Dienst.

## Nachweise und Grenzen

`summary.json` enthaelt die finalen Zaehler, Originalreportpfade und SHA-256.
`source_manifest.json` enthaelt ausschliesslich eigene Quellen, nicht den parallel
vom Root bearbeiteten HTML-Bericht. Alle darin enthaltenen Dateien wurden streng
als UTF8 gelesen; die urspruenglichen kompakten Karten-Tilerecords und Keyorder
bleiben erhalten.

Der Kernverifier verwendet reale Adapter-, Root-, Supply-, Cargo-, ShipSystems-
und MetaLayerFlow-Funktionen. Seine kleinen Testdoubles liefern geparkte Pose,
Besuch und abgeschlossenen NPC-Kontakt als ausdrueckliche Fixtureeingaben. Er
belegt die Command-/Autoritaetsgrenzen, keine komplette menschliche Missionsreise.
Der positive Plateaucheck verwendet die echte importierte Buccaneer-AABB mit
Scale/Yaw und alle23betroffenen Hexzellen; er ist kein Sieben-Zellen-Dummy.
Kappenrandausschluss, lebender Owner, tatsaechliche Ersatzfuellung, alle vier
Stationsraeume, falsches Team, Offpad, Ortsspoofing, echter75→100-Rumpf,
Reparaturreplay, kompletter Fracht-/Verkaufskreislauf, Credits/Mengen/Restore,
Polisa-/Satellitenregression und die drei wirklichen Presenterbuttons sind erfasst.

Native Bilder unter `images/before` und `images/after` sind Godot4.6.2 mit
Compatibility-Renderer und1280×720. Die Aufnahmen wurden geoeffnet. Benutzerbilder
sind getrennte Quellen unter docs/reports/assets/map-services-20261114/.
Private Testdesktops wurden nie aktiviert, keine OS-Eingabe wurde gesendet;
Originalprofil- und Quellguards der Reviewrunner bestehen.

Die gezielten Bestandschecks umfassen Cargo/Restore, Mapmetadata sowie den
angepassten Editor-Hoehengrenztest. Der erste historische H7-Grenztest schlug
korrekt nach der Bereichserweiterung fehl; MAX-1/H16 wurde gesondert gruen
nachgeprueft. Weitere verworfene Authoring-/Fixture-/Footprintversuche stehen
transparent in summary.json und zaehlen nicht als bestanden.

Kein vollstaendiger Fuenf-Missionen-Sieg, kein WAN-/FPS-Gesamtgate und keine
persoenliche Gestaltungsfreigabe. Keine neue EXE wurde in diesem Arbeitsschritt
gebaut. Ein lokaler Servicezugriff ist kein Nachweis eines gesamten Spielzyklus.
