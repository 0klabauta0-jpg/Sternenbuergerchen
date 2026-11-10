# Kampagnenersatz: Absturzursache und Quellpruefung

Stand 10.11.2026: Der Quellfix ist gezielt headless und nativ auf D3D12
geprueft. **Eine neue exportierte EXE ist noch nicht gebaut oder geprueft.**
Die Releaseabnahme bleibt ein eigenes offenes Gate.

## Ausgang und Reproduktion

Arbeitsbasis ist Main `ee0591cfedb4d28a01788defdcf23d98439d49ad`, geaendert
auf `task/campaign-replace-crash-20261110`. Die untenstehenden Quelllaeufe
pruefen den eingefrorenen Produktpatch in diesem Branch, keinen bereits
veroeffentlichten Fixcommit. Godot: `4.6.2.stable.official.71f334935`.

Der Nutzer meldete einen Absturz des Pakets
`C:/dev/SternenBuergerchen-builds/2026-11-10-orbit-base-main-r01/`
bei Neue Kampagne -> Kampagne ersetzen. Dessen Logs enthalten die Folge
Mipanforderung 5 bei maximal 4 -> ungueltige Textur/RID -> null Uniformset.
Die vorhandene alte Menuepruefung ueberschrieb die Szenenroute und konnte
den anschliessenden echten Basisrenderer deshalb nicht absichern.

Die tatsaechliche r01-EXE wurde separat mit privatem Profil und dem vorhandenen
`--release-singleplayer`-Deeplink gestartet. Sie stuerzte unter D3D12 mit
Exit `-1073741819` (`0xc0000005`) und denselben sieben Rendererfehlern ab.
Dieser EXE-Lauf reproduziert den gemeinsamen Basisrenderer, nicht den gesamten
Kampagnenersatz per Menue. Belege:
[Metadaten](raw/campaign_replace_old_release_gpu_red.json),
[EXE-Log](raw/campaign_replace_old_release_gpu_red.log).

Alle hier dokumentierten GPU-Laeufe verwenden D3D12/Forward+ auf einer
NVIDIA GeForce RTX 4070 Ti SUPER. Godot ist ueber `--wid`/`--single-window`
in einen verborgenen Win32-Elternhost eingebettet; die Metadaten bestaetigen
`hidden_parent_visible=false`. Die Testprofile liegen getrennt unter dem
Projekt-`output/`; persoenliche Saves wurden nicht beschrieben.

## Belegte Ursache

Beim ersten Layout ist das berechnete Vorschaurechteck noch leer. Der
`PanelContainer` liefert trotzdem sein Style-Mindestmass von 16x12 Pixeln.
Die vorherige Positivgroessenpruefung wertete dieses Mass als gueltige
3D-Vorschau. Die absolute Basisansicht kopierte es, ohne dem spaeteren
Layout synchron zu folgen. Das betraf Erststart, Kampagnenersatz und
Fortsetzen. Der lokale Prozesszweig der statischen Padvorschau ist deaktiviert;
seine normale per-frame-Groessenanpassung konnte das nicht rechtzeitig heilen.

Zusaetzlich besitzt bei `SubViewportContainer.stretch` der Container die
tatsaechliche Renderallokation. Eine direkte Groessenzuweisung am inneren
`SubViewport` ersetzt diesen Owner nicht. Das Ergebnis waren aktive
SSAO-Kameraziele von 16x12 Pixeln. Der native echte Menue-/OK-/Szenenlauf vor
dem Fix erfasste sechs unsichere Samples und endete mit 83 bestandenen und
12 fehlgeschlagenen Assertions sowie den passenden Rendererfehlern:
[Metadaten](raw/campaign_replace_menu_gpu_red.json),
[Quell-RED](raw/campaign_replace_menu_gpu_red.log).

Der minimale GPU-Kontrollversuch isoliert die Groessengrenze:

| Unveraenderte SSAO-Konfiguration, nur Zielgroesse anders | Exit | Rendererfehler | Warnungen |
| --- | ---: | ---: | ---: |
| [16x16](raw/campaign_replace_tiny_ssao_red.json) / [Log](raw/campaign_replace_tiny_ssao_red.log) | 0 | 133 | 0 |
| [32x32](raw/campaign_replace_ssao_32_probe.json) / [Log](raw/campaign_replace_ssao_32_probe.log) | 0 | 0 | 0 |

Exit 0 allein reicht somit nicht als Erfolgskriterium. Die fuenf Mipstufen
des halbierten SSR/SSAO-Puffers verlangen mindestens 32 Pixel pro voller
Zielachse. 32x32 ist eine Sicherheitsuntergrenze, keine dauerhafte
Vorschauaufloesung.

## Produktkorrektur

- `homebase_operations_presenter.gd` verwendet das tatsaechlich berechnete
  Layoutrechteck und aktiviert die Padvorschau erst ab mindestens 32 Pixeln
  je Achse. Die Basisflaeche folgt sowohl Layout- als auch Snapshotupdates
  synchron; das Panel-Style-Mindestmass gilt nicht mehr als Layoutbeleg.
- `terrain_map_3d_view.gd` sichert den streckenden Container schon vor dem
  Einhaengen mit mindestens 32x32 und `stretch_shrink=1`. Normale Flaechen
  werden weiterhin vollstaendig in 1:1-Aufloesung genutzt. Ein eigener
  Parent-Viewport-`size_changed`-Callback synchronisiert die Geometrie auch
  bei deaktiviertem Prozesszweig und fordert dann genau ein Neuzeichnen an.
  Auch weitere Redraw-Anforderungen starten bei deaktiviertem Prozess keine
  Dauerzeichnung.

SSAO bleibt aktiviert. Save-/Kampagnenregeln und die autoritative gemeinsame
Basissimulation wurden fuer diesen Fix nicht geaendert.

## Finale Quelltests

| Pruefung | Ergebnis | Beleg |
| --- | --- | --- |
| Echter Menueweg, native D3D12-Quelle | 89/0; Exit 0, Fehler 0 | [Metadaten](raw/campaign_replace_menu_gpu_final.json), [Log](raw/campaign_replace_menu_gpu_final.log) |
| Derselbe echte Menueweg, headless | 88/0; Exit 0, Fehler 0 | [Log](raw/headless_final/campaign_replace_render_verifier.log) |
| Rendergroessenowner ohne Kartenmesh | 18/0; Exit 0, Fehler 0 | [Log](raw/headless_final/terrain_render_target_size_verifier.log) |
| Schiffs-/Shared-Sim-Vorschau | 37/0; Exit 0, Fehler 0 | [Log](raw/headless_final/ui_regressions/ship_context_preview_verifier.log) |
| Echte Basis-Weltbedienung | 9/0; Exit 0, Fehler 0 | [Log](raw/headless_final/ui_regressions/base_personnel_world_ui_test.log) |
| Kampagnen-Abflug und Overlaybedienbarkeit | 42/0; Exit 0, Fehler 0 | [Log](raw/headless_final/ui_regressions/campaign_launch_actionability_verifier.log) |

Der neue `campaign_replace_render_verifier.gd` nutzt die echte
`SceneTree.current_scene`, den Campaign-Button und die jeweiligen
`ConfirmationDialog.get_ok_button()`-/Cancel-Buttons. Er prueft Start ohne
Datei, einen gueltigen unterscheidbaren Loadout-Checkpoint, unveraenderte
Dateibytes bei Abbrechen, bestaetigten Ersatz durch genau zwei neue
Kampagnenpersonen, gueltigen neuen Basischeckpoint und anschliessendes
echtes Fortsetzen. Ansichtswechsel erfolgen ueber die vorhandenen
Navigationsbuttons. Die Szenenroute wird nicht ersetzt.

Der finale native Lauf erfasst 117 `RenderingServer.frame_pre_draw`-Signale,
219 aktive Kamera-/SSAO-Samples und **0 unsichere Ziele**. Erststart, Ersatz
und Fortsetzen verwenden jeweils 578x650 statt 16x12; die begehbare Basis
1710x944, die Abflugansicht 780x650. Das innere Ziel folgt jeweils der
aeusseren sichtbaren Flaeche. Die sechs Warnungen sind ausschliesslich die
bekannten UID-Textpfad-Fallbacks der beiden Homebase-Szenenskripte bei den
drei Szenenladungen. Keine Renderer-/Scriptfehler oder Leakwarnungen im
finalen GPU-Log.

Headless liefert keine `frame_pre_draw`-Signale und ist hier nur State- und
Szenenbeleg. Der zusaetzliche `terrain_render_target_size_verifier.gd` prueft
ohne manuelle Resize-/Redraw-Aufrufe: 16x16 -> 32x32 vor dem ersten Frame,
danach exakt 1280x720 und 1920x1080, einzelne schmale/kurze Achsen sowie
Rueckkehr auf 32x32. Groessenwechsel wirken synchron trotz deaktiviertem
Ancestor, mit `UPDATE_ONCE` statt Dauerzeichnung und weiterhin aktivem SSAO.

Die finalen Headless-Logs und Resultate wurden unveraendert aus
`docs/qa/orbit_quantum_20261109/raw/campaign_replace_final_green/` und
`campaign_replace_final_ui_regressions/` nach `raw/headless_final/` bzw.
`raw/headless_final/ui_regressions/` kopiert; SHA256 aller sieben Kopien
stimmt mit der jeweiligen Quelle ueberein. Die kopierten `results.json`
behalten ihre urspruenglichen absoluten Log-/Profilpfade als Herkunft:
[Kernresultate](raw/headless_final/results.json),
[UI-Resultate](raw/headless_final/ui_regressions/results.json).

## Reproduktion und Quellidentitaet

[source_hashes.json](source_hashes.json) identifiziert die beiden Produkt-
und die beiden neuen Testdateien des geprueften eingefrorenen Standes.
Der parametrierte [GPU-Runner](tools/run_hidden_gpu.ps1) und die beiden
minimalen [16x16-](tools/tiny_ssao_repro.gd) und
[32x32-Proben](tools/safe_ssao_probe.gd) sind im QA-Ordner erhalten.
Der Runner verwendet standardmaessig das Repository als SourceRoot;
ProjectPath/MainPack erlauben spaeter eine getrennte PCK-Probe.
EvidenceRoot und ProfileRoot koennen getrennt angegeben werden. Fuer den
Menueverifier ist ein frisches privates Profil erforderlich, dessen
APPDATA-Pfad `campaign_replace` enthaelt.

Beispiel fuer einen erneuten Quelllauf mit neuem Profilnamen:

```powershell
& docs/qa/campaign_replace_crash_20261110/tools/run_hidden_gpu.ps1 `
  -Script res://scripts/tests/campaign_replace_render_verifier.gd `
  -Label campaign_replace_menu_recheck -TimeoutSeconds 180
```

Die begleitende Nutzercheckpoint-Kontrolle blieb unveraendert:
7173 Bytes, LastWriteTime `2026-11-09T23:36:11.5121966+01:00`.

## Offenes Releasegate

Diese Belege geben den gezielten **Quellfix** frei. Sie sind keine Abnahme
einer neu exportierten EXE und keine allgemeine Grafik-/Performancefreigabe.
Die alte r01-EXE bleibt als fehlerhafter Vergleichskandidat unveraendert.

Ausstehend sind der dokumentierte Commit/Main-/Pushabschluss, Export aus
dem identischen geprueften sauberen Main sowie eine native Start-/Basisprobe
der **neuen** EXE mit privatem Profil. Der vorhandene
`--release-singleplayer`-Deeplink kann deren gemeinsamen Basisrenderer
absichern; eine solche Probe ersetzt keine behauptete Menuebedienung.
Commit, Remote-HEAD, EXE-/PCK-Identitaet und tatsaechliche Releaseergebnisse
gehoeren in den kuenftigen externen Paketbericht
`C:/dev/SternenBuergerchen-builds/2026-11-10-campaign-replace-fix-main-r02/PRUEFBERICHT.md`.
Dieses neue Paket ist in diesem Quell-QA-Stand noch nicht gebaut oder geprueft.
