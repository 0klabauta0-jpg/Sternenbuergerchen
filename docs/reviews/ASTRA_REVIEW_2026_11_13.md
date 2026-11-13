# Code-, Architektur-, Usability- und Gestaltungsreview · 13.11.2026

Produktbasis: **9fdeb866b** (integrierter Main). Urteil: **Änderungen erforderlich**. VierP1 und fünfP2; keine Produkt-/Assetänderungen. Frühere177Regressionen bleiben historische gezielte Nachweise, keine Gesamtfreigabe.

## Codebefunde

P1 = zeitnah beheben (Multiplayer-Manipulation oder blockierter Kampagnen-/Ladepfad). P2 = relevanter Funktionsfehler mit konkreter Bedingung. Evidenzsicherheit ist getrennt von Priorität.

### C1 · P1 · Clients können Kampf- und Bewegungswerte vorgeben

Quelle: [scripts/multiplayer/multiplayer_command_contract.gd:200](../../scripts/multiplayer/multiplayer_command_contract.gd#L200).

Ein berechtigter Fireteam-Client übermittelt mit einem normalen hold_position auch attack_bonus, cover_score, move_speed_factor und sight_range_factor. Der Host übernimmt diese Werte in den tatsächlichen Unit-State.

**Nachweis:** Echtes ENet: Hostwerte Angriff100, Deckung1000, Bewegung100 und Sicht50 nach Remote-Befehl. Synthetische kleine Szene, tatsächliche RPC-/Commandpipeline.

**Kleinster sinnvoller Folgeschritt:** Remote-Payload auf Spielerabsichten begrenzen und interne Modifikatoren aus Host-Ownern bestimmen.

**Regression:** Manipulierte RPCs mit erlaubtem eigenen Team/Trupp ablehnen oder kanonisieren; Unitwerte sowie normale Befehle prüfen.

### C2 · P1 · Client kann Missionsinteraktion sofort abschließen

Quelle: [scripts/tests/mission_combat_loop_driver.gd:683](../../scripts/tests/mission_combat_loop_driver.gd#L683).

Bei der ersten Interaktion fehlen hostseitiger Abgleich von Position, Radius, Dauer und Missionsschritt mit dem geladenen Szenario. Der Client liefert die später als Wahrheit verwendeten Angaben.

**Nachweis:** Echter ENet-Client schließt das konfigurierte 30-Sekunden-Computerziel nach0,01Sekunden ab; Missionsgate wird vollständig erfüllt.

**Kleinster sinnvoller Folgeschritt:** Host löst Interaktions-ID auf und bestimmt Ziel, Radius, Dauer, Voraussetzungen und Ergebnis selbst.

**Regression:** Erst-RPC mit Dauer0, fremdem Ziel, übergroßem Radius und erfundener Schritt-ID; gültiger Befehl und Konkurrenz bleiben korrekt.

### C3 · P1 · Orbitaler Kampfabschluss findet keinen gültigen Rückweg

Quelle: [scripts/core/simulation_root.gd:8033](../../scripts/core/simulation_root.gd#L8033).

Root erzeugt end_campaign_encounter, aber weder Fleet-Validator noch vorbereiteter Reiseübergang unterstützen diese Operation. Der Adapter kehrt bei Ablehnung still zurück.

**Nachweis:** Tatsächliche Root-/Adapter-/Fleet-/Combat-Owner, synthetisch vorbereitete Begegnung: Rückzug wird bestätigt, Rückkehr ergibt invalid_area_context; Encounter bleibt aborted/resolved=false, Reise bleibt approach. Kein vollständiger Fünf-Missionen-Durchlauf.

**Kleinster sinnvoller Folgeschritt:** Einen vollständigen, ownergebundenen Abschlussübergang implementieren und Fehler sichtbar machen. Nur die Whitelist zu erweitern reicht nicht.

**Regression:** Gebundener Sieg, Rückzug und Niederlage bis Reisephase, Ergebnis, Fuel und wiederholbarem Commit.

### C4 · P1 · Alter beschädigter Einsatzsave blockiert neue Kampagne

Quelle: [scripts/meta/campaign_start_configuration.gd:35](../../scripts/meta/campaign_start_configuration.gd#L35).

Ein vorhandener ungültiger active_checkpoint wird vor dem neuen Kampagnenkontext abgewiesen. Eine neue Kampagne mit gültigem Basisstand behält die alte Datei; Fortsetzen bleibt dadurch gesperrt.

**Nachweis:** Echte neue Kampagne erfolgreich gespeichert, danach Fortsetzen wegen des absichtlich beschädigten privaten alten Einsatzstands abgebrochen. JSON-Parse-Diagnose gehört zur Reproduktion.

**Kleinster sinnvoller Folgeschritt:** Neue Kampagne vom alten aktiven Slot trennen und einen expliziten Wiederherstellungsweg zum gültigen Basisstand anbieten; beschädigte Datei zur Diagnose erhalten.

**Regression:** Beschädigter und veralteter Einsatzslot + neue Kampagne + Save + Neustart/Continue; guter Basisstand darf nicht unerreichbar werden.

### C5 · P2 · Basis-Checkpoint-Aktion lädt stattdessen Einsatzsave

Quelle: [scripts/meta/meta_layer_flow.gd:4234](../../scripts/meta/meta_layer_flow.gd#L4234).

Nach gescheiterter Extraktion verspricht der Debrief ausdrücklich den letzten sicheren Basisstand. Er startet jedoch allgemeines Continue, das einem passenden aktiven Einsatzsave Vorrang gibt.

**Nachweis:** Echte Satellitenreise, aktiver Missionssave, Besatzungsverlust und tatsächlicher Debriefbutton: Mission wird auf der Oberfläche wiederhergestellt, Basisdatei bleibt unverändert.

**Kleinster sinnvoller Folgeschritt:** Expliziten Basis-Rollback von normalem Continue unterscheiden.

**Regression:** Missionssave vor Niederlage erstellen und den tatsächlichen Debriefbutton bis zur Heimatbasis verfolgen.

### C6 · P2 · Sichtprüfung schneidet halbe Rampenhöhen ab

Quelle: [scripts/core/los_system.gd:82](../../scripts/core/los_system.gd#L82).

Die präzise Standhöhe2,5 wird im gemeinsamen LOS-Helper auf Integer2 verkürzt. Ein Hindernis mit Oberkante2 blockiert dann fälschlich die Sicht.

**Nachweis:** Kanonische Rampen auf beiden Seiten liefern stand_height_steps2=5; reine Hexquery und Cache melden beide terrain_blocked.

**Kleinster sinnvoller Folgeschritt:** Halbe Höhen bis zum abschließenden Vergleich erhalten.

**Regression:** Rampen2,5 und Hindernis2/3 in beiden Richtungen; erwartete Geometrie prüfen, nicht nur Cache gegen denselben fehlerhaften Helper.

### C7 · P2 · Schusspfad umgeht teilweise die logische Hexsicht

Quelle: [scripts/tactical/combat_fire_decision_resolver.gd:334](../../scripts/tactical/combat_fire_decision_resolver.gd#L334).

Kontakte verwenden Ground-Facing und Hexadapter; tatsächliche Feuerentscheidung verwendet weiter Weltpositions-LOS. Ein Gegner mit gültiger Erkennungsverzögerung0 kann so ein rückwärtiges Ziel wählen.

**Nachweis:** Tatsächlicher Driver/Root: Hexadapter outside_arc, Kontakt-LOS=false, trotzdem nichtleeres Angriffspaar enemy→own. Opt-in-Hexfixture, kein flächiger Nachweis auf allen Karten.

**Kleinster sinnvoller Folgeschritt:** Sicht und Reichweite für aktive Hexkämpfe über denselben vorhandenen Adapter führen; Legacyfallback erhalten.

**Regression:** Rückwärtige Ziele bei0/positiver Erkennungsdauer, Richtungswechsel und alle sechs Hexachsen sowie Legacyfälle.

### C8 · P2 · HUD-Diagnose würfelt und verändert Kampfzustand

Quelle: [scripts/tests/mission_combat_loop_driver.gd:2232](../../scripts/tests/mission_combat_loop_driver.gd#L2232).

Ein öffentlicher Diagnosegetter ruft die mutierende Schusserlaubnis auf. Beim Wechsel von keinem Gegner zu vorhandenem Gegner kann Lesen einen Disziplinwurf, Cooldown und Ereignis auslösen.

**Nachweis:** Öffentlicher Getter mit reproduzierbarem Seed13: Cooldown{}→{own:10} und Ereignis „own bricht Feuerstopp!“, ohne Schuss. Normaler HUD-Aufrufpfad im Controller nachverfolgt.

**Kleinster sinnvoller Folgeschritt:** Reine Diagnose von autoritativer Entscheidung trennen; UI liest bereits ermittelte Resultate.

**Regression:** Beliebig viele Snapshotreads erhalten RNG, Cooldowns und Ereignisse, einschließlich leer→Gegner vorhanden.

### C9 · P2 · Enter aktiviert verdeckte Aktionen hinter Escape-Menü

Quelle: [scripts/ui/global_escape_menu.gd:91](../../scripts/ui/global_escape_menu.gd#L91).

Das Overlay fängt Mausereignisse ab, übernimmt und begrenzt aber den Tastaturfokus nicht. Der zuvor fokussierte Button bleibt erreichbar.

**Nachweis:** Tatsächliches Autoloadmenü per Viewport-Escape geöffnet; Fokus bleibt UnderlyingAction, Enter erzeugt1Buttonaktion bei weiterhin sichtbarem Menü. Nur lokale Test-Viewportevents, keine OS-Eingaben.

**Kleinster sinnvoller Folgeschritt:** Menüfokus setzen und halten, vorherigen Fokus beim Schließen wiederherstellen; Gameplay-Hotkeys hinter Modal sperren. Echtzeit läuft absichtlich weiter.

**Regression:** Enter, Leertaste, Tab/Shift-Tab und Gameplay-Hotkeys hinter Menü, Einstellungen und Hilfe prüfen.

## Architektur

Grundarchitektur tragfähig, ihre Grenzen aber verletzt. PROJECT_BRIEF, ARCHITECTURE, DECISIONS und konkrete Contracts sind die geltende Grundlage; fehlende Plugin-GDD-/ADR-Verzeichnisse sind kein Fehler. Kein neuer Engine-Kompatibilitätsmangel nachgewiesen; lokale Proben liefen auf Godot4.6.2.

| Anforderung | Befund |
|---|---|
| Host bestimmt Gameplaywerte | C1/C2 verletzen bestehenden Authorityvertrag |
| UI liest ohne Mutation | C8/C9 zeigen fehlende Read-/Inputgrenzen |
| Einheitliche aktive Hexentscheidungen | C6/C7; nur ein Teil der Karten nutzt opt-in Hexregeln |
| Ownergebundene Reise und Speicherung | Gute Grundtrennung, aber C3–C5 an Übergängen |
| Registry, begrenzter Cache, frisches Teamfanout | Im geprüften Ausschnitt sinnvoll; kein weiterer Defekt im jüngsten Fanout/Cache nachgewiesen |
| Mainvertrag und Prüfungen passen zusammen | Cachevertrag veraltet; kombinierte Übergangstests fehlen |

## Architekturmaßnahmen

### Absicht, Entscheidung und Anzeige konsequent trennen

Die bestehenden Owner sind sinnvoll. Remote-Commands brauchen hostseitige Kanonisierung, und UI-Lesewege dürfen keine Würfe oder Mutationen auslösen. C1/C2/C8 sind konkrete Verletzungen dieser bereits dokumentierten Grenzen.

**Vorschlag / Prüfung:** Zuerst kleine Eingangs- und Read-only-Grenzen schließen; keine zweite Commandqueue und kein Architektur-Neubau.

### Kampfregeln vereinheitlichen, Domänen getrennt lassen

Kein zweiter unabhängiger Schadensowner im geprüften Bodenpfad. Es bestehen aber unterschiedliche Sichtentscheidungen und globale Disziplin-/Fehlidentifikationswürfe neben Roots gespeichertem Combat-RNG. Ein Hexraster aktiviert noch nicht automatisch hex_tactical_v1; unter den geprüften Karten-JSONs trägt nur polisa_station.json diese Kennung.

**Vorschlag / Prüfung:** Gemeinsamen Sicht-/Würfelvertrag bis zum realen Schuss und Checkpoint sichern. Boden- und Raumkampf müssen nicht dieselben Datenmodelle bekommen.

### Übergangsstruktur klein zurückbauen und Main-Verträge pflegen

Produktive Mission lädt weiterhin Driver/Controller unter scripts/tests. Die Ordner sind laut Vertrag bewusste Legacybrücken; Dateigröße allein ist kein Bug. Der Hexvertrag beschreibt außerdem16384persistenteLRU-Einträge, Main dagegen4096ticklokaleEinträge.

**Vorschlag / Prüfung:** Als ersten klaren Bereich Interaktionsautorität kapseln; Pfadkompatibilität erhalten. Dokumentation Main/Kandidat trennen. Integrationsprüfungen über RPC→Owner→Ergebnis und Save→Fehlschlag→Continue ergänzen.

## Usability

### Speichern und Fortsetzen eindeutig erklären

Der Hauptdialog verspricht einen Basis-Neustart, obwohl ein Einsatzsave fortgesetzt werden kann. Tutorial und Sperrtexte unterscheiden die beiden Speicherarten ebenfalls nicht durchgehend.

**Vorschlag / Prüfung:** Gemeinsame lesende Projektion von Speicherart, Ort, Zeitpunkt und Sperrgrund. Vor dem Laden soll ein Spieler korrekt vorhersagen können, wo er weiterspielt.

Quelle: `scripts/ui/main_menu_screen.gd:3823`.

### Beim Beenden den erhaltenen Fortschritt zeigen

Hauptmenü und Beenden wirken unmittelbar. Gerade während einer nicht speicherbaren Reise zeigt das Menü nicht, welcher Stand später geladen wird.

**Vorschlag / Prüfung:** Letzten wiederaufnehmbaren Stand anzeigen; bei ausstehendem Fortschritt gezielt bestätigen lassen. Mit einem Spieler den Ausstieg während einer Reise prüfen.

Quelle: `scripts/ui/global_escape_menu.gd:216`.

### Treibstoffanzeige auffindbar und anklickbar machen

Die nützliche Hin-/Rückfluganzeige erscheint nur bei gehaltener Alt-Taste; ein sichtbarer Zugang fehlt.

**Vorschlag / Prüfung:** Fokussierbarer Schalter „Treibstoff & Reichweite“, Alt bleibt Abkürzung. Reiseplanung jeweils nur mit Maus und nur mit Tastatur prüfen.

Quelle: `scripts/ui/star_map_screen.gd:70`.

### Fokus und Modalität verlässlich führen

Der konkrete Fokusdurchgriff ist bereits CodebefundC9 und wird nicht doppelt gezählt. Ein Menü muss sichtbaren Fokus erhalten und ihn beim Schließen sinnvoll zurückgeben.

**Vorschlag / Prüfung:** Esc→Tab/Shift-Tab→Enter/Leertaste aus Crew-, Sternkarten- und Einsatzansicht prüfen. Die absichtlich weiterlaufende Echtzeitsimulation bleibt bestehen.

Quelle: `scripts/ui/global_escape_menu.gd:91`.

## Visuelle Gestaltung

### Personenstil und Wiedererkennung zusammenführen

Detailliertes Anja-Porträt und stark vereinfachte Astronautenfigur wirken stilistisch und äußerlich wenig zusammengehörig. Das ist keine nachgewiesene Verwechslung der Runtime-ID.

**Vorschlag / Prüfung:** Zunächst eine Figur gegen dieselbe Zielvorlage abstimmen: Identität, Kopf-/Körperproportionen und Palette.

### Sternkartenraster gegenüber Zielen zurücknehmen

Das dichte Cyanraster konkurriert in der Gesamtansicht mit kleinen Orbitmarkern und Schiffszeichen.

**Vorschlag / Prüfung:** Rasterkontrast mit Zoom reduzieren; wichtige Marker behalten lesbare Bildschirmgröße. Vorhandenen Meshcache weiterverwenden.

### Auftragsaktionen optisch zum Appfenster gehören lassen

Die Aktionen stehen im nativen Bild außerhalb der dunklen Appkarte über der orangefarbenen Welt; darunter konkurriert das Basisband.

**Vorschlag / Prüfung:** Deckende Petrol-Fußleiste mit gemeinsamem Rahmen; die bereits korrigierte Erreichbarkeit außerhalb des Scrollbereichs erhalten.

### Leere Beziehungskarte verkleinern

„Noch keine Beziehung bekannt“ erhält fast das Gewicht der belegten Eigenschaftskarte, während andere Inhalte bei720p scrollen.

**Vorschlag / Prüfung:** Leeren Zustand als kurze Zeile oder geschlossenen Abschnitt; Platz für Figur und Ausrüstung statt kleinerer Schrift.

## Bildgrundlage und Grenzen

Fünf native Bilder plus vier Originalziele vom Fachagenten angesehen; Root zusätzlich Sternkarte und älteren720p-Charakterbogen. Historische Bilder sind keine frische Mainabnahme. Stilvorschläge sind fachliche Einschätzungen, keine gemessenen Nutzertestresultate.

- Charakterdetails · nativ1280×720 · 12.11.2026; historischer Integrationsstand: `docs/qa/job_app_safe_area_20261112/details-1280.png`; SHA256 `bde5c083252e2222183646bd75249ed95b80414a0a874f0f68035b94c3eed619`.
- Auftragsapp · nativ1280×720 · 12.11.2026; historischer Integrationsstand: `docs/qa/job_app_safe_area_20261112/mobile-1280.png`; SHA256 `acc349746bb8fcf04b1025aca5aba0c5a6d810b3a1983a0f055dbee6b631d8f0`.
- Sternkarte · native Zwei-Owner-Testszene · 12.11.2026; kein erspielter Mehrschiff-Spielstand: `docs/qa/starmap_wings_20261112/selected_wings.png`; SHA256 `1c1d351d20f9d5ad2aec6e3accb1af12ad92723e099af6847b1e21617b96000f`.

Quellenabgleich: personnel_body_preview.gd:27, personnel_inventory_panel.gd:240, star_map_canvas.gd:359, singleplayer_job_board_presenter.gd:29/74, character_sheet_view.gd:179. Die Sternkarte zeigt eine Zwei-Owner-Fixture; deren Testnamen werden nicht als Katalogfehler bewertet.

**Positiv:** Einheitliche Petrol/Cyan/Creme-Palette, reale Crew-/Pilot-/Abfluggates und explizite Auftrags-/Anfluginformationen. Die Cutlass-Silhouette und Palette passen im betrachteten Bild zur zugeordneten Vorlage. Keine Pause im Einsatz ist ausdrücklich gewollt.

## Vorgehensreihenfolge

1. C1/C2: Multiplayer-Eingangsgrenzen schließen.
2. C3/C4/C5: Begegnungsabschluss und eindeutige Save-/Rollbackwahl sichern.
3. C6/C7/C8: Sicht, Schuss und Zufallsentscheidung durchgängig verbinden.
4. C9 und Speicher-/Ausstiegshinweise: verlässliche Bediengrenzen.
5. Danach kleine visuelle Vergleichsrunde, beginnend mit einer Person und der Sternkarte.

## Prüfmethodik / ausgeschlossene Verdachtsfälle

Gezielte Quellprüfung und sieben verwertbare private headless Reproduktionen; zusätzlich ein verworfener Fixturefehler. Keine Produktänderung, keine neue EXE, kein vollständiger Spiel-/WAN-/GPU-/FPS- oder menschlicher Usabilitytest. Visuelle Empfehlungen basieren auf historischen nativen Aufnahmen mit Quellabgleich. Bestehende grüne Regressionen werden nicht als Sicherheits- oder Gesamtfreigabe ausgegeben.

Sieben verwertbare Reproduktionsläufe (UI, Hex, Diagnose, Netzwerk, Kampagne, Fleetgrenze, Rootabschluss). PASS bedeutet in diesen Proben: Fehler beobachtet, ausdrücklich nicht Fehler repariert. Alle Produktquellenhashes und echten Profilfingerabdrücke blieben identisch; private user://-Canarys vorhanden.

Die Kampagnenprobe meldet40Beobachtungschecks und0fehlgeschlagene Checks bei Engineexit0. Der erwartete Parserfehler stammt ausschließlich aus der absichtlich beschädigten privaten Testdatei. Der strenge Wrapper endet deshalb1; dies wird nicht als fehlerfreies Runtimegate verkauft. Ein früher Rootabschluss-Fixture benutzte den falschen Admissionseinstieg und scheiterte9mal; als Harnessfehler verworfen. Die korrigierte tatsächliche Ownerbindung hat17/0 und keine Enginefehler. Beide Rohlogs erhalten.

Overwatch wurde nicht als aktiver Fehler aufgenommen: regulärer Readiness-Producer liefertfalse. Der neue Cache bewahrt Keys/Revision/Facingfilter; sein Vergleich mit derselben LOS-Query übersah jedoch C6. Keine zusätzliche Fehlermeldung nur wegen großer Dateien oder unter scripts/tests liegender Produktkomponenten.

Vollständige Rohlogs, Quellhashes und Proben: docs/qa/astra_review_20261113/reproduction_evidence.zip; strukturierte Ergebnisse: summary.json. Wiederausführung: ZIPs tmp/astra_review_20261113 unter denselben Projektroot extrahieren und python tmp/astra_review_20261113/run_probe.py <case> starten. Nur mit passender Godot4.6.2 und vorhandenen Importressourcen.
