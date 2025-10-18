
use CpsWarehouse
go


/*OBS - HDID - meaning
BHVISITSTRAT - 489709 - BH vs CBCM type
BHVISITTYPE - 489708 - BH visit Type

PSYCHEVCHINT - 49608 - inial and annual diagnositc note
BH PROGRESS1 - 181245 - BH Progress note
BHTXPLANDATE - 61012 - initial and followup treatment note
CONSULTVISIT - 48381 - consult note
PSYIVISITDAT - 222891 - Psych Note
BHTXLENGTHGR - 62714 - group note
BHDISCHCRIT - 61014 - discharge note

PREAUDIT - 217287 - pre audit
AUDIT COMP - 411704 - initial / follow up audit
AUDITSCORE - 36210 - AUDIT score

PREDAST - 217288 - Pre DAST
DAST COMP - 411705 - DAST initial / follow up
DAST-10TOTAL - 39141 - DAST Score

PHQ-9 DONE - 53332 - PHQ initial and follow up
PHQ9_2 - 65683 - PHQ2 Score
PHQ-9 SCORE - 53333 - PHQ9 score

PSYDISTRHEUM - 40773 - BPRS score

CRAFFT_SCORE	230587	Crafft score
CRAFFT12MOQ1	385369	Crafft Q1 (pre)
CRAFFT12MOQ2	385370	Crafft Q2 (pre)
CRAFFT12MOQ3	385371	Crafft Q3 (pre)
CRFTFOLUP		497249	Crafft initial / follow up
*/

drop table if exists [CpsWarehouse].[cps_bh].[BH_Metric_All];
create table [CpsWarehouse].[cps_bh].[BH_Metric_All](
	PID numeric(19,0) not null,
	SDID numeric(19,0) not null,
	Obsdate date not null,
	PubUser numeric(19,0) not null,
	BH_Metric varchar(30) not null,
	BH_Result varchar(20) not null
)


go


drop proc if exists [cps_bh].[ssis_BH_Metric_All];
go
create procedure [cps_bh].[ssis_BH_Metric_All]
as begin

truncate table [cps_bh].[BH_Metric_All];

/*Get All BH Metric Obs*/
begin
	/*define hdid into metric*/
	drop table if exists #metric_define;
	select 
		o.hdid, o.name,
		coalesce
		(
			case HDID 
				when 217287 then 'Audit_Pre'
				when 411704 then 'Audit_Type'
				when 36210 then 'Audit_Score'
				when 217288 then 'Dast_Pre'
				when 411705 then 'Dast_Type'
				when 39141 then 'Dast_Score'
				when 65683 then 'PHQ_Pre'
				when 53333 then 'PHQ_Score'
				when 53332 then 'PHQ_Type'
			end,
			case HDID
				when 40773 then 'BPRS'
				when 230587 then 'Crafft_Score'
				when 385369 then 'Crafft_Pre'
				when 385370 then 'Crafft_Pre'
				when 385371 then 'Crafft_Pre'
				when 497249 then 'Crafft_Type'
			end,
			case 
				when hdid in (48381, 222891, 62714, 61014, 181245, 61012, 49608)   then 'DocumentType'
				when hdid in (489708, 489709) then 'VisitType'
			end

		) BH_Metric
	into #metric_define
	from [cpssql].CentricityPS.dbo.obshead o
	where o.hdid IN 
		(
			489709,489708,									/*visit type - BH, ongoing, consult, discharge*/
			49608,181245,61012,48381, 222891,62714,61014,	/*type of note*/
			217287,411704,36210,							/*Audit*/
			217288,411705,39141,							/*Dast*/
			53332,65683,53333,								/*phq*/
			40773,											/*bprs*/
			230587,385369,385370,385371,497249				/*crafft*/
		);

-- select * from #metric_define
	/*get relevant metric for patient with BH appointment*/
	declare @cutoffDate date = '2014-01-01';
	drop table if exists #all_metric;
		select 
			obs.PID PID, obs.sdid SDID, obs.pubuser PubUser, obs.hdid hdid,  obs.obsdate obsdate,
			d.BH_Metric,
			case obs.hdid
				when 489708 then
					case obsvalue 
						when 'ongoing BH patient' then 'Ongoing'
						when 'consult BH patient/short term therapy' then 'Consult'
						when 'patient discharged from all BH services' then 'Discharged'
						else 'Call me'
					end
				when 489709 then 
					case obsvalue 
						when 'Behavioral Health' then 'BH'
						else obsvalue
					end
				else obs.obsvalue
			end  ObsValue
		into #all_metric
		from [CpsWarehouse].cps_bh.BH_Patient bh
			left join [cpssql].CentricityPS.dbo.obs on obs.pid = bh.PID
			inner join #metric_define d on d.hdid = obs.hdid	
		where 
			obs.xid = 1000000000000000000								/*final value*/
			and obs.change not in  (10,11,12)							/*remove file in error*/
			and obs.obsdate >= @cutoffDate								/*older visit were setup diffently*/
			and obs.pubuser != 0										/*remove unsigned*/
			;
end

/*Clean up each metric*/
begin
	/*pre audit, pre dast and pre phq / phq2
	0 if no need full 
	1 if pre questionaire requires follow up

	select * from #all_metric where hdid in  (489709) order by obsdate desc
	*/
	drop table if exists #pre_metric;
	select 
		PID, SDID, ObsDate, PubUser, 
		BH_Metric,
			case 
				when HDID = 217287 and obsvalue = 'Never' then 0
				when HDID = 217287 and obsvalue = '1 or more' then 1
				when HDID = 217288 and obsvalue = 'Never' then 0
				when HDID = 217288 and obsvalue = '1 or more' then 1 
				when HDID = 65683 and obsvalue = 'no' then 0
				when HDID = 65683 and obsvalue = 'yes' then 1
				when HDID = 65683 and obsvalue = 'done' then 0
			
			end BH_Result
	into #pre_metric
	from #all_metric
	where HDID in (217287, 217288,65683 );

	drop table if exists #pre_Crafft;
	with cra as (
		select 
			PID, SDID, ObsDate, PubUser, 
			BH_Metric,
				case 
					when hdid = 85369 and obsvalue = 'No' then 0
					when hdid = 85369 and obsvalue = 'Yes' then 1
					when hdid = 385370 and obsvalue = 'No' then 0
					when hdid = 385370 and obsvalue = 'Yes' then 1
					when hdid = 385371 and obsvalue = 'No' then 0
					when hdid = 385371 and obsvalue = 'Yes' then 1
					else obsvalue
				end BH_Result
		from #all_metric
		where HDID in (85369,385370,385371 )
	)
	select 
		PID, SDID, ObsDate, PubUser, BH_Metric, 
		max(BH_Result) BH_Result /*max is 1. if one then need follow up*/
	into #pre_Crafft
	from cra
	group by PID, SDID, ObsDate, PubUser, BH_Metric;


	/*audit results with pivot
		arrange all audit score ascending by date.
		First one is initial and rest is followup 
	*/
	drop table if exists #audit_results;
	with aud as ( 
		select 
			PID, SDID, PubUser, ObsDate, HDID, ObsValue, 
			try_convert(int,ObsValue) BH_Result,
			rowNum = ROW_NUMBER() over(partition by PID order by obsdate asc)
		from #all_metric
		where HDID in (36210)
			and ObsValue != 'incomplete'
	)
		select 
			PID, SDID, ObsDate, PubUser,
			case rowNum when 1 then 'Audit_Initial'
				else 'Audit_Followup'
			end BH_Metric,
			BH_Result
		into #audit_results
		from aud;

	/*dast - same pivot as audit*/
	drop table if exists #dast_results;
	with dast as ( 
		select 
			PID, SDID, PubUser, ObsDate, HDID, ObsValue, 
			try_convert(int,ObsValue) BH_Result,
			rowNum = ROW_NUMBER() over(partition by PID order by obsdate asc)
		from #all_metric
		where HDID in (39141)
			and ObsValue != 'incomplete'
	)
		select 
			PID, SDID, ObsDate, PubUser, 
			case rowNum when 1 then 'Dast_Initial'
				else 'Dast_Followup'
			end BH_Metric,
			BH_Result
		into #dast_results
		from dast;

	/*phq: same pivot as dast and audit*/
	drop table if exists #phq_results;
	with phq as ( 
		select 
			PID, SDID, PubUser, ObsDate, HDID, ObsValue, 
			try_convert(int,ObsValue) BH_Result,
			rowNum = ROW_NUMBER() over(partition by PID order by obsdate asc)
		from #all_metric
		where HDID in (53333)
			and ObsValue != 'incomplete'
	)
		select 
			PID, SDID, ObsDate, PubUser,  
			case rowNum when 1 then 'Phq_Initial'
				else 'Phq_Followup'
			end BH_Metric,
			BH_Result
		into #phq_results
		from phq;

	/*crafft - same pivot as audit*/
	drop table if exists #crafft_results;
	with cra as ( 
		select 
			PID, SDID, PubUser, ObsDate, HDID, ObsValue, 
			try_convert(int,ObsValue) BH_Result,
			rowNum = ROW_NUMBER() over(partition by PID order by obsdate asc)
		from #all_metric
		where HDID in (230587)
			and ObsValue != 'incomplete'
	)
		select 
			PID, SDID, ObsDate, PubUser, 
			case rowNum when 1 then 'Crafft_Initial'
				else 'Crafft_Followup'
			end BH_Metric,
			BH_Result
		into #crafft_results
		from cra;
end

/*Clean up visit type*/
begin
	drop table if exists #visitType;
	;with val as (
		select 
			PID, SDID, PubUser, ObsDate, BH_Metric,  
			max(case  when hdid = 489709 then ObsValue end) x ,
			max(case  when hdid = 489708 then ObsValue end) y
		from #all_metric
		where hdid IN (489709,489708)
			and ObsValue != 'CBCM'
		group by PID, SDID, PubUser, ObsDate, BH_Metric
	)
		select
			PID, SDID, ObsDate, PubUser, 
			BH_Metric,
			case when y is null then x else y end BH_Result
		into #visitType
		from val;
end

/*Clean up Document type*/
begin
	/*Treatment Plan*/
	drop table if exists #treatment;
	with treat as (
		select
			PID, SDID, PubUser, ObsDate, BH_Metric,
			rowNum = ROW_NUMBER() over (partition by PID order by obsdate asc)
		from #all_metric
		where hdid in (61012)
	) 
		select 
			PID, SDID, ObsDate, PubUser, BH_Metric, 
			case rowNum when 1 then 'Treat_Initial'
				else 'Treat_Annual'
			end BH_Result
		into #treatment
		from treat;

	/*Diagnostic Eval*/
	drop table if exists #diagnostic;
	with diag as (
		select
			PID, SDID, ObsDate, PubUser,  BH_Metric, 
			rowNum = ROW_NUMBER() over (partition by PID order by obsdate asc)
		from #all_metric m
		where hdid in (49608)
	) 
		select 
			PID, SDID, PubUser, ObsDate, BH_Metric, 
			case rowNum when 1 then 'Diag_Initial'
				else 'Diag_Annual'
			end BH_Result
		into #diagnostic
		from diag;

	/*Consult, Psych, Group, discharge & progress clean up*/
	drop table if exists #RestDocType;
	select PID, SDID, ObsDate, PubUser, BH_Metric, 
		case hdid 
			when 48381 then 'Consult'
			when 222891 then 'Psych_Note'
			when 62714 then 'Group'
			when 61014 then 'Discharge'
			when 181245 then 'Progress_Note'			
		end BH_result
	into #RestDocType
	from #all_metric
	where hdid in (48381,222891,62714,61014,181245);

	
end 


; with comb as (
	select PID, SDID, ObsDate, PubUser, BH_Metric, convert(varchar(20), BH_result) BH_result
	from #pre_metric
	where BH_Result is not null
	union 
	select  PID, SDID, ObsDate, PubUser, BH_Metric, convert(varchar(20), BH_result) BH_result
	from #pre_Crafft 
	where BH_Result is not null
	union 
	select  PID, SDID, ObsDate, PubUser, BH_Metric, convert(varchar(20), BH_result) BH_result
	from #audit_results 
	where BH_Result is not null
	union 
	select  PID, SDID, ObsDate, PubUser, BH_Metric, convert(varchar(20), BH_result) BH_result
	from #dast_results  
	where BH_Result is not null
	union 
	select  PID, SDID, ObsDate, PubUser, BH_Metric, convert(varchar(20), BH_result) BH_result
	from #phq_results
	where BH_Result is not null
	union
	select  PID, SDID, ObsDate, PubUser, BH_Metric, convert(varchar(20), BH_result) BH_result
	from #crafft_results
	where BH_Result is not null
	union 
	select  PID, SDID, ObsDate, PubUser, BH_Metric, convert(varchar(20), BH_result) BH_result
	from #visitType
	where BH_Result is not null
	union
	select  PID, SDID, ObsDate, PubUser, BH_Metric, convert(varchar(20), BH_result) BH_result
	from #treatment
	where BH_Result is not null
	union
	select  PID, SDID, ObsDate, PubUser, BH_Metric, convert(varchar(20), BH_result) BH_result
	from #diagnostic
	where BH_Result is not null
	union
	select  PID, SDID, ObsDate, PubUser, BH_Metric, convert(varchar(20), BH_result) BH_result
	from #RestDocType
	where BH_Result is not null
)
, dist as (
	select  
		PID, SDID, ObsDate, PubUser, BH_Metric, BH_result, 
		RowNUm = ROW_NUMBER() over(partition by PID, SDID, ObsDate, PubUser, BH_Metric order by obsdate desc)
	from comb
)
, u as (
	select * 
	from dist
	where RowNUm  = 1
)


	insert into [cps_bh].[BH_Metric_All] (PID, SDID, ObsDate,PubUser, BH_Metric, BH_Result)
	select PID, SDID, ObsDate,PubUser, BH_Metric, BH_Result from u;

end

GO
