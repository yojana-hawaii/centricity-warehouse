use CpsWarehouse
go


drop proc if exists cps_orders.rpt_OrderStatusSummary
go

create proc cps_orders.rpt_OrderStatusSummary
(
	@StartDate date,
	@EndDate date
)
as
begin



;with raw_data as (
	select --top 100 
	case 
		when o.OrderClassification = 'EXT' then 'Ext Referral'
		when o.OrderClassification in ('CLH','DLS','DOH','HPL') then 'Labs'
		when o.OrderClassification in ('RAD', 'HDRS') then 'Imaging'
	end OrderTypes, 
	orderdesc + ' (' + ordercode + ')' Orders,
	case o.CurrentStatus
		when 'X' then 'Cancel'
		when 'C' then 'Complete'
		when 'H' then 'Admin Hold'
		when 'S' then 'In Process'
	end Status, 
	d.Year, d.Quarter, d.MonthName, o.Facility, PID
	from cps_orders.Fact_all_orders o
		left join dbo.dimDate d on d.date = o.OrderDate
	where o.OrderClassification  in ('EXT','CLH','DLS','DOH','HPL','RAD', 'HDRS')
		and OrderDate >= @StartDate and o.OrderDate <= @EndDate
		and Facility in ('facilit A', 'B', 'C', 'D')
)
	, monthly as (
	select *
	from (
		select OrderTypes, Orders, PID,  Status , MonthName,  Year
		from raw_data
	) q
	pivot (
		count(PID)
		for monthName in (January, February, March, April, May, June, July, August, September,  October, November, December)
	) pvt
)
, quarterly as (
	select *
	from 
	(
		select OrderTypes, Orders, PID,  Status , Quarter,  Year
		from raw_data
	) q
	pivot
	(
		count(PID)
		for quarter in ([1],[2],[3],[4])
	) pvt
)
, yearly as (
	select OrderTypes, Orders, count(PID) Total,  Status ,  Year
		from raw_data
	group by Year,  Status, OrderTypes, Orders
)
	select m.*
		, q.[1] Q1,q.[2] Q2,q.[3] Q3,q.[4] Q4
		,y.Total
	from monthly m
		left join quarterly q on m.OrderTypes = q.OrderTypes and m.Orders= q.Orders and  m.Year = q.Year and m.Status = q.Status
		left join yearly y on m.OrderTypes = y.OrderTypes and m.Orders = y.Orders and m.Year = y.Year and m.Status = y.Status
	--order by  Specialist, year, tpye, CurrentStatus

end

go
