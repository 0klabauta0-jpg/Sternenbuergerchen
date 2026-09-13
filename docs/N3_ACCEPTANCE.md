# N3-Abnahme · Internet, Rüstung und Außenposten

13.09.2026, Godot 4.6.2.stable.official.71f334935. Eigenständiges Neustartprojekt auf `codex/rostgrenze-internet-aussenposten`, Ausgangspunkt `7f5fcc4c27f447c74b697d3a558ffbd0d527d529`. Altprojekt unverändert. Die nachfolgende Abnahme beschreibt die erste funktionierende N3-Stufe, keine vollständige Spielkampagne.

## Resultierender Spielerweg

Das Hauptmenü verwendet das tatsächliche alte Bild mit der sitzenden Frau. Neue Karriere beginnt in der Heimat. Ida stellt an der Werkbank Schutzrüstung her und rüstet sie aus. Die Crew findet auf der vergrößerten Rostkarte den Satelliten, birgt Blackbox, Erz und Legierung, verkauft Fracht und verdient die Geier-Miete. Jaro erhält gekaufte Rüstung. Mit dem Mietschiff steigt die Ausbeute am passenden Schiffwrack; sichere Rückgabe erhält die Fracht.

Danach fliegt die Crew zum Bunker, landet außerhalb der Flakreichweite, bekämpft Wächter und Turm und erreicht über den Aufzug eine separat geladene Untergrundkarte. Türöffnungen und Sichtblockaden wirken. Nach Kampf und Bergung geht es zurück zur Oberfläche, zum Verteilzentrum und zum Handelsposten mit abseitigem Fund. Speichern/Laden erhält den Fortschritt.

Internet ergänzt ENet-LAN durch einen temporären verschlüsselten Einladungsraum. Der Host bestätigt die Simulation; der Gast sendet weiterhin Befehle. Authentifizierung, Schemaabgleich und Senderrechte gelten vor der Freigabe von Spielzustand und Crewplatz.

## Geprüfte Wege

| Prüfung | Ergebnis | Nachweis |
|---|---:|---|
| Neue Kernregeln: Kampf, AA, Navigation, Ressourcen, Rüstung, Miete, Ausfall und v3-Validierung | 151/151 | `tests/ground_stage_core_test.gd` |
| Frühere Kern- und Orbitregressionen einschließlich Save-Migration | 100/100 + 67/67 | `tests/core_flow_test.gd`, `tests/next_stage_core_test.gd` |
| Neuer kompletter Weg im echten Produktfenster | 69/69 | `tests/ground_product_test.gd`, `output/n3-product-result.json`, `output/n3-product-final.log` |
| Früherer Produktweg | 63/63 | `tests/product_flow_test.gd` |
| Auswahl, Rechtsklick, Rahmen, Kamera, Pause | 13/13 | `tests/control_window_test.gd` |
| Vier echte Starts, Fortsetzen und Speicherfehlerschutz | 10/10 | `tests/save_lifecycle_run.ps1` |
| Welt, tatsächliche Raypicks, aktive Einzelkarte, Rüstung, Fundorte und Schiffe | 92/92 + 9/9 | `scripts/world/world_ground_probe.gd`, `output/ground-world/world-results.json` und Armor-Nahaufnahme |
| Öffentliches WSS, zwei echte Prozesse | 55/55 | `tests/internet_report.md` |
| Produktiver DNS-/TLS-Fallback über öffentliche Strecke | 55/55 | `tests/internet_report.md` |
| ENet-LAN-Regression | 69/69 | `tests/internet_report.md` |
| Gateway-Eingaben, Auth und direkte Szenenfreigabe | 15/15 | `tests/internet_gateway_test.gd` |
| Portables Windows-Paket: echte Release-Menü-/Spielstarts, eingebettete lokale Modelle, frisch entpacktes ZIP | 22/22, alle EXE-Starts Exit 0 | `docs/WINDOWS_DELIVERY.md`, `output/windows-delivery/` |
| Frischer Quellsnapshot ohne lokale Modelle: Import, drei kuratierte Fallbacks, Hauptmenü | 12/12, Import/Boot Exit 0 | `tests/asset_delivery_test.gd --require-curated`, Nachweispfad unten |

Die vollständige neue Produktprobe vergibt keine Belohnungen oder Spielzustände direkt: Sie verwendet normale Befehle, echte Zeit, Auswahl und UI-Aktionen. Geier-Miete wird aus Mission/Mining/Verkauf verdient. Die Weltprobe ergänzt Kameras und Bildbelege; sie ist kein Ersatz für den Produktpfad. Netzwerkproben verwenden eigene APPDATA-Verzeichnisse und zwei wirkliche Prozesse. Keine normale Nutzerkarriere wurde für Testfortschritt überschrieben.

Frischer Quellsnapshot: `C:/Users/bjoer/AppData/Local/Temp/sternenbuergerchen-source-delivery-6dc5ba2ebe784d3e908caffb99e49cf2/`. 186 Quelldateien, 2.549.927 Byte, ohne `.godot`, `assets/local`, `output` oder `.git`. Alle drei Schiff-IDs laden bestätigt den mitgeführten Kenney-Ersatz. Import-, Asset- und Bootlogs ohne Fehler/Warnungen; keine Karriere angelegt. Das fertige Windows-Paket mit den vorhandenen lokalen Schiffen ist separat in [WINDOWS_DELIVERY.md](WINDOWS_DELIVERY.md) nachgewiesen.

## Daten, Darstellung und Bedienung

- Snapshot Schema 3; alte v1/v2-Kataloge und Validatoren bleiben für kontrollierte Migration eingefroren. Autoritative N3-Felder liegen im Kern, nicht im HUD.
- Karte: Basis 320 × 320 m, Rostwelt 960 × 960 m, Station 160 × 160 m, Raumkontakt 480 × 480 m, Bunkeroberfläche 640 × 640 m, Untergrund 128 × 128 m, Distribution 800 × 800 m, Handelsposten 400 × 400 m. Gemeint sind jeweilige Seitenlängen, nicht durchgehend bebaute Flächen.
- Neue Gebäudehindernisse sind dieselben Rechtecke für Navigation, Sicht und Darstellung. Das macht nicht automatisch sämtliche alten Basiswände und Felsen zu Kollisionskörpern.
- Frontwände verwenden wirksame Materialtransparenz. Bodenplatten und Wege überlappen nicht mehr. Shader-/Meshdarstellung verändert keine Kampfergebnisse.
- Schiffe prüfen Ressourcen mit `ResourceLoader.exists`, damit auch importierte Modelle im Export-PCK funktionieren. Eigene lokale Modelle sind weiterhin Git-ignoriert; kuratierte Fallbacks erhalten den frischen Checkout.
- Einladungen sind im Eingabefeld maskiert. Kopieren erfolgt bewusst per Knopf; Statusmeldungen und öffentliche Nachweise enthalten keinen Einladungsschlüssel.
- Bedienung bleibt Commander mit Linksklick, Rechtsklick und Rahmenauswahl. WASD bewegt nur die Kamera. Kein direkter WASD-Figuren- oder Höhenflugmodus.

## Grenzen und weitere Arbeit

Die Internetstrecke wurde tatsächlich über einen öffentlichen Tunnel geprüft, aber beide Prozesse liefen auf demselben PC. Ein zweites Heimnetz, längere Sitzungen, Provider-Firewalls, Paketverlust und der Test mit dem Freund in Österreich stehen aus. Quick Tunnel ist ein Prototypdienst ohne SLA; dauerhafte Räume und betriebene Vermittlung folgen später. Zwei feste Crewrollen, keine weiteren Gäste oder PvP.

Fähigkeiten wirken bereits, wachsen aber noch nicht durch Erfahrung. Technik betrifft Rezeptzugang und Abbau-/Bergezeit; Bordrollen sind Ida/Jaro fest zugeordnet. Details: [N3_SKILLS_MENU.md](N3_SKILLS_MENU.md). Traits, Beziehungen, Moral, Bewerber, Forschung und tatsächlich baubare Räume bleiben offen.

Geier: Miete und Fracht-/Wrackbonus sind spielbar, noch kein eigener Schiffs-Bergungslaser. Bodenberufe sind einfache endliche Arbeitsaufträge; Raum-Mining, Raum-Salvage und Lieferverträge folgen. Wachen stehen an einfachen Posten; keine Patrouillen, Deckung oder Alarmkette. Der 20-Sekunden-Ausfall ersetzt noch kein ausgearbeitetes Medizin-/Evakuierungssystem.

Framezeit-Stichproben und Modellprovenienz: [GEIER_ASSET_METRICS.md](GEIER_ASSET_METRICS.md). Dies sind Messungen auf dem gemeinsamen Entwicklungsrechner, keine allgemeine Performancefreigabe. Menschlicher Spielspaß und UX-Verständlichkeit bleiben praktisch zu erproben.

## Bericht und Auslieferung

Der aktualisierte private [Handy-Spielplan](https://sternenbuergerchen-neustart.klabauta.chatgpt.site) enthält Vision, tatsächliche Skillwirkungen, neue Orte, Internetbedienung, Grenzen und zwölf echte Laufzeitbilder. Die Vorlage unter `docs/reports/` und `tools/build_report.py` erzeugen denselben Inhalt als eigenständige lokale HTML-Dateien. IDs, Sprunglinks, Bildreferenzen und mobile Viewport-/CSS-Regeln wurden statisch geprüft; kein behaupteter Browser- oder menschlicher UX-Test.

Weitere Verträge: [N3_GROUND.md](contracts/N3_GROUND.md), [INTERNET_COOP.md](INTERNET_COOP.md), [Auftrag](tasks/N3_INTERNET_OUTPOSTS.md).

Veröffentlichung bestätigt: private Site-Version 2, Quellcommit `f0cab42083f1bd3292bdc502e53b59e38edee3b5`, gespeicherte Version `appgprj_6aa62f5331b081918ef8f9dfa0a19ab6~appgver_f27309be37a08191864d1a3efe8ce779`, Deployment `appgdep_6aa656aa284c8191afda4c27ee998531`, Status `succeeded`. Das Archiv enthält ausschließlich Bericht, Bildbelege und Hosting-Konfiguration.
