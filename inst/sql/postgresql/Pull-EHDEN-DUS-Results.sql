DROP TABLE IF EXISTS public.database_totals cascade;

-- Totals by year
WITH censoredYears AS (
	select database, year, SUM(personcount) total_patients_with_paths
	from public.network_pathways_results
	group by database, year HAVING SUM(personcount) < 10
), personsWithPathsByYear as (
  select npr.database, npr.year, SUM(npr.personcount) total_patients_with_paths
  from public.network_pathways_results npr
  left join censoredYears cy ON npr.database = cy.database AND npr.year = cy.year
  WHERE cy.database IS NULL
  group by npr.database, npr.year
), totalPersonsByYear as (
	select distinct npr.database, npr.year, npr.totalcohortcount
	from public.network_pathways_results npr
  left join censoredYears cy ON npr.database = cy.database AND npr.year = cy.year
  WHERE cy.database IS NULL
)
SELECT a.*, b.totalcohortcount
INTO public.database_totals
FROM personsWithPathsByYear a
INNER JOIN totalPersonsByYear b ON a.database = b.database AND a.year = b.year
;


-- First line monotherapy by year

drop table if exists public.first_line_therapy_by_year cascade;

with flMono as(
	select database, year, step_1, SUM(personcount) tot_personcount
	from public.network_pathways_results
	where step_1 NOT LIKE '%+%'
	group by database, year, step_1
), comboOfInterest AS (
	select database, year, '[EHDEN RA] methotrexate use + [EHDEN RA] hydroxychloroquine use' step_1, SUM(personcount) tot_personcount
	from public.network_pathways_results
	where step_1 IN (
		'[EHDEN RA] methotrexate use + [EHDEN RA] hydroxychloroquine use',
		'[EHDEN RA] hydroxychloroquine use + [EHDEN RA] methotrexate use'
	)
	group by database, year
), uncensored AS (
	select database, year, step_1, tot_personcount
	from flMono
	where tot_personcount >= 10
	union
	select database, year, step_1, tot_personcount
	from comboOfInterest
	where tot_personcount >= 10
), censored AS (
	select a.database, year, step_1, SUM(tot_personcount) tot_personcount
	from (
		SELECT database, year, step_1, tot_personcount
		FROM flMono
		WHERE tot_personcount < 10
		UNION
		SELECT database, year, step_1, tot_personcount
		FROM comboOfInterest
		WHERE tot_personcount < 10
	) a
	group by a.database, a.step_1, a.year
)
, combo AS (
	select database, year, 'COMBO' step_1, SUM(personcount) tot_personcount
	from public.network_pathways_results
	where step_1 LIKE '%+%'
	  and step_1 NOT IN (
		'[EHDEN RA] methotrexate use + [EHDEN RA] hydroxychloroquine use',
		'[EHDEN RA] hydroxychloroquine use + [EHDEN RA] methotrexate use'
	)
	group by database, year
), results AS (
	select database, year, step_1, tot_personcount
	from uncensored
	UNION ALL
	select database, year, step_1, tot_personcount
	from censored
	UNION ALL
	select database, year, step_1, tot_personcount
	from combo
), censoredYears AS (
	select database, year, SUM(personcount) total_patients_with_paths
	from public.network_pathways_results
	group by database, year HAVING SUM(personcount) < 10
)
SELECT r.*
into public.first_line_therapy_by_year
from results r
left join censoredYears cy ON r.database = cy.database AND r.year = cy.year
where cy.database is null
order by database, year, tot_personcount desc
;
