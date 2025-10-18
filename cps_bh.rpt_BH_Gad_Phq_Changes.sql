use CpsWarehouse
go


drop proc if exists cps_bh.rpt_BH_Gad_Phq_Changes;

go

create proc cps_bh.rpt_BH_Gad_Phq_Changes (
	@metric varchar(3),
	@year int
)
 as 
 begin
	--declare @metric varchar(3) = 'gad', @year int = 2021;

	drop table if exists #selected_metric;
	select distinct metric
	into #selected_metric
	from cps_bh.BH_phq_Gad
	where Metric like  @metric + '%'
		and Metric like '%Score'
		and Metric != @metric + '2_Score'


	;with raw_data as --GAD - 1274, PHQ - 7103, GAD for 2021 - , PHQ for 2021 - 
	(
		select 
			m.PID, m.Metric, PatientID, ObsDate, convert(int, Obsvalue) ObsValue, Month, MonthName, Year, Quarter, 
			FirstMetricForYear = ROW_NUMBER() over(partition by PID, m.Metric, Year order by obsdate asc),
			LastMetricForYear = ROW_NUMBER() over(partition by PID, m.Metric, Year order by obsdate desc)
		from cps_bh.rpt_view_BH_GAD_PHQ m
			inner join #selected_metric s on s.Metric = m.Metric
		where ISNUMERIC(obsvalue) = 1
			and Year = @year
	)
	,metric_count as (--258, 1262, GAD for 2021 - 219 , PHQ for 2021 - 272
		select PID, Metric, Year, count(*) MetricCountPerYear
		from raw_data
		group by PID, Metric, Year
		having count(*) > 1
	)
	, first_vist as (--258, 1262
		select r.PID, r.PatientID, r.Metric, r.ObsDate, ObsValue, r.year
		from raw_data r
			inner join metric_count m on r.pid = m.PID and m.Metric = r.Metric and m.Year = r.Year
		where FirstMetricForYear = 1 
	)
	, last_vist as ( --258, 1262
		select r.PID, r.Metric, r.ObsDate, ObsValue, r.year
		from raw_data r
			inner join metric_count m on r.pid = m.PID and m.Metric = r.Metric and m.Year = r.Year
		where LastMetricForYear = 1 
	)

	select 
		f.PID, f.PatientID, f.Metric, f.year, 
		f.ObsDate FirstDate, f.ObsValue FirstValue, 
		l.ObsDate LastDate, l.ObsValue LastValue,
		l.ObsValue - f.ObsValue Change
	from first_vist f
		left join last_vist l on l.pid = f.PID and l.Metric = f.Metric and l.Year = f.Year

end

go
