
use CpsWarehouse
go
drop proc if exists cps_all.rpt_active_facility
go

create proc cps_all.rpt_active_facility
as begin

select FacilityID, Facility 
from cps_all.Location loc
where MainFacility = 1
	and FacilityInactive = 0
	and LocInactive = 0

end

go