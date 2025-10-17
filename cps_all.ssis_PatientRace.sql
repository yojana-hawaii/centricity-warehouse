
use CpsWarehouse
go

drop table if exists cps_all.[PatientRace];
go
CREATE TABLE [cps_all].[PatientRace] (
    [PID]      NUMERIC (19) NOT NULL,
	[PatientId] int not null,
	[PatientProfileId] int not null,
    [Race1]    VARCHAR (50) NULL,
    [Race2]    VARCHAR (50) NULL,
    [SubRace1] VARCHAR (50) NULL,
    [SubRace2] VARCHAR (50) NULL,
	[Ethnicity1] VARCHAR (50) NULL,
    [Ethnicity2] VARCHAR (50) NULL,
    CONSTRAINT [PK_dimPatientRacePID] PRIMARY KEY CLUSTERED ([PID] ASC),
);


go

drop procedure if exists [cps_all].[ssis_PatientRace];
go
create procedure [cps_all].[ssis_PatientRace]
AS
BEGIN

truncate table cps_all.[PatientRace];

/*get all patient from patientprofile table*/
WITH temp0 AS(
	SELECT pp.patientid PatientId,pp.pid PID, pp.PatientProfileId PatientProfileId
	FROM [cpssql].[CentricityPS].dbo.PatientProfile pp
),temp1 AS(
	/*match all patient with race from patientrace table 
		- few have more than one race and more than one subrace
		- rowcount for patient with multiple race */
	SELECT  
		pp.patientid,pp.patientprofileid,pp.pid,
		case when race.Description = 'Unspecified' then null else race.Description end Race,
		--case when subrace.Description in ('Other','More than one race') then null else subrace.Description end Subrace,
		subrace.Description Subrace,
		RaceCount = ROW_NUMBER() OVER (PARTITION BY pp.PID order by  pr.LastModified desc)
	FROM temp0 pp
		LEFT JOIN [cpssql].[CentricityPS].dbo.PatientRace pr on pr.PID = pp.PID
		LEFT JOIN [cpssql].[CentricityPS].dbo.MedLists race on (race.MedListsId = pr.PatientRaceMid and race.tablename = 'Race')
		LEFT JOIN [cpssql].[CentricityPS].dbo.MedLists subrace on (subrace.MedListsId =  pr.PatientRaceSubCategoryMid and subrace.tablename = 'RaceSubcategory')
		
)
--select * from temp1
, temp2 AS (
	/*partition by race and subrace*/
	SELECT 
		pp.PatientId,pp.PatientProfileId, pp.PID,
		rtrim(ltrim(r1.Race)) Race1, rtrim(ltrim(r2.Race)) Race2, 
		rtrim(ltrim(r1.Subrace)) Subrace1, rtrim(ltrim(r2.Subrace)) Subrace2
	FROM temp0 pp
		LEFT JOIN temp1 r1 ON (r1.PID = pp.PID AND r1.RaceCount =1)
		LEFT JOIN temp1 r2 ON (r2.PID = pp.PID AND r2.RaceCount =2)
)
, fix_race1 AS (
	select 
		PatientId, PatientProfileId, PID, 
		case 
			when Race1 is null then Race2 
			when Race1 = 'Unspecified' and Race2 is not null then Race2
			When Race1 in ('State Prohibited', 'Patient Declined') 
					and Race2 is not null 
					and Race2 not in ( 'State Prohibited', 'Patient Declined','Unspecified')
				then Race2
			else Race1 end R1,
	
		race1,race2
	from temp2
)
,fix_race2 as (
	select 
		PatientId, PatientProfileId, PID,
		 r1 Race1,
		case 
			when race2 in ( 'State Prohibited', 'Patient Declined','Unspecified') 
					and r1 in ('American Indian or Alaska Native', 'Asian','Black or African American','Native Hawaiian or Other Pacific Islander','White') then null
			when race2 in ('Unspecified') 
					and r1 in ('State Prohibited', 'Patient Declined') then null
			when isnull(r1, '') = isnull(race2,'') then null 
			else Race2
		end Race2
	from fix_race1
)
, fix_subrace1 AS (
	select 
		s.PatientId, s.PatientProfileId, s.PID, 
		case 
			when Subrace2 is null  then Subrace1
			when Subrace2 = Subrace1  then Subrace1
			when Subrace1 is null then Subrace2
			when Subrace2 != Subrace1 then Subrace1
			else 'x'
			end SR1,
	
		Subrace1,Subrace2
	from temp2 s

)
, fix_subrace2 as (
	select 
		PatientId, PatientProfileId, PID,
		SR1 Subrace1, 
		case 
			when Subrace2 is null and Subrace1 is null  then NULL
			when Subrace2 is null  then NULL
			when isnull(subrace1,'') = isnull(subrace2,'') then NULL
			when Subrace1 is null   then NULL
			when Subrace1 != Subrace2 then Subrace2
			else 'x'
		end Subrace2
	from fix_subrace1
)
, u as (
	select 
		r.pid, r.PatientId, r.PatientProfileId, 
		s.Subrace1, s.Subrace2, r.Race1, r.Race2,
		eth.Ethnicity1, eth.Ethnicity2
	from fix_subrace2 s
		left join fix_race2 r on r.pid = s.PID
		left join CpsWarehouse.cps_all.tmp_view_PatientEthnicity eth on eth.PID = s.PID
)

INSERT into cps_all.PatientRace(PID,PatientId,PatientProfileId,Race1,Race2,SubRace1,SubRace2,Ethnicity1, Ethnicity2)
select PID,PatientId,PatientProfileId,Race1,Race2,SubRace1,SubRace2,Ethnicity1, Ethnicity2 from u;


END

go
