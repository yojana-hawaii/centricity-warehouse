
use [CpsWarehouse]
go
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
drop table if exists [CpsWarehouse].[cps_den].[Den_CPS_PatientMatching_Algorithm];
create table [CpsWarehouse].[cps_den].[Den_CPS_PatientMatching_Algorithm](
	Chart varchar(20) not null,
	PID numeric(19,0) not null,
	PatientID varchar(20)  not null,
	MatchPercent float not null,
	primary key (Chart, PID)
)

GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

drop PROCEDURE if exists [cps_den].[ssis_Den_CPS_PatientMatching_Algorithm] 

go
create procedure [cps_den].[ssis_Den_CPS_PatientMatching_Algorithm]
as begin

truncate table [cps_den].[Den_CPS_PatientMatching_Algorithm];
	
	drop table if exists #cps;
	select 
		pp.pid PID, isnull(cpp.SSN,'') SSN, 
		fxn.RemoveNonAlphaNumericCharacters(pp.Last) cpsLastName, 
		left(fxn.RemoveNonAlphaNumericCharacters(isnull(cpp.middle,'')),1) middle,
		fxn.RemoveNonAlphaNumericCharacters(pp.First) cpsFirstName, 
		pp.sex cpsGender, convert(date,pp.DoB) cpsDoB, 
		left(isnull(pp.zip,''),5) cpsZip, 
		fxn.RemoveNonAlphaNumericCharacters(isnull(cpp.address1,'')) cpsStreet
	into #cps
	from cpssql.centricityps.dbo.patientProfile cpp
		left join CpsWarehouse.cps_all.PatientProfile pp on cpp.pid = pp.pid
	where pp.PatientActive = 1 and pp.TestPatient = 0;

	drop table if exists #den;
	select 
		dpp.PatID PatId, dpp.Chart Chart, isnull(denPP.SS,'') SS, 
		fxn.RemoveNonAlphaNumericCharacters(dpp.lastname) denLastName,
		dpp.MiddleName,
		fxn.RemoveNonAlphaNumericCharacters(dpp.firstName) denFirstName, 
		left(dpp.Gender,1) Gender, 
		dpp.DoB DoB, left(dpp.Zip,5) Zip, 
		fxn.RemoveNonAlphaNumericCharacters(dpp.Street) Street
	into #den
	from  cps_den.DentalPatientProfile dpp 
		left join den_sql.Dentrix.dbo.DDB_PAT_BASE denPP on denPP.patID = dpp.PatID
	where dpp.Lastname not like 'ZZ%';


with matchedBySSN as (
		select cps.*, den.*,
			case 
				when cps.cpsLastName = den.denLastName 
						and cps.cpsFirstName = den.denFirstName 
						and cps.cpsDoB = den.DoB 
				then 1.0 
				when left(cps.cpsLastName,3) = left(den.denLastName,3) 
						and left(cps.cpsFirstName,3) = left(den.denFirstName,3) 
						and cps.cpsDoB = den.DoB
						and cps.cpsGender = den.Gender
						and cps.cpsZip = den.Zip 
				then 0.99
				when (cps.cpsLastName = den.denLastName or cps.cpsFirstName = den.denFirstName) 
						and cps.cpsDoB = den.DoB
						and cps.cpsGender = den.Gender
						and cps.cpsZip = den.Zip 
				then 0.98
				when cps.cpsLastName = den.denLastName 
						and cps.cpsFirstName = den.denFirstName 
						and den.Zip = cps.cpsZip 
						and cps.cpsGender = den.Gender
						and cps.cpsStreet = den.Street 
				then 0.97
				when cps.cpsLastName = den.denLastName 
						and cps.cpsFirstName = den.denFirstName 
						and den.Zip = cps.cpsZip 
						and cps.cpsGender = den.Gender
				then 0.96
				when (cps.cpsLastName = den.denLastName or cps.cpsFirstName = den.denFirstName) 
						and cps.cpsDoB = den.DoB
						and cps.cpsGender = den.Gender
				then 0.95
				when (cps.cpsLastName = den.denLastName or cps.cpsFirstName = den.denFirstName) 
						and cps.cpsDoB = den.DoB
				then 0.94
				when cps.cpsDoB = den.DoB
				then 0.93
			else 0.6 end MatchData
		from  #cps cps
			inner join  #den den on cps.SSN = den.SS and cps.SSN != '' and den.SS != ''
	)
	, match_level2 as (
		select * ,
			case 
				when cps1.cpsFirstName = den1.denFirstName and cps1.cpsLastName = den1.denLastName and cps1.cpsZip = den1.Zip and cps1.cpsGender = den1.Gender then 0.92
				when cps1.cpsFirstName = den1.denFirstName and cps1.cpsLastName = den1.denLastName and cps1.cpsGender = den1.Gender then 0.91
				when left(cps1.cpsLastName,3) = left(den1.denLastName,3) and left(cps1.cpsFirstName,3) = left(den1.denFirstName,3) and cps1.cpsZip = den1.Zip and cps1.cpsGender = den1.Gender then 0.90
				when (cps1.cpsLastName = den1.denLastName or cps1.cpsFirstName = den1.denFirstName) and cps1.cpsZip = den1.Zip and cps1.cpsGender = den1.Gender then 0.53
				when left(cps1.cpsLastName,3) = left(den1.denLastName,3) and left(cps1.cpsFirstName,3) = left(den1.denFirstName,3) and cps1.cpsGender = den1.Gender then 0.52

			else 0.0 end MatchData
		from
			(
				select * from #cps where pid not in (select PID from matchedBySSN where MatchData > 0.5 )
			) cps1
			inner join
				(
					select * from #den where PatID not in (select PatID from matchedBySSN)
				) den1
			on cps1.cpsDoB = den1.DoB
	)
	,combined as (
		select * 
		from match_level2
		where MatchData >= 0.5
	
		union

		select *
		from matchedBySSN
	) 
	,match_by_name_zip as (
		select *,
			case when cps2.cpsZip = den2.Zip and cps2.cpsGender = den2.Gender then 0.51
			else 0.0
			end MatchData
		from
			(
				select * from #cps where pid not in (select PID from combined )
			) cps2
			inner join
				(
					select * from #den where PatID not in (select PatID from combined)
				) den2
			on left(cps2.cpsLastName,5) = left(den2.denLastName,5) and left(cps2.cpsFirstName,5) = left(den2.denFirstName,5)
	)
	,combined2 as (
		select PID, Chart, MatchData from match_by_name_zip 
		where MatchData > 0.5
	
		union

		select  PID, Chart, MatchData from combined
	)

, u as (
	select * from 
	(
		select PID, NULL Chart, null as MatchData from #cps where pid not in (select PID from combined2)	
	
		union 

		select NULL PID, Chart, null as MatchData from #den where PatID not in (select PatID from combined2)

		union 
	
		select * from combined2
	) x
	where matchdata is not null
)

insert into [cps_den].[Den_CPS_PatientMatching_Algorithm] (Chart, [PID], [MatchPercent], PatientID)
select u.Chart, u.[PID], u.[MatchData], pp.PatientID
from u
left join cps_all.PatientProfile pp on pp.pid = u.pid ;

end
go
	
