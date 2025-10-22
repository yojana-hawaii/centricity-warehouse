
use CpsWarehouse
go


drop proc if exists cps_track.Yearly_Productivity_Report;
go
create procedure cps_track.Yearly_Productivity_Report
	(
		@StartDate date,
		@EndDate date,
		@bh int = 0
	)
as
begin
--	Declare @StartDate date = '2021-01-01', @EndDate date = '2021-12-31';

;with all_tickets as (
	select --pvt.*,
		appt.ListName [Provider], pvt.PatientVisitID, pvt.TicketNumber, pvt.PID,
		case when (OptVisit = 1 or MedicalVisit = 1 or BHVisit = 1) then 1 else 0 end 'E&MCode',
		month(pvt.DoS) Months, datename(month,pvt.DoS) MonthNames, year(pvt.DoS) Years
	from CpsWarehouse.cps_visits.PatientVisitType pvt
		left join CpsWarehouse.cps_all.DoctorFacility appt on appt.DoctorFacilityID = pvt.ApptProviderID

	where convert(date,pvt.DoS) >= @StartDate
		and convert(date,pvt.DoS) <= @EndDate
		and appt.ListName is not null
		and (OptVisit = 1 or MedicalVisit = 1 or BHVisit = 1) 
		and appt.Specialty like case when @bh = 1 then 'Behavioral Health' else '%' end
)
--	select * from all_tickets 
, countPerMonth as (
	select [Provider], count(*) VisitCount, count(distinct PID) PatientCount, MonthNames, Months, Years
	from all_tickets a
	group by [Provider], years, months, monthNames
)
--select * from countPerMonth	

, countPerYear as (
	select [Provider], count(*) VisitCount, count(distinct PID) PatientCount, Years
	from all_tickets a
	group by [Provider], years
)
--select * from countPerYear	

, concat_total_unique as  
(
	select 
		pvt.Provider, pvt.Years, 'Total Encounters' GroupedBy,
		isnull(pvt.January,0) January, isnull(pvt.February,0) February, isnull(pvt.March,0) March, isnull(pvt.April,0) April, 
		isnull(pvt.May,0) May, isnull(pvt.June,0) June, isnull(pvt.July,0) July, isnull(pvt.August,0) August, 
		isnull(pvt.September,0) September, isnull(pvt.October,0) October, isnull(pvt.November,0) November, isnull(pvt.December,0) December,
		isnull(cnt.VisitCount, 0) Total
	from(
		select Provider, years, monthNames, visitCount
		from countPerMonth
	) q
	pivot(
		max(visitCount)
		for monthNames in (January, February, March, April, May, June, July, August, September,  October, November, December)
	) pvt
		left join countPerYear cnt on cnt.Years = pvt.Years and cnt.Provider = pvt.Provider

union

-- unique patients

	select 
		pvt.Provider, pvt.Years, 'Unique Patient' GroupedBy,
		isnull(pvt.January,0) January, isnull(pvt.February,0) February, isnull(pvt.March,0) March, isnull(pvt.April,0) April, 
		isnull(pvt.May,0) May, isnull(pvt.June,0) June, isnull(pvt.July,0) July, isnull(pvt.August,0) August, 
		isnull(pvt.September,0) September, isnull(pvt.October,0) October, isnull(pvt.November,0) November, isnull(pvt.December,0) December,
		isnull(cnt.PatientCount, 0) Total
	from(
		select Provider, years, monthNames, PatientCount
		from countPerMonth
	) q
	pivot(
		max(PatientCount)
		for monthNames in (January, February, March, April, May, June, July, August, September,  October, November, December)
	) pvt
		left join countPerYear cnt on cnt.Years = pvt.Years and cnt.Provider = pvt.Provider
)
	select * 
	from concat_total_unique
	order by [Provider]


end 
GO

