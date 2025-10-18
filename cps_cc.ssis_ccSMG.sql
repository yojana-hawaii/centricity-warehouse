
use CpsWarehouse
go
drop table if exists [cps_cc].[CCSMG];
go
CREATE TABLE [cps_cc].[CCSMG] (
    [ccSMGID]     BIGINT        IDENTITY (1, 1) NOT NULL,
    [PID]         NUMERIC (19)  NOT NULL,
    [SDID]        NUMERIC (19)  NOT NULL,
    [Summary]     VARCHAR (100) NOT NULL,
    [DocType]     NUMERIC (19)  NOT NULL,
    [ObsDate]     DATE          NOT NULL,
    [Goal]        VARCHAR (MAX) NOT NULL,
    [Actions]     VARCHAR (MAX) NOT NULL,
    [Barrier]     VARCHAR (MAX) NOT NULL,
    [FollowUp]    VARCHAR (MAX) NOT NULL,
    [Confidence]  VARCHAR (MAX) NOT NULL,
    [GoalMetDate] VARCHAR (MAX) NOT NULL,
    PRIMARY KEY CLUSTERED ([ccSMGID] ASC),
);

go
drop proc if exists [cps_cc].[ssis_ccSMG];
go

create procedure [cps_cc].[ssis_ccSMG]
as begin

truncate table [cps_cc].[CCSMG];

with u as (
	Select PID, SDID,Summary,DocType,ObsDate, Goal, SMGSmokeAction AS [Action], SMGSmokeBarrier AS [Barrier], SMGSmokeFU AS[FollowUp], SMGSmokeConfidence AS [Confidence], SMGSmokeMet AS [GoalMetDate]
	from(
	select PID, SDID,Summary,DocType,ObsDate, 'Quit Smoking' Goal, ISNULL([306167],'') AS [SMGSmokeAction],ISNULL([388023],'') AS [SMGSmokeBarrier],ISNULL([306179],'') AS [SMGSmokeFU],ISNULL([229085],'') AS [SMGSmokeConfidence],ISNULL([229095],'') AS [SMGSmokeMet]
		from 
		(
			SELECT obs.PId,obs.SDID,obs.hdid,obs.OBSVALUE,obs.OBSDATE,doc.Summary, doc.DOCTYPE
			FROM [cpssql].[CentricityPS].dbo.OBS	
				LEFT JOIN [cpssql].[CentricityPS].dbo.DOCUMENT doc on doc.sdid = obs.sdid 
			WHERE obs.HDID IN (306167,388023,306179,229085,229095)
		) q
			PIVOT (
			MAX(obsvalue)
				FOR hdid IN ([306167],[388023],[306179],[229085],[229095])
		) AS p
	UNION
	select PID, SDID,Summary,DocType,ObsDate, 'Take Meds' Goal, ISNULL([306168],'') AS [SMGMedsAction],ISNULL([388030],'') AS [SMGMedsBarrier],ISNULL([306180],'') AS [SMGMEdsFU],ISNULL([229086],'') AS [SMGMedsConfidence],ISNULL([229096],'') AS [SMGMedsMet]
		from 
		(
			SELECT obs.PId,obs.SDID,obs.hdid,obs.OBSVALUE,obs.OBSDATE,doc.Summary, doc.DOCTYPE
			FROM [cpssql].[CentricityPS].dbo.OBS	
				LEFT JOIN [cpssql].[CentricityPS].dbo.DOCUMENT doc on doc.sdid = obs.sdid 
			WHERE obs.HDID IN (306168,388030,306180,229086,229096)
		) q
			PIVOT (
			MAX(obsvalue)
				FOR hdid IN ([306168],[388030],[306180],[229086],[229096])
		) AS p
	UNION
	select PID, SDID,Summary,DocType,ObsDate, 'Check Feet' Goal, ISNULL([306169],'') AS [SMGFeetAction],ISNULL([388037],'') AS [SMGFeetBarrier],ISNULL([306181],'') AS [SMGFeetFU],ISNULL([229087],'') AS [SMGFeetConfidence],ISNULL([229097],'') AS [SMGFeetMet]
		from 
		(
			SELECT obs.PId,obs.SDID,obs.hdid,obs.OBSVALUE,obs.OBSDATE,doc.Summary, doc.DOCTYPE
			FROM [cpssql].[CentricityPS].dbo.OBS	
				LEFT JOIN [cpssql].[CentricityPS].dbo.DOCUMENT doc on doc.sdid = obs.sdid 
			WHERE obs.HDID IN (306169,388037,306181,229087,229097)
		) q
			PIVOT (
			MAX(obsvalue)
				FOR hdid IN ([306169],[388037],[306181],[229087],[229097])
		) AS p
	UNION
	select PID, SDID,Summary,DocType,ObsDate, 'Eye Exam' Goal, ISNULL([306170],'') AS [SMGEyeAction],ISNULL([388043],'') AS [SMGEyeBarrier],ISNULL([306182],'') AS [SMGEyeFU],ISNULL([229088],'') AS [SMGEyeConfidence],ISNULL([229098],'') AS [SMGEyeMet]
		from 
		(
			SELECT obs.PId,obs.SDID,obs.hdid,obs.OBSVALUE,obs.OBSDATE,doc.Summary, doc.DOCTYPE
			FROM [cpssql].[CentricityPS].dbo.OBS	
				LEFT JOIN [cpssql].[CentricityPS].dbo.DOCUMENT doc on doc.sdid = obs.sdid 
			WHERE obs.HDID IN (306170,388043,306182,229088,229098)
		) q
			PIVOT (
			MAX(obsvalue)
				FOR hdid IN ([306170],[388043],[306182],[229088],[229098])
		) AS p
	UNION
	select PID, SDID,Summary,DocType,ObsDate, 'Physical Activity' Goal, ISNULL([306171],'') AS [SMGActivityAction],ISNULL([388050],'') AS [SMGActivityBarrier],ISNULL([306183],'') AS [SMGActivityFU],ISNULL([229089],'') AS [SMGActivityConfidence],ISNULL([229099],'') AS [SMGActivityMet]
		from 
		(
			SELECT obs.PId,obs.SDID,obs.hdid,obs.OBSVALUE,obs.OBSDATE,doc.Summary, doc.DOCTYPE
			FROM [cpssql].[CentricityPS].dbo.OBS	
				LEFT JOIN [cpssql].[CentricityPS].dbo.DOCUMENT doc on doc.sdid = obs.sdid 
			WHERE obs.HDID IN (306171,388050,306183,229089,229099)
		) q
			PIVOT (
			MAX(obsvalue)
				FOR hdid IN ([306171],[388050],[306183],[229089],[229099])
		) AS p
	UNION
	select PID, SDID,Summary,DocType,ObsDate, 'Healthy Food' Goal, ISNULL([306172],'') AS [SMGFoodAction],ISNULL([388057],'') AS [SMGFoodBarrier],ISNULL([306184],'') AS [SMGFoodFU],ISNULL([229090],'') AS [SMGFoodConfidence],ISNULL([229100],'') AS [SMGActivityMet]
		from 
		(
			SELECT obs.PId,obs.SDID,obs.hdid,obs.OBSVALUE,obs.OBSDATE,doc.Summary, doc.DOCTYPE
			FROM [cpssql].[CentricityPS].dbo.OBS	
				LEFT JOIN [cpssql].[CentricityPS].dbo.DOCUMENT doc on doc.sdid = obs.sdid 
			WHERE obs.HDID IN (306172,388057,306184,229090,229100)
		) q
			PIVOT (
			MAX(obsvalue)
				FOR hdid IN ([306172],[388057],[306184],[229090],[229100])
		) AS p

	UNION
	select PID, SDID,Summary,DocType,ObsDate, ('Other -' + ISNULL([105136],''))  Goal, ISNULL([306166],'') AS [SMGOtherAction],ISNULL([471235],'') AS [SMGOtherBarrier],ISNULL([306178],'') AS [SMGOtherFU],ISNULL([229104],'') AS [SMGOtherConfidence],ISNULL([229094],'') AS [SMGOtherMet]
		from 
		(
			SELECT obs.PId,obs.SDID,obs.hdid,obs.OBSVALUE,obs.OBSDATE,doc.Summary, doc.DOCTYPE
			FROM [cpssql].[CentricityPS].dbo.OBS	
				LEFT JOIN [cpssql].[CentricityPS].dbo.DOCUMENT doc on doc.sdid = obs.sdid 
			WHERE obs.HDID IN (306166,471235,306178,229104,229094,105136)
		) q
			PIVOT (
			MAX(obsvalue)
				FOR hdid IN ([306166],[471235],[306178],[229104],[229094],[105136])
		) AS p


	) r
)

	insert into cps_cc.CCSMG(PID,SDID,Summary,DocType,ObsDate,Goal,Actions,Barrier,FollowUp,Confidence,GoalMetDate)
	select PID,SDID,Summary,DocType,ObsDate,Goal,Action,Barrier,FollowUp,Confidence,GoalMetDate from u;
end

go
