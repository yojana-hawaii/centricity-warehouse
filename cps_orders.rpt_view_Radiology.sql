USE CpsWarehouse
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

	drop view if exists [cps_orders].[rpt_view_Radiology];
	go
	create view [cps_orders].[rpt_view_Radiology]
	as

	--select top 10 * from cps_orders.Fact_all_orders f
	
	select  
		f.OrderLinkID, f.PID, f.PatientID, 
		f.Name,
		--case 
		--	when AgeDecimal < 10 then '0 - 10'
		--	when AgeDecimal >= 10 and AgeDecimal < 20 then '10 - 20'
		--	when AgeDecimal >= 20 and AgeDecimal < 30 then '20 - 30'
		--	when AgeDecimal >= 30 and AgeDecimal < 40 then '30 - 40'
		--	when AgeDecimal >= 40 and AgeDecimal < 50 then '40 - 50'
		--	when AgeDecimal >= 50 and AgeDecimal < 60 then '50 - 60'
		--	when AgeDecimal >= 60 and AgeDecimal < 70 then '60 - 70'
		--	when AgeDecimal >= 70 and AgeDecimal < 80 then '70 - 80'
		--	when AgeDecimal >= 80 and AgeDecimal < 90 then '80 - 90'
		--else 'Over 90'
		--end AgeRange,
		--pp.Sex, 
		f.SDID, 
		f.OrderCodeID,f.OrderCode, f.OrderDesc,
		case 
			when f.OrderDesc like '%mammo%' then 'Mammogram'
			when f.OrderDesc like '%xray%' or f.OrderDesc like '%x-ray%' then 'Xray' 
			when f.OrderDesc like '%mri%' then 'MRI' 
			when f.OrderDesc like '%dexa%' then 'Dexa' 
			when f.OrderDesc like 'CT%' or f.OrderDesc like 'HDRS - CT%' then 'CT Scan'
			when f.OrderDesc like 'US%' or f.OrderDesc like 'HDRS - US%' then 'Ultrasound'
			else 'Other'
		end RadType,
		f.OrderType, f.EndDate, 
		f.OrderProviderID, f.OrderProvider,
		f.Facility , f.FacilityID ,
		f.ServProvID, sp.LastName, sp.FirstName, sp.Organization, isnull(sp.Org_Short,'Other') Org_Short,
		f.VisitDate, f.OrderDate, 
		case when f.VisitDate < f.OrderDate then 1 when f.VisitDate > f.OrderDate then 2 else 0 end FutureOrder,
		f.InProcessDate, 
		f.ReportReceivedDate, 
		f.CompletedDate,f.OrderClassification,

		datediff(day, f.OrderDate,  f.CompletedDate) DaysAfterOrderCompleted,

		case when f.CompletedDate is null then 0 else 1 end OrderCompleted,
		case when f.CompletedDate is null and f.InProcessDate is not null then 1 else 0 end OrderSentButNotCompleted,
		case when f.CompletedDate is null and f.InProcessDate is null then 1 else 0 end OrderNotSent,
		case when f.CompletedDate is null and f.ReportReceivedDate is not null then 1 else 0 end ReportReceivedButNotCompleted,

		f.CurrentStatus, f.ResultSDIDList1, f.ResultSDIDList2
	from cps_orders.Fact_all_orders f
		--left join [CpsWarehouse].[cps_all].[PatientProfile] pp on pp.pid = f.PID
		left join [CpsWarehouse].[cps_orders].[OrderSpecialist] sp on sp.ServProvID = f.ServProvID and f.ServProvID != 0
	where  f.OrderClassification IN ('RAD', 'HDRS') 
		and f.Canceled = 0


GO
