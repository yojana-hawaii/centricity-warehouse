USE CpsWarehouse
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
drop proc if exists cps_track.[Yearly_Productivity_by_Site]
go
create proc cps_track.[Yearly_Productivity_by_Site]
	(
		@StartDate date,
		@EndDate date
	)
as 
begin


	--declare @StartDate date = '2021-01-01', @EndDate date = '2021-12-31';

;with all_tickets as (
select 
	loc.Facility , loc.FacilityID, pvt.PID, pvt.PatientVisitID, convert(date,pvt.DoS) DOS,
	month(pvt.DoS) Months, datename(month,pvt.DoS) MonthNames, year(pvt.DoS) Years
from cps_visits.PatientVisitType pvt
	left join cps_all.Location loc on loc.FacilityID = pvt.FacilityID and loc.LocParentID = 0 and loc .locID != 0
where convert(date, DoS) >= @StartDate
	and CONVERT(date, DOS) <= @EndDate
	and (
			MedicalVisit = 1
			or BHVisit = 1 
			or OptVisit = 1
		)
), countPerMonth as (
	select 
		Facility, Count(distinct PatientVisitID) VisitCount, count(distinct PID) PatientCount, MonthNames, Months, Years
	from all_tickets
	group by MonthNames, Months, Years, Facility
), countPerYear as (
	select 
		Facility, Count(distinct PatientVisitID) VisitCount, count(distinct PID) PatientCount,  Years
	from all_tickets
	group by  Years, Facility
)


(
--total visits 
	select 
		pvt.Facility, pvt.Years, 'Total Encounters' GroupedBy,
		isnull(pvt.January,0) January, isnull(pvt.February,0) February, isnull(pvt.March,0) March, isnull(pvt.April,0) April, 
		isnull(pvt.May,0) May, isnull(pvt.June,0) June, isnull(pvt.July,0) July, isnull(pvt.August,0) August, 
		isnull(pvt.September,0) September, isnull(pvt.October,0) October, isnull(pvt.November,0) November, isnull(pvt.December,0) December,
		isnull(y.VisitCount,0) TotalYear
	from(
	select Facility, years, monthNames, visitCount
	from countPerMonth
	) q
	pivot(
	max(visitCount)
	for monthNames in (January, February, March, April, May, June, July, August, September,  October, November, December)
	) pvt
		left join countPerYear y on y.Facility = pvt.Facility and y.Years = pvt.Years

	union

---- unique patients

	select 
		pvt.Facility, pvt.Years, 'Unique Patient' GroupedBy,
		isnull(pvt.January,0) January, isnull(pvt.February,0) February, isnull(pvt.March,0) March, isnull(pvt.April,0) April, 
		isnull(pvt.May,0) May, isnull(pvt.June,0) June, isnull(pvt.July,0) July, isnull(pvt.August,0) August, 
		isnull(pvt.September,0) September, isnull(pvt.October,0) October, isnull(pvt.November,0) November, isnull(pvt.December,0) December,
		isnull(y.PatientCount,0) TotalYear
	from(
	select Facility, years, monthNames, PatientCount
	from countPerMonth
	) q
	pivot(
	max(PatientCount)
	for monthNames in (January, February, March, April, May, June, July, August, September,  October, November, December)
	) pvt
		left join countPerYear y on pvt.Facility = y.Facility and pvt.Years = y.Years
) 

end
go