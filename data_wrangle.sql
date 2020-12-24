--[KHURANA] PDR vs wet AMD Cohorts with Anti-VEGF, PRP, and Both Subcohorts

--This script was used to run both the wet amd and pdr patient cohorts.
--NOTE: PDR treatment is commonly done with PRP. Wet AMD treatment is usually dont with anti-vegf injections.

--Create patient universe 

		--First, we want to focus on coding the inclusion criteria.
		--We filter for patients in Madrid2 that have:
		--all ICD codes listed in SAP inclusion criteria
		--have been diagnosed between 2013 and 2015

		--We are also creating the 'diagnosis_date' since we don’t have a diagnosis date column in Madrid2.
		--It is standard protocol to take which ever date is earliest between documentation_date and problem_onset_date in the patient_problem_laterality 
		--table in order to create the diagnosis date since they are both related to the diagnosis that the patient has. Our goal with
		--taking the earliest date is to eventually create the index date for when the patients entered this study.  
				  
		--Get 1s and 2s for right and left eyes. Split 3s into 1s (right) and 2s (left). Unspecifiied eyes are not included. 
		
		--Create pdr and wet amd indicator variables with case statement in order to create individual cohorts for pdr and wet amd for analysis in R.

		--We UNION these three datasets to stack their results into one cohesive dataset. 
		

drop table if exists khurana_diag_pull;
create temp table khurana_diag_pull as 
select * from 
(select distinct pd.patient_guid, pd.problem_code,
case when (documentation_date > problem_onset_date) and problem_onset_date is not null then problem_onset_date
when (problem_onset_date > documentation_date) and documentation_date is not null then documentation_date
when problem_onset_date is null then documentation_date
when documentation_date is null then problem_onset_date
when documentation_date=problem_onset_date then documentation_date
end as diag_date,
case when pd.diag_eye='1' then 1
when pd.diag_eye='2' then 2
end as eye,
case when (pd.problem_code ILIKE 'H35.32%'
or pd.problem_code ILIKE '362.52%') then 1 else 0 end as wet_amd,
case when (pd.problem_code ILIKE 'E11.351%'
or pd.problem_code ILIKE '362.02%'
or pd.problem_code ILIKE 'E11.355%'
or pd.problem_code ILIKE 'E11.359%') then 1 else 0 end as pdr
from madrid2.patient_problem_laterality as pd
where (pd.problem_code ILIKE 'H35.32%'
or pd.problem_code ILIKE '362.52%'
or pd.problem_code ILIKE 'E11.351%'
or pd.problem_code ILIKE '362.02%'
or pd.problem_code ILIKE 'E11.355%'
or pd.problem_code ILIKE 'E11.359%')
and (pd.diag_eye='1' or pd.diag_eye='2')
union 
select distinct pd.patient_guid, pd.problem_code,
case when (documentation_date > problem_onset_date) and problem_onset_date is not null then problem_onset_date
when (problem_onset_date > documentation_date) and documentation_date is not null then documentation_date
when problem_onset_date is null then documentation_date
when documentation_date is null then problem_onset_date
when documentation_date=problem_onset_date then documentation_date
end as diag_date,
case when pd.diag_eye='3' then 1 
end as eye,
case when (pd.problem_code ILIKE 'H35.32%'
or pd.problem_code ILIKE '362.52%') then 1 else 0 end as wet_amd,
case when (pd.problem_code ILIKE 'E11.351%'
or pd.problem_code ILIKE '362.02%'
or pd.problem_code ILIKE 'E11.355%'
or pd.problem_code ILIKE 'E11.359%') then 1 else 0 end as pdr
from madrid2.patient_problem_laterality as pd
where (pd.problem_code ILIKE 'H35.32%'
or pd.problem_code ILIKE '362.52%'
or pd.problem_code ILIKE 'E11.351%'
or pd.problem_code ILIKE '362.02%'
or pd.problem_code ILIKE 'E11.355%'
or pd.problem_code ILIKE 'E11.359%')
and pd.diag_eye='3'
union 
select distinct pd.patient_guid, pd.problem_code,
case when (documentation_date > problem_onset_date) and problem_onset_date is not null then problem_onset_date
when (problem_onset_date > documentation_date) and documentation_date is not null then documentation_date
when problem_onset_date is null then documentation_date
when documentation_date is null then problem_onset_date
when documentation_date=problem_onset_date then documentation_date
end as diag_date,
case when pd.diag_eye='3' then 2 
end as eye,
case when (pd.problem_code ILIKE 'H35.32%'
or pd.problem_code ILIKE '362.52%') then 1 else 0 end as wet_amd,
case when (pd.problem_code ILIKE 'E11.351%'
or pd.problem_code ILIKE '362.02%'
or pd.problem_code ILIKE 'E11.355%'
or pd.problem_code ILIKE 'E11.359%') then 1 else 0 end as pdr
from madrid2.patient_problem_laterality as pd
where (pd.problem_code ILIKE 'H35.32%'
or pd.problem_code ILIKE '362.52%'
or pd.problem_code ILIKE 'E11.351%'
or pd.problem_code ILIKE '362.02%'
or pd.problem_code ILIKE 'E11.355%'
or pd.problem_code ILIKE 'E11.359%')
and pd.diag_eye='3') 
where extract(year from diag_date) <= 2015;

select * from khurana_diag_pull;
select count(distinct patient_guid) from khurana_diag_pull; 
select count(*) from (select distinct patient_guid, eye from khurana_diag_pull); 

-- This is where we create our pdr or wet amd patient cohorts.
-- We switch variables depending on if we want PDR or wet AMD patients (line 121).
-- The NOT IN statement will have the condition we wish to exclude in the where statement (line 125).
-- Take earliest diag date for each patient eye & condition, people with both conditions are excluded.

DROP TABLE if exists khurana_pdr_first;
CREATE temp TABLE khurana_pdr_first as
WITH pdrsum AS (
    SELECT p.patient_guid, 
           p.diag_date, 
           p.problem_code,
           p.eye,
           ROW_NUMBER() OVER(PARTITION BY p.patient_guid, p.eye
                                 ORDER BY p.diag_date ASC) AS rk
      FROM khurana_diag_pull p
      where p.diag_date is not null
      and p.pdr=1)
SELECT s.*
FROM pdrsum s
WHERE s.rk = 1 and extract(year from s.diag_date) between 2013 and 2015
and s.patient_guid not in (select distinct patient_guid from khurana_diag_pull where wet_amd=1);


select count(distinct patient_guid) from khurana_pdr_first; 
select count(*) from (select distinct patient_guid, eye from khurana_pdr_first);  

/*PULL EYES WITH PRP or WET AMD - PRP laser*/
DROP TABLE IF EXISTS khurana_pdr_prp_proc;
CREATE temp TABLE  khurana_pdr_prp_proc as
select distinct patient_guid, procedure_date, npi, procedure_code ,
case when proc_eye='1' then 1 when proc_eye='2' then 2
end as procedure_eye
from madrid2.patient_procedure_laterality
where procedure_code ILIKE '67228%'
and patient_guid in (select distinct patient_guid from khurana_pdr_first)
and (proc_eye='1' or proc_eye='2')
UNION
select distinct patient_guid, procedure_date, npi, procedure_code,
case when proc_eye='3' then 1 
end as procedure_eye
from madrid2.patient_procedure_laterality
where procedure_code ILIKE '67228%'
and patient_guid in (select distinct patient_guid from khurana_pdr_first)
and proc_eye='3'
UNION
select distinct patient_guid, procedure_date, npi, procedure_code,
case when proc_eye='3' then 2 
end as procedure_eye
from madrid2.patient_procedure_laterality
where procedure_code ILIKE '67228%'
and patient_guid in (select distinct patient_guid from khurana_pdr_first)
and proc_eye='3';

-- get the max treatment date for prp or wet amd 
-- this is used to create the variable to calculate treatment time length
drop table if exists khurana_max_tx_prp;
create temp table khurana_max_tx_prp as 
select a.patient_guid, a.procedure_eye, a.max_tx_date_prp, b.npi,b.procedure_code
from 
(select max(procedure_date) as max_tx_date_prp, patient_guid, procedure_eye
from khurana_pdr_prp_proc
where extract(year from procedure_date) between 2013 and 2018
group by patient_guid, procedure_eye,procedure_code) as a 
inner join khurana_pdr_prp_proc as b 
on a.patient_guid=b.patient_guid
and a.procedure_eye=b.procedure_eye
and a.max_tx_date_prp=b.procedure_date
and extract(year from a.max_tx_date_prp) between 2013 and 2018;

-- get the min treatment date for prp or wet amd 
-- this is used to create the variable to calculate treatment time length 
drop table if exists khurana_min_tx_prp;
create temp table khurana_min_tx_prp as 
select a.patient_guid, a.procedure_eye, a.min_tx_date_prp, b.npi,b.procedure_code
from 
(select min(procedure_date) as min_tx_date_prp, patient_guid, procedure_eye
from khurana_pdr_prp_proc
where extract(year from procedure_date) between 2013 and 2018
group by patient_guid, procedure_eye,procedure_code) as a 
inner join khurana_pdr_prp_proc as b 
on a.patient_guid=b.patient_guid
and a.procedure_eye=b.procedure_eye
and a.min_tx_date_prp=b.procedure_date
and extract(year from a.min_tx_date_prp) between 2013 and 2018;

-- Combine all prp or wet amd  data that occur after diagnosis date
DROP TABLE if exists khurana_pdr_tx_prp;
create temp table khurana_pdr_tx_prp as 
select distinct a.patient_guid, a.eye, b.procedure_eye, a.diag_date, b.max_tx_date_prp, c.min_tx_date_prp, b.npi, 1 as prp_ind
from khurana_pdr_first a 
inner join khurana_max_tx_prp b 
on a.patient_guid=b.patient_guid
and (a.eye=b.procedure_eye)
and b.max_tx_date_prp >= a.diag_date 
inner join khurana_min_tx_prp c
on a.patient_guid=c.patient_guid
and (a.eye=c.procedure_eye)
and c.min_tx_date_prp >= a.diag_date
and b.procedure_code=c.procedure_code;

--- get max of max and min of min treatment dates per patient eye
drop table if exists khurana_pdr_tx_prp_final;
create temp table khurana_pdr_tx_prp_final AS
WITH 
calc_mode AS (
   SELECT 
		patient_guid,
		eye,
		npi, 
		COUNT(*) as totalCount,
		ROW_NUMBER() OVER (Partition BY patient_guid,eye ORDER BY COUNT(*) DESC) a
	FROM 
		khurana_pdr_tx_prp 
    GROUP BY 
		patient_guid, eye, npi),
modes AS (
SELECT 
	patient_guid, eye,
    npi
FROM 
	calc_mode
WHERE a = 1 
)
select distinct a.patient_guid,a.eye,diag_date, max(max_tx_date_prp) as max_date, min(min_tx_date_prp) as min_date,prp_ind,b.npi from khurana_pdr_tx_prp a left join modes b on a.patient_guid=b.patient_guid and a.eye=b.eye group by a.patient_guid,a.eye,diag_date,prp_ind,b.npi;

select count(distinct patient_guid) from khurana_pdr_tx_prp_final; 
select count(*) from (select distinct patient_guid,eye from khurana_pdr_tx_prp_final);  
select count(*) from khurana_pdr_tx_prp_final;

/*PULL EYES WITH ANTI VEGF*/
DROP TABLE IF EXISTS khurana_pdr_vegf_proc;
CREATE temp TABLE khurana_pdr_vegf_proc as
select distinct patient_guid, procedure_date, npi, procedure_code ,
case when proc_eye='1' then 1 when proc_eye='2' then 2
end as procedure_eye
from madrid2.patient_procedure_laterality
where procedure_code ILIKE '67028%'
and patient_guid in (select distinct patient_guid from khurana_pdr_first)
and (proc_eye='1' or proc_eye='2')
UNION
select distinct patient_guid, procedure_date, npi,procedure_code,
case when proc_eye='3' then 1 
end as procedure_eye
from madrid2.patient_procedure_laterality
where procedure_code ILIKE '67028%'
and patient_guid in (select distinct patient_guid from khurana_pdr_first)
and proc_eye='3'
UNION
select distinct patient_guid, procedure_date, npi, procedure_code,
case when proc_eye='3' then 2 
end as procedure_eye
from madrid2.patient_procedure_laterality
where procedure_code ILIKE '67028%'
and patient_guid in (select distinct patient_guid from khurana_pdr_first)
and proc_eye='3';

-- get the max treatment date for vegf
drop table if exists khurana_max_tx_vegf;
create temp table khurana_max_tx_vegf as 
select a.patient_guid, a.procedure_eye, a.max_tx_date_vegf, b.npi,b.procedure_code
from 
(select max(procedure_date) as max_tx_date_vegf, patient_guid, procedure_eye
from khurana_pdr_vegf_proc
where extract(year from procedure_date) between 2013 and 2018
group by patient_guid, procedure_eye,procedure_code) as a 
inner join khurana_pdr_vegf_proc as b 
on a.patient_guid=b.patient_guid
and a.procedure_eye=b.procedure_eye
and a.max_tx_date_vegf=b.procedure_date
and extract(year from a.max_tx_date_vegf) between 2013 and 2018;

-- get the max treatment date for vegf
drop table if exists khurana_min_tx_vegf;
create temp table khurana_min_tx_vegf as 
select a.patient_guid, a.procedure_eye, a.min_tx_date_vegf, b.npi,b.procedure_code
from 
(select min(procedure_date) as min_tx_date_vegf, patient_guid, procedure_eye
from khurana_pdr_vegf_proc
where extract(year from procedure_date) between 2013 and 2018
group by patient_guid, procedure_eye,procedure_code) as a 
inner join khurana_pdr_vegf_proc as b 
on a.patient_guid=b.patient_guid
and a.procedure_eye=b.procedure_eye
and a.min_tx_date_vegf=b.procedure_date
and extract(year from a.min_tx_date_vegf) between 2013 and 2018;

-- Combine all vegf that occur after diagnosis date
DROP TABLE if exists khurana_pdr_tx_vegf;
create temp table khurana_pdr_tx_vegf as 
select distinct a.patient_guid, a.eye, b.procedure_eye, b.procedure_code, a.problem_code, a.diag_date, b.max_tx_date_vegf, c.min_tx_date_vegf, b.npi, 1 as vegf_ind
from khurana_pdr_first a 
inner join khurana_max_tx_vegf b 
on a.patient_guid=b.patient_guid
and (a.eye=b.procedure_eye)
and b.max_tx_date_vegf >= a.diag_date 
inner join khurana_min_tx_vegf c
on a.patient_guid=c.patient_guid
and (a.eye=c.procedure_eye )
and c.min_tx_date_vegf >= a.diag_date
and b.procedure_code=c.procedure_code;

--- get max of max and min of min treatment dates per patient eye
drop table if exists khurana_pdr_tx_vegf_final;
create temp table khurana_pdr_tx_vegf_final AS
WITH 
calc_mode AS (
   SELECT 
		patient_guid,eye,
		npi, 
		COUNT(*) as totalCount,
		ROW_NUMBER() OVER (Partition BY patient_guid,eye ORDER BY COUNT(*) DESC) a
	FROM 
		khurana_pdr_tx_vegf 
    GROUP BY 
		patient_guid, eye, npi),
modes AS (
SELECT 
	patient_guid, eye,
    npi
FROM 
	calc_mode
WHERE a = 1 
)
select distinct a.patient_guid,a.eye,diag_date, max(max_tx_date_vegf) as max_date, min(min_tx_date_vegf) as min_date,vegf_ind,b.npi from khurana_pdr_tx_vegf a left join modes b on a.patient_guid=b.patient_guid and a.eye=b.eye group by a.patient_guid,a.eye,diag_date,vegf_ind,b.npi;

select count(distinct patient_guid) from khurana_pdr_tx_vegf_final;
select count(*) from (select distinct patient_guid,eye from khurana_pdr_tx_vegf_final);  
select count(*) from khurana_pdr_tx_vegf_final;

/* VEGF ONLY -- filter out prp eyes*/
DROP TABLE if exists khurana_pdr_tx_vegf_only;
create table khurana_pdr_tx_vegf_only as
select *
from khurana_pdr_tx_vegf_final
where patient_guid || '-' || eye not in (select distinct patient_guid || '-' || eye from khurana_pdr_tx_prp_final);

select count(distinct patient_guid) from khurana_pdr_tx_vegf_only; 
select count(*) from khurana_pdr_tx_vegf_only; 
select count(*) from (select distinct patient_guid,eye from khurana_pdr_tx_vegf_only);

/* PRP ONLY -- filter out anti vegf eyes*/
DROP TABLE if exists khurana_pdr_tx_prp_only;
create table khurana_pdr_tx_prp_only as
select *
from khurana_pdr_tx_prp_final
where patient_guid || '-' || eye not in (select distinct patient_guid || '-' || eye from khurana_pdr_tx_vegf_final);

select count(distinct patient_guid) from khurana_pdr_tx_prp_only; 
select count(*) from khurana_pdr_tx_prp_only; 
select count(*) from (select distinct patient_guid,eye from khurana_pdr_tx_prp_only);

/* PEOPLE WITH BOTH */
drop table if exists khurana_pdr_tx_both_1;
create temp table khurana_pdr_tx_both_1 as 
select distinct a.patient_guid, a.eye, a.diag_date,b.max_date as max_vegf,b.min_date as min_vegf,a.max_date as max_prp,a.min_date as min_prp, a.npi as npi_prp ,b.npi as npi_vegf,a.prp_ind,b.vegf_ind from khurana_pdr_tx_prp_final a inner join khurana_pdr_tx_vegf_final b on a.patient_guid=b.patient_guid and a.eye=b.eye;

select count(*) from khurana_pdr_tx_both_1; 

select * from khurana_pdr_tx_both_1;

drop table if exists khurana_pdr_tx_both_2;
create temp table khurana_pdr_tx_both_2 AS
select distinct patient_guid, eye, diag_date, 
	case when min_vegf < min_prp then npi_vegf 
	when min_vegf > min_prp then npi_prp
	when min_vegf = min_prp then npi_prp
	end as npi,
	case when max_vegf > max_prp then max_vegf
	when max_vegf < max_prp then max_prp
	when max_vegf = max_prp then max_vegf
	end as max_date,
	case when min_vegf < min_prp then max_vegf
	when min_vegf > min_prp then max_prp
	when min_vegf = min_prp then max_vegf
	end as min_date,
	 prp_ind,vegf_ind
from khurana_pdr_tx_both_1;

--- get max of max and min of min treatment dates per patient eye
drop table if exists khurana_pdr_tx_both_final;
create temp table khurana_pdr_tx_both_final AS
WITH 
calc_mode AS (
   SELECT 
		patient_guid,eye,
		npi, 
		COUNT(*) as totalCount,
		ROW_NUMBER() OVER (Partition BY patient_guid,eye ORDER BY COUNT(*) DESC) a
	FROM 
		khurana_pdr_tx_both_2 
    GROUP BY 
		patient_guid, eye, npi),
modes AS (
SELECT 
	patient_guid, eye,
    npi
FROM 
	calc_mode
WHERE a = 1 
)
select distinct a.patient_guid,a.eye,diag_date, max(max_date) as max_date, min(min_date) as min_date,b.npi from khurana_pdr_tx_both_2 a left join modes b on a.patient_guid=b.patient_guid and a.eye=b.eye group by a.patient_guid,a.eye,diag_date,b.npi;


select top 10 * from khurana_pdr_tx_both_final; 
select count(distinct patient_guid) from khurana_pdr_tx_both_final; 
select count(*) from (select distinct patient_guid,eye from khurana_pdr_tx_both_final);  
select count(*) from khurana_pdr_tx_both_final;

--- We are creating the diagnostic exclusion based on excluding patients with
-- RVO, Myopic Degeneration, and Idiopathic Choroidal Neovascularization.
-- Unspecified eyes are not included.

drop table if exists khurana_pdr_excl;
create temp table khurana_pdr_excl as 
select distinct patient_guid, problem_code, 
case when (documentation_date > problem_onset_date) and problem_onset_date is not null then problem_onset_date
when (problem_onset_date > documentation_date) and documentation_date is not null then documentation_date
when problem_onset_date is null then documentation_date
when documentation_date is null then problem_onset_date
when documentation_date=problem_onset_date then documentation_date
end as diag_date, 
case when diag_eye='1' then 1 when diag_eye='2' then 2 
end as diagnosis_eye
from madrid2.patient_problem_laterality
where (
/*RVO*/
 problem_code ilike 'H34.8%'
or problem_code ilike '362.3%'
/*Myopic Degeneration*/
or problem_code ilike 'H44.2%'
or problem_code ilike '360.21%'
/*Idiopathic Choroidal Neovascularization*/
or problem_code ilike 'H35.05%'
or problem_code ilike '362.16%')
and patient_guid in (select distinct patient_guid from khurana_pdr_tx)
and ( diag_eye='1' or diag_eye='2')
union 
select distinct patient_guid, problem_code, 
case when (documentation_date > problem_onset_date) and problem_onset_date is not null then problem_onset_date
when (problem_onset_date > documentation_date) and documentation_date is not null then documentation_date
when problem_onset_date is null then documentation_date
when documentation_date is null then problem_onset_date
when documentation_date=problem_onset_date then documentation_date
end as diag_date, 
1 as diagnosis_eye
from madrid2.patient_problem_laterality
where (
/*RVO*/
problem_code ilike 'H34.8%'
or problem_code ilike '362.3%'
/*Myopic Degeneration*/
or problem_code ilike 'H44.2%'
or problem_code ilike '360.21%'
/*Idiopathic Choroidal Neovascularization*/
or problem_code ilike 'H35.05%'
or problem_code ilike '362.16%')
and patient_guid in (select distinct patient_guid from khurana_pdr_tx)
and diag_eye='3'
union 
select distinct patient_guid, problem_code, 
case when (documentation_date > problem_onset_date) and problem_onset_date is not null then problem_onset_date
when (problem_onset_date > documentation_date) and documentation_date is not null then documentation_date
when problem_onset_date is null then documentation_date
when documentation_date is null then problem_onset_date
when documentation_date=problem_onset_date then documentation_date
end as diag_date, 
2 as diagnosis_eye
from madrid2.patient_problem_laterality
where (
/*RVO*/
problem_code ilike 'H34.8%'
or problem_code ilike '362.3%'
/*Myopic Degeneration*/
or problem_code ilike 'H44.2%'
or problem_code ilike '360.21%'
/*Idiopathic Choroidal Neovascularization*/
or problem_code ilike 'H35.05%'
or problem_code ilike '362.16%')
and patient_guid in (select distinct patient_guid from khurana_pdr_tx)
and diag_eye='3';

-- Removed patients that have the exclusion criteria before 

/* VEGF */
DROP TABLE if exists khurana_pdr_tx_vegf_excl;
create table khurana_pdr_tx_vegf_excl as 
select distinct *
from  khurana_pdr_tx_vegf_only
where patient_guid not in 
(select distinct patient_guid from 
khurana_pdr_excl);

select count(distinct patient_guid) from khurana_pdr_tx_vegf_excl; 
select count(*) from khurana_pdr_tx_vegf_excl; 
select count(*) from (select distinct patient_guid,eye from khurana_pdr_tx_vegf_excl);

/* PRP */
DROP TABLE if exists khurana_pdr_tx_prp_excl;
create table khurana_pdr_tx_prp_excl as 
select distinct *
from  khurana_pdr_tx_prp_only
where patient_guid not in 
(select distinct patient_guid from 
khurana_pdr_excl);

select count(distinct patient_guid) from khurana_pdr_tx_prp_excl; 
select count(*) from khurana_pdr_tx_prp_excl; 
select count(*) from (select distinct patient_guid,eye from khurana_pdr_tx_prp_excl_1);


/* BOTH  */
DROP TABLE if exists khurana_pdr_tx_both_excl;
create table khurana_pdr_tx_both_excl as 
select distinct *
from  khurana_pdr_tx_both_final
where patient_guid not in 
(select distinct patient_guid from 
khurana_pdr_excl);

select count(distinct patient_guid) from khurana_pdr_tx_both_excl; 
select count(*) from khurana_pdr_tx_both_excl; 

--- follow ups 
/* VEGF ONLY */
drop table if exists khurana_all_dates_vegf;
create temporary table khurana_all_dates_vegf as
select distinct patient_guid, procedure_date as patient_date
from madrid2.patient_procedure 
where patient_guid in (select distinct patient_guid from khurana_pdr_tx_vegf_excl)
and procedure_date BETWEEN '2013-01-01' AND '2019-12-31'
UNION
select distinct patient_guid, visit_start_date as patient_date
from madrid2.patient_visit
where patient_guid in (select distinct patient_guid from khurana_pdr_tx_vegf_excl)
and visit_start_date BETWEEN '2013-01-01' AND '2019-12-31'
UNION
select distinct patient_guid, result_date as patient_date
from madrid2.patient_result_va
where patient_guid in (select distinct patient_guid from khurana_pdr_tx_vegf_excl)
and result_date BETWEEN '2013-01-01' AND '2019-12-31';

-- join post-diag dates to condition cohorts and calculate date_diff, also add one year, two year, and three year dates
select top 10 * from khurana_pdr_tx_vegf_excl;

drop table if exists khurana_pdr_datediff_vegf;
create temporary table khurana_pdr_datediff_vegf as 
select a.*, a.max_date+365 as oneyrdate, a.max_date+730 as twoyrdate, a.max_date+1095 as threeyrdate, 
b.patient_date, (b.patient_date - a.max_date) as date_diff,
case when (b.patient_date - a.max_date) between 31 and 365 then 1 
else 0 end as oneyearindonemo,
case when (b.patient_date - a.max_date) between 366 and 730 then 1 
else 0 end as twoyearind,
case when (b.patient_date - a.max_date) between 731 and 1095 then 1
else 0 end as threeyearind
from khurana_pdr_tx_vegf_excl as a 
left join khurana_all_dates_vegf as b 
on a.patient_guid=b.patient_guid
where b.patient_date >= a.max_date;

drop table if exists khurana_postdiag_followup_pdr_vegf;
create temp table khurana_postdiag_followup_pdr_vegf as 
select distinct patient_guid, max(oneyearindonemo) as oneyrindonemo, max(twoyearind) as twoyrind, max(threeyearind) as threeyrind
from khurana_pdr_datediff_vegf
group by patient_guid;

select top 10 * from khurana_postdiag_followup_pdr_vegf;

drop table if exists khurana_pdr_cohort_vegf;
create table khurana_pdr_cohort_vegf as
select a.patient_guid,a.eye, a.diag_date,a.max_date,a.min_date,a.npi,b.oneyrindonemo,b.twoyrind,b.threeyrind
FROM khurana_pdr_tx_vegf_excl a inner join khurana_postdiag_followup_pdr_vegf b on a.patient_guid=b.patient_guid;

select count(*) from khurana_pdr_cohort_vegf; 

--- follow ups 
/* PRP ONLY */
drop table if exists khurana_all_dates_prp;
create temporary table khurana_all_dates_prp as
select distinct patient_guid, procedure_date as patient_date
from madrid2.patient_procedure 
where patient_guid in (select distinct patient_guid from khurana_pdr_tx_prp_excl)
and procedure_date BETWEEN '2013-01-01' AND '2019-12-31'
UNION
select distinct patient_guid, visit_start_date as patient_date
from madrid2.patient_visit
where patient_guid in (select distinct patient_guid from khurana_pdr_tx_prp_excl)
and visit_start_date BETWEEN '2013-01-01' AND '2019-12-31'
UNION
select distinct patient_guid, result_date as patient_date
from madrid2.patient_result_va
where patient_guid in (select distinct patient_guid from khurana_pdr_tx_prp_excl)
and result_date BETWEEN '2013-01-01' AND '2019-12-31';

-- join post-diag dates to condition cohorts and calculate date_diff, also add one year, two year, and three year dates
select top 10 * from khurana_pdr_tx_prp_excl;

drop table if exists khurana_pdr_datediff_prp;
create temporary table khurana_pdr_datediff_prp as 
select a.*, a.max_date+365 as oneyrdate, a.max_date+730 as twoyrdate, a.max_date+1095 as threeyrdate, 
b.patient_date, (b.patient_date - a.max_date) as date_diff,
case when (b.patient_date - a.max_date) between 31 and 365 then 1 
else 0 end as oneyearindonemo,
case when (b.patient_date - a.max_date) between 366 and 730 then 1 
else 0 end as twoyearind,
case when (b.patient_date - a.max_date) between 731 and 1095 then 1
else 0 end as threeyearind
from khurana_pdr_tx_prp_excl as a 
left join khurana_all_dates_prp as b 
on a.patient_guid=b.patient_guid
where b.patient_date >= a.max_date;

drop table if exists khurana_postdiag_followup_pdr_prp;
create temp table khurana_postdiag_followup_pdr_prp as 
select distinct patient_guid, max(oneyearindonemo) as oneyrindonemo, max(twoyearind) as twoyrind, max(threeyearind) as threeyrind
from khurana_pdr_datediff_prp
group by patient_guid;

select top 10 * from khurana_postdiag_followup_pdr_prp;

drop table if exists khurana_pdr_cohort_prp;
create table khurana_pdr_cohort_prp as
select a.patient_guid,a.eye, a.diag_date,a.max_date,a.min_date,a.npi,b.oneyrindonemo,b.twoyrind,b.threeyrind
FROM khurana_pdr_tx_prp_excl a inner join khurana_postdiag_followup_pdr_prp b on a.patient_guid=b.patient_guid;

select count(*) from khurana_pdr_cohort_prp; 
select count(*) from (select distinct patient_guid,eye from khurana_pdr_cohort_prp);

--- follow ups 
/* BOTH */
drop table if exists khurana_all_dates_both;
create temporary table khurana_all_dates_both as
select distinct patient_guid, procedure_date as patient_date
from madrid2.patient_procedure 
where patient_guid in (select distinct patient_guid from khurana_pdr_tx_both_excl)
and procedure_date BETWEEN '2013-01-01' AND '2019-12-31'
UNION
select distinct patient_guid, visit_start_date as patient_date
from madrid2.patient_visit
where patient_guid in (select distinct patient_guid from khurana_pdr_tx_both_excl)
and visit_start_date BETWEEN '2013-01-01' AND '2019-12-31'
UNION
select distinct patient_guid, result_date as patient_date
from madrid2.patient_result_va
where patient_guid in (select distinct patient_guid from khurana_pdr_tx_both_excl)
and result_date BETWEEN '2013-01-01' AND '2019-12-31';

-- join post-diag dates to condition cohorts and calculate date_diff, also add one year, two year, and three year dates


drop table if exists khurana_pdr_datediff_both;
create temporary table khurana_pdr_datediff_both as 
select a.*, a.max_date+365 as oneyrdate, a.max_date+730 as twoyrdate, a.max_date+1095 as threeyrdate, 
b.patient_date, (b.patient_date - a.max_date) as date_diff,
case when (b.patient_date - a.max_date) between 31 and 365 then 1 
else 0 end as oneyearindonemo,
case when (b.patient_date - a.max_date) between 366 and 730 then 1 
else 0 end as twoyearind,
case when (b.patient_date - a.max_date) between 731 and 1095 then 1
else 0 end as threeyearind
from khurana_pdr_tx_both_excl as a 
left join khurana_all_dates_both as b 
on a.patient_guid=b.patient_guid
where b.patient_date >= a.max_date;

drop table if exists khurana_postdiag_followup_pdr_both;
create temp table khurana_postdiag_followup_pdr_both as 
select distinct patient_guid, max(oneyearindonemo) as oneyrindonemo, max(twoyearind) as twoyrind, max(threeyearind) as threeyrind
from khurana_pdr_datediff_both
group by patient_guid;

select top 10 * from khurana_postdiag_followup_pdr_both;

drop table if exists khurana_pdr_cohort_both;
create table khurana_pdr_cohort_both as
select a.patient_guid,a.eye, a.diag_date,a.max_date,a.min_date,a.npi,b.oneyrindonemo,b.twoyrind,b.threeyrind
FROM khurana_pdr_tx_both_excl a inner join khurana_postdiag_followup_pdr_both b on a.patient_guid=b.patient_guid;


/*COUNTS*/

/* ANTI-VEGF */
select count(distinct patient_guid) from khurana_pdr_cohort_vegf; 
select count(*) from khurana_pdr_cohort_vegf; 

/* PRP */
select count(distinct patient_guid) from khurana_pdr_cohort_prp; 
select count(*) from khurana_pdr_cohort_prp; 

/* BOTH */
select count(distinct patient_guid) from khurana_pdr_cohort_both; 
select count(*) from khurana_pdr_cohort_both ; 


/* UNIQUE FOLLOW UP 1 YEAR COUNTS*/

/* ANTI-VEGF */
select count(distinct patient_guid) from khurana_pdr_cohort_vegf where oneyrindonemo = 1 ; 
select count(*) from khurana_pdr_cohort_vegf where oneyrindonemo = 1; 

/* PRP */
select count(distinct patient_guid) from khurana_pdr_cohort_prp where oneyrindonemo = 1; 
select count(*) from khurana_pdr_cohort_prp where oneyrindonemo = 1; 

/* BOTH */
select count(distinct patient_guid) from khurana_pdr_cohort_both where oneyrindonemo = 1; 
select count(*) from khurana_pdr_cohort_both where oneyrindonemo = 1; 

/* UNQIUE NO FOLLOW UP*/

/* ANTI-VEGF */
select count(distinct patient_guid) from khurana_pdr_cohort_vegf where oneyrindonemo = 0; 
select count(*) from khurana_pdr_cohort_vegf where oneyrindonemo = 0; 

/* PRP */
select count(distinct patient_guid) from khurana_pdr_cohort_prp where oneyrindonemo = 0; 
select count(*) from khurana_pdr_cohort_prp where oneyrindonemo = 0; 

/* BOTH */
select count(distinct patient_guid) from khurana_pdr_cohort_both where oneyrindonemo = 0; 
select count(*) from khurana_pdr_cohort_both where oneyrindonemo = 0; 


--------------------------------------------------------------------------------------------------------------------- PULL DEMOGRAPHICS (VEGF)
-- create eye ct variable - pdr
drop table if exists khurana_pdr_eye_vegf;
create temp table khurana_pdr_eye_vegf as 
select count(patient_guid) as eye_ct, patient_guid
from khurana_pdr_cohort_vegf
group by patient_guid;


--- race 
drop table if exists khurana_demog_process_vegf;
create temporary table khurana_demog_process_vegf as
select distinct patient_guid, year_of_birth as yob, gender, 
case when ethnicity = 'Hispanic or Latino' then 'Hispanic'
            when (ethnicity = 'Hispanic or Latino' and race = 'Declined to Answer') then 'Hispanic'
            when race = 'Caucasian' then 'White' 
            when race = '2 or more races' then 'Multi'
			when race = 'Declined to answer' then 'Unknown'
			else race end as race
from madrid2.patient_demographic
where patient_guid in (select patient_guid from khurana_pdr_cohort_vegf);


-- REGION
drop table if exists khurana_location_process_vegf;
create temp table khurana_location_process_vegf as 
select distinct npi, state, postal_code,
CASE
    when state = 'AK' then 'West'
    when state = 'CA' then 'West'
    when state = 'HI' then 'West'
    when state = 'OR' then 'West'
    when state = 'WA' then 'West'
    when state = 'AZ' then 'West'
    when state = 'CO' then 'West'
    when state = 'ID' then 'West'
    when state = 'NM' then 'West'
    when state = 'MT' then 'West'
    when state = 'UT' then 'West'
    when state = 'NV' then 'West'
    when state = 'WY' then 'West'
    when state = 'DE' then 'South'
    when state = 'DC' then 'South'
    when state = 'FL' then 'South'
    when state = 'GA' then 'South'
    when state = 'MD' then 'South'
    when state = 'NC' then 'South'
    when state = 'SC' then 'South'
    when state = 'VA' then 'South'
    when state = 'WV' then 'South'
    when state = 'AL' then 'South'
    when state = 'KY' then 'South'
    when state = 'MS' then 'South'
    when state = 'TN' then 'South'
    when state = 'AR' then 'South'
    when state = 'LA' then 'South'
    when state = 'OK' then 'South'
    when state = 'TX' then 'South'
    when state = 'IN' then 'Midwest'
    when state = 'IL' then 'Midwest'
    when state = 'MI' then 'Midwest'
    when state = 'OH' then 'Midwest'
    when state = 'WI' then 'Midwest'
    when state = 'IA' then 'Midwest'
    when state = 'KS' then 'Midwest'
    when state = 'MN' then 'Midwest'
    when state = 'MO' then 'Midwest'
    when state = 'NE' then 'Midwest'
    when state = 'ND' then 'Midwest'
    when state = 'SD' then 'Midwest'
    when state = 'CT' then 'Northeast'
    when state = 'ME' then 'Northeast'
    when state = 'MA' then 'Northeast'
    when state = 'NH' then 'Northeast'
    when state = 'RI' then 'Northeast'
    when state = 'VT' then 'Northeast'
    when state = 'NJ' then 'Northeast'
    when state = 'NY' then 'Northeast'
    when state = 'PA' then 'Northeast'
    else null end as region
from madrid2.provider_directory
where npi in (select distinct npi from khurana_pdr_cohort_vegf)
and state is not null;

DROP TABLE if exists khurana_region_process_vegf;
CREATE temp TABLE khurana_region_process_vegf as
WITH regsum AS (
    SELECT p.npi, 
           p.region, 
           p.postal_code,
           ROW_NUMBER() OVER(PARTITION BY p.npi
                                 ORDER BY p.npi ASC) AS rk
      FROM khurana_location_process_vegf p)
SELECT s.*
FROM regsum s
WHERE s.rk = 1;

-- INCOME 
drop table if exists khurana_agi_vegf;
create temp table khurana_agi_vegf as 
select distinct b.npi,
cast(b.mhi as numeric)
from 
(select distinct a.*, 
case when zip.median_household_income='' then null else zip.median_household_income end as mhi
from khurana_region_process_vegf a 
inner join aao_team.zipcode_data zip 
on substring(zip.zip,1,5) = substring(a.postal_code, 1,5)
and a.postal_code is not null 
and len(a.postal_code) >= 3) as b;

-- INSURANCE
-- additional request (insurance status)
drop table if exists khurana_ins_process1_vegf;
create temp table khurana_ins_process1_vegf as 
select distinct patient_guid, insurance_type,
case when insurance_type ilike '%No�Insurance%' then 1 else 0 end as npl, 
case when insurance_type ilike '%Misc%' then 1 else 0 end as misc,
case when insurance_type ilike '%Medicare%' then 1 else 0 end as mc,  
case when insurance_type ilike '%Military%' then 1 else 0 end as mil,
case when insurance_type ilike '%Govt%' then 1 else 0 end as govt,
case when insurance_type ilike '%Medicaid%' then 1 else 0 end as medicaid,
case when insurance_type ilike '%Commercial%' then 1 else 0 end as private,
case when (insurance_type ilike '%Unknown%' or insurance_type is NULL)
then 1 else 0 end as unkwn
from madrid2.patient_insurance 
where patient_guid in (select distinct patient_guid from khurana_pdr_cohort_vegf);

-- sum the indicators
drop table if exists khurana_ins_process2_vegf;
create temp table khurana_ins_process2_vegf as 
select distinct patient_guid, sum(npl) as npl_sum, sum(misc) as misc_sum, sum(mc) as mc_sum, 
sum(mil) as mil_sum, sum(govt) as govt_sum, sum(medicaid) as medicaid_sum,
sum(private) as private_sum, sum(unkwn) as unkwn_sum
from khurana_ins_process1_vegf
group by patient_guid;

-- denote categories
drop table if exists khurana_ins_process_final_vegf;
create temp table khurana_ins_process_final_vegf as 
select distinct patient_guid, 
case when (medicaid_sum>0 and mc_sum>0) then 'Dual'
when (private_sum>0 and mc_sum>0) then 'Medicare'
when (private_sum>0 and medicaid_sum>0) then 'Medicaid'
when private_sum>0 then 'Private'
when medicaid_sum>0 then 'Medicaid'
when mc_sum>0 then 'Medicare'
when mil_sum>0 then 'Military'
when govt_sum>0 then 'Govt' 
when misc_sum>0 then 'Private'
when (unkwn_sum>0 or npl_sum>0) then 'Unknown'
else 'Unknown'
end as ins_final
from khurana_ins_process2_vegf;


--process va change for vegf subcohort 
--get stats -> compare to R -good
drop table if exists aao_grants.lkhurana_va_process_442_vegf;
create table aao_grants.lkhurana_va_process_442_vegf as 
SELECT
	patient_guid,
	eye,
	(logmar_2-logmar) as va_change,
	ABS(date_diff_1 - date_diff_2) AS date_diff
FROM (
	SELECT
		a.*,
		c.oneyrindonemo,
		abs((b.min_date + 442) - a.result_date) AS date_diff_1,
		abs((b.max_date + 442) - a.result_date) AS date_diff_2,
		b.logmar AS logmar_2
	FROM
		khurana_pdr_va_process2_vegf AS a
		INNER JOIN khurana_pdr_va_process_first_tx_vegf AS b ON a.patient_guid = b.patient_guid
		INNER JOIN aao_grants.hosk_khurana_pdr_cohort_vegf c ON c.patient_guid = b.patient_guid
		c.patient_guid = b.patient_guid
			and(a.eye = b.eye
				or(b.eye in('1', '2'))
				or(a.eye in('1', '2'))))
WHERE
	oneyrindonemo = 0;


SELECT
	'mean' AS value,
	CAST(AVG(va_change) AS DECIMAL(10,2)) 
FROM
	aao_grants.khurana_va_process_442_vegf
UNION
SELECT
	'min' AS value,
	CAST(MIN(va_change) AS DECIMAL(10,2))
FROM
	aao_grants.khurana_va_process_442_vegf
UNION
SELECT
	'max' AS value,
	CAST(MAX(va_change) AS DECIMAL(10,2))
FROM
	aao_grants.khurana_va_process_442_vegf
UNION
SELECT
	'stddev' AS value,
	CAST(stddev(va_change) AS DECIMAL(10,2))
FROM
	aao_grants.khurana_va_process_442_vegf
UNION
SELECT
	'Q1' AS value,
	percentile_cont(0.25)
	WITHIN GROUP (ORDER BY va_change)
FROM
	aao_grants.khurana_va_process_442_vegf
UNION
SELECT
	'Q3' AS value,
	percentile_cont(0.75)
	WITHIN GROUP (ORDER BY va_change) AS Q3
FROM
	aao_grants.khurana_va_process_442_vegf;


--- NUMBER OF ANTI VEGF INJECTIONS - vegf subcohort 

-- new addition: inj up to 442 days (ADD IN DURING RERUN)
--get stats -> compare to R -good
drop table if exists aao_grants.lkhurana_inj_vegf_442;
CREATE TABLE aao_grants.lkhurana_inj_vegf_442 AS
SELECT
	patient_guid,
	patient_date as procedure_date,
	count(
		patient_guid) AS inj_ct
FROM (
	SELECT DISTINCT
		a.patient_guid,
		a.eye,
		b.patient_date
	FROM
		khurana_pdr_va_process_first_tx_vegf AS a
		inner join khurana_all_dates_vegf as b  ON a.patient_guid = b.patient_guid
		INNER JOIN aao_grants.hosk_khurana_pdr_cohort_vegf c on c.patient_guid = b.patient_guid
			and(a.eye = c.eye
				or(a.eye in(1, 2))
				or(c.eye in(1, 2)))
	WHERE
		b.patient_date BETWEEN c.diag_date
		and(a.min_date + 442))
GROUP BY
	patient_guid,
	patient_date;

SELECT * from aao_grants.hosk_khurana_pdr_cohort_vegf;

drop table if exists aao_grants.lkhurana_inj_2_vegf_442;
CREATE TABLE aao_grants.lkhurana_inj_2_vegf_442 AS SELECT DISTINCT
	patient_guid,
	extract(
		month FROM procedure_date) AS proc_month,
	sum(
		inj_ct2) AS inj_ct_sum
FROM (
	SELECT DISTINCT
		patient_guid,
		procedure_date,
		inj_ct,
		CASE WHEN inj_ct > 1 THEN
			2
		ELSE
			1
		END AS inj_ct2
	FROM
		aao_grants.khurana_inj_vegf_442)
GROUP BY
	patient_guid,
	proc_month;

drop table if exists aao_grants.khurana_inj_3_vegf_442;
CREATE TABLE aao_grants.khurana_inj_3_vegf_442 AS SELECT DISTINCT
	patient_guid,
	sum(
		inj_ct_final) AS inj_ct_final_sum
FROM (
	SELECT DISTINCT
		a.patient_guid,
		proc_month,
		inj_ct_sum,
		CASE WHEN inj_ct_sum > 4 THEN
			4
		ELSE
			inj_ct_sum
		END AS inj_ct_final
	FROM
		aao_grants.khurana_inj_2_vegf_442 a 
		INNER JOIN aao_grants.hosk_khurana_pdr_cohort_vegf b on a.patient_guid=b.patient_guid
		WHERE
	oneyrindonemo = 1)
GROUP BY
	patient_guid;


SELECT
	'mean' AS value,
	CAST(AVG(inj_ct_final_sum) AS DECIMAL(10,2)) 
FROM
	aao_grants.khurana_inj_3_vegf_442
UNION
SELECT
	'min' AS value,
	CAST(MIN(inj_ct_final_sum) AS DECIMAL(10,2))
FROM
	aao_grants.khurana_inj_3_vegf_442
UNION
SELECT
	'max' AS value,
	CAST(MAX(inj_ct_final_sum) AS DECIMAL(10,2))
FROM
	aao_grants.khurana_inj_3_vegf_442
UNION
SELECT
	'stddev' AS value,
	CAST(stddev(inj_ct_final_sum) AS DECIMAL(10,2))
FROM
	aao_grants.khurana_inj_3_vegf_442
UNION
SELECT
	'Q1' AS value,
	percentile_cont(0.25)
	WITHIN GROUP (ORDER BY inj_ct_final_sum)
FROM
	aao_grants.khurana_inj_3_vegf_442
UNION
SELECT
	'Q3' AS value,
	percentile_cont(0.75)
	WITHIN GROUP (ORDER BY inj_ct_final_sum) AS Q3
FROM
	aao_grants.khurana_inj_3_vegf_442;


--Last IRIS Visit VA >=20/40
--Last IRIS Visit VA <20/200
--get stats -> compare to R -good

drop table if exists aao_grants.last_iris_va_vegf;
CREATE TABLE aao_grants.last_iris_va_vegf AS
SELECT
	*,
	CASE
	WHEN oneyrindonemo = 1
		and((logmar IS NOT NULL
			AND logmar >= 0.3)) THEN
		1
	ELSE
		0
	END AS twentyforty_ind_442,
	
	CASE 
	WHEN oneyrindonemo = 1
		and(
			logmar < 0.3) THEN
		1
	ELSE
		0
	END AS ind_442,
	
	CASE WHEN oneyrindonemo = 0 THEN
		logmar
	ELSE
		(
			logmar - bl_va)
	END AS va_change_fix_442
FROM (
	SELECT
		a.*,
		b.logmar,
		c.bl_va,
		CASE WHEN c.bl_va IS NULL THEN
			NULL
		WHEN (d.oneyrindonemo = 1
			AND b.logmar IS NOT NULL) THEN
			b.logmar
		ELSE
			c.bl_va
		END AS one_yr_fu_va,
		b.result_date+442 AS va_442_date,
		CASE WHEN (d.oneyrindonemo = 0
			AND b.logmar IS NOT NULL) THEN
			b.logmar
		ELSE
			c.bl_va
		END AS no_one_yr_fu_va,
		d.oneyrindonemo
	FROM
		aao_grants.khurana_va_process_442_vegf AS a
		INNER JOIN madrid2.patient_result_va AS b ON a.patient_guid = b.patient_guid
		INNER JOIN khurana_pdr_cohort_vegf_total c ON c.patient_guid = b.patient_guid
		INNER JOIN aao_grants.hosk_khurana_pdr_cohort_vegf d on c.patient_guid = d.patient_guid
		WHERE one_yr_fu_va <> 999
		and no_one_yr_fu_va <> 999
		and b.logmar <> 999);


SELECT COUNT(DISTINCT patient_guid)
from aao_grants.last_iris_va_vegf
WHERE oneyrindonemo = 1 
AND logmar >= 0.3;

SELECT COUNT(DISTINCT patient_guid)
from aao_grants.last_iris_va_vegf
WHERE oneyrindonemo = 1 
AND logmar < 0.3;

SELECT COUNT(DISTINCT patient_guid)
from aao_grants.last_iris_va_vegf
WHERE oneyrindonemo = 0 
AND logmar >= 0.3;

SELECT COUNT(DISTINCT patient_guid)
from aao_grants.last_iris_va_vegf
WHERE oneyrindonemo = 0
AND logmar < 0.3;


---- DIABETES
drop table if exists khurana_bl_diab_vegf;
create temp table khurana_bl_diab_vegf as 
select distinct patient_guid, case when (documentation_date > problem_onset_date) and problem_onset_date is not null then problem_onset_date
when (problem_onset_date > documentation_date) and documentation_date is not null then documentation_date
when problem_onset_date is null then documentation_date
when documentation_date is null then problem_onset_date
when documentation_date=problem_onset_date then documentation_date
end as diag_date
from madrid2.patient_problem
where patient_guid in (select patient_guid from khurana_pdr_cohort_vegf) and 
(problem_code ilike '249.5%' 
						or problem_code ilike '250.5%' 
						or problem_code ilike '362.0' 
						or problem_code ilike '362.01%'
						or problem_code ilike 'E08.31%'
						or problem_code ilike 'E09.31%'
						or problem_code ilike 'E10.31%'
						or problem_code ilike 'E11.31%'
						or problem_code ilike 'E13.31%'
					    or problem_code ilike '362.04%' 
						or problem_code ilike '362.05%'
						or problem_code ilike '362.06%'
						or problem_code ilike 'E08.32%'
						or problem_code ilike 'E09.32%'
						or problem_code ilike 'E10.32%'
						or problem_code ilike 'E11.32%'
						or problem_code ilike 'E13.32%'
						or problem_code ilike 'E08.33%'
						or problem_code ilike 'E09.33%'
						or problem_code ilike 'E10.33%'
						or problem_code ilike 'E11.33%'
						or problem_code ilike 'E13.33%'
						or problem_code ilike 'E08.34%'
						or problem_code ilike 'E09.34%'
						or problem_code ilike 'E10.34%'
						or problem_code ilike 'E11.34%'
						or problem_code ilike 'E13.34%');
					
drop table if exists khurana_bl_diab_join_vegf;
create temp table khurana_bl_diab_join_vegf as 
select distinct a.patient_guid, 1 as diab 
from khurana_pdr_cohort_vegf as a 
inner join khurana_bl_diab_vegf as b 
on a.patient_guid=b.patient_guid
and b.diag_date <= a.max_date 
where extract(year from b.diag_date) between 2000 and 2019;

----- VA
drop table if exists khurana_va_vegf;
create temp table khurana_va_vegf as 
select distinct patient_guid, result_date, result_description, observation_description, va_type,
CAST(logmar AS DECIMAL(6, 2)),
refraction, pinhole, order_criteria,
case when eye='2' then 2 when eye='1' then 1 
end as va_eye
from madrid2.patient_result_va
where EXTRACT(YEAR FROM result_date) BETWEEN 2013 AND 2019
and patient_guid in (select distinct patient_guid from khurana_pdr_cohort_vegf)
and logmar not ilike '999'
and va_method <> 2
and CAST(logmar AS DECIMAL(6, 2)) < 3
and (eye='2' or eye='1')
UNION 
select distinct patient_guid, result_date, result_description, observation_description, va_type,
CAST(logmar AS DECIMAL(6, 2)),
refraction, pinhole, order_criteria,
case when eye='3' then 1 
end as va_eye
from madrid2.patient_result_va
where EXTRACT(YEAR FROM result_date) BETWEEN 2013 AND 2019
and patient_guid in (select distinct patient_guid from khurana_pdr_cohort_vegf)
and logmar not ilike '999'
and va_method <> 2
and CAST(logmar AS DECIMAL(6, 2)) < 3
and eye='3'
UNION 
select distinct patient_guid, result_date, result_description, observation_description, va_type,
CAST(logmar AS DECIMAL(6, 2)),
refraction, pinhole, order_criteria,
case when eye='3' then 2 
end as va_eye
from madrid2.patient_result_va
where EXTRACT(YEAR FROM result_date) BETWEEN 2013 AND 2019
and patient_guid in (select distinct patient_guid from khurana_pdr_cohort_vegf)
and logmar not ilike '999'
and va_method <> 2
and CAST(logmar AS DECIMAL(6, 2)) < 3
and eye='3'
;

-- Step 1: average per day where va_type=1 (BCVA)
drop table if exists khurana_bcva_avg_vegf;
create temp table khurana_bcva_avg_vegf as 
select distinct patient_guid, va_eye, result_date, avg(logmar) as va_avg
from khurana_va_vegf
where va_type=1
group by patient_guid, va_eye, result_date;

-- Step 2: for the patient, eyes, date combos that are NOT IN the BCVA group, we are going to create an order variable
-- 1: pinhole 2: distance 3: refraction 4: glare*/
drop table if exists khurana_va_process_vegf;
create temp table khurana_va_process_vegf as 
select distinct *, 
case when pinhole ilike 'TRUE' then 1
when refraction ilike 'TRUE' then 3
when (observation_description ilike '%glare%' or result_description ilike '%glare%') then 4 
when va_type=2 then 5
else 2 end as va_order
from khurana_va_vegf as a
where not exists 
(SELECT distinct patient_guid, va_eye
                 FROM khurana_bcva_avg_vegf as b 
                 WHERE a.patient_guid=b.patient_guid
                 and a.va_eye=b.va_eye
                 and a.result_date=b.result_date);

-- Step 3: for the non va_type=1, take value that is lowest in the order      
DROP TABLE if exists khurana_va_process2_vegf;
CREATE temp TABLE khurana_va_process2_vegf as
WITH vsum AS (
    SELECT p.patient_guid, 
           p.va_eye, 
           p.result_date, 
           p.logmar,
           p.va_order,
           ROW_NUMBER() OVER(PARTITION BY p.patient_guid, p.va_eye, p.result_date
                                 ORDER BY va_order ASC) AS rk
      FROM khurana_va_process_vegf p)
SELECT s.*
FROM vsum s
WHERE s.rk = 1
UNION 
SELECT distinct patient_guid, va_eye, result_date, va_avg as logmar, 0 as va_order, 1 as rk
from khurana_bcva_avg_vegf;

-- Step 4: find up to three values closest to treatment date, then take best VA (lowest logmar) - wet amd per patient
drop table if exists khurana_pdr_va_process_vegf;
create temp table khurana_pdr_va_process_vegf as 
WITH vapdrsum AS (
    SELECT p.*,
           ROW_NUMBER() OVER(PARTITION BY p.patient_guid, p.eye
                                 ORDER BY (p.max_date - p.result_date) ASC) AS rk
      FROM (select distinct a.patient_guid, a.eye, a.max_date, b.logmar, b.result_date
      from khurana_pdr_cohort_vegf as a
      inner join khurana_va_process2_vegf as b 
      on a.patient_guid=b.patient_guid
      and (a.eye=b.va_eye or (a.eye=4 and b.va_eye in (1,2)) or (a.eye in (1,2) and b.va_eye=4))
      and b.result_date <= a.max_date) p)
SELECT s.*
FROM vapdrsum s
WHERE s.rk <= 3;

drop table if exists khurana_pdr_va_process2_vegf;
create temp table khurana_pdr_va_process2_vegf as 
WITH vapdrsum AS (
    SELECT p.*,
           ROW_NUMBER() OVER(PARTITION BY p.patient_guid
                                 ORDER BY p.logmar ASC) AS rk1
      FROM khurana_pdr_va_process_vegf p)
SELECT s.*
FROM vapdrsum s
WHERE s.rk1=1;

---- COMBINE DEMOGRAPHICS
drop table if exists khurana_pdr_cohort_vegf_total;
create table khurana_pdr_cohort_vegf_total as 
select a.*,
c.gender, extract(year from a.max_date) - c.yob as txage, c.race, f.logmar as bl_va, f.result_date as bl_va_date, 
case when g.eye_ct=1 then 1 else 2 end as eye_involve, 
(h.max_visit_date - a.max_date) as followup_time, (h.max_visit_date - a.min_date) as tx_time, h.max_visit_date,
coalesce(j.diab,0) as diab_indicator, k.region, l.mhi, m.ins_final, n.min_visit_date
from khurana_pdr_cohort_vegf as a
left join khurana_demog_process_vegf as c
on a.patient_guid=c.patient_guid
left join khurana_pdr_va_process2_vegf as f 
on a.patient_guid=f.patient_guid
and (a.eye=f.eye or (a.eye=4 and f.eye in (1,2)) or (a.eye in (1,2) and f.eye=4))
left join khurana_pdr_eye_vegf as g 
on a.patient_guid=g.patient_guid
left join (select distinct patient_guid, max(patient_date) as max_visit_date
from khurana_all_dates_vegf
group by patient_guid) as h 
on a.patient_guid=h.patient_guid
left join khurana_bl_diab_join_vegf as j 
on a.patient_guid=j.patient_guid
left join khurana_region_process_vegf as k 
on a.npi=k.npi
left join khurana_agi_vegf as l 
on a.npi=l.npi
left join khurana_ins_process_final_vegf as m 
on a.patient_guid=m.patient_guid
left join (select distinct patient_guid, min(patient_date) as min_visit_date
from khurana_all_dates_vegf
group by patient_guid) as n
on a.patient_guid=n.patient_guid;


select count(*) from khurana_pdr_cohort_vegf_total;
select count(*) from (select distinct patient_guid,eye from khurana_pdr_cohort_vegf_total);


-- partition to get patient w/longest pdr or wet amd follow-up time

drop table if exists khurana_pdr_cohort2_vegf;
create temp table khurana_pdr_cohort2_vegf as 
WITH wasum AS (
    SELECT p.*,
           ROW_NUMBER() OVER(PARTITION BY p.patient_guid,p.eye
                                 ORDER BY p.followup_time DESC) AS rk2
      FROM khurana_pdr_cohort_vegf_total p)
SELECT s.*
FROM wasum s
WHERE s.rk2=1;

-- new addition: VA at last IRIS date

drop table if exists khurana_pdr_va_process_last_visit_vegf;
create temp table khurana_pdr_va_process_last_visit_vegf as 
WITH vawamdsum AS (
    SELECT p.*,
           ROW_NUMBER() OVER(PARTITION BY p.patient_guid, p.eye
                                 ORDER BY (p.max_visit_date - p.result_date) ASC) AS rk
      FROM (select distinct a.*, b.result_date, b.logmar
      from khurana_pdr_cohort2_vegf as a
      inner join khurana_va_process2_vegf as b 
      on a.patient_guid=b.patient_guid
      and (a.eye=b.va_eye or (a.eye=4 and b.va_eye in (1,2)) or (a.eye in (1,2) and b.va_eye=4))
      and b.result_date <= a.max_visit_date) p)
SELECT s.*
FROM vawamdsum s
WHERE s.rk <= 3;

drop table if exists khurana_pdr_va_process_last_visit2_vegf;
create temp table khurana_pdr_va_process_last_visit2_vegf as 
WITH vawamdsum AS (
    SELECT p.*,
           ROW_NUMBER() OVER(PARTITION BY p.patient_guid,p.eye
                                 ORDER BY p.logmar ASC) AS rk1
      FROM khurana_pdr_va_process_last_visit_vegf p)
SELECT s.*
FROM vawamdsum s
WHERE s.rk1=1 and (bl_va_date <> result_date);



-- final cohort for khurana pdr or wet amd

drop table if exists aao_grants.hosk_khurana_pdr_cohort_vegf;
create table aao_grants.hosk_khurana_pdr_cohort_vegf as 
select distinct a.patient_guid, a.eye, a.diag_date, a.max_date, a.min_date,
a.oneyrindonemo, a.twoyrind, a.threeyrind, a.gender, a.txage, a.race, a.bl_va, 
a.eye_involve, a.followup_time, a.tx_time, a.max_visit_date, 
 a.diab_indicator, a.region, a.mhi, a.ins_final,
a.min_visit_date, 
case when (b.logmar is not null and b.logmar <= 0.3) then 1 else 0 end as twentyforty_ind, 
case when (b.logmar > 1) then 1 else 0 end as twentytwohundred_ind,
(b.logmar - a.bl_va) as va_change, b.logmar as folup_va, b.result_date as folup_va_date
from khurana_pdr_cohort2_vegf as a 
left join khurana_pdr_va_process_last_visit2_vegf as b 
on a.patient_guid=b.patient_guid;

--a.visit_time, removed from above 
select count(patient_guid) from aao_grants.hosk_khurana_pdr_cohort_vegf; 


-- new addition: VA at first tx date (ADD IN DURING RERUN)

drop table if exists khurana_pdr_va_process_first_tx_vegf;
create temp table khurana_pdr_va_process_first_tx_vegf as 
WITH vawamdtxsum AS (
    SELECT p.*,
           ROW_NUMBER() OVER(PARTITION BY p.patient_guid, p.eye
                                 ORDER BY (p.min_date - p.result_date) ASC) AS rk
      FROM (select distinct a.*, b.result_date, b.logmar
      from aao_grants.hosk_khurana_pdr_cohort_vegf as a
      inner join khurana_va_process2_vegf as b 
      on a.patient_guid=b.patient_guid
      and (a.eye=b.va_eye or (b.va_eye in (1,2)) or (a.eye in (1,2))
      and b.result_date <= a.min_date) )p)
SELECT s.*
FROM vawamdtxsum s
WHERE s.rk <= 3;

drop table if exists khurana_pdr_va_process_first_tx2;
create temp table khurana_pdr_va_process_first_tx2 as 
WITH vawamdsum AS (
    SELECT p.*,
           ROW_NUMBER() OVER(PARTITION BY p.patient_guid
                                 ORDER BY p.logmar ASC) AS rk1
      FROM khurana_pdr_va_process_first_tx_vegf p)
SELECT s.*
FROM vawamdsum s
WHERE s.rk1=1 and (folup_va_date <> result_date);

drop table if exists aao_grants.hosk_khurana_pdr_cohort_fix_vegf;
create table aao_grants.hosk_khurana_pdr_cohort_fix_vegf as 
select distinct a.*, b.logmar as first_tx_va, (a.folup_va - b.logmar) as va_change_fix
from aao_grants.hosk_khurana_pdr_cohort_vegf as a 
left join khurana_pdr_va_process_first_tx_vegf as b 
on a.patient_guid=b.patient_guid;

select distinct patient_guid, folup_va, first_tx_va, va_change_fix 
from aao_grants.hosk_khurana_pdr_cohort_fix limit 100;

select count(*) from aao_grants.hosk_khurana_pdr_cohort_fix_vegf;

-- Create demographic variables (PRP)

-- create eye ct variable 
drop table if exists khurana_pdr_eye_prp;
create temp table khurana_pdr_eye_prp as 
select count(patient_guid) as eye_ct, patient_guid
from khurana_pdr_cohort_prp
group by patient_guid;

--- race 
drop table if exists khurana_demog_process_prp;
create temporary table khurana_demog_process_prp as
select distinct patient_guid, year_of_birth as yob, gender, 
case when ethnicity = 'Hispanic or Latino' then 'Hispanic'
            when (ethnicity = 'Hispanic or Latino' and race = 'Declined to Answer') then 'Hispanic'
            when race = 'Caucasian' then 'White' 
            when race = '2 or more races' then 'Multi'
			when race = 'Declined to answer' then 'Unknown'
			else race end as race
from madrid2.patient_demographic
where patient_guid in (select patient_guid from khurana_pdr_cohort_prp);


-- REGION
drop table if exists khurana_location_process_prp;
create temp table khurana_location_process_prp as 
select distinct npi, state, postal_code,
CASE
    when state = 'AK' then 'West'
    when state = 'CA' then 'West'
    when state = 'HI' then 'West'
    when state = 'OR' then 'West'
    when state = 'WA' then 'West'
    when state = 'AZ' then 'West'
    when state = 'CO' then 'West'
    when state = 'ID' then 'West'
    when state = 'NM' then 'West'
    when state = 'MT' then 'West'
    when state = 'UT' then 'West'
    when state = 'NV' then 'West'
    when state = 'WY' then 'West'
    when state = 'DE' then 'South'
    when state = 'DC' then 'South'
    when state = 'FL' then 'South'
    when state = 'GA' then 'South'
    when state = 'MD' then 'South'
    when state = 'NC' then 'South'
    when state = 'SC' then 'South'
    when state = 'VA' then 'South'
    when state = 'WV' then 'South'
    when state = 'AL' then 'South'
    when state = 'KY' then 'South'
    when state = 'MS' then 'South'
    when state = 'TN' then 'South'
    when state = 'AR' then 'South'
    when state = 'LA' then 'South'
    when state = 'OK' then 'South'
    when state = 'TX' then 'South'
    when state = 'IN' then 'Midwest'
    when state = 'IL' then 'Midwest'
    when state = 'MI' then 'Midwest'
    when state = 'OH' then 'Midwest'
    when state = 'WI' then 'Midwest'
    when state = 'IA' then 'Midwest'
    when state = 'KS' then 'Midwest'
    when state = 'MN' then 'Midwest'
    when state = 'MO' then 'Midwest'
    when state = 'NE' then 'Midwest'
    when state = 'ND' then 'Midwest'
    when state = 'SD' then 'Midwest'
    when state = 'CT' then 'Northeast'
    when state = 'ME' then 'Northeast'
    when state = 'MA' then 'Northeast'
    when state = 'NH' then 'Northeast'
    when state = 'RI' then 'Northeast'
    when state = 'VT' then 'Northeast'
    when state = 'NJ' then 'Northeast'
    when state = 'NY' then 'Northeast'
    when state = 'PA' then 'Northeast'
    else null end as region
from madrid2.provider_directory
where npi in (select distinct npi from khurana_pdr_cohort_prp)
and state is not null;

DROP TABLE if exists khurana_region_process_prp;
CREATE temp TABLE khurana_region_process_prp as
WITH regsum AS (
    SELECT p.npi, 
           p.region, 
           p.postal_code,
           ROW_NUMBER() OVER(PARTITION BY p.npi
                                 ORDER BY p.npi ASC) AS rk
      FROM khurana_location_process_prp p)
SELECT s.*
FROM regsum s
WHERE s.rk = 1;

-- INCOME 
drop table if exists khurana_agi_prp;
create temp table khurana_agi_prp as 
select distinct b.npi,
cast(b.mhi as numeric)
from 
(select distinct a.*, 
case when zip.median_household_income='' then null else zip.median_household_income end as mhi
from khurana_region_process_prp a 
inner join aao_team.zipcode_data zip 
on substring(zip.zip,1,5) = substring(a.postal_code, 1,5)
and a.postal_code is not null 
and len(a.postal_code) >= 3) as b;

-- INSURANCE
-- additional request (insurance status)
drop table if exists khurana_ins_process1_prp;
create temp table khurana_ins_process1_prp as 
select distinct patient_guid, insurance_type,
case when insurance_type ilike '%No�Insurance%' then 1 else 0 end as npl, 
case when insurance_type ilike '%Misc%' then 1 else 0 end as misc,
case when insurance_type ilike '%Medicare%' then 1 else 0 end as mc,  
case when insurance_type ilike '%Military%' then 1 else 0 end as mil,
case when insurance_type ilike '%Govt%' then 1 else 0 end as govt,
case when insurance_type ilike '%Medicaid%' then 1 else 0 end as medicaid,
case when insurance_type ilike '%Commercial%' then 1 else 0 end as private,
case when (insurance_type ilike '%Unknown%' or insurance_type is NULL)
then 1 else 0 end as unkwn
from madrid2.patient_insurance 
where patient_guid in (select distinct patient_guid from khurana_pdr_cohort_prp);

-- sum the indicators
drop table if exists khurana_ins_process2_prp;
create temp table khurana_ins_process2_prp as 
select distinct patient_guid, sum(npl) as npl_sum, sum(misc) as misc_sum, sum(mc) as mc_sum, 
sum(mil) as mil_sum, sum(govt) as govt_sum, sum(medicaid) as medicaid_sum,
sum(private) as private_sum, sum(unkwn) as unkwn_sum
from khurana_ins_process1_prp
group by patient_guid;

-- denote categories
drop table if exists khurana_ins_process_final_prp;
create temp table khurana_ins_process_final_prp as 
select distinct patient_guid, 
case when (medicaid_sum>0 and mc_sum>0) then 'Dual'
when (private_sum>0 and mc_sum>0) then 'Medicare'
when (private_sum>0 and medicaid_sum>0) then 'Medicaid'
when private_sum>0 then 'Private'
when medicaid_sum>0 then 'Medicaid'
when mc_sum>0 then 'Medicare'
when mil_sum>0 then 'Military'
when govt_sum>0 then 'Govt' 
when misc_sum>0 then 'Private'
when (unkwn_sum>0 or npl_sum>0) then 'Unknown'
else 'Unknown'
end as ins_final
from khurana_ins_process2_prp;


--- NUMBER OF INJECTIONS (SKIPPED)

---- DIABETES
drop table if exists khurana_bl_diab_prp;
create temp table khurana_bl_diab_prp as 
select distinct patient_guid, case when (documentation_date > problem_onset_date) and problem_onset_date is not null then problem_onset_date
when (problem_onset_date > documentation_date) and documentation_date is not null then documentation_date
when problem_onset_date is null then documentation_date
when documentation_date is null then problem_onset_date
when documentation_date=problem_onset_date then documentation_date
end as diag_date
from madrid2.patient_problem
where patient_guid in (select patient_guid from khurana_pdr_cohort_prp) and 
(problem_code ilike '249.5%' 
						or problem_code ilike '250.5%' 
						or problem_code ilike '362.0' 
						or problem_code ilike '362.01%'
						or problem_code ilike 'E08.31%'
						or problem_code ilike 'E09.31%'
						or problem_code ilike 'E10.31%'
						or problem_code ilike 'E11.31%'
						or problem_code ilike 'E13.31%'
					    or problem_code ilike '362.04%' 
						or problem_code ilike '362.05%'
						or problem_code ilike '362.06%'
						or problem_code ilike 'E08.32%'
						or problem_code ilike 'E09.32%'
						or problem_code ilike 'E10.32%'
						or problem_code ilike 'E11.32%'
						or problem_code ilike 'E13.32%'
						or problem_code ilike 'E08.33%'
						or problem_code ilike 'E09.33%'
						or problem_code ilike 'E10.33%'
						or problem_code ilike 'E11.33%'
						or problem_code ilike 'E13.33%'
						or problem_code ilike 'E08.34%'
						or problem_code ilike 'E09.34%'
						or problem_code ilike 'E10.34%'
						or problem_code ilike 'E11.34%'
						or problem_code ilike 'E13.34%');
					
drop table if exists khurana_bl_diab_join_prp;
create temp table khurana_bl_diab_join_prp as 
select distinct a.patient_guid, 1 as diab 
from khurana_pdr_cohort_prp as a 
inner join khurana_bl_diab_prp as b 
on a.patient_guid=b.patient_guid
and b.diag_date <= a.max_date 
where extract(year from b.diag_date) between 2000 and 2019;

----- VA
drop table if exists khurana_va_prp;
create temp table khurana_va_prp as 
select distinct patient_guid, result_date, result_description, observation_description, va_type,
CAST(logmar AS DECIMAL(6, 2)),
refraction, pinhole, order_criteria,
case when eye='2' then 2 when eye='1' then 1 
end as va_eye
from madrid2.patient_result_va
where EXTRACT(YEAR FROM result_date) BETWEEN 2013 AND 2019
and patient_guid in (select distinct patient_guid from khurana_pdr_cohort_prp)
and logmar not ilike '999'
and va_method <> 2
and CAST(logmar AS DECIMAL(6, 2)) < 3
and (eye='2' or eye='1')
UNION 
select distinct patient_guid, result_date, result_description, observation_description, va_type,
CAST(logmar AS DECIMAL(6, 2)),
refraction, pinhole, order_criteria,
case when eye='3' then 1 
end as va_eye
from madrid2.patient_result_va
where EXTRACT(YEAR FROM result_date) BETWEEN 2013 AND 2019
and patient_guid in (select distinct patient_guid from khurana_pdr_cohort_prp)
and logmar not ilike '999'
and va_method <> 2
and CAST(logmar AS DECIMAL(6, 2)) < 3
and eye='3'
UNION 
select distinct patient_guid, result_date, result_description, observation_description, va_type,
CAST(logmar AS DECIMAL(6, 2)),
refraction, pinhole, order_criteria,
case when eye='3' then 2 
end as va_eye
from madrid2.patient_result_va
where EXTRACT(YEAR FROM result_date) BETWEEN 2013 AND 2019
and patient_guid in (select distinct patient_guid from khurana_pdr_cohort_prp)
and logmar not ilike '999'
and va_method <> 2
and CAST(logmar AS DECIMAL(6, 2)) < 3
and eye='3'
;

-- Step 1: average per day where va_type=1 (BCVA)
drop table if exists khurana_bcva_avg_prp;
create temp table khurana_bcva_avg_prp as 
select distinct patient_guid, va_eye, result_date, avg(logmar) as va_avg
from khurana_va_prp
where va_type=1
group by patient_guid, va_eye, result_date;

-- Step 2: for the patient, eyes, date combos that are NOT IN the BCVA group, we are going to create an order variable
-- 1: pinhole 2: distance 3: refraction 4: glare*/
drop table if exists khurana_va_process_prp;
create temp table khurana_va_process_prp as 
select distinct *, 
case when pinhole ilike 'TRUE' then 1
when refraction ilike 'TRUE' then 3
when (observation_description ilike '%glare%' or result_description ilike '%glare%') then 4 
when va_type=2 then 5
else 2 end as va_order
from khurana_va_prp as a
where not exists 
(SELECT distinct patient_guid, va_eye
                 FROM khurana_bcva_avg_prp as b 
                 WHERE a.patient_guid=b.patient_guid
                 and a.va_eye=b.va_eye
                 and a.result_date=b.result_date);

-- Step 3: for the non va_type=1, take value that is lowest in the order      
DROP TABLE if exists khurana_va_process2_prp;
CREATE temp TABLE khurana_va_process2_prp as
WITH vsum AS (
    SELECT p.patient_guid, 
           p.va_eye, 
           p.result_date, 
           p.logmar,
           p.va_order,
           ROW_NUMBER() OVER(PARTITION BY p.patient_guid, p.va_eye, p.result_date
                                 ORDER BY va_order ASC) AS rk
      FROM khurana_va_process_prp p)
SELECT s.*
FROM vsum s
WHERE s.rk = 1
UNION 
SELECT distinct patient_guid, va_eye, result_date, va_avg as logmar, 0 as va_order, 1 as rk
from khurana_bcva_avg_prp;

-- Step 4: find up to three values closest to treatment date, then take best VA (lowest logmar) - wet amd per patient
drop table if exists khurana_pdr_va_process_prp;
create temp table khurana_pdr_va_process_prp as 
WITH vapdrsum AS (
    SELECT p.*,
           ROW_NUMBER() OVER(PARTITION BY p.patient_guid, p.eye
                                 ORDER BY (p.max_date - p.result_date) ASC) AS rk
      FROM (select distinct a.patient_guid, a.eye, a.max_date, b.logmar, b.result_date
      from khurana_pdr_cohort_prp as a
      inner join khurana_va_process2_prp as b 
      on a.patient_guid=b.patient_guid
      and (a.eye=b.va_eye or (a.eye=4 and b.va_eye in (1,2)) or (a.eye in (1,2) and b.va_eye=4))
      and b.result_date <= a.max_date) p)
SELECT s.*
FROM vapdrsum s
WHERE s.rk <= 3;

drop table if exists khurana_pdr_va_process2_prp;
create temp table khurana_pdr_va_process2_prp as 
WITH vapdrsum AS (
    SELECT p.*,
           ROW_NUMBER() OVER(PARTITION BY p.patient_guid
                                 ORDER BY p.logmar ASC) AS rk1
      FROM khurana_pdr_va_process_prp p)
SELECT s.*
FROM vapdrsum s
WHERE s.rk1=1;



--get change in VA in prp cohort between first and last IRIS dates and calculate descriptive statistics
--impose 442 day restriction
drop table if exists aao_grants.khurana_va_process_442_prp;
create table aao_grants.khurana_va_process_442_prp as 
SELECT
	patient_guid,
	eye,
	(logmar_2-logmar) as va_change,
	ABS(date_diff_1 - date_diff_2) AS date_diff
FROM (
	SELECT
		a.*,
		c.oneyrindonemo,
		abs((b.min_date + 442) - a.result_date) AS date_diff_1,
		abs((b.max_date + 442) - a.result_date) AS date_diff_2,
		b.logmar AS logmar_2
	FROM
		khurana_pdr_va_process2_prp AS a
		INNER JOIN khurana_pdr_va_process_first_tx_prp AS b ON a.patient_guid = b.patient_guid
		INNER JOIN aao_grants.hosk_khurana_pdr_cohort_prp c ON c.patient_guid = b.patient_guid
			and(a.eye = b.eye
				or(b.eye in('1', '2'))
				or(a.eye in('1', '2'))))
WHERE
	oneyrindonemo = 1;

	

SELECT
	'mean' AS value,
	CAST(AVG(va_change) AS DECIMAL(10,2)) 
FROM
	aao_grants.khurana_va_process_442_prp
UNION
SELECT
	'min' AS value,
	CAST(MIN(va_change) AS DECIMAL(10,2))
FROM
	aao_grants.khurana_va_process_442_prp
UNION
SELECT
	'max' AS value,
	CAST(MAX(va_change) AS DECIMAL(10,2))
FROM
	aao_grants.khurana_va_process_442_prp
UNION
SELECT
	'stddev' AS value,
	CAST(stddev(va_change) AS DECIMAL(10,2))
FROM
	aao_grants.khurana_va_process_442_prp
UNION
SELECT
	'Q1' AS value,
	percentile_cont(0.25)
	WITHIN GROUP (ORDER BY va_change)
FROM
	aao_grants.khurana_va_process_442_prp
UNION
SELECT
	'Q3' AS value,
	percentile_cont(0.75)
	WITHIN GROUP (ORDER BY va_change) AS Q3
FROM
	aao_grants.khurana_va_process_442_prp;


--Last IRIS Visit VA >=20/40
--Last IRIS Visit VA <20/200

drop table if exists aao_grants.last_iris_va_prp;
CREATE TABLE aao_grants.last_iris_va_prp AS
SELECT
	*,
	CASE
	WHEN oneyrindonemo = 1
		and((logmar IS NOT NULL
			AND logmar >= 0.3)) THEN
		1
	ELSE
		0
	END AS twentyforty_ind_442,
	
	CASE 
	WHEN oneyrindonemo = 1
		and(
			logmar < 0.3) THEN
		1
	ELSE
		0
	END AS ind_442,
	
	CASE WHEN oneyrindonemo = 0 THEN
		logmar
	ELSE
		(
			logmar - bl_va)
	END AS va_change_fix_442
FROM (
	SELECT
		a.*,
		b.logmar,
		c.bl_va,
		CASE WHEN c.bl_va IS NULL THEN
			NULL
		WHEN (d.oneyrindonemo = 1
			AND b.logmar IS NOT NULL) THEN
			b.logmar
		ELSE
			c.bl_va
		END AS one_yr_fu_va,
		b.result_date+442 AS va_442_date,
		CASE WHEN (d.oneyrindonemo = 0
			AND b.logmar IS NOT NULL) THEN
			b.logmar
		ELSE
			c.bl_va
		END AS no_one_yr_fu_va,
		d.oneyrindonemo
	FROM
		aao_grants.khurana_va_process_442_prp AS a
		INNER JOIN madrid2.patient_result_va AS b ON a.patient_guid = b.patient_guid
		INNER JOIN khurana_pdr_cohort_prp_total c ON c.patient_guid = b.patient_guid
		INNER JOIN aao_grants.hosk_khurana_pdr_cohort_prp d on c.patient_guid = d.patient_guid
		WHERE one_yr_fu_va <> 999
		and no_one_yr_fu_va <> 999
		and b.logmar <> 999);


SELECT COUNT(DISTINCT patient_guid)
from last_iris_va_prp
WHERE oneyrindonemo = 1 
AND logmar <= 0.3;

SELECT COUNT(DISTINCT patient_guid)
from last_iris_va_prp
WHERE oneyrindonemo = 1 
AND logmar > 0.3;

SELECT COUNT(DISTINCT patient_guid)
from last_iris_va_prp
WHERE oneyrindonemo = 0 
AND logmar <= 0.3;

SELECT COUNT(DISTINCT patient_guid)
from last_iris_va_prp
WHERE oneyrindonemo = 0
AND logmar > 0.3;

---- COMBINE DEMOGRAPHICS prp
drop table if exists khurana_pdr_cohort_prp_total;
create table khurana_pdr_cohort_prp_total as 
select a.*,
c.gender, extract(year from a.max_date) - c.yob as txage, c.race, f.logmar as bl_va, f.result_date as bl_va_date, 
case when g.eye_ct=1 then 1 else 2 end as eye_involve, 
(h.max_visit_date - a.max_date) as followup_time, (h.max_visit_date - a.min_date) as tx_time, h.max_visit_date,
coalesce(j.diab,0) as diab_indicator, k.region, l.mhi, m.ins_final, n.min_visit_date
from khurana_pdr_cohort_prp as a
left join khurana_demog_process_prp as c
on a.patient_guid=c.patient_guid
left join khurana_pdr_va_process2_prp as f 
on a.patient_guid=f.patient_guid
and (a.eye=f.eye or (a.eye=4 and f.eye in (1,2)) or (a.eye in (1,2) and f.eye=4))
left join khurana_pdr_eye_prp as g 
on a.patient_guid=g.patient_guid
left join (select distinct patient_guid, max(patient_date) as max_visit_date
from khurana_all_dates_prp
group by patient_guid) as h 
on a.patient_guid=h.patient_guid
left join khurana_bl_diab_join_prp as j 
on a.patient_guid=j.patient_guid
left join khurana_region_process_prp as k 
on a.npi=k.npi
left join khurana_agi_prp as l 
on a.npi=l.npi
left join khurana_ins_process_final_prp as m 
on a.patient_guid=m.patient_guid
left join (select distinct patient_guid, min(patient_date) as min_visit_date
from khurana_all_dates_prp
group by patient_guid) as n
on a.patient_guid=n.patient_guid;


select count(*) from khurana_pdr_cohort_prp_total;
select count(*) from (select distinct patient_guid,eye from khurana_pdr_cohort_prp_total);


-- partition to get patient w/longest pdr or wet amd follow-up time

drop table if exists khurana_pdr_cohort2_prp;
create temp table khurana_pdr_cohort2_prp as 
WITH wasum AS (
    SELECT p.*,
           ROW_NUMBER() OVER(PARTITION BY p.patient_guid,p.eye
                                 ORDER BY p.followup_time DESC) AS rk2
      FROM khurana_pdr_cohort_prp_total p)
SELECT s.*
FROM wasum s
WHERE s.rk2=1;

-- new addition: VA at last IRIS date

drop table if exists khurana_pdr_va_process_last_visit_prp;
create temp table khurana_pdr_va_process_last_visit_prp as 
WITH vawamdsum AS (
    SELECT p.*,
           ROW_NUMBER() OVER(PARTITION BY p.patient_guid, p.eye
                                 ORDER BY (p.max_visit_date - p.result_date) ASC) AS rk
      FROM (select distinct a.*, b.result_date, b.logmar
      from khurana_pdr_cohort2_prp as a
      inner join khurana_va_process2_prp as b 
      on a.patient_guid=b.patient_guid
      and (a.eye=b.va_eye or (a.eye=4 and b.va_eye in (1,2)) or (a.eye in (1,2) and b.va_eye=4))
      and b.result_date <= a.max_visit_date) p)
SELECT s.*
FROM vawamdsum s
WHERE s.rk <= 3;

drop table if exists khurana_pdr_va_process_last_visit2_prp;
create temp table khurana_pdr_va_process_last_visit2_prp as 
WITH vawamdsum AS (
    SELECT p.*,
           ROW_NUMBER() OVER(PARTITION BY p.patient_guid,p.eye
                                 ORDER BY p.logmar ASC) AS rk1
      FROM khurana_pdr_va_process_last_visit_prp p)
SELECT s.*
FROM vawamdsum s
WHERE s.rk1=1 and (bl_va_date <> result_date);

-- final cohort for khurana wet amd or pdr

drop table if exists aao_grants.hosk_khurana_pdr_cohort_prp;
create table aao_grants.hosk_khurana_pdr_cohort_prp as 
select distinct a.patient_guid, a.eye, a.diag_date, a.max_date, a.min_date,
a.oneyrindonemo, a.twoyrind, a.threeyrind, a.gender, a.txage, a.race, a.bl_va, 
a.eye_involve, a.followup_time, a.tx_time, a.max_visit_date, 
 a.diab_indicator, a.region, a.mhi, a.ins_final,
a.min_visit_date, 
case when (b.logmar is not null and b.logmar <= 0.3) then 1 else 0 end as twentyforty_ind, 
case when (b.logmar > 1) then 1 else 0 end as twentytwohundred_ind,
(b.logmar - a.bl_va) as va_change, b.logmar as folup_va, b.result_date as folup_va_date
from khurana_pdr_cohort2_prp as a 
left join khurana_pdr_va_process_last_visit2_prp as b 
on a.patient_guid=b.patient_guid;

--a.visit_time, removed from above 
select count(patient_guid) from aao_grants.hosk_khurana_pdr_cohort_prp; 


-- new addition: VA at first tx date (ADD IN DURING RERUN)

drop table if exists khurana_pdr_va_process_first_tx_prp;
create temp table khurana_pdr_va_process_first_tx_prp as 
WITH vawamdtxsum AS (
    SELECT p.*,
           ROW_NUMBER() OVER(PARTITION BY p.patient_guid, p.eye
                                 ORDER BY (p.min_date - p.result_date) ASC) AS rk
      FROM (select distinct a.*, b.result_date, b.logmar
      from aao_grants.hosk_khurana_pdr_cohort_prp as a
      inner join khurana_va_process2_prp as b 
      on a.patient_guid=b.patient_guid
      and (a.eye=b.va_eye or (a.eye=4 and b.va_eye in (1,2)) or (a.eye in (1,2) and b.va_eye=4))
      and b.result_date <= a.min_date) p)
SELECT s.*
FROM vawamdtxsum s
WHERE s.rk <= 3;

drop table if exists khurana_pdr_va_process_first_tx2_prp;
create temp table khurana_pdr_va_process_first_tx2_prp as 
WITH vawamdsum AS (
    SELECT p.*,
           ROW_NUMBER() OVER(PARTITION BY p.patient_guid
                                 ORDER BY p.logmar ASC) AS rk1
      FROM khurana_pdr_va_process_first_tx_prp p)
SELECT s.*
FROM vawamdsum s
WHERE s.rk1=1 and (folup_va_date <> result_date);

drop table if exists aao_grants.hosk_khurana_pdr_cohort_fix_prp;
create table aao_grants.hosk_khurana_pdr_cohort_fix_prp as 
select distinct a.*, b.logmar as first_tx_va, (a.folup_va - b.logmar) as va_change_fix
from aao_grants.hosk_khurana_pdr_cohort_prp as a 
left join khurana_pdr_va_process_first_tx2_prp as b 
on a.patient_guid=b.patient_guid;

select distinct patient_guid, folup_va, first_tx_va, va_change_fix 
from aao_grants.hosk_khurana_pdr_cohort_fix limit 100;

select count(*) from aao_grants.hosk_khurana_pdr_cohort_fix_prp;

--------------------------------------------------------------------------------------------------------------------- PULL DEMOGRAPHICS (BOTH)
-- create eye ct variable - pdr
drop table if exists khurana_pdr_eye_both;
create temp table khurana_pdr_eye_both as 
select count(patient_guid) as eye_ct, patient_guid
from khurana_pdr_cohort_both
group by patient_guid;

--- race 
drop table if exists khurana_demog_process_both;
create temporary table khurana_demog_process_both as
select distinct patient_guid, year_of_birth as yob, gender, 
case when ethnicity = 'Hispanic or Latino' then 'Hispanic'
            when (ethnicity = 'Hispanic or Latino' and race = 'Declined to Answer') then 'Hispanic'
            when race = 'Caucasian' then 'White' 
            when race = '2 or more races' then 'Multi'
			when race = 'Declined to answer' then 'Unknown'
			else race end as race
from madrid2.patient_demographic
where patient_guid in (select patient_guid from khurana_pdr_cohort_both);


-- REGION
drop table if exists khurana_location_process_both;
create temp table khurana_location_process_both as 
select distinct npi, state, postal_code,
CASE
    when state = 'AK' then 'West'
    when state = 'CA' then 'West'
    when state = 'HI' then 'West'
    when state = 'OR' then 'West'
    when state = 'WA' then 'West'
    when state = 'AZ' then 'West'
    when state = 'CO' then 'West'
    when state = 'ID' then 'West'
    when state = 'NM' then 'West'
    when state = 'MT' then 'West'
    when state = 'UT' then 'West'
    when state = 'NV' then 'West'
    when state = 'WY' then 'West'
    when state = 'DE' then 'South'
    when state = 'DC' then 'South'
    when state = 'FL' then 'South'
    when state = 'GA' then 'South'
    when state = 'MD' then 'South'
    when state = 'NC' then 'South'
    when state = 'SC' then 'South'
    when state = 'VA' then 'South'
    when state = 'WV' then 'South'
    when state = 'AL' then 'South'
    when state = 'KY' then 'South'
    when state = 'MS' then 'South'
    when state = 'TN' then 'South'
    when state = 'AR' then 'South'
    when state = 'LA' then 'South'
    when state = 'OK' then 'South'
    when state = 'TX' then 'South'
    when state = 'IN' then 'Midwest'
    when state = 'IL' then 'Midwest'
    when state = 'MI' then 'Midwest'
    when state = 'OH' then 'Midwest'
    when state = 'WI' then 'Midwest'
    when state = 'IA' then 'Midwest'
    when state = 'KS' then 'Midwest'
    when state = 'MN' then 'Midwest'
    when state = 'MO' then 'Midwest'
    when state = 'NE' then 'Midwest'
    when state = 'ND' then 'Midwest'
    when state = 'SD' then 'Midwest'
    when state = 'CT' then 'Northeast'
    when state = 'ME' then 'Northeast'
    when state = 'MA' then 'Northeast'
    when state = 'NH' then 'Northeast'
    when state = 'RI' then 'Northeast'
    when state = 'VT' then 'Northeast'
    when state = 'NJ' then 'Northeast'
    when state = 'NY' then 'Northeast'
    when state = 'PA' then 'Northeast'
    else null end as region
from madrid2.provider_directory
where npi in (select distinct npi from khurana_pdr_cohort_both)
and state is not null;

DROP TABLE if exists khurana_region_process_both;
CREATE temp TABLE khurana_region_process_both as
WITH regsum AS (
    SELECT p.npi, 
           p.region, 
           p.postal_code,
           ROW_NUMBER() OVER(PARTITION BY p.npi
                                 ORDER BY p.npi ASC) AS rk
      FROM khurana_location_process_both p)
SELECT s.*
FROM regsum s
WHERE s.rk = 1;

-- INCOME 
drop table if exists khurana_agi_both;
create temp table khurana_agi_both as 
select distinct b.npi,
cast(b.mhi as numeric)
from 
(select distinct a.*, 
case when zip.median_household_income='' then null else zip.median_household_income end as mhi
from khurana_region_process_both a 
inner join aao_team.zipcode_data zip 
on substring(zip.zip,1,5) = substring(a.postal_code, 1,5)
and a.postal_code is not null 
and len(a.postal_code) >= 3) as b;

-- INSURANCE
-- additional request (insurance status)
drop table if exists khurana_ins_process1_both;
create temp table khurana_ins_process1_both as 
select distinct patient_guid, insurance_type,
case when insurance_type ilike '%No�Insurance%' then 1 else 0 end as npl, 
case when insurance_type ilike '%Misc%' then 1 else 0 end as misc,
case when insurance_type ilike '%Medicare%' then 1 else 0 end as mc,  
case when insurance_type ilike '%Military%' then 1 else 0 end as mil,
case when insurance_type ilike '%Govt%' then 1 else 0 end as govt,
case when insurance_type ilike '%Medicaid%' then 1 else 0 end as medicaid,
case when insurance_type ilike '%Commercial%' then 1 else 0 end as private,
case when (insurance_type ilike '%Unknown%' or insurance_type is NULL)
then 1 else 0 end as unkwn
from madrid2.patient_insurance 
where patient_guid in (select distinct patient_guid from khurana_pdr_cohort_both);

-- sum the indicators
drop table if exists khurana_ins_process2_both;
create temp table khurana_ins_process2_both as 
select distinct patient_guid, sum(npl) as npl_sum, sum(misc) as misc_sum, sum(mc) as mc_sum, 
sum(mil) as mil_sum, sum(govt) as govt_sum, sum(medicaid) as medicaid_sum,
sum(private) as private_sum, sum(unkwn) as unkwn_sum
from khurana_ins_process1_both
group by patient_guid;

-- denote categories
drop table if exists khurana_ins_process_final_both;
create temp table khurana_ins_process_final_both as 
select distinct patient_guid, 
case when (medicaid_sum>0 and mc_sum>0) then 'Dual'
when (private_sum>0 and mc_sum>0) then 'Medicare'
when (private_sum>0 and medicaid_sum>0) then 'Medicaid'
when private_sum>0 then 'Private'
when medicaid_sum>0 then 'Medicaid'
when mc_sum>0 then 'Medicare'
when mil_sum>0 then 'Military'
when govt_sum>0 then 'Govt' 
when misc_sum>0 then 'Private'
when (unkwn_sum>0 or npl_sum>0) then 'Unknown'
else 'Unknown'
end as ins_final
from khurana_ins_process2_both;


--- NUMBER OF INJECTIONS (SKIPPED)

---- DIABETES
drop table if exists khurana_bl_diab_both;
create temp table khurana_bl_diab_both as 
select distinct patient_guid, case when (documentation_date > problem_onset_date) and problem_onset_date is not null then problem_onset_date
when (problem_onset_date > documentation_date) and documentation_date is not null then documentation_date
when problem_onset_date is null then documentation_date
when documentation_date is null then problem_onset_date
when documentation_date=problem_onset_date then documentation_date
end as diag_date
from madrid2.patient_problem
where patient_guid in (select patient_guid from khurana_pdr_cohort_both) and 
(problem_code ilike '249.5%' 
						or problem_code ilike '250.5%' 
						or problem_code ilike '362.0' 
						or problem_code ilike '362.01%'
						or problem_code ilike 'E08.31%'
						or problem_code ilike 'E09.31%'
						or problem_code ilike 'E10.31%'
						or problem_code ilike 'E11.31%'
						or problem_code ilike 'E13.31%'
					    or problem_code ilike '362.04%' 
						or problem_code ilike '362.05%'
						or problem_code ilike '362.06%'
						or problem_code ilike 'E08.32%'
						or problem_code ilike 'E09.32%'
						or problem_code ilike 'E10.32%'
						or problem_code ilike 'E11.32%'
						or problem_code ilike 'E13.32%'
						or problem_code ilike 'E08.33%'
						or problem_code ilike 'E09.33%'
						or problem_code ilike 'E10.33%'
						or problem_code ilike 'E11.33%'
						or problem_code ilike 'E13.33%'
						or problem_code ilike 'E08.34%'
						or problem_code ilike 'E09.34%'
						or problem_code ilike 'E10.34%'
						or problem_code ilike 'E11.34%'
						or problem_code ilike 'E13.34%');
					
drop table if exists khurana_bl_diab_join_both;
create temp table khurana_bl_diab_join_both as 
select distinct a.patient_guid, 1 as diab 
from khurana_pdr_cohort_both as a 
inner join khurana_bl_diab_both as b 
on a.patient_guid=b.patient_guid
and b.diag_date <= a.max_date 
where extract(year from b.diag_date) between 2000 and 2019;

----- VA
drop table if exists khurana_va_both;
create temp table khurana_va_both as 
select distinct patient_guid, result_date, result_description, observation_description, va_type,
CAST(logmar AS DECIMAL(6, 2)),
refraction, pinhole, order_criteria,
case when eye='2' then 2 when eye='1' then 1 
end as va_eye
from madrid2.patient_result_va
where EXTRACT(YEAR FROM result_date) BETWEEN 2013 AND 2019
and patient_guid in (select distinct patient_guid from khurana_pdr_cohort_both)
and logmar not ilike '999'
and va_method <> 2
and CAST(logmar AS DECIMAL(6, 2)) < 3
and (eye='2' or eye='1')
UNION 
select distinct patient_guid, result_date, result_description, observation_description, va_type,
CAST(logmar AS DECIMAL(6, 2)),
refraction, pinhole, order_criteria,
case when eye='3' then 1 
end as va_eye
from madrid2.patient_result_va
where EXTRACT(YEAR FROM result_date) BETWEEN 2013 AND 2019
and patient_guid in (select distinct patient_guid from khurana_pdr_cohort_both)
and logmar not ilike '999'
and va_method <> 2
and CAST(logmar AS DECIMAL(6, 2)) < 3
and eye='3'
UNION 
select distinct patient_guid, result_date, result_description, observation_description, va_type,
CAST(logmar AS DECIMAL(6, 2)),
refraction, pinhole, order_criteria,
case when eye='3' then 2 
end as va_eye
from madrid2.patient_result_va
where EXTRACT(YEAR FROM result_date) BETWEEN 2013 AND 2019
and patient_guid in (select distinct patient_guid from khurana_pdr_cohort_both)
and logmar not ilike '999'
and va_method <> 2
and CAST(logmar AS DECIMAL(6, 2)) < 3
and eye='3'
;

-- Step 1: average per day where va_type=1 (BCVA)
drop table if exists khurana_bcva_avg_both;
create temp table khurana_bcva_avg_both as 
select distinct patient_guid, va_eye, result_date, avg(logmar) as va_avg
from khurana_va_both
where va_type=1
group by patient_guid, va_eye, result_date;

-- Step 2: for the patient, eyes, date combos that are NOT IN the BCVA group, we are going to create an order variable
-- 1: pinhole 2: distance 3: refraction 4: glare*/
drop table if exists khurana_va_process_both;
create temp table khurana_va_process_both as 
select distinct *, 
case when pinhole ilike 'TRUE' then 1
when refraction ilike 'TRUE' then 3
when (observation_description ilike '%glare%' or result_description ilike '%glare%') then 4 
when va_type=2 then 5
else 2 end as va_order
from khurana_va_both as a
where not exists 
(SELECT distinct patient_guid, va_eye
                 FROM khurana_bcva_avg_both as b 
                 WHERE a.patient_guid=b.patient_guid
                 and a.va_eye=b.va_eye
                 and a.result_date=b.result_date);

-- Step 3: for the non va_type=1, take value that is lowest in the order      
DROP TABLE if exists khurana_va_process2_both;
CREATE temp TABLE khurana_va_process2_both as
WITH vsum AS (
    SELECT p.patient_guid, 
           p.va_eye, 
           p.result_date, 
           p.logmar,
           p.va_order,
           ROW_NUMBER() OVER(PARTITION BY p.patient_guid, p.va_eye, p.result_date
                                 ORDER BY va_order ASC) AS rk
      FROM khurana_va_process_both p)
SELECT s.*
FROM vsum s
WHERE s.rk = 1
UNION 
SELECT distinct patient_guid, va_eye, result_date, va_avg as logmar, 0 as va_order, 1 as rk
from khurana_bcva_avg_both;

-- Step 4: find up to three values closest to treatment date, then take best VA (lowest logmar) - wet amd per patient
drop table if exists khurana_pdr_va_process_both;
create temp table khurana_pdr_va_process_both as 
WITH vapdrsum AS (
    SELECT p.*,
           ROW_NUMBER() OVER(PARTITION BY p.patient_guid, p.eye
                                 ORDER BY (p.max_date - p.result_date) ASC) AS rk
      FROM (select distinct a.patient_guid, a.eye, a.max_date, b.logmar, b.result_date
      from khurana_pdr_cohort_both as a
      inner join khurana_va_process2_both as b 
      on a.patient_guid=b.patient_guid
      and (a.eye=b.va_eye or (a.eye=4 and b.va_eye in (1,2)) or (a.eye in (1,2) and b.va_eye=4))
      and b.result_date <= a.max_date) p)
SELECT s.*
FROM vapdrsum s
WHERE s.rk <= 3;

drop table if exists khurana_pdr_va_process2_both;
create temp table khurana_pdr_va_process2_both as 
WITH vapdrsum AS (
    SELECT p.*,
           ROW_NUMBER() OVER(PARTITION BY p.patient_guid
                                 ORDER BY p.logmar ASC) AS rk1
      FROM khurana_pdr_va_process_both p)
SELECT s.*
FROM vapdrsum s
WHERE s.rk1=1;


--process va change for both (prp and anti vegf) cohort and compare calculations to R -good 

drop table if exists aao_grants.khurana_va_process_442_both;
create table aao_grants.khurana_va_process_442_both as 
SELECT
	patient_guid,
	eye,
	(logmar_2-logmar) as va_change,
	ABS(date_diff_1 - date_diff_2) AS date_diff
FROM (
	SELECT
		a.*,
		c.oneyrindonemo,
		abs((b.min_date + 442) - a.result_date) AS date_diff_1,
		abs((b.max_date + 442) - a.result_date) AS date_diff_2,
		b.logmar AS logmar_2
	FROM
		khurana_pdr_va_process2_both AS a
		INNER JOIN khurana_pdr_va_process_first_tx2_both AS b ON a.patient_guid = b.patient_guid
		INNER JOIN aao_grants.hosk_khurana_pdr_cohort_fix_both c ON c.patient_guid = b.patient_guid
			and(a.eye = b.eye
				or(b.eye in('1', '2'))
				or(a.eye in('1', '2'))))
WHERE
	oneyrindonemo = 1;

	

SELECT
	'mean' AS value,
	CAST(AVG(va_change) AS DECIMAL(10,2)) 
FROM
	aao_grants.khurana_va_process_442_prp
UNION
SELECT
	'min' AS value,
	CAST(MIN(va_change) AS DECIMAL(10,2))
FROM
	aao_grants.khurana_va_process_442_prp
UNION
SELECT
	'max' AS value,
	CAST(MAX(va_change) AS DECIMAL(10,2))
FROM
	aao_grants.khurana_va_process_442_prp
UNION
SELECT
	'stddev' AS value,
	CAST(stddev(va_change) AS DECIMAL(10,2))
FROM
	aao_grants.khurana_va_process_442_prp
UNION
SELECT
	'Q1' AS value,
	percentile_cont(0.25)
	WITHIN GROUP (ORDER BY va_change)
FROM
	aao_grants.khurana_va_process_442_prp
UNION
SELECT
	'Q3' AS value,
	percentile_cont(0.75)
	WITHIN GROUP (ORDER BY va_change) AS Q3
FROM
	aao_grants.khurana_va_process_442_prp;


--- NUMBER OF ANTI VEGF INJECTIONS - vegf + prp (both) subcohort 

-- new addition: inj up to 442 days (ADD IN DURING RERUN) - get descriptive stats -> compare to R -good

drop table if exists aao_grants.khurana_inj_vegf_442_both;
CREATE TABLE aao_grants.khurana_inj_vegf_442_both AS
SELECT
	patient_guid,
	patient_date as procedure_date,
	count(
		patient_guid) AS inj_ct
FROM (
	SELECT DISTINCT
		a.patient_guid,
		a.eye,
		b.patient_date
	FROM
		khurana_pdr_va_process_first_tx_both AS a
		inner join khurana_all_dates_both as b  ON a.patient_guid = b.patient_guid
		INNER JOIN aao_grants.hosk_khurana_pdr_cohort_both c on c.patient_guid = b.patient_guid
			and(a.eye = c.eye
				or(a.eye in(1, 2))
				or(c.eye in(1, 2)))
	WHERE
		b.patient_date BETWEEN c.diag_date
		and(a.min_date + 442))
GROUP BY
	patient_guid,
	patient_date;


drop table if exists aao_grants.khurana_inj_2_vegf_442_both;
CREATE TABLE aao_grants.khurana_inj_2_vegf_442_both AS SELECT DISTINCT
	patient_guid,
	extract(
		month FROM procedure_date) AS proc_month,
	sum(
		inj_ct2) AS inj_ct_sum
FROM (
	SELECT DISTINCT
		patient_guid,
		procedure_date,
		inj_ct,
		CASE WHEN inj_ct > 1 THEN
			2
		ELSE
			1
		END AS inj_ct2
	FROM
		aao_grants.khurana_inj_vegf_442_both)
GROUP BY
	patient_guid,
	proc_month;

drop table if exists aao_grants.khurana_inj_3_vegf_442_both;
CREATE TABLE aao_grants.khurana_inj_3_vegf_442_both AS SELECT DISTINCT
	patient_guid,
	sum(
		inj_ct_final) AS inj_ct_final_sum
FROM (
	SELECT DISTINCT
		a.patient_guid,
		proc_month,
		inj_ct_sum,
		CASE WHEN inj_ct_sum > 4 THEN
			4
		ELSE
			inj_ct_sum
		END AS inj_ct_final
	FROM
		aao_grants.khurana_inj_2_vegf_442_both a 
		INNER JOIN aao_grants.hosk_khurana_pdr_cohort_both b on a.patient_guid=b.patient_guid
		WHERE
	oneyrindonemo = 0)
GROUP BY
	patient_guid;


SELECT
	'mean' AS value,
	CAST(AVG(inj_ct_final_sum) AS DECIMAL(10,2)) 
FROM
	aao_grants.khurana_inj_3_vegf_442_both
UNION
SELECT
	'min' AS value,
	CAST(MIN(inj_ct_final_sum) AS DECIMAL(10,2))
FROM
	aao_grants.khurana_inj_3_vegf_442_both
UNION
SELECT
	'max' AS value,
	CAST(MAX(inj_ct_final_sum) AS DECIMAL(10,2))
FROM
	aao_grants.khurana_inj_3_vegf_442_both
UNION
SELECT
	'stddev' AS value,
	CAST(stddev(inj_ct_final_sum) AS DECIMAL(10,2))
FROM
	aao_grants.khurana_inj_3_vegf_442_both
UNION
SELECT
	'Q1' AS value,
	percentile_cont(0.25)
	WITHIN GROUP (ORDER BY inj_ct_final_sum)
FROM
	aao_grants.khurana_inj_3_vegf_442_both
UNION
SELECT
	'Q3' AS value,
	percentile_cont(0.75)
	WITHIN GROUP (ORDER BY inj_ct_final_sum) AS Q3
FROM
	aao_grants.khurana_inj_3_vegf_442_both;


--Last IRIS Visit VA >=20/40
--Last IRIS Visit VA <20/200
--get stats -> compare to R -good

drop table if exists aao_grants.last_iris_va_both;
CREATE TABLE aao_grants.last_iris_va_both AS
SELECT
	*,
	CASE
	WHEN oneyrindonemo = 1
		and((logmar IS NOT NULL
			AND logmar >= 0.3)) THEN
		1
	ELSE
		0
	END AS twentyforty_ind_442,
	
	CASE 
	WHEN oneyrindonemo = 1
		and(
			logmar < 0.3) THEN
		1
	ELSE
		0
	END AS ind_442,
	
	CASE WHEN oneyrindonemo = 0 THEN
		logmar
	ELSE
		(
			logmar - bl_va)
	END AS va_change_fix_442
FROM (
	SELECT
		a.*,
		b.logmar,
		c.bl_va,
		CASE WHEN c.bl_va IS NULL THEN
			NULL
		WHEN (d.oneyrindonemo = 1
			AND b.logmar IS NOT NULL) THEN
			b.logmar
		ELSE
			c.bl_va
		END AS one_yr_fu_va,
		b.result_date+442 AS va_442_date,
		CASE WHEN (d.oneyrindonemo = 0
			AND b.logmar IS NOT NULL) THEN
			b.logmar
		ELSE
			c.bl_va
		END AS no_one_yr_fu_va,
		d.oneyrindonemo
	FROM
		aao_grants.khurana_inj_3_vegf_442_both AS a
		INNER JOIN madrid2.patient_result_va AS b ON a.patient_guid = b.patient_guid
		INNER JOIN khurana_pdr_cohort_both_total c ON c.patient_guid = b.patient_guid
		INNER JOIN aao_grants.hosk_khurana_pdr_cohort_both d on c.patient_guid = d.patient_guid
		WHERE one_yr_fu_va <> 999
		and no_one_yr_fu_va <> 999
		and b.logmar <> 999);


SELECT COUNT(DISTINCT patient_guid)
from aao_grants.last_iris_va_both
WHERE oneyrindonemo = 1 
AND logmar >= 0.3;

SELECT COUNT(DISTINCT patient_guid)
from aao_grants.last_iris_va_both
WHERE oneyrindonemo = 1 
AND logmar < 0.3;

SELECT COUNT(DISTINCT patient_guid)
from aao_grants.last_iris_va_both
WHERE oneyrindonemo = 0 
AND logmar >= 0.3;

SELECT COUNT(DISTINCT patient_guid)
from aao_grants.last_iris_va_both
WHERE oneyrindonemo = 0
AND logmar < 0.3;


---- COMBINE DEMOGRAPHICS BOTH
drop table if exists khurana_pdr_cohort_both_total;
create table khurana_pdr_cohort_both_total as 
select a.*,
c.gender, extract(year from a.max_date) - c.yob as txage, c.race, f.logmar as bl_va, f.result_date as bl_va_date, 
case when g.eye_ct=1 then 1 else 2 end as eye_involve, 
(h.max_visit_date - a.max_date) as followup_time, (h.max_visit_date - a.min_date) as tx_time, h.max_visit_date,
coalesce(j.diab,0) as diab_indicator, k.region, l.mhi, m.ins_final, n.min_visit_date
from khurana_pdr_cohort_both as a
left join khurana_demog_process_both as c
on a.patient_guid=c.patient_guid
left join khurana_pdr_va_process2_both as f 
on a.patient_guid=f.patient_guid
and (a.eye=f.eye or (a.eye=4 and f.eye in (1,2)) or (a.eye in (1,2) and f.eye=4))
left join khurana_pdr_eye_both as g 
on a.patient_guid=g.patient_guid
left join (select distinct patient_guid, max(patient_date) as max_visit_date
from khurana_all_dates_both
group by patient_guid) as h 
on a.patient_guid=h.patient_guid
left join khurana_bl_diab_join_both as j 
on a.patient_guid=j.patient_guid
left join khurana_region_process_both as k 
on a.npi=k.npi
left join khurana_agi_both as l 
on a.npi=l.npi
left join khurana_ins_process_final_both as m 
on a.patient_guid=m.patient_guid
left join (select distinct patient_guid, min(patient_date) as min_visit_date
from khurana_all_dates_both
group by patient_guid) as n
on a.patient_guid=n.patient_guid;


select count(*) from khurana_pdr_cohort_both_total;
select count(*) from (select distinct patient_guid,eye from khurana_pdr_cohort_both_total);


-- partition to get patient w/longest pdr follow-up time

drop table if exists khurana_pdr_cohort2_both;
create temp table khurana_pdr_cohort2_both as 
WITH wasum AS (
    SELECT p.*,
           ROW_NUMBER() OVER(PARTITION BY p.patient_guid,p.eye
                                 ORDER BY p.followup_time DESC) AS rk2
      FROM khurana_pdr_cohort_both_total p)
SELECT s.*
FROM wasum s
WHERE s.rk2=1;

-- new addition: VA at last IRIS date

drop table if exists khurana_pdr_va_process_last_visit_both;
create temp table khurana_pdr_va_process_last_visit_both as 
WITH vawamdsum AS (
    SELECT p.*,
           ROW_NUMBER() OVER(PARTITION BY p.patient_guid, p.eye
                                 ORDER BY (p.max_visit_date - p.result_date) ASC) AS rk
      FROM (select distinct a.*, b.result_date, b.logmar
      from khurana_pdr_cohort2_both as a
      inner join khurana_va_process2_both as b 
      on a.patient_guid=b.patient_guid
      and (a.eye=b.va_eye or (a.eye=4 and b.va_eye in (1,2)) or (a.eye in (1,2) and b.va_eye=4))
      and b.result_date <= a.max_visit_date) p)
SELECT s.*
FROM vawamdsum s
WHERE s.rk <= 3;

drop table if exists khurana_pdr_va_process_last_visit2_both;
create temp table khurana_pdr_va_process_last_visit2_both as 
WITH vawamdsum AS (
    SELECT p.*,
           ROW_NUMBER() OVER(PARTITION BY p.patient_guid,p.eye
                                 ORDER BY p.logmar ASC) AS rk1
      FROM khurana_pdr_va_process_last_visit_both p)
SELECT s.*
FROM vawamdsum s
WHERE s.rk1=1 and (bl_va_date <> result_date);

-- final cohort for khurana wet amd

drop table if exists aao_grants.hosk_khurana_pdr_cohort_both;
create table aao_grants.hosk_khurana_pdr_cohort_both as 
select distinct a.patient_guid, a.eye, a.diag_date, a.max_date, a.min_date,
a.oneyrindonemo, a.twoyrind, a.threeyrind, a.gender, a.txage, a.race, a.bl_va, 
a.eye_involve, a.followup_time, a.tx_time, a.max_visit_date, 
 a.diab_indicator, a.region, a.mhi, a.ins_final,
a.min_visit_date, 
case when (b.logmar is not null and b.logmar <= 0.3) then 1 else 0 end as twentyforty_ind, 
case when (b.logmar > 1) then 1 else 0 end as twentytwohundred_ind,
(b.logmar - a.bl_va) as va_change, b.logmar as folup_va, b.result_date as folup_va_date
from khurana_pdr_cohort2_both as a 
left join khurana_pdr_va_process_last_visit2_both as b 
on a.patient_guid=b.patient_guid;

--a.visit_time, removed from above 
select count(patient_guid) from aao_grants.hosk_khurana_pdr_cohort_both; 


-- new addition: VA at first tx date (ADD IN DURING RERUN)

drop table if exists khurana_pdr_va_process_first_tx_both;
create temp table khurana_pdr_va_process_first_tx_both as 
WITH vawamdtxsum AS (
    SELECT p.*,
           ROW_NUMBER() OVER(PARTITION BY p.patient_guid, p.eye
                                 ORDER BY (p.min_date - p.result_date) ASC) AS rk
      FROM (select distinct a.*, b.result_date, b.logmar
      from aao_grants.hosk_khurana_pdr_cohort_both as a
      inner join khurana_va_process2_both as b 
      on a.patient_guid=b.patient_guid
      and (a.eye=b.va_eye or (a.eye=4 and b.va_eye in (1,2)) or (a.eye in (1,2) and b.va_eye=4))
      and b.result_date <= a.min_date) p)
SELECT s.*
FROM vawamdtxsum s
WHERE s.rk <= 3;

drop table if exists khurana_pdr_va_process_first_tx2_both;
create temp table khurana_pdr_va_process_first_tx2_both as 
WITH vawamdsum AS (
    SELECT p.*,
           ROW_NUMBER() OVER(PARTITION BY p.patient_guid
                                 ORDER BY p.logmar ASC) AS rk1
      FROM khurana_pdr_va_process_first_tx_both p)
SELECT s.*
FROM vawamdsum s
WHERE s.rk1=1 and (folup_va_date <> result_date);

drop table if exists aao_grants.hosk_khurana_pdr_cohort_fix_both;
create table aao_grants.hosk_khurana_pdr_cohort_fix_both as 
select distinct a.*, b.logmar as first_tx_va, (a.folup_va - b.logmar) as va_change_fix
from aao_grants.hosk_khurana_pdr_cohort_both as a 
left join khurana_pdr_va_process_first_tx2_both as b 
on a.patient_guid=b.patient_guid;

select distinct patient_guid, folup_va, first_tx_va, va_change_fix 
from aao_grants.hosk_khurana_pdr_cohort_fix limit 100;

select count(*) from aao_grants.hosk_khurana_pdr_cohort_fix_both;

-------------- EXPORT 
select * from aao_grants.hosk_khurana_pdr_cohort_fix_vegf; -- 451,047
select *  from aao_grants.hosk_khurana_pdr_cohort_fix_prp; -- 379
select * from aao_grants.hosk_khurana_pdr_cohort_fix_both; -- 621


--QC STEP to assure that counts match in R and SQL 

--Number of patients with one year follow up 
SELECT
	count(DISTINCT patient_guid)
FROM
	aao_grants.hosk_khurana_pdr_cohort_fix_both
		/*aao_grants.hosk_khurana_pdr_cohort_fix_prp*/
	/*aao_grants.hosk_khurana_pdr_cohort_fix_vegf*/
WHERE
	oneyrindonemo = 1;
--PDR COUNTS

--BOTH: 22,683
--PRP: 23,398
--VEGF: 28,743

--WET AMD COUNTS
--BOTH: 524
--PRP: 329
--VEGF: 164,214

--Number of eyes with one year follow up 
SELECT count(*) from (
SELECT
	DISTINCT patient_guid, eye
FROM
	/*aao_grants.hosk_khurana_pdr_cohort_fix_both*/
		/*aao_grants.hosk_khurana_pdr_cohort_fix_prp*/
	aao_grants.hosk_khurana_pdr_cohort_fix_vegf
WHERE
	oneyrindonemo = 1);
--PDR COUNTS

--BOTH: 30,207
--PRP: 29,067
--VEGF: 36,207

--WET AMD COUNTS
--BOTH: 568
--PRP: 355
--VEGF: 194,518

--Number of patients with loss to follow up at one year 
SELECT
	count(DISTINCT patient_guid)
FROM
	aao_grants.hosk_khurana_pdr_cohort_fix_both
		/*aao_grants.hosk_khurana_pdr_cohort_fix_prp*/
		/*aao_grants.hosk_khurana_pdr_cohort_fix_vegf*/
WHERE
	oneyrindonemo = 0;
--PDR COUNTS
--BOTH: 2,707
--PRP: 2605
--VEGF: 3,700

--WET AMD COUNTS
--BOTH: 53
--PRP: 23
--VEGF: 21,672

--Number of eyes with loss to follow up at one year 
SELECT count(*) from (
SELECT
	DISTINCT patient_guid, eye
FROM
	aao_grants.hosk_khurana_pdr_cohort_fix_both
		/*aao_grants.hosk_khurana_pdr_cohort_fix_prp*/
	/*aao_grants.hosk_khurana_pdr_cohort_fix_vegf*/
WHERE
	oneyrindonemo = 0);

--BOTH: 53
--PRP: 24
--VEGF: 23,615


--Patient age counts for follow up only during 1 year

SELECT
	*
FROM (
	SELECT
		tx_age,
		COUNT(DISTINCT patient_guid)
	FROM ( SELECT DISTINCT
			patient_guid,
			CASE WHEN txage <= '70' THEN
				'<= 70'
			WHEN txage BETWEEN '71'
				AND '75' THEN
				'71-75'
			WHEN txage BETWEEN '76'
				AND '80' THEN
				'76-80'
			WHEN txage BETWEEN '81'
				AND '85' THEN
				'81-85'
			WHEN txage BETWEEN '86'
				AND '90' THEN
				'86-90'
			WHEN txage > '90' THEN
				'> 90'
			ELSE
				'Unreported'
			END AS tx_age,
			txage
		FROM
 			aao_grants.hosk_khurana_pdr_cohort_fix_both
			/*aao_grants.hosk_khurana_pdr_cohort_fix_prp*/
			/*aao_grants.hosk_khurana_pdr_cohort_fix_vegf*/
		WHERE
			oneyrindonemo = 1)
	GROUP BY
		tx_age)
ORDER BY
	tx_age;
		 
--Patient age counts for no follow up only during 1 year


SELECT
	*
FROM (
	SELECT
		tx_age,
		COUNT(DISTINCT patient_guid)
	FROM ( SELECT DISTINCT
			patient_guid,
			CASE WHEN txage <= '70' THEN
				'<= 70'
			WHEN txage BETWEEN '71'
				AND '75' THEN
				'71-75'
			WHEN txage BETWEEN '76'
				AND '80' THEN
				'76-80'
			WHEN txage BETWEEN '81'
				AND '85' THEN
				'81-85'
			WHEN txage BETWEEN '86'
				AND '90' THEN
				'86-90'
			WHEN txage > '90' THEN
				'> 90'
			WHEN txage IS NULL THEN
				'Unreported'
			WHEN txage < '0' THEN
				'Unreported'
			WHEN txage > '115' THEN
				'Unreported'
			WHEN txage = '999' THEN
				'Unreported'
			END AS tx_age,
			txage
		FROM
			aao_grants.hosk_khurana_pdr_cohort_fix_both
			/*aao_grants.hosk_khurana_pdr_cohort_fix_prp*/
			/*aao_grants.hosk_khurana_pdr_cohort_fix_vegf*/
		WHERE
			oneyrindonemo = 0)
	GROUP BY
		tx_age)
ORDER BY
	tx_age;


--Patient sex counts for follow up only during 1 year


SELECT
	*
FROM (
	SELECT
		gender,
		COUNT(DISTINCT patient_guid)
	FROM ( SELECT DISTINCT
			patient_guid,
			CASE WHEN gender = 'Female' THEN
				'Female'
			WHEN gender = 'Male' THEN
				'Male'
			ELSE
				'Unreported'
			END AS gender
		FROM
			aao_grants.hosk_khurana_pdr_cohort_fix_both
			/*aao_grants.hosk_khurana_pdr_cohort_fix_prp*/
			/*aao_grants.hosk_khurana_pdr_cohort_fix_vegf*/
		WHERE
			oneyrindonemo = 1)
	GROUP BY
		gender
	ORDER BY
		gender);




--Patient sex counts for no follow up only during 1 year


SELECT
	*
FROM (
	SELECT
		gender,
		COUNT(DISTINCT patient_guid)
	FROM ( SELECT DISTINCT
			patient_guid,
			CASE WHEN gender = 'Female' THEN
				'Female'
			WHEN gender = 'Male' THEN
				'Male'
			ELSE
				'Unreported'
			END AS gender
		FROM
			aao_grants.hosk_khurana_pdr_cohort_fix_both
			/*aao_grants.hosk_khurana_pdr_cohort_fix_prp*/
			/*aao_grants.hosk_khurana_pdr_cohort_fix_vegf*/
		WHERE
			oneyrindonemo = 0)
	GROUP BY
		gender
	ORDER BY
		gender);


--Patient race counts for follow up only during 1 year


SELECT
	*
FROM (
	SELECT race_final,
		COUNT(DISTINCT patient_guid)
		
	FROM (
		SELECT
			patient_guid,
			CASE WHEN race = 'White' THEN
				'White'
			WHEN race = 'Black or African American' THEN
				'African American'
			WHEN race = 'Asian' THEN
				'Asian'
			WHEN race = 'Hispanic' THEN
				'Hispanic'
			WHEN race = 'Unknown' THEN
				'Unreported'
			ELSE
				'Other'
			END AS race_final
		FROM
			aao_grants.hosk_khurana_pdr_cohort_fix_both
			/*aao_grants.hosk_khurana_pdr_cohort_fix_prp*/
			/*aao_grants.hosk_khurana_pdr_cohort_fix_vegf*/
		WHERE
			oneyrindonemo = 1)
	GROUP BY
		race_final)
ORDER BY
	race_final;




--Patient race counts for no follow up only during 1 year

SELECT
	*
FROM (
	SELECT race_final,
		COUNT(DISTINCT patient_guid)
		
	FROM (
		SELECT
			patient_guid,
			CASE WHEN race = 'White' THEN
				'White'
			WHEN race = 'Black or African American' THEN
				'African American'
			WHEN race = 'Asian' THEN
				'Asian'
			WHEN race = 'Hispanic' THEN
				'Hispanic'
			WHEN race = 'Unknown' THEN
				'Unreported'
			ELSE
				'Other'
			END AS race_final
		FROM
			aao_grants.hosk_khurana_pdr_cohort_fix_both
			/*aao_grants.hosk_khurana_pdr_cohort_fix_prp*/
			/*aao_grants.hosk_khurana_pdr_cohort_fix_vegf*/
		WHERE
			oneyrindonemo = 0)
	GROUP BY
		race_final)
ORDER BY
	race_final;


--Patient eye counts for follow up only during 1 year

SELECT
	*
FROM (
	SELECT
		eye_involvement,
		COUNT(DISTINCT patient_guid)
	FROM (
		SELECT
			patient_guid,
			CASE WHEN eye_involve = '1' THEN
				'Unilateral'
			ELSE
				'Bilateral'
			END AS eye_involvement
		FROM
			aao_grants.hosk_khurana_pdr_cohort_fix_both
			/*aao_grants.hosk_khurana_pdr_cohort_fix_prp*/
			/*aao_grants.hosk_khurana_pdr_cohort_fix_vegf*/
		WHERE
			oneyrindonemo = 1)
	GROUP BY
		eye_involvement)
ORDER BY
	eye_involvement;


--Patient eye counts for no follow up only during 1 year


SELECT
	*
FROM (
	SELECT
		eye_involvement,
		COUNT(DISTINCT patient_guid)
	FROM (
		SELECT
			patient_guid,
			CASE WHEN eye_involve = '1' THEN
				'Unilateral'
			ELSE
				'Bilateral'
			END AS eye_involvement
		FROM
			aao_grants.hosk_khurana_pdr_cohort_fix_both
			/*aao_grants.hosk_khurana_pdr_cohort_fix_prp*/
			/*aao_grants.hosk_khurana_pdr_cohort_fix_vegf*/
		WHERE
			oneyrindonemo = 0)
	GROUP BY
		eye_involvement)
ORDER BY
	eye_involvement;


--Patient baseline VA counts for follow up only during 1 year


SELECT
	*
FROM (
	SELECT
		bl_va,
		COUNT(DISTINCT patient_guid)
	FROM (
		SELECT
			patient_guid,
			CASE WHEN bl_va IS NULL THEN
				'Unreported'
				WHEN bl_va < '0' THEN
				'Unreported'
				WHEN bl_va <= '0.3' THEN
				'>=20/40'
				WHEN bl_va <= '1' THEN
				'20/50-20/200'
				WHEN bl_va > '1' THEN
				'<20/200'
				ELSE 'Unreported'
			END AS bl_va
		FROM
			aao_grants.hosk_khurana_pdr_cohort_fix_both
			/*aao_grants.hosk_khurana_pdr_cohort_fix_prp*/
			/*aao_grants.hosk_khurana_pdr_cohort_fix_vegf*/
		WHERE
			oneyrindonemo = 1)
	GROUP BY
		bl_va)
ORDER BY
	bl_va;


--Patient baseline VA counts for no follow up only during 1 year

SELECT
	*
FROM (
	SELECT
		bl_va,
		COUNT(DISTINCT patient_guid)
	FROM (
		SELECT
			patient_guid,
			CASE WHEN bl_va IS NULL THEN
				'Unreported'
				WHEN bl_va < '0' THEN
				'Unreported'
				WHEN bl_va <= '0.3' THEN
				'>=20/40'
				WHEN bl_va <= '1' THEN
				'20/50-20/200'
				WHEN bl_va > '1' THEN
				'<20/200'
				ELSE 'Unreported'
			END AS bl_va
		FROM
			aao_grants.hosk_khurana_pdr_cohort_fix_both
			/*aao_grants.hosk_khurana_pdr_cohort_fix_prp*/
			/*aao_grants.hosk_khurana_pdr_cohort_fix_vegf*/
		WHERE
			oneyrindonemo = 0)
	GROUP BY
		bl_va)
ORDER BY
	bl_va;


--Patient diabetes counts for follow up only during 1 year


SELECT
	*
FROM (
	SELECT
		diab,
		COUNT(DISTINCT patient_guid)
	FROM (
		SELECT
			patient_guid,
			CASE WHEN diab_indicator = '1' THEN
				'Yes'
				WHEN diab_indicator = '0' THEN
				'No'
			END AS diab
		FROM
			aao_grants.hosk_khurana_pdr_cohort_fix_both
			/*aao_grants.hosk_khurana_pdr_cohort_fix_prp*/
			/*aao_grants.hosk_khurana_pdr_cohort_fix_vegf*/
		WHERE
			oneyrindonemo = 1)
	GROUP BY
		diab)
ORDER BY
	diab;


--Patient diabetes counts for no follow up only during 1 year


SELECT
	*
FROM (
	SELECT
		diab,
		COUNT(DISTINCT patient_guid)
	FROM (
		SELECT
			patient_guid,
			CASE WHEN diab_indicator = '1' THEN
				'Yes'
				WHEN diab_indicator = '0' THEN
				'No'
			END AS diab
		FROM
			aao_grants.hosk_khurana_pdr_cohort_fix_both
			/*aao_grants.hosk_khurana_pdr_cohort_fix_prp*/
			/*aao_grants.hosk_khurana_pdr_cohort_fix_vegf*/
		WHERE
			oneyrindonemo = 0)
	GROUP BY
		diab)
ORDER BY
	diab;

--Patient region counts for follow up only during 1 year

SELECT
	region,
	COUNT(DISTINCT patient_guid)
FROM (
	SELECT
		CASE WHEN region = 'South' THEN
			'South'
		WHEN region = 'North' THEN
			'North'
		WHEN region = 'Midwest' THEN
			'Midwest'
		WHEN region = 'Northeast' THEN
			'Northeast'
		WHEN region = 'West' THEN
			'West'
		ELSE
			'Unknown'
		END AS region,
		patient_guid
	FROM
		aao_grants.hosk_khurana_pdr_cohort_fix_both
		/*aao_grants.hosk_khurana_pdr_cohort_fix_prp*/
		/*aao_grants.hosk_khurana_pdr_cohort_fix_vegf*/
	WHERE
		oneyrindonemo = 1)
	GROUP BY
		region
	ORDER BY
		region;


--Patient region counts for no follow up only during 1 year

SELECT
	region,
	COUNT(DISTINCT patient_guid)
FROM (
	SELECT
		CASE WHEN region = 'South' THEN
			'South'
		WHEN region = 'North' THEN
			'North'
		WHEN region = 'Midwest' THEN
			'Midwest'
		WHEN region = 'Northeast' THEN
			'Northeast'
		WHEN region = 'West' THEN
			'West'
		ELSE
			'Unknown'
		END AS region,
		patient_guid
	FROM
		aao_grants.hosk_khurana_pdr_cohort_fix_both
		/*aao_grants.hosk_khurana_pdr_cohort_fix_prp*/
		/*aao_grants.hosk_khurana_pdr_cohort_fix_vegf*/
	WHERE
		oneyrindonemo = 0)
	GROUP BY
		region
	ORDER BY
		region;


--Patient insurance counts for follow up only during 1 year

SELECT
	insurance,
	COUNT(DISTINCT patient_guid)
FROM (
	SELECT
		CASE WHEN ins_final = 'Dual' THEN
			'Dual'
		WHEN ins_final = 'Govt' THEN
			'Govt/Military'
			WHEN ins_final = 'Military' THEN
			'Govt/Military'
		WHEN ins_final = 'Medicaid' THEN
			'Medicaid'
		WHEN ins_final = 'Medicare' THEN
			'Medicare'
		WHEN ins_final = 'Private' THEN
			'Private'
		ELSE
			'Unknown'
		END AS insurance,
		patient_guid
	FROM
		aao_grants.hosk_khurana_pdr_cohort_fix_both
		/*aao_grants.hosk_khurana_pdr_cohort_fix_prp*/
		/*aao_grants.hosk_khurana_pdr_cohort_fix_vegf*/
	WHERE
		oneyrindonemo = 1)
	GROUP BY
		insurance
	ORDER BY
		insurance;


--Patient insurance counts for no follow up only during 1 year

SELECT
	insurance,
	COUNT(DISTINCT patient_guid)
FROM (
	SELECT
		CASE WHEN ins_final = 'Dual' THEN
			'Dual'
		WHEN ins_final = 'Govt' THEN
			'Govt/Military'
			WHEN ins_final = 'Military' THEN
			'Govt/Military'
		WHEN ins_final = 'Medicaid' THEN
			'Medicaid'
		WHEN ins_final = 'Medicare' THEN
			'Medicare'
		WHEN ins_final = 'Private' THEN
			'Private'
		ELSE
			'Unknown'
		END AS insurance,
		patient_guid
	FROM
		aao_grants.hosk_khurana_pdr_cohort_fix_both
		/*aao_grants.hosk_khurana_pdr_cohort_fix_prp*/
		/*aao_grants.hosk_khurana_pdr_cohort_fix_vegf*/
	WHERE
		oneyrindonemo = 0)
	GROUP BY
		insurance
	ORDER BY
		insurance;


--Patient MHI counts for follow up only during 1 year

SELECT
	mhi,
	COUNT(DISTINCT patient_guid)
FROM (
	SELECT
			CASE WHEN mhi <= '25000' THEN
			'25k and below'
		WHEN mhi BETWEEN '25001' AND '75000' THEN
			'25,001-75,000'
		WHEN mhi BETWEEN '75001' AND '100000' THEN
			'75,001-100,000'
		WHEN mhi > '100000' THEN
			'>100,000'
		WHEN mhi <= '0' THEN
			'Unknown'
			ELSE 'Unknown'
			END AS mhi,
			patient_guid
	FROM
		aao_grants.hosk_khurana_pdr_cohort_fix_both
		/*aao_grants.hosk_khurana_pdr_cohort_fix_prp*/
		/*aao_grants.hosk_khurana_pdr_cohort_fix_vegf*/
	WHERE
		oneyrindonemo = 1)
	GROUP BY
		mhi
	ORDER BY
		mhi;


--Patient MHI counts for no follow up only during 1 year

SELECT
	mhi,
	COUNT(DISTINCT patient_guid)
FROM (
	SELECT
		CASE WHEN mhi <= '25000' THEN
			'25k and below'
		WHEN mhi BETWEEN '25001' AND '75000' THEN
			'25,001-75,000'
		WHEN mhi BETWEEN '75001' AND '100000' THEN
			'75,001-100,000'
		WHEN mhi > '100000' THEN
			'>100,000'
		WHEN mhi <= '0' THEN
			'Unknown'
			ELSE 'Unknown'
			END AS mhi,
			patient_guid
	FROM
		aao_grants.hosk_khurana_pdr_cohort_fix_both
		/*aao_grants.hosk_khurana_pdr_cohort_fix_prp*/
		/*aao_grants.hosk_khurana_pdr_cohort_fix_vegf*/
	WHERE
		oneyrindonemo = 0)
	GROUP BY
		mhi
	ORDER BY
		mhi;



              
