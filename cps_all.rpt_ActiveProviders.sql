

use CpsWarehouse
go


drop proc if exists cps_all.rpt_ActiveProviders
go

create proc cps_all.rpt_ActiveProviders
as
begin

select * from cps_all.rpt_view_ActiveProviders

end

go
