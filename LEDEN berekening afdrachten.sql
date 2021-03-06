------------------------------------------------------------------
--VERSIE CONTROLE
-----------------
--V1.0	08/09/2015	aanmaak procedure
--V1.2	09/10/2015	toevoegen controle van de [account_move_line].[last_rec_date] ter controle van de betaal datum
--			omdat de de van-tot data van uit de [membership_membership_line] tabel geen uitsluitsel geven (worden niet noodzakelijk aangepast bij effectieve betaling vh lidgeld)
--			is deze datum nodig om te controleren vanaf wanneer iemand juist lid is.
--			voor 2015 wordt dit veld gebruikt om te controleren op cutoff datum 08/09/2015 wanneer de berekening van de afdrachten gebeurde
--			In de toekomst moet de de ECHTE cutoff datum worden (30/04/2015 of 01/05/2015 nog te bekijken)
--			Wordt gewoon in het resultaat van de queries die de dataset ophalen afgedrukt; Filtering gebeurd dan bij afdrukken van resultaat.
--v1.3	23/05/2016	[account_move_line].[last_rec_date] niet toereikend.  "p.[membership_pay_date] betaaldatum" toegevoegd.
--			Kan enkele gebruikt worden voor het huidige jaar.
--			Voorlopig ook enkel manuele uitfiltering na lopen van query.  
--v1.4  25/05/2016	aanbreng premie in kader van "op naar 100.000" aangepast van €3 naar €20
--v2.0	--/--/----	Geen docu
--v3.0 	15/03/2017	Aanpak moet eenvoudiger
--			ook aanpassing gemaakt bij berekening "aangebrachte leden": bij afdeling zonder hernieuwingen werd hier niets geregistreerd.  
--			nu worden eerst alle afdelingen (en koepels) toegevoegd met 0-waarden om op die manier niets meer te missen
--			Berekening "einddatum_hern" wordt op 17/11/2016 gezet
--v3.1	28/07/2017	Afdeling "Natuurpunt Schijnvallei vzw" krijgt geen speciaal tarief van €3.7 meer, maar gewoon €3 zoals de rest
--			Berekening "einddatum_hern" blijft op eind april voor deze periode
--			Berekening "startdatum_hern" wordt op 18/11/2016 gezet
--			Berekening ledenaantal en afdracht voor koepels gebeurde foutief/niet (berekening Afdelingen werd herhaald): 
--				"UPDATE tempBerekenAfdracht_totalen" voor koepels aangepast
--			Berekening "aantal leden"/afdeling of koepel aangepast: aangebrachte leden mogen maar 1x geteld worden 
--				en tot voorheen werden die zowel geteld als lid en als aangebracht lid
--v3.2	05/02/2018	"p.membership_start start_datum" toegevoegd aan "tempBerekenAfdracht" als extra controle in details dump
--			"einddatum_hern" op '2017-11-03' gezet voor DEC (datum start aanmaak hernieuwingsfacturen 2018)
--			"p.active" toegevoegd als veld "actief" in resultaat details voor controle (ook leeg veld wordt geëvalueerd)
--v4.0	16/02/2018	berekeningswijze voor hernieuwingen over andere boeg gegooid:
--			een hernieuwd lid heeft 
--				een startdatum voor 01/09 van het vorige jaar
--				een lidmaatschapslijn status 'betaald lid'
--				ml.date_from <= 31/08/YYYY
--				ml.date_to > 01/01/YYYY
--			de periode wordt dus voor APR en DEC helemaal gelopen.  Het verschil is het resultaat voor DEC
--v4.1	17/05/2018	berekeningswijze voor hernieuwingen na ocntrole periode APR 2018 aangepast:
--			een hernieuwd lid heeft 
--				een startdatum voor 01/07 van het vorige jaar, waar dat vorig jaar werd gezet op "voor 01/09 van het vorige jaar"
--v4.2	23/05/2018	TOE TE VOEGEN: aanmaakdatum; ook in logica (zeker voor nieuwe leden)
--			"aanmaakdatum date" toegevoegd aan "CREATE TEMP TABLE tempBerekenAfdracht"
--			"p.create_date::date aanmaakdatum" toegevoegd aan "INSERT INTO tempBerekenAfdracht"
--			logica aangepast naar gebruik van lidmaatschapslijnen voor voorwaarde periode NIEUW (p.create_date niet altijd ingevuld)
--v4.3	14/09/2018	nav begroting berekining van "totalen per afdeling" aangepast voor wat betref "aantal leden"
--			WHERE "type" = 'hernieuwing' aangepast naar NOT(type = 'nieuw' AND afdeling_aangebracht <> 'onbekend')
--			nieuwe leden die niet door afd. werden aangebracht moeten wel meegeteld worden (gebeurde in verleden niet)
--	12/10/2018	"v.startdatum_n" voor periode "DEC" ook op '01/01/2018'; na de berekening moet dan gewoon de correctie gebeuren zoals ook vroeger; en nu ook nog met de hernieuwingen
--			(vooral omdat blijkt bij herlopen van de cijfers voor "APR" dat het aantal aangebrachte leden daar nadien nog stijgt; waarschijnlijk een gevolg van de datum logica in ERP)
--!!!BIJ BEREKING IN DECEMBER EXTRA CHECKEN OP CORRECTHEID!!!
--v4.4	22/05/2019	aanpassing gemaakt in berekening afdrachten Koepels (Regionales): voor "np waasland vzw" en "np schijnvallei vzw" afdracht op €0.7 gezet
--			sectie toegevoegd (onderaan in comment) ter controle van de detail-gegevens
-- -----
--Vanaf nu enkel nog versie controle in Github
------------------------------------------------------------------
--CREATE TEMP VARs
DROP TABLE IF EXISTS myvar;
--ENKEL DE PERIODE AANPASSEN
-- -indien ook gebruikt voor 2015 eerst terug testen!!!!
SELECT 'DEC'::text AS periode, '2019-01-01'::date AS startjaar, '2019-12-31'::date AS eindejaar, 
	'1999-01-01'::date AS startdatum_hern, '1999-01-01'::date AS einddatum_hern, '1999-01-01'::date AS startminhalfjaar, 
	'1999-01-01'::date AS startdatum_n, '1999-01-01'::date AS einddatum_n, '1999-01-01'::date AS cutoff_hern_sept
INTO TEMP TABLE myvar;
UPDATE myvar
	SET startdatum_hern = CASE WHEN periode = 'APR' THEN startjaar - '4 month'::interval WHEN periode = 'DEC' THEN startjaar + '4 month'::interval END,
	einddatum_hern = CASE WHEN periode = 'APR' THEN eindejaar - '4 month'::interval WHEN periode = 'DEC' THEN eindejaar - '1 month'::interval END,
	startdatum_n = startjaar,
	einddatum_n = CASE WHEN periode = 'APR' THEN eindejaar - '8 month'::interval WHEN periode = 'DEC' THEN eindejaar END,
	startminhalfjaar = eindejaar - '18 month'::interval,
	cutoff_hern_sept = eindejaar - '4 month'::interval;
	--CASE WHEN periode = 'DEC' THEN startjaar + '5 month'::interval END startdatum_hern,
	--CASE WHEN periode = 'DEC' THEN eindejaar - '1 month'::interval END einddatum_hern
--voor NIEUWE leden tellen we JAN tem DEC; voor HERNIEUWINGEN hoort DEC bij het volgende jaar
-----------------------------------------------
-- !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! --
--UPDATE myvar SET einddatum_hern = '2017-11-03';  --hernieuwingsfacturen voor 2017 werden aangemaakt van 18/11/2016 tot 24/11/2016: 
							--alles voor hernieuwd vanaf 18/11/2016 wordt dus meegenomen naar 2017
							--hiermee moet ook rekening gehouden worden voor period APR 2017 waar de starddatum_hern zal moeten aangepast worden
-- !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! --
-----------------------------------------------
-- !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! --
--UPDATE myvar SET startdatum_hern = '2016-11-18';  --hernieuwingsfacturen voor 2017 werden aangemaakt van 18/11/2016 tot 24/11/2016: 
							--alles voor hernieuwd vanaf 18/11/2016 wordt dus meegenomen naar 2017
							--hiermee moet ook rekening gehouden worden voor period APR 2017 waar de starddatum_hern zal moeten aangepast worden
-- !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! --
-----------------------------------------------
SELECT * FROM myvar;
-------------------------------------
DROP TABLE IF EXISTS tempBerekenAfdrachtNieuw;
CREATE TEMP TABLE tempBerekenAfdrachtNieuw (id numeric);
-------------------------------------
DROP TABLE IF EXISTS tempBerekenAfdrachtHern;
CREATE TEMP TABLE tempBerekenAfdrachtHern (id numeric);
-------------------------------------
DROP TABLE IF EXISTS tempBerekenAfdracht;
CREATE TEMP TABLE tempBerekenAfdracht (id numeric, afdeling_id numeric, afdeling text, afdracht numeric(3,1), id_nieuw text, afdeling_aangebracht_id numeric, afdeling_aangebracht text, aanbreng_premie numeric(3,1), koepel_id numeric, koepel text, afdracht_koepel numeric(3,1), postcode text, aanmaakdatum date, start_datum date, betaaldatum date, "type" text, actief text);
-------------------------------------
--berekening nieuwe leden in een jaar
-------------------------------------
INSERT INTO tempBerekenAfdrachtNieuw (
/*SELECT p.id--, p.inactive_id
FROM myvar v, res_partner p
WHERE COALESCE(p.create_date::date,p.membership_start) BETWEEN startdatum_n AND einddatum_n
	AND (p.active OR (p.active = 'false' AND COALESCE(p.inactive_id,0) IN (0,2,11)))*/
	--AND p.id = 231667
SELECT p.id--, ml.date_from
FROM myvar v, res_partner p
	JOIN 
		(SELECT DISTINCT ml.partner, MIN(ml.date_from) date_from
		FROM myvar v, membership_membership_line ml
			JOIN product_product pp ON pp.id = ml.membership_id
		WHERE pp.membership_product
			AND (ml.state = 'paid') 
		GROUP BY ml.partner
		) ml ON p.id = ml.partner
WHERE ml.date_from BETWEEN startdatum_n AND einddatum_n 
	AND (p.active OR (p.active = 'false' AND COALESCE(p.inactive_id,0) IN (0,2,11)))
	);
-- SELECT * FROM partner_inactive
-- SELECT * FROM tempBerekenAfdrachtNieuw	
-----------------------------------------
--berekening hernieuwde leden in een jaar
-----------------------------------------
INSERT INTO tempBerekenAfdrachtHern (
SELECT p.id--, ml.date_from
FROM myvar v, res_partner p
	JOIN 
		(SELECT DISTINCT ml.partner, MIN(ml.date_from) date_from
		--SELECT ml.*
		FROM myvar v, membership_membership_line ml
			JOIN product_product pp ON pp.id = ml.membership_id
		WHERE pp.membership_product
			/*AND 
			CASE 
			WHEN periode = 'APR' THEN
				(ml.date_from BETWEEN v.startdatum_hern AND v.einddatum_hern OR v.startjaar BETWEEN ml.date_from AND ml.date_to)
				AND ml.date_to > v.startjaar
			WHEN periode = 'DEC' THEN ml.date_from BETWEEN v.startdatum_hern AND v.einddatum_hern
			END*/
			AND ml.date_from <= v.cutoff_hern_sept AND ml.date_to > v.startjaar
			AND (ml.state = 'paid') --OR (ml.state = 'canceled' AND ml.date_cancel > v.eindejaar))
			--AND ml.partner = 282008
		GROUP BY ml.partner
		) ml ON p.id = ml.partner
WHERE (p.active OR (p.active = 'false' AND COALESCE(p.inactive_id,0) IN (0,2,11))) --AND ml.date_from <= v.cutoff_hern_sept
	);
-----------------------------------------
-- SELECT * FROM tempBerekenAfdrachtNieuw
-- SELECT * FROM tempBerekenAfdrachtHern
-----------------------------------------
INSERT INTO tempBerekenAfdracht (
	SELECT 
		p.id, 
		--p.membership_start, p.membership_end, -- enkel nodig voor testen; bij gewone berekening afdrachten in commentaar zetten
		COALESCE(COALESCE(a2.id,a.id),0) afdeling_id,
		COALESCE(COALESCE(a2.name,a.name),'onbekend') afdeling,	
		0 afdracht,
		p.id id_nieuw,
		--COALESCE(COALESCE(a4.name,a.name),'onbekend') afdeling_aangebracht, 3 aanbreng_premie,
		COALESCE(a4.id,0) afdeling_aangebracht_id,
		COALESCE(a4.name,'onbekend') afdeling_aangebracht, 0 aanbreng_premie,
		--afdeling aangebracht is voor hernieuwingen niet van belang, we zetten ze gelijk aan de afdeling en de aanbreng premie gelijk aan 0 (dat vergemakkelijkt het werken in excel straks)
		COALESCE(a5.id,0) koepel_id, COALESCE(a5.name,'onbekend') koepel, 0 afdracht_koepel,
		p.zip postcode,
		--COALESCE(aml2.last_rec_date,ml.date_from) rec_date,
		p.create_date::date aanmaakdatum,
		p.membership_start start_datum,
		p.membership_pay_date betaaldatum,
		'nieuw' "type",
		p.active
	FROM tempBerekenAfdrachtNieuw tban
		JOIN res_partner p ON tban.id = p.id
		--afdeling & afdeling eigenkeuze
		LEFT OUTER JOIN res_partner a ON p.department_id = a.id
		LEFT OUTER JOIN res_partner a2 ON p.department_choice_id = a2.id
		--link naar wervende organisatie
		LEFT OUTER JOIN res_partner a4 ON p.recruiting_organisation_id = a4.id
		--link naar regionale
		LEFT OUTER JOIN res_partner a5 ON p.partner_up_id = a5.id AND p.organisation_type_id = 1
	);

INSERT INTO tempBerekenAfdracht (
	SELECT 
		p.id, 
		COALESCE(COALESCE(a2.id,a.id),0) afdeling_id,
		COALESCE(COALESCE(a2.name,a.name),'onbekend') afdeling,	
		0 afdracht,
		NULL id_nieuw,
		COALESCE(a4.id,0) afdeling_aangebracht_id,
		COALESCE(a4.name,'onbekend') afdeling_aangebracht, 0 aanbreng_premie,
		COALESCE(a5.id,0) koepel_id, COALESCE(a5.name,'onbekend') koepel, 0 afdracht_koepel,
		p.zip postcode,
		p.create_date::date aanmaakdatum,
		p.membership_start start_datum, 
		p.membership_pay_date betaaldatum,
		'hernieuwing' "type",
		p.active
	FROM myvar v, tempBerekenAfdrachtHern tbah
		LEFT OUTER JOIN tempBerekenAfdrachtNieuw tban ON tbah.id = tban.id
		JOIN res_partner p ON tbah.id = p.id
		--afdeling & afdeling eigenkeuze
		LEFT OUTER JOIN res_partner a ON p.department_id = a.id
		LEFT OUTER JOIN res_partner a2 ON p.department_choice_id = a2.id
		--link naar wervende organisatie
		LEFT OUTER JOIN res_partner a4 ON p.recruiting_organisation_id = a4.id
		--link naar regionale
		LEFT OUTER JOIN res_partner a5 ON p.partner_up_id = a5.id AND p.organisation_type_id = 1
	WHERE tbah.id <> COALESCE(tban.id,0) AND p.membership_start < startjaar - '6 month'::interval --AND p.id = 282008
	);
---------------
--SELECT * FROM tempBerekenAfdracht WHERE id = 286745;
---------------------------------------------------
-- - afdracht + aanbrengpremie afdelingen toevoegen
---------------------------------------------------
UPDATE tempBerekenAfdracht
SET afdracht = SQ1.remittance_exist_member
FROM (SELECT p.id, p.remittance_exist_member FROM res_partner p) SQ1
WHERE SQ1.id = tempBerekenAfdracht.afdeling_id;
--
UPDATE tempBerekenAfdracht
SET aanbreng_premie = COALESCE(SQ1.remittance_new_member,0)
FROM (SELECT p.id, p.remittance_new_member FROM res_partner p) SQ1
WHERE SQ1.id = tempBerekenAfdracht.afdeling_aangebracht_id;
------------------------------------------------------
-- - regionale + afdracht regionale (koepel) toevoegen
------------------------------------------------------
UPDATE tempBerekenAfdracht
SET koepel_id = COALESCE(SQ1.partner_up_id,0) , koepel = COALESCE(SQ1.a5_name,'')
FROM (SELECT p.id, p.name, p.partner_up_id, a5.name a5_name FROM res_partner p LEFT OUTER JOIN res_partner a5 ON p.partner_up_id = a5.id) SQ1
WHERE SQ1.id = tempBerekenAfdracht.afdeling_id;
--SELECT p.id, p.name, p.partner_up_id, a5.name FROM res_partner p LEFT OUTER JOIN res_partner a5 ON p.partner_up_id = a5.id 
--WHERE p.id = 292997 
--
UPDATE tempBerekenAfdracht
SET afdracht_koepel = COALESCE(SQ1.remittance_exist_member,0)
FROM (SELECT p.id, p.remittance_exist_member FROM res_partner p) SQ1
WHERE SQ1.id = tempBerekenAfdracht.koepel_id;
/*
-------------------------------------------
--KOEPELS + afdracht toevoegen aan gegevens
UPDATE tempBerekenAfdracht
SET koepel = CASE WHEN afdeling_id IN (248606,249229,261276,248642,248638,248610,248587,248522,248556,248639,248591,248649,248581,248503,248579,248566,248582,248597,248517,248526,248573,248493,248656,248561,248583,248576,248641,248516,248495,248648,248542,248534,248529,248547,248653) THEN 'Natuurpunt Limburg vzw'
		WHEN afdeling_id IN (249492,248552,248586,248550,248500,248607,248598,248497) THEN 'Natuurpunt en Partners Meetjesland vzw'
		WHEN afdeling_id IN (248540,248506,248511,248585,249248,248600,248572,248596,248501,248612,248508,248559,248544,248613,248504,248654,248492,248592,248601,248498,248637,248618,248512) THEN 'Natuurpunt Oost-Brabant vzw'
		WHEN afdeling_id IN (248588,248509,248589,248546,248659,248622,248643,248574,248520) OR (afdeling_id = 248502 AND postcode <> '9870') THEN 'Natuur.koepel vzw'
		WHEN afdeling_id IN (248510,249427,248531,248647,248513,248568,248658,248565,248494,248650) THEN 'Natuurpunt Brugs Ommeland vzw' 
		WHEN afdeling_id IN (287761,248545,248623) THEN 'Natuurpunt Waasland vzw'
		WHEN afdeling_id IN (248533,248567,248564) THEN 'Natuurpunt Midden-West-Vlaanderen vzw'
		WHEN afdeling_id IN (248620,248557,248558) THEN 'Natuurpunt De Bron, voor Natuur & Milieu tussen IJzer & Leie vzw'
		WHEN afdeling_id IN (292997,248532,248575) THEN 'Natuurpunt Schijnvallei vzw'		
		ELSE 'geen koepel'
END;

UPDATE tempBerekenAfdracht
SET koepel_id = CASE WHEN koepel = 'Natuurpunt Limburg vzw' THEN 14855
			WHEN koepel = 'Natuurpunt en Partners Meetjesland vzw' THEN 17230
			WHEN koepel = 'Natuurpunt Oost-Brabant vzw' THEN 15192
			WHEN koepel = 'Natuur.koepel vzw' THEN 17130
			WHEN koepel = 'Natuurpunt Brugs Ommeland vzw' THEN 17209
			WHEN koepel = 'Natuurpunt Waasland vzw' THEN 248644
			WHEN koepel = 'Natuurpunt Midden-West-Vlaanderen vzw' THEN 258380
			WHEN koepel = 'Natuurpunt De Bron, voor Natuur & Milieu tussen IJzer & Leie vzw' THEN 74586
			WHEN koepel = 'Natuurpunt Schijnvallei vzw' THEN 248530			
			ELSE null
END;

UPDATE tempBerekenAfdracht
SET afdracht_koepel = CASE WHEN koepel_id = 14855 THEN 3
			WHEN koepel_id = 17230 THEN 3
			WHEN koepel_id = 15192 THEN 5
			WHEN koepel_id = 17130 THEN 2.5
			WHEN koepel_id = 17209 THEN 3
			WHEN koepel_id = 248644 THEN 0.7
			WHEN koepel_id = 258380 THEN 3
			WHEN koepel_id = 74586 THEN 2.5	
			WHEN koepel_id = 248530 THEN 0.7
			ELSE 0.0
END;	
*/
---------------
--=====details=====--
SELECT * FROM tempBerekenAfdracht --WHERE NOT(type = 'nieuw' AND afdeling_aangebracht <> 'onbekend');
---------------
------------------------------------------
--===BEREKENING: TOTALEN PER AFDELING===--
DROP TABLE IF EXISTS tempBerekenAfdracht_totalen;
CREATE TEMP TABLE tempBerekenAfdracht_totalen ("sort" numeric, afdeling_id numeric, "afdeling/koepel" text, "aantal leden" numeric, afdracht numeric(7,1), "leden aangebracht" numeric, "aanbreng premie" numeric(7,1), totaal numeric(8,1));
SELECT * FROM tempBerekenAfdracht_totalen;
-----afdelingen
INSERT INTO tempBerekenAfdracht_totalen
	(SELECT 1, id, name, 0,0,0,0 FROM res_partner WHERE NOT(id = 254827) AND organisation_type_id = 1 AND active); --[254827] te innen overschrijving
/*INSERT INTO tempBerekenAfdracht_totalen
	(SELECT 1, 0, onbekend, 0,0,0,0 FROM res_partner WHERE NOT(id = 254827) AND organisation_type_id = 1 AND active); --[254827] te innen overschrijving	*/
UPDATE tempBerekenAfdracht_totalen
	SET "aantal leden" = x.leden, afdracht = x.afdracht 
	FROM (SELECT afdeling_id, afdeling, COUNT(id) leden, SUM(afdracht) afdracht, null, null FROM tempBerekenAfdracht WHERE  NOT(type = 'nieuw' AND afdeling_aangebracht <> 'onbekend') /*"type" = 'hernieuwing'*/ GROUP BY afdeling, afdeling_id ORDER BY afdeling) x
	WHERE tempBerekenAfdracht_totalen.afdeling_id = x.afdeling_id;
-----koepels	
INSERT INTO tempBerekenAfdracht_totalen
	(SELECT 2, id, name, 0,0,0,0 FROM res_partner WHERE organisation_type_id = 7 AND active);
UPDATE tempBerekenAfdracht_totalen
	SET "aantal leden" = x.leden, afdracht = x.afdracht 
	FROM (SELECT koepel_id, koepel, COUNT(id) leden, SUM(afdracht_koepel) afdracht, null, null FROM tempBerekenAfdracht WHERE NOT(type = 'nieuw' AND afdeling_aangebracht <> 'onbekend') /*"type" = 'hernieuwing'*/ GROUP BY koepel, koepel_id ORDER BY koepel) x
	WHERE tempBerekenAfdracht_totalen.afdeling_id = x.koepel_id;
-----aanbrengpremies
UPDATE tempBerekenAfdracht_totalen
	SET "leden aangebracht" = aantal_leden, "aanbreng premie" = aanbreng_premie
	FROM (SELECT afdeling_aangebracht, COUNT(id_nieuw) aantal_leden, COUNT(id_nieuw)*aanbreng_premie aanbreng_premie FROM tempBerekenAfdracht /*WHERE afdeling_aangebracht LIKE '%Gulke%'*//*WHERE id = 205296*/ GROUP BY afdeling_aangebracht, aanbreng_premie) x
	WHERE tempBerekenAfdracht_totalen."afdeling/koepel" = x.afdeling_aangebracht /*AND "sort" = 1*/;
-----totalen rij niveau (afdracht + aanbreng premie per afdeling)
UPDATE tempBerekenAfdracht_totalen
	SET totaal = COALESCE(tot,0)
	FROM (SELECT "afdeling/koepel", (afdracht + "aanbreng premie") tot FROM tempBerekenAfdracht_totalen WHERE "afdeling/koepel" <> 'onbekend' AND "afdeling/koepel" <> 'geen koepel') x
	WHERE tempBerekenAfdracht_totalen."afdeling/koepel" = x."afdeling/koepel";
-----totalen op kolom niveau
INSERT INTO tempBerekenAfdracht_totalen
	(SELECT 3, null, 'TOTAAL', null, SUM(afdracht), null, SUM("aanbreng premie"), SUM(totaal) FROM tempBerekenAfdracht_totalen WHERE "afdeling/koepel" <> 'onbekend' AND "afdeling/koepel" <> 'geen koepel');
-----EINDRESULTAAT	
SELECT afdeling_id, "afdeling/koepel", "aantal leden", afdracht, "leden aangebracht", "aanbreng premie", totaal 
FROM tempBerekenAfdracht_totalen 
WHERE "afdeling/koepel" <> 'onbekend' AND "afdeling/koepel" <> 'geen koepel' --AND "sort" = 2
ORDER BY "sort", "afdeling/koepel"

--SELECT SUM("aantal leden") FROM tempBerekenAfdracht_totalen WHERE "sort" = 1	
	
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--TEST voor DUBBELS (op basis van ID)
/*SELECT a.*, x.r FROM tempBerekenAfdracht a JOIN 
	(SELECT ROW_NUMBER() OVER (PARTITION BY id ORDER BY afdeling DESC) AS r,
	id, afdeling_id, afdeling, afdracht, id_nieuw, afdeling_aangebracht, aanbreng_premie
	FROM	tempBerekenAfdracht ) x	ON a.id = x.id
WHERE x.r > 1*/

--SELECT * FROM tempNieuweLeden WHERE afdeling_aangebracht = '' AND aanbreng_premie <> 0--n_id = '250527'

--SELECT * FROM tempBerekenAfdracht WHERE id_nieuw = '250527'--afdeling_aangebracht = 'Natuurpunt Alken' AND aanbreng_premie > 0

--SELECT * FROM res_partner WHERE id = 250527
--==================================================================
/*
--CONTROLE
SELECT tba.*, 
	p.membership_state huidige_lidmaatschap_status,
	COALESCE(p.create_date::date,p.membership_start) aanmaak_datum,
	p.membership_start Lidmaatschap_startdatum, 
	p.membership_stop Lidmaatschap_einddatum,  
	p.membership_pay_date betaaldatum,
	p.membership_renewal_date hernieuwingsdatum,
	p.membership_end recentste_einddatum_lidmaatschap,
	p.membership_cancel membership_cancel,
	_crm_opzegdatum_membership(p.id) opzegdatum_LML,
	p.active
FROM res_partner p
	JOIN tempBerekenAfdracht tba ON tba.id = p.id
*/
---------------
--test CASE 	
---------------
/*
SELECT DISTINCT ml.partner
SELECT ml.*
		FROM myvar v, membership_membership_line ml
		WHERE membership_id IN (2,5,6,7,205,206,207,208)
			AND CASE 
			WHEN periode = 'APR' THEN
				(ml.date_from BETWEEN v.startdatum_hern AND v.einddatum_hern OR v.startjaar BETWEEN ml.date_from AND ml.date_to)
				AND ml.date_to > v.startjaar
			WHEN periode = 'DEC' THEN ml.date_from BETWEEN v.startdatum_hern AND v.einddatum_hern
			END	
			AND ml.state = 'paid'
			--AND ml.partner = 147702
*/
