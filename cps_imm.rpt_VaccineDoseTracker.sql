
use CpsWarehouse
go

drop proc if exists cps_imm.rpt_VaccineDoseTracker;
go

create proc cps_imm.rpt_VaccineDoseTracker
(
	@VaccineGroup nvarchar(30)
)
as 
begin

	--declare @VaccineGroup varchar(30) = 'meningB';
	declare @5year date = convert(date, dateadd(year, -5, getdate()));
	--select @5year

	select  pp.Name, pp.sex,pp.Language,i.* 
	from cps_imm.view_fullyVaccinatedStatus i
		left join cps_all.PatientProfile pp on pp.pid = i.PID
	where series1date > @5year  and VaccineGroup = @VaccineGroup

end
