
use CpsWarehouse
go

drop view if exists cps_meds.view_ActivePharmacy
go

create view cps_meds.view_ActivePharmacy
as

	select *
	from cpssql.centricityps.dbo.Pharmacy
	where inactive = 0

go