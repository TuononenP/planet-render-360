# Venice Landmark Sources & Site Audit

Grounded against `assets/osm_snapshots/venice_detailed.osmb` (14,020 elements: 3,660 buildings, 1,825 `building:part`s, 858 bridges, 277 waterways, 345 ferry/pier elements, 1,101 trees) and `venice_far.osmb` (3,731 elements), centred on the Ponte dell'Accademia preset vantage (`45.4318, 12.3290`, OSM base `2026-11-02`).

## Snapshot Audit (`VN-0.2`)

- **Height tag coverage:** Only 255 / 3,660 buildings (7.0 %) have an explicit `height` tag; 1,254 (34.3 %) carry `building:levels`; 2,508 (68.5 %) are untyped `building=yes`.
- **Churches & campanili:** Only 6 / 76 churches and 43 / 76 bell towers carry `height`. Key missing/under-mapped heights:
  - `Basilica di San Giorgio Maggiore` (`way:138804537`): `height=-` (real dome ~46 m, campanile 75 m).
  - `Chiesa del Redentore` (`way:154856677`): `height=-` (real dome ~52 m).
  - `Campanile di Santo Stefano` (`way:138841364`): `height=-` (real leaning brick campanile 66 m).
  - `Molino Stucky` (`way:138841259`): `height=-, levels=3` (real Neo-Gothic brick mill ~38 m).
  - `Colonna di San Marco` (`way:431003455` / `431003657`): `height=0.4–15 m` (real monument ~18 m with winged lion).
  - `Chiesa di San Zaccaria` (`way:162035005`): `height=-, levels=2` (real Renaissance facade ~28 m).
  - `Santa Maria della Salute` (`way:138801509`): `height=18` (real main dome + Virgin 60 m).
  - `Basilica di San Marco` (`way:138800932`): `height=13` (real central dome + cross 43 m).
- **Foreground `venice_modern` misclassification:** `relation:1927018` (`109 m, h=24 m, 80x109 m`) and `relation:2373333` (`161 m, h=18.5 m, 64x149 m`) beside Ponte dell'Accademia previously triggered `lv >= 6 -> venice_modern` in `building_era.gd:463`. Fixed by restricting `venice_modern` to Tronchetto, Santa Marta, Piazzale Roma, Marittima and Sacca Fisola.
- **Vaporetto pier trap:** 88 `building=roof` + `man_made=pier` / `ferry=yes` elements (`Accademia`, `Accademia A`, `Ca' D'oro`, `Ca' Rezzonico`, `Salute`, `San Giorgio`, `Rialto C/D`, `San Marco Giardinetti`, `San Zaccaria - Danieli`, `Zattere`) are ACTV floating pontoons and must not be confused with palazzi behind them.
- **Ring truncation:** `venice_ring1600.osmb` (`ww=150`) and `venice_ring2500.osmb` (`ww=150`) hit the old 150-waterway cap.

## Verified Landmark Registry Table

Yaw convention (`terrain_builder.gd:221`): `rotation.y = -deg_to_rad(yaw_deg)`. Local `+X` points along `(90 + yaw_deg) mod 360`; local `+Z` faces `(180 + yaw_deg) mod 360`.

| Type | Name | OSM Element | Lat | Lon | Yaw (°) | Height (m) | Architectural Reference |
| --- | --- | --- | ---: | ---: | ---: | ---: | --- |
| `salute` | Santa Maria della Salute | `way:138801509` | 45.43068 | 12.33472 | 178.0 | 60.0 | Longhena 1631–87; octagonal Istrian stone, 16 *orecchioni* scrolls, lead dome + Virgin |
| `st_marks_campanile` | St Mark's Campanile | `way:252637693` | 45.43405 | 12.33903 | -109.4 | 98.6 | 1912 rebuild; brick *lesene* shaft, Istrian belfry, copper spire, Sansovino Loggetta (+Z toward Basilica) |
| `doges_palace` | Doge's Palace | `way:138803915` | 45.43375 | 12.34038 | -15.1 | 27.3 | Venetian Gothic double arcade + pink/white Verona marble lozenges + Porta della Carta |
| `st_marks_basilica_venice` | St Mark's Basilica | `way:138800932` | 45.43455 | 12.33975 | 74.1 | 43.0 | 5-domed Veneto-Byzantine basilica, gilt mosaic portals, quadriga horses, Gothic ogee crest |
| `bridge_of_sighs` | Bridge of Sighs | Rio di Palazzo | 45.43406 | 12.34086 | -14.0 | 11.85 | Antonio Contin 1600–03; enclosed Istrian limestone arch between Doge's Palace & Prigioni |
| `rialto_bridge` | Rialto Bridge | `ways:166489459,121674081` | 45.43800 | 12.33591 | 36.9 | 12.8 | Antonio da Ponte 1591; 28.8 m segmental Istrian arch, 24 stepped shops, central portico |
| `san_giorgio_maggiore` | Basilica di San Giorgio Maggiore | `ways:138804537,138800498` | 45.42937 | 12.34331 | 110.0 | 75.0 | Palladio 1566; interlocking white Istrian temple front, 46 m dome, 75 m brick campanile, monastery & harbour lighthouses |
| `punta_della_dogana` | Punta della Dogana | `rel:2317795` | 45.43072 | 12.33627 | 10.0 | 28.0 | Benoni 1677; triangular customs house, rusticated Istrian arcades, square tower, Atlases & gilded Fortune |
| `ponte_accademia` | Ponte dell'Accademia | `way:946641888` | 45.43168 | 12.32894 | -60.9 | 8.2 | Miozzi 1933; 48 m single-span arched oak timber & steel tie footbridge |
| `ponte_scalzi` | Ponte degli Scalzi | `ways:240496236,240496241` | 45.44116 | 12.32272 | 59.0 | 8.8 | Miozzi 1934; 40 m flattened white Istrian-stone single arch |
| `ponte_costituzione` | Ponte della Costituzione | `way:1098943156` | 45.43902 | 12.31964 | -52.3 | 10.2 | Calatrava 2008; 81 m red-oxide steel ribs & illuminated laminated-glass arch |
| `palazzo_cavalli_franchetti` | Palazzo Cavalli-Franchetti | `way:138841814` | 45.43195 | 12.32969 | 16.5 | 21.0 | 15th-c. / Boito Neo-Gothic pink-ochre palazzo, 5-bay pointed *polifore* |
| `palazzo_barbaro` | Palazzo Barbaro | `way:138843885` | 45.43173 | 12.32996 | 13.5 | 19.0 | Twin Gothic (1425) + Baroque (1694) palazzi beside Cavalli-Franchetti |
| `palazzo_contarini_polignac` | Palazzo Contarini Polignac | `way:313876764` | 45.43104 | 12.32920 | -150.0 | 19.0 | Early Renaissance Lombardo Istrian & marble-roundel facade |
| `gallerie_accademia` | Gallerie dell'Accademia | `way:138842956` | 45.43131 | 12.32850 | -56.7 | 22.0 | Former Santa Maria della Carità Gothic red-brick church & Palladian wing |
| `san_vidal_chiesa` | Chiesa di San Vidal | `way:138842959` | 45.43242 | 12.32952 | 14.7 | 20.0 | Tirali Palladian Istrian-stone church facade on Campo San Vidal |
| `palazzo_barbarigo` | Palazzo Barbarigo | `way:313876763` | 45.43090 | 12.33052 | 196.4 | 18.0 | 16th-c. palazzo clad in gleaming 1886 Murano gold-and-polychrome glass mosaics |
| `palazzo_corner_ca_granda` | Palazzo Corner della Ca' Granda | `rel:4207325` | 45.43177 | 12.33180 | 5.9 | 26.0 | Sansovino 1545; monumental rusticated Istrian stone & paired Ionic/Corinthian orders |
| `palazzo_venier_guggenheim` | Palazzo Venier dei Leoni (Guggenheim) | `way:313876769` | 45.43085 | 12.33155 | 182.7 | 9.5 | Boschetti 1748; unfinished single-storey white Istrian-stone palazzo & canal garden terrace |
| `ca_dario` | Ca' Dario | `way:138843787` | 45.43082 | 12.33222 | 177.4 | 18.0 | Lombardo 1487; subtly leaning polychrome marble-roundel Renaissance facade |
| `gritti_palace` | Gritti Palace (Palazzo Pisani Gritti) | `way:314323127` | 45.43172 | 12.33332 | -5.2 | 18.5 | Burnt-salmon Venetian Gothic palazzo with *polifore* & canal dining terrace |
| `palazzo_ferro_fini_bauer` | Palazzo Ferro Fini & Contarini Fasan | `rel:19801771` | 45.43184 | 12.33390 | -3.2 | 20.0 | Twin Gothic/Renaissance canal palaces opposite Salute |
| `san_gregorio_abbazia` | Abbazia di San Gregorio | `way:138800410` | 45.43067 | 12.33396 | 178.7 | 17.5 | Gothic red-brick stepped-gable abbey & cloister immediately west of Salute |
| `procuratie_piazza_san_marco` | Procuratie Vecchie, Nuove & Ala Napoleonica | `ways:410344923,138803888,410344936` | 45.43400 | 12.33790 | -16.0 | 22.0 | Continuous 3-sided Istrian-stone colonnaded enclosure of Piazza San Marco |
| `biblioteca_marciana` | Biblioteca Marciana & La Zecca | `ways:206333242,431003622` | 45.43348 | 12.33923 | -21.3 | 22.0 | Sansovino 1537; two-tier classical arcades, statue balustrade & rusticated Zecca |
| `torre_orologio` | Torre dell'Orologio | `way:410344943` | 45.43474 | 12.33893 | -16.0 | 31.0 | Codussi 1496; deep-blue/gold astronomical zodiac clock, winged lion & bronze *Mori* |
| `colonne_san_marco` | Colonne di San Marco e San Todaro | `ways:431003657,431003588` | 45.43335 | 12.33991 | -15.0 | 18.0 | Twin monumental granite Piazzetta columns with bronze Lion & St Theodore |
| `prigioni_danieli` | Prigioni Nuove & Hotel Danieli | `rel:2080520`, `way:446527969` | 45.43405 | 12.34160 | -5.1 | 22.0 | Rusticated Istrian prisons + pink Venetian Gothic Palazzo Dandolo on Riva degli Schiavoni |
| `teatro_la_fenice` | Teatro La Fenice | `way:813451645` | 45.43353 | 12.33347 | -20.7 | 24.0 | Selva 1792; Corinthian portico, gilt phoenix emblem & pediment |
| `contarini_del_bovolo` | Palazzo Contarini del Bovolo | `rel:2766982` | 45.43486 | 12.33437 | 52.6 | 28.0 | Candi 1499; 28 m cylindrical external arcaded spiral staircase tower & belvedere dome |
| `ca_rezzonico` | Ca' Rezzonico | `rel:1927025` | 45.43354 | 12.32655 | -96.1 | 25.0 | Longhena 1649; Baroque Istrian-stone palazzo on Grand Canal west bank |
| `palazzo_grassi` | Palazzo Grassi | `way:173619525` | 45.43377 | 12.32794 | 87.0 | 23.0 | Massari 1748; white Neoclassical Istrian palazzo at San Samuele |
| `ca_foscari` | Ca' Foscari | `way:138843741` | 45.43455 | 12.32655 | -1.1 | 24.0 | 1452; monumental brick-and-Istrian Gothic *polifora* focal point of Volta de Canal |
| `fondaco_dei_tedeschi` | Fondaco dei Tedeschi | `way:138803475` | 45.43826 | 12.33669 | 101.0 | 24.0 | Spavento/Scarpagnino 1508; ochre Renaissance palazzo, 5 water-gate arches, roof terrace |
| `palazzo_camerlenghi` | Palazzo dei Camerlenghi | `way:138800761` | 45.43845 | 12.33579 | -62.8 | 17.5 | Bergamasco 1528; pentagonal Istrian Renaissance treasury at Rialto foot |
| `rialto_mercato_pescheria` | Rialto Fabbriche & Pescheria | `rel:4182882`, `ways:129298088,138800979` | 45.43915 | 12.33470 | -41.4 | 18.0 | Scarpagnino/Sansovino market arcades + 1907 Neo-Gothic brick/marble Pescheria loggia |
| `ca_doro` | Ca' d'Oro (Palazzo Santa Sofia) | Cannaregio (behind pier `138802455`) | 45.44070 | 12.33385 | 22.0 | 20.5 | Bon 1428–30; Flamboyant Gothic marble lacework loggias, pink Verona marble & scalloped cresting |
| `ca_pesaro` | Ca' Pesaro | `rel:2382783` | 45.44097 | 12.33152 | 212.0 | 26.0 | Longhena 1652; diamond-rusticated Istrian Baroque Grand Canal palazzo |
| `fontego_dei_turchi` | Fontego dei Turchi | `rel:2375803` | 45.44179 | 12.32865 | 195.7 | 16.5 | 13th-c. Veneto-Byzantine 10/18-arch marble loggia & twin crenellated towers |
| `ca_vendramin_calergi` | Ca' Vendramin Calergi (Casinò) | `way:835241186` | 45.44269 | 12.32998 | 16.8 | 22.0 | Codussi 1509; luminous white Istrian Renaissance *bifore* facade |
| `san_simeone_piccolo` | San Simeone Piccolo | `way:138841179` | 45.44030 | 12.32242 | 139.4 | 44.0 | Scalfarotto 1738; tall elongated patinated green-copper dome + Corinthian portico |
| `stazione_santa_lucia` | Stazione Venezia Santa Lucia | `way:138841071` | 45.44164 | 12.31991 | 38.8 | 18.5 | Mazzoni/Perilli 1954; travertine modernist terminus facade, canopy & canal steps |
| `il_redentore` | Il Redentore | `way:154856677` | 45.42495 | 12.33239 | 188.7 | 52.0 | Palladio 1577; white temple pediments, high ribbed dome, twin white conical campanili |
| `le_zitelle` | Le Zitelle | `rel:2382773` | 45.42672 | 12.33923 | 157.8 | 36.0 | Palladian white-and-ochre Giudecca church with central dome & twin bell turrets |
| `molino_stucky` | Molino Stucky | `way:138841259` | 45.42771 | 12.31948 | 199.7 | 38.0 | Wullekopf 1895; colossal red-brick Neo-Gothic flour mill with stepped gables & corner tower |
| `basilica_dei_frari` | Basilica dei Frari | `way:815442226` | 45.43690 | 12.32644 | 139.5 | 70.0 | Gothic red-brick Franciscan basilica & Venice's 2nd-tallest campanile (70 m) |
| `scuola_grande_san_rocco` | Scuola Grande di San Rocco | `way:138843143` | 45.43653 | 12.32530 | -59.9 | 22.0 | Bon/Scarpagnino Renaissance Istrian & polychrome marble facade |
| `chiesa_santo_stefano` | Chiesa di Santo Stefano & Leaning Campanile | `ways:138842928,138841364` | 45.43366 | 12.33112 | 41.1 | 66.0 | Gothic brick church + famously leaning (~2 m tilt) 66 m red-brick campanile |
| `chiesa_gesuati` | Chiesa dei Gesuati (Zattere) | `way:118714648` | 45.42954 | 12.32733 | 20.2 | 34.0 | Massari 1736; white Palladian Corinthian facade, dome & twin small campanili |
| `squero_san_trovaso` | Squero di San Trovaso | `way:138841864` | 45.43034 | 12.32586 | 34.5 | 10.5 | 17th-c. Alpine dark-timber gondola boatyard & wooden slipway |
| `santa_maria_miracoli` | Santa Maria dei Miracoli | `way:138800840` | 45.43950 | 12.33924 | 120.8 | 22.5 | Lombardo 1489; veined polychrome marble jewel-box church & semicircular pediment |
| `san_zaccaria` | Chiesa di San Zaccaria & Pietà | `way:162035005` | 45.43471 | 12.34360 | 90.0 | 28.0 | Codussi 5-tier arched Istrian Renaissance facade |
| `chiesa_san_moise` | Chiesa di San Moisè | `way:138804072` | 45.43309 | 12.33615 | -10.0 | 24.0 | Tremignon 1668; richly sculpted Baroque Istrian stone facade |
| `santa_maria_formosa` | Santa Maria Formosa | Castello | 45.43710 | 12.34115 | 0.0 | 40.0 | Codussi church + 40 m Baroque onion-domed campanile |
| `zanipolo_san_marco` | Santi Giovanni e Paolo & Scuola San Marco | Castello | 45.43930 | 12.34220 | 78.0 | 42.0 | Huge brick Gothic basilica, Lombardo marble Scuola facade & Colleoni bronze equestrian monument |
| `arsenale_venezia` | Arsenale di Venezia | Castello | 45.43485 | 12.35010 | 15.0 | 26.0 | 1460 Porta Magna Istrian triumphal arch + Twin crenellated red-brick Water-Gate Towers |
| `san_pietro_castello` | San Pietro di Castello | Castello | 45.43450 | 12.35980 | 82.0 | 48.0 | Palladian cathedral front, dome & Venice's leaning all-white Istrian-stone campanile |
| `chiesa_gesuiti_orto` | Gesuiti, Madonna dell'Orto & San Michele | Cannaregio / Lagoon | 45.44360 | 12.33890 | 10.0 | 56.0 | Baroque Gesuiti & Gothic Madonna dell'Orto with 56 m cupola campanile |
| `san_michele_island` | San Michele Cemetery Island | Lagoon North | 45.44720 | 12.34700 | 0.0 | 22.0 | Codussi's white Istrian church, cypress groves & red-brick lagoon perimeter wall |
| `murano_faro_donato` | Murano Lighthouse (Faro) | Murano | 45.45175 | 12.35540 | 0.0 | 35.0 | 1934 white Istrian-stone fluted cylindrical lagoon lighthouse |
