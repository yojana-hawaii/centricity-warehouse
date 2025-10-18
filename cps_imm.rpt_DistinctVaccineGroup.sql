
use CpsWarehouse
go

drop proc if exists cps_imm.rpt_DistinctVaccineGroup
go

create proc cps_imm.rpt_DistinctVaccineGroup
as
begin
	select distinct VaccineGroup
	from cps_imm.view_fullyVaccinatedStatus
end
go
