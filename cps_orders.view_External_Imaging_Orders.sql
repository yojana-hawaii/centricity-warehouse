



use CpsWarehouse
go

drop view if exists [cps_orders].[view_External_Imaging_Orders]
go
CREATE view [cps_orders].[view_External_Imaging_Orders]
as

select 
	o.ServProvID, 
	sp.Org_Short, sp.Organization,
	o.OrderLinkID, o.PID, o.PatientId, o.Name, 
	o.SDID, 
	o.OrderCodeID, o.OrderDesc, o.OrderCode, o.OrderType,
	o.CurrentStatus,
	o.OrderProvider, o.OrderProviderID,
	o.VisitDate, o.OrderDate, 
	o.CompletedDate, o.CompleteBy,
	o.Canceled, o.CancelDate, o.CancelBy, o.CancelReason,
	o.DocumentAssociated, o.ReportReceivedDate,
	o.LocID, o.LoC, o.Facility, cat.DefaultClassification,
	datediff(day, o.OrderDate,  o.CompletedDate) DaysAfterOrderCompleted,
	case when o.CompletedDate is null then 0 else 1 end OrderCompleted,
	case when o.CompletedDate is null and o.InProcessDate is not null then 1 else 0 end OrderSentButNotCompleted,
	case when o.CompletedDate is null and o.InProcessDate is null then 1 else 0 end OrderNotSent,
	case when o.CompletedDate is null and o.ReportReceivedDate is not null then 1 else 0 end ReportReceivedButNotCompleted


from [CpsWarehouse].[cps_orders].Fact_all_orders o
	left join CpsWarehouse.cps_orders.OrderCodesAndCategories cat on cat.OrderCodeID = o.OrderCodeID
	left join CpsWarehouse.[cps_orders].[OrderSpecialist] sp on sp.ServProvID = o.ServProvID and o.ServProvID != 0
where   cat.OrderClassification in ('RAD', 'HDR')


GO


