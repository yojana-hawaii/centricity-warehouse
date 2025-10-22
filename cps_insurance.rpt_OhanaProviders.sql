

use CpsWarehouse
go
drop proc if exists cps_insurance.rpt_OhanaProviders
go
create proc cps_insurance.rpt_OhanaProviders
as 
begin


	select df.ListName Prov, df.NPI, n.OhanaSpecialty, n.NPIEnumerationDate, n.State

	from cps_all.DoctorFacility df
		left join cps_insurance.NPIDetails n on df.DoctorFacilityID = n.DoctorFacilityID
	where Inactive = 0 and df.Billable = 1 and df.npi is not null and df.Specialty not in ('Behavioral Health');


end

go



