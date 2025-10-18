

use CpsWarehouse
go

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


drop proc if exists cps_bh.rpt_BH_sbirt_count_by_month;
go
create procedure cps_bh.rpt_BH_sbirt_count_by_month
as
begin


;with distinct_sbirt_patient as (	
	select * 
	from cps_bh.rpt_view_BHSbirt_Code_Obs

)
, total_sbirt as (
	select 
		pvt.Year,  'Total Encounter' Metric,
		January, February, March, April, May, June, 
		July, August, September,  October, November, December
	from
	(

		select q.PID,q.MonthName, q.Year--, BH_Metric
		from (
			select distinct s.PID, s.Date, s.MonthName, s.year, BH_Metric
			from  distinct_sbirt_patient s
		) q
	)q
	 pivot 
	(
		count(PID)
		for monthName in (January, February, March, April, May, June, July, August, September,  October, November, December)
	) pvt
) --select * from total_sbirt
, total_sbirt_metric as (
	select 
		pvt.Year,  BH_metric + ' Total Encounter' Metric,
		January, February, March, April, May, June, 
		July, August, September,  October, November, December
	from
	(
		select q.PID,q.MonthName, q.Year, BH_Metric
		from (
			select distinct s.PID, s.Date, s.MonthName, s.year, BH_Metric
			from  distinct_sbirt_patient s
		) q
	)q
	 pivot 
	(
		count(PID)
		for monthName in (January, February, March, April, May, June, July, August, September,  October, November, December)
	) pvt
) --select * from total_sbirt_metric order by year, Metric
, unique_sbirt as (
	select 
		pvt.Year, 'Unique Patient' Metric,
		January, February, March, April, May, June, 
		July, August, September,  October, November, December
	from
	(

		select q.PID,q.MonthName, q.Year
		from (
			select distinct s.PID, s.Date, s.MonthName, s.year
			from  distinct_sbirt_patient s
		) q
	)q
	 pivot 
	(
		count(PID)
		for monthName in (January, February, March, April, May, June, July, August, September,  October, November, December)
	) pvt
) --select * from unique_sbirt
, unique_sbirt_metric as (
	select 
		pvt.Year, BH_Metric + ' Unique Patient' Metric,
		January, February, March, April, May, June, 
		July, August, September,  October, November, December
	from
	(
		select q.PID,q.MonthName, q.Year, BH_Metric
		from (
			select distinct s.PID, s.Date, s.MonthName, s.year, BH_Metric
			from  distinct_sbirt_patient s
		) q
	)q
	 pivot 
	(
		count(PID)
		for monthName in (January, February, March, April, May, June, July, August, September,  October, November, December)
	) pvt
) --select * from unique_sbirt_metric order by year, Metric
, quarterly_sbirt as (
	select *
	from 
	(
		select distinct Year, quarter, PID
		from distinct_sbirt_patient
	) q
	pivot
	(
		count(PID)
		for quarter in ([1],[2],[3],[4])
	) pvt
) --select * from quarterly_sbirt
, quarterly_sbirt_metric as (
	select *
	from 
	(
		select distinct BH_Metric, Year, quarter, PID
		from distinct_sbirt_patient
	) q
	pivot
	(
		count(PID)
		for quarter in ([1],[2],[3],[4])
	) pvt
) --select * from quarterly_sbirt_metric
, yearly_sbirt as (
	select  Year,  count(distinct PID) Total
	from distinct_sbirt_patient
	group by  Year
) --select * from yearly_sbirt
, yearly_sbirt_metric as (
	select  Year, BH_Metric, count(distinct PID) Total
	from distinct_sbirt_patient
	group by  Year, BH_Metric
) --select * from yearly_sbirt_metric

	select t.*, 
		January + February + March + April + 
		May + June + July + August +
		September + October + November + December Yearly_Total,
		January + February + March Q1,
		April + May + June Q2,
		July + August + September Q3,
		October + November + December Q4
	from total_sbirt t

	union

	select u.*, y.Total Yearly_Total, q.[1] Q1, q.[2] Q2, q.[3] Q3, q.[4] Q4
	from unique_sbirt u
		left join yearly_sbirt y on y.year = u.year --and y.BH_Metric + ' Unique' = u.Metric
		left join quarterly_sbirt q on q.year = u.year --and q.BH_Metric + ' Unique' = u.Metric

	union

	select t.*, 
		January + February + March + April + 
		May + June + July + August +
		September + October + November + December Yearly_Total,
		January + February + March Q1,
		April + May + June Q2,
		July + August + September Q3,
		October + November + December Q4
	from total_sbirt_metric t

	union

	select u.*, y.Total Yearly_Total, q.[1] Q1, q.[2] Q2, q.[3] Q3, q.[4] Q4
	from unique_sbirt_metric u
		left join yearly_sbirt_metric y on y.year = u.year and y.BH_Metric + ' Unique Patient' = u.Metric
		left join quarterly_sbirt_metric q on q.year = u.year and q.BH_Metric + ' Unique Patient' = u.Metric

	order by year, Metric

end 
go
