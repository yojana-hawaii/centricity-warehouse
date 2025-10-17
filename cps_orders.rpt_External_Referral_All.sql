
go
use CpsWarehouse
go

drop proc if exists cps_orders.rpt_External_Referral_All;
go

create proc cps_orders.rpt_External_Referral_All
(
	@year int 
)
as
begin
select 
	OrderDesc Referral, Facility, Name, PatientId, OrderDate, CurrentStatus, OrderProvider, SpecialistInForm, 
	ReferralSpecialist, ReferralDate, FollowupSpecialist, FollowupReport, InsuranceName
from cps_orders.rpt_view_ExternalReferral e
	left join dbo.dimDate d on e.OrderDate = d.Date
where d.Year = @year

end
go
