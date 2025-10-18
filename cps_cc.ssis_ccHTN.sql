
use CpsWarehouse
go

drop table if exists [cps_cc].[CCHTN]
go
CREATE TABLE [cps_cc].[CCHTN] (
    [ccHTNID]           BIGINT        IDENTITY (1, 1) NOT NULL,
    [PID]               NUMERIC (19)  NOT NULL,
    [SDID]              NUMERIC (19)  NOT NULL,
    [Summary]           VARCHAR (100) NOT NULL,
    [DocType]           NUMERIC (19)  NOT NULL,
    [ObsDate]           DATE          NOT NULL,
    [BloodTest]         VARCHAR (MAX) NOT NULL,
    [BloodTestComment]  VARCHAR (MAX) NOT NULL,
    [RiskFactor]        VARCHAR (MAX) NOT NULL,
    [RiskFactorComment] VARCHAR (MAX) NOT NULL,
    [Support]           VARCHAR (MAX) NOT NULL,
    [SupportComment]    VARCHAR (MAX) NOT NULL,
    [BarrierToCare]     VARCHAR (MAX) NOT NULL,
    [BarrierComment]    VARCHAR (MAX) NOT NULL,
    [Cultural]          VARCHAR (MAX) NOT NULL,
    [HTNPlan]           VARCHAR (MAX) NOT NULL,
    PRIMARY KEY CLUSTERED ([ccHTNID] ASC),
);



go
drop proc if exists [cps_cc].[ssis_ccHTN];
go
create procedure [cps_cc].[ssis_ccHTN]
as begin

truncate table cps_cc.cchtn;

with u as (
	select PID, SDID, SUMMARY, DOCTYPE, ObsDate, ISNULL([12600011],'') AS BloodTest, ISNULL([471185],'') AS BloodTestComment, 
	ISNULL([471190],'') As RiskFactor,ISNULL([471195],'') AS [RiskComment], ISNULL([471200],'') AS Support, ISNULL([471205],'') AS SupportComment, 
	ISNULL([471210],'') AS barrierToCare, ISNULL([471215],'') BarrierComment, ISNULL([187831],'') AS Cultural, ISNULL([100427],'') HTNPlan
	from 
	(
		SELECT obs.PId PID,obs.SDID SDID,doc.Summary SUmmary, doc.DOCTYPE Doctype,obs.hdid,obs.OBSVALUE,obs.OBSDATE ObsDate
		FROM [cpssql].[CentricityPS].dbo.OBS
			LEFT JOIN [cpssql].[CentricityPS].dbo.DOCUMENT doc on doc.sdid = obs.sdid 
		WHERE obs.HDID IN (12600011,471185,471190,471195,471200,471205,471210,471215,187831,100427)
			AND DOCTYPE != 1
	) q
		PIVOT (
		MAX(obsvalue)
			FOR hdid IN ([12600011],[471185],[471190],[471195],[471200],[471205],[471210],[471215],[187831],[100427])
	) AS p
)
insert into cps_cc.CCHTN(PID,SDID,Summary,DocType,ObsDate,BloodTest,BloodTestComment,RiskFactor,RiskFactorComment,Support,SupportComment,BarrierToCare,BarrierComment,Cultural,HTNPlan)
select PID,SDID,Summary,DocType,ObsDate,BloodTest,BloodTestComment,RiskFactor,[RiskComment],Support,SupportComment,BarrierToCare,BarrierComment,Cultural,HTNPlan from u;


END

go
