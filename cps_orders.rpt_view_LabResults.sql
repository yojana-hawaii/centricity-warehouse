USE [CpsWarehouse]
GO


SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

drop view if exists [cps_orders].[rpt_view_LabResults]
go
create view [cps_orders].[rpt_view_LabResults]
as

select  
	f.PatientID, f.pid, f.Name, 
	f.OrderCodeID,f.OrderDesc, f.OrderCode, 
	f.OrderProvider, 
	f.FacilityID,f.Facility, 
	f.VisitDate, f.OrderDate, f.endDate, f.ReportReceivedDate, f.ReportSource,
	f.CompletedDate, f.CurrentStatus, f.OrderClassification,f.ResultSDIDList1, f.ResultSDIDList2
from cps_orders.Fact_all_orders f
where 
	f.OrderClassification in ('CLH','DLS','DOH','HPL')
	--f.Canceled != 1

GO
