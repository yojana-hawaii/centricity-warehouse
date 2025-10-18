use CpsWarehouse
go

drop table if exists [cps_cc].[Covid_SupplyTracker]
go
create table [cps_cc].[Covid_SupplyTracker](
	PID numeric(19,0) not null,
	SDID numeric(19,0) not null,
	[Source] varchar(10) not null,
	ProductName varchar(max) not null,
	Manufacturer varchar(50) null,
	LotNumber varchar(50) null,
	ExpirationDate date null,
	Quantity varchar(20) null,
	StartDate_DispensedDate date null
);
go
drop proc if exists cps_cc.ssis_covid_supplyTracker;
go
create proc cps_cc.ssis_covid_supplyTracker
as
begin

truncate table cps_cc.Covid_SupplyTracker;


with u as (
	select 
		pp.pid, req.SDID SDID,
		case 
		when charindex(':', req.MedDisplayName) > 0 
			then substring(req.MedDisplayName, 1, charindex(':', req.MedDisplayName)-1 )
		else 'N/A' end [Source],
		req.ProductName ProductName, 
		med.Manufacturer Manufacturer, med.LotNumber LotNumber, 
		med.AdminDose + ' ' + med.AdminUnits Quantity,
		convert(date, med.ExpirationDate) ExpirationDate, 
		convert(date, med.StartDateTime) StartDate_DispensedDate
	from cpssql.CentricityPS.dbo.MedAdminRequest req
		left join cpssql.CentricityPS.dbo.MedAdministration med on med.MedAdminRequestID = req.MedAdminRequestID
		left join cps_all.PatientProfile pp on pp.pid = req.PID
	where req.CustomListName = 'KPHC Diagnostics'
		and req.FiledInError = 'N'
		and med.Inactive = 'N'
)
	insert into cps_cc.Covid_SupplyTracker(PID, SDID, Source, ProductName, Manufacturer, LotNumber, ExpirationDate, StartDate_DispensedDate, Quantity )
	select PID, SDID, Source, ProductName, Manufacturer, LotNumber, ExpirationDate, StartDate_DispensedDate, Quantity
	from u
end

go
