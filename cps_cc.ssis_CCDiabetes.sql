
use CpsWarehouse
go

drop table if exists [cps_cc].[CCDiabetes];
go
CREATE TABLE [cps_cc].[CCDiabetes] (
    [ccDiabetesID]        BIGINT        IDENTITY (1, 1) NOT NULL,
    [PID]                 NUMERIC (19)  NOT NULL,
    [SDID]                NUMERIC (19)  NOT NULL,
    [Summary]             VARCHAR (100) NOT NULL,
    [DocType]             NUMERIC (19)  NOT NULL,
    [ObsDate]             DATE          NOT NULL,
    [PsychoSocial]        VARCHAR (MAX) NOT NULL,
    [PsychoSocialComment] VARCHAR (MAX) NOT NULL,
    [LifeStyleGoal]       VARCHAR (MAX) NOT NULL,
    [LifeStyleComment]    VARCHAR (MAX) NOT NULL,
    [DiabetesGoal]        VARCHAR (MAX) NOT NULL,
    [DiabetesGoalComment] VARCHAR (MAX) NOT NULL,
    [DMPlan]              VARCHAR (MAX) NOT NULL,
    PRIMARY KEY CLUSTERED ([ccDiabetesID] ASC),
    CONSTRAINT [fk_diabObs] FOREIGN KEY ([ObsDate]) REFERENCES [dbo].[dimDate] ([date])
);
go
drop procedure if exists [cps_cc].[ssis_CCDiabetes];
go
create procedure [cps_cc].[ssis_CCDiabetes]
as begin

truncate table cps_cc.CCDiabetes;

with u as (
	select PID, SDID, SUMMARY, DOCTYPE, ObsDate, ISNULL([125465],'') AS [PyschoSocial], ISNULL([8757],'') AS [PsychoSocialComment], ISNULL([482286],'') AS [LifestyleGoal], ISNULL([152755],'') AS [LifestyleComment],ISNULL([19400],'') AS [DiabetesGoal], ISNULL([19405],'') AS [DiabetesGoalComment], ISNULL([407536],'') AS DMPlan
	from 
	(
		SELECT obs.PId PID,obs.SDID SDID,doc.Summary Summary, doc.DOCTYPE DocType,obs.hdid,obs.OBSVALUE,obs.OBSDATE Obsdate
		FROM [cpssql].[CentricityPS].dbo.OBS
			LEFT JOIN [cpssql].[CentricityPS].dbo.DOCUMENT doc on doc.sdid = obs.sdid 
		WHERE obs.HDID IN (125465,8757,482286,152755,19400,19405,407536)
			AND DOCTYPE != 1
	) q
		PIVOT (
		MAX(obsvalue)
			FOR hdid IN ([125465],[8757],[482286],[152755],[19400],[19405],[407536])
	) AS p
)

	insert into cps_cc.CCDiabetes (PID,SDID,Summary,DocType,Obsdate,PsychoSocial,PsychoSocialComment,LifeStyleGoal,LifeStyleComment,DiabetesGoal,DiabetesGoalComment,DMPlan)
	select PID,SDID,Summary,DocType,Obsdate,[PyschoSocial],PsychoSocialComment,LifeStyleGoal,LifeStyleComment,DiabetesGoal,DiabetesGoalComment,DMPlan from u;
end

go
