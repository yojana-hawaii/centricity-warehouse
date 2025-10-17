

USE CpsWarehouse
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

drop proc if exists cps_visits.rpt_random_Visit_per_provider
go
create procedure cps_visits.rpt_random_Visit_per_provider
	(
		@StartDate date, 
		@EndDate date,
		@TotalVisits nvarchar(4) = '100',
		@doctorfacilityid nvarchar(100)
	)
as begin


	--declare 
	--	@StartDate date = '2018-08-05', 
	--	@EndDate date = '2019-10-09',
	--	@TotalVisits nvarchar(4) = '10',
	--	@doctorfacilityid nvarchar(100) = '56' ;

	drop table if exists #providers;
	select convert(int,Item) Item
	into #providers
	from dbo.fnSplitStrings(@doctorfacilityid, ',');
	

	declare
		@TotalVisit int = case when try_convert(int, @totalVisits) is null then 100 else try_convert(int, @TotalVisits) end;

	select   
		top (@TotalVisit)
		df.ListName, 
		pp.PatientID, pv.TicketNumber, pv.DoS, loc.Facility, ICD10, CPTCode
	from cps_visits.PatientVisitType pv
		inner join #providers p on p.Item = pv.Resource1
		left join cps_all.DoctorFacility df on df.DoctorFacilityID = p.Item
		inner join cps_all.PatientProfile pp on pp.pid = pv.PID
		inner join cps_all.Location loc on loc.FacilityID = pv.FacilityID and loc.MainFacility = 1
	where pv.DoS >= @StartDate 
		and pv.DoS <= @EndDate
		and (MedicalVisit  = 1 or BHVisit = 1 or OptVisit = 1)
	order by newid()




END 
go
