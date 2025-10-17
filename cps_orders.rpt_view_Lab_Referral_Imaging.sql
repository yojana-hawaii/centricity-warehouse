
use CpsWarehouse
go
drop view if exists cps_orders.rpt_view_Lab_Referral_Imaging
go

create view cps_orders.rpt_view_Lab_Referral_Imaging
as 

with raw_data as (
	select --top 100 
	case 
		when o.OrderClassification = 'EXT' then 'External Referral'
		when o.OrderClassification in ('CLH','DLS','DOH','HPL') then 'Labs'
		when o.OrderClassification in ('RAD', 'HDRS') then 'Imaging'
	end OrderTypes, 
	case o.CurrentStatus
		when 'X' then 'Cancel'
		when 'C' then 'Complete'
		when 'H' then 'Admin Hold'
		when 'S' then 'In Process'
	end Status, 
	d.Year, d.Quarter, o.Facility, PID
	from cps_orders.Fact_all_orders o
		left join dbo.dimDate d on d.date = o.OrderDate
	where o.OrderClassification  in ('EXT','CLH','DLS','DOH','HPL','RAD', 'HDRS')
		and d.Year >= 2017 and o.OrderDate <= convert(date, getdate())
		and Facility in ('fac A', 'Facility B', 'Facility C', 'Facility D')
)
, total_orders_per_facility as (
	select Year, Quarter, OrderTypes,Facility, count(*) Total 
	from raw_data
	group by Year, Quarter, Facility, OrderTypes
)
, total_orders_entire_clinic as (
	select Year, Quarter, OrderTypes, count(*) Total 
	from raw_data
	group by Year, Quarter,  OrderTypes
)
, total_entire_clinic as (
	select distinct
		pvt.Year, 'Quarter ' + convert(varchar(1), pvt.Quarter) Quarter, pvt.OrderTypes,  'Total' Facility,
		t.Total, pvt.[Admin Hold], pvt.[In Process], pvt.Complete, pvt.Cancel
 	from (
		select Year, Quarter, OrderTypes, Status, PID 
		from raw_data
	) q
	pivot (
		count(PID)
		for Status in ([Admin Hold], [In Process], [Complete], [Cancel])
	)pvt
		left join total_orders_entire_clinic t on t.Year = pvt.Year and t.Quarter = pvt.Quarter
							and t.OrderTypes = pvt.OrderTypes
)
, by_facility as (

	select 
		pvt.Year, 'Quarter ' + convert(varchar(1), pvt.Quarter) Quarter, pvt.OrderTypes, pvt.Facility, 
		t.Total, pvt.[Admin Hold], pvt.[In Process], pvt.Complete, pvt.Cancel
 	from (
		select Year, Quarter, OrderTypes,Facility,  Status, PID 
		from raw_data
	) q
	pivot (
		count(PID)
		for Status in ([Admin Hold], [In Process], [Complete], [Cancel])
	)pvt
		left join total_orders_per_facility t on t.Year = pvt.Year and t.Quarter = pvt.Quarter
						and t.OrderTypes = pvt.OrderTypes and t.Facility = pvt.Facility
)
	select 
		* ,
		[Percent Including Cancel] = cast( cast(Complete * 100.0 / Total as decimal(10,2) ) as varchar(6) ) + ' %' ,
		[Percent Excluding Cancel] = cast( cast(Complete * 100.0 / (Total - Cancel) as decimal(10,2) ) as varchar(6) ) + ' %' 
	from (
		select * from total_entire_clinic
		union 
		select * from by_facility
	) q
--	order by year, quarter, ordertypes, facility
go
