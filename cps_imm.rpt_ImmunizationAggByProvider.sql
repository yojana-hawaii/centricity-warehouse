
use CpsWarehouse
go

drop proc if exists cps_imm.rpt_ImmunizationAggByProvider;
go
create proc cps_imm.rpt_ImmunizationAggByProvider

(
	@Year int = 2021,
	@month varchar(3) = 'all'
)
as
begin

declare @adminDate date = '2018-01-01';

declare @monthNum int = case when @month ='0' then null else convert(int, @month) end

select  VaccineGroup, Brand, NDC, LotNumber, ExpirationDate, i.Providers ,AdministeredDate, d.Quarter, d.Month, d.MonthName, d.WeekName, d.DayOfWeek, d.Year
from cps_imm.ImmunizationGiven i
	inner join  dbo.dimDate d on d.date = i.AdministeredDate
	--left join cps_all.DoctorFacility df on df.ListName = i.Providers and df.Billable = 1 and i.Providers != ''
	--inner join cps_all.PatientProfile pp on pp.pid = i.pid and pp.TestPatient = 0 /*Test Patient already removed from immunizationGiven table*/
where AdministeredDate >= @adminDate
	and wasGiven = 'Y'
	and Historical = 'N'
	and year = isnull(@year, year)
	and d.Month = isnull(@monthNum, d.Month)


end


go



