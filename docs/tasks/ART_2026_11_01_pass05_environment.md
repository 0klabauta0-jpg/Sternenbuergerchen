# ART Pass05 Umgebung: bewohnter Aussenposten statt steriler Assetaufstellung

## Ziel / Anlass
Der Nutzer verlangt einen erneuten direkten 2D/Ist-Vergleich und danach einen
weiteren Grafikpass fuer Gebaeude, Boden, Felsen und Umgebung. Pass04 ist
technisch sauber, wirkt aber weiter steril und deutlich vorlagenfern.
Schiffe bleiben ausschliesslich bei der separaten Astra-Ultra-Modellarbeit.

## Beobachtete Ursache / gestalterische Entscheidung
Verglichen: Rostgrenze-Cutaway, Freihafen-Distributionszentrum, taktische
Uebersicht und native Pass04 closed_outpost/landscape/closed_hall.
1. Zwei fast gleiche Kasten-/Dachsilhouetten, geringe mittlere Formenstaffelung.
2. Gleichmaessig leere Bodenflaechen und abrupte Objekt-/Bodenkontakte; fehlende
   Geröllsaeume, Staub, Fahr-/Laufspuren und unterschiedlich grosse Ablagerungen.
3. Wiederholte horizontale Felsbaender/gerade Grossflaechen statt lokaler Brueche.
4. Gleichmaessige Assetverteilung und Crew-Reihe statt funktionaler Arbeitsgruppen.
5. Gleich helle unbenutzte Flaechen; wenig Material-/Farbgewicht und lokales Licht.

Gewaehlter Ansatz: zusammenhaengende Form-, Material- und Gebrauchshierarchie.
Nur mehr Nieten/Kisten behebt die Hauptursachen nicht; eine reine globale
Lichtaenderung allein ebenfalls nicht. Mittlere Formen und Bodenanschluesse
zuerst, danach wenige begruendete kleine Gebrauchsspuren. Keine neue Simulation.

## Umfang / Nicht-Ziele
- Gebaeude klarer unterscheiden: versetzte Dachtechnik, lesbare Vorzonen,
  Fassaden-/Sockelstaffelung, sparsame warme Eingangs-/Fensterakzente.
- Neue gebrochene Felsformen innerhalb bestehender konservativer Navhuellen;
  weniger wiederholte Baender, bessere Gross-/Mittel-/Klein-Hierarchie.
- Staub-/Sedimentfelder, lokale Spuren und Geröll-/Vegetationsgruppen gezielt
  an Bau-/Felskontakten. Wege weiterhin klar und begehbare Zentren frei.
- Wenige funktionale Arbeitsgruppen statt zufaelliger Dekoration, vorhandene
  vier Citizens sinnvoller angeordnet; keine neue KI, Wirtschaft oder Statistenlogik.
- Vergleichsanalyse, neue reale native Aufnahmen und aktualisierte Offline-HTML.
- Keine Schiffsaenderungen, Figuren-Neumodellierung, Kampagnen-/Editor-Migration,
  Innenraum-/Tormechanik, Architektur-/Topologieaenderung oder neue Abhaengigkeiten.

## Arbeitsbasis / Contracts
Fortsetzung des bewusst unintegrierten Branches task/grafikreferenzen-20261101,
Ausgang fbcac03d1. Astra-Ausgaben pass05_astra_ultra unangetastet lassen.
docs/PROJECT_BRIEF.md, ARCHITECTURE.md, CODEX_RULES.md;
docs/dev/graphics_reference_revision_contract.md,
html_report_workbench_contract.md, hex_grid_v1_contract.md.

## Betroffene Dateien / Besitz
Gebaeude: frontier_closed_buildings.gd; Felsen: frontier_art_geology.gd;
Root: Dressing-/Kontaktflaechen, Ground-Shader, Preview/Captures/Verifier;
Report: Analyse, Workbench/Quellbelege/BrowserQA. Source-/Exportpfade der
Kenney-/Citizen-/Schiffs-GLBs bleiben unveraendert und hashgeprueft.

## Akzeptanz und lokale Pruefung
- Vorlagen und Ist-Bilder tatsaechlich geoeffnet; Befunde mit Bildzuordnung
  und umgesetzten sowie weiterhin offenen Unterschieden dokumentiert.
- Neue Gebaeude-/Gelaendeformen aus Spielabstand sichtbar unterschiedlich;
  keine Wiederholung als blosse Detailanzahlsteigerung ausgeben.
- Drei geschlossene/offene Sichten, Boden-/Felsdetails sowie gleiche feste
  Vorher/Nachher-Kameras zeigen. Licht unveraendert halten fuer direkte Paare;
  zusaetzliche bewusste Lookdev-Aenderungen getrennt kennzeichnen.
- Endliche Geometrie/Normalen, keine schwebenden Teile, Z-Fights oder neuen
  Hindernisse auf begehbaren Zentren. Neue solide Props vor Registry-Aufbau
  durch deklarierte Huellen reservieren; reine Bodenspuren besitzen keine Fakten.
- C-Umschalter, Hex-Picking und SimulationRoot-Bewegung weiter pruefen.
- Offline-Workbench mit eigener Pass05-Notiznamespace/JSON-Export frisch
  Desktop/Mobil pruefen; Pass04-Bericht/Bilder bytegleich archivieren.
- Technische Pruefung, sichtbarer Fortschritt und Nutzerurteil getrennt;
  verbleibende Referenzabweichungen offen nennen. Relevante Commits pushen.

## Risiken / offene Punkte
Mehr Dekoration kann nur anderes Rauschen erzeugen. Funktionsgruppen und freie
Flaechen brauchen deshalb klare Hierarchie. Detailgeometrie wird einmalig gebaut,
Material-/Meshinstanzen geteilt oder gebatcht; keine SceneTree-Scans im Hotpath.
Referenzen sind reichere Illustrationen, keine Behauptung identischer Runtime-
Qualitaet oder allgemeiner Art-/Performance-/Release-Abnahme.

## Umgesetzter und lokal gepruefter Stand
- Gebaeude: Habitat2588/Halle2508Tris, eigeneGeometrie21/21; bewusst andere
  Dach-/Portal-/Sockelhierarchie, keine neuen Licht-/Tor-/Innenraumzustaende.
- Geologie54Meshes/23112Vertices;14alteNavhuellen mitmax0.95MikrometerDelta,
  lokaleSpalten/ungleicheAbsätze/abgestufterTalus;12/12Geometrievertrag.
- Drei Arbeitsgruppen mitdreiOriginalKenneyProps (Instanzmaterialien warm
  getoent, GLB/UV/Atlas/Lizenzdateien hashgleich), Tisch/TerminalmitAuflage,
  Lieferpallet/Versorgungsschlauch, begrenzter niedrigerGeröll-MultiMesh.
- Vier alteCitizens aufdreiTiefen undmitpassenderenBlickrichtungen, keine neueKI.
- Opaque Weg-/Apronmaterialroute mitlokalenFahrspuren, Soilkontaktlayer beiY.004
  unterApronTop.006 (kein koplanarer Ueberzug), neununveraendertePaarkameras.
- 18/18strengeGodot-PrueflaeufePASS, neueUmgebungspruefung19/19;20native
  Forward+/Vulkan-PNGs, drei neueDetailkameras ohnevorgetaeuschtesVorherbild.
- NativeBilderdurchRootundunabhaengiggeoeffnet: keinekonkretenneuen
  Platzierungs-/Normalen-/Ueberlappungsblocker; keinegestalterischeFreigabe.
- OffenerZielabstand: ebenerBoden, grobePlateaus/ruhigeFelsrueckseiten,
  kompakteGebaeudemasse, wenigerMaterialabrieb/GebrauchsdichtealsIllustration.
  BerichtenthaeltAnalysedirektmitBildzuordnungstattallgemeinerDetailaufforderung.

FinaleOffline-HTML:297/297frischeBrowserchecks,111Bilder/222Decodes,
38automatischeScreenshots+5Sichtnachweise,2echteJSONexports. P4Archiv
bytegleich, eigenerP5Speicherbereich, keine Nutzer-Artabnahme behauptet.
