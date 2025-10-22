USE CpsWarehouse
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO

drop table if exists [CpsWarehouse].[cps_track].[breast_diagnosis]
go
create table [CpsWarehouse].[cps_track].[breast_diagnosis] (
	[PID] [numeric](19, 0) NOT NULL,
	[SDID] [numeric](19, 0) NOT NULL,
	[VisitDate] [date] NOT NULL,
	[Code] [varchar](10) NOT NULL,
	[ProblemDesc] [varchar](100) NOT NULL,
	[DiagnosisDate] [date] NULL,
	[StopDate] [date] NULL,
	[StopReason] [varchar](30) NULL,
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO


SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

drop PROCEDURE if exists [cps_track].[ssis_breastDiagnosis] 

go
CREATE procedure [cps_track].[ssis_breastDiagnosis]
as begin

truncate table cps_track.breast_diagnosis;


--DECLARE @StartDate DATETIME = '2017-1-1';
--DECLARE @EndDate DATETIME = '2017-12-15';
DECLARE @AllDiag NVARCHAR(100) = 'N60.19,N61,N63,N64.52,R92.0,R92.2,R92.8,D05.11,D05.90,D24.9,C50.919,C50.911,C50.912';

with u as (
	select 
		doc.PID, doc.SDID, CONVERT(DATE,doc.db_Create_Date) VisitDate, 
		diag.Code Code,diag.ShortDescription ProblemDesc, 
		CONVERT(DATE,pr.ONSETDATE) DiagnosisDate, 
		case when convert(date,pr.stopDate) = '4700-12-31' then NULL
			else convert(date,pr.stopDate) end StopDate, 
		case pr.stopreason 
			when 'I' then 'Inactive'
			when 'O' then 'Ruled Out'
			when 'R' then 'Removed'
			when 'S' then 'Resolved'
			when 'T' then 'Correction'
			when 'G' then 'Discharged'
			when 'F' then 'Refinement'
			when 'P' then 'Not specified'
			when 'N' then 'None'
			when 'C' then 'Changed'
			when 'E' then 'Entered In Error'
		end StopReason
	from [CpsWarehouse].cps_visits.DOCUMENT doc
		LEFT JOIN [cpssql].CentricityPS.dbo.Problem pr ON pr.SDID = doc.SDID
		LEFT JOIN [cpssql].CentricityPS.dbo.MasterDiagnosis diag ON diag.MasterDiagnosisId = pr.ICD10MasterDiagnosisId
	where   doc.DocType = 1
		AND diag.Code IN ('N60.19','N61','N63','N64.52','R92.0','R92.2','R92.8','D05.11','D05.90','D24.9','C50.919','C50.911','C50.912')
		--and  doc.db_Create_Date BETWEEN @StartDate AND @EndDate
) 

insert into cps_track.breast_diagnosis (PID,SDID,VisitDate,Code,ProblemDesc,DiagnosisDate,StopDate,StopReason)
select PID,SDID,VisitDate,Code,ProblemDesc,DiagnosisDate,StopDate,StopReason from u


end

go

