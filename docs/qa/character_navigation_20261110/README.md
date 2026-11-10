# Charakterdetails und Navigation
Aufbau auf noch nicht integriertem5df2d3b6f (Mainbasis1e3cca237).
Doppelbutton entfernt, Tankservice unter Flugdeck. Details nutzen Viewporthöhe,
bis1500px Breite. Stärkste Eignung und Herkunftskarte je halbe Spalte. Zwei
kompakte Wertespalten, unabhängige Fahrzeug-/Herleitungszweige, vertikale Hoverfaktoren.

Ganzkörper-Vorschau projiziert den tatsächlichen Basisactor mit dem vorhandenen
Terrain-Visualresolver (Modell, Skin und vorhandenes Loadout). Keine Meshänderung,
keine individuellen Porträtgesichter auf neue Modelle übertragen. Modellprozess
deaktiviert, SubViewport rendert bei Änderungen/Sichtbarkeit einmal. Slots am
Torso/an Hüften rufen vorhandene Inventarbefehle auf. Basislager war bereits freier
Bestand; keine erneute Subtraktion getragener Items. Frei-Kennzeichnung ergänzt.

Nativ D3D12:26/0, Enginefehler0, zwei vorhandene UID-Pfadfallbackwarnungen.
Logische Viewports1280/1920/3440, hidden host1280x720, aspect-ignore explizit im
Verifier; keine Behauptung dreier physischer Fenstergrößen. Echter Button zum
Detailöffnen, Slot-Drop verbraucht ein echtes Medgerät und gibt eine Pistole exakt
einmal ans Basislager zurück. Popupgrößen, Trees, Hoverwerte geprüft.
Profil-/Compact-Verifier22/0; Inventartransfer/Checkpoint-Verifier failures0.

Beim Slot-Drop reproduziertes Free-while-emitting behoben: alte Controls werden
abgehängt und verzögert freigegeben. Erste rote Native-Probe hatte außerdem eine
falsche Ultrawide-Erwartung bei keep-aspect im Verifier; tatsächliche1935px
Viewporthöhe erkannt. Anschließend gewünschte logische1440px explizit geprüft.
Native PNGs visuell angesehen. Keine gestalterische Nutzerabnahme, Main/EXE,
Multiplayerabnahme oder allgemeiner Performancebeleg. Nutzerprofil unverändert;
Tests isolieren APPDATA.
