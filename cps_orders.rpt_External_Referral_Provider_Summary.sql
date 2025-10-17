
USE CpsWarehouse
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


drop PROCEDURE if exists [cps_orders].[rpt_External_Referral_Provider_Summary] 
go

create procedure [cps_orders].[rpt_External_Referral_Provider_Summary] 
(
	@StartDate date,
	@EndDate date,
	@Facility nvarchar(15) = null
)
as 
begin

--declare @startDate date = '1-1-2019', 
--	@endDate date = '12-31-2019', 
--	@facility nvarchar(10) = 'All';


declare 
	@Facility1 nvarchar(15) = case when @Facility = 'All' then null  else @Facility end,
	@StartDate1 date = convert(date, @StartDate),
	@EndDate1 date = convert(date, @EndDate) 


;with u as (
	select 
		r.OrderProvider, r.Facility,r.PID,
		month(r.OrderDate) Months, datename(month, 	r.OrderDate) MonthNames, year(	r.OrderDate) Years,
		case r.CurrentStatus 
			when 'C' then 'Complete'
			when 'H' then 'Admin Hold'
			when 'S' then 'In Process'
		end Status
	from cps_orders.rpt_view_ExternalReferral r
	where 
		r.OrderDate  >= @Startdate1
		and r.OrderDate <= @EndDate1
		and r.facilityID = isnull(@facility1, r.facilityID)
)
, countPerMonth as (
	select 
		OrderProvider, Facility, Status, Months, MonthNames, Years,
		count(*) Total
	from u
	group by OrderProvider, Facility, Status, Months, MonthNames, Years
)
	select pvt.OrderProvider, pvt.Facility, pvt.Status, pvt.years, 
		isnull(pvt.January,0) January, isnull(pvt.February,0) February, isnull(pvt.March,0) March, isnull(pvt.April,0) April, 
		isnull(pvt.May,0) May, isnull(pvt.June,0) June, isnull(pvt.July,0) July, isnull(pvt.August,0) August, 
		isnull(pvt.September,0) September, isnull(pvt.October,0) October, isnull(pvt.November,0) November, isnull(pvt.December,0) December

	from
	(
		select c.OrderProvider, c.Facility, c.Status, c.MonthNames, c.Total, c.Years
		from countPerMonth c
	) q
	pivot 
	(
		max(Total)
		for monthNames in (January, February, March, April, May, June, July, August, September,  October, November, December)
	) pvt
end 
go
