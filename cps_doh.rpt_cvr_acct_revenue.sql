
use CpsWarehouse
go
set ansi_nulls on
go
set quoted_identifier on
go

drop proc if exists [cps_doh].[rpt_cvr_acct_revenue];
go

create proc [cps_doh].[rpt_cvr_acct_revenue]
(
	@StartDate date,
	@EndDate date
)
as 
begin


--	declare @StartDate DATETIME = '3-1-2018',   @EndDate DateTIme = '3-31-2019', @FilterBy varchar(30) = 'LastModified';

select 
	cvr.pid,cvr.PatientProfileId,ISNULL(cvr.PatientVisitID,'') PatientVisitID,
	
	cvr.PatientId,
	ISNULL(pv.TicketNumber,'') TicketNumber,
	convert(date, (CASE WHEN pv.visit IS NOT NULL THEN CONVERT(DATE,pv.Visit) Else cvr.DB_CREATE_DATE END )) DoS,
	convert(date, vt.LastModified) PaymentDate,
	ISNULL(ic.InsuranceName,'') Insurance, ic.Classify_DoH_CVR,
	cvr.Provider, vt.Payments, 
	case 
		when vt.insuranceCarriersId is null and vt.payments is null then null 
		when vt.insuranceCarriersId is null then 'Patient' 
		else 'Insurance' end PaymentSource
from [CpsWarehouse].[cps_doh].rpt_view_FindCVRPatients cvr
	--left join cps_all.PatientVisitType_Join_Document pvd on pvd.SDID = cvr.sdid
	left join [cpssql].[CentricityPS].dbo.PatientVisit pv on pv.PatientVisitId = cvr.PatientVisitID
	left join [CpsWarehouse].[cps_all].InsuranceCarriers ic on ic.InsuranceCarriersId = pv.PrimaryInsuranceCarriersId
	LEFT JOIN [CpsWarehouse].[cps_all].patientprofile pp on pp.PID = cvr.PID
	left join [cpssql].[CentricityPS].dbo.VisitTransactions vt on pv.PatientVisitId = vt.PatientVisitID and vt.payments != 0.00
where cvr.FPExclusive = 1
	and convert(date, vt.created) >= @StartDate 
	and convert(date, vt.created) <= @EndDate



end

go

