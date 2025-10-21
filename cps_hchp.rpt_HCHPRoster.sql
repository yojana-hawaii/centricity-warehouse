
use CpsWarehouse
go

drop proc if exists cps_hchp.rpt_HCHPRoster;
go
create proc cps_hchp.rpt_HCHPRoster
as
begin
	select * 
	from cps_hchp.tmp_view_HCHPClients

end

go
