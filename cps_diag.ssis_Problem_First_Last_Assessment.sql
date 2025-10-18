
use CpsWarehouse
go 
drop table if exists [cps_diag].[Problem_First_Last_Assessment];
go
CREATE TABLE [cps_diag].[Problem_First_Last_Assessment] (
    [PRID]             NUMERIC (19)  NOT NULL,
    [SPRID]            NUMERIC (19)  NOT NULL,
    [PID]              NUMERIC (19)  NOT NULL,
    [ICD10Code]        VARCHAR (100) NULL,
    [ShortDescription] VARCHAR (MAX) NULL,
    [Inactive]         INT           NOT NULL,
    [OnsetDate]        DATE          NULL,
    [StopDate]         DATE          NULL,
    [StopReason]       VARCHAR (50)  NULL,
    [LastAssessDate]   DATE          NULL,
    [TotalAssessment]  INT           NOT NULL,
    PRIMARY KEY CLUSTERED ([SPRID] ASC)
);

go
drop proc if exists [cps_diag].ssis_Problem_First_Last_Assessment;
go

create proc [cps_diag].ssis_Problem_First_Last_Assessment
as 
begin
truncate table [cps_diag].[Problem_First_Last_Assessment];
with u as (
	select  
		pr.prid prid, pr.sprid sprid,
		pr.pid pid, md.Code ICD10Code, md.ShortDescription ShortDescription, 
		convert(date, pr.ONSETDATE) OnsetDate, 
		convert(date, pr.STOPDATE) StopDate, 
	
		coalesce(
		case pr.stopReason
				when 'I' then 'Inactive'
				when 'O' then 'Ruled Out'
				when 'R' then 'Removed'
				when 'S' then 'Resolved'
				when 'T' then 'Correction'
				when 'G' then 'Discharged'
		end,
		case pr.stopReason
				when 'F' then 'Refinement'
				when 'P' then 'Not specified'
				when 'N' then 'None'
				when 'C' then 'Changed'
				when 'E' then 'Entered In Error'
			end 
		) StopReason,
		case 
			when pr.xid = 1000000000000000000 and convert(date, stopdate) > convert(date, getdate() ) then 0	--xid changes to sprid when problem is inactive, sometime it doesn't so use stop date as well.
			else 1
			end Inactive,
		(select 
				max(convert(date, ass.CLINICALDATE)) l
		from cpssql.CentricityPS.dbo.assess ass
		where ass.SPRID = pr.SPRID
		) [LastAssessDate],
		(select 
				count(sprid) + 1 total							-- add one coz it doesn't the onset date from problem table, only counts number of assessment in assess table
		from cpssql.CentricityPS.dbo.assess ass
		where ass.SPRID = pr.SPRID
		) [TotalAssessment]
	from cpssql.CentricityPS.dbo.PROBLEM pr
		left join cpssql.CentricityPS.dbo.MasterDiagnosis md on pr.ICD10MasterDiagnosisId = md.MasterDiagnosisId
		inner join CpsWarehouse.cps_visits.Document doc on doc.sdid = pr.sdid

)
	 insert [cps_diag].[Problem_First_Last_Assessment] (
		[PRID], [SPRID], [PID], [ICD10Code], [ShortDescription], [Inactive], 
		[OnsetDate], [StopDate], [StopReason], [LastAssessDate], [TotalAssessment]
		)
	select
		[PRID], [SPRID], [PID], [ICD10Code], [ShortDescription], [Inactive], 
		[OnsetDate], [StopDate], [StopReason], [LastAssessDate], [TotalAssessment]
	from u;

	end

	go
