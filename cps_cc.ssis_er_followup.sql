GO
use CpsWarehouse
go
drop table if exists [cps_cc].[ER_Followup];
go
CREATE TABLE [cps_cc].[ER_Followup] (
    [ER_Followup_GUID]            UNIQUEIDENTIFIER DEFAULT (newsequentialid()) NOT NULL primary key,
    [PID]                         NUMERIC (19)     NOT NULL,
    [PatientID]                   VARCHAR (20)     NOT NULL,
    [newXSDID]                    NUMERIC (19)     NOT NULL,
    [CCDA]                        SMALLINT         NOT NULL,
    [ApptFacility]                VARCHAR (50)     NULL,
    [AdmitDate]                   DATE             NULL,
    [DischargeDate]               DATE             NULL,
    [AdmitDx]                     VARCHAR (500)    NULL,
    [ER]                          SMALLINT         NOT NULL,
    [ER_Hosp_Name]                VARCHAR (100)    NULL,
    [FirstAttempt]                DATE             NULL,
    [SecondAttempt]               DATE             NULL,
    [ThirdAttempt]                DATE             NULL,
    [FourthAttempt]               DATE             NULL,
    [FifthAttempt]                DATE             NULL,
    [SixthAttempt]                DATE             NULL,
    [SeventhAttempt]              DATE             NULL,
    [LetterAttempt]               DATE             NULL,
    [Q1]                          VARCHAR (3)      NULL,
    [Q2]                          VARCHAR (20)     NULL,
    [Q3]                          VARCHAR (5)      NULL,
    [Q4]                          VARCHAR (3)      NULL,
    [Q4_Y_Cps_to_ER]             SMALLINT         NULL,
    [Q4_Y_Phone_Busy]             SMALLINT         NULL,
    [Q4_Y_No_Answer]              SMALLINT         NULL,
    [Q4_Y_No_Call_Back]           SMALLINT         NULL,
    [Q4_Y_NoAppt]                 SMALLINT         NULL,
    [Q4_Y_Other]                  SMALLINT         NULL,
    [Q4_N_Clinic_Closed]          SMALLINT         NULL,
    [Q4_N_No_Phone]               SMALLINT         NULL,
    [Q4_N_Forgot]                 SMALLINT         NULL,
    [Q4_N_Language]               SMALLINT         NULL,
    [Q4_N_Other]                  SMALLINT         NULL,
    [Q5]                          VARCHAR (3)      NULL,
    [Education]                   SMALLINT         NULL,
    [EducationHoursOfOperation]   SMALLINT         NULL,
    [EducationAfterHours]         SMALLINT         NULL,
    [EducationPhysicianExch]      SMALLINT         NULL,
    [EducationNurseAdvice]        SMALLINT         NULL,
    [EducationPCPFollowUp]        SMALLINT         NULL,
    [EducationSameDay]            SMALLINT         NULL,
    [EducationMedication]         SMALLINT         NULL,
    [EducationAppropriateER]      SMALLINT         NULL,
    [EducationOther]              SMALLINT         NULL,
    [No_Appt_Refused]             SMALLINT         NULL,
    [No_Appt_NoContact]           SMALLINT         NULL,
    [No_Appt_NoPhone]             SMALLINT         NULL,
    [No_Appt_PhoneDisconnected]   SMALLINT         NULL,
    [No_Appt_PhoneBusy]           SMALLINT         NULL,
    [No_Appt_NoAnswer]            SMALLINT         NULL,
    [No_Appt_WrongNumber]         SMALLINT         NULL,
    [No_Appt_LeftMessage]         SMALLINT         NULL,
    [No_Appt_Other]               SMALLINT         NULL,
    [ApptScheduledinForm]         VARCHAR (50)     NULL,
    [ApptDateInForm]              DATE             NULL,
    [CpsSentToER]                INT              NULL,
    [ApptDateInCPS]               DATE             NULL,
    [ApptProv]                    VARCHAR (100)    NULL,
    [FutureApptDate]              DATE             NULL,
    [FutureProv]                  VARCHAR (100)    NULL,
    [No_Show_Count]               INT              NULL,
    [First_Contact_Attempt_Range] VARCHAR (10)     NULL,
    [Actual_Qualified_Appt_Range] VARCHAR (10)     NULL,

);

go

drop table if exists [cps_cc].[ER_Staff_Count];
go
CREATE TABLE [cps_cc].[ER_Staff_Count] (
    [ER_Staff_Followup_GUID] UNIQUEIDENTIFIER DEFAULT (newsequentialid()) NOT NULL primary key,
    [PID]                    NUMERIC (19)     NOT NULL,
    [xsdid]                  NUMERIC (19)     NOT NULL,
    [ClinicalDate]           DATE             NOT NULL,
    [DocAbbr]                VARCHAR (50)     NOT NULL,
    [DocSigned]              NUMERIC (19)     NOT NULL,
    [ListName]               VARCHAR (200)    NOT NULL
);
go


drop procedure if exists [cps_cc].[ssis_er_followup];
go
create procedure [cps_cc].[ssis_er_followup] 
as 
begin

truncate table [cps_cc].[ER_Followup];
truncate table [cps_cc].[ER_Staff_Count];

/*
Short Name		HDID		Description
ADMITTING DX	8752		admitting diagnosis
APPT SCHED		200228		Appointment scheduled
APPTDECLNRSN	214274		Reason appointment declined
BONE EDUC		4562		patient education, osteoporosis
CCAPPT1			211557		Care Coordination Appointment 1
CONT PHONE		78599		contact phone,for clinical purposes
CPOKCALLHM#		137288		Care Plan contact info ok to call or leave a message at patient's home number
DATE OF APPT	1000086		date of appointment
DATEHOSPIT 2	360332		Date of Hospitalization 2
DCHRGE ER DT	6292		emergency room, discharge date
EMERG ROOM		114070		Name of Emergency Room
EMERGENCY NT	77027		Emergency Room Note
ercount			568894		How many times have you been to the ER or hospital in the last 12 months?
ERLOC			574873		Location of ER
ERVISDATE		96267		date of ER visit
HEERTRANSPT		166846		Hospital encounter Transport method to ER
HOSPITAL LOS	10400002	Hospital Length of Stay
HOSPTRANSPRT	44688		transportation to hospital
ltr sent		15500029	letter was sent
NAME OF HOSP	6287		name of admitting/treating hospital
PHONE CALLER	54797		phone note, caller
PTDIRGOALS		167206		patient directed goals

HOSP DAYS		3227		More than One ER
HOSPNUMDAYS		38688		Total ER in a day
*/


-- Start of new form

declare @DocCreatedCutoffDate date = '2017-01-01';
declare @AdmitDateCutoff date = dateadd(day, -30, @DocCreatedCutoffDate)

/****GET DATA FROM OBS, ER SCAN, HOSP SCAN & CCDA and COMBINE

select * from #obs_cleaned_up where patientID = 12073343 and visdocid = 306
select * from #hospital_scans
select * from #ccda_import where patientID = 12073343 and visdocid = 306
select * from #ER_Scans
select * from #allDocs
********************************************************************************************************/

BEGIN

/** #obs_pivot: only signed
	all docs with ER followup - not Care coordinators forms
	find by obsterm --> 22 obs hdid
	doc has to be signed
	not internal other, office visit, phone notes
	only comNote, CCDA, ER ept and append
	remove test patients
	pivot
****************************************************/
--	declare @DocCreatedCutoffDate date = '2017-01-01';
drop table if exists #obs_pivot
select
	pp.PID PID,pp.PatientID,doc.SDID,doc.XID,doc.DocAbbr,OBSDATE ObsDate,
	doc.db_Create_Date db_Create_Date, fxn.ClinicalDateToDate(doc.ClinicalDate) ClinicalDate,
	doc.VisDocID, doc.Summary Summary,obs.pubuser DocSigned, doc.Facility,

	max(case  when hdid = 96267 then obsvalue  end) admitDate,
	max(case  when hdid = 360332 then obsvalue  end) admitTime,
	max(case  when hdid = 6292 then obsvalue  end) dischargeDate,
	max(case  when hdid = 114070 then obsvalue  end) ER,
	max(case  when hdid = 6287 then obsvalue  end) hospital,
	max(case  when hdid = 8752 then obsvalue  end) admitDx,
	max(case  when hdid = 44688 then obsvalue  end) Q1,
	max(case  when hdid = 10400002 then obsvalue  end) Q2,
	max(case  when hdid = 4562 then obsvalue  end) Q3,
	max(case  when hdid = 78599 then obsvalue  end) Q4,
	max(case  when hdid = 166846 then obsvalue  end) Q5,	
	max(case  when hdid = 568894 then obsvalue  end) erCount,
	max(case  when hdid = 167206 then obsvalue  end) EducCpsServices,
	max(case  when hdid = 200228 then obsvalue  end) ApptSch,
	max(case  when hdid = 1000086 then obsvalue  end) DateAppt,
	max(case  when hdid = 214274 then obsvalue  end) NoApptReason,
	max(case  when hdid = 77027 then obsvalue  end) NoApptReason2,
	max(case  when hdid = 211557 then obsvalue  end) ApptCareCoord,
	max(case  when hdid = 574873 then obsvalue  end) CpsSentToER,
	max(case  when hdid = 137288 then obsvalue  end) CallAttempt,
	max(case  when hdid = 15500029 then obsvalue  end) Letter,
	max(case  when hdid = 54797 then obsvalue  end) [Caller],

	max(case  when hdid = 3227 then obsvalue  end) [MoreThanOneERInDay],
	max(case  when hdid = 38688 then obsvalue  end) [TotalERInOneDay]
into #obs_pivot
from [cpssql].centricityps.dbo.obs
	left join CpsWarehouse.cps_visits.Document doc on doc.sdid = obs.sdid
	left join CpsWarehouse.cps_all.PatientProfile pp on pp.pid = obs.pid
	--left join olap_sql.CpsWarehouse.cps_all.DoctorFacility df on obs.pubuser = df.pvid
where hdid in (96267,360332, 6292, 114070, 8752, 6287, 166846,
				10400002,4562,568894,167206,200228,1000086,214274,44688,78599,137288,574873,
				77027,211557,15500029,54797,
				3227,38688) 
	and doc.SignStatus = 'S' /*only signed docs*/
	and doc.DocType not in (6,1,24,3) /*internal other(6) and phone note(3) is for care coordinators, exclude office visits(1) and error(24)*/
	and pp.last not in ('tests', 'test')
	and doc.db_Create_Date > @DocCreatedCutoffDate
group by pp.PID, OBSDATE, doc.SDID,doc.XID,doc.DocAbbr, pp.PatientID,doc.db_Create_Date,doc.Summary,obs.pubuser, doc.VisDocID, doc.Facility, doc.ClinicalDate
;

/**#obs_cleaned_up:
 - fix bad admitdate, dischargedate 
 - convert all dates from string to date
 - standardize ER and hospital names
 - combine to fields for no appt reason
 - combine sdid and xid to create xsdid

 - if admit & discharge date before 2014, default it to null
 ER vs hospital
 - if admit date - discharge date > 2 then hospital (0)
 - if summary contains hosp then hosptial (0)
 - if summary contains ER, ED, emergency, or er@ then ER(1)
 - not sure (-1) 

select * from #obs_pivot						--14471
select * from #obs_cleaned_up	order by er				--14471
****************************************************/
--	declare @DocCreatedCutoffDate date = '2017-01-01';
--	declare @AdmitDateCutoff date = dateadd(day, -30, @DocCreatedCutoffDate)
drop table if exists #obs_cleaned_up
;with u as (
	select 
		PID, patientid, SDID, XID, 
		DocAbbr, convert(date,ObsDate) ObsDate, Summary, db_Create_Date, ClinicalDate, VisDocID,Facility, 
		case 
			when summary like '%Hosp%' then 0
			when summary like '%ER%' 
				or summary like '%ED%' 
				or summary like '%emergency%' 
				or summary like 'er@%' 
			then 1
			else -1
		end ER,
		admitDate admitUnclean, 
		convert(date, case 
			when admitDate = '01/13/2001' then '01/13/2016'
			when admitDate = '09/01/2006' then '09/01/2016'
			when admitDate = '07/31/2006' then '07/31/2016'
			when isdate(admitDate) = 1 then admitDate
			when admitDate in ('.','3/') then null
			when admitDate = '4/417' then '04/04/2017'
			when admitDate = '5/12/816' then '05/12/2016'
			when admitDate = '10/18/117' then '10/18/2017'
			when admitDate = '1015/17' then '10/15/2017'
			when admitDate = '10/09/214' then '10/09/2014'
			when admitDate = '1/22/161' then '01/22/2016'
			when admitDate = '2/5/118' then '02/5/2018'
			when admitdate = '3/12' then '03/12/2018'
			when admitDate = '710/16' then '07/10/2016'
			when admitDate = '8/16' then '08/16/2017'
			when admitDate = '1/181/15' then '01/18/2015'
			when admitDate = '3/7/173' then '03/07/2017'
		else null end) admitDate, 
		admitTime,
		dischargeDate dischargeUnclean,
		convert(date, case 
			when dischargeDate = '08/22/2106' then '08/22/2016'
			when dischargeDate = '09/13/2001' then '09/13/2016'
			when isdate(dischargeDate) = 1  then dischargeDate
			when dischargeDate = '10/1115' then '10/11/2015'
			when dischargeDate = '0209/15' then '02/09/2015'
			when dischargeDate = '11/3/156' then '11/3/2015'
			when dischargeDate = '7/1915' then '07/19/2015'
			when dischargeDate = '8/20/115' then '08/20/2015'
			when dischargeDate = '02/2318' then '02/23/2018'
			when dischargeDate = '99/22/15' then '09/22/2015'
			when dischargeDate = '6/27/145' then '06/27/2015'
			when dischargeDate = '12/11/125' then '12/11/2015'
			when dischargeDate = '12/1615' then '12/16/2015'
			when dischargeDate = '1214/15' then '12/14/2015'
			when dischargeDate = '12/11/' then '12/11/2016'
			when dischargeDate = '8/1217' then '08/12/2017'
			when dischargeDate = '9/222/17' then '09/22/2017'
			when dischargeDate = '10/30/201' then '10/30/2017'
			when dischargeDate = '83/15' then '08/03/2015'
			when dischargeDate = '218/18' then '02/18/2018'
			when dischargeDate = '11/717' then '11/7/2017'
			when dischargeDate = '70/7/16' then '10/07/2016'
			when dischargeDate = '1/2918' then '01/29/2018'
			when dischargeDate = '2/717' then '02/07/2017'
			when dischargeDate = '2/2017' then '02/20/2017'
			when dischargeDate = '9/2015' then '09/20/2015'
		else null end) dischargeDate,
		case 
			when ER in ('Castle','Castle Medical','Castle Medical Cenetr','Castle Medical Center') then 'Castle'
			when ER in ('kapiloan women and children hospital','Kapiolani Medical Center','Kapiolani Medical Center for Women & Children','Kapiolani Womens and Children','KMC','KMCWC') then 'KMC'
			when (ER like '%queen%' or ER like '%QMC%') and ER like '%west%' then 'QMC West'
			when ER like '%queen%' or ER like '%QMC%' then 'QMC'
			when ER like '%straub%' or ER like 'Struab%' or er = 'sta' then 'Straub'
			when ER like 'Wahiawa%' then 'Wahiawa'
			when ER like 'Pali%' then 'Pali Momi'
			when ER like 'Kuakini%' then 'Kuakini'
			when ER in ('HPH' , 'Hawaii Pacific Health') then 'HPH'
			when ER like 'Urgent%' then 'Urgent Care'
			when ER like 'Waianae%' then 'Waianae'
			when ER like 'UCERA%' then 'UCERA'

			else ER
		end ER_Name,
		case 
			when Hospital in ('Castle','Castle Medical','Castle Medical Cenetr','Castle Medical Center') then 'Castle'
			when Hospital in ('kapiloan women and children hospital','Kapiolani Medical Center','Kapiolani Medical Center for Women & Children','Kapiolani Womens and Children','KMC','KMCWC') then 'KMC'
			when (Hospital like '%queen%' or Hospital like '%QMC%') and Hospital like '%west%' then 'QMC West'
			when Hospital like '%queen%' or Hospital like '%QMC%' then 'QMC'
			when Hospital like '%straub%' or Hospital like 'Struab%' or hospital = 'sta' then 'Straub'
			when Hospital like 'Wahiawa%' then 'Wahiawa'
			when Hospital like 'Pali%' then 'Pali Momi'
			when Hospital like 'Kuakini%' then 'Kuakini'
			when Hospital in ('HPH' , 'Hawaii Pacific Health') then 'HPH'
			when Hospital like 'Urgent%' then 'Urgent Care'
			when Hospital like 'Waianae%' then 'Waianae'
			when Hospital like 'UCERA%' then 'UCERA'

			else Hospital
		end Hospital_Name,
		admitDX,
		Q1, Q2, Q3, Q4, Q5,
		erCount,
		EducCpsServices,
		ApptSch,DateAppt, NoApptReason, NoApptReason2,
		ApptCareCoord, Letter, DocSigned, 
		CpsSentToER, 
		[Caller], 
		case 
		when CallAttempt = 'First Call' or CallAttempt = 'First Attempt' then 'First'
		when CallAttempt = 'Second Attempt' or CallAttempt = 'Second Call' then 'Second'
		when CallAttempt = 'Third Attempt' then 'Third'
		when CallAttempt is null then null
		when CallAttempt = 'Already Scheduled' then 'Scheduled'
		when CallAttempt = 'Already Seen' then 'Seen'
	end CallAttempt,
	MoreThanOneERInDay, TotalERInOneDay
	from #obs_pivot
)
	select 1 countAsFollowup,  
		PID, patientid, SDID, XID, 
		case when XID != 1000000000000000000 then XID else SDID end XSDID, 
		DocAbbr, db_Create_Date, ClinicalDate, VisDocID, Summary, DocSigned, Facility, 
		case 
			when datediff(day,admitDate,dischargeDate) > 2 then 0
			else ER 
		end ER,
		case when admitDate < @AdmitDateCutoff then null else admitDate end admitDate, 
		admitTime,
		case when dischargeDate < @AdmitDateCutoff then null else dischargeDate end dischargeDate,
		ER_Name, Hospital_Name,admitDX,
		Q1, Q2, Q3, Q4, Q5,
		erCount,
		EducCpsServices as Education,
		ApptSch,
		convert(date,case
			when isdate(DateAppt) = 1 or DateAppt is null then DateAppt 
			when DateAppt = '7/1615' then  '07/16/2015'
			when DateAppt = '12/16/1409' then  '12/16/2014'
		else null end) DateAppt,
		case 
			when NoApptReason is null and NoApptReason2 is null then null
			when NoApptReason is null then NoApptReason2
			when NoApptReason2 is null then NoApptReason
			else NoApptReason + ', ' + NoApptReason2
		end NoApptReason,
		ApptCareCoord, CpsSentToER, CallAttempt, Letter, [Caller],
	MoreThanOneERInDay, convert(int,TotalERInOneDay) TotalERInOneDay
	into #obs_cleaned_up
	from u
;


/*Hospital scans - include unsigne
	doctype: 11 (hospital)
	extID in document table has to be
		1538307085850730	DocumentManagement
		1538307086350730	DocumentManagement-AIDS
		1538307086700730	DocumentManagementLab
	clinical date --> discharge date since 2017
	summary needs discharge or D/C

	merge hospital report if clinical date and PID is same
	use only the last scanned info
	affects: visDocID, SDID, Summary, DocSignedUser, Facility

	ER bit 0
******************************************************/

--	declare @DocCreatedCutoffDate date = '2017-01-01';
drop table if exists #hospital_scans;
; with hospital_scan as (
	select 
		doc.pid PID, pp.patientID, doc.sdid SDID, doc.xid XID, 
		case when XID != 1000000000000000000 then XID else SDID end XSDID,
		'Hosp_Scan' DocAbbr,
		convert(date,doc.db_create_date) db_create_date, fxn.ClinicalDateToDate(clinicalDate) ClinicalDate,
		doc.VisDocID VisDocID, doc.Summary Summary,
		isnull(doc.PubUser,0) as DocSigned,  loc.Facility,
		rowNum = row_number() over( partition by doc.PID, clinicalDate order by db_create_date desc)
	from [cpssql].centricityPS.dbo.document doc
		inner join cps_all.Location loc on loc.locID = doc.locofcare
		inner join  cps_all.patientProfile pp on pp.pid = doc.pid
	where 
		/*and hospital (11)  with extID for scanned hospital rpt*/
		doc.extID in (1538307085850730,1538307086350730,1538307086700730)
		and doc.doctype = 11
		and db_create_date > @DocCreatedCutoffDate
		and ( 
				doc.summary  like '%discharge%'
				or doc.summary  like '%D/C%'
			)
		and pp.TestPatient = 0
)
	select 0 countAsFollowup,  
		h1.PID, h1.PatientID, h1.sdid, h1.xid, h1.XSDID, h1.DocAbbr, h1.db_create_date, h1.ClinicalDate, h1.visDocID, 
		h1.Summary, h1.DocSigned, h1.Facility, 0 ER,
		convert(date,null) admitDate, convert(varchar(2000), null) admitTime, h1.ClinicalDate dischargeDate, 
		convert(varchar(2000), null) ER_Name, convert(varchar(2000), null) Hospital_Name, convert(varchar(2000), null) admitDX, 
		convert(varchar(2000), null) Q1, convert(varchar(2000), null) Q2, convert(varchar(2000), null) Q3, 
		convert(varchar(2000), null) Q4, convert(varchar(2000), null) Q5, 
		convert(varchar(2000), null) erCount, convert(varchar(2000), null) Education, convert(varchar(2000), null) ApptSch, 
		convert(date,null) DateAppt, convert(varchar(2000), null) NoApptReason,
		convert(varchar(2000), null) ApptCareCoord, convert(varchar(2000), null) CpsSentToER, convert(varchar(2000), null) CallAttempt, 
		convert(varchar(2000), null) Letter, convert(varchar(2000), null) [Caller], 
		convert(varchar(50), null) MoreThanOneER,
		convert(int, null) TotalER
	into #hospital_scans
	from  hospital_scan h1
	where h1.rowNum = 1



/*CCDA from HPH - include unsigned
	document with sourcename not blank
	document with clinical date --> discharge date after 2017
	search for word ER, ED and Emergency for ER= 1
	hosp or hospital for Er = 0
	else null
	if ER = 1 then admit and discharge date same as clinical date
	for ER = 0 only discharge date = clinical date


	#ccda combine shredded data with temp ccda data

*********************************/
--	declare @DocCreatedCutoffDate date = '2017-01-01';

drop table if exists #ccda_import
;with ccda_import as (
	select 
		doc.pid PID, pp.patientID, doc.sdid SDID, doc.xid XID, 
		case when XID != 1000000000000000000 then doc.XID else doc.SDID end XSDID,
		'CCDA' DocAbbr,
		convert(date,doc.db_create_date) db_create_date, fxn.ClinicalDateToDate(clinicalDate) ClinicalDate,
		doc.VisDocID VisDocID, doc.Summary Summary,
		isnull(doc.PubUser,0) as DocSigned,  loc.Facility,
		case 
			when doc.doctype = 15 then 0
			when doc.doctype = 26 then 1
			when summary like '%Hosp%' then 0
			when summary like '%ER%' 
				or summary like '%ED%' 
				or summary like '%emergency%' 
				or summary like 'er@%' 
			then 1
			else -1
		end ER
		
	from [cpssql].centricityPS.dbo.document doc
		inner join cps_all.Location loc on loc.locID = doc.locofcare
		inner join cps_all.patientProfile pp on pp.pid = doc.pid
		
	where 
			/*SourceName: Captures the source (sending provider) from whom or where the external document(CCDA) has been imported. */
			doc.sourcename is not null 
		and db_create_date > @DocCreatedCutoffDate
		and doc.doctype in (15,26,1542266325850610) /*only hospital, ER, comm notes*/
		and pp.last not in ('tests', 'test')

) --select * from ccda_import
 select 0 countAsFollowup,
		h1.PID, h1.PatientID, h1.sdid, h1.xid, h1.XSDID, h1.DocAbbr, h1.db_create_date, h1.ClinicalDate, h1.visDocID, 
		h1.Summary, h1.DocSigned, h1.Facility, 
		ER,
		
		case when ER = 1 then h1.ClinicalDate end admitDate, 
		convert(varchar(2000), null) admitTime, 
		h1.ClinicalDate dischargeDate, 
		convert(varchar(2000), null) ER_Name, convert(varchar(2000), null) Hospital_Name, convert(varchar(2000), null) admitDX, 
		convert(varchar(2000), null) Q1, convert(varchar(2000), null) Q2, convert(varchar(2000), null) Q3, 
		convert(varchar(2000), null) Q4, convert(varchar(2000), null) Q5, 
		convert(varchar(2000), null) erCount, convert(varchar(2000), null) Education, convert(varchar(2000), null) ApptSch, 
		convert(date,null) DateAppt, convert(varchar(2000), null) NoApptReason,
		convert(varchar(2000), null) ApptCareCoord, convert(varchar(2000), null) CpsSentToER, convert(varchar(2000), null) CallAttempt, 
		convert(varchar(2000), null) Letter, convert(varchar(2000), null) [Caller],
		convert(varchar(50), null) MoreThanOneER,
		convert(int, null) TotalER
	into #ccda_import
	from  ccda_import h1
	where er != -1

	

/*ER Scan
	doctype: 26 (ER)
	extID in document table has to be
		1538307085850730	DocumentManagement
		1538307086350730	DocumentManagement-AIDS
		1538307086700730	DocumentManagementLab
	remove any summary with x-ray
	admit date and discharge date same as clinical date.

	merge hospital report if clinical date and PID is same
	use only the last scanned info
	affects: visDocID, SDID, Summary, DocSignedUser, Facility
******************************/
--	declare @DocCreatedCutoffDate date = '2017-01-01';
drop table if exists #ER_Scans;
;with er_scans as 
(
	select 
		doc.pid PID, pp.patientID, doc.sdid SDID, doc.xid XID, 
		case when XID != 1000000000000000000 then XID else SDID end XSDID,
		'ER_Scan' DocAbbr, 
		convert(date,doc.db_create_date) db_create_date, fxn.ClinicalDateToDate(clinicalDate) ClinicalDate,
		doc.VisDocID VisDocID, doc.Summary Summary,
		isnull(doc.PubUser,0) as DocSigned,  loc.Facility,
		rowNum = row_number() over( partition by doc.PID, clinicalDate order by db_create_date desc)
	from [cpssql].centricityPS.dbo.document doc
		inner join cps_all.Location loc on loc.locID = doc.locofcare
		inner join  cps_all.patientProfile pp on pp.pid = doc.pid
		left join [cpssql].CentricityPS.dbo.doctypes dt on dt.dtid = doc.doctype
	where 
		/*DocType ER (26) with extID for scanned ER*/
		doc.extID in (1538307085850730,1538307086350730,1538307086700730) 
		and doc.doctype = 26
		and doc.db_create_date > @DocCreatedCutoffDate
		and doc.summary not like 'x-ray%'
		and doc.summary not like 'x ray%'
		and pp.last not in ('tests', 'test')
)
 select 0 countAsFollowup,
		h1.PID, h1.PatientID, h1.sdid, h1.xid, h1.XSDID, h1.DocAbbr, h1.db_create_date, h1.ClinicalDate, h1.visDocID, 
		h1.Summary, h1.DocSigned, h1.Facility, 
		1 ER,
		
		h1.ClinicalDate admitDate, 
		convert(varchar(2000), null) admitTime, 
		h1.ClinicalDate dischargeDate, 
		convert(varchar(2000), null) ER_Name, convert(varchar(2000), null) Hospital_Name, convert(varchar(2000), null) admitDX, 
		convert(varchar(2000), null) Q1, convert(varchar(2000), null) Q2, convert(varchar(2000), null) Q3, 
		convert(varchar(2000), null) Q4, convert(varchar(2000), null) Q5, 
		convert(varchar(2000), null) erCount, convert(varchar(2000), null) Education, convert(varchar(2000), null) ApptSch, 
		convert(date,null) DateAppt, convert(varchar(2000), null) NoApptReason,
		convert(varchar(2000), null) ApptCareCoord, convert(varchar(2000), null) CpsSentToER, convert(varchar(2000), null) CallAttempt, 
		convert(varchar(2000), null) Letter, convert(varchar(2000), null) [Caller],
		convert(varchar(50), null) MoreThanOneER,
		convert(int, null) TotalER
	into #ER_Scans
	from  er_scans h1
	where rowNum = 1



/**#allDocs: union obs_doc, hosp_scan, er_scan and ccda

	final doctype
		Hosp_Scan
		ComNote
		ER_Scan
		CCDA
		ER Rpt
		Append

select * from #obs_cleaned_up 	-- 14515
select * from #hospital_scans	-- 6870
select * from #ccda_import		-- 3669
select * from #ER_Scans			-- 22324
****************************************************/
drop table if exists #allDocs;
select countAsFollowup,
	PID, patientid, SDID, XID, XSDID, DocAbbr, db_Create_Date, ClinicalDate, 
	VisDocID, Summary, DocSigned, Facility, ER, 
	case when ER = 1 and admitDate is null then dischargeDate else admitDate end admitDate, 
	admitTime, 
	case when ER = 1 and dischargeDate is null then admitDate else dischargeDate end dischargeDate, 
	ER_Name, Hospital_Name, 
	case 
		when ER_Name = Hospital_Name then Hospital_Name
		when ER_Name is null then Hospital_Name
		when Hospital_Name is null then ER_Name
	end ER_Hosp_Name,
	admitDX, Q1, Q2, Q3, Q4, Q5,
	erCount, Education, ApptSch, DateAppt, NoApptReason, ApptCareCoord, 
	CpsSentToER, CallAttempt, Letter, Caller, MoreThanOneERInDay, TotalERInOneDay

into #allDocs
from 
(
	/*from obs: form filled out*/
	select  * from #obs_cleaned_up
	union all
	/*from hospital report scanned*/
	select * from #hospital_scans
	union all
	/*CCDA from HPH*/
	select * from #ccda_import
	union all
	/**ER scans**/
	select * from #ER_Scans
) u

END


/*****GET DATA FROM SUMMARY*********
select * from #dateFromSummary where pid =1737388065725100
select * from #dx_from_summary
select * from #allDocs_withSummary
**********************************************************************************************/

BEGIN 

/*********get date from summary
	pattern matching --> between strings "date:" and "CC:"
		could be date or could be admitDate - dischargeDate
		if it is straight up date and discharge is blank then use it as discharge date
			moreover if admitdate is blank and it is ER then use same date for ER admitDate
		if both admitDate and Discharge Date in summary
			1.  break it up by ' - ': with spaces since some people use mm/dd/yy and others use mm-dd-yy
			2. break '-' just in case there was no space between admitDate and dischargeDate
				first part if date is admitDate
				second part if date is dischargeDate
			3. some people use mm/dd: concatenate last 2 digit of clinicaDate year and if it is date then use as admit
				

****************************************************/


drop table if exists #dateFromSummary;
;with get_one_date_like_structure_from_summary as (
	select 
		PID, SDID,Summary, ER, ClinicalDate,AdmitDate,DischargeDate,
		case 
			when charindex( 'Date:',Summary) > 0 and charindex( 'C/C:',Summary) > 0 and (admitDate is null or dischargeDate is null)
				then ltrim(rtrim(substring(Summary, charindex( 'Date:',Summary) + 5 , charindex( 'C/C:',Summary) - charindex( 'Date:',Summary) -5 ) ))
		end Summary_Date_Raw
	from #allDocs
) 
, get_two_date_like_structure_from_summary as (
	select 
		PID, SDID ,Summary, ER, ClinicalDate,
		case 
			when isdate(summary_date_raw) = 1 and ER = 1 and admitDate is null 
			then convert(date, Summary_Date_Raw)
			else admitDate
		end AdmitDate,
		case 
			when isdate(summary_date_raw) = 1 and DischargeDate is null 
			then convert(date, Summary_Date_Raw)
			else DischargeDate
		end DischargeDate,
		summary_date_raw,
		case 
			when CHARINDEX( ' - ', summary_date_raw) > 0 and (admitDate is null or dischargeDate is null)
				then ltrim(rtrim( substring( summary_date_raw, 1, CHARINDEX( ' - ', summary_date_raw) ) ))
			when CHARINDEX( '-', summary_date_raw) > 0 and (admitDate is null or dischargeDate is null)
				then ltrim(rtrim( substring( summary_date_raw, 1, CHARINDEX( '-', summary_date_raw) -1 ) ))
		end admit_from_Summary,
		case 
			when CHARINDEX( ' - ', summary_date_raw) > 0 and (admitDate is null or dischargeDate is null)
				then ltrim(rtrim( substring( summary_date_raw, CHARINDEX( ' - ', summary_date_raw) + 3,  len(summary_date_raw) - CHARINDEX( ' - ', summary_date_raw) ) ))
			when CHARINDEX( '-', summary_date_raw) > 0 and (admitDate is null or dischargeDate is null)
				then ltrim(rtrim( substring( summary_date_raw, CHARINDEX( '-', summary_date_raw) + 1,  len(summary_date_raw) - CHARINDEX( '-', summary_date_raw) ) ))
		end discharge_from_Summary
	
	from get_one_date_like_structure_from_summary 
) 
select 
	PID, SDID,Summary, ER, ClinicalDate,
	case 
		when isdate(admit_from_Summary) = 1 and AdmitDate is null
			then convert(date, admit_from_Summary)
		when isdate( replace(admit_from_Summary + '/' + convert(varchar(2), year(clinicalDate) % 100) , '//' ,'/') ) = 1 and AdmitDate is null
			then convert(date, replace( (admit_from_Summary + '/' + convert(varchar(2), year(clinicalDate) % 100) ), '//' ,'/') )
		else AdmitDate
	end AdmitDate,

	case 
		when isdate(discharge_from_Summary) = 1 and DischargeDate is null
			then convert(date, discharge_from_Summary)
		else DischargeDate
	end DischargeDate
into #dateFromSummary
from get_two_date_like_structure_from_summary 
;
--select * from get_two_date_like_structure_from_summary where PID = 1737388065725100 and ClinicalDate = '2019-06-13'

/**************get ER diag, Name of hosp
					anything after cc: in summary is diag
					for scanned docs right after :
					anything resembling hospital names are ER_Hospital_name
					use summary info only if document missing from documentation


***************************************************/

drop table if exists #dx_from_summary;
with dx_name_from_summary as (
	select
		PID, SDID,Summary, ClinicalDate,
			case 
				when CHARINDEX( 'c/c:', Summary) > 0
					then ltrim(rtrim(SUBSTRING(summary,  charindex( 'C/C:',Summary) + 4, len(summary) -  charindex( 'C/C:',Summary)) ))
				when DocAbbr in ('ER_Scan','Hosp_Scan') and CHARINDEX( ':', Summary) > 0
					then ltrim(rtrim(SUBSTRING(summary, CHARINDEX( ':', Summary) + 1, len(summary) - CHARINDEX( ':', Summary) ) ))
			end Summary_admitDx_Raw,
			DocAbbr,
			admitDx,
			case 
				when Summary like 'Castle%' then 'Castle'
				when Summary like 'Kapiolani%'then 'KMC'
				when Summary like 'KMC%'then 'KMC'
				when (summary like '%queen%' or summary like '%QMC%') and summary like '%west%' then 'QMC West'
				when summary like '%queen%' or summary like '%QMC%' then 'QMC'
				when summary like 'straub%' then 'Straub'
				when summary like 'Wahiawa%' then 'Wahiawa'
				when summary like 'Pali%' then 'Pali Momi'
				when summary like 'Kuakini%' then 'Kuakini'
				when summary like 'HPH%' then 'HPH'
				when summary like 'Urgent%' then 'Urgent Care'
				when summary like 'Waianae%' then 'Waianae'
				when summary like 'UCERA%' then 'UCERA'
				when summary like 'Wilcox%' then 'Wilcox'
				when summary like 'Tripler%' then 'Tripler'
			end Summary_ER_Name,
			ER_Hosp_Name
	from #allDocs
)
	select 
		PID, SDID,Summary, ClinicalDate,
		case 
			when admitDx is null then Summary_admitDx_Raw
			else admitDx
		end admitDx,
		case 
			when ER_Hosp_Name is null then Summary_ER_Name
			else ER_Hosp_Name
		end ER_Hosp_Name
	into #dx_from_summary
	from dx_name_from_summary


/** incorporate data obtained from summary
		first with admitDate and dischargeDate
		then add admit DX and ER/Hospital Name

***********************************/

drop table if exists #allDocs_withSummary;
select d.countAsFollowup,
	d.PID, patientid, d.SDID, XID, XSDID, DocAbbr, db_Create_Date, d.ClinicalDate, 
	VisDocID, d.Summary, DocSigned, Facility as [DocumentFacility], 
	case 
		when datediff(day,s.admitDate,s.dischargeDate) >= 2 
			then 0
		when datediff(day,s.admitDate,s.dischargeDate) < 1
			then 1
		when d.ER = -1 and (d.summary like 'Inpatient%' or d.summary like 'Adm%') 
			then 0
		else d.ER 
	end ER,
	s.admitDate, 
	admitTime, 
	s.dischargeDate, 
	dx.ER_Hosp_Name, dx.admitDX, Q1, Q2, Q3, Q4, Q5,
	erCount, Education, ApptSch ApptScheduled, DateAppt ApptDateInForm, NoApptReason, ApptCareCoord, 
	CpsSentToER, CallAttempt, Letter, Caller, MoreThanOneERInDay, TotalERInOneDay
into #allDocs_withSummary
from #allDocs d
	left join #dateFromSummary s on d.pid = s.pid and d.sdid = s.SDID
	left join #dx_from_summary dx on d.pid = dx.pid and d.sdid = dx.SDID

END

/*****standardize er / hospital by discharge date and xsdid for appends
select * from #standardize_basic_info
select * from #standardize_xsdid
*******************************************************************************************************/
BEGIN

/************#standardize_basic_info
basic info include dischargeDate, admitDate, admitDX, ER, ER_Hosp_Name
	* for scan doc and CCDA - get from summary when possible
partition row by PID and XSDID for appended documents
Standarization Discharge Date
	* use clinical date off ccda as ground truth when ccda is available
	* use clinical date of scaned document - medical record scan more reliable
	* if both scan and ccda not available - use date from last append
		* sometime append has different dates
		* could be different ER or it could be user error
		* assuming user error in previous append
		* hopefully last append has correct data
		* if last is blank then do second to last and so on
*********************/
drop table if exists #standardize_basic_info;
with order_by_xsdid as (
	select 
		PId, DischargeDate, countAsFollowup, 
		AdmitDate, admitDx, ER, ER_Hosp_Name,
		clinicalDate, Summary, DocAbbr, XSDID, SDID,VisDocID, CallAttempt, db_Create_Date,  letter, 
		rowNum_append = ROW_NUMBER() over(partition by PId, XSDID order by db_create_date, visdocID)
	from #allDocs_withSummary
)
, get_discharge_from_append as (
	select PID, XSDID ,

		max(case when DocAbbr = 'CCDA' and DischargeDate is not null then DischargeDate end) dischargeDateCCDA,
		max(case when DocAbbr = 'ER_Scan' and DischargeDate is not null then DischargeDate end) dischargeDate_ER_Scan,
		max(case when DocAbbr = 'Hosp_Scan' and DischargeDate is not null then DischargeDate end) dischargeDate_Hosp_Scan,
		max(case when rowNum_append = 1  then DischargeDate end) dischargeDate1,
		max(case when rowNum_append = 2 then DischargeDate end) dischargeDate2,
		max(case when rowNum_append = 3 then DischargeDate end) dischargeDate3,
		max(case when rowNum_append = 4 then DischargeDate end) dischargeDate4,
		max(case when rowNum_append = 5 then DischargeDate end) dischargeDate5,
		max(case when rowNum_append = 6 then DischargeDate end) dischargeDate6,
		max(case when rowNum_append = 7 then DischargeDate end) dischargeDate7,
		max(case when rowNum_append = 8 then DischargeDate end) dischargeDate8,
		max(case when rowNum_append = 9 then DischargeDate end) dischargeDate9
	from order_by_xsdid
	group by PID, XSDID
	
) 
	select 
		d.PId, d.XSDID, SDID,countAsFollowup, clinicalDate, Summary, DocAbbr, VisDocID, CallAttempt, db_Create_Date,  letter, 
		AdmitDate, AdmitDx, ER, ER_Hosp_Name,
		case 
			when dischargeDateCCDA is not null then dischargeDateCCDA
			when dischargeDate_ER_Scan is not null then dischargeDate_ER_Scan
			when dischargeDate_Hosp_Scan is not null then dischargeDate_Hosp_Scan
			when dischargeDate9 is not null then dischargeDate9
			when dischargeDate8 is not null then dischargeDate8
			when dischargeDate7 is not null then dischargeDate7
			when dischargeDate6 is not null then dischargeDate6
			when dischargeDate5 is not null then dischargeDate5
			when dischargeDate4 is not null then dischargeDate4
			when dischargeDate3 is not null then dischargeDate3
			when dischargeDate2 is not null then dischargeDate2
			when dischargeDate1 is not null then dischargeDate1
		end DischargeDate
	into #standardize_basic_info
	from order_by_xsdid d
		left join get_discharge_from_append f on f.pid = d.pid and f.xsdid = d.xsdid;


/************#standardize_xsdid
use standardized discharge date to partition further and standardize xsdid
	one ER follow up could be append to CCD 
	while the different user might be start new comNote
Standardize
1. XSDID --> new XSDID
	* first xsdid as primary,
	* ccda or scan or comNote
	* sometime comNote created before scan
2. AdmitDate, ER, ER_Hosp_Name
	* summary from ccda and scan doc cannot be taken as ground truth
	* start from the last append and continue forward like last option for discharge
3. AdmitDx
	* same as 2 but look for something other than order
	* slightly longer case statement
*********************/
drop table if exists #standardize_xsdid;
with order_by_discharge as (
	select 
		countAsFollowup,PId, XSDID, SDID, clinicalDate, DischargeDate, 
		AdmitDate, AdmitDx, ER, ER_Hosp_Name,
		Summary, DocAbbr, VisDocID, CallAttempt, db_Create_Date,  letter,
		rowNum_discharge = ROW_NUMBER() over(partition by PId, dischargedate order by db_create_date, visdocID)
	from #standardize_basic_info
)
,pivot_xsdid as (
	select 
		PId, DischargeDate, 
		max(case when rowNum_discharge = 1 then XSDID end) XSDID1,
		max(case when rowNum_discharge = 2 then XSDID end) XSDID2,
		max(case when rowNum_discharge = 3 then XSDID end) XSDID3,
		max(case when rowNum_discharge = 4 then XSDID end) XSDID4,
		max(case when rowNum_discharge = 5 then XSDID end) XSDID5,
		max(case when rowNum_discharge = 6 then XSDID end) XSDID6,
		max(case when rowNum_discharge = 7 then XSDID end) XSDID7,
		max(case when rowNum_discharge = 8 then XSDID end) XSDID8,
		max(case when rowNum_discharge = 9 then XSDID end) XSDID9,

		max(case when rowNum_discharge = 1  then AdmitDate end) AdmitDate1,
		max(case when rowNum_discharge = 2 then AdmitDate end) AdmitDate2,
		max(case when rowNum_discharge = 3 then AdmitDate end) AdmitDate3,
		max(case when rowNum_discharge = 4 then AdmitDate end) AdmitDate4,
		max(case when rowNum_discharge = 5 then AdmitDate end) AdmitDate5,
		max(case when rowNum_discharge = 6 then AdmitDate end) AdmitDate6,
		max(case when rowNum_discharge = 7 then AdmitDate end) AdmitDate7,
		max(case when rowNum_discharge = 8 then AdmitDate end) AdmitDate8,
		max(case when rowNum_discharge = 9 then AdmitDate end) AdmitDate9,

		max(case when rowNum_discharge = 1  then AdmitDx end) AdmitDx1,
		max(case when rowNum_discharge = 2 then AdmitDx end) AdmitDx2,
		max(case when rowNum_discharge = 3 then AdmitDx end) AdmitDx3,
		max(case when rowNum_discharge = 4 then AdmitDx end) AdmitDx4,
		max(case when rowNum_discharge = 5 then AdmitDx end) AdmitDx5,
		max(case when rowNum_discharge = 6 then AdmitDx end) AdmitDx6,
		max(case when rowNum_discharge = 7 then AdmitDx end) AdmitDx7,
		max(case when rowNum_discharge = 8 then AdmitDx end) AdmitDx8,
		max(case when rowNum_discharge = 9 then AdmitDx end) AdmitDx9,

		max(case when rowNum_discharge = 1  then ER end) ER1,
		max(case when rowNum_discharge = 2 then ER end) ER2,
		max(case when rowNum_discharge = 3 then ER end) ER3,
		max(case when rowNum_discharge = 4 then ER end) ER4,
		max(case when rowNum_discharge = 5 then ER end) ER5,
		max(case when rowNum_discharge = 6 then ER end) ER6,
		max(case when rowNum_discharge = 7 then ER end) ER7,
		max(case when rowNum_discharge = 8 then ER end) ER8,
		max(case when rowNum_discharge = 9 then ER end) ER9,

		max(case when rowNum_discharge = 1  then ER_Hosp_Name end) ER_Hosp_Name1,
		max(case when rowNum_discharge = 2 then ER_Hosp_Name end) ER_Hosp_Name2,
		max(case when rowNum_discharge = 3 then ER_Hosp_Name end) ER_Hosp_Name3,
		max(case when rowNum_discharge = 4 then ER_Hosp_Name end) ER_Hosp_Name4,
		max(case when rowNum_discharge = 5 then ER_Hosp_Name end) ER_Hosp_Name5,
		max(case when rowNum_discharge = 6 then ER_Hosp_Name end) ER_Hosp_Name6,
		max(case when rowNum_discharge = 7 then ER_Hosp_Name end) ER_Hosp_Name7,
		max(case when rowNum_discharge = 8 then ER_Hosp_Name end) ER_Hosp_Name8,
		max(case when rowNum_discharge = 9 then ER_Hosp_Name end) ER_Hosp_Name9
	from order_by_discharge
	group by PID, DischargeDate
) 
	select 
		countAsFollowup,o.PId, clinicalDate, o.DischargeDate, 
		Summary, DocAbbr, VisDocID, CallAttempt, db_Create_Date,  letter,XSDID, SDID,
		case 
			when XSDID1 is not null then XSDID1
			when XSDID2 is not null then XSDID2
			when XSDID3 is not null then XSDID3
			when XSDID4 is not null then XSDID4
			when XSDID5 is not null then XSDID5
			when XSDID6 is not null then XSDID6
			when XSDID7 is not null then XSDID7
			when XSDID8 is not null then XSDID8
			when XSDID9 is not null then XSDID9
			else XSDID
		end newXSDID,

		case 
			when AdmitDate9 is not null then AdmitDate9
			when AdmitDate8 is not null then AdmitDate8
			when AdmitDate7 is not null then AdmitDate7
			when AdmitDate6 is not null then AdmitDate6
			when AdmitDate5 is not null then AdmitDate5
			when AdmitDate4 is not null then AdmitDate4
			when AdmitDate3 is not null then AdmitDate3
			when AdmitDate2 is not null then AdmitDate2
			when AdmitDate1 is not null then AdmitDate1
			else AdmitDate
		end AdmitDate,

		case 
			when AdmitDx9 is not null and AdmitDx9 != 'Other' then AdmitDx9
			when AdmitDx8 is not null and AdmitDx8 != 'Other' then AdmitDx8
			when AdmitDx7 is not null and AdmitDx7 != 'Other' then AdmitDx7
			when AdmitDx6 is not null and AdmitDx6 != 'Other' then AdmitDx6
			when AdmitDx5 is not null and AdmitDx5 != 'Other' then AdmitDx5
			when AdmitDx4 is not null and AdmitDx4 != 'Other' then AdmitDx4
			when AdmitDx3 is not null and AdmitDx3 != 'Other' then AdmitDx3
			when AdmitDx2 is not null and AdmitDx2 != 'Other' then AdmitDx2
			when AdmitDx1 is not null then AdmitDx1
			when AdmitDx2 is not null then AdmitDx2
			when AdmitDx3 is not null then AdmitDx3
			when AdmitDx4 is not null then AdmitDx4
			when AdmitDx5 is not null then AdmitDx5
			when AdmitDx6 is not null then AdmitDx6
			when AdmitDx7 is not null then AdmitDx7
			when AdmitDx8 is not null then AdmitDx8
			when AdmitDx9 is not null then AdmitDx9
			else admitDx
		end AdmitDx,

		case 
			when ER9 is not null then ER9
			when ER8 is not null then ER8
			when ER7 is not null then ER7
			when ER6 is not null then ER6
			when ER5 is not null then ER5
			when ER4 is not null then ER4
			when ER3 is not null then ER3
			when ER2 is not null then ER2
			when ER1 is not null then ER1
			else ER
		end ER,

		case 
			when ER_Hosp_Name9 is not null then ER_Hosp_Name9
			when ER_Hosp_Name8 is not null then ER_Hosp_Name8
			when ER_Hosp_Name7 is not null then ER_Hosp_Name7
			when ER_Hosp_Name6 is not null then ER_Hosp_Name6
			when ER_Hosp_Name5 is not null then ER_Hosp_Name5
			when ER_Hosp_Name4 is not null then ER_Hosp_Name4
			when ER_Hosp_Name3 is not null then ER_Hosp_Name3
			when ER_Hosp_Name2 is not null then ER_Hosp_Name2
			when ER_Hosp_Name1 is not null then ER_Hosp_Name1
			else ER_Hosp_Name
		end ER_Hosp_Name
	into #standardize_xsdid
	from order_by_discharge o
		left join pivot_xsdid p on p.pid = o.pid and o.DischargeDate = p.DischargeDate
end 


/***************#distinct_ER_Visits_append_ccda
find all CCDA separately
	* multiple CCDA in one day means multiple ER in one day
	* CCDA_count
		0 = did not get ccda
		1 = first ccda for the day
		2 = second ccda for the day
find distinct discharge info by newXSDID from #standardize_xsdid
combine ccda and distinct XSDID

find distinct  by newXSDID and ccda_count
Final list of ER / hosptial
********************************/
drop table if exists #distinct_ER_Visits_append_ccda;
;with all_ccda as (
	select 
		PID, newXSDID, xs.AdmitDate, xs.DischargeDate, xs.AdmitDx, xs.ER, xs.ER_Hosp_Name, 
		ccda_count = ROW_NUMBER() over(partition by PID, newXSDID order by newXSDID desc)
	from #standardize_xsdid xs
	where xs.DocAbbr = 'ccda'
)
, combine_xsdid_ccda as (
	select 
		case when xs.pid is null then c.PID else xs.PID end PID,
		case when xs.newXSDID is null then c.newXSDID else xs.newXSDID end newXSDID,
		case when xs.DischargeDate is null then c.DischargeDate else xs.DischargeDate end DischargeDate,
		case when xs.AdmitDate is null then c.AdmitDate else xs.AdmitDate end AdmitDate,
		case when xs.AdmitDx is null then c.AdmitDx else xs.AdmitDx end AdmitDx,
		case when xs.ER is null then c.ER else xs.ER end ER,
		case when xs.ER_Hosp_Name is null then c.ER_Hosp_Name else xs.ER_Hosp_Name end ER_Hosp_Name,
		ccda_count
	from #standardize_xsdid c
		full outer join all_ccda xs on xs.newXSDID = c.newXSDID 
)
	select 
		PID, newXSDID, 
		AdmitDate, DischargeDate, AdmitDx, ER, ER_Hosp_Name,
		ccda_count, rownum
	into #distinct_ER_Visits_append_ccda
	from
	(
		select 
			PID, newXSDID, isnull(ccda_count, 0) ccda_count, 
			AdmitDate, DischargeDate, AdmitDx, ER, ER_Hosp_Name,
			rownum = ROW_NUMBER() over(partition by PID, newXSDID, ccda_count order by newXSDID ) 
		from combine_xsdid_ccda
	) x
	where rownum = 1	
	order by PID, newXSDID;


/****************clean up remaining data from form - call attempt, questions, education, noApptReason, RestofFormData
	select * from #callAttempt_Letter_date
	select * from #questions
	select * from #education
	select * from #noApptReason
	select * from #RestofFormData
	
**************************************************************/

BEGIN



/**************#callAttempt_Letter_date
partition by newly create newXSDID from #standardize_xsdid --> looking at just documents that count as call attempt
	if callAttempt is marked - only newer documents, then use it 
		* else use row number partitioned by discharge and order by visdocID
		* lowest visDocID will number as first call and so on
	if letter is marked use it for letter date
PID and newXSDID as identifier
****************************************/
drop table if exists #callAttempt_Letter_date;
with order_by_xsdid as (
	select 
		countAsFollowup, PId, XSDID, newXSDID, DocAbbr, DischargeDate, 
		AdmitDate, AdmitDx, ER, ER_Hosp_Name,
		CallAttempt, letter,clinicalDate, 
		rowNum_discharge = ROW_NUMBER() over(partition by PId, newXSDID order by db_create_date, visdocID)
	from #standardize_xsdid
	where countAsFollowup = 1
)
, callAttempt as (
	select 
		o.PID, o.newXSDID, AdmitDate, DischargeDate, AdmitDx, ER, ER_Hosp_Name, 
		max(case when o.CallAttempt = 'First' or o.rowNum_discharge = 1 then o.clinicalDate end) FirstAttempt,
		max(case when o.CallAttempt = 'Second' or o.rowNum_discharge = 2 then o.clinicalDate end) SecondAttempt,
		max(case when o.CallAttempt = 'Third' or o.rowNum_discharge = 3 then o.clinicalDate end) ThirdAttempt,
		max(case when o.rowNum_discharge = 4 then o.clinicalDate end) FourthAttempt,
		max(case when o.rowNum_discharge = 5 then o.clinicalDate end) FifthAttempt,
		max(case when o.rowNum_discharge = 6 then o.clinicalDate end) SixthAttempt,
		max(case when o.rowNum_discharge = 7 then o.clinicalDate end) SeventhAttempt,
		max(case when o.CallAttempt = 'Letter' or o.Letter = 'Yes' then o.clinicalDate end) LetterAttempt
	from order_by_xsdid o
	group by o.PID, o.newXSDID, AdmitDate, DischargeDate, AdmitDx, ER, ER_Hosp_Name
)
	select 
		PID, newXSDID, AdmitDate, DischargeDate, AdmitDx, ER, ER_Hosp_Name, 
		FirstAttempt, SecondAttempt, ThirdAttempt, FourthAttempt,
		FifthAttempt, SixthAttempt, SeventhAttempt, LetterAttempt
	into #callAttempt_Letter_date
	from callAttempt 
;


/**************#questions
partition by newly create newXSDID from #standardize_xsdid 
	use the last data first. 
	hoping last documentationb corrects previous errors
	not just appends but ComNote created separately
PID and newXSDID as identifier
****************************************/ 
drop table if exists #questions;
with questions as 
(
	select 
		stand.newXSDID, summ.PID, summ.db_Create_Date,  
		Q1 /*1. Were you admitted to the hospital? yes, no, NULL*/, 
		Q2 /*2. How long did you stay in the hospital? < 2 days, more than 10 days, other, between 3-5 days, between 6-10 days, NULL*/, 
		Q3 /*3. Are you aware that you can contact your doctor at Cps when the office is closed? yes, no, NULL*/,
		Q4 /*4. Did you contact Cps before you went to ER? 25 different options*/, 
		Q5 /*5. Were you referred to another facility? yes, no, NULL*/, 
		Q_num = ROW_NUMBER() over(partition by stand.newXSDID order by summ.db_Create_Date)
	from #allDocs_withSummary summ
		left join #standardize_xsdid stand on stand.SDID = summ.SDID
) --select distinct Q5 from questions
, pivot_qs as 
(
	select 
		PID, newXSDID, 

		max(case when Q_num = 1 then Q1 end) Q1_1,
		max(case when Q_num = 2 then Q1 end) Q1_2,
		max(case when Q_num = 3 then Q1 end) Q1_3,
		max(case when Q_num = 4 then Q1 end) Q1_4,
		max(case when Q_num = 5 then Q1 end) Q1_5,
		max(case when Q_num = 6 then Q1 end) Q1_6,
		max(case when Q_num = 7 then Q1 end) Q1_7,
		max(case when Q_num = 8 then Q1 end) Q1_8,
		max(case when Q_num = 9 then Q1 end) Q1_9,

		max(case when Q_num = 1 then Q2 end) Q2_1,
		max(case when Q_num = 2 then Q2 end) Q2_2,
		max(case when Q_num = 3 then Q2 end) Q2_3,
		max(case when Q_num = 4 then Q2 end) Q2_4,
		max(case when Q_num = 5 then Q2 end) Q2_5,
		max(case when Q_num = 6 then Q2 end) Q2_6,
		max(case when Q_num = 7 then Q2 end) Q2_7,
		max(case when Q_num = 8 then Q2 end) Q2_8,
		max(case when Q_num = 9 then Q2 end) Q2_9,

		max(case when Q_num = 1 then Q3 end) Q3_1,
		max(case when Q_num = 2 then Q3 end) Q3_2,
		max(case when Q_num = 3 then Q3 end) Q3_3,
		max(case when Q_num = 4 then Q3 end) Q3_4,
		max(case when Q_num = 5 then Q3 end) Q3_5,
		max(case when Q_num = 6 then Q3 end) Q3_6,
		max(case when Q_num = 7 then Q3 end) Q3_7,
		max(case when Q_num = 8 then Q3 end) Q3_8,
		max(case when Q_num = 9 then Q3 end) Q3_9,

		max(case when Q_num = 1 then Q4 end) Q4_1,
		max(case when Q_num = 2 then Q4 end) Q4_2,
		max(case when Q_num = 3 then Q4 end) Q4_3,
		max(case when Q_num = 4 then Q4 end) Q4_4,
		max(case when Q_num = 5 then Q4 end) Q4_5,
		max(case when Q_num = 6 then Q4 end) Q4_6,
		max(case when Q_num = 7 then Q4 end) Q4_7,
		max(case when Q_num = 8 then Q4 end) Q4_8,
		max(case when Q_num = 9 then Q4 end) Q4_9,

		max(case when Q_num = 1 then Q5 end) Q5_1,
		max(case when Q_num = 2 then Q5 end) Q5_2,
		max(case when Q_num = 3 then Q5 end) Q5_3,
		max(case when Q_num = 4 then Q5 end) Q5_4,
		max(case when Q_num = 5 then Q5 end) Q5_5,
		max(case when Q_num = 6 then Q5 end) Q5_6,
		max(case when Q_num = 7 then Q5 end) Q5_7,
		max(case when Q_num = 8 then Q5 end) Q5_8,
		max(case when Q_num = 9 then Q5 end) Q5_9

	from questions
	group by pid, newXSDID
)
, questions_merged as 
(
	select 
		PID, newXSDID,
		case 
			when Q1_9 is not null then Q1_9
			when Q1_8 is not null then Q1_8
			when Q1_7 is not null then Q1_7
			when Q1_6 is not null then Q1_6
			when Q1_5 is not null then Q1_5
			when Q1_4 is not null then Q1_4
			when Q1_3 is not null then Q1_3
			when Q1_2 is not null then Q1_2
			when Q1_1 is not null then Q1_1
		end Q1, 

		case 
			when Q2_9 is not null then Q2_9
			when Q2_8 is not null then Q2_8
			when Q2_7 is not null then Q2_7
			when Q2_6 is not null then Q2_6
			when Q2_5 is not null then Q2_5
			when Q2_4 is not null then Q2_4
			when Q2_3 is not null then Q2_3
			when Q2_2 is not null then Q2_2
			when Q2_1 is not null then Q2_1
		end Q2,

		case 
			when Q3_9 is not null then Q3_9
			when Q3_8 is not null then Q3_8
			when Q3_7 is not null then Q3_7
			when Q3_6 is not null then Q3_6
			when Q3_5 is not null then Q3_5
			when Q3_4 is not null then Q3_4
			when Q3_3 is not null then Q3_3
			when Q3_2 is not null then Q3_2
			when Q3_1 is not null then Q3_1
		end Q3, 

		case 
			when Q4_9 is not null then Q4_9
			when Q4_8 is not null then Q4_8
			when Q4_7 is not null then Q4_7
			when Q4_6 is not null then Q4_6
			when Q4_5 is not null then Q4_5
			when Q4_4 is not null then Q4_4
			when Q4_3 is not null then Q4_3
			when Q4_2 is not null then Q4_2
			when Q4_1 is not null then Q4_1
		end Q4, 

		case 
			when Q5_9 is not null then Q5_9
			when Q5_8 is not null then Q5_8
			when Q5_7 is not null then Q5_7
			when Q5_6 is not null then Q5_6
			when Q5_5 is not null then Q5_5
			when Q5_4 is not null then Q5_4
			when Q5_3 is not null then Q5_3
			when Q5_2 is not null then Q5_2
			when Q5_1 is not null then Q5_1
		end Q5 
	from pivot_qs
)
	select 
		PID, newXSDID,
		Q1, Q2, Q3, Q5, 
		case when Q4 like 'No%' then 'No' when Q4 like 'yes%' then 'Yes' end Q4, 
	
	case when CHARINDEX('Cps sent me to ER', Q4) > 0 then 1 end Q4_Y_Cps_to_ER,
	case when CHARINDEX('Phone busy', Q4) > 0 then 1 end Q4_Y_Phone_busy,
	case when CHARINDEX('No answer', Q4) > 0 then 1 end Q4_Y_No_Answer,
	case when CHARINDEX('Left message did', Q4) > 0 then 1 end Q4_Y_No_call_back,
	case when CHARINDEX('No available appointment', Q4) > 0 then 1 end Q4_Y_NoAppt,
	case when (CHARINDEX('Other', Q4) > 0 and CHARINDEX('Yes', Q4) > 0 )
				or ltrim(rtrim(fxn.RemoveNonAlphaNumericCharacters(Q4))) ='Yes' then 1 
			 end Q4_Y_Other,

	case when CHARINDEX('Clinic was closed', Q4) > 0 then 1 end Q4_N_Clinic_Closed,
	case when CHARINDEX('No phone', Q4) > 0 then 1 end Q4_N_No_Phone,
	case when CHARINDEX('Forgot to call', Q4) > 0 then 1 end Q4_N_Forgot,
	case when CHARINDEX('Language barrier', Q4) > 0 then 1 end Q4_N_Language,
	case when (CHARINDEX('Other', Q4) > 0 and CHARINDEX('No', Q4) > 0 )
				or ltrim(rtrim(fxn.RemoveNonAlphaNumericCharacters(Q4))) = 'No' then 1 
			 end Q4_N_Other
	into #questions
	from questions_merged;
	


/**************#education
partition by newly create newXSDID from #standardize_xsdid 
	same as questions
PID and newXSDID as identifier
****************************************/ 
drop table if exists #education;
declare 
	@EdHours varchar(30) = 'Hours of Operation (8am- 4:30pm Mon to Sat)',
	@EdAfter varchar(30) = 'After hours services (808-524-2575)',
	@EdExchange varchar(30) = 'Physician Exchange Line (808-524-2575)',
	@EdNurse varchar(30) = 'Nurse Advice Line',
	@EdPCP varchar(30) = 'Regular follow up with PCP',
	@EdSameDay varchar(30) = 'Same day appointment',
	@EdMedication varchar(30) = 'Proper Medication Use',
	@EdUseER varchar(30) = 'Appropriate ER Use',
	@EdOther varchar(30) = 'Other';
with education as 
(
	select 
		stand.newXSDID, summ.PID, summ.db_Create_Date,  
		case when Education is not null then 1 end Education, 
		case when charindex(@EdHours,Education) > 0 
					OR charindex('Hours Of Operation',Education) > 0  then 1 end EducationHoursOfOperation,
		case when charindex(@EdAfter,Education) > 0
					OR charindex('After Hour Services',Education) > 0   then 1 end EducationAfterHours,
		case when charindex(@EdExchange,Education) > 0  then 1 end EducationPhysicianExch,
		case when charindex(@EdNurse,Education) > 0 
					OR charindex('Nurse Advice',Education) > 0  then 1 end EducationNurseAdvice,
		case when charindex(@EdPCP,Education) > 0  then 1 end EducationPCPFollowUp,
		case when charindex(@EdSameDay,Education) > 0  then 1 end EducationSameDay,
		case when charindex(@EdMedication,Education) > 0  then 1 end EducationMedication,
		case when charindex(@EdUseER,Education) > 0  then 1 end EducationAppropriateER,
		case when charindex(@EdOther,Education) > 0  then 1 end EducationOther,
		E_num = ROW_NUMBER() over(partition by stand.newXSDID order by summ.db_Create_Date)
	from #allDocs_withSummary summ
		left join #standardize_xsdid stand on stand.SDID = summ.SDID
) --select * from education
, pivot_Es as 
(
	select 
		PID, newXSDID, 

		max(case when E_num = 1 then Education end) Education_1,
		max(case when E_num = 2 then Education end) Education_2,
		max(case when E_num = 3 then Education end) Education_3,
		max(case when E_num = 4 then Education end) Education_4,
		max(case when E_num = 5 then Education end) Education_5,
		max(case when E_num = 6 then Education end) Education_6,
		max(case when E_num = 7 then Education end) Education_7,
		max(case when E_num = 8 then Education end) Education_8,
		max(case when E_num = 9 then Education end) Education_9,

		max(case when E_num = 1 then EducationHoursOfOperation end) EducationHoursOfOperation_1,
		max(case when E_num = 2 then EducationHoursOfOperation end) EducationHoursOfOperation_2,
		max(case when E_num = 3 then EducationHoursOfOperation end) EducationHoursOfOperation_3,
		max(case when E_num = 4 then EducationHoursOfOperation end) EducationHoursOfOperation_4,
		max(case when E_num = 5 then EducationHoursOfOperation end) EducationHoursOfOperation_5,
		max(case when E_num = 6 then EducationHoursOfOperation end) EducationHoursOfOperation_6,
		max(case when E_num = 7 then EducationHoursOfOperation end) EducationHoursOfOperation_7,
		max(case when E_num = 8 then EducationHoursOfOperation end) EducationHoursOfOperation_8,
		max(case when E_num = 9 then EducationHoursOfOperation end) EducationHoursOfOperation_9,

		max(case when E_num = 1 then EducationAfterHours end) EducationAfterHours_1,
		max(case when E_num = 2 then EducationAfterHours end) EducationAfterHours_2,
		max(case when E_num = 3 then EducationAfterHours end) EducationAfterHours_3,
		max(case when E_num = 4 then EducationAfterHours end) EducationAfterHours_4,
		max(case when E_num = 5 then EducationAfterHours end) EducationAfterHours_5,
		max(case when E_num = 6 then EducationAfterHours end) EducationAfterHours_6,
		max(case when E_num = 7 then EducationAfterHours end) EducationAfterHours_7,
		max(case when E_num = 8 then EducationAfterHours end) EducationAfterHours_8,
		max(case when E_num = 9 then EducationAfterHours end) EducationAfterHours_9,

		max(case when E_num = 1 then EducationPhysicianExch end) EducationPhysicianExch_1,
		max(case when E_num = 2 then EducationPhysicianExch end) EducationPhysicianExch_2,
		max(case when E_num = 3 then EducationPhysicianExch end) EducationPhysicianExch_3,
		max(case when E_num = 4 then EducationPhysicianExch end) EducationPhysicianExch_4,
		max(case when E_num = 5 then EducationPhysicianExch end) EducationPhysicianExch_5,
		max(case when E_num = 6 then EducationPhysicianExch end) EducationPhysicianExch_6,
		max(case when E_num = 7 then EducationPhysicianExch end) EducationPhysicianExch_7,
		max(case when E_num = 8 then EducationPhysicianExch end) EducationPhysicianExch_8,
		max(case when E_num = 9 then EducationPhysicianExch end) EducationPhysicianExch_9,

		max(case when E_num = 1 then EducationNurseAdvice end) EducationNurseAdvice_1,
		max(case when E_num = 2 then EducationNurseAdvice end) EducationNurseAdvice_2,
		max(case when E_num = 3 then EducationNurseAdvice end) EducationNurseAdvice_3,
		max(case when E_num = 4 then EducationNurseAdvice end) EducationNurseAdvice_4,
		max(case when E_num = 5 then EducationNurseAdvice end) EducationNurseAdvice_5,
		max(case when E_num = 6 then EducationNurseAdvice end) EducationNurseAdvice_6,
		max(case when E_num = 7 then EducationNurseAdvice end) EducationNurseAdvice_7,
		max(case when E_num = 8 then EducationNurseAdvice end) EducationNurseAdvice_8,
		max(case when E_num = 9 then EducationNurseAdvice end) EducationNurseAdvice_9,

		max(case when E_num = 1 then EducationPCPFollowUp end) EducationPCPFollowUp_1,
		max(case when E_num = 2 then EducationPCPFollowUp end) EducationPCPFollowUp_2,
		max(case when E_num = 3 then EducationPCPFollowUp end) EducationPCPFollowUp_3,
		max(case when E_num = 4 then EducationPCPFollowUp end) EducationPCPFollowUp_4,
		max(case when E_num = 5 then EducationPCPFollowUp end) EducationPCPFollowUp_5,
		max(case when E_num = 6 then EducationPCPFollowUp end) EducationPCPFollowUp_6,
		max(case when E_num = 7 then EducationPCPFollowUp end) EducationPCPFollowUp_7,
		max(case when E_num = 8 then EducationPCPFollowUp end) EducationPCPFollowUp_8,
		max(case when E_num = 9 then EducationPCPFollowUp end) EducationPCPFollowUp_9,

		max(case when E_num = 1 then EducationSameDay end) EducationSameDay_1,
		max(case when E_num = 2 then EducationSameDay end) EducationSameDay_2,
		max(case when E_num = 3 then EducationSameDay end) EducationSameDay_3,
		max(case when E_num = 4 then EducationSameDay end) EducationSameDay_4,
		max(case when E_num = 5 then EducationSameDay end) EducationSameDay_5,
		max(case when E_num = 6 then EducationSameDay end) EducationSameDay_6,
		max(case when E_num = 7 then EducationSameDay end) EducationSameDay_7,
		max(case when E_num = 8 then EducationSameDay end) EducationSameDay_8,
		max(case when E_num = 9 then EducationSameDay end) EducationSameDay_9,

		max(case when E_num = 1 then EducationMedication end) EducationMedication_1,
		max(case when E_num = 2 then EducationMedication end) EducationMedication_2,
		max(case when E_num = 3 then EducationMedication end) EducationMedication_3,
		max(case when E_num = 4 then EducationMedication end) EducationMedication_4,
		max(case when E_num = 5 then EducationMedication end) EducationMedication_5,
		max(case when E_num = 6 then EducationMedication end) EducationMedication_6,
		max(case when E_num = 7 then EducationMedication end) EducationMedication_7,
		max(case when E_num = 8 then EducationMedication end) EducationMedication_8,
		max(case when E_num = 9 then EducationMedication end) EducationMedication_9,

		max(case when E_num = 1 then EducationAppropriateER end) EducationAppropriateER_1,
		max(case when E_num = 2 then EducationAppropriateER end) EducationAppropriateER_2,
		max(case when E_num = 3 then EducationAppropriateER end) EducationAppropriateER_3,
		max(case when E_num = 4 then EducationAppropriateER end) EducationAppropriateER_4,
		max(case when E_num = 5 then EducationAppropriateER end) EducationAppropriateER_5,
		max(case when E_num = 6 then EducationAppropriateER end) EducationAppropriateER_6,
		max(case when E_num = 7 then EducationAppropriateER end) EducationAppropriateER_7,
		max(case when E_num = 8 then EducationAppropriateER end) EducationAppropriateER_8,
		max(case when E_num = 9 then EducationAppropriateER end) EducationAppropriateER_9,

		max(case when E_num = 1 then EducationOther end) EducationOther_1,
		max(case when E_num = 2 then EducationOther end) EducationOther_2,
		max(case when E_num = 3 then EducationOther end) EducationOther_3,
		max(case when E_num = 4 then EducationOther end) EducationOther_4,
		max(case when E_num = 5 then EducationOther end) EducationOther_5,
		max(case when E_num = 6 then EducationOther end) EducationOther_6,
		max(case when E_num = 7 then EducationOther end) EducationOther_7,
		max(case when E_num = 8 then EducationOther end) EducationOther_8,
		max(case when E_num = 9 then EducationOther end) EducationOther_9
	from education 
	group by PID, newXSDID
)
	select 
		PID, newXSDID,
		case 
			when Education_9 is not null then Education_9
			when Education_8 is not null then Education_8
			when Education_7 is not null then Education_7
			when Education_6 is not null then Education_6
			when Education_5 is not null then Education_5
			when Education_4 is not null then Education_4
			when Education_3 is not null then Education_3
			when Education_2 is not null then Education_2
			when Education_1 is not null then Education_1
		end Education, 

		case 
			when EducationHoursOfOperation_9 is not null then EducationHoursOfOperation_9
			when EducationHoursOfOperation_8 is not null then EducationHoursOfOperation_8
			when EducationHoursOfOperation_7 is not null then EducationHoursOfOperation_7
			when EducationHoursOfOperation_6 is not null then EducationHoursOfOperation_6
			when EducationHoursOfOperation_5 is not null then EducationHoursOfOperation_5
			when EducationHoursOfOperation_4 is not null then EducationHoursOfOperation_4
			when EducationHoursOfOperation_3 is not null then EducationHoursOfOperation_3
			when EducationHoursOfOperation_2 is not null then EducationHoursOfOperation_2
			when EducationHoursOfOperation_1 is not null then EducationHoursOfOperation_1
		end EducationHoursOfOperation, 

		case 
			when EducationAfterHours_9 is not null then EducationAfterHours_9
			when EducationAfterHours_8 is not null then EducationAfterHours_8
			when EducationAfterHours_7 is not null then EducationAfterHours_7
			when EducationAfterHours_6 is not null then EducationAfterHours_6
			when EducationAfterHours_5 is not null then EducationAfterHours_5
			when EducationAfterHours_4 is not null then EducationAfterHours_4
			when EducationAfterHours_3 is not null then EducationAfterHours_3
			when EducationAfterHours_2 is not null then EducationAfterHours_2
			when EducationAfterHours_1 is not null then EducationAfterHours_1
		end EducationAfterHours,

		case 
			when EducationPhysicianExch_9 is not null then EducationPhysicianExch_9
			when EducationPhysicianExch_8 is not null then EducationPhysicianExch_8
			when EducationPhysicianExch_7 is not null then EducationPhysicianExch_7
			when EducationPhysicianExch_6 is not null then EducationPhysicianExch_6
			when EducationPhysicianExch_5 is not null then EducationPhysicianExch_5
			when EducationPhysicianExch_4 is not null then EducationPhysicianExch_4
			when EducationPhysicianExch_3 is not null then EducationPhysicianExch_3
			when EducationPhysicianExch_2 is not null then EducationPhysicianExch_2
			when EducationPhysicianExch_1 is not null then EducationPhysicianExch_1
		end EducationPhysicianExch, 

		case 
			when EducationNurseAdvice_9 is not null then EducationNurseAdvice_9
			when EducationNurseAdvice_8 is not null then EducationNurseAdvice_8
			when EducationNurseAdvice_7 is not null then EducationNurseAdvice_7
			when EducationNurseAdvice_6 is not null then EducationNurseAdvice_6
			when EducationNurseAdvice_5 is not null then EducationNurseAdvice_5
			when EducationNurseAdvice_4 is not null then EducationNurseAdvice_4
			when EducationNurseAdvice_3 is not null then EducationNurseAdvice_3
			when EducationNurseAdvice_2 is not null then EducationNurseAdvice_2
			when EducationNurseAdvice_1 is not null then EducationNurseAdvice_1
		end EducationNurseAdvice, 

		case 
			when EducationPCPFollowUp_9 is not null then EducationPCPFollowUp_9
			when EducationPCPFollowUp_8 is not null then EducationPCPFollowUp_8
			when EducationPCPFollowUp_7 is not null then EducationPCPFollowUp_7
			when EducationPCPFollowUp_6 is not null then EducationPCPFollowUp_6
			when EducationPCPFollowUp_5 is not null then EducationPCPFollowUp_5
			when EducationPCPFollowUp_4 is not null then EducationPCPFollowUp_4
			when EducationPCPFollowUp_3 is not null then EducationPCPFollowUp_3
			when EducationPCPFollowUp_2 is not null then EducationPCPFollowUp_2
			when EducationPCPFollowUp_1 is not null then EducationPCPFollowUp_1
		end EducationPCPFollowUp, 

		case 
			when EducationSameDay_9 is not null then EducationSameDay_9
			when EducationSameDay_8 is not null then EducationSameDay_8
			when EducationSameDay_7 is not null then EducationSameDay_7
			when EducationSameDay_6 is not null then EducationSameDay_6
			when EducationSameDay_5 is not null then EducationSameDay_5
			when EducationSameDay_4 is not null then EducationSameDay_4
			when EducationSameDay_3 is not null then EducationSameDay_3
			when EducationSameDay_2 is not null then EducationSameDay_2
			when EducationSameDay_1 is not null then EducationSameDay_1
		end EducationSameDay, 

		case 
			when EducationMedication_9 is not null then EducationMedication_9
			when EducationMedication_8 is not null then EducationMedication_8
			when EducationMedication_7 is not null then EducationMedication_7
			when EducationMedication_6 is not null then EducationMedication_6
			when EducationMedication_5 is not null then EducationMedication_5
			when EducationMedication_4 is not null then EducationMedication_4
			when EducationMedication_3 is not null then EducationMedication_3
			when EducationMedication_2 is not null then EducationMedication_2
			when EducationMedication_1 is not null then EducationMedication_1
		end EducationMedication, 

		case 
			when EducationAppropriateER_9 is not null then EducationAppropriateER_9
			when EducationAppropriateER_8 is not null then EducationAppropriateER_8
			when EducationAppropriateER_7 is not null then EducationAppropriateER_7
			when EducationAppropriateER_6 is not null then EducationAppropriateER_6
			when EducationAppropriateER_5 is not null then EducationAppropriateER_5
			when EducationAppropriateER_4 is not null then EducationAppropriateER_4
			when EducationAppropriateER_3 is not null then EducationAppropriateER_3
			when EducationAppropriateER_2 is not null then EducationAppropriateER_2
			when EducationAppropriateER_1 is not null then EducationAppropriateER_1
		end EducationAppropriateER, 

		case 
			when EducationOther_9 is not null then EducationOther_9
			when EducationOther_8 is not null then EducationOther_8
			when EducationOther_7 is not null then EducationOther_7
			when EducationOther_6 is not null then EducationOther_6
			when EducationOther_5 is not null then EducationOther_5
			when EducationOther_4 is not null then EducationOther_4
			when EducationOther_3 is not null then EducationOther_3
			when EducationOther_2 is not null then EducationOther_2
			when EducationOther_1 is not null then EducationOther_1
		end EducationOther
	into #education
	from pivot_Es


/**************#noApptReason
partition by newly create newXSDID from #standardize_xsdid 
	same as questions and education
PID and newXSDID as identifier
****************************************/ 
drop table if exists #noApptReason;
declare 
	@NoApptRefused varchar(30) = 'Refused',
	@NoApptNoContact varchar(30) = 'No Contact',
	@NoApptNoPhone varchar(30) = 'No Phone',
	@NoApptDisconnected varchar(30) = 'Phone Disconnected',
	@NoApptBusy varchar(30) = 'Phone Busy',
	@NoApptNoAnswer varchar(30) = 'No Answer',
	@NoApptWrong varchar(30) = 'Wrong Number',
	@NoApptLeftMessage varchar(30) = 'Left Message',
	@NoApptOther varchar(30) = 'Other';
;with no_appt as (
	select stand.newXSDID, summ.PID, summ.db_Create_Date,  NoApptReason,
		case when charindex(@NoApptRefused,NoApptreason) > 0  then 1 end No_Appt_Refused,
		case when charindex(@NoApptNoContact,NoApptreason) > 0  then 1 end No_Appt_NoContact,
		case when charindex(@NoApptNoPhone,NoApptreason) > 0  then 1 end No_Appt_NoPhone,
		case when charindex(@NoApptDisconnected,NoApptreason) > 0  then 1 end No_Appt_PhoneDisconnected,
		case when charindex(@NoApptBusy,NoApptreason) > 0  then 1 end No_Appt_PhoneBusy,
		case when charindex(@NoApptNoAnswer,NoApptreason) > 0  then 1 end No_Appt_NoAnswer,
		case when charindex(@NoApptWrong,NoApptreason) > 0  then 1 end No_Appt_WrongNumber,
		case when charindex(@NoApptLeftMessage,NoApptreason) > 0  then 1 end No_Appt_LeftMessage,
		case when NoApptReason is not null
					and charindex(@NoApptRefused,NoApptreason) < 1
					and charindex(@NoApptNoContact,NoApptreason) < 1
					and charindex(@NoApptNoPhone,NoApptreason) < 1
					and charindex(@NoApptDisconnected,NoApptreason) < 1
					and charindex(@NoApptBusy,NoApptreason) < 1
					and charindex(@NoApptNoAnswer,NoApptreason) < 1
					and charindex(@NoApptWrong,NoApptreason) < 1
					and charindex(@NoApptLeftMessage,NoApptreason) < 1
				then 1 end No_Appt_Other,
		A_num = ROW_NUMBER() over(partition by stand.newXSDID order by summ.db_Create_Date)
	from #allDocs_withSummary summ
			left join #standardize_xsdid stand on stand.SDID = summ.SDID
)
, pivot_no_appts as 
(
	select 
		PID, newXSDID, 

		max(case when A_num = 1 then No_Appt_Refused end) No_Appt_Refused_1,
		max(case when A_num = 2 then No_Appt_Refused end) No_Appt_Refused_2,
		max(case when A_num = 3 then No_Appt_Refused end) No_Appt_Refused_3,
		max(case when A_num = 4 then No_Appt_Refused end) No_Appt_Refused_4,
		max(case when A_num = 5 then No_Appt_Refused end) No_Appt_Refused_5,
		max(case when A_num = 6 then No_Appt_Refused end) No_Appt_Refused_6,
		max(case when A_num = 7 then No_Appt_Refused end) No_Appt_Refused_7,
		max(case when A_num = 8 then No_Appt_Refused end) No_Appt_Refused_8,
		max(case when A_num = 9 then No_Appt_Refused end) No_Appt_Refused_9,
		
		max(case when A_num = 1 then No_Appt_NoContact end) No_Appt_NoContact_1,
		max(case when A_num = 2 then No_Appt_NoContact end) No_Appt_NoContact_2,
		max(case when A_num = 3 then No_Appt_NoContact end) No_Appt_NoContact_3,
		max(case when A_num = 4 then No_Appt_NoContact end) No_Appt_NoContact_4,
		max(case when A_num = 5 then No_Appt_NoContact end) No_Appt_NoContact_5,
		max(case when A_num = 6 then No_Appt_NoContact end) No_Appt_NoContact_6,
		max(case when A_num = 7 then No_Appt_NoContact end) No_Appt_NoContact_7,
		max(case when A_num = 8 then No_Appt_NoContact end) No_Appt_NoContact_8,
		max(case when A_num = 9 then No_Appt_NoContact end) No_Appt_NoContact_9,
		
		max(case when A_num = 1 then No_Appt_NoPhone end) No_Appt_NoPhone_1,
		max(case when A_num = 2 then No_Appt_NoPhone end) No_Appt_NoPhone_2,
		max(case when A_num = 3 then No_Appt_NoPhone end) No_Appt_NoPhone_3,
		max(case when A_num = 4 then No_Appt_NoPhone end) No_Appt_NoPhone_4,
		max(case when A_num = 5 then No_Appt_NoPhone end) No_Appt_NoPhone_5,
		max(case when A_num = 6 then No_Appt_NoPhone end) No_Appt_NoPhone_6,
		max(case when A_num = 7 then No_Appt_NoPhone end) No_Appt_NoPhone_7,
		max(case when A_num = 8 then No_Appt_NoPhone end) No_Appt_NoPhone_8,
		max(case when A_num = 9 then No_Appt_NoPhone end) No_Appt_NoPhone_9,
		
		max(case when A_num = 1 then No_Appt_PhoneDisconnected end) No_Appt_PhoneDisconnected_1,
		max(case when A_num = 2 then No_Appt_PhoneDisconnected end) No_Appt_PhoneDisconnected_2,
		max(case when A_num = 3 then No_Appt_PhoneDisconnected end) No_Appt_PhoneDisconnected_3,
		max(case when A_num = 4 then No_Appt_PhoneDisconnected end) No_Appt_PhoneDisconnected_4,
		max(case when A_num = 5 then No_Appt_PhoneDisconnected end) No_Appt_PhoneDisconnected_5,
		max(case when A_num = 6 then No_Appt_PhoneDisconnected end) No_Appt_PhoneDisconnected_6,
		max(case when A_num = 7 then No_Appt_PhoneDisconnected end) No_Appt_PhoneDisconnected_7,
		max(case when A_num = 8 then No_Appt_PhoneDisconnected end) No_Appt_PhoneDisconnected_8,
		max(case when A_num = 9 then No_Appt_PhoneDisconnected end) No_Appt_PhoneDisconnected_9,
		
		max(case when A_num = 1 then No_Appt_PhoneBusy end) No_Appt_PhoneBusy_1,
		max(case when A_num = 2 then No_Appt_PhoneBusy end) No_Appt_PhoneBusy_2,
		max(case when A_num = 3 then No_Appt_PhoneBusy end) No_Appt_PhoneBusy_3,
		max(case when A_num = 4 then No_Appt_PhoneBusy end) No_Appt_PhoneBusy_4,
		max(case when A_num = 5 then No_Appt_PhoneBusy end) No_Appt_PhoneBusy_5,
		max(case when A_num = 6 then No_Appt_PhoneBusy end) No_Appt_PhoneBusy_6,
		max(case when A_num = 7 then No_Appt_PhoneBusy end) No_Appt_PhoneBusy_7,
		max(case when A_num = 8 then No_Appt_PhoneBusy end) No_Appt_PhoneBusy_8,
		max(case when A_num = 9 then No_Appt_PhoneBusy end) No_Appt_PhoneBusy_9,
		
		max(case when A_num = 1 then No_Appt_NoAnswer end) No_Appt_NoAnswer_1,
		max(case when A_num = 2 then No_Appt_NoAnswer end) No_Appt_NoAnswer_2,
		max(case when A_num = 3 then No_Appt_NoAnswer end) No_Appt_NoAnswer_3,
		max(case when A_num = 4 then No_Appt_NoAnswer end) No_Appt_NoAnswer_4,
		max(case when A_num = 5 then No_Appt_NoAnswer end) No_Appt_NoAnswer_5,
		max(case when A_num = 6 then No_Appt_NoAnswer end) No_Appt_NoAnswer_6,
		max(case when A_num = 7 then No_Appt_NoAnswer end) No_Appt_NoAnswer_7,
		max(case when A_num = 8 then No_Appt_NoAnswer end) No_Appt_NoAnswer_8,
		max(case when A_num = 9 then No_Appt_NoAnswer end) No_Appt_NoAnswer_9,
		
		max(case when A_num = 1 then No_Appt_WrongNumber end) No_Appt_WrongNumber_1,
		max(case when A_num = 2 then No_Appt_WrongNumber end) No_Appt_WrongNumber_2,
		max(case when A_num = 3 then No_Appt_WrongNumber end) No_Appt_WrongNumber_3,
		max(case when A_num = 4 then No_Appt_WrongNumber end) No_Appt_WrongNumber_4,
		max(case when A_num = 5 then No_Appt_WrongNumber end) No_Appt_WrongNumber_5,
		max(case when A_num = 6 then No_Appt_WrongNumber end) No_Appt_WrongNumber_6,
		max(case when A_num = 7 then No_Appt_WrongNumber end) No_Appt_WrongNumber_7,
		max(case when A_num = 8 then No_Appt_WrongNumber end) No_Appt_WrongNumber_8,
		max(case when A_num = 9 then No_Appt_WrongNumber end) No_Appt_WrongNumber_9,
		
		max(case when A_num = 1 then No_Appt_LeftMessage end) No_Appt_LeftMessage_1,
		max(case when A_num = 2 then No_Appt_LeftMessage end) No_Appt_LeftMessage_2,
		max(case when A_num = 3 then No_Appt_LeftMessage end) No_Appt_LeftMessage_3,
		max(case when A_num = 4 then No_Appt_LeftMessage end) No_Appt_LeftMessage_4,
		max(case when A_num = 5 then No_Appt_LeftMessage end) No_Appt_LeftMessage_5,
		max(case when A_num = 6 then No_Appt_LeftMessage end) No_Appt_LeftMessage_6,
		max(case when A_num = 7 then No_Appt_LeftMessage end) No_Appt_LeftMessage_7,
		max(case when A_num = 8 then No_Appt_LeftMessage end) No_Appt_LeftMessage_8,
		max(case when A_num = 9 then No_Appt_LeftMessage end) No_Appt_LeftMessage_9,
		
		max(case when A_num = 1 then No_Appt_Other end) No_Appt_Other_1,
		max(case when A_num = 2 then No_Appt_Other end) No_Appt_Other_2,
		max(case when A_num = 3 then No_Appt_Other end) No_Appt_Other_3,
		max(case when A_num = 4 then No_Appt_Other end) No_Appt_Other_4,
		max(case when A_num = 5 then No_Appt_Other end) No_Appt_Other_5,
		max(case when A_num = 6 then No_Appt_Other end) No_Appt_Other_6,
		max(case when A_num = 7 then No_Appt_Other end) No_Appt_Other_7,
		max(case when A_num = 8 then No_Appt_Other end) No_Appt_Other_8,
		max(case when A_num = 9 then No_Appt_Other end) No_Appt_Other_9
	from no_appt
	group by PID, newXSDID
)
	select
		PID, newXSDID,
		case 
			when No_Appt_Refused_9 is not null then No_Appt_Refused_9
			when No_Appt_Refused_8 is not null then No_Appt_Refused_8
			when No_Appt_Refused_7 is not null then No_Appt_Refused_7
			when No_Appt_Refused_6 is not null then No_Appt_Refused_6
			when No_Appt_Refused_5 is not null then No_Appt_Refused_5
			when No_Appt_Refused_4 is not null then No_Appt_Refused_4
			when No_Appt_Refused_3 is not null then No_Appt_Refused_3
			when No_Appt_Refused_2 is not null then No_Appt_Refused_2
			when No_Appt_Refused_1 is not null then No_Appt_Refused_1
		end No_Appt_Refused, 

		case 
			when No_Appt_NoContact_9 is not null then No_Appt_NoContact_9
			when No_Appt_NoContact_8 is not null then No_Appt_NoContact_8
			when No_Appt_NoContact_7 is not null then No_Appt_NoContact_7
			when No_Appt_NoContact_6 is not null then No_Appt_NoContact_6
			when No_Appt_NoContact_5 is not null then No_Appt_NoContact_5
			when No_Appt_NoContact_4 is not null then No_Appt_NoContact_4
			when No_Appt_NoContact_3 is not null then No_Appt_NoContact_3
			when No_Appt_NoContact_2 is not null then No_Appt_NoContact_2
			when No_Appt_NoContact_1 is not null then No_Appt_NoContact_1
		end No_Appt_NoContact, 
		case 
			when No_Appt_NoPhone_9 is not null then No_Appt_NoPhone_9
			when No_Appt_NoPhone_8 is not null then No_Appt_NoPhone_8
			when No_Appt_NoPhone_7 is not null then No_Appt_NoPhone_7
			when No_Appt_NoPhone_6 is not null then No_Appt_NoPhone_6
			when No_Appt_NoPhone_5 is not null then No_Appt_NoPhone_5
			when No_Appt_NoPhone_4 is not null then No_Appt_NoPhone_4
			when No_Appt_NoPhone_3 is not null then No_Appt_NoPhone_3
			when No_Appt_NoPhone_2 is not null then No_Appt_NoPhone_2
			when No_Appt_NoPhone_1 is not null then No_Appt_NoPhone_1
		end No_Appt_NoPhone, 

		case 
			when No_Appt_PhoneDisconnected_9 is not null then No_Appt_PhoneDisconnected_9
			when No_Appt_PhoneDisconnected_8 is not null then No_Appt_PhoneDisconnected_8
			when No_Appt_PhoneDisconnected_7 is not null then No_Appt_PhoneDisconnected_7
			when No_Appt_PhoneDisconnected_6 is not null then No_Appt_PhoneDisconnected_6
			when No_Appt_PhoneDisconnected_5 is not null then No_Appt_PhoneDisconnected_5
			when No_Appt_PhoneDisconnected_4 is not null then No_Appt_PhoneDisconnected_4
			when No_Appt_PhoneDisconnected_3 is not null then No_Appt_PhoneDisconnected_3
			when No_Appt_PhoneDisconnected_2 is not null then No_Appt_PhoneDisconnected_2
			when No_Appt_PhoneDisconnected_1 is not null then No_Appt_PhoneDisconnected_1
		end No_Appt_PhoneDisconnected, 

		case 
			when No_Appt_PhoneBusy_9 is not null then No_Appt_PhoneBusy_9
			when No_Appt_PhoneBusy_8 is not null then No_Appt_PhoneBusy_8
			when No_Appt_PhoneBusy_7 is not null then No_Appt_PhoneBusy_7
			when No_Appt_PhoneBusy_6 is not null then No_Appt_PhoneBusy_6
			when No_Appt_PhoneBusy_5 is not null then No_Appt_PhoneBusy_5
			when No_Appt_PhoneBusy_4 is not null then No_Appt_PhoneBusy_4
			when No_Appt_PhoneBusy_3 is not null then No_Appt_PhoneBusy_3
			when No_Appt_PhoneBusy_2 is not null then No_Appt_PhoneBusy_2
			when No_Appt_PhoneBusy_1 is not null then No_Appt_PhoneBusy_1
		end No_Appt_PhoneBusy, 

		case 
			when No_Appt_NoAnswer_9 is not null then No_Appt_NoAnswer_9
			when No_Appt_NoAnswer_8 is not null then No_Appt_NoAnswer_8
			when No_Appt_NoAnswer_7 is not null then No_Appt_NoAnswer_7
			when No_Appt_NoAnswer_6 is not null then No_Appt_NoAnswer_6
			when No_Appt_NoAnswer_5 is not null then No_Appt_NoAnswer_5
			when No_Appt_NoAnswer_4 is not null then No_Appt_NoAnswer_4
			when No_Appt_NoAnswer_3 is not null then No_Appt_NoAnswer_3
			when No_Appt_NoAnswer_2 is not null then No_Appt_NoAnswer_2
			when No_Appt_NoAnswer_1 is not null then No_Appt_NoAnswer_1
		end No_Appt_NoAnswer, 

		case 
			when No_Appt_WrongNumber_9 is not null then No_Appt_WrongNumber_9
			when No_Appt_WrongNumber_8 is not null then No_Appt_WrongNumber_8
			when No_Appt_WrongNumber_7 is not null then No_Appt_WrongNumber_7
			when No_Appt_WrongNumber_6 is not null then No_Appt_WrongNumber_6
			when No_Appt_WrongNumber_5 is not null then No_Appt_WrongNumber_5
			when No_Appt_WrongNumber_4 is not null then No_Appt_WrongNumber_4
			when No_Appt_WrongNumber_3 is not null then No_Appt_WrongNumber_3
			when No_Appt_WrongNumber_2 is not null then No_Appt_WrongNumber_2
			when No_Appt_WrongNumber_1 is not null then No_Appt_WrongNumber_1
		end No_Appt_WrongNumber, 

		case 
			when No_Appt_LeftMessage_9 is not null then No_Appt_LeftMessage_9
			when No_Appt_LeftMessage_8 is not null then No_Appt_LeftMessage_8
			when No_Appt_LeftMessage_7 is not null then No_Appt_LeftMessage_7
			when No_Appt_LeftMessage_6 is not null then No_Appt_LeftMessage_6
			when No_Appt_LeftMessage_5 is not null then No_Appt_LeftMessage_5
			when No_Appt_LeftMessage_4 is not null then No_Appt_LeftMessage_4
			when No_Appt_LeftMessage_3 is not null then No_Appt_LeftMessage_3
			when No_Appt_LeftMessage_2 is not null then No_Appt_LeftMessage_2
			when No_Appt_LeftMessage_1 is not null then No_Appt_LeftMessage_1
		end No_Appt_LeftMessage, 

		case 
			when No_Appt_Other_9 is not null then No_Appt_Other_9
			when No_Appt_Other_8 is not null then No_Appt_Other_8
			when No_Appt_Other_7 is not null then No_Appt_Other_7
			when No_Appt_Other_6 is not null then No_Appt_Other_6
			when No_Appt_Other_5 is not null then No_Appt_Other_5
			when No_Appt_Other_4 is not null then No_Appt_Other_4
			when No_Appt_Other_3 is not null then No_Appt_Other_3
			when No_Appt_Other_2 is not null then No_Appt_Other_2
			when No_Appt_Other_1 is not null then No_Appt_Other_1
		end No_Appt_Other
	into #noApptReason
	from pivot_no_appts

/**************************#RestofFormData
	Includes: documentation of appt scheduled, dat of appt in form, whether Cps sent to ER
	same as questions, education and noApptReason
*************************************************/
drop table if exists #RestofFormData
; with rest_data as (
	select 
		stand.newXSDID, summ.PID, summ.db_Create_Date,
		ApptScheduled, ApptDateInForm,  
		case when CpsSentToER = 'Cps sent to ER' then 1 end CpsSentToER, 
		R_num = ROW_NUMBER() over(partition by stand.newXSDID order by summ.db_Create_Date)
	from #allDocs_withSummary summ
			left join #standardize_xsdid stand on stand.SDID = summ.SDID
)
, pivot_rest as 
(
	select 
		PID, newXSDID, 

		max(case when R_num = 1 then CpsSentToER end) CpsSentToER_1,
		max(case when R_num = 2 then CpsSentToER end) CpsSentToER_2,
		max(case when R_num = 3 then CpsSentToER end) CpsSentToER_3,
		max(case when R_num = 4 then CpsSentToER end) CpsSentToER_4,
		max(case when R_num = 5 then CpsSentToER end) CpsSentToER_5,
		max(case when R_num = 6 then CpsSentToER end) CpsSentToER_6,
		max(case when R_num = 7 then CpsSentToER end) CpsSentToER_7,
		max(case when R_num = 8 then CpsSentToER end) CpsSentToER_8,
		max(case when R_num = 9 then CpsSentToER end) CpsSentToER_9,

		max(case when R_num = 1 then ApptScheduled end) ApptScheduled_1,
		max(case when R_num = 2 then ApptScheduled end) ApptScheduled_2,
		max(case when R_num = 3 then ApptScheduled end) ApptScheduled_3,
		max(case when R_num = 4 then ApptScheduled end) ApptScheduled_4,
		max(case when R_num = 5 then ApptScheduled end) ApptScheduled_5,
		max(case when R_num = 6 then ApptScheduled end) ApptScheduled_6,
		max(case when R_num = 7 then ApptScheduled end) ApptScheduled_7,
		max(case when R_num = 8 then ApptScheduled end) ApptScheduled_8,
		max(case when R_num = 9 then ApptScheduled end) ApptScheduled_9,

		max(case when R_num = 1 then ApptDateInForm end) ApptDateInForm_1,
		max(case when R_num = 2 then ApptDateInForm end) ApptDateInForm_2,
		max(case when R_num = 3 then ApptDateInForm end) ApptDateInForm_3,
		max(case when R_num = 4 then ApptDateInForm end) ApptDateInForm_4,
		max(case when R_num = 5 then ApptDateInForm end) ApptDateInForm_5,
		max(case when R_num = 6 then ApptDateInForm end) ApptDateInForm_6,
		max(case when R_num = 7 then ApptDateInForm end) ApptDateInForm_7,
		max(case when R_num = 8 then ApptDateInForm end) ApptDateInForm_8,
		max(case when R_num = 9 then ApptDateInForm end) ApptDateInForm_9
	from rest_data
	group by PID, newXSDID
)
	select
		PID, newXSDID,
		case 
			when CpsSentToER_9 is not null then CpsSentToER_9
			when CpsSentToER_8 is not null then CpsSentToER_8
			when CpsSentToER_7 is not null then CpsSentToER_7
			when CpsSentToER_6 is not null then CpsSentToER_6
			when CpsSentToER_5 is not null then CpsSentToER_5
			when CpsSentToER_4 is not null then CpsSentToER_4
			when CpsSentToER_3 is not null then CpsSentToER_3
			when CpsSentToER_2 is not null then CpsSentToER_2
			when CpsSentToER_1 is not null then CpsSentToER_1
		end CpsSentToER, 

		case 
			when ApptScheduled_9 is not null then ApptScheduled_9
			when ApptScheduled_8 is not null then ApptScheduled_8
			when ApptScheduled_7 is not null then ApptScheduled_7
			when ApptScheduled_6 is not null then ApptScheduled_6
			when ApptScheduled_5 is not null then ApptScheduled_5
			when ApptScheduled_4 is not null then ApptScheduled_4
			when ApptScheduled_3 is not null then ApptScheduled_3
			when ApptScheduled_2 is not null then ApptScheduled_2
			when ApptScheduled_1 is not null then ApptScheduled_1
		end ApptScheduled, 

		case 
			when ApptDateInForm_9 is not null then ApptDateInForm_9
			when ApptDateInForm_8 is not null then ApptDateInForm_8
			when ApptDateInForm_7 is not null then ApptDateInForm_7
			when ApptDateInForm_6 is not null then ApptDateInForm_6
			when ApptDateInForm_5 is not null then ApptDateInForm_5
			when ApptDateInForm_4 is not null then ApptDateInForm_4
			when ApptDateInForm_3 is not null then ApptDateInForm_3
			when ApptDateInForm_2 is not null then ApptDateInForm_2
			when ApptDateInForm_1 is not null then ApptDateInForm_1
		end ApptDateInForm
	into #RestofFormData
	from pivot_rest


END

/*****BILLED APPT and FUTURE APPT, NO PAST APPT NOT BILLED
	select * from #withFirstBilledApptAfterDischarge
	select * from #future_appt_including_today
*******************************************************************************************************/

BEGIN


/**#withFirstBilledApptAfterDischarge: add next appt date after discharge date
		- has to be FQHC qualified BH or medical visit 
		- not optometry facility --> optometry uses some medical codes
		- gap when patient seen but billing not complete
--****************************************************/
drop table if exists #withFirstBilledApptAfterDischarge;
;with get_first_BH_medical_visit_afterDischarge as (
	select 
		d.PID, d.newXSDID,
		convert(date, pv.DoS) ApptDate, 
		pv.Facility ApptFacility,
		df.ListName ApptProv, pv.MedicalVisit, pv.BHVisit,
		rownum = row_number() over(partition by d.PID, d.newXSDID order by pv.DoS asc)
	from #distinct_ER_Visits_append_ccda d
		left join cps_visits.PatientVisitType pv on pv.PID = d.PID 
													and (pv.MedicalVisit = 1 or pv.BHVisit = 1)
													and pv.FacilityID not in (4/*Optometry*/)
													and d.DischargeDate <= convert(date,pv.DoS)
		left join cps_all.DoctorFacility df on df.DoctorFacilityID = pv.ApptProviderID

) --select * from get_first_BH_medical_visit_afterDischarge where rownum = 1
select 
	PID, newXSDID, ApptDate, ApptFacility,  ApptProv
into #withFirstBilledApptAfterDischarge
from get_first_BH_medical_visit_afterDischarge u
where rowNum = 1


/* #future_appt: for visits without FQHC visit, look for future appt including today
		- appt has to be with billable provider but with execption for few job title

--****************************************************/
drop table if exists #future_appt_including_today;
;with future_appt as (
	select 
		b.PID, b.newXSDID, b.ApptDate, 
		ap.ApptDate [FutureApptDate], ap.AppointmentsID, df.ListName FutureProv, ap.Facility FutureFacility, 
		rowNum = ROW_NUMBER() over (partition by b.PID, newXSDID order by ap.apptDate )
	from #withFirstBilledApptAfterDischarge b
	left join cps_visits.Appointments ap on b.pid = ap.PID 
						and convert(datetime,ap.apptdate) + convert(datetime,ap.StartTime) >= getdate()
						and b.ApptDate is null
						and ap.PVID in (select pvid from cps_all.DoctorFacility df 
										where Billable = 1 and Inactive = 0 and ChartAccess = 1 
											and df.JobTitle not in ('Optometrist','Educator','Case Manager','Information Systems','Proxy users','Social Services')
										)
	left join cps_all.DoctorFacility df on df.PVID = ap.PVID
)
	select PID, newXSDID, FutureApptDate, FutureFacility, FutureProv, rowNum 
	into #future_appt_including_today
	from future_appt
	where rowNum = 1

END

/**#noshow: 
	Patient with FQHC appt or future appt scheduled
		- cancelled appt between discharge date and FQHC visit or future visit
		- count all the cancelled appt between discharge date and actual appt
		- exclude data entry error and facility error
		- separate patient with no show and without no show
			- add up number of no show for patients with no show 
			- combine patient with no show and without no show

	No appointment completed and no future appt scheduled
		- Get cancelled appt for those that dont have FQHC visit or future visit since discharged
		- count all the cancelled appt
		- no appt scheduled then count = -1
		- separate patient with no show and no appt at all
			- add up number of no show for patients with no show 
			- combine patient with no show and no appt at all

	Combine no shows
		- patient that had FQHC appt or future appt
		- patient that dont have any
--****************************************************/
drop table if exists #noshow;
;with appt_dates as (
select 
	dis.PID, dis.newXSDID, dis.DischargeDate,
	ApptDate, FutureApptDate
from #distinct_ER_Visits_append_ccda dis
	left join #withFirstBilledApptAfterDischarge bil on bil.newXSDID = dis.newXSDID
	left join  #future_appt_including_today fut on fut.newXSDID = dis.newXSDID
)
, add_no_show_between_discharge_and_appt as (
	select 
		w.PID, newXSDID, w.DischargeDate, ap.ApptDate CancelledAppt, w.ApptDate, w.FutureApptDate, ap.Canceled, ap.ApptStatus, 
		case when Canceled is null then 0 else 1 end No_Show_Count
	from appt_dates w
		left join cps_visits.Appointments ap on ap.pid = w.PID  
											and ap.ApptDate >= w.DischargeDate
											and ap.ApptDate <= isnull(w.ApptDate, w.FutureApptDate)
											and ap.Canceled = 1
											and ap.ApptStatus not in ('Data Entry Error','Cancel/Facility Error')
	where w.ApptDate is not null or w.FutureApptDate is not null 
) 
, noshow_between_discharge_and_appt as (
	/* no_show_count = 0, there wasn't any no show*/
	select newXSDID, No_Show_Count
	from add_no_show_between_discharge_and_appt
	where No_Show_Count = 0

	union
	
	/*no_show_count = 1, there was atleast 1 no show*/
	select newXSDID, count(*) No_Show_Count
	from add_no_show_between_discharge_and_appt
	where No_Show_Count = 1
	group by newXSDID

)
, no_show_people_with_no_appt as (
	select
		w.PID, newXSDID, w.DischargeDate, ap.ApptDate ApptInBetween, w.ApptDate, ap.Canceled, ap.ApptStatus,
		case when Canceled is null then -1 else 1 end No_Show_Count
	from appt_dates w
	left join cps_visits.Appointments ap on ap.pid = w.PID  
										and ap.ApptDate >= w.DischargeDate
										and ap.Canceled = 1
										and ap.ApptStatus not in ('Data Entry Error','Cancel/Facility Error')
	where w.ApptDate is null and w.FutureApptDate is null
)
, noshow_neverShowup as (
	/*appt never scheduled*/
	select newXSDID, No_Show_Count
	from no_show_people_with_no_appt
	where No_Show_Count = -1

	union 

	select newXSDID, count(*) No_Show_Count
	from no_show_people_with_no_appt
	where No_Show_Count = 1
	group by newXSDID
)
select * 
into #noshow
from (
	select * 
	from noshow_between_discharge_and_appt
	union 
	select * from noshow_neverShowup
) x

/********************CONTACT_ATTEMPT 
	* time between discharge and first call
	* time between dicharge and appt
*********************************************/

drop table if exists #contact_Attempt;
;with contact_attempt as (
	select distinct
		dis.newXSDID, dis.DischargeDate, FirstAttempt, ApptDate,
		DATEDIFF(day, dis.DischargeDate, FirstAttempt) First_Contact_Attempt,  
		DATEDIFF(day, dis.DischargeDate, ApptDate) Actual_Qualified_Appt
	from #distinct_ER_Visits_append_ccda dis
		left join #callAttempt_Letter_date cal on dis.newXSDID = cal.newXSDID
		left join #withFirstBilledApptAfterDischarge bil on bil.newXSDID = dis.newXSDID
)
	select newXSDID,
		case 
		when c.first_contact_attempt <=7 and c.First_Contact_Attempt >= 0 then '0_7'
		when c.first_contact_attempt <=14 and c.First_Contact_Attempt > 7 then '8_14'
		when c.first_contact_attempt <=30 and c.First_Contact_Attempt > 14 then '15_30'
		when c.First_Contact_Attempt >= 31 then '31+'
		when c.First_Contact_Attempt < 0 then 'Error'
	end First_Contact_Attempt_Range,
	case 
		when c.Actual_Qualified_Appt <=7 and c.Actual_Qualified_Appt >= 0 then '0_7'
		when c.Actual_Qualified_Appt <=14 and c.Actual_Qualified_Appt > 7 then '8_14'
		when c.Actual_Qualified_Appt <=30 and c.Actual_Qualified_Appt > 14 then '15_30'
		when c.Actual_Qualified_Appt >= 31 then '31+'
		when c.Actual_Qualified_Appt < 0 then 'Error'
		when c.Actual_Qualified_Appt is null then 'Not Yet'
	end Actual_Qualified_Appt_Range  
	into #contact_Attempt
	from contact_attempt c



/****************combine rest of the data with sanitized distinct ER/ Hospital Visit
	* combine call attempt
	* combine questions
	* combine education
	* combine noApptReason
	* combine restOfFormData

	* combine FQHC appt
	* combine future appt
	* combine no show

	* combine contact attempt
**************************************************************/


drop table if exists #combine;
select 
	dis.PID, pp.PatientID, dis.newXSDID, dis.ccda_count CCDA,
	case 
		when ApptFacility is not null then ApptFacility
		when FutureFacility is not null then FutureFacility
		when pp.Facility is not null then pp.Facility
		else 'Not Sure'
	end Apptfacility,
	case when cal.AdmitDate is null then dis.AdmitDate else cal.AdmitDate end AdmitDate, 
	case when cal.DischargeDate is null then dis.DischargeDate else cal.DischargeDate end DischargeDate, 
	case when cal.AdmitDx is null then dis.AdmitDx else cal.AdmitDx end AdmitDx, 
	case 
		when cal.ER_Hosp_Name is not null then cal.ER_Hosp_Name 
		when dis.ER_Hosp_Name is not null then dis.ER_Hosp_Name
		else 'Not Sure' 
	end ER_Hosp_Name, 
	case 
		when datediff(day, cal.AdmitDate, dis.DischargeDate) >= 2 then 0
		when datediff(day, cal.AdmitDate, dis.DischargeDate) = 0 then 1
		when Q2 is not null and Q1 = 'Yes' then 0
		when Q1 = 'No' then 1
		when cal.ER is null then dis.ER
		else cal.ER 
	end ER,

	FirstAttempt, SecondAttempt, ThirdAttempt, FourthAttempt,
	FifthAttempt, SixthAttempt, SeventhAttempt, LetterAttempt,
	Q1, Q2, Q3, Q4,
	Q4_Y_Cps_to_ER, Q4_Y_Phone_busy, Q4_Y_No_Answer, Q4_Y_No_call_back, Q4_Y_NoAppt, Q4_Y_Other,
	Q4_N_Clinic_Closed, Q4_N_No_Phone, Q4_N_Forgot, Q4_N_Language, Q4_N_Other,
	Q5,
	es.Education, EducationHoursOfOperation, EducationAfterHours, EducationPhysicianExch,
	EducationNurseAdvice, EducationPCPFollowUp, EducationSameDay, EducationMedication,
	EducationAppropriateER, EducationOther,
	No_Appt_Refused, No_Appt_NoContact, No_Appt_NoPhone, No_Appt_PhoneDisconnected, 
	No_Appt_PhoneBusy, No_Appt_NoAnswer, No_Appt_WrongNumber, No_Appt_LeftMessage,
	No_Appt_Other,
	ApptScheduled [ApptScheduledinForm], ApptDateInForm, CpsSentToER,
	ApptDate [ApptDateInCPS], ApptProv, 
	FutureApptDate, FutureProv, 
	No_Show_Count,
	First_Contact_Attempt_Range, Actual_Qualified_Appt_Range
into #combine
from #distinct_ER_Visits_append_ccda dis
	left join cps_all.PatientProfile pp on pp.PID = dis.PID
	left join #callAttempt_Letter_date cal on dis.newXSDID = cal.newXSDID
	left join #questions qs on qs.newXSDID = dis.newXSDID
	left join #education es on es.newXSDID = dis.newXSDID
	left join #noApptReason na on na.newXSDID = dis.newXSDID
	left join #RestofFormData rf on rf.newXSDID = dis.newXSDID
	left join #withFirstBilledApptAfterDischarge bil on bil.newXSDID = dis.newXSDID
	left join #future_appt_including_today fut on fut.newXSDID = dis.newXSDID
	left join #noshow sho on sho.newXSDID = dis.newXSDID
	left join #contact_Attempt con on con.newXSDID = dis.newXSDID



/* Unsed data in fnal SSIS
merged
	document info: sdid, xid, docabbr, db_create_date, clinicalDate, visDocID, Summary, docSigned, documentFacility
ignored  
	Form info: admitTime, ERCount, moreThanOneERInADay, TotalERInOneDay, Caller, apptCareCoordinator
*/

--select * from #combine


	insert into cps_cc.ER_Followup
	(
		[PID], [PatientID], [newXSDID], [CCDA], [ApptFacility], [AdmitDate], [DischargeDate], 
		[AdmitDx], [ER], [ER_Hosp_Name], [FirstAttempt], [SecondAttempt], [ThirdAttempt], 
		[FourthAttempt], [FifthAttempt], [SixthAttempt], [SeventhAttempt], [LetterAttempt], 
		[Q1], [Q2], [Q3], [Q4], [Q4_Y_Cps_to_ER], [Q4_Y_Phone_Busy], [Q4_Y_No_Answer], 
		[Q4_Y_No_Call_Back], [Q4_Y_NoAppt], [Q4_Y_Other], [Q4_N_Clinic_Closed], [Q4_N_No_Phone], 
		[Q4_N_Forgot], [Q4_N_Language], [Q4_N_Other], [Q5], [Education], [EducationHoursOfOperation], 
		[EducationAfterHours], [EducationPhysicianExch], [EducationNurseAdvice], [EducationPCPFollowUp], 
		[EducationSameDay], [EducationMedication], [EducationAppropriateER], [EducationOther], 
		[No_Appt_Refused], [No_Appt_NoContact], [No_Appt_NoPhone], [No_Appt_PhoneDisconnected], 
		[No_Appt_PhoneBusy], [No_Appt_NoAnswer], [No_Appt_WrongNumber], [No_Appt_LeftMessage], 
		[No_Appt_Other], [ApptScheduledinForm], [ApptDateInForm], [CpsSentToER], [ApptDateInCPS], 
		[ApptProv], [FutureApptDate], [FutureProv], [No_Show_Count], [First_Contact_Attempt_Range], 
		[Actual_Qualified_Appt_Range] 

	)
	select 
		[PID], [PatientID], [newXSDID], [CCDA], [ApptFacility], [AdmitDate], [DischargeDate], 
		[AdmitDx], [ER], [ER_Hosp_Name], [FirstAttempt], [SecondAttempt], [ThirdAttempt], 
		[FourthAttempt], [FifthAttempt], [SixthAttempt], [SeventhAttempt], [LetterAttempt], 
		[Q1], [Q2], [Q3], [Q4], [Q4_Y_Cps_to_ER], [Q4_Y_Phone_Busy], [Q4_Y_No_Answer], 
		[Q4_Y_No_Call_Back], [Q4_Y_NoAppt], [Q4_Y_Other], [Q4_N_Clinic_Closed], [Q4_N_No_Phone], 
		[Q4_N_Forgot], [Q4_N_Language], [Q4_N_Other], [Q5], [Education], [EducationHoursOfOperation], 
		[EducationAfterHours], [EducationPhysicianExch], [EducationNurseAdvice], [EducationPCPFollowUp], 
		[EducationSameDay], [EducationMedication], [EducationAppropriateER], [EducationOther], 
		[No_Appt_Refused], [No_Appt_NoContact], [No_Appt_NoPhone], [No_Appt_PhoneDisconnected], 
		[No_Appt_PhoneBusy], [No_Appt_NoAnswer], [No_Appt_WrongNumber], [No_Appt_LeftMessage], 
		[No_Appt_Other], [ApptScheduledinForm], [ApptDateInForm], [CpsSentToER], [ApptDateInCPS], 
		[ApptProv], [FutureApptDate], [FutureProv], [No_Show_Count], [First_Contact_Attempt_Range], 
		[Actual_Qualified_Appt_Range] 
	from #combine;


/* NEED TO COUNT WHO DID WHAT*/
; with u as 
(
	select DocAbbr, DocSigned, df.ListName, ClinicalDate, XSDID, PID
	from #allDocs_withSummary s
		left join cps_all.DoctorFacility df on df.PVID = s.DocSigned
	where DocAbbr not in ('ER_Scan', 'Hosp_Scan', 'CCDA')
)
	insert into [cps_cc].[ER_Staff_Count] (PID, XSDID, ClinicalDate, DocAbbr, DocSigned, ListName)
	select PID, XSDID, ClinicalDate, DocAbbr, DocSigned, ListName from u

end

go
