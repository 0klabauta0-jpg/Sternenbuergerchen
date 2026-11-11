# Gemeinsame Abflug-/Anflugtransaktion

Gepruefter Elternstand: e205137d6. Enthalten sind die Quellen 1b0b8e0aa,
af23d641c, be0a21d2c, 09bbe4627, bbf6b3593 und 2171e7f25.
Die bereits im Elternstand vorhandene pure Adaptervorschau eb251eb23 wurde
nicht ein zweites Mal als Quellkopie 02cf827f0 eingespielt.

Frische kleine Laeufe im privaten Projekt:
- `departure`: bestanden. Echte Campaign-/Supply-/Fleetowner, kleiner Adapter-
  bzw. Flowdouble. Ungueltiger Auftrag ohne Teilverbrauch; einmaliger Abflug;
  strategischer und lokaler Anflug; Adaptertoken/aeussere Receipts vor Signalen;
  reentrante Wiederholung ohne weitere Mutation; Reset desselben Travelowners
  bei identischer Flightreferenz verwirft alten Gruppenbeleg.
- `surface_group`: bestanden. Echte Owner inkl. Flight/Combat/Equipment,
  Pilotdouble. Unpassendes Bundle und fehlender Fuel ohne Teilcommit;
  Anflug/Deaktivierung, bestehender Finish, Rueckorbit/Reaktivierung und Bewegung
  mit derselben Flightinstanz. Requestkonflikt und Ownerreset werden verworfen.

Beide Reports bestaetigen saubere Logs, unveraenderte gepruefte Quellen und
echtes Nutzerprofil sowie private Isolation-Canary. Dies ist kein Nachweis
nativen Einsteigens, einer kompletten produktiven Rueckreise, Save/Continue,
Netzspiel, Gefechtsleistung oder persoenlicher Gestaltungsfreigabe.
AP6-Boarding und produktive Rueckwegtransaktion laufen in den Besitzerchats
weiter. Keine EXE, kein Mainrelease, keine Livekatalogaktivierung.
