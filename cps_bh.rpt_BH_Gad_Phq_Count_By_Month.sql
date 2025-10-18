

use CpsWarehouse

go


drop proc if exists cps_bh.rpt_BH_Gad_Phq_Count_By_Month;
go

create proc cps_bh.rpt_BH_Gad_Phq_Count_By_Month
(
	@metric varchar(3) = 'phq'
)

as 
begin
	--declare @metric varchar(3) = 'phq', @year int = 2021, @month int = 1

	drop table if exists #selected_metric;
	select distinct metric
	into #selected_metric
	from cps_bh.BH_phq_Gad
	where Metric like  @metric + '%'
		and Metric like '%Score';

	;with raw_data as (
		select m.*
		from cps_bh.rpt_view_BH_GAD_PHQ m
			inner join #selected_metric s on s.Metric = m.Metric
	)
	, total_cnt as (
		select 
			pvt.Year,  Metric + ' Total Encounter' Metric,
			January, February, March, April, May, June, 
			July, August, September,  October, November, December
		from (
			select PID, MonthName, Year, Metric
			from raw_data
		) q
		pivot 
		(
			count(PID)
			for  monthName in (January, February, March, April, May, June, July, August, September,  October, November, December)
		) pvt
	)
	, unique_cnt as (
		select 
			pvt.Year,  Metric + ' Unique Patient' Metric,
		January, February, March, April, May, June, 
		July, August, September,  October, November, December
		from (
			select distinct PID, MonthName, Year, Metric
			from raw_data
		) q
		pivot 
		(
			count(PID)
			for  monthName in (January, February, March, April, May, June, July, August, September,  October, November, December)
		) pvt
	)
	, quarterly_Uniqe as (
		select pvt.Year, pvt.Metric, pvt.[1], pvt.[2], pvt.[3], pvt.[4]	
		from 
		(
			select distinct Year, quarter, PID, metric
			from raw_data
		) q
		pivot
		(
			count(PID)
			for quarter in ([1],[2],[3],[4])
		) pvt
	)
	, yearly_Uniqe as (
		
		select Year, count(distinct PID) Total, metric
		from raw_data
		group by year, Metric
		
	)
	select t.*, 
		January + February + March + April + 
		May + June + July + August +
		September + October + November + December Yearly_Total,
		January + February + March Q1,
		April + May + June Q2,
		July + August + September Q3,
		October + November + December Q4
	from total_cnt t
	union all
	select u.*,
		y.Total,
		q.[1] Q1, q.[2] Q2, q.[3] Q3, Q.[4] Q4
	from unique_cnt u
		left join quarterly_Uniqe q on u.Year = q.Year and u.Metric = q.Metric + ' Unique Patient'
		left join yearly_Uniqe y on u.Year = y.Year and u.Metric = y.Metric + ' Unique Patient'

end

go
