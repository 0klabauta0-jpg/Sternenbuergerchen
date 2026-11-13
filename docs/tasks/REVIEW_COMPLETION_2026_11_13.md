# Offene Reviewpunkte vollständig umsetzen · 13.11.2026

## Ziel / Problem
Nutzerauftrag: Hex und Würfeln, Architektur, Bedienbarkeit sowie Grafik einschließlich
Maps und Assets umsetzen, mit Agenten, ohne Desktopübernahme, Regressionen und
aktualisiertem Websitebericht. Basis ist der integrierte Main dc2ca9aca. Der vorige
Fixlauf schloss C1–C10, ließ jedoch Kartenaktivierung, weitere Zufallswege,
Architekturmaßnahmen und Gestaltungs-/Bedienvorschläge offen.

## Ursache / Sinnhaftigkeit
Hexgeometrie allein aktiviert keine autoritative Hex-Taktik. Globale Zufallsaufrufe
umgehen gespeicherte Owner-Zufallszustände. Produktive Legacy-Driver enthalten
abgrenzbare Zuständigkeiten. Fehlende sichtbare Bedienelemente und uneinheitliche
Darstellung erschweren Reiseplanung, Wiederaufnahme und Orientierung.

## Umfang und Nicht-Ziele
- Alle aktuell spielbaren Boden-/Kampagnen-/Skirmish-Karten inventarisieren und auf
  den bestehenden Hex-Taktikvertrag migrieren; Basisnavigation konsistent anbinden.
  Historische Square8-Dateien bleiben als explizite Import-/Testkompatibilität erhalten.
- Autoritative Zufallsentscheidungen auf normalisierte Werte 0..1 bringen; Anzeigen
  dürfen 0..100 % verwenden. Bestehende Domänenowner und deterministische Streams
  erhalten, globale Gameplay-Würfe beseitigen, Save/Restore und Replikate absichern.
- Aktive Sicht-, Bewegungs-, Schuss- und Schablonenpfade an vorhandenen Hexownern
  vereinheitlichen. Keine zweite Schadens-/Positionswahrheit und keine neue Ballistik.
- Review-Architekturmaßnahmen: Interaktionsautorität aus dem Legacy-Driver kapseln,
  kompatible Einstiegspunkte erhalten, aktuelle Contracts und Integrationsprüfungen.
- Usability: gemeinsame lesende Speicherprojektion, sichtbarer Fortschritt vor
  Ausstieg, fokussierbarer Treibstoff-/Reichweitenschalter; bestehende Bedienung erhalten.
- Grafik: ursprüngliche vier Gestaltungsbefunde bearbeiten; aktive Karten, Boden,
  Gebäude, Figuren und weitere Assetgruppen gegen vorhandene Zielbilder prüfen,
  konkrete Lesbarkeits-/Kohärenzfehler korrigieren und tatsächliche Varianten zeigen.
  Bestehende Nutzerreferenzen und fremde Kandidaten erhalten. Kein beliebiger Stilwechsel.
- Kein EXE-Export angefordert. Menschliche Geschmacksabnahme wird nicht durch Tests ersetzt.

## Dokumente / Contracts
AGENTS.md, PROJECT_BRIEF.md, ARCHITECTURE.md, CODEX_RULES.md,
IMPLEMENTATION_STATUS.md, TASK_ROADMAP.md;
docs/reviews/ASTRA_REVIEW_2026_11_13.md;
docs/dev/{hex_tactical_runtime,hex_grid_v1,combat_loop_authority,
runtime_script_layout,multiplayer_authority_command,graphics_reference_revision,
terrain_truth_visual_audit,html_report_workbench}_contract.md;
docs/superpowers/plans/2026-11-11-hex-sight-occupancy.md.

## Akzeptanzkriterien
1. Inventar benennt alle produktiven Karten und aktive Regeln; reale Starts,
   Bewegung, Belegung, Sicht/Schuss, Transport, Save/Restore und ENet bleiben konsistent.
2. Gameplay-Würfe sind ownergebunden, normalisiert und reproduzierbar; Diagnose/UI
   und Replikate verbrauchen keine Würfe. Fortsetzung erhält die nächste Folge.
3. Die extrahierte Interaktionsgrenze wahrt Hostbindings, Lifecycle, Abbruch,
   konkurrierende Trupps und RPC-Normalisierung ohne neue Autoritätsquelle.
4. Treibstoffinformation ist per Maus und Tastatur erreichbar; Ausstieg erklärt
   den tatsächlich wiederaufnehmbaren Stand. Speichern/Fortsetzen bleiben korrekt.
5. Personenstil, Kartenraster, Appfußleiste und leere Beziehungskarte sind korrigiert.
   Grafikgruppeninventar, zugeordnete Referenzen, native vergleichbare Bilder sowie
   Bounds/Material-/Terrainregressionen belegen Karten-/Assetkorrekturen.
6. Serienweise private Godotprüfungen bestehen mit nichtleeren Assertions, ohne
   Enginefehler/Leaks und ohne Änderung der echten Spielerprofile. Native Aufnahmen
   ausschließlich auf nie aktiviertem privatem Desktop oder geeignetem Offscreenpfad.
7. Mobile/offline Workbench mit lokalem JSON-Export aktualisiert; bestehende private
   Website aktualisieren und tatsächlichen Deploymentstatus dokumentieren.

## Dateien / Zuständigkeiten
Hexagent: Kartenaktivierung, Root/Combat/Navigation/RNG sowie zugehörige Tests/Contracts.
UXagent: Speichern-/Ausstiegprojektion, Menü, Sternkartenbedienung, Auftragsfußleiste,
Beziehungskarte und Tests. Grafikagent: Terrain-/Asset-/Personendarstellung,
Sternkartenraster, Referenzinventar, native Capturefixtures und Tests.
Root: Architektur-Extraction nach Driver-Freeze, serialisierte Prüfungen,
unabhängiger Review, Integration/Main und HTML/Website. Gemeinsame Dateien abstimmen.

## Prüfung / Risiken / offene Punkte
Vorher/Nachher gegen dieselbe Kamera/Rendererroute; keine unsichtbaren Screenshots
als visuelle Abnahme. RNG-Reihenfolge, Kartenadmission, alte Saves, Ownerlebenszeit,
Eingabefokus, Material-/Importkosten und Cacheinvalidierung gezielt prüfen.
Vorheriger Websiteversuch scheiterte beim Hosting; bestehende Site-ID/Audience
erhalten, abgeschlossenen Fehler nicht als laufendes Deployment pollen.
Fremdes WIP im Hauptcheckout bleibt unangetastet. Arbeit auf
task/review-completion-20261113 ab aktuellem Main, keine Übernahme alter Taskbäume.

## Fortschritt
Hex-/RNG-, Architektur-, UI- und Grafikänderungen sind implementiert. Die gemeinsame
Prüfung läuft: alle 17 Karten bestehen die Funktionsmatrix, UI und Assetnachweise
sind vorhanden. Neu gefundene Save-/Restore- und Stationsdarstellungsübergänge
werden mit echten Spielständen, verbundenen Peers und nativen Bildern geschlossen.
Mainintegration und Websiteveröffentlichung stehen bis zur Endprüfung aus.

## Im Durchlauf zusätzlich bestätigt

Die breite Umstellung wurde bewusst gegen echte Spielstarts, Dateipaare und
native Bilder geprüft. Dabei neu gefunden und im selben Auftrag bearbeitet:

- Fehlender erster Basischeckpoint; fehlgeschlagener Save meldete zu lange Erfolg.
- Gleiche Blickrichtung erzeugte ständig ausstehende Arbeit.
- Rundumsicherungsbefehle fehlten im engen Savecodec; angekommenes Hex-Move-Label
  wurde noch als laufende Bewegung behandelt.
- Frische Stations-Registries hatten beim Restore einen kalten Korridorindex.
- Finalisierter Identity-Callback hielt einen Refcount-Kreis; Prepare-Kapazität
  musste vor inneren Ownern bereinigt und gemeinsam begrenzt werden.
- Im 720p-Header brach ein Label zeichenweise um; Tutorial-/Supply-Overlays
  verdeckten den tatsächlichen Charakterbogen.
- Auftragsbriefing und Sternkarte nannten unterschiedliche Himmelskörper;
  Projektion wird aus denselben bestehenden Reisedaten abgeleitet.
- Square-Modulmeshes wurden nach Hexaktivierung mit falscher lokaler Basis
  dargestellt; native Bilder zeigten klaffende Platten-/Wandanschlüsse.
- Dünne regionale Kappen unterschiedlicher logischer Höhe teilten einen
  Schatten-Batchkey; einfügereihenfolgeabhängiges Schattenverhalten.
- Lokale Interaktionen quittierten Ankunft vor dem tatsächlichen Hex-Hold und
  konnten nach der Zentrierung knapp außerhalb ihrer Reichweite hängen bleiben.
  Ausführungsumfang, Hold-Receipt und Radiusprüfung lesen jetzt dieselben Owner.
- Formationsstufen verglichen Hexzentren noch mit einem ungequantelten 18px-Ziel;
  Einpersonen-Buddygruppen enthielten außerdem eine nicht quittierbare Leerphase.
- Die Stationsroute publizierte eine lokale Frachtschifftextur im rohen
  Netzwerkzustand. Die strikte DTO-Prüfung lehnte dadurch alle Snapshots ab.
  Bildobjekte bleiben ausschließlich im lokalen Visualpfad; das bestehende
  Schiffs-/Dropkartenformat bleibt unverändert.
- Rückkehr-/Aufsitzbefehle zielten in die gesperrte Schiffsmitte. Die tatsächliche
  Cutlassmaske lässt keinen Standpunkt innerhalb der alten Mittelpunktradien zu.
  Gemeinsame Zugangsprojektion und normale Root-Bewegung ersetzen dieses Ziel;
  siehe produktiven Hexvertrag. Keine Radiuslockerung oder erneute Admission.

Im echten dritten Ausflug wurde zusätzlich eine bereits freigegebene alte
Missionsinstanz aus dem gespeicherten Ansichtskontext wieder als Node zugewiesen.
Der Kontext muss die Instanz schwach referenzieren und nach ihrer Ablösung aus
dem lebenden Ortsowner neu projizieren. Die vorherige Sternkarten-/Basisansicht
bleibt erhalten; eine entfernte andere Missionsansicht fällt auf deren schwarze
Ortsinspektion zurück. Regression: freigegebene Referenz, lebender Ersatz,
aktuelle Planung und unveränderte Gameplayowner, danach fünf echte Ausflüge.

Abschluss und Mainintegration erfolgen erst nach den zugehörigen Regressionen.
Fehlversuche und verworfene Fixtures bleiben in der Evidenz nachvollziehbar.

## Ergänzung: sichtbare Hexoberflächen und Kenney-Anschlüsse

Nutzeranforderung im laufenden Review: Kenney-Zellmodule müssen zur Hexbasis
passen. Das sichtbare Hexfeld muss auch auf Hügeln, Rampen, Pads, Brücken und
anderen begehbaren Deckflächen ihrer tatsächlichen Oberfläche folgen. Bisherige
Konturen können in erhöhten Modellböden verschwinden; nichtregionale Rampen
verwenden noch einen flachen Rasterpfad. Das erschwert die Feld-/Höhenlesbarkeit.

Umfang: Kenney-Boden-/Deckmodule gezielt auf sechseckige Fußabdrücke projizieren;
verbundene Wand-/Tür-/Korridormodule behalten ihre gemeinsame axiale Basis.
Raster aus vorhandener
Terrain-/Registrywahrheit auf vorhandene Höhen-/Rampen-/Deckdarstellung projizieren.
Blockierte und unbekannte Zellen nicht als verfügbare Felder kennzeichnen.
Konturen bleiben tiefengeprüfte Leseschicht, ohne Pathing-/LOS-/Kollisionsmutation,
neue Gameplayzustände, Austausch von Binärmodellen oder Neugestaltung der Schiffe.
Vorhandene Chunk-/Dirtywege wiederverwenden; kein Meshaufbau pro Frame.

Contracts: terrain_truth_visual_audit_contract.md, hex_tactical_runtime_contract.md,
graphics_reference_revision_contract.md. Betroffen: TerrainMap3DView, enger
Rasterprojektionshelper/Materialpfad sowie eigene Regression-/Capturefixtures.
Akzeptanz: gleiche Hexgeometrie auf H0/Höhe, sechs Rampenrichtungen, tatsächliche
Kenneyboden-/Pad-/Brückenhöhe, unverdeckte sichtbare Konturen bei gleichem Renderer,
keine freigegebenen Blocker-/Fogfelder und stabile Mesh-/Refreshzähler bei
unverändertem Kontext. Native Vergleichsbilder werden geöffnet; Enginejobs führt
weiterhin nur der koordinierte serielle Runner im privaten Desktop aus.

### Nutzerkorrektur: keine dicken weißen Hexknöpfe

Die Station64-Aufnahme `hex_surface_after/985bbe319b1a4c07a5394c4279e55e12`
wurde ausdrücklich wegen der dicken weißen Bodenklumpen abgelehnt. Technisch
korrekte Hexbounds ersetzen diese visuelle Akzeptanz nicht. Die bisherige
Darstellung ist kein freigegebenes Zielbild.

Die vorhandenen zellgebundenen Floor-/Balcony-/Deckmodule werden deshalb gezielt
als flache zusammenhängende HELLE Metallflächen mit gedeckten Strukturakzenten und dünnen Fugen
projiziert. Die abgeleitete Modellhöhe darf vereinheitlicht werden; echte
Terrainhöhen und Rampen bleiben unverändert. Original-Binärressourcen, Textur-
und UV-Quellen bleiben erhalten. Kein Flachziehen von Figuren, Schiffen, Möbeln,
Wänden oder eigenständigen Gebäuden. Betroffen: HexFloorModelAdapter,
TerrainMap3DView und die vorhandenen Surface-/Stationverifier und Capturefixtures.

Akzeptanz: begrenzte dünne Modellauflage, unveränderte logische Höhen, gleiche
Footprints und Anschlüsse, gedämpfte gemeinsame Metallroute ohne Original-
Materialmutation, korrekte Figuren-/Konturstützhöhe und gecachte Wiederverwendung.
Dieselben nativen Station64-/GM02-/Kenneykameras vor und nach der Revision öffnen.
Keine optische Abnahme aus Assertions ableiten; Restbefunde sichtbar festhalten.

Weitere verbindliche Nutzerkorrektur: Der dunkle KI-Entwurf ist nicht akzeptiert.
Das weiße Lagerhaus unten rechts samt Winkel ist die positive Referenz und bleibt
unverändert. Stationsmodule sollen keine axiale Meshscherung zeigen: ihre
tatsächlichen Reihen bleiben am Hexlayout, die lokale Körperform wird orthogonal
entlang dieser Reihen orientiert. Echte Hexlinien bleiben auch außerhalb der
Station sichtbar. Bäume gehören nicht in dieses authored Wüstenszenario;
vorhandene Wüstengesteine ersetzen dort ausschließlich die Visualprojektion,
während Blocker-/Cover-/Terrainzustand erhalten bleibt. Kein globaler Austausch
der Vegetation auf anderen Karten und keine Verdunkelung der gesamten Station.

## Erweiterung im laufenden Auftrag

### Weitere native Grafiksteuerung: Materialruhe, Orientierung, Bruchstein

Die Nutzerkritik am Stationsbild verlangt ruhige helle Decks ohne kontrastreiche
Keksmuster, dauerhaft erkennbare Hexkonturen und eine konsistente rost-/ockerfarbene
aride Steinfamilie. Weiße Deckungssteine und regelmäßige identische Baumersatzsteine
werden als reine Darstellung korrigiert; jedes logische Hindernis bleibt sichtbar
und behält Registry-/LOS-/Deckungsfakten. Keine neuen Bodenflecken hinzufügen.
Kamera, weißes Lagerhaus und dessen Perspektive bleiben unverändert. Der Unterschied
zwischen axialen 60-Grad-Wandreihen und rechtwinkligem Lagerhaus ist rechnerisch
zu prüfen; keine Wand neben ihre autoritative Blockerzelle verschieben. Falls nötig,
migriert der Contentowner ein begrenztes Stationsensemble samt Tür-/Markerbindings.

Die rechte Variante von `cliff_detail_proposal.png` ist ausdrücklich als Richtung
freigegeben: gebrochene Sandsteinfacetten und wenige kleine Geröllstücke am
bestehenden Fuß. Höhen, Außenkanten, Rampen, begehbare Oberseiten und Gameplaydaten
bleiben erhalten. Die neue Form entsteht ausschließlich im statischen Chunkmesh
mit geteiltem Material, ohne Gameplay-RNG oder Streuung pro Frame. Native gleiche
Kamera vor/nachher sowie Bounds-, Kanten-, Determinismus- und Cachetests sind nötig.
Betroffen: enge Terrainvisualhelper, FrontierArtProfile, Shader und Grafikverifier.
Technische isolierte Szenen bleiben QA-Nachweise, keine akzeptierten Designbeispiele.

Die Nutzersteuerung zu Sternkarte/Smart Mobile vom 13.11.2026 wird im selben
Durchlauf umgesetzt: aufklappbare System-/Planeten-/Mond-/Ortshierarchie,
wirklich verfügbare oder erledigte Missionen, individuelle Anzeigenamen und
kompakte Star-Citizen-/RTS-inspirierte Controls mit erhaltenen farbigen Bildern.
Konkrete Akzeptanz und Save-/Performancegrenzen stehen in
STARMAP_SMART_MOBILE_2026_11_13.md sowie
docs/dev/starmap_smart_mobile_contract.md. Drei Bild-KI-Revisionen und offizielle
Vorlagen sind im QA-Paket nachvollziehbar. Dies ist eine ausdrücklich
angeforderte Erweiterung, keine stillschweigende globale UI-Neugestaltung.

### Aktuelle native Stationskorrektur nach freigegebenem Wandwinkel

Die tatsächlichen Warehouse-/Stationsachsen im Kandidaten 735118e sind vom Nutzer
akzeptiert und bleiben erhalten. Der praktische Kenney-Subset umfasst helle Wände,
Tore, passende Ecken und dünne Böden, dazu vorhandene Raumprops. Keine Anpassung
des ganzen Katalogs oder Kenney-Hügelmigration. Authored Rohre entfernt der
Contentowner konsistent einschließlich ihrer Objektblocker. Die grüne
Patrouillen-Authoringlinie gehört nicht in die normale Spielansicht.

Floors müssen auch unter Wänden und Raumprops sichtbar bleiben; ein Objekt darf
den authored Floor-type_id nicht verdrängen. Baugrenzen sollen bei Bedarf eine
Hexbodenfläche teilen. Wandfugen, Eckverbinder und Türpositionen werden eng am
bereits freigegebenen Winkel korrigiert. Gesteinsformen sind akzeptiert, zusätzliche
kleine reine Geröll-Deko darf keine Collision/LOS/Cover besitzen. Die aktuell
hellen Bodenflecken ausdrücklich vorerst erhalten. Prüfung erfolgt über dieselbe
native Stationskamera, echte Floor-/Wand-/Türbounds und unveränderte Gameplaydaten;
keine optische Abnahme allein aus technischen Assertions.

Die vollständige Station192-Prüfung erfasst neun aktive Ensembles mit zusammen
684 Wand-/Türmodulen. Nur 76 zentrale Module waren zuerst gebunden; die acht
äußeren Regionen werden separat vom Contentowner bijektiv migriert und von der
Darstellung anhand derselben expliziten `regions` gelesen. Authored
`floor_boundary` trennt nur die Farben der vorhandenen dünnen Bodenauflage an
Außenwand-Mittellinien; Geometrie und visuelle Stützhöhe bleiben erhalten.
Zusätzliche Gates: `review_completion_station_building_verifier.gd` (reale
Wandanschlüsse, Türsturz/Blatt, Doorowner/Cachehandoff, alle Bodenmaterialrouten),
`review_completion_station_ensembles_capture.gd` (echte zentrale und gedrehte
äußere Ensembles) und `review_completion_station_shadow_capture.gd` (gleiche
Kamera, Side-Caster gegen frühere Vollsäule und schattenlose Diagnosekontrolle).

### Echte Home-Meilensteine und Exportdiagnostik
Five-Lauf4d07 beendete drei reale Heimkehren, scheiterte beim ersten Export nach dem Autosaveintervall jedoch mit verschlucktem Ownergrund (`runtime_unavailable`). Die vorherigen Meilensteine waren nur gedrosselte `ok`-Antworten; die unveränderte private Datei enthält ausschließlich den Anfangsstand (SHA2565c494ef267d5ea1e81527f91a7db551f1ec50fc23d4c2c941a9023b7b3ff917f). Der Verifier verwendet deshalb an expliziten Meilensteinen den vorhandenen manuellen Force-Savepfad und liest die tatsächlich geschriebenen Job-/Roster-/Flottendaten zurück. Bei Fehler werden aktuelle Root-, Movement- und Base-Exportgründe rein lesend protokolliert. Keine Status-/Checkpoint-/Gameplayguards werden gelockert; ein Produktfix benötigt den konkreten Ownerbefund.

#### Bestätigter Rekrutierungs-/Transportfehler
Der echte Force-Save-Lauf d054 scheitert nach Außenposten-Heimkehr an `base_checkpoint_aboard_context`: Der registrierte Rekrut ist an Bord, aber nicht Mitglied des geladenen Payload-Trupps. Korrektur ausschließlich im vorhandenen Rekrutierungs-/Roster-Handoff; der Checkpointguard bleibt unverändert. Akzeptanz: tatsächlicher Schiffstransport und Trupp stimmen überein, andere Teams bleiben unverändert, Wiederholung dupliziert nichts, separater Fighterpilot bleibt Pilot. Enge echte Ownerfixture plus vollständige Five-Sequenz mit erzwungenem Save/Dateireload und Continue sichern den Weg; keine frei erfundene Saveberechtigung aus bloßer Rosterexistenz.

#### Verbleibender vierter Anmarsch: enge Diagnose
Nach dem Rekrutierungsfix besteht der gezielte echte Ownerfall 23/0. FullFive efdc erreicht drei tatsächliche Heimkehren mit jeweils erzwungenem Save und Dateireload, endet aber 198/1 im unveränderten 60s-Anmarsch-/Kampfwait des vierten Auftrags (9055 Weltpixel). Der nächste Diagnoselauf protokolliert deshalb alle fünf Sekunden echte Actor-/Rootbewegung und Gegnerleben, ohne das Zeitbudget zu erhöhen. `campaign_post_benit_continue_verifier.gd` lädt ausschließlich das bytegleiche echte dritte Homeartefakt (SHA354a4a9f6841b51a8d906878c2b263e6cbb55136cbd9939dfdac7ca038c5e789) über normales Continue in ein isoliertes Profil und erwartet ausdrücklich zwei weitere Heimkehren. Quelle und Herkunft stehen unter `post_benit_source`; dieser Diagnosefall zählt nicht als weitere vollständige Fünf-Ausflüge-Abnahme.

#### Belegtes Bewegungsziel
Ein stationaer belegtes Ziel darf keine aussichtslose Vollkartensuche starten. Der bestehende Bewegungsowner behaelt Intent und Token, wartet ohne Navigationsexpansion und plant nach Freigabe regulaer neu. Regression: zwei echte Root-Actors, unveraenderter Blocker, keine Ueberlappung, echte Zielankunft nach Release. Keine erfundene Zielposition oder Timeoutlockerung.

Formationsziele auf fremd belegten Hexfeldern werden vor Commandausgabe ueber den bestehenden Root-Approach auf freie Nachbarfelder aufgeloest. Freie Mitgliedsziele und bereits vergebene Ziele bleiben ausgeschlossen; keine Ueberlappung oder Verschiebung fremder Actors. Der echte 60s-Trace belegt ~87 Felder Leaderfortschritt bei ~125 Feldern Anmarsch; die Fixture trennt deshalb Anmarsch (180s) vom anschliessenden Kampf (60s).
