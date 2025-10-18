
use CpsWarehouse
go

drop table if exists [cps_cc].[CCCKD];
go
CREATE TABLE [cps_cc].[CCCKD] (
    [ccCKDID]             BIGINT        IDENTITY (1, 1) NOT NULL,
    [PID]                 NUMERIC (19)  NOT NULL,
    [SDID]                NUMERIC (19)  NOT NULL,
    [Summary]             VARCHAR (100) NOT NULL,
    [DocType]             NUMERIC (19)  NOT NULL,
    [ObsDate]             DATE          NOT NULL,
    [VascRiskFactor]      VARCHAR (MAX) NOT NULL,
    [VascComment]         VARCHAR (MAX) NOT NULL,
    [RenoFactor]          VARCHAR (MAX) NOT NULL,
    [RenalComment]        VARCHAR (MAX) NOT NULL,
    [Vein]                VARCHAR (MAX) NOT NULL,
    [VeinComment]         VARCHAR (MAX) NOT NULL,
    [Commorbidity]        VARCHAR (MAX) NOT NULL,
    [CommorbidityComment] VARCHAR (MAX) NOT NULL,
    [CKDPlan]             VARCHAR (MAX) NOT NULL,
    PRIMARY KEY CLUSTERED ([ccCKDID] ASC),
  
);
go

drop proc if exists [cps_cc].[ssis_CCCKD];
go
CREATE procedure [cps_cc].[ssis_CCCKD]
as begin

truncate table [cps_cc].[CCCKD];

with u as (
	select PID, SDID, SUMMARY, DOCTYPE, ObsDate, ISNULL([162411],'') AS [VascRiskFactor], ISNULL([95890],'') AS [VascComment],ISNULL([61335],'') AS [RenoFactor], 
	ISNULL([29747],'') AS [RenalComment], ISNULL([38499],'') AS [Vein], ISNULL([32276],'') AS [VeinComment],ISNULL([62189],'') AS [Commorbidity], 
	ISNULL([172758],'') AS [CommorbidityComment], ISNULL([407539],'') AS CKDPlan
	from 
	(
		SELECT obs.PId PID,obs.SDID SDID,doc.Summary Summary, doc.DOCTYPE DocType,obs.hdid,obs.OBSVALUE,obs.OBSDATE Obsdate
		FROM [cpssql].[CentricityPS].dbo.OBS
			LEFT JOIN [cpssql].[CentricityPS].dbo.DOCUMENT doc on doc.sdid = obs.sdid 
		WHERE obs.HDID IN (162411,95890,61335,29747,38499,32276,62189,172758,407539)
			AND DOCTYPE != 1
	) q
		PIVOT (
		MAX(obsvalue)
			FOR hdid IN ([162411],[95890],[61335],[29747],[38499],[32276],[62189],[172758],[407539])
	) AS p
)

	insert into cps_cc.CCCKD(PID,SDID,Summary,DocType,ObsDate,VascRiskFactor,VascComment,RenoFactor,RenalComment,Vein,VeinComment,Commorbidity,CommorbidityComment,CKDPlan)
	select PID,SDID,Summary,DocType,ObsDate,VascRiskFactor,VascComment,RenoFactor,RenalComment,Vein,VeinComment,Commorbidity,CommorbidityComment,CKDPlan from u;


end

go
