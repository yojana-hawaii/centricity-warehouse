
use CpsWarehouse
go

drop view if exists cps_all.view_DoctorFacility_Active_30days;
go

create view cps_all.view_DoctorFacility_Active_30days
as

	select 
		df.DoctorFacilityID,df.PVID,
		df.LastLogIn, df.AccountCreated,
		df.Billable, df.CentricityUser, df.HasSchedule, df.ChartAccess, df.SignDocs,
		df.UserName, df.ListName, df.FirstName, df.LastName, df.Suffix,
		df.JobTitle, df.Specialty, df.PreferenceGroup, df.Role,
		df.HomeLocation, df.CurrentLocation LastLocation,
		df.NPI, df.SPI, df.DEA, 
		df.Address1, df.Notes
	from CpsWarehouse.cps_all.DoctorFacility df
	where df.PVID > 0
		and df.Inactive = 0
		and df.DoctorFacilityID <> df.PVID
		and df.CentricityUser = 1
		and 
			(
				df.JobTitle not in ('Auditors', 'Student','Proxy users', 'Vendor')
				or
				df.JobTitle is null
			)
		and 
			(
				df.Address1 not in ('Proxy User')
				or
				df.Address1 is null
			)
		and datediff(day,df.LastLogIn, getdate() ) < 30

go
