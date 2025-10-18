


use CpsWarehouse
go

drop proc if exists cps_imm.rpt_ImmunizationAggregate;
go
create proc cps_imm.rpt_ImmunizationAggregate

(
	@Year int = 2021,
	@Facility varchar(20) = 'downtown',
	@month varchar(3) = 'all'
)
as
begin

declare @adminDate date = '2018-01-01';

set @facility = case when @facility = 'All' then NULL else @Facility end
declare @monthNum int = case when @month ='0' then null else convert(int, @month) end

select  VaccineGroup, Brand, NDC, LotNumber, ExpirationDate, i.Facility,AdministeredDate, d.Quarter, d.Month, d.MonthName, d.WeekName, d.DayOfWeek, d.Year
from cps_imm.ImmunizationGiven i
	inner join  dbo.dimDate d on d.date = i.AdministeredDate
	--inner join cps_all.PatientProfile pp on pp.pid = i.pid and pp.TestPatient = 0 /*Test Patient already removed from immunizationGiven table*/
where AdministeredDate >= @adminDate
	and wasGiven = 'Y'
	and Historical = 'N'
	and year = isnull(@year, year)
	and i.Facility = isnull(@Facility, i.Facility)
	and d.Month = isnull(@monthNum, d.Month)


end


go




