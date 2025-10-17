use CpsWarehouse
go

drop table if exists [cps_visits].[Document];
go
CREATE TABLE [cps_visits].[Document] (
    [PID]                   NUMERIC (19) NOT NULL,
    [SDID]                  NUMERIC (19) NOT NULL,
    [XID]                   NUMERIC (19) NOT NULL,
    [LinkLogicSource]       varchar(30) NULL,
    [HasAttachment]         smallint	NOT NULL,
    [CCDA_Reconcile]        VARCHAR (15) NULL,
    [CCDA_Imports]          smallint     NULL,
    [FPExclusive]           SMALLINT     NULL,
    [CVR]                   VARCHAR (20) NULL,
    [DocAbbr]               VARCHAR (10) NOT NULL,
    [DocType]               NUMERIC (19) NULL,
    [Summary]               VARCHAR (64) NULL,
    [SignStatus]            VARCHAR (1)  NOT NULL,
    [db_Create_Date]        DATE         NOT NULL,
    [ClinicalDate]          NUMERIC (19) NOT NULL,
    [ClinicalDateConverted] AS           (fxn.[ClinicalDateToDate]([ClinicalDate])),
	[DaysToSign]			int			not null,
	[Signer]				varchar(50)	not null,
    [PubUser]               NUMERIC (19) not NULL,
    [Facility]              varchar(50) NOT NULL,
    [LoC]					varchar(10) NOT NULL,
    [VisDocID]              VARCHAR (12) NULL,
    [PatientVisitID]        INT          NULL,
    [AppointmentsID]        INT          NULL,
    PRIMARY KEY CLUSTERED ([SDID] ASC),
);
go

drop proc if exists [cps_visits].[ssis_Document]
go
CREATE procedure [cps_visits].[ssis_Document]
as begin

truncate table cps_visits.Document;
declare @cutOffDate date = '2016-01-01';

drop table if exists #fpExc
; WITH FPExclusive AS (
		SELECT 
			ifInOfficeVisit.PID PID,ifInOfficeVisit.SDID SDID,ifInOfficeVisit.XID,ifInOfficeVisit.DOCTYPE,ifInOfficeVisit.SUMMARY,ifInOfficeVisit.PatientVisitId,obs.OBSVALUE
		FROM [cpssql].CentricityPS.dbo.OBS
			INNER JOIN [cpssql].CentricityPS.dbo.DOCUMENT ifInOfficeVisit ON (ifInOfficeVisit.SDID = OBS.SDID AND ifInOfficeVisit.DOCTYPE = 1)
		WHERE hdid = 462432

		UNION

		SELECT 
			joinMainDoc.PID,joinMainDoc.SDID,joinMainDoc.XID,joinMainDoc.DOCTYPE,joinMainDoc.SUMMARY,joinMainDoc.PatientVisitId,obs.OBSVALUE
		FROM [cpssql].CentricityPS.dbo.OBS
			INNER JOIN [cpssql].CentricityPS.dbo.DOCUMENT ifAppended ON (ifAppended.SDID = OBS.SDID AND ifAppended.DOCTYPE = 31)
			INNER JOIN [cpssql].CentricityPS.dbo.DOCUMENT joinMainDoc ON (ifAppended.XID = joinMainDoc.SDID)
		WHERE hdid = 462432
	) 
	select 
		sdid, pid, 1 FPExclusive
	into #fpExc
	from FPExclusive

	--select * from #fpExc

drop table if exists #cvr;
; with AllCVRPatients AS (
		SELECT 
			ifInOfficeVisit.PID PID,ifInOfficeVisit.SDID SDID,ifInOfficeVisit.XID,ifInOfficeVisit.DOCTYPE,ifInOfficeVisit.SUMMARY,ifInOfficeVisit.PatientVisitId,obs.OBSVALUE,ifInOfficeVisit.DB_CREATE_DATE,ifInOfficeVisit.PUBUSER,ifInOfficeVisit.usrid
		FROM [cpssql].CentricityPS.dbo.OBS
			INNER JOIN [cpssql].CentricityPS.dbo.DOCUMENT ifInOfficeVisit ON (ifInOfficeVisit.SDID = OBS.SDID AND ifInOfficeVisit.DOCTYPE IN (1,6) )
		WHERE hdid = 97955

		UNION 

		SELECT 
			joinMainDoc.PID,joinMainDoc.SDID,joinMainDoc.XID,joinMainDoc.DOCTYPE,joinMainDoc.SUMMARY,joinMainDoc.PatientVisitId,obs.OBSVALUE,joinMainDoc.DB_CREATE_DATE,joinMainDoc.PUBUSER,joinMainDoc.usrid
		FROM [cpssql].CentricityPS.dbo.OBS
			INNER JOIN [cpssql].CentricityPS.dbo.DOCUMENT ifAppended ON (ifAppended.SDID = OBS.SDID AND ifAppended.DOCTYPE = 31)
			INNER JOIN [cpssql].CentricityPS.dbo.DOCUMENT joinMainDoc ON (ifAppended.XID = joinMainDoc.SDID)
		WHERE hdid = 97955
	)
	select 
		sdid, pid, ObsValue CVR
	into #cvr
	from AllCVRPatients

;with u as (
	select 
		
		doc.PID, doc.SDID, XID, 
		  
		case 
			when l3.name = 'LIS-DLS' then 'DLS - electronic'
			when l3.name = 'DocumentManagement' then 'DocMan - Scanned'
			when l3.name = 'DocumentManagementLab' then 'DocMan - Scanned'
			when l3.name = 'DocumentManagementLabSigned' then 'DocMan - Scanned'
			when l3.name = 'DocumentManagement-AIDS' then 'DocMan - Scanned'
			when l3.name = 'Corepoint-HDRS' then 'HDRS - electronic'
			
			when l3.name = 'LAB' then 'CLH - electronic'
			when l3.name = 'MIDMARK REPORT' then 'Midmark'
			when l3.name = 'MIDMARK OBS' then 'Midmark'
			when l3.name = 'BRENTWOOD REPORT' then 'Midmark'
			when l3.name = 'BRENTWOOD OBS' then 'Midmark'
			else l3.name 

		end LinkLogicSource,
		isnull(HasExtRef,0) HasAttachment, 

		case doc.RECONCILE_STATUS 
			when 'N' then 'New'
			when 'P' then 'InProgress'
			when 'C' then 'Complete'
			end CCDA_Reconcile, 
		case when doc.SOURCENAME is null then 0 else 1 end CCDA_Imports,

		case 
			when doc.DocType = 1534687650550890 then 'Preload' 
			when doc.SDID = 1821716161019650 then 'ComNote' 
		else dt.Abbr end DocAbbr, 
		doc.DocType,

		ClinicalDate, Summary, Status [SignStatus],
		convert(date,db_Create_Date) db_Create_Date,
		doc.PubUser,
		datediff(day, fxn.ClinicalDateToDate(doc.ClinicalDate), fxn.ClinicalDateToDate(doc.PubTime) ) DaysToSign,
		df.ListName Signer,  

		loc.Facility, loc.LocAbbrevName LoC,

		fp.FPExclusive, cvr.CVR, 
		
		VisDocID, 
		doc.PatientVisitID, doc.AppointmentsID

	from [cpssql].CentricityPS.dbo.Document doc
		inner join cps_all.PatientProfile pp on pp.pid = doc.pid
		left join [cpssql].CentricityPS.dbo.DoctorFacility df on df.PVID = doc.pubuser
		left join cps_all.Location loc on loc.locID = doc.LocOfCare
		left join [cpssql].CentricityPS.dbo.DocTypes dt on dt.dtid = doc.doctype
		left join [cpssql].CentricityPS.dbo.l3qualifier l3 on l3.qualid = doc.extid
		left join #fpExc fp on fp.pid = doc.pid and fp.sdid = doc.sdid 
		left join #cvr cvr on cvr.pid = doc.pid and cvr.sdid = doc.sdid
	where doc.doctype not in (30,24) /*replaced doc and filed in error*/
		and doc.status = 'S'
		and fxn.ClinicalDateToDate(doc.ClinicalDate) >= @cutOffDate
		and doc.pubuser is not null

)
--select * from u 
--where u.Signer = null
insert cps_visits.Document(
	[PID],[SDID],[XID],[LinkLogicSource],[HasAttachment],
	[CCDA_Reconcile],[CCDA_Imports],[FPExclusive],[CVR],[DocAbbr],
	[DocType],[Summary],[SignStatus],[db_Create_Date],[ClinicalDate],
	[DaysToSign],[Signer],[PubUser],[Facility],
	[LoC],[VisDocID],[PatientVisitID],[AppointmentsID]
)

select 
	[PID],[SDID],[XID],[LinkLogicSource],[HasAttachment],
	[CCDA_Reconcile],[CCDA_Imports],[FPExclusive],[CVR],[DocAbbr],
	[DocType],[Summary],[SignStatus],[db_Create_Date],[ClinicalDate],
	[DaysToSign],[Signer],[PubUser],[Facility],
	[LoC],[VisDocID],[PatientVisitID],[AppointmentsID]
from u;

end

go
