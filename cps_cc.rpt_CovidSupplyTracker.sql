
use CpsWarehouse
go

drop proc if exists cps_cc.rpt_CovidSupplyTracker;
go

create proc cps_cc.rpt_CovidSupplyTracker
as 
begin

	select 
		pp.Name, pp.DoB, 
		race.Race1, race.race2, race.Ethnicity1, race.Ethnicity2, race.SubRace1, race.SubRace2,
		pp.LimitedEnglish, 
		case when pp.IsHomeless = 1 then 'yes' else 'no' end IsHomeless,
		case when pp.IsPublicHousing = 1 then 'yes' else 'no' end IsPublicHousing,
		isnull(pp.AgriculturalMigration, 'N/A') AgriculturalMigration,cov.Quantity,
		cov.Source, cov.ProductName, cov.Manufacturer, cov.LotNumber, cov.ExpirationDate, cov.StartDate_DispensedDate
	from cps_cc.Covid_SupplyTracker cov
		left join cps_all.PatientProfile pp on pp.PID = cov.PID
		left join cps_all.PatientRace race on race.pid = cov.PID
	where pp.TestPatient = 0


end
go
