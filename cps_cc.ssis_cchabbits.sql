
use CpsWarehouse
go
drop table if exists [cps_cc].[CCHabits]
go
CREATE TABLE [cps_cc].[CCHabits] (
    [ccHabitID]        BIGINT        IDENTITY (1, 1) NOT NULL,
    [PID]              NUMERIC (19)  NOT NULL,
    [SDID]             NUMERIC (19)  NOT NULL,
    [Summary]          VARCHAR (100) NOT NULL,
    [DocType]          NUMERIC (19)  NOT NULL,
    [ObsDate]          DATE          NOT NULL,
    [CareCoordinator]  VARCHAR (100) NOT NULL,
    [PhysicalActivity] VARCHAR (20)  NOT NULL,
    [ActivityPerWeek]  VARCHAR (20)  NOT NULL,
    [TypeOfActivity]   VARCHAR (MAX) NOT NULL,
    [Food]             VARCHAR (MAX) NOT NULL,
    [Fluid]            VARCHAR (MAX) NOT NULL,
    [CarePlanGiven]    VARCHAR (5)   NOT NULL,
    PRIMARY KEY CLUSTERED ([ccHabitID] ASC),

);

go

drop proc if exists [cps_cc].[ssis_cchabbits];
go
create procedure [cps_cc].[ssis_cchabbits]
as begin

truncate table cps_cc.[CCHabits];

with u as (
	select PID, SDID, SUMMARY, DOCTYPE, ObsDate, ISNULL([487418],'') [CareCoordinator],ISNULL([5449],'') [PhysicalActivity],ISNULL([128],'') [ActivityPerWeek], ISNULL([8833],'') [TypeOfActivity],ISNULL([46385],'') [Food],ISNULL([44726],'') [Fluid],
	case [95265] WHEN 'CARE PLAN GIVEN TO PATIENT' THEN 'Yes' Else 'No' End [CarePlanGiven]
	from 
	(
		SELECT obs.PId PID,obs.SDID SDID,doc.Summary Summary, doc.DOCTYPE DocType,obs.hdid,obs.OBSVALUE,obs.OBSDATE Obsdate
		FROM [cpssql].[CentricityPS].dbo.OBS
			LEFT JOIN [cpssql].[CentricityPS].dbo.DOCUMENT doc on doc.sdid = obs.sdid 
		WHERE obs.HDID IN (487418,5449,128,8833,46385,44726,95265)
			AND DOCTYPE != 1
	) q
		PIVOT (
		MAX(obsvalue)
			FOR hdid IN ([487418],[5449],[128],[8833],[46385],[44726],[95265])
	) AS p
)

	insert into cps_cc.CCHabits(PID, SDID,Summary,DocType,ObsDate,CareCoordinator,PhysicalActivity,ActivityPerWeek,TypeOfActivity,Food,Fluid,CarePlanGiven)
	select PID, SDID,Summary,DocType,ObsDate,CareCoordinator,PhysicalActivity,ActivityPerWeek,TypeOfActivity,Food,Fluid,CarePlanGiven from u;

end

go
