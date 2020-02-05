drop view v_FirstLineTherapy;

create view v_FirstLineTherapy AS 

SELECT flt.*, d.total_cohort_count, d.total_patients_with_paths
FROM public.first_line_therapy flt
INNER JOIN public.database_totals d ON d.database = flt.database

;

select * from public.v_FirstLineTherapy