select count(*) from public.network_pathways_results;
select * from public.network_pathways_results limit 10;

-- Totals by year
with valByYear as(
	select distinct database, year, totalcohortcount, totalcohortwithpathcount
	from public.network_pathways_results
)
select database, SUM(totalcohortcount) total_cohort_count, SUM(totalcohortwithpathcount) total_patients_with_paths
--into public.database_totals
from valByYear
group by database
order by database
;

--"SIDIAP";2007;105;98
select step_1, sum(personcount) from public.network_pathways_results where database = 'SIDIAP' and year = 2007 group by step_1 order by sum(personcount) desc;

with byYear AS (
	select distinct database, year, totalcohortwithpathcount 
	from public.network_pathways_results 
	--where database = 'SIDIAP'
), results AS (
	SELECT y.database, y.year, y.totalcohortwithpathcount, SUM(r.personcount) personcount
	FROM byYear y
	INNER JOIN public.network_pathways_results r ON r.year = y.year and r.database = y.database --'SIDIAP'
	group by y.database, y.year, y.totalcohortwithpathcount
)
SELECT *
FROM results r
where r.totalcohortwithpathcount != r.personcount
order by r.database, r.year, r.totalcohortwithpathcount
;

-- Check out CCAE
select database, year, step_1, SUM(personcount), SUM(personcount) * 1.0/ totalcohortwithpathcount * 100
from public.network_pathways_results 
where database = 'CCAE' 
and year = '2014' 
group by database, year, step_1, totalcohortwithpathcount
order by SUM(personcount) desc;


-- First line monotherapy

--drop table public.first_line_therapy cascade;

with flMono as(
	select database, step_1, SUM(personcount) tot_personcount
	from public.network_pathways_results
	where step_1 NOT LIKE '%+%'
	group by database, step_1
), comboOfInterest AS (
	select database, '[EHDEN RA] methotrexate use + [EHDEN RA] hydroxychloroquine use' step_1, SUM(personcount) tot_personcount
	from public.network_pathways_results
	where step_1 IN (
		'[EHDEN RA] methotrexate use + [EHDEN RA] hydroxychloroquine use',
		'[EHDEN RA] hydroxychloroquine use + [EHDEN RA] methotrexate use'
	)
	group by database
), uncensored AS (
	select database, step_1, tot_personcount
	from flMono
	where tot_personcount >= 10
	union
	select database, step_1, tot_personcount
	from comboOfInterest
	where tot_personcount >= 10
), censored AS (
	select a.database, step_1, SUM(tot_personcount) tot_personcount
	from (
		SELECT database, step_1, tot_personcount
		FROM flMono
		WHERE tot_personcount < 10
		UNION
		SELECT database, step_1, tot_personcount
		FROM comboOfInterest
		WHERE tot_personcount < 10
	) a
	group by a.database, a.step_1
)
select *
from censored
where database = 'SIDIAP'

, combo AS (
	select database, 'COMBO' step_1, SUM(personcount) tot_personcount
	from public.network_pathways_results
	where step_1 LIKE '%+%'
	  and step_1 NOT IN (
		'[EHDEN RA] methotrexate use + [EHDEN RA] hydroxychloroquine use',
		'[EHDEN RA] hydroxychloroquine use + [EHDEN RA] methotrexate use'
	)
	group by database
), results AS (
	select database, step_1, tot_personcount
	from uncensored
	UNION ALL
	select database, step_1, tot_personcount
	from censored
	UNION ALL
	select database, step_1, tot_personcount
	from combo
) 
SELECT *
into public.first_line_therapy
from results
;

select flt.*, d.total_patients_with_paths
from public.first_line_therapy flt
inner join public.database_totals d ON flt.database = d.database
order by flt.database, flt.tot_personcount desc
;


-- Get the first line treatments by year
with flMonoYear as(
	select database, year, step_1, SUM(personcount) tot_personcount
	from public.network_pathways_results
	where step_1 NOT LIKE '%+%'
	group by database, year, step_1
), comboOfInterest AS (
	select database, year, '[EHDEN RA] methotrexate use + [EHDEN RA] hydroxychloroquine use' step_1, SUM(personcount) tot_personcount
	from public.network_pathways_results
	where step_1 = '[EHDEN RA] methotrexate use + [EHDEN RA] hydroxychloroquine use'
	   or step_1 = '[EHDEN RA] hydroxychloroquine use + [EHDEN RA] methotrexate use'
	group by database, year
), uncensored AS (
	select database, year, step_1, tot_personcount
	from flMonoYear
	where tot_personcount >= 10
	union
	select database, year, step_1, tot_personcount
	from comboOfInterest
	where tot_personcount >= 10
), censored AS (
	select a.database, a.year, 'CENSORED' step_1, SUM(tot_personcount) tot_personcount
	from (
		SELECT database, year, step_1, tot_personcount
		FROM flMonoYear
		WHERE tot_personcount < 10
		UNION
		SELECT database, year, step_1, tot_personcount
		FROM comboOfInterest
		WHERE tot_personcount < 10
	) a
	group by a.database, a.year
), combo AS (
	select database, year, 'COMBO' step_1, SUM(personcount) tot_personcount
	from public.network_pathways_results
	where step_1 LIKE '%+%'
	  and (step_1 <> '[EHDEN RA] methotrexate use + [EHDEN RA] hydroxychloroquine use'
	       or step_1 <> '[EHDEN RA] hydroxychloroquine use + [EHDEN RA] methotrexate use')
	group by database, year
)
select database, year, step_1, tot_personcount
from uncensored
UNION ALL
select database, year, step_1, tot_personcount
from censored
UNION ALL
select database, year, step_1, tot_personcount
from combo
order by database, year, tot_personcount desc
;

-- Get the number with 2nd line therapy count
with flMonoYear as(
	select database, year, step_1, SUM(personcount) tot_personcount
	from public.network_pathways_results
	where step_1 NOT LIKE '%+%'
	group by database, year, step_1
), uncensored AS (
	select database, year, step_1, tot_personcount
	from flMonoYear
	where tot_personcount >= 10
), censored AS (
	select database, year, 'CENSORED' step_1, SUM(tot_personcount) tot_personcount
	from flMonoYear
	where tot_personcount < 10
	group by database, year
), combo AS (
	select database, year, 'COMBO' step_1, SUM(personcount) tot_personcount
	from public.network_pathways_results
	where step_1 LIKE '%+%'
	group by database, year
)
select database, year, step_1, tot_personcount
from uncensored
UNION ALL
select database, year, step_1, tot_personcount
from censored
UNION ALL
select database, year, step_1, tot_personcount
from combo
order by database, year, tot_personcount desc
;



select distinct step_1
from public.network_pathways_results
where step_1 = '[EHDEN RA] methotrexate use + [EHDEN RA] hydroxychloroquine use'
   or step_1 = '[EHDEN RA] hydroxychloroquine use + [EHDEN RA] methotrexate use'
order by step_1
;

select step_1, sum(personcount)
from public.network_pathways_results
group by step_1
order by sum(personcount) desc
;

