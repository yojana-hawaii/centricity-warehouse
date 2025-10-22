
use CpsWarehouse
go

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
drop table if exists [CpsWarehouse].[cps_insurance].Ohana_CPT_ICD;
go
create table [CpsWarehouse].[cps_insurance].Ohana_CPT_ICD (
	[PID] [numeric](19, 0) NOT NULL,
	[SDID] [numeric](19, 0)  NULL,
	[Service_Performed] nvarchar(16) not null,
	CPTCode nvarchar(100)  null,
	ICD10Code nvarchar(10)  null,
	PatientVisitID int not null,
	[Service_Date] date not null,
)

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

drop PROCEDURE if exists [cps_insurance].ssis_Ohana_CPT_ICD; 
 
go
CREATE procedure [cps_insurance].ssis_Ohana_CPT_ICD
as 
begin

	truncate table cps_insurance.Ohana_CPT_ICD;


	
	drop table if exists #OhanaCPT;
	Create table #OhanaCPT
	(
		OhanaCode varchar(20) not null,
		CPTCode varchar(10) not null,
	);
	insert into #OhanaCPT 
	values 
		('WELLV','99381'),('WELLV','99382'),('WELLV','99383'),('WELLV','99384'),('WELLV','99385'),
		('WELLV','99391'),('WELLV','99392'),('WELLV','99393'),('WELLV','99394'),('WELLV','99395'),
		('WELLV','99461')
		--('CWP', '87070'),('CWP', '87071'),('CWP', '87081'),('CWP', '87430'),('CWP', '87650'),
		--('CWP', '87651'),('CWP', '87652'),('CWP', '87880'),
		--('AMB','G0438'),('AMB','G0439')
	--select * from #OhanaCPT order by OhanaCode, cptcode

	drop table if exists #OhanaICD;
	Create table #OhanaICD
	(
		OhanaCode varchar(20) not null,
		ICDCode varchar(10) not null,
	);
	insert into #OhanaICD 
	values ('WELLV','Z00.110'),('WELLV','Z00.111'),('WELLV','Z00.121'),('WELLV','Z00.129'),
		('WELLV', 'Z00.00'),('WELLV', 'Z00.01'),
		('AOCHX', 'Z90.71'),('AOCHX', 'Z90.710'),
		--('BLMHX','Z90.1'), ('BLMHX','Z90.10'),('BLMHX','Z90.11'),('BLMHX','Z90.12'),/*1/5/2023 - met with josh. bilaternal should only be Z90.13*/
		('BLMHX','Z90.13'),
		('TAH','Z90.710'),
		('ULMHX','Z90.11'),('ULMHX','Z90.12'),('ULMHX','Z90.10')
		--('POST','Z39.1'),
		--('PREN','Z34.91'),('PREN','Z34.92'),('PREN','Z34.93')
		--('AMB','Z00.00'),('AMB','Z00.01')
	--select * from #OhanaICD

	;with telehealth as (
		select 
			o.PID, o.SDID, o.CPTCode,
			--pvp.Code CPTCode, c.OhanaCode, 
			case 
				when o.CPTCode like '%99441%' or o.CPTCode like '%99442%' or o.CPTCode like '%99443%' or 
					o.CPTCode like '%98966%' or o.CPTCode like '%98967%' or o.CPTCode like '%98968%'
				then 'TELE'
			else 'OASS'
			end Service_Performed, convert(date,o.DoS) Service_Date,
			o.PatientVisitID, o.Telehealth
		from cps_insurance.tmp_view_OhanaEncounters o
		where o.Telehealth = 1
			
	), icd as (
		select o.PID, o.SDID, d.Code ICD10Cde, i.OhanaCode, o.PatientVisitID, o.Telehealth,  convert(date,o.DoS) Service_Date
		from cps_insurance.tmp_view_OhanaEncounters o
			inner join cpssql.centricityps.dbo.patientvisitdiags d  on o.patientVisitID= d.patientVisitID
			inner join #OhanaICD i on i.ICDCode = ltrim(rtrim(d.code))
		where o.Telehealth = 0
		--where sdid is not null
	), cpt as (
		select o.PID, o.SDID, pvp.Code CPTCode, c.OhanaCode, o.PatientVisitID, o.Telehealth,  convert(date,o.DoS) Service_Date
		from cps_insurance.tmp_view_OhanaEncounters o
			inner join cpssql.CentricityPS.dbo.PatientVisitProcs pvp  on o.patientVisitID= pvp.patientVisitID
			inner join #OhanaCPT c on c.CPTCode = ltrim(rtrim(pvp.code))
		--where sdid is not null
		where o.Telehealth = 0
	)
	,u as (
		select 
			case when cpt.PID is not null then cpt.PID else icd.PID end PID, 
			case when cpt.SDID is not null then cpt.SDID else icd.SDID end SDID, 
			case when cpt.PatientVisitID is not null then cpt.PatientVisitID else icd.PatientVisitID end PatientVisitID, 
			case when cpt.OhanaCode is not null then cpt.OhanaCode else icd.OhanaCode end Service_Performed, 
			case when cpt.Service_Date is not null then cpt.Service_Date else icd.Service_Date end Service_Date, 
			cpt.CPTCode, icd.ICD10Cde 
		from icd
			full outer join cpt on cpt.PatientVisitID = icd.PatientVisitID and cpt.OhanaCode = icd.OhanaCode
		union

		select PID, SDID, PatientVisitID, Service_Performed,Service_Date, CPTCode, null ICD10Cde
		from telehealth
	)	

	--select * from u
		insert into cps_insurance.Ohana_CPT_ICD (PID, SDID, Service_Performed, CPTCode, ICD10Code, PatientVisitID,Service_Date)
		select pid, sdid, Service_Performed, CPTCode, ICD10Cde, PatientVisitID,Service_Date from u
		
end

go
