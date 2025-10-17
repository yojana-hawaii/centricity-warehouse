

use CpsWarehouse
go

drop proc if exists cps_all.rpt_facility
go

create proc cps_all.rpt_facility
as 
begin

select Facility, convert(varchar(5), FacilityID) FacilityID, FacilityAddress
from cps_all.Location
where FacilityInactive = 0
and MainFacility = 1
union
select 'All', 'All', 'All'

end

go
