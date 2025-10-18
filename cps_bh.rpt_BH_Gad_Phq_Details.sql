


use CpsWarehouse
go

drop proc if exists cps_bh.rpt_bh_phq_gad_details;

go

create proc cps_bh.rpt_bh_phq_gad_details
(
	@metric varchar(3),
	@year int = 2021,
	@month int = 1
)

as 
begin


--	declare @metric varchar(3) = 'gad', @year int = 2021, @month int = 1

	drop table if exists #selected_metric;
	select distinct metric
	into #selected_metric
	from cps_bh.BH_phq_Gad
	where Metric like  @metric + '%'
		and Metric like '%Score'
		and Metric != @metric + '2_Score'

	select m.PID, m.PatientID, m.ListName Prov, m.ObsDate, m.Metric, m.ObsValue, m.Month, m.MonthName, m.Year, m.Quarter
	from cps_bh.rpt_view_BH_GAD_PHQ m
		inner join #selected_metric s on s.Metric = m.Metric
	where Year = @year
		and Month = @month
		
end

go
