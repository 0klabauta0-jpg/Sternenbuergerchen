# AP5: echte Hex-Move-Absichten im Ortsruntime

Ziel: Vorhandene Root-Movebefehle dürfen hinter `hex_tactical_v1` nicht mehr
den Actor durch Legacy-Avoidance bewegen. Ein Root-eigener Runtimebaustein
verwaltet angenommene Bewegungsabsichten, deren abgeleitete Navigation und
Ankunft; Ground bleibt alleinige Zell-/Zusage-/Bewegungsphasenwahrheit.
Basis d00eba780, keine aktive Karte und keine Main-/EXEänderung.

Verträge: hex_tactical_runtime_contract.md, hex_reservation_plan_contract.md,
explicit_hex_ramps_contract.md, AP5 sowie HEX_RESERVED_MOVEMENT_2026_11_11.md.
Dateien: neuer HexMovementCommandRuntime, SimulationRoot, schmale Groundreads/
Startphasenereignisse, TerrainPathfinder für temporäre autoritative Blocker,
kleiner tatsächlicher Root-/UnitRegistry-/Actor-Verifier. Späterer Anschluss
von FireteamMovementController und View bleibt eigener überprüfbarer Schritt.

Absichtsvertrag: Ziel wird auf das gewünschte Hex bezogen; Root hält ein
angenommenes Ziel bis tatsächlicher Ankunft, explizitem Hold/Auftragswechsel,
Verwundung oder Lifecycleende. `requeue_until_target` ist im Hexpfad nur der
alte Queuehinweis, keine Framebewegung. Der Hexruntime führt das Ziel selbst
weiter und kopiert keine Weltpfade in eine eigene Requeue pro Frame.
UnitCommand bleibt der vom Root angewendete Auftrags-/Profilkontext; der neue
Baustein besitzt Planung/Ankunft desselben angenommenen Ziels, keinen zweiten
Unitstandort, Skill-/Vitalwert oder UIzustand. Legacyweg bleibt unverändert.

Akzeptanz in kleinen Schritten:
- Echte enqueue_command→Physics→Ownerzusagen→Actorprojektion, höchstens zwölf
  Felder, langsamere Führung und Folgefigur, keine doppelte logische Belegung.
- Gecachte inkrementelle Hexnavigation, vorhandener96-Expansions-/4Jobrahmen,
  höchstens16 neue Reservierungsanfragen mit drei Übergängen. Stehende/verwundete
  Groundfiguren als temporäre Navblocker; gemeinsame bewegte Abfahrten weiter
  durch den atomaren Planer. Keine dauernde Neusuche bei unverändertem Blocker.
- Physisches Registryhexmaß statt Bildschirmdistanz; vorhandene Geschwindigkeits-
  und Profilschnittstellen, Terrainzeit aus beiden halben Oberflächen. Dauer
  zugesagter Segmente bleibt bis sicherem Stopp erhalten. Keine neue XPformel.
- Folgehorizont vor Segmentende zusagen, tatsächliche Ankunft erst nach letzter
  Kante/Zentrierphase. Reine Readout-/Ankunftsgetter ändern keinen Zustand.
- Neues Ziel/Hold/Wunde stoppt Abhängigkeiten gemeinsam; Wiederholung desselben
  Zielauftrags startet weder Suche noch Zusage neu. Unsichtbarer Ort tickt weiter.
- Aktive Hexfiguren aus Legacy-Mindestabstand, Avoidance und Legacy-Passageplaner
  ausschließen. 2DActorposition und Metadaten sind reine Groundprojektion.
  3DView folgt separat und muss bestehende Mappinghöhe lesen.
- Fehlende Zulassung, falsche Autorität und ungültige Eingaben fallen geschlossen
  aus; kein Rückfall auf Renderposition oder einen fremden Ortsruntime.

Nichtziele: neue große Karte/aktivierter Modus, echte Mehrort-UI/Servicearbeit
des koordinierenden Chats, fertige Save-/Netzwerkfreigabe oder große Tests.
Bewegungsschussabzug/Profilgetter und Türmutationsguard folgen in abgestimmten
engen Schritten, bevor AP5 als vollständig angeschlossen gilt.

Prüfung: kleiner isolierter `movement`-Case, dann nur betroffene Owner-/Stop-/
Projektionsnachbarn und frischer Review. Keine native Framerate-/Spielgefühl-
abnahme. Risiken: vorläufige Zielslot-/Rücksetzpolitik und neue private Ziele
müssen AP6/7/8 samt tatsächlicher UI-/Lebenszyklus-/Restoreanbindung mitführen.

Ergebnis dieses Schritts: Moveadapter, 2DProjektion, tatsächliche Hold-/Damage-
Producer, logische Captureposition und Ankunft angeschlossen. Bewegung42/0;
Owner56/0, Stop34/0, Projektion56/0, Facing24/0, Security34/0, Consumers39/0,
ReservationOwner36/0, Korridor15/0. Quellen-/Profil-/Canaryguards grün,
frischer enger Review ohne verbleibende Befunde. QA hex_move_commands_20261111.
Die oben genannten Folgeanschlüsse bleiben ausdrücklich offen.
