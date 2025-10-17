

USE [CpsWarehouse]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/*
Asthma
BCCCP
BH
BHCC
CKD
Dental
DiabClinic
DiabEd
Dietician
DRE
Eligibility
Glucometer
HCHP
HodgePodge
IM
Memory
Nutrition
OB/GYN
OPT
Patient Assistance
Peds
Psych
Psycho
SS
SubstanceAbuse
Surgeon
Tobacco
Uro-Gyn
WH
WIC

*/
 
drop proc if exists cps_orders.rpt_internal_referral_tracking;
go
create procedure [cps_orders].[rpt_internal_referral_tracking]
	(
		@StartDate date,
		@EndDate date,
		@InternalReferral nvarchar(max)
	)
as
begin

--declare @days int = 30;
--declare @StartDate date = DATEADD(day, -@Days,GETDATE() ), 
--	@EndDate date = GETDATE(),
--	@InternalReferral nvarchar(20) = 'All'--'BH, PSYCH';


drop table if exists #referralList;
create table #referralList (
	InternalReferral varchar(50)
)

--different query depending on paramter
if (@InternalReferral = 'All')
begin 
	insert into #referralList 
	select distinct DefaultClassification
	from cps_orders.rpt_view_InternalReferral_Appt i
	where i.OrderDate >= @StartDate
		and i.OrderDate <= @EndDate
end else  begin
	insert into #referralList 
	select Item
	from fxn.SplitStrings(@InternalReferral, ',')
end

--select * from #referralList


select 
	i.Name, i.PatientID, i.DoB, i.Phone1, 
	i.OrderDesc, i.OrderDate, i.ClinicalComment, 
	i.ReferralStatus,
	ic.InsuranceName,
	i.OrderProvider, i.Facility, i.ApptType, i.Specialist, i.ApptDate, i.StartTime, i.ApptStatus, i.DefaultClassification
	,year,month,MonthName
from cps_orders.rpt_view_InternalReferral_Appt i
	left join cps_all.PatientInsurance pin on pin.pid = i.pid
	left join cps_all.InsuranceCarriers ic on ic.InsuranceCarriersID = pin.PrimCarrierID
	inner join #referralList r on i.DefaultClassification = r.InternalReferral
where i.OrderDate >= @StartDate
	and i.OrderDate <= @EndDate

end

go
