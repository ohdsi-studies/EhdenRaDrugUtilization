DROP TABLE IF EXISTS public.database_totals cascade;

-- Totals by year
with npr as (
	select database, SUM(personcount) total_patients_with_paths
	from public.network_pathways_results
	group by database
), nprTotal as (
	select distinct database, year, totalcohortcount
	from public.network_pathways_results
), nprTotalAgg as (
	SELECT database, SUM(totalcohortcount) total_cohort_count
	from nprTotal
	group by database
)
SELECT npra.*, npr.total_patients_with_paths
INTO public.database_totals
FROM npr
INNER JOIN nprTotalAgg npra ON npra.database = npr.database
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
) 
SELECT *
into public.first_line_therapy_by_year
from results
order by database, year, tot_personcount desc
;
