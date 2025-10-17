use CpsWarehouse
go
drop proc if exists [cps_visits].[rpt_Productivity_Monthly_Ticket_Generated]
go
create procedure [cps_visits].[rpt_Productivity_Monthly_Ticket_Generated]
	(
		@StartDate date,
		@EndDate date
	)
as
begin

;with all_tickets as (
	select --pvt.*,
		appt.ListName [Provider], pvt.PatientVisitID, pvt.TicketNumber, pvt.PID,
		month(pvt.DoS) Months, datename(month,pvt.DoS) MonthNames, year(pvt.DoS) Years
	from cps_visits.PatientVisitType pvt
		left join cps_all.DoctorFacility appt on appt.DoctorFacilityID = pvt.ApptProviderID

	where convert(date,pvt.DoS) >= @StartDate
		and convert(date,pvt.DoS) <= @EndDate
		and  (OptVisit = 1 or MedicalVisit = 1 or BHVisit = 1) 
		and appt.ListName is not null
)
--	select * from all_tickets 
, countPerMonth as (
	select [Provider], count(*) VisitCount, count(distinct PID) PatientCount, MonthNames, Months, Years
	from all_tickets a
	group by [Provider], years, months, monthNames
)
--select * from countPerMonth	

--visits 
(
	select 
		pvt.Provider, pvt.Years, 'Total Encounters' GroupedBy,
		isnull(pvt.January,0) January, isnull(pvt.February,0) February, isnull(pvt.March,0) March, isnull(pvt.April,0) April, 
		isnull(pvt.May,0) May, isnull(pvt.June,0) June, isnull(pvt.July,0) July, isnull(pvt.August,0) August, 
		isnull(pvt.September,0) September, isnull(pvt.October,0) October, isnull(pvt.November,0) November, isnull(pvt.December,0) December
	from(
	select Provider, years, monthNames, visitCount
	from countPerMonth
	) q
	pivot(
	max(visitCount)
	for monthNames in (January, February, March, April, May, June, July, August, September,  October, November, December)
	) pvt

union

-- unique patients

	select 
		pvt.Provider, pvt.Years, 'Unique Patient' GroupedBy,
		isnull(pvt.January,0) January, isnull(pvt.February,0) February, isnull(pvt.March,0) March, isnull(pvt.April,0) April, 
		isnull(pvt.May,0) May, isnull(pvt.June,0) June, isnull(pvt.July,0) July, isnull(pvt.August,0) August, 
		isnull(pvt.September,0) September, isnull(pvt.October,0) October, isnull(pvt.November,0) November, isnull(pvt.December,0) December
	from(
	select Provider, years, monthNames, PatientCount
	from countPerMonth
	) q
	pivot(
	max(PatientCount)
	for monthNames in (January, February, March, April, May, June, July, August, September,  October, November, December)
	) pvt
)



end

go