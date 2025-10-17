
use CpsWarehouse
go

drop view if exists cps_all.rpt_view_ActiveProviders
go
create view cps_all.rpt_view_ActiveProviders
as
	select df.DoctorFacilityID, df.ListName, df.PVID, df.JobTitle
	from cps_all.DoctorFacility df 
	where df.Inactive = 0 and df.Billable = 1 
		and df.HasSchedule = 1 and df.ChartAccess = 1 
		and df.SignDocs = 1
		and df. JobTitle not in ('Proxy users', 'Information Systems');

go
