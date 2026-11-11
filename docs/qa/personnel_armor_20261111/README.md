# Anzug und sichtbare Rüstung

Historischer Stand; die aktive R05-Modellrevision und ihre eigenen Prüfungen
stehen unter [armor_kenney_r05_20261111](../armor_kenney_r05_20261111/README.md).


Grafikstatus: Diese frühere Modellfassung wurde vom Nutzer gestalterisch
abgelehnt. Die Funktionsnachweise bleiben erhalten; die damalige nachfolgende eigene
Modellrevision ist unter [armor_revision_20261111](../armor_revision_20261111/README.md)
dokumentiert. Diese ältere QA ist keine Stilabnahme.

Stand11.11.2026, isolierter Taskbranch auf820a91caf. Frische Kampagne beginnt im
Anzug ohne freie leichte Rüstung. Vorhandener Satelliten-Blueprint und Herstellung
für20Credits bleiben der frühe Erwerbsweg. Alte kanonische Loadouts behalten ihre
Klasse. Anzug ist eine intrinsische Unterbekleidung und kein Lagergegenstand.
Ein Datenträgerfach bleibt ohne Rucksack nutzbar. Punktepakete können Anzug für0
Rüstungspunkte wählen; bisheriges995-Punkte-Beispiel mit leichter Rüstung unverändert.

Basisakteure lesen ihre Ausrüstung schwach referenziert vom SimulationRoot-Owner.
Keine Ausrüstungskopie im Visual. Basiswelt, Einsatzproxy und Inventarkörper verwenden
denselben ArmorVisual-Helper. Die Basis prüft bekannte Personen alle0,2s und baut
nur bei geänderter Klasse an. Einsatzproxies berücksichtigen die Rüstung in ihrer
bestehenden Revisionssignatur. Ressourcen sind gecacht; kein neuer Vollscan im Hotpath.

Echte starre Meshteile am vorhandenen Skelett: leicht2, mittel4, schwer9 Teile.
Körperachsen werden aus dem jeweiligen Rig abgeleitet; sowohl das Z-up-Einsatzrig
als auch der Y-up-Basisoperator sind geprüft. Die erste rechteckige Brustplatte
wurde verworfen; Revision2 hat Halsausschnitt, Schulterabschrägung und Taille.
Das vorhandene Untermodell bleibt erhalten. Es ist eine erste tragbare Modellfassung,
keine endgültig vom Nutzer abgenommene Kleidung oder fertig überarbeitete Unterbekleidung.

Blender5.1.1: acht Einzelteile bestehen Geometrie-/UV-Prüfung ohne Fehler. Akzeptierte
Warnung: Teile haben absichtlich einen mittigen Knochen-Pivot, keinen Boden-Pivot.
Editierbare Quelle, Exportpipeline, Quell-/Exporthashes und Zielreferenz in
art/armor_20261111. Material- und Wire-Vierwinkelbilder wurden geöffnet.

Godot4.6.2, native D3D12 Forward+, RTX4070TiSUPER. Front/Stand, Lauf, Feuer und Rückseite
geöffnet; native Poseprüfung62/0. Reale Kampagnenszene und normaler Inventarpfad16/0:
fehlender Besitz/Blueprint, Fertigung, Verbrauch, kanonischer Wechsel, tatsächlicher
„Rüstung ablegen“-Button, genau eine Rückgabe, kein erzeugter Anzug, Legacy-Restore
und Darstellung in der echten Basiswelt. Der Rezept-Receipt ist ein ausdrücklich
markiertes Domainfixture; kein durchgespielter Satellitenausflug in diesem Test.
Autosave wird für dieses Fixture gestoppt. Privates APPDATA-Testprofil; der vorhandene
Benutzercheckpoint blieb beim11.11.-Arbeitslauf auf seinem10.11.-Zeitstempel.

Neun gezielte Headless-Programme bestanden: Pose, Anzug/Inventar, frischer Start,
Supply, vollständige Fünf-Auftrags-Domainkette54/0, bisherige Inventartransfers,
Inventaradapter, Punktekauf und kompakte Charakterkarte. Die abschließenden nativen
Pose-/Buttonprüfungen sind in ihren separaten Logs enthalten.
Editorimport Exit0 mit der bekannten ObjectDB-Abschlusswarnung. Zwei bestehende
Szenen-UID-Fallbacks im normalen Start; keine Script-/Compile-/Runtimefehler in
den bestandenen gezielten Prüfungen.

Anzug-Modifikatoren sind erste Balancewerte: Speed+.18, Toughness-.15, Cover-.08,
Gewicht.5; bestehende drei Klassen bleiben unverändert. Weitere Ausrüstungskosten,
Transport-/Sitzposen, zusätzliche Modelle, Gesamtgefechtsleistung und Nutzerurteil
zur Form bleiben offen. Keine Mainintegration und keine neue EXE.
