

use CpsWarehouse
go

drop view if exists [cps_orders].[rpt_view_EnablingCodes]
go
CREATE view [cps_orders].[rpt_view_EnablingCodes]
as

select 
	o.OrderLinkID, o.PID, o.PatientId, o.Name, o.SDID, 
	o.OrderCodeID, o.OrderDesc, o.OrderCode,
	o.OrderProvider, o.OrderProviderID,
	o.OrderDate, o.Units,
	o.LocID, o.LoC, o.Facility
	

from CpsWarehouse.[cps_orders].Fact_all_orders o
	inner join CpsWarehouse.[cps_orders].OrderCodesAndCategories cat 
				on cat.OrderCodeID = o.orderCodeID
					and cat.CategoryName in ('Enabling Services HCHP','Enabling Services/HE/CHW')
where  o.Canceled = 0
	and o.OrderType = 'S'



GO
