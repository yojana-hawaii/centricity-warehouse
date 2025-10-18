
use CpsWarehouse
go

drop table if exists CpsWarehouse.cps_bh.BH_phq_Gad;
go

create table cps_bh.BH_phq_Gad (
	[PID] [numeric](19, 0) NOT NULL,
	[SDID] [numeric](19, 0) NOT NULL,
	[ListName] varchar(50) NOT NULL,
	[Facility] [varchar](20) not NULL,
	[Metric] [varchar](25) NOT NULL,
	[ObsDate] [date] NOT NULL,
	[ObsValue] [varchar](max) NULL,
)
go

drop proc if exists cps_bh.ssis_BH_Phq_Gad;
go

create proc cps_bh.ssis_BH_Phq_Gad
as 
begin
	truncate table cps_bh.BH_phq_Gad;

	drop table if exists #hdid
	select HDID, Obsterm 
	into #hdid
	from cps_obs.ObsHead
	where ObsTerm in('PHQ9_2', 'PHQ22', 'PHQ21','PHQ9','PHQ-9 SCORE',
					'GAD-2SCORE','GAD 2','GAD 1','GAD7 INTERP','GAD SCORE');

	;with all_phq_Gad as (
		select 
			obs.PID PID, obs.SDID SDID, h.ObsTerm, 
			df.ListName, convert(date, obsdate) obsdate, obsvalue ObsValue, 
			doc.Facility, datediff(year, pp.dob, obsdate) AgeInYears
		from cpssql.CentricityPS.dbo.Obs
			inner join #hdid h on h.HDID = obs.hdid
			left join cps_all.DoctorFacility df on df.PVID = obs.PUBUSER
			inner join cps_visits.Document doc on doc.sdid = obs.sdid
			left join cps_all.PatientProfile pp on pp.pid = obs.PID 
		where  obs.XID  = 1000000000000000000
			and obs.obsdate >= '2018-01-01'
	)
	, u as (
		select 
			PID, SDID, ListName, Facility, obsdate, 'Phq2_Score' Metric, 
			convert(varchar(1), pvt.PHQ21 + pvt.PHQ22) Obsvalue
		from (
			select * 
			from all_phq_Gad
			 where ObsTerm in( 'PHQ22', 'PHQ21')
		) q
		pivot (
			max(obsvalue)
			for obsterm in ([PHQ21],[PHQ22])
		) pvt

		union all

		select 
			PID, SDID, ListName, Facility, obsdate, 'Gad2_Score' Metric, 
			convert(varchar(1), pvt.[GAD 1] + pvt.[GAD 2]) Obsvalue
		from (
			select * 
			from all_phq_Gad
			 where ObsTerm in( 'GAD 2','GAD 1')
		) q
		pivot (
			max(obsvalue)
			for obsterm in ([GAD 1],[GAD 2])
		) pvt

		union all

		select 
			PID, SDID, ListName, Facility, obsdate,
			case ObsTerm
				when 'PHQ9_2' then 'Phq2_Interpretation'
				when 'GAD-2SCORE' then 'Gad2_Interpretation'
				when 'GAD7 INTERP' then 'Gad7_Interpretation'
				when 'GAD SCORE' then 'Gad7_Score'
			end Metric,

			ObsValue
		from all_phq_Gad
		where ObsTerm in('PHQ9_2','GAD-2SCORE','GAD7 INTERP','GAD SCORE')
		union all
		
		select 
			pg.PID, SDID, ListName, pg.Facility, obsdate, --AgeInYears, 
			case 
				when ObsTerm = 'PHQ9' and AgeInYears >= 1 and AgeInYears <= 17 then 'PhqA_Interpretation'
				when ObsTerm = 'PHQ-9 SCORE' and AgeInYears >= 1 and AgeInYears <= 17 then 'PhqA_Score'
				when ObsTerm = 'PHQ9' and AgeInYears >= 18 then 'Phq9_Interpretation'
				when ObsTerm = 'PHQ-9 SCORE' and AgeInYears >=18 then 'Phq9_Score'
				else 'PhqConnfused'
			end Metric,

			ObsValue
		from all_phq_Gad pg
			
		where ObsTerm in('PHQ9','PHQ-9 SCORE')
	)
	--select * from u
	--where metric not in ('Phq9_Interpretation', 'Phq9_Score', 'PhqA_Interpretation', 'PhqA_Score')
	--order by AgeInYears
	--where Facility is null

		insert into cps_bh.BH_phq_Gad(pid, SDID, ListName, Facility, ObsDate, Metric, ObsValue)
		select 
			pid, SDID, ListName, Facility, ObsDate, Metric, ObsValue
		from u
		where metric is not null

end

go
