

use CpsWarehouse
go
drop view if exists cps_insurance.tmp_view_OhanaProviders
go
create view cps_insurance.tmp_view_OhanaProviders
as 



	select 
		df.FirstName Provider_FName, 
		df.LastName Provider_LName, 
		df.ListName, 
		case when df.NPI is null then n.NPI else df.NPI end Provider_NPI, 
		n.OhanaSpecialty, n.NPIEnumerationDate, n.State, df.PVID, df.DoctorFacilityID

	from cps_insurance.NPIDetails n
		left join cps_all.DoctorFacility df  on df.DoctorFacilityID = n.DoctorFacilityID
--	where Inactive = 0 and df.Billable = 1 and df.npi is not null and df.Specialty not in ('Behavioral Health');



go

