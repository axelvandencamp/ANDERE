--------------------------------------
--SET VARIABLES
DROP TABLE IF EXISTS myvar;
SELECT 
	'2019-01-01'::date AS startdatum 
	,'2019-12-31'::date AS einddatum
	,4::numeric AS magazine --3 = focus; 4 = oriolus; 204 = zoogdier;
INTO TEMP TABLE myvar;
SELECT * FROM myvar;
------------------------------------------------
SELECT	DISTINCT--COUNT(p.id) _aantal, now()::date vandaag
	p.id database_id, 
	p.membership_nbr lidnummer, --p.email,
	mm.name_template, mm.write_date::date date,
	p.first_name voornaam, p.last_name achternaam,
	/*COALESCE(p.first_name,'') || ' ' || COALESCE(p.last_name,'') 										as NAW1,
	CASE	WHEN c.id = 21 AND p.crab_used = 'true' THEN COALESCE(ccs.name,'')	ELSE COALESCE(p.street,'')	END || ' ' ||
	CASE	WHEN c.id = 21 AND p.crab_used = 'true' THEN COALESCE(p.street_nbr,'') 	ELSE ''    			END || 
	CASE	WHEN COALESCE(p.street_bus,'_') = '_' OR COALESCE(p.street_bus,'') = ''  THEN '' ELSE ' bus ' || COALESCE(p.street_bus,'') 	END NAW2,
	CASE	WHEN c.id = 21 AND p.crab_used = 'true' THEN cc.zip			ELSE p.zip			END || ' ' || 
	CASE 	WHEN c.id = 21 AND p.crab_used = 'true' THEN cc.name ELSE p.city 								END NAW3,*/
	CASE	WHEN c.id = 21 AND p.crab_used = 'true' THEN COALESCE(ccs.name,'')	ELSE COALESCE(p.street,'')				END straat,
	p.street_nbr huisnummer,
	p.street_bus bus,
	p.street2 huisnaam,
	CASE	WHEN c.id = 21 AND p.crab_used = 'true' THEN cc.zip			ELSE p.zip						END postcode,
	CASE 	WHEN c.id = 21 AND p.crab_used = 'true' THEN cc.name ELSE p.city 								END woonplaats,
	--p.postbus_nbr postbus,
	c.name land,
	
	COALESCE(p.email,p.email_work) email,
	p.membership_state status,
	COALESCE(p.create_date::date,membership_start) aanmaakdatum,
	p.membership_start Lidmaatschap_startdatum, 
	p.membership_stop Lidmaatschap_einddatum, 
	mm1.name tijdschrift_1,
	mm1.name tijdschrift_1,
	p.active,
	p.address_state_id address_state, --waarde 2 is een fout adres
	p.deceased overleden
FROM 	res_partner p
	--JOIN membership_membership_line ml ON ml.partner = p.id
	--------------------------------------------
	--SQ1: ophalen van laatste lidmaatschapslijn
	--LEFT OUTER JOIN (SELECT partner ml_partner, max(id) ml_id FROM membership_membership_line ml WHERE  /*ml.partner = '55505' AND*/ ml.membership_id IN (2,5,6,7,205,206,207,208) GROUP BY ml.partner) SQ1 ON SQ1.ml_partner = p.id
	------------------------------------- SQ1 --
	-- SQ1 koppelen aan lidmaatschapslijnen om op basis van max(id) de data voor enkel die lijn op te halen
	--JOIN membership_membership_line ml ON ml.id = SQ1.ml_id
	--land, straat, gemeente info
	JOIN res_country c ON p.country_id = c.id
	LEFT OUTER JOIN res_country_city_street ccs ON p.street_id = ccs.id
	LEFT OUTER JOIN res_country_city cc ON p.zip_id = cc.id
	--tijdschriften
	LEFT OUTER JOIN mailing_mailing mm1 ON mm1.id = p.periodical_1_id
	LEFT OUTER JOIN mailing_mailing mm2 ON mm2.id = p.periodical_2_id
	--herkomst lidmaatschap
	--LEFT OUTER JOIN res_partner_membership_origin mo ON p.membership_origin_id = mo.id
	--afdeling vs afdeling eigen keuze
	--LEFT OUTER JOIN res_partner a ON p.department_id = a.id
	--LEFT OUTER JOIN res_partner a2 ON p.department_choice_id = a2.id
	--bank/mandaat info
	--LEFT OUTER JOIN res_partner_bank pb ON pb.partner_id = p.id
	--LEFT OUTER JOIN sdd_mandate sm ON sm.partner_bank_id = pb.id
	--door bank aan mandaat te linken en enkel de mandaat info te nemen ontdubbeling veroorzaakt door meerdere bankrekening nummers
	--LEFT OUTER JOIN (SELECT pb.id pb_id, pb.partner_id pb_partner_id, sm.id sm_id, sm.state sm_state, pb.bank_bic sm_bank_bic, pb.acc_number sm_acc_number FROM res_partner_bank pb JOIN sdd_mandate sm ON sm.partner_bank_id = pb.id /*WHERE sm.state = 'valid'*/) sm ON pb_partner_id = p.id
	JOIN
		(SELECT pp.name_template, mm.* 
		FROM myvar v, 
			membership_membership_magazine mm
				JOIN product_product pp ON pp.id = mm.product_id
		WHERE product_id = v.magazine
			AND mm.date_to >= v.einddatum
			AND COALESCE(date_cancel,'2099-01-01') > now()::date) mm ON mm.partner_id = p.id
--WHERE p.id = 278207	
