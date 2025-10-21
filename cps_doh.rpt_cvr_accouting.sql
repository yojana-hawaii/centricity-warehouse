

USE [CpsWarehouse]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


drop PROCEDURE if exists [cps_doh].[rpt_cvr_accouting]

go
create PROCEDURE [cps_doh].[rpt_cvr_accouting]  
	(
		@StartDate date, 
		@EndDate date,
		@FilterBy varchar(30) = 'LastModified'
	)
AS
BEGIN
--	declare @StartDate DATETIME = '6-1-2019',   @EndDate DateTIme = '6-30-2019', @FilterBy varchar(30) = 'BillingEntered';

with u as (
	select 
		cvr.pid,cvr.PatientId,cvr.PatientProfileId,ISNULL(cvr.PatientVisitID,'') PatientVisitID,ISNULL(pv.TicketNumber,'') TicketNumber,cvr.FPExclusive,
		pp.DoB,
		Race1, Race2, SubRace1, SubRace2,
		convert(date, (CASE WHEN pv.visit IS NOT NULL THEN CONVERT(DATE,pv.Visit) Else cvr.DB_CREATE_DATE END )) DoS,
		CONVERT(DATE,pv.Entered) BillingEntryDate,
		convert(date, agg.LastModified) LastModifiedDate,
		ISNULL(ic.InsuranceName,'') Insurance,cvr.Provider,
		agg.OrigInsAllocation,agg.InsAllocation,agg.InsBalance,agg.InsPayment,agg.InsAdjustment,
		agg.OrigPatAllocation,agg.PatAllocation,agg.PatBalance,agg.PatPayment,agg.PatAdjustment
	from [CpsWarehouse].[cps_doh].rpt_view_FindCVRPatients cvr
		--left join cps_all.PatientVisitType_Join_Document pvd on pvd.SDID = cvr.sdid
		left join [cpssql].[CentricityPS].dbo.PatientVisit pv on pv.PatientVisitId = cvr.PatientVisitID
		left join [cpssql].[CentricityPS].dbo.PatientVisitAgg agg on agg.PatientVisitid = pv.PatientVisitID
		left join [CpsWarehouse].[cps_all].InsuranceCarriers ic on ic.InsuranceCarriersId = pv.PrimaryInsuranceCarriersId
		LEFT JOIN [CpsWarehouse].[cps_all].patientprofile pp on pp.PID = cvr.PID
		left join [CpsWarehouse].[cps_all].[PatientRace] race on pp.pid = race.PID
)
select * from u
where 
	case 
		when @FilterBy = 'LastModified' then LastModifiedDate 
		when @FilterBy = 'DOS' then DOS 
		when @FilterBy = 'BillingEntered' then BillingEntryDate 
	end >= @StartDate 
	AND 
	case 
		when @FilterBy = 'LastModified' then LastModifiedDate 
		when @FilterBy = 'DOS' then DOS 
		when @FilterBy = 'BillingEntered' then BillingEntryDate 
	end <= @EndDate

END
go