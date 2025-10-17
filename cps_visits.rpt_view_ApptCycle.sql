
use CpsWarehouse
go
drop view if exists cps_visits.rpt_view_ApptCycle
go
create view cps_visits.rpt_view_ApptCycle
as

	select 
		top 1000 a.Facility, a.ListName, a.EndTime, a.ApptStatus, a.ApptType, a.InternalReferral, c.*
	from cps_visits.ApptCycleType c
		left join cps_visits.Appointments a on c.AppointmentsID = a.AppointmentsID
	where ApptStatus not in  ('Provider Cancelled Appt','Deceased','Data Entry Error','Cancel/Facility Error')
		and ApptDate >= '2022-01-01'
		and CancellationReason is null
		and c.Canceled =1
	
go