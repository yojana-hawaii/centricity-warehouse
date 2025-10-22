
use CpsWarehouse
go

drop proc if exists cps_track.rpt_aapcho_enabling_service;
go
create proc  cps_track.rpt_aapcho_enabling_service
(
	@StartDate date,
	@EndDate date,
	@pvid varchar(max)
)
as
begin

	--declare @StartDate date = '2021-09-01', @EndDate date = '2021-09-25', @pvid varchar(max) = '1616337978000010,1675762865011500'; 
	
	drop table if exists #temp
	select item
	into #temp
	from fxn.SplitStrings(@pvid, ',')

	select 
		pp.PatientID, convert(date, e.OrderDate) OrderDate, pp.Sex, 
		isnull(pr.Race1, '') Race1, isnull(pr.Race2, '') Race2, 
		isnull(pr.Ethnicity1,'') Ethnicity1, isnull(pr.Ethnicity2,'') Ethnicity2, 
		isnull(pp.Language,'') Language, isnull(pp.Zip,'') Zip, e.OrderProvider, e.OrderProviderID
	from cps_orders.rpt_view_EnablingCodes e
		inner join #temp t on t.Item = e.OrderProviderID
		left join cps_all.PatientProfile pp on pp.pid = e.PID
		left join cps_all.PatientRace pr on pr.pid = pp.PID

	where e.OrderDate >= @StartDate
		and e.OrderDate <= @EndDate

end
go
