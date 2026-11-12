# Bestaetigte enge Fortsetzung (inzwischen implementiert)

1. Vor Travel.enter_space_orbit reine _prepare_space_surface_departure:
   bestehender eigener Record/Marker, aktueller Visit/Controller/Root, deklarierte
   Hex-Receiptpflicht lesen; keine RegistryAPI-Ausfallvorwegnahme (das darf warten).
2. Nach positivem Travelreceipt alten normalen Transfer entfernen, vorbereiteten
   Weakref-/Visit-/Rootcontextrecord und Marker nichtfallibel registrieren.
   Initialcall bleibt deferred, erhaelt aber DIESEN Record statt neuer Capture.
   Falls reentrante Publikation inzwischen frischen Record einsetzte: niemals
   ueberschreiben. Bound Currentcheck vor dem Callback stoppt alte Welten.
3. _finish_space_surface_departure direkter Aufruf ohne Record bleibt kompatibel:
   Prepare+Register+initialer zweistelliger Controllercall; vorhandener Record
   erzeugt keinen zweiten Call. Retry bleibt dritter opaker Bindingparameter.
4. _finish_space_home_landing bei offenem Record merkt ausschliesslich
   home_landing_requested in diesem Record. Keine Membership-/Locationmutation.
5. Commit setzt retryable=false und behaelt den eigenen Marker durch alle
   modellierenden Tails. Erst vorhandene starmap-/Rememberprojektion und ggf
   intern exakt gebundener HomeLandingtail; vor Fortsetzung Current-/ID-/Scope-
   und erwarteten Aircraftlocationstatus pruefen. stale verwirft Fortsetzung.
6. Marker/Record exakt freigeben; aborted-Observerevent ist LETZTER Schritt.
   Kein alter Flowwrite darf nach dessen reentrantem Callback folgen.

Private Zusatzfaelle sind vorbereitet: fruehes HomeLanding ohne Vorwrites,
echtes Membershiptail vor aborted-Observer und dessen neuer Visit bleibt,
Travelreceipt hat sofort Marker/noch keinen Controllercall, Visitwechsel vor
dem deferred Callback wird ohne Controller-/Flowcompletion verworfen.
Kein Produktwrite oder Testlauf erfolgte waehrend angeordnetem Basisfreeze.
Nach erneutem Ownerfreeze implementiert und18/0 gruen nachgewiesen, inklusive
letzter reiner Capture-/Travelreadreihenfolge vor potenziell buchendem
authorize_return (LegacyFuel-Spy).
