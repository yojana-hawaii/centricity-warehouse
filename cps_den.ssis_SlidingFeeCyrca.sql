
USE CpsWarehouse
GO 

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO

drop table if exists [CpsWarehouse].[cps_den].[SlidingFeeCyrca];
create table [CpsWarehouse].[cps_den].[SlidingFeeCyrca] (
	[PatientID] [varchar](20) NOT NULL,
	[LastName] [varchar](21) NOT NULL,
	[Firstname] [varchar](16) NOT NULL,
	[BirthDate] [date] NOT NULL,
	[Gender] [varchar](6) NOT NULL,
	[Race] [varchar](25) NOT NULL,
	[ClinicName] [varchar](25) NOT NULL,
	[Insurance] [varchar](50) NOT NULL,
	[InsID] [int] NOT NULL,
	[ServiceDate] [date] NOT NULL,
	[ADACode] [varchar](10) NOT NULL,
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO

--	exec [cps_den].[ssis_slidingFee_Cyrca] 
--	select * from [cps_den].[SlidingFeeCyrca]

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
drop PROCEDURE if exists [cps_den].[ssis_slidingFee_Cyrca] 
go
CREATE procedure [cps_den].[ssis_slidingFee_Cyrca]
as begin

truncate table [cps_den].[SlidingFeeCyrca];

declare @startdate DATE = '01-01-2015', @enddate DATE = getdate();--, @insurance nvarchar(30) = 'Cyrca';
with u as (
	SELECT DISTINCT  
		(Patient.Chart) as PatientID, Patient.LastName LastName, Patient.FirstName FirstName, 
 		CONVERT(DATE,ProcLog.PLDate) as ServiceDate,CONVERT (DATE, Patient.BIRTHDATE) as BirthDate,
		(CASE WHEN Gender = 1 THEN 'Male' ELSE 'Female' END) as Gender,
		RTRIM(def.DESCRIPTION) as Race, ProcCode.ADACode as 'ADACode',
		Insurance.INSCONAME as Insurance, 
		Insurance.INSID,
		(case Clinic.RSCID 
			when 'downtown' then 'Dental DT'
			when 'cps' then 'Dental 915' 
			when 'WCC' then 'Dental 710A'
			when 'FDC' then 'Dental 710B'
		else 'Call me' end )as ClinicName
	FROM [den_sql].[Dentrix].dbo.DDB_PROC_LOG_BASE as ProcLog 
		left join [den_sql].[Dentrix].dbo.DDB_PROC_CODE_BASE as ProcCode on (ProcCode.PROC_CODEID=ProcLog.PROC_CODEID)    
		left join [den_sql].[Dentrix].dbo.DDB_PAT_BASE as Patient on ProcLog.PATID=Patient.PATID  
		left join [den_sql].[Dentrix].dbo.DDB_DEF_TEXT as def on (def.DEFID = Patient.Race AND def.TYPE = 100 )
		left join [den_sql].[Dentrix].dbo.DDB_CLINIC_INFO as Clinic on (Clinic.UrscId=ProcLog.ClinicAppliedTo)
		left join [den_sql].[Dentrix].dbo.DDB_INSURED_BASE as Insured  on (Patient.PrInsuredId = Insured.InsuredId )
		left join [den_sql].[Dentrix].dbo.DDB_INSURANCE as Insurance on Insured.InsId=Insurance.InsId  
	WHERE ProcLog.HISTORY	= '1'		-- just added (history 1 is treatment plan before march 2022)
		--and and CHART_STATUS = 102 -- possible filter to remove treatment plan - 
		AND	ProcLog.PLDate BETWEEN @startdate AND @enddate
		/*Elcid - state does accept these codes*/
		and ProcCode.ADACode not in ('D0120','D0220','D0150','D1110','D2160','D0210','D9310',
									'D0330','D0230','D1208','D0274','D0272','D1206','D1120',
									'D0140', 'D0140m', 'D0270','D1354')
		and Insurance.INSID IN (1000106,1000108,1000127,1000431,1000638,1000655,1000656,1000004,1000003,1000005,1000006,1000007)
		--AND (
		--		(@insurance like '%Cyrca%' AND Insurance.INSID IN (1000106,1000108,1000127,1000431,1000638,1000655,1000656) )
		--		or
		--		(@insurance like '%Sliding%' AND Insurance.INSID IN (1000004,1000003,1000005,1000006,1000007) )
				--or
				--(@insurance = ('Sliding,Cyrca') AND Insurance.INSID IN (1000004,1000003,1000005,1000006,1000007,1000106,1000108,1000127,1000431,1000638,1000655,1000656) )
			--) 
		and  LTRIM(RTRIM(ProcCode.ADACode)) like 'd%'
									
)
,v as(
select 
	u1.PatientID ,u1.LastName,u1.FirstName,convert(date,u1.BirthDate) BirthDate,u1.Gender,isnull(u1.Race,'') Race,u1.ClinicName,u1.Insurance, u1.InsID,convert(date,u1.ServiceDate) ServiceDate,
	u1.ADACode ,
	(select ADACode + ', '
	from u u2
	where u1.PatientID = u2.PatientID and u1.ServiceDate = u2.ServiceDate
	order by ADACode
		FOR XML path('') ) as Codes
from u u1
group by u1.PatientID,u1.LastName,u1.FirstName,BirthDate,u1.Gender,u1.Race,u1.ClinicName,u1.Insurance,u1.ServiceDate, u1.ADACode,InsID
), w as(
select *, 
	case  when codes like '%D7140%' or codes like '%D9110%' or codes like '%D0140m%' or codes like '%D9310%' or codes like '%D0140%' 
	then 1 
	else 0 end as  MayNotCountCoz
from v
) 

insert [cps_den].[SlidingFeeCyrca] (PatientID,LASTNAME,FirstName,BirthDate,Gender,Race,ClinicName,Insurance,ServiceDate,ADACode,InsID)
select PatientID,LASTNAME,FirstName,BirthDate,Gender,Race,ClinicName,Insurance,ServiceDate ,ADACode,InsID from w;


end
GO
